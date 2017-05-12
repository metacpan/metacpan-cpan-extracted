# Before `make install' is performed this script should be runnable with
# `make test'.  After `make install' it should work as `perl t/00all.t'.

use warnings;
use strict;

use Test;
use Getopt::Std;
use IO::File;

use constant TEST_FILENAME => 't/test.dat';

my @test_table;

BEGIN {
    my $test_file = IO::File->new(TEST_FILENAME);
    @test_table = grep { /\S/ && !/^\s*#/ } <$test_file>;
    chomp(@test_table);
    
    plan(
        tests   => 1 + map(/\G,?(\d+)/g, @test_table),
        todo    => [219]  # The SERVFAIL test isn't completely reliable.
    );
};

use Mail::SPF::Query;

# Test #1: Did the library load okay?
ok(1);

my %opts;
getopts('d:', \%opts);

my $test_log;
if ($opts{d}) {
    $test_log = IO::File->new(">$opts{d}") || die("Cannot open $opts{d} for output");
}

my $testnum = 2;

foreach my $tuple (@test_table) {
    my ($num, $domain, $ipv4, $expected_result, $expected_smtp_comment, $expected_header_comment) =
        ($tuple =~ /\t/ ? split(/\t/, $tuple) : split(' ', $tuple));
    
    my ($actual_result, $actual_smtp_comment, $actual_header_comment);
    
    my ($sender, $localpolicy) = split(':', $domain, 2);
    $sender =~ s/\\([0-7][0-7][0-7])/chr(oct($1))/ge;
    $domain = $sender;
    if ($domain =~ /\@/) { ($domain) = $domain =~ /\@(.+)/ }
    
    my $testcnt = 3;
    
    if ($expected_result =~ /=(pass|fail),/) {
        my $debug_log_buf = "# Detailed debug log for test(s) $num:\n";
        Mail::SPF::Query->clear_cache;
        my $query = eval {
            Mail::SPF::Query->new(
                ipv4    => $ipv4,
                sender  => $sender,
                helo    => $domain,
                debug   => 1,
                debuglog
                        => make_debug_log_accumulator(\$debug_log_buf),
                local   => $localpolicy
            )
        };
        
        my $ok = 1;
        my $header_comment;
        
        $actual_result = '';
        
        foreach my $e_result (split(/,/, $expected_result)) {
            if ($e_result !~ /=/) {
                my ($msg_result, $smtp_comment);
                ($msg_result, $smtp_comment, $header_comment) = eval {
                    $query->message_result2()
                };
                
                $actual_result .= $msg_result;
                
                $ok = ok($msg_result, $e_result) && $ok;
            }
            else {
                my ($recip, $expected_recip_result) = split(/=/, $e_result, 2);
                my ($recip_result, $smtp_comment) = eval {
                    $query->result2(split(';', $recip))
                };
                
                $actual_result .= "$recip=$recip_result,";
                $testcnt++;
                
                $ok = ok($recip_result, $expected_recip_result) && $ok;
            }
        }
        
        $header_comment =~ s/\S+: //;  # strip the reporting hostname prefix
        
        if ($expected_header_comment) {
            $ok = ok($header_comment, $expected_header_comment) && $ok;
        }
        
        $actual_header_comment = $header_comment;
        $actual_smtp_comment = '.';
        
        STDERR->print($debug_log_buf) if !$ok;
    }
    else {
        my $debug_log_buf = "# Detailed debug log for test(s) $num:\n";
        my ($result, $smtp_comment, $header_comment) = eval {
            Mail::SPF::Query->new(
                ipv4    => $ipv4,
                sender  => $sender,
                helo    => $domain,
                local   => $localpolicy,
                debug   => 1,
                debuglog
                        => make_debug_log_accumulator(\$debug_log_buf),
                default_explanation
                        => 'explanation'
            )->result()
        };
        
        $header_comment =~ s/^\S+: //;  # strip the reporting hostname prefix
        
        my $ok = ok($result,         $expected_result);
        if ($expected_smtp_comment) {
           $ok = ok($smtp_comment,   $expected_smtp_comment  ) && $ok;
           $ok = ok($header_comment, $expected_header_comment) && $ok;
        }
        
        $actual_result          = $result;
        $actual_smtp_comment    = $smtp_comment;
        $actual_header_comment  = $header_comment;
        
        STDERR->print($debug_log_buf) if !$ok;
    }
    
    if ($opts{d}) {
        $num = join(',', $testnum .. $testnum + $testcnt - 1);
        $testnum += $testcnt;
        $test_log->print(
            join(
                "\t",
                $num,
                $sender . ($localpolicy ? ":$localpolicy": ''),
                $ipv4,
                $actual_result,
                $actual_smtp_comment,
                $actual_header_comment
            ),
            "\n"
        );
    }
}

sub make_debug_log_accumulator {
    my ($log_buffer_ref) = @_;
    return sub { $$log_buffer_ref .= "# $_[0]\n" };
}

# vim:syn=perl
