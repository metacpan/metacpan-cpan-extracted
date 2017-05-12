package Devel::Spy::TieScalar;
use strict;
use warnings;

use constant PAYLOAD => 0;
use constant CODE => 1;

sub TIESCALAR {
    my $class = shift @_;

    my @self;
    @self[ PAYLOAD, CODE, ] = @_;

    return bless \@self, $class;
}

sub FETCH {
    my $self = shift @_;

    my $value = ${ $self->[PAYLOAD] };

    my $followup = $self->[CODE]->("-> $value");

    return Devel::Spy->new( $value, $followup );
}

sub STORE {
    my ( $self, $value ) = @_;

    ${ $self->[PAYLOAD] } = $value;

    my $followup = $self->[CODE]->("= $value");

    return Devel::Spy->new( $value, $followup );
}

sub UNTIE {}
sub DESTROY {}

1;

__END__

=head1 NAME

Devel::Spy::TieScalar - Tied logging wrapper for scalars

=head1 SYNOPSIS

  tie my $pretend_guts, 'Devel::Spy::TieScalar', \ $real_guts, $logging_function
    or croak;

  # Passed operation through to $real_guts and tattled about the
  # operation to $logging_function.
  $pretend_guts = 42;

=head1 CAVEATS

Most functions have not been implemented. I implemented only the ones
I needed. Feel free to add more and send me patches. I'll also grant
you permission to upload into the Devel::Spy namespace if you're a
clueful developer.

=head1 SEE ALSO

L<Devel::Spy>, L<Devel::Spy::_obj>, L<Devel::Spy::Util>,
L<Devel::Spy::TieHash>, L<Devel::Spy::TieArray>,
L<Devel::Spy::TieHandle>.
