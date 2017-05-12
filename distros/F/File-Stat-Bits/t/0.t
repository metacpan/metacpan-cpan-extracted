#!perl -w

$^W=1;

require 5.005;
use strict;
use integer;
use Test;

BEGIN { plan tests => 21 };

BEGIN
{
=head1
    require re;	# load arch-dependend modules before @INC stripping

    use Config; my $archname = $Config{'archname'};

    foreach (my $i=0; $i < @INC; ++$i)	# strip arch paths from @INC
    {
	if ( $INC[$i] =~ m{$archname$}o )
	{
	    splice(@INC, $i, 1);
	    redo;
	}
    }
=cut
}

use File::Stat::Bits;
ok(1);#1

ok(S_ISDIR (S_IFDIR ));#2
ok(S_ISCHR (S_IFCHR ));#3
ok(S_ISBLK (S_IFBLK ));#4
ok(S_ISREG (S_IFREG ));#5
ok(S_ISFIFO(S_IFIFO ));#6
ok(S_ISLNK (S_IFLNK ));#7
ok(S_ISSOCK(S_IFSOCK));#8

ok( S_IRWXU == (S_IRUSR|S_IWUSR|S_IXUSR) );# 9
ok( S_IRWXG == (S_IRGRP|S_IWGRP|S_IXGRP) );#10
ok( S_IRWXO == (S_IROTH|S_IWOTH|S_IXOTH) );#11
ok( ACCESSPERMS == (S_IRWXU|S_IRWXG|S_IRWXO) );#12
ok(    ALLPERMS == (S_ISUID|S_ISGID|S_ISVTX|ACCESSPERMS) );#13

my $ifmt = (S_IFDIR|S_IFCHR|S_IFBLK|S_IFREG|S_IFIFO|S_IFLNK|S_IFSOCK);
ok( ($ifmt & ~S_IFMT) == 0 );#14


use File::stat;

my $st = stat($0) or die "Can't stat $0: $!\n";
ok(S_ISREG($st->mode));#15

ok( ($st->mode & (S_IRUSR|S_IRGRP|S_IROTH)) != 0 );# 16

sub is_int { my $arg = shift; return scalar($arg =~ m/^\d+$/) }

if ( defined major(0) )
{
    my ($major, $minor) = dev_split( $st->rdev );
    ok( is_int($major) and is_int($minor) );#17

    ok( dev_join($major, $minor) == $st->rdev );#18

    ok( $major == major($st->rdev) );#19
    ok( $minor == minor($st->rdev) );#20
}
else
{
    ok(1);#17
    ok(1);#18
    ok(1);#19
    ok(1);#20
}

$st = stat('/') or die "Can't stat /: $!\n";
ok(S_ISDIR($st->mode));#21
