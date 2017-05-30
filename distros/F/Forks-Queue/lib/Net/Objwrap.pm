package Net::Objwrap;
use 5.012;
use Net::Objwrap::Server;
use Net::Objwrap::Client;
use Net::Objwrap::Proxy;
use Net::Objwrap::ProxyS;
use Carp;
use base 'Exporter';

#croak "not supported on $^O" if $^O eq 'MSWin32';

our @EXPORT_OK = qw(wrap unwrap);

our $VERSION = '0.09';
our $XDEBUG = $ENV{XDEBUG} || 0;
if ($XDEBUG && $XDEBUG != 1) {
    close STDERR;
    open *STDERR, '>', $XDEBUG;
    if ($INC{'Test/More.pm'}) {
        Test::More->builder->{Stack}[0]{_formatter}{handles}[1] = *STDERR;
    }
}

sub xdiag { $XDEBUG && $INC{'Test/More.pm'} && Test::More::diag(@_) }
sub xdiagdump { $XDEBUG && $INC{'Test/More.pm'} 
                && Test::More::diag(Data::Dumper::Dumper(\@_)) }

sub serialize {
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 1;
    my $dump = Data::Dumper::Dumper($_[0]);
    chomp($dump);
    return $dump;
}

sub deserialize {
    my $VAR1;
    eval $_[0];
    $VAR1;
}

sub wrap {
    my ($file, @obj) = @_;
    my $opts = {};
    if (ref($file) eq 'HASH') {
	$opts = $file;
	$file = shift @obj;
    }
    croak 'usage: wrap($file,$obj)' if @obj == 0;
    Net::Objwrap::Server->new($opts, $file, @obj);
}

sub unwrap {
    my $file = shift;
    my $client = Net::Objwrap::Client->new($file);
    my @o = $client->get_objs;
    return wantarray ? @o : $o[0];
}

sub ref {
    xdiag "in NO::ref";
    my $handle = ref($_[0]) eq 'Net::Objwrap::Proxy' ? ${$_[0]} : $_[0];
    return $handle && Net::Objwrap::Aux::process_request(
        $handle, { topic => 'META', command => 'ref', id => $handle->{id} });
}

sub reftype {
    xdiag "in NO::reftype";
    my $handle = ref($_[0]) eq 'Net::Objwrap::Proxy' ? ${$_[0]} : $_[0];
    return $handle && Net::Objwrap::Aux::process_request(
        $handle, { topic => 'META', command => 'reftype',
                   id => $handle->{id} });
}

sub import {
    my ($class,@args) = @_;
    my @tags = grep /^:/, @args;
    @args = grep !/^:/, @args;
    foreach my $tag (@tags) {
	if ($tag eq ':test' || $tag eq ':all-test') {
	    # settings that will allow the tests to run faster
            Net::Objwrap::Server->TEST_MODE;
	}
	if ($tag eq ':all' || $tag eq ':all-test') {
	    push @args, 'wrap', 'unwrap';
	}
    }
    Net::Objwrap->export_to_level(1,'Net::Objwrap',@args);
}

1;

=head1 NAME

Net::Objwrap - allow arbitrary access to Perl object over network


=head1 VERSION

0.09


=head1 SYNOPSIS

    # on machine 1
    use Net::Objwrap 'wrap';
    use Some::Package;
    my $obj = Some::Package->new(...);
    wrap("obj17.cfg", $obj);
    ...

    # on machine 2
    use Net::Objwrap 'unwrap';
    my $obj = unwrap("obj17.cfg");
    $obj->{bar} = 19;      # updates $obj->{bar} on the server
    my $x = $obj->foo(42); # calls $obj->foo(42) on object on machine 1



=head1 DESCRIPTION

The classes of the C<Net::Objwrap> provide network
access to a Perl object. The name of a configuration file and an
arbitrary Perl object are passed to the L<"wrap"> function.
C<wrap> launches a simple server
and publishes connection info in the configuration file.

Another script, possibly on a another host, loads the configuration
file with a call to a L<"unwrap">, and
receives a proxy to the object on the server. The client establishes
communication with the server specified in the config file.
As this second script manipulates or makes method calls on the
proxy object, the client communicates with the server to
manipulate the object and return the results of the operation.

Some important features:

=head2 Hash members and array indices

Accessing or updating hash values or array values on a remote object
is done with the same syntax as access of a local object.

    # host 1
    use Net::Objwrap 'wrap';
    my $hash1 = { abc => 123, def => [ 456, { ghi => "jkl" }, "mno" ] };
    wrap('server.cfg', $hash1);
    ...

    # host 2
    use Net::Objwrap 'unwrap';
    my $hash2 = unwrap('server.cfg');
    print $hash2->{abc};                 # "123"
    $hash2->{def}[2] = "pqr";            # updates $hash1 on host1
    print delete $hash2->{def}[1]{ghi};  # "jkl", updates $hash1 on host1

=head2 Remote method calls

Method calls on the proxy object are propagated to the remote object,
affecting the remote object and returning the result of the call.

    # host 1
    use Net::Objwrap 'wrap';
    sub Foofie::new { bless \$_[1], 'Foofie' }
    sub Foofie::blerp {my $self=shift;wantarray ? (5,6,7,$$self) : ++$$self}
    wrap('server.cfg', Foofie->new(17));

    # host 2
    use Net::Objwrap 'unwrap';
    my $foo = unwrap('server.cfg');
    my @x = $foo->blerp;   # (5,6,7,17)
    my $x = $foo->blerp;   # 18

=head2 overload'ed operators

Any overloading that is enabled for a remote object will occur for the proxy
as well.

    # host 1
    use Net::Objwrap 'wrap';
    my $obj = Barfie->new(2,5);
    wrap('server.cfg',$obj);
    package Barfie;
    use overload '+=',sub{$_+=$_[1] for @{$_[0]->{vals}};$_[0]}, fallback => 1;
    sub new {
        my $pkg = shift;
        bless { vals => [ @_ ] }, $pkg;
    }
    sub prod { my $self=shift; my $z=1; $z*=$_ for @{$self->{vals}}; $z }

    # host 2
    use Net::Objwrap 'unwrap';
    my $obj = unwrap('server.cfg');
    print $obj->prod;      # 2 * 5 => 10
    $obj += -4;
    print $obj->prod;      # 6 * 9 => 54



=head1 FUNCTIONS

=head2 wrap

=head2 wrap($config_filename,@object)

=head2 wrap(\%opts,$config_filename,@object)

Creates a TCP server on the local machine that provides proxy
access to one or more given object, and writes information to the given
filename about how to connect to the server.

This function will C<die> if there are any issues establishing
the server.


=head2 unwrap

=head2 $proxy = unwrap($config_filename)

=head2 @proxies = unwrap($config_filename)

Connects to the server specified by information in the given
configuration file name, and returns a proxy to one or more
remote objects that were identified in the server's C<wrap> call.


=head2 ref

=head2 reftype

=head2 $ref = Net::Objwrap::ref($proxy)

=head2 $reftype = Net::Objwrap::reftype($proxy)

Returns the "real" object types. That is, the object types of the
object on the remote server.


=head1 BUGS AND LIMITATIONS


=head2 Overhead

Every interrogation and manipulation of an object incurs
network overhead.

=head2 Server runs in a separate process from the process
that created the object

Once a client connects to the object wrapper server, the
interaction with the client is handled in a child process,
and the client is interacting with a I<copy> of the
original object. Unless the object takes care to be
synchronized across different processes (like C<Forks::Queue>
does) or stashes its contents in an external data store
like shared memory or a database, programs running on
different hosts or in different processes on the same host
will not be working with the same object.

It is possible that a future version of this distribution
could use threads and shared objects to mitigate this
limitation.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut




=begin TODO

Other things that don't work:

    $proxy->{member} = value      when  $remote->{member} is tied
    $proxy->member = value        when  Remote::member  has lvalue attribute
    tied($proxy)                  when  $remote  is tied

=end TODO

=cut
