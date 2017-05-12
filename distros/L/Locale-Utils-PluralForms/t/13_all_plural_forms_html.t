#!perl -T

use strict;
use warnings;

use Test::More;

$ENV{TEST_AUTHOR}
    or plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';

SKIP: {
    plan(tests => 2 + 1);
    require Test::NoWarnings; Test::NoWarnings->import;
    use Test::Differences;
    use Test::Exception;

    use Locale::Utils::PluralForms;

    my $obj = Locale::Utils::PluralForms->new;

    lives_ok(
        sub {
            $obj->language('ru');
        },
        'language ru, load all plural forms from web page',
    );
    
    is_deeply(
        $obj->all_plural_forms->{ $obj->language },
        {            
            english_name => 'Russian',
            plural_forms => 'nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)',
        },
        'check downloaded plural forms for language ru',        
    );
}
