package AI::Util;

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

    # set the version for version checking
    $VERSION = 0.01;

    @ISA = qw(Exporter);

    # functions
    @EXPORT = qw(
        &say
        &connect_to
        &only_have_ability
        &be_service
        &kill_all_subprocesses
        &kill_process_from
        &client_setup
        &LANGUAGE
        &get_data
        &exit_handler
        &is_array
        &ascii
        &get_client_response
    );
    %EXPORT_TAGS = ();    # eg: TAG => [ qw!name1 name2! ],
    
    my @subpaths = ('AI/FreeHAL/Module/');
    my @modules_with_functions;
        
    our $data = {};    
    sub get_data {
        return $data;
    }

    foreach my $_inc_path ('.', @INC) {
        foreach my $subpath (@subpaths) {
            my $inc_path = $_inc_path . '/' . $subpath;
            print "- Looking in ", $inc_path, "\n";
            opendir(my $directory, $inc_path);
            my @files = grep { /\.pm$/i } readdir($directory);
            closedir($directory);
            
            FILE:
            foreach my $file (@files) {
                my $filename = $inc_path . $file;
                print "  - Found: ", $filename, "\n";
                
                my $module = $subpath . $file;
                $module =~ s/\..*?$//gm;
                $module =~ s/\//::/gm;
                print "    - Module: ", $file, "\n";

                eval 'use ' . $module . ';';
                if ($@) {
                    print '      - ', $@, "\n" ;                    
                    print '      - next...', "\n";
                    next FILE;
                };
                print '      - ', $@, "\n" if $@;
                

                eval {
                    $SIG{__DIE__} = 'IGNORE';
                    my @funcs;
                    eval '@funcs = @' . $module . '::functions;';
                    print '      - ', $@, "\n" if $@;
                    eval '*' . $module . '::get_data = *get_data;';
                    eval '*' . $module . '::data = *data;';
                    print '      - ', $@, "\n" if $@;
                    
                    if ( @funcs ) {
                        foreach my $func (@funcs) {
                            print "      - Function: ", $func, "\n";
                            eval '*' . $func . ' = *' . $module . '::' . $func . ';';
                            push @modules_with_functions, [ '*' . $module . '::' . $func, $func ];
                            print '      -', $@, "\n" if $@;
                            push @EXPORT, '&' . $func;
                        }
                    }
                    else {
                        print "      - No functions given.\n";
                    }
                };
                print $@, "\n" if $@;
            }
        }
    }
    
    my @modules_found = ();
    
    foreach my $_inc_path ('.', @INC) {
        foreach my $subpath (@subpaths) {
            my $inc_path = $_inc_path . '/' . $subpath;
            opendir(my $directory, $inc_path);
            my @files = grep { /\.pm$/i } readdir($directory);
            closedir($directory);
            
            FILE:
            foreach my $file (@files) {
                my $filename = $inc_path . $file;
                
                my $module = $subpath . $file;
                $module =~ s/\..*?$//gm;
                $module =~ s/\//::/gm;

                eval 'use ' . $module . ';';
                if ($@) {
                    print '      - ', $@, "\n" ;                    
                    print '      - next...', "\n";
                    next FILE;
                };
                
                push @modules_found, $module;
                

                eval {
                    $SIG{__DIE__} = 'IGNORE';
                    
                    if ( @modules_with_functions ) {
                        foreach my $func (@modules_with_functions) {
                            my $str_to_eval = '*' . $module . '::' . $func->[1] . ' = ' . $func->[0] . ' if ' . $func->[0] . ';';
                            #print 'eval ', $str_to_eval , ';', "\n";
                            eval $str_to_eval;
                            print $@, "\n" if $@;
                        }
                    }
                };
                print $@, "\n" if $@;
            }
        }
    }
    
    
    my $str_to_eval = map { 'use ' . $_ . ';' . "\n" } @modules_found;
    print $str_to_eval;
    eval $str_to_eval;
    print $@, "\n" if $@;
    foreach my $module (@modules_found) {
        eval {
            $SIG{__DIE__} = 'IGNORE';
            
            if ( @modules_with_functions ) {
                foreach my $func (@modules_with_functions) {
                    my $str_to_eval = '*' . $module . '::' . $func->[1] . ' = ' . $func->[0] . ' if ' . $func->[0] . ';';
                    #print 'eval ', $str_to_eval , ';', "\n";
                    eval $str_to_eval;
                    print $@, "\n" if $@;
                }
            }
        };
        print $@, "\n" if $@;
    }

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK = qw();
}
our @EXPORT_OK;

use Data::Dumper;
use AI::FreeHAL::Config;

our $LANGUAGE;
our $batch;

sub LANGUAGE {
    return &$LANGUAGE;
}

sub say {
    print scalar localtime;
    print ': ';
    print grep { defined $_ } @_;
    print "\n";
    return 1;
}

=head2 get_client_response( $CLIENT_ref )

Returns the next line sent from socket reference $CLIENT_ref.

=cut

sub get_client_response {
    my ( $CLIENT_ref, $not_exit_this_thread ) = @_;
    my $CLIENT = $$CLIENT_ref;

    read_config $data->{intern}{config_file} => my %config;

    my $line = '';
    while ( defined( $line = <$CLIENT> ) ) {
        chomp $line;
        next if $line =~ /^EMPTY/;

        #        print $line . "\n";

        $line =~ s/[:]/: /igm;
        $line =~ s/[:]\s+[:]\s+/::/igm;
        my @parts = split /[:]\s+/, $line;

        if ( $line =~ /^EXIT/ ) {
            kill_all_subprocesses();
            exit 0;
        }

        if ( $line =~ /^HERE_IS_.*?EXIT$/ ) {
            next;
            threads->self()->kill('TERM') if !$not_exit_this_thread;
            threads->self()->kill('KILL') if !$not_exit_this_thread;
            return 'EXIT_THREAD'          if $not_exit_this_thread;
        }

        if ( $line =~ /^OFFLINE_MODE/ ) {
            $config{'modes'}{'offline_mode'} = $parts[1];
            $config{'modes'}{'offline_mode'} = 0
              if !$config{'modes'}{'offline_mode'};
            print '$config{\'modes\'}{\'offline_mode\'} = ',
              $config{'modes'}{'offline_mode'}, "\n";
            write_config %config, $data->{intern}{config_file};

            next;
        }

        if ( $line =~ /^SPEECH_MODE/ ) {
            $config{'modes'}{'speech_mode'} = $parts[1];
            print '$config{\'speech\'}{\'activated\'} = ',
              $config{'modes'}{'speech_mode'}, "\n";
            write_config %config, $data->{intern}{config_file};

            next;
        }

        if ( $line =~ /^GET_DB_STRING/ ) {
            my @lines = ();

            opendir( my $dir_handle,
                $data->{intern}{dir} . "/lang_" . LANGUAGE() );
            foreach my $filename ( readdir $dir_handle ) {
                next if $filename =~ /^\./;
                next if $filename !~ /\.pro$/;

                open my $db_file, "<",
                  $data->{intern}{dir} . "/lang_" . LANGUAGE() . '/' . $filename
                  or warn "Error while opening file: $!";
                push @lines, <$db_file>;
                close $db_file;
            }
            closedir $dir_handle;

            my $db_string = q{};    # empty
            map { chomp $_ } @lines;

            $db_string .= join '<BR>', sort @lines;
            $parts[1] =~ s/[:]/::/igm;
            print $CLIENT "HERE_IS_DB_STRING:", $db_string, ':', $parts[1],
              "\n";

            next;
        }

        last;
    }
    return $line;
}

sub connect_to {
    my %arg = ();
    %arg = ( %arg, @_ );
    
    local *data = $arg{data};
    read_config $data->{intern}{config_file} => my %config;

    my $server =
         $arg{host}
      || $config{'servers'}{ 'host_' . $arg{name} }
      || '127.0.0.1';
    my $port = $arg{port} || $config{'servers'}{ 'port_' . $arg{name} };

    if ( !$server || !$port ) {
        say ' information for: ', $arg{name};
        say 'server: ',                     $server;
        say 'port:   ',                     $port;
        return \undef;
    }

    if ( $port =~ /no/ && $server =~ /no/ ) {
        $data->{abilities}->{ $arg{name} } = 1;

        only_have_ability( name => $arg{name} );

        return \undef;
    }

    my $sock = new IO::Socket::INET(
        PeerAddr => $server,
        PeerPort => $port,
        Proto    => 'tcp',
        Blocking => 1,
    );

    if ( !$sock && !$arg{no_reconnect} ) {
        if ( !$sock && !$data->{abilities}->{ $arg{name} } ) {
            $sock = ${
                connect_to(
                    data         => $data,
                    name         => $arg{name},
                    host         => '127.0.0.1',
                    no_reconnect => 1
                )
              };
        }

        select undef, undef, undef, 1;

        if ( !$sock && !$data->{abilities}->{ $arg{name} } ) {
            $sock = ${
                connect_to(
                    data         => $data,
                    name         => $arg{name},
                    host         => '127.0.0.1',
                    no_reconnect => 1
                )
              };
        }

        select undef, undef, undef, 1;

        if ( !$sock && !$data->{abilities}->{ $arg{name} } ) {
            $sock = ${
                connect_to(
                    data         => $data,
                    name         => $arg{name},
                    host         => '127.0.0.1',
                    no_reconnect => 1
                )
              };
        }

        select undef, undef, undef, 1;

        if ( !$sock && !$data->{abilities}->{ $arg{name} } ) {
            $sock = ${
                connect_to(
                    data         => $data,
                    name         => $arg{name},
                    host         => '127.0.0.1',
                    no_reconnect => 1
                )
              };
        }

        select undef, undef, undef, 1;

        if ( !$sock && !$data->{abilities}->{ $arg{name} } ) {
            say 'service is down: ', $arg{name};
            say 'server: ',          $server;
            say 'port:   ',          $port;
            say 'I will be ',        $arg{name}, '!';

            be_service( name => $arg{name} );

            return connect_to(
                    data         => $data,
                    name => $arg{name},
                    host => '127.0.0.1'
                );
        }
    }

    return \$sock;
};

sub only_have_ability {
    my %arg = ();
    %arg = ( %arg, @_ );


    my $service = $arg{name};

    if ( !$service ) {
        say 'cannot be nothing. no service specified to only_have_ability();';
        return;
    }

    eval "AI::FreeHAL::Engine::start_ability_$service();";
    if ($@) {
        say $@;
    }
}

sub be_service {
    my %arg = ();
    %arg = ( %arg, @_ );

    my $service = $arg{name};

    if ( !$service ) {
        say 'cannot be nothing. no service specified to be_service();';
        return;
    }

    # eval 'start_service_' . $service . '();';

    my $filename = 'jeliza-service-' . $service . '.pl';
    open my $file, '>', $filename;
    print $file q[#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify  
#   it under the terms of the GNU General Public License as published by  
#   the Free Software Foundation; either version 3 of the License, or     
#   (at your option) any later version.                                   
#                                                                         

#fork && exit;

open my $pidfile, '>', '] . $service . q[.pid';
print $pidfile $$;
close $pidfile;

use strict;
use warnings;
use AI::FreeHAL::Config;

sub LANGUAGE {
	return '] . LANGUAGE() . qq[';
}
sub no_answers_found {
}

require './jeliza-engine.pl' or require 'jeliza-engine.pl';

] . q[
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

sub impl_get_pos {
	my ( $CLIENT_ref, $word ) = @_;
	my $CLIENT = $$CLIENT_ref;

    alarm(60);

	print $CLIENT 'GET_POS:' . $word . "\n"
	  or die "Error:" . 'GET_POS:' . $word . "\n";
	while ( my $line = get_client_response( $CLIENT_ref ) ) {
		chomp $line;
		print 'line: ' . $line . "\n";
		if ( $line =~ /HERE_IS_POS/ ) {
			$line =~ s/HERE_IS_POS[:]//i;    
			return $line;
		}
	}
}

] . qq[

eval 'start_service_$service();';
    
    ];
    close $file;

    kill_process_from( $service . '.pid' );

    select undef, undef, undef, 2;

    if ( lc($^O) =~ /win/ ) {
        if ( -f 'tagger-perl.exe' ) {
            system( 'start', 'tagger-perl.exe', $filename );
        }
        else {
            system( 'start', 'perl.exe', $filename );
        }
    }
    else {
        system( 'perl ' . $filename . ' &' );
    }

    select undef, undef, undef, 10;
}

sub kill_all_subprocesses {
    my %arg = @_;

    opendir( my $direc, '.' );
    my @pidfiles = grep { /pid$/ } readdir($direc);
    closedir $direc;
    foreach my $file ( @pidfiles ) {
        #kill_process_from($file);
        print "killed $file";
    }
}

sub kill_process_from {
    my ($file) = @_;

    -f $file or return;

    open my $pidfile, '<', $file or return;
    my $pid = <$pidfile> or return;
    print "\n", $pid, "\n";
    chomp $pid;
    close $pidfile or return;


    return if !$pid;
    return if $pid == $$;
    return if -$pid == $$;
    return if $pid == -$$;


    if ( lc($^O) =~ /win/ ) {
        kill( -9, $pid );
    }
    else {
        kill 9 => $pid;
    }
    unlink $pidfile;
}

sub client_setup {
    my ($data) = $_[1];

    $data->{connection}{client_info} = {
        username => 'human',

        # socket_tagger => connect_to(name => 'tagger'),
        @_,
    };
    close ${ connect_to(
            data         => *data,
            name => 'tagger'
        ) };
    #say 'client_setup:';
    say 'client_setup!';
}

sub exit_handler {
    kill_all_subprocesses();
    say @_;
    exit(0);
}

sub is_array {
    my ($ref) = @_;

    print ref($ref) . "\n";
    return ref($ref) eq 'ARRAY';
}

$data->{lang}{is_ascii_character} = {
    map { $_ => 1 } (
        'a' .. 'z',
        'A' .. 'Z',
        '0' .. '9',
        ' ', qw{/ ( ) & % $ " ' ! . ? ; - = > < + _},
        '[', ']', '{', '}', ',',
    )
};

my %UMLAUTE = (
    'Ä' => 'Ae',
    'Ö' => 'Oe',
    'Ü' => 'Ue',
    'ä' => 'ae',
    'ö' => 'oe',
    'ü' => 'ue'
);
my @UMLKEYS = join( "|", keys(%UMLAUTE) );

=head2 ascii($sent)

Returns $sent without non-ascii characters.

=cut

sub ascii {
    my ($sent) = @_;

    $sent =~ s/(@UMLKEYS)/$UMLAUTE{$1}/g;

    my @old = split //, $sent;

    #	say Dumper \@old;
    $sent = '';
    while ( defined( my $c = shift @old ) ) {

        #		say $c;
        #		say ord $c;

        if    ( ( ord $c ) == 228 ) { $sent .= 'ae' }
        elsif ( ( ord $c ) == 196 ) { $sent .= 'Ae' }
        elsif ( ( ord $c ) == 252 ) { $sent .= 'ue' }
        elsif ( ( ord $c ) == 220 ) { $sent .= 'Ue' }
        elsif ( ( ord $c ) == 246 ) { $sent .= 'oe' }
        elsif ( ( ord $c ) == 214 ) { $sent .= 'Oe' }
        elsif ( ( ord $c ) == 223 ) { $sent .= 'ss' }
        elsif ( ( ord $c ) == 195 && ord $old[0] == 164 ) {
            shift @old;
            $sent .= 'ae';
        }
        elsif ( ( ord $c ) == 195 && ord $old[0] == 188 ) {
            shift @old;
            $sent .= 'ue';
        }
        elsif ( ( ord $c ) == 195 && ord $old[0] == 182 ) {
            shift @old;
            $sent .= 'oe';
        }
        elsif ( ( ord $c ) == 195 && ord $old[0] == 132 ) {
            shift @old;
            $sent .= 'Ae';
        }
        elsif ( ( ord $c ) == 195 && ord $old[0] == 165 ) {
            shift @old;
            $sent .= 'Ue';
        }
        elsif ( ( ord $c ) == 195 && ord $old[0] == 150 ) {
            shift @old;
            $sent .= 'Oe';
        }
        elsif ( ( ord $c ) == 195 && ord $old[0] == 159 ) {
            shift @old;
            $sent .= 'ss';
        }
        elsif ( $data->{lang}{is_ascii_character}{$c} ) {
            $sent .= $c;
        }
    }

    return $sent;
}



1;