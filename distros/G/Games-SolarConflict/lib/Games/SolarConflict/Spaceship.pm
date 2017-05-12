package Games::SolarConflict::Spaceship;
{
  $Games::SolarConflict::Spaceship::VERSION = '0.000001';
}

# ABSTRACT: Spaceship model

use strict;
use warnings;
use Mouse;
use Math::Trig qw( deg2rad );

with 'Games::SolarConflict::Roles::Physical';

has '+r' => ( default => 14 );

has '+mass' => ( default => 101 );

# directional acceleration
has d_a => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has power => (
    is      => 'rw',
    isa     => 'Num',
    default => 100,
);

has sprite => (
    is       => 'ro',
    isa      => 'Games::SolarConflict::Sprite::Rotatable',
    required => 1,
    handles  => [qw( rect )],
);

has torpedos => (
    is      => 'ro',
    isa     => 'ArrayRef[Games::SolarConflict::Torpedo]',
    default => sub { [] },
);

with 'Games::SolarConflict::Roles::Drawable';
with 'Games::SolarConflict::Roles::Explosive';

before acc => sub {
    my ( $self, $acc ) = @_;
    $self->_update_acc( $self->d_a, $self->rotation ) if defined $acc;
};

sub _update_acc {
    my ( $self, $acc, $rot ) = @_;

    my $angle = deg2rad($rot);

    $self->a_x( $acc * sin($angle) );
    $self->a_y( $acc * -cos($angle) );
}

sub draw {
    my ( $self, $surface ) = @_;

    $self->sprite->x( $self->x - $self->rect->w / 2 );
    $self->sprite->y( $self->y - $self->rect->h / 2 );
    $self->sprite->rotation( $self->rotation );
    $self->sprite->draw($surface);

    return [
        $self->rect->x - 1,
        $self->rect->y - 1,
        $self->rect->w + 2,
        $self->rect->h + 2
    ];
}

sub interact {
    my ( $self, $obj ) = @_;

    $self->decrease_power( $obj->mass );
}

sub decrease_power {
    my ( $self, $damage ) = @_;

    my $power = $self->power - $damage;

    if ( $self->power >= 0 && $power < 0 ) {
        $self->explode();
        $self->active(0);
    }

    $self->power($power);
}

sub fire_torpedo {
    my ($self) = @_;

    my $torpedo = $self->_torpedo;

    return unless $torpedo;

    return if $self->power < 1;
    $self->decrease_power(1);

    my $angle = deg2rad( $self->rotation );

    my $v_x = $self->v_x;
    my $v_y = $self->v_y;

    my $dx = sin($angle);
    my $dy = -cos($angle);
    my $dd = $self->r + $torpedo->r + 5;
    my $dv = 20;

    $torpedo->x( $self->x + $dx * $dd );
    $torpedo->y( $self->y + $dy * $dd );
    $torpedo->v_x( $v_x + $dx * $dv );
    $torpedo->v_y( $v_y + $dy * $dv );
    $torpedo->active(1);
}

sub warp {
    my ( $self, $x, $y ) = @_;

    return if $self->power < 10;
    $self->decrease_power(10);

    $self->x($x);
    $self->y($y);
    $self->v_x(0);
    $self->v_y(0);
    $self->ang_v(0);
}

sub _torpedo {
    my ($self) = @_;

    foreach my $torpedo ( @{ $self->torpedos } ) {
        return $torpedo unless $torpedo->active;
    }

    return;
}

sub reset {
    my ($self) = @_;

    $self->active(1);
    $self->visible(1);
    $self->power(100);

    $self->x(0);
    $self->y(0);
    $self->rotation(0);

    $self->v_x(0);
    $self->v_y(0);
    $self->ang_v(0);

    $_->active(0) foreach ( @{ $self->torpedos } );
}

__PACKAGE__->meta->make_immutable;

no Mouse;

1;



=pod

=head1 NAME

Games::SolarConflict::Spaceship - Spaceship model

=head1 VERSION

version 0.000001

=for Pod::Coverage decrease_power fire_torpedo interact warp

=head1 SEE ALSO

=over 4

=item * L<Games::SolarConflict>

=back

=head1 AUTHOR

Jeffrey T. Palmer <jtpalmer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jeffrey T. Palmer.

This is free software, licensed under:

  The MIT (X11) License

=cut


__END__


