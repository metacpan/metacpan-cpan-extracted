use 5.008001;
use strict;
use warnings;

package Jifty::Plugin::EmailErrors;
use base qw/Jifty::Plugin/;

our $VERSION = '0.02';

=head1 NAME

Jifty::Plugin::EmailErrors - Emails all 500 pages to an arbitrary email address

=head1 SYNOPSIS

In your config.yml or equivalent:

  Plugins:
   - EmailErrors:
       to: address@example.com
       from: server@example.com
       subject: Server error

=head1 DESCRIPTION

All errors which result in the browser going to the '500 server error'
page will send an email with the stack trace that caused it.

=head1 METHODS

=head2 init

Sets up the global values for C<from>, C<to>, and C<subject>, based on
the plugin's provided configuration.

=cut

sub init {
    my $self = shift;
    my %args = @_;
    $Jifty::Plugin::EmailErrors::Notification::EmailError::TO = $args{to}     || 'nobody@localhost';
    $Jifty::Plugin::EmailErrors::Notification::EmailError::FROM = $args{from} || 'nobody@localhost';
    $Jifty::Plugin::EmailErrors::Notification::EmailError::SUBJECT = $args{subject} || 'Jifty error';
}

=head1 AUTHORS

Alex Vandiver C<alexmv@bestpractical.com>

Shawn M Moore C<sartak@bestpractical.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
