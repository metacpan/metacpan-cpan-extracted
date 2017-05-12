use inc::Module::Install;

githubmeta;

name     'Fedora-Bugzilla';
all_from 'lib/Fedora/Bugzilla.pm';
author   'Chris Weyl <cweyl@alumni.drew.edu>';

no_index 'directory' => 'xt';

requires 'namespace::clean';

requires 'Crypt::SSLeay';   # https://... access to bugzilla
requires 'DateTime::Format::Pg';
requires 'Email::Address';
requires 'HTTP::Cookies';
requires 'MIME::Base64';
requires 'RPC::XML::Client';
requires 'Moose';
requires 'Moose::Util::TypeConstraints';
requires 'MooseX::AttributeHelpers' => '0.21';
requires 'MooseX::CascadeClearing';
requires 'MooseX::MultiInitArg';
requires 'MooseX::StrictConstructor';
requires 'MooseX::Traits::Attribute::CascadeClear';
requires 'MooseX::Traits::Attribute::CascadeClearMaster';
requires 'MooseX::Types';
requires 'MooseX::Types::DateTime';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Types::URI';
requires 'Regexp::Common';
requires 'URI::Fetch';
requires 'URI::Find';
requires 'XML::Twig';

# DateTime::Format::Bugzilla
#requires 'DateTime::Format::Builder';

test_requires 'Test::More';

extra_tests;
auto_provides;
auto_install;

WriteAll;

