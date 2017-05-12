#!/usr/bin/perl

#add an additional path to your search path
use lib '/path/to/your/private/modules';

#preload commonly used modules to share them across the processes to save memory
#all this preloading is optional
use CGI ();
CGI->compile(':all');
use Apache::DBI; Apache::DBI must be loaded before any DBI::* oder DBD::* module
use DBI;
use DBD::mysql;
use Session;

#core konstrukt stuff
use Konstrukt;
use Konstrukt::Handler;
use Konstrukt::Handler::Apache;

#preload modules
use Konstrukt::Plugin::blog;
use Konstrukt::Plugin::blog::DBI;
use Konstrukt::Plugin::bookmarks;
#...

1;
