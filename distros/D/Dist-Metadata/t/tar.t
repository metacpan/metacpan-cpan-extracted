use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Dist::Metadata::Tar';
eval "require $mod" or die $@;

my $base = 'corpus/Dist-Metadata-Test-NoMetaFile-0.1';

# test that instantiating this class directly does not negotiate type
new_ok($mod => [file => "$base.zip"]);

my $file = "$base.tar.gz";
my $tar = new_ok($mod => [file => $file]);

# file_content, and find_files tested in t/archive.t

# read_archive
isa_ok($tar->read_archive($file), 'Archive::Tar');

# tar
{
  my $warning;
  local $SIG{__WARN__} = sub { $warning = $_[0] };
  isa_ok($tar->tar, 'Archive::Tar');
  like($warning, qr/deprecated/, 'tar() works but is deprecated');
}

done_testing;
