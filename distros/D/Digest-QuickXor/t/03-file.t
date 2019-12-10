use strict;
use warnings;
use utf8;
use v5.24;

use FindBin;
use Test::More;

use IO::File;

my $package;

BEGIN {
  $package = 'Digest::QuickXor';
  use_ok $package or exit;
}

note 'Object';
ok my $object = $package->new, 'Create object';

my %hashes = (
  'longer_text.txt' => 'MyNPbFMLAm5Ol0JF4iqBwtfLtf8=',
  'perl_camel.png'  => 'btGJtuvrt57YpSgEUpMJKkNQywA=',
  'perl_logo.svg'   => 't+ivKo9P9+OBdXUVle2LDwOmIzI=',
  'short_text.txt'  => 'QQDBHNDwBjnQAQR0JAMe6AAAAAA=',
);

for my $file (sort keys %hashes) {
  note $file;
  my $fh;
  my $path = "$FindBin::Bin/resources/$file";

  ok open($fh, '<', $path), "Glob for $file";
  is $object->addfile($fh)->b64digest, $hashes{$file}, "Hash for $file glob";
  close $fh;

  ok $fh= IO::File->new($path, '<'), "Handle for $file";
  is $object->addfile($fh)->b64digest, $hashes{$file}, "Hash for $file handle";
  $fh->close;

  eval { $object->addfile($path) };
  like $@, qr/Not a file handle!/, 'Correct error for path';
}

done_testing();
