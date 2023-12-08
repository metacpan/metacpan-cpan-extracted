#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

# Lists
# https://proj.org/development/reference/functions.html#lists

plan tests => 4 + 6 + 6 + 6 + 4 + $no_warnings;

use Geo::LibProj::FFI qw( :all );


my ($list, @e);


# proj_list_operations

lives_ok { $list = proj_list_operations() } 'list_operations';
ok scalar @$list > 1, 'list_operations multiple';
@e = grep {$_->{id} eq 'noop'} @$list;
ok @e, 'list_operations id noop';
like ${$e[0]->{descr}}, qr/\bNo operation\b/i, 'list_operations descr';

# proj_list_ellps

lives_ok { $list = proj_list_ellps() } 'list_ellps';
ok scalar @$list > 1, 'list_ellps multiple';
@e = grep {$_->{id} eq 'intl'} @$list;
ok @e, 'list_ellps id intl';
like $e[0]->{name}, qr/\bHayford\b/i, 'list_ellps name';
like $e[0]->{major}, qr/\b6378388\b/, 'list_ellps major';
like $e[0]->{ell}, qr/\b297\b/, 'list_ellps major';

# proj_list_units

lives_ok { $list = proj_list_units() } 'list_units';
ok scalar @$list > 1, 'list_units multiple';
@e = grep {$_->{id} eq 'm'} @$list;
ok @e, 'list_units id m';
like $e[0]->{name}, qr/\bMeter\b/i, 'list_units name';
is $e[0]->{to_meter}, "1", 'list_units to_meter';
is $e[0]->{factor}, 1, 'list_units factor';

# proj_list_angular_units

lives_ok { $list = proj_list_angular_units() } 'list_angular_units';
ok scalar @$list > 1, 'list_angular_units multiple';
@e = grep {$_->{id} eq 'deg'} @$list;
ok @e, 'list_angular_units id deg';
like $e[0]->{name}, qr/\bDegree\b/i, 'list_angular_units name';
like $e[0]->{to_meter}, qr/^0\.0174/, 'list_angular_units to_meter ballpark';
like $e[0]->{factor}, qr/^0\.0174/, 'list_angular_units factor ballpark';

# proj_list_prime_meridians

lives_ok { $list = proj_list_prime_meridians() } 'list_prime_meridians';
ok scalar @$list > 1, 'list_prime_meridians multiple';
@e = grep {$_->{id} eq 'greenwich'} @$list;
ok @e, 'list_prime_meridians id lonlat';
is $e[0]->{defn}, "0dE", 'list_prime_meridians defn';
# the PROJ docs actually say it's .def, not .defn


done_testing;
