use lib -e 't' ? 't' : 'test';
use Test::More;
use Test;

my $home = cwd;
chdir(-e 't' ? 't' : 'test') or die;
my $t = cwd;

set_env_min();
my $label = "use Devel::Local;";
my $expected_path = join($sep, "$t/aaa/bin", "$t/bbb/bin", '|', $ENV{PATH});
my $expected_perl5lib = join($sep, "$t/aaa/lib", "$t/ccc/lib", '|');
do {
    test($label,
        sub {
            eval "use Devel::Local; 1" or die $@;
            (($ENV{PERL5LIB} = join $sep, @INC)) =~ s/(?<=\:\|):.*//;
        },
        $expected_path,
        $expected_perl5lib,
    );
    $label .= " (2nd time)";
} for 1..2;

set_env_min();
test("perl -MDevel::Local::ENVVAR ...",
    sub {
        $ENV{PATH} = `$^X -I../lib -MDevel::Local::PATH`;
        $ENV{PERL5LIB} = `$^X -I../lib -MDevel::Local::PERL5LIB`;
    },
    $expected_path,
    $expected_perl5lib,
);

# TODO Fix this test. 2014-08-13
# chdir $home or die;
# set_env_min();
# {
#     local $ENV{HOME} = $t;
#     test('use Devel::Local; # With $HOME/.perl-devel-local',
#         sub {
#             eval "use Devel::Local; 1" or die $@;
#             (($ENV{PERL5LIB} = join $sep, @INC)) =~ s/(?<=\:\|):.*//;
#         },
#         join($sep, "$t/bbb/bin", '|', $ENV{PATH}),
#         join($sep, "$t/ccc/lib", '|'),
#     );
# }

set_env_min();
my $path1 = $ENV{PATH};
test("use Devel::Local '$t/*';",
    sub {
        $ENV{PATH} = `$^X -I../lib -MDevel::Local::PATH -e1 '$t/*'`;
        $ENV{PERL5LIB} = `$^X -I../lib -MDevel::Local::PERL5LIB -e1 '$t/*'`;
    },
    $expected_path,
    $expected_perl5lib,
);
eval "use Devel::Local '!'; 1" or die $@;
is $ENV{PATH}, $path1, 'PATH reset works';

done_testing;

#------------------------------------------------------------------------------#
sub test {
    my ($label, $callback, $expected_path, $expected_perl5lib) = @_;
    $ENV{PERL_DEVEL_LOCAL_QUIET} = 1;
    &$callback();

    is $ENV{PATH}, $expected_path, "$label - PATH works";
    is $ENV{PERL5LIB}, $expected_perl5lib, "$label - PERL5LIB works";
}
