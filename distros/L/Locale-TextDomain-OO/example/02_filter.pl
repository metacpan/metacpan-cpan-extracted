#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    plugins   => [ qw( Expand::Gettext::Loc ) ],
    logger    => sub { () = print shift, "\n" },
    filter    => sub {
        my ( $self, $translation_ref ) = @_;
        ${$translation_ref} .= ' filter added: ' . $self->language;
        return;
    },
);

# translation with empty default lexicon i-default::
() = print map { "$_\n" }
    $loc->loc_('Hello World 1!'),
    $loc->loc_('Hello World 2!');

#$Id: 02_filter.pl 573 2015-02-07 20:59:51Z steffenw $

__END__

Output:

Hello World 1! filter added: i-default
Hello World 2! filter added: i-default

