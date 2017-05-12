#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin;
use Cwd qw/abs_path/;
use YAML::XS qw/DumpFile LoadFile/;
use DBI;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::Utils qw/get_server_timezone_diff/;
use vars qw/$dbh/;

my $path = abs_path( File::Spec->catdir( $FindBin::Bin, '..' ) );

print "You are going to configure Foorum for your own using.\n",
    '=' x 50,
    "\nPlease report bugs to AUTHORS if u meet any problem.\n\n";

my $foorum_local_file = File::Spec->catfile( $path, 'foorum_local.yml' );
print 'We are saving your configure to ', "$foorum_local_file\n",
    "You can change it by a plain editor (Notepad or Vi) later\n\n";

DBI:

# options
print 'Which Database are u used for Foorum (MySQL, SQLite, Pg): ';
my $db_type;
while ( $db_type = <> ) {
    chomp($db_type);
    if ( 'MySQL' eq $db_type or 'SQLite' eq $db_type or 'Pg' eq $db_type ) {
        last;
    } else {
        print 'Which Database are u used for Foorum (MySQL, SQLite, Pg): ';
    }
}

print "Your $db_type host (localhost by default): ";
my $dns_host = <>;
chomp($dns_host);
$dns_host = 'localhost' unless ($dns_host);

# SQLite don't require user and password
my ( $dns_user, $dns_password ) = ( '', '' );
if ( 'MySQL' eq $db_type or 'Pg' eq $db_type ) {
    print "Your $db_type user (root by default): ";
    $dns_user = <>;
    chomp($dns_user);
    $dns_user = 'root' unless ($dns_user);

    print "Your $db_type pass: ";
    $dns_password = <>;
    chomp($dns_password);
}

$db_type = lc($db_type) if ( 'MySQL' eq $db_type );
my $dns = "dbi:$db_type:database=foorum;host=$dns_host;port=3306";
my $theschwartz_dsn
    = "dbi:$db_type:database=theschwartz;host=$dns_host;port=3306";
if ( 'SQLite' eq $db_type ) {
    $dns             = "dbi:$db_type:$dns_host";
    $theschwartz_dsn = $dns;
    $theschwartz_dsn =~ s/foorum\./theschwartz\./;
}
eval {
    $dbh
        = DBI->connect( $dns, $dns_user, $dns_password,
        { RaiseError => 1, PrintError => 1 } )
        or die $DBI::errstr;
};
if ($@) {
    print "\nError:\n", $@, "\nPlease try it again\n\n";
    goto DBI;
}

print "Set your site domain which will be used in cron email.\n";
print 'Your site domain (http://www.foorumbbs.com/ by default): ';
my $domain = <>;
chomp($domain);
$domain = 'http://www.foorumbbs.com/' unless ($domain);
$domain .= '/';
$domain =~ s/\/+$/\//isg;

my $yaml;
if ( -e $foorum_local_file ) {
    $yaml = LoadFile($foorum_local_file);
}

$yaml->{dsn}             = $dns;
$yaml->{dsn_user}        = $dns_user;
$yaml->{dsn_pwd}         = $dns_password;
$yaml->{theschwartz_dsn} = $theschwartz_dsn;
$yaml->{site}->{domain}  = $domain;

# timezone setting
my $diff = get_server_timezone_diff();
$yaml->{timezonediff} = $diff * 3600;

print "\n\nSaving ....\n\n";
DumpFile( $foorum_local_file, $yaml );

print "Attention! The first user created will be site admin automatically!\n";
my $sql
    = q~INSERT INTO user_role (user_id, role, field) VALUES (1, 'admin', 'site')~;
$dbh->do($sql) or die $DBI::errstr;
print '[OK] ', $sql, "\n";

print '=' x 50, "\nDone!\n", "Thanks For Join US!\n";
