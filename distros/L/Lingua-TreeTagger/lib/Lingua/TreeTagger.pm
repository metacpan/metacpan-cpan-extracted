package Lingua::TreeTagger;

use Moose;
use Moose::Util::TypeConstraints;
use Path::Class;
use File::Temp;
use Carp;

use Lingua::TreeTagger::TaggedText;
use Lingua::TreeTagger::ConfigData;

our $VERSION = '0.08';


#===============================================================================
# Initialization.
#===============================================================================

our $_treetagger_lib_path
    = dir( Lingua::TreeTagger::ConfigData->config( 'treetagger_lib_path' ) );

our $_treetagger_prog_path
    = file( Lingua::TreeTagger::ConfigData->config( 'treetagger_prog_path' ) );

our $_tokenizer_prog_path
    = file( Lingua::TreeTagger::ConfigData->config( 'tokenizer_prog_path' ) );


#===============================================================================
# Subtype definitions.
#===============================================================================

# This is the list of supported TreeTagger options. It includes only those
# options that work as flags and it excludes some flags that are used for other
# purposes than part-of-speech tagging. Note that option '-quiet' is always
# selected.

enum 'treetagger_option' => [ qw(
    -token              -lemma              -sgml               -ignore-prefix
    -no-unknown         -cap-heuristics     -hyphen-heuristics  -pt-with-lemma
    -pt-with-prob       -base
) ];


#===============================================================================
# Public attributes.
#===============================================================================

has 'tokenizer' => (
      is        => 'ro',
      isa       => 'CodeRef',
);

has 'language'  => (
      is        => 'ro',
      isa       => 'Str',
      required  => 1,
      trigger   => \&_validate_language,
);

has 'use_utf8'  => (
      is        => 'ro',
      isa       => 'Bool',
      default   => undef,
      trigger   => \&_setup_utf8,
);

has 'options'   => (
      is        => 'ro',
      isa       => 'ArrayRef[treetagger_option]',
      default   => sub { [ qw( -token -lemma ) ] },
);


#===============================================================================
# Private attributes.
#===============================================================================

has '_parameter_file' => (
      is        => 'ro',
      isa       => 'Path::Class::File',
      lazy      => 1,
      default   => sub {
          my $self = shift;
          my $paramfile = $self->language();
          $paramfile .= $self->use_utf8 ? '-utf8' : '';
          return file( $_treetagger_lib_path, $paramfile . '.par' );
      }
);

has '_abbreviation_file' => (
      is        => 'ro',
      isa       => 'Path::Class::File',
      lazy      => 1,
      default   => sub {
          my $self = shift;
          my $abbrfile = $self->language() . '-abbreviations';
          $abbrfile .= $self->use_utf8 ? '-utf8' : '';
          return file( $_treetagger_lib_path, $abbrfile );
      }
);


#===============================================================================
# Public instance methods.
#===============================================================================

#-------------------------------------------------------------------------------
# Method tag_file
#-------------------------------------------------------------------------------
# Synopsis:      Tokenizes and tags a file's content.
# Arguments:     A string containing the file's path.
# Return values: A TaggedText object.
#-------------------------------------------------------------------------------

sub tag_file {
    my ( $self, $path ) = @_;

    # Path argument is required.
    croak 'Method tag_file requires a path argument' if ! defined $path;

    # Get file path.
    my $file = file( $path )->absolute();

    # If using default tokenizer...
    if ( ! defined $self->tokenizer() ) {

        # Tokenize and tag text, return the result as a new TaggedText object.
        return $self->_tag_with_default_tokenizer( $file );
    }

    # Else if using custom tokenizer...
    else {

        # Get the content of the file.
        my $content = $file->slurp();

        # Tokenize and tag text, return the result as a new TaggedText object.
        return $self->_tag_with_custom_tokenizer( \$content );
    }
}


#-------------------------------------------------------------------------------
# Method tag_text
#-------------------------------------------------------------------------------
# Synopsis:      Tokenizes and tags the text contained in a string.
# Arguments:     A string containing the text to be tagged.
# Return values: A TaggedText object.
#-------------------------------------------------------------------------------

sub tag_text {
    my ( $self, $text_ref ) = @_;

    # Text argument is required.
    croak 'Method tag_text requires a string reference as argument'
        if ! defined $text_ref;

    # If using default tokenizer...
    if ( ! defined $self->tokenizer() ) {

        # Save the text in a temporary file.
        my $temp_file_handle = File::Temp->new();
        if( $self->use_utf8 ) {
            binmode( $temp_file_handle, ':encoding(UTF-8)' );
        }
        print $temp_file_handle $$text_ref;
        
        # Tokenize and tag text, return the result as a new TaggedText object.
        return $self->_tag_with_default_tokenizer(
            $temp_file_handle->filename()
        );
    }

    # Else if using custom tokenizer...
    else {

        # Tokenize and tag text, return the result as a new TaggedText object.
        return $self->_tag_with_custom_tokenizer( $text_ref );
    }
}


#===============================================================================
# Private class methods.
#===============================================================================

#-------------------------------------------------------------------------------
# Method _run_treetagger
#-------------------------------------------------------------------------------
# Synopsis:      Run TreeTagger according to a command whose elements are
#                passed as an array, and returns a reference to an array of
#                tagged lines.
# Arguments:     An array containing the elements of the command.
# Return values: A reference to an array containing tagged lines.
#-------------------------------------------------------------------------------

sub _run_treetagger {
    my ( $self, @command_array ) = @_;

    my $command_output_handle;

    # Compose the command string and execute it.
    my $process = open(
        $command_output_handle,
        '-|',
        join q{ }, @command_array
    ) || croak "Couldn't fork: $!\n";

    # Get the result and close the command output handle.
    if( $self->use_utf8 ) {
        binmode( $command_output_handle, ':encoding(UTF-8)' );
    }
    my @tagged_lines = <$command_output_handle>;
    close $command_output_handle;

    # Wait for the child process to terminate.
    waitpid $process, 0;
    
    return \@tagged_lines;
}


#-------------------------------------------------------------------------------
# Method _quote
#-------------------------------------------------------------------------------
# Synopsis:      Adds quotes around a string, OS-wise.
# Arguments:     A string.
# Return values: A string (with quotes added).
#-------------------------------------------------------------------------------

sub _quote {
    my ( $string ) = @_;

    my $_quote = do { $^O eq 'MSWin32' ? q{"} : q{'} };

    return $_quote . $string . $_quote;
}


#===============================================================================
# Private instance methods.
#===============================================================================

#-------------------------------------------------------------------------------
# Method _validate_language
#-------------------------------------------------------------------------------
# Synopsis:      Checks and possibly modifies the language attribute.
# Arguments:     A string containing the value of the language attribute.
# Return values: None.
#-------------------------------------------------------------------------------

sub _validate_language {
    my ( $self, $language ) = @_;

    # Convert language to lowercase (bypassing the accessor because the
    # attribute is defined as read-only!!).
    $self->{ 'language' } = lc( $language );

    # Die if there's no parameter file for this language.
    croak 'There is no parameter file for language ' . $self->language()
        if ! -e $self->_parameter_file();

    return;
}


#-------------------------------------------------------------------------------
# Method _setup_utf8
#-------------------------------------------------------------------------------
# Synopsis:      Changes the default tokenizer based on the use_utf8 attribute.
# Arguments:     A string containing the value of the use_utf8 attribute.
# Return values: None.
#-------------------------------------------------------------------------------

sub _setup_utf8 {
    my ( $self, $use_utf8 ) = @_;
    # Change the default tokenizer program path to the UTF-8 version
    # if necessary.
    if ( $use_utf8 && $_tokenizer_prog_path->basename eq 'tokenize.pl' ) {
        my $utf8_tokenizer = file(
            $_tokenizer_prog_path->dir, 'utf8-tokenize.perl'
        );
        $_tokenizer_prog_path = $utf8_tokenizer;
    }
}


#-------------------------------------------------------------------------------
# Method _tag_with_default_tokenizer
#-------------------------------------------------------------------------------
# Synopsis:      Tokenizes a file's content with TreeTagger's default tokenizer
#                and tags its content.
# Arguments:     A Path::Class::File object.
# Return values: A TaggedText object.
#-------------------------------------------------------------------------------

sub _tag_with_default_tokenizer {
    my ( $self, $path ) = @_;

    # Check if file exists...
    croak "File $path not found" if ! -e "$path";

    my ( $language_option, $abbreviation_file_option ) = ( q{}, q{} );

    # If there are special rules for clitics in this language...
    if (
           $self->language() eq 'english'
        || $self->language() eq 'french'
        || $self->language() eq 'italian'
    ) {
        # Set the tokenizer's language option.
        $language_option = q{-} . substr( $self->language(), 0, 1 )
    }

    # If there is an abbreviation file for this language...
    if ( -e $self->_abbreviation_file() ) {

        # Set the tokenizer's abbreviation file option.
        $abbreviation_file_option =
            q{-a } . _quote( $self->_abbreviation_file() );
    }

    # Push command elements into a list to be joined later.
    my @command_array = (
        'perl',
        _quote( $_tokenizer_prog_path ),
        $language_option,
        $abbreviation_file_option,
        _quote( $path ),
        '|',
        _quote( $_treetagger_prog_path ),
        @{ $self->options() },
        '-quiet',
        _quote( $self->_parameter_file() ),
    );

    # Execute the command (i.e. tag).
    my $tagged_lines_ref = $self->_run_treetagger( @command_array );

    return Lingua::TreeTagger::TaggedText->new( $tagged_lines_ref, $self );
}


#-------------------------------------------------------------------------------
# Method _tag_with_custom_tokenizer
#-------------------------------------------------------------------------------
# Synopsis:      Tokenizes the content of a string with a custom subroutine
#                provided by the user, and tags this text.
# Arguments:     A reference to a string.
# Return values: A TaggedText object.
#-------------------------------------------------------------------------------

sub _tag_with_custom_tokenizer {
    my ( $self, $text_ref ) = @_;

    # Apply the custom tokenizer and save the result in a temporary file...
    my $tokenized_text_ref = $self->tokenizer()->( $text_ref );
    my $temp_file_handle   = File::Temp->new();
    print $temp_file_handle $$tokenized_text_ref;

    # Push command elements into a list to be joined later.
    my @command_array = (
        _quote( $_treetagger_prog_path ),
        @{ $self->options() },
        '-quiet',
        _quote( $self->_parameter_file() ),
        _quote( $temp_file_handle->filename() ),
    );

    # Execute the command (i.e. tag).
    my $tagged_lines_ref = $self->_run_treetagger( @command_array );

    return Lingua::TreeTagger::TaggedText->new( $tagged_lines_ref, $self );
}


#===============================================================================
# Standard Moose cleanup.
#===============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=encoding ISO8859-1

=head1 NAME

Lingua::TreeTagger - Using TreeTagger from Perl

=head1 VERSION

This documentation refers to Lingua::TreeTagger version 0.04.

=head1 SYNOPSIS

    use Lingua::TreeTagger;

    # Create a Tagger object.
    my $tagger = Lingua::TreeTagger->new(
        'language' => 'english',
        'options'  => [ qw( -token -lemma -no-unknown ) ],
    );

    # The tagger's input text can be stored in a string (passed by reference)...
    my $text_to_tag = 'Yet another sample text.';
    my $tagged_text = $tagger->tag_text( \$text_to_tag );

    # ... or in a file.
    my $file_path = 'path/to/some/file.txt';
    $tagged_text = $tagger->tag_file( $file_path );

    # Both methods return a Lingua::TreeTagger::TaggedText object, i.e. a
    # sequence of Lingua::TreeTagger::Token objects, which can be stringified
    # as raw text...
    print $tagged_text->as_text();

    # ... or in XML format.
    print $tagged_text->as_XML();

    # Token objects may be accessed directly for more specific purposes.
    foreach my $token ( @{ $tagged_text->sequence() } ) {

        # A token may contain a single SGML tag...
        if ( $token->is_SGML_tag() ) {
            print 'An SGML tag: ', $token->tag(), "\n";
        }

        # ... or a part-of-speech tag.
        else {
            print 'A part-of-speech tag: ', $token->tag(), "\n";

            # In the latter case, the token may also have attributes specifying
            # the original string...
            if ( defined $token->original() ) {
                print '  token: ', $token->original(), "\n";
            }

            # ... or the corresponding lemma.
            if ( defined $token->lemma() ) {
                print '  lemma: ', $token->lemma(), "\n";
            }
        }
    }

=head1 DESCRIPTION

This Perl module provides a simple object-oriented interface to the TreeTagger
part-of-speech tagger created by Helmut Schmid. See also
L<Lingua::TreeTagger::TaggedText> and L<Lingua::TreeTagger::Token>.

=head1 METHODS

=over 4

=item C<new()>

Creates a new Tagger object. One named parameter is required:

=over 4

=item C<language>

A (lowercase) string specifying the language that the tagger object will have
to cope with (e.g. 'english', 'french', 'german', and so on). Note that the
corresponding TreeTagger parameter files have to be installed by the user.

=back

Three optional named parameters may be passed to the constructor:

=over 4

=item C<use_utf8>

A boolean flag indicating that the utf-8 version of the parameter file should
be used. This also enables use of Unicode strings internally, use of the utf8
tokenizer by default, and use of the utf8 abbreviations file (if present) for
tokenization.

=item C<options>

A reference to a list of options to be passed to TreeTagger. Note that this
module supports only those options that work as flags (e.g. '-token' or
'-lemma') and it excludes some flags that are used for other purposes than
part-of-speech tagging (e.g. '-proto' or '-print-prob-tree').

At present, the full list of supported options is the following (see the
documentation of TreeTagger for details):

    -token              -lemma              -sgml               -ignore-prefix
    -no-unknown         -cap-heuristics     -hyphen-heuristics  -pt-with-lemma
    -pt-with-prob       -base

The list of options defaults to '-token' and '-lemma'.

=item C<tokenizer>

A reference to a subroutine for tokenizing the input text. This subroutine must
take a reference to a string as argument and return a reference to the tokenized
string, where each line contains a distinct token. Here is a simple example of
such a subroutine:

    sub my_tokenizer {
        my ( $original_text_ref ) = @_;
        my @tokens = split /\s+/, $$original_text_ref;
        my $tokenized_text = join "\n", @tokens;
        return \$tokenized_text;
    }

=back

=item C<tag_file()>

Tokenizes and tags the textual content of a file. It requires only one argument,
namely the path to the file, e.g. a string such as 'path/to/some/file.txt'. The
method returns a C<Lingua::TreeTagger::TaggedText> object.

=item C<tag_text()>

Tokenizes and tags the text contained in a string. It requires only one
argument, namely a reference to the string to be tagged. The method returns
a C<Lingua::TreeTagger::TaggedText> object.

=back

=head1 ACCESSORS

=over 4

=item C<language()>

Read-only accessor for the 'language' attribute of a TreeTagger object.

=item C<options()>

Read-only accessor for the 'options' attribute of a TreeTagger object, i.e.
a reference to the list of options it uses.

=item C<tokenizer()>

Read-only accessor for the 'tokenizer' attribute of a TreeTagger object, i.e.
a reference to the custom tokenizer subroutine it uses (if any).

=back

=head1 DIAGNOSTICS

=over 4

=item There is no parameter file for language ...

This exception is raised by the class constructor when attempting to create a
new TreeTagger object with a 'language' attribute for which no parameter file
is installed in TreeTagger's C</lib> directory.

=item Method tag_file requires a path argument

This exception is raised when method L<tag_file()> is called without specifying
a path argument.

=item Method tag_text requires a string reference as argument

This exception is raised when method L<tag_text()> is called without providing
a string reference as argument.

=item Couldn't fork: ...

This exception is raised by methods L<tag_file()> and L<tag_text()> when they
fail to create a child process for executing the TreeTagger program.

=item File ... not found

This exception is raised when method L<tag_file()> is called with a path
argument corresponding to a file that does not exist.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Installing and using this module requires a working version of TreeTagger
(available at L<http://www.ims.uni-stuttgart.de/projekte/corplex/TreeTagger>).
Windows users are advised to follow the installation instructions given on page
L<http://www.smo.uhi.ac.uk/~oduibhin/oideasra/interfaces/winttinterface.htm>.
There is also a L<Lingua::TreeTagger::Installer> module created by Alberto 
Simões (this distribution is not directly related to the present
one).

The particular set of TreeTagger parameter files installed on the user's
machine determines the set of languages that can by used by this module. Note
that the parameter file for English must be installed for the successful
execution of the distribution tests.

During the installation procedure, the user is prompted for the path to
TreeTagger's base directory (e.g. C<C:\Program Files\TreeTagger>), which is
used for testing and saved for later use in module
Lingua::TreeTagger::ConfigData.

=head1 DEPENDENCIES

This is the base module of the Lingua::TreeTagger distribution. It uses modules
L<Lingua::TreeTagger::TaggedText> (version 0.01), L<Lingua::TreeTagger::Token>
(version 0.01), and Lingua::TreeTagger::ConfigData (automatically generated
during the installation procedure).

This module requires module Moose and was developed using version 1.09.
Please report incompatibilities with earlier versions to the author.

Also required are modules L<File::Temp> (version 0.19 or later) and
L<Path::Class> (version 0.19 was used for development, please report
incompatibilies with earlier versions).

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Aris Xanthos (aris.xanthos@unil.ch)

Patches are welcome.

In the current version, the L<options()> accessor is read-only, which implies
that a new TreeTagger object must be created whenever a change in the set of
options is needed (see L<Lingua::TreeTagger::TaggedText/"BUGS AND LIMITATIONS">).
This can be expected to change in a future version.

This module attempts to provide a user-friendly object-oriented interface to
TreeTagger, but it is seriously limited from the point of view of performance.
Each call to methods L<tag_text()> and L<tag_file()> translates into a new
execution of the TreeTagger program, which entails a considerable time most
probably devoted to the program's initialization.

If performance is critical, there are essentially three available options: (i)
reduce the number of calls to L<tag_text()> and L<tag_file()> by buffering a
larger amount of text to tag, (ii) try the L<Alvis::TreeTagger> module (which
does not seem to work on Windows), or (iii) help the author find out how to use
a module such as L<IPC::Open2> to open a permanent two-ways communication
channel between this module and the TreeTagger executable.

=head1 ACKNOWLEDGEMENTS

The author is grateful to Alberto Simões, Christelle Cocco, Yannis
Haralambous, and Andrew Zappella for their useful feedback.

Also a warm thank you to Tara Andrews who provided a patch for adding unicode
support to the module, as well as Zoffix Znet and Hiroyuki Yamanaka, who
provided patches for fixing a bug related to a modification of the Moose
dependency.

=head1 AUTHOR

Aris Xanthos  (aris.xanthos@unil.ch)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2014 Aris Xanthos (aris.xanthos@unil.ch).

This program is released under the GPL license (see
L<http://www.gnu.org/licenses/gpl.html>).

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Lingua::TreeTagger::TaggedText>, L<Lingua::TreeTagger::Token>


