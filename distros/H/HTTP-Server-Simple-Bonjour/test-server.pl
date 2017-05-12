#!/usr/bin/perl
use strict;
package MyServer;
use base qw( HTTP::Server::Simple::Bonjour HTTP::Server::Simple::CGI );

package main;
MyServer->new->run;
