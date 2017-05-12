use Test::More tests => 2 + 1*2;
BEGIN { $^W = 1 }
use strict;

my $module;
BEGIN {
    $module = 'List::Extract';

    require_ok($module);
    use_ok($module, 'extract');
}

###############################################################################

{
    my @list = qw/ foo BAR baz /;
    my @extracted = extract { $_ = uc; /A/ } @list;
    is_deeply([ @extracted ], [qw/ BAR BAZ /]);
    is_deeply([ @list ], [qw/ foo /]);
}
