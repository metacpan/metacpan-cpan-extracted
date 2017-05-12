use strict;
use Test::More;

use FormValidator::Nested;
use FormValidator::Nested::ProfileProvider::YAML;
use Class::Param;
use Data::Visitor::Callback;

use utf8;

use Test::Fixture::DBIC::Schema;
use DBICx::TestDatabase;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('My::Schema');
construct_fixture(
    schema  => $schema,
    fixture => 't/var/fixture/test1.yml',
);


my ($fvt, $res, @error_params);

$fvt = FormValidator::Nested->new({
    profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
        dir     => 't/var/profile',
        visitor => Data::Visitor::Callback->new(
            plain_value => sub {
                my ( $self, $value ) = @_;
                if ( $value =~ m{__resultset\( (.+) \)__}xms ) {
                    $value = $schema->resultset($1);
                }
                return $value;
            },
        ),
    }),
});

{ # unique
    check({
        mail => 'chiba+unique@geminium.com',
    }, 'validator/dbic', 0);
    check({
        mail => 'chiba1@geminium.com',
    }, 'validator/dbic', 1, 'mail', 'メールアドレスは既に使われています');
    check({
        mail2 => 'chiba2@geminium.com',
    }, 'validator/dbic', 0);
    check({
        mail3 => 'chiba1@geminium.com',
    }, 'validator/dbic', 1, 'mail3', 'メールアドレス3は既に使われています');
}
{ # exist
    check({
        mail_exist => 'chiba+not_exist@geminium.com',
    }, 'validator/dbic', 1, 'mail_exist', 'メールアドレス_existは存在しません');
    check({
        mail_exist => 'chiba2@geminium.com',
    }, 'validator/dbic', 0);
}


sub check {
    my ($param, $key, $error, $param_name, $msg) = @_;

    $res = $fvt->validate(Class::Param->new($param), $key);

    is $res->has_error => $error;

    my $error_params = $res->error_params;

    if ( $error ) {
        is $error_params->{$param_name}->[0]->msg => $msg;
    }
}

done_testing;
