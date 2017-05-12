#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#

package AI::POS;

unshift @INC, ('.', 'lib', 'site/lib');

use strict;
use warnings;
use Carp;
use Digest::MD5 qw(md5_hex);
use Storable qw(store retrieve freeze thaw dclone);

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION     = 0.01;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(&part_of_speech_load
                      &part_of_speech_init
                      &part_of_speech_get_entry
                      &part_of_speech_get_memory
                      &part_of_speech_get_smalltalk
                      &part_of_speech_write_memory
                      &part_of_speech_add
                      &part_of_speech_clean); # functions
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = qw($Var1 %Hashit &func3);
}
our @EXPORT_OK;

# exported package globals go here


# non-exported package globals go here
our $part_of_speech__type;
our $part_of_speech__genus;
our $part_of_speech_config;
our $part_of_speech;

our $important_file = '';
our $basedir = '.';

our %part_of_speech_keys_type_hash;
our %part_of_speech_keys_genus_hash;
our $verbose;


# initialize package globals, first exported ones


# then the others
$part_of_speech__type = [];
$part_of_speech__genus = [];
$part_of_speech_config = {};
$part_of_speech = {};

%part_of_speech_keys_type_hash = ();
%part_of_speech_keys_genus_hash = ();


# destructor
END {
    undef $part_of_speech__type;
    undef $part_of_speech__genus;
}


# use
#use Devel::DumpSizes qw/dump_sizes/;

# code

#    eval  'use MLDBM qw( DB_File Storable );'
#        . 'use Fcntl qw( :flock O_CREAT O_RDWR );'
#        . 'my $part_of_speech__type__db = \'part_of_speech__type.temp\';'
#        . 'tie @$part_of_speech__type, \'MLDBM\', $part_of_speech__type__db, O_CREAT|O_RDWR, 0644 or die "Can\'t open $part_of_speech__type__db : $!";'
#        ;

eval 'use DBM::Deep;';
#eval 'tie %$part_of_speech, \'DBM::Deep\', \'cache__part_of_speech.tmp\';';
#print $@;
eval 'tie @$part_of_speech__type, \'DBM::Deep\', \'cache__part_of_speech__type.tmp\';';
print $@;
eval 'tie @$part_of_speech__genus, \'DBM::Deep\', \'cache__part_of_speech__genus.tmp\';';
print $@;

sub part_of_speech_init {
    # parameters
    $part_of_speech_config = { usage => 'bigmem', files => [] }
    		if !$part_of_speech_config || !keys %$part_of_speech_config;
    %$part_of_speech_config = ( %$part_of_speech_config, @_ );
    $basedir = $part_of_speech_config->{basedir};
    
    use Data::Dumper;
    print Dumper $part_of_speech_config;
}

sub part_of_speech_clean {
    undef $part_of_speech__type;
    undef $part_of_speech__genus;
    $part_of_speech__type = [];
    $part_of_speech__genus = [];
    
}

sub part_of_speech_save_state {
	my ( $file ) = @_;
	# ENABLE THIS (05. Okt. 2008)
    # ONLY TEST
	#######
    ## return;
    
    
    store($part_of_speech, $basedir . '/persistent_data_for_tagger.tmp');

	open my $file_handle, '<', $file;
	binmode($file_handle);
	my $hash_string = md5_hex((join('',<$file_handle>)));
	close $file_handle;
	print $file, "\n";
	print $hash_string, "\n";
	
	open my $md5file, '>', $basedir . '/persistent_data_for_tagger.md5';
	print { $md5file } $hash_string;
	close $md5file;
}

sub part_of_speech_load {
    # parameters
    my %arg = ( files => [], type => 'normal', at => 'init' );
    %arg = ( %arg, @_ );
    
    # initialize hash
    %part_of_speech_keys_type_hash = (1 => 1);
    %part_of_speech_keys_genus_hash = (1 => 1);
    
    # make better names for values in argument hash
    my $arg_type = $arg{type};
    my $arg_at = $arg{at};
    my $usage = $part_of_speech_config->{usage};
    my $use_bigmem = $usage eq 'bigmem';
    my $use_get = $arg_type eq 'get';

    my $arg_search_for = $arg{search_for} || '';
    $arg_search_for =~ s/([)(\]\[\/=])/\\$1/igm;
    
    # print message to inform user
    if ( $arg_search_for ) {
    	print 'Searching for ' . $arg_search_for . "\n";
	}
    
    # standard files
    if ( !$arg{files} || !@{$arg{files}} ) {
        $arg{files} = $part_of_speech_config->{files};
    }

    # skip this if low-mem usage is set
    if (    $usage eq 'lowmem'
         && $arg_at eq 'init' ) {
        
        print "Usage is lowmem, exiting part_of_speech_load()\n";
        return ({});
    }
    
    if (    $usage eq 'bigmem' ) {
    	print "checking: ", $arg{files}[-1], "\n";

		$important_file = $arg{files}[-1];
		open my $file_handle, '<', $important_file;
		binmode($file_handle);
		my $hash_string = md5_hex((join('',<$file_handle>)));
		close $file_handle;
		
		open my $md5file, '<', $basedir . '/persistent_data_for_tagger.md5';
		my $md5 = <$md5file>;
		chomp $md5;
		close $md5file;
		
		print "current: $md5\n";
		print "wanted:  $hash_string\n";
		
		if ( $md5 eq $hash_string ) {
			
			eval {
				local $SIG{'__DIE__'}; 
                
                # ENABLE THIS (05. Okt. 2008)
                # ONLY TEST
				$part_of_speech = retrieve( $basedir . '/persistent_data_for_tagger.tmp' );
				
			};
			$part_of_speech ||= {};
			
			return;
		}
	}
    
    # tie to disk if in big-memory mode
    if ( !$use_bigmem ) {
#    	eval 'tie %$part_of_speech, \'DBM::Deep\', \'cache__part_of_speech.tmp\';';
#		print $@;
	}
	else {
		eval 'untie %$part_of_speech;';
		print $@;
	}

	my $m = 0;    
    # load from files
    foreach my $file_str ( @{$arg{files}} ) {
#        print "Loading $file_str\n";
        open my $file, "<", $file_str
        		or do {
        	
#        	carp 'Error while opening: ', $file_str;
        	next;
		};

        <$file>;
        

        my @lines = ();
        while ( defined( my $line = shift @lines || <$file> ) ) {
            next if !$line;
            
            $line =~ tr/\r//d;
            $line =~ tr/\n//d;
            $line =~ tr/:/\//;

            if ( $use_get && $line !~ /^$arg_search_for\// ) {
            	next;
            }

            my @items = split /\//, $line;
            $items[1] = q{} if !defined $items[1];
            
            my $ref;
            if ( $use_bigmem ) {
            	$part_of_speech->{$items[0]}
            			||= { genus => 'q', type => 'q', rtime => 'not_new' };
            	$ref = $part_of_speech->{$items[0]};
			}
			else {
				$ref = { genus => 'q', type => 'q', rtime => 'not_new' };
			}

            if ( !$items[1] ) {
                my $found = 0;

                #say( $items[0] . ':' );
                while ( defined( $line = shift @lines || <$file> ) && $line =~ /^\s/ ) {
                	
                	# next if $items[0] =~ /[rtsl]en$/;
                	
                    $line =~ s/[\r\n]+$//gm;
                    $line =~ s/(\\[rn])+($|["])/$2/gm;
                    $line =~ s/(\\[rn])+($|["])/$2/gm;
                    my @items = split /[:]\s+?/, $line;
                    $items[1] = q{} if !defined $items[1];
                    $items[0] =~ s/^\s+//igm;    # important !

					$items[1] = 'f' if $items[1] eq 'w';
					
					$items[1] = $items[1] eq q{''}   ? q{}
                        : $items[1] eq q{"''"} ? q{}
                        : $items[1];

                    $ref->{ $items[0] } =
                          $items[1]
                        if $items[0] eq 'genus'
                            || $items[0] eq 'type'
                            && $items[1] && $items[1] ne 'q';

                    $found = 1;
                }
                push @lines, $line if $found;
                undef $line;
            }
            
            if ( $use_get ) {
                undef %part_of_speech_keys_type_hash;
                undef %part_of_speech_keys_genus_hash;
                
                return ({ reference => $ref });
            }
            
            elsif ( $use_bigmem ) {
            	$m += 1;
            	print "\rWord no $m loaded ", scalar @lines, "\r" if $m % 100 == 0;
			}
            
            else {
                part_of_speech_add( key => $items[0],
                        reference => $ref );
            }
        }

        close $file;
    }
    
    undef %part_of_speech_keys_type_hash;
    undef %part_of_speech_keys_genus_hash;
    
#    use Data::Dumper;
#    print Dumper $part_of_speech__type;
#    print Dumper $part_of_speech__genus;
    print "\n";
    
    return ({});
}

sub part_of_speech_add {
    # parameters
    my %arg = ( );
    %arg = ( %arg, @_ );
    
    if ( !$arg{key} ) {
        return;
    }
    if ( !$arg{reference} ) {
        return;
    }
    
    my $key  = $arg{key};
    my $ref = $arg{reference};
    
    # search if key already exists
    my $exists_type = 0;
    my $exists_genus = 0;
    if ( !keys %part_of_speech_keys_type_hash ) {
        if ( !$exists_type ) {
            NET:
            foreach (reverse @$part_of_speech__type) {
                if ( $_->[0] eq $key ) {
                    $exists_type = 1;
                    last NET;
                }
            }
        }
        if ( !$exists_genus ) {
            NET:
            foreach (reverse @$part_of_speech__genus) {
                if ( $_->[0] eq $key ) {
                    $exists_genus = 1;
                    last NET;
                }
            }
        }
    }
    else {
        $exists_type = $part_of_speech_keys_type_hash{$key};
        $exists_genus = $part_of_speech_keys_genus_hash{$key};
    }

    # add fact to semantic network
    if ( !$exists_type && $ref->{type} ) {
        push @$part_of_speech__type,
            [ $key, $ref->{type} ];
        $part_of_speech_keys_type_hash{$key} = 1;
    }
    if ( !$exists_genus && $ref->{genus} ) {
        push @$part_of_speech__genus,
            [ $key, $ref->{genus} ];
        $part_of_speech_keys_genus_hash{$key} = 1;
    }
}

sub part_of_speech_get_entry {
	
	if ( $part_of_speech_keys_type_hash{$_[0]} ) {
		my $hash_ref = {
				type => $part_of_speech_keys_type_hash{$_[0]},
				genus => $part_of_speech_keys_genus_hash{$_[0]},
			};
    	return $hash_ref;
	}
	
	elsif ( $part_of_speech->{$_[0]}{type} || $part_of_speech_config->{usage} eq 'bigmem' ) {
    	
    	my $hash_ref = $part_of_speech->{$_[0]};
    	return $hash_ref;
	}
	
	else {
    	
    	my $hash_ref = part_of_speech_load(
                         type => 'get',
                         at => 'in-get',
                         search_for => $_[0],
                       );
    	$hash_ref->{reference} ||= {};

		$part_of_speech->{$_[0]}
        			->{type} = $hash_ref->{reference}{type} || 'q'
        			if !$part_of_speech->{$_[0]}->{type};
		$part_of_speech->{$_[0]}
        			->{genus} = $hash_ref->{reference}{genus}
        			if !$part_of_speech->{$_[0]}->{genus};
        print 'Added: ',
              $_[0],
              ' = ',
              $part_of_speech->{$_[0]}
        		->{type},
              "\n";

	

    	return $hash_ref->{reference};
	}
}

sub part_of_speech_write_memory {
    # parameters
    my %arg = ( );
    %arg = ( %arg, @_ );
    
    if ( !$arg{file} ) {
    	return;
	}
    
    # clean
	delete $part_of_speech->{''};
    delete $part_of_speech->{' '};
#    foreach my $key ( keys %$part_of_speech ) {
#        delete $part_of_speech->{$key}
#            if $key =~ /['"*+\-)(]|(^[\s_])/;
#    }

	# write it
    write_to( $arg{file},
    	$part_of_speech );
    
    part_of_speech_save_state($arg{file});
}


sub part_of_speech_get_memory {
	return $part_of_speech;
}

my %lines_found = ();

sub write_to {
    my ( $file, $data_ref ) = @_;
    
    my $new_entries = q{}; # empty

    open my $handle, ">", $file;

	my $count = keys %$data_ref;
	my $m = 0;
    while ( my ($key, $value) = each %$data_ref ) {
    	next if $key =~ /nosave/;
    	
    	next if !keys %$value;
    	next if !$value->{type};
    	next if $value->{type} eq 'q';
    	
    	$m += 1;
        if ( ($value->{rtime} || q{}) eq 'not_new' || ($value->{new} || q{}) != 1 ) {
	        print $handle $key, ":\012";
    
        	while ( my ( $key_2, $value_2 ) = each %$value ) {
	            print $handle '  ', $key_2, ': ', $value_2
                	|| '', "\012"
                	if ($key_2 eq 'genus'
	                    || $key_2 eq 'type')
	                    && $value_2 && $value_2 ne 'q';
        	}
		}
		else {
	        $new_entries .= $key . ":\012";
            $value->{new} = 0;
            

        	while ( my ( $key_2, $value_2 ) = each %$value ) {
	            $new_entries .= '  ' . $key_2 . ': ' . ($value_2
                	|| '') . "\012"
                	if ($key_2 eq 'genus'
	                    || $key_2 eq 'type')
	                    && $value_2 && $value_2 ne 'q';
        	}
            $new_entries .= '###';
		}
        
        print "\r", 100 / $count * $m, "% written \r" if $m % 100 == 0;
    }
    (my $new_entries_print = $new_entries) =~ s/###//igm;
    print $handle $new_entries_print;

    open my $protocol_memory, '<', 'protocol_memory.txt';
    my @lines;
    {
        @lines = <$protocol_memory>;
    }
    map { chomp } @lines;
    close $protocol_memory;

    my @new_lines = grep { !$lines_found{ $_ } } split /###/, $new_entries;
    map { chomp } @new_lines;
    
    open my $protocol_memory, '>', 'protocol_memory.txt';
    foreach my $line (@lines) {
        print $protocol_memory $line . "\012";
    }
    foreach my $new_line (@new_lines) {
        $new_line =~ m/^(.*?)\012/;
        my $comparable = $1;
        my $line_found = 0;
        foreach my $line (grep { /^[a-zA-Z0-9]/ } @lines) {
            if ( $line eq $comparable ) {
                $line_found = 1;
            }
        }
        if ( !$line_found ) {
            print $protocol_memory $new_line . "\012";
            $lines_found{ $new_line } = 1;
        }
    }
    close $protocol_memory;



    close $handle;
}


1;
