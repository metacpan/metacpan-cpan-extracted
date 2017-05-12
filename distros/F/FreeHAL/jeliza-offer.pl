#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify  
#   it under the terms of the GNU General Public License as published by  
#   the Free Software Foundation; either version 3 of the License, or     
#   (at your option) any later version.                                   
#                                                                         

$| = 1;

use File::Tee qw(tee);
tee(STDOUT, '>', 'freehal-offer-pl.log');
tee(STDERR, '>', 'freehal-offer-pl-err.log');

use strict;
use warnings;
use AI::FreeHAL::Config;

unshift @INC, ( 'Clone-0.28', '.' );

my $lang = shift || 'de';
our $start_proxy = 1;

sub LANGUAGE {
	return $lang;
}
sub no_answers_found {
}
require './jeliza-engine.pl' or require 'jeliza-engine.pl';

kill_all_subprocesses(noexit => 1);

sub impl_get_genus {
	my ( $CLIENT_ref, $word ) = @_;

	return 3;
}

sub impl_get_noun_or_not {
	my ( $CLIENT_ref, $word ) = @_;
	
	return 1;
}

sub impl_get_word_type {
	my ( $CLIENT_ref, $word ) = @_;

	return 7;
}

no strict;
$in_cgi_mode = 0;
use strict;

open my $protocol_memory, '>', 'protocol_memory.txt';
close $protocol_memory;

server_loop();
kill_all_subprocesses();
