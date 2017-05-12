use Forks::Super qw(:test overload);
use Forks::Super::Util qw(is_socket is_pipe);
use Test::More tests => 25;
use utf8;
use strict;
use warnings;

my $gzip_layer_avail = eval 'use PerlIO::gzip; 1';
my $utf8_layer_avail = $] >= 5.008;

if (!$utf8_layer_avail) {
  SKIP: {
        skip "layers not available for $]", 25;
    }
    exit;
}

{
    ############### utf8 layer ###################

    my $unicode_phrase = "A string with wide characters: Tiếng Viẹt ... \n";
    my $layer = ':utf8';
    if (!$utf8_layer_avail) {
	$unicode_phrase = "A string\nwith newlines\n";
	$layer = ':crlf';
    }

    my $pid = fork {
	child_fh => "out,err,block,$layer",
	sub => sub {
	    print STDERR "foo\n";
	    print STDOUT $unicode_phrase;
	}
    };

    ok(isValidPid($pid), "$pid is valid pid");
  SKIP: {
      if (Forks::Super::Config::CONFIG('filehandles') == 0) {
	  skip "filehandles are unconfigured, ignore handle type test", 1;
      }
      ok(!is_socket($pid->{child_stdout}) && !is_pipe($pid->{child_stdout}), 
	 "ipc with filehandles");
    }
    sleep 1;
    my $err = Forks::Super::read_stderr($pid);
    ok($err =~ /^foo/, "read stderr")
	or diag("expected 'foo', got $err");

    my $out = join '', $pid->read_stdout();
    if ($] < 5.008) {
	# read with :crlf layer doesn't work the same in 5.6
	$unicode_phrase =~ s/\n/\r\n/g;
    }
    s/\r/\\r/g,s/\n/\\n/g for $out, $unicode_phrase;
    ok($out eq $unicode_phrase, "read stdout")
	or diag("output was: $out\nexpected  : $unicode_phrase\n");

    # read the output in raw mode and verify the encoding was used
    my $f_out = $pid->{fh_config}{f_out};
    open my $fh1, '<', $f_out;
    my $line1 = <$fh1>;
    close $fh1;
    open my $fh2, '<', $f_out;
    binmode $fh2, $layer;
    my $line2 = <$fh2>;
    close $fh2;
    if ($utf8_layer_avail) {
	ok($line1 ne $line2 && length($line1) > length($line2)     ### 5a ###
	   && $line2 =~ /[\x{0100}-\x{CCCC}]/
	   && !$line1 !~ /[\x{0100}-\x{CCCC}]/,
	   ':utf8 encoding respected in output');
    } elsif ($layer eq ':crlf') {
	my $t1 = $line1 ne $line2;
	my $t2 = length($line1)>length($line2);
	my $t3 = $line1 =~ /\r/;
	my $t4 = $line2 !~ /\r/;
	if ($] >= 5.008) {
	    ok($t1 && $t2 && $t3 && $t4,                           ### 5b ###
	       ':crlf encoding respected in output')
		or diag("$t1 / $t2 / $t3 / $t4");
	} else {
	    # :crlf layer behaves differently in 5.6
	    ok($t3, ':crlf encoding respected in output')          ### 5c ###
		or diag("$t1 / $t2 / $t3 / $t4");
	}
    } else {
	ok(0, "I/O layer $layer not tested!");                     ### 5d ###
	diag("recognized layers for this test are :utf8, :crlf");
    }

    #### no more input on STDOUT or STDERR

    $err = Forks::Super::read_stderr($pid);
    ok(!defined($err) || $err eq '',                         ### 6 ###
       "blocking read on empty stderr returns empty")
	or diag("expected nothing, got $err");

    $out = Forks::Super::read_stdout($pid, "block" => 0);
    ok(!defined($out) || $out eq "",                         ### 7 ###
       "non-blocking read on empty stdout returns empty");

}


if (!$gzip_layer_avail) {
  SKIP: {
      skip ":gzip PerlIO layer not available", 18;
    }
    exit;
}


{
    ############ gzip layer ##############

    # a non random string that should be easy to compress
    my $phrase_to_compress = "1234" x 5678;

    my $pid = fork {
	child_fh => "out,err,block,:gzip",
	sub => sub {
	    print STDERR "foo\n";
	    print STDOUT $phrase_to_compress, "\n";
	    print STDOUT "baz\n";

	    # with :gzip layer, STDOUT, STDERR won't autoflush
	    close STDERR;
	    close STDOUT;
	}
    };

    ok(isValidPid($pid), "$pid is valid pid");
  SKIP: {
      if (Forks::Super::Config::CONFIG('filehandles') == 0) {
	  skip "filehandles are unconfigured, ignore handle type test", 1;
      }
      ok(!is_socket($pid->{child_stdout}) && !is_pipe($pid->{child_stdout}), 
	 "ipc with filehandles");
    }
    sleep 1;
    my $err = Forks::Super::read_stderr($pid);
    ok($err =~ /^foo/, "read stderr")                      ### 10 ###
	or diag("expected 'foo', got $err");

    my $out = <$pid>;
    ok($out eq "$phrase_to_compress\n", "read stdout")
	or diag("output was: $out\nexpected  : $phrase_to_compress\n");

    my $out_file = $pid->{fh_config}{f_out};
    ok(-f $out_file && -s $out_file,
       "found ipc output file for :gzip test");
    my $out_file_size = -s $out_file;
    my $output_length = length($phrase_to_compress);
    ok($out_file_size < 0.4 * $output_length,
       "data was compressed  $out_file_size << $output_length");

    $out = Forks::Super::read_stdout($pid);
    ok($out =~ /^baz/, "successful blocking read on stdout");

    #### no more input on STDOUT or STDERR

    $err = Forks::Super::read_stderr($pid);
    ok(!defined($err) || $err eq '',                         ### 15 ###
       "blocking read on empty stderr returns empty")
	or diag("expected nothing, got $err");

    $out = Forks::Super::read_stdout($pid, "block" => 0);
    ok(!defined($out) || $out eq "",                         ### 16 ###
       "non-blocking read on empty stdout returns empty");

}

if (!$utf8_layer_avail) {
  SKIP: {
      skip ":utf8 layer needed for multi-layer test", 9;
    }
    exit;
}

{
    ############### :utf8 AND :gzip layers ###################

    # a non random string that should be easy to compress
    my $unicode_phrase_to_compress = "₫đĐỷỡ" x 3000;

    my $pid = fork {
	child_fh => "out,err,block,:encoding(utf8),:gzip",
	sub => sub {
	    binmode *STDOUT,':utf8';
	    print STDERR "foo\n";
	    print STDOUT $unicode_phrase_to_compress, "\n";
	    print STDOUT "baz\n";

	    # with I/O layer, STDOUT, STDERR might not autoflush
	    close STDERR;
	    close STDOUT;
	}
    };

    ok(isValidPid($pid), "$pid is valid pid");
  SKIP: {
      if (Forks::Super::Config::CONFIG('filehandles') == 0) {
	  skip "filehandles are unconfigured, ignore handle type test", 1;
      }
      ok(!is_socket($pid->{child_stdout}) && !is_pipe($pid->{child_stdout}), 
	 "ipc with filehandles");
    }
    for (1..5) { last if $pid->is_complete; sleep 1 }
    my $err = Forks::Super::read_stderr($pid);
    if ($err =~ /Failed to apply .* layer/i) {
	warn "Got Forks::Super::Job::Ipc warning in stderr: $err\n";
	$err = Forks::Super::read_stderr($pid);
    }
    ok($err =~ /^foo/, "read stderr")                       ### 19 ###
	or diag("expected 'foo', got $err");

    my $out = <$pid>;
    ok($out eq "$unicode_phrase_to_compress\n", "read stdout")
	or diag("output was: $out\nexpected  : $unicode_phrase_to_compress\n");

    my $out_file = $pid->{fh_config}{f_out};
    ok(-f $out_file && -s $out_file,
       "found ipc output file for :gzip test");
    my $out_file_size = -s $out_file;
    my $output_length = length($unicode_phrase_to_compress);
    ok($out_file_size < 0.4 * $output_length,
       "data was compressed  $out_file_size << $output_length");

    $out = Forks::Super::read_stdout($pid);
    ok($out =~ /^baz/, "successful blocking read on stdout");

    #### no more input on STDOUT or STDERR

    my @err = Forks::Super::read_stderr($pid);
    ok(@err==0,
       "blocking read on empty stderr returns empty")
	or diag("expected nothing, got @err");

    $out = Forks::Super::read_stdout($pid, "block" => 0);
    ok(!defined($out) || $out eq "",                         ### 13 ###
       "non-blocking read on empty stdout returns empty");

}
