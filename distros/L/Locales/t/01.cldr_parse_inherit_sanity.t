use Test::More tests => 7;

BEGIN {
    use_ok('Locales');
}

diag("Testing Locales $Locales::VERSION");

is(
    Locales->new('fr')->{'language_data'}{'misc_info'}{'cldr_formats'}{'_decimal_format_group'},
    "\xC2\xA0",
    "XML parsed whitespace-only content properly"
);

isnt(
    Locales->new('pt_br')->{'language_data'}{'misc_info'}{'delimiters'}{'alternate_quotation_end'},
    undef(),
    "deep struct undef inherited"
);

isnt(
    ref( Locales->new('ak')->{'language_data'}{'misc_info'}{'delimiters'}{'alternate_quotation_end'} ),
    'HASH',
    "deep struct hash in XML value fetched"
);

is(
    Locales->new('ak')->{'language_data'}{'misc_info'}{'plural_forms'}{'category_list'}[-1],
    'other',
    '"other" default appended to plural-rule locales'
);

my $az = Locales->new('az');
is_deeply(
    $az->{'language_data'}{'misc_info'}{'plural_forms'}{'category_list'},
    ['other'],
    '"other" default appended to no-plural-rule locales'
);
is_deeply(
    $az->{'language_data'}{'misc_info'}{'plural_forms'}{'category_rules'},
    {},
    'no-plural-rule locales do not inherit from root/en/etc'
);
