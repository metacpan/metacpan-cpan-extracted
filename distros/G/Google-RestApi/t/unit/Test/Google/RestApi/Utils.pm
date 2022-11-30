package Test::Google::RestApi::Utils;

# Utils is not a class, but it's the only module that's not a class module, so use the same
# Test::Class pattern that the rest of the tests use so we don't have to do something
# different for this one module. prefix each test with 'test_' so it doesn't get mixed up
# with the sub names in the Utils module we're testing. for the other modules that use actual
# classes, there is no sub name clash since we're using class instances to call the subs.

use Test::Unit::Setup;

use parent 'Test::Unit::TestBase';

use Google::RestApi::Utils qw(:all);

sub test_named_extra : Tests(2) {
  my %args = ( validated => {} );
  throws_ok sub { named_extra(%args); }, qr/Missing required/i, "named_extra: No _extra_ key throws";
  %args = ( _extra_ => { joe => 'fred' } );
  is_deeply named_extra(%args), $args{_extra_}, "named_extra: Returns the _extra_ hash";
  return;
}

sub test_merge_config_file : Tests(3) {
  my %config = ( joe => 'fred' );
  is_deeply merge_config_file(%config), \%config, "merge_config_file: Returns the original hash";

  $config{config_file} = 'x';
  throws_ok sub { merge_config_file(%config); }, qr/did not pass type constraint/i, "merge_config_file: Invalid file throws";

  $config{config_file} = fake_config_file();
  cmp_ok scalar keys(%config), '>', 1, "merge_config_file: Merging a file returns full hash";

  return;
}

sub test_resolve_config_file_path : Tests(5) {
  my %config = ( joe => 'fred' );
  
  is resolve_config_file_path(\%config, 'x'), undef, "resolve_config_file_path: Returns undef on invalid key";

  $config{config_file} = fake_config_file();
  is resolve_config_file_path(\%config, 'config_file'), $config{config_file}, "resolve_config_file_path: Returns the original full file path";

  $config{token_file} = 'rest_config.token';
  is resolve_config_file_path(\%config, 'token_file'), fake_token_file(), "resolve_config_file_path: Returns full token file path";
  is $config{token_file}, fake_token_file(), "resolve_config_file_path: Token file path updated in config";

  $config{x_file} = 'x';
  throws_ok sub { resolve_config_file_path(\%config, 'x_file'); }, qr/Unable to resolve/i, "resolve_config_file_path: throws on invalid file path";

  return;
}

sub test_bool : Tests(7) {
  # bool clashes with Test::Deeply::bool.
  is bool(), 'true', "bool: passing undef returns true";
  is bool('true'), 'true', "bool: passing true returns true";
  is bool('false'), 'false', "bool: passing false returns false";
  is bool('TRUE'), 'true', "bool: passing TRUE returns true";
  is bool('FALSE'), 'false', "bool: passing FALSE returns false";
  is bool(1), 'true', "bool: passing 1 returns true";
  is bool(0), 'false', "bool: passing 0 returns false";
  return;
}

1;
