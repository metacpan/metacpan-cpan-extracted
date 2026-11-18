#!/usr/bin/env perl
# Build/smoke matrix of the binary release workflow.
#   plan.pl <META.json>  ->  legs=<json> / smoke=<json> / prepare_key=<hex|none>
package DzilBinary::Plan;
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA ();
use File::Basename ();
use File::Spec ();

# almalinux:8 OCI index (manifest list) digest, read from Docker Hub on 2026-11-06.
my $CONTAINER = 'almalinux:8@sha256:2d0f2eb2a83cc09dbc2eb92fade4dbe8f709628149e81aa00aec70630406603b';

my @PLATFORMS = qw( linux-x86_64 linux-arm64 macos-arm64 macos-x86_64 windows-x86_64 );
my %RUNNER = (
  'linux-x86_64'   => 'ubuntu-24.04',
  'linux-arm64'    => 'ubuntu-24.04-arm',
  'macos-arm64'    => 'macos-15',
  'macos-x86_64'   => 'macos-15-intel',
  'windows-x86_64' => 'windows-2025',
);
my %SMOKE = (
  'linux-x86_64'   => { runner => 'ubuntu-24.04',     images => [qw( almalinux:8 almalinux:9 debian:bookworm-slim )] },
  'linux-arm64'    => { runner => 'ubuntu-24.04-arm', images => [qw( almalinux:9 )] },
  'macos-arm64'    => { runner => 'macos-26' },
  'macos-x86_64'   => { runner => 'macos-26-intel' },
  'windows-x86_64' => { runner => 'windows-2022' },
);

sub plan {
  my ($meta_file) = @_;
  open my $fh, '<:raw', $meta_file or die "cannot read $meta_file: $!\n";
  my $meta = eval { JSON::PP->new->decode(do { local $/; <$fh> }) };
  die "$meta_file is not valid JSON: $@" unless $meta;
  my $x = $meta->{x_binaries};
  die "$meta_file has no x_binaries\n" unless ref $x eq 'HASH';

  my $want = $x->{platforms};
  $want = [@PLATFORMS] unless ref $want eq 'ARRAY' && @$want;
  my %seen;
  for my $p (@$want) {
    die "x_binaries: unknown platform '$p'\n" unless $RUNNER{$p};
    $seen{$p} = 1;
  }
  my @use = grep { $seen{$_} } @PLATFORMS;

  my (@legs, @smoke);
  for my $p (@use) {
    push @legs, { platform => $p, runner => $RUNNER{$p},
      ($p =~ /\Alinux-/ ? (container => $CONTAINER) : ()) };
    my $s = $SMOKE{$p};
    if ($s->{images}) { push @smoke, { platform => $p, runner => $s->{runner}, image => $_ } for @{ $s->{images} } }
    else              { push @smoke, { platform => $p, runner => $s->{runner} } }
  }

  my $key = 'none';
  my $prepare = $x->{prepare};
  if (defined $prepare && $prepare =~ /\S/) {
    my ($first) = $prepare =~ /\A\s*(\S+)/;
    my $file = File::Spec->catfile(File::Basename::dirname($meta_file), $first);
    die "x_binaries prepare: '$first' is not a file in the dist ($file)\n" unless -f $file;
    $key = Digest::SHA->new(256)->addfile($file, 'b')->hexdigest;
  }

  my $json = JSON::PP->new->canonical;
  return ("legs=" . $json->encode(\@legs), "smoke=" . $json->encode(\@smoke), "prepare_key=$key");
}

sub main {
  my (@args) = @_;
  die "usage: plan.pl <META.json>\n" unless @args == 1;
  my @lines = eval { plan($args[0]) };
  if ($@) { print STDERR $@; return 1 }
  print "$_\n" for @lines;
  return 0;
}

exit main(@ARGV) unless caller;
1;
