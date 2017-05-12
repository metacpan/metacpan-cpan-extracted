#!/usr/bin/perl
use strict;
use warnings;
use File::Spec::Functions ':ALL';

use Test::More tests => 62;
use Test::Fatal;
use Email::Stuffer;

my $TEST_GIF = catfile( 't', 'data', 'paypal.gif' );
ok( -f $TEST_GIF, "Found test image: $TEST_GIF" );

sub string_ok {
	my $string = shift;
	$string = !! (defined $string and ! ref $string and $string ne '');
	ok( $string, $_[0] || 'Got a normal string' );
}

sub stuff_ok {
	my $stuff = shift;
	isa_ok( $stuff,        'Email::Stuffer' );
	isa_ok( $stuff->email, 'Email::MIME' );
	string_ok( $stuff->as_string, 'Got a non-null string for Email::Stuffer->as_string' );
}

#####################################################################
# Main Tests

# Create a new Email::Stuffer object
my $Stuffer = Email::Stuffer->new;
stuff_ok( $Stuffer );
my @headers = $Stuffer->headers;
ok( scalar(@headers), 'Even the default object has headers' );

# Set a To name
my $rv = $Stuffer->to('adam@ali.as');
stuff_ok( $Stuffer );
stuff_ok( $rv    );
is( $Stuffer->as_string, $rv->as_string, '->To returns the same object' );
is( $Stuffer->email->header('To'), 'adam@ali.as', '->To sets To header' );

# Set a From name
$rv = $Stuffer->from('bob@ali.as');
stuff_ok( $Stuffer );
stuff_ok( $rv    );
is( $Stuffer->as_string, $rv->as_string, '->From returns the same object' );
is( $Stuffer->email->header('From'), 'bob@ali.as', '->From sets From header' );

# To allows multiple recipients
$rv = $Stuffer->to('adam@ali.as', 'another@ali.as', 'bob@ali.as');
stuff_ok( $Stuffer );
stuff_ok( $rv    );
is( $Stuffer->as_string, $rv->as_string, '->To (multiple) returns the same object' );
is( $Stuffer->email->header('To'), 'adam@ali.as, another@ali.as, bob@ali.as', '->To (multiple) sets To header' );

# Cc allows multiple recipients
$rv = $Stuffer->cc('adam@ali.as', 'another@ali.as', 'bob@ali.as');
stuff_ok( $Stuffer );
stuff_ok( $rv    );
is( $Stuffer->as_string, $rv->as_string, '->Cc (multiple) returns the same object' );
is( $Stuffer->email->header('Cc'), 'adam@ali.as, another@ali.as, bob@ali.as', '->Cc (multiple) sets To header' );

# Bcc allows multiple recipients
$rv = $Stuffer->bcc('adam@ali.as', 'another@ali.as', 'bob@ali.as');
stuff_ok( $Stuffer );
stuff_ok( $rv    );
is( $Stuffer->as_string, $rv->as_string, '->Bcc (multiple) returns the same object' );
is( $Stuffer->email->header('Bcc'), 'adam@ali.as, another@ali.as, bob@ali.as', '->Bcc (multiple) sets To header' );

# More complex one
use Email::Sender::Transport::Test 0.120000 (); # ->delivery_count, etc.
my $test = Email::Sender::Transport::Test->new;
my $rv2 = Email::Stuffer->from       ( 'Adam Kennedy<adam@phase-n.com>')
                        ->to         ( 'adam@phase-n.com'              )
                        ->subject    ( 'Hello To:!'                    )
                        ->text_body  ( 'I am an email'                 )
                        ->attach_file( $TEST_GIF                       )
                        ->transport  ( $test                           )
                        ->send;
ok( $rv2, 'Email sent ok' );
is( $test->delivery_count, 1, 'Sent one email' );
my $email = $test->shift_deliveries->{email}->as_string;
like( $email, qr/Adam Kennedy/,  'Email contains from name' );
like( $email, qr/phase-n/,       'Email contains to string' );
like( $email, qr/Hello/,         'Email contains subject string' );
like( $email, qr/I am an email/, 'Email contains text_body' );
like( $email, qr/paypal/,        'Email contains file name' );

# attach_file content_type
$rv2 = Email::Stuffer->from       ( 'Adam Kennedy<adam@phase-n.com>'        )
                     ->to         ( 'adam@phase-n.com'                      )
                     ->subject    ( 'Hello To:!'                            )
                     ->text_body  ( 'I am an email'                         )
                     ->attach_file( 'dist.ini', content_type => 'text/plain')
                     ->transport  ( $test                                   )
                     ->send;
ok( $rv2, 'Email sent ok' );
is( $test->delivery_count, 1, 'Sent one email' );
$email = $test->shift_deliveries->{email}->as_string;
like( $email, qr/Adam Kennedy/,  'Email contains from name' );
like( $email, qr/phase-n/,       'Email contains to string' );
like( $email, qr/Hello/,         'Email contains subject string' );
like( $email, qr/I am an email/, 'Email contains text_body' );
like( $email, qr{Content-Type: text/plain; name="dist\.ini"}, 'Email contains attachment content-Type' );

# attach_file with no such file
my $error = exception { Email::Stuffer->attach_file( 'no such file' ) };
like $error,
    qr/No such file 'no such file'/,
    'attach_file croaks when passed a bad file name';

# attach_file with a non-file object
$error = exception { Email::Stuffer->attach_file( $rv2 ) };
like $error,
    qr/Expected a file name or an IO::All::File derivative, got Email::Sender::Success/,
    'attach_file croaks when passed a bad reference';

my $enoent = do {
  use Errno 'ENOENT';
  local $! = ENOENT;
  "$!";
};

# _slurp croaks when passed a bad file
$error = exception { Email::Stuffer::_slurp( 'no such file' ) };
like $error,
    qr/\Aerror opening no such file: \Q$enoent/,
    '_slurp croaks when passed a bad filename';

1;
