use Test;
use Mail::CheckUser qw(:constants check_email last_check);

require 't/check.pl';

# syntax test
$Mail::CheckUser::Skip_Network_Checks = 1;

@ok_emails = qw(foo@aaa.bbb foo.bar@aaa.bbb foo@aaa.bbb.ccc foo.bar@aaa.bbb.ccc foo@aaa.aaa -gizmo-@mail.ru info@a--z.com a1a@b1.c b{x@a.a c~23@a.a);
@bad_emails = qw(bar@aaa .bar@aaa.bbb bar.@aaa.bbb bar@aaa.bbb. bar@.aaa.bbb <>[]@aaa.bbb brothren@hiron.bebrothren@hiron.bel.krid.crimea.ua a@a_a.a fred@aol foo@bar.w3c);
push @bad_emails, qw(akorobkova@yahoo/com ced);
push @bad_emails, 'ralph	fred@henry.com';
push @bad_emails, 'user@bad_domain.com';
push @ok_emails, q{jared's_brother@domain.com};
push @bad_emails, 'qqqqqqqqq wwwwwwww@test.com';
push @bad_emails, 'Ваш e-mail OlegNick@nursat.kz';
push @bad_emails, 'РусскийТекст@nursat.kz';

start(scalar(@ok_emails) + scalar(@bad_emails) + 8);

foreach my $email (@ok_emails) {
        run_test($email, 0);
}

foreach my $email (@bad_emails) {
        run_test($email, 1);
}

run_test('test@aaa.com', 0);
ok(last_check()->{code} == CU_OK);
ok(last_check()->{ok});
ok(defined last_check()->{reason});

run_test('testaaa.com', 1);
ok(last_check()->{code} == CU_BAD_SYNTAX);
ok(not last_check()->{ok});
ok(defined last_check()->{reason});
