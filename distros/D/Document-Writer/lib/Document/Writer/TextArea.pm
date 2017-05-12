package Document::Writer::TextArea;
use Moose;

extends 'Graphics::Primitive::TextBox';

__PACKAGE__->meta->make_immutable;

1;
__END__
=head1 NAME

Document::Writer::Page - A page in a document

=head1 SYNOPSIS

    use Document::Writer;

    my $doc = Document::Writer->new(default_color => ...);
    my $p = $doc->next_page($width, $height);
    $p->add_text_to_page($driver, $font, $text);
    ...

=head1 METHODS

=head2 body

Set/Get this page's body container.

=head2 footer

Set/Get this page's footer component.

=head2 header

Set/Get this page's footer component.

=head2 BUILD

Moose hackery, ignore me.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geometry-primitive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geometry-Primitive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.