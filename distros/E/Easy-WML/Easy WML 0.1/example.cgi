#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);

use Easy

my $site = new Easy->header('card1', 'My First Card Deck');

$site = Easy->img('http://www.mcarterbrown.com/wapimages/logo.wbmp', 'My Logo', 'center');

$site = Easy->print('<br>Hello there.. this is my first WAP site... <br><br>test...');

$site = Easy->link('http://www.mcarterbrown.com/index.wml', 'Carter\'s Web Page', 'center');

$site = Easy->footer();

exit;
