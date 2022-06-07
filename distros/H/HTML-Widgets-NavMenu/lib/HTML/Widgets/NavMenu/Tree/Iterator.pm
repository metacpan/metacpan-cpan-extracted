package HTML::Widgets::NavMenu::Tree::Iterator;
$HTML::Widgets::NavMenu::Tree::Iterator::VERSION = '1.1000';
use strict;
use warnings;

use parent qw(HTML::Widgets::NavMenu::Object);

use HTML::Widgets::NavMenu::Tree::Iterator::Stack ();
use HTML::Widgets::NavMenu::Tree::Iterator::Item  ();

__PACKAGE__->mk_acc_ref(
    [
        qw(
            coords
            stack
            _top
        )
    ]
);


sub _init
{
    my $self = shift;

    $self->stack( HTML::Widgets::NavMenu::Tree::Iterator::Stack->new() );
    $self->{_top} = undef();

    return 0;
}


sub top
{
    return shift(@_)->{_top};
}

sub _construct_new_item
{
    my ( $self, $args ) = @_;

    return HTML::Widgets::NavMenu::Tree::Iterator::Item->new($args);
}


sub get_new_item
{
    my ( $self, $args ) = @_;

    my $node        = $args->{'node'};
    my $parent_item = $args->{'parent_item'};

    return $self->_construct_new_item(
        {
            'node'        => $node,
            'subs'        => $self->get_node_subs( { 'node' => $node } ),
            'accum_state' => $self->get_new_accum_state(
                {
                    'item' => $parent_item,
                    'node' => $node,
                }
            ),
        }
    );
}


sub traverse
{
    my $self   = shift;
    my $_items = $self->stack->_items;

    my $push = sub {
        push @{$_items},
            (
            $self->{_top} = $self->get_new_item(
                {
                    'node'        => shift(@_),
                    'parent_item' => $self->{_top},
                }
            )
            );
    };
    $push->( $self->get_initial_node() );
    $self->{_is_root} = ( scalar(@$_items) == 1 );

    my $co = $self->coords( [] );

MAIN_LOOP: while ( my $top_item = $self->{_top} )
    {
        my $visited = $top_item->_is_visited();

        if ( !$visited )
        {
            $self->node_start();
        }

        my $sub_item = (
              $self->node_should_recurse()
            ? $top_item->_visit()
            : undef
        );

        if ( defined($sub_item) )
        {
            push @$co, $top_item->_visited_index();
            $push->(
                $self->get_node_from_sub(
                    {
                        'item' => $top_item,
                        'sub'  => $sub_item,
                    }
                ),
            );
            $self->{_is_root} = ( scalar(@$_items) == 1 );
            next MAIN_LOOP;
        }
        else
        {
            $self->node_end();
            pop @$_items;
            $self->{_top}     = $_items->[-1];
            $self->{_is_root} = ( scalar(@$_items) == 1 );
            pop @$co;
        }
    }

    return 0;
}


sub get_node_from_sub
{
    return $_[1]->{'sub'};
}


sub find_node_by_coords
{
    my $self     = shift;
    my $coords   = shift;
    my $callback = shift || ( sub { } );

    my $idx  = 0;
    my $item = $self->get_new_item(
        {
            'node' => $self->get_initial_node(),
        }
    );

    my $internal_callback = sub {
        $callback->(
            'idx'  => $idx,
            'item' => $item,
            'self' => $self,
        );
    };

    $internal_callback->();
    foreach my $c (@$coords)
    {
        $item = $self->get_new_item(
            {
                'node' => $self->get_node_from_sub(
                    {
                        'item' => $item,
                        'sub'  => $item->_get_sub($c),
                    }
                ),
                'parent_item' => $item,
            }
        );
        ++$idx;
        $internal_callback->();
    }
    return +{ 'item' => $item, };
}


sub get_coords
{
    my $self = shift;

    return $self->coords();
}

sub _is_root
{
    my $self = shift;

    return $self->{_is_root};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widgets::NavMenu::Tree::Iterator - an iterator for HTML.

=head1 VERSION

version 1.1000

=head1 SYNOPSIS

For internal use only.

=head1 METHODS

=head2 coords

Internal use.

=head2 stack

Internal use.

=head2 $self->top()

Retrieves the stack top item.

=head2 $self->get_new_item({'node' => $node, 'parent_item' => $parent})

Gets the new item.

=head2 $self->traverse()

Traverses the tree.

=head2 $self->get_node_from_sub()

This function can be overridden to generate a node from the sub-nodes
returned by get_node_subs() in a different way than the default.

=head2 $self->find_node_by_coords($coords, $callback)

Finds a node by its coordinations.

=head2 $self->get_coords()

Returns the current coordinates of the object.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/HTML-Widgets-NavMenu>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Widgets-NavMenu>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Widgets-NavMenu>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Widgets-NavMenu>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Widgets-NavMenu>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Widgets::NavMenu>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-widgets-navmenu at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Widgets-NavMenu>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-HTML-Widgets-NavMenu>

  git clone git://github.com/shlomif/perl-HTML-Widgets-NavMenu.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-HTML-Widgets-NavMenu/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
