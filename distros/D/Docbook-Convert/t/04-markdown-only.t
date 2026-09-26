use strict;
use warnings;
use Test::More;
use IPC::Run3 qw(run3);
use Docbook::Convert::Constant;

ok(!exists $HANDLER_HR->{'pod'}, 'POD handler retired');
ok(!-f 'bin/docbook2pod', 'POD command no longer shipped');
foreach my $option ('--pod', '--merge') {
    my ($out, $error);
    run3([$^X, '-Ilib', 'bin/docbook-convert', $option, 't/para.xml'], undef, \$out, \$error);
    ok($? != 0, "$option rejected");
    like($error, qr/Unknown option/, 'unsupported conversion fails explicitly');
}
done_testing();
