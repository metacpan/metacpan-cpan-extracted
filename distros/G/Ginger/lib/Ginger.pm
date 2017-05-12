# Ginger Framework
# Version 0.01
# Copyright (C) 2013 David Helkowski

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.  You may also can
# redistribute it and/or modify it under the terms of the Perl
# Artistic License.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

=head1 NAME

Ginger - Application framework built around Class::Core wrapper system

=head1 VERSION

0.04

=cut

package Ginger;

use vars qw/$VERSION/;
$VERSION = "0.04";

sub new {
    my $class = shift;
    return bless {}, $class;
}

1;

__END__

=head1 SYNOPSIS

Ginger is a development environment for Perl. It is designed to be modular, with many "default" modules relevant to a base functional
system being provided. The "default" modules can be used to build a full application with minimal system code, focusing on application functionality
instead of how to handle typical things such as logging, cookies, sessions, api, etc.

One of the primary uses of Ginger is as an application server. Ginger::Reference::Core is the base of that application server.

Ginger::Reference::Core allows for an application to be created as a package of configuration and modules, similar to the way web containers or servlets
are used in a Java environment with a Java application server such as JBoss or Tomcat.

Ginger::Reference::Core differs significantly from the approach taken by other Perl applications servers such as Catalyst and Dancer, in that it attempts
to seperate the configuration of your application from the application code itself.

This base modole "Ginger" is a placeholder to describe the layout of all the Ginger CPAN modules, both for ones released by the Ginger maintainers as
well as user created open source Ginger modules.

=head1 DESCRIPTION

=head2 Basic Example

=head3 runcore.pl

    #!/usr/bin/perl -w
    use strict;
    use Ginger::Reference::Core;
    
    my $core = Ginger::Reference::Core->new();
    $core->run( config => "config.xml" );

=head3 config.xml

    <xml>
        <log>
            <console/>
        </log>
        
        <web_request>
            <mod>mongrel2</mod>
        </web_request>
        
        <mode name="default">
            <init>
                <call mod="web_request" func="run" />
                <call mod="web_request" func="wait_threads"/>
            </init>
        </mode>
    </xml>

=head2 Configuration

Configuration of an Ginger application is accomplished primarily by the creation and editing of a 'config.xml' file.
Such an xml file contains the following:

=over 4

=item * A list of the modules your application contains

=item * Configuration for each of your modules

=item * Configuration for Ginger::Reference::Core itself and the included modules

=item * A sequence of steps to be used when starting up an Ginger instance

=back

=head2 Application Modules

Application modules are custom modules that interact with Ginger itself to define your custom application logic.
An application module is a perl module using L<Class::Core>, containing specific functions so that it can integrate with Ginger
and other modules.

=head2 Concurrency / Multithreading

Ginger does not currently support multithreading of requests. Long running requests can and will prevent handling of other requests
until the long running request is finished. This will be fixed in the next version.

=head2 Modules

Note that in version 0.03 ( this version ) the following components are included in the base install of Ginger::Reference::Core.
Note also that none of the following links currently have any detailed documentation. The next version should address this.

=over 4

=item * L<Ginger::Reference::Admin::Default>

An admin interface to see the state of a running Ginger, and various information about it's activity.

=item * L<Ginger::Reference::Log::Default>

A simple logging system that logs to the shell.

=item * L<Ginger::Reference::Web::CookieMan::Default>

A basic cookie handling module.

=item * Incoming Web Request Modules

=over 4

=item * L<Ginger::Reference::Web::Request::HTTP_Server_Simple>

A module that uses L<HTTP::Server::Simple> in order to accept incoming requests directly.
Note that this module will need L<HTTP::Server::Simple::CGI> to be installed in order for it to work.
Also, using this module will redirect regular print statements to go through to a web request; which may be unexpected.

=item * L<Ginger::Reference::Web::Request::Mongrel2>

A module that connects to a Mongrel2 server in order to accept incoming requests.
Using this module, which is enabled by default, will require the following CPAN modules to be installed:

=over 4

=item * L<ZMQ::LibZMQ3>

=item * L<URI::Simple>

=item * L<Text::TNetstrings>

=back

=back

=item * L<Ginger::Reference::Web::Router::Default>

A basic routing module that allows modules to register routes against it so that different
modules can handle different path requests into the system.

=item * L<Ginger::Reference::Web::SessionMan::Default>

A basic session management module that stores sessions in memory. Note session data stored through
this module will be lost whenever the Ginger is restarted.

=item * Internally used modules

=over 4

=item * L<Ginger::Reference::Shared::Http_Server_Simple_Wrapper>

=back

=back

=head1 LICENSE

  Copyright (C) 2015 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut