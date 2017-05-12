use strict;
use warnings;

use Test::More;
use HTML::Restrict;
use Scalar::Util qw(weaken);

# Ensure that we don't have any circular references between the HTML::Restrict
# object and its parser.
my $hr = HTML::Restrict->new;
my $p  = $hr->parser;

my $weak_hr = $hr;
my $weak_p  = $p;
weaken($weak_hr);
weaken($weak_p);

undef $hr;
undef $p;

ok !defined $weak_hr, 'HTML::Restrict freed; no circular reference.';
ok !defined $weak_p,  'HTML::Parser freed; no circular reference.';

done_testing();
