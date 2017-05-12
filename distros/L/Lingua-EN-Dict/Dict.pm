#!/usr/bin/perl	

# Copyright (c) 2000  Josiah Bryan  USA
#
# See AUTHOR section in pod text below for usage and distribution rights.   
#

BEGIN {
	 $Lingua::EN::Dict::VERSION = "0.20";
	 $Lingua::EN::Dict::ID = 
'$Id: Lingua::EN::Dict.pm, v'.$Lingua::EN::Dict::VERSION.' 2000/06/10 24:07:16 josiah Exp $';
}
		
package Lingua::EN::Dict;

    @ISA = qw(Exporter);
	@EXPORT = qw(daemon);	
	
    use XML::Parser;		# Parses the XML dictionary file
    use Data::Dumper;		# Used to store extra data in XML and for TCP
	use IO::Handle;			# Just needed for the autoflush() function 
    use Socket;				# Ummmm...gee, what is this for? :)
    use strict;				# Make sure I behave
    
    BEGIN {
    	eval('use Coy');	# Try to make it pretty
    	eval('use Carp') if $@;
    }
    
    sub EOL{"\015\012"}
    sub flush  { my $a = shift; autoflush $a, 1 }; 
    sub logmsg { print "$0 $$: @_ at ", scalar localtime, "\n" }
	sub daemon {
	    my $port  = shift || 7778;
	    my $file  = shift || 'words.xml';
	    my $inad  = shift || INADDR_ANY;
	    my $dict  = Lingua::EN::Dict->new(file=>$file,warn=>1);
	    socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp')) || die "socket: $!";
	    setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, pack("l", 1))  || die "setsockopt: $!";
	    bind(SERVER, sockaddr_in($port, $inad)) 	        		|| die "bind: $!";
	    listen(SERVER,SOMAXCONN)                            		|| die "listen: $!";
	    logmsg "server started on port $port";
	    my $paddr;
	    for (; $paddr = accept(CLIENT,SERVER); close Client) {
	        my($port,$iaddr) = sockaddr_in($paddr);
	        my $name = gethostbyaddr($iaddr,AF_INET);
	        logmsg "connection from $name [",inet_ntoa($iaddr),"] 
	        	at port $port";
	        RXLOOP:
	        $_=<CLIENT>; chomp; chomp;  
	        logmsg "received command $_ 
	        	at port $port";
	        /^DICT-PING/		&&	do {	
	        	print CLIENT "DICT-PING: Ping? Pong! : You are: $name [",inet_ntoa($iaddr),"] at port $port", EOL; 
	        	flush *CLIENT;
	        	goto RXLOOP;
	        };
	        /^DICT-QUERY/		&&	do {	
	        	/^(DICT-QUERY:)([\w]+)/; 
	        	my $dump=Dumper($dict->{$2}); $dump=~s/\$VAR1 = //g;
		        print CLIENT $dump,EOL;
		        flush *CLIENT;
		        goto RXLOOP;
	        };
			/^DICT-KEYS/		&&	do {	
	        	my @keys = keys %{$dict}; 
	        	print CLIENT '[\''.join('\',\'',@keys).'\']', EOL;
	        	flush *CLIENT;
	        	goto RXLOOP;
	        };         
	        /^DICT-TENSE/		&& 	do {
	        	/^(DICT-TENSE:)([\w]+)/; 
	        	print CLIENT $dict->tense($2), EOL;
		        flush *CLIENT;
		        goto RXLOOP;
		    };
		    /^DICT-TYPES/		&& 	do {
	        	/^(DICT-TYPES:)([\w]+)/; 
	        	my $type = $2;$type =~ s/\r//g;$type =~ s/\n//g;
	        	print CLIENT '[\''.join('\',\'',@{$dict->types($type)}).'\']',EOL;
		        flush *CLIENT;
		        goto RXLOOP;
		    };
	        /^DICT-SET/			&&	do {
	        	/^(DICT-SET:)([\w]+)/;
	        	my $word = $2;$word =~ s/\r//g;$word =~ s/\n//g;
	        	s/^(DICT-SET:$word)//g;
	        	$dict->{$word} = eval;
	        	$dict->{$word}->{modified_by} = { name => $name, ip => inet_ntoa($iaddr) }
	        		if(inet_ntoa($iaddr) ne '127.0.0.1');
	        };
	        /^DICT-WRITEOUT/	&&	do {
	        	$dict->save;
	        };
	        /^DICT-CLOSE/		&& 	do {	            
	        	next	
	        };
            !/^DICT/			&& 	do {	
            	print CLIENT "Erroneous command: $_",EOL; 
            	flush *CLIENT; 
            	next 
            };
	    }
	}
    	
    my $word_hash={};                                                   
        
    sub new {
        my $type = shift;
        my %args = @_;
        my $file = $args{file} || 'words.xml';
        my $self = {};
        $word_hash=$self;
        $self->{_}->{'.file'}=$file;
        $self->{_}->{'.changed'} = 0;
        $self = bless $self,$type;
		my ($remote,$port, $iaddr, $paddr, $proto, $line, $flag, $sync);
		$flag	 = 1;                                   
		$sync	 = defined($args{$sync})?$args{$sync}:0;
    	$remote  = $args{server} 					  || 'localhost';
    	$port    = $args{port}   					  || 7778;
    	if ($port =~ /\D/) { $port = getservbyname($port, 'tcp') }
    	die "No port" unless $port;
    	$iaddr   = inet_aton($remote)                 || ($flag = 0);
    	$paddr   = sockaddr_in($port, $iaddr);
    	$proto   = getprotobyname('tcp');
    	socket(SERVER, PF_INET, SOCK_STREAM, $proto)  || ($flag = 0);
    	my $server = *SERVER;
    	undef $self->{_}->{'.server'};
    	undef $self->{_}->{'.sync'};
    	if($args{file} && !$args{server}) {
    		$flag = 0;
    		undef $server;
    	}
    	if($flag) {
		    if(connect($server, $paddr)) {
		    	print $server "DICT-PING",EOL; flush $server;
		    	my $rx = <SERVER>;
		    	if($rx =~ /^DICT-PING/) { 
		    		$self->{_}->{'.server'} = $server;
		    		$self->sync() if $sync;
		    	} else {
		    		close($server);
		    		warn "did not receive expected response from server [$remote] at port [$port]" if(!$args{warn_off});
		    		undef $server;
		    	}
		    } else {   
		    	warn "cannot connect to server [$remote] at port [$port]" if(!$args{warn_off});
		    	undef $server;
		    }
		}
		if(!$server) {
		    if(-f $file && -s $file) {
		    	$self->{_}->{'.sync'} = 1;
		        XML::Parser->new(Handlers=>{Start => \&tag_start,
		                                    End   => \&tag_end,
		                                    Char  => \&tag_char})
	          	                                  -> parsefile($file);
		    }
	    }
	    $self;
    }
        
    sub DESTROY {
		my $server = shift->{_}->{'.server'};
		print ($server "DICT-CLOSE", EOL), flush $server if $server;
	}	
	
	sub save {
        my ($word,$info);
        my $word_hash = shift;
        my $file      = $_[0] || $word_hash->{_}->{'.file'};
        return undef if(!$word_hash->{_}->{'.changed'} || !$self->{_}->{'.synced_down'});
        if($word_hash->{_}->{'.server'} && !$_[0]) {
        	$word_hash->sync('up');
        	return $word_hash;
        }
        my @keys = sort keys %{$word_hash};
        open FILE, ">$file";
        print FILE "<?xml version='1.0'?>\n<dictionary>\n";
        foreach my $word (@keys) {
            next if $word eq '_';
            $info=$word_hash->{$word};
            print FILE "\t<record>\n\t\t<word>$word</word>\n\t\t<type>$info->{type}</type>\n";
            if($info->{type} eq 'modal') {
                print FILE "\t\t<modal_type>$info->{modal_type}</modal_type>\n";
            }
            if($info->{type} eq 'verb') {
                print FILE "\t\t<forms>\n\t\t\t<third>$info->{third}</third>\n\t\t\t".
                             "<past>$info->{past}</past>\n\t\t\t".
                             "<part>$info->{part}</part>\n\t\t\t".
                             "<gerund>$info->{gerund}</gerund>\n".
                             "\t\t</forms>\n";
            }
            if($info->{links}) {
                foreach my $link (@{$info->{links}}) {
                    print FILE "\t\t<link relation='$link->{relation}'>$link->{word}</link>\n";
                }
            }    
            if($info->{defn}) {
            	print FILE "\t\t<defn>$info->{defn}</defn>\n";
            }    
            my %clone = %{$info};
            delete $clone{links}; delete $clone{defn};
            delete $clone{third}; delete $clone{past};
            delete $clone{modal}; delete $clone{gerund};
            delete $clone{part};  delete $clone{modal_type};
            delete $clone{type};
            if(keys %clone) {
                my $dump = "\n\t".Dumper(\%clone);
	            $dump=~s/\n/\n\t\t/g;$dump=~s/\$VAR1 = //g;$dump=~s/\;\n//g;
	            print FILE "\t\t<extra>$dump\n\t\t</extra>\n";
            }
            print FILE "\t</record>\n";
        }
        print FILE "</dictionary>";
        close FILE;  
        $word_hash->{_}->{'.changed'} = 0;
        return $word_hash;
    }
    
    sub tag_start {
        my ($x,$el) = (shift,shift);
        my ($a,$b) =  (shift,shift);
        $word_hash->{_}->{'.string.tmp'}->{$el} = '';
        $word_hash->{_}->{'.current.el'} = $el;
        $word_hash->{_}->{'.ab'}->{$el} = {$a=>$b};
    }
    
    sub tag_end {
        my ($x,$el) = (shift,shift);
        if($el eq 'word') {
            $word_hash->{
                $word_hash->{_}->{'.string.tmp'}->{$el}
            } = {};
            $word_hash->{_}->{'.current.word'} = $word_hash->{_}->{'.string.tmp'}->{$el};
            $word_hash->{_}->{'.string.tmp'}->{$el} = '';
        }
        if($el eq 'type') {
            $word_hash->{
                    $word_hash->{_}->{'.current.word'}
            }->{type} = 
                $word_hash->{_}->{'.string.tmp'}->{$el};
        }
        if($el eq 'modal_type' && $word_hash->{
                $word_hash->{_}->{'.current.word'}
            }->{type} eq 'modal') {
            $word_hash->{$word_hash->{_}->{'.current.word'}}->{modal} = 
                $word_hash->{_}->{'.string.tmp'}->{$el};
        }
        if(($el eq 'third' || $el eq 'past' || $el eq 'part' || $el eq 'gerund') 
            && $word_hash->{ 
                    $word_hash->{_}->{'.current.word'}
                }->{type} eq 'verb') {
            $word_hash->{$word_hash->{_}->{'.current.word'}}->{$el} = 
                $word_hash->{_}->{'.string.tmp'}->{$el};
        }
        if($el eq 'link') {
            push @{$word_hash->{$word_hash->{_}->{'.current.word'}}->{'links'}}, {
                word     => $word_hash->{_}->{'.string.tmp'}->{$el},
                relation => $word_hash->{_}->{'.ab'}->{$el}->{relation}
            };
        }                             
        if($el eq 'extra') {
            my $tmp = eval($word_hash->{_}->{'.string.tmp'}->{$el});
            print STDERR $@ if $@;
            my @keys = keys %{$tmp};
            foreach my $key (@keys) {
                $word_hash->{$word_hash->{_}->{'.current.word'}}->{$key} = $tmp->{$key};
            }
        }
        if($el eq 'defn') {
            $word_hash->{$word_hash->{_}->{'.current.word'}}->{defn} = $word_hash->{_}->{'.string.tmp'}->{$el};
        }
    }             
    
    sub tag_char {
        shift; $word_hash->{_}->{'.string.tmp'}->{$word_hash->{_}->{'.current.el'}}.=shift;
    }


	sub types {
		my $word_hash = shift;
		my $type = shift;
		my $server = $word_hash->{_}->{'.server'};
		if($server) {
			print $server "DICT-TYPES:$type", EOL; flush $server;
			my $str=<SERVER>;
			my $return = eval($str);
			warn "Error in database server query: $@\n" if $@;
			return $return;
		}
		my (@words,$word,$info); 
		while(($word,$info) = each %{$word_hash}) {
			push(@words, $word) if $info->{type} eq $type;
		}
		return \@words;    
	}
	
	sub is {
		my $word_hash = shift;
		my $word = shift;
		my $type = shift;
		my $server = $self->{_}->{'.server'};
		my $eval = 'return 1 if $word_hash->type($word) eq $type';
		if($server) {
			if(exists $self->{$word}) {
				return eval($eval);
			} else {
				$self->retrieve($word);
				return eval($eval);
			}
		}
		eval($eval);
		return undef;
	}
	
	sub add {
		my $word_hash = shift;
		my $aword = shift;
		my $tense = shift;
		$word_hash->{$aword}->{type} = $tense;
		if($tense eq 'verb') {
			my $word= $aword;
			my $end = substr($word,-1,1);		
			my $es='s';
			SWITCH: for($end) {
				/e/ 		&& do { $word = substr($word,0,-1)		};
				/y/	    	&& do { $word = substr($word,0,-1).'i' 	};
				/[eghsxy]/	&& do { $es	  = 'es';					};
				1;
			}
			$word_hash->{$aword}->{third}  = $word.$es;
			$word_hash->{$aword}->{past}   = $word.'ed';
			$word_hash->{$aword}->{part}   = $word.'ed';
			if(substr($aword,-2,2) ne 'ie') {
				$word_hash->{$aword}->{gerund} = ($end eq 'y')?$aword.'ing':$word.'ing'; 
			} else {
				$word_hash->{$aword}->{gerund} = substr($aword,0,-2).'ying'; 
			}
		}
		push @{$word_hash->{_}->{'.modified'}}, $aword;
		$word_hash->{_}->{'.changed'} = 1;
		$word_hash->{_}->{'.server'} = 1;
		return $word_hash;
	}
	
	sub link {
		my $word_hash = shift;
		my $word = shift;
		my $lword = shift;
		my $rel = shift || 'synonym';     
		$word_hash->type($word);
		my @tmp = grep { $_->{word} eq $lword && $_ ->{relation} eq $rel } 
				@{$word_hash->{$word}->{links}};
		if(!@tmp){
			push @{$word_hash->{$word}->{links}}, {
				word		=>	$word,
				relation	=>	$rel,
			};
			push @{$word_hash->{_}->{'.modified'}}, $word;
			$word_hash->{_}->{'.changed'} = 1;
			$word_hash->{_}->{'.server'} = 1;
			return $word_hash;
		}
		return undef;
	}
		
	sub is_verb   { shift->tense (shift)   		 	 	  	 }
	sub is_past   { shift->tense (shift)    eq 'past'	   	 }
	sub is_part   { shift->tense (shift)    eq 'part'   	 }
	sub is_third  { shift->tense (shift)    eq 'third'  	 }
	sub is_gerund { shift->tense (shift)    eq 'gerund' 	 }   
	sub is_noun   { shift->type  (shift)    eq 'noun'        }
	sub is_adv    { shift->type  (shift)  	eq 'adverb'      }
	sub is_pnoun  { shift->type  (shift)  	eq 'pronoun'     }
	sub is_art    { shift->type  (shift)  	eq 'article'     }
	sub is_adj    { shift->type  (shift)  	eq 'adjective'   }
	sub is_conj   { shift->type  (shift)  	eq 'cojunction'  }
	sub is_prep   { shift->type  (shift)  	eq 'preposition' }
	sub defn      { $_[0]->type  ($_[1]);   $_[0]->{$_[1]}->{defn} }
	sub type      { 
		my $self = shift;
		my $word = shift;
		my $server = $self->{_}->{'.server'};
		my $eval = '($self->{$word}->{type})?$self->{$word}->{type}:$self->tense($word)';
		if($server) {
			if(exists $self->{$word}) {
				return eval($eval);
			} else {
				$self->retrieve($word);
				return eval($eval);
			}
		}
		eval($eval);
	}
	
	sub retrieve {
		my $self = shift;
		my $word = shift;
		my $server = $self->{_}->{'.server'};
		return undef if!$server;
		print $server "DICT-QUERY:$word", EOL; flush $server;
		my $str;while(chomp($_=<$server>)){s/\r//g;;last if!$_;$str.=$_}
		$self->{$word} = eval($str);
		warn "Error in database server query: $@\n" if $@;
		return $self->{$word};
	}
	
	sub sync {
		my $self = shift;
		my $server = $self->{_}->{'.server'};
		my $direction = shift || 'down';
		return undef if $direction ne 'up' && $direction ne 'down';
		my $verbose = shift || 0;
		if($direction eq 'down') {
			print $server "DICT-KEYS",EOL; flush $server;
		  	my $eval = <$server>;
		  	my $keys = eval($eval);
		  	my $count = 0;
		  	foreach my $key (@{$keys}) {
		  		next if!$key;
		  		$self->type($key);
		  		++$count;
		  		print sprintf("%.0f",($#keys/$count)),"% ($count of $#keys words)\r" if($verbose);		  			
		  	}	    		
	  		$self->{_}->{'.sync'} = 1;
	  		$self->{_}->{'.synced_down'} = 1;
	  	} else {
	  		my $count = 0;
	  		my @keys = @{$self->{_}->{'.modified'}};
	  		foreach my $key (@keys) {
	  			print $server "DICT-SET:$key\n";
	  			my $dump=Dumper($self->{$2}); $dump=~s/\$VAR1 = //g;
		        print $server $dump,EOL;
		        ++$count;
		  		print sprintf("%.0f",($#keys/$count)),"% ($count of $#keys words)\r" if($verbose);
		    }
		    print $server 'DICT-WRITEOUT',EOL;
		    $self->{_}->{'.modified'} = {};
		}
		$self;
	}
	
	sub tense {
		my $word_hash = shift;
		my $word = shift;
		my $tense = shift;
		my $server = $word_hash->{_}->{'.server'};
		if($server) {
			print $server "DICT-TENSE:$word", EOL; flush $server;
			my $str;while(chomp($_=<$server>)){s/\r//g;;last if!$_;$str.=$_}
			my $return = eval($str);
			warn "Error in database server query: $@\n" if $@;
			return $return;
		}
		if($tense) {
			return 1 if $word_hash->tense($word) eq $tense;
			return undef;
		}
		my ($w,$info);
		while(($w,$info) = each %{$word_hash}) {
			if($info->{type} eq 'verb) {
				return 'past'       if $info->{past}   eq $word;
				return 'part'       if $info->{part}   eq $word;
				return 'third'      if $info->{third}  eq $word;
				return 'gerund'     if $info->{gerund} eq $word;
				return 'infinitive' if $w eq $word;
			}
		}
		return undef;
	}
	
	sub syns {
		my $word_hash = shift;
		my $word = shift;
		my @words;
		$word_hash->type($word);
		foreach my $link (@{$word_hash->{$word}->{links}}) {
			push @words, $link->{word} if $link->{relation} eq 'synonym';
		}
		return \@words;
	}
	
	sub opps {
		my $word_hash = shift;
		my $word = shift;
		my @words;
		$word_hash->type($word);
		foreach my $link (@{$word_hash->{$word}->{links}}) {
			push @words, $link->{word} if $link->{relation} eq 'opposite';
		}
		return \@words;
	}
1;

=begin

=head1 NAME
	
Lingua::EN::Dict - BETA Version of XML english dictionary storage.	

=head1 SYNOPSIS

	use Lingua::EN::Dict;
	
	my $dict = Lingua::EN::Dict->new('words.xml');
	my $part_of_speech = $dict->type('abash');
	my $verb_tense = $dict->tense('zoomed');
	my $flag1 = $dict->is_verb('utilizes');
	my $flag2 = $dict->is_verb('utilized');
	my $flag3 = $dict->is_verb('utilizing');
	my @synonyms = $dict->syns('dictate');
	my @antonyms = $dict->opps('valid');
	my $defenition = $dict->defn('vindicate');
	
	undef $dict;
	$dict = Lingua::EN::Dict->new(
		server		=>	e.tdcj.com
		port		=>	7778,
	}
	# defaults to local file 'words.xml' if it 
	# cannot reach server.
	# everything in first paragraph works here too
	
	undef $dict;
	$dict = Lingua::EN::Dict->new(
		server		=>	localhost
		port		=>	7778,
	}
	# everything in first paragraph works here too
	
	undef $dict;
	$dict = Lingua::EN::Dict->new;
    # same as above consructor, defaults to local file
    # 'words.xml' if it cannot reach server.
	# everything in first paragraph works here too
	
=head1 DESCRIPTION

Note: BETA VERSION.                 

See main reason for release of this module, three paragraphs down.

=item Description

This is a small module I came up with to use as a storage format for
my humble attempt at a natural language parser (or a subset of natural
language - english that is). This is a seperate module that stores
the words in an xml-format file. With the distribution file, you 
should have received an XML file called 'words.xml' that contains almost
3000 words consiting of several hundred verbs (not counting the seperate
forms of each of the verbs), as well as several hundred nouns, and 
adjectives, articles, and modals.

This module was created for the storage and retrieval of words from 
the XML file. It parses the XML file with XML::Parser and stores the
words in a blessed hash refrence which is returned from the new constructor.
This means that after you have loaded the dictionary, assuming you used
the default XML file, you can access the properties of the word 'abash' with
this:
	my $info = $dict->{'abash'};
$info will now contain a hash refrence to a structure of information about
the word 'abash'. $info will always have at least one key, 'type'. 'type' indicates
the part of speech that the word is. What keys $info contains depends on the type 
of word 'abash' is. If it is a verb, $info will contain the keys 'third', 'past',
'part', and 'gerund', and possible, 'defn'. If it is a modal, it will have a key
named 'modal_type'. Since this is a beta version, I wont go into too much more
detail here. Experiment and enjoy. Look at the default 'words.xml' file
for an idea of the structure. Each tag inside a <record></record> pair is
stored under that tags name as a key in $info, with a few exceptions, of course.


=item Reason for Release

The main reason for the beta relerase of this module is this: I would like
any and all feedback on the TCP server setup that I have added to this module.

I often got fed-up with having to wait 20 - 40 seconds for the new() constructor
to load and parse the entire 590k of words just to run a simple 2 line test script.
And since I like to tweek and run, tweek and run (the life of a Perl programmer, eh? :-),
it was really annoying to have to wait 30 seconds for each test to run, when the 
actual test script took less than 50ms to run.  Sooooo... I added a simple TCP transfer
setup for the dictionary.

To invovke a server process for the dictionary, simply use this one-liner:

% perl -MLingua::EN::Dict -e daemon

daemon() is a function automatically exported by this module for just this purpose. It
binds a TCP server to port 7778, accepting input from any IP address and loads the file
'words.xml' into a dictionary object for serving.

To create a client for this server, simply use:

	my $dict = new Lingua::EN::Dict;

This automatically tries to connect to the server on port 7778 of 'localhost'. If it cannot
connect to the server, it emits a warning and proceeds to try to load the default file 'words.xml'.

There are other options for the new constructor, as well as other options to the daemon() function.
For both, see below.

The reason I released this beta version was to get input from those of you who 
might have some idea of how to make sure I don't leave any security holes in the TCP server
portion. Because, for example, it is possible:

	my $dict = new Lingua::EN::Dict(
		server	=>	remote.server.system.com,
		port	=>	7778
	);
	
The new constructor allows you to specify the server name and port
to connect to. This would allow a central dictionary server to be setup
on some server (I have a server I am setting up for that purpose) and that
would allow other users of this module to access a much larger database
which can be updated by many people, instead of each user having to 
maintain his own copy of the words database. (Yes, I know I'll need to 
add forking to the daemon(), but this is just development, I'll keep it simple for
now. Future release I'll add forking.)

Since it does allow remote users the ability to TCP into the daemon, I know
that security checks need to be added to plug any potential holes. What I don't
know is exactly what holes exist and how to plug them.

HELP, I<PLEASE>! Anyone who does know anything about TCP or security of such, I<please>
take a look at the daemon() function code and let me know anything that I need to
do to make it secure. 


=head1 CONSTRUCTOR

	my $dict = Lingua::EN::Dict->new;
	
This is the default, most basic way to create a dictionary object. It will automatically
attempt to connect to the server on localhost:7778. If it doesn't find a server that
gives the expected response on that port, it will emit a warning and try to load
the file in 'words.xml' or whatever file was passed in the 'file' tag (below) and pare that. 
If it cannot load that file, or if the file doesn't exist, there is no warnings. The 
constructor returns a blessed refrence to a new dictionary object.

You can turn the warning about the inability to connect to the server if you want to by simply
defining the option tag 'warn_off'.
	
	my $dict = Lingua::EN::Dict->new( warn_off => 1 );

This will let it just silently try the server without emitting a warning if it cannot find
the server.

You can also tell it to explictly load from local disk without trying to connect to the
server by explictly passing a filename to the constructor as in this example:

	my $dict = Lingua::EN::Dict->new( file => 'words.xml' );

You may also tell it explictly what server to try to connect to with the 'server' and 'port'
tags.
 
	my $dict = Lingua::EN::Dict->new( 
		server => remote.server.com,
		port => 7778
	);
	
You can also tell it explictly what file to load if it cannot reach the server with
the file tag.	
	
	my $dict = Lingua::EN::Dict->new( 
		server => remote.server.com,
		port => 7778,
		file => 'mydictionary.xml',
	);
	

Quick example of how to download an entire database and save it locally:

	% perl -MLingua::EN::Dict -e 'Linga::EN::Dict->new(server=>"remote.server",
	port=>7778)->sync("down",1)->save("somefile.xml") or die "Error in sync/save."' 

This tries to login to the specified server and download the entire database from
that server (with the sync() command), printing out its progress as it goes. Then
it writes the entire database in XML format locally to the specified file, as
well as checking for errors.

	
=head1 METHODS

=item $dict->save( [ $file ] );

This writes out the dictionary in XML format to the file loaded from or $file if specified.
The only writes out IF (a) the dictionary has been modified by add() or link, or (b) it
has had sync("down",...) called on it. If it does not write out, it will return undef,
otherwise it returns $dict.

If $file is NOT specified, AND youn are connected to a dictionary server, save() will
loop through the internal array refrence at $dict->{_}->{'.modified'}, where each
key contains the name of a word that was modified with link() or add(). save() loops
thru this array and sends the info for each word modified to the server and then 
sends a DICT-WRITEOUT command to the server to write the database at the server end to
disk.


=item $dict->types($type);

This returns an array refrence to all the words that have the same type as $type. Note,
the elements of the array are a scalar value containing the name of the word, NOT a hash
refrence to the info. 

=item $dict->type($word);

This returns the 'type' entry for word $word. It is almost the same as:
	
	$type = $dict->{$word};

Why dont you want to use that code? Well, type() automatically checks to see
if you are using a server connection, and if the word has been retrieved from
the server yet. If the word hasn't been retrieved, it automatically retrieves
the word and caches it locally, THEN it returns the type. If you were to call
the above code example on a word that hadn't been retrieved yet, you would
simply get undef. 

See also retrieve().

=item $dict->is($word,$type);

Comparse the type of $word with $type, returning 1 if $word is type $type, undef
otherwise. This also automatically retrieves and caches words from the server
in a server usage situation. See above explanation for type().


=item $dict->add($word,$type);

This will add $word to the dictionary with type $type. If $type is 'verb', add()
will attempt to conjugate the verb into infinitive, past, present, part, and gerund parts.
add() will return $dict upon completion and add $word to the internal 'modified' list.

=item $dict->link($from, $to [,$rel]);

link() adds a relation link which appears as a <link> tag in the XML file. link() adds
a <link> entry in word $from to the word $to. $rel is an optional variable specifying the
'relation' attribute of the link. If $rel is not specified, $rel defaults to 'synonym'.


=item $dict->retrieve($word);

This attempts to retrieve the word information for $word from the dictionary server and
cache it in $dict, if connected. If it is not connected, it will return undef, otherwise
it will return a hash refrence to the info for the word. 

=item $dict->sync( [ $dir, $verbose ] );

If sync() is called without any arguments, $dir defaults to "down". The valid values 
for $dir are "down" or "up". If $verbose is defined (non-zero) it will print percentage
done followed by "\r". 

If $dir eq "down", sync() will query the server for a list of all the words in the database 
and then it will call retrieve() on each of the words in the list. 

If $dir eq "up", sync() will loop thru all the words in the "modified" list stored internally of
words that were modified by add() or link(), and it will upload those words to the server, 
followed by a DICT-WRITEOUT command to the server. 

sync() is used internally by $dict->save().

If $verbose is defined, it prints a string in the form of:
	50% (50 of 100 word)
With appropriate values substituted for the numbers, of course.


=item $dict->tense($word);	

This searches the verbs in the dictionary, comparing $word to the known tenses of that
verb (Infinitive, Past, Past Participle, Third Person, Gerund). If $word matches any of the tenses,
tense() will return the name of which tense it matched ("infinitive", "past", "part",
or "gerund"). If $verb doesn't match any of the verbs in the dictionary, tense() returns
undef.

This automatically detects if you are using the dictionary connected to a dictionary server.
If you are, then it sends the tense() request to be run at the server. The server will
scan the dictionary file and send the results back. All this is done transparently, so
tense() will run the same wether you are connected to a server or not.


=item $dict->syns($word);

=item $dict->opps($word);

Both of these functions return arrays, not array refs. syns() finds all the synonyms for
the $word. opps() finds all the antonyms for $word. 

You can add more synonyms or antonyms with the link() method. Example:

	$dict->link('cat',    'dog',  'opposite');
	$dict->link('scream', 'yell', 'synonym');
	
See the link() method for more information on syntax.


=item $dict->defn($word);

Returns a scalar containing the definition entry for word $word. Note: Words may not 
have a definition entry.


=item $dict->is_verb($word);

=item $dict->is_past($word);

=item $dict->is_part($word);

=item $dict->is_third($word);

=item $dict->is_gerund($word);

These five functions test verbs for the specified part. Ex. is_gerund($word) tests if
$word is in Gerund form. Uses tense() internally. Returns undef on failure, otherwise
returns a defined value for truth.

=item $dict->is_noun($word);

=item $dict->is_adv($word);

=item $dict->is_pnoun($word);

=item $dict->is_art($word);

=item $dict->is_adj($word);

=item $dict->is_conj($word);

=item $dict->is_prep($word);

These test word $word for the type indicated by the function name. The abreviations are 
as follows:

	noun	=>	noun
	adv		=>	adverb
	pnoun	=>	pronoun
	art		=>	article
	adj		=>	adjective
	conj	=>	conjunction
	prep	=>	preposition

Returns undef for false, otherwise returns a defined value for true.


=head1 daemon( [ $file,$port,$addr ] );

This is an automatically exported function. When called with no arguments,
it binds to port 7778 and loads file 'words.xml' in a dictionary object to be served.
It, by default, accepts requests from any IP address. To bind to a specific IP,
use:
	daemon(undef,undef,'206.70.2.13');
	
Example usage:	

	% perl -MLingua::EN::Dict -e daemon
	
This starts a server process on port 7778, letting requests from any IP. 
To specify a different file to load, use:

	% perl -MLingua::EN::Dict -e daemon("myfile.xml");
	
Or, for multiple network adapters, you can use one network adapter for the server (at 
least, thats how my development box is: I use one network card for my dictionary server,
one for my main inet connection, and one for my LAN). Anyways, to specify port and IP,
as well as file, do:

	% perl -MLingua::EN::Dict -e daemon("myfile.xml",3000,'206.70.2.13');
	
B<This function is what I need feedback on.> I<Please> take a look at the source to
see if there are any security holes that need patched, or anyother security-related
problems. Thankyou ahead of time!
	

=head1 EXPORT

daemon();

=head1 AUTHOR

Josiah Bryan F<E<lt>jdb@wcoil.comE<gt>>

Copyright (c) 2000 Josiah Bryan. All rights reserved. This program is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself.

The C<Lingua::EN::Dict> and related modules are free software. THEY COME WITHOUT WARRANTY OF ANY KIND.

=head1 DOWNLOAD

You can always download the latest copy of Lingua::EN::Dict
from http://www.josiah.countystart.com/modules/get.pl?dict:pod


=head1 SEE ALSO

Nothing to see also here... move along now.

=cut
