use strict;
use warnings;

use File::Spec;

use HTML::Parser::Simple::Reporter;

use Test::More tests => 1;

# -----------------------------------

my($p) = HTML::Parser::Simple::Reporter -> new
(
	input_file => File::Spec -> catfile('data' ,'s.1.html'),
);


my(@got)      = @{$p -> traverse_file};
my($expected) = <<EOS;
html. Attributes: {}. Content:
  body. Attributes: {}. Content:
    img. Attributes: {alt => My pix, src => /My.Image.png}. Content:
    p. Attributes: {}. Content: Start of table.
    table. Attributes: {WIDTH => 660, align => center}. Content:
      tbody. Attributes: {}. Content:
        tr. Attributes: {}. Content:
          td. Attributes: {}. Content: td11
            br. Attributes: {}. Content:
            br. Attributes: {}. Content:
          td. Attributes: {}. Content: td12
            br. Attributes: {}. Content:
            br. Attributes: {}. Content:
        tr. Attributes: {}. Content:
          td. Attributes: {}. Content: td21
            br. Attributes: {}. Content:
            br. Attributes: {}. Content:
          td. Attributes: {}. Content: td22
            br. Attributes: {}. Content:
            br. Attributes: {}. Content:
    p. Attributes: {}. Content: End of table.
EOS

my(@expected) = split(/\n/, $expected);

is_deeply(\@got, \@expected, 'Got expected output of HTML::Parser::Simple::Reporter.traverse_file()');