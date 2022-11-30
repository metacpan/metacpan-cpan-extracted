package Jenkins::i18n::ProcOpts;

use 5.014004;
use strict;
use warnings;
use Hash::Util qw(lock_hash unlock_value lock_value);
use Carp qw(confess);
use File::Spec;

our $VERSION = '0.08';

=pod

=head1 NAME

Jenkins::i18n::ProcOpts - process files definitions based on CLI options

=head1 SYNOPSIS

  use Jenkins::i18n::ProcOpts;

=head1 DESCRIPTION

This module define how the translation files should be processed based on the
collected CLI options.

=head2 EXPORT

None by default.

=head1 METHODS

=head2 new

Creates a new instance.

Expects as positional parameters:

=over

=item 1

A string representing the path where the files should be reviewed.

=item 2

A string representing the path where the processed files should be written to.

=item 3

A boolean (in Perl terms) if a counter is to be used.

=item 4

A boolean (in Perl terms) if deprecated files should be removed.

=item 5

A boolean (in Perl terms) if new files should be added.

=item 6

A boolean (in Perl terms) if CLI is running in debug mode.

=item 7

A string identifying the chosen language for processing.

=item 8

An optional string of a regular expression to match the content of the
translated properties.

=back

=cut

sub new {
    my (
        $class,  $source_dir, $target_dir, $use_counter, $is_remove,
        $is_add, $is_debug,   $lang,       $search
    ) = @_;
    my $self = {
        source_dir  => $source_dir,
        target_dir  => $target_dir,
        use_counter => $use_counter,
        is_remove   => $is_remove,
        is_add      => $is_add,
        is_debug    => $is_debug,
        language    => $lang,
        counter     => 0,
        ext_sep     => qr/\./
    };

    foreach my $attrib ( keys( %{$self} ) ) {
        confess "must receive $attrib as parameter"
            unless ( defined( $self->{$attrib} ) );
    }

    confess
'Removing or adding translation files are excluding operations, they cannot be both true at the same time'
        if ( $is_remove and $is_add );

    if ( defined($search) ) {
        $self->{search}     = qr/$search/;
        $self->{has_search} = 1;
    }
    else {
        $self->{has_search} = 0;
    }

    bless $self, $class;
    lock_hash( %{$self} );
    return $self;
}

=head2 is_to_search

Returns true (1) or false (0) if there is a defined term to search on the
translated properties values.

=cut

sub is_to_search {
    my $self = shift;
    return $self->{has_search};
}

=head2 search_term

Returns the compiled regular expression that will be used to match terms in the
translated properties values.

=cut

sub search_term {
    my $self = shift;
    confess 'There is no defined search term' unless ( $self->{has_search} );
    return $self->{search};
}

=head2 get_language

Returns a string identifying the chosen language for processing.

=cut

sub get_language {
    my $self = shift;
    return $self->{language};
}

=head2 get_source

Returns string of the path where the translation files should be looked for.

=cut

sub get_source {
    my $self = shift;
    return $self->{source_dir};
}

=head2 get_target

Returns a string of the path where the reviewed translation files should be
written to.

=cut

sub get_target {
    my $self = shift;
    return $self->{target_dir};
}

=head2 inc

Increments the processed files counter.

=cut

sub inc {
    my $self = shift;

    if ( $self->use_counter ) {
        my $attrib = 'counter';
        unlock_value( %{$self}, $attrib );
        $self->{$attrib}++;
        lock_value( %{$self}, $attrib );
        return 1;
    }

    warn "Useless invocation of inc with file counter disabled\n";
    return 0;
}

=head2 use_counter

Returns true (1) or false (0) if the processed counter is in use.

=cut

sub use_counter {
    my $self = shift;
    return $self->{use_counter};
}

=head2 get_counter

Returns an integer representing the number of translation files already
processed.

=cut

sub get_counter {
    my $self = shift;
    return $self->{counter};
}

=head2 is_remove

Returns true (1) or false (0) if the outdated translation files should be
removed.

=cut

sub is_remove {
    my $self = shift;
    return $self->{is_remove};
}

=head2 is_add

Returns true (1) or false (0) if the translation files should be added.

=cut

sub is_add {
    my $self = shift;
    return $self->{is_add};
}

=head2 is_debug

Returns true (1) or false (0) if the CLI is running in debug mode.

=cut

sub is_debug {
    my $self = shift;
    return $self->{is_debug};
}

=head2 define_files

Based on complete path to a translation file as input, defines the resulting
expected translation files and their locations, even if they don't yet exist.

Expects as parameter the complete path to a translation file (Jelly or Java
Properties).

Returns an array with the following elements:

=over

=item 1

The path to the current language file location.

=item 2

The path to the English file location.

=back

=cut

sub define_files {
    my ( $self, $file ) = @_;
    my ( $volume, $dirs, $filename ) = File::Spec->splitpath($file);
    my @file_parts      = split( $self->{ext_sep}, $filename );
    my $filename_ext    = pop(@file_parts);
    my $filename_prefix = join( '.', @file_parts );
    my ( $curr_lang_file, $english_file );

    if ( $filename_ext eq 'jelly' ) {
        $curr_lang_file
            = $filename_prefix . '_' . $self->{language} . '.properties';
        $english_file = "$filename_prefix.properties";
    }
    elsif ( $filename_ext eq 'properties' ) {
        $curr_lang_file
            = $filename_prefix . '_' . $self->{language} . '.properties';
        $english_file = $filename;
    }
    else {
        confess "Unexpected file extension '$filename_ext' in $file";
    }

    my $english_file_path
        = File::Spec->catfile( $volume, $dirs, $english_file );

    if ( $self->{source_dir} eq $self->{target_dir} ) {
        return ( File::Spec->catfile( $volume, $dirs, $curr_lang_file ),
            $english_file_path );
    }

    $dirs =~ s/$self->{source_dir}/$self->{target_dir}/;

    return ( File::Spec->catfile( $volume, $dirs, $curr_lang_file ),
        $english_file_path );

}

1;
__END__

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 of Alceu Rodrigues de Freitas Junior,
E<lt>arfreitas@cpan.orgE<gt>

This file is part of Jenkins Translation Tool project.

Jenkins Translation Tool is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your option)
any later version.

Jenkins Translation Tool is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Jenkins Translation Tool. If not, see (http://www.gnu.org/licenses/).

The original C<translation-tool.pl> script was licensed through the MIT
License, copyright (c) 2004-, Kohsuke Kawaguchi, Sun Microsystems, Inc., and a
number of other of contributors. Translations files generated by the Jenkins
Translation Tool CLI are distributed with the same MIT License.

=cut
