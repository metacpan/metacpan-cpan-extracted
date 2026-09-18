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

# Stop the spew of errors if using Clang (FreeBSD) but don't add the
# options if not.

# On some Windows with what I assume are ageing gccs the -Wno
# .. things cause compilation failures as seen here:

# https://matrix.perl-magpie.org/results/7f0e1e90-6cc8-1014-ae5c-7ea4b03d33c9

my $is_clang = ($Config{cc} =~ /clang/i) || 
               ($Config{ccversion} && $Config{ccversion} =~ /clang/i);
# On FreeBSD $Config{cc} returns "cc".
if ($Config{cc} eq 'cc') {
    my $ccversion = `$Config{cc} --version`;
    if ($ccversion =~ /clang/) {
	$is_clang = 1;
    }
}
my $cc_flags = $Config{ccflags};
if ($is_clang) {
    $cc_flags = $cc_flags . ' -Wno-compound-token-split-by-macro -Wno-macro-redefined ';
}

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
	    'vividsnow',
	],
    },
    MIN_PERL_VERSION => '5.008001',
    OBJECT => 'Faster.o',
    LIBS => '-lz',
    CCFLAGS => $cc_flags,
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
