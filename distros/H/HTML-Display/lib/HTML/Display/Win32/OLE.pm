package HTML::Display::Win32::OLE;
use strict;
use parent 'HTML::Display::Common';
use vars qw($VERSION);
$VERSION='0.40';

=head1 NAME

HTML::Display::Win32::OLE - use an OLE object to display HTML

=head1 SYNOPSIS

=for example begin

  package HTML::Display::Win32::OleControl;
  use parent 'HTML::Display::Win32::OLE';

  sub new {
    my $class = shift;
    $class->SUPER::new( app_string => "FooBrowser.Application", @_ );
    $self;
  };

  my $browser = HTML::Display->new(
    class => 'HTML::Display::Win32::OleControl',
  );
  $browser->display("<html><body><h1>Hello world!</h1></body></html>");

=for example end

=cut

sub new {
  my ($class) = shift;
  my %args = @_;

  my $self = $class->SUPER::new( %args );
  $self;
};

=head2 setup

C<setup> is a method you can override to provide initial
setup of your OLE control. It is called after the control
is instantiated for the first time.

=cut

sub setup {};

=head2 control

This initializes the OLE control and returns it. Only one
control is initialized for each object instance. You don't need
to store it separately.

=cut

sub control {
  my $self = shift;
  unless ($self->{control}) {
    eval "use Win32::OLE";
    die $@ if $@;
    my $control = Win32::OLE->CreateObject($self->{app_string});
    $self->{control} = $control;
    $self->setup($control);
  };
  $self->{control};
};

=head1 AUTHOR

Copyright (c) 2004-2007 Max Maischein C<< <corion@cpan.org> >>

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

1;
