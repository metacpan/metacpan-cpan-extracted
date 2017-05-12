## @file
# Base package for all Lemonldap::NG CGI

## @class
# Base class for all Lemonldap::NG CGI
package Lemonldap::NG::Common::CGI;

use strict;

use File::Basename;
use MIME::Base64;
use Time::Local;
use CGI;
use utf8;
use Encode;
use Net::CIDR::Lite;

#parameter syslog Indicates syslog facility for logging user actions

our $VERSION = '1.9.1';
our $_SUPER;
our @ISA;

BEGIN {
    if ( exists $ENV{MOD_PERL} ) {
        if ( $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION} >= 2 ) {
            eval 'use constant MP => 2;';
        }
        else {
            eval 'use constant MP => 1;';
        }
    }
    else {
        eval 'use constant MP => 0;';
    }
    $_SUPER = 'CGI';
    @ISA    = ('CGI');
}

sub import {
    my $pkg = shift;
    if ( $pkg eq __PACKAGE__ and @_ and $_[0] eq "fastcgi" ) {
        eval 'use CGI::Fast';
        die($@) if ($@);
        unshift @ISA, 'CGI::Fast';
        $_SUPER = 'CGI::Fast';
    }
}

## @cmethod Lemonldap::NG::Common::CGI new(@p)
# Constructor: launch CGI::new() then secure parameters since CGI store them at
# the root of the object.
# @param p arguments for CGI::new()
# @return new Lemonldap::NG::Common::CGI object
sub new {
    my $class = shift;
    my $self = $_SUPER->new(@_) or return undef;
    $self->{_prm} = {};
    my @tmp = $self->param();
    foreach (@tmp) {
        $self->{_prm}->{$_} = $self->param($_);
        $self->delete($_);
    }
    $self->{lang} = extract_lang();
    bless $self, $class;
    return $self;
}

## @method scalar param(string s, scalar newValue)
# Return the wanted parameter issued of GET or POST request. If $s is not set,
# return the list of parameters names
# @param $s name of the parameter
# @param $newValue if set, the parameter will be set to his value
# @return datas passed by GET or POST method
sub param {
    my ( $self, $p, $v ) = @_;
    $self->{_prm}->{$p} = $v if ($v);
    unless ( defined $p ) {
        return keys %{ $self->{_prm} };
    }
    return $self->{_prm}->{$p};
}

## @method scalar rparam(string s)
# Return a reference to a parameter
# @param $s name of the parameter
# @return ref to parameter data
sub rparam {
    my ( $self, $p ) = @_;
    return $self->{_prm}->{$p} ? \$self->{_prm}->{$p} : undef;
}

## @method void lmLog(string mess, string level)
# Log subroutine. Use Apache::Log in ModPerl::Registry context else simply
# print on STDERR non debug messages.
# @param $mess Text to log
# @param $level Level (debug|info|notice|error)
sub lmLog {
    my ( $self, $mess, $level ) = @_;
    my $call;
    if ( $level eq 'debug' ) {
        $mess = ( ref($self) ? ref($self) : $self ) . ": $mess";
    }
    else {
        my @tmp = caller();
        $call = "$tmp[1] $tmp[2]:";
    }
    if ( $self->r and MP() ) {
        $self->abort( "Level is required",
            'the parameter "level" is required when lmLog() is used' )
          unless ($level);
        if ( MP() == 2 ) {
            require Apache2::Log;
            Apache2::ServerRec->log->debug($call) if ($call);
            Apache2::ServerRec->log->$level($mess);
        }
        else {
            Apache->server->log->debug($call) if ($call);
            Apache->server->log->$level($mess);
        }
    }
    else {
        $self->{hideLogLevels} = 'debug|info'
          unless defined( $self->{hideLogLevels} );
        my $re = qr/^(?:$self->{hideLogLevels})$/o;
        print STDERR "$call\n" if ( $call and 'debug' !~ $re );
        print STDERR "[$level] $mess\n" unless ( $level =~ $re );
    }
}

## @method void setApacheUser(string user)
# Set user for Apache logs in ModPerl::Registry context. Does nothing else.
# @param $user data to set as user in Apache logs
sub setApacheUser {
    my ( $self, $user ) = @_;
    if ( $self->r and MP() ) {
        $self->lmLog( "Inform Apache about the user connected", 'debug' );
        if ( MP() == 2 ) {
            require Apache2::Connection;
            $self->r->user($user);
        }
        else {
            $self->r->connection->user($user);
        }
    }
    $ENV{REMOTE_USER} = $user;
}

##@method string getApacheHtdocsPath()
# Return absolute path to the htdocs directory where the current script is
# @return path string
sub getApacheHtdocsPath {
    return dirname( $ENV{SCRIPT_FILENAME} || $0 );
}

## @method void soapTest(string soapFunctions, object obj)
# Check if request is a SOAP request. If it is, launch
# Lemonldap::NG::Common::CGI::SOAPServer and exit. Else simply return.
# @param $soapFunctions list of authorized functions.
# @param $obj optional object that will receive SOAP requests
sub soapTest {
    my ( $self, $soapFunctions, $obj ) = @_;

    # If non form encoded datas are posted, we call SOAP Services
    if ( $ENV{HTTP_SOAPACTION} ) {
        require
          Lemonldap::NG::Common::CGI::SOAPServer;    #link protected dispatcher
        require
          Lemonldap::NG::Common::CGI::SOAPService;   #link protected soapService
        my @func = (
            ref($soapFunctions) ? @$soapFunctions : split /\s+/,
            $soapFunctions
        );
        my $dispatcher =
          Lemonldap::NG::Common::CGI::SOAPService->new( $obj || $self, @func );
        Lemonldap::NG::Common::CGI::SOAPServer->dispatch_to($dispatcher)
          ->handle($self);
        $self->quit();
    }
}

## @method string header_public(string filename)
# Implements the "304 Not Modified" HTTP mechanism.
# If HTTP request contains an "If-Modified-Since" header and if
# $filename was not modified since, prints the "304 Not Modified" response and
# exit. Else, launch CGI::header() with "Cache-Control" and "Last-Modified"
# headers.
# @param $filename Optional name of the reference file. Default
# $ENV{SCRIPT_FILENAME}.
# @return Common Gateway Interface standard response header
sub header_public {
    my $self     = shift;
    my $filename = shift;
    $filename ||= $ENV{SCRIPT_FILENAME};
    my @tmp  = stat($filename);
    my $date = $tmp[9];
    my $hd   = gmtime($date);
    $hd =~ s/^(\w+)\s+(\w+)\s+(\d+)\s+([\d:]+)\s+(\d+)$/$1, $3 $2 $5 $4 GMT/;
    my $year = $5;
    my $cm   = $2;

    # TODO: Remove TODO_ for stable releases
    if ( my $ref = $ENV{HTTP_IF_MODIFIED_SINCE} ) {
        my %month = (
            jan => 0,
            feb => 1,
            mar => 2,
            apr => 3,
            may => 4,
            jun => 5,
            jul => 6,
            aug => 7,
            sep => 8,
            oct => 9,
            nov => 10,
            dec => 11
        );
        if ( $ref =~ /^\w+,\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)/ ) {
            my $m = $month{ lc($2) };
            $year-- if ( $m > $month{ lc($cm) } );
            $ref = timegm( $6, $5, $4, $1, $m, $3 );
            if ( $ref == $date ) {
                print $self->SUPER::header( -status => '304 Not Modified', @_ );
                $self->quit();
            }
        }
    }
    return $self->SUPER::header(
        '-Last-Modified' => $hd,
        '-Cache-Control' => 'public; must-revalidate; max-age=1800',
        @_
    );
}

## @method void abort(string title, string text)
# Display an error message and exit.
# Used instead of die() in Lemonldap::NG CGIs.
# @param title Title of the error message
# @param text Optional text. Default: "See Apache's logs"
sub abort {
    my $self = shift;
    my $cgi  = CGI->new();
    my ( $t1, $t2 ) = @_;

    # Default message
    $t2 ||= "See Apache's logs";

    # Change \n into <br /> for HTML
    my $t2html = $t2;
    $t2html =~ s#\n#<br />#g;

    print $cgi->header( -type => 'text/html; charset=utf-8', );
    print $cgi->start_html(
        -title    => $t1,
        -encoding => 'utf8',
        -style    => {
            -code => '
body{
	background:#000;
	color:#fff;
	padding:10px 50px;
	font-family:sans-serif;
}
a {
	text-decoration:none;
	color:#fff;
}
        '
        },
    );
    print "<h1>$t1</h1><p>$t2html</p>";
    print
      '<center><a href="http://lemonldap-ng.org">LemonLDAP::NG</a></center>';
    print STDERR ( ref($self) || $self ) . " error: $t1, $t2\n";
    print $cgi->end_html();
    $self->quit();
}

##@method private void startSyslog()
# Open syslog connection.
sub startSyslog {
    my $self = shift;
    return if ( $self->{_syslog} );
    eval {
        require Sys::Syslog;
        Sys::Syslog->import(':standard');
        openlog( 'lemonldap-ng', 'ndelay,pid', $self->{syslog} );
    };
    $self->abort( "Unable to use syslog", $@ ) if ($@);
    $self->{_syslog} = 1;
}

##@method void userLog(string mess, string level)
# Log user actions on Apache logs or syslog.
# @param $mess string to log
# @param $level level of log message
sub userLog {
    my ( $self, $mess, $level ) = @_;
    if ( $self->{syslog} ) {
        $self->startSyslog();
        $level =~ s/^warn$/warning/;
        syslog( $level || 'notice', $mess );
    }
    else {
        $self->lmLog( $mess, $level );
    }
}

##@method void userInfo(string mess)
# Log non important user actions. Alias for userLog() with facility "info".
# @param $mess string to log
sub userInfo {
    my ( $self, $mess ) = @_;
    $mess = "Lemonldap::NG : $mess (" . $self->ipAddr . ")";
    $self->userLog( $mess, 'info' );
}

##@method void userNotice(string mess)
# Log user actions like access and logout. Alias for userLog() with facility
# "notice".
# @param $mess string to log
sub userNotice {
    my ( $self, $mess ) = @_;
    $mess = "Lemonldap::NG : $mess (" . $self->ipAddr . ")";
    $self->userLog( $mess, 'notice' );
}

##@method void userError(string mess)
# Log user errors like "bad password". Alias for userLog() with facility
# "warn".
# @param $mess string to log
sub userError {
    my ( $self, $mess ) = @_;
    $mess = "Lemonldap::NG : $mess (" . $self->ipAddr . ")";
    $self->userLog( $mess, 'warn' );
}

## @method protected scalar _sub(string sub, array p)
# Launch $self->{$sub} if defined, else launch $self->$sub.
# @param $sub name of the sub to launch
# @param @p parameters for the sub
sub _sub {
    my ( $self, $sub, @p ) = @_;
    if ( $self->{$sub} ) {
        $self->lmLog( "processing to custom sub $sub", 'debug' );
        return &{ $self->{$sub} }( $self, @p );
    }
    else {
        $self->lmLog( "processing to sub $sub", 'debug' );
        return $self->$sub(@p);
    }
}

##@method string extract_lang
#@return array of user's preferred languages (two letters)
sub extract_lang {
    my $self = shift;

    my @langs = split /,\s*/, ( shift || $ENV{HTTP_ACCEPT_LANGUAGE} || "" );
    my @res = ();

    foreach (@langs) {

        # Languages are supposed to be sorted by preference
        my $lang = ( split /;/ )[0];

        # Take first part of lang code (part before -)
        $lang = ( split /-/, $lang )[0];

        # Go to next if lang was already added
        next if grep( /\Q$lang\E/, @res );

        # Store lang only if size is 2 characters
        push @res, $lang if ( length($lang) == 2 );
    }

    return \@res;
}

##@method void translate_template(string text_ref, string lang)
# translate_template is used as an HTML::Template filter to tranlate strings in
# the wanted language
#@param text_ref reference to the string to translate
#@param lang optionnal language wanted. Falls to browser language instead.
#@return
sub translate_template {
    my $self     = shift;
    my $text_ref = shift;

    # Decode UTF-8
    utf8::decode($$text_ref) unless ( $ENV{FCGI_ROLE} );

    # Test if a translation is available for the selected language
    # If not available, return the first translated string
    # <lang en="Please enter your credentials" fr="Merci de vous autentifier"/>
    foreach ( @{ $self->{lang} } ) {
        if ( $$text_ref =~ m/$_=\"(.*?)\"/ ) {
            $$text_ref =~ s/<lang.*$_=\"(.*?)\".*?\/>/$1/gx;
            return;
        }
    }
    $$text_ref =~ s/<lang\s+\w+=\"(.*?)\".*?\/>/$1/gx;
}

##@method void session_template(string text_ref)
# session_template is used as an HTML::Template filter to replace session info
# by their value
#@param text_ref reference to the string to translate
#@return
sub session_template {
    my $self     = shift;
    my $text_ref = shift;

    # Replace session information
    $$text_ref =~ s/\$(\w+)/decode("utf8",$self->{sessionInfo}->{$1})/ge;
}

## @method private void quit()
# Simply exit.
sub quit {
    my $self = shift;
    if ( $_SUPER eq 'CGI::Fast' ) {
        next LMAUTH;
    }
    else {
        exit;
    }
}

##@method string ipAddr()
# Retrieve client IP address from remote address or X-FORWARDED-FOR header
#@return client IP
sub ipAddr {
    my $self = shift;

    unless ( $self->{ipAddr} ) {
        $self->{ipAddr} = $ENV{REMOTE_ADDR};
        if ( my $xheader = $ENV{HTTP_X_FORWARDED_FOR} ) {
            if (   $self->{trustedProxies} =~ /\*/
                or $self->{useXForwardedForIP} )
            {
                $self->{ipAddr} = $1 if ( $xheader =~ /^([^,]*)/ );
            }
            elsif ( $self->{trustedProxies} ) {
                my $localIP =
                  Net::CIDR::Lite->new("127.0.0.0/8"); # TODO: add IPv6 local IP
                my $trustedIP =
                  Net::CIDR::Lite->new( split /\s+/, $self->{trustedProxies} );
                while (
                    (
                           $localIP->find( $self->{ipAddr} )
                        or $trustedIP->find( $self->{ipAddr} )
                    )
                    and $xheader =~ s/[,\s]*([^,\s]+)$//
                  )
                {

                    # because it is of no use to store a local IP as client IP
                    $self->{ipAddr} = $1 unless ( $localIP->find($1) );
                }
            }
        }
    }
    return $self->{ipAddr};
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::CGI - Simple module to extend L<CGI> to manage
HTTP "If-Modified-Since / 304 Not Modified" system.

=head1 SYNOPSIS

  use Lemonldap::NG::Common::CGI;
  
  my $cgi = Lemonldap::NG::Common::CGI->new();
  $cgi->header_public($ENV{SCRIPT_FILENAME});
  print "<html><head><title>Static page</title></head>";
  ...

=head1 DESCRIPTION

Lemonldap::NG::Common::CGI just add header_public subroutine to CGI module to
avoid printing HTML elements that can be cached.

=head1 METHODS

=head2 header_public

header_public works like header (see L<CGI>) but the first argument has to be
a filename: the last modify date of this file is used for reference.

=head2 EXPORT

=head1 SEE ALSO

L<Lemonldap::NG::Manager>, L<CGI>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2008-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012-2013 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2010-2016 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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
