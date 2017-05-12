package FvwmPiazza::GroupWindow;
{
  $FvwmPiazza::GroupWindow::VERSION = '0.3001';
}
use strict;
use warnings;

=head1 NAME

FvwmPiazza::GroupWindow - FvwmPiazza class for windows.

=head1 VERSION

version 0.3001

=head1 SYNOPSIS

    use FvwmPiazza::GroupWindow;

=head1 DESCRIPTION

This module remembers information about windows.

=cut

use lib `fvwm-perllib dir`;
use FVWM::Module;

use base qw( Class::Base );

our $ERROR;
our $DEBUG = 0 unless defined $DEBUG;

=head2 init

Initialize.

=cut
sub init {
    my ($self, $config) = @_;
    
    $self->params($config,
	{
	    ID => '',
	    GID=>undef,
            MAXIMIZE=>0,
	})
	|| return undef;

    return $self;
} # init

=head2 set_group

Change the group of the window.

=cut
sub set_group {
    my $self = shift;
    my %args = (
	group=>undef,
	@_
    );
    $self->{GID} = $args{group};

} # set_group

=head2 arrange_self

Resize and move self.

$self->arrange_self(x=>$xpos,
y=>$ypos,
width=>$width,
height=>$height,
module=>$mod_ref,
);

=cut
sub arrange_self {
    my $self = shift;
    my %args = (
	x=>undef,
	y=>undef,
	width=>undef,
	height=>undef,
	module=>undef,
	@_
    );
    # Even though we are calling this by window-id, add the window-id condition
    # to prevent a race condition (i hope)
    my $msg = sprintf("WindowId %s %s %s frame %dp %dp %dp %dp",
                      $self->{ID},
                      ($self->{MAXIMIZE} ? "(Maximizable)" : '(!Maximized)'),
                      ($self->{MAXIMIZE} ? "ResizeMoveMaximize" : "ResizeMove"),
                      $args{width},
                      $args{height},
                      $args{x},
                      $args{y});
    $args{module}->postponeSend($msg, $self->{ID});
} # arrange_self

1; # End
__END__
