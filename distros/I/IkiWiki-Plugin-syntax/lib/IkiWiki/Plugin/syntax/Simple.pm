package IkiWiki::Plugin::syntax::Simple;
use base qw(IkiWiki::Plugin::syntax::base);
use strict;
use warnings;
use Carp;
use utf8;
use English qw(-no_match_vars);

use HTML::Entities;

our $VERSION = '0.1';

sub can_syntax_from {
    my  $self   =   shift;

    ## and return a positive response (if it's text we can do it :-)
    return 1;
}

sub parse_and_html {
    my  $self   =   shift;

    my  $source =   $self->source();

    if ($self->language() =~ m{x?html}xmsi or 
        $source =~ m{<html>}xmsi) {
        $source = encode_entities($source);
    }
        
    $self->htmlized( $source );

    return;
}

sub build_plugin_info {
    my  $self   =   shift;

    return (        
            name        =>  q(Simple),
            version     =>  $VERSION,
            description =>  <<EOF,
Simple engine for basic installations without third party modules.
EOF
            special     =>  <<EOF,
If the source language matches "x?html" or the source contains a "<html>" string
the plugin uses the HTML::Entities::encode_entities() function.
EOF
            linenumbers =>  1,
            bars        =>  1,
            supported   =>  [
                    {   
                    language    =>  q(All),
                    description =>  q(All text contents),
                    fileext     =>  q(*),       
                    },
                ],
            );
}
                            
1;
__END__

=head1 NAME

IkiWiki::Plugin::syntax::Simple - Simple engine for syntax highlight

=head1 VERSION

This documentation refers to IkiWiki::Plugin::syntax::Simple version 0.1

=head1 SYNOPSIS

	use IkiWiki::Plugin::syntax::Simple;

    my $engine = IkiWiki::Plugin::syntax::Simple->new();

    my $htmlized_text = $engine->syntax_highlight(
                            source   =>  q(....),
                            language => q(pod),
                            linenumbers => 1,
                            );

=head1 DESCRIPTION

This module provides a simple syntax highlight engine for use with ikiwiki on
installations where don't install third party modules.

The code return the source text received without special CSS marks inside with
the exception of the C<PRE> html paragraph.

=head1 SUBROUTINES/METHODS

=head2 build_plugin_info( )

Returns a hash with information about his capabilities.

=head2 can_syntax_from( )

This method returns always true because it don't make any real work with the
source. 

=head1 DIAGNOSTICS

This module don't raise any exceptions.

=head1 CONFIGURATION AND ENVIRONMENT

This module don't need any special configuration nor environment.

=head1 DEPENDENCIES

=over

=item IkiWiki::Plugin::syntax::base

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to the author. 
Patches are welcome.

=head1 AUTHOR

Víctor Moral <victor@taquiones.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 "Víctor Moral" <victor@taquiones.net>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.


You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 US

