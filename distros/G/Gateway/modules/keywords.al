# keywords.al -- Check for required subject line keywords.  -*- perl -*-
# $Id: keywords.al,v 0.4 1997/10/24 18:02:44 eagle Exp $
#
# Copyright 1997 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

# @@ Interface:  ['keywords']

package News::Gateway;

############################################################################
# Option settings
############################################################################

# We take a single optional argument which, if present, is a reference to an
# anonymous sub that, when given a subject line, returns a list of all of
# the keywords present.  This allows the user of this module to write
# arbitrary code to define what a keyword is.
sub keywords_init {
    my $self = shift;
    $$self{keywords}{code} = shift;
}


############################################################################
# Configuration directives
############################################################################

# Our single directive takes a file of acceptable keywords.
sub keywords_conf {
    my ($self, $directive, $keywords) = @_;
    open (KEYWORDS, $keywords)
        or $self->error ("Can't open keywords file $keywords: $!");
    local $_;
    while (<KEYWORDS>) {
        chomp;
        $$self{keywords}{valid}{lc $_} = 1;
    }
    close KEYWORDS;
}


############################################################################
# Post checks
############################################################################

# The default routine to extract keywords from a subject line.  We support
# the forms:
#
#     KEYWORD:
#     KEYWORD/KEYWORD:
#     [KEYWORD]
#     [KEYWORD/KEYWORD]
#     [KEYWORD][KEYWORD]
#
# by default.
sub keywords_parse {
    my $subject = shift;
    ($subject) = ($subject =~ /^(?:Re: )*(\S+)/);
    my @keywords;
    my ($keywords) = ($subject =~ /^\[(\S+)\]$/);
    if ($keywords) {
        @keywords = split (/\/|\]\[/, $keywords);
    } else {
        ($keywords) = ($subject =~ /^(\S+):$/);
        return () unless $keywords;
        @keywords = split ('/', $keywords);
    }
    @keywords;
}

# Check the subject line of the article to make sure it contains one of the
# acceptable keywords.
sub keywords_mesg {
    my ($self) = @_;
    my $subject = $$self{article}->header ('subject');
    my @keywords;
    if ($$self{keywords}{code}) {
        @keywords = &{$$self{keywords}{code}} ($subject);
    } else {
        @keywords = keywords_parse ($subject);
    }
    unless (@keywords) { return "No keywords found" }
    for (@keywords) {
        unless ($$self{keywords}{valid}{lc $_}) {
            return "Invalid keyword '$_'";
        }
    }
    undef;
}

1;
