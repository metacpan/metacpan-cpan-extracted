use strict;
use warnings;

use ExtUtils::Manifest qw(maniread maniskip);
use File::Find qw(find);
use Test2::V0;

my $manifest = maniread('MANIFEST');
my $skip     = maniskip();

my @missing;
find(
  {
    no_chdir => 1,
    wanted   => sub {
      return if -d $_;
      my $file = $File::Find::name;
      $file =~ s{^\./}{};
      return if $file eq q{};
      return if exists $manifest->{$file};
      return if $skip->($file);
      push @missing, $file;
    },
  },
  '.',
);

is(
  \@missing,
  [],
  'all repository files are listed in MANIFEST or excluded via MANIFEST.SKIP',
) or diag "Missing entries:\n" . join("\n", @missing);

done_testing();
