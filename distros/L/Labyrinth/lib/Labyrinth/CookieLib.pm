package Labyrinth::CookieLib;

use warnings;
use strict;

use vars qw(%cookie_config $VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::CookieLib - Cookie Management for Labyrinth

=head1 DESCRIPTION

This collection of functions provides the cookie functionality within 
the Labyrinth framework.

Based on the NMS cookielib script. 

=cut

# -------------------------------------
# Library Modules

use Labyrinth::Variables;

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    'all' => [ qw(
        SetCookieExpDate SetCookiePath SetCookieDomain SetSecureCookie
        GetCookies SetCookie SetCookies GetCompressedCookies SetCompressedCookies
    ) ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

# -------------------------------------
# The Subs

=head1 FUNCTIONS

=over 4

=item SetCookieExpDate

Set the cookie expiration date.

=item SetCookiePath

Set the cookie path.

=item SetCookieDomain

Set the cookie domain.

=item SetSecureCookie

Set the cookie security.

=item GetCookies

Get all existing cookies.

=item SetCookie

Set a single cookie.

=item SetCookies

Set all given cookies.

=item GetCompressedCookies

Get all compressed cookies.

=item SetCompressedCookies

Set all given cookies as compressed cookies.

=back

=cut

sub SetCookieExpDate {
    $cookie_config{expires} = $_[0];
}

sub SetCookiePath {
    $cookie_config{path} = $_[0];
}

sub SetCookieDomain {

    if ($_[0] =~ /(.com|.edu|.net|.org|.gov|.mil|.int)$/i &&
        $_[0] =~ /\.[^.]+\.\w{3}$/) {
        $cookie_config{domain} = $_[0];
        return 1;
    } elsif ($_[0] !~ /(.com|.edu|.net|.org|.gov|.mil|.int)$/i &&
           $_[0] =~ /\.[^.]+\.[^.]+\./) {
        $cookie_config{domain} = $_[0];
        return 1;
    } else {
        return 0;
    }
}

sub SetSecureCookie {
    $cookie_config{secure} = $_[0];
}

sub GetCookies {
    my @cookies = @_;

    my $exists = 0;
    foreach my $name (@cookies)
    {
        my $value = $cgi->cookie($name);
        $main::Cookies{$name} = $value;
        $exists = 1 if $value;
    }
    return $exists;
}

sub SetCookie {
    my ($name,$value) = @_;
    my $c = $cgi->cookie (
                         -name    => $name,
                         -value   => $value,
                         -expires => (exists($cookie_config{expires}) ? $cookie_config{expires} : undef),
                         -domain  => (exists($cookie_config{domain})  ? $cookie_config{domain}  : undef),
                         -secure  => (exists($cookie_config{secure})  ? $cookie_config{secure}  : undef),
                         -path    => (exists($cookie_config{path})    ? $cookie_config{path}    : undef),
                        );
    return $c;
}

sub SetCookies {
    my (%input) = @_;
    while( my($name,$value) = each %input ) {
        my $c = SetCookie($name,$value);
        print "Set-Cookie: ", $c, "\n";
    }
}

sub GetCompressedCookies {
    my($cookie_name,@cookies) = @_;
    my $exists = 0;

    return unless( GetCookies(@_) );

    # extract specified cookies
    if( @cookies ) {
        foreach my $name (@cookies) {
            if($main::Cookies{$cookie_name} =~ /$name\:\:([^&]+)/) {
                my $value = $1;
                $main::Cookies{$name} = $value;
                $exists = 1 if $value;
            }
        }

    # extract all cookies
    } else {
        foreach my $cookie (split /&/, $main::Cookies{$cookie_name}) {
            my ($name,$value) = (split /::/, $cookie);
            $main::Cookies{$name} = $value;
            $exists = 1 if $value;
        }
    }

    return $exists;
}

sub SetCompressedCookies {
    my($cookie_name,@cookies) = @_;
    my $cookie_value = "";

    my %input = (@cookies);
    while( my($name,$value) = each %input ) {
        if ($cookie_value) {
            $cookie_value .= '&'.$name.'::'.$value;
        } else {
            $cookie_value = $name.'::'.$value;
        }
    }
    SetCookies($cookie_name,$cookie_value);
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
