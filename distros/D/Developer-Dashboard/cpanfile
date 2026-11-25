on 'configure' => sub {
    requires 'File::ShareDir::Install';
};

requires 'perl', '5.038';
requires 'Filter::Simple';
requires 'JSON::XS', '4.04';
requires 'YAML::XS', '0.903.0';
requires 'TOML::Parser';
requires 'Capture::Tiny', '0.24';
requires 'Getopt::Long';
requires 'Digest::MD5', '2.25';
requires 'Crypt::URandom', '0.55';
requires 'Digest::SHA', '5.96';
requires 'String::Compare::ConstantTime', '0.321';
requires 'Archive::Tar', '3.10';
requires 'Archive::Zip', '1.61';
requires 'MIME::Base64';
requires 'Compress::Raw::Zlib', '2.220';
requires 'IO::Compress::Gzip', '2.220';
requires 'IO::Uncompress::Gunzip', '2.220';
requires 'Cpanel::JSON::XS', '4.80';
requires 'Dancer2', '2.2.0';
requires 'Plack', '1.0056';
requires 'Pod::Text', '6.1.1';
requires 'YAML', '1.30';
requires 'Socket', '2.041';
requires 'Starman', '0.4019';
requires 'Storable', '3.41';
requires 'HTML::Parser', '3.84';
requires 'HTTP::Date', '6.08';
requires 'HTTP::Parser::XS', '0.18';
requires 'HTTP::Tiny', '0.096';
requires 'HTTP::Request';
requires 'LWP::Protocol::https', '6.07';
requires 'LWP::UserAgent', '6.83';
# Prevent historical and 2026-10 CA-bundle vulnerability resolutions.
requires 'Mozilla::CA', '20261020';
requires 'Template', '3.103';
requires 'URI', '5.36';
requires 'URI::Escape', '5.36';
requires 'XML::Parser', '2.48';

on 'test' => sub {
    # Windows development installs retain an optional coverage dependency.
    # Windows CI explicitly installs Devel::Cover and fails if unavailable.
    # This keeps the production dependency tree independent of instrumentation.
    requires 'Devel::Cover' if $^O ne 'MSWin32';
    requires 'Test::Harness', '3.48';
    requires 'TAP::Harness::Env', '3.29';
    requires 'CPAN::Audit';
};

on 'develop' => sub {
    recommends 'DBI';
    recommends 'DBD::SQLite';
    recommends 'DBD::mysql';
    recommends 'DBD::Pg';
    recommends 'DBD::ODBC';
    recommends 'DBD::Oracle';
};
