package Jabber::SimpleSend;

use strict;
use warnings;

require Exporter;

use Carp;
use Net::Jabber qw(Client);

our @ISA =qw( Exporter );
our @EXPORT_OK = qw( send_jabber_message );
our $VERSION='0.03';

sub send_jabber_message {

  my $arguments = {};
  my $first_argument = shift;
  if (ref($first_argument)) {
    $arguments = $first_argument;
  } else {
    $arguments->{user} = $first_argument;
    ($arguments->{password},$arguments->{target},$arguments->{subject},$arguments->{message}) = @_;
  }

  for (qw(user password target message subject)) {
    croak "send_jabber_message requires a $_ argument." unless defined $arguments->{$_};
  }

  croak "The user argument doesnt look like a valid JID."   unless ($arguments->{user} =~ m/.*@.*/);
  croak "The user argument doesnt look like a valid JID."   unless (scalar($arguments->{user} =~ m/@/g) == 1);
  croak "The target argument doesnt look like a valid JID." unless ($arguments->{target} =~ m/.*@.*/);
  croak "The target argument doesnt look like a valid JID." unless (scalar($arguments->{target} =~ m/@/g) == 1);

  my ($username,$hostname) = split /@/,$arguments->{user};

  croak "The user argument doesnt look like a valid JID."  unless (length($username));
  croak "The user argument doesnt look like a valid JID." unless (length($hostname));


  my $jabber_connection = Net::Jabber::Client->new();
  $jabber_connection->Connect(  'hostname' => $hostname,
                                'port'     => 5222
                             );


  $jabber_connection->AuthSend( 'username' => $username,
                                'password' => $arguments->{password},
                                'resource' => 'SimpleSend');

  die "Could not connect to Jabber server" unless ($jabber_connection->Connected());

  #print STDERR "USERNAME : $username , PASSWORD : $arguments->{password}\n";
  $jabber_connection->MessageSend( to      => $arguments->{target},
                                   subject => $arguments->{subject},
                                   body    => $arguments->{message});
  $jabber_connection->Process(1);
  $jabber_connection->Disconnect();

  return 1;
}

1;

__END__

=pod

=head1 NAME

Jabber::SimpleSend - Send a Jabber message simply.

=head1 SYNOPSIS

  use Jabber::SimpleSend qw(send_jabber_message);
  send_jabber_message('youruserid@jabberdomain',
                      'yourpassword',
                      'target@jabber.domain',
                      "Problems with Pie',
                      "Pie taste funny.");

or

  use Jabber::SimpleSend qw(send_jabber_message);
  send_jabber_message({
                       user     => 'youruserid@jabber.domain',
                       password => 'yourpassword',
                       target   => 'target@jabber.domain',
                       subject  => 'Pie Advice',
                       message  => "Must be wrong end.\nPie Good"});

=head1 DESCRIPTION

This module is a wrapper around Net::Jabber that allows you to do one
thing simply - send Jabber messages.  It is useful for daemon
processes, cron jobs or in any program that you want to be able to get
your attention via Jabber.

=head1 METHODS

=head2 send_jabber_mesage()

You can call this method with either 5 scalar arguments or with
a single reference to a hash. In the later case it takes a hash
with the following keys,

=over

=item user

Your JID, or at least the JID you want the program to use.

=item password

The password corresponding to the username above.

=item target

The JID you want to send the message to.

=item subject

The subject of the message.

=item message

The message (which can include newlines).

=back

=head1 KUDOS

Ryan Eatmon for doing the hard work and doing Net::Jabber, DJ Adams
for answering my questions about Jabber in the past. Various CPAN
authors for proving the usefulness of ::Simple modules.

=head1 AUTHOR

Greg McCarroll <greg@mccarroll.org.uk>

=head1 COPYRIGHT

Copyright 2006 by Greg McCarroll <greg@mccarroll.org.uk>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
