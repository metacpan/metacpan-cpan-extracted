use strict;
use warnings;

use Test::More tests => 7;

BEGIN { use_ok('Keystone', ':all'); }

my $ks;
my @ins;

# 32 bits mode
ok($ks = Keystone->new(KS_ARCH_X86, KS_MODE_32));

ok(@ins = $ks->asm("int 0x80; ret"));

ok(join(" ", map{sprintf "%.2x", $_} @ins) eq 'cd 80 c3');


# 64 bits mode
ok($ks = Keystone->new(KS_ARCH_X86, KS_MODE_64));

ok(@ins = $ks->asm("mov rdx, rdi; int 0x80; inc rdx; mov eax, 0x12345678"));

ok(join(" ", map{sprintf "%.2x", $_} @ins) eq '48 89 fa cd 80 48 ff c2 b8 78 56 34 12');
