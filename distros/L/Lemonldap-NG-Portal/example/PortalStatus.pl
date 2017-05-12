#!/usr/bin/perl

use CGI;
use strict;

# Status page for Lemonldap::NG::Portal
#
# This CGI displays some information about Lemonldap::NG sessions
#

BEGIN {

    sub Apache::Session::get_sessions_count {
        return 0;
    }

    sub Apache::Session::MySQL::get_sessions_count {
        my $class = shift;
        my $args  = shift;
        my $dbh =
          DBI->connect( $args->{DataSource}, $args->{UserName},
            $args->{Password} )
          or die("$!$@");
        my $table = $args->{TableName} || 'sessions';
        my $sth = $dbh->prepare("SELECT count(*) from $table");
        $sth->execute;
        return ( $sth->fetchrow_array )[0];
    }

    *Apache::Session::Postgres::get_sessions_count =
      \&Apache::Session::MySQL::get_sessions_count;
    *Apache::Session::Oracle::get_sessions_count =
      \&Apache::Session::MySQL::get_sessions_count;
    *Apache::Session::Sybase::get_sessions_count =
      \&Apache::Session::MySQL::get_sessions_count;
    *Apache::Session::Informix::get_sessions_count =
      \&Apache::Session::MySQL::get_sessions_count;

    sub Apache::Session::File::get_sessions_count {
        my $class = shift;
        my $args  = shift;
        $args->{Directory} ||= '__SESSIONDIR__';
        unless ( opendir DIR, $args->{Directory} ) {
            die "Cannot open directory $args->{Directory}\n";
        }
        my @t =
          grep { -f "$args->{Directory}/$_" and /^[A-Za-z0-9@\-]+$/ }
          readdir(DIR);
        closedir DIR;
        return $#t + 1;
    }

    sub Apache::Session::DB_File::get_sessions_count {
        my $class = shift;
        my $args  = shift;

        if ( !tied %{ $class->{dbm} } ) {
            my $rv = tie %{ $class->{dbm} }, 'DB_File', $args->{FileName};

            if ( !$rv ) {
                die "Could not open dbm file $args->{FileName}: $!";
            }
        }
        my @t = keys( %{ $class->{dbm} } );
        return $#t + 1;
    }
}

use Lemonldap::NG::Common::Conf;
use Lemonldap::NG::Common::Conf::Constants;
use strict;
use DBI;

my $cgi = CGI->new();

print $cgi->header(
    -charset => 'ascii',
    -type    => 'text/plain',
);

print "LEMONLDAP::NG::PORTAL STATUS\n\nConfiguration          : ";

my $lmconf = Lemonldap::NG::Common::Conf->new();

unless ($lmconf) {
    print "unable to create conf object\n";
}
else {
    my $conf = $lmconf->getConf;
    unless ($conf) {
        write "unable to get configuration ($!)\n";
    }
    else {
        print "OK\nApache::Session module : ";
        my $tmp = $conf->{globalStorage};
        eval "use $tmp";
        if ($@) {
            print "unable to load $tmp ($@)\n";
        }
        else {
            my $t = $tmp->get_sessions_count( $conf->{globalStorageOptions} );
            print "OK\nActive sessions        : $t\n";
        }
    }
}

1;

