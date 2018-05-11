#!perl

use local::lib;
use Cwd;
use File::Spec;
use Dist::Zilla::App;
use Test::More;

my $cwd = cwd;
my $libPath = File::Spec->catdir( cwd, "blib", "lib" );

require_ok('Dist::Zilla::Plugin::LocalHTML');
require_ok('Dist::Zilla::Plugin::LocalHTML::Pod2HTML');

sub dz_build {
    my $dir = shift;

    if (chdir File::Spec->catdir( "t", $dir )) {
    local @ARGV = qw<build>;
    $rc = Dist::Zilla::App->run;
    } else {
        fail("Cannot use $dir directory: " . $!);
    }
    
    # TODO: HTML needs to be compared.
}

dz_build('DZPL-Test-Module-_DUMMY');

done_testing;
