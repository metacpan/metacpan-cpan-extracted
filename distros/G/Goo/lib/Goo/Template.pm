#!/usr/bin/perl

package Goo::Template;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2002
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Template.pm
# Description:  Replace tokens in a file or a string
#
# Date          Change
# -----------------------------------------------------------------------------
# 04/03/1999    Version 1 - Based on Michael Snell's brilliant replace.pm 
#				"This is the future"
# 10/05/2000    Version 2 - a more efficient slurping mode
# 01/02/2002    Caching version - is memory consumption OK?
# 24/07/2002    More OO version
# 24/07/2004    Added a new dynamic include token
#               {{>HelloWorld::hello()}} it efficiently replaces the token with
#               the output of the code specified
# 05/08/2004    Needed a way of evaluating new dynamic tokens - recursion?
# 02/02/2005    Added a direct WebDBLite way of replacing in templates
#               Decided not to --- this module must stay lite.
# 10/02/2005    Added slurping FileUtilities functions for file access
#
###############################################################################

use strict;
use Goo::Object;
use Goo::FileUtilities;

our @ISA   = ("Goo::Object");    # used to print out the contents of the cache
our $cache = {};                 # a persistent hash of templates keyed on filenames


###############################################################################
#
# replace_tokens_in_string - replace tokens in a string
#
###############################################################################

sub replace_tokens_in_string {

    my ($string, $tokens) = @_;

    # replace tokens in the string
    $string =~ s! {{([^}]*)}} !		# match {{ followed by any
     						# non } characters followed by
     						# two }} characters
			get_token($1, $tokens)

                  !gsex;    # g - global, keep matching
                            # e - eval the code to substitute
                            # s - . matches newlines, needed?
                            # x - ignore whitespace allow comments


    return $string;

}


###############################################################################
#
# get_token - look up the hash for the token and return the value
#
###############################################################################

sub get_token {

    my ($tokenstring, $tokenhash) = @_;

    if (exists $tokenhash->{$tokenstring}) {
        return $tokenhash->{$tokenstring};
    }

    # is it a special code include token?
    # e.g., {{>Test::HelloWorld()}}
    if ($tokenstring =~ /^\>(.*?)::(.*?)$/) {

        # insert an object dynamically generated from code
        return eval <<CODE;
        	use lib '/home/search/shared/bin';
        	use lib '/home/search/trexy/bin';
        	use lib '/home/search/trexy/bin';
         	use $1; 
         	$1::$2;
CODE


        #return "wanker";
    }

    # maybe the token has already been set with curly brackets {{ }}
    # this is so the template module is backwards compatible
    $tokenstring = '{{' . $tokenstring . '}}';

    return $tokenhash->{$tokenstring};

}


###############################################################################
#
# replace_tokens_in_file - replace tokens in a file and use a cache too
#
###############################################################################

sub replace_tokens_in_file {

    my ($template_file, $tokens) = @_;

    # is the file in the cache? if so, don't go to disk, use the cached version
    # instead
    if (exists($cache->{$template_file})) {

        return replace_tokens_in_string($cache->{$template_file}, $tokens);

    }

    # this file is not in the cache - grab it from disk and put into cache
    $cache->{$template_file} = Goo::FileUtilities::get_file_as_string($template_file);

    return replace_tokens_in_string($cache->{$template_file}, $tokens);

}


1;


__END__

=head1 NAME

Goo::Template - Replace special tokens in a file or a string

=head1 SYNOPSIS

use Goo::Template;

=head1 DESCRIPTION

=head1 METHODS

=over

=item replace_tokens_in_string

replace tokens in a string

=item get_token

look up the hash for the token and return the value

=item replace_tokens_in_file

replace tokens in a file

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

