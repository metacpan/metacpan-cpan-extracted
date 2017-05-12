#!/usr/bin/perl

use strict;
use CGI qw(:standard);

print header;
print start_html,
    h1('Embeding perl scripts example'),
    start_form(-action=>'/cgi/perl.pl'),
    "<img src='/LinuxQuestions.png'/>", 
    p,
    "What's your name? ",textfield('name'),
    p,
    "What's the combination?",
    p,
    checkbox_group(-name=>'words',
		   -values=>['eenie','meenie','minie','moe'],
		   -defaults=>['eenie','minie']),
    p,
    "What's your favorite color? ",
    popup_menu(-name=>'color',
	       -values=>['red','green','blue','chartreuse']),
    p,
    submit,
    end_form,
    hr;

if (param()) {
    print 
	"Your name is",em(param('name')),
	p,
	"The keywords are: ",em(join(", ",param('words'))),
	p,
	"Your favorite color is ",em(param('color')),
	hr;
}
print end_html;
