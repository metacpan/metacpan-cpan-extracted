#!/usr/bin/env perl
use strict;
use warnings;
use IO::Socket::SSL;
use File::Spec;

die unless @ARGV == 3;
my $server_port = shift @ARGV;
my ( $username, $password ) = map { quotemeta $_ } @ARGV;

my $server = IO::Socket::SSL->new(
    LocalAddr     => '127.0.0.1',
    LocalPort     => $server_port,
    Proto         => 'tcp',
    ReuseAddr     => 1,
    Listen        => 2,
    SSL_key_file  => File::Spec->catfile(qw/t certs server-key.pem/),
    SSL_cert_file => File::Spec->catfile(qw/t certs server-cert.pem/),
) or die "Couldn't listen: " . IO::Socket::SSL::errstr() . "\n";

while ( my $client = $server->accept() ) {
    local $/ = "\r\n";
    print {$client} "* OK IMAP4rev1 server ready\r\n";
    chomp( my $response = <$client> );
    $response =~ s{^(\S+)\s+}{}xms;
    my $cid = $1 || q{*};
    if ( $response =~ m{^LOGIN \s+ "?$username"? \s+ "?$password"?}xms ) {
        print {$client} "$cid OK LOGIN Completed\r\n";
    }
    else {
        print {$client} "$cid NO LOGIN Incorrect username or password\r\n";
    }
    close($client);
}

close($server);

