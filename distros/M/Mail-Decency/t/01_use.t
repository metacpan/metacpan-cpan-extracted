#!/usr/bin/perl

use Test::More tests => 48;

#
# VERSION 0.1.6
#

BEGIN {
    ok( eval "use v5.10; 1", "Perl 5.10" ) or die "Perl 5.10 required";
    use_ok( 'Archive::Tar', '1.40' ) or die;
    use_ok( 'Cache::FastMmap' ) or die;
    use_ok( 'Cache::File' ) or die;
    use_ok( 'Cache::Memcached' ) or die;
    use_ok( 'Crypt::OpenSSL::RSA' ) or die;
    use_ok( 'DateTime' ) or die;
    use_ok( 'DBD::SQLite' ) or die;
    use_ok( 'DBI' ) or die;
    use_ok( 'DBIx::Connector' ) or die;
    use_ok( 'Email::Valid' ) or die;
    use_ok( 'Getopt::Long' ) or die;
    use_ok( 'IO::File' ) or die;
    use_ok( 'IO::Handle' ) or die;
    use_ok( 'IO::Pipe' ) or die;
    use_ok( 'IO::Socket' ) or die;
    use_ok( 'IO::YAML', '0.08' ) or die;
    use_ok( 'IPC::Semaphore', '2.01' ) or die;
    use_ok( 'IPC::SysV', '2.01' ) or die;
    use_ok( 'Mail::DKIM', '0.38' ) or die;
    use_ok( 'Mail::SPF' ) or die;
    use_ok( 'MIME::Base64' ) or die;
    use_ok( 'MIME::Lite' ) or die;
    use_ok( 'MIME::Parser' ) or die;
    use_ok( 'MIME::QuotedPrint' ) or die;
    use_ok( 'Moose', '1.00' ) or die;
    use_ok( 'Net::Domain::TLD' ) or die;
    use_ok( 'Net::DNS' ) or die;
    use_ok( 'Net::DNSBL::Client' ) or die;
    use_ok( 'Net::LMTP' ) or die;
    use_ok( 'Net::Milter' ) or die;
    use_ok( 'Net::Netmask' ) or die;
    use_ok( 'Net::SMTP' ) or die;
    use_ok( 'POE' ) or die;
    use_ok( 'POE::Filter::Postfix::Plain' ) or die;
    use_ok( 'POE::Wheel::FollowTail' ) or die;
    use_ok( 'POE::Wheel::ReadWrite' ) or die;
    use_ok( 'POE::Wheel::SocketFactory' ) or die;
    use_ok( 'Regexp::Common' ) or die;
    use_ok( 'SQL::Abstract' ) or die;
    use_ok( 'Throwable' ) or die;
    use_ok( 'version', '0.74' ) or die;
    use_ok( 'YAML' ) or die;
    
    use_ok( 'Mail::Decency::Policy' ) or die;
    use_ok( 'Mail::Decency::ContentFilter' ) or die;
    use_ok( 'Mail::Decency::LogParser' ) or die;
    use_ok( 'Mail::Decency::Helper::Database' ) or die;
    use_ok( 'Mail::Decency::Helper::Cache' ) or die;
};
