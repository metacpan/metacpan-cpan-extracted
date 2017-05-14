#!/usr/local/bin/perl
;# HTMLQuickCheck.pm: a simple/fast html syntax checking package for perl 4
;# and 5.

;# $Id: HTMLQuickCheck.pm,v 1.2 1995/10/01 09:01:33 ylu Exp ylu $
;#
;# Copyright 1995, Luke Y.  Lu <ylu@mail.utexas.edu>
;# may be copied under the terms of either the Perl Artistic License or the
;# GNU General Public License.  Comments/suggestions/bugfixes/improvements
;# welcome.

package HTML'QuickCheck;   # perl 4 compatibility

$Version = '1.0b1';

;# 5/12/95 ylu added netscape extensions: <font> <center> and <blink> --
;# they can lead to major havoc -- affect the rest of the file if not
;# closed, so checking is is necessary to localize any possible damage.

;# start-html-def
;# elements that _require_ closing tags.
%Pair = (
               'A',         1,
         'ADDRESS',         1,
               'B',         1,
           'BLINK',         1,  # mozilla 
      'BLOCKQUOTE',         1,
              'BQ',         1,
          'CENTER',         1,  # mozilla 
            'CITE',         1,
            'CODE',         1,
             'DFN',         1,
             'DIR',         1,
              'DL',         1,
              'EM',         1,
             'FIG',         1,
            'FONT',         1,  # mozilla 
            'FORM',         1,
              'H1',         1,
              'H2',         1,
              'H3',         1,
              'H4',         1,
              'H5',         1,
              'H6',         1,
            'HEAD',         1,
            'HTML',         1,
               'I',         1,
             'KBD',         1,
         'LISTING',         1,
            'MATH',         1,
            'MENU',         1,
              'OL',         1,
             'PRE',         1,
               'S',         1,
            'SAMP',         1,
          'SELECT',         1,
          'STRONG',         1,
           'STYLE',         1,
           'TABLE',         1,
        'TEXTAREA',         1,
           'TITLE',         1,
              'TT',         1,
               'U',         1,
              'UL',         1,
             'VAR',         1,
             'XMP',         1,
);

# Nestable elements
%Nestable = (
      'BLOCKQUOTE',         1,
              'DL',         1,
            'MENU',         1,
              'OL',         1,
           'TABLE',         1,
              'UL',         1,
);

# end-html-def

;# HTML'QuickCheck'OK($html_text);
;# a quick check for html essentials.  return 1 for success, 0 for error,
;# set $HTML'QuickCheck'Error. 

*HTML'QuickCheck'Error = *Error;    # perl 4 package unnestable workaround.
 
sub HTML'QuickCheck'OK
{
    local($_) = @_;
    local($tag, $isendtag, @tags, %tags, $tag1);
    local($*) = 0;
    
    $Error = "";

    unless (&anglematch($_)) {
        $Error = "mismatched < and >\n";
        return 0;
    }

    for $tag (/<\s*([^\s>]+)[^>]*>/g) {
        $tag =~ y/a-z/A-Z/;
        $isendtag = $tag =~ s!^/!!;

        next unless $Pair{$tag};
        if ($isendtag) {
            if ($tag1 = pop @tags) {
                $tag1 eq $tag || 
                    ($Error .=  "<$tag1> does not match </$tag>\n");
            }
            else {
                $Error .=  "</$tag> appears without matching <$tag>\n";
            }
            $tags{$tag1} -= 1;
        }
        else {
            push(@tags, $tag);
            $tags{$tag} += 1;
            $tags{$tag} <=1 || $Nestable{$tag} ||
                ($Error .=  "<$tag> cannot be nested\n");
        }
    }

    for $tag (@tags) {
        $Error .= "missing required </$tag> for <$tag>\n";
    }

    return $Error ? 0 : 1;
}

# anglematch
# return 1 if < and > matches

sub anglematch
{
    ;# in perl5 we can use s/<!--.*?-->//g to remove html comments.  Kinda
    ;# hairy and slow to do in perl4, don't bother.  So it will reject html
    ;# text with markups within comments -- hey, who types html with
    ;# comments anyway :).  some browsers also seem to be confused with
    ;# markups inside a comment.
    
    #eval 's/<!--.*?-->//g' if $] =~ /^5/; # uncomment to slow down if you want
    return 0 if /<[^>]*</;
    return 0 if />[^<]*>/;
    return 0 if /<[^>]*$/;
    return 0 if /^[^<]*>/;
    1;
}

1;

__END__

=head1 NAME

HTMLQuickCheck.pm -- a simple and fast HTML syntax checking package for
perl 4 and perl 5

=head1 SYNOPSIS
    
    require 'HTMLQuickCheck.pm';

    &HTML'QuickCheck'OK($html_text) || die "Bad HTML: $HTML'QuickCheck'Error";

    or for perl 5:
    HTML::QuickCheck::OK($html_text) || 
            die "Bad HTML: $HTML::QuickCheck::Error";

=head1 DESCRIPTION

The objective of the package is to provide a fast and essential HTML check
(esp. for CGI scripts where response time is important) to prevent a piece
of user input HTML code from messing up the rest of a file, i.e., to
minimize and localize any possible damage created by including a piece of
user input HTML text in a dynamic document.

HTMLQuickCheck checks for unmatched < and >, unmatched tags and improper
nesting, which could ruin the rest of the document.  Attributes and
elements with optional end tags are not checked, as they should not cause
disasters with any decent browsers (they should ignore any unrecognized
tags and attributes according to the standard).  A piece of HTML that
passes HTMLQuickCheck may not necessarily be valid HTML, but it would be
very unlikely to screw others but itself. A valid piece of HTML that
doesn't pass the HTMLQuickCheck is however very likely to screw many
browsers(which are obviously broken in terms of strict conformance).

HTMLQuickCheck currently supports HTML 1.0, 2.x (draft), 3.0 (draft) and
netscape extensions (1.1).

=head1 EXAMPLE

    htmlchk, a simple html checker:

    #!/usr/local/bin/perl
    require 'HTMLQuickCheck.pm';
    undef $/;
    print &HTML'QuickCheck'OK(<>) ? "HTML OK\n" : 
            "Bad HTML:\n", $HTML'QuickCheck'Error;
    __END__

    Usage: 
    htmlchk [html_file]

=head1 AUTHOR

Luke Y. Lu <ylu@mail.utexas.edu>

=head1 SEE ALSO

HTML docs at <URL:http://www.w3.org/hypertext/WWW/MarkUp/MarkUp.html>;
HTML validation service at <URL:http://www.halsoft.com/html/>;
perlSGML package at <URL:http://www.oac.uci.edu/indiv/ehood/perlSGML.html>;
weblint at <URL:http://www.khoros.unm.edu/staff/neilb/weblint.html>

=head1 BUGS

Please report them to the author.

=cut



