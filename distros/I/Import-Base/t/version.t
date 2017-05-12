
use strict;
use warnings;
use lib 't/lib';
use Test::More;

subtest 'static API' => sub {

    subtest 'hashrefs' => sub {
        subtest 'version' => sub {
            subtest 'version too high' => sub {
                my $warn;
                local $SIG{__WARN__} = sub { $warn = $_[0] };
                eval q{
                    package static::version::bad;
                    use MyStaticVersion 'Bad';
                };
                delete $SIG{__WARN__};

                like $@, qr/MyVersioned version 9999 required/;
                ok !$warn, 'no warnings' or diag $warn;
            };

            subtest 'version okay' => sub {
                my $warn;
                local $SIG{__WARN__} = sub { $warn = $_[0] };
                eval q{
                    package static::version::okay;
                    use MyStaticVersion 'Good';
                };
                delete $SIG{__WARN__};

                unlike $@, qr/MyVersioned version 9999 required/;
                ok !$@, 'lived' or diag $@;
                ok !$warn, 'no warnings' or diag $warn;
            };

            subtest 'version too high with args' => sub {
                my $warn;
                local $SIG{__WARN__} = sub { $warn = $_[0] };
                eval q{
                    package static::version::bad_args;
                    use MyStaticVersion 'BadArgs';
                    foo();
                };
                delete $SIG{__WARN__};

                like $@, qr/MyVersionedExporter version 9999 required/;
                ok !$warn, 'no warnings' or diag $warn;
            };

            subtest 'version okay' => sub {
                my $warn;
                local $SIG{__WARN__} = sub { $warn = $_[0] };
                eval q{
                    package static::version::okay_args;
                    use MyStaticVersion 'GoodArgs';
                    foo();
                };
                delete $SIG{__WARN__};

                unlike $@, qr/MyVersionedExporter version 9999 required/;
                ok !$@, 'lived' or diag $@;
                ok !$warn, 'no warnings' or diag $warn;
            };
        };
    };
};

done_testing;
