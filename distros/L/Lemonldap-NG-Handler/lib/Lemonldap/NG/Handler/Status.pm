## @file
# Status process mechanism

package Lemonldap::NG::Handler::Status;

use strict;
use POSIX qw(setuid setgid);
use Data::Dumper;

our $VERSION = '1.9.1';

our $status   = {};
our $activity = [];
our $start    = int( time / 60 );
use constant MN_COUNT => 5;

our $page_title = 'Lemonldap::NG statistics';

## @fn private hashRef portalTab()
# @return Constant hash used to convert error codes into string.
sub portalTab {
    return {
        -5 => 'PORTAL_IMG_NOK',
        -4 => 'PORTAL_IMG_OK',
        -3 => 'PORTAL_INFO',
        -2 => 'PORTAL_REDIRECT',
        -1 => 'PORTAL_DONE',
        0  => 'PORTAL_OK',
        1  => 'PORTAL_SESSIONEXPIRED',
        2  => 'PORTAL_FORMEMPTY',
        3  => 'PORTAL_WRONGMANAGERACCOUNT',
        4  => 'PORTAL_USERNOTFOUND',
        5  => 'PORTAL_BADCREDENTIALS',
        6  => 'PORTAL_LDAPCONNECTFAILED',
        7  => 'PORTAL_LDAPERROR',
        8  => 'PORTAL_APACHESESSIONERROR',
        9  => 'PORTAL_FIRSTACCESS',
        10 => 'PORTAL_BADCERTIFICATE',
        21 => 'PORTAL_PP_ACCOUNT_LOCKED',
        22 => 'PORTAL_PP_PASSWORD_EXPIRED',
        23 => 'PORTAL_CERTIFICATEREQUIRED',
        24 => 'PORTAL_ERROR',
        25 => 'PORTAL_PP_CHANGE_AFTER_RESET',
        26 => 'PORTAL_PP_PASSWORD_MOD_NOT_ALLOWED',
        27 => 'PORTAL_PP_MUST_SUPPLY_OLD_PASSWORD',
        28 => 'PORTAL_PP_INSUFFICIENT_PASSWORD_QUALITY',
        29 => 'PORTAL_PP_PASSWORD_TOO_SHORT',
        30 => 'PORTAL_PP_PASSWORD_TOO_YOUNG',
        31 => 'PORTAL_PP_PASSWORD_IN_HISTORY',
        32 => 'PORTAL_PP_GRACE',
        33 => 'PORTAL_PP_EXP_WARNING',
        34 => 'PORTAL_PASSWORD_MISMATCH',
        35 => 'PORTAL_PASSWORD_OK',
        36 => 'PORTAL_NOTIFICATION',
        37 => 'PORTAL_BADURL',
        38 => 'PORTAL_NOSCHEME',
        39 => 'PORTAL_BADOLDPASSWORD',
        40 => 'PORTAL_MALFORMEDUSER',
        41 => 'PORTAL_SESSIONNOTGRANTED',
        42 => 'PORTAL_CONFIRM',
        43 => 'PORTAL_MAILFORMEMPTY',
        44 => 'PORTAL_BADMAILTOKEN',
        45 => 'PORTAL_MAILERROR',
        46 => 'PORTAL_MAILOK',
        47 => 'PORTAL_LOGOUT_OK',
        48 => 'PORTAL_SAML_ERROR',
        49 => 'PORTAL_SAML_LOAD_SERVICE_ERROR',
        50 => 'PORTAL_SAML_LOAD_IDP_ERROR',
        51 => 'PORTAL_SAML_SSO_ERROR',
        52 => 'PORTAL_SAML_UNKNOWN_ENTITY',
        53 => 'PORTAL_SAML_DESTINATION_ERROR',
        54 => 'PORTAL_SAML_CONDITIONS_ERROR',
        55 => 'PORTAL_SAML_IDPSSOINITIATED_NOTALLOWED',
        56 => 'PORTAL_SAML_SLO_ERROR',
        57 => 'PORTAL_SAML_SIGNATURE_ERROR',
        58 => 'PORTAL_SAML_ART_ERROR',
        59 => 'PORTAL_SAML_SESSION_ERROR',
        60 => 'PORTAL_SAML_LOAD_SP_ERROR',
        61 => 'PORTAL_SAML_ATTR_ERROR',
        62 => 'PORTAL_OPENID_EMPTY',
        63 => 'PORTAL_OPENID_BADID',
        64 => 'PORTAL_MISSINGREQATTR',
        65 => 'PORTAL_BADPARTNER',
        66 => 'PORTAL_MAILCONFIRMATION_ALREADY_SENT',
        67 => 'PORTAL_PASSWORDFORMEMPTY',
        68 => 'PORTAL_CAS_SERVICE_NOT_ALLOWED',
        69 => 'PORTAL_MAILFIRSTACCESS',
        70 => 'PORTAL_MAILNOTFOUND',
        71 => 'PORTAL_PASSWORDFIRSTACCESS',
        72 => 'PORTAL_MAILCONFIRMOK',
        73 => 'PORTAL_RADIUSCONNECTFAILED',
        74 => 'PORTAL_MUST_SUPPLY_OLD_PASSWORD',
        75 => 'PORTAL_FORBIDDENIP',
        76 => 'PORTAL_CAPTCHAERROR',
        77 => 'PORTAL_CAPTCHAEMPTY',
        78 => 'PORTAL_REGISTERFIRSTACCESS',
        79 => 'PORTAL_REGISTERFORMEMPTY',
        80 => 'PORTAL_REGISTERALREADYEXISTS',
    };
}

eval {
    setgid( ( getgrnam( $ENV{APACHE_RUN_GROUP} ) )[2] );
    setuid( ( getpwnam( $ENV{APACHE_RUN_USER} ) )[2] );
};

## @rfn void run()
# Main.
# Reads requests from STDIN to :
# - update counts
# - display results
sub run {
    $| = 1;
    my ( $lastMn, $mn, $count, $cache );
    while (<STDIN>) {
        $mn = int( time / 60 ) - $start + 1;

        # Cleaning activity array
        if ( $mn > $lastMn ) {
            for ( my $i = 0 ; $i < $mn - $lastMn ; $i++ ) {
                unshift @$activity, {};
                delete $activity->[ MN_COUNT + 1 ];
            }
        }
        $lastMn = $mn;

        # Activity collect
        if (
/^(\S+)\s+=>\s+(\S+)\s+(OK|REJECT|REDIRECT|LOGOUT|UNPROTECT|\-?\d+)$/
          )
        {
            my ( $user, $uri, $code ) = ( $1, $2, $3 );

            # Portal error translation
            $code = portalTab->{$code} || $code if ( $code =~ /^\-?\d+$/ );

            # Per user activity
            $status->{user}->{$user}->{$code}++;

            # Per uri activity
            $uri =~ s/^(.*?)\?.*$/$1/;
            $status->{uri}->{$uri}->{$code}++;
            $count->{uri}->{$uri}++;

            # Per vhost activity
            my ($vhost) = ( $uri =~ /^([^\/]+)/ );
            $status->{vhost}->{$vhost}->{$code}++;
            $count->{vhost}->{$vhost}++;

            # Last 5 minutes activity
            $activity->[0]->{$code}++;
        }

        elsif (/^RELOADCACHE(?:\s+(\S+?),(\S+))?$/) {
            if ( my ( $cacheModule, $cacheOptions ) = ( $1, $2 ) ) {
                eval "use $cacheModule;"
                  . "\$cache = new $cacheModule(\$cacheOptions);";
                print STDERR "$@\n" if ($@);    # TODO: use lmLog instead
            }
            else {
                $cache = undef;
            }
        }

        # Status requests

        # $args contains parameters passed to url status page (a=1 for example
        # if request is http://test.example.com/status?a=1). To be used
        # later...
        elsif (/^STATUS(?:\s+(\S+))?$/) {
            my $tmp  = $1;
            my $args = {};
            %$args = split( /[=&]/, $tmp ) if ($tmp);
            &head;

            my ( $c, $m, $u );
            foreach my $user ( keys %{ $status->{user} } ) {
                my $v = $status->{user}->{$user};
                $u++ unless ( $user =~ /^\d+\.\d+\.\d+\.\d+$/ );

                # Total requests
                foreach ( keys %$v ) {
                    $c->{$_} += $v->{$_};
                }
            }
            for ( my $i = 1 ; $i < @$activity ; $i++ ) {
                $m->{$_} += $activity->[$i]->{$_}
                  foreach ( keys %{ $activity->[$i] } );
            }
            foreach ( keys %$m ) {
                $m->{$_} = sprintf( "%.2f", $m->{$_} / MN_COUNT );
                $m->{$_} = int( $m->{$_} ) if ( $m->{$_} > 99 );
            }

            # Raw values (Dump)
            if ( $args->{'dump'} ) {
                print "<div id=\"dump\"><pre>\n";
                print Dumper( $status, $activity, $count );
                print "</pre></div>\n";
                &end;
            }
            else {

                # Total requests
                print "<h2>Total</h2>\n<div id=\"total\"><pre>\n";
                print sprintf( "%-30s : \%6d (%.02f / mn)\n",
                    $_, $c->{$_}, $c->{$_} / $mn )
                  foreach ( sort keys %$c );
                print "\n</pre></div>\n";

                # Average
                print "<h2>Average for last " . MN_COUNT
                  . " minutes</h2>\n<div id=\"average\"><pre>\n";
                print sprintf( "%-30s : %6s / mn\n", $_, $m->{$_} )
                  foreach ( sort keys %$m );
                print "\n</pre></div>\n";

                # Users connected
                print "<div id=\"users\"><p>\nTotal users : $u\n</p></div>\n";

                # Local cache
                if ($cache) {
                    my @t = $cache->get_keys( $_[1]->{namespace} );
                    print "<div id=\"cache\"><p>\nLocal Cache : " . @t
                      . " objects\n</p></div>\n";
                }

                # Uptime
                print "<div id=\"up\"><p>\nServer up for : "
                  . &timeUp($mn)
                  . "\n</p></div>\n";

                # Top uri
                if ( $args->{top} ) {
                    print "<hr/>\n";
                    $args->{categories} ||=
                      'REJECT,PORTAL_FIRSTACCESS,LOGOUT,OK';

                    # Vhost activity
                    print
"<h2>Virtual Host activity</h2>\n<div id=\"vhost\"><pre>\n";
                    foreach (
                        sort { $count->{vhost}->{$b} <=> $count->{vhost}->{$a} }
                        keys %{ $count->{vhost} }
                      )
                    {
                        print
                          sprintf( "%-40s : %6d\n", $_, $count->{vhost}->{$_} );
                    }
                    print "\n</pre></div>\n";

                    # General
                    print "<h2>Top used URI</h2>\n<div id=\"uri\"><pre>\n";
                    my $i = 0;
                    foreach (
                        sort { $count->{uri}->{$b} <=> $count->{uri}->{$a} }
                        keys %{ $count->{uri} }
                      )
                    {
                        last if ( $i == $args->{top} );
                        last unless ( $count->{uri}->{$_} );
                        $i++;
                        print
                          sprintf( "%-80s : %6d\n", $_, $count->{uri}->{$_} );
                    }
                    print "\n</pre></div>\n";

                    # Top by category
                    print
"<table class=\"topByCat\"><tr><th style=\"width:20%\">Code</th><th>Top</th></tr>\n";
                    foreach my $cat ( split /,/, $args->{categories} ) {
                        print
                          "<tr><td>$cat</td><td nowrap>\n<div id=\"$cat\">\n";
                        topByCat( $cat, $args->{top} );
                        print "</div>\n</td></tr>";
                    }
                    print "</table>\n";
                }

                &end;
            }
        }
    }
}

## @rfn private string timeUp(int d)
# Return the time since the status process was launched (last Apache reload).
# @param $d Number of minutes since start
# @return Date in format "day hour minute"
sub timeUp {
    my $d  = shift;
    my $mn = $d % 60;
    $d = ( $d - $mn ) / 60;
    my $h = $d % 24;
    $d = ( $d - $h ) / 24;
    return "${d}d ${h}h ${mn}mn";
}

## @rfn private void topByCat(string cat,int max)
# Display the "top 10" for a category (OK, REDIRECT,...).
# @param $cat Category to display
# @param $max Number of lines to display
sub topByCat {
    my ( $cat, $max ) = @_;
    my $i = 0;
    print "<pre>\n";
    foreach (
        sort { $status->{uri}->{$b}->{$cat} <=> $status->{uri}->{$a}->{$cat} }
        keys %{ $status->{uri} }
      )
    {
        last if ( $i == $max );
        last unless ( $status->{uri}->{$_}->{$cat} );
        $i++;
        print sprintf( "%-80s : %6d\n", $_, $status->{uri}->{$_}->{$cat} );
    }
    print "</pre>\n";
}

## @rfn private void head()
# Display head of HTML status responses.
sub head {
    print <<"EOF";
<!DOCTYPE html
    PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>$page_title</title>
<style type="text/css">
<!--
body{
	background: #000;
	color:#fff;
	padding:10px 50px;
	font-family:sans-serif;
}
h1 {
	margin:5px 20px;
}
h2 {
	margin:30px 0 0 0;
	padding:0 10px;
	border-left:20px solid orange;
	line-height:20px;
}
hr {
	height:1px;
	background-color:orange;
	margin:10px 0;
	border:0;
}
a {
	color:orange;
	text-decoration:none;
	font-weight:bold;
}
#footer {
	text-align:center;
}
#footer a {
	margin-left:10px;
	padding:5px;
	border-bottom:1px solid #fff;
}
#footer a:hover {
	border-color:orange;
}
table.topByCat {
	table-layout:fixed;
	border-collapse:collapse;
	border:1px solid #fff;
	width:100%;
}
table.topByCat td, table.topByCat th {
	padding:5px;
	border:1px solid #fff;
}
table.topByCat th {
	color:orange;
	text-align:center;
}
-->
</style>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
<table>
<tr>
<td style="width:30px;height:30px;background:orange;">&nbsp;</td>
<td>&nbsp;</td>
<td rowspan=2><h1>$page_title</h1></td>
</tr>
</tr>
<td>&nbsp;</td>
<td style="width:30px;height:30px;background:orange;">&nbsp;</td>
</tr>
</table>
EOF
}

## @rfn private void end()
# Display end of HTML status responses.
sub end {
    print <<"EOF";
<hr/>
<div id="footer">
<script type="text/javascript" language="Javascript">
  //<!--
  var a = document.location.href;
  a=a.replace(/\\?.*\$/,'');
  document.write('<a href="'+a+'">Standard view</a>');
  document.write('<a href="'+a+'?top=10&categories=REJECT,PORTAL_FIRSTACCESS,LOGOUT,OK">Top 10</a>');
  document.write('<a href="'+a+'?dump=1">Raw results</a>');
  //-->
</script>
</div>
</body>
</html>
END
EOF
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Handler::Status - Perl extension to add a mod_status like system for L<Lemonldap::NG::Handler>

=head1 SYNOPSIS

=head2 Create your Apache module

Create your own package (example using a central configuration database):

  package My::Package;
  use Lemonldap::NG::Handler::SharedConf;
  @ISA = qw(Lemonldap::NG::Handler::SharedConf);
  
  __PACKAGE__->init ( {
    # Activate status feature
    status              => 1,
    # Local storage used for sessions and configuration
    localStorage        => "Cache::DBFile",
    localStorageOptions => {...},
    # How to get my configuration
    configStorage       => {
        type                => "DBI",
        dbiChain            => "DBI:mysql:database=lemondb;host=$hostname",
        dbiUser             => "lemonldap",
        dbiPassword          => "password",
    }
    # ... See Lemonldap::NG::Handler
  } );

=head2 Configure Apache

Call your package in /apache-dir/conf/httpd.conf:

  # Load your package
  PerlRequire /My/File
  # Normal Protection
  PerlHeaderParserHandler My::Package
  
  # Status page
  <Location /status>
    Order deny,allow
    Allow from 10.1.1.0/24
    Deny from all
    PerlHeaderParserHandler My::Package->status
  </Location>

=head1 DESCRIPTION

Lemonldap::NG::Handler::Status adds a mod_status like feature to display
Lemonldap::NG::Handler activity on a protected server. It can so be used by
L<mrtg> or directly browsed by your browser.

=head1 SEE ALSO

L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Manager>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2008-2012 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=item Copyright (C) 2012 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2010-2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
