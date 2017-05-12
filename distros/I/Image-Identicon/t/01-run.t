
use strict;
use warnings;
use Test::More tests => 6;
use Image::Identicon;

&test01_run;

sub test01_run
{
	diag("GD version $GD::VERSION");
	eval{ Image::Identicon->new(); };
	isnt( $@, '', "constructor need SALT" );
	my $identicon = Image::Identicon->new({ salt => "pepper" });
	isa_ok($identicon, "Image::Identicon");
	
	my $code = 1481252014;
	is($identicon->identicon_code("10.11.12.13"), $code, "identicon code 10.11.12.13 is $code");
	my $r = $identicon->render($code);
	isa_ok($r, 'HASH', "result of \$identicon->render");
	ok($r->{image}, "\$r->{image} exists");
	ok($r->{image}->png, "\$r->{image}->png returns something.");
}


