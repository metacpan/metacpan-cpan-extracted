#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::Maketext ) ],
    logger  => sub { () = print shift, "\n" }
);
$loc->expand_maketext->formatter_code(
    sub {
        my $value = shift;
        # set the , between 3 digits
        while ( $value =~ s{(\d+) (\d{3})}{$1,$2}xms ) {}
        # German number format
        $loc->language =~ m{\A de \b}xms
            and $value =~ tr{.,}{,.};
        return $value;
    },
);

# run translations
() = print map {"$_\n"}
    'language is ' . $loc->language,
    $loc->maketext('[*,_1,EUR]', '12345678.90'),
    do {
        $loc->language('de');
        'language set to de';
    },
    $loc->maketext('[*,_1,EUR]', '12345678.90'),
    do {
        $loc->expand_maketext->clear_formatter_code;
        'formatter_code deleted';
    },
    $loc->maketext('[*,_1,EUR]', '12345678.90');

# $Id: 06_expand_maketext_formatter_code.pl 546 2014-10-31 09:35:19Z steffenw $

__END__

Output:

Using lexicon "de::". msgstr not found for msgctxt=undef, msgid="[*,_1,EUR]".
Using lexicon "de::". msgstr not found for msgctxt=undef, msgid="[*,_1,EUR]".
language is i-default
12,345,678.90 EUR
language set to de
12.345.678,90 EUR
formatter_code deleted
12345678.90 EUR
