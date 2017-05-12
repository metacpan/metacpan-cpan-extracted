# $Id: /mirror/gungho/lib/Gungho.pm 67350 2008-07-28T10:37:01.975672Z lestrrat  $
# 
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho;
use strict;
use warnings;
use 5.008;
use base qw(Class::C3::Componentised);
our $VERSION = '0.09008';

__PACKAGE__->load_components('Setup');

sub component_base_class { "Gungho::Component" }

1;

__END__

=head1 NAME

Gungho - Yet Another High Performance Web Crawler Framework

=head1 SYNOPSIS

  use Gungho;
  Gungho->run($config);

=head1 DESCRIPTION

Gungho provides a complete out-of-the-box web crawler framework with
high performance and great felxibility.

Please note that Gungho is in beta. It has been stable for some time, but
its internals may still change, including the API.

Gungho comes with many features that solve recurring problems when building
a spider:

=over 4

=item Event-Based, Asynchronous Engine

Gungho uses event-based dispatch via POE, Danga::Socket, or IO::Async.
Choose the best engine that fits your needs.

=item Asynchronous DNS lookups

HTTP connections are handled asynchronously, why not DNS lookups?
Gungho doesn't block while hostnames are being resolved, so other jobs can
continue.

=item Automatic robots.txt Handling

Every crawler needs to respect robots.txt. Gungho offers automatic handling
of robots.txt. If you use it in conjunction with memcached, you can even
do this in a distributed environment, where farms of Gungho crawler hosts
are all fetching pages.

=item Robots META Directives

Robots META directives embedded in HTML text can also be parsed automatically.
You can then access this resulting structure to decide if you can process
the fetched URL.

=item Throttling

You don't want your crawl targets to go under just because you let loose a
crawler against it and did a million fetches per hour. With Gungho's 
throttling component, you can throttle the amount of requests that are sent
against a domain.

=item Private IP Blocking

Malicious sites may embed hostnames that resolve to internal IP address ranges
such as 192.168.11.*, which may lead to a DoS attack to your private servers.
Gungho has an automatic option to block such IP addresses via BlockPrivateIP
component.

=item Caching

Whatever you want to cache, Gungho offers a generic cache interface a-la
Catalyst via Gungho::Component::Cache

=item Web::Scraper Integration

(Note: This is not quite production ready) Gungho has Web::Scraper integration
that allows you to easily call Web::Scraper sripts defined in your config files.

=item Request Logging

Requests can be automatically logged to a file, a database, to screen, via
Gungho::Plugin::RequestLog, which gives you the full power of Log::Dispatch
for your logging needs.

=back

=head1 HISTORY

First there were a bunch of scripts that used scrape a bunch of RSS feeds.
Then I got tired of writing scripts, so I decided a framework is the way to
go, and Xango was born.

Xango was my first attempt at trying to harness the full power of event-based
framework. It was fast. It wasn't fun to extend. It had a nightmare-ish
way to deal with robots.txt. 

Couple of more attempts later, more inspirations and lessons learned from
Catalyst, Plagger, DBIx::Class, Gungho was born. 

Since its inception, Gungho has been in successfully used as crawlers that
fetch hundreds of thousands of urls to a few million urls per day. 

=head1 PLEASE READ BEFORE USE

Gungho is designed to so that it can handle massive amount of traffic.
If you're careful enough with your Provider and Handler implementation, you
can in fact hit millions of URL with this crawler.

So PLEASE DO NOT LET IT LOOSE. DO NOT OVERLOAD your crawl targets.
You are STRONGLY advised to use Gungho::Component::Throttle to throttle your 
fetches. 

Also PLEASE CHANGE THE USER AGENT NAME OF YOUR CRAWLER. If you hit your targets
hard with the default name (Gungho/VERSION X.XXXX), it will look as though a
service called Gungho is hitting their site, which really isn't the case.
Whatever it is, please specify at least a simple user agent in your config

=head1 STRUCTURE

Gungho is comprised of three parts. A Provider, which provides Gungho with
requests to process, a Handler, which handles the fetched page, and an
Engine, which controls the entire process.

There are also "hooks". These hooks can be registered from anywhere by
invoking the register_hook() method. They are run at particular points,
which are specified when you call register_hook().

All components (engine, provider, handler) are overridable and switcheable.
However, do note that if you plan on customizing stuff, you should be aware
that Gungho uses Class::C3 extensively, and hence you may see warnings about
the code you use.

=head1 HOW *NOT* TO USE Gungho

One note about Gungho - Don't use it if you are planning on accessing
a single url -- It's usually not worth it, so you might as well use
LWP::UserAgent or an equivalent module.

Gungho's event driven engine works best when you are accessing hundreds,
if not thousands of urls. It may in fact be slower than using LWP::UserAgent
if you are accessing just a single url.

Of course, you may wish to utilize features other than speed that Gungho 
provides, so at that point, it's simply up to you.

=head1 RUNNING IN DISTRIBUTED ENVIRONMENT

Gungho has experimental support for running in distributed environments.

Strictly speaking, each crawler needs to have its own strategy to enable
itself to to run in a distribued environment. What Gungho offers is a
"good enough" solution that I<may> work for your. If what Gungho offers
isn't enough, at least what comes with it might help to show you what
needs to be tweaked for your particular environment.

Roughly speaking, there are three components you need to worry about in order
to make a well bahaved and distributed crawler. Check out the below list
and documentation for each component. 

=over 4

=item Distributed Throttling

As of version 0.08010, Throttle::Domain and Throttle::Simple can be configured
to use whatever Data::Throttler-based throttling object as its engine.

Download Data::Throttler::Memcached, and specify it as the engine behind
your throttling for Gungho. Using Data::Throttler::Memcached  will make
Gungho store throttling information in a shared Memcached server, which will 
allow separate Gungho instances to share that information.

=item Distributed robots.txt Handling

As of version 0.08013, RobotRules can be configured to use a cache in the
backend. You can specify your choice of distributed cache (e.g. Memcached)
and use that as the storage for robots.txt data.

Of course, this means that robots.txt data isn't persitent, but you should be
expiring robots.txt once in while to reflect new data, anyways.

=item Distributed Provider

This is actually the simplest aspect, as it's usually done by hooking the
provider with a database. However, if you prefer, you may use some sort of
Message Queue as your backend.

=back

=head1 GLOBAL CONFIGURATION OPTIONS

=over 4

=item debug

   ---
   debug: 1

Setting debug to a non-zero value will trigger debug messages to be displayed.

=back

=head1 COMPONENTS

Components add new functionality to Gungho. Components are loaded at
startup time from the config file / hash given to Gungho constructor.

  Gungho->run({
    components => [
      'Throttle::Simple'
    ],
    throttle => {
      max_interval => ...,
    }
  });

Components modify Gungho's inheritance structure at run time to add
extra functionality to Gungho, and therefore should only be loaded
before starting the engine.

Please refer to each component's document for details

=over 4

=item Gungho::Component::Authentication::Basic

=item Gungho::Component::BlockPrivateIP

=item Gungho::Component::Cache

=item Gungho::Component::RobotRules

=item Gungho::Component::RobotsMETA

=item Gungho::Component::Scraper

=item Gungho::Component::Throttle::Domain

=item Gungho::Component::Throttle::Simple

=back

=head1 INLINE

If you're looking into simple crawlers, you may want to look at Gungho::Inline,

  Gungho::Inline->run({
    provider => sub { ... },
    handler  => sub { ... }
  });

See the manual for Gungho::Inline for details.

=head1 PLUGINS

Plugins are different from components in that, whereas components require the
developer to explicitly call the methods, plugins are loaded and are not
touched afterwards.

Please refer to the documentation of each plugin for details.

=over 4

=item RequestLog

=item Statistics

=back

=head1 HOOKS

Currently available hooks are:

=head2 engine.send_request

=head2 engine.handle_response

=head1 METHODS

=head2 component_base_class

Used for Class::C3::Componentised

=head1 CODE

You can obtain the current code base from

  http://gungho-crawler.googlecode.com/svn/trunk

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 CONTRIBUTORS

=over 4

=item Jeff Kim

=item Kazuho Oku

=item Keiichi Okabe

=back

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
