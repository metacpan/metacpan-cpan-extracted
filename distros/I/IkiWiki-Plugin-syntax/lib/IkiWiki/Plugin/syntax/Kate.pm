package IkiWiki::Plugin::syntax::Kate;
use base qw(IkiWiki::Plugin::syntax::base);
use strict;
use warnings;
use Carp;
use utf8;
use English qw(-no_match_vars);

## package variables
our $VERSION        =   '0.1';
my  %substitutions  =   (
    "<"     => "&lt;",
    ">"     => "&gt;",
    "&"     => "&amp;",
    " "     => "&nbsp;",
    "\t"    => "&nbsp;" x 4,    
    "\n"    => "\n",
);
my  %format_table   =   (
    Alert           => 'synError',
    BaseN           => 'synConstant',
    BString         => 'synConstant',
    Char            => 'synUnderlined',
    Comment         => 'synComment',
    DataType        => 'synType',
    DecVal          => 'synConstant',
    Error           => 'synError',
    Float           => 'synConstant',
    Function        => 'synSpecial',
    IString         => 'synConstant',
    Keyword         => 'synStatement',
    Normal          => undef,
    Operator        => 'synConstant',
    Others          => 'synPreProc',
    RegionMarker    => 'synPreProc',
    Reserved        => 'synSpecial',
    String          => 'synConstant',
    Variable        => 'synIdentifier',
    Warning         => 'synError',
);

## public methods 

sub external_parameters {
    my  $self   =   shift;

    return (
            substitutions   =>  \%substitutions,
            format_table    =>  $self->_build_format_table(),
            );
}
                                
sub _build_format_table {
    my  $self   =   shift;

    foreach my $name (keys %format_table) {
        if (not ref $format_table{$name}) {
            $format_table{$name} = [ $self->css_pair($format_table{$name}) ];
        }
    }

    return \%format_table;
}

sub configure_engine {
    my  $self   =   shift;
    my  $kate   =   $self->_engine();

    if ($kate) {
        $kate->language( $self->language() );
    }

    return $self;
}

sub parse_and_html {
    my  $self   =   shift;
    my  $kate   =   $self->_engine();

    if ($kate) {
        no warnings;

        $self->htmlized( $kate->highlightText( $self->source() ) );
    }

    return $self;
}

sub can_syntax_from {
    my  $self   =   shift;
    my  $origin =   shift;
    my  $value  =   shift;

    # check the language proposed
    if ($origin eq 'proposed') {
        my @languages = $self->_engine->languageList();

        # try a direct search
        foreach my $lang (@languages) {
            if (uc $lang eq uc $value) {
                $self->detect( $lang );
                return 1;
            }
        }

        # try a regex search 
        foreach my $lang (@languages) {
            if ($lang =~ m{$value}xims) {
                $self->detect( $lang );
                return 1;
            }
        }
    }
    elsif ($origin eq 'filename') {
        if ($self->_engine->languageProposed( $value )) {
            return 1;
        }
    }
    elsif ($origin eq 'context') {
        # this plugin hasn't autodetection from source 
        return 0;
    }

    return 0;
}

sub reset_engine {
    my  ($self,@fields) =   @_;
    
    ## base class reset fields
    $self->SUPER::reset_engine(@fields);

    ## reset real engine if exists
    if ($self->{_engine}) {
        $self->{_engine}->reset();
    }

    return $self;
}

sub build_plugin_info {
    my  $self           =   shift;
    my  $kate_version   =   '';

    return  ( 
        name        =>  'Kate',
        version     =>  $VERSION,
        external    =>  q(Syntax::Highlight::Engine::Kate),
        description =>  <<'EOF',
Using the Syntax::Highlight::Engine::Kate package, a port to Perl of the
syntax highlight engine of the Kate text editor.

Copyright (c) 2006 by Hans Jeuken, all rights reserved.
EOF
        linenumbers =>  1,
        bars        =>  1,
        bugs        =>  <<EOF,
- Lacks of a normalized mechanism for to select the language syntax.
EOF
        special     =>  undef,
        supported   =>  
            [ 
                $self->_list_of_supported_syntaxes()
            ],
            );
}

sub _list_of_supported_syntaxes {
    my  $self       =   shift;
    my  $filexts    =   $self->_engine->extensions();
    my  $syntaxes   =   $self->_engine->syntaxes();
    my  @rlist     =   ();

    foreach my $extension (keys %{ $filexts }) {
        my  $syntax_name    =   undef;

        if (ref $filexts->{ $extension } eq 'ARRAY') {
            foreach my $desc (@{ $filexts->{ $extension } }) {
                $syntax_name = $syntaxes->{ $desc };

                _add_syntax_info( \@rlist, $syntax_name, $extension, $desc );
            }
        }
        else {
            _add_syntax_info( \@rlist, $syntaxes->{ $filexts->{ $extension } },
                                $extension, $filexts->{ $extension } );
        }
    }

    return (sort { uc($a->{language}) cmp uc($b->{language}) } @rlist);
}

sub _add_syntax_info {
    my  $target_ref     =   shift;
    my  $language       =   shift;
    my  $fileext        =   shift;
    my  $description    =   shift;

    push @{ $target_ref }, {
        language    =>  $language,
        fileext     =>  $fileext,
        description =>  $description,
    };

    return;
}

1;
__END__

=head1 NAME

IkiWiki::Plugin::syntax::Kate - Interface between Syntax::Highlight::Engine::Kate and IkiWiki

=head1 VERSION

This documentation refers to IkiWiki::Plugin::syntax::Kate version 0.1

=head1 SYNOPSIS

This module is used internally by L<IkiWiki::Plugin::syntax::base>.

=head1 DESCRIPTION

This package is a interface between the Hans Jeuken's 
L<Syntax::Highlight::Engine::Kate> module and the Joey Hess's IkiWiki program.

It is a derived class from L<IkiWiki::Plugin::syntax::base> and override a few
methods.

=head1 SUBROUTINES/METHODS

=head2 build_plugin_info( ) 

=head2 can_syntax_from( ) 

=head2 configure_engine( ) 

=head2 external_parameters( ) 

=head2 parse_and_html( ) 

=head2 reset_engine( ) 

=head1 DIAGNOSTICS

At the moment there is no declared errors or exceptions.

=head1 CONFIGURATION AND ENVIRONMENT

The module needs a functional installation of
L<Syntax::Highlight::Engine::Kate> distribution.

=head1 DEPENDENCIES

=over

=item L<Syntax::Highlight::Engine::Kate>

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

