use Test::More tests => 5;
use strict;
use warnings;

use Gapp;
use GappX::FormTraits;

my $e;

$e = Gapp::Entry->new( traits => [qw( CityEntry )] );
is $e->gobject->get_width_chars, 25, 'city width chars set';

$e = Gapp::Entry->new( traits => [qw( EmailEntry )] );
is $e->gobject->get_width_chars,  60, 'email address width chars set';

$e = Gapp::Entry->new( traits => [qw( StateEntry )] );
is $e->gobject->get_width_chars, 2, 'state width chars set';

$e = Gapp::Entry->new( traits => [qw( StreetEntry )] );
is $e->gobject->get_width_chars, 35, 'address width chars set';

$e = Gapp::Entry->new( traits => [qw( ZipCodeEntry )] );
is $e->gobject->get_width_chars, 5, 'zip code width chars set';

