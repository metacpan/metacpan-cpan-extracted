#!/usr/bin/perl
use strict;
use warnings;
use CGI qw/ :standard /;
use HTML::Template;
use HTML::Template::Associate::FormField;

my %formfields= (
  StartForm=> { type=> 'opt_form' },
  Name  => { type=> 'textfield', size=> 30, maxlength=> 100 },
  Email => { type=> 'textfield', size=> 50, maxlength=> 200 },
  Sex   => { type=> 'select', values=> [0, 1, 2], labels=> { 0=> 'please select !!', 1=> 'man', 2=> 'gal' } },
  ID    => { type=> 'textfield', size=> 15, maxlength=> 15 },
  Passwd=> { type=> 'password', size=> 15, maxlength=> 15, default=> "", override=> 1 },
  submit=> { type=> 'submit', value=> ' Please push !! ' },
  );

my $cgi = CGI->new;
my $form= HTML::Template::Associate::FormField->new($cgi, \%formfields);
my $tp  = HTML::Template->new(
  associate => [$form],
  filename  => './Example.tmpl',
  );

print $cgi->header, $tp->output;
