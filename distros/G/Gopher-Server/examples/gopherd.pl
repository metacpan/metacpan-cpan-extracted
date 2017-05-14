#!/usr/local/bin/perl
# 
# A simple Gopher server
# 
use strict;
use warnings;
use Gopher::Server::ParseRequest;
use Gopher::Server::RequestHandler::File;

# Constants
sub HOSTNAME ()  {  'localhost'  }
sub PORT ()      {  70           }
sub ROOT ()      {  '/home/www/data/gopher/' }


{
}

