package GappX::Dialogs::Meta::Widget::Trait::MessageDialog;
{
  $GappX::Dialogs::Meta::Widget::Trait::MessageDialog::VERSION = '0.005';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

use Gapp::Types qw( GappDialogImage );

use Gapp::HBox;
use Gapp::Image;
use Gapp::Label;


has 'alert' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has 'image' => (
    is => 'ro',
    isa => GappDialogImage,
    default => sub {
        Gapp::Image->new(
            stock => [ 'gtk-dialog-info', 'dialog' ],
            fill => 0,
            expand => 0,
        );
    },
    trigger => sub { $_[1]->set_fill(0); $_[1]->set_expand(0); },
    coerce => 1,
    lazy => 1,
);

has 'text_widget' => (
    is => 'ro',
    isa => 'Gapp::Widget',
    lazy_build => 1,
);

sub _build_text_widget {
    Gapp::Label->new(
        markup => '<b>' . $_[0]->text . '</b>',
        fill => 0,
        expand => 0,
        properties => { xalign => 0 }
    );
};

has 'secondary_widget' => (
    is => 'ro',
    isa => 'Gapp::Widget',
    lazy_build => 1,
);

sub _build_secondary_widget {
    Gapp::Label->new(
        markup => $_[0]->secondary,
        fill => 0,
        expand => 0,
        properties => { xalign => 0, wrap => 1 }
    );
};

has 'text' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'secondary' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'hbox' => (
    is => 'ro',
    default => sub {
        my $self = shift;
        Gapp::HBox->new(
            content => [
                $self->image,
                
                Gapp::VBox->new (
                    content => [ $self->text_widget, $self->secondary_widget ],
                    fill => 1,
                    expand => 1,
                )
                
            ],
            fill => 1,
            expand => 0,
        );
    },
    lazy => 1,
);

around BUILDARGS => sub {
    my ( $orig, $class, %opts ) = @_;
    $opts{buttons} ||= [ qw(gtk-ok ok) ];
    $opts{icon} ||= 'gtk-dialog-info';
    $opts{title} ||= '';
    return $class->$orig( %opts );
};

before '_build_gobject' => sub {
    my ( $self ) = @_;
    $self->add( $self->hbox );
};

after '_build_gobject' => sub {
    my ( $self ) = @_;
    $self->hbox->gobject->show_all;
};

before 'run' => sub {
    print "\a\n" if $_[0]->alert;
};

package Gapp::Meta::Widget::Custom::Trait::MessageDialog;
{
  $Gapp::Meta::Widget::Custom::Trait::MessageDialog::VERSION = '0.005';
}
sub register_implementation { 'GappX::Dialogs::Meta::Widget::Trait::MessageDialog' };


1;



__END__

=pod

=head1 NAME

GappX::Dialogs::Meta::Widget::Trait::MessageDialog - MessageDialog widget trait

=head1 SYNOPSIS

  use Gapp;

  use GappX::Dialogs;

  $dlg = Gapp::Dialog->new(

    traits => [qw( MessageDialog )],

    rext => 'Primary Text',

    secondary => 'Secondary Text',

  );

  $dlg->run;
     
=head1 DESCRIPTION

MessageDialog provides a simple layout for presenting commonly used dialogs.

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<alert>

=over 4

=item is rw

=item isa Bool

=item default 0

=back

If set to C<true> will sound the system beep when displaying the dialog.

=item B<image>

=over 4

=item is rw

=item isa L<Gapp::Image>

=back

Defaults to stock image C<gtk-dialog-question>.

=item B<text>

=over 4

=item is rw

=item isa Str

=back

The primary message text to display.

=item B<text_widget>

=over 4

=item is rw

=item isa L<Gapp::Label>

=back

The label to display the primary message text.

=item B<secondary>

=over 4

=item is rw

=item isa Str

=back

The secondary message text to display.

=item B<secondary_widget>

=over 4

=item is rw

=item isa L<Gapp::Label>

=back

The label to display the secondary message text.


=head1 PROVIDED TRAITS

All of the traits in this package apply the L<MessageDialog|GappX::Dialogs::Meta::Widget::Trait::MessageDialog>
trait to your object. See  L<MessageDialog|GappX::Dialogs::Meta::Widget::Trait::MessageDialog> for more information.

=over 4

=item ConfirmDialog

L<GappX::Dialogs::Meta::Widget::Trait::ConfirmDialog>

=item ErrorDialog

L<GappX::Dialogs::Meta::Widget::Trait::ErrorDialog>

=item InfoDialog

L<GappX::Dialogs::Meta::Widget::Trait::InfoDialog>

=item MessageDialog

L<GappX::Dialogs::Meta::Widget::Trait::MessageDialog>

=item QuestionDialog

L<GappX::Dialogs::Meta::Widget::Trait::QuestionDialog>

=item WarningDialog

L<GappX::Dialogs::Meta::Widget::Trait::WarningDialog>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2012 Jeffrey Ray Hallock.
    
This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut