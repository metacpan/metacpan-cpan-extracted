use warnings;
use strict;

package Jifty::Plugin::Feedback::Notification;
use base qw/Jifty::Notification/;

=head1 NAME

Jifty::Plugin::Feedback::Notification - the default feedback email

=head1 ARGUMENTS

=over

=item recipients

=item from

=item body

=back

=cut

=head2 setup

Set up the subject

=cut

sub setup {
    my $self = shift;
    $self->SUPER::setup(@_);

    # Subject: [AppName feedback] first 60 chars of message [set by the action]
    my $subject = "[".Jifty->config->framework('ApplicationName')." feedback] ";
    $subject .= $self->subject;
    $self->subject($subject);
}

1;

