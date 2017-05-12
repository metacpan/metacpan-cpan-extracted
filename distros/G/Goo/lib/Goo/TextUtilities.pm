#!/usr/bin/perl

package Goo::TextUtilities;

###############################################################################
# trexy.com - miscellaneous utilities for handling text
#
# Copyright Nigel Hamilton 2002
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::TextUtilities.pm
# Description:  Miscellaneous utilities for handling text
#
# Date          Change
# -----------------------------------------------------------------------------
# 07/05/2001    Version 1
# 17/03/2003    Expanded to handle HTML, Javascript etc.
# 15/05/2003    &#39; this character was not being stripped from
#               the HTML sent to the browser needed to strip it out
# 03/08/2005    Added getMatchingLineNumber
#
###############################################################################

use strict;

use URI;
use Goo::Logger;

###############################################################################
#
# get_hostname - return a hostname from the url
#
###############################################################################

sub get_hostname {

    my ($url) = @_;

    my $hostname;

    # prepend http:// to the URL if it is missing - but why would it be missing?
    # watch out for perltidy!
    unless ($url =~ /^http:\/\//i) { $url = "http://" . $url; }

    eval {

        # catch unwanted exception thrown
        # this function will die if the protocol is not included (http://)
        # if the protocol is partially included it won't die but will return null
        # this was failing during a redirect from dogpile - the redirect worked on
        # FireFox - but failed on IE???!!! - we suspected an encoding problem
        my $uri = URI->new($url);
        $hostname = $uri->host();
    };

    if ($@) {
        Goo::Logger::write("Write tried to resolve this URL: $url ." . $@, "/tmp/uri.bug.log");
        die("URI bug: $url " . $@);
    }

    return $hostname;
}

###############################################################################
#
# strip_hreftags - strip all href tags
#
###############################################################################

sub strip_hreftags {

    my ($string) = @_;

    $string =~ s!<a\s+		
			( "[^"]*" |		
		          '[^']*' |
			  [^'">]
			)*
			>.*?</a>!!gsix;

    return $string;

}

###############################################################################
#
# uppercase_first_letters - turn the first letters of each word into uppercase
#
###############################################################################

sub uppercase_first_letters {

    my ($string) = @_;

    # substitute at word boundaries
    # store the word in $1
    # set the whole thing to lowercase and the first letter to uppercase
    $string =~ s/\b([\w\']+)/\L\u$1/g;

    return $string;
}

###############################################################################
#
# escape_url - escape a url string
#
###############################################################################

sub escape_url {

    my ($string) = @_;

    # substitute any spaces for
    $string =~ s/ /\+/g;

    return $string;
}

###############################################################################
#
# strip_funky_html - strip any html that is too funky for a normal tag strip
#
###############################################################################

sub strip_funky_html {

    my ($string) = @_;

    $string =~ s!<script[^>]*>.*?</script>! !sig;    # strip Javascript
    $string =~ s!<style[^>]*>.*?</style>! !sig;      # strip stylesheets
    $string =~ s|<!--.*?-->| |sig;                   # strip HTML comments

    $string = strip_html($string);                   # strip all other tags

    # strip any html entities like &nbsp; - this could be better
    $string =~ s/&[a-zA-Z]{1,4};/ /sig;

    # strip any numeric entities
    $string =~ s/&[0-9]{1,4};/ /g;

    # strip any numeric entities
    $string =~ s/&\#[0-9]{1,4};/ /g;

    # strip any parentheses ()
    $string =~ s/\(\W*\)/ /g;

    # strip any literal carriage returns
    $string =~ s/\\[rn]/ /g;

    $string = compress_whitespace($string);

    return $string;
}

###############################################################################
#
# strip_html - strip the html from a string
#
###############################################################################

sub strip_html {

    my ($string) = @_;

    # strip HTML entities
    $string =~ s/\&lt\;/</ig;
    $string =~ s/\&gt\;/>/ig;

    # strip tags
    $string =~ s/<[^>]*>//g;

    return $string;
}

###############################################################################
#
# trim_whitespace - strip whitespace from the front and back of a string
#
###############################################################################

sub trim_whitespace {

    my ($string) = @_;

    $string =~ s/^\s+//g;    # strip leading whitespace
    $string =~ s/\s+$//g;    # string trailing whitespace

    return $string;
}

###############################################################################
#
# compress_whitespace - compress excess whitespace from many to 1 space
#
###############################################################################

sub compress_whitespace {

    my ($string) = @_;

    $string =~ s/\s+/ /g;    # compress whitespace

    return $string;
}

###############################################################################
#
# right_pad - pad a string on the righthand side up to a maximum
#
###############################################################################

sub right_pad {

    my ($string, $padding, $maxsize) = @_;

    # truncate the string if longer than maxsize
    $string = substr($string, 0, $maxsize);

    # add some padding on the right
    return $string . $padding x ($maxsize - length($string));

}

###############################################################################
#
# strip_last_word - strip the last word off the end of a string
#
###############################################################################

sub strip_last_word {

    my ($string) = @_;

    # go to the end of the string and snip off the first bit of
    # non-whitespace
    $string =~ s/\S+$//;

    return $string;

}

###############################################################################
#
# left_pad - pad a string on the lefthand side up to a maximum
#
###############################################################################

sub left_pad {

    my ($string, $padding, $maxsize) = @_;

    # truncate the string if longer than maxsize
    $string = substr($string, 0, $maxsize);

    # add some padding on the left
    return ($maxsize - length($string)) x $padding . $string;

}

###############################################################################
#
# truncate_string - reduce the size of the string and remove the last word
#
###############################################################################

sub truncate_string {

    my ($string, $size, $dots) = @_;

    # print $string;
    if (length($string) > $size) {

        #print "--------> in here <----- $size";
        $string = substr($string, 0, $size);

        # print $string;
        #print $string;
        # lop off the last word - removes partial words
        $string = strip_last_word($string);

        # add dots if we want them
        if ($dots) { $string .= $dots; }
    }

    return $string;

}

###############################################################################
#
# escape_javascript - escape double quotes etc.
#
###############################################################################

sub escape_javascript {

    my ($string) = @_;

    # escape any double quotes, so the Javascript parses OK
    $string =~ s/"/\\"/g;

    # strip line feeds
    $string =~ s/[\n\r]+//g;

    # strip excess whitespace around = signs
    $string =~ s/\s+=\s+/=/g;

    # strip excess whitespace
    $string =~ s/\s+/ /g;

    return $string;

}

###############################################################################
#
# get_matching_line_number - return the linenumber that matches the regex
#
###############################################################################

sub get_matching_line_number {

    my ($regex, $string) = @_;

    my @lines = split(/\n/, $string);

    my $linecount = 0;

    foreach my $line (@lines) {

        $linecount++;

        if ($line =~ /$regex/) {

            # add 5 to get into the body of the method
            return $linecount;
        }

    }

    return $linecount;
}

1;


__END__

=head1 NAME

Goo::TextUtilities - Miscellaneous utilities for handling text

=head1 SYNOPSIS

use Goo::TextUtilities;

=head1 DESCRIPTION



=head1 METHODS

=over

=item get_hostname

return a hostname from the url

=item strip_hreftags

strip all href tags in a string

=item uppercase_first_letters

turn the first letters of each word into uppercase

=item escape_url

escape a url string

=item strip_funky_html

strip any HTML that is too funky for a normal tag strip

=item strip_html

strip the HTML from a string

=item trim_whitespace

strip whitespace from the front and back of a string

=item compress_whitespace

compress excess whitespace from many spaces to one space

=item right_pad

pad a string on the righthand side up to a maximum number of characters

=item strip_last_word

strip the last word off the end of a string

=item left_pad

pad a string on the lefthand side up to a maximum

=item truncate_string

reduce the size of the string and remove the last word

=item escape_javascript

escape double quotes etc.

=item get_matching_line_number

return the linenumber that matches the regex

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

