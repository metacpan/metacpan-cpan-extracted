#!/usr/bin/perl -I../lib

use strict;
use warnings;
use Test::More tests => 4;

use Mail::DKIM::Verifier;

my $homedir = ( -d "t" ) ? "t" : ".";

sub read_file {
    my $srcfile = shift;
    open my $fh, "<", $srcfile
      or die "Error: can't open $srcfile: $!\n";
    binmode $fh;
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

sub test_email_strict {
    my ( $file, $expected_result ) = @_;
    print "# verifying message '$file'\n";
    my $dkim  = Mail::DKIM::Verifier->new( 'Strict' => 1 );
    my $path  = "$homedir/corpus/$file";
    my $email = read_file($path);
    $dkim->PRINT($email);
    $dkim->CLOSE;
    my $result = $dkim->result;
    print "#   result: " . $dkim->result_detail . "\n";
    ok( $result eq $expected_result, "'$file' should '$expected_result'" );
}

# Test strict mode
test_email_strict( "good_1878523.txt",  "invalid" );
test_email_strict( "good_ietf01_1.txt", "fail" );
test_email_strict( "good_qp_1.txt",     "invalid" );
test_email_strict( "mine_ietf01_3.txt", "pass" );

# override the DNS implementation, so that these tests do not
# rely on DNS servers I have no control over
my $CACHE;

sub Mail::DKIM::DNS::fake_query {
    my ( $domain, $type ) = @_;
    die "can't lookup $type record" if $type ne "TXT";

    unless ($CACHE) {
        open my $fh, "<", "$homedir/FAKE_DNS.dat"
          or die "Error: cannot read $homedir/FAKE_DNS.dat: $!\n";
        $CACHE = {};
        while (<$fh>) {
            chomp;
            next if /^\s*[#;]/ || /^\s*$/;
            my ( $k, $v ) = split /\s+/, $_, 2;
            $CACHE->{$k} =
                ( $v =~ /^~~(.*)~~$/ ) ? "$1"
              : $v eq "NXDOMAIN"       ? []
              :                          [ bless \$v, "FakeDNS::Record" ];
        }
        close $fh;
    }

    if ( not exists $CACHE->{$domain} ) {
        warn "did not cache that DNS entry: $domain\n";
        print STDERR ">>>\n";
        my @result = Mail::DKIM::DNS::orig_query( $domain, $type );
        if ( !@result ) {
            print STDERR "No results: $@\n";
        }
        else {
            foreach my $rr (@result) {

                # join with no intervening spaces, RFC 6376
                if ( Net::DNS->VERSION >= 0.69 ) {

                    # must call txtdata() in a list context
                    printf STDERR ( "%s\n", join( "", $rr->txtdata ) );
                }
                else {
                    # char_str_list method is 'historical'
                    printf STDERR ( "%s\n", join( "", $rr->char_str_list ) );
                }
            }
        }
        print STDERR "<<<\n";
        die;
    }

    if ( ref $CACHE->{$domain} ) {
        return @{ $CACHE->{$domain} };
    }
    else {
        die "DNS error: $CACHE->{$domain}\n";
    }
}

BEGIN {
    unless ( $ENV{use_real_dns} ) {
        *Mail::DKIM::DNS::orig_query = *Mail::DKIM::DNS::query;
        *Mail::DKIM::DNS::query      = *Mail::DKIM::DNS::fake_query;
    }
}

package FakeDNS::Record;

sub type {
    return "TXT";
}

sub char_str_list {
    return ${ $_[0] };
}

sub txtdata {
    return ${ $_[0] };
}

