requires 'perl', '5.024000';
requires 'JSON::MaybeXS', '0';
requires 'Promise::XS', '0.21';
requires 'Role::Tiny', '0';
requires 'XSLoader';

on configure => sub {
    requires 'Module::Build', '0.4005';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Deep', '1.205';
    requires 'Test::Exception', '0.43';
};

on 'develop' => sub {
    # graphql-perl is only used by util/ benchmark and profiling scripts
    # for cross-implementation comparison. lib/ no longer depends on it.
    requires 'GraphQL', '0.54';
};
