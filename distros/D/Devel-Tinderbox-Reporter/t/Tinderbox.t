#!perl

use Test::More tests => 4;

use_ok('Devel::Tinderbox::Reporter');

my $report = Devel::Tinderbox::Reporter->new({
                          from => 'schwern@pobox.com',
                          to   => 'schwern@pobox.com',
                          project => 'perl6',
                          boxname => 'Schwern blackrider Debian/PowerPC',
                          style   => 'unix/perl'
                         });
isa_ok($report, 'Devel::Tinderbox::Reporter');
is( $report->from,      'schwern@pobox.com',    'from()' );
is( $report->to,        'schwern@pobox.com',    'to()'   );
