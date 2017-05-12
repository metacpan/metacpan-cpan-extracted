#!/usr/bin/perl
# $Id$
use strict;

use CGI qw(:standard);
use Mac::iTunes;
use Text::Template;

my $Template = '/Users/brian/Dev/MacOSX/iTunes/html/iTunes.html';

=head1 NAME

iTunes.cgi - control iTunes from the web

=head1 SYNOPSIS

run as a CGI script

=head1 DESCRIPTION

This is only a proof-of-concept script.

=head1 AUTHOR

brian d foy, E<lt>bdfoy@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2002 brian d foy, All rights reserved

=cut

my $controller = Mac::iTunes->new()->controller;

my $command      = param('command');
my $playlist     = param('playlist') || 'Library';
my $set_playlist = param('set_playlist');

if( $command )
	{
	my %Commands = map { $_, 1 } qw( play stop pause back_track);
	$controller->$command if exists $Commands{$command};
	}
elsif( $set_playlist )
	{
	$controller->_set_playlist( $set_playlist );
	$playlist = $set_playlist;
	}

my %var;

$var{base}      = 'http://10.0.1.2:8080/cgi-bin/iTunes.cgi';
$var{state}     = $controller->player_state;
$var{current}   = $controller->current_track_name;
$var{playlist}  = $playlist;
$var{playlists} = $controller->get_playlists;
$var{tracks}    = $controller->get_track_names_in_playlist( $playlist );

my $html = Text::Template::fill_in_file( $Template, HASH => \%var );

print header(), $html, "\n";
