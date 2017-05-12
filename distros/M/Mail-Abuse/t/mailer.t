
# $Id: mailer.t,v 1.4 2004/02/04 22:45:21 lem Exp $

use IO::File;
use Test::More;
use Mail::Abuse::Report;
use Mail::Abuse::Processor::Mailer;
use Mail::Abuse::Incident::Normalize;

our $stdout;

our $config	= './config' . $$;
our $fail	= './fail' . $$;
our $success	= './success' . $$;
our $output	= './output' . $$;
our @msgs = ();
our $msg = 0;

				# Read the sample messages into an easy to
				# easy to use array, using $/ for simplicity
{
    local $/ = "*EOM\n";
    push @msgs, <DATA>;
}

				# A simple reader, which returns each message
				# from @msgs
package MyReader;
use base 'Mail::Abuse::Reader';
sub read
{ 
  main::ok(1, "Read message $main::msg with " 
         . length($main::msgs[$main::msg]) . ' octets');
#    print "Read ", $main::msgs[$main::msg++], "\n";
    $_[1]->text(\$main::msgs[$main::msg++]); 
    return 1;
}

				# A very dummy incident parser... Looks for
				# a token and that's it
package MyIncident;
use base 'Mail::Abuse::Incident';
sub new { bless {}, ref $_[0] || $_[0] };
sub parse 
{ 
    my $self	= shift;
    my $rep	= shift;

    my @ret = ();
    my $text = $rep->normalized ? $rep->body : $rep->text;
    push @ret, $self->new if $$text =~ m/INCIDENT/;
    return @ret;
};
package main;

my $tests = 18 * @msgs + 5;
plan tests => $tests;

sub write_config
{
    my $fh = new IO::File;

    $fh->open($config, "w");
    return undef unless $fh;
    return undef unless print $fh <<EOF;
# This is a config file
mailer type: test
mailer from: this_is_the_from_address
mailer reply to: this_is_the_mailer_reply_to_address
mailer errors to: this_is_the_mailer_errors_to_address
mailer fail message: $fail
mailer success message: $success
EOF
    ;
    $fh->close || return;

    $fh->open($success, "w");
    return undef unless $fh;
    return undef unless print $fh <<EOF;
This is the SUCCESS message
EOF
    ;
    $fh->close || return;

    $fh->open($fail, "w");
    return undef unless $fh;
    return undef unless print $fh <<EOF;
This is the FAIL message
EOF
    ;
    return $fh->close;
}

END 
{ 
    unlink $config; 
    unlink $success; 
    unlink $fail; 
#    unlink $output;
}

sub stdout_reset
{
    unlink $output;
    close STDOUT;
    open STDOUT, ">$output"
      or die "Failed to create stdout file ($output): $!\n";
}

sub capture
{
    my $fh = new IO::File "$output"
      or die "Failed to open stdout file ($output): $!\n";
    local $/ = undef;
    return <$fh>;
}

SKIP:
{
    skip "This test is currently broken by what seems to be "
	. "a bug in Mail::Mailer::test", $tests;
    ok(write_config, "Write config files") 
	or skip 'Failed to write config files (FATAL)', $tests--;
    use_ok('Mail::Abuse::Processor::Mailer') or
	skip 'Mail::Abuse::Report failed to load (FATAL)', $tests--;

    my $e = new Mail::Abuse::Processor::Mailer;

    isa_ok($e, 'Mail::Abuse::Processor::Mailer');
    isa_ok($e, 'Mail::Abuse::Processor');

    my $rep = new Mail::Abuse::Report
	(
	 config		=> $config,
	 reader		=> new MyReader,
	 processors	=> [ $e ],
	 );

    ok($rep, "Mail::Abuse::Report created");

				# The first test round, verifies the
				# modules using ::Normalize...

    $rep->parsers([new Mail::Abuse::Incident::Normalize, 
		   new MyIncident]);

    for my $m (@msgs)
    {
	my $r;	
	stdout_reset;
	eval { $r = $rep->next; };
	my $stdout = capture;
	diag '>>>' . $stdout . '<<<';
	die;
	diag "Output is {$stdout}\n";
	ok($stdout =~ m/^Errors-To: this_is_the_mailer_errors_to_address$/m,
	   "Errors-To: header looks ok");
	ok($stdout =~ m/^Reply-To: this_is_the_mailer_reply_to_address$/m,
	   "Reply-To: header looks ok");
	ok($stdout =~ m/^To: .*testme\@test.tld/m,
	   "To: header looks ok");
	ok($stdout =~ m/^From: this_is_the_from_address$/m,
	   "From: header looks ok");
	ok($stdout =~ m/^X-Mail-Abuse-Loop:/m,
	   "X-Mail-Abuse-Loop: header looks ok");
	ok($stdout =~ m/^X-Mailer: Mail::Abuse::Processor::Mailer/m,
	   "X-Mailer: header looks ok");

	if ($m =~ /INCIDENT/)
	{
	    ok($stdout =~ m/^This is the SUCCESS message/m,
	       "Correct type of message sent");
	}
	else
	{
	    ok($stdout =~ m/^This is the FAIL message/m,
	       "Correct type of message sent");
	}

	isa_ok($r, 'Mail::Abuse::Report');
    }

				# The second round, does not use ::Normalize

    $msg = 0;			# Retry all the messages
    $rep->parsers([new MyIncident]);

    for my $m (@msgs)
    {
	$stdout = '';
	my $r;
	eval { $r = $rep->next; };
	ok($stdout =~ m/^Errors-To: this_is_the_mailer_errors_to_address$/m,
	   "Errors-To: header looks ok");
	ok($stdout =~ m/^Reply-To: this_is_the_mailer_reply_to_address$/m,
	   "Reply-To: header looks ok");
	ok($stdout =~ m/^To: .*testme\@test.tld/m,
	   "To: header looks ok");
	ok($stdout =~ m/^From: this_is_the_from_address$/m,
	   "From: header looks ok");
	ok($stdout =~ m/^X-Mail-Abuse-Loop:/m,
	   "X-Mail-Abuse-Loop: header looks ok");
	ok($stdout =~ m/^X-Mailer: Mail::Abuse::Processor::Mailer/m,
	   "X-Mailer: header looks ok");
	if ($m =~ /INCIDENT/)
	{
	    ok($stdout =~ m/^This is the SUCCESS message/m,
	       "Correct type of message sent");
	}
	else
	{
	    ok($stdout =~ m/^This is the FAIL message/m,
	       "Correct type of message sent");
	}

	isa_ok($r, 'Mail::Abuse::Report');
    }
}

__DATA__
From: testme@test.tld (test account)
Subject: Nasty complaint

INCIDENT

*EOM
From: "Test account" <testme@test.tld>
Subject: Nasty complaint with no incident

This cannot be parsed as we want...

*EOM
