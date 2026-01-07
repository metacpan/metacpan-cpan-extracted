requires 'Cache::Memory::Simple';
requires 'Carp';
requires 'Exporter';
requires 'File::Slurp';
requires 'Furl';
requires 'Hash::Merge';
requires 'JSON::MaybeXS';
requires 'LWP::Protocol::https';
requires 'List::MoreUtils';
requires 'List::Util';
requires 'Log::Log4perl';
requires 'Module::Load';
requires 'Net::OAuth2::Client';
requires 'Net::OAuth2::Profile::WebServer';
requires 'PerlX::Maybe';
requires 'Readonly';
requires 'Retry::Backoff';
requires 'Scalar::Util';
requires 'Storable';
requires 'Term::Prompt';
requires 'Tie::Hash';
requires 'ToolSet';
requires 'Try::Tiny';
requires 'Type::Params', '== 1.004004';
requires 'Types::Standard';
requires 'URI';
requires 'URI::QueryParam';
requires 'WWW::Google::Cloud::Auth::ServiceAccount';
requires 'YAML::Any';
requires 'aliased';
requires 'autodie';
requires 'autovivification';
requires 'constant';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on build => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Sub::Override';
    requires 'Test::Class';
    requires 'Test::Class::Load';
    requires 'Test::Deep';
    requires 'Test::Most';
    requires 'Test::Perl::Critic';
    requires 'Perl::Critic::TooMuchCode';
};
