use Test::More tests => 34;
use Test::Warn;

use Mail::GcalReminder;

diag("Testing Mail::GcalReminder $Mail::GcalReminder::VERSION");

my $gcr = Mail::GcalReminder->new( gmail_user => 'me@example.com', gmail_pass => "this_is_a_terrible_password" );

#### set up ##

{
    no warnings 'redefine';
    *Mail::GcalReminder::send_gmail = sub { return 1 };
}

my $target = $gcr->base_date->clone();
$target->add( 'days' => 2 );
my $target_str = $target->format_cldr("E MMM d");    # 'Tue Jan 28'

$gcr->gcal_cache(
    {
        'noevent'        => {},
        'min_max_events' => {
            $target_str => [ { 'guests' => [1] }, { 'guests' => [1] } ],
        },
        'no_guests' => {
            $target_str => [ { title => 'my event' }, { title => 'my event 2', 'guests' => [1] } ],
        },
        'guests' => {
            $target_str => [ { title => 'my event', 'guests' => [ 1, 2 ] }, { title => 'my event 2', 'guests' => [ 1, 2 ] } ],
        },
    }
);

warnings_like {
    $gcr->send_reminders( { 'gcal' => 'no_guests', 'in_advance' => [ 'days' => 2 ] } );
}
qr/No guests for “my event”\. at \Q$0\E line @{[ __LINE__-2]}/, 'warnings() indirectly has caller at-line';

my $warn;
$gcr->warning_code( sub { $warn .= "$_[1]\n" } );

#### send_reminders ##

# zero but true when no events
my $rc = $gcr->send_reminders( { 'gcal' => 'noevent' } );
is( $rc, "0E0", 'no events rc is zero-but-true' );
cmp_ok( $rc, '==', 0, "no events rc is zero" );
ok( $rc, "no events rc is true" );

# warning() when min_events
$gcr->send_reminders( { 'gcal' => 'min_max_events', 'in_advance' => [ 'days' => 2 ], 'min_events' => 3 } );
like( $warn, qr/Not enough events \(min 3, actual 2\) for “min_max_events”\./, 'min_events not met triggers warning (label default to gcal)' );

# warning() when max_events
$gcr->send_reminders( { 'gcal' => 'min_max_events', 'in_advance' => [ 'days' => 2 ], 'max_events' => 1, 'label' => 'my label' } );
like( $warn, qr/Too many events \(max 1, actual 2\) for “my label”\./, 'max_events not met triggers warning (label applies when given)' );

# no warning() when min_events
# no warning() when max_events
$warn = undef;
$gcr->send_reminders( { 'gcal' => 'min_max_events', 'in_advance' => [ 'days' => 2 ], 'min_events' => 1, 'max_events' => 3 } );
is( $warn, undef, 'no warnings when min_events and max_events are below and above the count respectively' );

$warn = undef;
$gcr->send_reminders( { 'gcal' => 'min_max_events', 'in_advance' => [ 'days' => 2 ], 'min_events' => 2, 'max_events' => 2 } );
is( $warn, undef, 'no warnings when min_events and max_events are at the count' );

# no guests: warning()
$warn = undef;
$gcr->no_guests_is_ok(1);
my $rv_ok = $gcr->send_reminders( { 'gcal' => 'no_guests', 'in_advance' => [ 'days' => 2 ] } );
like( $warn, qr/No guests for “my event”\./, 'no guests trigger warnings when no_guests_is_ok(1)' );

$warn = undef;
$gcr->no_guests_is_ok(0);
my $rv_no = $gcr->send_reminders( { 'gcal' => 'no_guests', 'in_advance' => [ 'days' => 2 ] } );
like( $warn, qr/No guests for “my event”\./, 'no guests trigger warnings when no_guests_is_ok(0)' );

# no guests: RV when no_guests_is_ok(1)
is( $rv_ok, 2, 'no guests RV when no_guests_is_ok(1)' );

# no guests: RV when no_guests_is_ok(0)
is( $rv_no, undef, 'no guests RV when no_guests_is_ok(0)' );

# guests:
#   warning() min_guests
$warn = undef;
$gcr->send_reminders( { 'gcal' => 'guests', 'in_advance' => [ 'days' => 2 ], 'min_guests' => 3 } );
like( $warn, qr/Not enough guests \(min 3, actual 2\) for “my event”\./, 'min_guests not met triggers warning (label default to gcal)' );

#   warning() max_guests
$warn = undef;
$gcr->send_reminders( { 'gcal' => 'guests', 'in_advance' => [ 'days' => 2 ], 'max_guests' => 1 } );
like( $warn, qr/Too many guests \(max 1, actual 2\) for “my event”\./, 'max_events not met triggers warning (label applies when given)' );

#   no warning() min_guests
#   no warning() max_guests
$warn = undef;
$gcr->send_reminders( { 'gcal' => 'guests', 'in_advance' => [ 'days' => 2 ], 'min_guests' => 1, 'max_guests' => 3 } );
is( $warn, undef, 'no warnings when min_guests and max_events are below and above the count respectively' );

$warn = undef;
$gcr->send_reminders( { 'gcal' => 'guests', 'in_advance' => [ 'days' => 2 ], 'min_guests' => 2, 'max_guests' => 2 } );
is( $warn, undef, 'no warnings when min_guests and max_events are at the count' );

#   send_gmail() called && sub/body as string
{
    no warnings 'redefine';
    *Mail::GcalReminder::send_gmail = sub {
        my ( $self, $to, $sub, $body ) = @_;
        ok( 1, 'send_gmail() called' );
        is( $to,   '1,2',         'send_gmail() called w/ correct to' );
        is( $sub,  'subject str', 'send_gmail() called w/ subject via string' );
        is( $body, 'body str',    'send_gmail() called w/ body via string' );
    };
}
$gcr->send_reminders( { 'gcal' => 'guests', 'in_advance' => [ 'days' => 2 ], subject => 'subject str', body => 'body str' } );

#    guestcheck code filter, subject body as coderef && as string
{
    no warnings 'redefine';
    *Mail::GcalReminder::send_gmail = sub {
        my ( $self, $to, $sub, $body ) = @_;
        is( $to,   '3,4,1,2',      'send_gmail() called w/ correct to when guestcheck (guestcheck gets correct args)' );
        is( $sub,  'subject code', 'send_gmail() called w/ subject via code' );
        is( $body, 'body code',    'send_gmail() called w/ body via code' );
    };
}
$gcr->send_reminders(
    {
        'gcal' => 'guests', 'in_advance' => [ 'days' => 2 ], subject => sub { 'subject code' }, body => sub { 'body code' },
        'guestcheck' => sub { shift; return ( 3, 4, @_ ) }
    }
);

# guestcheck code filter: none -- no guests warning
$warn = undef;
my $send_gmail = 0;
{
    no warnings 'redefine';
    *Mail::GcalReminder::send_gmail = sub { $send_gmail++ };
}
$gcr->send_reminders(
    {
        'gcal' => 'guests', 'in_advance' => [ 'days' => 2 ], 'guestcheck' => sub { return }
    }
);
is( $send_gmail, 0, 'send_gmail() not called when guestcheck returns empty list' );
like( $warn, qr/No guests for/, 'guestcheck returns empty list' );

#   RV when all send_gmail() ok
{
    no warnings 'redefine';
    *Mail::GcalReminder::send_gmail = sub { 1 };
}
is( $gcr->send_reminders( { 'gcal' => 'guests', 'in_advance' => [ 'days' => 2 ] } ), 2, 'RV when all send_gmail() ok' );

#   RV when a send_gmail() fails
my $try = 1;
{
    no warnings 'redefine';
    *Mail::GcalReminder::send_gmail = sub { return $try--; };
}
is( $gcr->send_reminders( { 'gcal' => 'guests', 'in_advance' => [ 'days' => 2 ] } ), undef, 'RV when aa ll send_gmail() fails' );
