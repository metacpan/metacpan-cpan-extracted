#!/usr/bin/perl
use strict;
use warnings;

use MIME::Lite;
use Test::More tests => 3;

my $msg = MIME::Lite->new( Type => "multipart/digest" );
$msg->attr( 'MIME-Version' => 'qqq' );

my $str = $msg->as_string;

like(
  $str,
  qr/MIME-Version: qqq/,
  '"MIME-Version" header has been set to qqq'
);

unlike(
  $str,
  qr/MIME-Version: 1\.0/,
  'default header "MIME-Version: 1.0" is no longer found'
);

is(
  $str =~ s/MIME-Version: /counted/g,
  1,
  'only one MIME-Version header present',
);
