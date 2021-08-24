##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Text.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/08/23
## Modified 2021/08/23
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Markdown::Parser::Text;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use Nice::Try;
    use Devel::Confess;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{text}       = '';
    $self->{tag_name}   = 'text';
    return( $self->SUPER::init( @_ ) );
}

sub append { return( shift->text->append( @_ ) ); }

sub as_markdown { return( shift->text->scalar ); }

sub as_string { return( shift->text->scalar ); }

sub text { return( shift->_set_get_scalar_as_object( 'text', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Text - Markdown Text Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Text->new;
    # or
    $doc->add_element( $o->create_text( @_ ) );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a text chunk. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 append

Provided with a string, and this will add it at the end of the current text data accessible with L</text>.

=head2 as_markdown

Returns a string representation of the text formatted in markdown.

It returns a plain string.

=head2 as_string

Returns an html representation of the text.

It returns a plain string.

=head2 text

Set or gets the text. The value is stored as a L<Module::Generic::Scalar> object.

It returns the current value set.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2000-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
