use strict;
use warnings;
package GitSetup;

use Test::More;
use Path::Tiny;
use Try::Tiny;
use IPC::Cmd qw[can_run];

use Exporter 5.57 'import';
our @EXPORT = qw(no_git_tempdir);

$ENV{HOME} = Path::Tiny->tempdir->stringify;

unless ( can_run('git') ) {
  ok('No git, no dice');
  done_testing;
  exit 0;
}

{
  my ($gitver) = `git version`;
  my ($ver) = $gitver =~ m!git version ([0-9.]+(\.msysgit)?[0-9.]+)!;
  $ver =~ s![^\d._]!!g;
  $ver =~ s!\.$!!;
  $ver =~ s!\.+!.!g;
  chomp $gitver;
  require version;
  my $ver_obj = try { version->parse( $ver ) }
    catch { die "'$gitver' not parsable as '$ver': $_" };
  if ( $ver_obj < version->parse('1.5.0') ) {
    diag("$gitver is too low, 1.5.0 or above is required");
    ok("$gitver is too low, 1.5.0 or above is required");
    done_testing;
    exit 0;
  }
  diag("Using $gitver\n");
}

# provides a temp directory that is guaranteed to not be inside a git repository
# copied from Dist-Zilla-Plugin-Git-Contributors/t/lib/GitSetup.pm
sub no_git_tempdir
{
    my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
    mkdir $tempdir if not -d $tempdir;    # FIXME: File::Temp::newdir doesn't make the directory?!

    {
        my $in_git;
        my $dir = $tempdir;
        my $count = 0;
        while (not $dir->is_rootdir) {
            # this should never happen.
            do { diag "failed to detect that $dir is at the root?!"; last } if $dir eq $dir->parent;

            my $checkdir = path($dir, '.git');
            if (-d $checkdir) {
                note "found $checkdir in $tempdir";
                $in_git = 1;
                last;
            }
            $dir = $dir->parent;
        }
        continue {
            die "too many iterations when traversing $tempdir!"
                if $count++ > 100;
        }

        ok(!$in_git, 'tempdir is not in a real git repository');
    }

    return $tempdir;
}

1;
