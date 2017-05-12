---
title: Home
---

<div id="index-banner">
<h1>Mercury <small>WebSocket Message Broker</small></h1>
<div class="latest-release">
    % my ( $latest ) = $site->app( 'blog' )->recent_posts( 1 );
    % if ( $latest ) {
        % my ( $version ) = $latest->title =~ /(v\d+[.]\d+(?:[.]\d+)?)/;
        <a href="<%= $latest->path %>">
            Latest release: <%= $version %>
            (<date><%= $latest->date->strftime( '%Y-%m-%d' ) %></date>)
        </a>
    % }
</div>
</div>

Mercury is a simple message broker that allows for some common messaging
patterns using WebSockets. This allows communication between web
browsers and other WebSocket-capable programs.

## Features

* Easy-to-install. If you've got Perl 5.10 or later, you can use
  Mercury.
* Multiple message patterns supported:
    * pub/sub - One-to-many pattern
    * bus - Many-to-many pattern
    * push/pull - Worker queue pattern
* Example JavaScript application included.

## Demo

Try out [the live demo of Mercury](http://preaction.me:3000/)

## Installing

Install the latest version of Mercury from CPAN:

    curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Mercury

## Getting Started

To use the example application locally, run:

    mercury broker

See [the mercury documentation](/pod/) for more information.

## Help

* [Get online help with our IRC channel, #statocles on
  irc.perl.org](https://chat.mibbit.com/?channel=%23statocles&server=irc.perl.org).
* [Report any issues or questions to the Mercury issue tracker on
  Github](http://github.com/preaction/Mercury/issues).

