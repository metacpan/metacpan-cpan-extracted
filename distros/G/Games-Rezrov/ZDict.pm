package Games::Rezrov::ZDict;
# dictionary routines

use strict;
use 5.004;
#use SelfLoader;

use Games::Rezrov::ZObjectCache;
use Games::Rezrov::ZObject;
use Games::Rezrov::ZText;
use Games::Rezrov::ZConst;
use Games::Rezrov::ZObjectStatus;
use Games::Rezrov::Inliner;

use Games::Rezrov::MethodMaker ([],
			 qw(
			    ztext
			    dictionary_word_start
			    entry_length
			    entry_count
			    separators
			    encoded_word_length
			    version
			    decoded_by_word
			    decoded_by_address
			    object_cache
			    last_random
 
                            dictionary_fully_decoded

                            bp_cheat_data
			   ));

use constant OMAP_START_INDENT => 1;
use constant OMAP_INDENT_STEP => 3;

use constant WWW_BROWSER_EXES => qw(firefox netscape mozilla phoenix firebird);
# add more executables here

use constant ZORK_1 => ("Zork I", 88, "840726", 41257);
use constant ZORK_2 => ("Zork II", 48, "840904", 55449);
use constant ZORK_3 => ("Zork III", 17, "840727", 11898);
use constant ENCHANTER => ("Enchanter", 29, "860820", 9543);
use constant SORCERER => ("Sorcerer", 15, "851108", 10467);
use constant SPELLBREAKER => ("Spellbreaker", 87, "860904", 2524);
use constant INFIDEL => ("Infidel", 22, "830916", 16674);
use constant ZTUU => ("Zork: The Undiscovered Underground", 16, 970828, 4485);
use constant PLANETFALL => ("Planetfall", 37, "851003", 726);
use constant BUREAUCRACY => ("Bureaucracy", 116, 870602, 64613);
use constant SAMPLER1 => ("Sampler", 55, 850823, 28449);
use constant BEYOND_ZORK => ("Beyond Zork", 57, 871221, 50605);

use constant SNIDE_MESSAGES => (
				'A hollow voice says, "cretin."',
				'An invisible boot kicks you in the shin. Ouch!',
				'An invisible hand smacks you in the head. Ouch!',
#				'An invisible hand slaps you smartly across the face.  Ouch!',
			       );

use constant PILFER_LOCAL_MESSAGES => (
				       'The %s glows briefly with a faint blue glow.',
				       'Sparks fly from the %s!',
				       'The %s shimmers briefly.',
				      );

use constant PILFER_SELF_MESSAGES => (
				      'You feel invisible hands grope around your person.',
				      'You feel invisible hands rifling through your possessions.',
				      
);

use constant PILFER_REMOTE_MESSAGES => (
					'The earth seems to shift slightly beneath your feet.',
					'You hear a roll of thunder in the distance.',
					'A butterfly flits by, glistening green and gold and black.  There is a sound of thunder...',
					# Ray Bradbury = The Man
					'The smell of burning leaves surrounds you.',
				       );

use constant TELEPORT_MESSAGES => (
				   'You blink, and find your surroundings have changed...',
				   'You are momentarily dizzy, and then...',
				   '*** Poof! ***',
#				   'The taste of salted peanuts fills your mouth.',
				   
				  );

use constant TELEPORT_HERE_MESSAGES => (
					"Look around you!",
					"Sigh...",
#					"So that's why cabs have minimum fares...",
					"You experience the strange sensation of materializing in your own shoes.",
				       );

use constant TELEPORT_TO_ITEM_MESSAGES => (
					   "Oh yes, that's right over here...",
					   "Right this way...",
					  );

use constant SHAMELESS_MESSAGES => (
				    "Michael Edmonson just wishes he were an Implementor.",
				    "Michael Edmonson is a sinister, lurking presence in the dark places of the earth.  His favorite diet is onion rings from Cooke's Seafood, but his insatiable appetite is tempered by his fear of light.  Michael Edmonson has never been seen by the light of day, and few have survived his fearsome jaws to tell the tale.",
				    "Michael Edmonson has too much time on his hands.",
				    "Michael Edmonson is at this moment most likely parked in front of his whiz-bang PC.",
				   );

use constant FROTZ_SELF_MESSAGES => (
				     "Nah.",
				     "Bizarre!",
				     "I'd like to; unfortunately it won't work.",
				     "How about one of your fine possessions instead?",
				    );

use constant BANISH_MESSAGES => (
#				 'The %s disappears in a shower of sparks.',
				 'A sinister black fog descends; when it lifts, the %s is nowhere to be seen.',
				 'There is a bright flash; when you open your eyes, the %s is nowhere to be seen.',
				 'The %s disappears with a pop.'
				 );

use constant BANISH_CONTAINER_MESSAGES => (
					   'The %s flickers with a faint blue glow.',
					   'The %s shimmers briefly...'
				 );

use constant BANISH_SELF_MESSAGES => (
				      'You feel a tickle...',
				      'Your load feels lighter.',
				      '%s?  What %s?',
				 );

use constant TRAVIS_MESSAGES => (
				 "Looking at the %s, you suddenly feel an inflated sense of self-esteem.",
				 "The %s looks more dangerous already.",
				 "The %s glows wickedly.",
				);

use constant LUMMOX_MESSAGES => (
				 "Your load feels less heavy.",
				 "Your possessions seem suddenly ephemeral.",
#				 "Suddenly, you get some great ideas on how to reorganize your closet.",
				 "You are struck with some great ideas on how to reorganize your closet.",
				);

use constant HELP_INFOCOM_URLS => (
				   "http://www.csd.uwo.ca/Infocom/Invisiclues/",
				  );

use constant HELP_GENERIC_URLS => (
				   "http://www.yahoo.com/Recreation/Games/Interactive_Fiction/",
);

use constant VILIFY_MESSAGES => (
				 "I never liked the look of that %s.",
				 "That %s is really asking for trouble.",
				);

use constant VILIFY_SELF_MESSAGES => (
				      "I never liked you to begin with!",
				      "Okay...you're ugly and your mother dresses you funny.",
				      "You are filled with self-loathing.",
				      "You disgust me."
				     );

use constant BASTE_MESSAGES => (
				 "The %s looks mouth-wateringly delicious.",
#				 "The %s looks particularly toothsome.",
				 "Mmm, %s."
				);

use constant VOLUMINUS_SELF_MESSAGES => (
					  "You're pretty full of yourself already.",
					  "You're pretty full of it already.",
					 );

use constant VOLUMINUS_MESSAGES => (
				     "The interior of the %s seems to recede away from you.",
				    );

use constant VOLUMINUS_CLOSED_MESSAGES => (
					    "The %s seems to bulge for a moment."
					   );

use constant GO_BACK_TO_X => (
			      "New York",
			      "San Francisco",
			      "New Jersey",
			     );

use constant WWW_HELP_MESSAGES => (
    "I can barely see what's going on there, but I'll see what I can do...",
    "Perhaps your plea will be heard."
);

use constant ANGIOTENSIN_MESSAGES => (
	"It looks suspiciously like a children's vitamin.",
	"Use caution when driving, operating machinery, or performing other hazardous activities.",
	"Side effects may include dizziness or rash.",
	);

use constant CANT_FIND_YOU_YET_MESSAGES => (
	"Sorry, I haven't got my bearings just yet; try again in a few moves.",
	"Move around a little first so I can lock on to your signal...",
	"Take a few steps first so I can triangulate your signal...",
	);

use constant SPEECH_ENABLED_MESSAGES => (
					 "Speech output enabled.",
					 "Hello.",
					 "Hello there.",
#					 "Bitchin' Betty activated.",
					 "Altitude! Altitude!",
					 "Dough Re Mi Fa So La Ti Dough..."
					);

use constant GMACHO_MESSAGES => (
				 "While your spellbook remains closed, its pages seem to rustle for a moment.",
				 "For a moment you could swear your spellbook was glowing with a faint blue glow.",
				);

use constant PLENTY_O_ROOM => 32000;

%Games::Rezrov::ZDict::MAGIC_WORDS = map {$_ => 1} (
						    "pilfer",
						    "teleport",
						    "#teleport",
						    "bamf",
						    "lingo",
						    "embezzle",
						    "omap",
						    "lumen",
						    "frotz",
						    "futz",
						    "travis",
						    "bickle",
						    "tail",
						    "#sa",
						    "#sp",
						    "#dta",
						    "#dat", "spiel",
						    "#sprop",
						    "rooms",
						    "items",
						    "#sgv",
						    "#slv",
						    "#ggv",
						    "#serials",
						    "lummox",
						    "systolic",
						    "vilify",
						    "baste", "nosh",
						    "voluminus",
#						    "compartmentalize",
						    "angiotensin",

						    "gmacho",

						    "verdelivre",
						   );

%Games::Rezrov::ZDict::ALIASES = (
			   "x" => "examine",
			   "g" => "again",
			   "z" => "wait",
			   "l" => "look",
			  );

my $INLINE_CODE = '
sub new {
  my ($type, $addr) = @_;
  my $self = [];
  bless $self, $type;
  $self->version(Games::Rezrov::StoryFile::version());
  $self->ztext(Games::Rezrov::StoryFile::ztext());
  my $header = Games::Rezrov::StoryFile::header();
  $self->encoded_word_length($header->encoded_word_length());
  my $dp;
  if ($addr) {
    $dp = $addr;
  } else {
    $dp = $header->dictionary_address();
  }
  
  $self->decoded_by_word({});
  $self->decoded_by_address({});

  # 
  #  get token separators
  #
  my $sep_count = GET_BYTE_AT($dp++);
  my %separators;
  for (my $i=0; $i < $sep_count; $i++) {
    $separators{chr(GET_BYTE_AT($dp++))} = 1;
  }
  $self->separators(\%separators);
  
  $self->entry_length(GET_BYTE_AT($dp++));
  # number of bytes for each encoded word
  $self->entry_count(Games::Rezrov::StoryFile::get_word_at($dp));
  # number of words in the dictionary
  $dp += 2;

  $self->dictionary_word_start($dp);
  # start address of encoded words
  
#  die sprintf "%s %s\n", $self->entry_length(), $self->entry_count();
  
  return $self;
}

';

Games::Rezrov::Inliner::inline(\$INLINE_CODE);
#print $INLINE_CODE;
#die;
eval $INLINE_CODE;
undef $INLINE_CODE;


1;

#__DATA__

sub save_buffer {
  # copy the input buffer to story memory.
  # This may be called internally during oops emulation.
  my ($self, $buf, $text_address) = @_;
  my $mem_offset;
  my $z_version = $self->version();
  my $len = length $buf;
  if ($z_version >= 5) {
    Games::Rezrov::StoryFile::set_byte_at($text_address + 1, $len);
    $mem_offset = $text_address + 2;
  } else {
    $mem_offset = $text_address + 1;
  }
  
  for (my $i=0; $i < $len; $i++, $mem_offset++) {
    # copy the buffer to memory
    Games::Rezrov::StoryFile::set_byte_at($mem_offset, ord substr($buf,$i,1));
  }
  Games::Rezrov::StoryFile::set_byte_at($mem_offset, 0) if ($z_version <= 4);
  # terminate the line
}

sub tokenize_line {
  my ($self, $text_address, $token_address, %options) = @_;
#      $text_len, $oops_word) = @_;
  my $text_len = $options{"-len"};
  my $oops_word = $options{"-oops"};
  my $flag = $options{"-flag"} || 0;
  
#  my $b1 = new Benchmark();
  my $max_tokens = Games::Rezrov::StoryFile::get_byte_at($token_address);
  my $token_p = $token_address + 2;
  # pointer to location where token data will be written
  my $separators = $self->separators();

  #
  #  Step 1: parse out the tokens
  #
  my $text_p = $text_address + 1;
  # skip past max bytes enterable
  if ($self->version() >= 5) {
    $text_len = Games::Rezrov::StoryFile::get_byte_at($text_p) unless defined $text_len;
    # needed if called from tokenize opcode (VAR 0x1b)
    $text_p++;
    # move pointer past length of entered text.
  }
  my $raw_input = Games::Rezrov::StoryFile::get_string_at($text_p, $text_len);
#  print STDERR "raw: $raw_input\n";

  my $text_end = $text_p + $text_len;
  # we're passed the length because in <= v4 we would have to count
  # the bytes in the buffer, looking for terminating zero.

  my @tokens;
  my $start_offset = 0;
  # token start position
  my $token = "";

  my $c;
  my $token_done = 0;
  my $all_done = 0;
  while (! $all_done) {
    if ($text_p >= $text_end) {
      # finished
      $token_done = 1;
      $all_done = 1;
    } else {
      $start_offset = $text_p unless $start_offset;
      $c = chr(Games::Rezrov::StoryFile::get_byte_at($text_p++));
      if ($c eq ' ') {
	# a space character:
	if ($token ne "") {
	  # token is completed
	  $token_done = 1;
	} else {
	  # ignore whitespace: move start pointer past it
	  $start_offset++;
	}
      } elsif (exists $separators->{$c}) {
	# hit a game-specific token separator
#	print STDERR "separator: $c\n";
	$token_done = 1;
	if ($token ne "") {
	  # a token is already built; use it, and move
	  # text pointer back one so we'll make a new token
	  # out of this separator
	  $text_p--;
	} else {
	  # the separator itself is a token
	  $token = $c;
	}
      } else {
	# append to the token
	$token .= $c;
      }
    }
    if ($token_done) {
#      push @tokens, [ $token, $start_offset - $text_address ] if $token;
      push @tokens, [ $token, $start_offset - $text_address ] if $token ne "";
      $token = "";
      $token_done = $start_offset = 0;
    }
  }
#  printf STDERR "tokens: %s\n", join "/", map {$_->[0]} @tokens;

  if (@tokens == 3 and
      Games::Rezrov::ZOptions::SHAMELESS() and
      $tokens[0]->[0] =~ /^(who|what)$/i and
      $tokens[1]->[0] =~ /^is$/ and
      $tokens[2]->[0] =~ /^(michae\w*|edmons\w*)/) {
    # shameless self-promotion
    unless ($self->get_dictionary_address($1)) {
      # don't do anything if name is in dictionary (e.g. Suspect has a Michael)
      $self->write_text($self->random_message(SHAMELESS_MESSAGES));
      $self->newline();
      $self->newline();
      $self->suppress_output();
      return;
    }
  }

  #
  #  Step 2: store dictionary addresses for words
  #
  my $encoded_length = $self->encoded_word_length();
  my $wrote_tokens = 0;
  my $untrunc_token;
  for (my $ti = 0; $ti < @tokens; $ti++) {
    my ($token, $offset) = @{$tokens[$ti]};
    if ($wrote_tokens++ < $max_tokens) {
      $untrunc_token = lc($token);
      $token = substr($token,0,$encoded_length)
	if length($token) > $encoded_length;
      my $addr = $self->get_dictionary_address($token);
      if ($addr == 0) {
	# NOP if in dictionary
	if (Games::Rezrov::ZOptions::EMULATE_NOTIFY() and $token eq "notify") {
	  $self->notify_toggle();
	} elsif (lc($token) eq "#speak") {
	  # toggle speech output
	  my $zio = Games::Rezrov::StoryFile::screen_zio();
	  # horrible
	  my $msg;
	  if ($zio->speaking()) {
	    $msg = "Speech output disabled.";
	    $zio->speaking(0);
	  } else {
	    if ($zio->init_speech_synthesis()) {
	      # ok
	      $msg = $self->random_message(SPEECH_ENABLED_MESSAGES);
	    } else {
	      $msg = $zio->speech_synthesis_error();
	    }
	  }
	  $self->write_text($msg);
	  newline();
	  newline();
	  suppress_output();
	} elsif (lc($untrunc_token) eq "#listen") {
	  # toggle speech recognition
	  my $zio = Games::Rezrov::StoryFile::screen_zio();
	  # horrible
	  my $msg;
	  if ($zio->listening()) {
	    $msg = "Speech recognition disabled.";
	    $zio->speaking(0);
	  } else {
	    if ($zio->init_speech_recognition()) {
	      # ok
	      $msg = "Speech recognition enabled.";
	    } else {
	      $msg = $zio->speech_recognition_error();
	    }
	  }
	  $self->write_text($msg);
	  newline();
	  newline();
	  suppress_output();

	} elsif (lc($token) eq "#typo") {
	  my $status = !Games::Rezrov::ZOptions::CORRECT_TYPOS();
	  $self->write_text(sprintf "Typo correction is now %s.", $status ? "on" : "off");
	  Games::Rezrov::ZOptions::CORRECT_TYPOS($status);
	  $self->newline();
	  $self->newline();
	  $self->suppress_output();
	} elsif (Games::Rezrov::ZOptions::EMULATE_HELP() and $token eq "help") {
	  $self->help();
	} elsif (Games::Rezrov::ZOptions::EMULATE_OOPS() and ($oops_word or
					      (($token eq "oops") or
					       (Games::Rezrov::ZOptions::ALIASES() and $token eq "o")))) {
	  if ($oops_word) {
	    # replace misspelled word
	    $addr = $self->get_dictionary_address($oops_word);
	  } else {
	    # entered "oops"
	    my $last_input = Games::Rezrov::StoryFile::last_input();
	    $self->save_buffer($last_input, $text_address);
	    $self->tokenize_line($text_address,
				 $token_address,
				 "-len" => length($last_input),
				 "-oops" => $tokens[$ti + 1]->[0]);
	    return;
	  }
	} elsif (Games::Rezrov::ZOptions::MAGIC() and exists $Games::Rezrov::ZDict::MAGIC_WORDS{$untrunc_token}) {
	  (my $what = $raw_input) =~ s/.*?${untrunc_token}\s*//i;
	# use the raw input rather than joining the remaining tokens.
	# Necessary if the query string contains what the game considers
	# tokenization characters.  For example, "Mrs. Robner" in Deadline
	# is broken into 3 tokens: "Mrs", ".", and "Robner".  Joined
	# this is "Mrs . Robner", which doesn't match anything in the object
	# table.
#	print STDERR "magic: -$what-\n";
	  $self->magic($untrunc_token, $what);
#		       $ti < @tokens - 1 ?
#		       join " ", map {$_->[0]} @tokens[$ti + 1 .. $#tokens]
#		       : "");
	} elsif (Games::Rezrov::ZOptions::ALIASES() and
		 exists $Games::Rezrov::ZDict::ALIASES{$untrunc_token}) {
	  $addr = $self->get_dictionary_address($Games::Rezrov::ZDict::ALIASES{$untrunc_token});
	} elsif (Games::Rezrov::ZOptions::EMULATE_COMMAND_SCRIPT() and
		 $untrunc_token eq "#reco" or
		 $untrunc_token eq "#unre" or
		 $untrunc_token eq "#comm") {
	  if ($untrunc_token eq "#comm") {
	    # play back commands
	    Games::Rezrov::StoryFile::input_stream(Games::Rezrov::ZConst::INPUT_FILE);
	  } else {
	    Games::Rezrov::StoryFile::output_stream($untrunc_token eq "#reco" ? Games::Rezrov::ZConst::STREAM_COMMANDS : - Games::Rezrov::ZConst::STREAM_COMMANDS);
	  }
	  $self->newline();
	  $self->suppress_output();
	} elsif ($untrunc_token eq "#cheat") {
	  my $status = !(Games::Rezrov::ZOptions::MAGIC());
	  Games::Rezrov::ZOptions::MAGIC($status);
	  $self->write_text(sprintf "Cheating is now %sabled.", $status ? "en" : "dis");
	  $self->newline();
	  $self->newline();
	  $self->suppress_output();
	}
      }
    
      if ($flag and $addr == 0) {
	# sect15.html#tokenise:
        # when $flag is set, don't touch entries not in the dictionary.
	1;
      } else {
        Games::Rezrov::StoryFile::set_word_at($token_p, $addr);
        Games::Rezrov::StoryFile::set_byte_at($token_p + 2, length $untrunc_token);
        Games::Rezrov::StoryFile::set_byte_at($token_p + 3, $offset);
      }
      $token_p += 4;
    } else {
      $self->write_text("Too many tokens; ignoring $token");
      $self->newline();
    }
  }

  Games::Rezrov::StoryFile::set_byte_at($token_address + 1, $wrote_tokens);
  # record number of tokens written

#  my $b2 = new Benchmark();
#  my $td = timediff($b2, $b1);
#  printf STDERR "took: %s\n", timestr($td, 'all');

}

sub get_dictionary_address {
  # get the dictionary address for the given token.
  #
  # NOTES:
  #   This does NOT conform to the spec; officially, we should encode
  #   the word and look up the encoded value.  This would be a bit
  #   faster, but I'm too Lazy and Impatient right now to do it that
  #   way.  Contains ugly hacks for non-alphanumeric "words".
  #
  # alas, certain v5 opcodes require text encoding.  Tomorrow  :)
  #
  my $self = $_[0];
  my $token = lc($_[1]);

  my $max = $self->encoded_word_length();
  $token = substr($token,0,$max) if length($token) > $max;
  # make sure token is truncated to max length

  my $by_name = $self->decoded_by_word();

  if (exists $by_name->{$token}) {
    # we already know where this word is; return its address
#    print STDERR "cache hit for $token\n";
    return $by_name->{$token};
  } else {
    # find the word
    my $dict_start = $self->dictionary_word_start();
    my $ztext = $self->ztext();
    my $num_words = $self->entry_count();
    my $entry_length = $self->entry_length();
    my $by_address = $self->decoded_by_address();
    my $char = substr($token,0,1);
    my $search_index;
    my $linear_search = 0;
    if ($char =~ /[a-z]/) {
      $search_index = int(($num_words - 1) * (ord(lc($char)) - ord('a')) / 26);
      # pick an approximate start position
    } elsif (ord($char) < ord 'a') {
      $search_index = 0;
      $linear_search = 1;
    } else {
      printf STDERR "tokenize: fix me, char %d", ord($char);
    }

    my ($address, $word, $delta_mult, $delta, $next);
    my $behind = -1;
    my $ahead = $num_words;
    while (1) {
      $address = $dict_start + ($search_index * $entry_length);
      if (exists $by_address->{$address}) {
	# already know word for this address
#	print STDERR "address cache hit!\n";
	$word = $by_address->{$address};
      } else {
	# decode word at this address and cache
	$word = ${$ztext->decode_text($address)};
	$by_name->{$word} = $address;
	$by_address->{$address} = $word;
      }
#      print "Got $word at $search_index\n";
      if ($word eq $token) {
	# found the word we're looking for: done
	return $address;
      } else {
	# missed: search further
	if ($linear_search) {
	  $next = $search_index + 1;
	} else {
	  $delta_mult = $token cmp $word;
	  # determine direction we need to search
	  if ($delta_mult == -1) {
	    # ahead; need to search back
	    $delta = int(($search_index - $behind) / 2);
	    $ahead = $search_index;
	  } else {
	    # behind; need to search ahead
	    $delta = int(($ahead - $search_index) / 2);
	    $behind = $search_index;
	  }
	  $delta = 1 if $delta == 0;
	  $next = $search_index + ($delta * $delta_mult);
	}
	if ($next < 0 or $next >= $num_words) {
	  # out of range
	  return 0;
	} elsif ($next == $ahead or $next == $behind) {
	  # word does not exist between flanking words
	  return 0;
	} else {
	  $search_index = $next;
	}
      }
    }
  }
  die;
}

sub magic {
  #
  #  >read dusty book
  #  The first page of the book was the table of contents. Only two
  #  chapter names can be read: The Legend of the Unseen Terror and
  #  The Legend of the Great Implementers.
  #  
  #  >read legend of the implementers
  #  This legend, written in an ancient tongue, speaks of the
  #  creation of the world. A more absurd account can hardly be
  #  imagined. The universe, it seems, was created by "Implementers"
  #  who directed the running of great engines. These engines       
  #  produced this world and others, strange and wondrous, as a test
  #  or puzzle for others of their kind. It goes on to state that
  #  these beings stand ready to aid those entrapped within their
  #  creation. The great magician-philosopher Helfax notes that a
  #  creation of this kind is morally and logically indefensible and
  #  discards the theory as "colossal claptrap and kludgery."
  #
  
  my ($self, $token, $what) = @_;
  my $object_cache = $self->get_object_cache();

  my $player_object = Games::Rezrov::StoryFile::player_object();
  my $current_room = Games::Rezrov::StoryFile::current_room();

  if ($what) {
    if ($player_object and $what =~ /^(me|self)$/i) {
      # for the purposes of these commands, consider "me" and "self"
      # equivalent to the player object (whatever that's called)
      my $desc = $object_cache->print($player_object);
      $what = $$desc;
    } elsif ($current_room and $what =~ /^here$/) {
      # likewise consider "here" to be the current room
      my $desc = $object_cache->print($current_room);
      $what = $$desc;
    }
  }

  my $just_one_newline = 0;

  if (0 and $token eq "fbg") {
    # can we make arbitrary things glow with a faint blue glow?
    # (nope)
    my $zo = new Games::Rezrov::ZObject(160);
    # 160=mailbox
    my $zp = $zo->get_property(12);
    $self->write_text($zp->property_exists() ? "yes" : "no");
  } elsif (0 and $token eq "fbg2") {
    # do all objects with "blue glow" property behave the same?
    my $object_cache = $self->get_object_cache();
    for (my $i = 1; $i <= $object_cache->last_object(); $i++) {
      my $zo = new Games::Rezrov::ZObject($i);
      my $zp = $zo->get_property(12);
      if ($zp->property_exists()) {
	$zp->set_value(3);
	$self->write_text(${$zo->print()});
	$self->newline();
      }
    }
  } elsif ($token eq "rooms") {
    $self->dump_objects(2);
  } elsif ($token eq "items") {
    $self->dump_objects(3);
  } elsif ($token eq "#serials") {
    my $header = Games::Rezrov::StoryFile::header();
    $self->write_text(sprintf "Z-machine version %d, ",
		      Games::Rezrov::StoryFile::version());
    $self->write_text(sprintf "release %s, ", $header->release_number());
    $self->write_text(sprintf "serial number %s, ", $header->serial_code());
    $self->write_text(sprintf "checksum %s.", $header->file_checksum());
  } elsif ($token eq "systolic") {
    # lower blood pressure (Bureaucracy only)
    $self->systolic();
  } elsif ($token eq "angiotensin") {
    # take blood pressure regulating medication (Bureaucracy only)
    $self->medicate();
  } elsif ($token eq "lummox") {
    # remove restrictions on weight and number of items that can be carried
    $self->lummox();
  } elsif ($token eq "omap") {
    # dump object relationships
    $self->dump_objects(1, $what);
  } elsif ($token eq "lingo") {
    # dump the dictionary
    $self->dump_dictionary($what);
  } elsif ($token eq "embezzle") {
    # manipulate game score
    if ($self->version() > 3) {
      $self->write_text("Sorry, this trick only works in version 3 games.");
    } elsif (Games::Rezrov::StoryFile::header()->is_time_game()) {
      $self->write_text("Sorry, this trick doesn't work in \"time\" games.");
    } elsif (length $what) {
      if ($what =~ /^-?\d+$/) {
	Games::Rezrov::StoryFile::set_global_var(1, $what);
	$self->write_text("\"Clickety click...\"");
	# BOFH
      } else {
	$self->write_text("Is that a score on your planet?");
      }
    } else {
      $self->write_text("Tell me what to set your score to.");
    }
  } elsif ($token =~ "#sgv") {
    my ($var, $value) = split /\s+/, $what;
    $self->write_text("Setting global variable $var to $value.");
    Games::Rezrov::StoryFile::set_global_var($var, $value);
  } elsif ($token =~ "#slv") {
    my ($var, $value) = split /\s+/, $what;
    $self->write_text("Setting local variable $var to $value.");
    Games::Rezrov::StoryFile::set_variable($var, $value);
  } elsif ($token =~ "#ggv") {
    $self->write_text(sprintf "Global variable %d is %d.", $what,
		      Games::Rezrov::StoryFile::get_global_var($what));
  } elsif ($token =~ "#?teleport") {
    $self->teleport($what);
  } elsif ($token eq "baste" or $token eq "nosh") {
    $self->baste($token, $what);
  } elsif ($token eq "voluminus") {
    $self->voluminus($token, $what);
  } elsif ($token eq "gmacho") {
    $self->gmacho($token, $what);
  } elsif ($token eq "verdelivre") {
    $self->bookworm($token, $what);
#  } elsif ($token eq "compartmentalize") {
#    $self->compartmentalize($token, $what);
  } elsif ($token eq "vilify") {
    $Games::Rezrov::IGNORE_PROPERTY_ERRORS = 1;
    $self->vilify($what);
  } elsif ($token eq "travis" or $token eq "bickle") {
    $self->travis($what);
  } elsif ($token =~ /^(frotz|futz|lumen)$/) {
    $self->frotz($what);
  } elsif ($token eq "tail") {
    $self->tail($what);
  } elsif ($token eq "#sa") {
    $self->set_attr($what);
  } elsif ($token eq "#sp") {
    $self->set_property($what);
  } elsif ($token eq "#dta") {
    $self->decode_text_at($what);
  } elsif ($token eq "#dat" or $token eq "spiel") {
    $self->decode_all_text(split /\s+/, $what);
  } elsif ($token eq "#sprop") {
    $self->property_dump($what);
  } else {
    # pilfer or bamf
    my @hits = $what ? $object_cache->find($what, "-room" => 0) : ();
    if (@hits > 1) {
      $self->write_text(sprintf 'Hmm, which do you mean: %s?',
			 nice_list(sort map {$_->[1]} @hits));
    } elsif (@hits == 1) {
      my ($id, $desc) = @{$hits[0]};
      my $zo = $object_cache->get($id);
      my $zstat = new Games::Rezrov::ZObjectStatus($hits[0]->[0],
						   $object_cache);

      if ($token eq "bamf") {
	#
	#  Make an object disappear
	#
	if ($zstat->is_player()) {
	  $self->write_text("You are beyond help already.");
	} elsif ($zstat->in_current_room()) {
	  if ($zstat->in_inventory()) {
	    $self->write_text(ucfirst(sprintf $self->random_message(BANISH_SELF_MESSAGES), $desc, $desc));
	  } elsif ($zstat->is_toplevel_child()) {
	    # top-level, should be visible
	    $self->write_text(sprintf $self->random_message(BANISH_MESSAGES), $desc);
	  } else {
	    # in something else
	    $self->write_text(sprintf $self->random_message(BANISH_CONTAINER_MESSAGES), ${$zstat->toplevel_child()->print()});
	  }
	  $self->move_object($id, 0);
	  # set the object's parent to zero (nothing)
	} else {
	  $self->write_text(sprintf "I don't see any %s here.", ${$zo->print()});
	}
      } elsif ($token eq "pilfer") {
	#
	#  Try to move and item to inventory
	#  (move it to this room and submit "take" command)
	#
	my $proceed = 0;
	if (!$player_object or !Games::Rezrov::StoryFile::current_room()) {
	  $self->write_text("Sorry, I haven't got my bearings just yet.  Maybe you could walk around a little and try again.");
	} elsif ($zstat->is_player()) {
	  if ($desc eq "cretin") {
	    $self->write_text("\"cretin\" suits you, I see.");
	  } else {
	    $self->write_text($self->random_message(SNIDE_MESSAGES));
	  }
	} elsif ($zstat->in_current_room()) {
	  if ($zstat->in_inventory()) {
	    $self->write_text($self->random_message(PILFER_SELF_MESSAGES));
	    $proceed = 1;
	    # sometimes makes sense: pilfer canary from egg, even
	    # when carrying it
	  } elsif ($zstat->is_toplevel_child()) {
	    # at top level in room (should already be visible)
	    $self->write_text($self->random_message(SNIDE_MESSAGES));
	    $self->newline();
	    $self->write_text(sprintf "The %s seems unaffected.", $desc);
	  } else {
	    # inside something else in this room
	    $self->write_text(sprintf $self->random_message(PILFER_LOCAL_MESSAGES), ${$zstat->toplevel_child->print});
	    $proceed = 1;
	  }
	} else {
	  $self->write_text($self->random_message(PILFER_REMOTE_MESSAGES));
	  $proceed = 1;
        }
        if ($proceed) {
	  $self->move_object($id, $current_room);
	  my $thing = (reverse(split /\s+/, $desc))[0];
	  # if description is multiple words, use the last one.
          # example: zork 1, "jewel-encrusted egg" becomes "egg".
	  # (parser doesn't understand "jewel-encrusted" part)
	  # room for improvement: check to make sure this word
	  # is in dictionary
	  $self->steal_turn("take " . $thing);
	  $just_one_newline = 1;
        }
      } else {
	die "unknown cheat $token";
      }
    } elsif ($what) {
$self->write_text(sprintf "I don't know what that is, though I have seen a %s that you might be interested in...", ${$object_cache->get_random()});
    } elsif ($token eq "pilfer") {
      $self->write_text("Please tell me what you want to pilfer.");
    } elsif ($token eq "bamf") {
      $self->write_text("Please tell me what you want to make disappear.");
    } else {
      $self->write_text("Can you be more specific?");
    }
  }

  $self->newline();
  $self->newline() unless $just_one_newline;
  $self->suppress_output();
  # suppress parser output ("I don't know the word XXX.");
}

sub get_object_cache {
  # FIX ME
  unless ($_[0]->object_cache()) {
    my $cache = new Games::Rezrov::ZObjectCache();
    $cache->load_names();
    $_[0]->object_cache($cache);
  }
  return $_[0]->object_cache();
}

sub random_message {
  my ($self, @messages) = @_;
  my $index;
  my $last_hash = $self->last_random() || $self->last_random({});
  my $last_stamp = $last_hash->{$messages[0]};
  while (1) {
    $index = int(rand(scalar @messages));
    last if (@messages == 1 or 
	     !defined($last_stamp) or
	     $index ne $last_stamp);
    # don't use the same index twice in a row for a given set of messages
  }
  $last_hash->{$messages[0]} = $index;
  return $messages[$index];
}

sub nice_list {
  if (@_ == 1) {
    return $_[0];
  } elsif (@_ == 2) {
    return join " or ", @_;
  } else {
    return join(", ", @_[0 .. ($#_ - 1)]) . ", or " . $_[$#_];
  }
}

sub decode_dictionary {
  # decode entire dictionary
  my ($self) = @_;

  unless ($self->dictionary_fully_decoded()) {
    my $dict_start = $self->dictionary_word_start();
    my $ztext = $self->ztext();
    my $num_words = $self->entry_count();
    my $entry_length = $self->entry_length();
    my $by_name = $self->decoded_by_word();
    my $by_address = $self->decoded_by_address();
    my $address;

    for (my $index = 0; $index < $num_words; $index++) {
      $address = $dict_start + ($index * $entry_length);
      unless (exists $by_address->{$address}) {
	my $word = $ztext->decode_text($address);
	$by_name->{$$word} = $address;
	$by_address->{$address} = $$word;
      }
    }
  }

  $self->dictionary_fully_decoded(1);
  
}

sub dump_dictionary {
  my ($self, $what) = @_;
  $self->decode_dictionary();
  my $by_name = $self->decoded_by_word();
  my $by_address = $self->decoded_by_address();

  my $rows = Games::Rezrov::StoryFile::rows();
  my $columns = Games::Rezrov::StoryFile::columns();
  my $len = $self->encoded_word_length();
  my $fit = int($columns / ($len + 2));
  my $fmt = '%-' . $len . "s";
  my $wrote = 0;

  my @words;
  if ($what) {
    @words = grep {/^$what/} sort keys %{$by_name};
  } else {
    my %temp = %{$by_name};
    if (Games::Rezrov::ZOptions::SHAMELESS()) {
      my $token_len = Games::Rezrov::StoryFile::header()->encoded_word_length();
      my ($word, $copy);
      foreach $word ("michael", "edmonson") {
        $copy = $word;
	$copy = substr($copy,0,$token_len) if length $copy > $token_len;
	$temp{$copy} = 1;
      }
    }
    @words = sort keys %temp;
  }

  foreach (@words) {
    $self->write_text(sprintf $fmt, $_);
    if (++$wrote % $fit) {
      $self->write_text("  ");
    } else {
      $self->newline();
    }
  }
}

sub dump_objects {
  my ($self, $type, $what) = @_;
  my $object_cache = $self->get_object_cache();
  my $last = $object_cache->last_object();
  
  $SIG{"__WARN__"} = sub {};
  # intercept perl's silly "deep recursion" warnings
  
  if ($type == 1) {
    # show object relationships
    if ($what) {
      my @hits = $object_cache->find($what, "-all" => 1);
      if (@hits > 1) {
	$self->write_text(sprintf 'Hmm, which do you mean: %s?', nice_list(map {$_->[1]} @hits));
      } elsif (@hits == 1) {
	my $zstat = new Games::Rezrov::ZObjectStatus($hits[0]->[0],
						     $object_cache);

	if (my $pr = $zstat->parent_room()) {
	  $self->dump_object($pr, OMAP_START_INDENT, 1);
	} else {
	  $self->dump_object($object_cache->get($hits[0]->[0]), OMAP_START_INDENT, 1);
	}
      } else {
	$self->write_text(sprintf 'I have no idea what you mean by "%s."', $what);
      }
    } else {
      my ($zo, $pid);
      my (%objs, %parents, @tops, %seen);
      for (my $i = 1; $i <= $last; $i++) {
	$zo = $object_cache->get($i);
	$pid = $zo->get_parent_id();
	$objs{$i} = $zo;
	$parents{$i} = $pid;
      }

      for (my $i = 1; $i <= $last; $i++) {
	$pid = $parents{$i};
	if ($pid == 0 or !$objs{$pid}) {
	  push @tops, $i;
	}
      }

      foreach (@tops) {
	next if exists $seen{$_};
	$self->dump_object($objs{$_}, OMAP_START_INDENT, 0, \%seen);
      }
    }
  } else {
    # list rooms/items
    foreach ($type == 2 ? $object_cache->get_rooms() : $object_cache->get_items()) {
      $self->write_text(" " . $_);
      $self->newline();
    }
  }
  #  delete $SIG{"__WARN__"};
  # doesn't restore handler (!)
  $SIG{"__WARN__"} = "";
  # but this does
}

sub dump_object {
  my ($self, $object, $indent, $no_sibs, $seen_ref) = @_;

  my $object_cache = $self->get_object_cache();
  my $id = $object->object_id();
  my $last = $object_cache->last_object();
  die unless $id;
  my $desc = $object_cache->print($id);
  if (defined $desc) {
    if ($seen_ref) {
      return if exists $seen_ref->{$id};
      $seen_ref->{$id} = 1;
    }
    $self->newline();
    $self->write_text((" " x $indent) . $$desc . " ($id)");
    my $child = $object_cache->get($object->get_child_id());
    $self->dump_object($child, $indent + OMAP_INDENT_STEP, 0, $seen_ref) if $child and
      $child->object_id() and
      $child->object_id() <= $last;
    unless ($no_sibs) {
      my $sib = $object_cache->get($object->get_sibling_id());
#      printf STDERR "sib of %s: %s (%d)\n", ${$object->print}, ${$sib->print}, $sib->object_id if $sib;
      $self->dump_object($sib, $indent, 0, $seen_ref) if $sib and
	$sib->object_id() and
	$sib->object_id() <= $last;
    }
  } else {
    print STDERR "No desc for item $id!\n";
  }
}

sub teleport {
  #
  #  cheat command: move the player to a new location
  #
  my ($self, $where) = @_;
  my $player_object = Games::Rezrov::StoryFile::player_object();
  if (!$where) {
    $self->write_text("Where to?");
  } elsif (!$player_object) {
    $self->write_text($self->random_message(CANT_FIND_YOU_YET_MESSAGES));
  } else {
    my $object_cache = $self->get_object_cache();
    my @hits = $object_cache->find($where, "-room" => 1);
    my @item_hits = $object_cache->find($where);
    if (@hits == 1) {
      # only one possible destination: proceed
      my $room_id = $hits[0]->[0];
      my $zstat = new Games::Rezrov::ZObjectStatus($room_id,
						   $object_cache);
      if ($zstat->is_current_room()) {
	# destination object is the current room: be rude
	$self->write_text($self->random_message(TELEPORT_HERE_MESSAGES));
      } else {
	# "teleport" to the new room
	$self->move_object($player_object, $room_id);
	# make the player object a child of the new room object
	$self->write_text($self->random_message(TELEPORT_MESSAGES));
	# print an appropriate message
	$self->steal_turn("look");
	# steal player's next turn to describe new location
      }
    } elsif (@item_hits == 1 and @hits == 0) {
      # user has specified an item instead of a room; try to teleport
      # to the room the item is in
      my $zstat = new Games::Rezrov::ZObjectStatus($item_hits[0]->[0],
						   $object_cache);
      
      if ($zstat->parent_room()) {
	# item was in a room
	my $proceed = 1;
	if ($zstat->is_current_room()) {
	  # destination is the current room: be rude
	  $self->write_text($self->random_message(TELEPORT_HERE_MESSAGES));
	  $proceed = 0;
	} elsif ($zstat->is_player()) {
	  $self->write_text("Sure, just tell me where.");
	  $proceed = 0;
	} elsif ($zstat->is_toplevel_child()) {
	  # top-level, should be visible in new location
	  $self->write_text($self->random_message(TELEPORT_TO_ITEM_MESSAGES));
	} else {
	  # item is probably inside something else visible in the room
	  my $desc = $zstat->toplevel_child()->print();
	  $self->write_text(sprintf "I think it's around here somewhere; try the %s.", $$desc);
	  # print description of item's toplevel container
	}
	if ($proceed) {
	  # move the player to the room and steal turn to look around
	  $self->move_object($player_object,
			     $zstat->parent_room()->object_id());
	  $self->steal_turn("look");
	}
      } else {
	# can't determine parent (many objects are in limbo until 
	# something happens)
	my $random = $object_cache->get_random("-room" => 1);
	$self->write_text(sprintf "I don't where that is; how about the %s?", $$random);
      }
    } elsif (@hits > 1) {
      # ambiguous destination
      $self->write_text(sprintf 'Hmm, where you mean: %s?',
			 nice_list(sort map {$_->[1]} @hits));
    } elsif (@item_hits > 1) {
      # ambiguous item
      $self->write_text(sprintf 'Hmm, which do you mean: %s?',
			 nice_list(sort map {$_->[1]} @item_hits));
    } else {
      # no clue at all
      my $random = $object_cache->get_random("-room" => 1);
      $self->write_text(sprintf "I don't where that is; how about the %s?", $$random);
    }
  }
}

sub frotz {
  # cheat command --
  # "frotz" emulation, from Enchanter spell to cause something to emit light.
  # Zork I/II/III define frotz in their dictionaries!  Aliases: "futz", "lumen"
  #
  # Light is usually provided by a particular object attribute,
  # which varies by game...
  my ($self, $what) = @_;

  my @SUPPORTED_GAMES = (
			 [ ZORK_1, 20 ],
			 [ ZORK_2, 19 ],
			 [ ZORK_3, 15 ],
			 [ INFIDEL, 21, 10 ],
			 # In Infidel, attribute 21 provides light,
			 # attribute 10 seems to show "lit and burning" in
			 # inventory
			 [ ZTUU, 9 ],
			 [ PLANETFALL, 5 ]
			);

  my @attributes = $self->support_check(@SUPPORTED_GAMES);
  return unless @attributes;
#  die join ",", @attributes;
  
  unless ($what) {
    $self->write_text("Light up what?");
  } else {
    # know how to do it
    my $object_cache = $self->get_object_cache();
    my @hits = $object_cache->find($what);
    if (@hits == 1) {
      # just right
      my $id = $hits[0]->[0];
      my $zo = $object_cache->get($id);
      my $zstat = new Games::Rezrov::ZObjectStatus($id,
						   $object_cache);
      my $proceed = 0;
      if ($zstat->is_player()) {
	$self->write_text($self->random_message(FROTZ_SELF_MESSAGES));
      } elsif ($zstat->in_inventory()) {
	$proceed = 1;
      } elsif ($zstat->in_current_room()) {
	if ($zstat->is_toplevel_child()) {
	  # items that are a top-level child of the room are OK;
	  # even if we can't pick them up, assume they are visible
	  $proceed = 1;
	} else {
	  # things inside other things might not be visible; be coy
	  $self->write_text(sprintf "Why don't you pick it up first.");
	}
      } else {
	$self->write_text(sprintf "I don't see any %s here!", $what);
      }

      if ($proceed) {
	# with apologies to "Enchanter"  :)
	my $desc = $zo->print();
	$self->write_text(sprintf "There is an almost blinding flash of light as the %s begins to glow! It slowly fades to a less painful level, but the %s is now quite usable as a light source.", $$desc, $$desc);
	foreach (@attributes) {
	  $zo->set_attr($_);
	}
      }
    } elsif (@hits > 1) {
      # too many 
      $self->write_text(sprintf 'Hmm, which do you mean: %s?',
			 nice_list(sort map {$_->[1]} @hits));
    } else {
      # no matches
      $self->write_text("What's that?");
    }
  }
}

sub travis {
  #
  # cheat command -- "travis": turn an ordinary item into a weapon.
  # 
  # "Weapons" just seem to be items with a certain object property set...
  #
  # You lookin' at me?
  #
  my ($self, $what) = @_;
  my @SUPPORTED_GAMES = (
			 [ ZORK_1, 29 ],
		       );

  my $property = $self->support_check(@SUPPORTED_GAMES) || return;

  unless ($what) {
    $self->write_text("What do you want to use as a weapon?");
  } else {
    my $object_cache = $self->get_object_cache();
    my @hits = $object_cache->find($what);
    if (@hits == 1) {
      my $zo = $object_cache->get($hits[0]->[0]);
      my $zstat = new Games::Rezrov::ZObjectStatus($hits[0]->[0],
						   $object_cache);
      if ($zstat->is_player()) {
	$self->write_text("You're scary enough already.");
      } elsif ($zstat->in_inventory()) {
	if ($zo->test_attr($property)) {
	  $self->write_text(sprintf "The %s looks pretty menacing already.", ${$zo->print});
	} else {
	  $zo->set_attr($property);
	  $self->write_text(sprintf $self->random_message(TRAVIS_MESSAGES), ${$zo->print});
	}
      } elsif ($zstat->in_current_room()) {
	$self->write_text("Pick it up, then we'll talk.");
      } else {
	$self->write_text(sprintf "I don't see any %s here!", ${$zo->print});	
      }
    } elsif (@hits > 1) {
      $self->write_text(sprintf 'Hmm, which do you mean: %s?',
			 nice_list(sort map {$_->[1]} @hits));
    } else {
      $self->write_text("What's that?");
    }
  }
}

sub support_check {
  # check if this game matches one of a given a list of game versions
  my ($self, @list) = @_;
  foreach (@list) {
    my ($name, $rnum, $serial, $checksum, @stuff) = @{$_};
    if (Games::Rezrov::StoryFile::is_this_game($rnum, $serial, $checksum)) {
      # yay
      return @stuff == 1 ? $stuff[0] : @stuff;
    }
  }
  # failed, complain:
  $self->write_text(sprintf "Sorry, this trickery only currently works in the following game%s:", scalar @list == 1 ? "" : "s");
  foreach (@list) {
    $self->newline();
    $self->write_text(sprintf "  - %s (release %d, serial number %s, checksum %s)", @{$_});
  }

  if (my $title = Games::Rezrov::StoryFile::game_title()) {
    my $header = Games::Rezrov::StoryFile::header();
    $self->newline();
    $self->newline();
    $self->write_text("You appear to be playing \"$title\", ");
    $self->write_text(sprintf "release %s, ", $header->release_number());
    $self->write_text(sprintf "serial number %s, ", $header->serial_code());
    $self->write_text(sprintf "with checksum %s.", $header->file_checksum());
  }
  
  return ();
}

sub tail {
  # cheat command --
  # follow an object as it moves around; usually a "person"
  my ($self, $what) = @_;
  unless ($what) {
    $self->write_text("Who or what do you want to tail?");
  } else {
    my $object_cache = $self->get_object_cache();
    my @hits = $object_cache->find($what);
    if (@hits == 1) {
      # just right
      my $id = $hits[0]->[0];
      my $zo = $object_cache->get($id);
      my $target_desc = $zo->print();
      my $zstat = new Games::Rezrov::ZObjectStatus($id,
						   $object_cache);
      if (my $parent = $zstat->parent_room()) {
	Games::Rezrov::StoryFile::tail($id);
	my $zs2 = new Games::Rezrov::ZObjectStatus($parent->object_id(),
						   $object_cache);
	if ($zs2->in_current_room()) {
	  # in same room already
	  $self->write_text(sprintf "OK.");
	} else {
	  # our subject is elsewhere: go there
	  my $desc = ${$parent->print()};
      	  if ($$target_desc =~ /^mr?s\. /i) {
   	    $self->write_text(sprintf "All right; she's in the %s.", $desc);
	  } elsif ($$target_desc =~ /^mr\. /i) {
   	    $self->write_text(sprintf "All right; he's in the %s.", $desc);
	  } else {
	    $self->write_text(sprintf "All right; heading to %s.", $desc);
	  }
          $self->newline();
   	  $self->teleport($desc);
        }
      } else {
	$self->write_text(sprintf "I don't know where %s is...", ${$zo->print});
      }
    } elsif (@hits > 1) {
      $self->write_text(sprintf 'Hmm, which one: %s?',
			 nice_list(sort map {$_->[1]} @hits));
    } else {
      $self->write_text("Who or what is that?");
    }
  }

}

sub help {
  # when user types "help" and the game doesn't understand
  my $self = shift;

  my @stuff = gethostbyname("www.netscape.com");
  if (@stuff) {
    my $url;
    my $fvo = Games::Rezrov::StoryFile::full_version_output() || "";
    if ($fvo =~ /infocom/i) {
      # we're playing an infocom game
      $url = $self->random_message(HELP_INFOCOM_URLS);
    } else {
      # title disabled or not infocom
      $url = $self->random_message(HELP_GENERIC_URLS);
    }
    $self->call_web_browser($url);
  } else {
    $self->write_text("Connect to the Internet, then maybe I'll help you.");
  }
  $self->newline();
  $self->newline();
  $self->suppress_output();
}


sub call_web_browser {
  # try to call a web browser for a particular URL.
  # uses Netscape's remote-control interface if available
  my ($self, $url) = @_;
  
  if ($^O eq "MSWin32") {
    $self->write_text($self->random_message(WWW_HELP_MESSAGES));

#      system "start $url";
    # "start" seems to be trouble: app seems to hang if we run it 
    # more than once without first closing the invoked web browser.

    my $cmd;
    
    #
    # find user's default browser
    #
    require Win32::TieRegistry;
    $SIG{"__WARN__"} = sub {};
    # Win32::TieRegistry can spew warnings

    my $key = new Win32::TieRegistry(
				     'Classes\\.htm',
				    );
    # find class name for .htm file association

    if ($key) {
      my $class = ($key->GetValue(''))[0];
      if ($class) {
	# find invocation
	#
	# IE:
	# "C:\Program Files\Internet Explorer\iexplore.exe" -nohome
	#
	# Firefox: 
	# C:\PROGRA~1\MOZILL~2\FIREFOX.EXE -url "%1"
	#
	my $ckey = 'Classes\\' . $class . '\\shell\\open\\command';
	$key = new Win32::TieRegistry($ckey);
	if ($key) {
	  ($cmd) = $key->GetValue('');
	  if ($cmd =~ /%1/) {
	    # placeholder for url (Phoenix|(Fire(bird|fox)))
	    $cmd =~ s/\%1/$url/;
	  } else {
	    # raw (IE), just append
	    $cmd .= " " . $url;
	  }
	}
      }
    }
    
    my $exec_error = 0;
    if ($cmd) {
      require Win32::Process;
      import Win32::Process;

      my ($exe_name, $cmd_line);

      if ($cmd =~ /^([\"\'])/) {
	# exe name is quoted (e.g. IE); need to unquote before executing
	my $regexp = '^' . $1 . '([^\\' . $1 . ']+)' . $1 . '\s*(.*)';
	$cmd =~ /$regexp/ || die;
	($exe_name, $cmd_line) = ($1, $2);
      } else {
	# unquoted executable (e.g. firefox)
	$cmd =~ /^(\S+)\s*(.*)/;
	($exe_name, $cmd_line) = ($1, $2);
      }

      my $pobj;
      unless (
	  Win32::Process::Create($pobj,
			     $exe_name,
			     $cmd_line,
			     0,
			     NORMAL_PRIORITY_CLASS(),
			     ".")
	     ) {
	$self->newline();
	my $error = Win32::FormatMessage(Win32::GetLastError());
	$error =~ s/\s+$//;
	$self->write_text(sprintf 'You quake in your boots as a booming voice intones: "%s"', $error);
	$exec_error = 1;
      }
    }

    if (not($cmd) or $exec_error) {
      # whatever
      system "explorer $url";
    }

  } else {
    # any good platform-independent way of doing this??
    # total hack based on Linux environment
    my @paths = split /:/, $ENV{PATH};
    my ($browser, $basename);
    foreach my $path (@paths) {
      foreach my $exe (WWW_BROWSER_EXES) {
        my $fq = $path . '/' . $exe;
	if (-x $fq) {
	  $browser = $fq;
          $basename = $exe;
	  last;
	}	
      }     
      last if $browser;
    }   
   
    if ($browser and $ENV{DISPLAY}) {
      # found www browser executable on path
      $self->write_text($self->random_message(WWW_HELP_MESSAGES));
      my $tried_remote;
      my $cmd;
      if ($basename eq "netscape" or $basename eq "phoenix" or $basename eq "firebird") {
         $tried_remote = 1;
	 $cmd = sprintf "%s -remote 'openURL(%s)' >/dev/null 2>&1", $browser, $url;
	 system $cmd;
	 # try remote invocation if browser is known to support it
      }
      if ($tried_remote ? $? : 1) {
         # remote command failed or browser not running
         my $cmd = sprintf '%s %s >/dev/null 2>&1 &', $browser, $url;
         # horrible
         system $cmd;
      }	    
    } else {
      # not X, or can't find browser, give up
      $self->write_text(sprintf "Perhaps the answers you seek may be found at %s.  Sadly I am too feeble to take you there directly.", $url);
    }   
  }
}

sub set_attr {
  #
  # cheat command: turn an object attribute on or off
  #
  my ($self, $what) = @_;
#  $what =~ s/^\s+//;
#  $what =~ s/\s+$//;
  my @stuff = split /\s+/, $what;
  if (@stuff == 3) {
    my ($oid, $pid, $state) = @stuff;
    if ($state) {
      Games::Rezrov::StoryFile::set_attr($oid, $pid);
    } else {
      Games::Rezrov::StoryFile::clear_attr($oid, $pid);
    }
    $self->write_text("Duly tweaked.");
  } else {
    $self->write_text("Specify object ID, attribute ID, state (0=clear, 1=set)");
  }
}

sub set_property {
  #
  # cheat command: set an object's property to a specified value
  #
  my ($self, $what) = @_;
  my @stuff = split /\s+/, $what;
  if (@stuff == 3) {
    my ($oid, $property, $value) = @stuff;
    Games::Rezrov::StoryFile::put_property($oid, $property, $value);
    $self->write_text("Duly tweaked.");
  } else {
    $self->write_text("Specify object ID, property ID, value");
  }
}

sub decode_text_at {
  # attempt to decode text at a given address; hack, not a real command
  my ($self, $what) = @_;
  return unless $what;
  my $zt = Games::Rezrov::StoryFile::ztext();
  Games::Rezrov::StoryFile::write_zchunk($zt->decode_text($what));
}

sub decode_all_text {
  # hack, try to find and decode all text in the game.
  my ($self, $start, $sl, $min_words) = @_;
  my $zt = Games::Rezrov::StoryFile::ztext();
  my $header = Games::Rezrov::StoryFile::header();
  my $flen = $header->file_length();
  $start = $header->static_memory_address() unless $start;
  $min_words = 3 unless $min_words;
#  die $start;
#  $start = 78463;

  my $SHOW_LEVEL = $sl || 4;
  # 1. unconditionally show text decoded from each possible address
  # 2. skip text ending at locations we've previously decoded as not bad
  # 3. don't show what we think is bad text
  # 4. only show text we're highly confident of

  my @last_after;

 ADDRESS:
  for (my $i=$start; $i < $flen; $i++) {
    my ($blob, $after) = $zt->decode_text($i);

    unless ($SHOW_LEVEL <= 1) {
      # if this blob's decoded end address matches one of the
      # end addresses of "okay" chunks we've seen recently,
      # skip it.
      foreach (@last_after) {
	next ADDRESS if $_ == $after;
      }
    }

    my $definitely_ok = 0;
    my $bad = 0;
    
    my @words;
    if (1) {
      if ($$blob =~ /\s{2,}/) {
	# sequential whitespace
	$bad = "too much whitespace" unless $$blob =~ /(\*{3,}|\x0d|\d\.\s+[A-Z])/;
	# except:
	# - asterisks
	# - 80840: You have two choices: 1. Leave  2. Become dinner.
      }

      $bad = "leading junk I" if $$blob =~ /^\s*[a-z\d\'\-]+[A-Z]\w/;
      # leading junk before a sentence starts.
      # planetfall:
      #  29023: [ok: 4] mxnYou're already in it!
      #  42037: [ok: 5] 'vnhnYou're already in the booth!
      #  59517: [definitely ok: 17] -uhnThe door is locked. You probably have to turn the dial to some number to open it.
      #
      # z1:
      #  31560: [definitely ok: 12] qduvQlhmIt's a well known fact that only schizophrenics say "Hello" to a

      $bad = "leading junk II" if $$blob =~ /^\s*[A-Z\d]\w*[a-z]+[A-Z]/;
      # z1:
      #  28386: [definitely ok: 13] HmZORK I: The Great Underground Empire
      #  34419: [ok: 3] 5mHow singularly useless.
      #
      # pf:
      #  29021: [definitely ok: 4] AsmxnYou're already in it!
      #  41486: CHnThe elevator door closes just as the monsters reach it! You slump back against the wall, exhausted from the chase. The elevator begins to move downward.

      $bad = "leading junk III" if $$blob =~ /^[a-z]+ [A-Z]/;
      # pf:
      # 26811: [ok: 10] edavkkthm Floyd giggles. "You look funny without any clothes on."

      # but make sure:
      # 106966: [definitely ok: 43] "Memoo tuu awl lab pursunel: Duu tuu xe daanjuris naatshur uv xe biioo eksperiments, an eemurjensee sistum haz bin instawld. Xis sistum wud flud xe entiir Biioo Lab wic aa dedlee fungasiid. Propur preecawshunz shud bee taakin if xis sistum iz evur yuuzd."



      if ($$blob =~ /(?<!\.\.)([,.][A-z])/) {
	# ok: "Mmm...that tasted just like" [planetfall]
	if ($$blob =~ /([\w\d]\.){2,}/) {
	  # numeric sections or acronyms:
	  # "Pouring or spilling non-liquids is specifically forbidden by section 17.9.2 of the Galactic Adventure Game Compendium of Rules."
	  # S.P.S. Flathead
	  1;
	} else {
	  $bad = "bad comma/period position: $1";
	}
	# ok: 
      }
	  
#      $bad = "bad period/sentence" if $$blob =~ /(?<!\.\.)\.\s+[a-z]/;
      # sentences must start capitalized; alas this breaks Zork I's
      # matchbox text (..."Mr. Anderson of Muddle, Mass. says:"...)
      foreach ($$blob =~ /(\w+)\.\s+[a-z]/g) {
	# look for suspicious periods, eg:
	# 43719: [ok: 20] vqu candles voa. and, being for the moment sated, throws it back. Fortunately, the troll has poor control, and the
	next if /[A-Z][a-z]+/;
	# but allow in proper abbreviations:
	# Mr. Anderson of Muddle, Mass. says: "Before I took this course I was a lowly bit twiddler. Now with what I learned at GUE Tech I feel really important and can obfuscate and confuse with the best."
	$bad = "suspicious period";
      }

      $bad = "space before period" if $$blob =~ /\s\.(?!\.\.)/;
      # ellipsis ok

      $bad = "bad comma" if $$blob =~ /\s,/;

#      $bad = "bad quote: $1" if $$blob =~ /(\s\')/;
      # OK: 
      #  - \n'Til one brave advent'rous spirit
      #  - 80588: The cyclops, tired of all of your games and trickery, grabs you firmly. As he licks his chops, he says "Mmm. Just like Mom used to make 'em." It's nice to be appreciated.

      $bad = "bad punctuation" if $$blob =~ /[\!\?]\w/;
      
#      $bad = "multi punctuation" if $$blob =~ /[\'\.\,\;\:\?]{2,}/;

      # problematic?:
#      $bad = 1 if $$blob =~ /[bcdfghjklmnpqrstvwxyz]{5,}/i;
      # if too many consonants in a row.
      # 4 not enough: "filthy"

      # odd capitalization (problematic):
      $bad = "weird capitalization I" if $$blob =~ /[a-z][A-Z]\s+/;
      $bad = "weird capitalization II" if $$blob =~ /\s[a-z]+[A-Z]/;
      # ok: InvisiClues
      
      $$blob =~ s/^\s+//;
      $$blob =~ s/\s+$//;
      # ignore leading/trailing whitespace
#      my @words = split /\s+/, $$blob;
      @words = split /\s+/, $$blob;

      unless (@words >= $min_words) {
	$bad = sprintf "only %d words", scalar @words
	  unless $$blob =~ /.+[\!\?\.\:]$/;
	# forgive low word counts for exclamations, etc
      }

      foreach (@words) {
	next unless length $_;
	# leading/trailing whitespace, or spaces around "..."
	# planetfall:
	#
	# Wow!!! Under the table are three keys, a sack of food, a reactor elevator access pass, one hundred gold pieces ... Just kidding. Actually, there's nothing there.

	next if $_ eq "...";

	next if /^[A-Z][a-z]+\.$/;
	# title; Mrs./Dr. etc

	next if /^[A-Z]\.$/;
	# initial: S. Eric Meretzky
	
	next if /^\(c\)$/i;
	# copyright

	s/\W+$//;
	s/^\W+//;
	# strip puntuncation, etc from end of sentences
	# catch cases like this -- ("n"), planetfall 29855
	# This n. You'll have to eat it right from the survival kit.
	# 80588: [no vowel: "Mmm] The cyclops, tired of all of your games and trickery, grabs you firmly. As he licks his chops, he says "Mmm. Just like Mom used to make 'em." It's nice to be appreciated.

	next unless $_;
	# might be leading punctuation:
	# 26127: [no vowel: ] , but both of these are blocked by closed bulkheads.
	next if /-/ and /^[\w-]+$/;
	# 67812: [no vowel: B-19-7] Suddenly, the robot comes to life and its head starts swivelling about. It notices you and bounds over. "Hi! I'm B-19-7, but to everyperson I'm called Floyd. Are you a doctor-person or a planner-person?
	
	next if /^\#?[\d,]+$/;
	# a number
	# 44128: There are 69,105 leaves here.
	# FIX ME: floating point/money/etc
	# 47374: [no vowel: #3] You are standing on the top of the Flood Control Dam #3, which was quite a tourist attraction in times far distant. There are paths to the north, south, and west, and a scramble down.


	unless (/[aeiouy]/i) {
	  # require words to contain at least one vowel...
	  # "y" allowed; eg "by"
	  $bad = "no vowel: $_" unless /[\.\#]/
	    or /^h?m{2,}$/i
	      or /^\d+(rd|st|nd|th)$/
		or /^\d+\/\d+/;
	  # except:
	  #  - 21st, 22nd, 23rd, 24th...
	  # 88472: [no vowel: 22nd] Grues are vicious, carnivorous beasts first introduced to Earth by a visiting alien spaceship during the late 22nd century. Grues spread throughout the galaxy alongside man. Although now extinct on all civilized planets, they still exist in some backwater corners of the galaxy. Their favorite diet is Ensigns Seventh Class, but their insatiable appetite is tempered by their fear of light.
	  #  - fractions (1/4)
	  #  - acronyms (eg. "S.P.S. Flathead")
	  #  - FDC#3
	  #  - Mmmm...
	  #  - Hmm
	  # but not:
	  # 37729: [no vowel: hm] hm You are also incredibly famished. Better get some breakfast!
	  #
	  #  - 
	}
	$bad = "embedded quotes: $_" if /\w+\"\w+/;
	# embedded quotes no good

	$bad = "too much mixed-case" if /([A-Z][a-z]+){3,}/;
	
	$bad = "unlikely word: $_" if /[A-z]\d[A-z]/;
	
	if (length $_ == 1) {
	  $bad = "bogus 1-char word: $_" unless /^[aio]$/i;
	  # few very 1-letter words legal
	  # "O, they ruled the solar system"
	} elsif (length($_) > 24) {
	  # ok: Br'gun-te'elkner-ipg'nun
	  # [planetfall]
	  $bad = "too long: $_";
	} else {

	  if (/^[aeiou]+$/i) {
	    $bad = "all vowels: $_" unless ($_ eq 'aa') or /^[MCLXVI]+$/;
	    # bad if all vowels:
	    #  - don't count y; "you" is ok
	    #  - roman numerals OK: 69098: [all vowels: II] The solid-gold coffin used for the burial of Ramses II is here.
	    # 
	    # however, planetfall at 106966:
	    # "Memoo tuu awl lab pursunel: Duu tuu xe daanjuris naatshur uv xe biioo eksperiments, an eemurjensee sistum haz bin instawld. Xis sistum wud flud xe entiir Biioo Lab wic aa dedlee fungasiid. Propur preecawshunz shud bee taakin if xis sistum iz evur yuuzd."
	  }
	  
	}
	
	$bad = "all consonants: $_" if $$blob =~ /^[bcdfghjklmnpqrstvwxyz]+$/i;
	# bad if all consonants
      }
      #	die "\"$_\" bad " . length($_) if $bad;
      1;
    }
  
    unless ($bad) {
      my @hits = ($$blob =~ /\.\s*\w/g);
      if (@hits) {
	# if the blob contains periods that are positioned in a way
	# that seems to make sense, consider the blob confirmed
	my $p_all_ok = 1;
	foreach (@hits) {
	  unless (/\.\s+[A-Z]/) {
	    $p_all_ok = 0;
	  }
	}
	$definitely_ok = 1 if $p_all_ok;
	#      printf STDERR "  comma check: %s, $bad $c_all_ok\n", $$blob;
      }
      
      $definitely_ok = 1 if $$blob =~ /\".*\"/;
      # embedded quoted string

      $definitely_ok = 1 if $$blob =~ /^[A-Z].+\.$/;

#      $definitely_ok = 1 if $$blob =~ /^[A-Z][A-z\d\s\'\-\.\!\,\;\:\(\)\?\*]+?\w[\!\?\.\:\"]{1,3}$/;
      $definitely_ok = 1 if $$blob =~ /^[A-Z].*[\!\?\.\:\"]{1,3}$/;
      # looks like one or more complete sentences.
      # allow ending with "..."
      # 44018: [ok: 6] I don't know the word "
    }

#    $definitely_ok = 0;

    unless ($bad) {
      push @last_after, $after;
      shift @last_after if @last_after > 5;
    }

    if ($bad ? $SHOW_LEVEL < 3 : $SHOW_LEVEL == 4 ? $definitely_ok : 1) {
      $$blob =~ s/\x0d/\x0a/g;
      if (0) {
	# testing
	my $tag;
	if ($bad) {
	  $tag = "[$bad] ";
	} elsif ($SHOW_LEVEL == 4) {
	  $tag = "";
	} else {
	  $tag = sprintf "[%sok: %d] ",
	  ($definitely_ok ? "definitely " : ""),
	  scalar @words;
	}
	printf STDERR "%d: %s%s\n", $i, $tag, $$blob;
      } else {
	# for user
	$self->write_text(sprintf "%d: %s", $i, $$blob);
	$self->newline();
      }
    }
  
    if ($definitely_ok) {
      # if we're *really* sure about the blob, continue our decoding
      # after it's done (so we don't see redundant partially-decoded
      # bits).
      $i = $after - 1;
    }
  }
}

sub notify_toggle {
  # "notify" emulation: user is toggling state.
  my ($self) = @_;
  my $now = Games::Rezrov::ZOptions::notifying();
  my $status = $now ? 0 : 1;
  $self->write_text(sprintf "Score notification is now %s.", $status ? "on" : "off");
  $self->newline();
  $self->newline();
  $self->suppress_output();
  Games::Rezrov::ZOptions::notifying($status);
}

sub move_object {
  Games::Rezrov::StoryFile::insert_obj($_[1], $_[2]);
  # hee hee
}

sub steal_turn {
  Games::Rezrov::StoryFile::push_command($_[1]);
}

sub newline {
  Games::Rezrov::StoryFile::newline();
}

sub write_text {
  Games::Rezrov::StoryFile::write_text($_[1]);
}

sub suppress_output {
  Games::Rezrov::StoryFile::suppress_hack();
}

sub property_dump {
  my ($self, $what) = @_;
  my $header = Games::Rezrov::StoryFile::header();
  my $max_objects = $header->max_objects();
  my $oc = $self->object_cache();
  for (my $i=1; $i <= $max_objects; $i++) {
    my $zo = $oc->get($i);
    my $zp = $zo->get_property(Games::Rezrov::ZProperty::FIRST_PROPERTY);
    printf STDERR "%s: %s\n",
    ${$zo->print},
  ($zp->property_exists() ? $zp->property_number() : "no properties");
}
}

sub lummox {
  # cheat command: remove restrictions on weight and number of items
  # that can be carried.  So far, it seems that there are two global
  # variables involved: one holds the total weight of items that may
  # be carried, the other the maximum number of items that may be carried.
  #
  # Usually a 2OP compare_* opcode precedes this operation:
  #
  # count:1358 pc:37207 type:2OP opcode:3(0x03;raw=99) (compare_jg) operands:112,100
  # count:1359 pc:37211 type:1OP opcode:0(0x00;raw=160) (compare_jz) operands:1
  # count:1360 pc:37214 type:0OP opcode:2(0x02;raw=178) (print_text) operands:
  # count:1361 pc:37227 type:2OP opcode:2(0x02;raw=98) (compare_jl) operands:100,100
  # count:1362 pc:37259 type:0OP opcode:2(0x02;raw=178) (print_text) operands:
  # count:1363 pc:37262 type:0OP opcode:11(0x0b;raw=187) (newline) operands:
  # brass lantern: Your load is too heavy.
  #
  # see the "-hack" command-line switch to help decode which variable is used
  # for the opcode; in this case (Zork I, PC 37207, global variable # 133).

  my ($self) = @_;
  my @SUPPORTED_GAMES = (
			 [ ZORK_1, 133, 59 ],
			 [ ZORK_2, 159, 83 ],
			 [ ZORK_3, 184, 116 ],
			 [ PLANETFALL, 218, 128 ],
			);
  

  my ($total_weight, $max_items) = $self->support_check(@SUPPORTED_GAMES);
  return unless $total_weight;

  my $LOTSA_WEIGHT = 32000;
  my $LOTSA_ITEMS = 250;
  if (Games::Rezrov::StoryFile::get_global_var($total_weight) == $LOTSA_WEIGHT and Games::Rezrov::StoryFile::get_global_var($max_items) == $LOTSA_ITEMS) {
    $self->write_text("You feel pretty pumped up already.");
  } else {
    Games::Rezrov::StoryFile::set_global_var($total_weight, $LOTSA_WEIGHT);
    Games::Rezrov::StoryFile::set_global_var($max_items, $LOTSA_ITEMS);
    $self->write_text($self->random_message(LUMMOX_MESSAGES));
  }
}

sub systolic {
  # cheat command: lower blood pressure (bureaucracy only)
  my $self = shift;
  my @SUPPORTED_GAMES = (
			 [ BUREAUCRACY, 232, 32082 ]
			);

  if (my ($var, $value) = $self->support_check(@SUPPORTED_GAMES)) {
    Games::Rezrov::StoryFile::set_global_var($var, $value);
    $self->write_text("You feel a bit calmer.");
  }
}

sub medicate {
  # cheat command: manage blood pressure (bureaucracy only)
  my $self = shift;
  my @SUPPORTED_GAMES = (
			 [ BUREAUCRACY, 232, 32082 ]
			);

  if (my ($var, $value) = $self->support_check(@SUPPORTED_GAMES)) {
    my $data = $self->bp_cheat_data();
    my $doses = 1;
    if ($data) {
      $doses = $data->[0] + 1;
    }
    $self->bp_cheat_data([$doses, $var, $value]);

    if ($doses > 2) {
      $self->write_text("While your blood pressure medication is tantalizingly candylike, you've had enough.");
    } else {
      my $msg = "You pop a generic angiotensin-II receptor antagonist. " . $self->random_message(ANGIOTENSIN_MESSAGES);
      $self->write_text($msg);
    }
  }
}

sub blood_pressure_cheat_hook {
  # cheat: automatically manage blood pressure in "Bureaucracy"
  my ($self) = @_;
  my $ref = $self->bp_cheat_data();
  if ($ref) {
    # active
    my ($doses, $var, $value) = @{$ref};
    Games::Rezrov::StoryFile::set_global_var($var, $value);
  }
}

sub vilify {
  # cheat command --
  # make an object attackable.
  my ($self, $what) = @_;

  my @SUPPORTED_GAMES = (
			 [ ZORK_1, 30 ],
			);

  my @attributes = $self->support_check(@SUPPORTED_GAMES);
  return unless @attributes;
#  die join ",", @attributes;
  
  unless ($what) {
    $self->write_text("Vilify what?");
  } else {
    # know how to do it
    my $object_cache = $self->get_object_cache();
    my @hits = $object_cache->find($what);
    if (@hits == 1) {
      # just right
      my $id = $hits[0]->[0];
      my $zo = $object_cache->get($id);
      my $zstat = new Games::Rezrov::ZObjectStatus($id,
						   $object_cache);
      my $proceed = 0;
      my $msg;
      if ($zstat->is_player()) {
	$proceed = 1;
	$msg = $self->random_message(VILIFY_SELF_MESSAGES);
      } elsif ($zstat->in_current_room()) {
	$proceed = 1;
	$msg = $self->random_message(VILIFY_MESSAGES);
	if ($zstat->in_inventory()) {
	  $msg =~ s/\.$/; I don't know why you're toting it around./;
	}
      } else {
	$self->write_text(sprintf "I don't see any %s here!", $what);
      }

      if ($proceed) {
	# with apologies to "Enchanter"  :)
	my $desc = $zo->print();
	$self->write_text(sprintf $msg, $$desc);
	foreach (@attributes) {
	  $zo->set_attr($_);
	}
      }
    } elsif (@hits > 1) {
      # too many
      $self->write_text(sprintf 'Hmm, which do you mean: %s?',
			 nice_list(sort map {$_->[1]} @hits));
    } else {
      # no matches
      $self->write_text("What's that?");
    }
  }
}

sub baste {
  # cheat command --
  # make an object edible.
  my ($self, $word, $what) = @_;

  my @SUPPORTED_GAMES = (
			 [ ZORK_1, 21 ],
			);

  my @attributes = $self->support_check(@SUPPORTED_GAMES);
  return unless @attributes;
#  die join ",", @attributes;
  
  unless ($what) {
    $self->write_text(sprintf "%s what?", ucfirst(lc($word)));
  } else {
    # know how to do it
    my $object_cache = $self->get_object_cache();
    my @hits = $object_cache->find($what);
    if (@hits == 1) {
      # just right
      my $id = $hits[0]->[0];
      my $zo = $object_cache->get($id);
      my $zstat = new Games::Rezrov::ZObjectStatus($id,
						   $object_cache);
      my $proceed = 0;
      my $msg;
      if ($zstat->is_player()) {
	$proceed = 1;
	$msg = sprintf 'Go back to %s!', $self->random_message(GO_BACK_TO_X);
	# ", hippie!"
      } elsif ($zstat->in_current_room()) {
	$proceed = 1;
	$msg = $self->random_message(BASTE_MESSAGES);
      } else {
	$self->write_text(sprintf "I don't see any %s here!", $what);
      }

      if ($proceed) {
	# with apologies to "Enchanter"  :)
	my $desc = $zo->print();
	$self->write_text(sprintf $msg, $$desc);
	foreach (@attributes) {
	  $zo->set_attr($_);
	}
      }
    } elsif (@hits > 1) {
      # too many
      $self->write_text(sprintf 'Hmm, which do you mean: %s?',
			 nice_list(sort map {$_->[1]} @hits));
    } else {
      # no matches
      $self->write_text("What's that?");
    }
  }
}

sub correct_typos {
  # attempt to correct typos as Nitfol interpreter does:
  #
  # If the entered word is in the dictionary, behave as normal.
  #
  # If the length of the word is less than 3 letters long, give up. We
  # don't want to make assumptions about what so short words might be.
  #
  # If the word is the same as a dictionary word with one transposition,
  # assume it is that word. exmaine becomes examine.
  #
  # If it is a dictionary word with one deleted letter, assume it is
  # that word. botle becomes bottle.
  #
  # If it is a dictionary word with one inserted letter, assume it is
  # that word. tastey becomes tasty.
  #
  # If it is a dictionary word with one substitution, assume it is that
  # word. opin becomes open.
  #
  # *** FIX ME: ***
  #  - what to do when corrected word is truncated?
  #    i.e. "mailbax" should be corrected to "mailbox", but token is "mailbo"
  #  - deletion with irrelevant last token letter:
  #    "malbox" should be "mailbo"
  #    => do an object lookup?

  my ($self, $line) = @_;
  my $raw_line = $line;
  chomp $line;

  $self->decode_dictionary();

  my %words = %{$self->decoded_by_word()};
  foreach (keys %Games::Rezrov::ZDict::MAGIC_WORDS) {
    # use a copy of the dictionary so we can add cheat verbs to the
    # list of known words
    $words{$_} = 1;
  }

  my $encoded_length = $self->encoded_word_length();
  my @all_words = keys %words;

  my $i;
  my @subs;

  my $zoc = Games::Rezrov::StoryFile::get_zobject_cache();
  $zoc->load_names();
  # ugh

  my $correct_word = sub {
    # attempt to typo-correct a given word; must return word
    # (original or changed).
    my ($word) = @_;
    my $new_word = $word;
    my $token = lc($word);
    $token = substr($token,0,$encoded_length)
      if length($token) > $encoded_length;
    my $tlen = length($token);
    unless (length($word) < 3 or exists $words{$token} or $word =~ /^#/) {
      # attempt correction unless:
      #  - word is too short
      #  - word is already in dictionary
      #  - word begins with a cheat/debug prefix ("#")	    
      my (@sub_hits, @trans_hits, @del_hits, @ins_hits);

      #
      # single-character insertion
      #
      for ($i=0; $i < $tlen; $i++) {
	my $try = "";
	for (my $j=0; $j < $tlen; $j++) {
	  $try .= substr($token, $j, 1) unless $j == $i;
	}
#	print "$token $try\n";
	push @ins_hits, $try if exists $words{$try};
      }

      #
      # single-character deletion
      #
      for ($i=1; $i < $tlen; $i++) {
	my $regexp = substr($token, 0, $i) . "." . substr($token, $i);
	$regexp = substr($regexp, 0, $encoded_length) if length($regexp) > $encoded_length;
	# i.e. in zork I, "malbox" search for "ma.lbox" must
	# search dictionary for "ma.lbo" (only 6 characters)

#	my @h = grep {/$regexp/} @all_words;
	my @h = grep {/^$regexp$/} @all_words;
#	printf "%s: %s\n", $regexp, join ",", @h;

	push @del_hits, @h if @h;
      }

      #
      #  single-character transpositions
      #
      for ($i=0; $i < $tlen - 1; $i++) {
	my $try = $token;
	my $save = substr($try, $i, 1);
	substr($try,$i,1) = substr($token,$i + 1,1);
	substr($try,$i+1,1) = $save;
	push @trans_hits, $try if exists $words{$try};
      }

      #
      #  single-character substitutions
      #
      for ($i=0; $i < $tlen; $i++) {
	my $regexp = $token;
	substr($regexp, $i, 1) = '.';
	my @hits = grep {/^$regexp$/} @all_words;
	push @sub_hits, @hits if @hits;
      }

      foreach (\@trans_hits, \@del_hits, \@ins_hits, \@sub_hits) {
	$new_word = $_->[0], last if @{$_};
      }

      if ($word ne $new_word) {
	#
	# correction found
	#

	if (length($new_word) == $encoded_length) {
	  # word might be truncated! e.g. in Zork I:
	  #
	  #    - user enters "leaflwt"
	  #    - actual word is "leaflet"
	  #    - dictionary entry is truncated to 6 characters, "leafle".
	  #
	  # ...this is ugly because the corrected word is printed
	  # to the screen.  Look for matches for the corrected word in
	  # the object database, using that object's description if it
	  # matches.

	  my @hits = $zoc->find($new_word);
	  if (@hits == 1) {
	    my $desc = $zoc->print($hits[0]->[0]);
	    if (index(lc($$desc), lc($new_word)) == 0) {
	      # require a perfect match; too strict?
	      # in Zork I, "mailbox" object lookup returns "small mailbox",
	      # which works, but I'm not certain other typos would do as well.
#	      printf STDERR "%s => %s => %s\n", $word, $new_word, $$desc;
	      $new_word = $$desc;
	      # huzzah
	    }
	  }
	}

	push @subs, [ $word, $new_word ];
      }
    }

#    print STDERR "word: $new_word\n";
    return $new_word;
  };

#  $line =~ s/(\w+)/&$correct_word($1)/eg;
  # NO: excludes cheat commands
#  $line =~ s/(\S+)/&$correct_word($1)/eg;
  # NO: includes punctuation

  $line =~ s/([\#\w]+)/&$correct_word($1)/eg;

#  print STDERR "corrected: $line\n";
  # HACK: doesn't follow the tokenization rules in tokenize_line().
  # Direct queries to my associate, Dr. Sosumi.

  my $msg = "";
  if (@subs) {
    # something was corrected
    $msg = '[Assuming you meant ';
    for ($i=0; $i < @subs; $i++) {
      if ($i > 0) {
	$msg .= ', ';
	$msg .= 'and ' if $i == $#subs;
      }
      $msg .= sprintf '"%s" instead of "%s"', $subs[$i]->[1], $subs[$i]->[0];
    }
    $msg .= '.]';
  }

  return ($line, $msg);
}

sub gmacho {
  # cheat command --
  # move any spell to your scrollbook (Enchanter series)
  my ($self, $token, $what, %options) = @_;

  my $quiet = $options{"-quiet"};

  unless ($what) {
    $self->write_text(sprintf "%s what?", ucfirst(lc($token)));
    return 0;
  }

  my @SUPPORTED_GAMES = (
			 [ ENCHANTER, 4 ],
			 [ SORCERER, 7 ],
			 [ SPELLBREAKER, 0 ],
			 # attribute determining whether object is a spell.
			 # don't know how this works in Spellbreaker;
			 # looks like it "should" be attr 18, but doesn't work!
			);

  my @attributes = $self->support_check(@SUPPORTED_GAMES);
  return 0 unless @attributes;

  my $spell_attr = $attributes[0];

  my $object_cache = $self->get_object_cache();

  my @hits = $object_cache->find("spell book");
  unless (@hits == 1) {
    $self->write_text("Hmm, I can't seem to find your spell book.") unless $quiet;
    return 0;
  }
  my $spellbook_id = $hits[0]->[0];
  
  my @try = $what;
  unless ($what =~ / spell$/i) {
    push @try, $what . " spell";
  }

  my $found;
  my $worked = 0;
  foreach my $try (@try) {
    @hits = $object_cache->find($try);
    if (@hits == 1) {
      # found desired spell
      $found = 1;
      my $spell_id = $hits[0]->[0];
      
      my $usable = 1;
      my $zo = $object_cache->get($spell_id);

      if ($spell_attr) {
	# we know how to test if the requested object is a spell
	my $zp = $zo->get_property($attributes[0]);
	$usable = $zp->property_exists();
      } 

      if ($usable) {
	my $parent = $zo->get_parent();
	if ($parent and $parent->object_id() == $spellbook_id) {
	  # spell is already in spell book
	  my $thing = $what;
	  $thing =~ s/\s+.*//;
	  $self->write_text("Great idea, Berzio, if only the $thing spell weren't already in your spellbook.") unless $quiet;
	} else {
	  $self->move_object($spell_id, $spellbook_id);
	  $self->write_text($self->random_message(GMACHO_MESSAGES)) unless $quiet;
	  $worked = 1;
	}
      } else {
	$self->write_text("That doesn't appear to be a spell.") unless $quiet;
      }
      last;
    }
  }
  $self->write_text("I can't find that spell, if that is a spell.") unless $found or $quiet;
  return $worked;
}

sub voluminus {
  # cheat command --
  # expand the capacity of a container object.
  #
  # BTW, it's not that I don't know how to spell "voluminous".
  # I'm just a grown man who's read all the Harry Potter books.

  my ($self, $token, $what) = @_;
  my @SUPPORTED_GAMES = (
			 [ ZORK_1, 19, 11, 10 ],
			 # 0 = game ID
			 # 1 = attribute # for whether object is a container
			 # 2 = attribute # for whether container is open
			 # 3 = property # for container capacity
			);

  my @attributes = $self->support_check(@SUPPORTED_GAMES);
  return unless @attributes;
  my ($attr_container, $attr_container_open, $property_capacity) = @attributes;
  
  unless ($what) {
    $self->write_text("Voluminus what?");
  } else {
    # given an object
    my $object_cache = $self->get_object_cache();
    my @hits = $object_cache->find($what);
    if (@hits == 1) {
      # just right
      my $id = $hits[0]->[0];
      my $zo = $object_cache->get($id);
      my $zstat = new Games::Rezrov::ZObjectStatus($id,
						   $object_cache);
      my $proceed = 0;
      my $msg;
      if ($zstat->is_player()) {
	$msg = $self->random_message(VOLUMINUS_SELF_MESSAGES);
      } elsif ($zstat->in_current_room()) {
	if ($zo->test_attr($attr_container)) {
	  # is the specified object a container?
	  $proceed = 1;
	  if ($zo->test_attr($attr_container_open)) {
	    $msg = $self->random_message(VOLUMINUS_MESSAGES);
	  } else {
	    $msg = $self->random_message(VOLUMINUS_CLOSED_MESSAGES);
	  }
	} else {
	  # not a container
	  $msg = "It's difficult to see how the %s could hold more, given that it can't hold anything.";
	}
      } else {
	$msg = sprintf "I don't see any %s here!", $what;
      }

      if ($msg) {
	my $desc = $zo->print();
	$self->write_text(sprintf $msg, $$desc);
      }

      if ($proceed) {
	Games::Rezrov::StoryFile::put_property($id, $property_capacity, PLENTY_O_ROOM);
      }
    } elsif (@hits > 1) {
      # too many
      $self->write_text(sprintf 'Hmm, which do you mean: %s?',
			 nice_list(sort map {$_->[1]} @hits));
    } else {
      # no matches
      $self->write_text("What's that?");
    }
  }
}

sub compartmentalize {
  # cheat command --
  # make an object into a container.
  # *** doesn't seem to work: non-containers seem to be missing required capacity property.

  my ($self, $token, $what) = @_;
  my $PLENTY_O_ROOM = 32000;
  my @SUPPORTED_GAMES = (
			 [ ZORK_1, 19, 11, 10 ],
			 # 0 = game ID
			 # 1 = attribute # for whether object is a container
			 # 2 = attribute # for whether container is open
			 # 3 = property # for container capacity
			);

  my @attributes = $self->support_check(@SUPPORTED_GAMES);
  return unless @attributes;
  my ($attr_container, $attr_container_open, $property_capacity) = @attributes;
  
  unless ($what) {
    $self->write_text("Compartmentalize what?");
  } else {
    # given an object
    my $object_cache = $self->get_object_cache();
    my @hits = $object_cache->find($what);
    if (@hits == 1) {
      # just right
      my $id = $hits[0]->[0];
      my $zo = $object_cache->get($id);
      my $zstat = new Games::Rezrov::ZObjectStatus($id,
						   $object_cache);
      my $proceed = 0;
      my $msg;
      if ($zstat->is_player()) {
	$msg = $self->random_message(VOLUMINUS_SELF_MESSAGES);
      } elsif ($zstat->in_current_room()) {
	$proceed = 1;
	$msg = $self->random_message("compartmentalize test");
      } else {
	$msg = sprintf "I don't see any %s here!", $what;
      }

      if ($msg) {
	my $desc = $zo->print();
	$self->write_text(sprintf $msg, $$desc);
      }

      if ($proceed) {
	Games::Rezrov::StoryFile::set_attr($id, $attr_container);
	Games::Rezrov::StoryFile::set_attr($id, $attr_container_open);
	Games::Rezrov::StoryFile::put_property($id, $property_capacity, PLENTY_O_ROOM);
      }
    } elsif (@hits > 1) {
      # too many
      $self->write_text(sprintf 'Hmm, which do you mean: %s?',
			 nice_list(sort map {$_->[1]} @hits));
    } else {
      # no matches
      $self->write_text("What's that?");
    }
  }
}

sub bookworm  {
  # cheat command --
  # move all game spells to your scrollbook (Enchanter series)
  my ($self, $token, $what, %options) = @_;

  my @SUPPORTED_GAMES = (
			 [ ENCHANTER, 4 ],
			 [ SORCERER, 7 ],
			 [ SPELLBREAKER, 0],
			 # - attribute determining whether object is a spell
			);

  my @attributes = $self->support_check(@SUPPORTED_GAMES);
  return unless @attributes;

  my $object_cache = $self->get_object_cache();
  my @hits = $object_cache->find(" spell");
  
  if (@hits) {
    my $imported = 0;
    foreach my $ref (@hits) {
      next unless $ref->[1] =~ / spell$/i;
#      printf "DEBUG: %s\n", $ref->[1];
      $imported += $self->gmacho("gmacho", $ref->[1], "-quiet" => 1);
    }
    if ($imported) {
      $self->write_text("Your spellbook spins in the air, its pages flapping wildly!");
    } else {
      $self->write_text("Your spellbook twitches feebly.");
    }
  } else {
    $self->write_text("Sorry, I couldn't find any spells.");
  }


}

1;
