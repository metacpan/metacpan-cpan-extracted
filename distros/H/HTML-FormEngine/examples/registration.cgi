#!/usr/bin/perl -w

use strict;
use CGI;
use HTML::FormEngine;
#use POSIX; # for setlocale
#setlocale(LC_MESSAGES, 'german'); # for german error messages

my $q = new CGI;
print $q->header;

my $Form = HTML::FormEngine->new(scalar $q->Vars);
my @form = (
	    {
	      templ => 'select',
	      NAME => 'Salutation',
	      OPTION => [[['mr.','mrs.']]],
	    },
	    {
	      templ => 'hidden_no_title',
	      NAME => 'test123',
	      VALUE => 'test',
	    },
	    {
	     SIZE => 10,
	     MAXLEN => 20,
	     PREFIX => [['&nbsp;', '&nbsp;/&nbsp;']],
	     NAME => 'name',
	     TITLE => 'For- / Surname ',
             ERROR_IN => 'not_null'
	    },
	    {
	      MAXLEN => 30,
	      NAME => 'Email',
	      ERROR => ['not_null', ['rfc822'], ['match', 'matched net!']] # rfc822 defines the email address standard
	    },
	    {
	     templ => 'radio',
	     TITLE => 'Subscribe to newsletter?',
	     NAME => 'newsletter',
	     OPT_VAL => [[1, 2, 3]],
	     OPTION => [['Yes', 'No', 'Perhaps']],
	     VALUE => 1
	    },
	    {
	     templ => 'check',
             OPTION => 'I agree to the terms of condition!',
             NAME => "agree",
	     TITLE => '',
	     ERROR => sub{ return("you've to agree!") if(! shift); }
	    }
);

$Form->set_seperate(1);
$Form->conf(\@form);
$Form->make();

print $q->start_html('FormEngine example: Registration');
if($Form->ok){
  $Form->clear();	
  print "<center>You've successfully subscribed!</center><br>";
}
print $Form->get,
      $q->end_html;
