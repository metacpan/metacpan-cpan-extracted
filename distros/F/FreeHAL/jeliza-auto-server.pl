#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify  
#   it under the terms of the GNU General Public License as published by  
#   the Free Software Foundation; either version 3 of the License, or     
#   (at your option) any later version.                                   
#                                                                         

$| = 1;

use strict;
use warnings;
use AI::FreeHAL::Config;

use File::Tee qw(tee);
tee(STDOUT, '>', 'freehal.log');
tee(STDERR, '>', 'freehal-err.log');

unshift @INC, ( 'Clone-0.28', '.' );

my $lang = shift || 'de';
our $unix_shell_mode = 2;
our $start_proxy = 2;


use AI::FreeHAL::Engine;

use AI::Util;
$AI::Util::LANGUAGE = sub {
	return $lang;
};
*AI::FreeHAL::Engine::no_answers_found = sub {
};


sub impl_get_genus {
	my ( $CLIENT_ref, $word ) = @_;
	my $CLIENT = $$CLIENT_ref;

	return 3;
}

sub impl_get_noun_or_not {
	my ( $CLIENT_ref, $word ) = @_;
	my $CLIENT = $$CLIENT_ref;

	return 1;
}

sub impl_get_word_type {
	my ( $CLIENT_ref, $word ) = @_;
	my $CLIENT = $$CLIENT_ref;

	return 7;
}

use AI::FreeHAL::Module::Tagger;
*AI::FreeHAL::Module::Tagger::impl_get_word_type = *impl_get_word_type;
*AI::FreeHAL::Module::Tagger::impl_get_noun_or_not = *impl_get_noun_or_not;
*AI::FreeHAL::Module::Tagger::impl_get_genus = *impl_get_genus;

no strict;
$in_cgi_mode = 0;
use strict;




AI::FreeHAL::Engine::server_loop();
#server_offer();



1;