package Image::Button::Set;

# $Id: Set.pm,v 1.6 2003/03/04 15:58:15 joanmg Exp $

use strict;
use vars qw($VERSION);

$VERSION = "0.53";


sub new
{
    my $pkg = shift;
    my %args = (buttons  => undef,
                button   => undef,
                textlist => [],
                @_,);

    my $self = bless {
        buttons => [],
    }, $pkg;

    $self->push(%args);
    return $self;
}

sub push
{
    my $self = shift;
    my %args = (buttons  => undef,  # expect []
                button   => undef,  # expect Image::Button::*
                textlist => [],
                @_,);
    push @{ $self->{buttons} }, @{ $args{buttons} } if defined $args{buttons};
    push @{ $self->{buttons} }, $args{button} if defined $args{button};

    my $labels = $args{textlist};
    if (@$labels) {
        my $button = $self->{buttons}[-1];
        unless (defined $button) {
            die "Need a button to clone\n";
        }
        foreach my $label (@$labels) {
            $self->push(button => $button->copy(text => $label,
                                                file => ''));
        }
    }
}

sub print
{
    my $self = shift;
    my %args = (sameWidth  => 0,
                sameHeight => 0,
                prefix     => '',
                postfix    => '',
                override   => {},
                @_,);

    my $sw  = $args{sameWidth};
    my $sh  = $args{sameHeight};
    my $pre = $args{prefix};
    my $pos = $args{postfix};

    my $th = 0;
    my $tw = 0;
    if ($sw or $sh) {
        foreach my $b (@{ $self->{buttons} }) {
            my ($w, $h) = $b->getSize;
            if ($sw) {
                $tw = ($w > $tw) ? $w : $tw;
            }
            if ($sh) {
                $th = ($h > $th) ? $h : $th;
            }
        }
    }
    
    foreach my $b (@{ $self->{buttons} }) {
        $b->textSize(texth => $th,
                     textw => $tw);
        $b->override(self => $args{override});
        $b->print(prefix => $pre, postfix => $pos);
    }
}

sub flush
{
    my $self = shift;
    my %args = (print => 1,
                @_);
    if ($args{print}) { $self->print(%args) }
    $self->{buttons} = [];
}

1;

=head1 NAME

Image::Button::Set - Builds a set of related PNG buttons

=head1 SYNOPSIS

  use Image::Button::Rect;
  use Image::Button::Plain;
  use Image::Button::Set;

  my $b1 = new Image::Button::Rect(text     => 'text b1',
                                   font     => 'newsgotn.ttf',
                                   fontsize => 20,
                                   fgcolor  => [0, 0, 0],
                                   file     => 'b1.png');

  my $b2 = $b1->copy(text => 'text b2', file => 'b2.png');

  my $set = new Image::Button::Set(buttons => [ $b1, $b2 ]);
  
  my $b3 = $b1->copy(text => 'text b3', file => 'b3.png');

  $set->push(button => $b3);

  my $b4 = $b1->copy(text => 'text b4', file => 'b4.png');
  my $b5 = $b1->copy(text => 'text b5', file => 'b5.png');

  my $b6 = new Image::Button::Plain(text     => 'text b6',
                                    font     => 'newsgotn.ttf',
                                    bdcolor  => [10, 10, 10]);

  $set->push(buttons => [$b4, $b5, $b6]);

  $set->print(sameWidth  => 0, 
              sameHeight => 1,
              prefix     => 'w-');
  $set->flush(sameWidth  => 1,
              sameHeight => 0,
              postfix    => '-h',
              override   => { bdcolor => [0, 0, 20],
                              btcolor => [20, 0, 0] });

=head1 DESCRIPTION

Builds a set of related buttons.  They might be forced to have the
same width and/or height.  Make sure you specify an output file in the
constructor of the buttons, because otherwise they will all go to
stdout and the result won't be what you expect.

=head1 FUNCTIONS

=head2 Constructor

  my $set = new Image::Button::Set(buttons => [ $b1, $b2 ]);

Takes the same arguments as flush, coming next.

=head2 Add buttons

Either

  $set->push(button   => $b1,
             textlist => ['text b2', 'text b3', 'text b4']);

or

  $set->push(buttons  => [$b1, $b2],
             textlist => ['text b3', 'text b4']);

or
  $set->push(button => $b1);
  $set->push(textlist => ['text b2', 'text b3', 'text b4']);

Possible arguments are:

=over 4

=item button => $button

A button to add to the list.

=item buttons => [$button1, $button2]

A reference to an array of buttons to add to the list.

=item textlist => ['text b1', 'text b2']

A list of button texts with which buttons will be built and appended.
They will clone the last button on the list, so there has to be at
least one.  If called with a I<button> or I<buttons> argument it will
go lat, so it will clone the last button you just added.

=back

=head2 Print the buttons

  $set->print(sameWidth  => 1,
              sameHeight => 0,
              prefix     => 'pre-',
              postfix    => '-pos',
              override   => { fontsize => 23,
                              fgcolor  => [0, 0, 0] });

or 

  $set->flush(sameWidth  => 1,
              sameHeight => 0,
              prefix     => 'pre-',
              postfix    => '-pos');

They both take the same arguments:

=over 4

=item sameWidth => 0

If 1 makes all the buttons of the same width, which will equal the
width of the widest one.  Defaults to 0.

=item sameHeight => 0

If 1 makes all the buttons of the same height, which will equal the
height of the tallest one.  Defaults to 0.

=item prefix => ''

Adds a prefix to the file name of each button.  Useful when you want
to print a list of buttons several times in different configurations
to different files.

=item postfix => ''

Adds a postfix before the extension to the file name of each button.

=item override => { font => 'newfont.ttf', fontsize => 10 }

A dictionary reference with parameters to override on the buttons to
print.  Any parameter that the button's constructor understands can be
overriden here.  The buttons will actually be changed.

=back

After I<flush> the button list is cleared.  Flush understands an
additional parameter, I<print>, which defaults to 1.  If set to zero
the list will be cleared, but nothing will be printed.

=head1 SEE ALSO

F<Image::Button> for a description of how to make buttons, and a list
of available button types.

=head1 AUTHOR

Juan M. García-Reyero E<lt>joanmg@twostones.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2003 Juan M. García-Reyero.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

