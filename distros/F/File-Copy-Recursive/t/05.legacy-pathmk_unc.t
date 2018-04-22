use strict;
use warnings;

use Cwd;
use File::Copy::Recursive qw(pathmk pathempty);
use File::Temp ();
use Path::Tiny;
use Test::More;
use Test::Deep;

diag("Testing legacy File::Copy::Recursive::pathmk() $File::Copy::Recursive::VERSION");

sub translate_to_unc {
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

if ( $^O eq 'MSWin32' ) {

    # test translate_to_unc

    is(
        translate_to_unc('C:/foo/bar.txt'), '//127.0.0.1/C$/foo/bar.txt',
        'translate_to_unc /'
    );
    is(
        translate_to_unc('C:\\foo\\bar.txt'),
        '\\\\127.0.0.1\\C$\\foo\\bar.txt', 'translate_to_unc \\'
    );
}

my $tempdir = File::Temp->newdir();

my @members = _all_files_in($tempdir);
is_deeply( \@members, [], 'created empty temp dir' );

# create regular path
pathmk("$tempdir/foo/bar/baz");

@members = _all_files_in($tempdir);
cmp_deeply(
    \@members,
    bag("$tempdir/foo", "$tempdir/foo/bar", "$tempdir/foo/bar/baz"),
    'pathmk regular path'
);

pathempty($tempdir);

@members = _all_files_in($tempdir);
is_deeply( \@members, [], 'temp dir empty again' );

if ( $^O eq 'MSWin32' ) {
    my $uncpath = translate_to_unc($tempdir);

    # create UNC path
    pathmk("$uncpath/foo/bar/baz");

    @members = _all_files_in($tempdir);
    is_deeply(
        \@members,
        [
            $tempdir, "$tempdir/foo", "$tempdir/foo/bar",
            "$tempdir/foo/bar/baz"
        ],
        'pathmk unc'
    );
}

done_testing();

sub _all_files_in {
    my $dir = shift;
    my $state = path($dir)->visit(
        sub {
            my ($path, $state) = @_;
            push @{ $state->{files} }, $path;
        },
        { recurse => 1 },
    );
    return map { "$_" } @{ $state->{files} || [] };
}

# temp dir is deleted automatically when $tempdir goes out of scope
