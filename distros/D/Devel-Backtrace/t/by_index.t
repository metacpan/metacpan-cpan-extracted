#!perl

use Test::More tests => 2;

use Devel::Backtrace;

sub get_caller_index {
    my $idx = shift;
    my $bt = Devel::Backtrace->new;
    return $bt->point(1)->by_index($idx);
}

my $sub = get_caller_index(3); # 3 is subroutine
is($sub, 'main::get_caller_index', 'field 3');

eval {
    get_caller_index(7000);
};
like($@, qr/There is no field with index 7000/, 'field 7000');
