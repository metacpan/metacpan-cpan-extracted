#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

## why do I have to do this?!?
use lib qw( ./blib/lib ./blib/arch );
BEGIN {print "1..9\n";}
END {print "not ok 1\n" unless $loaded;}
use File::BSDGlob ':glob';
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub array {
    return '(', join(", ", map {defined $_ ? "\"$_\"" : "undef"} @a), ")\n";
}

# look for the contents of the current directory
$ENV{PATH} = "/bin";
delete @ENV{BASH_ENV, CDPATH, ENV, IFS};
@correct = ();
if (opendir(D, ".")) {
   @correct = grep { !/^\.\.?$/ } sort readdir(D);
   closedir D;
}
@a = File::BSDGlob::glob("*", 0);
@a = sort @a;
if ("@a" ne "@correct" || GLOB_ERROR) {
    print "# |@a| ne |@correct|\nnot ";
}
print "ok 2\n";

# look up the user's home directory
# should return a list with one item, and not set ERROR
if ($^O ne 'MSWin32') {
    ($name, $home) = (getpwuid($>))[0,7];
    @a = File::BSDGlob::glob("~$name", GLOB_TILDE);
    if (scalar(@a) != 1 || $a[0] ne $home || GLOB_ERROR) {
	print "not ";
    }
}
print "ok 3\n";

# check backslashing
# should return a list with one item, and not set ERROR
@a = File::BSDGlob::glob('BSDGlob\.pm', GLOB_QUOTE);
if (scalar @a != 1 || $a[0] ne 'BSDGlob.pm' || GLOB_ERROR) {
    local $/ = "][";
    print "# [@a]\n";
    print "not ";
}
print "ok 4\n";

# check nonexistent checks
# should return an empty list
# XXX since errfunc is NULL on win32, this test is not valid there
@a = File::BSDGlob::glob("asdfasdf", 0);
if ($^O ne 'MSWin32' and scalar @a != 0) {
    print "# |@a|\nnot ";
}
print "ok 5\n";

# check bad protections
# should return an empty list, and set ERROR
$dir = "PtEeRsLt.dir";
mkdir $dir, 0;
@a = File::BSDGlob::glob("$dir/*", GLOB_ERR);
#print "\@a = ", array(@a);
rmdir $dir;
if (scalar(@a) != 0 || ($^O ne 'MSWin32' && GLOB_ERROR == 0)) {
    print "# @a\n";
    print "not ";
}
print "ok 6\n";

# check for csh style globbing
@a = File::BSDGlob::glob('{a,b}', GLOB_BRACE | GLOB_NOMAGIC);
unless (@a == 2 and $a[0] eq 'a' and $a[1] eq 'b') {
    print "not ";
}
print "ok 7\n";

@a = File::BSDGlob::glob(
    '{BSDGlob.p*,doesntexist*,a,b}',
    GLOB_BRACE | GLOB_NOMAGIC
);
unless (@a == 3
        and $a[0] eq 'BSDGlob.pm'
        and $a[1] eq 'a'
        and $a[2] eq 'b')
{
    print "not ";
}
print "ok 8\n";

# "~" should expand to $ENV{HOME}
$ENV{HOME} = "sweet home";
@a = File::BSDGlob::glob('~', GLOB_TILDE | GLOB_NOMAGIC);
unless (@a == 1 and $a[0] eq $ENV{HOME}) {
    print "not ";
}
print "ok 9\n";
