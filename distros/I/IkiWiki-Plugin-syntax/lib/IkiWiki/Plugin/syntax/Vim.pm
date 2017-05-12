package IkiWiki::Plugin::syntax::Vim;
use base qw(IkiWiki::Plugin::syntax::base);
use strict;
use warnings;
use Carp;
use utf8;
use English qw(-no_match_vars);

use IO::File;
use IO::Dir;

use constant VIM_SYNTAX  =>   q(/usr/share/vim/vimcurrent/syntax);

# package variables
our $VERSION = '0.2';

# private variables
my %syntaxes = ();

# public methods
sub can_syntax_from {
    my  $self       =   shift;
    my  $origin     =   shift;
    my  $value      =   shift;

    if ($origin eq 'proposed') {
        # save on temporary variable because the function can modify the
        # proposed value
        if (my $lang = $self->_syntax_proposed( $value )) {
            $self->language($lang);
            return 1;
        }
    }
    elsif ($origin eq 'filename') {
        1;
    }
    elsif ($origin eq 'content') {
        # vim has autodetection capabilities
        return 1;
    }

    return 0;
}

sub _syntax_proposed {
    my  $self       =   shift;
    my  $proposed   =   shift;
    
    if (not %syntaxes) {
        $self->_build_syntaxes();
    }

    # if we have a direct relation 
    if (exists $syntaxes{lc $proposed}) {
        return $proposed;
    }
    else {
        # search for a special form
        foreach my $lang (keys %syntaxes) {
            if ($proposed =~ qr{$lang} ) {
                return $lang;
            }
        }

        return;
    }
}

sub _build_syntaxes {
    my  $self   =   shift;

    $self->logging("scanning files in " . VIM_SYNTAX);
    
    %syntaxes = ( _build_syntax_hash() );
}

sub parse_and_html {
    my  $self   =   shift;
    my  $vim    =   $self->_engine();

    my $result = $vim->syntax_mark_string( $self->source(), 
                    filetype => $self->language() )->html();

    return $self->htmlized( $result );
}

#
#   Build a hash scanning all files under the directory 
#   /usr/share/vim/vimcurrent/syntax and with extension .vim
#   The hash is keyed using the syntax language keyname.
#

sub _build_syntax_hash {
    my  $dir = IO::Dir->new( VIM_SYNTAX );
    my  %hash   =   ();

    if ($dir) {
        while (defined( my $entry = $dir->read())) {
            my $syntax_file = VIM_SYNTAX . "/${entry}";

            if (-f $syntax_file and $syntax_file =~ m{\.vim$}xms) {
                my ($key,$desc) = _scan_syntax_file( $syntax_file );

                if ($key) {
                    $hash{lc $key} = $desc;
                }
            }
        }
        $dir->close();
    }

    return %hash;
}

#
#   Scan a syntax vim file and extract two values from it: 
#   - Keyname (perl, php, pascal, html, ...)
#   - Description ( Pascal, php PHP 3/4/5, Mutt setup files, ...)
#
sub _scan_syntax_file {
    my  $file   =   shift;
    my  ($description, $keyname);

    if (my $fh = IO::File->new( $file )) {
        while (<$fh>) {
            chomp;

            if (m{^"\s+Language:\s+(.+)$}xms) {
                $description = $1;
            }
            elsif (m{^let\s+b:current_syntax\s+=\s+"(.+)"}xms) {
                $keyname = $1;
            }

            if ($description and $keyname) {
                return ($keyname => $description);
            }
        }
        $fh->close();
    }

    return ();
}

sub build_plugin_info {
    my  $self   =   shift;

    return ( 
        name        =>  'Vim',
        version     =>  $VERSION,
        external    =>  q(Text::VimColor),
        description =>  <<'EOF',
This plugin uses the Text::VimColor module and the vim editor.

Copyright 2002-2006, Geoff Richards.
EOF
        special     =>  <<EOF,
- Available the autodetection capability through vim program.
EOF
        bugs        =>  <<EOF,
- Could not show the file name extensions in the information page.
EOF
        supported   =>  
                [
                $self->_list_of_supported_syntaxes(),
                ]
        );
}    

sub _list_of_supported_syntaxes {
    my  $self       =   shift;
    my  @rlist      =   ();

    if (not %syntaxes) {
        $self->_build_syntaxes();
    }

    foreach my $syntax_name (keys %syntaxes) {
        push @rlist, { language => $syntax_name, fileext => '', 
                        description => $syntaxes{$syntax_name} };
    }                    

    return (sort { $a->{language} cmp $b->{language} } @rlist);
}

1;
__END__

=head1 NAME

IkiWiki::Plugin::syntax::Vim - Uses Text::VimColor for syntax highlight in IkiWiki

=head1 VERSION

This documentation refers to IkiWiki::Plugin::syntax::Vim  version 0.1

=head1 SYNOPSIS

This module is used internally for L<IkiWiki::Plugin::syntax>. 

=head1 DESCRIPTION

See the L<IkiWiki::Plugin::syntax> for examples of use.

=head1 SUBROUTINES/METHODS

=head2 can_syntax_from( language|filename|content => value )

Return a true value if the module can work with the parameters passed to.

=over

=item proposed

Check if C<Vim> has a syntax file for the proposed language.

=item filename

Check if C<Vim> has a syntax file for the filename extension.

=item contents

Check if C<Vim> can determine the source language.

=back

=head2 parse_and_html( )

Do the real work of parse the source and htmlized using the C<Vim> editor and
the L<Text::VimColor> module.

=head2 build_plugin_info( )

Returns a hash with information about the plugin capabilities.

=head1 DIAGNOSTICS

A list of every error and warning message that the module
can generate.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to <Maintainer name(s)> (<contact address>).
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

