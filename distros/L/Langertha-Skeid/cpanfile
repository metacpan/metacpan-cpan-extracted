requires 'Digest::SHA', '6.02';
requires 'File::ShareDir', '1.118';
requires 'HTTP::Tiny', '0.080';
requires 'JSON::MaybeXS', '1.004004';
requires 'Langertha', '0.503';
requires 'Mojolicious', '9.0';
requires 'Moo', '2.005005';
requires 'namespace::clean', '0.27';
requires 'YAML::PP', '0.038';
recommends 'Cpanel::JSON::XS', '4.20';

# DBD::Pg also serves customer_source (ADR 0026), loaded only when the config has the section.
recommends 'DBD::Pg';
recommends 'DBD::SQLite', '1.66';
recommends 'DBI', '1.643';

on test => sub {
  requires 'Test2::Suite';
  requires 'Test::File::ShareDir';
  requires 'Test::Mojo';
};
