# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 05-font_metrics.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 13;
use Test::More::UTF8;
use Test::Warn;
use Storable qw(nstore retrieve);

BEGIN { use_ok('LaTeX::Replicase') }; ### Test 1
use LaTeX::Replicase qw(font_metrics); # :all

##### Test font_metrics() #####

### Test 2.1
my $AFMfile = 't/PTC55F.afm';
my $glyphlist = 't/glyphlist.txt';

my $op = {glyphlist =>$glyphlist }; # , noBbox =>1, noKPX =>1, mate =>'symbol'|'glyph'|'hex'
my $font_metrics;

my $msg = 'Undefined glyph:';
my $msgs = [
	qr/$msg 'afii10055.alt'/,
	qr/$msg 'afii10103.alt'/,
	qr/$msg 'caron.l'/,
	qr/$msg 'fraction.alt'/,
	qr/$msg 'l.var'/,
	qr/$msg 'one.numerator'/,
];

warnings_exist {
	$font_metrics = &font_metrics( $AFMfile, $op );
} $msgs, 'Checked carp warning for Test #2.1';

my $dump = 't/PTC55F_undef.dump';
my $font_metrics_ref = retrieve $dump;

is_deeply( $font_metrics, $font_metrics_ref, "Test #2.1: { glyphlist =>$glyphlist } options for '$dump'");

### Test 2.2
$op->{noBbox} = 1;

warnings_exist {
	$font_metrics = &font_metrics( $AFMfile, $op );
} $msgs, 'Checked carp warning for Test #2.2';

delete $font_metrics_ref->{Bbox};

is_deeply( $font_metrics, $font_metrics_ref, "Test #2.2: { glyphlist =>$glyphlist, noBbox =>1 } options for '$dump'");

### Test 2.3
$op->{noKPX} = 1;

warnings_exist {
	$font_metrics = &font_metrics( $AFMfile, $op );
} $msgs, 'Checked carp warning for Test #2.3';

delete $font_metrics_ref->{KPX};

is_deeply( $font_metrics, $font_metrics_ref, "Test #2.3: { glyphlist =>$glyphlist, noBbox =>1, noKPX =>1 } options for '$dump'");

### Test 3
$op = {glyphlist =>$glyphlist, mate =>'glyph'}; # , noBbox =>1, noKPX =>1, mate =>'symbol'|'glyph'|'hex'

warnings_are {
	$font_metrics = &font_metrics( $AFMfile, $op );
} [], 'Checked carp warning for Test #3';

$dump = 't/PTC55F_glyph.dump';
$font_metrics_ref = retrieve $dump;

is_deeply( $font_metrics, $font_metrics_ref, "Test #3: { glyphlist =>$glyphlist, mate =>'glyph'} options for '$dump'");

### Test 4
$op->{mate} = 'symbol'; # mate =>'glyph'|'hex'

warnings_exist {
	$font_metrics = &font_metrics( $AFMfile, $op );
} $msgs, 'Checked carp warning for Test #4';

$dump = 't/PTC55F_symbol.dump';
$font_metrics_ref = retrieve $dump;

is_deeply( $font_metrics, $font_metrics_ref, "Test #4: { glyphlist =>$glyphlist, mate =>'symbol'} options for '$dump'");

### Test 5
$op->{mate} = 'hex';

warnings_exist {
	$font_metrics = &font_metrics( $AFMfile, $op );
} $msgs, 'Checked carp warning for Test #5';

$dump = 't/PTC55F_hex.dump';
$font_metrics_ref = retrieve $dump;

is_deeply( $font_metrics, $font_metrics_ref, "Test #5: { glyphlist =>$glyphlist, mate =>'hex'} options for '$dump'");

