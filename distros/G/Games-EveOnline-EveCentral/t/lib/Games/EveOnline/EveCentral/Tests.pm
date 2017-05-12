package Games::EveOnline::EveCentral::Tests;

use strict;


# ABSTRACT: Provides helper functions for tests.


our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION);
use Exporter;
$VERSION = 0.01;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(fake_http_response);
%EXPORT_TAGS = (
  all => [qw(fake_http_response)]
);


use Encode qw(encode);
use HTTP::Response;


sub fake_http_response {
  my $filename = shift;
  my $xml;

  {
    open (my $fh, '<', $filename) or die $!;
    local $/;
    $xml = <$fh>;
  }

  my $res = HTTP::Response->new;

  $res->code(200);
  $res->content(encode('utf-8', $xml));

  return $res;
}

1;
