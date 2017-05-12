package GappX::NoticeBox;
{
  $GappX::NoticeBox::VERSION = '0.200';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw( ArrayRef );

extends 'Gapp::Widget';

use GappX::Moose::Meta::Attribute::Trait::GappNoticeBox;

use GappX::Notice;

has '+gclass' => (
    default => 'Gtk2::Window',
);

has 'notice' => (
    is => 'ro',
    isa => 'Maybe[GappX::Notice]',
    writer => '_set_notice',
);

has 'fade_step' => (
    is => 'rw',
    isa => 'Num',
    default => 0.07,
);

has 'fade_duration' => (
    is => 'rw',
    isa => 'Num',
    default => 700,
);

has 'display_duration' => (
    is => 'rw',
    isa => 'Num',
    default => 3000,
);


sub display {
    my ( $self, $notice, $duration ) = @_;   
    
    for ( $self->gobject->get_children ) {
        $self->gobject->remove( $_ );
    }
    
    $self->gobject->add( $notice->gwrapper );
    
    $self->_set_notice( $notice );
    
    
    $self->gobject->set( opacity => 0 );
    
    my $gtkw = $self->gobject;
    my $screen = $gtkw->get_screen;
    my ($width, $height) = $gtkw->get_size;
    
    $gtkw->move( 0, $screen->get_height - $height - 40 );
    
    my $nsteps = 1 / $self->fade_step;
    my $steplength = $self->fade_duration / $nsteps;
    
    $self->gobject->set( opacity => 0 );
    $self->gobject->show_all;
    
    my $x = 0;
    Glib::Timeout->add( $steplength, sub {
        # start the hide timer of fully display
        if ( $x >= 1 ) {
            $self->gobject->set( opacity => 1 );
            $self->start_hide_timer( $duration );
            return 0;
        }
        else {
            $self->gobject->set( opacity => $x );
            $x += $self->fade_step;
            $x = 1 if ( $x >= 1 );
            return 1;
        }
    });
}

sub hide {
    my $self = shift;
    
    my $nsteps = 1 / $self->fade_step;
    my $steplength = $self->fade_duration / $nsteps;
    
    my $x = $self->gobject->get( 'opacity' );
    Glib::Timeout->add( $steplength, sub {
        if ( $x <= 0 ) {
            $self->gobject->set( opacity => 0 );
            return 0;
        }
        else {
            $self->gobject->set( opacity => $x );
            $x -= .07;
            return 1;
        }
    });   
}

sub start_hide_timer {
    my ( $self, $duration ) = @_;
    $duration ||= $self->display_duration;
    Glib::Timeout->add( $duration, sub { $self->hide; return 0; } );
}

1;

package Gapp::Layout::Default;
{
  $Gapp::Layout::Default::VERSION = '0.200';
}
use Gapp::Layout;



# NoticeBox
style 'GappX::NoticeBox', sub {
    my ( $l, $w ) = @_;
    
    $w->properties->{decorated} ||= 0;
    $w->properties->{opacity}   ||= 0;
    $w->properties->{border_width} ||= 5;
    $w->properties->{gravity}   ||= 'south-east';
    $w->properties->{'skip-taskbar-hint'} = 1;
};

build 'GappX::NoticeBox', sub {
    my ( $l, $w ) = @_;

    my $gtkw = $w->gobject;
    $gtkw->set_keep_above( 1 );
};


__END__

=pod

=head1 NAME

GappX::NoticeBox - NoticeBox widget

=head1 SYNOPSIS

  use Gapp;

  use Gapp::NoticeBox;

  $box = Gapp::NoticeBox->new;

  $n = Gapp::Notice->new(

    icon => 'gtk-info',

    text => 'Display notice to user.',

    action => sub { print "Notice clicked\n" },

  );
  
=head1 DECRIPTION

Displays a message to the user in the notification area of the desktop.

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- Gapp::NoticeBox

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<display_duration>

Length of time in milliseconds to display the notice on the screen.

=over 4

=item is rw

=item isa Num

=item default 3000

=back

=item B<fade_duration>

Length of time in milliseconds it takes for the notice to fade in/fade out.

=over 4

=item is rw

=item isa Num

=item default 700

=back

=item B<fade_step>

The amount to change the up or down when fading in or out. The smaller the number,
the more steps required to complete the fade.

=over 4

=item is rw

=item isa Num

=item default .07

=back

=back

=head1 PROVIDED METHODS

=over 4

=item B<display $notice, $duration?>

Display L<GappX::Notice> to the user in the notification area. If no C<$duration> is specified, the
C<display_duration> value will be used.

=item B<hide>

Remove the notice box from the users screen.

=item B<start_hide_timer $duration>

Sets a timer to remove the notices from the user's screen after a specified duration.

=back

=head1 SEE ALSO

=over 4

=item L<Gapp>

=item L<GappX::Notice>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2012 Jeffrey Ray Hallock.
    
    This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
    
=cut
