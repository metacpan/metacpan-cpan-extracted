use strict;
use Test::More;
use Test::Exception;

use FormValidator::Nested;
use FormValidator::Nested::ProfileProvider::YAML;
use Class::Param;

my $fvt;

throws_ok {
    $fvt = FormValidator::Nested->new({
        profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
            dir => 't/var/exception_profile',
            init_read_all_profile => 1,
        }),
    });
} qr/no require FormValidator::Nested::Validator::Exception/, 'no require';


$fvt = FormValidator::Nested->new({
    profile_provider => FormValidator::Nested::ProfileProvider::YAML->new({
        dir => 't/var/profile',
    }),
});

throws_ok {
    $fvt->validate({}, 'invalid');
} qr/not found profile /, 'no found profile';

dies_ok { $fvt->validate($fvt, 'basic') };

is $fvt->get_profile('invalid') => 0;

check_validate({
} => 1);
check_validate({
    hoge => 'a',
} => 1);
check_validate({
    mail => 'a',
} => 1);
check_validate({
    mail => 'chiba@geminium.com',
} => 1);
check_validate({
    mail => 'chiba.@geminium.com',
} => 1);

check_validate({
    mail_require => 'chiba@geminium.com',
} => 0);
check_validate({
    mail_require => 'chiba.@geminium.com',
} => 1);

check_validate({
    mail         => 'chiba@geminium.com',
    mail_require => 'chiba@geminium.com',
} => 0);
check_validate({
    mail         => 'chiba.@geminium.com',
    mail_require => 'chiba@geminium.com',
} => 1);
check_validate({
    mail         => 'chiba@geminium.com',
    mail_require => 'chiba.@geminium.com',
} => 1);


sub check_validate {
    my ($req_hash, $error) = @_;
    is $fvt->validate(Class::Param->new($req_hash), 'basic')->has_error => $error;
    is $fvt->validate($req_hash, 'basic')->has_error => $error;
}


done_testing;
