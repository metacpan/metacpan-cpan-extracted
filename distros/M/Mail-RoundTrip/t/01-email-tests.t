# Email tests for Mail::RoundTrip.
#
# Note these will not be set unless you set at least the following:
#
# SENDTO for the email address to send the test to, and
# EMAIL_TESTS to activate email tests. 
#
# Optionally REPLY_TO and RETURN_PATH can be set to operate these tests.
#
# If SPOOLDIR not set, it defaults to /tmp/

use strict;
use warnings;
use Test::More;
use Mail::RoundTrip;

my $template = 'test string __CODE__ test string';
my $sendto;
my $replyto;
my $returnpath;
my $from;
my $spooldir = '/tmp';

if (!defined $ENV{EMAIL_TESTS}){
    plan skip_all => 'Skipping.  EMAIL_TESTS not set';
} elsif (!defined $ENV{SENDTO}){
    plan skip_all => 'Skipping.  SENDTO not set';
} else {
    plan tests => 6;
    $sendto = $ENV{SENDTO};
    $replyto = $ENV{REPLY_TO};
    $returnpath = $ENV{RETURN_PATH};
    $from = $ENV{FROM};
    $spooldir = $ENV{SPOOL_DIR} if defined $ENV{SPOOL_DIR};
}

my $data = { passed => 1};
my %args = (address => $sendto, spool_dir => $spooldir, data => $data);

$args{reply_to} = $replyto if defined $replyto;
$args{return_path} = $returnpath if defined $returnpath;
$args{from} = $from if defined $from;

my $verifier = Mail::RoundTrip->new(%args);
ok($verifier, 'Verifier returned');
ok($verifier->send_confirmation(template => $template), 'Returned true on send confirmation');
my $code = $verifier->code;
ok(-f "$spooldir/$code", 'Spool file exists');
is(length $code, 36, 'filename length 36 characters long for UUID');
my $data2 = Mail::RoundTrip->get_data(spool_dir => $spooldir, code => $code);
is(ref $data2, ref $data, 'Same ref type for stored and received hashes');
is($data2->{passed}, 1, 'Data2 has correct data on retrieval');
