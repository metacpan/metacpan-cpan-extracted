package File::SOPS::Comment;
# ABSTRACT: the leaf a sops comment becomes -- not a value, and not a string
our $VERSION = '0.004';
use Moo;
use Carp qw(croak);
use namespace::clean;

###############################################################################
# The comment leaf (k76, docs/adr/0041)
#
# sops attaches a comment to the node that FOLLOWS it. Above a mapping key that
# stays a `#ENC[...,type:comment]` line, which YAML::XS drops before this
# distribution sees a tree; above a SEQUENCE entry there is no comment line to
# write, so sops emits the comment as a sequence ENTRY of its own -- in YAML and,
# measured, in `--output-type json` as well.
#
# That entry needs a Perl value that cannot be mistaken for a string, or reading
# it puts a value in the caller's list that the file does not contain and a
# re-encrypt makes it permanent (k108). This is that value, and it is the
# same move type:bool already makes with JSON::PP::Boolean.
#
# NO OVERLOADED STRINGIFICATION, deliberately. An object that compares equal to
# a string slips through every `eq` in this distribution, which is how a comment
# became a value in the first place; and detect_type would then have two ways to
# answer for the same leaf. ->text is the way to the text.
#
# This module knows nothing about the wire and loads nothing from this
# distribution -- File::SOPS::Encrypted loads IT, which is the direction that
# has to hold: the ladder produces the type from this class and
# _deserialize_value produces the class from the type, and neither can be
# reached from here. k147 moved it out of File/SOPS/Encrypted.pm, where
# ADR 0041 first put it, without renaming it.
###############################################################################


has text => (is => 'ro', required => 1);

# required => 1 covers only the missing case. The reference and the empty
# string are both defined, so they satisfy `required` and have to be refused
# here, once the attribute is set -- BUILD runs after that. The messages are
# the ones the hand-written constructor raised before this class became Moo
# (docs/adr/0068); t/56 reads the empty-string one.
sub BUILD {
    my ($self) = @_;
    my $text = $self->text;

    croak "a comment's text is a string, not a " . ref($text) . " reference"
        if ref $text;

    # Measured against sops 3.13.3: a bare `#` above a sequence entry is
    # written as an UNENCRYPTED empty string element (`- ""`) and no comment
    # leaf at all, so type:comment never carries an empty plaintext. Refused
    # here rather than three layers down in encrypt_value, whose message is
    # about GCM ciphertext length and says nothing about comments.
    croak "a comment's text cannot be empty: AES-GCM ciphertext is the length "
        . "of its plaintext, so there is no ENC[...] to write -- and sops "
        . "itself writes an empty comment as an empty string element rather "
        . "than as a comment"
        unless length $text;

    return;
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::SOPS::Comment - the leaf a sops comment becomes -- not a value, and not a string

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use File::SOPS::Comment;

    my $comment = File::SOPS::Comment->new(text => ' a comment');
    $comment->text;   # => ' a comment'

    # A comment in a list is what a decrypted document hands back
    my $data = File::SOPS->decrypt(
        encrypted  => $yaml,
        identities => [$identity],
    );
    # $data->{list}[0] is a File::SOPS::Comment, $data->{list}[1] a string

=head1 DESCRIPTION

C<File::SOPS::Comment> is the Perl representation of SOPS's C<type:comment>: a
leaf that is B<not a value>. sops attaches a comment to the node that follows
it, and where that node is a sequence entry it has nowhere to put a comment
line, so it writes the comment as a sequence entry of its own:

    list:
        - ENC[AES256_GCM,...,type:comment]
        - ENC[AES256_GCM,...,type:str]

This class is what such an entry becomes on the way in, and what produces one on
the way out. It holds the comment's text and nothing else.

B<It is an object rather than a string on purpose>, and it is the same move
C<type:bool> makes with L<JSON::PP::Boolean>: a wire type that is not a string
gets a Perl value that cannot be mistaken for one. Read as a string, a comment
is an extra element in the caller's list that the file does not contain, and a
C<decrypt> plus C<encrypt> cycle makes it permanent with every party reporting
success -- which is the defect (k108) this class exists to close.

=over 4

=item * L<File::SOPS::Encrypted/detect_type> answers C<comment> for it, and
L<File::SOPS::Encrypted/value_to_bytes> writes its text as UTF-8 bytes,
verbatim -- the same treatment a string gets.

=item * L<File::SOPS::Encrypted/decrypt_value> builds one for every
C<type:comment> leaf, so a tree handed back by L<File::SOPS/decrypt> holds
objects where the document holds comments.

=item * It is B<excluded from the MAC digest>, because sops excludes it --
measured four ways, in both MAC modes.

=item * L</text> is everything after the C<#>, B<leading space included>, which
is what the plaintext holds. It is never empty: sops writes a bare C<#> as an
empty string element instead.

=back

There is deliberately B<no overloaded stringification>: a comment that compares
equal to a string is how one became a value in the first place. L</text> is the
way to the text.

Callers do not have to load this module to receive one --
L<File::SOPS::Encrypted> loads it, and the dependency runs only that way. Load
it to B<build> one.

See L<docs/adr/0041|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0041-a-sops-comment-is-a-leaf-of-its-own-not-a-value-and-not-a-refusal.md>.

=head2 new

    my $comment = File::SOPS::Comment->new(text => ' a comment');

Builds a comment leaf from its C<text>, which is everything sops puts after the
C<#>, B<leading space included>. The text is a character string and is encoded
on the way to the wire like every other string (docs/adr/0003); Perl's UTF-8
flag is not consulted here or there.

Croaks on the three inputs that are not a comment: a missing C<text>, a
reference, and an B<empty> string. The last one is not a strictness of this
distribution's own -- measured against sops 3.13.3, a bare C<#> above a
sequence entry is written as an unencrypted empty string element (C<- "">) and
no comment leaf at all, so C<type:comment> never carries an empty plaintext and
AES-GCM has no ciphertext for one either.

=head2 text

    $comment->text;   # => ' a comment'

The comment's text, verbatim, as a character string. This is the only way to
it: the class deliberately does not overload stringification.

=head1 SEE ALSO

=over 4

=item * L<File::SOPS::Encrypted> - the type ladder that produces this class and
the conversion that writes it

=item * L<File::SOPS> - the tree a decrypted document hands back, and where a
comment may sit in one

=item * docs/adr/0041 - why a comment is a leaf of its own, measured against
sops 3.13.3

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-file-sops/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
