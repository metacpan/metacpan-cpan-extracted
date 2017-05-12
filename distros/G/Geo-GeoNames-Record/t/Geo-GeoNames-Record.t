use Test::More tests => 8;

use utf8;

use File::Spec;
use File::HomeDir;

BEGIN
{ 
  use_ok('Geo::GeoNames::Record');
}

my $geoname_line = q{1816670	Beijing	Beijing	BJS,Baekging,Beijing,Beijing - Pekin,Beijing - 北京,Beijing Shi,Beising,Béising,Bắc Kinh,Pechino,Pechinu,Pechinum,Pecinum,Pei-ching,Pei-ching-shih,Pei-p'ing,Pei-p'ing-shih,Pekin,Pekina,Pekinas,Peking,Pekino,Pekín,Pekîn,Peping,Pequim,Pequin,Pequín,Pékin,Πεκίνο,Пекин,Пекинг,בייג'ינג,بكين,بېيجىڭ,بېيجىڭ شەھىرى,बेइजिन्ग,বেইজিং,பீஜிங்,ปักกิ่ง,პეკინი,北京,北京市,베이징,북경	39.9074977414405	116.397228240967	P	PPLC	CN		22				7480601		63	Asia/Harbin	2008-10-31};

my $record = Geo::GeoNames::Record->new( $geoname_line );

is( $record->as_string(), $geoname_line, "as_string()" );

ok( $record eq $record, "op_eq()" );

ok( $record->has_name("Beijing"), "has_name()");
ok( $record->has_name("北京"),   "has_name()" ); # utf-8
ok( !$record->has_name("New York"), "has_name()" );

SKIP: {
  skip("Admins not loaded.", 2) 
    unless -e File::Spec->catfile( File::HomeDir->my_home(),
				   '.Geo-GeoNames-Record',
				   'admin_code_to_record.hash' );

  ok( $record->country()->has_name("China"), "country()" );
  ok( $record->admin1()->has_name("Beijing Shi"), "admin1()" );
}
