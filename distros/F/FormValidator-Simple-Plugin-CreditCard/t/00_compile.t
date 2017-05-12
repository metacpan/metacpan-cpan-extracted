use strict;
use Test::More tests => 1;
use FormValidator::Simple;

eval{
    FormValidator::Simple->load_plugin('FormValidator::Simple::Plugin::CreditCard');
};
ok(!$@);
