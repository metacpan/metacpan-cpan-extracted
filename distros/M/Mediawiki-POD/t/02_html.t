#!/usr/bin/perl -w

# some basic tests of Mediawiki::POD::HTML
use Test::More;

BEGIN
  {
  plan tests => 5;
  chdir 't' if -d 't';

  use lib '../lib';

  use_ok (qw/ Mediawiki::POD::HTML /);
  }

can_ok ( 'Mediawiki::POD::HTML', qw/
  new
  get_headlines
  /);

my $pod = Mediawiki::POD::HTML->new();

is (ref($pod), 'Mediawiki::POD::HTML');

my ($url, $space) = $pod->keyword_search_url();

like ($url, qr/##KEYWORD##/, 'Some default keyword search');
is ($space, undef, 'Space will be either "+" or "_"');

