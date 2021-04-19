# get all plugin proc-names with this:
# perl -MIO::All -e 'for $f (@ARGV) { $_ = io($f)->all; next unless @m = /\bregister\s+(\S+)["\\'\'']/sg; map { s#[^a-zA-Z\d_]##g; print "$f: $_\n"; } @m }' blib/plugins/*

use strict;
use Test::More;
our ($dir, $DEBUG);
BEGIN {
#  $Gimp::verbose = 3;
  $ENV{LC_ALL} = 'en_GB.UTF-8'; # 5.20.0 in de_DE fails on "use 5.006_001"
  $DEBUG = 0;
  require './t/gimpsetup.pl';
  # most minimal and elegant would be to symlink sandbox gimp-dir's
  # plug-ins to our blib/plugins dir, but not portable to windows
  my $blibdir = 'blib/plugins';
  my @plugins = grep { !/Perl-Server/ } glob "$blibdir/*";
  map {
    warn "inst $_\n" if $Gimp::verbose;
    write_plugin($DEBUG, $_, io($_)->all);
  } @plugins;
  map { symlink_sysplugin($_) }
    qw(
      noise-rgb noise-solid blur-gauss grid pixelize blur-motion displace
      bump-map checkerboard edge file-gif-save file-png unsharp-mask crop-auto
    );
}
use Gimp qw(:consts), "net_init=spawn/";

our @testbench;
require './t/examples-api.pl';

for my $test (@testbench) {
  my ($actualparams, $tempdir, $tempfile) = setup_args(@$test);
  my $name = $test->[0];
  warn "Running $name\n" if $Gimp::verbose;
#use Data::Dumper;warn Dumper(Gimp->procedural_db_proc_info("perl_fu_$name"));
  my $img = eval { Gimp::Plugin->$name(@$actualparams); };
  is($@, '', "plugin $name");
  $img->delete if defined $img;
}

Gimp::Net::server_quit;
Gimp::Net::server_wait;

done_testing;
