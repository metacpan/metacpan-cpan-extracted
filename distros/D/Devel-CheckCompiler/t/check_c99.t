use strict;
use warnings;
use utf8;
use Test::More;
use Devel::CheckCompiler;
use File::Temp;

my $tmp = File::Temp->new;

subtest 'failing case' => sub {
    make_stub(0, 0);
    ok(!check_c99());
    make_stub(0, 1);
    ok(!check_c99());
    make_stub(1, 0);
    ok(!check_c99());
};

subtest 'success case' => sub {
    make_stub(1, 1);
    ok(check_c99());
};

done_testing;

sub make_stub {
    my ($have_compiler, $compile) = @_;

    no warnings 'redefine';
    no warnings 'once';
    *ExtUtils::CBuilder::new = sub { bless {}, shift };
    *ExtUtils::CBuilder::have_compiler = sub { $have_compiler };
    *ExtUtils::CBuilder::compile = sub { $compile ? $tmp->filename : undef };
}
