use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Exception::Backtrace;

use lib 't';
use MyTest;

Exception::Backtrace::install();

plan skip_all => 'Sub::Name is need for this test' unless eval {
    require Sub::Name;
    Sub::Name->import;
    1;
};

my ($fn1, $fn2, $fn3);

$fn1 = subname("just_fn1" => sub {
    $fn2->();
});

$fn2 = subname("New::Package::just_fn2" => sub {
    $fn3->();
});

$fn3 = sub { Exception::Backtrace::create_backtrace()->perl_trace } ;

my $perl_trace = $fn1->();
note "sample: ", $perl_trace->to_string;

my $frames = $perl_trace->get_frames;
ok $frames;
is scalar(@$frames), 3;

my ($f1, $f2, $f3) = @$frames;
is $f1->name, '__ANON__';
is $f1->library, 'main';

is $f2->name, 'just_fn2';
is $f2->library, 'New::Package';

is $f3->name, 'just_fn1';
is $f3->library, 'main';

done_testing;
