package Markapl::Tags;

use strict;
use warnings;

our $VERSION = "0.01";

sub w3c_html4 {
    qw(
       a abbr acronym address applet area b base basefont bdo big
       blockquote body br button caption center cite code col colgroup
       dd del dfn dir div dl dt em fieldset font form frame frameset
       h1 h2 h3 h4 h5 h6 head hr html i iframe img input ins isindex
       kbd label legend li link map menu meta noframes noscript object
       ol optgroup option p param pre q s samp script select small
       span strike strong style sub sup table tbody td textarea tfoot
       th thead title tr tt u ul var
    );
}

sub html4_perl_common {
    qw(link map q s sub tr);
}

sub html {
    # removed common ones. add replacements
    qw(
       a abbr acronym address applet area b base basefont bdo big
       blockquote body br button caption center cite code col colgroup
       dd del dfn dir div dl dt em fieldset font form frame frameset
       h1 h2 h3 h4 h5 h6 head hr html i iframe img input ins isindex
       kbd label legend li menu meta noframes noscript object
       ol optgroup option p param pre samp script select small
       span strike strong style sup table tbody td textarea tfoot
       th thead title tt u ul var

       base html_link html_map html_q html_s html_sub html_tr
       cell row
    );
}

sub html_inline {
    qw( base link meta isindex img br hr wbr
        input area param embed bgsound spacer
        basefont col frame );
}

1;

=head1 NAME

Markapl::Tags - List of tags.

=head1 DESCRIPTION

This module is used internally to get a list of HTML tags.  However,
Markapl users may call C<Markapl::Tags->html> to retrieve the list of
supported html tags. (Or even modify it)

Invoke C<perldoc -m Markapl::Tags> too see the full list of tag names.

=head1 FUNCTIONS

=over 4

=item html

Return the list of supported html tags. The following tags are in the
returned list but they are not standard html tags:

  html_link html_map html_q html_s html_sub html_tr cell row

Because their corresponding html tag names conflicts with perl builtin
functions.

=item w3c_html4

Return the list of standard html tag names. This is just here for
references.

=back

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
