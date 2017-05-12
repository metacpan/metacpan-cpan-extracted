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
