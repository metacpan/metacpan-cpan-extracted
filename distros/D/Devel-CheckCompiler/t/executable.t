use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp;

use Devel::CheckCompiler;

my $check;
my $extra_linker_flags;

my $code = <<'...';
int main(void)
{
    return maybe_not_defined_function12345678(0);
}
...

subtest 'generate only object file' => sub {
    my $tmpobj = File::Temp->new;
    make_stub($tmpobj->filename);
    ok(check_compile($code) && $check == 1);
};

subtest 'generate executable file' => sub {
    my $tmpobj = File::Temp->new;
    my $tmpexe = File::Temp->new;
    make_stub($tmpobj->filename, $tmpexe->filename);
    ok(check_compile($code, executable => 1) && $check == 2);
};

subtest 'generate executable file with linker option' => sub {
    my $tmpobj = File::Temp->new;
    my $tmpexe = File::Temp->new;
    make_stub($tmpobj->filename, $tmpexe->filename);
    ok(check_compile($code, executable => 1, extra_linker_flags => '-lm')
           && ($check == 2 && $extra_linker_flags eq '-lm'));
};

done_testing;

sub make_stub {
    my ($obj, $exe) = @_;

    no warnings 'redefine';
    no warnings 'once';
    *ExtUtils::CBuilder::new = sub { $check = 0; bless {}, shift };
    *ExtUtils::CBuilder::have_compiler = sub { 1 };
    *ExtUtils::CBuilder::compile = sub { $check = 1; $obj ? $obj : undef };
    *ExtUtils::CBuilder::link_executable = sub {
        my (undef, %args) = @_;
        $check = 2;
        $extra_linker_flags = $args{extra_linker_flags} || '';
        $exe ? $exe : undef;
    };
}

