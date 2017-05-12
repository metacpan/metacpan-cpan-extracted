use strict;
use File::Path;
use File::Basename;
use Getopt::Std;

getopts( 'iru:', \my %opt );
my $d = dirname(__FILE__) . '/extra';

bringup()  if defined $opt{i};
teardown() if defined $opt{r};

# Setup structure:

# {base}/         (0755, 0, 0);
#   1/             (0777, u, g)
#     a             (0600, u, g)
#     b             (0400, u, g)
#   2/             (0700, u, g)
#     a             (0066, 0, 0)
#     b             (0400, 0, 0)
#     c             (0000, u, g)
#   3/             (0700, u, g)
#     a             (0400, 0, 0)
#     b             (0400, u, g)
#     M/            (0700, u, g)
#       xx           (0400, u, g)
#       yy           (0400, u, g)
#     N => M/
#     S/            (0000, 0, 0)
#     T/            (0000, 0, 0)
#     U/            (0000, 0, 0)
#     V/            (0700, u, g)
#   4 => 3/
#   5/             (0200, 0, 0)
#     xx            (0700, 0, 0)
#     yy            (0700, 0, 0)

sub bringup {
  die 'Must be root to bringup test' if $< != 0;
  die 'Must provide uid of the user running tests as non-root'
    if not defined $opt{u};

  my ($uid, $gid) = $opt{u} =~ /\D/
      ? (getpwnam($opt{u}))[2,3]
      : (getpwuid($opt{u}))[2,3]
  ;

  create_dir($d, 0755);

  # directory EXTRA/1 could be deleted by a
  # non-privileged account, including one file belonging to root.
  create_dir ( $d . '/1',   0777, $uid, $gid );
  create_file( $d . '/1/a', 0600, $uid, $gid );
  create_file( $d . '/1/b', 0400, $uid, $gid );

  # contents of EXTRA/2 can be removed by a
  # non-privileged account.
  create_dir ( $d . '/2',   0700, $uid, $gid );
  create_file( $d . '/2/a', 0066, $<,   $(   );
  create_file( $d . '/2/b', 0400, $<,   $(   );
  create_file( $d . '/2/c', 0000, $uid, $gid );

  # directory EXTRA/3 contains sundry files
  create_dir(  $d . '/3',      0700, $uid, $gid );
  create_file( $d . '/3/a',    0400, $<,   $(   );
  create_file( $d . '/3/b',    0400, $uid, $gid );

  # directory EXTRA/4 is a symlink to EXTRA/3
  symlink './3', $d . '/4' or die "symlink: $!";

  create_dir(    $d . '/3/M',    0700, $uid, $gid );
  create_file(   $d . '/3/M/xx', 0400, $uid, $gid );
  create_file(   $d . '/3/M/yy', 0400, $uid, $gid );
  create_dir(    $d . '/3/S',    0000, $<,   $( );
  create_dir(    $d . '/3/T',    0000, $<,   $( );
  create_dir(    $d . '/3/U',    0000, $<,   $( );
  create_dir(    $d . '/3/V',    0700, $uid, $gid );
  symlink './M', $d . '/3/N' or die "symlink: $!";

  # inaccessible child dir
  create_dir (   $d . '/5',    0700, $<,   $( );
  create_file(   $d . '/5/xx', 0700, $<,   $( );
  create_file(   $d . '/5/yy', 0700, $<,   $( );
  chmod( 0200,   $d . '/5' );
}

sub teardown {
  die 'Must be root to teardown test' if $< != 0;
  rmtree($d);
}

sub create_dir {
    my $dir  = shift;
    my $mask = shift;
    my $uid  = shift;
    my $gid  = shift;
    if (!-d $dir) {
        mkdir $dir, $mask or die "mkdir $dir: $!\n";
    }
    if (defined $uid and defined $gid) {
        chown $uid, $gid, $dir
            or die "failed to chown dir $dir to ($uid,$gid)\n"
    }
}

sub create_file {
    my $file = shift;
    my $mask = shift;
    my $uid  = shift;
    my $gid  = shift;
    open OUT, "> $file" or die "Cannot open $file for output: $!\n";
    print OUT <<EOM;
Test file for module File::Path
If you can read this, feel free to delete this file.
EOM
    close OUT;
    if ($uid and defined $gid) {
        chown $uid, $gid, $file
            or die "failed to chown $file to ($uid,$gid)\n"
    }
    if (defined $mask) {
        chmod $mask, $file
            or die "failed to chmod $file to $mask: $!\n";
    }
}
