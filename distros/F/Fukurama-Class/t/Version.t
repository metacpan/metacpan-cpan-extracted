#!perl -T
use Test::More tests => 14;
use strict;
use warnings;

{
	package MyClass;
	use Fukurama::Class::Version(100);
	
	main::is($MyClass::VERSION, 100, 'version is set at runtime');
	
	BEGIN {
		main::is($MyClass::VERSION, 100, 'version is set at BEGIN');
	}
	$MyClass::VERSION = undef;
	
	eval("use Fukurama::Class::Version('0.0_1')");
	main::is($@, '', 'no old extendet version error');
	main::is($MyClass::VERSION, '0.0_1', 'old extendet version is ok');
	$MyClass::VERSION = undef;
	
	eval("use Fukurama::Class::Version('0.0.1')");
	main::is($@, '', 'no extendet version error');
	main::is($MyClass::VERSION, '0.0.1', 'extendet version is ok');
	$MyClass::VERSION = undef;
	
	eval("use Fukurama::Class::Version('0.01.')");
	main::like($@, qr/non-decimal/, 'numer-error');
	main::is($MyClass::VERSION, undef, 'version is undef');
	
	eval("use Fukurama::Class::Version(undef)");
	main::like($@, qr/undefined/, 'numer-error');
	main::is($MyClass::VERSION, undef, 'version is undef');
	
	eval("use Fukurama::Class::Version('1')");
	main::is($@, '', 'correct version');
	main::is($MyClass::VERSION, 1, 'version is set');
	
	eval("Fukurama::Class::Version->version('" . __PACKAGE__ . "', '1.8')");
	main::is($@, '', 'correct version');
	main::is($MyClass::VERSION, 1.8, 'version is set');
}