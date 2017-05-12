use Test::More   tests => 1;
use Devel::StealthDebug emit_type => 'croak';

eval {
	my $foo = 42;#!emit(croak ok)!
	print $foo++;
};

like($@,qr/croak ok/);
