## @file
# Status process mechanism

package Lemonldap::NG::Handler::Lib::Status;

use strict;
use POSIX qw(setuid setgid);
use JSON qw(to_json);
use IO::Select;
use IO::Socket::INET;

our $VERSION = '2.0.2';

our $status   = {};
our $activity = [];
our $start    = int( time / 60 );
use constant MN_COUNT => 5;

our $page_title = 'Lemonldap::NG statistics';

## @fn private hashRef portalTab()
# @return Constant hash used to convert error codes into string.
sub portalTab {
    return {
        -5 => 'PORTAL_IDPCHOICE',
        -4 => 'PORTAL_SENDRESPONSE',
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
        81 => 'PE_NOTOKEN',
        82 => 'PE_TOKENEXPIRED',
        83 => 'PE_U2FFAILED',
        84 => 'PE_UNAUTHORIZEDPARTNER',
        85 => 'PE_RENEWSESSION',
        86 => 'PE_WAIT',
        87 => 'PE_MUSTAUTHN',
        88 => 'PE_MUSTHAVEMAIL',
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
    my ( $lastMn, $mn, $count, $cache, @ready );
    my $sel = IO::Select->new;
    $sel->add( \*STDIN );
    while ( my $opt = shift @ARGV ) {
        if ( $opt eq '--udp' ) {
            my $hp = shift @ARGV;
            my $s = IO::Socket::INET->new( Proto => 'udp', LocalAddr => $hp );
            $sel->add($s);
        }
        else {
            die "Unknown option $opt";
        }
    }
    while ( @ready = $sel->can_read ) {
        foreach my $fh (@ready) {
            if ( $fh == \*STDIN and $fh->eof ) {
                exit;
            }
            $_ = $fh->getline or next;
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

            elsif (/^RELOADCACHE(?:\s+(\S+?),(.+))?$/) {
                if ( my ( $cacheModule, $cacheOptions ) = ( $1, $2 ) ) {
                    eval "use $cacheModule;"
                      . "\$cache = new $cacheModule($cacheOptions);";
                    print STDERR "$@\n" if ($@);    # TODO: use logger instead
                }
                else {
                    $cache = undef;
                }
            }

            # Status requests

          # $args contains parameters passed to url status page (a=1 for example
          # if request is http://test.example.com/status?a=1). To be used
          # later...
            elsif (/^STATUS\s*(.+)?$/) {
                my $tmp = $1;
                my $out;
                if ( $fh == \*STDIN ) {
                    $out = \*STDOUT;
                }
                elsif ( $tmp =~ s/\s*host=(\S+)$// ) {
                    $out =
                      IO::Socket::INET->new( Proto => "udp", PeerAddr => $1 );
                    unless ($out) {
                        print STDERR "Unable to open UDP connection\n";
                        next;
                    }
                }
                else {
                    print STDERR "No host given, skipping\n";
                    next;
                }
                $out->autoflush(1);
                my $args = {};
                %$args = split( /[=&]/, $tmp ) if ($tmp);
                &head($out) unless ( $args->{json} );

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

                # JSON values
                if ( $args->{json} ) {
                    $out->print(
                        to_json( { average => $m, total => $c } ) . "\nEND\n" );
                }

                # Raw values (Dump)
                elsif ( $args->{'dump'} ) {
                    require Data::Dumper;
                    $out->print("<div id=\"dump\"><pre>\n");
                    $out->print(
                        Data::Dumper::Dumper( $status, $activity, $count ) );
                    $out->print("</pre></div>\n");
                    &end($out);
                }
                else {

                    # Total requests
                    $out->print("<h2>Total</h2>\n<div id=\"total\"><pre>\n");
                    $out->print(
                        sprintf(
                            "%-30s : \%6d (%.02f / mn)\n",
                            $_, $c->{$_}, $c->{$_} / $mn
                        )
                    ) foreach ( sort keys %$c );
                    $out->print("\n</pre></div>\n");

                    # Average
                    $out->print( "<h2>Average for last "
                          . MN_COUNT
                          . " minutes</h2>\n<div id=\"average\"><pre>\n" );
                    $out->print( sprintf( "%-30s : %6s / mn\n", $_, $m->{$_} ) )
                      foreach ( sort keys %$m );
                    $out->print("\n</pre></div>\n");

                    # Users connected
                    $out->print(
                        "<div id=\"users\"><p>\nTotal users : $u\n</p></div>\n"
                    );

                    # Local cache
                    if ($cache) {
                        my @t = $cache->get_keys( $_[1]->{namespace} );
                        $out->print( "<div id=\"cache\"><p>\nLocal Cache : "
                              . @t
                              . " objects\n</p></div>\n" );
                    }

                    # Uptime
                    $out->print( "<div id=\"up\"><p>\nServer up for : "
                          . &timeUp( $out, $mn )
                          . "\n</p></div>\n" );

                    # Top uri
                    if ( $args->{top} ) {
                        $args->{categories} ||=
                          'REJECT,PORTAL_FIRSTACCESS,LOGOUT,OK';

                        # Vhost activity
                        $out->print(
"<hr/>\n<h2>Virtual Host activity</h2>\n<div id=\"vhost\"><pre>\n"
                        );
                        foreach (
                            sort {
                                $count->{vhost}->{$b} <=> $count->{vhost}->{$a}
                            }
                            keys %{ $count->{vhost} }
                          )
                        {
                            $out->print(
                                sprintf( "%-40s : %6d\n",
                                    $_, $count->{vhost}->{$_} )
                            );
                        }
                        $out->print("\n</pre></div>\n");

                        # General
                        $out->print(
                            "<h2>Top used URI</h2>\n<div id=\"uri\"><pre>\n");
                        my $i = 0;
                        foreach (
                            sort { $count->{uri}->{$b} <=> $count->{uri}->{$a} }
                            keys %{ $count->{uri} }
                          )
                        {
                            last if ( $i == $args->{top} );
                            last unless ( $count->{uri}->{$_} );
                            $i++;
                            $out->print(
                                sprintf( "%-80s : %6d\n",
                                    $_, $count->{uri}->{$_} )
                            );
                        }
                        $out->print("\n</pre></div>\n");

                        # Top by category
                        $out->print(
"<table class=\"topByCat\"><tr><th style=\"width:20%\">Code</th><th>Top</th></tr>\n"
                        );
                        foreach my $cat ( split /,/, $args->{categories} ) {
                            $out->print(
"<tr><td>$cat</td><td nowrap>\n<div id=\"$cat\">\n"
                            );
                            topByCat( $out, $cat, $args->{top} );
                            $out->print("</div>\n</td></tr>");
                        }
                        $out->print("</table>\n");
                    }

                    &end($out);
                }
            }
            else {
                print STDERR "Status: Unknown command line : $_";
            }
        }
    }
}

## @rfn private string timeUp(int d)
# Return the time since the status process was launched (last Apache reload).
# @param $d Number of minutes since start
# @return Date in format "day hour minute"
sub timeUp {
    my ( $out, $d ) = @_;
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
    my ( $out, $cat, $max ) = @_;
    my $i = 0;
    $out->print("<pre>\n");
    foreach (
        sort { $status->{uri}->{$b}->{$cat} <=> $status->{uri}->{$a}->{$cat} }
        keys %{ $status->{uri} }
      )
    {
        last if ( $i == $max );
        last unless ( $status->{uri}->{$_}->{$cat} );
        $i++;
        $out->print(
            sprintf( "%-80s : %6d\n", $_, $status->{uri}->{$_}->{$cat} ) );
    }
    $out->print("</pre>\n");
}

## @rfn private void head()
# Display head of HTML status responses.
sub head {
    my $out = shift;
    $out->print( <<"EOF");
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
    my $out = shift;
    $out->print( <<"EOF");
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
