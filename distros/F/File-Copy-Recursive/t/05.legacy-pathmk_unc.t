use strict;
use warnings;

use Cwd;
use File::Copy::Recursive qw(pathmk pathempty);
use File::Temp ();
use Path::Tiny;
use Test::More;

if ( $^O ne 'MSWin32' ) {
    plan skip_all => 'Test irrelevant on non-windows OSs';
}
else {
    plan tests => 6;
}

diag("Testing legacy File::Copy::Recursive::pathmk() $File::Copy::Recursive::VERSION");

is( _translate_to_unc('C:/foo/bar.txt'),   '//127.0.0.1/C$/foo/bar.txt',      'sanity check: _translate_to_unc w/ /' );
is( _translate_to_unc('C:\\foo\\bar.txt'), '\\\\127.0.0.1\\C$\\foo\\bar.txt', 'sanity check: _translate_to_unc w/ \\' );

my $tempdir = File::Temp->newdir();

my @members = _all_files_in($tempdir);
is_deeply( \@members, [], 'sanity check: created empty temp dir' );

pathmk("$tempdir\\foo\\bar\\baz");    # create regular path

@members = _all_files_in($tempdir);
ok( -d "$tempdir\\foo\\bar\\baz", "pathmk(regular path) creates path" );

pathempty($tempdir);

@members = _all_files_in($tempdir);
is_deeply( \@members, [], 'sanity check: temp dir empty again' );

my $uncpath = _translate_to_unc($tempdir);

pathmk("$uncpath\\foo\\bar\\baz");    # create UNC path

@members = _all_files_in($tempdir);
ok( -d "$tempdir\\foo\\bar\\baz", "pathmk(unc path) creates path" );

###############
#### helpers ##
###############

sub _all_files_in {
    my $dir   = shift;
    my $state = path($dir)->visit(
        sub {
            my ( $path, $state ) = @_;
            push @{ $state->{files} }, $path;
        },
        { recurse => 1 },
    );
    return map { "$_" } @{ $state->{files} || [] };
}

sub _translate_to_unc {
    my ($path) = @_;
    die "Should be called on Windows only!" unless $^O eq 'MSWin32';
    if ( $path =~ m|^\w:([/\\])| ) {

        # an absolute path with a Windows-style drive letter
        my $sep = $1;

        # C:\path\foo.txt corresponds to \\127.0.0.1\C$\path\foo.txt (if \
        # is regarded as a regular character, not an escape character).
        # Prefix UNC part, using path separator from original
        $path =~ s|^(\w):|$sep${sep}127.0.0.1${sep}$1\$|;
    }
    else {
        # a relative path
        my ($sep) = $path =~ m|([\\/])|;    # locate path separator
        $sep ||= '\\';                      # default to backslash
        $path = translate_to_unc( Cwd::getcwd() . $sep . $path );

        # assumes that Cwd::getcwd() returns a path with a drive letter!
    }
    $path;
}
