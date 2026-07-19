#!/usr/bin/env perl
use strict;
use warnings;

use File::Find qw(find);
use File::Spec;

my $root = File::Spec->curdir();
my @roots = map { File::Spec->catdir($root, $_) } qw(src lib);
my @files;

find(
  {
    wanted => sub {
      return unless -f $_;
      return unless /\.(?:h|xs|pm)$/;
      return if $_ eq 'ppport.h';
      push @files, $File::Find::name;
    },
    no_chdir => 1,
  },
  @roots,
);

my @patterns = (
  {
    name => 'temporary key SV passed inline to hv_store_ent',
    re   => qr/hv_store_ent\(\s*[^,\n]+,\s*newSV(?:sv|pv|pvf|pvn|uv|iv)\b/,
  },
  {
    name => 'temporary key SV passed inline to hv_fetch_ent or hv_exists_ent',
    re   => qr/hv_(?:fetch|exists)_ent\(\s*[^,\n]+,\s*newSV(?:sv|pv|pvf|pvn|uv|iv)\b/,
  },
  {
    name => 'nested sv_2mortal call',
    re   => qr/sv_2mortal\([^\n]*sv_2mortal\b/,
  },
);

my @violations;

for my $file (@files) {
  open my $fh, '<', $file or die "open $file: $!";
  my $line_no = 0;
  while (my $line = <$fh>) {
    $line_no++;
    for my $pattern (@patterns) {
      next unless $line =~ $pattern->{re};
      push @violations, {
        file => $file,
        line => $line_no,
        name => $pattern->{name},
        text => $line,
      };
    }
  }
  close $fh;
}

if (@violations) {
  for my $violation (@violations) {
    chomp(my $text = $violation->{text});
    print "$violation->{file}:$violation->{line}: $violation->{name}\n";
    print "  $text\n";
  }
  exit 1;
}

print "XS ownership lint passed.\n";
exit 0;
