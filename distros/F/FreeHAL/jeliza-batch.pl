#!/usr/bin/env perl

$| = 1;

use strict;
use warnings;

unshift @INC, ( '.' );

open my $file, '>', 'do-batch';
close $file;

our $dir = './';
our $batch = 1;
my $lang = shift || 'de';

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

our $unix_shell_mode = 1;


delete $INC{"AI/SemanticNetwork.pm"};
use Data::Dumper;
print Dumper \%INC;
require 'AI/SemanticNetwork.pm';


use AI::Util;
$AI::Util::batch = 1;
use AI::FreeHAL::Engine;
print 'batch...: ', $AI::FreeHAL::Engine::batch, "\n";
$AI::FreeHAL::Engine::batch = 1;
$AI::FreeHAL::Engine::data->{modes}{batch} = 1;

use AI::FreeHAL::Module::Tagger;
*AI::FreeHAL::Module::Tagger::impl_get_word_type = *impl_get_word_type;
*AI::FreeHAL::Module::Tagger::impl_get_noun_or_not = *impl_get_noun_or_not;
*AI::FreeHAL::Module::Tagger::impl_get_genus = *impl_get_genus;

use AI::Util;
$AI::Util::LANGUAGE = sub {
	return $lang;
};
*AI::FreeHAL::Engine::no_answers_found = sub {
};



$::config{'features'}{'news'} = 1;


#use Memoize;
#memoize('search_semantic');

print << "EOF";
This is FreeHAL BATCH rev. $AI::FreeHAL::Engine::FULL_VERSION

EOF

use AI::FreeHAL::Config;

open my $CLIENT, ">", "to-server.log";
close $CLIENT;

#load_word_types();


print "\n";
print "> ";
my $display_str = q{}; # empty

my $user = 'human';

if ( not( -f $dir . '/display.cfg' ) ) {
	open my $handle, ">", $dir . '/display.cfg';
	close $handle;
}
read_config( $dir . '/display.cfg' => my %config_display );
$config_display{'user_' . $user}{'display'} = '';
write_config( %config_display, $dir . '/display.cfg' );

AI::Util::client_setup( username => $user );

################# load_database_file( \$CLIENT, get_database_files() );
AI::FreeHAL::Engine::run_code(
    q{
    my @files = AI::FreeHAL::Engine::get_database_files();
    unshift @files,  "./lang_" . LANGUAGE() . '/actual_news.prot';
    open my $CLIENT, ">", "to-server.log";
    close $CLIENT;
    say "load_news();";
    AI::FreeHAL::Engine::start_ability_tagger();
    load_news(\$CLIENT);
    push_hooks();
    say "AI::SemanticNetwork::semantic_network_load_nosql(";
    AI::SemanticNetwork::semantic_network_load_nosql(
            files              => \@files,
            optional_hook_args => [ \$CLIENT ],
            execute_hooks => 1,            # !$persistent_loaded_successfully,
            client        => \$CLIENT,
            extra_hooks_for_more_prot_data => [ \&AI::FreeHAL::Engine::load_news ],
        );
    });

1;