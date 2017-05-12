use Mail::CheckUser qw(check_email);

require 't/check.pl';

# network test (SMTP check disabled)
$Mail::CheckUser::Skip_Network_Checks = 0;
$Mail::CheckUser::Skip_SMTP_Checks = 1;
$Mail::CheckUser::Timeout = 120;

@ok_emails = qw(m_ilya@agava.com m_ilya@hotmail.com);
@bad_emails = qw(unknown@for.bar);

start(scalar(@ok_emails) + scalar(@bad_emails));

foreach my $email (@ok_emails) {
	run_test($email, 0);
}

foreach my $email (@bad_emails) {
	run_test($email, 1);
}
