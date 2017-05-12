#!/usr/bin/env perl

# Pragmata

use 5.10.0;
use strict;
use warnings;

# Utility

use autodie              qw( chdir unlink );
use File::Basename       qw( basename );
use FindBin              qw( $Bin $Script );
use Getopt::Long         qw( GetOptions );
use IPC::System::Simple  qw( capturex system );
use IO::All              qw( io );
use POSIX                qw( ceil );
use Readonly             qw( Readonly );
use Term::ReadKey        qw( GetTerminalSize );

# -------------------------------------

Readonly my $TERM_WIDTH => (GetTerminalSize)[0];

my $Clean  = 'clean' eq lc $Script;
my $DryRun = 0;

# Subrs ------------------------------------------------------------------------

sub run {
  my ($cmd, $exit) = @_;
  my $cmdstring = join ' ', @$cmd;

  if ( $DryRun ) {
    say "CMD: $cmdstring";
    return;
  }

  my $dash_width = ($TERM_WIDTH - length($cmdstring) - 2) / 2;
  say STDERR '';
  say STDERR '-' x $dash_width, ' ', $cmdstring, ' ', '-' x ceil $dash_width;
  say STDERR '';

  $exit ||= [0];
  # not systemx, so we can, e.g., yes | debuild
  # (pipes do not work with systemx)
  system $exit, @$cmd;

  say STDERR '';
}

# -------------------------------------

# inplace edit file
sub hackit {
  my ($fn, $rules) = @_;
  my $io = io($fn)->open('+<');
  my @lines;
  for my $l ($io->chomp->slurp) {
    $l = $_->($l)
      for @$rules;
    push @lines, $l
      if defined $l;
  }

  $io->seek(0, 0)
    or confess "failed to seek to start on $fn: $!\n";
  $io < join '', map "$_\n", @lines;
}

# Main -----------------------------------------------------------------------

GetOptions('C|clean'   => \$Clean,
           'n|dry-run' => \$DryRun,
          )
  or die "options parsing failed\n";

chdir $Bin;

my $hmod = basename $Bin; # hyphenated module name
(my $mod = $hmod) =~ s/-/::/g;
my $mod_version = capturex qw( perl -I lib ), "-M$mod",
                           -e => "print \$${mod}::VERSION";
my $libstub = sprintf 'lib%s-perl_',  lc $hmod;

run(['./Build' => 'distclean'])
  if -e 'Build';

FN:
for my $fn (grep -e,
              map glob($_), "$libstub*", "$hmod-*.tar.gz",
              qw( debian MANIFEST.bak Makefile.PL META.yml Makefile ), ) {
  if ( $DryRun ) {
    say "RM : $fn";
    next FN;
  }

  unlink $fn;
}

exit 0
  if $Clean;

say  "Building... $mod: $mod_version";

run([perl => 'Build.PL']);
run(['./Build' => $_])
  for qw( test distmeta distcheck distsign disttest dist distdir );
run(['dh-make-perl', '--closes' => 0, "$hmod-$mod_version"]);
chdir "$hmod-$mod_version";
hackit("debian/control",
       [sub {
          my ($x) = @_;
          $x =~ s!\bperl/(libparams-validate-perl)\b!$1!;
          $x =~ s!\b(perl\s+\(>= )v([\d.]+)\)!$1$2)!;
          return $x;
        }]);
run(['yes | debuild'],[29]);
say 'Now run:';
printf "  sudo dpkg --install lib%s-perl_%s-1_all.deb\n", lc $hmod, $mod_version;
