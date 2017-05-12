use warnings;
use strict;

use Test::More tests => 3 + 3 + 6;

use JSON::RPC::LWP;

note q[setting 'from' during object creation];
{
  # 3
  my $email = 'user@example.com';
  my $rpc = new_ok(
    'JSON::RPC::LWP',
    [ from => $email ],
  );

  is $rpc->from, $email, q['from' attribute set];
  is $rpc->ua->from, $email, q['ua->from' has the same value];
}

note q[setting 'prefer_get' during object creation];
{
  # 3
  my $rpc = new_ok(
    'JSON::RPC::LWP',
    [ prefer_get => 1 ],
  );

  is $rpc->prefer_get, 1, q['prefer_get' attribute set];
  is $rpc->marshal->prefer_get, 1, q['marshal->prefer_get' has the same value];
};

sub type_constraint_error{
  my($error) = @_;
  $error = $@ unless $error;
  $error =~ /does not pass the type constraint/;
}

note q[Setting 'version' attribute];
{
  # 6

  my $rpc = new_ok(
    'JSON::RPC::LWP',
    [ version => 1.0 ],
  );

  is $rpc->version, '1.0', q['version' attribute has been set correctly];

  local $@;
  eval{
    $rpc->version(0);
  };
  ok type_constraint_error($@), 'fail when trying to set version to 0';

  local $@;
  eval{
    $rpc->version(1.01);
  };
  ok type_constraint_error($@), 'fail when trying to set version to 1.01';

  $rpc->version(1.1);
  is $rpc->version, 1.1, 'set version to 1.1';

  $rpc->version(1);
  is $rpc->version, '1.0', 'set version to 1 => 1.0';
}
