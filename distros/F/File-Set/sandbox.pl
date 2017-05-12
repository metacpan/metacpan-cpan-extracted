#!/usr/local/bin/perl -w

use File::Set;
use File::Temp qw(tempfile);
use Cwd;
use strict;

our @Exclude;

if (!@ARGV) {
  print <<EOF;
Usage: $0 create /path
       $0 snap /path result.tar.gz
       $0 update /path

  create
    - create a sandbox under /path

  snap
    - create a snapshot of changes under /path into result.tar.gz
      (if you use '' as filename, outputs file list to stdout)

  update
    - bring checksum db up to date with current contents of /path

EOF
  exit(1);
}

my $Action = shift;

if ($Action eq 'create') {
  CreateSandbox(@ARGV);
} elsif ($Action eq 'snap') {
  SnapSandbox(@ARGV);
} elsif ($Action eq 'update') {
  CreateChecksums(@ARGV);
} else {
  die "Unknown action '$Action'";
}

sub CreateSandbox {
  my ($Path) = @_;

  # Check and make path and helper dir
  !-e $Path || die "Path '$Path' already exists. Delete first.";
  $Path =~ m{^/} || die "Path '$Path' must be absolute.";
  mkdir $Path || die "Could not create '$Path' directory: $!";
  mkdir "$Path-data" || die "Could not create '$Path-data' directory: $!";

  # Tar up sandbox files
  my $FS = File::Set->new();
  $FS->add_from_file(\*DATA);
  $FS->create_gnu_tar("$Path-data/sandbox.tar.gz");

  RebuildSandbox($Path);
}

sub RebuildSandbox {
  my ($Path) = @_;

  # Clean sandbox
  system('/bin/rm', '-rf', glob("$Path/*"));

  # And untar into sandbox
  chdir $Path || die "Could not chdir to '$Path': $!";
  system("/bin/tar", "-xpzf", "$Path-data/sandbox.tar.gz");

  # Create special dirs
  mkdir "$Path/build" || die "Could not create '$Path/build': $!";
  mkdir "$Path/tmp" || die "Could not create '$Path/tmp': $!";
  system("/bin/chmod", "+t", "$Path/tmp");
  mkdir "$Path/tmpfs" || die "Could not create '$Path/tmpfs': $!";
  system("/bin/chmod", "+t", "$Path/tmpfs");

  CreateChecksums($Path);
}

sub CreateChecksums {
  my ($Path) = @_;

  # Now build checksum db
  my $FS = File::Set->new();
  $FS->prefix($Path);
  $FS->add('/');
  $FS->exclude(@Exclude);

  $FS->save_checksum_db("$Path-data/checksums.txt");
}

sub SnapSandbox {
  my ($Path, $TarFile) = @_;

  my $FS = File::Set->new();
  $FS->prefix($Path);
  $FS->add('/');
  $FS->exclude(@Exclude);

  # Build a list of changed/added files
  my ($Fh, $FileList) = tempfile(DIR => '/tmp');

  my %NewDirs;

  $FS->compare_checksum_db("$Path-data/checksums.txt", '', sub {
    my ($Context, $Action, $Type, $Prefix, $Path) = @_;
    return if ($Type eq 'd' && $Action ne 'n') || $Action eq 'd';

    $Path =~ s{^/}{};

    # Keep track of newly added directories
    if ($Type eq 'd' && $Action eq 'n') {
      $NewDirs{$Path} = 1;
    }

    # Don't add files/dirs in new dirs, automatically added
    my ($TestPath, $SubPath) = ($Path, '');
    while ($TestPath =~ s/^(.*)\///) {
      $SubPath .= $1;
      return if $NewDirs{$SubPath};
      $SubPath .= '/';
    }

    print $Fh $Path, "\n";
  });
  close ($Fh);

  if ($TarFile eq '') {
    system('cat', $FileList);
    return;
  }

  # Tar result
  if ($TarFile =~ m{/}) {
    $TarFile = getcwd() . "/$TarFile";
  } else {
    $TarFile = "$Path-data/$TarFile";
  }
  chdir $Path || die "Could not chdir to '$Path': $!";
  system('/bin/tar', '-czf', $TarFile, '-T', $FileList);

  system('/bin/cp', "$Path-data/checksums.txt", "$TarFile-checksums.txt");
}

BEGIN { @Exclude = qw(/build /dev /tmp /tmpfs /proc /home /root /etc/passwd /etc/shadow /etc/group /etc/hosts /etc/ld.so.cache /etc/ld.so.conf /usr/share); }

__DATA__
@/bin/
@/usr/
@/sbin/
@/lib/
@/usr/bin/
/usr/lib/
/usr/include/
@/usr/kerberos/
@/usr/lib/rpm/
@/usr/local/bin/
@/var/lib/rpm/
/usr/share/locale/
/usr/share/tabset/
@/root/
@/dev/

# Files
/etc/passwd
/etc/shadow
/etc/group
/etc/hosts
/etc/services
/etc/protocols
/etc/ld.so.cache
/etc/ld.so.conf
/etc/termcap
/etc/resolv.conf
/etc/host.conf
/etc/nsswitch.conf


