##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Line.pm
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
package Markdown::Parser::Line;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use Nice::Try;
    use Devel::Confess;
    use constant TAB_SPACES => '    ';
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{tag_name}   = 'hr';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    return( $self->raw->scalar ) if( $self->raw->length );
    return( '* * *' );
}

sub as_string
{
    my $self = shift( @_ );
    my $tag  = 'hr';
    return( "<$tag />" );
}

1;

__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Line - Markdown Line Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Line->new;
    # or
    $doc->add_element( $o->create_line( @_ ) );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a horizontal line. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_markdown

Returns a string representation of the horizontal line formatted in markdown.

It returns a plain string.

=head2 as_string

Returns an html representation of the horizontal line.

It returns a plain string.

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#hr>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
