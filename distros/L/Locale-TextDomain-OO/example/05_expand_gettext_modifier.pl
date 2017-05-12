#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use Locale::TextDomain::OO;

our $VERSION = 0;

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::Gettext ) ],
    logger  => sub { () = print shift, "\n" },
);
$loc->expand_gettext->modifier_code(
    sub {
        my ( $value, $attribute ) = @_;
        if ( $attribute eq 'num' ) {
            # set the , between 3 digits
            while ( $value =~ s{(\d+) (\d{3})}{$1,$2}xms ) {}
            # German number format
            $loc->language =~ m{\A de \b}xms
                and $value =~ tr{.,}{,.};
        }
        return $value;
    },
);

# run translations
() = print map {"$_\n"}
    'language is ' . $loc->language,
    $loc->__('{count :num} EUR', count => '12345678.90'),
    do {
        $loc->language('de');
        'language set to de';
    },
    $loc->__('{count :num} EUR', count => '12345678.90'),
    do {
        $loc->expand_gettext->clear_modifier_code;
        'modifier deleted';
    },
    $loc->__('{count :num} EUR', count => '12345678.90');

# $Id: 05_expand_gettext_modifier.pl 546 2014-10-31 09:35:19Z steffenw $

__END__

Output:

Using lexicon "de::". msgstr not found for msgctxt=undef, msgid="{count :num} EUR".
Using lexicon "de::". msgstr not found for msgctxt=undef, msgid="{count :num} EUR".
language is i-default
12,345,678.90 EUR
language set to de
12.345.678,90 EUR
modifier deleted
12345678.90 EUR
