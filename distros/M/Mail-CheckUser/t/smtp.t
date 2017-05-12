use Mail::CheckUser qw(check_email);

require './t/check.pl';

# network test (SMTP check enabled)
$Mail::CheckUser::Skip_Network_Checks = 0;
$Mail::CheckUser::Skip_SMTP_Checks = 0;
$Mail::CheckUser::Timeout = 120;

@ok_emails = qw(ilya@martynov.org brokenmx@yhoo.com);
@bad_emails = qw(unknown@for.bar freghrexquczew@gmail.com);

start(scalar(@ok_emails) + scalar(@bad_emails));

foreach my $email (@ok_emails) {
        run_test($email, 0);
}

foreach my $email (@bad_emails) {
        run_test($email, 1);
}
