#!perl

# Very Contrived example. This module is used for doing boring
# stuff internally by me, so it took a while to find an example
# that wasn't very obviously better done by WWW::Mechanize...

use strict;
use warnings;

use LWP::Simple::Post qw(post);
use URI::Escape;

my $term = $ARGV[0] || 'JAPH';

my $result = post(
	'http://www.dict.org/bin/Dict',
	'Form=Dict1&Strategy=*&Database=vera&Query=' . $term);

my ( $definition ) = $result =~ m!<pre>([^<]{10,})</pre>!s;
print $definition;