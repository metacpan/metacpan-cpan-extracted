use strict;
use warnings;
use Test::More;
use_ok('Markdown::Pod::Embed');
ok(!exists($INC{'ExtUtils/MakeMaker.pm'}), 'processor does not load MakeMaker');
done_testing();
