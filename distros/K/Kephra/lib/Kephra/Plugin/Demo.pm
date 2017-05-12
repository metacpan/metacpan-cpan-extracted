package Kephra::Plugin::Demo;
use strict;
use warnings;

our $VERSION = '0.01';

#################################################
# Demoplugin as an tutorial for plugin authors
#################################################

our $commands = {
	'open' => {
		call => 'show_dialog()',
		label => 'Demo Plugin',
		key => 'alt+shift+D',
		icon => '',
		menu => 'OWN',
	} 
};

sub init {
}

sub start {
}

sub show_dialog {
}

1;
