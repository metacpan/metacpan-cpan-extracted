package HTML::Scrubber::StripScripts;
use strict;

use vars qw($VERSION);
$VERSION = '0.02';

=head1 NAME

HTML::Scrubber::StripScripts - strip scripting from HTML

=head1 SYNOPSIS

   use HTML::Scrubber::StripScripts;

   my $hss = HTML::Scrubber::StripScripts->new(
      Allow_src      => 1,
      Allow_href     => 1,
      Allow_a_mailto => 1,
      Whole_document => 1,
      Block_tags     => ['hr'],
   );

   my $clean_html = $hss->scrub($dirty_html);

=head1 DESCRIPTION

This module provides a preworked configuration for L<HTML::Scrubber>,
configuring it to leave as much non-scripting markup in place as
possible while being certain to eliminate all scripting constructs.
This allows web applications to display HTML originating from an
untrusted source without introducing XSS (cross site scripting)
vulnerabilities.

=head1 CONSTRUCTORS

=over

=item new ( CONFIG )

Returns a new C<HTML::Scrubber> object, configured with a filtering
policy based on a whitelist of XSS-free tags and attributes.  If
present, the CONFIG parameter must be a hashref.  The following keys
are recognized (unrecognized keys will be silently ignored).

=over

=item C<Allow_src>

By default, the scrubber won't be configured to allow constructs
that cause the browser to fetch things automatically, such as C<SRC>
attributes in C<IMG> tags.  If this option is present and true then
those constructs will be allowed.

=item C<Allow_href>

By default, the scrubber won't be configured to allow constructs
that cause the browser to fetch things if the user clicks on
something, such as the C<HREF> attribute in C<A> tags.  Set this
option to a true value to allow this type of construct.

=item C<Allow_a_mailto>

By default, the scrubber won't be configured to allow C<MAILTO:>
URLs in C<HREF> attributes in C<A> tags.  Set this option to a true
value to allow them.  Ignored unless C<Allow_href> is true.

=item C<Whole_document>

By default, the scrubber will be configured to deal with a snippet
of HTML to be placed inside another document after scrubbing, and
won't allow C<head> and C<body> tags and so on.

Set this option to a true value if an entire HTML document is being
scrubbed.

=item C<Block_tags>

If present, this must be an array ref holding a list of lower case
tag names.  These tags will be removed from the allowed list.

For example, a guestbook CGI that uses C<HR> tags to separate posts
might wish to disallow the C<HR> tag in posts, even though C<HR>
presents no XSS hazard.

=back

=cut

require 5.005; # for qr//
use HTML::Scrubber;

use vars qw(%re);
%re = (
  size      => qr#^[+-]?\d+(?:\./d+)?[%*]?$#,
  color     => qr#^(?:\w{2,20}|\#[\da-fA-F]{6})$#,
  word      => qw#^\w*$#,
  wordlist  => qr#(?:[\w\-\, ]{1,200})$#,
  text      => qr#^[^\0]*$#,
  url       => qr# (?:^ (?:https?|ftp) :// ) | (?:^ [\w\.,/-]+ $) #ix,
  a_mailto  => qr# (?:^ (?:https?|ftp) :// ) | (?:^ [\w\.,/-]+ $) | (?:^ mailto: [\w\-\.\+\=\*]+\@[\w\-\.]+ $) #ix,
);

sub new {
    my ($pkg, %cfg) = @_;

    my (@cite, @href, @src, @background);
    @cite       = ( cite       => $re{'url'} ) if $cfg{Allow_href};
    @href       = ( href       => $re{'url'} ) if $cfg{Allow_href};
    @src        = ( src        => $re{'url'} ) if $cfg{Allow_src};
    @background = ( background => $re{'url'} ) if $cfg{Allow_src};

    my %empty = ();

    my %font_attr = (
      'size'  => $re{'size'},
      'face'  => $re{'wordlist'},
      'color' => $re{'color'},
    );

    my %insdel_attr = (
      @cite,
      'datetime' => $re{'text'},
    );

    my %texta_attr = (
      'align' => $re{'word'},
    );

    my %cellha_attr = (
      'align'    => $re{'word'},
      'char'     => $re{'word'},
      'charoff'  => $re{'size'},
    );

    my %cellva_attr = (
      'valign' => $re{'word'},
    );

    my %cellhv_attr = ( %cellha_attr, %cellva_attr );

    my %col_attr = (
      %cellhv_attr,
      'width' => $re{'size'},
      'span'  => $re{'number'},
    );

    my %thtd_attr = (
      'abbr'             => $re{'text'},
      'axis'             => $re{'text'},
      'headers'          => $re{'text'},
      'scope'            => $re{'word'},
      'rowspan'          => $re{'size'},
      'colspan'          => $re{'size'},
      %cellhv_attr,
      'nowrap'           => $re{'word'},
      'bgcolor'          => $re{'color'},
      'width'            => $re{'size'},
      'height'           => $re{'size'},
      'bordercolor'      => $re{'color'},
      'bordercolorlight' => $re{'color'},
      'bordercolordark'  => $re{'color'},
    );

    my %rules = (
      'br'         => { 'clear' => $re{'word'} },
      'em'         => \%empty,
      'strong'     => \%empty,
      'dfn'        => \%empty,
      'code'       => \%empty,
      'samp'       => \%empty,
      'kbd'        => \%empty,
      'var'        => \%empty,
      'cite'       => \%empty,
      'abbr'       => \%empty,
      'acronym'    => \%empty,
      'q'          => { @cite },
      'blockquote' => { @cite },
      'sub'        => \%empty,
      'sup'        => \%empty,
      'tt'         => \%empty,
      'i'          => \%empty,
      'b'          => \%empty,
      'big'        => \%empty,
      'small'      => \%empty,
      'u'          => \%empty,
      's'          => \%empty,
      'strike'     => \%empty,
      'font'       => \%font_attr,
      'table'      => { 'frame'            => $re{'word'},
                        'rules'            => $re{'word'},
                        %texta_attr,
                        'bgcolor'          => $re{'color'},
                        @background,
                        'width'            => $re{'size'},
                        'height'           => $re{'size'},
                        'cellspacing'      => $re{'size'},
                        'cellpadding'      => $re{'size'},
                        'border'           => $re{'size'},
                        'bordercolor'      => $re{'color'},
                        'bordercolorlight' => $re{'color'},
                        'bordercolordark'  => $re{'color'},
                        'summary'          => $re{'text'},
                      },
      'caption'    => { 'align' => $re{'word'} },
      'colgroup'   => \%col_attr,
      'col'        => \%col_attr,
      'thead'      => \%cellhv_attr,
      'tfoot'      => \%cellhv_attr,
      'tbody'      => \%cellhv_attr,
      'tr'         => { bgcolor => $re{'color'},
                        %cellhv_attr,
                      },
      'th'         => \%thtd_attr,
      'td'         => \%thtd_attr,
      'ins'        => \%insdel_attr,
      'del'        => \%insdel_attr,
      'a'          => { @href },
      'h1'         => \%texta_attr,
      'h2'         => \%texta_attr,
      'h3'         => \%texta_attr,
      'h4'         => \%texta_attr,
      'h5'         => \%texta_attr,
      'h6'         => \%texta_attr,
      'p'          => \%texta_attr,
      'div'        => \%texta_attr,
      'span'       => \%texta_attr,
      'ul'         => { 'type'    => $re{'word'},
                        'compact' => $re{'word'},
                      },
      'ol'         => { 'type'    => $re{'text'},
                        'compact' => $re{'word'},
                        'start'   => $re{'size'},
                      },
      'li'         => { 'type'  => $re{'text'},
                        'value' => $re{'size'},
                      },
      'dl'         => { 'compact' => $re{'word'} },
      'dt'         => \%empty,
      'dd'         => \%empty,
      'address'    => \%empty,
      'hr'         => { %texta_attr,
                        'width'   => $re{'size'},
                        'size '   => $re{'size'},
                        'noshade' => $re{'word'},
                      },
      'pre'        => { 'width' => $re{'size'} },
      'center'     => \%empty,
      'nobr'       => \%empty,
      'img'        => { @src,
                        'alt'    => $re{'text'},
                        'width'  => $re{'size'},
                        'height' => $re{'size'},
                        'border' => $re{'size'},
                        'hspace' => $re{'size'},
                        'vspace' => $re{'size'},
                        'align'  => $re{'word'},
                      },
      ( $cfg{Whole_document} ? 
        ( 'body'  => { 'bgcolor'    => $re{'color'},
                        @background,
                        'link'       => $re{'color'},
                        'vlink'      => $re{'color'},
                        'alink'      => $re{'color'},
                        'text'       => $re{'color'},
                     },
          'head'  => {},
          'title' => {},
          'html'  => {},
        ) : ()
      ),
    );

    if ( $cfg{Allow_href} and $cfg{Allow_a_mailto} ) {
        $rules{'a'}{'href'} = $re{'a_mailto'};
    }

    if ( $cfg{Block_tags} ) {
        foreach my $block (@{ $cfg{Block_tags} }) {
            delete $rules{$block};
        }
    }

    return HTML::Scrubber->new(
        rules   => [%rules],
        comment => 0,
        process => 0,
    );
}

=head1 BUGS

=over

=item

All scripting is safely removed, but no attempt is made to ensure that
there is a matching end tag for each start tag.  That could be a problem
if the scrubbed HTML is to be inserted into a larger HTML document, since
C<FONT> tags and so on could be maliciously left open.

If that's a big problem for you, consider using the more heavyweight
(and probably much slower) L<HTML::StripScripts> module instead.

=back

=head1 SEE ALSO

L<HTML::Scrubber>, L<HTML::StripScripts>

=head1 AUTHOR

Nick Cleaton E<lt>nick@cleaton.netE<gt>

=head1 COPYRIGHT

Copyright (C) 2003 Nick Cleaton.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

