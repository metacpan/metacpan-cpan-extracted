package Kwiki::Footnote;

use strict;
our $VERSION = '0.01';
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-Base';

const class_id    => 'footnote';
const class_title => 'Footnote Wafl';
const css_file    => 'footnote.css';

field footnotes => [];

sub register {
    my $registry = shift;
    $registry->add(wafl => footnote => "Kwiki::Footnote::Footnote");
    $registry->add(wafl => footnotelist => "Kwiki::Footnote::FootnoteList");
}

package Kwiki::Footnote::Footnote;
use base 'Spoon::Formatter::WaflPhrase';

sub html {
    my $text = $self->arguments;
    my $footnotes = $self->hub->footnote->footnotes;
    push @$footnotes, $text;
    my $num = @$footnotes;
    return <<EOF;
<sup id="fb$num"><a href="#fn$num" title="@{[$self->html_escape($text)]}">$num</a></sup>
EOF
}

package Kwiki::Footnote::FootnoteList;
use base 'Spoon::Formatter::WaflPhrase';

sub html {
    my @footnotes = @{$self->hub->footnote->footnotes};
    my $html = qq(<ul class="footnotelist">\n);
    for my $idx (0..$#footnotes) {
	my $text = $footnotes[$idx];
	my $num  = $idx + 1;
	$html .= <<EOF
<li class="footnote"><cite id="fn$num"><a href="#fb$num">*$num</a></cite>: @{[$self->hub->formatter->text_to_html($text)]}</li>
EOF
    ;
    }
    $html .= "</ul>\n";
    return $html;
}

package Kwiki::Footnote;
1;
__DATA__

=head1 NAME

Kwiki::Footnote - Footnote plugin for Kwiki

=head1 SYNOPSIS

  This Wiki is powered by Kwiki {footnote: Kwiki is Spoon and Spiffy}

  ....

  {footnotelist}

=head1 DESCRIPTION

Kwiki::Footnote allows you to add footnotes with inline Wafl.

=head1 WANT-TODO

=over 4

=item *

Writing {footnotelist} by hand seems like a pain. Are there any way to automatically insert footnote listing after the page body using some hook?

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Kwiki::AnchorLink>

=cut

__css/footnote.css__
ul.footnotelist {
  margin-left: 0;
}
li.footnote {
  margin-left: 0;
}
