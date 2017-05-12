package IkiWiki::Plugin::syntax::base;
use base qw(Class::Accessor::Fast); 
use strict;
use warnings;
use Carp;
use utf8;
use English qw(-no_match_vars);

## declare the accessors 
IkiWiki::Plugin::syntax::base->mk_accessors( qw( 
        language detect page file source 
        linenumbers first_line_number 
        htmlized output bars 
    ) );

## other libraries
use IkiWiki::Plugin::syntax::gettext;
use IkiWiki::Plugin::syntax::CSS;
use IkiWiki::Plugin::syntax::X;

## package variables 
our $VERSION = '0.2';

my  %plugin2external    =   (
    'IkiWiki::Plugin::syntax::Simple'   =>  undef,
    'IkiWiki::Plugin::syntax::Kate'     =>  'Syntax::Highlight::Engine::Kate',
    'IkiWiki::Plugin::syntax::Vim'      =>  'Text::VimColor',
);

#
#   public methods
#

sub new {
    my  ($class,@params)    =  @_;
    my  $self               =  $class->SUPER::new( @params );

    if ($self) {
        $self->reset_engine( qw(syntax linenumbers first_line_number bars) );
    }

    return $self;
}

sub _engine {
    my  ($self,$package,%params) = @_;

    if (not $self->{_engine}) {
        if (not $package) {
            $package = $plugin2external{ ref $self };
        }

        ## try to load the external and real module 
        eval "use ${package};";

        # verify the package load             
        if ($@) {
            Syntax::X::Engine::Use->throw( package => $package,
                                               message => $@ );
        }
        else {
            ## check the parameters using a optional method
            if (not %params) {
                if ($self->can('external_parameters')) {
                    %params = ( $self->external_parameters() );
                }
            }

            # try to build a new object 
            eval {
                $self->{_engine} = $package->new( %params );
            };

            if ($@ or not $self->{_engine}) {
                Syntax::X::Engine->throw( 
                    message     => gettext(q(Could not create a new object)),
                    'package'   => $package );
            }
        }
    }

    return $self->{_engine};
}

sub configure {
    my  ($self, %params)    =   @_;

    ## save the parameters
    foreach my $field (keys %params) {
        next if not $params{$field};

        $self->set( $field, $params{$field} );
    }

    ## and configure the engine 
    if ($self->can('configure_engine')) {
        $self->configure_engine( );
    }       

    return $self;
}

sub reset_engine {
    my  ($self,@fields)     =   @_;
    my  %resets =   (
        syntax              =>  undef,
        source              =>  undef,
        htmlized            =>  undef,
        output              =>  undef,
        linenumbers         =>  0,
        first_line_number   =>  1,
        bars                =>  0,
        );

    if (not @fields) {
        @fields = keys %resets;
    }

    foreach my $name (@fields) {
        $self->set( $name, $resets{$name} );
    }

    return $self;
}

sub detect_language {
    my  $self       =   shift;
    my  %params     =   (
            proposed    =>  undef,
            filename    =>  undef,
            content     =>  undef,
            @_ );

    if (defined $params{proposed}) {
        if ($self->can_syntax_from( proposed => $params{proposed})) {
            $self->language( $self->detect() || $params{proposed} );
            return 1;
        }
        elsif ($self->can_auto_detect()) {
            $self->language( q(Auto) );
        }
    }

    if (defined $params{filename} and 
        $self->can_syntax_from( filename => $params{filename})) {
        $self->language( $self->detect() || q(Auto) );
        return 1;
    }

    if (defined $params{content} and 
        $self->can_syntax_from( content => $params{content})) {
        $self->language( $self->detect() || q(Auto) );
        $self->file( q(Inline) );
        return 1;
    }

    return 0;
}

sub can_syntax_from {
    my  $self   =   shift;
    my  $origin =   shift;
    my  $value  =   shift;

    # by default we can't do it
    return 0;
}

sub logging {
    my  $self       =   shift;
    my  $message    =   shift || '';
    my  $page       =   '';

    if ($self->page()) {
        $page = sprintf 'on page (%s)', $self->page;
    }

    IkiWiki::debug( sprintf 'syntax %s: %s ...', $page, $message );
}

sub fail_response {
    my  $self       =   shift;
    my  $fail       =   shift;
    my  $error_msg  =   undef;

    if (not $fail) {
        $error_msg = gettext(q(unknown exception));
    }
    elsif (ref($fail)) {
        $error_msg = $fail->full_message();
    }
    else {
        $error_msg = $fail;
    }

    return sprintf 'syntax (%s) on page %s: %s', 
                    $self->engine() || 'undef', 
                    $self->page() || 'none',                        
                    $error_msg;
}

sub engine {
    my  $self   =   shift;

    if (ref $self) {
        return ref $self;
    }
    else {
        return '';
    }
}


sub plugin_info {
    my  ($self,@params)   =   @_;
    my  %info = (
        name        =>  undef,      # shorten plugin name 
        version     =>  undef,      # version number
        description =>  undef,      # human readable description
        special     =>  undef,      # special features
        bugs        =>  undef,      # bugs or missing features
        external    =>  undef,      # external modules 
        linenumbers =>  0,
        bars        =>  0,
        supported   =>  [],
    );

    if ($self->can('build_plugin_info')) {
        %info = $self->build_plugin_info(@params);
    }
    else {
        # fill with harmless values
        $info{name}         = q(None);
        $info{description}  = gettext(q(No external plugin available));
    }

    return %info;        
}

sub _split_htmlized {
    my  $self   =   shift;

    return split m{\n}xms, $self->htmlized();
}

sub _join_html_lines {
    my  ($self,@lines)   =   @_;

    return join "\n", @lines;
}

sub syntax_highlight {
    my  ($self, %params)    =  @_;

    ## configure engine
    $self->configure( %params );

    ## is the language missing ? 
    if (not $self->language()) {
        Syntax::X::Parameters::Wrong->throw( 
            message => gettext('missing language for source highlight'),
            );
    }

    ## do we have a source text ? 
    if (not $self->source()) {
        Syntax::X::Parameters::Source->throw();
    }

    ## is the language supported ? 
    if (not $self->can_syntax_from( proposed => $self->language() )) {
        Syntax::X::Engine::Language->throw( language => $self->language() );
    }

    ## parse the source and add html tags
    $self->parse_and_html( );

    ## normalize the css tags 
    $self->normalize_tags( );

    ## are the lines numered ?
    if ($self->linenumbers()) {
        $self->to_number_lines( );
    }

    ## is the output barred ? 
    if ($self->bars()) {
        $self->to_bar_lines();
    }

    ## future updates: format comments ? 

    ## save the htmlized to the final target
    return $self->output( $self->htmlized() );
}

sub normalize_tags {
    my  $self   =   shift;

    return $self;
}

sub parse_and_html {
    my  $self   =   shift;

    # copy the source over the htmlized field by default 
    $self->set('htmlized', $self->source() );

    return;
}

sub to_number_lines {
    my  $self       =   shift;
    my  $counter    =   shift || $self->first_line_number();
    my  @numered    =   ();

    ## avoid renumber the text
    if (not $self->match_css('line_number', $self->htmlized())) {
        # if we haven't a first line number set to first 
        if (not $counter  =~ m{^\d+}xms) {
            $counter = 1;
        }

        #   Wrap every line with special class
        foreach my $line ($self->_split_htmlized()) {
            #   add a formated line number and a indent space
            push @numered, $self->css('line_number', sprintf '%5u', $counter++ ) 
                            . '  ' . $line ;
        }

        # save the result in the htmlized field
        $self->htmlized( $self->_join_html_lines( @numered ) );
    }

    return $self;
}

sub to_bar_lines {
    my  $self   =   shift;

    ## avoid rebar the text
    if (not $self->match_css('bar_line', $self->htmlized())) {
        my $counter = 0;
        my @barred = ();

        foreach my $line ($self->_split_htmlized()) {
            if ( ($counter++ % 2) == 0) {
                ## even line 
                push @barred, $self->css('bar_line', $line );
            }
            else {
                push @barred, $line ;
            }
        }

        $self->htmlized( $self->_join_html_lines( @barred ) );
    }

    return $self;
}

1;
__END__

=head1 NAME

IkiWiki::Plugin::syntax::base - Base class for the IkiWiki::Plugin::syntax 

=head1 VERSION

This documentation refers to IkiWiki::Plugin::syntax::base version 0.1

=head1 SYNOPSIS

	package IkiWiki::Plugin::syntax::MyEngine;
    use base qw(IkiWiki::Plugin::syntax::base);

    ...

    1;
    
=head1 DESCRIPTION

This module provides a base class for build specialized interfaces to external
syntax highlight engines.

=head1 SUBROUTINES/METHODS

=head2 new( )

Build a new object and initialize his attributes. 

Accept the following parameters:

=over

=item engine

=back

=head2 reset_engine( )

    $engine->reset_engine();

This method initialize the syntax highlight engine.

=head2 plugin_info( )

Return a hash with information about the syntax highlight module's capabilities.

=head2 syntax_highlight( )

This method produces a HTML text with the original source and the CSS tags. 

=head2 configure( )

=head2 parse_and_html( )

=head2 normalize_tags( )

=head2 to_number_lines( )

=head2 to_bar_lines( )

=head2 can_syntax_from( )

=head2 detect_language( )

=head2 fail_response( )

=head2 logging( )

=head2 plugin_info( )

=head1 DIAGNOSTICS

A list of every error and warning message that the module
can generate.

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
version 2.1 of the License, or (at your option) any later version.


This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.


You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 US

