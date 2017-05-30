package Net::Objwrap::ProxyS;
use 5.012;
use strict;
use warnings;

# we want to avoid polluting this namespace as much as possible

# like Net::Objwrap::Proxy but exclusively for SCALAR reftypes.
# It would be cumbersome to use a common proxy type that could
# be dereferenced as either a hash, an array, or a scalar,
# so let's use this separate proxy class that can be dereferenced
# as a scalar only.

use Carp ();
use Socket ();
use Data::Dumper ();

use overload
    '${}' => sub { $_[0]->{scalar} },
    'nomethod' => \&Net::Objwrap::Aux::overload_handler
    ;

sub AUTOLOAD {
    my $method = $Net::Objwrap::ProxyS::AUTOLOAD;
    $method =~ s/.*:://;

    my $self = shift;
    my $has_args = @_ > 0;
    my $args = [ @_ ];

    # context: 0=void, 1=scalar, 2=list
    my $context = defined(wantarray) ? 1+wantarray : 0;

    my $req = {
        id => $self->{id},
	topic => 'METHOD',
	command => $method,
	has_args => $has_args,
	args => $args,
	context => $context,
	autoload => 1
    };
    return Net::Objwrap::Aux::process_request($self, $req);
}

sub DESTROY {
    my $self = shift;
    $self->{_DESTROY}++;
    my $socket = $self->{socket};
    Net::Objwrap::Aux::process_request(
	$self, { id => $self->{id}, topic => 'META', command => 'disconnect' });
    close $socket if $socket;
}

############################################################

# tie classes. Operations on the objects are forwarded to the remote server

sub Net::Objwrap::SCALAR::TIESCALAR {
    my ($pkg, $proxy) = @_;
    return bless { obj => $proxy, id => $proxy->{id} }, $pkg;
}

sub Net::Objwrap::SCALAR::__ {
    my ($tied, $name, $context, @args) = @_;
    $context //= defined(wantarray) ? 1+wantarray : 0;
    return Net::Objwrap::Aux::process_request(
	$tied->{obj},
	{ topic => 'SCALAR', command => $name, context => $context,
	  has_args => @_ > 0, args => [ @args ], id => $tied->{id} });
}

sub Net::Objwrap::SCALAR::FETCH { return shift->__('FETCH',0) }
sub Net::Objwrap::SCALAR::STORE { return shift->__('STORE',1,@_) }

1;

=head1 NAME

Net::Objwrap::ProxyS - handle for proxy access to remote Perl object



=head1 VERSION

0.09



=head1 DESCRIPTION

See L<Net::Objwrap> for a description of this module and
instructions for using it.

L<Net::Objwrap::Proxy> describes a client-side class that provides
a handle for access to a remote object of reference type HASH or ARRAY,
and provides facilities, through L<overload>,
to dereference a proxy object as if it were
a reference to a hash or an array. It is cumbersome to use an object
that is overloaded for use a dereferenced hash, array, and scalar,
and so this separate class, C<Net::Objwrap::ProxyS>, is available
to provide remote access to objects of SCALAR reference type.

From the user's perspective, method calls, overloading, 
and dereferencing of a C<Net::Objwrap::ProxyS> proxy object should
work the same way as for a C<Net::Objwrap::Proxy> object, and there
is little need for the user to know which type of object is being
used to access the remote object.



=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
