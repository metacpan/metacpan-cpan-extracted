use strict;
use Test::More;

use FormValidator::Nested::ProfileProvider::YAML;

use lib 't/lib';

my $provider_yaml = FormValidator::Nested::ProfileProvider::YAML->new({
    dir => 't/var/profile/',
});
ok !$provider_yaml->_exists_profile('index');


# extendsのチェックもいっしょに
for my $key ('index', 'foo/extends', 'foo/extends_only') {
    is $provider_yaml->get_profile($key)->get_param('mail')->key => 'mail';
    is $provider_yaml->get_profile($key)->get_param('mail')->get_validator(0)->class => 'FormValidator::Nested::Validator::Email';
    is $provider_yaml->get_profile($key)->get_param('mail')->get_validator(0)->method => 'email';
    is $provider_yaml->get_profile($key)->get_param('mail')->get_validator(1)->class => 'FormValidator::Nested::Validator::String';
    is $provider_yaml->get_profile($key)->get_param('mail')->get_validator(1)->method => 'max_length';
    is_deeply $provider_yaml->get_profile($key)->get_param('mail')->get_validator(1)->options => {
        max => 100,
    };
}
# extendsへの拡張
is $provider_yaml->get_profile('foo/extends')->get_param('mail_array')->get_validator(0)->class => 'FormValidator::Nested::Validator::Blank';
is $provider_yaml->get_profile('foo/extends')->get_param('mail_array')->get_validator(0)->method => 'not_blank';

is $provider_yaml->get_profile('foo/bar')->get_param('password')->key => 'password';
is $provider_yaml->get_profile('foo/bar')->get_param('password')->get_validator(0)->class => 'FormValidator::Nested::Validator::String';
is $provider_yaml->get_profile('foo/bar')->get_param('password')->get_validator(0)->method => 'max_length';
is_deeply $provider_yaml->get_profile('foo/bar')->get_param('password')->get_validator(0)->options => {
    max => 16
};

# init_read_all_profileのチェック
my $provider_yaml_init_all = FormValidator::Nested::ProfileProvider::YAML->new({
    dir => 't/var/profile/',
    init_read_all_profile => 1,
    filter => sub {
        my $data = shift;
        $data->{____hogehogehoge___} = 1;
    },
});

ok $provider_yaml_init_all->_exists_profile('index');

# filter-test
is $provider_yaml_init_all->get_profile('index')->data->{____hogehogehoge___} => 1;



done_testing;
