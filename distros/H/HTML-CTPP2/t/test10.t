# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-CTPP2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('HTML::CTPP2') };

use strict;
use MIME::Base64;
use IO::Scalar;

sub get_data
{
	my $data = 'Тест кодировки ';
	my $SH = new IO::Scalar \$data;
	$SH -> print('CP-1251');
return $SH; 
}

my $T = new HTML::CTPP2();
ok( ref $T eq "HTML::CTPP2", "Create object.");

my $Bytecode = $T -> parse_template("charset_recoder.tmpl");
ok( ref $Bytecode eq "HTML::CTPP2::Bytecode", "Create object.");

my $data = 'Тест кодировки ';
my $SH = new IO::Scalar \$data;
$SH -> print('CP-1251');

my %H = ("a" => &get_data());
ok( $T -> param(\%H) == 0);

ok( encode_base64($T -> dump_params()) eq "ewogICJhIiA9PiAi0uXx8iDq7uTo8O7i6uggQ1AtMTI1MSIKfQ==\n");

my $Result = encode_base64($T -> output($Bytecode));
ok( $Result eq "0uXx8jog0uXx8iDq7uTo8O7i6uggQ1AtMTI1MQo=\n");

$T -> reset();
