# -*- perl -*-

# t/004_when_creating_beads.t - test bead module

use strict;
use warnings;

use lib "t/lib";

use Test::More;

use Test::PNG;

use FuseBead::From::PNG;

use FuseBead::From::PNG::Bead;

use FuseBead::From::PNG::Const qw(:all);

# ----------------------------------------------------------------------

my $tests = 0;

should_die_if_invalid_color();

should_set_default_dimensions();

should_be_able_to_access_color();

should_be_able_to_set_color();

should_be_able_to_access_dimensions();

should_be_able_to_access_meta();

should_be_able_to_access_color_information();

done_testing( $tests );

exit;

# ----------------------------------------------------------------------

sub should_die_if_invalid_color {
    undef $@;
    my $bead = eval { FuseBead::From::PNG::Bead->new(color => 'NOTACOLOR') };

    my $has_error = defined $@ ? 1 : 0;
    cmp_ok($has_error, "==", 1, "Exception in ->new if setting invalid color");

    $bead = FuseBead::From::PNG::Bead->new(color => 'BLACK');

    undef $@;
    eval { $bead->color('NOTACOLOR') };

    $has_error = defined $@ ? 1 : 0;
    cmp_ok($has_error, "==", 1, "Exception in ->color if setting invalid color");

    $tests += 2;
}

sub should_set_default_dimensions {
    my $bead = FuseBead::From::PNG::Bead->new(color => 'BLACK');

    my $dimensions = {};
    @{$dimensions}{qw(diameter)} = @{$bead}{qw(diameter)};

    my $expected_dimensions = {
        diameter  => FuseBead::From::PNG::Const::BEAD_DIAMETER,
    };

    is_deeply($dimensions, $expected_dimensions, "Default dimensions are set");

    $tests++;
}

sub should_be_able_to_access_color {
    my $bead = FuseBead::From::PNG::Bead->new(color => 'BLACK');

    cmp_ok($bead->color, 'eq', 'BLACK', "Accessed color");

    $tests++;
}

sub should_be_able_to_set_color {
    my $bead = FuseBead::From::PNG::Bead->new(color => 'BLACK');

    $bead->color('WHITE');

    cmp_ok($bead->color, 'eq', 'WHITE', "Set color");

    $tests++;
}

sub should_be_able_to_access_dimensions {
    my $bead = FuseBead::From::PNG::Bead->new(color => 'BLACK', depth => 1, length => 2, height => 3);

    cmp_ok($bead->diameter, '==', FuseBead::From::PNG::Const::BEAD_DIAMETER, "Accessed diameter");

    $tests++;
}

sub should_be_able_to_access_meta {
    my $bead = FuseBead::From::PNG::Bead->new(color => 'BLACK', meta => {
        id    => 1,
        ara   => [],
        stuff => {},
    });

    my $expected = {
        id    => 1,
        ara   => [],
        stuff => {},
    };

    is_deeply($bead->meta, $expected, "Meta accessed");

    $tests++;
}

sub should_be_able_to_access_color_information {
    my $png = FuseBead::From::PNG->new();
    my $bead = FuseBead::From::PNG::Bead->new(color => 'BLACK');

    is_deeply($bead->color_info ,$png->bead_colors->{'BLACK'}, "Correct color information is returned");

    $tests++;
}
