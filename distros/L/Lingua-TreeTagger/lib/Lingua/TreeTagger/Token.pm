package Lingua::TreeTagger::Token;

use Moose;
use Carp;

our $VERSION = '0.01';


#===============================================================================
# Public attributes.
#===============================================================================

has 'tag'  => (
      is        => 'ro',
      isa       => 'Str',
      required  => 1,
);

has 'is_SGML_tag'  => (
      is        => 'ro',
      isa       => 'Bool',
      required  => 1,
);

has 'original'  => (
      is        => 'ro',
      isa       => 'Str',
      lazy      => 1,
      default   => undef,
      trigger   => sub {
          my $self = shift;
          croak "An SGML tag cannot have a 'original' attribute"
            if $self->is_SGML_tag();
      }
);

has 'lemma'  => (
      is        => 'ro',
      isa       => 'Str',
      lazy      => 1,
      default   => undef,
      trigger   => sub {
          my $self = shift;
          croak "An SGML tag cannot have a 'lemma' attribute"
            if $self->is_SGML_tag();
      }
);


#===============================================================================
# Standard Moose cleanup.
#===============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

Lingua::TreeTagger::Token - Representing a token tagged by TreeTagger.

=head1 VERSION

This documentation refers to Lingua::TreeTagger::Token version 0.01.

=head1 SYNOPSIS

    use Lingua::TreeTagger;

    # Create a Tagger object.
    my $tagger = Lingua::TreeTagger->new(
        'language' => 'english',
    );

    # Tag some text and get a new TaggedText object.
    my $tagged_text = $tagger->tag_file( 'path/to/some/file.txt' );

    # A TaggedText object is essentially a sequence of Lingua::TreeTagger::Token
    # objects.
    foreach my $token ( @{ $tagged_text->sequence() } ) {

        # A token may contain a single SGML tag...
        if ( $token->is_SGML_tag() ) {
            print 'An SGML tag: ', $token->tag, "\n";
        }

        # ... or a part-of-speech tag.
        else {
            print 'A part-of-speech tag: ', $token->tag, "\n";
            
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

This module is part of the Lingua::TreeTagger distribution. It defines a class
for representing a unit in the output of TreeTagger in an object-oriented way.
Such a unit consists in either (i) exactly one part-of-speech tag and possibly
a token and a lemma (tab-delimited) or (ii) an SGML tag. See also
L<Lingua::TreeTagger> and L<Lingua::TreeTagger:TaggedText>.

=head1 METHODS

=over 4

=item C<new()>

Creates a new Token object. This is normally called by a
Lingua::TreeTagger::TaggedText object rather than directly by the user. It
requires two parameters:

=over 4

=item C<tag>

A string containing either a part-of-speech tag or an SGML tag.

=item C<is_SGML_tag>

1 if the value of the C<tag> attribute is to be interpreted as an SGML tag,
0 otherwise.

=back

If the <is_SGML_tag> attribute is set to 0, the constructor may take two
additional optional parameters:

=over 4

=item C<original>

A string containing the original token to which the part-of-speech tag has been
attributed.

=item C<lemma>

A string containing the lemma of the original token.

=back

=back

=head1 ACCESSORS

=over 4

=item C<tag()>

Read-only accessor for the 'tag' attribute of a token (either a TreeTagger
part-of-speech tag or an SGML tag).

=item C<is_SGML_tag()>

Read-only accessor for the 'is_SGML_tag' attribute of a token (value is C<1> if
the tag is an SGML tag and C<0> otherwise).

=item C<original()>

Read-only accessor for the 'original' attribute of a token, i.e. the original
word token to which a given part-of-speech tag was assigned. Available only if
the value of 'is_SGML_tag' is C<0>.

=item C<lemma()>

Read-only accessor for the 'lemma' attribute of a token, i.e. the base form of
the original word token to which a given part-of-speech tag was assigned.
Available only if the value of 'is_SGML_tag' is C<0>.

=back

=head1 DIAGNOSTICS

=over 4

=item An SGML tag cannot have a 'original' attribute

This exception is raised by the class constructor when a new Token object is
simultaneously specified as being an SGML tag and having a 'original'
attribute.

=item An SGML tag cannot have a 'lemma' attribute

This exception is raised by the class constructor when a new Token object is
simultaneously specified as being an SGML tag and having a 'lemma'
attribute.

=back

=head1 DEPENDENCIES

This module is part of the Lingua::TreeTagger distribution. It is not intended
to be used as an independent module.

It requires module Moose and was developed using version 1.09. Please
report incompatibilities with earlier versions to the author.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Aris Xanthos (aris.xanthos@unil.ch)

Patches are welcome.

=head1 AUTHOR

Aris Xanthos  (aris.xanthos@unil.ch)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Aris Xanthos (aris.xanthos@unil.ch).

This program is released under the GPL license (see
L<http://www.gnu.org/licenses/gpl.html>).

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Lingua::TreeTagger>, L<Lingua::TreeTagger::TaggedText>


