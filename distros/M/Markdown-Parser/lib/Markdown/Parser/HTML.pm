##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/HTML.pm
## Version v0.2.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/08/23
## Modified 2022/09/22
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Markdown::Parser::HTML;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use vars qw( $VERSION );
    use Devel::Confess;
    our $VERSION = 'v0.2.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{is_comment} = 0;
    # HTML::Object::Element object
    $self->{object}     = '';
    $self->{tag_name}   = 'html';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    return( $self->raw->scalar );
}

sub as_pod
{
    my $self = shift( @_ );
    # Hmmm, could be embedded within something else, so we cannot actually say that
    # return( "=begin html\n\n" . $self->raw->scalar . "\n\n=end html\n" );
    return( $self->raw->scalar );
}

sub as_string
{
    my $self = shift( @_ );
    my $html = $self->raw;
    my $tree;
    if( $html->length > 0 && ( $tree = $self->object ) )
    {
        my @elem = $tree->look_down( _tag => 'div', class => qr/\bmermaid\b/ );
        if( scalar( @elem ) )
        {
            $self->document->setup_mermaid;
        }
    }
    return( $html );
}

sub is_comment { return( shift->_set_get_boolean( 'is_comment', @_ ) ); }

sub object
{
    my $self = shift( @_ );
    my $obj  = $self->_set_get_object( 'object' );
    return( $obj ) if( $obj );
    return if( !$self->raw->length );
    my $html = $self->raw->scalar;
    $obj = $self->parse_html( $html );
    $self->_set_get_object( 'object', 'HTML::Object::Element', $obj );
    return( $obj );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::HTML - Markdown HTML Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::HTML->new;
    # or
    $doc->add_element( $o->create_html( @_ ) );

=head1 VERSION

    v0.2.1

=head1 DESCRIPTION

This class represents a html chunk of data. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_markdown

Returns a string representation of the HTML formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the HTML formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the HTML.

It returns a plain string.

=head2 is_comment

Boolean value to define the content as an html comment or not.

This value does B<not> impact how the method L</as_string> or L</as_markdown> will work to return the string value.

=head2 object

Returns an L<HTML::Object::Element> object from the data stored

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#html>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
