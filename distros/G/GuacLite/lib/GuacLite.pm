package GuacLite;

use strict;

our $VERSION = '0.02';
$VERSION = eval $VERSION;

1;

=head1 NAME

GuacLite - Toolkit for implementing a frontend server/client the Apache Guacamole system

=head1 DESCRIPTION

=head1 GUACAMOLE SYSTEM OVERVIEW

The L<Apache Guacamole system|https://guacamole.apache.org/> comprises several tools which used in combination can provide access to remote hosts via various protocols.

The first component is a daemon, "Guacd", which is a compiled application that uses these various protocols to communicate with host computers.
It then accepts inbound connections from clients which speak a unified protocol, called guacamole, to access those hosts.
Guacd is therefore both a proxy/relay and a translator.

In theory any system could connect to guacd but in practice there is a major client, the Java application called "guacamole-common".
It is a server which serves a Javascript application and provides a websocket <-> tcp proxy/relay between the javascript application and guacd.
It also has user, group, and host management, authentication, and policy management.

Because of these extra features it requires persistence (a database) and api calls to add/update users and hosts in order to use it.
Also, because it is written in Java any extension to the system must also be written in Java and served alongside it in a Tomcat or other JSP server.

The Javascript application, called "guacamole-common-js", is a browser-native client for guacd with the exception that it speaks websocket rather than direct tcp.
Therefore it requires a service that can provide that relay.
It also sends keep-alive (ping/pong) messages that don't conform to the guacamole protocol and that the proxy must filter out and reply to.

=head1 MOTIVATION AND COMPONENTS

This project exists to allow non-Java projects that wish to use guacamole-common-js to access a guacd service, without having to conform to the usage expectations of guacamole-common, and without having to alter that application via Java.
It provides a toolkit for implementing a frontend server/client to guacd via Perl and Mojolicious, without any built-in business logic (user management, host configuration).
It provides the following components, each of which are independent and may be used with any Mojolicious application to provide or embed remote access via a guacd service.

=head2 Guacd Client

L<GuacLite::Client::Guacd> is a Perl/L<Mojolicious> client that communicates with a guacd service.
It configures all relevant parameters for communicating with the guacd service and opening a connection to the remote host (including performing the requisite handshake).

The current supported version of the protocol is 1.3.0

=head2 Guacd Websocket Tunneling Plugin

L<GuacLite::Plugin::Guacd> is a plugin that provides a helper method to establish a websocket connection between a client and a guacd service via a configured (but not connected) L<GuacLite::Client::Guacd> instance.
It initiates the guacd connection and triggers the handshake, it then passes messages between the guacd connection and the client's websocket, monitoring backpressure between them, and handling the keep-alive messages.

In the future, passing a connected guacd client should be possible, but it hasn't been implemented yet.

=head2 Utilities

L<GuacLite::Util> provides utilies for using the system.
Currently it only provides one function which can bundle the guacamole-common-js files into a single javascript file and provide an initialize function to defer loading the javascript until necessary, which is required by some newer browsers.

=head2 Example Web Application

L<GuacLite::Client::Web> is an example web application which is intended to be used as a reference and test implementation of the tools.
It should function correctly but currently has almost no user interface and for the time being shouldn't be relied on to be in its current state.
While the preceding libraries in the distribution are considered production ready and will only change if necessary, this example application can and may change without warning.

In the future, perhaps this application will be made into a fully featured web client, however that risks falling into the (my opinion) feature creep seen in the original Java application that it replaces.

=head2 guaclite script

It includes an script which can start the example application or can be used to bundle the javascript via the utility function.
See details of both above.

=head2 Bundled Assets

The distribution does include the bundled version guacamole-common-js.
The exact version provided is not guaranteed.
For production environments, it is encouraged that you download you own copy of the library and either bundle it with the utility or else bundle as you see fit.

It also contains the templates/files for the example application, which are subject to the caveats of the example application itself.

=head2 Containerization Files

The distribution contains example Dockerfile and docker-compose.yml files to facilitate easy use of the example application and for deploying both it and a guacd service.
These are provided as reference only and should not be relied upon for production use, owing to the same warning as previously about the stability of the example application.

=head1 AUTHOR

Joel Berger, <joel.a.berger@gmail.com>

=head1 CONTRIBUTORS

None yet :)

=head1 COPYRIGHT AND LICENSE

This original work is copyright 2020 - 2021 by L</AUTHOR> and L</CONTRIBUTORS>.

This original work is licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 LICENSE NOTICE FOR BUNDLED WORKS

This repository and/or library also bundles work from L<"Apache Guacamole"|https://guacamole.apache.org/>
which is also licensed under the terms of the Apache 2.0 License.
