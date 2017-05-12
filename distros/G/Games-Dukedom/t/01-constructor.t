#!perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;

use Games::Dukedom;

my $pkg = 'Games::Dukedom';

my $game = new_ok( $pkg => [], '$game' );

# check that class attributes are rejected in the constructor
for (qw( show_msg get_yn get_value signal )) {
    throws_ok(
        sub { $pkg->new( $_ => undef ) },
        qr/unknown attribute/,
        "initializer rejected for class attribute: $_"
    );
}

# check that public attributes marked as 'init_arg => undef' are rejected
for (
    qw( year population grain land land_fertility war yield unrest king_unrest black_D input status )
  )
{
    throws_ok(
        sub { $pkg->new( $_ => undef ) },
        qr/unknown attribute/,
        "initializer rejected for attribute: $_"
    );
}

# check that initializers for private attributes are rejected
for (qw( _base_values _population _grain _land _war _unrest _steps _msg )) {
    throws_ok(
        sub { $pkg->new( $_ => undef ) },
        qr/unknown attribute/,
        "initializer rejected for private attribute: $_"
    );
}

throws_ok(
    sub { $pkg->new( foo => 'bar' ) },
    qr/unknown attribute/,
    'unknown attribute rejected'
);

done_testing();

exit;

__END__

