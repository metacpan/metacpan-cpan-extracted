#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify  
#   it under the terms of the GNU General Public License as published by  
#   the Free Software Foundation; either version 3 of the License, or     
#   (at your option) any later version.                                   
#                                                                         

$| = 1;

use File::Tee qw(tee);
tee(STDOUT, '>', 'freehal.log');
tee(STDERR, '>', 'freehal-err.log');

use strict;
use warnings;
use AI::FreeHAL::Config;

unshift @INC, ( 'Clone-0.28', '.' );

my $lang = shift || 'de';
our $start_proxy = 0;


our $gui = 1;

# require './jeliza-engine.pl' or require 'jeliza-engine.pl';
use AI::FreeHAL::Engine;
use AI::Util;
use AI::FreeHAL::Module::Tagger;
$AI::Util::LANGUAGE = sub {
	return $lang;
};
*AI::FreeHAL::Engine::no_answers_found = sub {
};

AI::FreeHAL::Engine::kill_all_subprocesses(noexit => 1);

sub impl_get_genus {
	my ( $CLIENT_ref, $word ) = @_;
	my $CLIENT = $$CLIENT_ref;

	print $CLIENT 'GET_GENUS:' . $word . "\n"
	  or die "Error:" . 'GET_GENUS:' . $word . "\n";
	while ( my $line = get_client_response( $CLIENT_ref ) ) {
		chomp $line;
		print 'line: ' . $line . "\n";
		if ( $line =~ /HERE_IS_GENUS/ ) {
			$line =~ s/HERE_IS_GENUS[:]//i;
			return $line;
		}
	}
}

sub impl_get_noun_or_not {
	my ( $CLIENT_ref, $word ) = @_;
	my $CLIENT = $$CLIENT_ref;

	print $CLIENT 'GET_NOUN_OR_NOT:' . $word . "\n"
	  or die "Error:" . 'GET_NOUN_OR_NOT:' . $word . "\n";
	while ( my $line = get_client_response( $CLIENT_ref ) ) {
		chomp $line;
		print 'line: ' . $line . "\n";
		if ( $line =~ /HERE_IS_NOUN_OR_NOT/ ) {
			$line =~ s/HERE_IS_NOUN_OR_NOT[:]//i;
			return $line;
		}
	}
	print "\n\n\nCommunication Error!\n" . $CLIENT . "\n" . $word . "\n\n";
}

sub impl_get_word_type {
	my ( $CLIENT_ref, $word ) = @_;
	my $CLIENT = $$CLIENT_ref;

	print $CLIENT 'GET_WORD_TYPE:' . $word . "\n"
	  or die "Error:" . 'GET_WORD_TYPE:' . $word . "\n";
	while ( my $line = get_client_response( $CLIENT_ref ) ) {
		chomp $line;
		print 'line: ' . $line . "\n";
		if ( $line =~ /HERE_IS_WORD_TYPE/ ) {
			$line =~ s/HERE_IS_WORD_TYPE[:]//i;    
			return $line;
		}
	}
}

*AI::FreeHAL::Module::Tagger::impl_get_word_type = *impl_get_word_type;
*AI::FreeHAL::Module::Tagger::impl_get_noun_or_not = *impl_get_noun_or_not;
*AI::FreeHAL::Module::Tagger::impl_get_genus = *impl_get_genus;

no strict;
$in_cgi_mode = 0;
use strict;

open my $protocol_memory, '>', 'protocol_memory.txt';
close $protocol_memory;

AI::FreeHAL::Engine::server_loop();
AI::FreeHAL::Engine::kill_all_subprocesses();


1;