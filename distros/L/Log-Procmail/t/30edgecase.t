use Test::More tests => 83;
use Log::Procmail;

# a file with actual bad logs
my $log = Log::Procmail->new('t/procmail4.log');
my $rec = $log->next;

# first log is okay
is( $rec->from,    'chandra_mcCarty_af@chingrafix.de', 'Correct from' );
is( $rec->date,    'Tue Apr  6 02:48:11 2004',         'Correct date' );
is( $rec->subject, 'Viagra that last all weekend',     'Correct subject' );
is( $rec->folder,  'spam',                             'Correct folder' );
is( $rec->size,    2726,                               'Correct size' );

# change the date (see rt ticket #2658)
$rec->date( "foo bar" );
is( $rec->ymd, undef, "ymd() returns undef when the date is incorrect" );

# next two logs are mixed up
# but the first log does not have a Folder line
$rec = $log->next;
#is( $rec->from,    'root@home.bruhat.net',     'Correct from' );
#is( $rec->date,    'Tue Apr  6 02:53:47 2004', 'Correct date' );
#is( $rec->subject, undef,                      'Could not get the subject' );
#is( $rec->folder,  undef,                      'Could not get the folder' );
#is( $rec->size,    undef,                      'Could not get the size' );
#$rec = $log->next;
is( $rec->from,   'anxiety@schooloftheair.com', 'Correct from' );
is( $rec->date,   'Tue Apr  6 02:53:43 2004',   'Correct date' );
is( $rec->subject,
    'Cron <root@rose> test -e /usr/sbin/anacron || run-parts --report /etc',
    'Got the wrong subject');
is( $rec->folder, 'root',                       'Got the wrong folder' );
is( $rec->size, 5212, 'Got the wrong size' );

# should we ignore the next two lines ?
$rec = $log->next;
is( $rec->from,    undef,           'Correct from' );
is( $rec->date,    undef,           'Correct date' );
is( $rec->subject, 'Up to 80 percent off on medication, Sponsors.',
                                    'Correct subject' );
is( $rec->folder,  'conf-sponsors', 'Correct folder' );
is( $rec->size,    4453,            'Correct size' );

# next log is ok
$rec = $log->next;
is( $rec->from,    'bridgeheads@get-off-the-grass.com', 'Correct from' );
is( $rec->date,    'Tue Apr  6 02:53:43 2004',          'Correct date' );
is( $rec->subject, 'Jobs, need drugs?',                 'Correct subject' );
is( $rec->folder,  'mongueurs-jobs',                    'Correct folder' );
is( $rec->size,    4492,                                'Correct size' );

# no subject
$rec = $log->next;
is( $rec->from,    'qlogbffxuwl@freemail.com.au', 'Correct from' );
is( $rec->date,    'Tue Apr  6 06:40:05 2004',    'Correct date' );
is( $rec->subject, undef,                         'Correct subject' );
is( $rec->folder,  '/var/mail/book',              'Correct folder' );
is( $rec->size,    1205,                          'Correct size' );

# this one is correct
$rec = $log->next;
is( $rec->from,   'l_crockerqu@xcelco.on.ca', 'Correct from' );
is( $rec->date,   'Tue Apr  6 06:57:02 2004', 'Correct date' );
is( $rec->subject,
    '=?iso-8859-1?b?RXh0cmVtZWx5IEFmZm9yZGFibGUgUHJlcyVjcmlwdGlvbiBEcnVbZ3',
    'Correct subject');
is( $rec->folder, 'isspam',                   'Correct folder' );
is( $rec->size, 1857, 'Correct size' );

# an empty file followed by a file with a custom format
$log = Log::Procmail->new('t/procmail4.log');
$rec = $log->next;

# first log is okay
is( $rec->from,    'chandra_mcCarty_af@chingrafix.de', 'Correct from' );
is( $rec->date,    'Tue Apr  6 02:48:11 2004',         'Correct date' );
is( $rec->subject, 'Viagra that last all weekend',     'Correct subject' );
is( $rec->folder,  'spam',                             'Correct folder' );
is( $rec->size,    2726,                               'Correct size' );

# a file that doesn't start with logs
$log = Log::Procmail->new( 't/procmail5.log');
$log->errors(1);
my @errors = (
    '',
    'procmail: [26829] Fri Oct 28 17:58:28 2005',
    'procmail: Assigning "MAILDIR=/home/bepi/Procmail/messages"',
    'procmail: Assigning "INCLUDERC=/home/bepi/Procmail/rc.spamassassin"',
    'procmail: Assigning "SPAMASSASSIN_DIR=/usr/local/perl-5.8.7/bin"',
    'procmail: Assigning "SPAMASSASSIN=/usr/local/perl-5.8.7/bin/spamassassin"',
    'procmail: No match on "^Subject:.*test"',
    'procmail: No match on "> 256000"',
    'procmail: No match on "(^((Original-)?(Resent-)?(To|Cc|Bcc)|(X-Envelope|Apparently(-Resent)?)-To):(.*[^-a-zA-Z0-9_.])?)spam@"',
    'procmail: Skipped "* < 256000"',
    'procmail: Match on "< 256000"',
    'procmail: Locking "spamassassin.lock"',
    'procmail: Executing "/usr/local/perl-5.8.7/bin/spamassassin"',
    '[26831] warn: config: created user preferences file: /home/bepi/.spamassassin/user_prefs',
    'procmail: [26829] Fri Oct 28 17:58:30 2005',
    'procmail: Unlocking "spamassassin.lock"',
    'procmail: No match on "^X-Spam-Level: \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*"',
    'procmail: Locking "/var/spool/mail/bepi.lock"',
    'procmail: Assigning "LASTFOLDER=/var/spool/mail/bepi"',
    'procmail: Opening "/var/spool/mail/bepi"',
    'procmail: Acquiring kernel-lock',
    'procmail: Unlocking "/var/spool/mail/bepi.lock"',
    'procmail: Notified comsat: "bepi@9865:/var/spool/mail/bepi"',
);

for my $err (@errors) {
    $rec = $log->next;
    is( $rec, $err, 'Error line' );
}

$rec = $log->next;
is( $rec->from, 'MAILER-DAEMON@koenig.fantagruel.it', 'Correct from' );
is( $rec->date, 'Fri Oct 28 17:58:28 2005',           'Correct date' );
is( $rec->subject,
    'Delivery Status Notification (Failure)',
    'Correct subject'
);
is( $rec->folder, '/var/spool/mail/bepi', 'Correct folder' );
is( $rec->size, 6974, 'Correct size' );

# more debug messages
@errors = (
    '',
    'procmail: [26839] Fri Oct 28 17:58:53 2005',
    'procmail: Assigning "MAILDIR=/home/bepi/Procmail/messages"',
    'procmail: Assigning "INCLUDERC=/home/bepi/Procmail/rc.spamassassin"',
    'procmail: Assigning "SPAMASSASSIN_DIR=/usr/local/perl-5.8.7/bin"',
    'procmail: Assigning "SPAMASSASSIN=/usr/local/perl-5.8.7/bin/spamassassin"',
    'procmail: Match on "^Subject:.*test"',
    'procmail: Locking "IN-testing.lock"',
    'procmail: Assigning "LASTFOLDER=IN-testing"',
    'procmail: Opening "IN-testing"',
    'procmail: Acquiring kernel-lock',
    'procmail: [26839] Fri Oct 28 17:58:54 2005',
    'procmail: Unlocking "IN-testing.lock"',
    'procmail: Notified comsat: "bepi@0:/home/bepi/Procmail/messages/IN-testing"',
);

for my $err (@errors) {
    $rec = $log->next;
    is( $rec, $err, 'Error line' );
}

$rec = $log->next;
is( $rec->from,    'enrico@forget.it',    'Correct from' );
is( $rec->date,    'Fri Oct 28 17:58:53 2005', 'Correct date' );
is( $rec->subject, 'test',                     'Correct subject' );
is( $rec->folder,  'IN-testing',               'Correct folder' );
is( $rec->size,    1494,                       'Correct size' );

