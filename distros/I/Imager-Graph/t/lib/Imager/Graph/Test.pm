package Imager::Graph::Test;
use strict;
use Test::More;
use Imager::Test qw(is_image_similar);

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(cmpimg);

our $VERSION = "0.10";

sub cmpimg ($$;$$) {
  my ($img, $filename, $error, $note) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  $note ||= $filename;
  $error ||= 10_000;
 SKIP: {
    $Imager::formats{png}
      or skip("png not available", 1);

    my $cmpim = Imager->new;
    if ($cmpim->read(file => $filename)) {
      is_image_similar($img, $cmpim, $error, $note);
    }
    else {
      fail("$note: load");
      diag("loading $filename: " . $cmpim->errstr);
    }
  }
}

1;
