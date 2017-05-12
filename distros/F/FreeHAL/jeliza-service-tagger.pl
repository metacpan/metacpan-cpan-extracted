#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify  
#   it under the terms of the GNU General Public License as published by  
#   the Free Software Foundation; either version 3 of the License, or     
#   (at your option) any later version.                                   
#                                                                         

#fork && exit;

open my $pidfile, '>', 'tagger.pid';
print $pidfile $$;
close $pidfile;

use strict;
use warnings;
use AI::FreeHAL::Config;

sub LANGUAGE {
	return 'de';
}
sub no_answers_found {
}

require './jeliza-engine.pl' or require 'jeliza-engine.pl';


sub impl_get_genus {
	my ( $CLIENT_ref, $word ) = @_;
	my $CLIENT = $$CLIENT_ref;
    
    alarm(60);

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

    alarm(60);

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

    alarm(60);

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



eval 'start_service_tagger();';
    
    