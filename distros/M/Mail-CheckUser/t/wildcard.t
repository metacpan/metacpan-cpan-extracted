use Mail::CheckUser qw(check_email);

require 't/check.pl';

# network test (SMTP check disabled)
$Mail::CheckUser::Skip_Network_Checks = 0;
$Mail::CheckUser::Skip_SMTP_Checks = 1;
$Mail::CheckUser::Timeout = 120;

@ok_emails = qw(m_ilya@hotmail.com);
@bad_emails = qw|
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.bogustld
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.com
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.net
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.nu
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.tk
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.cc
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.mp
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.ws
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.sh
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.pw
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.ph
  bogus@pqpqpqp-wildcard-qpqpqpqpqpq.ba
  |;

start(scalar(@ok_emails) + scalar(@bad_emails));

foreach my $email (@ok_emails) {
	run_test($email, 0);
}

foreach my $email (@bad_emails) {
	run_test($email, 1);
}
