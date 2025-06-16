#!perl
use strict;
use warnings;
use version;

use Test::More;

use Imager::zxing;

my $v = version->new(Imager::zxing->version);

my @types = Imager::zxing::Encoder->availFormats;

my %type_strs =
  (
    "EAN-8" => "96385074",   # 8 characters
    "ITF" => "0123456789", # even count
    "UPC-A" => "485963095124", # 11 or 12 digits
    "UPC-E" => "05096893", # 6+check digits, decode returns the check
    # Codabar encoder adds start/end, add our own which we get back by default.
    "Codabar" => "B9781975344054C",
   );

diag "Types @types\n";
for my $type (@types) {
  my $e = Imager::zxing::Encoder->new($type);

  my $text = $type_strs{$type};
  defined $text or $text = "9781975344054";
  my $im = $e->encode($text, 200, 200);
  my $msg = Imager->errstr;
  ok($im, "make a $type")
    or diag "Error for $type: ".Imager->errstr;
  my $d = Imager::zxing::Decoder->new;
  $d->setFormats($type);
  my $result = $d->decode($im);
  is($result->text, $text, "$type: check it decodes to the input");
}

# image types, fg, background colors
{
  my $e = Imager::zxing::Encoder->new("QRCode");
  ok($e, "got a qrcode encoder");
  my $text = "https://www.perl.org";
  ok($e->setForeground("#404142"), "set foreground");
  ok($e->setBackground("#FFC0C1"), "set background");
  for my $fmt (qw(RGB RGBA Palette Gray)) {
    $e->setFormat($fmt);
    my $im = $e->encode($text, 200, 200);
    ok($im, "$fmt: got image");
    if ($fmt eq "Palette") {
      is($im->type, "paletted", "$fmt: image is paletted");
      my @colors = sort { ($a->rgba)[0] <=> ($b->rgba)[0] } $im->getcolors;
      is_deeply([ ($colors[0]->rgba)[0, 1, 2] ], [ 64, 65, 66 ],
                "$fmt: check colors (low)");
      is_deeply([ ($colors[1]->rgba)[0, 1, 2] ], [ 255, 192, 193 ],
                "$fmt: check colors (high)");
    }
    else {
      is($im->type, "direct", "$fmt: image is direct");
    }
    if ($fmt eq "RGBA") {
      is($im->getchannels, 4, "$fmt: has 4 channels");
    }
    elsif ($fmt eq "Gray") {
      is($im->getchannels, 1, "$fmt: has 1 channel");
    }
    else {
      is($im->getchannels, 3, "$fmt: has 3 channels");
      my $usage = $im->getcolorusagehash();
      my @colors = sort keys %$usage;
      is(@colors, 2, "$fmt: two colors used");
      is($colors[0], "\x40\x41\x42", "$fmt: check fg color");
      is($colors[1], "\xFF\xC0\xC1", "$fmt: check bg color");
    }
  }
}

done_testing();
