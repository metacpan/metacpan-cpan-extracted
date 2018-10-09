package Forks::Super::Tie::Enum;
use Carp;
use strict;
use warnings;
use vars qw(%ATTR %VALUE);

# A tie'd scalar value that can only take on values
# from a pre-specified list.
# Used in Forks::Super for $ON_BUSY and $QUEUE_INTERRUPT

sub TIESCALAR {
    my ($class, @attr) = @_;
    my $self;
    bless \$self, $class;
    $VALUE{\$self} = $attr[0];
    $ATTR{\$self} = [ @attr ];
    return \$self;
}

sub FETCH {
    my $self = shift;
    return $VALUE{$self};
}

sub STORE {
    my ($self,$value) = @_;
    foreach my $attr (@{$ATTR{$self}}) {
	if (uc $value eq uc $attr) {
	    $VALUE{$self} = $attr;
	    return;
	}
    }
    if ($ATTR{''}) {
	$VALUE{$self} = '';
    } else {
	carp "Invalid assignment to enumerated tied scalar";
    }
    return;
}

sub has_attr {
    my ($obj, $value) = @_;
    foreach my $attr (@{$ATTR{$obj}}) {
	if (uc $value eq uc $attr) {
	    return 1;
	}
    }
    return 0;
}

sub get_value {
    my ($obj) = @_;
    return $VALUE{$obj};
}

1;

=head1 NAME

Forks::Super::Tie::Enum - tie'd scalar that can only hold values on a small list

=head1 SYNOPSIS

    use Forks::Super::Tie::Enum;
    tie $next_action, 'Forks::Super::Tie::Enum', 'abort', 'retry', 'fail';
    $next_action = "abort";       # ok
    $next_action = "retry";       # ok
    $next_action = "go fishing";  # warning "Invalid assignment ..."

=head1 DESCRIPTION

This package is part of the L<Forks::Super|Forks::Super> distribution.
But it does not depend on any other part of C<Forks::Super> and there
is no reason it couldn't be extricated and used in a different context.

Scalar value where assignment will fail unless the new value is on a
list of value provided when the tie is started. If you expect
the value of C<$switch> to be either C<"on"> or C<"off"> and if your
script would fail catastrophically if a user tried to assign

    $switch = "cheesecake";

then this module might be for you!

=head1 USAGE

    tie $var, "Forks::Super::Tie::Enum", @list;

Assigns the first element of the given C<@list> to the scalar <$var>,
and ignores any future attempts to assign a value to C<$var> that was
not in C<@list> at the time of tie'ing.

Assigning an invalid value will cause this package to produce the
warning message

    Invalid assignment to enumerated tied scalar.

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2018, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
