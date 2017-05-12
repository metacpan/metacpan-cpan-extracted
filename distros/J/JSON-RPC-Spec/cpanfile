requires 'JSON::MaybeXS';
requires 'Moo';
requires 'Moo::Role';
requires 'Router::Simple';
requires 'Try::Tiny';
requires 'namespace::clean';
requires 'version';

recommends 'Cpanel::JSON::XS';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'Test::Fatal';
    requires 'Test::More', '0.98';
};
