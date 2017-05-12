#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename 'basename';
use LWP::UserAgent;
use HTTP::Request;
use Time::HiRes ();

=head1 DESCRIPTION

This script shows how to limit download/upload speed with LWP::UseAgent.

=cut

my $LIMIT_UNIT_SECOND = 0.001;
sub BUFSIZE () { 32768 }

sub download_data_callback {
    my ($fh, $limit_bps) = @_;
    if (!$limit_bps) {
        return sub { print {$fh} $_[0] };
    }
    my $previous = [ [Time::HiRes::gettimeofday], 0 ];
    sub {
        print {$fh} $_[0];
        my $elapsed = Time::HiRes::tv_interval($previous->[0]);
        return 1 if $elapsed < $LIMIT_UNIT_SECOND;
        my $sleep = 8 * (tell($fh) - $previous->[1]) / $limit_bps - $elapsed;
        if ($sleep > 0) {
            select undef, undef, undef, $sleep;
            $previous->[0] = [Time::HiRes::gettimeofday];
            $previous->[1] = tell($fh);
        }
    };
}

sub upload_data_callback {
    my ($fh, $limit_bps) = @_;
    if (!$limit_bps) {
        return sub {
            my $len = read $fh, my $buf, BUFSIZE;
            if (!defined $len) {
                die "file read error: $!";
            } elsif ($len == 0) {
                undef; # EOF, finish
            } else {
                $buf;
            }
        };
    }
    my $previous = [ [Time::HiRes::gettimeofday], 0 ];
    sub {
        my $len = read $fh, my $buf, BUFSIZE;
        if (!defined $len) {
            die "file read error: $!";
        } elsif ($len == 0) {
            undef; # EOF, finish
        } else {
            $previous->[1] += $len;
            my $elapsed = Time::HiRes::tv_interval($previous->[0]);
            if ($elapsed > $LIMIT_UNIT_SECOND) {
                my $sleep = 8 * $previous->[1] / $limit_bps - $elapsed;
                if ($sleep > 0) {
                    select undef, undef, undef, $sleep;
                    $previous->[0] = [Time::HiRes::gettimeofday];
                    $previous->[1] = 0;
                }
            }
            $buf;
        }
    }
}

# download limit
{
    my $url = "http://www.cpan.org/src/5.0/perl-5.22.0.tar.gz";
    my $file = basename $url;
    open my $fh, ">", $file or die;
    binmode $fh;

    my $res = LWP::UserAgent->new->get(
        $url,
        ':content_cb' => download_data_callback($fh, 5 * (1024**2)), # 5Mbps
    );
    close $fh;
}

# upload limit
{
    my $file = "big-file.txt";
    open my $fh, "<", $file or die;
    binmode $fh;

    my $req = HTTP::Request->new(
        POST => "http://example.com",
        [ 'Content-Length' => -s $fh ],
        upload_data_callback($fh, 5 * (1024**2)), # 5Mbps
    );
    my $res = LWP::UserAgent->new->request($req);
    close $fh;
}
