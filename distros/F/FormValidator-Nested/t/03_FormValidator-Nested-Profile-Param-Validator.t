use strict;
use Test::More;

use FormValidator::Nested;
use FormValidator::Nested::ProfileProvider::YAML;
use FormValidator::Nested::Validator::Email;

use Class::Param;

my $fvt = FormValidator::Nested->new({
    profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
        dir => 't/var/profile',
    }),
});


my $email_validator = $fvt->get_profile('index')->get_param('mail')->get_validator(0);

is validate($email_validator, Class::Param->new({
    mail     => 'chiba@geminium.com',
    password => 'hoge',
}))->has_error => 0;
is validate($email_validator, Class::Param->new({
    mail     => 'hoge',
    password => 'hoge',
}))->has_error => 1;


my $email_array_validator = $fvt->get_profile('index')->get_param('mail_array')->get_validator(0);

is validate($email_array_validator, Class::Param->new({
    mail_array => 'chiba@geminium.com',
    password   => 'hoge',
}))->has_error => 0;
is validate($email_array_validator, Class::Param->new({
    mail_array => 'chiba.@geminium.com',
    password   => 'hoge',
}))->has_error => 1;
is validate($email_array_validator, Class::Param->new({
    mail_array => ['chiba@geminium.com', 'chiba+hoge@geminium.com'],
    password   => 'hoge',
}))->has_error => 0;
is validate($email_array_validator, Class::Param->new({
    mail_array => ['chiba@geminium.com', 'chiba.@geminium.com'],
    password   => 'hoge',
}))->has_error => 1;
is validate($email_array_validator, Class::Param->new({
    mail_array => ['chiba.@geminium.com', 'chiba@geminium.com'],
    password   => 'hoge',
}))->has_error => 1;


my $email_array_required_validator = $fvt->get_profile('index')->get_param('mail_array_required')->get_validator(0);
# mail_array_requiredがない場合
is validate($email_array_required_validator, Class::Param->new({
    mail_array => 'chiba@geminium.com',
    password   => 'hoge',
}))->has_error => 1;
is validate($email_array_required_validator, Class::Param->new({
    mail_array_required => '',
    password   => 'hoge',
}))->has_error => 1;
is validate($email_array_required_validator, Class::Param->new({
    mail_array_required => ['chiba@geminium.com', ''],
    password   => 'hoge',
}))->has_error => 1;
is validate($email_array_required_validator, Class::Param->new({
    mail_array_required => 'chiba@geminium.com',
    password   => 'hoge',
}))->has_error => 0;




sub validate {
    my ( $validator, $req ) = @_;

    $validator->process($req, $validator->param->get_values($req));
}

done_testing;
