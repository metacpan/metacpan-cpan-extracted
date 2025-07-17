use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use File::Temp 'tempfile';

test_for_zlib ();

my $pm = 'lib/Gzip/Faster.pm';
my $pod = 'lib/Gzip/Faster.pod';
my $github = 'github.com/benkasminbullock/gzip-faster';
my $repo = "https://$github";

WriteMakefile (
    NAME => 'Gzip::Faster',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <benkasminbullock@gmail.com>',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
    META_MERGE => {
	'meta-spec' => {
	    version => 2,
	},
        resources => {
            repository => {
		type => 'git',
		url => "git://$github.git",
		web => $repo,
	    },
            bugtracker => {
		web => "$repo/issues",
	    },
#	    homepage => 'http://',
        },
	x_contributors => [
	    'Aristotle Pagaltzis <aristotle@cpan.org>',
	    'zgrim <zgrim@cpan.org>',
	],
    },
    MIN_PERL_VERSION => '5.008001',
    OBJECT => 'Faster.o',
    LIBS => '-lz',
#    OPTIMIZE => '-Wall -g -O',
);

exit;

# Test for zlib. If zlib doesn't seem to be present, die.

sub test_for_zlib
{
    my $c = <<'EOF';
#include <zlib.h>
#include <stdio.h>
int main (void) {
    printf ("%s\n", zlibVersion ());
    return 0;
}
EOF
    my ($fh, $filename) = tempfile ("tempXXXXXX");
    print $fh $c;
    close $fh or die "Can't close $filename: $!";
    my $cfilename = "$filename.c";
    rename $filename, $cfilename
        or die "Can't rename $filename to $cfilename: $!";
    my $status = system ("$Config{cc} -o $filename $cfilename -lz");
    if ($status != 0) {
	unlink $cfilename, $filename;
	die "You don't seem to have zlib available on your system.";
    }
    unlink $cfilename or warn "Could not delete temp file $cfilename";
    unlink $filename or warn "Could not delete temp file $filename";

    # OK
}
