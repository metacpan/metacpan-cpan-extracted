#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use Javascript::SHA1;

# ------------------

my($q)	= CGI -> new();
my($p)	= $q -> param('my_password') || '';
my($js)	= Javascript::SHA1 -> new();

print $q -> header(),
      $q -> start_html({script => $js -> javascript('my_password'), title => 'Javascript::SHA1'}),
      $q -> h1({align => 'center'}, 'Javascript::SHA1'),
      "Previous value: $p",
      $q -> br(),
      $q -> start_form({action => $q -> url(), name => 'sha1'}),
      'Username: ',
      $q -> textfield({name => 'my_username', size => 80}),
      $q -> br(),
      'Password: ',
      $q -> password_field({name => 'my_password', size => 80}),
      $q -> br(),
      'Generate str2hex_sha1: ',
      $q -> submit({onClick => 'return str2hex_sha1()'}),
      $q -> end_form(),
      $q -> end_html();
