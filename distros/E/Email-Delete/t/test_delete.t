use Test::More qw[no_plan];
use File::Path;
use strict;
$^W = 1;

BEGIN {
    use_ok 'Email::Delete', qw[delete_message];
}

my @boxes = ('t/Mail/Maildir/', 't/Mail/mbox', 't/Mail/mbox2');
seed_mail(@boxes);

foreach my $box (@boxes) {
    my $n = delete_message from     => $box,
                           matching => sub {
                               my $msg = shift;
                               $msg->header("From") =~ /casey\@geeknest\.com/;
                           };
    is $n, 2, "deleted proper messages for '$box'";
}

my $n = delete_message from     => $boxes[1],
                       matching => sub { 1 };
is $n, 1, 'calling delete on mbox again';

unseed_mail(@boxes);

sub seed_mail {
    my @boxes = @_;
    use_ok 'Email::LocalDelivery';
    unseed_mail(@boxes);

    
    my @from = ('casey@geeknest.com',
                'test@example.com',
                'casey@geeknest.com');
    my @to   = ('test@example.com',
                'casey@geeknest.com',
                'test@example.com');
    while ( my $from = shift @from ) {
        my $to = shift @to;
        Email::LocalDelivery->deliver(<<__MAIL__, @boxes);
From: $from
To: $to
Subject: Test message

Enjoy it.
__MAIL__
    }
}

sub unseed_mail {
    my @boxes = @_;
    rmtree 't/Mail';
}
