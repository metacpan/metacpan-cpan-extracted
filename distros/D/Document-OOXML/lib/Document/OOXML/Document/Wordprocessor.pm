use utf8;
package Document::OOXML::Document::Wordprocessor;
use Moose;

extends 'Document::OOXML::Document';

# ABSTRACT: Wordprocessor file (".docx")



has '+document_part' => (
    handles => [qw(
        remove_spellcheck_markers
        merge_runs
        find_text_nodes
        style_text
        replace_text
        extract_words
    )],
);

__PACKAGE__->meta->make_immutable();

__END__

=pod

=encoding UTF-8

=head1 NAME

Document::OOXML::Document::Wordprocessor - Wordprocessor file (".docx")

=head1 VERSION

version 0.180750

=head1 DESCRIPTION

This class represents a "wordprocessor" file in OOXML format (usually, these
have the extension .docx).

It will be returned by L<Document::OOXML> when reading a document with a
WordprocessingML main document part.

=head1 METHODS

=head2 remove_spellcheck_markers

Remove spellcheck markers (C<< <w:proofErr> >>) from the document.

=head2 merge_runs

Merge the content of identical adjacent runs (C<< <w:r> >> elements).

This is done internally to make finding and replacing text easy/possible.

=head2 find_text_nodes(qr/text/)

Finds C<< w:t >> nodes matching a specified regular expression, splits
the run around the match, and returns the matching parts.

The regular expression should not contain capture groups, as this
will mess with the text run splitting.

=head2 replace_text($search, $replace)

Finds all occurrences of C<$search> in the text of the document, and
replaces them with C<$replace>.

=head1 SEE ALSO

=over

=item * L<Document::OOXML>

=item * L<Document::OOXML::Part::WordprocessingML>

=back

=head1 AUTHOR

Martijn van de Streek <martijn@vandestreek.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Martijn van de Streek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
