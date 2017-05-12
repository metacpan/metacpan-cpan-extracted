#!/usr/bin/env perl
#
# Test conversions from HTML/XHTML to postscript with HTML::FormatPS
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Body::Lines;

use Test::More;


BEGIN {
   
   eval 'require HTML::FormatPS';

   if($@)
   {   plan skip_all => "requires HTML::FormatPS.\n";
       exit 0;
   }

   require Mail::Message::Convert::HtmlFormatPS;
   plan tests => 5;
}

my $html  = Mail::Message::Convert::HtmlFormatPS->new;

my $body = Mail::Message::Body::Lines->new
  ( type => 'text/html'
  , data => $raw_html_data
  );

my $f = $html->format($body);
ok(defined $f);
ok(ref $f);
isa_ok($f, 'Mail::Message::Body');
is($f->type, 'application/postscript');
is($f->transferEncoding, 'none');

# The result of the conversion is not checked, because the output
# is rather large and may vary over versions of HTML::FormatPS
