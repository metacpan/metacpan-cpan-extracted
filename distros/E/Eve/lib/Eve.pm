package Eve;

use 5.006;
use strict;
use warnings;

=head1 NAME

Eve - The web service creation framework written with events in mind.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';


=head1 SYNOPSIS

Currently Eve supports running web services under Apache2 with
mod_perl2 using the PSGI protocol. To run a web service you need to
prepare a configuration file, create a startup script and create a
PSGI event handler.

=head2 The startup script

The startup script is required to prepare all needed objects in order
for the web service to run. To make a "Hello, World!" application we
need to have a minimal script located in the C<bin> folder of the
installation like this:

    #!/usr/bin/perl
    use lib::abs '../lib';

    use warnings;
    use strict;

    use File::Basename ();
    use File::Spec ();
    use YAML ();

    use Eve::Registry;
    use Eve::Support;

    sub main {

        # Make sure we are in a sane environment.
        $ENV{MOD_PERL} or die 'not running under mod_perl!';

        my $dirname = File::Basename::dirname(__FILE__);

        my $file_path = File::Spec->catfile($dirname, '../etc/hello.yaml');

        $Eve::Registry::instance = Eve::Registry->new(%{
            YAML::LoadFile(
                Eve::Support::open(mode => '<', file => $file_path))});

        $Eve::Registry::instance->bind();

        return;
    }

    main();

    1;

=head2 The configuration file

As you can see from the startup script example, the application draws
its initialization parameters from the hello.yaml file which is
located in the C<etc> folder of the installation:

    base_uri_string: http://example.com/base-uri

All keys and values represented in this file will be automatically
passed to the registry object constructor.

=head2 The event handler

Last but not least, the PSGI event handler script:

    #!/usr/bin/perl

    use utf8;
    use strict;
    use warnings;

    use open qw(:std :utf8);
    use charnames qw(:full);

    use Cwd qw(abs_path);
    use File::Spec;
    use Plack::Request;
    use YAML;

    use Eve::Event::PsgiRequestReceived;

    return sub {
        my $env = shift;

        my $event = Eve::Event::PsgiRequestReceived->new(
            env_hash => $env,
            event_map => $Eve::Registry::instance->get_event_map());

        chdir($Eve::Registry::instance->working_dir_string);

        $event->trigger();

        return $event->response->get_raw_list();
    };

Those scripts must be set as a startup and request event handlers in
your C<VirtualHost> apache setting:

    # This is the startup script, it will be run on each apache service
    # start
    PerlPostConfigRequire /var/www/helloworld/bin/startup.pl

    PerlSetupEnv Off
    SetHandler perl-script
    PerlResponseHandler Plack::Handler::Apache2

    # This is the PSGI request event handler script
    PerlSetVar psgi_app /var/www/dev/eve/bin/http.psgi

=head1 DESCRIPTION

=head2 Layers of the system

The first layer of the system is the application layer that is
responsible for assembling all the components and dealing with
features specific to the type of the built program. It is the entry
point of the system. This layer operates with the delegation layer.

The second one is the delegation layer. It is a control delegation
facility based on a map of controlling events and handling code. For
example an event of the "blog post entry creation" type could initiate
delegation of control to quota check and statistics handlers
independently. This layer operates with the controlling layer and
could be requested by any other layer.

The third one is the controlling layer. Some applications, like web
services, could consist of many handling code parts mapped to many
types of controlling events. Each of the code parts itself could
resemble the MVC pattern controller component for example. So to post
a new blog post entry we might need to call a blog post creation
handler as an original MVC controller. This layer operates with the
enterprise layer.

The forth one is the enterprise layer. It might be represented as the
model and view parts of MVC pattern components interacting with each
other. In case of the blog posting example the model is a set of
objects representing a blog and the view is a template engine
interface that is responsible for building output. This layer operates
with the tools layer.

The fifth is the environmental layer. It includes things like database
adaptation code, external systems integration, template and output
engines internals. It interacts with databases, web services,
operation system and other external information sources.

=head2 Registry of services

The Inversion of Control is used as a base framework components
manipulation principle. It is reflected on the system as a registry of
services. A service is a definition of how the component should be
implemented and instantiated and which other components it depends on.

There is a central registry of the framework that contains generic
services. Also every subsystem has its own registry that the central
one refers to. So we have a hierarchical structure where we can
conveniently manage implementations without affecting the problem
specific parts.

=head2 Controlling events

Another technique we use to favor better decoupling of the components
is the Event-driven approach. There are three entities in the
implemented concept - an event itself, an event handler and the
mapping facility to map events to handlers. One event could be
inherited from another. This inheritance is used when triggering
events so the derivative will be triggered by handlers listening for
its ancestors.

=head2 Enterprise modeling

The modeling infrastructure of the framework is based on a set of
simple data objects managed by a set of model classes. The data
objects are simple field containers with service behavior injections
like serialization/deserialization. The domain logic is encapsulated
in the model classes. For example a blog post object having a title
and text fields is a data object and blogging is a model class
implementing such functionality as appending new post, listing blog
entries, etc.

The model classes interact with a persistence layer through data
gateways. These gateways implement data level functionality
adaptation. For example the comments gateway could implement select,
insert, update and delete operations for the comments database table
and transform data rows into comment data objects and vice versa. As
data gateways are differentiated based on data storage logic they can
be used by different model classes. For example comments gateway can
be used by blogging model and activity stream model.

=head2 Running an application

When building an application first of all we need to create the
application script. The script itself should create a registry
instance, map events to their handlers, setup other application
specific stuff and generate the initial event.

=head1 AUTHOR

Sergey Konoplev, C<< <gray.ru at gmail.com> >>

Igor Zinovyev, C<< <zinigor at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-eve at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Eve>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Eve


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Eve>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Eve>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Eve>

=item * Search CPAN

L<http://search.cpan.org/dist/Eve/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2009-2013 Igor Zinovyev, Sergey Konoplev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
