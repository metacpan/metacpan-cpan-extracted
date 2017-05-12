use strict;
use warnings;

package Jifty::Plugin::Feedback;
use base qw/Jifty::Plugin Class::Accessor::Fast/;

our $VERSION = '0.05';

=head1 NAME

Jifty::Plugin::Feedback - Plugin to provides a feedback box

=head1 DESCRIPTION

This plugin provides a "feedback box" for your app.

Add to your app's config:

  Plugins: 
    - Feedback: 
        from: defaultsender@example.com
        to: recipient@example.com
        # optional
        notification: YourApp::Notification::Feedback

Add to your app's UI where you want the feedback box:

 show '/feedback/request_feedback';

=cut

__PACKAGE__->mk_accessors(qw(from to notification));

=head2 init

Initializes the Feedback object. Takes a paramhash with keys C<from> and C<to>,
which are email addresses.  The optional C<notification> key is used to
override the plugin's default L<Jifty::Plugin::Feedback::Notification> when
sending mail.

=cut

sub init {
    my $self = shift;
    my %opt = @_;
    $self->from($opt{'from'});
    $self->to($opt{'to'});
    $self->notification($opt{'notification'} || 'Jifty::Plugin::Feedback::Notification');
}

=head1 AUTHOR

Jesse Vincent, C<jesse@bestpractical.com>

=head1 LICENSE

This plugin is copyright 2007-2011 Best Practical Solutions, LLC.

This plugin is distributed under the same terms as Perl itself.

=cut

1;

