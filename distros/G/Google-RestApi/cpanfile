requires 'Cache::Memory::Simple';
requires 'Carp';
requires 'Exporter';
requires 'File::Slurp';
requires 'Furl';
requires 'Hash::Merge';
requires 'JSON::MaybeXS';
requires 'LWP::Protocol::https';
requires 'List::MoreUtils';
requires 'MIME::Base64';
requires 'MIME::Lite';
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
requires 'Type::Params', '>= 2.000000';
requires 'Types::Standard';
requires 'URI';
requires 'URI::QueryParam';
requires 'WWW::Google::Cloud::Auth::ServiceAccount';
requires 'YAML::Any';
requires 'aliased';
requires 'autodie';
requires 'autovivification';

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
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Perl::Critic';
    requires 'Perl::Critic::TooMuchCode';
};

on 'develop' => sub {
    requires 'Pod::Markdown';
};
