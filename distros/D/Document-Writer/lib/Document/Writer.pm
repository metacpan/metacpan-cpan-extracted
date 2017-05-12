package Document::Writer;
use Moose;
use MooseX::AttributeHelpers;

use Carp;
use Forest;
use Paper::Specs units => 'pt';

use Document::Writer::Page;

our $AUTHORITY = 'cpan:GPHAT';
our $VERSION = '0.13';

has 'components' => (
    metaclass => 'Collection::Array',
    is => 'rw',
    isa => 'ArrayRef[Graphics::Primitive::Component]',
    default => sub { [] },
    provides => {
        'clear'=> 'clear_components',
        'count'=> 'component_count',
        'get' => 'get_component',
        'push' => 'add_component',
        'first'=> 'first_component',
        'last' => 'last_component'
    }
);
has 'last_page' => (
    is => 'rw',
    isa => 'Document::Writer::Page',
);

sub draw {
    my ($self, $driver) = @_;

    my @pages;
    foreach my $c (@{ $self->components }) {

        next unless(defined($c));

        $driver->prepare($c);

        if($c->isa('Document::Writer::Page')) {
            $c->layout_manager->do_layout($c);
            push(@pages, $c);
        } elsif($c->isa('Document::Writer::TextArea')) {
            my $page = $self->last_page;

            my $avail = $page->body->inside_height - $page->body->layout_manager->used->[1];
            $c->width($page->body->inside_width);

            my $tl = $driver->get_textbox_layout($c);

            my $tlh = $tl->height;
            my $used = 0;

            # This is around to keep control of runaway page adding.  We
            # should never end up with an empty page.
            my $newpage = 0;
            # So.  We need to 'use' all of the TextLayout we got.  The height
            # is $tlh and we have $avail space available on the page.
            while($used < $tlh) {
                # We've not yet used all of the TextLayout...
                if($avail <= 0) {

                    # Stop runaway page adding.
                    if($newpage >= 1) {
                        last;
                    }

                    # But we ran out of available space. So we need to add a
                    # new page.  We do this at the top so that we don't add
                    # a new page on the last iteration and then never use it!
                    $page = $self->add_page_break($driver);
                    $avail = $page->body->inside_height - $page->body->layout_manager->used->[1];
                    $newpage += 1;
                } else {
                    $newpage = 0;
                }

                # Ask the TL to slice off a chunk.  Ask it for however much
                # space we have available ($avail).  If the TL doesn't have
                # that much, it will give us all it has.  If it has more, we'll
                # re-loop.
                my $new_ta = $tl->slice($used, $avail);

                if(defined($new_ta)) {
                    $used += $new_ta->height;
                    # Add whatever we got to the page body.
                    $page->body->add_component($new_ta, 'n');
                    # Relayout the page.
                    $page->layout_manager->do_layout($page);
                    # Get the new avail
                    $avail = $page->body->inside_height - $page->body->layout_manager->used->[1];
                } else {
                    $avail = 0;
                }
            }

        } elsif($c->isa('Graphics::Primitive::Container')) {

            my $page = $self->last_page;
            my $avail = $page->body->inside_height - $page->body->layout_manager->used->[1];

            $driver->prepare($c);
            if($avail < $c->minimum_height) {
                $page = $self->add_page_break($driver);
                $avail = $page->body->inside_height;
            }
            $page->body->add_component($c, 'n');
            $page->layout_manager->do_layout($page);
        }
    }

    foreach my $p (@pages) {
        # Prepare all the pages...
        $driver->prepare($p);
        # Layout each page...

        if($p->layout_manager) {
            $p->layout_manager->do_layout($p);
            $p->body->layout_manager->do_layout($p->body);
        }
        $driver->finalize($p);
        $driver->reset;
        $driver->draw($p);
    }

    return \@pages;
}

sub find {
    my ($self, $predicate) = @_;

    my $newlist = Graphics::Primitive::ComponentList->new;
    foreach my $c (@{ $self->components }) {

        return unless(defined($c));

        unless($c->can('components')) {
            return $newlist;
        }
        my $list = $c->find($predicate);
        if(scalar(@{ $list->components })) {
            $newlist->push_components(@{ $list->components });
            $newlist->push_constraints(@{ $list->constraints });
        }
    }

    return $newlist;
}

sub get_paper_dimensions {
    my ($self, $name) = @_;

    my $form = Paper::Specs->find(brand => 'standard', code => uc($name));
    if(defined($form)) {
        return $form->sheet_size;
    } else {
        return (undef, undef);
    }
}

sub get_tree {
    my ($self) = @_;

    my $tree = Forest::Tree->new(node => $self);

    foreach my $c (@{ $self->components }) {
        $tree->add_child($c->get_tree);
    }

    return $tree;
}

sub add_page_break {
    my ($self, $driver, $page) = @_;

    my $newpage;
    if(defined($page)) {
        $newpage = $page;
    } else {
        die('Must add a first page to create implicit ones') unless defined($self->last_page);
        my $last = $self->last_page;
        $newpage = Document::Writer::Page->new(
            color   => $last->color,
            width   => $last->width,
            height  => $last->height,
        );
    }

    $driver->prepare($newpage);
    $newpage->layout_manager->do_layout($newpage);

    $self->add_component($newpage);
    $self->last_page($newpage);
    return $newpage;
}

__PACKAGE__->meta->make_immutable;

1;
__END__
=head1 NAME

Document::Writer - Library agnostic document creation

=head1 SYNOPSIS

    use Document::Writer;
    use Graphics::Color::RGB;
    # Use whatever you like, but this is best!
    use Graphics::Primitive::Driver::CairoPango;

    my $doc = Document::Writer->new;
    my $driver = Graphics::Primitive::Driver::CairoPango->new(format => 'pdf');
    
    # Create the first page
    my @dim = Document::Writer->get_paper_dimensions('letter');
    my $p = Document::Writer::Page->new(
        color => Graphics::Color::RGB->new(red => 0, green => 0, blue => 0),
        width => $dim[0], height => $dim[1]
    );

    $doc->add_page_break($driver, $page);
    ...
    my $textarea = Document::Writer::TextArea->new(
        text => 'Lorem ipsum...'
    );
    $textarea->font->size(13);
    $textarea->padding(10);
    $textarea->line_height(17);

    $doc->add_component($textarea);
    $doc->draw($driver);
    $driver->write('/Users/gphat/foo.pdf');

=head1 DESCRIPTION

Document::Writer is a document creation library that is built on the
L<Graphics::Primitive> stack.  It aims to provide convenient abstractions for
creating documents and a library-agnostic base for the embedding of other
components that use Graphics::Primitive.

When you create a new Document::Writer, it has no pages.  You can add a page
to the document using C<add_page_break($driver, [ $page ])>.  The first
time this is called, a page must be supplied.  Subsequent calls will clone the
last page that was passed in.  If you add components to the document, then
they will automatically be paginated at render time, if necessary.  You only
need to add the first page and any manual page breaks.

=head1 NOTICE

Document::Writer is a hobby project that I work on in my spare time.  It's
yet to be used for any real work and it's likely I've forgotten something
important.  Free free to contact me via IRC or email if you run into problems.

=head1 METHODS

=head2 add_component

Add a component to this document.

=head2 add_page_break ($driver, [ $page ])

Add a page break to the document.  The first time this is called, a page must
be supplied.  Subsequent calls will clone the last page that was passed in.

=head2 clear_components

Remove all pages from this document.

=head2 draw ($driver)

Convenience method that hides all the Graphics::Primitive magic when you
give it a driver.  After this method completes the entire document will have
been rendered into the driver.  You can retrieve the output by using
L<Driver's|Graphics::Primitive::Driver> I<data> or I<write> methods.  Returns
the list of Page's as an arrayref.

=head2 find ($CODEREF)

Compatability and convenience method matching C<find> in
Graphics::Primitive::Container.

Returns a new ComponentList containing only the components for which the
supplied CODEREF returns true.  The coderef is called for each component and
is passed the component and it's constraints.  Undefined components (the ones
left around after a remove_component) are automatically skipped.

  my $flist = $list->find(
    sub{
      my ($component, $constraint) = @_; return $comp->class eq 'foo'
    }
  );

If no matching components are found then a new list is returned so that simple
calls liked $container->find(...)->each(...) don't explode.

=head2 get_paper_dimensions

Given a paper name, such as letter or a4, returns a height and width in points
as an array.  Uses L<Paper::Specs>.

=head2 get_tree

Returns a L<Forest::Tree> object with this document at it's root and each
page (and it's children) as children.  Provided for convenience.

=head2 last_component

The last component in the list.

=head1 SEE ALSO

L<Graphics::Primitive>, L<Paper::Specs>

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geometry-primitive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geometry-Primitive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.