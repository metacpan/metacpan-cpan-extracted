package Devel::Spy::TieHash;
use strict;
use warnings;

use constant PAYLOAD => 0;
use constant CODE => 1;

sub TIEHASH {
    my $class = shift @_;

    return bless [@_], $class;
}

sub FETCH {
    my ( $self, $key ) = @_;
    $key = '' unless defined $key;

    my $value = $self->[PAYLOAD]{$key};

    my $followup = $self->[CODE]
        ->( "->{$key} -> " . ( defined $value ? $value : 'undef' ) );

    return Devel::Spy->new( $value, $followup );
}

sub STORE {
    my ( $self, $key, $value ) = @_;
    $key = '' unless defined $key;

    $self->[PAYLOAD]{$key} = $value;

    my $followup = $self->[CODE]
        ->( "->{$key} = " . ( defined $value ? $value : 'undef' ) );

    return Devel::Spy->new( $value, $followup );
}

sub DELETE {
    my ( $self, $key ) = @_;
    $key = '' unless defined $key;

    my $value = delete $self->[PAYLOAD]{$key};

    my $followup = $self->[CODE]
        ->( " delete ->{$key} ->" . ( defined $value ? $value : 'undef' ) );

    return Devel::Spy->new( $value, $followup );
}

sub CLEAR {
    my ($self) = @_;

    %{ $self->[PAYLOAD] } = ();
    $self->[CODE](' %... = ()');
    return;
}

sub EXISTS {
    my ( $self, $key ) = @_;
    $key = '' unless defined $key;

    my $value    = exists $self->[PAYLOAD]{$key};
    my $followup = $self->[CODE](" exists(->{$key}) ->" . ( defined $value ? $value : 'undef' ));

    return Devel::Spy->new( $value, $followup );
}

sub FIRSTKEY {
    my ($self) = @_;

    keys %{ $self->[PAYLOAD] };
    my $key      = each %{ $self->[PAYLOAD] };
    my $followup = $self->[CODE](" each(%...) ->" . ( defined $key ? $key : 'undef' ));
    return Devel::Spy->new( $key, $followup );
}

sub NEXTKEY {
    my ( $self, undef ) = @_;

    my $key      = each %{ $self->[PAYLOAD] };
    my $followup = $self->[CODE](" each(%...) ->" . ( defined $key ? $key : 'undef' ));
    return Devel::Spy->new( $key, $followup );
}

sub SCALAR {
    my ($self) = @_;

    my $value    = %{ $self->[PAYLOAD] };
    my $followup = $self->[CODE](" scalar(%...) ->" . ( defined $value ? $value : 'undef' ));
    return Devel::Spy->new( $value, $followup );
}

sub UNTIE {}
sub DESTROY {}

1;

__END__

=head1 NAME

Devel::Spy::TieHash - Tied logging wrapper for hashes

=head1 SYNOPSIS

  tie my %pretend_guts, 'Devel::Spy::TieHash', \ %real_guts, $logging_function
    or croak;

  # Passed operation through to %real_guts and tattled about the
  # operation to $logging_function.
  $pretend_guts{foo} = 42;

=head1 CAVEATS

Most functions have not been implemented. I implemented only the ones
I needed. Feel free to add more and send me patches. I'll also grant
you permission to upload into the Devel::Spy namespace if you're a
clueful developer.

=head1 SEE ALSO

L<Devel::Spy>, L<Devel::Spy::_obj>, L<Devel::Spy::Util>,
L<Devel::Spy::TieArray>, L<Devel::Spy::TieScalar>,
L<Devel::Spy::TieHandle>.
