#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::Gettext::Loc ) ],
);

$loc->loc_('January');
$loc->loc_x('This is a new {thing}.', thing => 'text');

# $Id: gettext_loc.pl 561 2014-11-11 16:12:48Z steffenw $
