use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp;

my $exit_status;
BEGIN {
    *CORE::GLOBAL::exit = sub { $exit_status = $_[0] };
}

use Devel::CheckCompiler;

my $tmp = File::Temp->new;

subtest 'c99 is not available' => sub {
    undef $exit_status;
    make_stub(0, 0);
    check_c99_or_exit();
    is($exit_status, 0);
};

subtest 'c99 is available' => sub {
    undef $exit_status;
    make_stub(1, 1);
    check_c99_or_exit();
    is($exit_status, undef);
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
