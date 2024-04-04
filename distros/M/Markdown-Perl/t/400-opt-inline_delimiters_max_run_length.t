use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert';
use Test2::V0;

# Ideally this would be tested by the GitHub test suite for which this is
# implemented but, as of writing, the cmark-gfm repo lags behind the public
# documentation for that syntax.
is(convert("***test***"), "<p><em><strong>test</strong></em></p>\n", 'default');
is(convert("***test***", inline_delimiters_max_run_length => {'*' => 3}), "<p><em><strong>test</strong></em></p>\n", 'max_length_3');
is(convert("***test***", inline_delimiters_max_run_length => {'*' => 2}), "<p>***test***</p>\n", 'max_length_2');

done_testing;
