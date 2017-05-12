use utf8;
use strict;
use Test::More tests => 29;
use File::Spec;
use File::Basename;

BEGIN { use_ok( 'Encode' ); use_ok( 'Encode::CNMap' ); }

my $path = dirname($0);
my ( $data_utf8, $data_gb, $data_ugb, $data_gbk, $data_gbk2, $data_b5, $data_ub5 );

&setenv; is( simp_to_gb(		$data_gb  ), $data_gb,	'GB  ->GB'	);
&setenv; is( simp_to_b5(		$data_gb  ), $data_b5,	'GB  ->Big5');
&setenv; is( simp_to_utf8(		$data_gb  ), $data_ugb,	'GB  ->utf8');
&setenv; is( simp_to_simputf8(	$data_gb  ), $data_ugb,	'GB  ->simp utf8');
&setenv; is( simp_to_tradutf8(	$data_gb  ), $data_ub5,	'GB  ->trad utf8');

&setenv; is( simp_to_gb(		$data_gbk ), $data_gb,	'GBK ->GB'	);
&setenv; is( simp_to_b5(		$data_gbk ), $data_b5,	'GBK ->Big5');
&setenv; is( simp_to_utf8(		$data_gbk ), $data_utf8,'GBK ->utf8');
&setenv; is( simp_to_simputf8(	$data_gbk ), $data_ugb,	'GBK ->simp utf8');
&setenv; is( simp_to_tradutf8(	$data_gbk ), $data_ub5,	'GBK ->trad utf8');

&setenv; is( trad_to_gb(		$data_b5  ), $data_gb,	'Big5->GB'	);
&setenv; is( trad_to_gbk(		$data_b5  ), $data_gbk2,'Big5->GBK'	);
&setenv; is( trad_to_utf8(		$data_b5  ), $data_ub5, 'Big5->utf8');
&setenv; is( trad_to_simputf8(	$data_b5  ), $data_ugb,	'Big5->simp utf8');
&setenv; is( trad_to_tradutf8(	$data_b5  ), $data_ub5,	'Big5->trad utf8');

&setenv; is( utf8_to_gb(		$data_utf8), $data_gb,  'utf8-> GB'	);
&setenv; is( utf8_to_gbk(		$data_utf8), $data_gbk, 'utf8-> GBK');
&setenv; is( utf8_to_b5(		$data_utf8), $data_b5,  'utf8-> Big5');
&setenv; is( utf8_to_utf8(		$data_utf8), $data_utf8,'utf8->utf8');
&setenv; is( utf8_to_simputf8(	$data_utf8), $data_ugb, 'utf8->simp utf8');
&setenv; is( utf8_to_tradutf8(	$data_utf8), $data_ub5, 'utf8->trad utf8');

is(simp_to_gb(_('zhengqi.gbk')), _('zhengqi.gb'), 'File GBK ->GB');
is(simp_to_b5(_('zhengqi.gbk')), _('zhengqi.b5'), 'File GBK ->Big5');

is(simp_to_gb(_('zhengqi.gb')), _('zhengqi.gb'), 'GB File->GB');
is(simp_to_b5(_('zhengqi.gb')), _('zheng_gb.b5'), 'GB File->Big5');

is(trad_to_gb(_('zhengqi.b5')), _('zhengqi.gb'), 'Big5 File->GB');
is(trad_to_gbk(_('zhengqi.b5')), _('zhengqi.gbk'), 'Big5 File->GBK');

sub _ { local $/; open _, "<:raw", File::Spec->catfile($path, $_[0]); return <_> }
sub setenv {
	$data_utf8  = "中華中华";
	$data_gb    = Encode::encode( "gb2312", "中华中华" );
	$data_ugb   = "中华中华";
	$data_gbk   = Encode::encode( "gbk",    "中華中华" );
	$data_gbk2  = Encode::encode( "gbk",    "中華中華" );
	$data_ub5   = "中華中華";
	$data_b5    = Encode::encode( "big5",   "中華中華" );
}