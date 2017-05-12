#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use Javascript::MD5;

# ------------------

my($q)	= CGI -> new();
my($p)	= $q -> param('my_password') || '';
my($js)	= Javascript::MD5 -> new();

print $q -> header(),
      $q -> start_html({script => $js -> javascript('my_password'), title => 'Javascript::MD5'}),
      $q -> h1({align => 'center'}, 'Javascript::MD5'),
      "Previous value: $p",
      $q -> br(),
      $q -> start_form({action => $q -> url(), name => 'md5'}),
      'Username: ',
      $q -> textfield({name => 'my_username', size => 80}),
      $q -> br(),
      'Password: ',
      $q -> password_field({name => 'my_password', size => 80}),
      $q -> br(),
      'Generate str2hex_md5: ',
      $q -> submit({onClick => 'return str2hex_md5()'}),
      $q -> end_form(),
      $q -> end_html();
