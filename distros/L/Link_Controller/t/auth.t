=head1 DESCRIPTION

tests for LWP::Auth_UA authentication functions.

=cut

BEGIN {print "1..10\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

use LWP::Auth_UA;
$loaded=1;
ok(1);

$::credentials = {
  my_realm => { uri_re => "^https://myhost.example.com",
                credential => "my_secret" },
  my_unsafe_realm => { uri_re => ".*",
		       credential => "my_dummy_secret" }
} ;

my $ua=new LWP::Auth_UA;
ok(2);
$ua->auth_ua_credentials($::credentials);
ok(3);

my $warning;
my $oldwarn = $SIG{__WARN__};
$SIG{__WARN__} =sub { $warning=$_[0] };
$ua->delete_brain_dead_credentials();
$SIG{__WARN__}=$oldwarn; 

ok(4);
nogo unless $warning =~ m/Deleting credential/;
ok(5);
nogo if defined $::credentials->{my_unsafe_realm};
ok(6);
nogo unless defined $::credentials->{my_realm};
ok(7);
nogo if defined
  $ua->get_basic_credentials("other_realm", "https://myhost.example.com");
ok(8);
nogo if defined
  $ua->get_basic_credentials("my_realm", "https://otherhost.example.com");
ok(9);
nogo unless
  $ua->get_basic_credentials("my_realm", "https://myhost.example.com")
  eq "my_secret";
ok(10);
