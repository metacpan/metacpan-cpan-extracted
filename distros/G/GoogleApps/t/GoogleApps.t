package Tests::GoogleApps;
use Test::Class::Most parent => 'GoogleApps::TestClass';

BEGIN {
   use_ok 'GoogleApps';
}

sub test_new : Tests {
   my $app = GoogleApps->new();
   isa_ok $app, 'GoogleApps';
}

sub read_config_file : Tests {
   my $app = GoogleApps->new();
   isa_ok $app->config, 'HASH';
}

sub get_a_param_from_config_file : Tests {
   my $app = GoogleApps->new();
   cmp_ok($app->config->{admin}, 'eq', 'johndoe', 'admin is jonhdoe');
}

sub fail_trying_to_start_google_session : Tests {
   my $mock = Test::MockObject->new();
   $mock->fake_new('VUser::Google::ApiProtocol::V2_0');
   $mock->set_true('Login');
   $mock->set_false('IsAuthenticated');

   my $app = GoogleApps->new();
   throws_ok { $app->api() } qr/Authentication failed/, "Google Isn't Authenticated";
}
