use strict;
$^W = 1;

use Test::More;
END { done_testing }

use Devel::CheckOS;

eval { Devel::CheckOS::list_family_members() };
ok($@, 'list_family_members() is fatal');

is_deeply(
    scalar(Devel::CheckOS::list_family_members('Cygwin')), [],
    'list_family_members($not_a_family) gives an empty list'
);

is_deeply(
    [sort(&Devel::CheckOS::list_family_members('Linux'))],
    [sort(qw(Android Linux))],
    'Linux family includes both Linux and Android'
);

is_deeply(
    [(Devel::CheckOS::list_family_members('DEC'))],
    [qw(OSF VMS)],
    'array list_family_members works for DEC family'
);
is_deeply(
    scalar(Devel::CheckOS::list_family_members('DEC')),
    [qw(OSF VMS)],
    'scalar list_family_members works for DEC family'
);
is_deeply(
    scalar(Devel::CheckOS::list_family_members('MicrosoftWindows')),
    [qw(Cygwin MSWin32 MSYS)],
    'scalar list_family_members works for MicrosoftWindows family'
);
