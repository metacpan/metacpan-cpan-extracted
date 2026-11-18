#!/usr/bin/env perl
# Publish-job helper of the binary release workflow.
#   publish.pl render   <META.json> <owner> <repo> <tag> <dir>  -> <dir>/install.sh, <dir>/install.ps1
#   publish.pl expected <META.json> <version>                   -> expected asset names, one per line
#   publish.pl sums     <dir>                                    -> <dir>/SHA256SUMS over the binaries found there
#   publish.pl check    <META.json> <version> <dl-dir> <release-json> <latest-json>
#                       <latest-json>: the releases/latest response, empty when that answered 404
package DzilBinary::Publish;
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA ();
use File::Basename ();
use File::Spec ();

my @PLATFORMS = qw( linux-x86_64 linux-arm64 macos-arm64 macos-x86_64 windows-x86_64 );

sub read_meta {
  my ($file) = @_;
  open my $fh, '<:raw', $file or die "cannot read $file: $!\n";
  my $meta = eval { JSON::PP->new->decode(do { local $/; <$fh> }) };
  die "$file is not valid JSON: $@" unless $meta;
  die "$file has no x_binaries\n" unless ref $meta->{x_binaries} eq 'HASH';
  return $meta;
}

sub platforms_of {
  my ($x) = @_;
  my $want = $x->{platforms};
  $want = [@PLATFORMS] unless ref $want eq 'ARRAY' && @$want;
  my %seen = map { $_ => 1 } @$want;
  for my $p (keys %seen) { die "x_binaries: unknown platform '$p'\n" unless grep { $_ eq $p } @PLATFORMS }
  return grep { $seen{$_} } @PLATFORMS;
}

sub binaries_of {
  my ($x) = @_;
  die "x_binaries has no binaries\n" unless ref $x->{binaries} eq 'HASH' && %{ $x->{binaries} };
  return sort keys %{ $x->{binaries} };
}

# binaries sorted by name, platforms in constraint order within each
sub expected_names {
  my ($x, $version) = @_;
  my @p = platforms_of($x);
  return map { my $n = $_; map { "$n-$version-$_" . ($_ eq 'windows-x86_64' ? '.exe' : '') } @p } binaries_of($x);
}

sub slurp { open my $fh, '<:raw', $_[0] or die "cannot read $_[0]: $!\n"; local $/; return scalar <$fh> }

sub spew {
  my ($path, $data) = @_;
  open my $fh, '>:raw', $path or die "cannot write $path: $!\n";
  print $fh $data;
  close $fh or die "cannot write $path: $!\n";
}

sub render {
  my ($meta_file, $owner, $repo, $tag, $dir) = @_;
  my $meta = read_meta($meta_file);
  my $x = $meta->{x_binaries};
  my ($name, $version) = ($meta->{name}, $meta->{version});
  die "$meta_file has no name or version\n" unless defined $name && defined $version;
  die "tag '$tag' does not end with version '$version'\n" unless length $tag >= length $version && substr($tag, -length $version) eq $version;
  my $prefix = substr($tag, 0, length($tag) - length $version);
  die "tag '$tag' does not end with version '$version' after a digit-free prefix (prefix '$prefix' contains a digit)\n" if $prefix =~ /\d/;
  my @bins = binaries_of($x);
  my @plat = platforms_of($x);
  for my $v ($name, $owner, $repo, $tag, $version, @bins) {
    die "refusing '$v': only letters, digits, '.', '_', '-', '+' are allowed\n" unless $v =~ /\A[A-Za-z0-9._+-]+\z/;
  }
  (my $env = uc $name) =~ s/-/_/g;
  die "dist name '$name' gives no valid environment prefix\n" unless $env =~ /\A[A-Z][A-Z0-9_]*\z/;
  my %v = (
    DIST => $name, OWNER => $owner, REPO => $repo, TAG => $tag, VERSION => $version,
    BINARIES => join(' ', @bins), PLATFORMS => join(' ', @plat), ENV => $env,
  );
  my $here = File::Basename::dirname(__FILE__);
  for my $f (qw( install.sh install.ps1 )) {
    my $c = slurp(File::Spec->catfile($here, "$f.in"));
    $c =~ s/\@(DIST|OWNER|REPO|TAG|VERSION|BINARIES|PLATFORMS|ENV)\@/$v{$1}/g;
    my $out = File::Spec->catfile($dir, $f);
    spew($out, $c);
    chmod 0644, $out;
  }
  return 0;
}

# The binaries are recognised by their asset name (<name>-<version>-<platform>[.exe]),
# so the tarball and strays in the directory get no line.
sub sums {
  my ($dir) = @_;
  opendir my $dh, $dir or die "cannot read $dir: $!\n";
  my $alt = join '|', map { quotemeta } @PLATFORMS;
  my %idx; @idx{@PLATFORMS} = (0 .. $#PLATFORMS);
  my @found;
  for my $f (readdir $dh) {
    next unless -f File::Spec->catfile($dir, $f);
    next unless $f =~ /\A(.+)-[0-9][^-]*-($alt)(?:\.exe)?\z/;
    my ($n, $plat) = ($1, $2);
    next unless ($plat eq 'windows-x86_64') == ($f =~ /\.exe\z/ ? 1 : 0);
    push @found, [ $n, $idx{$plat}, $f ];
  }
  closedir $dh;
  die "no binaries found in $dir\n" unless @found;
  my $out = '';
  for my $e (sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] } @found) {
    $out .= Digest::SHA->new(256)->addfile(File::Spec->catfile($dir, $e->[2]), 'b')->hexdigest . "  $e->[2]\n";
  }
  spew(File::Spec->catfile($dir, 'SHA256SUMS'), $out);
  return 0;
}

sub check {
  my ($meta_file, $version, $dl, $release_file, $latest_file) = @_;
  my $meta = read_meta($meta_file);
  my @want = expected_names($meta->{x_binaries}, $version);
  my $rel = eval { JSON::PP->new->decode(slurp($release_file)) };
  die "$release_file is not valid JSON: $@" unless ref $rel eq 'HASH';
  my %have = map { $_->{name} => 1 } grep { ref $_ eq 'HASH' && defined $_->{name} } @{ $rel->{assets} || [] };
  my @bad;
  push @bad, map { "missing binary: $_" } grep { !-f File::Spec->catfile($dl, $_) } @want;
  push @bad, map { "release already has asset: $_" } grep { $have{$_} } @want;
  if (@bad) { print STDERR "$_\n" for @bad; return 1 }
  print 'latest=', (latest_rule($rel, $latest_file) ? 'true' : 'false'), "\n";
  return 0;
}

# Never rolls releases/latest back: GitHub orders "latest" by created_at, so an
# older release finishing (or re-run) after a newer one is not marked latest.
sub latest_rule {
  my ($rel, $latest_file) = @_;
  return 0 if $rel->{prerelease};
  my $raw = slurp($latest_file);
  return 1 unless length $raw;   # 404: no latest release yet
  my $latest = eval { JSON::PP->new->decode($raw) };
  die "$latest_file is not valid JSON: $@" unless ref $latest eq 'HASH';
  return 1 if defined $rel->{id} && defined $latest->{id} && $rel->{id} eq $latest->{id};
  my %at;
  for ([ this => $rel, 'the release' ], [ latest => $latest, $latest_file ]) {
    my ($k, $r, $what) = @$_;
    my $t = $r->{created_at};
    die "$what has no created_at\n" unless defined $t && !ref $t;
    die "$what has created_at '$t', not YYYY-MM-DDThh:mm:ssZ\n" unless $t =~ /\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/;
    $at{$k} = $t;
  }
  return 1 if $at{latest} le $at{this};
  print STDERR 'not marking latest: ', ($latest->{tag_name} // "release $latest->{id}"),
    " (created $at{latest}) is newer than this release (created $at{this})\n";
  return 0;
}

sub main {
  my ($cmd, @a) = @_;
  $cmd //= '';
  my $rc = eval {
    if    ($cmd eq 'render'   && @a == 5) { render(@a) }
    elsif ($cmd eq 'expected' && @a == 2) {
      print "$_\n" for expected_names(read_meta($a[0])->{x_binaries}, $a[1]);
      0;
    }
    elsif ($cmd eq 'sums'     && @a == 1) { sums(@a) }
    elsif ($cmd eq 'check'    && @a == 5) { check(@a) }
    else { die "usage: publish.pl render|expected|sums|check ...\n" }
  };
  if (!defined $rc) { print STDERR $@; return 1 }
  return $rc;
}

exit main(@ARGV) unless caller;
1;
