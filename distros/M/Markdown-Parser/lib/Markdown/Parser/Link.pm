## -*- perl -*-
##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Link.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/08/23
## Modified 2022/09/19
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Markdown::Parser::Link;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use vars qw( $VERSION );
    use Devel::Confess;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{encrypt}        = '';
    $self->{id}             = '';
    $self->{link_id}        = '';
    $self->{name}           = '';
    $self->{original}       = '';
    $self->{tag_name}       = 'link';
    $self->{title}          = '';
    $self->{url}            = '';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    my $arr = $self->new_array;
    $arr->push( sprintf( '[%s]', $self->alt ) );
    if( $self->id )
    {
        $arr->push( sprintf( '[%s]', $self->link_id ) );
    }
    elsif( $self->url || $self->title )
    {
        $arr->push( '(' );
        $arr->push( sprintf( '%s', $self->url ) ) if( $self->url );
        $arr->push( ' ' ) if( $self->url && $self->title );
        $arr->push( sprintf( '"%s"', $self->title ) );
        $arr->push( ')' );
    }
    if( $self->class->length || $self->id->length )
    {
        my $def = $self->new_array;
        $def->push( $self->id->map(sub{ "\#${_}" })->list );
        $def->push( $self->class->map(sub{ ".$_" })->list );
        $arr->push( '{' . $def->join( ' ' )->scalar . '}' );
    }
    return( $arr->join( '' )->scalar );
}

sub as_pod
{
    my $self = shift( @_ );
    my $arr = $self->new_array;
    if( $self->url && $self->title )
    {
        $arr->push( sprintf( 'L<%s|%s>', $self->title, $self->url ) );
    }
    elsif( $self->url )
    {
        $arr->push( sprintf( 'L<%s>', $self->url ) );
    }
    return( $arr->join( '' )->scalar );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr  = $self->new_array;
    my $tag  = 'a';
    my $tag_open = $tag;
    my $url = $self->url;
    my $orig = $self->original->scalar;
    my $url_str = "$url";
    my $encrypt = $self->encrypt;
    my $scheme = '';
    $scheme = $url->scheme if( ref( $url ) );
    $arr->push( "<${tag_open}" );
    my $attr = $self->new_array;
    $attr->push( $self->format_id ) if( $self->id->length );
    $attr->push( $self->format_class ) if( $self->class->length );
    my $attributes = $self->format_attributes;
    $attr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
    $arr->push( ' ' . $attr->join( ' ' )->scalar ) if( $attr->length );
    if( $scheme eq 'mailto' )
    {
        if( $encrypt eq 'obfuscate' )
        {
            $self->document->setup_email_obfuscation;
            # We use the original e-mail address as it as provided in the text, because URI alters it by url-encoding it
            my $email = $orig;
            my $user = substr( $email, 0, rindex( $email, '@' ) );
            my $host = substr( $email, rindex( $email, '@' ) + 1 );
            # Use of a decoy email address
            if( $self->document->default_email->length > 0 )
            {
                $arr->push( sprintf( ' href="%s"', $self->document->default_email->scalar ) );
            }
            else
            {
                $arr->push( " href=\"mailto:dave.null\@${host}\"" );
            }
            my $data_user = $self->document->email_obfuscate_data_user->scalar || 'user';
            my $data_host = $self->document->email_obfuscate_data_host->scalar || 'host';
            $arr->push( sprintf( ' data-%s="%s"', $data_user, $self->encode_html( ['"', '&', '?', '#'], join( '', reverse( split( //, $user ) ) ) ) ) );
            $arr->push( sprintf( ' data-%s="%s"', $data_host, $self->encode_html( ['"', '&', '?', '#'], join( '', reverse( split( //, $host ) ) ) ) ) );
            $self->class->push( $self->document->email_obfuscate_class ) if( !$self->class->has( $self->document->email_obfuscate_class->scalar ) );
            $arr->push( sprintf( ' class="%s"', $self->class->join( ', ' )->scalar ) );
        }
        elsif( $encrypt eq 'encode' || $encrypt )
        {
            $url_str = $self->encode_email_address( $orig );
            $arr->push( " href=\"$url_str\"" );
        }
        else
        {
            $arr->push( " href=\"$url_str\"" );
        }
    }
    else
    {
        $arr->push( " href=\"$url_str\"" );
    }
    if( $self->title->length )
    {
        $arr->push( sprintf( ' title="%s"', $self->encode_html( 'all', $self->title ) ) );
    }
    $arr->push( ">" );
    if( $scheme eq 'mailto' && $encrypt eq 'obfuscate' )
    {
        ## We do nothing
    }
    elsif( $self->children->length )
    {
        $arr->push( $self->children->map(sub{ $_->as_string })->list );
    }
    else
    {
        my $link_text = $scheme eq 'mailto' ? $self->encode_email_address( $orig ) : $orig;
        $arr->push( $link_text );
    }
    $arr->push( "</${tag}>" );
    return( $arr->join( '' )->scalar );
}

sub copy_from
{
    my $self = shift( @_ );
    my $def  = shift( @_ ) || return( $self->error( "No link definition object was provided." ) );
    return( $self->error( "Link definition object provided to copy information from \"", overload::StrVal( $def ), "\" is not a Markdown::Parser::LinkDefinition object." ) ) if( !$self->_is_a( $def, 'Markdown::Parser::LinkDefinition' ) );
    return( $def->copy_to( $self ) );
}

sub encrypt { return( shift->_set_get_scalar_as_object( 'encrypt', @_ ) ); }

sub encode_email_address
{
    my $self = shift( @_ );
    my $addr = shift( @_ );
    return( '' ) if( !length( $addr ) );
    ## Borrowed from Markdown original author John Gruber
	srand();
	## Use either decimal, hexadecimal or no encoding
	## https://stackoverflow.com/questions/20357800/html-entities-when-to-use-decimal-vs-hex
	my @encode = 
	(
		sub{ '&#' .                 ord( shift )   . ';' },
		sub{ '&#x' . sprintf( "%X", ord( shift ) ) . ';' },
		sub{                             shift           },
	);
	my @chars = split( //, $addr );
	for my $i ( 0..$#chars )
	{
		if( $chars[$i] eq '@' )
		{
			## Markdown's original author John Gruber says: "this *must* be encoded. I insist."
			$chars[$i] = $encode[ int( rand( 1 ) ) ]->( $chars[$i] );
		}
		elsif( $chars[$i] ne ':' )
		{
			## leave ':' alone (to spot mailto: later)
			my $r = rand();
			# roughly 10% raw, 45% hex, 45% dec
			$chars[$i] = (
				$r > .9   ?  $encode[2]->( $chars[$i] )  :
				$r < .45  ?  $encode[1]->( $chars[$i] )  :
							 $encode[0]->( $chars[$i] )
			);
		}
	}
	return( join( '', @chars ) );
}

sub link_id { return( shift->_set_get_scalar_as_object( 'link_id', @_ ) ); }

sub name
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $text = shift( @_ );
        return( $self->add_element( $self->create_text({ text => $text }) ) );
    }
    else
    {
        return( $self->children->map(sub{ $_->as_string })->join( '' ) );
    }
}

sub original { return( shift->_set_get_scalar_as_object( 'original', @_ ) ); }

sub title { return( shift->_set_get_scalar_as_object( 'title', @_ ) ); }

sub url { return( shift->_set_get_uri( 'url', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Link - Markdown Link Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Link->new;
    # or
    $doc->add_element( $o->create_link( @_ ) );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class represents a link. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_markdown

Returns a string representation of the link formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the link formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the link.

It returns a plain string.

=head2 copy_from

Provided with a L<Markdown::Parser::LinkDefinition> object and this will call L<Markdown::Parser::LinkDefinition/copy_to>

=head2 encrypt

Boolean value to encrypt links that are an e-mail address

=head2 encode_email_address

Given an e-mail address, this use randomly 3 ways to encode it in an attempt to obfuscate and make it harder for spammers to harvest it.

This is based solely on Markdown's original author, John Gruber's code.

=head2 id

Sets or gets the array object of css id for this link. There should only be one set. Stores the value as an L<Module::Generic::Array> object.

=head2 link_id

Sets or gets the link id. Stores the value as an L<Module::Generic::Scalar> object.

Returns the current value.

=head2 name

Sets or gets the link name, i.e. the text highlighted in the link.

In void context, this return the text as a string.

=head2 original

Sets or gets the original link string.

=head2 title

Sets or gets the link title. Stores the value as an L<Module::Generic::Scalar> object.

Returns the current value.

=head2 url

Sets or gets the link url. This stores the value as an L<URL> object.

Returns the current value.

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#link>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
