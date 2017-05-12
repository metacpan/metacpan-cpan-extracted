#!/usr/bin/perl
use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use FCGI::Client;
use IO::Socket::INET;

GetOptions(
    'h|help' => \my $help,
) or pod2usage();
pod2usage() if $help;
pod2usage() if @ARGV < 1;
my ($fcgi_file, $query_string) = @ARGV;

&main;exit;

sub main {
    my $srvsock = IO::Socket::INET->new(
        LocalPort => 0,
        Listen    => 1,
    ) or die $!;

    defined( my $kid = fork ) or die "Cannot fork - $!";

    if( $kid == 0 ) {
        open STDIN, "<&", $srvsock;
        close STDOUT;
        exec( $fcgi_file );
        die "Cannot exec $fcgi_file - $!";
    }

    my $sock = IO::Socket::INET->new(
        PeerHost => $srvsock->sockhost,
        PeerPort => $srvsock->sockport,
    ) or die $!;

    my $client = FCGI::Client::Connection->new( sock => $sock );
    my ( $stdout, $stderr ) = $client->request(
        +{
            REQUEST_METHOD => 'GET',
            QUERY_STRING   => $query_string || '',
        },
        ''
    );
    print STDERR $stderr if $stderr;
    print $stdout;
}

__END__

=head1 NAME

fcgicli.pl - 

=head1 SYNOPSIS

    $ fcgicli.pl foo.fcgi [foo=bar&hoge=fuga]

=head1 AUTHOR

Paul Evans

Tokuhiro Matsuno
