#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok ( "HTML::Native::Document" );
}

foreach my $subclass ( qw ( XHTML10::Strict XHTML10::Transitional
			    XHTML10::Frameset XHTML11
			    HTML401::Strict HTML401::Transitional
			    HTML401::Frameset ) ) {
  my $doctype = "HTML::Native::Document::".$subclass;

  # new()

  {
    my $doc = $doctype->new ( "Welcome" );
    isa_ok ( $doc, $doctype );
    isa_ok ( $doc, "HTML::Native" );
    is ( $$doc, "html" );
    like ( $doc, qr/^<!DOCTYPE/m );
    if ( $doctype =~ /XHTML/ ) {
      like ( $doc, qr/^<\?xml/ );
      is ( $doc->{xmlns}, "http://www.w3.org/1999/xhtml" );
    } else {
      unlike ( $doc, qr/^<\?xml/ );
    }
  }

  # head()

  {
    my $doc = $doctype->new ( "Welcome" );
    my $head = $doc->head();
    isa_ok ( $head, "HTML::Native" );
    is ( $$head, "head" );
    is ( $head, "<head><title>Welcome</title></head>" );
  }

  # body()

  {
    my $doc = $doctype->new ( "Welcome" );
    my $body = $doc->body();
    isa_ok ( $body, "HTML::Native" );
    is ( $$body, "body" );
    push @$body, [ h1 => "Hello world" ];
    is ( $body, "<body><h1>Hello world</h1></body>" );
  }

  # title()

  {
    my $doc = $doctype->new ( "Welcome" );
    my $title = $doc->title();
    isa_ok ( $title, "HTML::Native" );
    is ( $$title, "title" );
    is ( $title, "<title>Welcome</title>" );
  }

}

done_testing();
