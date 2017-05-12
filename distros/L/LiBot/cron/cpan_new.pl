#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Furl;
use JSON;
use GDBM_File;
use Digest::SHA1 qw/sha1_hex/;
use Encode;

my $secret = shift;

my $dup_path = '/tmp/dup-cpan-new-lignr.gdbm';

my %dup;
unless ($ENV{DEBUG}) {
    tie %dup, 'GDBM_File', $dup_path, &GDBM_WRCREAT, 0640;
}

my $ua = Furl->new(agent => $0, timeout => 10);
my $res = $ua->get('http://api.metacpan.org/release/_search?sort=date:desc&size=5');
$res->is_success or die;
my $dat = decode_json($res->content);
for my $dist (map { $_->{_source} } @{$dat->{hits}->{hits}}) {
    next if $dup{$dist->{name}}++;

    my $msg = sprintf("%s - %s %s\n", $dist->{name}, $dist->{abstract}, "https://metacpan.org/release/$dist->{author}/$dist->{name}/");
    print $msg;

    unless ($ENV{DEBUG}) {
        my $res = $ua->post('http://lingr.com/api/room/say', [], [
            room => 'perl_jp',
            bot  => 'perl',
            bot_verifier => sha1_hex('perl' . $secret),
            text => encode_utf8($msg),
        ]);
        print $res->status_line . "\n";
        print "\n";
        print $res->content . "\n";
    }
}

