use strict;
use Test::More tests => 63;
use Log::Procmail;

# create a record by hand
my $rec = Log::Procmail::Abstract->new(
    from    => 'book@cpan.org',
    date    => 'Tue Feb  5 01:14:36 CET 2002',
    subject => 'Re: Log::Procmail',
    folder  => 'modules',
    size    => '2197',
);

isa_ok( $rec, "Log::Procmail::Abstract" );

# test the methods
is( $rec->from,    'book@cpan.org', "Correct from" );
is( $rec->date,    'Tue Feb  5 01:14:36 CET 2002', "Correct date");
is( $rec->subject, 'Re: Log::Procmail', "Correct subject");
is( $rec->folder,  'modules', "Correct folder" );
is( $rec->size,    '2197', "Correct size" );
is( $rec->ymd,     '20020205011436', "Correct ymd" );
is( $rec->source,  undef, "No source" );

# create a logger
my $log = Log::Procmail->new("t/procmail.log");
isa_ok( $log, "Log::Procmail" );

# read a record from the first file
$rec = $log->next;
is( $rec->from, 'r21436@start.no',          "Correct from" );
is( $rec->date, 'Wed Feb  6 18:50:17 2002', "Correct date" );
is( $rec->subject,
    'I woke up from my obesity nightmare                         5765',
    "Correct subject" );
is( $rec->folder, '/var/spool/mail/book', "Correct folder" );
is( $rec->size, 5774, "Correct size" );
is( $rec->source, 't/procmail.log', "Correct source" );

# a record with a <SPACE> in the From field
$rec = $log->next;
is( $rec->from, '"antispamsoftware <antispam"@mx05.sytes.net', "Correct from");
is( $rec->date, 'Mon Apr  5 23:01:10 2004', "Correct date" );
is( $rec->subject, 'Filter spammers and keep your email address', "Correct subject");
is( $rec->folder, "isspam", "Correct folder");
is( $rec->size, 7528, "Correct size" );

# read the remaining records
my $i = 1;
while ( $rec = $log->next ) { $i++ }
is( $i, 5, "Remaining logs" );

# push new files on the log stack
$log->push( 't/procmail.log', 't/procmail2.log' );
$rec = $log->next;

# did we get the first record again?
isa_ok( $rec, "Log::Procmail::Abstract" );
is( $rec->from, 'r21436@start.no',          "Correct from" );
is( $rec->date, 'Wed Feb  6 18:50:17 2002', "Correct date" );
is( $rec->subject,
    'I woke up from my obesity nightmare                         5765',
    "Correct subject" );
is( $rec->folder, '/var/spool/mail/book', "Correct folder" );
is( $rec->size, 5774, "Correct size" );
is( $rec->source, 't/procmail.log', "Correct source" );

# go to next file, automatically
$rec = $log->next for 1 .. 6;    # skip 6 records

is( $rec->from, 'p11542@24horas.com', "Correct from" );
is( $rec->date, 'Mon Feb  4 18:29:00 2002', "Correct date" );
is( $rec->subject,
    "I didn't want to struggle anymore                         5901",
    "Correct subject" );
is( $rec->folder, '/var/spool/mail/book', "Correct folder" );
is( $rec->size,   5745, "Correct size" );
is( $rec->source, 't/procmail2.log', "Correct source" );

# test modifying an abstract
$rec->from('book@cpan.org');
is( $rec->from, 'book@cpan.org', "Changed from" );

$rec->date('Mon Feb  4 18:29:00 2002');
is( $rec->ymd, '20020204182900', "date and ymd modified" );

1 while ( $log->next );
$log->push("t/log.tmp");

# test when a new mail is processed
open F, "> t/log.tmp" or die;
print F << 'EOT';
From e10299@firemail.de  Sat Feb  2 10:18:31 2002
 Subject: Boost Your Windows Reliability!!!!!!!                         14324
  Folder: /var/spool/mail/book						   3768
EOT
close F;

$rec = $log->next;
is( $rec->from,   'e10299@firemail.de', "Correct from" );
is( $rec->date,   'Sat Feb  2 10:18:31 2002', "Correct date" );
is( $rec->subject,
    'Boost Your Windows Reliability!!!!!!!                         14324',
    "Correct folder" );
is( $rec->folder, '/var/spool/mail/book', "Correct folder" );
is( $rec->size,   3768, "Correct size" );
is( $rec->source, 't/log.tmp', "Correct source" );
$rec = $log->next;
is( $rec, undef, "No log left" );

# a new mail arrives
open F, ">> t/log.tmp" or die;
print F << 'EOT';
From Viagra9520@eudoramail.com  Sat Feb  2 11:58:00 2002
 Subject: Make This Valentine's Day Unforgettable.           QTTKE
  Folder: /var/spool/mail/book						   3981
EOT
close F;

$rec = $log->next;
is( $rec->from,    'Viagra9520@eudoramail.com', "Correct from" );
is( $rec->date,    'Sat Feb  2 11:58:00 2002', "Correct date" );
is( $rec->subject, "Make This Valentine's Day Unforgettable.           QTTKE",
    "Correct subject" );
is( $rec->folder,  '/var/spool/mail/book', "Correct folder" );
is( $rec->size,    3981, "Correct size" );
is( $rec->source, 't/log.tmp', "Correct source" );

unlink "t/log.tmp";

# some folders with a space in their name
$log = Log::Procmail->new('t/procmail3.log');
$rec = $log->next;
is( $rec->from, 'lynn@cybermortrates.com', "Correct from" );
is( $rec->date, 'Tue Oct 10 02:31:27 2000', "Correct date" );
is( $rec->subject, 'BOOST WINDOWS RELIABILITY                         30865',
                   "Correct subject" );
is( $rec->folder, 'qmail-perms ./mail/inbox/', "Correct folder" );
is( $rec->size, 2585, "Correct size" );
is( $rec->source, 't/procmail3.log', "Correct source" );

# check that we correctly ignore errors
$rec = $log->next;
is( $rec->from, 'dailytip@bdcimail.com', "Correct from" );
$log->errors(1);

$rec = $log->next;
is( ref $rec, '', "Not a Log::Procmail::Abstract" );
like( $rec, qr/^Can't call method "print" on an undefined value/,
      "Got an error" );

# if errors are ignored and only errors are left in the current file,
# transparently open the next file
$log->errors(0);
$log->push('t/procmail2.log');
$rec = $log->next; # last log of t/procmail3.log
$rec = $log->next; # skip the last errors of t/procmail3.log

# this is the first log of t/procmail2.log
is( $rec->from, 'p11542@24horas.com', "Correct from" );
is( $rec->date, 'Mon Feb  4 18:29:00 2002', "Correct date" );
is( $rec->subject,
    "I didn't want to struggle anymore                         5901",
    "Correct subject" );
is( $rec->folder, '/var/spool/mail/book', "Correct folder" );
is( $rec->size,   5745, "Correct size" );

