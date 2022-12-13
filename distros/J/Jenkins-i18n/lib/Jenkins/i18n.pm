package Jenkins::i18n;

use 5.014004;
use strict;
use warnings;
use Carp qw(confess);
use File::Find;
use File::Spec;
use Set::Tiny;

use Jenkins::i18n::Properties;
use Jenkins::i18n::FindResults;
use Jenkins::i18n::Assertions qw(is_jelly_file has_empty);

=pod

=head1 NAME

Jenkins::i18n - functions for the jtt CLI

=head1 SYNOPSIS

    use Jenkins::i18n qw(remove_unused find_files load_properties load_jelly find_langs);

=head1 DESCRIPTION

C<jtt> is a CLI program used to help translating the Jenkins properties file.

This module implements some of the functions used by the CLI.

=cut

use Exporter 'import';
our @EXPORT_OK = (
    'remove_unused', 'find_files', 'load_properties', 'load_jelly',
    'find_langs',    'all_data',   'dump_keys',       'merge_data',
    'find_missing'
);

our $VERSION = '0.10';

=head1 EXPORT

None by default.

=head1 FUNCTIONS

=head2 find_missing

Compares the keys available from the source (Jelly and/or Properties files)
with the i18n file and updates the statistics based on the B<missing keys>,
i.e., the keys that exists in the source but not in the i18n Properties file.

Expects as parameters the following:

=over

=item 1.

a hash reference with all the keys/values from the Jelly/Properties file.

=item 2.

a hash reference with all the keys/values from the i18n Properties file.

=item 3.

a instance of a L<Jenkins::i18n::Stats> class.

=item 4.

a instance of L<Jenkins::i18n::Warnings> class.

=back

=cut

sub find_missing {
    my ( $source_ref, $i18n_ref, $stats, $warnings ) = @_;

    foreach my $entry ( keys %{$source_ref} ) {
        $stats->add_key($entry);

        # TODO: skip increasing missing if operation is to delete those
        unless (( exists( $i18n_ref->{$entry} ) )
            and ( defined( $i18n_ref->{$entry} ) ) )
        {
            $stats->inc_missing;
            $warnings->add( 'missing', $entry );
            next;
        }

        if ( $i18n_ref->{$entry} eq '' ) {
            unless ( has_empty($entry) ) {
                $stats->inc('empty');
                $warnings->add( 'empty', $entry );
            }
            else {
                $warnings->add( 'ignored', $entry );
            }
        }
    }
}

=head2 merge_data

Merges the translation data from a Jelly file and a Properties file.

Expects as parameters:

=over

=item 1.

A hash reference with all the keys/values from a Jelly file.

=item 2.

A hash reference with all the keys/values from a Properties file.

=back

This methods considers the way Jenkins is translated nowadays, considering
different scenarios where the Jelly and Properties have different data.

Returns a hash reference with the keys and values merged.

=cut

sub merge_data {
    my ( $jelly_ref, $properties_ref ) = @_;
    confess('A hash reference of the Jelly keys is required')
        unless ($jelly_ref);
    confess('The Jelly type is invalid') unless ( ref($jelly_ref) eq 'HASH' );
    confess('A hash reference of the Properties keys is required')
        unless ($properties_ref);
    confess('The Properties type is invalid')
        unless ( ref($properties_ref) eq 'HASH' );
    my %merged;

    if ( scalar( keys( %{$jelly_ref} ) ) == 0 ) {
        return $properties_ref;
    }

    foreach my $prop_key ( keys( %{$jelly_ref} ) ) {
        if ( exists( $properties_ref->{$prop_key} ) ) {
            $merged{$prop_key} = $properties_ref->{$prop_key};
        }
        else {
            $merged{$prop_key} = $prop_key;
        }
    }
    return \%merged;
}

=head2 dump_keys

Prints to C<STDOUT> all keys from a hash, using some formatting to make it
easier to read.

Expects as parameter a hash reference.

=cut

sub dump_keys {
    my $entries_ref = shift;
    foreach my $key ( keys( %{$entries_ref} ) ) {
        print "\t$key\n";
    }
}

=head2 all_data

Retrieves all translation data from a single given file as reference.

Expects as parameter a complete path to a file.

This file can be a Properties or Jelly file. From that file name, it will be
defined the related other files, by convention.

Returns a array reference, where each index is:

=over

=item 1.

A hash reference with all keys/values for the English language.

=item 2.

A hash reference with all the keys/values for the related language.

=item 3.

A hash reference for the keys retrieved from the respective Jelly file.

=back

Any of the return references may point to an empty hash, but at list the first
reference must point to a non-empty hash.

=cut

sub all_data {
    my ( $file, $processor ) = @_;
    print "#####\nWorking on $file\n" if ( $processor->is_debug );
    my ( $curr_lang_file, $english_file, $jelly_file )
        = $processor->define_files($file);

    if ( $processor->is_debug ) {
        print "For file $file:\n",
            "\tthe localization file is $curr_lang_file\n",
            "\tand the source is $english_file\n";
    }

   # entries_ref -> keys used in jelly or Message.properties files
   # lang_entries_ref -> keys/values in the desired language which are already
   # present in the file
    my ( $jelly_entries_ref, $lang_entries_ref, $english_entries_ref );

    if ( -f $jelly_file ) {
        $jelly_entries_ref = load_jelly($jelly_file);
    }
    else {
        $jelly_entries_ref = {};
    }

    $english_entries_ref
        = load_properties( $english_file, $processor->is_debug );
    $lang_entries_ref
        = load_properties( $curr_lang_file, $processor->is_debug );

    if ( $processor->is_debug ) {
        print "All keys retrieved from $jelly_file:\n";
        dump_keys($jelly_entries_ref);
        print "All keys retrieved from $english_file:\n";
        dump_keys($english_entries_ref);
        print "All keys retrieved from $curr_lang_file:\n";
        dump_keys($lang_entries_ref);
    }

    return ( $jelly_entries_ref, $lang_entries_ref, $english_entries_ref );
}

=head2 remove_unused

Remove unused keys from a properties file.

Each translation in every language depends on the original properties files
that are written in English.

This function gets a set of keys and compare with those that are stored in the
translation file: anything that exists outside the original set in English is
considered deprecated and so removed.

Expects as positional parameters:

=over

=item 1.

file: the complete path to the translation file to be checked.

=item 2.

keys: a L<Set::Tiny> instance of the keys from the original English properties
file.

=item 3.

license: a scalar reference with a license to include the header of the
translated properties file.

=item 4

backup: a boolean (0 or 1) if a backup file should be created in the same path
of the file parameter. Optional.

=back

Returns the number of keys removed (as an integer).

=cut

sub remove_unused {
    my $file = shift;
    confess "file is a required parameter\n" unless ( defined($file) );
    my $keys = shift;
    confess "keys is a required parameter\n" unless ( defined($keys) );
    confess "keys must be a Set::Tiny instance\n"
        unless ( ref($keys) eq 'Set::Tiny' );
    my $license_ref = shift;
    confess "license must be an array reference"
        unless ( ref($license_ref) eq 'ARRAY' );
    my $use_backup = shift;
    $use_backup = 0 unless ( defined($use_backup) );

    my $props_handler;

    if ($use_backup) {
        my $backup = "$file.bak";
        rename( $file, $backup )
            or confess "Cannot rename $file to $backup: $!\n";
        $props_handler = Jenkins::i18n::Properties->new( file => $backup );
    }
    else {
        $props_handler = Jenkins::i18n::Properties->new( file => $file );
    }

    my $curr_keys = Set::Tiny->new( $props_handler->propertyNames );
    my $to_delete = $curr_keys->difference($keys);

    foreach my $key ( $to_delete->members ) {
        $props_handler->deleteProperty($key);
    }

    open( my $out, '>', $file ) or confess "Cannot write to $file: $!\n";
    $props_handler->save( $out, $license_ref );
    close($out) or confess "Cannot save $file: $!\n";

    return $to_delete->size;
}

=head2 find_files

Find all Jelly and Java Properties files that could be translated from English,
i.e., files that do not have a ISO 639-1 standard language based code as a
filename prefix (before the file extension).

Expects as parameters:

=over

=item 1.

The complete path to a directory that might contain such files.

=item 2.

An instance of L<Set::Tiny> with all the languages codes identified. See
C<find_langs>.

=back

Returns an L<Jenkins::i18n::FindResults> instance.

=cut

# Relative paths inside the Jenkins project repository
my $src_test_path    = File::Spec->catfile( 'src',    'test' );
my $target_path      = File::Spec->catfile( 'target', '' );
my $src_regex        = qr/$src_test_path/;
my $target_regex     = qr/$target_path/;
my $msgs_regex       = qr/Messages\.properties$/;
my $jelly_regex      = qr/\.jelly$/;
my $properties_regex = qr/\.properties$/;

sub find_files {
    my ( $dir, $all_known_langs ) = @_;
    confess 'Must provide a string, invalid directory parameter'
        unless ($dir);
    confess 'Must provide a string as directory, not a reference'
        unless ( ref($dir) eq '' );
    confess "Directory '$dir' must exist" unless ( -d $dir );
    confess "Must receive a Set::Tiny instance for langs parameter"
        unless ( ref($all_known_langs) eq 'Set::Tiny' );

    my $country_code_length = 2;
    my $lang_code_length    = 2;
    my $min_file_pieces     = 2;
    my $under_regex         = qr/_/;
    my $result              = Jenkins::i18n::FindResults->new;
    $result->add_warning(
"Warning: ignoring the files at $src_test_path and $target_path paths."
    );

    find(
        sub {
            my $file = $File::Find::name;

            unless ( ( $file =~ $src_regex ) or ( $file =~ $target_regex ) ) {
                if (   ( $file =~ $msgs_regex )
                    or ( $file =~ $jelly_regex ) )
                {
                    $result->add_file($file);
                }
                else {

                    if ( $file =~ $properties_regex ) {
                        my $file_name = ( File::Spec->splitpath($file) )[-1];
                        $file_name =~ s/$properties_regex//;
                        my @pieces = split( $under_regex, $file_name );

                        # we must ignore a "_" at the beginning of the file
                        shift @pieces if ( $pieces[0] eq '' );

                        if ( scalar(@pieces) < $min_file_pieces ) {
                            $result->add_file($file);
                        }
                        else {
                            if (
                                    ( scalar(@pieces) == $min_file_pieces )
                                and
                                ( length( $pieces[-1] ) == $lang_code_length )
                                )
                            {
                                $result->add_warning("Ignoring $file")
                                    if (
                                    $all_known_langs->member( $pieces[-1] ) );
                            }
                            elsif (
                                ( scalar(@pieces) > $min_file_pieces )
                                and (
                                    length( $pieces[-1] )
                                    == $country_code_length )
                                and
                                ( length( $pieces[-2] ) == $lang_code_length )
                                )
                            {
                                $result->add_warning("Ignoring $file")
                                    if (
                                    $all_known_langs->member(
                                        $pieces[-2] . '_' . $pieces[-1]
                                    )
                                    );
                            }
                            else {
                                $result->add_file($file);
                            }
                        }
                    }
                }
            }
        },
        $dir
    );
    return $result;
}

my $regex = qr/_([a-z]{2})(_[A-Z]{2})?\.properties$/;

=head2 find_langs

Finds all ISO 639-1 standard language based codes available in the Jenkins
repository based on the filenames sufix (before the file extension) of the
translated files.

This is basically the opposite of C<find_files> does.

It expect as parameters the complete path to a directory to search for the
files.

Returns a instance of the L<Set::Tiny> class containing all the language codes
that were identified.

Find all files Jelly and Java Properties files that could be translated from
English, i.e., files that do not have a ISO 639-1 standard language based code
as a filename prefix (before the file extension).

=cut

sub find_langs {
    my $dir = shift;
    confess 'Must provide a string, invalid directory parameter'
        unless ($dir);
    confess 'Must provide a string as directory, not a reference'
        unless ( ref($dir) eq '' );
    confess "Directory '$dir' must exist" unless ( -d $dir );
    my $langs = Set::Tiny->new;

    find(
        sub {
            my $file = $File::Find::name;

            unless ( ( $file =~ $src_regex ) or ( $file =~ $target_regex ) ) {
                if ( $file =~ $regex ) {
                    my $lang;

                    if ($2) {
                        $lang = $1 . $2;
                    }
                    else {
                        $lang = $1;
                    }

                    $langs->insert($lang);
                }
            }
        },
        $dir
    );

    return $langs;
}

=head2 load_properties

Loads the content of a Java Properties file into a hash.

Expects as position parameters:

=over

=item 1

The complete path to a Java Properties file.

=item 2

True (1) or false (0) if a warn should be printed to C<STDERR> in case the file
is missing.

=back

Returns an hash reference with the file content. If the file doesn't exist,
returns an empty hash reference.

=cut

sub load_properties {
    my ( $file, $must_warn ) = @_;
    confess 'The complete path to the properties file is required'
        unless ($file);
    confess 'Must pass if a warning is required or not'
        unless ( defined($must_warn) );

    unless ( -f $file ) {
        warn "File $file doesn't exist, skipping it...\n" if ($must_warn);
        return {};
    }

    my $props_handler = Jenkins::i18n::Properties->new( file => $file );
    return $props_handler->getProperties;
}

=head2 load_jelly

Fill a hash with key/1 pairs from a C<.jelly> file.

Expects as parameter the path to a Jelly file.

Returns a hash reference.

=cut

# TODO: replace regex with XML parser
sub load_jelly {
    my $file = shift;
    my %ret;

    open( my $fh, '<', $file ) or confess "Cannot read $file: $!\n";

    while (<$fh>) {
        next if ( !/\$\{.*?\%([^\(]+?).*\}/ );
        my $line = $_;
        while ($line =~ /^.*?\$\{\%([^\(\}]+)(.*)$/
            || $line =~ /^.*?\$\{.*?['"]\%([^\(\}\"\']+)(.*)$/ )
        {
            $line = $2;
            my $word = $1;
            $word =~ s/\(.+$//g;
            $word =~ s/'+/''/g;
            $word =~ s/ /\\ /g;
            $word =~ s/\&gt;/>/g;
            $word =~ s/\&lt;/</g;
            $word =~ s/\&amp;/&/g;
            $word =~ s/([#:=])/\\$1/g;
            $ret{$word} = 1;
        }
    }

    close($fh);
    return \%ret;
}

1;

__END__


=head1 SEE ALSO

=over

=item *

L<Jenkins::i18n::Properties>

=item *

L<Set::Tiny>

=back

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
