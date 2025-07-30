use strict;
use warnings;
use Test::More 0.98;

BEGIN {
    use_ok 'Getopt::EX::i18n';
}

# Test LocaleObj class
{
    my $obj = Local::LocaleObj->create('ja_JP');
    isa_ok $obj, 'Local::LocaleObj';
    is $obj->name, 'ja_JP', 'name method works';
    is $obj->lang, 'ja', 'lang method works';
    is $obj->cc, 'JP', 'cc method works';
    
    # Test lang_name and cc_name methods
    ok $obj->lang_name, 'lang_name returns value';
    ok $obj->cc_name, 'cc_name returns value';
    
    # Test with known locale
    like $obj->lang_name, qr/japanese/i, 'Japanese language name';
    like $obj->cc_name, qr/japan/i, 'Japan country name';
}

# Test setopt function
{
    # Test setopt (function exists and can be called)
    ok eval { Getopt::EX::i18n::setopt(verbose => 1, list => 1); 1 }, 'setopt function works';
    
    # Reset options
    Getopt::EX::i18n::setopt(verbose => 0, list => 0);
    ok 1, 'setopt can reset options';
}

# Test setenv function
{
    local %ENV;
    
    Getopt::EX::i18n::setenv('LANG', 'ja_JP.UTF-8');
    is $ENV{LANG}, 'ja_JP.UTF-8', 'setenv sets environment variable';
    
    # Test multiple pairs
    Getopt::EX::i18n::setenv('LC_ALL', 'en_US.UTF-8', 'LC_TIME', 'fr_FR.UTF-8');
    is $ENV{LC_ALL}, 'en_US.UTF-8', 'setenv sets first pair';
    is $ENV{LC_TIME}, 'fr_FR.UTF-8', 'setenv sets second pair';
}

# Test setup function
{
    # Skip if locale command is not available
    SKIP: {
        skip "locale command not available", 1 unless grep { -x "$_/locale" } split /:/, $ENV{PATH};
        
        # Test that setup function can be called
        ok eval { Getopt::EX::i18n::setup(); 1 }, 'setup function works';
    }
}

done_testing;