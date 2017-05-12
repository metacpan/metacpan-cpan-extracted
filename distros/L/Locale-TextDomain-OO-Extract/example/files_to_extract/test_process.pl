#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::Gettext::Loc ) ],
);

$loc->loc_('This is an old text.');
$loc->loc_('This is a new text.');
$loc->loc_('January');

# $Id: test_process.pl 561 2014-11-11 16:12:48Z steffenw $
