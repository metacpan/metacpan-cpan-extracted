use 5.010;
use strict;
use warnings;
use Test::More;

use GitHub::Config::SSH::UserData qw(get_user_data_from_ssh_cfg);

plan(skip_all => "These tests run only in developer's local environment") if $ENV{NO_LOCAL_TESTS};

unless ($ENV{NO_LOCAL_TESTS}) {
  note('Test with my local ');
  my $result = get_user_data_from_ssh_cfg('klaus-rindfrey');
  ok(exists($result->{email})  && $result->{email} =~ /rindfrey/, "default config file: email");
  ok(exists($result->{email2}) && $result->{email2} eq 'klausrin@cpan.org',
     "default config file: email");
  ok(exists($result->{full_name}) && $result->{full_name} eq 'Klaus Rindfrey',
     "default config file: full_name");
}


#==================================================================================================
done_testing();
