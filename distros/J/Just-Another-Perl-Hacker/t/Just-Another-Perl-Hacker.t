# 
# $Id: Just-Another-Perl-Hacker.t,v 0.1 2006/03/25 12:13:58 dankogai Exp dankogai $
#
use strict;
use warnings;
use Test::More tests => 7;
BEGIN { use_ok('Just::Another::Perl::Hacker') };
my $japh;

$japh = 'Just Another Perl Hacker';
is((Just Another Perl Hacker), $japh, $japh);
$japh = 'Just Another Perl Porter';
is((Just Another Perl Porter), $japh, $japh);
$japh = 'Just Another Perl Poet';
is((Just Another Perl Poet), $japh, $japh);

$japh = 'Yet Another Perl Hacker';
is((Yet Another Perl Hacker), $japh, $japh);
$japh = 'Yet Another Perl Porter';
is((Yet Another Perl Porter), $japh, $japh);
$japh = 'Yet Another Perl Poet';
is((Yet Another Perl Poet), $japh, $japh);
