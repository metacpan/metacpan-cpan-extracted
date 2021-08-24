##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/NewLine.pm
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
package Markdown::Parser::NewLine;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use Nice::Try;
    use Want;
    use Devel::Confess;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    ## Some new lines are silents, and some are explicit like following a <br />
    $self->{break}      = 0;
    $self->{new_line}   = "\n";
    $self->{tag_name}   = 'nl';
    ## Repeating counts the number of occurence of new lines without having multiple new line objects
    $self->{repeating}  = 1;
    return( $self->SUPER::init( @_ ) );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr = $self->new_array;
    $arr->push( '<br />' ) if( $self->break );
    $arr->push( $self->new_line->scalar );
    return( $arr->join( '' )->scalar );
}

sub break { return( shift->_set_get_boolean( 'break', @_ ) ); }

sub new_line { return( shift->_set_get_scalar_as_object( 'new_line', @_ ) ); }

sub repeating : lvalue
{
    my $self = shift( @_ );
    my $v = $self->{repeating};
    my $v2 = $self->_set_get_lvalue( 'repeating', @_ );
    if( $v != $v2 )
    {
        $self->tag_name( 'nl' . $v2 );
    }
    return( $v2 );
}

1;

__END__

=encoding utf8

=head1 NAME

Markdown::Parser::NewLine - Markdown New Line Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::NewLine->new;
    # or
    $doc->add_element( $o->create_new_line( @_ ) );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a new line. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_markdown

Returns a string representation of the new line formatted in markdown.

It returns a plain string.

=head2 as_string

Returns an html representation of the new line.

It returns a plain string.

=head2 break

Boolean value to set whether this new line is a line break implying a E<lt>br /E<gt> html tag.

According to Markdown original author, John Gruber, this is the case when one creates 2 or more spaces followed by a new line in Markdown. For example:

    This is an example of a line break  
    and this line will be in another line.

This will be rendered as:

    This is an example of a line break<br />
    and this line will be in another line.

Without the 2 space preceding the line break, the html representation would have put this on one line like so:

    This is an example of a line break and this line will be in another line.

=head2 new_line

This sets or gets the character representation of a new line. Typically this would be C<\n>

This stores the value as a L<Module::Generic::Scalar>

=head2 repeating

Provided with an integer to set the number of time the new line was repeated, implying there was other new lines before. The parser uses it as an indicator during parsing, so this is more of an internal use and can be safely ignored.

Note that this method can be accessed as a regular object method, and also as an lvalue method, such as :

    $nl->repeating( 2 );
    # or
    $nl->repeating = 2;

=head1 SEE ALSO

L<Markdown::Parser>, 
Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#p>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
