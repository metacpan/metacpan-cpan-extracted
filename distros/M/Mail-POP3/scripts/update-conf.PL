#!/usr/bin/perl

use Config;

open OUTPUT, ">$ARGV[0]" or die "$ARGV[0]: $!\n";
select OUTPUT;

print << "!GROK!THIS!";
$Config{'startperl'}
!GROK!THIS!
print << '!GROK!THIS!';

use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 1;

my @SCALARS = qw(
    mpopd_conf_version
    port
    max_servers
    mpopd_pid_file
    timeout
    greeting
    parse_to_disk
    mpopd_spool
    use_maildir
    path_to_homedir
    message_start
    message_end
    mailgroup
    mail_spool_dir
    mpopd_failed_mail
    host_mail_path
    reject_bogus_user
    allow_non_fqdn
    trusted_networks
    hosts_allow_deny
    auth_type
    userlist
    mpopd_pam_service
    shadow
    switch
    passsecret
    user_log_dir
    debug_log
    debug
    receivedfrom
    timezone
);

my @HASHES = qw(
    user_log
    user_auth
);
# forwardto is now addreceived, and its sense is inverted, so edit the
#  conf manually

my $in = shift;

die "Usage: $0 mpopd.conf\n" unless -r $in;

require $in;

my %config;
map { $config{$_} = ${ $::{$_} } } @SCALARS;
map { $config{$_} = \%{ $::{$_} } } @HASHES;
print Dumper(\%config);
!GROK!THIS!
