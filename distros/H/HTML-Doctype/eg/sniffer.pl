#!/usr/bin/perl -w
use strict;
use warnings;
use LWP::Simple qw(get);
use HTML::Doctype;
use SGML::Parser::OpenSP;

# TODO: This should detect the encoding and transcode
# the input before passing it to SGML::Parser::OpenSP

if (@ARGV != 1) {
  print "Usage: $0 http://example.org\n";
  exit;
}

my $p = SGML::Parser::OpenSP->new;
my $h = HTML::Doctype::Detector->new($p);
$p->handler($h);
$p->parse_string(get($ARGV[0]));

printf "The document %s has a %s DOCTYPE\n",
  $ARGV[0], $h->is_xhtml ? 'XHTML' : 'HTML';
