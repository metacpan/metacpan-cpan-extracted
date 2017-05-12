package HTML::EscapeEvil::AllowAll;

=pod

=head1 NAME

HTML::EscapeEvil::AllowAll - Escape tag.but all tag allow

=head1 VERSION

0.05

=head1 SYNPSIS

    use HTML::EscapeEvil::AllowAll;
    my $escapeallow = HTML::EscapeEvil::AllowAll->new;
    print "script is " , ($escapeallow->allow_script) ? "allow" : "not allow";
    print "style is " , ($escapeallow->allow_style) ? "allow" : "not allow";
    $escapeallow->clear;

=head1 DESCRIPTION

Only tag where it wants to escape is specified with deny_tags method etc. 

and it uses it because it all enters the state of permission. 

=cut

use strict;
use base qw(HTML::EscapeEvil);

our $VERSION = 0.05;

=pod

=head1 METHOD

=head2 new

Create HTML::EscapeEvil::AllowAll instance.

=cut

sub new {

    my $class = shift;
    my $self  = $class->SUPER::new;
    bless $self, ref $class || $class;
    $self->{_tag_map} = [];
    $self->_init;
    $self->allow_all;
    $self;
}

=pod

=head2 allow_all

All tags allow.

Example : 

  $escapeallow->allow_all;

=cut

sub allow_all {

    my $self = shift;
    $self->allow_comment(1);
    $self->allow_declaration(1);
    $self->allow_process(1);
    $self->allow_entity_reference(1);
    $self->collection_process(1);

    $self->add_allow_tags( $self->_to_flat_array );
}

=pod

=head2 _to_flat_array

Private method.

=cut

sub _to_flat_array {

    map { @{$_} } @{shift->{_tag_map}};
}

=pod

=head2 _init

Private method.

=cut

sub _init {

    my $self = shift;
    $self->{_tag_map} = [
                         [ "a", "abbr", "acronym", "address", "area" ],
                         [ "b", "base", "basefont", "bdo", "big", "blockquote", "body", "br", "button" ],
                         [ "caption", "cite", "code", "col", "colgroup" ],
                         [ "dd", "del", "dfn", "div", "dl", "dt" ],
                         [ "em", "embed" ],
                         [ "fieldset", "frameset", "font", "form" ],
                         [ "h1", "h2", "h3", "h4", "h5", "h6", "head", "hr", "html" ],
                         [ "i", "iframe", "img", "input", "ins" ],
                         [ "kbd" ],
                         [ "label", "legend", "li", "link" ],
                         [ "map", "meta" ],
                         [ "nobr", "noscript" ],
                         [ "object", "ol", "optgroup", "option" ],
                         [ "p", "param", "pre" ],
                         [ "q" ],
                         [ "rb", "rbc", "rp", "rt", "rtc", "ruby" ],
                         [ "s", "samp", "script", "select", "small", "span", "strong", "strike", "style", "sub", "sup" ],
                         [ "table", "tbody", "td", "textarea", "tfoot", "th", "thead", "title", "tr", "tt" ],
                         [ "u", "ul" ],
                         [ "var" ]
                        ];
}

1;

__END__

=pod

=head1 SEE ALSO

L<HTML::EscapeEvil>

=head1 AUTHOR

Akira Horimoto <kurt0027@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 Akira Horimoto

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

