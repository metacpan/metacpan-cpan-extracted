use strict;
use warnings FATAL => 'all';
use Test::More 'no_plan';

sub wsis {
	my $got      = shift;
	my $expected = shift;
	s/\s//gs for $got, $expected;
	unshift @_, $got, $expected;
	goto \&is;
}

use HTML::Zoom;

my $template = <<HTML;
<html>
  <body></body>
</html>
HTML

my $expect = <<HTML;
<html>
  <body>Hello</body>
</html>
HTML

my $output = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
  ->from_html($template)
  ->apply_if(1, sub { $_->select('body')->replace_content('Hello') })
  ->to_html;

wsis( $output => $expect, 'apply_if with a true predicate' );

$output = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
  ->from_html($template)
  ->apply_if(0, sub { $_->select('body')->replace_content('Hello') })
  ->to_html;

wsis( $output => $template, 'apply_if with a false predicate' );
