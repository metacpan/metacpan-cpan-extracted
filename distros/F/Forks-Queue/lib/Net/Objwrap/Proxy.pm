package Net::Objwrap::Proxy;
use 5.012;
use strict;
use warnings;

# we want to avoid polluting this namespace as much as possible

use Carp ();
use Socket ();
use Data::Dumper ();
$Data::Dumper::Sortkeys = 1;

use overload
    '%{}' => sub { ${$_[0]}->{hash} },
    '@{}' => sub { ${$_[0]}->{array} },
    'nomethod' => \&Net::Objwrap::Aux::overload_handler,
    ;

# calling a method on the proxy object should have the effect
# of calling the same method on the remote object
sub AUTOLOAD {
    my $method = $Net::Objwrap::Proxy::AUTOLOAD;
    $method =~ s/.*:://;

    my $self = shift;
    my $has_args = @_ > 0;
    my $args = [ @_ ];

    # context: 0=void, 1=scalar, 2=list
    my $context = defined(wantarray) ? 1+wantarray : 0;

    my $req = {
        id => $$self->{id},
	topic => 'METHOD',
	command => $method,
	has_args => $has_args,
	args => $args,
	context => $context,
	autoload => 1
    };
    return Net::Objwrap::Aux::process_request($$self, $req);
}

sub DESTROY {
    my $self = shift;
    $$self->{_DESTROY}++;
    my $socket = $$self->{socket};
    Net::Objwrap::Aux::process_request(
	$$self, { id => $$self->{id}, topic => 'META',
                  command => 'disconnect' });
    close $socket if $socket;
}

############################################################

# tie classes. Operations on the objects are forwarded to the remote server

sub Net::Objwrap::HASH::TIEHASH {
    my ($pkg,$proxy) = @_;
    Net::Objwrap::xdiag("--- TIEHASH! ---");
    return bless { obj => $proxy, id => $proxy->{id} }, $pkg;
}

sub Net::Objwrap::HASH::__ {
    my ($tied, $name, $context, @args) = @_;
    $context //= defined(wantarray) ? 1+wantarray : 0;
    return Net::Objwrap::Aux::process_request(
	$tied->{obj},
	{ topic => 'HASH', command => $name, context => $context,
	  has_args => @args > 0, args => \@args, id => $tied->{id} } );
}

sub Net::Objwrap::HASH::CLEAR    { return shift->__('CLEAR',0) }
sub Net::Objwrap::HASH::DELETE   { return shift->__('DELETE',1,@_) }
sub Net::Objwrap::HASH::EXISTS   { return shift->__('EXISTS',1,@_) }
sub Net::Objwrap::HASH::FETCH    { return shift->__('FETCH',1,@_) }
sub Net::Objwrap::HASH::FIRSTKEY { return shift->__('FIRSTKEY',1) }
sub Net::Objwrap::HASH::NEXTKEY  { return shift->__('NEXTKEY',1,@_) }
sub Net::Objwrap::HASH::SCALAR   { return shift->__('SCALAR',1) }
sub Net::Objwrap::HASH::STORE    { return shift->__('STORE',1,@_) }

####

sub Net::Objwrap::ARRAY::TIEARRAY {
    my ($pkg,$proxy) = @_;
    return bless { obj => $proxy, id => $proxy->{id} }, $pkg;
}

sub Net::Objwrap::ARRAY::__ {
    my ($tied, $name, $context, @args) = @_;
    $context //= defined(wantarray) ? 1+wantarray : 0;
    return Net::Objwrap::Aux::process_request(
	$tied->{obj},
	{ topic => 'ARRAY', command => $name, context => $context,
	  has_args => @_ > 0, args => [ @args ], id => $tied->{id} });
}

sub Net::Objwrap::ARRAY::FETCH     { return shift->__('FETCH',1,@_) }
sub Net::Objwrap::ARRAY::STORE     { return shift->__('STORE',1,@_) }
sub Net::Objwrap::ARRAY::FETCHSIZE { return shift->__('FETCHSIZE',1) }
sub Net::Objwrap::ARRAY::STORESIZE { return shift->__('STORESIZE',1,@_) }
sub Net::Objwrap::ARRAY::DELETE    { return shift->__('DELETE',1,@_) }
sub Net::Objwrap::ARRAY::CLEAR     { return shift->__('CLEAR',0) }
sub Net::Objwrap::ARRAY::EXISTS    { return shift->__('EXISTS',1,@_) }
sub Net::Objwrap::ARRAY::PUSH      { return shift->__('PUSH',1,@_) }
sub Net::Objwrap::ARRAY::POP       { return shift->__('POP',1) };
sub Net::Objwrap::ARRAY::SHIFT     { return shift->__('SHIFT',1) }
sub Net::Objwrap::ARRAY::UNSHIFT   { return shift->__('UNSHIFT',1,@_) }
sub Net::Objwrap::ARRAY::SPLICE {
    my $tied = shift;
    my $off = @_ ? shift : 0;
    my $len = @_ ? shift : 'undef';
    return $tied->__('SPLICE',2,$off,$len,@_);
}

####

1;

=head1 NAME

Net::Objwrap::Proxy - handle for proxy access to remote Perl object



=head1 VERSION

0.09



=head1 DESCRIPTION

See L<Net::Objwrap> for a description of this module and
instructions for using it.

C<Net::Objwrap::Proxy> wraps a remote object and provides
access to the object as if it were on the local machine.
Member (for hash reference types) and index (for array
reference types) access, method calls, and object overloading
on the proxy object -- everything except lvalue usage --
should affect the remote object in the same way as using
the object locally.

The return value of L<"unwrap"/Net::Objwrap> is a list of
C<Net::Objwrap::Proxy> objects.

L<Net::Objwrap::ProxyS> is another proxy class used for
remote objects of SCALAR reference type. This second class
is provided because it is cumbersome in the C<Net::Objwrap>
implementation to use a proxy object that is capable of being
dereferenced as a hash, an array, and a scalar.




=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
