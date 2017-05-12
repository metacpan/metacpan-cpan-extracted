use strict; # -*-cperl-*-*
use warnings;

use Test::More tests => 63;
use Test::Exception;

BEGIN { use_ok( 'LCFG::Build::PkgSpec' ); }

my $spec = LCFG::Build::PkgSpec->new( name => 'foo', version => '0.0.1' );

is( $spec->version(), '0.0.1', 'version accessor' );

is( $spec->get_major, '0', 'version, major-part accessor' );

is( $spec->get_minor, '0', 'version, minor-part accessor' );

is( $spec->get_micro, '1', 'version, micro-part accessor' );

isnt( $spec->date(), undef, 'date should have a default value' );

my $date = $spec->date();
sleep 1; # guarantee a new time
$spec->update_date();

isnt( $date, $spec->date(), 'date has been updated' );

# smallest update

$date = $spec->date();
sleep 1; # guarantee a new time
$spec->update_micro();

isnt( $date, $spec->date(), 'date has been updated' );

is( $spec->version(), '0.0.2', 'Smallest version update' );
is( $spec->release(), '1', 'release accessor' );

# minor update

$date = $spec->date();
sleep 1; # guarantee a new time
$spec->update_minor();

isnt( $date, $spec->date(), 'date has been updated' );

is( $spec->version(), '0.1.0', 'Minor version update' );
is( $spec->release(), '1', 'release accessor' );

is( $spec->get_major, '0', 'version, major-part accessor' );

is( $spec->get_minor, '1', 'version, minor-part accessor' );

is( $spec->get_micro, '0', 'version, micro-part accessor' );

# major update

$date = $spec->date();
sleep 1; # guarantee a new time
$spec->update_major();

isnt( $date, $spec->date(), 'date has been updated' );

is( $spec->version(), '1.0.0', 'Major version update' );
is( $spec->release(), '1', 'release accessor' );

is( $spec->get_major, '1', 'version, major-part accessor' );

is( $spec->get_minor, '0', 'version, minor-part accessor' );

is( $spec->get_micro, '0', 'version, micro-part accessor' );

# dev versions

$spec->version('1.0.0_dev');
is( $spec->version, '1.0.0_dev', 'set dev version' );

# development versions, micro update

$spec->version('1.0.0_dev');
$spec->release('2');
$spec->update_micro();
is( $spec->version(), '1.0.1', 'dev version, smallest version update' );
is( $spec->release(), '1', 'dev version, release accessor' );

is( $spec->get_major, '1', 'version, major-part accessor' );

is( $spec->get_minor, '0', 'version, minor-part accessor' );

is( $spec->get_micro, '1', 'version, micro-part accessor' );

# development versions, minor update

$spec->version('1.0.0_dev');
$spec->release('2');
$spec->update_minor();
is( $spec->version(), '1.1.0', 'dev version, minor version update' );
is( $spec->release(), '1', 'dev version, release accessor' );

is( $spec->get_major, '1', 'version, major-part accessor' );

is( $spec->get_minor, '1', 'version, minor-part accessor' );

is( $spec->get_micro, '0', 'version, micro-part accessor' );

# development versions, major update

$spec->version('1.0.0_dev');
$spec->release('2');
$spec->update_major();
is( $spec->version(), '2.0.0', 'dev version, major version update' );
is( $spec->release(), '1', 'dev version, release accessor' );

is( $spec->get_major, '2', 'version, major-part accessor' );

is( $spec->get_minor, '0', 'version, minor-part accessor' );

is( $spec->get_micro, '0', 'version, micro-part accessor' );

# And again, with feeling...

# smallest update

$spec->version('1.0.0');
$spec->release('2.foo.1');
$spec->update_micro();

is( $spec->version(), '1.0.1', 'Smallest version update' );
is( $spec->release(), '1.foo.1', 'release accessor' );

# minor update

$spec->release('2.foo.1');
$spec->update_minor();

is( $spec->version(), '1.1.0', 'Minor version update' );
is( $spec->release(), '1.foo.1', 'release accessor' );

# major update

$spec->release('2.foo.1');
$spec->update_major();

is( $spec->version(), '2.0.0', 'Major version update' );
is( $spec->release(), '1.foo.1', 'release accessor' );

# release is undef

$spec->release(undef);
$spec->update_micro();
is( $spec->release(), '1', 'micro update after release is undef' );

my ( $ver_before, $rel_before ) = ( $spec->version, $spec->release );

$date = $spec->date();
sleep 1; # guarantee a new time

throws_ok { $spec->_update_version('willdie') } qr/^Unknown version update-type: willdie/, 'version update handler';

is( $spec->version, $ver_before, 'version unchanged' );

is( $spec->release, $rel_before, 'release unchanged' );

is( $date, $spec->date(), 'date is unchanged' );

throws_ok { $spec->version(undef) } qr/^Attribute \(version\) does not pass the type constraint because: Version string \(undef\) does not match the expected LCFG format\./, 'Avoid bad version numbers (undef)';

throws_ok { $spec->version('') } qr/^Attribute \(version\) does not pass the type constraint because: Version string \(.*\) does not match the expected LCFG format/, 'Avoid bad version numbers (empty string)';

throws_ok { $spec->version(0.1) } qr/^Attribute \(version\) does not pass the type constraint because: Version string \(.*\) does not match the expected LCFG format/, 'Avoid bad version numbers (0.1)';

throws_ok { $spec->version('0.1.2.3') } qr/^Attribute \(version\) does not pass the type constraint because: Version string \(.*\) does not match the expected LCFG format/, 'Avoid bad version numbers (0.1.2.3)';

throws_ok { $spec->version('1.2.foo') } qr/^Attribute \(version\) does not pass the type constraint because: Version string \(.*\) does not match the expected LCFG format/, 'Avoid bad version numbers (1.2.foo)';

throws_ok { $spec->release('') } qr/^Attribute \(release\) does not pass the type constraint because:/, 'Avoid bad release numbers (empty string)';

throws_ok { $spec->release('foo.2') } qr/^Attribute \(release\) does not pass the type constraint because:/, 'Avoid bad release numbers (foo.2)';

$spec->release(undef);

$spec->update_release;

is( $spec->release, 1, 'release incremented from undef');

$spec->release(0);

$spec->update_release;

is( $spec->release, 1, 'release incremented from zero');

$spec->release(2);

$spec->update_release;

is( $spec->release, 3, 'release incremented from 2');

$spec->version('1.2.3');
$spec->release(1);

$spec->dev_version;

is( $spec->version, '1.2.3_dev', 'create a devel version');
is( $spec->release, 2, 'release incremented for devel version');

$spec->version('1.2.3_dev');

$spec->dev_version;

is( $spec->version, '1.2.3_dev', 'update a devel version');
is( $spec->release, 3, 'release incremented for devel version');
