package Draft::TkGui;

=head1 NAME

Draft::TkGui - Display a Draft world

=head1 SYNOPSIS

Opens a Tk GUI window, displays a drawing and allows some user
interaction.

=cut

use strict;
use warnings;

=pod

=head1 DESCRIPTION

This module knows a little bit about Draft drawings and displays
them on screen using L<TK::WorldCanvas> which takes care of all the
drawing, panning etc..

This module is a sub-class of L<Tk::WorldCanvas> and so inherits
all L<Tk::Canvas> methods.

=cut

use Draft;
use Tk::WorldCanvas;
use File::Atomism;
use File::Atomism::utils qw /Undo Redo/;

use vars qw /@ISA/;
@ISA = qw /Tk::WorldCanvas/;

=pod

=head1 USAGE

Create a Draft::TkGui object like so:

  my $canvas = Draft::TkGui->new;

This should show a window and display the drawing, some interaction
is possible:

=over 2

=item *

Use the 'i' and 'o' keys to zoom in and out.

=item *

Use the left mouse button to drag items around the screen.

=item *

Use the middle mouse button to pan around the viewport.

=back

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;

    my $top = MainWindow->new;

    my $self = $top->WorldCanvas (-width => '297m', -height => '210m');

    $self->pack (-expand => 'yes', -fill => 'both');

    # make items change colour with mouse-over

    $self->bind ('all', '<Any-Enter>' => [\&_items_enter]);
    $self->bind ('all', '<Any-Leave>' => [\&_items_leave]);

    # i and o zoom in and out

    $self->CanvasBind('<i>' => sub {$self->zoom (1.25)});
    $self->CanvasBind('<o>' => sub {$self->zoom (0.8)});

    $self->CanvasBind ('<Control-Key-z>' => sub {Undo ($Draft::WORLD->{$Draft::PATH}->{_path}); $_[0]->Draw});
    $self->CanvasBind ('<Control-Key-y>' => sub {Redo ($Draft::WORLD->{$Draft::PATH}->{_path}); $_[0]->Draw});

    #$self->CanvasBind ('MouseWheel' => sub {$self->zoom (1.25)});

    # left-mouse is used to move anything

    $self->CanvasBind ('<1>' =>
        sub {$self->_items_start_drag ($Tk::event->x, $Tk::event->y)});

    $self->CanvasBind ('<B1-Motion>' =>
        sub {$self->_items_drag ($Tk::event->x, $Tk::event->y)});

    $self->CanvasBind ('<ButtonRelease-1>' =>
        sub {$self->_items_end_drag ($Tk::event->x, $Tk::event->y)});

    # middle-mouse is used to pan the viewport

    $self->CanvasBind ('<2>' =>
        sub {$self->scan ('mark', $Tk::event->x, $Tk::event->y); $self->configure (-cursor => 'fleur');});

    $self->CanvasBind ('<B2-Motion>' =>
        sub {$self->scan ('dragto', $Tk::event->x, $Tk::event->y, 1)});

    $self->CanvasBind ('<ButtonRelease-2>' =>
        sub {$self->configure (-cursor => '');});

    # canvas gets the focus and a redraw with a mouse-over

    $self->CanvasBind ('<Any-Enter>' => sub {$_[0]->CanvasFocus; $_[0]->Draw});

    $self = bless $self, $class;
    return $self;
}

=pod

You can redraw the canvas window like so:

  $canvas->Draw;

This scans all drawing elements and updates the display with any
changes.  No files are accessed unnecessarily, so feel free to call
this method as often as you like; by default this method is called
whenever a mouse pointer enters the canvas area.

=cut

sub Draw
{
    my $self = shift;

    my $drawing = $Draft::WORLD->{$Draft::PATH};
    my $offset = [0, 0, 0];

    $drawing->Draw ($self, $offset, [], []);

    $self->delete (keys %{$File::Atomism::EVENT->{_old}});

    $drawing->Draw ($self, $offset, [], []);

    undef $File::Atomism::EVENT->{_old};
    undef $File::Atomism::EVENT->{_new};
}

sub _items_start_drag
{
    my $self = shift;
    my ($x, $y) = @_;

    $self->{iinfo}->{lastX} = $self->{iinfo}->{startX} = $self->worldx ($x);
    $self->{iinfo}->{lastY} = $self->{iinfo}->{startY} = $self->worldy ($y);
}

sub _items_drag
{
    my $self = shift;
    my ($x, $y) = @_;

    my @tags = $self->gettags ('current');
    my $tag = shift @tags || return;

    $self->move ($tag, $self->worldx ($x) - $self->{iinfo}->{lastX},
                       $self->worldy ($y) - $self->{iinfo}->{lastY});

    $self->{iinfo}->{lastX} = $self->worldx ($x);
    $self->{iinfo}->{lastY} = $self->worldy ($y);
}

sub _items_end_drag
{
    my $self = shift;
    my ($x, $y) = @_;

    my @tags = $self->gettags ('current');
    my $tag = shift @tags || return;

    my $moveX = $self->worldx ($x) - $self->{iinfo}->{startX};
    my $moveY = $self->worldy ($y) - $self->{iinfo}->{startY};

    return if ($moveX == 0 and $moveY == 0);

    my @path = split '/', $tag;
    my $file = pop @path;
    my $folder = (join '/', @path) . '/';

    my $item = $Draft::WORLD->{$folder}->{$tag};

    $item->Move ([$moveX, $moveY, 0]);
    system 'sync';
}

sub _items_enter
{
    my $self = shift;

    my @tags = $self->gettags ('current');

    my $tag = shift @tags;

    for my $tag (@tags) {$self->itemconfigure ($tag, -fill => 'Orange')}

    # http://tmml.sourceforge.net/doc/tk/cursors.html
    $self->configure (-cursor => 'fleur');

    $self->itemconfigure ($tag, -fill => 'Red');
}

sub _items_leave
{
    my $self = shift;

    my @tags = $self->gettags ('current');

    $self->configure (-cursor => '');

    for my $tag (@tags) {$self->itemconfigure ($tag, -fill => 'Black')}
}


1;
