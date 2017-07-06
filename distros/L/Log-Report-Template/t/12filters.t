#!/usr/bin/env perl
# Test the additional filters.
use warnings;
use strict;

use lib 'lib';

use Test::More;

use_ok 'Log::Report::Template';

my $templater = Log::Report::Template->new;
isa_ok $templater, 'Log::Report::Template';

sub fill($$)
{   my ($input, $filter) = @_;
	my $templ = qq{[% "$input" | $filter %]};

    my $output = '';
    $templater->process(\$templ, {}, \$output)
		or die $templater->error;
    $output;
}

### cols

is fill("a", "cols"), "<td>a</td>", 'cols default';
is fill("a\tb\tc", "cols"), "<td>a</td><td>b</td><td>c</td>";

is fill("a", "cols('th')"), "<th>a</th>", 'cols first form';
is fill("a\tb\tc", "cols('th', 'td')"), "<th>a</th><td>b</td><td>c</td>";

is fill("a", "cols('<td align=left>\$1</td>')"), "<td align=left>a</td>"
  , 'cols second form';
is fill("a\tb\tc", "cols('\$3\$1')"), "ca";


### br

is fill("a\n", "br"), "a<br>\n", 'br';
is fill("a\nb\n", "br"), "a<br>\nb<br>\n", 'br simple';
is fill("  \t\na\n\n  \n\nb  \n\n", "br"), "a<br>\nb<br>\n", 'br cleanup';

done_testing;
