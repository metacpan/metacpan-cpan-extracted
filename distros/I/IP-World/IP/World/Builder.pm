# this package is used by Build.PL

package IP::World::Builder;

use strict;
use warnings;
use File::Copy;

# this is called during each Build step
sub do_dat {
  my $self = $_[0];
  my $invoked = $self->invoked_action();
  my $current = $self->current_action();

  if ($current eq 'code') {

    # create destination directories as necessary
    my $dest = '';
    for ('blib/lib/auto', '/IP', '/World') {
      if (!-d ($dest .= $_)) {
        mkdir $dest or die "Can't make dir $dest: $!";
    } }
    $dest .= '/ipworld.dat';

    # select source file based on this machine's endianness
    my $bigend = pack('L', 1) eq pack('N', 1);
    my $srcdir = 'lib/auto/IP/World';
    my $src = "$srcdir/ipworld." .($bigend ? 'be' : 'le');

    # get the proper mod time for the file from an accompanying file
    my ($src_mod, $dest_mod);
    my $fn = "$srcdir/modtime.dat";
    open DAT, "<$fn" or die "Can't open $fn for read: $!";
    read (DAT, $src_mod, 4)==4 or die "Can't read from $fn: $!";
    close DAT;
    $src_mod = unpack 'N', $src_mod;

    # set the mod times of the included files (in case someone copies)
    # Windows requires write permission
    my $WIN = $^O =~ /(ms|cyg)win/i;
    for ('be', 'le') {
      $fn = "$srcdir/ipworld.$_";
      $WIN and      chmod(0664, $fn) || die "Can't change permissions on $fn: $!";
      utime($src_mod, $src_mod, $fn) || die "Can't set mod time of $fn: $!";
      $WIN and      chmod(0444, $fn) || die "Can't change permissions on $fn: $!";
    }
    # copy database if necessary
    if (!-e $dest
     || $src_mod > ($dest_mod = (CORE::stat $dest)[9])
     || $src_mod == $dest_mod
     && -s $src != -s $dest) {

      # copy the file
      print "Copying $src -> $dest\n";
      copy ($src, $dest)               || die "Can't copy $src to $dest: $!";
      $WIN and      chmod(0664, $dest) || die "Can't change permissions on $dest: $!";
      utime($src_mod, $src_mod, $dest) || die "Can't set mod time of $dest: $!";
      $WIN and      chmod(0444, $dest) || die "Can't change permissions on $dest: $!";
    }
    # hopefully temporary (if the M::B guys include docs in test)
    if ($invoked eq 'test') {$self->depends_on('docs')}
  }
  if ($invoked eq 'install') {

    # run maint_ip_world_db to update the database if necessary
    my $tail = $self->is_unixish() ? ' 2>&1' : '';
    my $perl = $self->config_data('perl');
    if (!$perl) {die "Can't get path to perl"}
    my $fn = 'script/maint_ip_world_db';

    print "Checking for database update (may rebuild)...\n";

    my $result = `$perl $fn -t$tail`;
    while ($result && $result =~ /^PROXY\t(.+?)\t(.*)/) {

      # maint_ip_world_db has encountered a proxy, but since it doesn't have
      #   a STDIN, we have to ask for the user and PW
      my $netloc = $2;
      print STDERR "Enter username for proxy $1 at $netloc: ";
	  my $u = <STDIN>;
	  chomp($u);
	  print STDERR "Password: ";
	  system("stty -echo");
	  my $pw = <STDIN>;
	  system("stty echo");
	  print STDERR "\n";  # because we disabled echo
	  chomp($pw);
	  $result = `$perl $fn -t -u "$u" -p "$pw"$tail`;
    }
    if (!defined $result) {die "execution of $fn failed: $!"}
    print $result;

} } # end sub process_dat_file
1;