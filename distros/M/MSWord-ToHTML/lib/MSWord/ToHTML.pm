package MSWord::ToHTML;
{
  $MSWord::ToHTML::VERSION = '0.010';
}

use Moose;
use namespace::autoclean;
use strictures 1;
use MooseX::Method::Signatures;
use MSWord::ToHTML::Types::Library qw/:all/;
use Carp;
use MSWord::ToHTML::Doc;
use MSWord::ToHTML::DocX;
use Try::Tiny;

# ABSTRACT: Take old or new Word files and spit out superclean HTML

method validate_file( MyFile $file does coerce ) {
    try {
        if ("$file" =~ /doc$/) {
            return MSWord::ToHTML::Doc->new(file => $file) if is_MSDoc($file);
            return MSWord::ToHTML::DocX->new(file => $file)
                if is_MSDocX($file);

        } elsif ("$file" =~ /docx$/) {
            return MSWord::ToHTML::DocX->new(file => $file)
                if is_MSDocX($file);
            return MSWord::ToHTML::Doc->new(file => $file) if is_MSDoc($file);

        } else {
            return MSWord::ToHTML::Doc->new(file => $file) if is_MSDoc($file);
            return MSWord::ToHTML::DocX->new(file => $file)
                if is_MSDocX($file);

        }
    }
    catch {
        confess "I don't know what to do with this file: $_";
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

MSWord::ToHTML

Take old or new format Word files and spit out extremely clean HTML.

=head1 NOTICE

Because of the PITA involved in processing Word files, I have punted most of
the work to L<Libreoffice|http://www.libreoffice.org/> and L<tidy|http://tidy.sourceforge.net/>.

Which means that you must have the binary programs tidy and libreoffice installed.

=head1 SYNOPSIS

    {
        package My::Word::Converter;

        use strict;
        use warnings;
        use MSWord::ToHTML;

        my $converter = MSWord::ToHTML->new;
        my $doc = $converter->validate_file("/home/myself/my_excellent_writing.doc");
          # This returns an instance of MSWord::ToHTML::Doc
        my $docx = $converter->validate_file("/home/myself/my_excellent_notes.docx");
          # This returns an instance of MSWord::ToHTML::DocX

        my $writing_html = $doc->get_html;
          # This returns an instance of MSWord::ToHTML::HTML
        my $notes_html = $docx->get_html;
          # This returns an instance of MSWord::ToHTML::HTML

        my $text = $notes_html->content;
          # The text content of the file.
        my $text = $writing_html->content;
          # The text content of the file.

    }

=head1 METHODS

=head2 new

MSWord::ToHTML is a Moose class, so new is Moose's constructor.

=cut

=head2 validate_file

This gets you the only thing you need, which is an object ready to give you its HTML.

=cut

=head2 get_html

This is the other important method, that gives you an MSWord::ToHTML::HTML
object that contains:

=over

=item file

An IO::All::File object from the html file written to your temp directory.
I haven't tested this on Windows, but the module attempts to be
agnostic with regards to temporary directories.

Because of the type conversions involved, that file object stores its
content in a scalarref, which is an IO::All::String object. To use it
directly, use

  my $long_html_string = ${$notes_html->file};

=item content

This module does that dereferencing for you in this convenience method on
MSWord::ToHTML::HTML.

  my $long_html_string = $notes_html->content;


=item images

A Path::Class::Dir containing all the images or static files associated with
your html document, so that you can iterate over them and copy them to a
destination of your choosing.

I used Path::Class::Dir instead of IO::All's directory methods because it's
friendlier:

  my @image_files = $writing_html->images->children;

=back

=head1 AUTHOR

Amiri Barksdale, E<lt>amiribarksdale@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 the MSWord::ToHTML L</AUTHOR> listed above.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<IO::All>

L<IO::All::File>

L<IO::All::String>

=cut
