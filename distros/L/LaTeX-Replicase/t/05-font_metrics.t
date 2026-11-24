# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 05-font_metrics.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 15;
use Test::More::UTF8;
use Test::Exception;
use Test::Warn;
use Storable qw(nstore retrieve);
use Data::Dumper;

# Подключаем Test::File::ShareDir ДО загрузки модуля
use Test::File::ShareDir
    -share => {
#        -dist   => { 'LaTeX-Replicase' => 'share' },
        -module => { 'LaTeX::Replicase' => 'share' },
    };

### Test 1.1
BEGIN { use_ok('LaTeX::Replicase') };
use LaTeX::Replicase qw(font_metrics); # :all

use File::ShareDir qw(module_file); # dist_file

##### Test font_metrics() #####

### Test 2.0
my $font_metrics;

throws_ok {
	$font_metrics = &font_metrics('t/blah-blah.afm', {} );
} qr/Can\'t find the AFM file:/, 'Checked croak for Test #2.0';

is( $font_metrics, undef, "Test #2.0: 'font_metrics()' returns undef for BAD 'AFMfile' parameter");
undef $font_metrics;


### Test 2.1
my $AFMfile = 't/PTC55F.afm';

my $op = { }; # glyphlist =>$glyphlist, noBbox =>1, noKPX =>1, mate =>'symbol'|'glyph'|'hex'

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

my $dump = 't/PTC55F_undef.dump'; # Decimal Unicode
my $font_metrics_ref = retrieve $dump;

is_deeply( $font_metrics, $font_metrics_ref, "Test #2.1: EMPTY option for '$dump' -- Decimal Unicode");

### Test 2.2
$op->{noBbox} = 1;

warnings_exist {
	$font_metrics = &font_metrics( $AFMfile, $op );
} $msgs, 'Checked carp warning for Test #2.2';

delete $font_metrics_ref->{Bbox};

is_deeply( $font_metrics, $font_metrics_ref, "Test #2.2: { noBbox =>1 } option for '$dump'");

### Test 2.3
$op->{noKPX} = 1;

warnings_exist {
	$font_metrics = &font_metrics( $AFMfile, $op );
} $msgs, 'Checked carp warning for Test #2.3';

delete $font_metrics_ref->{KPX};

is_deeply( $font_metrics, $font_metrics_ref, "Test #2.3: { noBbox =>1, noKPX =>1 } options for '$dump'");

### Test 3
$op = { mate =>'glyph'}; # glyphlist =>$glyphlist, noBbox =>1, noKPX =>1, mate =>'symbol'|'glyph'|'hex'

warnings_are {
	$font_metrics = &font_metrics( $AFMfile, $op );
} [], 'Checked carp warning for Test #3';

$dump = 't/PTC55F_glyph.dump';
$font_metrics_ref = retrieve $dump;

is_deeply( $font_metrics, $font_metrics_ref, "Test #3: { mate =>'glyph'} option for '$dump'");


### Test 4
$op->{mate} = 'symbol'; # mate =>'glyph'|'hex'

warnings_exist {
	$font_metrics = &font_metrics( $AFMfile, $op );
} $msgs, 'Checked carp warning for Test #4';

$dump = 't/PTC55F_undef.dump'; # Decimal Unicode
$font_metrics_ref = retrieve $dump;

# Conver decimal to-> symbol
my $font_metrics_symbol_ref = {};
for('Bbox','WX') {
	while( my($k, $v) = each %{ $font_metrics_ref->{$_} } ) {
		$font_metrics_symbol_ref->{$_}{ chr($k) } = $v;
	}
}

while( my($k, $v) = each %{ $font_metrics_ref->{KPX} } ) {
	while( my($sk, $sv) = each %$v ) {
		$font_metrics_symbol_ref->{KPX}{ chr($k) }{ chr($sk) } = $sv;
	}
}

is_deeply( $font_metrics, $font_metrics_symbol_ref, "Test #4: { mate =>'symbol'} options");
undef $font_metrics_symbol_ref;

### Test 5
$op->{mate} = 'hex';

warnings_exist {
	$font_metrics = &font_metrics( $AFMfile, $op );
} $msgs, 'Checked carp warning for Test #5';

# Conver decimal to-> hex
my $font_metrics_hex_ref = {};
for('Bbox','WX') {
	while( my($k, $v) = each %{ $font_metrics_ref->{$_} } ) {
		my $kh = sprintf("%04X", $k);
		$font_metrics_hex_ref->{$_}{ $kh } = $v;
	}
}

while( my($k, $v) = each %{ $font_metrics_ref->{KPX} } ) {
	my $kh = sprintf("%04X", $k);

	while( my($sk, $sv) = each %$v ) {
		my $skh = sprintf("%04X", $sk);
		$font_metrics_hex_ref->{KPX}{ $kh }{ $skh } = $sv;
	}
}

is_deeply( $font_metrics, $font_metrics_hex_ref, "Test #5: { mate =>'hex'} option");

###DEL###
# open F, ">test.log";
# print F Dumper($font_metrics, $font_metrics_hex_ref);
# close F;
# exit;
