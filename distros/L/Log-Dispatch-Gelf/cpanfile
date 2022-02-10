requires 'perl', '5.010';
requires 'Log::Dispatch';
requires 'Log::GELF::Util', '>= 0.90';
requires 'Params::Validate';

recommends 'Cpanel::JSON::XS', '4';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Mock::Quick', '1.107';
    requires 'Test::Exception', '0.31';
    requires 'JSON::MaybeXS';
};

on 'develop' => sub {
  requires 'Minilla';
  requires 'Version::Next';
  requires 'CPAN::Uploader';
  requires 'Test::CPAN::Meta';
  requires 'Test::MinimumVersion::Fast';
  requires 'Test::PAUSE::Permissions';
};
