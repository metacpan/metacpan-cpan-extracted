
use strict;
use Test::More tests => 4;
use utf8;

use_ok('Mail::Builder::Simple::Scalar');

my $template = Mail::Builder::Simple::Scalar->new;

can_ok($template, 'new');
can_ok($template, 'process');

is($template->process('template content ţâţă de mâţă'),
'template content ţâţă de mâţă', 'Scalar template OK');
