use strict;
use Test::More;
our ($dir, $DEBUG);
my @PLUGINS;
my $LIKE_RX;
BEGIN {
#  $Gimp::verbose = 3;
  @PLUGINS = qw(dots glowing_steel map_to_gradient redeye);
  $LIKE_RX = qr/^(Xlib:\s*extension "RANDR" missing.*|.*(GEGL-WARNING|GeglBuffers leaked).*|)$/m;
  $DEBUG = 0;
  require './t/gimpsetup.pl';
  # most minimal and elegant would be to symlink sandbox gimp-dir's
  # plug-ins to our blib/plugins dir, but not portable to windows
  my $blibdir = 'blib/plugins';
  my @plugins = map { "$blibdir/$_" } @PLUGINS;
  map {
    warn "inst $_\n" if $Gimp::verbose;
    write_plugin($DEBUG, $_, io($_)->all);
  } @plugins;
  map { symlink_sysplugin($_) }
    qw(
      noise-rgb noise-solid blur-motion
    );
}
use Gimp ':consts', "net_init=spawn/";
use Gimp::Fu qw(save_image);
use IPC::Open3;
use Symbol 'gensym';
use IO::Select; # needed because output can be big and it can block!

our (@testbench, %proc2file, %file2procs);
require './t/examples-api.pl';

my %plug2yes = map { ($_=>1) } @PLUGINS;
@testbench = grep { $plug2yes{$_->[0]} } @testbench;
my @duptest = @{$testbench[0]};
$duptest[3] = [ @{$duptest[3]} ]; # don't change original
pop @{$duptest[3]}; # remove last param - test default
unshift @testbench, \@duptest;

for my $test (@testbench) {
  my ($actualparams, $tempdir, $tempfile) = setup_args(@$test);
  my $scratchdir = File::Temp->newdir($DEBUG ? (CLEANUP => 0) : ());
  my $name = $test->[0];
  my $file = "./blib/plugins/$proc2file{$name}";
  my $img = $actualparams->[0];
  if (ref $img eq 'Gimp::Image') {
    save_image($img, $actualparams->[0] = "$scratchdir/in.xcf");
    $actualparams->[1] = '%a';
  }
  my $output = "$scratchdir/out.xcf";
  unshift @$actualparams, '--output', $output;
  unshift @$actualparams, ('-v') x $Gimp::verbose;
  unshift @$actualparams, '-p', $name if @{$file2procs{$proc2file{$name}}} > 1;
  my @perl = ($^X, '-Mblib');
#use Data::Dumper;warn Dumper(Gimp->procedural_db_proc_info("perl_fu_$name"));
  my ($wtr, $rdr, $err, @outlines, @errlines) = (undef, undef, gensym);
  warn "Running @perl $file @$actualparams\n" if $Gimp::verbose;
  my $pid = open3($wtr, $rdr, $err, @perl, $file, @$actualparams);
  $wtr->close;
  my $sel = IO::Select->new($rdr, $err);
  while(my @ready = $sel->can_read) {
    foreach my $fh (@ready) {
      if (defined(my $l = $fh->getline)) {
	push @{$fh == $rdr ? \@outlines : \@errlines}, $l;
      } else {
	$sel->remove($fh);
	$fh->close;
      }
    }
  }
  like(join('', @errlines), $LIKE_RX, "$name stderr not of concern");
  like(join('', @outlines), $LIKE_RX, "$name stdout not of concern");
  waitpid($pid, 0);
  is($? >> 8, 0, "$file exit=0");
  ok(-f $output, "$file output exists");
}

Gimp::Net::server_quit;
Gimp::Net::server_wait;

done_testing;
