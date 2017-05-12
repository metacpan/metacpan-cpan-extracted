#!/usr/bin/perl -w
use strict;
use IRC::Bot;

my $bot = IRC::Bot->new(      
                         Debug    => 0,
                         Nick     => 'PerlBot',
     	     	         Server   => 'irc.ecnet.org',
			 Pass     => '',
                         Port     => '6667',
                         Username => 'TestBot',
                         Ircname  => 'TestBot',
			 Admin    => 'admin',
			 Apass    => 'changeme',
			 Channels => [ '#perl' ],
			 LogPath  => '',
			 NSPass	  => ''
                       );
$bot->daemon();
$bot->run();
