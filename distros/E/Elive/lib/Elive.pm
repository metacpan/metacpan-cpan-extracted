package Elive;
use warnings; use strict;

=head1 NAME

Elive - Elluminate Live! Manager (ELM) Command Toolkit bindings

=head1 VERSION

Version 1.37

=cut

our $VERSION = '1.37';

use 5.008003;

use parent qw{Class::Data::Inheritable};
use Scalar::Util;

use YAML::Syck;
use Carp;
use Elive::Entity;

=head1 EXAMPLE

The following (somewhat contrived) example sets up a meeting of selected
participants:

    use Elive;
    use Elive::Entity::User;
    use Elive::Entity::Preload;
    use Elive::Entity::Session;

    my $meeting_name = 'Meeting of the Smiths';

    Elive->connect('https://someEllumServer.com/my_instance',
                   'serversupport', 'mypass');

    my $users = Elive::Entity::User->list(filter => "(lastName = 'Smith')");
    die "smithless" unless @$users;

    my $start = time() + 15 * 60; # starts in 15 minutes
    my $end   = $start + 30 * 60; # runs for half an hour

    my $whiteboard_preload = Elive::Entity::Preload->upload('welcome.wbd');

    my $session = Elive::Entity::Session->insert({
	 name           => $meeting_name,
	 start          => $start . '000',
	 end            => $end   . '000',
         restricted     => 1,
         participants   => $users,
         add_preload    => $whiteboard_preload,
	 });

    print "Session address: ".$session->web_url;

    Elive->disconnect;

=head1 DESCRIPTION

Elive is a set of Perl bindings and entity definitions for quick and easy
integration with the Elluminate I<Live!> Manager (ELM) application. It can
be used to automate a range of tasks including setting up meetings and
participants, as well as managing users and user groups.

=head1 BACKGROUND

Elluminate I<Live!> is software for virtual online classrooms. It is suitable
for meetings, demonstrations, web conferences, seminars, training and support.

Most management functions that can be performed via the web interface can
also be achieved via SOAP web services. This is known as the
I<Command Toolkit> and is detailed in chapter 4 of the Elluminate I<Live!>
Software Developers Kit (SDK).

Users, Meetings and other resources are stored in the Elluminate I<Live!>
Manager (ELM) database. These can be entered, accessed and manipulated via
the Entity Commands in the Command Toolkit.

=cut

=head1 METHODS

=head2 connect

     Elive->connect('https://myServer.com/test', some_user => 'some_pass');
     my $connection = Elive->connection;

Connects to an Elluminate server instance. Dies if the connection could not
be established. If, for example, the SOAP connection or user login failed.

The login user must either be an Elluminate I<Live!> system administrator
account, or a user that has been configured to access the Command Toolkit
via web services.

See also: the Elive C<README> file, L<Elive::Connection::SDK>.

=cut

sub connect {
    my $class = shift;
    return Elive::Entity->connect(@_);
}

=head2 connection

     $e1 = Elive->connection
         or warn 'no elive connection active';

Returns the current L<Elive::Connection::SDK> connection.

=cut

sub connection {
    my $class = shift;
    return Elive::Entity->connection(@_);
}

=head2 login

Returns the login user for the default connection.

    my $login = Elive->login;
    say "logged in as: ".$login->loginName;

See L<Elive::Entity::User>.

=cut

sub login {
    my ($class, %opt) = @_;

    my $connection = $opt{connection} || $class->connection;

    die "not connected"
	unless $connection;

    return $connection->login;
}

=head2 server_details

Returns the server details for the current connection. See L<Elive::Entity::ServerDetails>.

    my $server = Elive->server_details;
    printf("server %s is running Elluminate Live! version %s\n", $server->name, $server->version);

There can potentially be multiple servers:

    my @servers = Elive->server_details;
    foreach my $server (@servers) {
        printf("server %s is running Elluminate Live! version %s\n", $server->name, $server->version);
    }

=cut

sub server_details {
    my ($class, %opt) = @_;

    my $connection = $opt{connection} || $class->connection
	or die "not connected";

    my @server_details = $connection->server_details;
    return wantarray ? @server_details : $server_details[0]
}
    
=head2 disconnect

Disconnects the default Elluminate connection. It is recommended that you
do this prior to exiting your program.

    Elive->disconnect;
    exit(0);

=cut

sub disconnect {
    my $self = shift;
    return Elive::Entity->disconnect;
}

=head2 debug

    Elive->debug(1)

Sets or gets the debug level.

=over 4

=item 0 = no debugging

=item 1 = dump object and class information 

=item 2 = also enable SOAP::Lite tracing

=item 3 = very detailed

=back

=cut

sub debug {
    my $class = shift;
    Elive::DAO::_Base->debug(@_);
}

=head1 ERROR MESSAGES

Elluminate Services Errors:

=over 4

=item   "Unable to determine a command for the key : Xxxx"

This may indicate that the particular command is is not available for your
site instance. Please follow the instructions in the README file for
detecting and repairing missing adapters.

=item   "User [<username>], not permitted to access the command {<command>]"

Please ensure that the user is a system administrator account and/or the
user has been configured to access commands via web services. See also the
L<README> file.

=back

=cut

=head1 SCRIPTS

=head2 elive_query - simple query shell

elive_query is a script for issuing basic sql-like queries on entities. It serves as a simple demonstration script, and can be used to confirm connectivity and operation of Elive.

    % perl elive_query https://myserver.com/test -user sdk_user
    Password: connecting to https://myserver.com/test...ok
    Elive query 1.xx - type 'help' for help

    elive> select address,version from serverDetails
    address     |version
    ------------|-------
    myserver.com|10.0.1 
    elive> ^D

It serves a secondary function of querying entity metadata. For example,
to show the C<meeting> entity:

    % elive_query
    Elive query 1.xx  - type 'help' for help

    elive> show
    usage: show group|meeting|...|serverParameters|session|users

    elive> show meeting
    meeting: Elive::Entity::Meeting:
      meetingId          : pkey Int        
      adapter            : Str       -- adapter used to create the meeting
      allModerators      : Bool      -- all participants can moderate
      deleted            : Bool            
      end                : HiResDate -- meeting end time
      facilitatorId      : Str       -- userId of facilitator
      name               : Str       -- meeting name
      password           : Str       -- meeting password
      privateMeeting     : Bool      -- don't display meeting in public schedule
      restrictedMeeting  : Bool      -- Restricted meeting
      start              : HiResDate -- meeting start time

for more information, please see L<elive_query>, or  or type the command: C<elive_query --help>

=head2 elive_raise_meeting - meeting creation

This is a demonstration script for creating meetings. This includes the setting
of meeting options, assigning participants and uploading of preloads (whiteboard, plan and media files).

For more information, see L<elive_raise_meeting> or type the command: C<elive_raise_meeting --help>

=head2 elive_lint_config - configuration file checker

A utility script that checks your Elluminate server configuration. This
is more likely to be of use for Elluminate I<Live!> prior to 10.0. Please
see the README file.

=head1 SEE ALSO

=head2 Modules in the Elive distribution

=over 4

=item L<Elive::Entity::Session> - Sessions (or meetings)

=item L<Elive::Entity::Group> - Groups of Users

=item L<Elive::Entity::Preload> - Preload Content (whiteboard, multimedia and plans)

=item L<Elive::Entity::Recording> - Session Recordings

=item L<Elive::Entity::Report> - Management Reports

=item L<Elive::Entity::User> - Users/Logins

=item L<Elive::Connection::SDK> - Elluminate SOAP connections

=back

=head2 Scripts in the Elive Distribution

=over 4

=item L<elive_query> - simple interactive queries on Elive entities

=item L<elive_raise_meeting> - command-line meeting creation

=item L<elive_lint_config> - Elluminate Live! configuration checker

=back

=head2 Related CPAN Modules

L<Bb::Collaborate::V3> - this module implements the Blackboard Collaborate Standard Integration API (v3) for C<SAS> servers. 

=head2 Elluminate Documentation

This following documents were used in the construction of this module:

=over 4

=item ELM2.5_SDK.pdf

General Description of SDK development for Elluminate I<Live!>. In particular
see section 4 - the SOAP Command Toolkit. This module concentrates on
implementing the Entity Commands described in section 4.1.8.

=item Undocumented ELM 3.x SDK Calls.pdf

This describes the C<createSession> and C<updateSession> commands, as
implemented by the L<Elive::Entity::Session> C<insert()> and C<update()>
methods.

=item DatabaseSchema.pdf

Elluminate Database Schema Documentation.

=back

=head1 AUTHOR

David Warring, C<< <david.warring at gmail.com> >>

=head1 BUGS AND LIMITATIONS

=over 4

=item * Elive does not support hosted (SAS) systems

The Elive distribution only supports the ELM (Elluminate I<Live!> Manager) SDK.
The SAS (Session Administration System) is not supported.

=back

=head1 SUPPORT

Please report any bugs or feature requests to C<bug-elive at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Elive>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Elive

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Elive>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Elive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Elive>

=item * Search CPAN

L<http://search.cpan.org/dist/Elive/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Lex Lucas and Simon Haidley for their ongoing support and
assistance with the development of this module.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2015 David Warring, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Elive
