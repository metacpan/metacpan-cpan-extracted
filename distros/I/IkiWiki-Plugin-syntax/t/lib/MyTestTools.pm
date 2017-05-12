package MyTestTools;
use base qw(Exporter);
use strict;
use warnings;

use Test::More;
use IO::File;

our @EXPORT         =   ();
our @CSS_FUNCTIONS  =   qw( build_css_regex count_css check_results );
our @EXPORT_OK      =   ( @CSS_FUNCTIONS, qw(Engines ResultsFile) );
our %EXPORT_TAGS    =   (
    'all'   =>  [ @EXPORT_OK ],
    'css'   =>  [ @CSS_FUNCTIONS ],
);

our $VERSION    = '0.1';
my %default_counters = (
    q(synLineNumber)    => 0, 
    q(synTitle)         => 0,      
    q(synBar)           => 0,       
    q(synComment)       => 0,   
    q(synConstant)      => 0,   
    q(synIdentifier)    => 0, 
    q(synStatement)     => 0, 
    q(synPreProc)       => 0,   
    q(synType)          => 0,     
    q(synSpecial)       => 0,    
    q(synUnderlined)    => 0, 
    q(synError)         => 0,       
    q(synTodo)          => 0,        
    );

sub build_css_regex {
    my  $tag    =   shift;
    my  $value  =   shift || q(.+);

    my  $expr  = sprintf('<span class="%s">\s*%s\s*</span>',
                        $tag, $value );

    return qr{$expr}; 
}

sub count_css {
    my  $text       = shift;
    my  %css_tags   = ();

    while ($text =~ m{<span\s+class\s*=\s*"(\w+)"\s*>}xmsg) {
        my  $name = $1;
        if (not exists $css_tags{$name}) {
            $css_tags{$name} = 0;
        }

        $css_tags{$name}++;
    }

    return wantarray ? %css_tags : scalar keys %css_tags;
}

sub check_results {
    my  ($text, %expect)    =   @_;
    
    my %found = ( %default_counters, 
                  count_css( $text ) );

    foreach my $name (keys %expect) {
        is($found{$name},$expect{$name}, sprintf ("Found %u %s tag(s)", $found{$name}, $name) );
    }

    return;
}

sub Engines {
    my  $full_path  =   shift || 0;
    my  @names = qw(Simple Kate Vim);

    if ($full_path) {
        return map { "IkiWiki::Plugin::syntax::${_}" } @names;
    }
    else {
        return @names;
    }
}

my $results_fh = undef;

sub ResultsFile {
    my  $path   =   shift;

    if (not $path) {
        return $results_fh;
    }
    else {
        # if the file exits and isn't writable 
        if (-e $path and not -w $path) {
            return;
        }
        else {
            # open the file for writing
            return $results_fh = IO::File->new( $path, ">" );
        }
    }        
}

1;
__END__
=head1 NAME

MyTestTools - Auxiliary functions for test the package IkiWiki::Plugin::syntax

=head1 SYNOPSIS

In a test script:

    use lib q(t/lib);
    use MyTestTools;

=head1 DESCRIPTION

The module exports auxiliary functions for automatic test with syntax highlight
engines.

=head1 SUBROUTINES/METHODS

=head2 build_css_regex( )

Build a regular expresion for matches CSS directives in a text.

=head2 count_css( )

Count the number of appearances of a CSS expresion in a text.

=head2 check_results( )

Compare the number of CSS expressions founded in a text with the data received
in the function.

=head1 DIAGNOSTICS

These functions don't raise any exceptions. It use the module Test::More for
checks.

=head1 DEPENDENCIES

=over

=item Text::More

=close

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

