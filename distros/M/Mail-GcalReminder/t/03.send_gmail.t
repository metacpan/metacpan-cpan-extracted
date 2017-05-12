use Test::More tests => 17;

use Mail::GcalReminder;

diag("Testing Mail::GcalReminder $Mail::GcalReminder::VERSION");

my $gcr = Mail::GcalReminder->new( gmail_user => 'me@example.com', gmail_pass => "this_is_a_terrible_password" );

if ( $ENV{'RELEASE_TESTING'} && $Email::Send::SMTP::Gmail::VERSION > $gcr->essg_hax_ver ) {
    diag("ATTENTION!!! Email::Send::SMTP::Gmail was updated ($Email::Send::SMTP::Gmail::VERSION)! reverify hack and update essg_hax_ver()");
}

##### send_gmail ##

{
    my $new_test  = 0;
    my $bye_test  = 0;
    my $send_name = 'default';
    my $send_data = [
        'Email::Send::SMTP::Gmail',
        '-to',
        'to@to.to',
        '-from',
        'me@example.com',
        '-cc',
        'me@example.com',
        '-subject',
        'Subject',
        '-charset',
        'UTF-8
X-Priority: 1
Priority: Urgent
Importance: high
X-Confirm-Reading-To: me@example.com
Return-Receipt-To: me@example.com
Disposition-Notification-To: me@example.com',
        '-verbose',
        0,
        '-body',
        'Body Body Body

--
me@example.com (Mail::GcalReminder)

Note: Please ensure mail from “me@example.com” is not being filtered out of your inbox.'
    ];

    # Mock Email::Send::SMTP::Gmail
    my $ns = 'Email::Send::SMTP::Gmail';

    no warnings 'redefine';
    local $Email::Send::SMTP::Gmail::VERSION = $gcr->essg_hax_ver;

    local *Email::Send::SMTP::Gmail::new = sub {
        if ( !$new_test ) {
            is_deeply(
                \@_,
                [ $ns, '-smtp' => 'smtp.gmail.com', '-login' => 'me@example.com', '-pass' => 'this_is_a_terrible_password' ],
                "$ns->new called w/ expected args"
            );
            $new_test++;
        }

        return $ns;
    };

    local *Email::Send::SMTP::Gmail::send = sub {
        is_deeply( \@_, $send_data, "$ns->send() $send_name" );
    };

    local *Email::Send::SMTP::Gmail::bye = sub {
        if ( !$bye_test ) {
            ok( 1, "$ns->bye called" );
            $bye_test++;
        }
    };

    #### begin tests ##
    my @send_gmail_args = ( 'to@to.to', 'Subject', 'Body Body Body' );

    my $warn;
    $gcr->warning_code( sub { shift; $warn = shift } );

    # $send_name = 'default';
    $gcr->send_gmail(@send_gmail_args);

    $gcr->debug(1);
    $send_name       = "debug true";
    $send_data->[2]  = 'me@example.com';
    $send_data->[12] = 1;
    $gcr->send_gmail(@send_gmail_args);
    $send_data->[2]  = 'to@to.to';
    $send_data->[12] = 0;
    $gcr->debug(0);

    $gcr->try_priority(1);    # just being explicit
    $gcr->try_receipts(0);
    $send_name = "only try_priority";
    $send_data->[10] = 'UTF-8
X-Priority: 1
Priority: Urgent
Importance: high';
    $gcr->send_gmail(@send_gmail_args);

    $gcr->try_priority(0);
    $gcr->try_receipts(1);
    $send_name = "only try_receipts";
    $send_data->[10] = 'UTF-8
X-Confirm-Reading-To: me@example.com
Return-Receipt-To: me@example.com
Disposition-Notification-To: me@example.com';
    $gcr->send_gmail(@send_gmail_args);

    $gcr->try_priority(0);    # just being explicit
    $gcr->try_receipts(0);
    $send_name = "neither try_priority or try_receipts";
    $send_data->[10] = 'UTF-8';
    $gcr->send_gmail(@send_gmail_args);

    $gcr->cc_self(0);
    $send_name = "cc_self false";
    splice @{$send_data}, 5, 2;    #remove 5 and 6
    $gcr->send_gmail(@send_gmail_args);
    $gcr->cc_self(1);

    is( $warn, undef, 'warning() not called under normal circumstances' );

    #### new send version will call warning() and not do header ##
    my $n = 1;
    *Email::Send::SMTP::Gmail::send = sub {
        unlike( $_[10], qr/X-/, "no charset hack $n" ) if $n < 4;
    };
    $Email::Send::SMTP::Gmail::VERSION++;

    $gcr->try_priority(1);
    $gcr->try_receipts(1);
    $warn = undef;
    $gcr->send_gmail(@send_gmail_args);
    like( $warn, qr/Email::Send::SMTP::Gmail is newer than .*, skipping header-via-charset hack/, 'warning() called for charset hack version when both try_priority and try_receipts are in effect' );

    $n = 2;
    $gcr->try_priority(1);
    $gcr->try_receipts(0);
    $warn = undef;
    $gcr->send_gmail(@send_gmail_args);
    like( $warn, qr/Email::Send::SMTP::Gmail is newer than .*, skipping header-via-charset hack/, 'warning() called for charset hack version when only try_priority true' );

    $n = 3;
    $gcr->try_priority(0);
    $gcr->try_receipts(1);
    $warn = undef;
    $gcr->send_gmail(@send_gmail_args);
    like( $warn, qr/Email::Send::SMTP::Gmail is newer than .*, skipping header-via-charset hack/, 'warning() called for charset hack version when only try_receipts true' );

    $n = 4;
    $gcr->try_priority(0);
    $gcr->try_receipts(0);
    $warn = undef;
    $gcr->send_gmail(@send_gmail_args);
    is( $warn, undef, 'warning() not called for charset hack version when neither try_priority or try_receipts is in effect' );

    #### fatals reported ##
    no warnings 'redefine';
    *Email::Send::SMTP::Gmail::send = sub { die "wooooooops\n" };
    $warn = undef;
    $gcr->send_gmail(@send_gmail_args);
    is( $warn, "wooooooops\n", 'warning() is called w/ $@ when send has fatality' );
}
