#!/usr/bin/env perl

$| = 1;

use strict;
use warnings;

unshift @INC, ( '.' );

our $dir = './';
my $lang = shift || 'de';
my $noinit = shift;
my $line = shift;

sub impl_get_genus {
	my ( $CLIENT_ref, $word ) = @_;

	print "
 Which gender is '" . $word . "'?
 
 1. male
 2. female
 3. neuter
 
 Please enter the number above and press ENTER;
 
 Number:\n";	
	my $num = <STDIN>;
	chomp $num;
	
	return $num;
}

sub impl_get_noun_or_not {
	my ( $CLIENT_ref, $word ) = @_;

	print "
 Is '" . $word . "' meant as a noun here?
 
 1. '" . $word . "' is a noun
 2. '" . $word . "' is not a noun
 
 Please enter the number above and press ENTER;
 
 Number:\n";
	my $num = <STDIN>;
	chomp $num;
	
	if ( $num =~ /3/ ) {
		$num = 1;
	}
	
	return $num;
}

sub impl_get_word_type {
	my ( $CLIENT_ref, $word ) = @_;

					print "
 Which word type is '" . $word . "'?
 
 1. verb
 2. noun oder name
 3. adjective oder adverb
 4. pronoun
 5. question word or conjunction
 6. preposition
 7. interjection
 
 Please enter the number above and press ENTER;
 
 Number:\n";
	my $num = <STDIN>;
	chomp $num;
	
	return $num;
}

our $unix_shell_mode = 2;

use AI::FreeHAL::Engine;


*AI::FreeHAL::Engine::no_answers_found = sub {
};

use AI::Util;
$AI::Util::LANGUAGE = sub {
	return $lang;
};

AI::FreeHAL::Engine::kill_all_subprocesses(noexit => 1);

use Memoize;
#memoize('search_semantic');

no strict;
no warnings;
print << "EOF";
This is FreeHAL rev. $FULL_VERSION

EOF
use strict;
use warnings;
use AI::FreeHAL::Config;

open my $CLIENT, ">", "to-server.log";
close $CLIENT;

my $display_str = q{}; # empty

my $user = 'human';

if ( not( -f $dir . '/display.cfg' ) ) {
	open my $handle, ">", $dir . '/display.cfg';
	close $handle;
}
read_config( $dir . '/display.cfg' => my %config_display );
$config_display{'user_' . $user}{'display'} = '';
write_config( %config_display, $dir . '/display.cfg' );

no strict;
AI::FreeHAL::Engine::client_setup( data => *AI::FreeHAL::Engine::data, username => $user );
use strict;

#if ( $noinit ) {
# load_word_types();
#}
AI::FreeHAL::Engine::load_database_file( \$CLIENT, AI::FreeHAL::Engine::get_database_files(), $noinit );

if ( $noinit ) {
	open my $CLIENT, ">>", "to-server.log";

	my $dialog = AI::FreeHAL::Engine::ask( \$CLIENT, $line, \$display_str, $user );
	$dialog =~ s/[:]+/:/igm;
	$dialog =~ s/((^|([<]br[>])))<b>Mensch<\/b>[:]\s+/$1You:     /igm;
	$dialog =~ s/[<]br[>]/\n/igm; 
	$dialog =~ s/[<](.*?)[>]//igm;
	$dialog =~ s/\s*$//igm;
	$dialog =~ s/^\s*//igm;

	print `clear`;


	print $dialog . "\n";
}
else {
	#load_word_types();
	
	use File::Spec;

	print "\n";
	print "> ";

	while (my $line = <STDIN>) {
		
		
		chomp $line;

		system( qq{perl},
				File::Spec->rel2abs( qq{jeliza-shell.pl} ),
				LANGUAGE(),
				1,
				$line,
			);

		print "> ";
		
	}
}
AI::FreeHAL::Engine::exit_handler();

1;