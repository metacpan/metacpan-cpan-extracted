package testload;

use strict;
use Test::More;
use File::Spec;
use LWP::UserAgent;
use HTTP::Request;

use Finance::QuoteHist;

use constant DEV_TESTS => $ENV{FQH_DEV_TESTS};

use constant GOLDEN_CHILD => 'yahoo';

use vars qw( @ISA @EXPORT );

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
  network_ok
  new_quotehist
  modules
  all_modules
  sources
  modes
  granularities
  basis
  csv_content
  GOLDEN_CHILD
  DEV_TESTS
);

my($Dat_Dir, $Mod_Dir);
BEGIN {
  my($vol, $dir, $file) = File::Spec->splitpath(__FILE__);
  my @parts = File::Spec->splitdir($dir);
  pop @parts while @parts && $parts[-1] ne 't';
  my $ddir = File::Spec->catdir(@parts, 'dat');
  $Dat_Dir = File::Spec->catpath($vol, $ddir, '');
  pop @parts;
  my $mdir = File::Spec->catdir(@parts, 'lib', 'Finance', 'QuoteHist');
  $Mod_Dir = File::Spec->catpath($vol, $mdir, '');
}

my $csv_txt;
my $csv_file = "$Dat_Dir/csv.dat";
open(F, '<', $csv_file) or die "problem reading $csv_file : $!";
$csv_txt = join('', <F>);
close(F);

sub csv_content { $csv_txt }

my(%Modules, %Files);

for my $f (glob("$Dat_Dir/*.dat")) {
  my($vol, $dir, $label) = File::Spec->splitpath($f);
  $label =~ s/\.dat$//;
  next unless $label =~ /^(quote|dividend|split)_/;
  open(F, '<', $f) or die "problem reading $f : $!";
  my @lines = <F>;
  chomp @lines;
  close(F);
  my $class = shift @lines;
  ++$Modules{$class};
  my($sym, $start, $end) = split(/,/, shift @lines);
  if ($1 eq 'quote') {
    my($mode, $gran, $source) = split(/_/, $label);
    if ($lines[0] =~ tr/:/:/ > 5) {
      # drop adjusted and volume, they've proven to be too
      # variable for testing
      for my $i (0 .. $#lines) {
        my @line = split(/:/, $lines[$i]);
        pop @line while @line > 6;
        $lines[$i] = join(':', @line);
      }
    }
    $Files{$source}{$mode}{$gran} = [$class, $sym, $start, $end, \@lines];
  }
  else {
    my($mode, $source) = split(/_/, $label);
    $Files{$source}{$mode} = [$class, $sym, $start, $end, \@lines];
  }
}

my $Network_Up;

sub network_ok {
  if (! defined $Network_Up) {
    my %ua_parms;
    if ($ENV{http_proxy}) {
      $ua_parms{env_proxy} = 1;
    }
    my $ua = LWP::UserAgent->new(%ua_parms)
      or die "Problem creating user agent\n";
    my $request = HTTP::Request->new('HEAD', 'http://finance.yahoo.com')
      or die "Problem creating http request object\n";
    my $response = $ua->request($request, @_);
    $Network_Up = $response->is_redirect || $response->is_success;
    if (!$Network_Up) {
      print STDERR "Problem with net fetch: ", $response->status_line, "\n";
    }
  }
  $Network_Up;
}

sub new_quotehist {
  my($symbols, $start_date, $end_date, %parms) = @_;
  my $class = $parms{class} || 'Finance::QuoteHist';
  delete $parms{class};
  $class->new(
    symbols    => $symbols,
    start_date => $start_date,
    end_date   => $end_date,
    auto_proxy => 1,
    %parms,
  );
}

sub modules { sort keys %Modules }

sub sources { sort keys %Files }

sub modes {
  my $src = shift || return;
  my $h = $Files{$src} || return;
  sort keys %$h;
}

sub granularities {
  my $src = shift || return;
  my $h = $Files{$src}{quote} || return;
  sort keys %$h;
}

sub basis {
  my($src, $mode, $gran) = @_;
  my $basis;
  if ($mode eq 'quote') {
    $basis = $Files{$src}{$mode}{$gran};
  }
  else {
    $basis = $Files{$src}{$mode};
  }
  return unless $basis;
  @$basis;
}

sub all_modules {
  my %mods;
  for my $f (glob "$Mod_Dir/*.pm") {
    my($vol, $dir, $base) = File::Spec->splitpath($f);
    $base =~ s/\.pm$//;
    next if $base eq 'Generic';
    $mods{lc($base)} = "Finance::QuoteHist::$base";
  }
  $mods{plain} = "Finance::QuoteHist";
  wantarray ? %mods : \%mods;
}

1;
