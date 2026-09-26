#
#  This file is part of Docbook::Convert.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


#
#
package Docbook::Convert::Markdown;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Docbook::Convert::Constant;
use Data::Dumper;
use HTML::Entities qw(encode_entities);    # for HTMLescape


#  Inherit Base functions (find_node etc.)
#
use base Docbook::Convert::Base;
use base Docbook::Convert::Common;
use base Docbook::Convert::Markdown::Util;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.012';


#  Make synonyms
#
&Docbook::Convert::Base::create_tag_synonym($MD_TAG_SYNONYM_HR);


#===================================================================================================


sub text {
    my ($self, $data_ar)=@_;
    my $text=$self->pull_node_text($data_ar, $NULL);
    unless ($self->_dont_escape($data_ar)) {
        $text=$self->_escape($text);
    }
    return $text;
}


sub warning {    # synonym for caution, important, note, tip
    my ($self, $data_ar)=@_;
    my $tag=$data_ar->[$NODE_IX];
    my $text=$self->pull_node_text($data_ar, $NULL);
    $tag=lc($tag);
    my $admonition=$self->_bold($ADMONITION_TEXT_HR->{$tag});

    #return $CR2 . $admonition. $CR2 . $text;
    return $CR2 . $self->_quote($admonition . $CR2 . $text);
}


sub _plaintext {

    my ($self, $tag)=@_;
    return $MD_PLAINTEXT_HR->{$tag}

}


sub _dont_escape {

    my ($self, $data_ar)=@_;
    if ($self->find_parent($data_ar, $MD_DONT_ESCAPE_AR)) {
        return 1;
    }
    elsif ($self->{'_plaintext'}) {
        return 1;
    }
    else {
        return undef;
    }

}


sub _escape {

    my ($self, $text)=@_;

    #  Escape markdown characters
    $text=~s/\s+([*_`\\{}\[\]\(\)#+-\.\!]+)/ \\$1/g;

    #  And HTML
    #$text=CGI::escapeHTML($text);
    $text=encode_entities($text);
    return $text;

}

1;
__END__

=begin markdown

# NAME

Docbook::Convert::Markdown - custom Markdown renderer for Docbook::Convert

# DESCRIPTION

This internal renderer maps the parsed DocBook tree to Markdown for the
original `Docbook::Convert` implementation. It is selected by
`Docbook::Convert->markdown()` and `markdown_file()`.

For guides requiring includes, stable section identifiers, code attributes or
MkDocs admonitions, use `Docbook::Convert::Pandoc`.

# SEE ALSO

`Docbook::Convert`, `Docbook::Convert::Pandoc`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Docbook::Convert.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Docbook::Convert::Markdown - custom Markdown renderer for Docbook::Convert


=head1 DESCRIPTION

This internal renderer maps the parsed DocBook tree to Markdown for the
original C<Docbook::Convert> implementation. It is selected by
C<<< Docbook::Convert->markdown() >>> and C<markdown_file()>.

For guides requiring includes, stable section identifiers, code attributes or
MkDocs admonitions, use C<Docbook::Convert::Pandoc>.


=head1 SEE ALSO

C<Docbook::Convert>, C<Docbook::Convert::Pandoc>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

=cut
