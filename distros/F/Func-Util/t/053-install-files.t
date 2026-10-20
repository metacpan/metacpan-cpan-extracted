use strict;
use warnings;
use Test::More;
use File::Spec;

# The headers a dependent XS dist builds against, and the ExtUtils::Depends
# configuration that tells it where they are.
require_ok 'Func::Util::Install::Files';
my $dir = File::Spec->catdir((File::Spec->splitpath($INC{'Func/Util/Install/Files.pm'}))[0, 1]);
for my $h (qw(funcutil_callbacks.h funcutil_export.h)) {
    ok -f File::Spec->catfile($dir, $h), "$h is installed beside the configuration";
}
SKIP: {
    skip 'ExtUtils::Depends is not installed', 1 unless eval { require ExtUtils::Depends; 1 };
    my %vars = ExtUtils::Depends->new('My::Consumer', 'Func::Util')->get_makefile_vars;
    like $vars{INC}, qr/\Q$dir\E/, 'a dependent\'s ExtUtils::Depends puts that directory on its include path';
}

done_testing;
