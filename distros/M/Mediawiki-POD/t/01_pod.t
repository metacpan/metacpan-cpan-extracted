#!/usr/bin/perl -w

# some basic tests of Mediawiki::POD
use Test::More;

BEGIN
  {
  plan tests => 9;
  chdir 't' if -d 't';

  use lib '../lib';

  use_ok (qw/ Mediawiki::POD /);
  }

can_ok ( 'Mediawiki::POD', qw/
  new
  as_html
  remove_newlines
  body_only
  /);

my $pod = Mediawiki::POD->new();

is (ref($pod), 'Mediawiki::POD');

#############################################################################
# Some example input

my $input = <<EOF

=pod

=head1 NAME

=head2 Test

Some text

 Verbatim text

=cut

EOF
;

#############################################################################
# test the default options

my $html = $pod->as_html( $input );

like ($html, qr/<h1>.*NAME.*<\/h1>/, 'contains <h1>');
unlike ($html, qr/<(head|body|title)>/, 'contains no head, body or title section');
unlike ($html, qr/\n/, 'contains no newlines');

#############################################################################
# remove_newlines(0)

$pod->remove_newlines(0);

$html = $pod->as_html( $input );

like ($html, qr/<h1>(.|\n)*NAME(.|\n)*<\/h1>/, 'contains <h1>');
unlike ($html, qr/<(head|body|title)>/, 'contains no head, body or title section');
like ($html, qr/\n/, 'contains newlines');

