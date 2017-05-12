package Encode::Guess::Educated;

use utf8;
use v5.10;
use strict;
use warnings;
use warnings FATAL => "utf8";
use charnames qw(:full);

use Carp 	 qw(carp croak cluck confess);
use Encode 	 qw(:fallback_all find_encoding encode decode);

# intentionally suppress import of guess_encoding() 
use Encode::Guess qw(); 

use List::Util 	 qw(sum max);
use Scalar::Util qw(refaddr reftype blessed looks_like_number);

use autouse "Unicode::UCD" 	=> qw(charinfo);

########################################################################

# forward definitions for functions in this module

sub known_encoding(_);
sub debug;
sub debugging();
sub pull_examples;
sub str2nummistr(_);
sub strnum_sort;
sub uniq;
sub uniquote(_);
sub whoami();
sub whowasi();

########################################################################

$| = 1;

our $VERSION = 0.03;

my @default_suspects = qw(

  iso-8859-1   
  iso-8859-15  
  iso-8859-2   
  iso-8859-5   

  cp1252       
  cp1250       
  cp1251       

  MacRoman     

);

my %default_training_data;

########################################################################
########################################################################
########################################################################
## OO API FOLLOWS
########################################################################
########################################################################
########################################################################

sub panic {
    confess "INTERNAL ERROR: @_";
} 

sub _validate_list_context() {

    my ($package,     $filename,    $line, 
        $subroutine,  $hasargs,     $wantarray, 
        $evaltext,    $is_require,
        $hints,       $bitmask,     $hinthash) = caller(1);

    $wantarray			|| panic "wanted to be called in list context";
} 

sub _validate_argc($$) { 
    my($have, $want) = @_;
    $have == $want 		|| panic "have $have arguments but wanted $want";
} 

sub _validate_argc_min($$) { 
    my($have, $want) = @_;
    $have >= $want 		|| panic "have $have arguments but wanted $want or more";
} 

sub _validate_object_invocant { 
    my($self) = @_;
    blessed($self) 		|| panic "object method call invoked at class method";
} 

sub _validate_class_invocant { 
    my($class) = @_;
   !blessed($class) 		|| panic "object method call invoked at class method";
}

sub _validate_private_method() { 
    caller(1) eq __PACKAGE__ 	|| panic "don't call private methods";
}

sub _validate_defined($) { 
    my($scalar) = @_;
    defined($scalar) 		|| panic "expected defined argument";
}

sub _validate_nonref($) { 
    my($arg) = @_;
    !ref($arg) 			|| panic "expected nonreference argument";
}

sub _validate_known_encoding($) { 
    my($encoding) = @_;
    _validate_defined($encoding);
    _validate_nonref($encoding);
    known_encoding($encoding) 	|| panic "unknown encoding $encoding";
} 

sub _validate_numeric($) {
    my($n) = @_;
    looks_like_number($n) 	|| panic "$n doesn't look like a number";
} 

sub _validate_nonnumeric($) {
    my($n) = @_;
   !looks_like_number($n) 	|| panic "$n doesn't look like a number";
} 

sub _validate_nonnegative_integer($) { 
    my($int) = @_;
    _validate_nonref($int);
    $int =~ /^[0-9]+\z/ 	|| panic "expected positive integer, not $int";
}

sub _validate_positive_integer($) { 
    my($int) = @_;
    _validate_nonref($int);
    $int =~ /^[1-9][0-9]*\z/ 	|| panic "expected positive integer, not $int";
}

sub _validate_numeric_range($$$) {
    my($n, $low, $high) = @_;
    _validate_numeric($n);
    $n >= $low && $n <= $high 	|| panic "expected $low <= $n <= $high";
} 

sub _validate_reftype($$) {
    my($type, $arg) = @_;
    reftype($arg) eq $type 	|| panic "expected reftype of $type";
} 

sub _validate_strlen($) { 
    my($string) = @_;
    _validate_defined($string);
    _validate_nonref($string);
    length($string) > 0 	|| panic "expected lengthier string";
}

sub _validate_no_wide_characters($) { 
    my($str) = @_;
    $str !~ /[^\x00-\xFF]/ 	|| panic "unexpected wide characters";
}

sub _validate_has_nonascii($) { 
    my($str) = @_;
    $str =~ /\P{ASCII}/ 	|| panic "expected non-ASCII in string";
}

sub _validate_is_plainfile($) {
    my($path) = @_;
    -e $path 			|| panic "can't stat $path: $!";
    -f _ 			|| panic "$path isn't a regular file";
    -s _ 			|| panic "$path is empty";
} 

########################################################################
########################################################################
########################################################################


# class constructor
sub new :method {

    _validate_class_invocant(@_);
    _validate_argc(@_ => 1);

    my($class) = @_;

    my $self = {
	TRAINING_DATA => undef,
	SUSPECTS      => [ ],
	BYTES	      => [ ],
	REPORT 	      => {
	    GUESSED_ENCODING	 => undef,
	    TOTAL_HIGH_BYTES 	 => undef,
	    DISTINCT_HIGH_BYTES  => undef,
	    DATA_LENGTH_IN_BYTES => undef,
	    SAMPLE		 => undef,
	    ERROR		 => undef,
	    AS_STRING		 => undef,
	}, 
    };

    bless $self, $class;

    $self->set_training_data( $class->get_training_data() );
    $self->set_suspects( $class->get_suspects() );

    return $self;
} 

sub _clear_report {

    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);
    _validate_private_method();

    my $self = shift();  

    for my $field (keys %{ $self->{REPORT} }) {
	$self->{REPORT}{$field} = undef;
    } 

} 

sub enable_debugging {
    _validate_argc(@_ => 2);
    my($self, $bool) = @_;
    our $DEBUG = $bool ? 1 : 0;
} 

sub get_guessed_encoding :method {

    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my($self) = @_;
    return $self->{REPORT}{GUESSED_ENCODING};
} 

sub get_report_distinct_high_bytes :method {

    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my $self = shift();  
    return $self->{REPORT}{DISTINCT_HIGH_BYTES};
} 

sub get_report_data_length :method { 

    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my $self = shift();  
    return $self->{REPORT}{DATA_LENGTH_IN_BYTES};
} 

sub get_report_total_high_bytes {

    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my $self = shift();  
    return $self->{REPORT}{TOTAL_HIGH_BYTES};
} 

sub get_errmsg {

    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my $self = shift();  
    return $self->{REPORT}{ERROR};

}

sub get_report_sample {

    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my $self = shift();  
    return $self->{REPORT}{SAMPLE};
}


sub _set_guessed_encoding :method { 

    _validate_argc(@_ => 2);
    _validate_object_invocant(@_);
    _validate_private_method();

    my($self, $encoding) = @_;

    _validate_known_encoding($encoding);

    $self->{REPORT}{GUESSED_ENCODING} = $encoding;
}

sub _set_report_data_length :method { 

    _validate_argc(@_ => 2);
    _validate_object_invocant(@_);
    _validate_private_method();

    my($self, $bytecount) = @_;

    _validate_nonnegative_integer($bytecount);

    $self->{REPORT}{DATA_LENGTH_IN_BYTES} = $bytecount;
}

sub _set_report_distinct_high_bytes {

    _validate_argc(@_ => 2);
    _validate_object_invocant(@_);
    _validate_private_method();

    my($self, $bytecount) = @_;

    _validate_nonnegative_integer($bytecount);

    $self->{REPORT}{DISTINCT_HIGH_BYTES} = $bytecount;

} 

sub _set_report_total_high_bytes {

    _validate_argc(@_ => 2);
    _validate_object_invocant(@_);
    _validate_private_method();

    my($self, $bytecount) = @_;

    _validate_nonnegative_integer($bytecount);

    $self->{REPORT}{TOTAL_HIGH_BYTES} = $bytecount;

} 

sub _set_errmsg {
    _validate_argc(@_ => 2);
    _validate_object_invocant(@_);
    _validate_private_method();

    my($self, $msg) = @_;

    _validate_strlen($msg);

    $self->{REPORT}{ERROR} = $msg;
}

sub _set_report_sample {
    _validate_argc(@_ => 2);
    _validate_object_invocant(@_);
    _validate_private_method();

    my($self, $sample) = @_;

    _validate_strlen($sample);
    _validate_has_nonascii($sample);

    $self->{REPORT}{SAMPLE} = $sample;
} 

sub get_byte_table :method {
    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my($self) = @_;
    return $self->{BYTES};
} 

sub _reset_byte_table :method {
    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);
    _validate_private_method();

    my($self) = @_;
    $self->{BYTES} = [ ];
} 

sub set_training_data :method {
    _validate_argc(@_ => 2);
    _validate_object_invocant(@_);

    my($self,$scores) = @_;

    _validate_reftype(HASH => $scores);

    my $keycount = 0;
    while (my($k, $v) = each %$scores) {
	$keycount++;
	_validate_nonnegative_integer($k);
	_validate_positive_integer($v);
    } 

    $keycount >   0
	|| croak "no training data";

    # e.g., Latin1 has 96 high-byte code points + 32 from the C1 control set
    $keycount >  90
	|| carp  "not much training data";

    $self->{TRAINING_DATA} = $scores;
    $self->_reset_byte_table();   # new training set invalidates old cache
}

sub get_training_data :method {
    _validate_argc(@_ => 1);

    my($self) = @_;

    if (blessed($self)) {
	return $self->{TRAINING_DATA};
    } else {
	# yes, this is supposed to be a copy
	return { %default_training_data };  
    } 

} 

sub get_suspects :method {
    _validate_argc(@_ => 1);

    my($self) = @_;

    if (blessed($self)) {
	return wantarray 
	    ?   @{ $self->{SUSPECTS} }
	    : [ @{ $self->{SUSPECTS} } ];
    } else {
	return wantarray 
	    ?   @default_suspects 
	    : [ @default_suspects ];
    } 

} 

sub set_suspects :method {

    _validate_argc_min(@_ => 2);
    _validate_object_invocant(@_);

    my($self,@suspects) = @_;
    for my $enc (@suspects) {
	_validate_known_encoding($enc);
	$self->_encache(known_encoding($enc));
    } 
    $self->{SUSPECTS} = \@suspects;
} 

sub add_suspects :method {

    _validate_argc_min(@_ => 2);
    _validate_object_invocant(@_);

    my($self,@suspects) = @_;
    for my $enc (@suspects) {
	_validate_known_encoding($enc);
	$self->_encache(known_encoding($enc));
    } 
    unshift @{ $self->{SUSPECTS} }, @suspects;
} 

##########
# USAGE: 
#   $weight = $self->_get_byte_weight($encoding, $byte)
#
# Mostly this method exists so we put all the sanity checks in one place.
# 
sub _get_byte_weight :method {

    _validate_argc(@_ => 3);
    _validate_private_method();
    _validate_object_invocant(@_);

    my($self, $encoding, $byte) = @_;

    _validate_known_encoding($encoding);
    _validate_numeric_range($byte, 128, 255);

    $byte &= 127;
    my $bt = $self->get_byte_table;

    croak "missing table for byte 128+$byte" unless $bt->[$byte];
    croak "missing encoding entry for $encoding at byte 128+$byte"
	unless exists $bt->[$byte]{$encoding};

    my $weight = $bt->[$byte]{$encoding};

    return $weight;
}

##########
# USAGE: $self->_set_byte_weight($encoding, $byte, $weight)
# (private method call from within another object method)
#
# Mostly this method exists so we can log it for debugging.
# 

sub _set_byte_weight :method {

    _validate_argc(@_ => 4);
    _validate_private_method();
    _validate_object_invocant(@_);

    my($self, $encoding, $byte, $weight) = @_;

    _validate_known_encoding($encoding);
    _validate_numeric_range($byte, 128, 255);

    if (defined $weight) { 
	_validate_numeric_range($weight, 0.0, 1.0);
	debug("enc $encoding %02X => %e", $byte, $weight);
    } else {
	debug("enc $encoding %02X => impossible", $byte);
    } 

    my $bt = $self->get_byte_table;
    croak "bad byte table" unless $bt && reftype($bt) eq "ARRAY";

    $byte &= 127;  # we only care about high bytes

    if (exists $bt->[$byte]{$encoding}) {
	##my $oldval = $bt->[$byte]{$encoding};
	carp sprintf "byte %02X already has a slot allocated to it", ($byte|128);
    } 
    $bt->[$byte]{$encoding} = $weight;

} 

sub guess_file_encoding :method {

    _validate_argc(@_ => 2);
    _validate_object_invocant(@_);

    my($self, $filename) = @_;

    _validate_is_plainfile($filename);

    open(my $fh, "<", $filename) 		    || croak "can't open < $filename: $!";
    binmode($fh)				    || croak "can't binmode $filename: $!";

    my $contents = do {
	local $/;   # "slurp" mode (read till eof)
	<$fh>;
    };
    close($fh)					    || croak "can't close $filename: $!";

    croak "bad read from $filename: $!"	    	    unless defined($contents);
    croak "empty read from nonempty $filename"	    unless length($contents);

    debug("guessing encoding of $filename");

    return $self->guess_data_encoding($contents);
}

sub guess_data_encoding :method {

    _validate_argc(@_ => 2);
    _validate_object_invocant(@_);

    my($self, $data) = @_;

    _validate_strlen($data);
    _validate_no_wide_characters($data);

    $self->_clear_report();

    $self->_set_report_data_length(length($data));

    # Faster to check for a single non-ASCII 
    # than to validate whole thing is ASCII only.
    unless ($data =~ /\P{ASCII}/) {  
	$self->_set_guessed_encoding("ascii");
	$self->_set_report_string("input contains only ascii");
	return "ascii";
    } 

    if (my $decoder = Encode::Guess::guess_encoding($data)) {
	if (ref $decoder) {
	    my $enc = $decoder->name;
	    $self->_set_guessed_encoding($enc);
	    my $reason = "guess from Encode::Guess::guess_encoding";
	    $self->_set_report_string($reason);

	    return $enc;
	} else {
	    debug("Encode::Guess::guess_encoding failed with: %s", $decoder);
	} 
    } 

    my @encodings = $self->get_suspects();

    @encodings = map { known_encoding } @encodings;

    my %scores = ();
    my %impossible = ();

    for (@encodings) { $scores{$_} = 0 }

    for ($data) { 
        while (/([\x80-\xFF])/g) {
            my $byte_ord = ord $1;
            debug("Checking byte table for %02X\n", $byte_ord);
            for my $enc (@encodings) {
                my $worth = $self->_get_byte_weight($enc, $byte_ord);
                if (defined $worth) {
		    debug("   %-12s %e += %e", $enc, $scores{$enc}, $worth);
                    $scores{$enc} += $worth;
                } else {
                    debug("   %-12s cannot have byte %02X\n", $enc, $byte_ord);
                    $impossible{$enc}++;
                } 
            } 
        }
    } 
    for my $bogus_enc (keys %impossible) {
        delete $scores{$bogus_enc};
    } 

    $self->_set_report_scores(\%scores);

    $self->_set_examples_from_data($data);

    panic "no high bytes" unless $self->get_report_total_high_bytes();

    $self->_evaluate_scores();

    return $self->get_guessed_encoding;

} 

sub _get_report_string {

    _validate_argc(@_ => 1);
    _validate_private_method();
    _validate_object_invocant(@_);

    my $self = shift();  
    return $self->{REPORT}{AS_STRING};
}

sub _set_report_string {

    _validate_argc(@_ => 2);
    _validate_private_method();
    _validate_object_invocant(@_);

    my($self, $report) = @_;

    _validate_strlen($report);
    _validate_nonnumeric($report);

    $self->{REPORT}{AS_STRING} = $report;
}


sub get_short_report {

    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my($self) = @_;

    my $reason = $self->_get_report_string();

    # this only makes sense for our own report, not the one from E:G::guess_encoding()
    for ($reason) {
	s/\A.*bytes=\d+\n//;
	s/\n\h+(\S+\h+)? => ".*"$//gm;
    } 
    return $reason;
}


sub get_long_report {
    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my($self) = @_;
    my $reason = $self->_get_report_string();
    return $reason;
} 

sub _set_report_scores {
    _validate_argc(@_ => 2);
    _validate_private_method();
    _validate_object_invocant(@_);

    my($self,$scores) = @_;
    _validate_reftype(HASH => $scores);

    $self->{REPORT}{SCORES} = $scores;
} 

sub get_report_scores {
    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my($self) = @_;
    return $self->{REPORT}{SCORES};
} 

sub _pick_winner :method {

    _validate_argc(@_ => 1);
    _validate_private_method();
    _validate_object_invocant(@_);

    my($self) = @_;

    my $scores_ref = $self->get_report_scores();
    my $samples    = $self->get_report_sample();

    _validate_reftype(HASH => $scores_ref);

    _validate_strlen($samples);
    _validate_no_wide_characters($samples);
    _validate_has_nonascii($samples);

    my @values = uniq values %$scores_ref;
    my $high_score = max @values;
    my @candidates = grep { $scores_ref->{$_} == $high_score } keys %$scores_ref;
    @candidates = $self->_sort_encodings_by_priority(@candidates);
    my @converts = uniq map { decode($_, $samples, Encode::FB_XMLCREF | Encode::LEAVE_SRC) } @candidates;
    if (@converts == 1) {
	my $winner = $candidates[0];
	$self->_set_guessed_encoding($winner);
	return $winner;
    } else {
	$self->_set_errmsg("tied scores have different Unicode conversions");
	return undef;
    } 

} 

sub _evaluate_scores :method {

    _validate_argc(@_ => 1);
    _validate_private_method();
    _validate_object_invocant(@_);

    my($self) = @_;

    my $scores_ref = $self->get_report_scores();
    _validate_reftype(HASH => $scores_ref);

    my $samples = $self->get_report_sample();
    _validate_strlen($samples);
    _validate_no_wide_characters($samples);
    _validate_has_nonascii($samples);

    my @values = uniq values %$scores_ref;
    my $sum_of_all_scores = sum @values;
    my $high_score = max @values;

    my $explanation = sprintf("total bytes=%d, high bytes=%d, distinct high bytes=%d\n",
				$self->get_report_data_length,
				$self->get_report_total_high_bytes,
				$self->get_report_distinct_high_bytes,
			     );

    for my $score (sort {$b <=> $a} @values) {

	next if $score == 0;
        my $winner = $score == $high_score ? "*" : " ";

	my $normalized_score = 100 * ($score / $sum_of_all_scores);
	$explanation .= sprintf "  $winner%9.6f %+f", $normalized_score, log($score);

	my @candidates = grep { $scores_ref->{$_} == $score } keys %$scores_ref;
	@candidates = $self->_sort_encodings_by_priority(@candidates);
	$explanation .= sprintf " %s\n", join(", " => @candidates);

	my @converts = uniq map { decode($_, $samples, Encode::FB_XMLCREF | Encode::LEAVE_SRC) } @candidates;
	if (@converts == 1) {
	    # next if $converts[0] =~ /[\x80-\x9F]/;
	    $self->_set_guessed_encoding($candidates[0]);
	    $explanation .= sprintf " %-12s => \"%s\"\n", "", $converts[0];
	    $explanation .= sprintf " %-12s => \"%s\"\n", "", uniquote($converts[0]);
	} else {
	    for my $enc (@candidates) {
		my $as_utf8 = decode($enc, $samples, Encode::FB_XMLCREF | Encode::LEAVE_SRC);
		next if $as_utf8 =~ /[\x80-\x9F]/;
		$explanation .= sprintf " %-12s => \"%s\"\n", $enc, $as_utf8;
		$explanation .= sprintf " %-12s => \"%s\"\n", $enc, uniquote($as_utf8);
	    } 
	} 

    } 

    $self->_set_report_string($explanation);

    $self->_pick_winner();

} 

sub _encache :method {

    _validate_argc(@_ => 2);
    _validate_private_method();
    _validate_object_invocant(@_);

    my($self, $enc) = @_;

    _validate_known_encoding($enc);

    our @B; local *B = $self->get_byte_table;

    return if exists $B[0]{$enc};

    debug("encaching weights for $enc");

    my $td = $self->get_training_data();
    my $total_training_data = sum values %$td;

BYTE:
    for my $byte_ord ( 0x80 .. 0xFF ) {
	my $unichr = eval { decode($enc, chr($byte_ord), FB_CROAK) };

	if ($@ || $unichr eq "\N{REPLACEMENT CHARACTER}") {
	    debug("byte %02X has no Unicode mapping in $enc", $byte_ord);
	    # so intentionally leave this byte slot value at undef
	    $self->_set_byte_weight($enc, $byte_ord, undef);
	    next BYTE;
	}

	die if ord($unichr) == 0xFFFD;

	my $count = $td->{ord $unichr};

	# several different strategies for missing training data
	if (!defined $count) {

	    debug("$enc byte %02X => U+%04X (%s) missing from training set\n", 
		$byte_ord, ord($unichr), 
		charnames::viacode(ord($unichr)) || "<unknown character name>");

	    # if in C1 control set, very unlikely to be correct
	    if ($unichr =~ /[\x80-\x9F]/) { 
		debug("enc $enc %02X => U+%02X from C1 control set at undef", 
		    $byte_ord, ord $unichr);
		$self->_set_byte_weight($enc, $byte_ord, undef);
		next BYTE;
	    }

	    # disqualify unless a private use character or from target script set
	    if ($unichr !~ /\p{Private_Use}/ 		&&  # *very* occasionally used
		$unichr !~ /[\p{Common}\p{Inherited}]/  &&  # eg: digits, punct, diacritics
		$unichr !~ /[\p{Latin}\p{Greek}]/           # regular letters
	       ) 
	    {

		debug("$enc byte %02X => U+%04X (%s) outside target script set", 
		    $byte_ord, ord($unichr), 
		    charnames::viacode(ord($unichr)) || "<unknown character name>");
		$self->_set_byte_weight($enc, $byte_ord, undef);
		next BYTE;
	    } 

	    # otherwise set the count to a neutral 0;
	    # could (should?) do add-one smoothing here, 
	    # or even figure out some negative weight
	    $count = 0;  
	} 

        my $weight = $count / $total_training_data;

	debug("$enc 0x%02X => U+%04X %8d / %8d = %e\n", 
		$byte_ord, ord($unichr),
		$count, $total_training_data, $weight);

	#$B[$byte_ord & 127]{$enc} = $weight;

	$self->_set_byte_weight($enc, $byte_ord, $weight);

    }

} 

sub dump_byte_table :method {

    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my($self) = @_;

    say "---DUMPING BYTE TABLE---";
    my $bt = $self->get_byte_table;
    for my $byte_ord ( 0x80 .. 0xFF ) {
	printf "byte 0x%02X => {\n", $byte_ord;
	my $href = $bt->[$byte_ord & 127];
	for my $enc (sort { 

	   ($href->{$b} || 0) <=> ($href->{$a} || 0) 
		              || 
	defined($href->{$b}) <=> defined($href->{$a})

			      || 

	lc(str2nummistr($a)) cmp lc(str2nummistr($b))
			     || 
	   str2nummistr($a)  cmp    str2nummistr($b)

			     || 

			$a   cmp  $b

		} keys %$href) 
     {
	    printf "  %-12s => ", $enc;
	    if (defined $href->{$enc}) {
		printf "%e ", $href->{$enc};
		my $unichr = decode($enc, chr($byte_ord), FB_CROAK);
		printf "U+%04X ", ord($unichr);
		my $name = charnames::viacode(ord $unichr) 
			 || sprintf "unnamed character U+%04X", ord $unichr;
		say $name;
	    } else {
		say "undef";
	    } 
	} 
	print "}\n";
    } 

    say "---END BYTE TABLE---";
}

sub dump_training_data :method {

    _validate_argc(@_ => 1);
    _validate_object_invocant(@_);

    my($self) = @_;

    require Unicode::Collate;

    state $collator = Unicode::Collate->new(
			  variable => "non-ignorable",
		      );

    say "---DUMPING TRAINING DATA---";

    my $td = $self->get_training_data;
    printf "Number of keys: %d\n", scalar keys   %$td; 
    printf "Sum of values:  %d\n", sum    values  %$td;

    my(@keycodes, @keychars);
    @keycodes = keys %$td;
    @keychars = map { chr } @keycodes;
    @keychars = $collator->sort(@keychars);
    @keycodes = map { ord } @keychars;

    my $max_value = max values %$td;
    my $max_width = length($max_value);

    my $sum_values = sum values %$td;

    for my $codepoint (@keycodes) {
	local $_ = chr($codepoint);

	##printf "%#06X => %*d, ", $codepoint, $max_width, $td->{$codepoint};
	printf "0x%06X => %25.20e, ", $codepoint, $td->{$codepoint} / $sum_values;
	print "  # ";


	if (/[\pC\pZ]/) {
	    print "<-> ";
	} else {
	    print "\N{DOTTED CIRCLE}" if /\p{BC=NSM}/;
	    #print "\N{LEFT-TO-RIGHT OVERRIDE}" if /[\p{BC=R}\p{BC=AL}\p{BC=AN}]/;
	    print " $_ ";
	    print " " unless /[\p{EA=F}\p{EA=W}]/;
	}

	my $name   = "<unassigned code point>";
	my $script = "unassigned_script";
	my $cat    = "Cn";

	if (my $ci = charinfo($codepoint)) { 
	    $name   = $$ci{name}     || "<unnamed code point in block=$$ci{block}>";
	    $script = $$ci{script}   || "unassigned";
	    $cat    = $$ci{category} || "XX";
	}

	print "gc=$cat ";
	printf "  sc=%-10s ", $script;
	say $name;

    }

    say "---END TRAINING DATA DUMP---";


} 

sub _sort_encodings_by_priority {

    _validate_argc_min(@_ => 2);
    _validate_private_method();
    _validate_object_invocant(@_);
    _validate_list_context();

    my($self, @enc) = @_;

    my %seen;

    my %rank;
    my $priority = -1;
    my @choices = map { known_encoding($_) } $self->get_suspects;
    for my $name (@choices) {
	$rank{$name} = $priority-- unless $seen{$name}++;
    } 

    my @sorted_encs = 
	map { $_->[0] }
	sort { 
		$b->[1] <=> $a->[1]
			||
		$a->[0] cmp $b->[0]
	    }
	map { [ $_ => $rank{ known_encoding($_) } || -1e6 ]  }
	@enc;

    return @sorted_encs;
} 

########################################################################
# utility functions
########################################################################

sub _set_examples_from_data {

    _validate_argc(@_ => 2);
    _validate_private_method();
    _validate_object_invocant(@_);

    my($self, $data) = @_;

    my @hits = ();

    my(%seen_string, %seen_char);

    my @chars = $data =~ /[\x80-\xFF]/g;
    $self->_set_report_total_high_bytes(scalar @chars);

    my @uniq_chars = uniq(@chars);
    $self->_set_report_distinct_high_bytes(scalar @uniq_chars);

    while ($data =~ m{ (?<string> 
			(?: \S+ \h* | \S* )
			(?<char> \P{ASCII} ) 
			(?: \h* \S+ | \S* )
		       )
	             }gx
	  )  
    {
	if (!      $seen_string{ $+{string} }++
	     &&  ++$seen_char{   $+{char}   } < 2)
	{
	    my $str = $+{string};
	    push @hits, $str;
	}
    }

    my $example_string = join(" ", @hits);
    $self->_set_report_sample($example_string) if @hits;
} 

sub known_encoding(_) {

    _validate_argc(@_ => 1);
    _validate_private_method();

    my($enc) = @_;

    _validate_strlen($enc);
    _validate_nonref($enc);

    if (my $enc_obj = Encode::find_encoding($enc)) {
        return $enc_obj->name || $enc;
    } else {
	return undef;
    } 

} 

# convert string with embedded decimal numbers into something
# that can be sorted by code point; that is, pad things like
# 23 into 0000027.  Also works on signed numbers and on floating
# point numbers.  
#
sub str2nummistr(_) {

    _validate_argc(@_ => 1);
    _validate_private_method();

    my($old) = @_;

    _validate_strlen($old);
    _validate_nonref($old);

    state $cache = { };
    return $$cache{$old} if defined $$cache{$old};
    my $new = $old;

    $new =~ s{ (   
	    # allow a plus or minus
	    # let them use any kind of dash but em and en
	    (?:
		(?! [\N{EM DASH}\N{EN DASH}]  )
		[\N{PLUS SIGN}\N{PLUS-MINUS SIGN}\N{MINUS-OR-PLUS SIGN}\p{Dash}]
	    )
	   (?: \b \d{1,3} (?: , \d{3} )+ \b
	     | \d+
	   )
       )
       (?: \. (\d+) )?
    }{
	my ($left, $right) = ($1, $2);
	$left =~ s/[\N{COMMA}\N{PLUS SIGN}\N{PLUS-MINUS SIGN}\N{MINUS-OR-PLUS SIGN}]//g;
	$left =~ s/\p{Pd}/-/g;
	my $result;
	if (length $right) {
	    $result = sprintf(" 000%+012d.%s ", $left, $right);

	} else { 
	    $result = sprintf(" 000%+012d ", $left);
	}

	# terrible hack to get signed numbers to sort right
	$result =~ tr[\-+][\N{CYRILLIC CAPITAL LETTER SCHWA}\N{CYRILLIC CAPITAL LETTER BE}];

	    $result;
    }xge;

    $$cache{$old} = $new;

    return $new;

} 

sub strnum_sort {

    _validate_argc_min(@_ => 1);
    _validate_private_method();
    _validate_list_context();

    return  map  { $_->[0] }
	    sort { $a->[1] cmp $b->[1] }
	    map  { [ $_ => lc str2nummistr($_) ] }
	    @_
	    ;

} 

sub uniq {
    _validate_private_method();
    _validate_list_context();

    my %seen;
    my @retlist;
    for (@_) {
	push @retlist, $_ unless $seen{$_}++;
    } 
    return @retlist;
} 

sub uniquote(_) {
    _validate_argc(@_ => 1);

    my($str) = @_;
    _validate_nonref($str);

    $str =~ s{ ( \P{ASCII} ) }
	     {
		my $ord = ord $1;
		my $name = charnames::viacode($ord) || sprintf("U+%04X", $ord);
		sprintf("\\N{%s}", $name);
	    }xge;
    return $str;
} 

sub debugging() { 
    _validate_private_method();
    return our $DEBUG;
}  

sub whoami()  { (caller(1))[3] }
sub whowasi() { (caller(2))[3] }

sub debug {
    _validate_private_method();
    return unless debugging();
    my($fmt, @args) = @_;
    my $subname = whowasi();
    printf STDOUT "DEBUG(%s): $fmt", $subname, @args;
    print "\n" unless $fmt =~ /\n\z/;
} 

########################################################################
########################################################################
########################################################################

# Class initializers

UNITCHECK { 

####################################
# Incidence of non-ASCII code points in PubMed Open Access as of December 2010.
#
# Table is UCA sorted and formatted using the dump_training_data
# object method, because sorting on anything else is trivial, so the 
# hard one is the default.
####################################

my %oed2_training = (
    0x000314 =>     241,   # ◌ ̔  gc=Mn   sc=Inherited  COMBINING REVERSED COMMA ABOVE
    0x000301 =>     325,   # ◌ ́  gc=Mn   sc=Inherited  COMBINING ACUTE ACCENT
    0x000300 =>       2,   # ◌ ̀  gc=Mn   sc=Inherited  COMBINING GRAVE ACCENT
    0x000306 =>    2214,   # ◌ ̆  gc=Mn   sc=Inherited  COMBINING BREVE
    0x000302 =>     201,   # ◌ ̂  gc=Mn   sc=Inherited  COMBINING CIRCUMFLEX ACCENT
    0x00030C =>       5,   # ◌ ̌  gc=Mn   sc=Inherited  COMBINING CARON
    0x000308 =>       5,   # ◌ ̈  gc=Mn   sc=Inherited  COMBINING DIAERESIS
    0x000303 =>     106,   # ◌ ̃  gc=Mn   sc=Inherited  COMBINING TILDE
    0x000307 =>      28,   # ◌ ̇  gc=Mn   sc=Inherited  COMBINING DOT ABOVE
    0x000327 =>     710,   # ◌ ̧  gc=Mn   sc=Inherited  COMBINING CEDILLA
    0x000304 =>     129,   # ◌ ̄  gc=Mn   sc=Inherited  COMBINING MACRON
    0x000320 =>     133,   # ◌ ̠  gc=Mn   sc=Inherited  COMBINING MINUS SIGN BELOW
    0x000336 =>     267,   # ◌ ̶  gc=Mn   sc=Inherited  COMBINING LONG STROKE OVERLAY
    0x000323 =>       6,   # ◌ ̣  gc=Mn   sc=Inherited  COMBINING DOT BELOW
    0x00032D =>      15,   # ◌ ̭  gc=Mn   sc=Inherited  COMBINING CIRCUMFLEX ACCENT BELOW
    0x000345 =>       9,   # ◌ ͅ  gc=Mn   sc=Inherited  COMBINING GREEK YPOGEGRAMMENI
    0x000651 =>       2,   # ◌ ّ  gc=Mn   sc=Inherited  ARABIC SHADDA
    0x0020E9 =>       2,   # ◌ ⃩  gc=Mn   sc=Inherited  COMBINING WIDE BRIDGE ABOVE
    0x0000B4 =>      48,   #  ´  gc=Sk   sc=Common     ACUTE ACCENT
    0x0000AF =>       5,   #  ¯  gc=Sk   sc=Common     MACRON
    0x0002D8 =>       4,   #  ˘  gc=Sk   sc=Common     BREVE
    0x0000A8 =>       6,   #  ¨  gc=Sk   sc=Common     DIAERESIS
    0x0000B8 =>       1,   #  ¸  gc=Sk   sc=Common     CEDILLA
    0x002010 => 1205194,   #  ‐  gc=Pd   sc=Common     HYPHEN
    0x002013 =>  163112,   #  –  gc=Pd   sc=Common     EN DASH
    0x002014 =>     430,   #  —  gc=Pd   sc=Common     EM DASH
    0x0000B7 =>  143383,   #  ·  gc=Po   sc=Common     MIDDLE DOT
    0x002018 =>  228766,   #  ‘  gc=Pi   sc=Common     LEFT SINGLE QUOTATION MARK
    0x002019 =>  737362,   #  ’  gc=Pf   sc=Common     RIGHT SINGLE QUOTATION MARK
    0x002039 =>      11,   #  ‹  gc=Pi   sc=Common     SINGLE LEFT-POINTING ANGLE QUOTATION MARK
    0x00203A =>      12,   #  ›  gc=Pf   sc=Common     SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
    0x00FF08 =>      13,   #  （ gc=Ps   sc=Common     FULLWIDTH LEFT PARENTHESIS
    0x00FF09 =>      13,   #  ） gc=Pe   sc=Common     FULLWIDTH RIGHT PARENTHESIS
    0x00FF3B =>       4,   #  ［ gc=Ps   sc=Common     FULLWIDTH LEFT SQUARE BRACKET
    0x00FF3D =>       4,   #  ］ gc=Pe   sc=Common     FULLWIDTH RIGHT SQUARE BRACKET
    0x00FF5B =>     102,   #  ｛ gc=Ps   sc=Common     FULLWIDTH LEFT CURLY BRACKET
    0x00FF5D =>     101,   #  ｝ gc=Pe   sc=Common     FULLWIDTH RIGHT CURLY BRACKET
    0x0000A7 =>   42343,   #  §  gc=So   sc=Common     SECTION SIGN
    0x0000B6 =>     235,   #  ¶  gc=So   sc=Common     PILCROW SIGN
    0x00204B =>   13003,   #  ⁋  gc=Po   sc=Common     REVERSED PILCROW SIGN
    0x0000A9 =>       4,   #  ©  gc=So   sc=Common     COPYRIGHT SIGN
    0x00FF0F =>       1,   #  ／ gc=Po   sc=Common     FULLWIDTH SOLIDUS
    0x002030 =>      16,   #  ‰  gc=Po   sc=Common     PER MILLE SIGN
    0x002020 =>    8882,   #  †  gc=Po   sc=Common     DAGGER
    0x002021 =>       9,   #  ‡  gc=Po   sc=Common     DOUBLE DAGGER
    0x002032 =>     967,   #  ′  gc=Po   sc=Common     PRIME
    0x002033 =>     362,   #  ″  gc=Po   sc=Common     DOUBLE PRIME
    0x002034 =>      24,   #  ‴  gc=Po   sc=Common     TRIPLE PRIME
    0x002038 =>       2,   #  ‸  gc=Po   sc=Common     CARET
    0x0002C8 =>    2550,   #  ˈ  gc=Lm   sc=Common     MODIFIER LETTER VERTICAL LINE
    0x0002CC =>     183,   #  ˌ  gc=Lm   sc=Common     MODIFIER LETTER LOW VERTICAL LINE
    0x0002DE =>      91,   #  ˞  gc=Sk   sc=Common     MODIFIER LETTER RHOTIC HOOK
    0x0000B0 =>    2165,   #  °  gc=So   sc=Common     DEGREE SIGN
    0x00211E =>      12,   #  ℞  gc=So   sc=Common     PRESCRIPTION TAKE
    0x002190 =>       3,   #  ←  gc=Sm   sc=Common     LEFTWARDS ARROW
    0x002192 =>     168,   #  →  gc=Sm   sc=Common     RIGHTWARDS ARROW
    0x0021CC =>       7,   #  ⇌  gc=So   sc=Common     RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
    0x002207 =>      74,   #  ∇  gc=Sm   sc=Common     NABLA
    0x00220B =>      42,   #  ∋  gc=Sm   sc=Common     CONTAINS AS MEMBER
    0x0000B1 =>     159,   #  ±  gc=Sm   sc=Common     PLUS-MINUS SIGN
    0x0000D7 =>     635,   #  ×  gc=Sm   sc=Common     MULTIPLICATION SIGN
    0x002260 =>      23,   #  ≠  gc=Sm   sc=Common     NOT EQUAL TO
    0x002212 =>    1416,   #  −  gc=Sm   sc=Common     MINUS SIGN
    0x002215 =>      19,   #  ∕  gc=Sm   sc=Common     DIVISION SLASH
    0x00221A =>     128,   #  √  gc=Sm   sc=Common     SQUARE ROOT
    0x00221E =>      53,   #  ∞  gc=Sm   sc=Common     INFINITY
    0x002225 =>     145,   #  ∥  gc=Sm   sc=Common     PARALLEL TO
    0x002227 =>      18,   #  ∧  gc=Sm   sc=Common     LOGICAL AND
    0x002228 =>      19,   #  ∨  gc=Sm   sc=Common     LOGICAL OR
    0x002229 =>       5,   #  ∩  gc=Sm   sc=Common     INTERSECTION
    0x00222A =>      12,   #  ∪  gc=Sm   sc=Common     UNION
    0x00222B =>      57,   #  ∫  gc=Sm   sc=Common     INTEGRAL
    0x002234 =>       8,   #  ∴  gc=Sm   sc=Common     THEREFORE
    0x00223C =>      93,   #  ∼  gc=Sm   sc=Common     TILDE OPERATOR
    0x002261 =>      48,   #  ≡  gc=Sm   sc=Common     IDENTICAL TO
    0x002263 =>       8,   #  ≣  gc=Sm   sc=Common     STRICTLY EQUIVALENT TO
    0x002265 =>       9,   #  ≥  gc=Sm   sc=Common     GREATER-THAN OR EQUAL TO
    0x002266 =>      28,   #  ≦  gc=Sm   sc=Common     LESS-THAN OVER EQUAL TO
    0x002267 =>       6,   #  ≧  gc=Sm   sc=Common     GREATER-THAN OVER EQUAL TO
    0x002282 =>      19,   #  ⊂  gc=Sm   sc=Common     SUBSET OF
    0x0022EE =>      11,   #  ⋮  gc=Sm   sc=Common     VERTICAL ELLIPSIS
    0x0022F0 =>       1,   #  ⋰  gc=Sm   sc=Common     UP RIGHT DIAGONAL ELLIPSIS
    0x0025B3 =>      34,   #  △  gc=So   sc=Common     WHITE UP-POINTING TRIANGLE
    0x00261B =>      36,   #  ☛  gc=So   sc=Common     BLACK RIGHT POINTING INDEX
    0x002625 =>       3,   #  ☥  gc=So   sc=Common     ANKH
    0x002627 =>       2,   #  ☧  gc=So   sc=Common     CHI RHO
    0x00263F =>      10,   #  ☿  gc=So   sc=Common     MERCURY
    0x002640 =>      25,   #  ♀  gc=So   sc=Common     FEMALE SIGN
    0x002642 =>      26,   #  ♂  gc=So   sc=Common     MALE SIGN
    0x002649 =>      12,   #  ♉  gc=So   sc=Common     TAURUS
    0x002652 =>       8,   #  ♒  gc=So   sc=Common     AQUARIUS
    0x002A7D =>      31,   #  ⩽  gc=Sm   sc=Common     LESS-THAN OR SLANTED EQUAL TO
    0x002A7E =>      15,   #  ⩾  gc=Sm   sc=Common     GREATER-THAN OR SLANTED EQUAL TO
    0x00266D =>      69,   #  ♭  gc=So   sc=Common     MUSIC FLAT SIGN
    0x00266F =>      21,   #  ♯  gc=Sm   sc=Common     MUSIC SHARP SIGN
    0x001D134 =>       1,   #  𝄴  gc=So   sc=Common     MUSICAL SYMBOL COMMON TIME
    0x001D135 =>       2,   #  𝄵  gc=So   sc=Common     MUSICAL SYMBOL CUT TIME
    0x00FFFD =>   10349,   #  �  gc=So   sc=Common     REPLACEMENT CHARACTER
    0x0002D0 =>      56,   #  ː  gc=Lm   sc=Common     MODIFIER LETTER TRIANGULAR COLON
    0x0000A2 =>      25,   #  ¢  gc=Sc   sc=Common     CENT SIGN
    0x0000A3 =>    2775,   #  £  gc=Sc   sc=Common     POUND SIGN
    0x0000E1 =>    5526,   #  á  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH ACUTE
    0x0000C1 =>       7,   #  Á  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH ACUTE
    0x0000E0 =>    2498,   #  à  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH GRAVE
    0x0000C0 =>      19,   #  À  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH GRAVE
    0x000103 =>     367,   #  ă  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH BREVE
    0x000102 =>       3,   #  Ă  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH BREVE
    0x0000E2 =>    3171,   #  â  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CIRCUMFLEX
    0x0000C2 =>     507,   #  Â  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH CIRCUMFLEX
    0x0001CE =>      19,   #  ǎ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CARON
    0x0000E5 =>     391,   #  å  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH RING ABOVE
    0x0000C5 =>     123,   #  Å  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH RING ABOVE
    0x0000E4 =>    2792,   #  ä  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH DIAERESIS
    0x0000C4 =>       9,   #  Ä  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH DIAERESIS
    0x0000E3 =>     265,   #  ã  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH TILDE
    0x000227 =>      25,   #  ȧ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH DOT ABOVE
    0x000226 =>       2,   #  Ȧ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH DOT ABOVE
    0x000101 =>   35015,   #  ā  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH MACRON
    0x000100 =>      10,   #  Ā  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH MACRON
    0x0000E6 =>   81225,   #  æ  gc=Ll   sc=Latin      LATIN SMALL LETTER AE
    0x0000C6 =>   17648,   #  Æ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER AE
    0x0001FD =>    2180,   #  ǽ  gc=Ll   sc=Latin      LATIN SMALL LETTER AE WITH ACUTE
    0x0001FC =>       1,   #  Ǽ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER AE WITH ACUTE
    0x0001E3 =>     107,   #  ǣ  gc=Ll   sc=Latin      LATIN SMALL LETTER AE WITH MACRON
    0x0001E2 =>       1,   #  Ǣ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER AE WITH MACRON
    0x000251 =>    6291,   #  ɑ  gc=Ll   sc=Latin      LATIN SMALL LETTER ALPHA
    0x000252 =>      54,   #  ɒ  gc=Ll   sc=Latin      LATIN SMALL LETTER TURNED ALPHA
    0x001D4B7 =>       1,   #  𝒷  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL B
    0x00212C =>       5,   #  ℬ  gc=Lu   sc=Common     SCRIPT CAPITAL B
    0x001E03 =>       1,   #  ḃ  gc=Ll   sc=Latin      LATIN SMALL LETTER B WITH DOT ABOVE
    0x000180 =>     436,   #  ƀ  gc=Ll   sc=Latin      LATIN SMALL LETTER B WITH STROKE
    0x000107 =>      55,   #  ć  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH ACUTE
    0x000109 =>       2,   #  ĉ  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH CIRCUMFLEX
    0x00010D =>     123,   #  č  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH CARON
    0x00010C =>      17,   #  Č  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH CARON
    0x00010B =>       7,   #  ċ  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH DOT ABOVE
    0x0000E7 =>    1356,   #  ç  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH CEDILLA
    0x0000C7 =>      21,   #  Ç  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH CEDILLA
    0x001E0B =>       2,   #  ḋ  gc=Ll   sc=Latin      LATIN SMALL LETTER D WITH DOT ABOVE
    0x001E11 =>      26,   #  ḑ  gc=Ll   sc=Latin      LATIN SMALL LETTER D WITH CEDILLA
    0x001E0D =>     142,   #  ḍ  gc=Ll   sc=Latin      LATIN SMALL LETTER D WITH DOT BELOW
    0x001E0C =>       5,   #  Ḍ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER D WITH DOT BELOW
    0x000110 =>    2501,   #  Đ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER D WITH STROKE
    0x0000F0 =>   39272,   #  ð  gc=Ll   sc=Latin      LATIN SMALL LETTER ETH
    0x0000E9 =>   32359,   #  é  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH ACUTE
    0x0000C9 =>     193,   #  É  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH ACUTE
    0x0000E8 =>    4603,   #  è  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH GRAVE
    0x000115 =>    6957,   #  ĕ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH BREVE
    0x0000EA =>    2654,   #  ê  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX
    0x0000CA =>       5,   #  Ê  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH CIRCUMFLEX
    0x00011B =>      53,   #  ě  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CARON
    0x0000EB =>    1811,   #  ë  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH DIAERESIS
    0x001EBD =>      10,   #  ẽ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH TILDE
    0x000117 =>     137,   #  ė  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH DOT ABOVE
    0x000229 =>    1163,   #  ȩ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CEDILLA
    0x000228 =>       1,   #  Ȩ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH CEDILLA
    0x000113 =>   11859,   #  ē  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH MACRON
    0x000112 =>       1,   #  Ē  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH MACRON
    0x001E17 =>       7,   #  ḗ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH MACRON AND ACUTE
    0x001EB9 =>       7,   #  ẹ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH DOT BELOW
    0x001EB8 =>       1,   #  Ẹ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH DOT BELOW
    0x000259 =>     377,   #  ə  gc=Ll   sc=Latin      LATIN SMALL LETTER SCHWA
    0x00025B =>     257,   #  ɛ  gc=Ll   sc=Latin      LATIN SMALL LETTER OPEN E
    0x00025A =>      26,   #  ɚ  gc=Ll   sc=Latin      LATIN SMALL LETTER SCHWA WITH HOOK
    0x00025C =>       6,   #  ɜ  gc=Ll   sc=Latin      LATIN SMALL LETTER REVERSED OPEN E
    0x001D50A =>      13,   #  𝔊  gc=Lu   sc=Common     MATHEMATICAL FRAKTUR CAPITAL G
    0x0001F5 =>       5,   #  ǵ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH ACUTE
    0x00011F =>       5,   #  ğ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH BREVE
    0x00011E =>       1,   #  Ğ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER G WITH BREVE
    0x00011D =>       2,   #  ĝ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH CIRCUMFLEX
    0x0001E7 =>       8,   #  ǧ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH CARON
    0x000121 =>      10,   #  ġ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH DOT ABOVE
    0x001E21 =>       2,   #  ḡ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH MACRON
    0x000263 =>    1887,   #  ɣ  gc=Ll   sc=Latin      LATIN SMALL LETTER GAMMA
    0x00210E =>      10,   #  ℎ  gc=Ll   sc=Common     PLANCK CONSTANT
    0x001D4BD =>       1,   #  𝒽  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL H
    0x00210C =>       3,   #  ℌ  gc=Lu   sc=Common     BLACK-LETTER CAPITAL H
    0x001D573 =>       4,   #  𝕳  gc=Lu   sc=Common     MATHEMATICAL BOLD FRAKTUR CAPITAL H
    0x001E23 =>       1,   #  ḣ  gc=Ll   sc=Latin      LATIN SMALL LETTER H WITH DOT ABOVE
    0x001E22 =>       1,   #  Ḣ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER H WITH DOT ABOVE
    0x001E25 =>     265,   #  ḥ  gc=Ll   sc=Latin      LATIN SMALL LETTER H WITH DOT BELOW
    0x001E24 =>      33,   #  Ḥ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER H WITH DOT BELOW
    0x001E2A =>       3,   #  Ḫ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER H WITH BREVE BELOW
    0x000127 =>      26,   #  ħ  gc=Ll   sc=Latin      LATIN SMALL LETTER H WITH STROKE
    0x002111 =>       2,   #  ℑ  gc=Lu   sc=Common     BLACK-LETTER CAPITAL I
    0x0000ED =>    3847,   #  í  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH ACUTE
    0x0000CD =>       5,   #  Í  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH ACUTE
    0x0000EC =>      78,   #  ì  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH GRAVE
    0x00012D =>     350,   #  ĭ  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH BREVE
    0x00012C =>       3,   #  Ĭ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH BREVE
    0x0000EE =>    2216,   #  î  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH CIRCUMFLEX
    0x0000CE =>       3,   #  Î  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH CIRCUMFLEX
    0x0001D0 =>       6,   #  ǐ  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH CARON
    0x0000EF =>    1161,   #  ï  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH DIAERESIS
    0x000129 =>       2,   #  ĩ  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH TILDE
    0x00012B =>   13635,   #  ī  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH MACRON
    0x00012A =>      10,   #  Ī  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH MACRON
    0x00026A =>      36,   #  ɪ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL I
    0x000269 =>       1,   #  ɩ  gc=Ll   sc=Latin      LATIN SMALL LETTER IOTA
    0x000196 =>       2,   #  Ɩ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER IOTA
    0x0001F0 =>       1,   #  ǰ  gc=Ll   sc=Latin      LATIN SMALL LETTER J WITH CARON
    0x001E33 =>      59,   #  ḳ  gc=Ll   sc=Latin      LATIN SMALL LETTER K WITH DOT BELOW
    0x001E32 =>       9,   #  Ḳ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER K WITH DOT BELOW
    0x002113 =>       1,   #  ℓ  gc=Ll   sc=Common     SCRIPT SMALL L
    0x002112 =>       1,   #  ℒ  gc=Lu   sc=Common     SCRIPT CAPITAL L
    0x001E37 =>      30,   #  ḷ  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH DOT BELOW
    0x001E3D =>       7,   #  ḽ  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH CIRCUMFLEX BELOW
    0x000141 =>      19,   #  Ł  gc=Lu   sc=Latin      LATIN CAPITAL LETTER L WITH STROKE
    0x00029F =>       1,   #  ʟ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL L
    0x00028E =>      10,   #  ʎ  gc=Ll   sc=Latin      LATIN SMALL LETTER TURNED Y
    0x001E41 =>      16,   #  ṁ  gc=Ll   sc=Latin      LATIN SMALL LETTER M WITH DOT ABOVE
    0x001E43 =>      32,   #  ṃ  gc=Ll   sc=Latin      LATIN SMALL LETTER M WITH DOT BELOW
    0x000144 =>      34,   #  ń  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH ACUTE
    0x000148 =>       4,   #  ň  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH CARON
    0x0000F1 =>     731,   #  ñ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH TILDE
    0x0000D1 =>       1,   #  Ñ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER N WITH TILDE
    0x001E45 =>     114,   #  ṅ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH DOT ABOVE
    0x001E44 =>       2,   #  Ṅ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER N WITH DOT ABOVE
    0x001E47 =>     167,   #  ṇ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH DOT BELOW
    0x001E4B =>      16,   #  ṋ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH CIRCUMFLEX BELOW
    0x000272 =>       6,   #  ɲ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH LEFT HOOK
    0x00014B =>     257,   #  ŋ  gc=Ll   sc=Latin      LATIN SMALL LETTER ENG
    0x0000F3 =>    3029,   #  ó  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH ACUTE
    0x0000D3 =>      16,   #  Ó  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH ACUTE
    0x0000F2 =>     101,   #  ò  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH GRAVE
    0x00014F =>     142,   #  ŏ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH BREVE
    0x00014E =>       1,   #  Ŏ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH BREVE
    0x0000F4 =>    3101,   #  ô  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX
    0x0000D4 =>       1,   #  Ô  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH CIRCUMFLEX
    0x0001D2 =>       9,   #  ǒ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CARON
    0x0000F6 =>    5712,   #  ö  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH DIAERESIS
    0x0000D6 =>      26,   #  Ö  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH DIAERESIS
    0x00022B =>       7,   #  ȫ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH DIAERESIS AND MACRON
    0x0000F5 =>      22,   #  õ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH TILDE
    0x00022F =>      13,   #  ȯ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH DOT ABOVE
    0x0000F8 =>     476,   #  ø  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH STROKE
    0x0000D8 =>       5,   #  Ø  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH STROKE
    0x0001FF =>      10,   #  ǿ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH STROKE AND ACUTE
    0x00014D =>   12489,   #  ō  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH MACRON
    0x00014C =>      47,   #  Ō  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH MACRON
    0x001E53 =>       5,   #  ṓ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH MACRON AND ACUTE
    0x001ECD =>       2,   #  ọ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH DOT BELOW
    0x000153 =>    8146,   #  œ  gc=Ll   sc=Latin      LATIN SMALL LIGATURE OE
    0x000152 =>     643,   #  Œ  gc=Lu   sc=Latin      LATIN CAPITAL LIGATURE OE
    0x000254 =>      76,   #  ɔ  gc=Ll   sc=Latin      LATIN SMALL LETTER OPEN O
    0x002119 =>      35,   #  ℙ  gc=Lu   sc=Common     DOUBLE-STRUCK CAPITAL P
    0x001E57 =>       4,   #  ṗ  gc=Ll   sc=Latin      LATIN SMALL LETTER P WITH DOT ABOVE
    0x000278 =>     239,   #  ɸ  gc=Ll   sc=Latin      LATIN SMALL LETTER PHI
    0x00211C =>       7,   #  ℜ  gc=Lu   sc=Common     BLACK-LETTER CAPITAL R
    0x0024C7 =>       8,   #  Ⓡ  gc=So   sc=Common     CIRCLED LATIN CAPITAL LETTER R
    0x000155 =>       3,   #  ŕ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH ACUTE
    0x000159 =>      29,   #  ř  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH CARON
    0x001E59 =>       9,   #  ṙ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH DOT ABOVE
    0x001E58 =>       1,   #  Ṙ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER R WITH DOT ABOVE
    0x001E5B =>     159,   #  ṛ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH DOT BELOW
    0x001E5A =>       9,   #  Ṛ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER R WITH DOT BELOW
    0x001E5D =>       2,   #  ṝ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH DOT BELOW AND MACRON
    0x000279 =>       8,   #  ɹ  gc=Ll   sc=Latin      LATIN SMALL LETTER TURNED R
    0x00015B =>     114,   #  ś  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH ACUTE
    0x00015A =>      29,   #  Ś  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH ACUTE
    0x00015D =>       1,   #  ŝ  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH CIRCUMFLEX
    0x000161 =>     227,   #  š  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH CARON
    0x000160 =>      12,   #  Š  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH CARON
    0x001E67 =>       1,   #  ṧ  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH CARON AND DOT ABOVE
    0x001E61 =>      10,   #  ṡ  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH DOT ABOVE
    0x001E60 =>       1,   #  Ṡ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH DOT ABOVE
    0x00015F =>      27,   #  ş  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH CEDILLA
    0x00015E =>       3,   #  Ş  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH CEDILLA
    0x001E63 =>     110,   #  ṣ  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH DOT BELOW
    0x001E62 =>      16,   #  Ṣ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH DOT BELOW
    0x000283 =>     124,   #  ʃ  gc=Ll   sc=Latin      LATIN SMALL LETTER ESH
    0x001E6B =>       2,   #  ṫ  gc=Ll   sc=Latin      LATIN SMALL LETTER T WITH DOT ABOVE
    0x000163 =>       7,   #  ţ  gc=Ll   sc=Latin      LATIN SMALL LETTER T WITH CEDILLA
    0x001E6D =>     433,   #  ṭ  gc=Ll   sc=Latin      LATIN SMALL LETTER T WITH DOT BELOW
    0x001E6C =>       4,   #  Ṭ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER T WITH DOT BELOW
    0x0000FA =>    2007,   #  ú  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH ACUTE
    0x0000DA =>       5,   #  Ú  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH ACUTE
    0x0000F9 =>     149,   #  ù  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH GRAVE
    0x00016D =>     306,   #  ŭ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH BREVE
    0x0000FB =>    1266,   #  û  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH CIRCUMFLEX
    0x0000DB =>       6,   #  Û  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH CIRCUMFLEX
    0x0001D4 =>      11,   #  ǔ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH CARON
    0x00016F =>      21,   #  ů  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH RING ABOVE
    0x0000FC =>    7400,   #  ü  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DIAERESIS
    0x0000DC =>      28,   #  Ü  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH DIAERESIS
    0x0001D8 =>       1,   #  ǘ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DIAERESIS AND ACUTE
    0x0001D6 =>      13,   #  ǖ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DIAERESIS AND MACRON
    0x000169 =>      12,   #  ũ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH TILDE
    0x001E79 =>       1,   #  ṹ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH TILDE AND ACUTE
    0x00016B =>    7760,   #  ū  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH MACRON
    0x00016A =>       1,   #  Ū  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH MACRON
    0x000265 =>       5,   #  ɥ  gc=Ll   sc=Latin      LATIN SMALL LETTER TURNED H
    0x00028A =>      36,   #  ʊ  gc=Ll   sc=Latin      LATIN SMALL LETTER UPSILON
    0x00028C =>      20,   #  ʌ  gc=Ll   sc=Latin      LATIN SMALL LETTER TURNED V
    0x001E83 =>       2,   #  ẃ  gc=Ll   sc=Latin      LATIN SMALL LETTER W WITH ACUTE
    0x001E81 =>       1,   #  ẁ  gc=Ll   sc=Latin      LATIN SMALL LETTER W WITH GRAVE
    0x000175 =>       4,   #  ŵ  gc=Ll   sc=Latin      LATIN SMALL LETTER W WITH CIRCUMFLEX
    0x001E89 =>       1,   #  ẉ  gc=Ll   sc=Latin      LATIN SMALL LETTER W WITH DOT BELOW
    0x001D54F =>       4,   #  𝕏  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL X
    0x001E8B =>       7,   #  ẋ  gc=Ll   sc=Latin      LATIN SMALL LETTER X WITH DOT ABOVE
    0x001E8A =>       2,   #  Ẋ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER X WITH DOT ABOVE
    0x001D550 =>       2,   #  𝕐  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL Y
    0x0000FD =>     843,   #  ý  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH ACUTE
    0x000177 =>      43,   #  ŷ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH CIRCUMFLEX
    0x0000FF =>      15,   #  ÿ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH DIAERESIS
    0x001EF9 =>       3,   #  ỹ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH TILDE
    0x001E8F =>      12,   #  ẏ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH DOT ABOVE
    0x001E8E =>       1,   #  Ẏ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Y WITH DOT ABOVE
    0x000233 =>     359,   #  ȳ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH MACRON
    0x00028F =>       2,   #  ʏ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL Y
    0x00017A =>       9,   #  ź  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH ACUTE
    0x00017E =>      37,   #  ž  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH CARON
    0x00017D =>       1,   #  Ž  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Z WITH CARON
    0x00017C =>      10,   #  ż  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH DOT ABOVE
    0x001E93 =>      13,   #  ẓ  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH DOT BELOW
    0x000225 =>     455,   #  ȥ  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH HOOK
    0x000292 =>   25134,   #  ʒ  gc=Ll   sc=Latin      LATIN SMALL LETTER EZH
    0x0001EF =>       1,   #  ǯ  gc=Ll   sc=Latin      LATIN SMALL LETTER EZH WITH CARON
    0x00021D =>   44741,   #  ȝ  gc=Ll   sc=Latin      LATIN SMALL LETTER YOGH
    0x00021C =>    3566,   #  Ȝ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER YOGH
    0x0000FE =>  174256,   #  þ  gc=Ll   sc=Latin      LATIN SMALL LETTER THORN
    0x0000DE =>   35163,   #  Þ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER THORN
    0x00A764 =>      88,   #  Ꝥ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER THORN WITH STROKE
    0x0001BF =>       6,   #  ƿ  gc=Ll   sc=Latin      LATIN LETTER WYNN
    0x0001F7 =>      11,   #  Ƿ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER WYNN
    0x0002BF =>     220,   #  ʿ  gc=Lm   sc=Common     MODIFIER LETTER LEFT HALF RING
    0x0003B1 =>   20478,   #  α  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA
    0x000391 =>      99,   #  Α  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ALPHA
    0x001F01 =>    2960,   #  ἁ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH DASIA
    0x001F09 =>     110,   #  Ἁ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ALPHA WITH DASIA
    0x001F05 =>     986,   #  ἅ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH DASIA AND OXIA
    0x001F0D =>      21,   #  Ἅ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ALPHA WITH DASIA AND OXIA
    0x001F85 =>       6,   #  ᾅ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH DASIA AND OXIA AND YPOGEGRAMMENI
    0x001F03 =>       6,   #  ἃ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH DASIA AND VARIA
    0x001F81 =>       2,   #  ᾁ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH DASIA AND YPOGEGRAMMENI
    0x0003AC =>    4668,   #  ά  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH TONOS
    0x000386 =>      13,   #  Ά  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ALPHA WITH TONOS
    0x001FB4 =>       3,   #  ᾴ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH OXIA AND YPOGEGRAMMENI
    0x001F70 =>     187,   #  ὰ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH VARIA
    0x001FB0 =>     251,   #  ᾰ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH VRACHY
    0x001FB1 =>     281,   #  ᾱ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH MACRON
    0x001FB3 =>      15,   #  ᾳ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH YPOGEGRAMMENI
    0x0003B2 =>   10489,   #  β  gc=Ll   sc=Greek      GREEK SMALL LETTER BETA
    0x000392 =>     213,   #  Β  gc=Lu   sc=Greek      GREEK CAPITAL LETTER BETA
    0x0003B3 =>    6960,   #  γ  gc=Ll   sc=Greek      GREEK SMALL LETTER GAMMA
    0x000393 =>      56,   #  Γ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER GAMMA
    0x0003B4 =>    6429,   #  δ  gc=Ll   sc=Greek      GREEK SMALL LETTER DELTA
    0x000394 =>     273,   #  Δ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER DELTA
    0x0003B5 =>   11186,   #  ε  gc=Ll   sc=Greek      GREEK SMALL LETTER EPSILON
    0x000395 =>      94,   #  Ε  gc=Lu   sc=Greek      GREEK CAPITAL LETTER EPSILON
    0x001F11 =>    1794,   #  ἑ  gc=Ll   sc=Greek      GREEK SMALL LETTER EPSILON WITH DASIA
    0x001F19 =>      72,   #  Ἑ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER EPSILON WITH DASIA
    0x001F15 =>     664,   #  ἕ  gc=Ll   sc=Greek      GREEK SMALL LETTER EPSILON WITH DASIA AND OXIA
    0x001F1D =>      14,   #  Ἕ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER EPSILON WITH DASIA AND OXIA
    0x001F13 =>       4,   #  ἓ  gc=Ll   sc=Greek      GREEK SMALL LETTER EPSILON WITH DASIA AND VARIA
    0x0003AD =>    3216,   #  έ  gc=Ll   sc=Greek      GREEK SMALL LETTER EPSILON WITH TONOS
    0x001F72 =>      39,   #  ὲ  gc=Ll   sc=Greek      GREEK SMALL LETTER EPSILON WITH VARIA
    0x0003DD =>      35,   #  ϝ  gc=Ll   sc=Greek      GREEK SMALL LETTER DIGAMMA
    0x0003DC =>       6,   #  Ϝ  gc=Lu   sc=Greek      GREEK LETTER DIGAMMA
    0x0003DB =>       8,   #  ϛ  gc=Ll   sc=Greek      GREEK SMALL LETTER STIGMA
    0x0003DA =>       1,   #  Ϛ  gc=Lu   sc=Greek      GREEK LETTER STIGMA
    0x0003B6 =>    1179,   #  ζ  gc=Ll   sc=Greek      GREEK SMALL LETTER ZETA
    0x000396 =>      21,   #  Ζ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ZETA
    0x0003B7 =>    5019,   #  η  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA
    0x000397 =>      27,   #  Η  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ETA
    0x001F21 =>     362,   #  ἡ  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA WITH DASIA
    0x001F29 =>      19,   #  Ἡ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ETA WITH DASIA
    0x001F25 =>      72,   #  ἥ  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA WITH DASIA AND OXIA
    0x001F2D =>       3,   #  Ἥ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ETA WITH DASIA AND OXIA
    0x001F23 =>      11,   #  ἣ  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA WITH DASIA AND VARIA
    0x001F91 =>       1,   #  ᾑ  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA WITH DASIA AND YPOGEGRAMMENI
    0x0003AE =>    3214,   #  ή  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA WITH TONOS
    0x001FC4 =>       1,   #  ῄ  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA WITH OXIA AND YPOGEGRAMMENI
    0x001F74 =>     223,   #  ὴ  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA WITH VARIA
    0x001FC3 =>      18,   #  ῃ  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA WITH YPOGEGRAMMENI
    0x0003B8 =>    3968,   #  θ  gc=Ll   sc=Greek      GREEK SMALL LETTER THETA
    0x000398 =>      78,   #  Θ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER THETA
    0x0003B9 =>   14514,   #  ι  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA
    0x000399 =>      51,   #  Ι  gc=Lu   sc=Greek      GREEK CAPITAL LETTER IOTA
    0x001F31 =>    1162,   #  ἱ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH DASIA
    0x001F39 =>      58,   #  Ἱ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER IOTA WITH DASIA
    0x001F35 =>     253,   #  ἵ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH DASIA AND OXIA
    0x001F3D =>       7,   #  Ἵ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER IOTA WITH DASIA AND OXIA
    0x001F33 =>       1,   #  ἳ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH DASIA AND VARIA
    0x0003AF =>    6345,   #  ί  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH TONOS
    0x001F76 =>     123,   #  ὶ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH VARIA
    0x001FD0 =>    1053,   #  ῐ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH VRACHY
    0x0003CA =>      55,   #  ϊ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH DIALYTIKA
    0x000390 =>      42,   #  ΐ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS
    0x001FD2 =>       2,   #  ῒ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH DIALYTIKA AND VARIA
    0x001FD1 =>     456,   #  ῑ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH MACRON
    0x0003BA =>   10021,   #  κ  gc=Ll   sc=Greek      GREEK SMALL LETTER KAPPA
    0x00039A =>     343,   #  Κ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER KAPPA
    0x0003BB =>   10745,   #  λ  gc=Ll   sc=Greek      GREEK SMALL LETTER LAMDA
    0x00039B =>     124,   #  Λ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER LAMDA
    0x0003BC =>   10774,   #  μ  gc=Ll   sc=Greek      GREEK SMALL LETTER MU
    0x00039C =>     129,   #  Μ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER MU
    0x0003BD =>   17863,   #  ν  gc=Ll   sc=Greek      GREEK SMALL LETTER NU
    0x00039D =>      72,   #  Ν  gc=Lu   sc=Greek      GREEK CAPITAL LETTER NU
    0x0003BE =>    1433,   #  ξ  gc=Ll   sc=Greek      GREEK SMALL LETTER XI
    0x00039E =>      15,   #  Ξ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER XI
    0x0003BF =>   22190,   #  ο  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON
    0x00039F =>      77,   #  Ο  gc=Lu   sc=Greek      GREEK CAPITAL LETTER OMICRON
    0x001F41 =>    1187,   #  ὁ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON WITH DASIA
    0x001F49 =>      28,   #  Ὁ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER OMICRON WITH DASIA
    0x001F45 =>     491,   #  ὅ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON WITH DASIA AND OXIA
    0x001F4D =>       6,   #  Ὅ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER OMICRON WITH DASIA AND OXIA
    0x001F43 =>       4,   #  ὃ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON WITH DASIA AND VARIA
    0x0003CC =>    8044,   #  ό  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON WITH TONOS
    0x001F78 =>     241,   #  ὸ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON WITH VARIA
    0x0003C0 =>    9528,   #  π  gc=Ll   sc=Greek      GREEK SMALL LETTER PI
    0x0003A0 =>     217,   #  Π  gc=Lu   sc=Greek      GREEK CAPITAL LETTER PI
    0x0003D8 =>     125,   #  Ϙ  gc=Lu   sc=Greek      GREEK LETTER ARCHAIC KOPPA
    0x0003C1 =>   15430,   #  ρ  gc=Ll   sc=Greek      GREEK SMALL LETTER RHO
    0x0003A1 =>      27,   #  Ρ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER RHO
    0x001FE5 =>     476,   #  ῥ  gc=Ll   sc=Greek      GREEK SMALL LETTER RHO WITH DASIA
    0x001FEC =>       6,   #  Ῥ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER RHO WITH DASIA
    0x0003C3 =>   10221,   #  σ  gc=Ll   sc=Greek      GREEK SMALL LETTER SIGMA
    0x0003A3 =>     313,   #  Σ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER SIGMA
    0x001D6BA =>      13,   #  𝚺  gc=Lu   sc=Common     MATHEMATICAL BOLD CAPITAL SIGMA
    0x0003C2 =>   18113,   #  ς  gc=Ll   sc=Greek      GREEK SMALL LETTER FINAL SIGMA
    0x0003C4 =>   14119,   #  τ  gc=Ll   sc=Greek      GREEK SMALL LETTER TAU
    0x0003A4 =>      89,   #  Τ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER TAU
    0x0003C5 =>    4269,   #  υ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON
    0x0003A5 =>      31,   #  Υ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER UPSILON
    0x001F51 =>    1287,   #  ὑ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH DASIA
    0x001F59 =>      14,   #  Ὑ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER UPSILON WITH DASIA
    0x001F55 =>     277,   #  ὕ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH DASIA AND OXIA
    0x001F5D =>       5,   #  Ὕ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER UPSILON WITH DASIA AND OXIA
    0x0003CD =>    2857,   #  ύ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH TONOS
    0x001F7A =>      32,   #  ὺ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH VARIA
    0x001FE0 =>     771,   #  ῠ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH VRACHY
    0x0003CB =>       4,   #  ϋ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH DIALYTIKA
    0x0003B0 =>       1,   #  ΰ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND TONOS
    0x001FE1 =>     365,   #  ῡ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH MACRON
    0x0003C6 =>    4597,   #  φ  gc=Ll   sc=Greek      GREEK SMALL LETTER PHI
    0x0003A6 =>      73,   #  Φ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER PHI
    0x0003C7 =>    3506,   #  χ  gc=Ll   sc=Greek      GREEK SMALL LETTER CHI
    0x0003A7 =>      90,   #  Χ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER CHI
    0x0003C8 =>     777,   #  ψ  gc=Ll   sc=Greek      GREEK SMALL LETTER PSI
    0x0003A8 =>      29,   #  Ψ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER PSI
    0x0003C9 =>    3872,   #  ω  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA
    0x0003A9 =>      72,   #  Ω  gc=Lu   sc=Greek      GREEK CAPITAL LETTER OMEGA
    0x001F61 =>     177,   #  ὡ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA WITH DASIA
    0x001F69 =>       4,   #  Ὡ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER OMEGA WITH DASIA
    0x001F65 =>      70,   #  ὥ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA WITH DASIA AND OXIA
    0x001FA1 =>      47,   #  ᾡ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA WITH DASIA AND YPOGEGRAMMENI
    0x0003CE =>     870,   #  ώ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA WITH TONOS
    0x001FF4 =>       6,   #  ῴ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA WITH OXIA AND YPOGEGRAMMENI
    0x001F7C =>      12,   #  ὼ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA WITH VARIA
    0x001FF3 =>     221,   #  ῳ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA WITH YPOGEGRAMMENI
    0x0003E1 =>       2,   #  ϡ  gc=Ll   sc=Greek      GREEK SMALL LETTER SAMPI
    0x002C84 =>       2,   #  Ⲅ  gc=Lu   sc=Coptic     COPTIC CAPITAL LETTER GAMMA
    0x002CA4 =>       7,   #  Ⲥ  gc=Lu   sc=Coptic     COPTIC CAPITAL LETTER SIMA
    0x0004A8 =>       1,   #  Ҩ  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER ABKHASIAN HA
    0x0005D7 =>       6,   #  ח  gc=Lo   sc=Hebrew     HEBREW LETTER HET
    0x010907 =>       1,   #  𐤇  gc=Lo   sc=Phoenician PHOENICIAN LETTER HET
    0x01090B =>       1,   #  𐤋  gc=Lo   sc=Phoenician PHOENICIAN LETTER LAMD
    0x010913 =>       1,   #  𐤓  gc=Lo   sc=Phoenician PHOENICIAN LETTER ROSH
    0x00FEE9 =>       1,   #  ﻩ  gc=Lo   sc=Arabic     ARABIC LETTER HEH ISOLATED FORM
    0x0016B9 =>       1,   #  ᚹ  gc=Lo   sc=Runic      RUNIC LETTER WUNJO WYNN W
    0x00209F =>      32,   # <unnamed codepoint>
);

my %elsevier_training = (
    0x00202A =>      21,   # <-> gc=Cf   sc=Common     LEFT-TO-RIGHT EMBEDDING
    0x002061 =>     154,   # <-> gc=Cf   sc=Common     FUNCTION APPLICATION
    0x00202B =>       1,   # <-> gc=Cf   sc=Common     RIGHT-TO-LEFT EMBEDDING
    0x002062 =>     143,   # <-> gc=Cf   sc=Common     INVISIBLE TIMES
    0x000092 =>      16,   # <-> gc=Cc   sc=Common     <control>
    0x000341 =>       6,   # ◌ ́  gc=Mn   sc=Inherited  COMBINING ACUTE TONE MARK
    0x000301 =>   57910,   # ◌ ́  gc=Mn   sc=Inherited  COMBINING ACUTE ACCENT
    0x000340 =>       4,   # ◌ ̀  gc=Mn   sc=Inherited  COMBINING GRAVE TONE MARK
    0x000300 =>    1230,   # ◌ ̀  gc=Mn   sc=Inherited  COMBINING GRAVE ACCENT
    0x000306 =>    1526,   # ◌ ̆  gc=Mn   sc=Inherited  COMBINING BREVE
    0x000302 =>    7848,   # ◌ ̂  gc=Mn   sc=Inherited  COMBINING CIRCUMFLEX ACCENT
    0x00030C =>    1919,   # ◌ ̌  gc=Mn   sc=Inherited  COMBINING CARON
    0x00030A =>     724,   # ◌ ̊  gc=Mn   sc=Inherited  COMBINING RING ABOVE
    0x000342 =>       4,   # ◌ ͂  gc=Mn   sc=Inherited  COMBINING GREEK PERISPOMENI
    0x000308 =>   13366,   # ◌ ̈  gc=Mn   sc=Inherited  COMBINING DIAERESIS
    0x00030B =>     516,   # ◌ ̋  gc=Mn   sc=Inherited  COMBINING DOUBLE ACUTE ACCENT
    0x000303 =>    2475,   # ◌ ̃  gc=Mn   sc=Inherited  COMBINING TILDE
    0x000307 =>   16962,   # ◌ ̇  gc=Mn   sc=Inherited  COMBINING DOT ABOVE
    0x000338 =>      33,   # ◌ ̸  gc=Mn   sc=Inherited  COMBINING LONG SOLIDUS OVERLAY
    0x000327 =>    1947,   # ◌ ̧  gc=Mn   sc=Inherited  COMBINING CEDILLA
    0x000328 =>     498,   # ◌ ̨  gc=Mn   sc=Inherited  COMBINING OGONEK
    0x000304 =>   10335,   # ◌ ̄  gc=Mn   sc=Inherited  COMBINING MACRON
    0x00032C =>       9,   # ◌ ̬  gc=Mn   sc=Inherited  COMBINING CARON BELOW
    0x00033A =>       6,   # ◌ ̺  gc=Mn   sc=Inherited  COMBINING INVERTED BRIDGE BELOW
    0x00033B =>      18,   # ◌ ̻  gc=Mn   sc=Inherited  COMBINING SQUARE BELOW
    0x00033C =>       1,   # ◌ ̼  gc=Mn   sc=Inherited  COMBINING SEAGULL BELOW
    0x000336 =>     178,   # ◌ ̶  gc=Mn   sc=Inherited  COMBINING LONG STROKE OVERLAY
    0x000337 =>      39,   # ◌ ̷  gc=Mn   sc=Inherited  COMBINING SHORT SOLIDUS OVERLAY
    0x0020DD =>      13,   # ◌ ⃝  gc=Me   sc=Inherited  COMBINING ENCLOSING CIRCLE
    0x0020DF =>       6,   # ◌ ⃟  gc=Me   sc=Inherited  COMBINING ENCLOSING DIAMOND
    0x000321 =>       4,   # ◌ ̡  gc=Mn   sc=Inherited  COMBINING PALATALIZED HOOK BELOW
    0x000322 =>      27,   # ◌ ̢  gc=Mn   sc=Inherited  COMBINING RETROFLEX HOOK BELOW
    0x000323 =>      15,   # ◌ ̣  gc=Mn   sc=Inherited  COMBINING DOT BELOW
    0x000326 =>     109,   # ◌ ̦  gc=Mn   sc=Inherited  COMBINING COMMA BELOW
    0x000331 =>    1593,   # ◌ ̱  gc=Mn   sc=Inherited  COMBINING MACRON BELOW
    0x000335 =>     139,   # ◌ ̵  gc=Mn   sc=Inherited  COMBINING SHORT STROKE OVERLAY
    0x0005B9 =>       1,   # ◌ ֹ  gc=Mn   sc=Hebrew     HEBREW POINT HOLAM
    0x0005BC =>       1,   # ◌ ּ  gc=Mn   sc=Hebrew     HEBREW POINT DAGESH OR MAPIQ
    0x000650 =>       1,   # ◌ ِ  gc=Mn   sc=Inherited  ARABIC KASRA
    0x0020D0 =>       3,   # ◌ ⃐  gc=Mn   sc=Inherited  COMBINING LEFT HARPOON ABOVE
    0x0020D1 =>       2,   # ◌ ⃑  gc=Mn   sc=Inherited  COMBINING RIGHT HARPOON ABOVE
    0x0020D7 =>     239,   # ◌ ⃗  gc=Mn   sc=Inherited  COMBINING RIGHT ARROW ABOVE
    0x0020DB =>       7,   # ◌ ⃛  gc=Mn   sc=Inherited  COMBINING THREE DOTS ABOVE
    0x003000 =>       1,   # <-> gc=Zs   sc=Common     IDEOGRAPHIC SPACE
    0x002002 =>       9,   # <-> gc=Zs   sc=Common     EN SPACE
    0x002003 =>      67,   # <-> gc=Zs   sc=Common     EM SPACE
    0x002005 =>      12,   # <-> gc=Zs   sc=Common     FOUR-PER-EM SPACE
    0x002008 =>  162990,   # <-> gc=Zs   sc=Common     PUNCTUATION SPACE
    0x002009 =>    7191,   # <-> gc=Zs   sc=Common     THIN SPACE
    0x00200A =>       2,   # <-> gc=Zs   sc=Common     HAIR SPACE
    0x0000A0 =>  249770,   # <-> gc=Zs   sc=Common     NO-BREAK SPACE
    0x0000B4 =>    1587,   #  ´  gc=Sk   sc=Common     ACUTE ACCENT
    0x000384 =>      82,   #  ΄  gc=Sk   sc=Greek      GREEK TONOS
    0x0002DC =>     316,   #  ˜  gc=Sk   sc=Common     SMALL TILDE
    0x0000AF =>     148,   #  ¯  gc=Sk   sc=Common     MACRON
    0x0002D8 =>       8,   #  ˘  gc=Sk   sc=Common     BREVE
    0x0002D9 =>      53,   #  ˙  gc=Sk   sc=Common     DOT ABOVE
    0x0000A8 =>    1445,   #  ¨  gc=Sk   sc=Common     DIAERESIS
    0x000385 =>       4,   #  ΅  gc=Sk   sc=Common     GREEK DIALYTIKA TONOS
    0x0002DA =>      69,   #  ˚  gc=Sk   sc=Common     RING ABOVE
    0x0002DD =>     239,   #  ˝  gc=Sk   sc=Common     DOUBLE ACUTE ACCENT
    0x0000B8 =>      42,   #  ¸  gc=Sk   sc=Common     CEDILLA
    0x0002DB =>       2,   #  ˛  gc=Sk   sc=Common     OGONEK
    0x002010 =>       8,   #  ‐  gc=Pd   sc=Common     HYPHEN
    0x002011 =>      12,   #  ‑  gc=Pd   sc=Common     NON-BREAKING HYPHEN
    0x002012 =>       5,   #  ‒  gc=Pd   sc=Common     FIGURE DASH
    0x002013 => 5188247,   #  –  gc=Pd   sc=Common     EN DASH
    0x002014 =>  702706,   #  —  gc=Pd   sc=Common     EM DASH
    0x002015 =>       1,   #  ―  gc=Pd   sc=Common     HORIZONTAL BAR
    0x0000A1 =>     742,   #  ¡  gc=Po   sc=Common     INVERTED EXCLAMATION MARK
    0x0000BF =>      92,   #  ¿  gc=Po   sc=Common     INVERTED QUESTION MARK
    0x002024 =>      41,   #  ․  gc=Po   sc=Common     ONE DOT LEADER
    0x002025 =>       2,   #  ‥  gc=Po   sc=Common     TWO DOT LEADER
    0x002026 =>   58545,   #  …  gc=Po   sc=Common     HORIZONTAL ELLIPSIS
    0x0000B7 =>  101123,   #  ·  gc=Po   sc=Common     MIDDLE DOT
    0x000387 =>       2,   #  ·  gc=Po   sc=Common     GREEK ANO TELEIA
    0x002018 =>  312098,   #  ‘  gc=Pi   sc=Common     LEFT SINGLE QUOTATION MARK
    0x002019 => 1345093,   #  ’  gc=Pf   sc=Common     RIGHT SINGLE QUOTATION MARK
    0x002039 =>       7,   #  ‹  gc=Pi   sc=Common     SINGLE LEFT-POINTING ANGLE QUOTATION MARK
    0x00203A =>       5,   #  ›  gc=Pf   sc=Common     SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
    0x00201C =>  807297,   #  “  gc=Pi   sc=Common     LEFT DOUBLE QUOTATION MARK
    0x00201D =>  810658,   #  ”  gc=Pf   sc=Common     RIGHT DOUBLE QUOTATION MARK
    0x00201E =>       3,   #  „  gc=Ps   sc=Common     DOUBLE LOW-9 QUOTATION MARK
    0x00201F =>       4,   #  ‟  gc=Pi   sc=Common     DOUBLE HIGH-REVERSED-9 QUOTATION MARK
    0x0000AB =>    1198,   #  «  gc=Pi   sc=Common     LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
    0x0000BB =>    3705,   #  »  gc=Pf   sc=Common     RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
    0x0024A0 =>       1,   #  ⒠  gc=So   sc=Common     PARENTHESIZED LATIN SMALL LETTER E
    0x0024B4 =>       1,   #  ⒴  gc=So   sc=Common     PARENTHESIZED LATIN SMALL LETTER Y
    0x00FE38 =>       2,   #  ︸ gc=Pe   sc=Common     PRESENTATION FORM FOR VERTICAL RIGHT CURLY BRACKET
    0x002985 =>       2,   #  ⦅  gc=Ps   sc=Common     LEFT WHITE PARENTHESIS
    0x002986 =>       2,   #  ⦆  gc=Pe   sc=Common     RIGHT WHITE PARENTHESIS
    0x002329 =>    3419,   #  〈 gc=Ps   sc=Common     LEFT-POINTING ANGLE BRACKET
    0x00232A =>    3428,   #  〉 gc=Pe   sc=Common     RIGHT-POINTING ANGLE BRACKET
    0x00300A =>      19,   #  《 gc=Ps   sc=Common     LEFT DOUBLE ANGLE BRACKET
    0x00300B =>      24,   #  》 gc=Pe   sc=Common     RIGHT DOUBLE ANGLE BRACKET
    0x00301A =>   22451,   #  〚 gc=Ps   sc=Common     LEFT WHITE SQUARE BRACKET
    0x00301B =>   22452,   #  〛 gc=Pe   sc=Common     RIGHT WHITE SQUARE BRACKET
    0x0000A7 =>   77766,   #  §  gc=So   sc=Common     SECTION SIGN
    0x0000B6 =>   22670,   #  ¶  gc=So   sc=Common     PILCROW SIGN
    0x00204B =>       1,   #  ⁋  gc=Po   sc=Common     REVERSED PILCROW SIGN
    0x0000A9 =>    6174,   #  ©  gc=So   sc=Common     COPYRIGHT SIGN
    0x0000AE =>   77437,   #  ®  gc=So   sc=Common     REGISTERED SIGN
    0x00204E =>  674216,   #  ⁎  gc=Po   sc=Common     LOW ASTERISK
    0x00FF05 =>       6,   #  ％ gc=Po   sc=Common     FULLWIDTH PERCENT SIGN
    0x002030 =>    1155,   #  ‰  gc=Po   sc=Common     PER MILLE SIGN
    0x002031 =>       8,   #  ‱  gc=Po   sc=Common     PER TEN THOUSAND SIGN
    0x002020 =>  294651,   #  †  gc=Po   sc=Common     DAGGER
    0x002021 =>  150474,   #  ‡  gc=Po   sc=Common     DOUBLE DAGGER
    0x002022 =>  310614,   #  •  gc=Po   sc=Common     BULLET
    0x002032 =>  583389,   #  ′  gc=Po   sc=Common     PRIME
    0x002033 =>   12193,   #  ″  gc=Po   sc=Common     DOUBLE PRIME
    0x002034 =>     240,   #  ‴  gc=Po   sc=Common     TRIPLE PRIME
    0x002057 =>      20,   #  ⁗  gc=Po   sc=Common     QUADRUPLE PRIME
    0x002035 =>      94,   #  ‵  gc=Po   sc=Common     REVERSED PRIME
    0x002036 =>       2,   #  ‶  gc=Po   sc=Common     REVERSED DOUBLE PRIME
    0x002041 =>       1,   #  ⁁  gc=Po   sc=Common     CARET INSERTION POINT
    0x0002BA =>     128,   #  ʺ  gc=Lm   sc=Common     MODIFIER LETTER DOUBLE PRIME
    0x0002C4 =>      10,   #  ˄  gc=Sk   sc=Common     MODIFIER LETTER UP ARROWHEAD
    0x0002C6 =>     227,   #  ˆ  gc=Lm   sc=Common     MODIFIER LETTER CIRCUMFLEX ACCENT
    0x0002C7 =>     138,   #  ˇ  gc=Lm   sc=Common     CARON
    0x0002C8 =>     276,   #  ˈ  gc=Lm   sc=Common     MODIFIER LETTER VERTICAL LINE
    0x0002C9 =>       1,   #  ˉ  gc=Lm   sc=Common     MODIFIER LETTER MACRON
    0x0002D4 =>       1,   #  ˔  gc=Sk   sc=Common     MODIFIER LETTER UP TACK
    0x0002E6 =>     211,   #  ˦  gc=Sk   sc=Common     MODIFIER LETTER HIGH TONE BAR
    0x0000B0 =>  803529,   #  °  gc=So   sc=Common     DEGREE SIGN
    0x002103 =>       2,   #  ℃  gc=So   sc=Common     DEGREE CELSIUS
    0x002109 =>     243,   #  ℉  gc=So   sc=Common     DEGREE FAHRENHEIT
    0x002118 =>       3,   #  ℘  gc=Sm   sc=Common     SCRIPT CAPITAL P
    0x00211E =>      34,   #  ℞  gc=So   sc=Common     PRESCRIPTION TAKE
    0x002127 =>       9,   #  ℧  gc=So   sc=Common     INVERTED OHM SIGN
    0x002129 =>       8,   #  ℩  gc=So   sc=Common     TURNED GREEK SMALL LETTER IOTA
    0x002190 =>     916,   #  ←  gc=Sm   sc=Common     LEFTWARDS ARROW
    0x002192 =>   62151,   #  →  gc=Sm   sc=Common     RIGHTWARDS ARROW
    0x00219B =>       3,   #  ↛  gc=Sm   sc=Common     RIGHTWARDS ARROW WITH STROKE
    0x002191 =>   23155,   #  ↑  gc=Sm   sc=Common     UPWARDS ARROW
    0x002193 =>   23655,   #  ↓  gc=Sm   sc=Common     DOWNWARDS ARROW
    0x002194 =>    3234,   #  ↔  gc=Sm   sc=Common     LEFT RIGHT ARROW
    0x002195 =>      81,   #  ↕  gc=So   sc=Common     UP DOWN ARROW
    0x002196 =>      77,   #  ↖  gc=So   sc=Common     NORTH WEST ARROW
    0x002197 =>     400,   #  ↗  gc=So   sc=Common     NORTH EAST ARROW
    0x002198 =>     419,   #  ↘  gc=So   sc=Common     SOUTH EAST ARROW
    0x002199 =>      23,   #  ↙  gc=So   sc=Common     SOUTH WEST ARROW
    0x00219E =>       1,   #  ↞  gc=So   sc=Common     LEFTWARDS TWO HEADED ARROW
    0x0021A0 =>       5,   #  ↠  gc=Sm   sc=Common     RIGHTWARDS TWO HEADED ARROW
    0x0021A6 =>      12,   #  ↦  gc=Sm   sc=Common     RIGHTWARDS ARROW FROM BAR
    0x0021AB =>       1,   #  ↫  gc=So   sc=Common     LEFTWARDS ARROW WITH LOOP
    0x0021AD =>       3,   #  ↭  gc=So   sc=Common     LEFT RIGHT WAVE ARROW
    0x0021B0 =>       1,   #  ↰  gc=So   sc=Common     UPWARDS ARROW WITH TIP LEFTWARDS
    0x0021B1 =>       4,   #  ↱  gc=So   sc=Common     UPWARDS ARROW WITH TIP RIGHTWARDS
    0x0021B3 =>       1,   #  ↳  gc=So   sc=Common     DOWNWARDS ARROW WITH TIP RIGHTWARDS
    0x0021BC =>       1,   #  ↼  gc=So   sc=Common     LEFTWARDS HARPOON WITH BARB UPWARDS
    0x0021BD =>       5,   #  ↽  gc=So   sc=Common     LEFTWARDS HARPOON WITH BARB DOWNWARDS
    0x0021BE =>       3,   #  ↾  gc=So   sc=Common     UPWARDS HARPOON WITH BARB RIGHTWARDS
    0x0021C0 =>     216,   #  ⇀  gc=So   sc=Common     RIGHTWARDS HARPOON WITH BARB UPWARDS
    0x0021C1 =>       1,   #  ⇁  gc=So   sc=Common     RIGHTWARDS HARPOON WITH BARB DOWNWARDS
    0x0021C2 =>       1,   #  ⇂  gc=So   sc=Common     DOWNWARDS HARPOON WITH BARB RIGHTWARDS
    0x0021C3 =>       1,   #  ⇃  gc=So   sc=Common     DOWNWARDS HARPOON WITH BARB LEFTWARDS
    0x0021C4 =>     402,   #  ⇄  gc=So   sc=Common     RIGHTWARDS ARROW OVER LEFTWARDS ARROW
    0x0021C5 =>       7,   #  ⇅  gc=So   sc=Common     UPWARDS ARROW LEFTWARDS OF DOWNWARDS ARROW
    0x0021C6 =>      78,   #  ⇆  gc=So   sc=Common     LEFTWARDS ARROW OVER RIGHTWARDS ARROW
    0x0021C8 =>      72,   #  ⇈  gc=So   sc=Common     UPWARDS PAIRED ARROWS
    0x0021C9 =>       8,   #  ⇉  gc=So   sc=Common     RIGHTWARDS PAIRED ARROWS
    0x0021CA =>      72,   #  ⇊  gc=So   sc=Common     DOWNWARDS PAIRED ARROWS
    0x0021CB =>      44,   #  ⇋  gc=So   sc=Common     LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON
    0x0021CC =>     445,   #  ⇌  gc=So   sc=Common     RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
    0x0021D0 =>      86,   #  ⇐  gc=So   sc=Common     LEFTWARDS DOUBLE ARROW
    0x0021D1 =>     918,   #  ⇑  gc=So   sc=Common     UPWARDS DOUBLE ARROW
    0x0021D2 =>    1367,   #  ⇒  gc=Sm   sc=Common     RIGHTWARDS DOUBLE ARROW
    0x0021D3 =>     841,   #  ⇓  gc=So   sc=Common     DOWNWARDS DOUBLE ARROW
    0x0021D4 =>     689,   #  ⇔  gc=Sm   sc=Common     LEFT RIGHT DOUBLE ARROW
    0x0021D5 =>       2,   #  ⇕  gc=So   sc=Common     UP DOWN DOUBLE ARROW
    0x0021DB =>       4,   #  ⇛  gc=So   sc=Common     RIGHTWARDS TRIPLE ARROW
    0x0021DD =>       1,   #  ⇝  gc=So   sc=Common     RIGHTWARDS SQUIGGLE ARROW
    0x0021F5 =>       6,   #  ⇵  gc=Sm   sc=Common     DOWNWARDS ARROW LEFTWARDS OF UPWARDS ARROW
    0x002200 =>     185,   #  ∀  gc=Sm   sc=Common     FOR ALL
    0x002201 =>       1,   #  ∁  gc=Sm   sc=Common     COMPLEMENT
    0x002202 =>    5852,   #  ∂  gc=Sm   sc=Common     PARTIAL DIFFERENTIAL
    0x002203 =>      39,   #  ∃  gc=Sm   sc=Common     THERE EXISTS
    0x002205 =>    1583,   #  ∅  gc=Sm   sc=Common     EMPTY SET
    0x002206 =>      12,   #  ∆  gc=Sm   sc=Common     INCREMENT
    0x002207 =>     916,   #  ∇  gc=Sm   sc=Common     NABLA
    0x002208 =>    1059,   #  ∈  gc=Sm   sc=Common     ELEMENT OF
    0x002209 =>      31,   #  ∉  gc=Sm   sc=Common     NOT AN ELEMENT OF
    0x00220A =>       3,   #  ∊  gc=Sm   sc=Common     SMALL ELEMENT OF
    0x00220B =>      18,   #  ∋  gc=Sm   sc=Common     CONTAINS AS MEMBER
    0x00220C =>       1,   #  ∌  gc=Sm   sc=Common     DOES NOT CONTAIN AS MEMBER
    0x00220D =>       4,   #  ∍  gc=Sm   sc=Common     SMALL CONTAINS AS MEMBER
    0x00220F =>     659,   #  ∏  gc=Sm   sc=Common     N-ARY PRODUCT
    0x002210 =>      10,   #  ∐  gc=Sm   sc=Common     N-ARY COPRODUCT
    0x002211 =>   10654,   #  ∑  gc=Sm   sc=Common     N-ARY SUMMATION
    0x0000B1 => 4564745,   #  ±  gc=Sm   sc=Common     PLUS-MINUS SIGN
    0x0000F7 =>    1835,   #  ÷  gc=Sm   sc=Common     DIVISION SIGN
    0x0000D7 =>  700976,   #  ×  gc=Sm   sc=Common     MULTIPLICATION SIGN
    0x00FF1C =>       1,   #  ＜ gc=Sm   sc=Common     FULLWIDTH LESS-THAN SIGN
    0x00226E =>       4,   #  ≮  gc=Sm   sc=Common     NOT LESS-THAN
    0x00FF1D =>      11,   #  ＝ gc=Sm   sc=Common     FULLWIDTH EQUALS SIGN
    0x002260 =>    1888,   #  ≠  gc=Sm   sc=Common     NOT EQUAL TO
    0x00226F =>      12,   #  ≯  gc=Sm   sc=Common     NOT GREATER-THAN
    0x0000AC =>      36,   #  ¬  gc=Sm   sc=Common     NOT SIGN
    0x0000A6 =>     150,   #  ¦  gc=So   sc=Common     BROKEN BAR
    0x002016 =>    3435,   #  ‖  gc=Po   sc=Common     DOUBLE VERTICAL LINE
    0x002212 => 1989514,   #  −  gc=Sm   sc=Common     MINUS SIGN
    0x002213 =>     158,   #  ∓  gc=Sm   sc=Common     MINUS-OR-PLUS SIGN
    0x002214 =>       3,   #  ∔  gc=Sm   sc=Common     DOT PLUS
    0x002215 =>      13,   #  ∕  gc=Sm   sc=Common     DIVISION SLASH
    0x002216 =>       4,   #  ∖  gc=Sm   sc=Common     SET MINUS
    0x002217 =>  579784,   #  ∗  gc=Sm   sc=Common     ASTERISK OPERATOR
    0x002218 =>    2540,   #  ∘  gc=Sm   sc=Common     RING OPERATOR
    0x002219 =>     784,   #  ∙  gc=Sm   sc=Common     BULLET OPERATOR
    0x00221A =>    3316,   #  √  gc=Sm   sc=Common     SQUARE ROOT
    0x00221D =>     909,   #  ∝  gc=Sm   sc=Common     PROPORTIONAL TO
    0x00221E =>    6138,   #  ∞  gc=Sm   sc=Common     INFINITY
    0x002220 =>     188,   #  ∠  gc=Sm   sc=Common     ANGLE
    0x002222 =>      19,   #  ∢  gc=Sm   sc=Common     SPHERICAL ANGLE
    0x002223 =>    3115,   #  ∣  gc=Sm   sc=Common     DIVIDES
    0x002225 =>   26293,   #  ∥  gc=Sm   sc=Common     PARALLEL TO
    0x002227 =>     936,   #  ∧  gc=Sm   sc=Common     LOGICAL AND
    0x002228 =>      34,   #  ∨  gc=Sm   sc=Common     LOGICAL OR
    0x002229 =>     216,   #  ∩  gc=Sm   sc=Common     INTERSECTION
    0x00222A =>     136,   #  ∪  gc=Sm   sc=Common     UNION
    0x00222B =>    4054,   #  ∫  gc=Sm   sc=Common     INTEGRAL
    0x00222C =>       1,   #  ∬  gc=Sm   sc=Common     DOUBLE INTEGRAL
    0x00222E =>      27,   #  ∮  gc=Sm   sc=Common     CONTOUR INTEGRAL
    0x00222F =>       2,   #  ∯  gc=Sm   sc=Common     SURFACE INTEGRAL
    0x002234 =>      54,   #  ∴  gc=Sm   sc=Common     THEREFORE
    0x002235 =>       2,   #  ∵  gc=Sm   sc=Common     BECAUSE
    0x002237 =>     973,   #  ∷  gc=Sm   sc=Common     PROPORTION
    0x002238 =>      30,   #  ∸  gc=Sm   sc=Common     DOT MINUS
    0x00223C =>  106319,   #  ∼  gc=Sm   sc=Common     TILDE OPERATOR
    0x00223D =>     154,   #  ∽  gc=Sm   sc=Common     REVERSED TILDE
    0x00223E =>      46,   #  ∾  gc=Sm   sc=Common     INVERTED LAZY S
    0x002242 =>       3,   #  ≂  gc=Sm   sc=Common     MINUS TILDE
    0x002243 =>     437,   #  ≃  gc=Sm   sc=Common     ASYMPTOTICALLY EQUAL TO
    0x002245 =>    1678,   #  ≅  gc=Sm   sc=Common     APPROXIMATELY EQUAL TO
    0x002248 =>   16602,   #  ≈  gc=Sm   sc=Common     ALMOST EQUAL TO
    0x002249 =>       1,   #  ≉  gc=Sm   sc=Common     NOT ALMOST EQUAL TO
    0x00224A =>      18,   #  ≊  gc=Sm   sc=Common     ALMOST EQUAL OR EQUAL TO
    0x00224B =>       1,   #  ≋  gc=Sm   sc=Common     TRIPLE TILDE
    0x00224C =>      12,   #  ≌  gc=Sm   sc=Common     ALL EQUAL TO
    0x00224D =>       1,   #  ≍  gc=Sm   sc=Common     EQUIVALENT TO
    0x00224F =>       1,   #  ≏  gc=Sm   sc=Common     DIFFERENCE BETWEEN
    0x002250 =>     318,   #  ≐  gc=Sm   sc=Common     APPROACHES THE LIMIT
    0x002251 =>       4,   #  ≑  gc=Sm   sc=Common     GEOMETRICALLY EQUAL TO
    0x002252 =>      56,   #  ≒  gc=Sm   sc=Common     APPROXIMATELY EQUAL TO OR THE IMAGE OF
    0x002253 =>       2,   #  ≓  gc=Sm   sc=Common     IMAGE OF OR APPROXIMATELY EQUAL TO
    0x002254 =>      23,   #  ≔  gc=Sm   sc=Common     COLON EQUALS
    0x002255 =>       4,   #  ≕  gc=Sm   sc=Common     EQUALS COLON
    0x002256 =>       1,   #  ≖  gc=Sm   sc=Common     RING IN EQUAL TO
    0x002259 =>       8,   #  ≙  gc=Sm   sc=Common     ESTIMATES
    0x00225C =>      41,   #  ≜  gc=Sm   sc=Common     DELTA EQUAL TO
    0x002261 =>     729,   #  ≡  gc=Sm   sc=Common     IDENTICAL TO
    0x002262 =>      34,   #  ≢  gc=Sm   sc=Common     NOT IDENTICAL TO
    0x002264 =>  143271,   #  ≤  gc=Sm   sc=Common     LESS-THAN OR EQUAL TO
    0x002270 =>       2,   #  ≰  gc=Sm   sc=Common     NEITHER LESS-THAN NOR EQUAL TO
    0x002265 =>  251048,   #  ≥  gc=Sm   sc=Common     GREATER-THAN OR EQUAL TO
    0x002271 =>      11,   #  ≱  gc=Sm   sc=Common     NEITHER GREATER-THAN NOR EQUAL TO
    0x002266 =>     723,   #  ≦  gc=Sm   sc=Common     LESS-THAN OVER EQUAL TO
    0x002267 =>    1249,   #  ≧  gc=Sm   sc=Common     GREATER-THAN OVER EQUAL TO
    0x00226A =>    1100,   #  ≪  gc=Sm   sc=Common     MUCH LESS-THAN
    0x00226B =>    1852,   #  ≫  gc=Sm   sc=Common     MUCH GREATER-THAN
    0x002272 =>      84,   #  ≲  gc=Sm   sc=Common     LESS-THAN OR EQUIVALENT TO
    0x002273 =>      48,   #  ≳  gc=Sm   sc=Common     GREATER-THAN OR EQUIVALENT TO
    0x002276 =>       5,   #  ≶  gc=Sm   sc=Common     LESS-THAN OR GREATER-THAN
    0x002277 =>      15,   #  ≷  gc=Sm   sc=Common     GREATER-THAN OR LESS-THAN
    0x002279 =>       2,   #  ≹  gc=Sm   sc=Common     NEITHER GREATER-THAN NOR LESS-THAN
    0x00227A =>       7,   #  ≺  gc=Sm   sc=Common     PRECEDES
    0x00227B =>      13,   #  ≻  gc=Sm   sc=Common     SUCCEEDS
    0x002281 =>       1,   #  ⊁  gc=Sm   sc=Common     DOES NOT SUCCEED
    0x00227D =>       1,   #  ≽  gc=Sm   sc=Common     SUCCEEDS OR EQUAL TO
    0x002282 =>      30,   #  ⊂  gc=Sm   sc=Common     SUBSET OF
    0x002284 =>       7,   #  ⊄  gc=Sm   sc=Common     NOT A SUBSET OF
    0x002283 =>       6,   #  ⊃  gc=Sm   sc=Common     SUPERSET OF
    0x002286 =>      12,   #  ⊆  gc=Sm   sc=Common     SUBSET OF OR EQUAL TO
    0x002287 =>       6,   #  ⊇  gc=Sm   sc=Common     SUPERSET OF OR EQUAL TO
    0x00228E =>      23,   #  ⊎  gc=Sm   sc=Common     MULTISET UNION
    0x002293 =>      10,   #  ⊓  gc=Sm   sc=Common     SQUARE CAP
    0x002294 =>       8,   #  ⊔  gc=Sm   sc=Common     SQUARE CUP
    0x002295 =>     361,   #  ⊕  gc=Sm   sc=Common     CIRCLED PLUS
    0x002296 =>      73,   #  ⊖  gc=Sm   sc=Common     CIRCLED MINUS
    0x002297 =>     376,   #  ⊗  gc=Sm   sc=Common     CIRCLED TIMES
    0x002298 =>      24,   #  ⊘  gc=Sm   sc=Common     CIRCLED DIVISION SLASH
    0x002299 =>      50,   #  ⊙  gc=Sm   sc=Common     CIRCLED DOT OPERATOR
    0x00229A =>     122,   #  ⊚  gc=Sm   sc=Common     CIRCLED RING OPERATOR
    0x00229B =>       7,   #  ⊛  gc=Sm   sc=Common     CIRCLED ASTERISK OPERATOR
    0x00229D =>      23,   #  ⊝  gc=Sm   sc=Common     CIRCLED DASH
    0x00229E =>      16,   #  ⊞  gc=Sm   sc=Common     SQUARED PLUS
    0x00229F =>       2,   #  ⊟  gc=Sm   sc=Common     SQUARED MINUS
    0x0022A0 =>      34,   #  ⊠  gc=Sm   sc=Common     SQUARED TIMES
    0x0022A1 =>       5,   #  ⊡  gc=Sm   sc=Common     SQUARED DOT OPERATOR
    0x0022A2 =>      24,   #  ⊢  gc=Sm   sc=Common     RIGHT TACK
    0x0022A3 =>      15,   #  ⊣  gc=Sm   sc=Common     LEFT TACK
    0x0022A4 =>      36,   #  ⊤  gc=Sm   sc=Common     DOWN TACK
    0x0022A5 =>     656,   #  ⊥  gc=Sm   sc=Common     UP TACK
    0x0022B9 =>       3,   #  ⊹  gc=Sm   sc=Common     HERMITIAN CONJUGATE MATRIX
    0x0022BB =>     229,   #  ⊻  gc=Sm   sc=Common     XOR
    0x0022BC =>      34,   #  ⊼  gc=Sm   sc=Common     NAND
    0x0022C0 =>      49,   #  ⋀  gc=Sm   sc=Common     N-ARY LOGICAL AND
    0x0022C1 =>       2,   #  ⋁  gc=Sm   sc=Common     N-ARY LOGICAL OR
    0x0022C2 =>      12,   #  ⋂  gc=Sm   sc=Common     N-ARY INTERSECTION
    0x0022C3 =>       6,   #  ⋃  gc=Sm   sc=Common     N-ARY UNION
    0x0022C4 =>       6,   #  ⋄  gc=Sm   sc=Common     DIAMOND OPERATOR
    0x0022C5 =>    6131,   #  ⋅  gc=Sm   sc=Common     DOT OPERATOR
    0x0022C6 =>      46,   #  ⋆  gc=Sm   sc=Common     STAR OPERATOR
    0x0022C7 =>      24,   #  ⋇  gc=Sm   sc=Common     DIVISION TIMES
    0x0022C8 =>       9,   #  ⋈  gc=Sm   sc=Common     BOWTIE
    0x0022CD =>      12,   #  ⋍  gc=Sm   sc=Common     REVERSED TILDE EQUALS
    0x0022CE =>       1,   #  ⋎  gc=Sm   sc=Common     CURLY LOGICAL OR
    0x0022CF =>       1,   #  ⋏  gc=Sm   sc=Common     CURLY LOGICAL AND
    0x0022D6 =>       4,   #  ⋖  gc=Sm   sc=Common     LESS-THAN WITH DOT
    0x0022D7 =>       6,   #  ⋗  gc=Sm   sc=Common     GREATER-THAN WITH DOT
    0x0022D8 =>       5,   #  ⋘  gc=Sm   sc=Common     VERY MUCH LESS-THAN
    0x0022D9 =>      74,   #  ⋙  gc=Sm   sc=Common     VERY MUCH GREATER-THAN
    0x0022DA =>       1,   #  ⋚  gc=Sm   sc=Common     LESS-THAN EQUAL TO OR GREATER-THAN
    0x0022EE =>     334,   #  ⋮  gc=Sm   sc=Common     VERTICAL ELLIPSIS
    0x0022EF =>    2676,   #  ⋯  gc=Sm   sc=Common     MIDLINE HORIZONTAL ELLIPSIS
    0x0022F1 =>      63,   #  ⋱  gc=Sm   sc=Common     DOWN RIGHT DIAGONAL ELLIPSIS
    0x002302 =>       1,   #  ⌂  gc=So   sc=Common     HOUSE
    0x002308 =>      20,   #  ⌈  gc=Sm   sc=Common     LEFT CEILING
    0x002309 =>      76,   #  ⌉  gc=Sm   sc=Common     RIGHT CEILING
    0x00230A =>      37,   #  ⌊  gc=Sm   sc=Common     LEFT FLOOR
    0x00230B =>      70,   #  ⌋  gc=Sm   sc=Common     RIGHT FLOOR
    0x002316 =>      15,   #  ⌖  gc=So   sc=Common     POSITION INDICATOR
    0x00231C =>       2,   #  ⌜  gc=So   sc=Common     TOP LEFT CORNER
    0x00231D =>      11,   #  ⌝  gc=So   sc=Common     TOP RIGHT CORNER
    0x00231F =>       5,   #  ⌟  gc=So   sc=Common     BOTTOM RIGHT CORNER
    0x002322 =>      11,   #  ⌢  gc=So   sc=Common     FROWN
    0x002323 =>      57,   #  ⌣  gc=So   sc=Common     SMILE
    0x002394 =>      20,   #  ⎔  gc=So   sc=Common     SOFTWARE-FUNCTION SYMBOL
    0x002500 =>       6,   #  ─  gc=So   sc=Common     BOX DRAWINGS LIGHT HORIZONTAL
    0x002534 =>       2,   #  ┴  gc=So   sc=Common     BOX DRAWINGS LIGHT UP AND HORIZONTAL
    0x002551 =>       1,   #  ║  gc=So   sc=Common     BOX DRAWINGS DOUBLE VERTICAL
    0x002580 =>       2,   #  ▀  gc=So   sc=Common     UPPER HALF BLOCK
    0x00258C =>       1,   #  ▌  gc=So   sc=Common     LEFT HALF BLOCK
    0x002591 =>       1,   #  ░  gc=So   sc=Common     LIGHT SHADE
    0x002592 =>       1,   #  ▒  gc=So   sc=Common     MEDIUM SHADE
    0x0025A0 =>   26845,   #  ■  gc=So   sc=Common     BLACK SQUARE
    0x0025A1 =>   28366,   #  □  gc=So   sc=Common     WHITE SQUARE
    0x0025A4 =>      85,   #  ▤  gc=So   sc=Common     SQUARE WITH HORIZONTAL FILL
    0x0025A5 =>      64,   #  ▥  gc=So   sc=Common     SQUARE WITH VERTICAL FILL
    0x0025A6 =>       1,   #  ▦  gc=So   sc=Common     SQUARE WITH ORTHOGONAL CROSSHATCH FILL
    0x0025A7 =>     188,   #  ▧  gc=So   sc=Common     SQUARE WITH UPPER LEFT TO LOWER RIGHT FILL
    0x0025A8 =>     525,   #  ▨  gc=So   sc=Common     SQUARE WITH UPPER RIGHT TO LOWER LEFT FILL
    0x0025A9 =>     728,   #  ▩  gc=So   sc=Common     SQUARE WITH DIAGONAL CROSSHATCH FILL
    0x0025AA =>     532,   #  ▪  gc=So   sc=Common     BLACK SMALL SQUARE
    0x0025AB =>     172,   #  ▫  gc=So   sc=Common     WHITE SMALL SQUARE
    0x0025AC =>       2,   #  ▬  gc=So   sc=Common     BLACK RECTANGLE
    0x0025AD =>      88,   #  ▭  gc=So   sc=Common     WHITE RECTANGLE
    0x0025AF =>       4,   #  ▯  gc=So   sc=Common     WHITE VERTICAL RECTANGLE
    0x0025B1 =>       5,   #  ▱  gc=So   sc=Common     WHITE PARALLELOGRAM
    0x0025B2 =>     208,   #  ▲  gc=So   sc=Common     BLACK UP-POINTING TRIANGLE
    0x0025B3 =>     792,   #  △  gc=So   sc=Common     WHITE UP-POINTING TRIANGLE
    0x0025B4 =>   12479,   #  ▴  gc=So   sc=Common     BLACK UP-POINTING SMALL TRIANGLE
    0x0025B5 =>    7692,   #  ▵  gc=So   sc=Common     WHITE UP-POINTING SMALL TRIANGLE
    0x0025B6 =>     643,   #  ▶  gc=So   sc=Common     BLACK RIGHT-POINTING TRIANGLE
    0x0025B7 =>      29,   #  ▷  gc=Sm   sc=Common     WHITE RIGHT-POINTING TRIANGLE
    0x0025BA =>       1,   #  ►  gc=So   sc=Common     BLACK RIGHT-POINTING POINTER
    0x0025BC =>      45,   #  ▼  gc=So   sc=Common     BLACK DOWN-POINTING TRIANGLE
    0x0025BD =>     220,   #  ▽  gc=So   sc=Common     WHITE DOWN-POINTING TRIANGLE
    0x0025BE =>    3335,   #  ▾  gc=So   sc=Common     BLACK DOWN-POINTING SMALL TRIANGLE
    0x0025BF =>    1557,   #  ▿  gc=So   sc=Common     WHITE DOWN-POINTING SMALL TRIANGLE
    0x0025C0 =>     113,   #  ◀  gc=So   sc=Common     BLACK LEFT-POINTING TRIANGLE
    0x0025C1 =>      33,   #  ◁  gc=Sm   sc=Common     WHITE LEFT-POINTING TRIANGLE
    0x0025C6 =>       9,   #  ◆  gc=So   sc=Common     BLACK DIAMOND
    0x0025C7 =>       2,   #  ◇  gc=So   sc=Common     WHITE DIAMOND
    0x0025C9 =>       1,   #  ◉  gc=So   sc=Common     FISHEYE
    0x0025CA =>     906,   #  ◊  gc=So   sc=Common     LOZENGE
    0x0025CB =>   28227,   #  ○  gc=So   sc=Common     WHITE CIRCLE
    0x0025CF =>    6925,   #  ●  gc=So   sc=Common     BLACK CIRCLE
    0x0025D0 =>      45,   #  ◐  gc=So   sc=Common     CIRCLE WITH LEFT HALF BLACK
    0x0025D1 =>      65,   #  ◑  gc=So   sc=Common     CIRCLE WITH RIGHT HALF BLACK
    0x0025D2 =>      11,   #  ◒  gc=So   sc=Common     CIRCLE WITH LOWER HALF BLACK
    0x0025D3 =>       3,   #  ◓  gc=So   sc=Common     CIRCLE WITH UPPER HALF BLACK
    0x0025D8 =>      14,   #  ◘  gc=So   sc=Common     INVERSE BULLET
    0x0025E6 =>    5443,   #  ◦  gc=So   sc=Common     WHITE BULLET
    0x0025E7 =>       5,   #  ◧  gc=So   sc=Common     SQUARE WITH LEFT HALF BLACK
    0x0025E8 =>      13,   #  ◨  gc=So   sc=Common     SQUARE WITH RIGHT HALF BLACK
    0x0025E9 =>       9,   #  ◩  gc=So   sc=Common     SQUARE WITH UPPER LEFT DIAGONAL HALF BLACK
    0x0025EA =>       9,   #  ◪  gc=So   sc=Common     SQUARE WITH LOWER RIGHT DIAGONAL HALF BLACK
    0x0025EB =>       3,   #  ◫  gc=So   sc=Common     WHITE SQUARE WITH VERTICAL BISECTING LINE
    0x0025EF =>      22,   #  ◯  gc=So   sc=Common     LARGE CIRCLE
    0x002605 =>   16916,   #  ★  gc=So   sc=Common     BLACK STAR
    0x002606 =>   91231,   #  ☆  gc=So   sc=Common     WHITE STAR
    0x00260E =>       4,   #  ☎  gc=So   sc=Common     BLACK TELEPHONE
    0x002610 =>    1600,   #  ☐  gc=So   sc=Common     BALLOT BOX
    0x002612 =>      32,   #  ☒  gc=So   sc=Common     BALLOT BOX WITH X
    0x00263C =>       1,   #  ☼  gc=So   sc=Common     WHITE SUN WITH RAYS
    0x002640 =>    1600,   #  ♀  gc=So   sc=Common     FEMALE SIGN
    0x002642 =>    1153,   #  ♂  gc=So   sc=Common     MALE SIGN
    0x002660 =>      67,   #  ♠  gc=So   sc=Common     BLACK SPADE SUIT
    0x002662 =>    3417,   #  ♢  gc=So   sc=Common     WHITE DIAMOND SUIT
    0x002663 =>     372,   #  ♣  gc=So   sc=Common     BLACK CLUB SUIT
    0x002665 =>      34,   #  ♥  gc=So   sc=Common     BLACK HEART SUIT
    0x002666 =>    6943,   #  ♦  gc=So   sc=Common     BLACK DIAMOND SUIT
    0x002713 =>    9161,   #  ✓  gc=So   sc=Common     CHECK MARK
    0x00271A =>       5,   #  ✚  gc=So   sc=Common     HEAVY GREEK CROSS
    0x002720 =>      96,   #  ✠  gc=So   sc=Common     MALTESE CROSS
    0x002726 =>       2,   #  ✦  gc=So   sc=Common     BLACK FOUR POINTED STAR
    0x002727 =>       2,   #  ✧  gc=So   sc=Common     WHITE FOUR POINTED STAR
    0x002730 =>       1,   #  ✰  gc=So   sc=Common     SHADOWED WHITE STAR
    0x002732 =>       2,   #  ✲  gc=So   sc=Common     OPEN CENTRE ASTERISK
    0x002736 =>       7,   #  ✶  gc=So   sc=Common     SIX POINTED BLACK STAR
    0x002737 =>       6,   #  ✷  gc=So   sc=Common     EIGHT POINTED RECTILINEAR BLACK STAR
    0x002739 =>       3,   #  ✹  gc=So   sc=Common     TWELVE POINTED BLACK STAR
    0x00274F =>     103,   #  ❏  gc=So   sc=Common     LOWER RIGHT DROP-SHADOWED WHITE SQUARE
    0x002751 =>      79,   #  ❑  gc=So   sc=Common     LOWER RIGHT SHADOWED WHITE SQUARE
    0x002752 =>     347,   #  ❒  gc=So   sc=Common     UPPER RIGHT SHADOWED WHITE SQUARE
    0x002756 =>      16,   #  ❖  gc=So   sc=Common     BLACK DIAMOND MINUS WHITE X
    0x002758 =>       5,   #  ❘  gc=So   sc=Common     LIGHT VERTICAL BAR
    0x002798 =>       1,   #  ➘  gc=So   sc=Common     HEAVY SOUTH EAST ARROW
    0x00279A =>       2,   #  ➚  gc=So   sc=Common     HEAVY NORTH EAST ARROW
    0x0027A2 =>     475,   #  ➢  gc=So   sc=Common     THREE-D TOP-LIGHTED RIGHTWARDS ARROWHEAD
    0x002937 =>       3,   #  ⤷  gc=Sm   sc=Common     ARROW POINTING DOWNWARDS THEN CURVING RIGHTWARDS
    0x002942 =>       4,   #  ⥂  gc=Sm   sc=Common     RIGHTWARDS ARROW ABOVE SHORT LEFTWARDS ARROW
    0x002944 =>       9,   #  ⥄  gc=Sm   sc=Common     SHORT RIGHTWARDS ARROW ABOVE LEFTWARDS ARROW
    0x002947 =>      15,   #  ⥇  gc=Sm   sc=Common     RIGHTWARDS ARROW THROUGH X
    0x00296E =>       3,   #  ⥮  gc=Sm   sc=Common     UPWARDS HARPOON WITH BARB LEFT BESIDE DOWNWARDS HARPOON WITH BARB RIGHT
    0x00296F =>       1,   #  ⥯  gc=Sm   sc=Common     DOWNWARDS HARPOON WITH BARB LEFT BESIDE UPWARDS HARPOON WITH BARB RIGHT
    0x002980 =>      17,   #  ⦀  gc=Sm   sc=Common     TRIPLE VERTICAL BAR DELIMITER
    0x002999 =>       2,   #  ⦙  gc=Sm   sc=Common     DOTTED FENCE
    0x0029A0 =>       2,   #  ⦠  gc=Sm   sc=Common     SPHERICAL ANGLE OPENING LEFT
    0x0029A1 =>      12,   #  ⦡  gc=Sm   sc=Common     SPHERICAL ANGLE OPENING UP
    0x0029B5 =>       9,   #  ⦵  gc=Sm   sc=Common     CIRCLE WITH HORIZONTAL BAR
    0x0029B6 =>      13,   #  ⦶  gc=Sm   sc=Common     CIRCLED VERTICAL BAR
    0x0029EB =>      59,   #  ⧫  gc=Sm   sc=Common     BLACK LOZENGE
    0x0029F8 =>   27547,   #  ⧸  gc=Sm   sc=Common     BIG SOLIDUS
    0x0029F9 =>    1238,   #  ⧹  gc=Sm   sc=Common     BIG REVERSE SOLIDUS
    0x002A0D =>       4,   #  ⨍  gc=Sm   sc=Common     FINITE PART INTEGRAL
    0x002A10 =>       2,   #  ⨐  gc=Sm   sc=Common     CIRCULATION FUNCTION
    0x002A16 =>       1,   #  ⨖  gc=Sm   sc=Common     QUATERNION INTEGRAL OPERATOR
    0x002A2A =>      42,   #  ⨪  gc=Sm   sc=Common     MINUS SIGN WITH DOT BELOW
    0x002A2F =>     270,   #  ⨯  gc=Sm   sc=Common     VECTOR OR CROSS PRODUCT
    0x002A38 =>       3,   #  ⨸  gc=Sm   sc=Common     CIRCLED DIVISION SIGN
    0x002A3C =>       1,   #  ⨼  gc=Sm   sc=Common     INTERIOR PRODUCT
    0x002A3F =>       6,   #  ⨿  gc=Sm   sc=Common     AMALGAMATION OR COPRODUCT
    0x002A5E =>      24,   #  ⩞  gc=Sm   sc=Common     LOGICAL AND WITH DOUBLE OVERBAR
    0x002A7D =>    5303,   #  ⩽  gc=Sm   sc=Common     LESS-THAN OR SLANTED EQUAL TO
    0x002A7E =>    6823,   #  ⩾  gc=Sm   sc=Common     GREATER-THAN OR SLANTED EQUAL TO
    0x002A85 =>       1,   #  ⪅  gc=Sm   sc=Common     LESS-THAN OR APPROXIMATE
    0x002A86 =>       1,   #  ⪆  gc=Sm   sc=Common     GREATER-THAN OR APPROXIMATE
    0x002A95 =>       2,   #  ⪕  gc=Sm   sc=Common     SLANTED EQUAL TO OR LESS-THAN
    0x002A96 =>      13,   #  ⪖  gc=Sm   sc=Common     SLANTED EQUAL TO OR GREATER-THAN
    0x002AA1 =>     303,   #  ⪡  gc=Sm   sc=Common     DOUBLE NESTED LESS-THAN
    0x002AA2 =>     696,   #  ⪢  gc=Sm   sc=Common     DOUBLE NESTED GREATER-THAN
    0x002AAF =>       9,   #  ⪯  gc=Sm   sc=Common     PRECEDES ABOVE SINGLE-LINE EQUALS SIGN
    0x002AB0 =>      27,   #  ⪰  gc=Sm   sc=Common     SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN
    0x002ADF =>      12,   #  ⫟  gc=Sm   sc=Common     SHORT DOWN TACK
    0x002AE0 =>       1,   #  ⫠  gc=Sm   sc=Common     SHORT UP TACK
    0x002AE2 =>       1,   #  ⫢  gc=Sm   sc=Common     VERTICAL BAR TRIPLE RIGHT TURNSTILE
    0x002AEB =>      19,   #  ⫫  gc=Sm   sc=Common     DOUBLE UP TACK
    0x002AF6 =>      44,   #  ⫶  gc=Sm   sc=Common     TRIPLE COLON OPERATOR
    0x00266D =>       1,   #  ♭  gc=So   sc=Common     MUSIC FLAT SIGN
    0x00266F =>     409,   #  ♯  gc=Sm   sc=Common     MUSIC SHARP SIGN
    0x00FFFD =>      46,   #  �  gc=So   sc=Common     REPLACEMENT CHARACTER
    0x0002D0 =>       4,   #  ː  gc=Lm   sc=Common     MODIFIER LETTER TRIANGULAR COLON
    0x0000A4 =>     140,   #  ¤  gc=Sc   sc=Common     CURRENCY SIGN
    0x0000A2 =>     241,   #  ¢  gc=Sc   sc=Common     CENT SIGN
    0x0000A3 =>    5506,   #  £  gc=Sc   sc=Common     POUND SIGN
    0x0000A5 =>     594,   #  ¥  gc=Sc   sc=Common     YEN SIGN
    0x0020A4 =>       3,   #  ₤  gc=Sc   sc=Common     LIRA SIGN
    0x0020A7 =>      33,   #  ₧  gc=Sc   sc=Common     PESETA SIGN
    0x0020AC =>    2757,   #  €  gc=Sc   sc=Common     EURO SIGN
    0x002460 =>      41,   #  ①  gc=No   sc=Common     CIRCLED DIGIT ONE
    0x002776 =>       2,   #  ❶  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED DIGIT ONE
    0x002780 =>       3,   #  ➀  gc=No   sc=Common     DINGBAT CIRCLED SANS-SERIF DIGIT ONE
    0x0000B9 =>       1,   #  ¹  gc=No   sc=Common     SUPERSCRIPT ONE
    0x0000BD =>    2556,   #  ½  gc=No   sc=Common     VULGAR FRACTION ONE HALF
    0x002153 =>      44,   #  ⅓  gc=No   sc=Common     VULGAR FRACTION ONE THIRD
    0x0000BC =>     190,   #  ¼  gc=No   sc=Common     VULGAR FRACTION ONE QUARTER
    0x002159 =>       1,   #  ⅙  gc=No   sc=Common     VULGAR FRACTION ONE SIXTH
    0x00215B =>       4,   #  ⅛  gc=No   sc=Common     VULGAR FRACTION ONE EIGHTH
    0x002469 =>       2,   #  ⑩  gc=No   sc=Common     CIRCLED NUMBER TEN
    0x002461 =>      41,   #  ②  gc=No   sc=Common     CIRCLED DIGIT TWO
    0x002777 =>       2,   #  ❷  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED DIGIT TWO
    0x0000B2 =>      53,   #  ²  gc=No   sc=Common     SUPERSCRIPT TWO
    0x002154 =>      10,   #  ⅔  gc=No   sc=Common     VULGAR FRACTION TWO THIRDS
    0x002156 =>       1,   #  ⅖  gc=No   sc=Common     VULGAR FRACTION TWO FIFTHS
    0x002462 =>      34,   #  ③  gc=No   sc=Common     CIRCLED DIGIT THREE
    0x002778 =>       2,   #  ❸  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED DIGIT THREE
    0x0000B3 =>       2,   #  ³  gc=No   sc=Common     SUPERSCRIPT THREE
    0x0000BE =>     307,   #  ¾  gc=No   sc=Common     VULGAR FRACTION THREE QUARTERS
    0x00215C =>       4,   #  ⅜  gc=No   sc=Common     VULGAR FRACTION THREE EIGHTHS
    0x002463 =>      24,   #  ④  gc=No   sc=Common     CIRCLED DIGIT FOUR
    0x002779 =>       1,   #  ❹  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED DIGIT FOUR
    0x002464 =>      26,   #  ⑤  gc=No   sc=Common     CIRCLED DIGIT FIVE
    0x00277A =>       1,   #  ❺  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED DIGIT FIVE
    0x00215A =>       1,   #  ⅚  gc=No   sc=Common     VULGAR FRACTION FIVE SIXTHS
    0x00215D =>       1,   #  ⅝  gc=No   sc=Common     VULGAR FRACTION FIVE EIGHTHS
    0x002465 =>      22,   #  ⑥  gc=No   sc=Common     CIRCLED DIGIT SIX
    0x002466 =>      13,   #  ⑦  gc=No   sc=Common     CIRCLED DIGIT SEVEN
    0x00215E =>       1,   #  ⅞  gc=No   sc=Common     VULGAR FRACTION SEVEN EIGHTHS
    0x002467 =>       9,   #  ⑧  gc=No   sc=Common     CIRCLED DIGIT EIGHT
    0x002468 =>       6,   #  ⑨  gc=No   sc=Common     CIRCLED DIGIT NINE
    0x0000AA =>      37,   #  ª  gc=Ll   sc=Latin      FEMININE ORDINAL INDICATOR
    0x0000E1 =>  122942,   #  á  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH ACUTE
    0x0000C1 =>    3242,   #  Á  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH ACUTE
    0x0000E0 =>   26679,   #  à  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH GRAVE
    0x0000C0 =>     301,   #  À  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH GRAVE
    0x000103 =>     246,   #  ă  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH BREVE
    0x000102 =>       7,   #  Ă  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH BREVE
    0x0000E2 =>    4353,   #  â  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CIRCUMFLEX
    0x0000C2 =>     214,   #  Â  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH CIRCUMFLEX
    0x001EA5 =>       3,   #  ấ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CIRCUMFLEX AND ACUTE
    0x001EA7 =>       1,   #  ầ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CIRCUMFLEX AND GRAVE
    0x0001CE =>     206,   #  ǎ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CARON
    0x0000E5 =>   19635,   #  å  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH RING ABOVE
    0x0000C5 =>   31442,   #  Å  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH RING ABOVE
    0x00212B =>      10,   #  Å  gc=Lu   sc=Latin      ANGSTROM SIGN
    0x0001FB =>       2,   #  ǻ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH RING ABOVE AND ACUTE
    0x0001FA =>     102,   #  Ǻ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH RING ABOVE AND ACUTE
    0x0000E4 =>  164121,   #  ä  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH DIAERESIS
    0x0000C4 =>    2253,   #  Ä  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH DIAERESIS
    0x0000E3 =>   39749,   #  ã  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH TILDE
    0x0000C3 =>     149,   #  Ã  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH TILDE
    0x000105 =>     221,   #  ą  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH OGONEK
    0x000104 =>       1,   #  Ą  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH OGONEK
    0x000101 =>     344,   #  ā  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH MACRON
    0x000100 =>      66,   #  Ā  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH MACRON
    0x001EA3 =>       4,   #  ả  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH HOOK ABOVE
    0x000201 =>       2,   #  ȁ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH DOUBLE GRAVE
    0x001EA1 =>       4,   #  ạ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH DOT BELOW
    0x001EB7 =>       1,   #  ặ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH BREVE AND DOT BELOW
    0x001EAD =>       5,   #  ậ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CIRCUMFLEX AND DOT BELOW
    0x0000E6 =>    4461,   #  æ  gc=Ll   sc=Latin      LATIN SMALL LETTER AE
    0x0000C6 =>     190,   #  Æ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER AE
    0x0001FD =>       5,   #  ǽ  gc=Ll   sc=Latin      LATIN SMALL LETTER AE WITH ACUTE
    0x001D00 =>       2,   #  ᴀ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL A
    0x000250 =>       6,   #  ɐ  gc=Ll   sc=Latin      LATIN SMALL LETTER TURNED A
    0x000251 =>       8,   #  ɑ  gc=Ll   sc=Latin      LATIN SMALL LETTER ALPHA
    0x00212C =>       1,   #  ℬ  gc=Lu   sc=Common     SCRIPT CAPITAL B
    0x00212D =>       1,   #  ℭ  gc=Lu   sc=Common     BLACK-LETTER CAPITAL C
    0x000107 =>    8874,   #  ć  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH ACUTE
    0x000106 =>      84,   #  Ć  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH ACUTE
    0x000109 =>     117,   #  ĉ  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH CIRCUMFLEX
    0x000108 =>      48,   #  Ĉ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH CIRCUMFLEX
    0x00010D =>    5401,   #  č  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH CARON
    0x00010C =>     938,   #  Č  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH CARON
    0x00010B =>      22,   #  ċ  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH DOT ABOVE
    0x00010A =>      17,   #  Ċ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH DOT ABOVE
    0x0000E7 =>   39619,   #  ç  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH CEDILLA
    0x0000C7 =>    3126,   #  Ç  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH CEDILLA
    0x002105 =>       2,   #  ℅  gc=So   sc=Common     CARE OF
    0x001D04 =>       9,   #  ᴄ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL C
    0x00010F =>       3,   #  ď  gc=Ll   sc=Latin      LATIN SMALL LETTER D WITH CARON
    0x00010E =>      17,   #  Ď  gc=Lu   sc=Latin      LATIN CAPITAL LETTER D WITH CARON
    0x000111 =>      62,   #  đ  gc=Ll   sc=Latin      LATIN SMALL LETTER D WITH STROKE
    0x000110 =>      50,   #  Đ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER D WITH STROKE
    0x0000F0 =>     116,   #  ð  gc=Ll   sc=Latin      LATIN SMALL LETTER ETH
    0x0000D0 =>      41,   #  Ð  gc=Lu   sc=Latin      LATIN CAPITAL LETTER ETH
    0x0000E9 =>  380198,   #  é  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH ACUTE
    0x0000C9 =>    3771,   #  É  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH ACUTE
    0x0000E8 =>   45632,   #  è  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH GRAVE
    0x0000C8 =>     199,   #  È  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH GRAVE
    0x000115 =>     122,   #  ĕ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH BREVE
    0x000114 =>       1,   #  Ĕ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH BREVE
    0x0000EA =>   12473,   #  ê  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX
    0x0000CA =>     181,   #  Ê  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH CIRCUMFLEX
    0x001EBF =>       3,   #  ế  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX AND ACUTE
    0x001EC5 =>      18,   #  ễ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX AND TILDE
    0x001EC3 =>       1,   #  ể  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX AND HOOK ABOVE
    0x00011B =>     474,   #  ě  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CARON
    0x00011A =>       1,   #  Ě  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH CARON
    0x0000EB =>    7505,   #  ë  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH DIAERESIS
    0x0000CB =>      39,   #  Ë  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH DIAERESIS
    0x001EBD =>       2,   #  ẽ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH TILDE
    0x000117 =>      22,   #  ė  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH DOT ABOVE
    0x000116 =>      20,   #  Ė  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH DOT ABOVE
    0x000229 =>       5,   #  ȩ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CEDILLA
    0x000119 =>     265,   #  ę  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH OGONEK
    0x000113 =>      63,   #  ē  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH MACRON
    0x000112 =>      88,   #  Ē  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH MACRON
    0x001EBB =>       2,   #  ẻ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH HOOK ABOVE
    0x001EB8 =>      31,   #  Ẹ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH DOT BELOW
    0x001EC7 =>       5,   #  ệ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX AND DOT BELOW
    0x001D07 =>       2,   #  ᴇ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL E
    0x000259 =>      55,   #  ə  gc=Ll   sc=Latin      LATIN SMALL LETTER SCHWA
    0x00025B =>     163,   #  ɛ  gc=Ll   sc=Latin      LATIN SMALL LETTER OPEN E
    0x00025C =>       2,   #  ɜ  gc=Ll   sc=Latin      LATIN SMALL LETTER REVERSED OPEN E
    0x00025E =>       2,   #  ɞ  gc=Ll   sc=Latin      LATIN SMALL LETTER CLOSED REVERSED OPEN E
    0x00FB01 =>       4,   #  ﬁ  gc=Ll   sc=Latin      LATIN SMALL LIGATURE FI
    0x0002A9 =>       1,   #  ʩ  gc=Ll   sc=Latin      LATIN SMALL LETTER FENG DIGRAPH
    0x000192 =>     309,   #  ƒ  gc=Ll   sc=Latin      LATIN SMALL LETTER F WITH HOOK
    0x002132 =>       5,   #  Ⅎ  gc=Lu   sc=Latin      TURNED CAPITAL F
    0x0001F5 =>       8,   #  ǵ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH ACUTE
    0x00011F =>    4021,   #  ğ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH BREVE
    0x00011E =>      57,   #  Ğ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER G WITH BREVE
    0x00011D =>      93,   #  ĝ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH CIRCUMFLEX
    0x00011C =>      10,   #  Ĝ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER G WITH CIRCUMFLEX
    0x0001E7 =>      37,   #  ǧ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH CARON
    0x000120 =>       4,   #  Ġ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER G WITH DOT ABOVE
    0x000123 =>       1,   #  ģ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH CEDILLA
    0x000122 =>       1,   #  Ģ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER G WITH CEDILLA
    0x001E21 =>       7,   #  ḡ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH MACRON
    0x000261 =>      11,   #  ɡ  gc=Ll   sc=Latin      LATIN SMALL LETTER SCRIPT G
    0x000263 =>       4,   #  ɣ  gc=Ll   sc=Latin      LATIN SMALL LETTER GAMMA
    0x00210C =>       3,   #  ℌ  gc=Lu   sc=Common     BLACK-LETTER CAPITAL H
    0x000125 =>       7,   #  ĥ  gc=Ll   sc=Latin      LATIN SMALL LETTER H WITH CIRCUMFLEX
    0x000124 =>      30,   #  Ĥ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER H WITH CIRCUMFLEX
    0x001E29 =>       1,   #  ḩ  gc=Ll   sc=Latin      LATIN SMALL LETTER H WITH CEDILLA
    0x000127 =>       2,   #  ħ  gc=Ll   sc=Latin      LATIN SMALL LETTER H WITH STROKE
    0x00210F =>      33,   #  ℏ  gc=Ll   sc=Common     PLANCK CONSTANT OVER TWO PI
    0x00029C =>       1,   #  ʜ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL H
    0x0002BD =>       2,   #  ʽ  gc=Lm   sc=Common     MODIFIER LETTER REVERSED COMMA
    0x0000ED =>   36153,   #  í  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH ACUTE
    0x0000CD =>    2242,   #  Í  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH ACUTE
    0x0000EC =>     748,   #  ì  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH GRAVE
    0x0000CC =>      41,   #  Ì  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH GRAVE
    0x00012D =>      56,   #  ĭ  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH BREVE
    0x00012C =>       4,   #  Ĭ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH BREVE
    0x0000EE =>     510,   #  î  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH CIRCUMFLEX
    0x0000CE =>      76,   #  Î  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH CIRCUMFLEX
    0x0001D0 =>       3,   #  ǐ  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH CARON
    0x0001CF =>       2,   #  Ǐ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH CARON
    0x0000EF =>    7749,   #  ï  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH DIAERESIS
    0x0000CF =>     149,   #  Ï  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH DIAERESIS
    0x000129 =>      10,   #  ĩ  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH TILDE
    0x000128 =>       6,   #  Ĩ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH TILDE
    0x000130 =>     353,   #  İ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH DOT ABOVE
    0x00012F =>       2,   #  į  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH OGONEK
    0x00012B =>      12,   #  ī  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH MACRON
    0x00012A =>      25,   #  Ī  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH MACRON
    0x001ECB =>       3,   #  ị  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH DOT BELOW
    0x000131 =>   86999,   #  ı  gc=Ll   sc=Latin      LATIN SMALL LETTER DOTLESS I
    0x00026A =>      22,   #  ɪ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL I
    0x000269 =>      85,   #  ɩ  gc=Ll   sc=Latin      LATIN SMALL LETTER IOTA
    0x0002B2 =>       1,   #  ʲ  gc=Lm   sc=Latin      MODIFIER LETTER SMALL J
    0x000135 =>       5,   #  ĵ  gc=Ll   sc=Latin      LATIN SMALL LETTER J WITH CIRCUMFLEX
    0x000134 =>      15,   #  Ĵ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER J WITH CIRCUMFLEX
    0x00212A =>      21,   #  K  gc=Lu   sc=Latin      KELVIN SIGN
    0x002113 =>     641,   #  ℓ  gc=Ll   sc=Common     SCRIPT SMALL L
    0x002112 =>       1,   #  ℒ  gc=Lu   sc=Common     SCRIPT CAPITAL L
    0x00013A =>      49,   #  ĺ  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH ACUTE
    0x000139 =>      19,   #  Ĺ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER L WITH ACUTE
    0x00013E =>       3,   #  ľ  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH CARON
    0x00013D =>       2,   #  Ľ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER L WITH CARON
    0x00013C =>       1,   #  ļ  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH CEDILLA
    0x000142 =>    4282,   #  ł  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH STROKE
    0x000141 =>     713,   #  Ł  gc=Lu   sc=Latin      LATIN CAPITAL LETTER L WITH STROKE
    0x000140 =>      11,   #  ŀ  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH MIDDLE DOT
    0x00013F =>       2,   #  Ŀ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER L WITH MIDDLE DOT
    0x00026D =>       2,   #  ɭ  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH RETROFLEX HOOK
    0x00019B =>      55,   #  ƛ  gc=Ll   sc=Latin      LATIN SMALL LETTER LAMBDA WITH STROKE
    0x002133 =>       2,   #  ℳ  gc=Lu   sc=Common     SCRIPT CAPITAL M
    0x000271 =>       1,   #  ɱ  gc=Ll   sc=Latin      LATIN SMALL LETTER M WITH HOOK
    0x000144 =>    5029,   #  ń  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH ACUTE
    0x000143 =>      14,   #  Ń  gc=Lu   sc=Latin      LATIN CAPITAL LETTER N WITH ACUTE
    0x000148 =>     665,   #  ň  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH CARON
    0x000147 =>       1,   #  Ň  gc=Lu   sc=Latin      LATIN CAPITAL LETTER N WITH CARON
    0x0000F1 =>   34405,   #  ñ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH TILDE
    0x0000D1 =>     156,   #  Ñ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER N WITH TILDE
    0x000146 =>       8,   #  ņ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH CEDILLA
    0x000272 =>       7,   #  ɲ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH LEFT HOOK
    0x00014B =>       6,   #  ŋ  gc=Ll   sc=Latin      LATIN SMALL LETTER ENG
    0x0000BA =>    1361,   #  º  gc=Ll   sc=Latin      MASCULINE ORDINAL INDICATOR
    0x002092 =>       2,   #  ₒ  gc=Lm   sc=Latin      LATIN SUBSCRIPT SMALL LETTER O
    0x0000F3 =>   99233,   #  ó  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH ACUTE
    0x0000D3 =>     607,   #  Ó  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH ACUTE
    0x0000F2 =>    5881,   #  ò  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH GRAVE
    0x0000D2 =>     103,   #  Ò  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH GRAVE
    0x00014F =>      42,   #  ŏ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH BREVE
    0x00014E =>       2,   #  Ŏ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH BREVE
    0x0000F4 =>   23832,   #  ô  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX
    0x0000D4 =>     149,   #  Ô  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH CIRCUMFLEX
    0x001ED1 =>       2,   #  ố  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX AND ACUTE
    0x001ED3 =>       4,   #  ồ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX AND GRAVE
    0x001ED7 =>       4,   #  ỗ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX AND TILDE
    0x001ED5 =>       1,   #  ổ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX AND HOOK ABOVE
    0x0001D2 =>      31,   #  ǒ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CARON
    0x0000F6 =>  247208,   #  ö  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH DIAERESIS
    0x0000D6 =>   15845,   #  Ö  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH DIAERESIS
    0x000151 =>      28,   #  ő  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH DOUBLE ACUTE
    0x000150 =>       8,   #  Ő  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH DOUBLE ACUTE
    0x0000F5 =>    2993,   #  õ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH TILDE
    0x0000D5 =>      55,   #  Õ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH TILDE
    0x0000F8 =>   32111,   #  ø  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH STROKE
    0x0000D8 =>    7555,   #  Ø  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH STROKE
    0x0001FF =>      27,   #  ǿ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH STROKE AND ACUTE
    0x0001FE =>       8,   #  Ǿ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH STROKE AND ACUTE
    0x00014D =>     118,   #  ō  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH MACRON
    0x00014C =>      75,   #  Ō  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH MACRON
    0x001ECF =>       1,   #  ỏ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH HOOK ABOVE
    0x0001A1 =>       1,   #  ơ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH HORN
    0x0001A0 =>       1,   #  Ơ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH HORN
    0x001EDB =>       2,   #  ớ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH HORN AND ACUTE
    0x001EDD =>       1,   #  ờ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH HORN AND GRAVE
    0x001ECD =>       7,   #  ọ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH DOT BELOW
    0x001ECC =>       8,   #  Ọ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH DOT BELOW
    0x001ED9 =>       1,   #  ộ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX AND DOT BELOW
    0x001ED8 =>       2,   #  Ộ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH CIRCUMFLEX AND DOT BELOW
    0x000153 =>     722,   #  œ  gc=Ll   sc=Latin      LATIN SMALL LIGATURE OE
    0x000152 =>      20,   #  Œ  gc=Lu   sc=Latin      LATIN CAPITAL LIGATURE OE
    0x001D0F =>      58,   #  ᴏ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL O
    0x000254 =>      45,   #  ɔ  gc=Ll   sc=Latin      LATIN SMALL LETTER OPEN O
    0x000275 =>       1,   #  ɵ  gc=Ll   sc=Latin      LATIN SMALL LETTER BARRED O
    0x001E55 =>       1,   #  ṕ  gc=Ll   sc=Latin      LATIN SMALL LETTER P WITH ACUTE
    0x001D18 =>       6,   #  ᴘ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL P
    0x0001A5 =>       1,   #  ƥ  gc=Ll   sc=Latin      LATIN SMALL LETTER P WITH HOOK
    0x000138 =>       2,   #  ĸ  gc=Ll   sc=Latin      LATIN SMALL LETTER KRA
    0x00211D =>       1,   #  ℝ  gc=Lu   sc=Common     DOUBLE-STRUCK CAPITAL R
    0x000155 =>      54,   #  ŕ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH ACUTE
    0x000154 =>       2,   #  Ŕ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER R WITH ACUTE
    0x000159 =>     882,   #  ř  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH CARON
    0x000158 =>      92,   #  Ř  gc=Lu   sc=Latin      LATIN CAPITAL LETTER R WITH CARON
    0x000157 =>       5,   #  ŗ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH CEDILLA
    0x000156 =>       2,   #  Ŗ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER R WITH CEDILLA
    0x000213 =>       1,   #  ȓ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH INVERTED BREVE
    0x000280 =>       1,   #  ʀ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL R
    0x00027C =>       1,   #  ɼ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH LONG LEG
    0x00027E =>       6,   #  ɾ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH FISHHOOK
    0x00015B =>     784,   #  ś  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH ACUTE
    0x00015A =>     317,   #  Ś  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH ACUTE
    0x00015D =>      59,   #  ŝ  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH CIRCUMFLEX
    0x00015C =>      63,   #  Ŝ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH CIRCUMFLEX
    0x000161 =>    5934,   #  š  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH CARON
    0x000160 =>    2967,   #  Š  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH CARON
    0x00015F =>    6549,   #  ş  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH CEDILLA
    0x00015E =>    1651,   #  Ş  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH CEDILLA
    0x00017F =>       7,   #  ſ  gc=Ll   sc=Latin      LATIN SMALL LETTER LONG S
    0x0000DF =>   12061,   #  ß  gc=Ll   sc=Latin      LATIN SMALL LETTER SHARP S
    0x000282 =>       2,   #  ʂ  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH HOOK
    0x000283 =>     498,   #  ʃ  gc=Ll   sc=Latin      LATIN SMALL LETTER ESH
    0x000165 =>      23,   #  ť  gc=Ll   sc=Latin      LATIN SMALL LETTER T WITH CARON
    0x000164 =>       3,   #  Ť  gc=Lu   sc=Latin      LATIN CAPITAL LETTER T WITH CARON
    0x001E6A =>       2,   #  Ṫ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER T WITH DOT ABOVE
    0x000163 =>      35,   #  ţ  gc=Ll   sc=Latin      LATIN SMALL LETTER T WITH CEDILLA
    0x002121 =>       1,   #  ℡  gc=So   sc=Common     TELEPHONE SIGN
    0x002122 =>   40398,   #  ™  gc=So   sc=Common     TRADE MARK SIGN
    0x0000FA =>   11344,   #  ú  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH ACUTE
    0x0000DA =>     147,   #  Ú  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH ACUTE
    0x0000F9 =>    1065,   #  ù  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH GRAVE
    0x0000D9 =>      34,   #  Ù  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH GRAVE
    0x00016D =>      19,   #  ŭ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH BREVE
    0x0000FB =>     781,   #  û  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH CIRCUMFLEX
    0x0000DB =>      43,   #  Û  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH CIRCUMFLEX
    0x0001D4 =>       9,   #  ǔ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH CARON
    0x00016F =>     148,   #  ů  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH RING ABOVE
    0x0000FC =>  200690,   #  ü  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DIAERESIS
    0x0000DC =>    5390,   #  Ü  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH DIAERESIS
    0x0001DC =>       2,   #  ǜ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DIAERESIS AND GRAVE
    0x0001D9 =>       1,   #  Ǚ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH DIAERESIS AND CARON
    0x0001D6 =>       2,   #  ǖ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DIAERESIS AND MACRON
    0x0001D5 =>       1,   #  Ǖ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH DIAERESIS AND MACRON
    0x000171 =>      19,   #  ű  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DOUBLE ACUTE
    0x000170 =>       3,   #  Ű  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH DOUBLE ACUTE
    0x000169 =>      51,   #  ũ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH TILDE
    0x000168 =>       1,   #  Ũ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH TILDE
    0x000173 =>       9,   #  ų  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH OGONEK
    0x00016B =>      70,   #  ū  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH MACRON
    0x00016A =>       9,   #  Ū  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH MACRON
    0x001EE7 =>       2,   #  ủ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH HOOK ABOVE
    0x0001B0 =>       1,   #  ư  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH HORN
    0x001EE9 =>       1,   #  ứ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH HORN AND ACUTE
    0x001EEB =>       1,   #  ừ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH HORN AND GRAVE
    0x001EEF =>       1,   #  ữ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH HORN AND TILDE
    0x001EF1 =>       3,   #  ự  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH HORN AND DOT BELOW
    0x001EE5 =>       3,   #  ụ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DOT BELOW
    0x000265 =>       2,   #  ɥ  gc=Ll   sc=Latin      LATIN SMALL LETTER TURNED H
    0x00026F =>      11,   #  ɯ  gc=Ll   sc=Latin      LATIN SMALL LETTER TURNED M
    0x00028A =>      14,   #  ʊ  gc=Ll   sc=Latin      LATIN SMALL LETTER UPSILON
    0x001D20 =>       4,   #  ᴠ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL V
    0x00028B =>       6,   #  ʋ  gc=Ll   sc=Latin      LATIN SMALL LETTER V WITH HOOK
    0x00028C =>      10,   #  ʌ  gc=Ll   sc=Latin      LATIN SMALL LETTER TURNED V
    0x000175 =>       8,   #  ŵ  gc=Ll   sc=Latin      LATIN SMALL LETTER W WITH CIRCUMFLEX
    0x0000FD =>    1882,   #  ý  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH ACUTE
    0x0000DD =>     227,   #  Ý  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Y WITH ACUTE
    0x001EF3 =>       7,   #  ỳ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH GRAVE
    0x000177 =>      65,   #  ŷ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH CIRCUMFLEX
    0x000176 =>      33,   #  Ŷ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Y WITH CIRCUMFLEX
    0x0000FF =>     153,   #  ÿ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH DIAERESIS
    0x000178 =>      23,   #  Ÿ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Y WITH DIAERESIS
    0x001EF9 =>       4,   #  ỹ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH TILDE
    0x00017A =>     767,   #  ź  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH ACUTE
    0x000179 =>      27,   #  Ź  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Z WITH ACUTE
    0x00017E =>    1338,   #  ž  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH CARON
    0x00017D =>     606,   #  Ž  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Z WITH CARON
    0x00017C =>     751,   #  ż  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH DOT ABOVE
    0x00017B =>     281,   #  Ż  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Z WITH DOT ABOVE
    0x000292 =>      10,   #  ʒ  gc=Ll   sc=Latin      LATIN SMALL LETTER EZH
    0x0000FE =>      41,   #  þ  gc=Ll   sc=Latin      LATIN SMALL LETTER THORN
    0x0000DE =>      23,   #  Þ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER THORN
    0x000294 =>       2,   #  ʔ  gc=Lo   sc=Latin      LATIN LETTER GLOTTAL STOP
    0x0002BC =>      50,   #  ʼ  gc=Lm   sc=Common     MODIFIER LETTER APOSTROPHE
    0x000295 =>       3,   #  ʕ  gc=Ll   sc=Latin      LATIN LETTER PHARYNGEAL VOICED FRICATIVE
    0x0001C0 =>     391,   #  ǀ  gc=Lo   sc=Latin      LATIN LETTER DENTAL CLICK
    0x0001C1 =>       2,   #  ǁ  gc=Lo   sc=Latin      LATIN LETTER LATERAL CLICK
    0x0001C2 =>      24,   #  ǂ  gc=Lo   sc=Latin      LATIN LETTER ALVEOLAR CLICK
    0x0001C3 =>      10,   #  ǃ  gc=Lo   sc=Latin      LATIN LETTER RETROFLEX CLICK
    0x000297 =>       6,   #  ʗ  gc=Ll   sc=Latin      LATIN LETTER STRETCHED C
    0x000298 =>       1,   #  ʘ  gc=Ll   sc=Latin      LATIN LETTER BILABIAL CLICK
    0x0003B1 => 1112960,   #  α  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA
    0x000391 =>     229,   #  Α  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ALPHA
    0x0003AC =>      81,   #  ά  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH TONOS
    0x0003B2 => 1097639,   #  β  gc=Ll   sc=Greek      GREEK SMALL LETTER BETA
    0x0003D0 =>      56,   #  ϐ  gc=Ll   sc=Greek      GREEK BETA SYMBOL
    0x000392 =>     149,   #  Β  gc=Lu   sc=Greek      GREEK CAPITAL LETTER BETA
    0x0003B3 =>  321472,   #  γ  gc=Ll   sc=Greek      GREEK SMALL LETTER GAMMA
    0x000393 =>    1435,   #  Γ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER GAMMA
    0x0003B4 =>   91875,   #  δ  gc=Ll   sc=Greek      GREEK SMALL LETTER DELTA
    0x000394 =>  169339,   #  Δ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER DELTA
    0x0003B5 =>   35812,   #  ε  gc=Ll   sc=Greek      GREEK SMALL LETTER EPSILON
    0x0003F5 =>   22254,   #  ϵ  gc=Ll   sc=Greek      GREEK LUNATE EPSILON SYMBOL
    0x000395 =>      25,   #  Ε  gc=Lu   sc=Greek      GREEK CAPITAL LETTER EPSILON
    0x0003AD =>       9,   #  έ  gc=Ll   sc=Greek      GREEK SMALL LETTER EPSILON WITH TONOS
    0x0003B6 =>   11812,   #  ζ  gc=Ll   sc=Greek      GREEK SMALL LETTER ZETA
    0x000396 =>      12,   #  Ζ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ZETA
    0x0003B7 =>    7730,   #  η  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA
    0x000397 =>      40,   #  Η  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ETA
    0x0003AE =>      19,   #  ή  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA WITH TONOS
    0x0003B8 =>   20347,   #  θ  gc=Ll   sc=Greek      GREEK SMALL LETTER THETA
    0x0003D1 =>     491,   #  ϑ  gc=Ll   sc=Greek      GREEK THETA SYMBOL
    0x000398 =>    1150,   #  Θ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER THETA
    0x0003F4 =>      79,   #  ϴ  gc=Lu   sc=Greek      GREEK CAPITAL THETA SYMBOL
    0x0003B9 =>     917,   #  ι  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA
    0x000399 =>     157,   #  Ι  gc=Lu   sc=Greek      GREEK CAPITAL LETTER IOTA
    0x0003AF =>      38,   #  ί  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH TONOS
    0x0003CA =>       4,   #  ϊ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH DIALYTIKA
    0x000390 =>       1,   #  ΐ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS
    0x0003BA =>  160319,   #  κ  gc=Ll   sc=Greek      GREEK SMALL LETTER KAPPA
    0x0003F0 =>     141,   #  ϰ  gc=Ll   sc=Greek      GREEK KAPPA SYMBOL
    0x00039A =>      29,   #  Κ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER KAPPA
    0x0003BB =>   36760,   #  λ  gc=Ll   sc=Greek      GREEK SMALL LETTER LAMDA
    0x00039B =>     771,   #  Λ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER LAMDA
    0x0003BC => 1693959,   #  μ  gc=Ll   sc=Greek      GREEK SMALL LETTER MU
    0x0000B5 =>     564,   #  µ  gc=Ll   sc=Common     MICRO SIGN
    0x00039C =>     208,   #  Μ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER MU
    0x0003BD =>    5284,   #  ν  gc=Ll   sc=Greek      GREEK SMALL LETTER NU
    0x00039D =>      46,   #  Ν  gc=Lu   sc=Greek      GREEK CAPITAL LETTER NU
    0x0003BE =>    2219,   #  ξ  gc=Ll   sc=Greek      GREEK SMALL LETTER XI
    0x00039E =>     100,   #  Ξ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER XI
    0x0003BF =>     231,   #  ο  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON
    0x00039F =>      45,   #  Ο  gc=Lu   sc=Greek      GREEK CAPITAL LETTER OMICRON
    0x0003CC =>       2,   #  ό  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON WITH TONOS
    0x0003C0 =>   12863,   #  π  gc=Ll   sc=Greek      GREEK SMALL LETTER PI
    0x0003D6 =>     128,   #  ϖ  gc=Ll   sc=Greek      GREEK PI SYMBOL
    0x0003A0 =>     563,   #  Π  gc=Lu   sc=Greek      GREEK CAPITAL LETTER PI
    0x0003C1 =>   16067,   #  ρ  gc=Ll   sc=Greek      GREEK SMALL LETTER RHO
    0x0003F1 =>     201,   #  ϱ  gc=Ll   sc=Greek      GREEK RHO SYMBOL
    0x0003A1 =>       9,   #  Ρ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER RHO
    0x0003C3 =>   32772,   #  σ  gc=Ll   sc=Greek      GREEK SMALL LETTER SIGMA
    0x0003A3 =>    5534,   #  Σ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER SIGMA
    0x0003C2 =>     107,   #  ς  gc=Ll   sc=Greek      GREEK SMALL LETTER FINAL SIGMA
    0x0003C4 =>   25989,   #  τ  gc=Ll   sc=Greek      GREEK SMALL LETTER TAU
    0x0003A4 =>      63,   #  Τ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER TAU
    0x0003C5 =>     760,   #  υ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON
    0x0003D2 =>      93,   #  ϒ  gc=Lu   sc=Greek      GREEK UPSILON WITH HOOK SYMBOL
    0x0003CD =>      10,   #  ύ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH TONOS
    0x0003CB =>      21,   #  ϋ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH DIALYTIKA
    0x0003C6 =>   12562,   #  φ  gc=Ll   sc=Greek      GREEK SMALL LETTER PHI
    0x0003D5 =>    3367,   #  ϕ  gc=Ll   sc=Greek      GREEK PHI SYMBOL
    0x0003A6 =>    5057,   #  Φ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER PHI
    0x0003C7 =>   71183,   #  χ  gc=Ll   sc=Greek      GREEK SMALL LETTER CHI
    0x0003A7 =>      94,   #  Χ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER CHI
    0x0003C8 =>    7035,   #  ψ  gc=Ll   sc=Greek      GREEK SMALL LETTER PSI
    0x0003A8 =>    7359,   #  Ψ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER PSI
    0x0003C9 =>   29414,   #  ω  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA
    0x0003A9 =>   16027,   #  Ω  gc=Lu   sc=Greek      GREEK CAPITAL LETTER OMEGA
    0x002126 =>      30,   #  Ω  gc=Lu   sc=Greek      OHM SIGN
    0x0003CE =>       7,   #  ώ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA WITH TONOS
    0x00038F =>       5,   #  Ώ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER OMEGA WITH TONOS
    0x0003E1 =>       1,   #  ϡ  gc=Ll   sc=Greek      GREEK SMALL LETTER SAMPI
    0x000430 =>      12,   #  а  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER A
    0x000410 =>       2,   #  А  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER A
    0x000431 =>       3,   #  б  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER BE
    0x000411 =>       1,   #  Б  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER BE
    0x000432 =>       4,   #  в  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER VE
    0x000433 =>       4,   #  г  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER GHE
    0x000413 =>      26,   #  Г  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER GHE
    0x000434 =>      10,   #  д  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER DE
    0x000414 =>       3,   #  Д  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER DE
    0x000454 =>      16,   #  є  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER UKRAINIAN IE
    0x000404 =>      21,   #  Є  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER UKRAINIAN IE
    0x000436 =>       5,   #  ж  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER ZHE
    0x000416 =>       4,   #  Ж  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER ZHE
    0x000437 =>       3,   #  з  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER ZE
    0x000417 =>       1,   #  З  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER ZE
    0x000438 =>       3,   #  и  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER I
    0x000418 =>      11,   #  И  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER I
    0x000406 =>       1,   #  І  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER BYELORUSSIAN-UKRAINIAN I
    0x000439 =>       9,   #  й  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER SHORT I
    0x00043A =>     147,   #  к  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER KA
    0x00041A =>       2,   #  К  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER KA
    0x00043B =>       2,   #  л  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER EL
    0x00041B =>       5,   #  Л  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER EL
    0x00043C =>       2,   #  м  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER EM
    0x00043D =>      10,   #  н  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER EN
    0x00043E =>       4,   #  о  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER O
    0x0004E9 =>       1,   #  ө  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER BARRED O
    0x00043F =>      12,   #  п  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER PE
    0x00041F =>      14,   #  П  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER PE
    0x000442 =>       7,   #  т  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER TE
    0x000423 =>       1,   #  У  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER U
    0x000444 =>      29,   #  ф  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER EF
    0x000424 =>      33,   #  Ф  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER EF
    0x000425 =>       1,   #  Х  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER HA
    0x000446 =>       6,   #  ц  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER TSE
    0x000426 =>       1,   #  Ц  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER TSE
    0x000447 =>       2,   #  ч  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER CHE
    0x000427 =>       2,   #  Ч  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER CHE
    0x000448 =>       2,   #  ш  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER SHA
    0x000428 =>       1,   #  Ш  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER SHA
    0x00044B =>       3,   #  ы  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER YERU
    0x00042B =>       3,   #  Ы  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER YERU
    0x00044C =>       1,   #  ь  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER SOFT SIGN
    0x00042C =>       1,   #  Ь  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER SOFT SIGN
    0x00044E =>      19,   #  ю  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER YU
    0x00044F =>       1,   #  я  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER YA
    0x00042F =>       1,   #  Я  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER YA
    0x002135 =>       8,   #  ℵ  gc=Lo   sc=Common     ALEF SYMBOL
    0x002137 =>       4,   #  ℷ  gc=Lo   sc=Common     GIMEL SYMBOL
    0x0005E1 =>       9,   #  ס  gc=Lo   sc=Hebrew     HEBREW LETTER SAMEKH
    0x000915 =>       3,   #  क  gc=Lo   sc=Devanagari DEVANAGARI LETTER KA
    0x000916 =>       1,   #  ख  gc=Lo   sc=Devanagari DEVANAGARI LETTER KHA
    0x000937 =>       1,   #  ष  gc=Lo   sc=Devanagari DEVANAGARI LETTER SSA
    0x000B0C =>       1,   #  ଌ  gc=Lo   sc=Oriya      ORIYA LETTER VOCALIC L
    0x00170E =>       1,   #  ᜎ  gc=Lo   sc=Tagalog    TAGALOG LETTER LA
    0x0015DB =>       3,   #  ᗛ  gc=Lo   sc=Canadian_aboriginal CANADIAN SYLLABICS CARRIER HWA
    0x004E1C =>       4,   #  东 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-4E1C
    0x0051AC =>       4,   #  冬 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-51AC
    0x005230 =>       6,   #  到 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-5230
    0x005357 =>       6,   #  南 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-5357
    0x005B50 =>       6,   #  子 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-5B50
    0x005E03 =>       2,   #  布 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-5E03
    0x0065B9 =>       6,   #  方 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-65B9
    0x0071D5 =>       6,   #  燕 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-71D5
    0x008201 =>       8,   #  舁 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-8201
    0x008805 =>       1,   #  蠅 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-8805
    0x008FC7 =>       6,   #  过 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-8FC7
    0x009638 =>       2,   #  阸 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-9638
    0x0098DE =>       6,   #  飞 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-98DE
    0x000E00 =>       1,   # <-> gc=Cn   sc=unassigned_script <unassigned code point>
    0x000EF7 =>       6,   # <-> gc=Cn   sc=unassigned_script <unassigned code point>
    0x002065 =>       1,   # <-> gc=Cn   sc=unassigned_script <unassigned code point>
    0x00E2D4 =>       6,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E301 =>       1,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E302 =>       2,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E34C =>       2,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E444 =>       1,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5B4 =>       7,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5B6 =>      18,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5B7 =>       2,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5B9 =>       3,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5BA =>       2,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5F2 =>       3,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5F4 =>       1,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5F8 =>    7497,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5F9 =>      10,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5FB =>     657,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5FC =>      43,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E5FD =>       3,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E605 =>    3025,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E606 =>     233,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E607 =>       1,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E60A =>       6,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E60B =>      24,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E626 =>      11,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E62D =>       5,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E630 =>       1,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E634 =>       1,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E643 =>      57,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E659 =>       1,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00E6D4 =>       6,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00EC02 =>       1,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00EF22 =>     157,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00F020 =>       6,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00F02C =>       3,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00F02D =>       2,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00F061 =>       4,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00F062 =>       2,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
    0x00F0A2 =>       1,   # <-> gc=Co   sc=Unknown    <unnamed code point in block=Private Use Area>
);

my %pmcoa_training = (

    0x000640 =>       4,  #  ـ  gc=Lm   sc=Common     ARABIC TATWEEL
    0x0000B4 =>    1203,  #  ´  gc=Sk   sc=Common     ACUTE ACCENT
    0x000384 =>       3,  #  ΄  gc=Sk   sc=Greek      GREEK TONOS
    0x0002DC =>    5725,  #  ˜  gc=Sk   sc=Common     SMALL TILDE
    0x0000AF =>    9247,  #  ¯  gc=Sk   sc=Common     MACRON
    0x00203E =>       1,  #  ‾  gc=Po   sc=Common     OVERLINE
    0x0002D8 =>       2,  #  ˘  gc=Sk   sc=Common     BREVE
    0x0002D9 =>    1774,  #  ˙  gc=Sk   sc=Common     DOT ABOVE
    0x0000A8 =>     159,  #  ¨  gc=Sk   sc=Common     DIAERESIS
    0x0002DA =>     356,  #  ˚  gc=Sk   sc=Common     RING ABOVE
    0x0002DD =>       1,  #  ˝  gc=Sk   sc=Common     DOUBLE ACUTE ACCENT
    0x001FBF =>       3,  #  ᾿  gc=Sk   sc=Greek      GREEK PSILI
    0x0000B8 =>      36,  #  ¸  gc=Sk   sc=Common     CEDILLA
    0x002017 =>       2,  #  ‗  gc=Po   sc=Common     DOUBLE LOW LINE
    0x00FF0D =>      11,  #  － gc=Pd   sc=Common     FULLWIDTH HYPHEN-MINUS
    0x002010 =>    1179,  #  ‐  gc=Pd   sc=Common     HYPHEN
    0x002011 =>     278,  #  ‑  gc=Pd   sc=Common     NON-BREAKING HYPHEN
    0x002012 =>      37,  #  ‒  gc=Pd   sc=Common     FIGURE DASH
    0x002013 => 2663710,  #  –  gc=Pd   sc=Common     EN DASH
    0x002014 =>  165345,  #  —  gc=Pd   sc=Common     EM DASH
    0x002015 =>     393,  #  ―  gc=Pd   sc=Common     HORIZONTAL BAR
    0x0030FB =>       7,  #  ・ gc=Po   sc=Common     KATAKANA MIDDLE DOT
    0x00FF0C =>       8,  #  ， gc=Po   sc=Common     FULLWIDTH COMMA
    0x00066C =>       4,  #  ٬  gc=Po   sc=Arabic     ARABIC THOUSANDS SEPARATOR
    0x00FF1B =>       1,  #  ； gc=Po   sc=Common     FULLWIDTH SEMICOLON
    0x00FF1A =>       1,  #  ： gc=Po   sc=Common     FULLWIDTH COLON
    0x0000A1 =>     191,  #  ¡  gc=Po   sc=Common     INVERTED EXCLAMATION MARK
    0x0000BF =>     188,  #  ¿  gc=Po   sc=Common     INVERTED QUESTION MARK
    0x00203D =>       1,  #  ‽  gc=Po   sc=Common     INTERROBANG
    0x00FF0E =>       1,  #  ． gc=Po   sc=Common     FULLWIDTH FULL STOP
    0x002025 =>     127,  #  ‥  gc=Po   sc=Common     TWO DOT LEADER
    0x002026 =>   25433,  #  …  gc=Po   sc=Common     HORIZONTAL ELLIPSIS
    0x003002 =>       1,  #  。 gc=Po   sc=Common     IDEOGRAPHIC FULL STOP
    0x000387 =>      20,  #  ·  gc=Po   sc=Common     GREEK ANO TELEIA
    0x0000B7 =>   86009,  #  ·  gc=Po   sc=Common     MIDDLE DOT
    0x00205C =>       1,  #  ⁜  gc=Po   sc=Common     DOTTED CROSS
    0x002018 =>  163000,  #  ‘  gc=Pi   sc=Common     LEFT SINGLE QUOTATION MARK
    0x002019 =>  376122,  #  ’  gc=Pf   sc=Common     RIGHT SINGLE QUOTATION MARK
    0x00201A =>      77,  #  ‚  gc=Ps   sc=Common     SINGLE LOW-9 QUOTATION MARK
    0x002039 =>      16,  #  ‹  gc=Pi   sc=Common     SINGLE LEFT-POINTING ANGLE QUOTATION MARK
    0x00203A =>       3,  #  ›  gc=Pf   sc=Common     SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
    0x00201C =>  292797,  #  “  gc=Pi   sc=Common     LEFT DOUBLE QUOTATION MARK
    0x00201D =>  293225,  #  ”  gc=Pf   sc=Common     RIGHT DOUBLE QUOTATION MARK
    0x00201E =>    1003,  #  „  gc=Ps   sc=Common     DOUBLE LOW-9 QUOTATION MARK
    0x00201F =>       3,  #  ‟  gc=Pi   sc=Common     DOUBLE HIGH-REVERSED-9 QUOTATION MARK
    0x0000AB =>    1069,  #  «  gc=Pi   sc=Common     LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
    0x0000BB =>    1166,  #  »  gc=Pf   sc=Common     RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
    0x00207D =>       1,  #  ⁽  gc=Ps   sc=Common     SUPERSCRIPT LEFT PARENTHESIS
    0x00207E =>       1,  #  ⁾  gc=Pe   sc=Common     SUPERSCRIPT RIGHT PARENTHESIS
    0x00FE37 =>      14,  #  ︷ gc=Ps   sc=Common     PRESENTATION FORM FOR VERTICAL LEFT CURLY BRACKET
    0x00FE38 =>     324,  #  ︸ gc=Pe   sc=Common     PRESENTATION FORM FOR VERTICAL RIGHT CURLY BRACKET
    0x00298F =>       2,  #  ⦏  gc=Ps   sc=Common     LEFT SQUARE BRACKET WITH TICK IN BOTTOM CORNER
    0x003008 =>     574,  #  〈 gc=Ps   sc=Common     LEFT ANGLE BRACKET
    0x002329 =>    3761,  #  〈 gc=Ps   sc=Common     LEFT-POINTING ANGLE BRACKET
    0x00FE3F =>       1,  #  ︿ gc=Ps   sc=Common     PRESENTATION FORM FOR VERTICAL LEFT ANGLE BRACKET
    0x003009 =>     597,  #  〉 gc=Pe   sc=Common     RIGHT ANGLE BRACKET
    0x00232A =>    3920,  #  〉 gc=Pe   sc=Common     RIGHT-POINTING ANGLE BRACKET
    0x003014 =>       3,  #  〔 gc=Ps   sc=Common     LEFT TORTOISE SHELL BRACKET
    0x003015 =>       3,  #  〕 gc=Pe   sc=Common     RIGHT TORTOISE SHELL BRACKET
    0x00301A =>       7,  #  〚 gc=Ps   sc=Common     LEFT WHITE SQUARE BRACKET
    0x00301B =>       7,  #  〛 gc=Pe   sc=Common     RIGHT WHITE SQUARE BRACKET
    0x0000A7 =>   21055,  #  §  gc=So   sc=Common     SECTION SIGN
    0x0000B6 =>    7433,  #  ¶  gc=So   sc=Common     PILCROW SIGN
    0x0000A9 =>  143225,  #  ©  gc=So   sc=Common     COPYRIGHT SIGN
    0x0000AE =>   63149,  #  ®  gc=So   sc=Common     REGISTERED SIGN
    0x00204E =>    3294,  #  ⁎  gc=Po   sc=Common     LOW ASTERISK
    0x002044 =>      13,  #  ⁄  gc=Sm   sc=Common     FRACTION SLASH
    0x00FF06 =>       4,  #  ＆ gc=Po   sc=Common     FULLWIDTH AMPERSAND
    0x002030 =>    1535,  #  ‰  gc=Po   sc=Common     PER MILLE SIGN
    0x002031 =>      62,  #  ‱  gc=Po   sc=Common     PER TEN THOUSAND SIGN
    0x002020 =>   60549,  #  †  gc=Po   sc=Common     DAGGER
    0x002021 =>   30763,  #  ‡  gc=Po   sc=Common     DOUBLE DAGGER
    0x002022 =>   85746,  #  •  gc=Po   sc=Common     BULLET
    0x002023 =>      21,  #  ‣  gc=Po   sc=Common     TRIANGULAR BULLET
    0x002027 =>      16,  #  ‧  gc=Po   sc=Common     HYPHENATION POINT
    0x002043 =>       1,  #  ⁃  gc=Po   sc=Common     HYPHEN BULLET
    0x002032 =>  359852,  #  ′  gc=Po   sc=Common     PRIME
    0x002033 =>    5714,  #  ″  gc=Po   sc=Common     DOUBLE PRIME
    0x002034 =>     176,  #  ‴  gc=Po   sc=Common     TRIPLE PRIME
    0x002035 =>      29,  #  ‵  gc=Po   sc=Common     REVERSED PRIME
    0x002037 =>       1,  #  ‷  gc=Po   sc=Common     REVERSED TRIPLE PRIME
    0x002038 =>      10,  #  ‸  gc=Po   sc=Common     CARET
    0x00203B =>      38,  #  ※  gc=Po   sc=Common     REFERENCE MARK
    0x00203F =>       1,  #  ‿  gc=Pc   sc=Common     UNDERTIE
    0x002041 =>      48,  #  ⁁  gc=Po   sc=Common     CARET INSERTION POINT
    0x0005BE =>       2,  #  ־  gc=Pd   sc=Hebrew     HEBREW PUNCTUATION MAQAF
    0x000F09 =>       1,  #  ༉  gc=Po   sc=Tibetan    TIBETAN MARK BSKUR YIG MGO
    0x0002B9 =>       3,  #  ʹ  gc=Lm   sc=Common     MODIFIER LETTER PRIME
    0x0002BA =>       3,  #  ʺ  gc=Lm   sc=Common     MODIFIER LETTER DOUBLE PRIME
    0x0002C3 =>       2,  #  ˃  gc=Sk   sc=Common     MODIFIER LETTER RIGHT ARROWHEAD
    0x0002C4 =>      18,  #  ˄  gc=Sk   sc=Common     MODIFIER LETTER UP ARROWHEAD
    0x0002C6 =>    2236,  #  ˆ  gc=Lm   sc=Common     MODIFIER LETTER CIRCUMFLEX ACCENT
    0x0002C7 =>      30,  #  ˇ  gc=Lm   sc=Common     CARON
    0x0002C9 =>      17,  #  ˉ  gc=Lm   sc=Common     MODIFIER LETTER MACRON
    0x0002CB =>       1,  #  ˋ  gc=Lm   sc=Common     MODIFIER LETTER GRAVE ACCENT
    0x00A719 =>      25,  #  ꜙ  gc=Lm   sc=Common     MODIFIER LETTER DOT HORIZONTAL BAR
    0x0000B0 =>  462505,  #  °  gc=So   sc=Common     DEGREE SIGN
    0x002103 =>    4992,  #  ℃  gc=So   sc=Common     DEGREE CELSIUS
    0x002109 =>       7,  #  ℉  gc=So   sc=Common     DEGREE FAHRENHEIT
    0x002117 =>       4,  #  ℗  gc=So   sc=Common     SOUND RECORDING COPYRIGHT
    0x002118 =>     459,  #  ℘  gc=Sm   sc=Common     SCRIPT CAPITAL P
    0x00211E =>       2,  #  ℞  gc=So   sc=Common     PRESCRIPTION TAKE
    0x00212E =>       1,  #  ℮  gc=So   sc=Common     ESTIMATED SYMBOL
    0x002190 =>    2765,  #  ←  gc=Sm   sc=Common     LEFTWARDS ARROW
    0x002192 =>   48480,  #  →  gc=Sm   sc=Common     RIGHTWARDS ARROW
    0x00219B =>      11,  #  ↛  gc=Sm   sc=Common     RIGHTWARDS ARROW WITH STROKE
    0x002191 =>   11349,  #  ↑  gc=Sm   sc=Common     UPWARDS ARROW
    0x002193 =>   12195,  #  ↓  gc=Sm   sc=Common     DOWNWARDS ARROW
    0x002194 =>    2957,  #  ↔  gc=Sm   sc=Common     LEFT RIGHT ARROW
    0x0021AE =>       1,  #  ↮  gc=Sm   sc=Common     LEFT RIGHT ARROW WITH STROKE
    0x002195 =>      49,  #  ↕  gc=So   sc=Common     UP DOWN ARROW
    0x002196 =>       8,  #  ↖  gc=So   sc=Common     NORTH WEST ARROW
    0x002197 =>      58,  #  ↗  gc=So   sc=Common     NORTH EAST ARROW
    0x002198 =>     105,  #  ↘  gc=So   sc=Common     SOUTH EAST ARROW
    0x002199 =>      11,  #  ↙  gc=So   sc=Common     SOUTH WEST ARROW
    0x00219D =>       2,  #  ↝  gc=So   sc=Common     RIGHTWARDS WAVE ARROW
    0x00219E =>       1,  #  ↞  gc=So   sc=Common     LEFTWARDS TWO HEADED ARROW
    0x0021A0 =>       5,  #  ↠  gc=Sm   sc=Common     RIGHTWARDS TWO HEADED ARROW
    0x0021A1 =>       5,  #  ↡  gc=So   sc=Common     DOWNWARDS TWO HEADED ARROW
    0x0021A3 =>       1,  #  ↣  gc=Sm   sc=Common     RIGHTWARDS ARROW WITH TAIL
    0x0021A6 =>     160,  #  ↦  gc=Sm   sc=Common     RIGHTWARDS ARROW FROM BAR
    0x0021AA =>      30,  #  ↪  gc=So   sc=Common     RIGHTWARDS ARROW WITH HOOK
    0x0021AD =>       2,  #  ↭  gc=So   sc=Common     LEFT RIGHT WAVE ARROW
    0x0021B1 =>       3,  #  ↱  gc=So   sc=Common     UPWARDS ARROW WITH TIP RIGHTWARDS
    0x0021C0 =>     133,  #  ⇀  gc=So   sc=Common     RIGHTWARDS HARPOON WITH BARB UPWARDS
    0x0021C4 =>      87,  #  ⇄  gc=So   sc=Common     RIGHTWARDS ARROW OVER LEFTWARDS ARROW
    0x0021C6 =>      59,  #  ⇆  gc=So   sc=Common     LEFTWARDS ARROW OVER RIGHTWARDS ARROW
    0x0021C7 =>       1,  #  ⇇  gc=So   sc=Common     LEFTWARDS PAIRED ARROWS
    0x0021C9 =>       2,  #  ⇉  gc=So   sc=Common     RIGHTWARDS PAIRED ARROWS
    0x0021CB =>     156,  #  ⇋  gc=So   sc=Common     LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON
    0x0021CC =>     276,  #  ⇌  gc=So   sc=Common     RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
    0x0021D0 =>     117,  #  ⇐  gc=So   sc=Common     LEFTWARDS DOUBLE ARROW
    0x0021D1 =>     154,  #  ⇑  gc=So   sc=Common     UPWARDS DOUBLE ARROW
    0x0021D2 =>    1032,  #  ⇒  gc=Sm   sc=Common     RIGHTWARDS DOUBLE ARROW
    0x0021D3 =>     228,  #  ⇓  gc=So   sc=Common     DOWNWARDS DOUBLE ARROW
    0x0021D4 =>     619,  #  ⇔  gc=Sm   sc=Common     LEFT RIGHT DOUBLE ARROW
    0x0021CE =>       1,  #  ⇎  gc=Sm   sc=Common     LEFT RIGHT DOUBLE ARROW WITH STROKE
    0x0021D7 =>       1,  #  ⇗  gc=So   sc=Common     NORTH EAST DOUBLE ARROW
    0x0021D8 =>       1,  #  ⇘  gc=So   sc=Common     SOUTH EAST DOUBLE ARROW
    0x0021DD =>      13,  #  ⇝  gc=So   sc=Common     RIGHTWARDS SQUIGGLE ARROW
    0x0021DE =>       1,  #  ⇞  gc=So   sc=Common     UPWARDS ARROW WITH DOUBLE STROKE
    0x0021DF =>       1,  #  ⇟  gc=So   sc=Common     DOWNWARDS ARROW WITH DOUBLE STROKE
    0x0021E7 =>      14,  #  ⇧  gc=So   sc=Common     UPWARDS WHITE ARROW
    0x0021E8 =>      47,  #  ⇨  gc=So   sc=Common     RIGHTWARDS WHITE ARROW
    0x0021E9 =>      12,  #  ⇩  gc=So   sc=Common     DOWNWARDS WHITE ARROW
    0x002200 =>    1204,  #  ∀  gc=Sm   sc=Common     FOR ALL
    0x002201 =>       1,  #  ∁  gc=Sm   sc=Common     COMPLEMENT
    0x002202 =>    6096,  #  ∂  gc=Sm   sc=Common     PARTIAL DIFFERENTIAL
    0x002204 =>      16,  #  ∄  gc=Sm   sc=Common     THERE DOES NOT EXIST
    0x002203 =>     216,  #  ∃  gc=Sm   sc=Common     THERE EXISTS
    0x002205 =>    1040,  #  ∅  gc=Sm   sc=Common     EMPTY SET
    0x002206 =>    1576,  #  ∆  gc=Sm   sc=Common     INCREMENT
    0x002207 =>    1564,  #  ∇  gc=Sm   sc=Common     NABLA
    0x002208 =>   15033,  #  ∈  gc=Sm   sc=Common     ELEMENT OF
    0x002209 =>     417,  #  ∉  gc=Sm   sc=Common     NOT AN ELEMENT OF
    0x00220A =>     455,  #  ∊  gc=Sm   sc=Common     SMALL ELEMENT OF
    0x00220B =>      27,  #  ∋  gc=Sm   sc=Common     CONTAINS AS MEMBER
    0x00220C =>       1,  #  ∌  gc=Sm   sc=Common     DOES NOT CONTAIN AS MEMBER
    0x00220D =>       3,  #  ∍  gc=Sm   sc=Common     SMALL CONTAINS AS MEMBER
    0x00220F =>    2159,  #  ∏  gc=Sm   sc=Common     N-ARY PRODUCT
    0x002211 =>   23572,  #  ∑  gc=Sm   sc=Common     N-ARY SUMMATION
    0x00207A =>      24,  #  ⁺  gc=Sm   sc=Common     SUPERSCRIPT PLUS SIGN
    0x0000B1 => 1009762,  #  ±  gc=Sm   sc=Common     PLUS-MINUS SIGN
    0x0000F7 =>     756,  #  ÷  gc=Sm   sc=Common     DIVISION SIGN
    0x0000D7 =>  350506,  #  ×  gc=Sm   sc=Common     MULTIPLICATION SIGN
    0x00226E =>       8,  #  ≮  gc=Sm   sc=Common     NOT LESS-THAN
    0x00FF1C =>       1,  #  ＜ gc=Sm   sc=Common     FULLWIDTH LESS-THAN SIGN
    0x002260 =>    4846,  #  ≠  gc=Sm   sc=Common     NOT EQUAL TO
    0x00FF1D =>       1,  #  ＝ gc=Sm   sc=Common     FULLWIDTH EQUALS SIGN
    0x00FE65 =>       1,  #  ﹥ gc=Sm   sc=Common     SMALL GREATER-THAN SIGN
    0x0000AC =>     377,  #  ¬  gc=Sm   sc=Common     NOT SIGN
    0x0000A6 =>      29,  #  ¦  gc=So   sc=Common     BROKEN BAR
    0x002016 =>    2982,  #  ‖  gc=Po   sc=Common     DOUBLE VERTICAL LINE
    0x00FF5E =>       1,  #  ～ gc=Sm   sc=Common     FULLWIDTH TILDE
    0x002212 =>  784139,  #  −  gc=Sm   sc=Common     MINUS SIGN
    0x002213 =>      78,  #  ∓  gc=Sm   sc=Common     MINUS-OR-PLUS SIGN
    0x002215 =>       1,  #  ∕  gc=Sm   sc=Common     DIVISION SLASH
    0x002216 =>     125,  #  ∖  gc=Sm   sc=Common     SET MINUS
    0x002217 =>    7734,  #  ∗  gc=Sm   sc=Common     ASTERISK OPERATOR
    0x002218 =>    1176,  #  ∘  gc=Sm   sc=Common     RING OPERATOR
    0x002219 =>     302,  #  ∙  gc=Sm   sc=Common     BULLET OPERATOR
    0x00221A =>    6937,  #  √  gc=Sm   sc=Common     SQUARE ROOT
    0x00221D =>    1136,  #  ∝  gc=Sm   sc=Common     PROPORTIONAL TO
    0x00221E =>    7509,  #  ∞  gc=Sm   sc=Common     INFINITY
    0x00221F =>       7,  #  ∟  gc=Sm   sc=Common     RIGHT ANGLE
    0x002220 =>     123,  #  ∠  gc=Sm   sc=Common     ANGLE
    0x002221 =>       2,  #  ∡  gc=Sm   sc=Common     MEASURED ANGLE
    0x002222 =>       4,  #  ∢  gc=Sm   sc=Common     SPHERICAL ANGLE
    0x002223 =>    2735,  #  ∣  gc=Sm   sc=Common     DIVIDES
    0x002224 =>       2,  #  ∤  gc=Sm   sc=Common     DOES NOT DIVIDE
    0x002226 =>       7,  #  ∦  gc=Sm   sc=Common     NOT PARALLEL TO
    0x002225 =>    1932,  #  ∥  gc=Sm   sc=Common     PARALLEL TO
    0x002227 =>    1432,  #  ∧  gc=Sm   sc=Common     LOGICAL AND
    0x002228 =>     359,  #  ∨  gc=Sm   sc=Common     LOGICAL OR
    0x002229 =>    1721,  #  ∩  gc=Sm   sc=Common     INTERSECTION
    0x00222A =>    1727,  #  ∪  gc=Sm   sc=Common     UNION
    0x00222B =>    3699,  #  ∫  gc=Sm   sc=Common     INTEGRAL
    0x00222C =>      57,  #  ∬  gc=Sm   sc=Common     DOUBLE INTEGRAL
    0x00222D =>       6,  #  ∭  gc=Sm   sc=Common     TRIPLE INTEGRAL
    0x00222E =>      14,  #  ∮  gc=Sm   sc=Common     CONTOUR INTEGRAL
    0x002232 =>       2,  #  ∲  gc=Sm   sc=Common     CLOCKWISE CONTOUR INTEGRAL
    0x002234 =>      13,  #  ∴  gc=Sm   sc=Common     THEREFORE
    0x002235 =>       1,  #  ∵  gc=Sm   sc=Common     BECAUSE
    0x002236 =>   36935,  #  ∶  gc=Sm   sc=Common     RATIO
    0x002237 =>    1405,  #  ∷  gc=Sm   sc=Common     PROPORTION
    0x002241 =>       2,  #  ≁  gc=Sm   sc=Common     NOT TILDE
    0x00223C =>   85341,  #  ∼  gc=Sm   sc=Common     TILDE OPERATOR
    0x00223D =>       4,  #  ∽  gc=Sm   sc=Common     REVERSED TILDE
    0x00223F =>       1,  #  ∿  gc=Sm   sc=Common     SINE WAVE
    0x002242 =>       1,  #  ≂  gc=Sm   sc=Common     MINUS TILDE
    0x002243 =>     536,  #  ≃  gc=Sm   sc=Common     ASYMPTOTICALLY EQUAL TO
    0x002245 =>     708,  #  ≅  gc=Sm   sc=Common     APPROXIMATELY EQUAL TO
    0x002246 =>      10,  #  ≆  gc=Sm   sc=Common     APPROXIMATELY BUT NOT ACTUALLY EQUAL TO
    0x002248 =>   12106,  #  ≈  gc=Sm   sc=Common     ALMOST EQUAL TO
    0x002249 =>       1,  #  ≉  gc=Sm   sc=Common     NOT ALMOST EQUAL TO
    0x00224A =>       6,  #  ≊  gc=Sm   sc=Common     ALMOST EQUAL OR EQUAL TO
    0x00224C =>       9,  #  ≌  gc=Sm   sc=Common     ALL EQUAL TO
    0x00224D =>      27,  #  ≍  gc=Sm   sc=Common     EQUIVALENT TO
    0x00224E =>       1,  #  ≎  gc=Sm   sc=Common     GEOMETRICALLY EQUIVALENT TO
    0x002250 =>      12,  #  ≐  gc=Sm   sc=Common     APPROACHES THE LIMIT
    0x002251 =>       2,  #  ≑  gc=Sm   sc=Common     GEOMETRICALLY EQUAL TO
    0x002252 =>       6,  #  ≒  gc=Sm   sc=Common     APPROXIMATELY EQUAL TO OR THE IMAGE OF
    0x002254 =>      97,  #  ≔  gc=Sm   sc=Common     COLON EQUALS
    0x002255 =>       4,  #  ≕  gc=Sm   sc=Common     EQUALS COLON
    0x002259 =>      12,  #  ≙  gc=Sm   sc=Common     ESTIMATES
    0x00225C =>      97,  #  ≜  gc=Sm   sc=Common     DELTA EQUAL TO
    0x002261 =>    3091,  #  ≡  gc=Sm   sc=Common     IDENTICAL TO
    0x002262 =>       1,  #  ≢  gc=Sm   sc=Common     NOT IDENTICAL TO
    0x002264 =>   70789,  #  ≤  gc=Sm   sc=Common     LESS-THAN OR EQUAL TO
    0x002270 =>      10,  #  ≰  gc=Sm   sc=Common     NEITHER LESS-THAN NOR EQUAL TO
    0x002265 =>  101964,  #  ≥  gc=Sm   sc=Common     GREATER-THAN OR EQUAL TO
    0x002266 =>     324,  #  ≦  gc=Sm   sc=Common     LESS-THAN OVER EQUAL TO
    0x002267 =>     503,  #  ≧  gc=Sm   sc=Common     GREATER-THAN OVER EQUAL TO
    0x002268 =>       4,  #  ≨  gc=Sm   sc=Common     LESS-THAN BUT NOT EQUAL TO
    0x00226A =>    1172,  #  ≪  gc=Sm   sc=Common     MUCH LESS-THAN
    0x00226B =>     992,  #  ≫  gc=Sm   sc=Common     MUCH GREATER-THAN
    0x002272 =>      71,  #  ≲  gc=Sm   sc=Common     LESS-THAN OR EQUIVALENT TO
    0x002273 =>      52,  #  ≳  gc=Sm   sc=Common     GREATER-THAN OR EQUIVALENT TO
    0x002276 =>       1,  #  ≶  gc=Sm   sc=Common     LESS-THAN OR GREATER-THAN
    0x002278 =>       5,  #  ≸  gc=Sm   sc=Common     NEITHER LESS-THAN NOR GREATER-THAN
    0x002277 =>       3,  #  ≷  gc=Sm   sc=Common     GREATER-THAN OR LESS-THAN
    0x002279 =>       3,  #  ≹  gc=Sm   sc=Common     NEITHER GREATER-THAN NOR LESS-THAN
    0x00227A =>     157,  #  ≺  gc=Sm   sc=Common     PRECEDES
    0x002281 =>       1,  #  ⊁  gc=Sm   sc=Common     DOES NOT SUCCEED
    0x00227B =>      32,  #  ≻  gc=Sm   sc=Common     SUCCEEDS
    0x00227C =>      24,  #  ≼  gc=Sm   sc=Common     PRECEDES OR EQUAL TO
    0x00227D =>      49,  #  ≽  gc=Sm   sc=Common     SUCCEEDS OR EQUAL TO
    0x00227E =>       4,  #  ≾  gc=Sm   sc=Common     PRECEDES OR EQUIVALENT TO
    0x002284 =>       8,  #  ⊄  gc=Sm   sc=Common     NOT A SUBSET OF
    0x002282 =>     594,  #  ⊂  gc=Sm   sc=Common     SUBSET OF
    0x002283 =>      79,  #  ⊃  gc=Sm   sc=Common     SUPERSET OF
    0x002288 =>       4,  #  ⊈  gc=Sm   sc=Common     NEITHER A SUBSET OF NOR EQUAL TO
    0x002286 =>     754,  #  ⊆  gc=Sm   sc=Common     SUBSET OF OR EQUAL TO
    0x002287 =>      29,  #  ⊇  gc=Sm   sc=Common     SUPERSET OF OR EQUAL TO
    0x00228A =>       3,  #  ⊊  gc=Sm   sc=Common     SUBSET OF WITH NOT EQUAL TO
    0x00228B =>       2,  #  ⊋  gc=Sm   sc=Common     SUPERSET OF WITH NOT EQUAL TO
    0x00228D =>       2,  #  ⊍  gc=Sm   sc=Common     MULTISET MULTIPLICATION
    0x00228F =>       3,  #  ⊏  gc=Sm   sc=Common     SQUARE IMAGE OF
    0x002291 =>      25,  #  ⊑  gc=Sm   sc=Common     SQUARE IMAGE OF OR EQUAL TO
    0x002293 =>      74,  #  ⊓  gc=Sm   sc=Common     SQUARE CAP
    0x002294 =>       8,  #  ⊔  gc=Sm   sc=Common     SQUARE CUP
    0x002295 =>     445,  #  ⊕  gc=Sm   sc=Common     CIRCLED PLUS
    0x002296 =>     183,  #  ⊖  gc=Sm   sc=Common     CIRCLED MINUS
    0x002297 =>     560,  #  ⊗  gc=Sm   sc=Common     CIRCLED TIMES
    0x002298 =>      82,  #  ⊘  gc=Sm   sc=Common     CIRCLED DIVISION SLASH
    0x002299 =>      43,  #  ⊙  gc=Sm   sc=Common     CIRCLED DOT OPERATOR
    0x00229A =>       2,  #  ⊚  gc=Sm   sc=Common     CIRCLED RING OPERATOR
    0x00229B =>       4,  #  ⊛  gc=Sm   sc=Common     CIRCLED ASTERISK OPERATOR
    0x00229D =>       3,  #  ⊝  gc=Sm   sc=Common     CIRCLED DASH
    0x00229F =>      22,  #  ⊟  gc=Sm   sc=Common     SQUARED MINUS
    0x0022A0 =>       7,  #  ⊠  gc=Sm   sc=Common     SQUARED TIMES
    0x0022A1 =>       4,  #  ⊡  gc=Sm   sc=Common     SQUARED DOT OPERATOR
    0x0022A2 =>      51,  #  ⊢  gc=Sm   sc=Common     RIGHT TACK
    0x0022A3 =>     153,  #  ⊣  gc=Sm   sc=Common     LEFT TACK
    0x0022A4 =>     473,  #  ⊤  gc=Sm   sc=Common     DOWN TACK
    0x0022A5 =>     687,  #  ⊥  gc=Sm   sc=Common     UP TACK
    0x0022A7 =>      23,  #  ⊧  gc=Sm   sc=Common     MODELS
    0x0022AA =>       3,  #  ⊪  gc=Sm   sc=Common     TRIPLE VERTICAL BAR RIGHT TURNSTILE
    0x0022B2 =>       1,  #  ⊲  gc=Sm   sc=Common     NORMAL SUBGROUP OF
    0x0022B8 =>       2,  #  ⊸  gc=Sm   sc=Common     MULTIMAP
    0x0022BF =>       8,  #  ⊿  gc=Sm   sc=Common     RIGHT TRIANGLE
    0x0022C0 =>      77,  #  ⋀  gc=Sm   sc=Common     N-ARY LOGICAL AND
    0x0022C1 =>       2,  #  ⋁  gc=Sm   sc=Common     N-ARY LOGICAL OR
    0x0022C2 =>      88,  #  ⋂  gc=Sm   sc=Common     N-ARY INTERSECTION
    0x0022C3 =>      69,  #  ⋃  gc=Sm   sc=Common     N-ARY UNION
    0x0022C4 =>     207,  #  ⋄  gc=Sm   sc=Common     DIAMOND OPERATOR
    0x0022C5 =>    6578,  #  ⋅  gc=Sm   sc=Common     DOT OPERATOR
    0x0022C6 =>     185,  #  ⋆  gc=Sm   sc=Common     STAR OPERATOR
    0x0022C7 =>       3,  #  ⋇  gc=Sm   sc=Common     DIVISION TIMES
    0x0022C8 =>       1,  #  ⋈  gc=Sm   sc=Common     BOWTIE
    0x0022CD =>       5,  #  ⋍  gc=Sm   sc=Common     REVERSED TILDE EQUALS
    0x0022CE =>       1,  #  ⋎  gc=Sm   sc=Common     CURLY LOGICAL OR
    0x0022D2 =>       1,  #  ⋒  gc=Sm   sc=Common     DOUBLE INTERSECTION
    0x0022D4 =>      15,  #  ⋔  gc=Sm   sc=Common     PITCHFORK
    0x0022D8 =>       3,  #  ⋘  gc=Sm   sc=Common     VERY MUCH LESS-THAN
    0x0022D9 =>      13,  #  ⋙  gc=Sm   sc=Common     VERY MUCH GREATER-THAN
    0x0022DB =>       3,  #  ⋛  gc=Sm   sc=Common     GREATER-THAN EQUAL TO OR LESS-THAN
    0x0022E8 =>       1,  #  ⋨  gc=Sm   sc=Common     PRECEDES BUT NOT EQUIVALENT TO
    0x0022EE =>    1123,  #  ⋮  gc=Sm   sc=Common     VERTICAL ELLIPSIS
    0x0022EF =>    3568,  #  ⋯  gc=Sm   sc=Common     MIDLINE HORIZONTAL ELLIPSIS
    0x0022F1 =>     197,  #  ⋱  gc=Sm   sc=Common     DOWN RIGHT DIAGONAL ELLIPSIS
    0x002300 =>       1,  #  ⌀  gc=So   sc=Common     DIAMETER SIGN
    0x002302 =>       5,  #  ⌂  gc=So   sc=Common     HOUSE
    0x002306 =>      13,  #  ⌆  gc=So   sc=Common     PERSPECTIVE
    0x002308 =>     127,  #  ⌈  gc=Sm   sc=Common     LEFT CEILING
    0x002309 =>     134,  #  ⌉  gc=Sm   sc=Common     RIGHT CEILING
    0x00230A =>     307,  #  ⌊  gc=Sm   sc=Common     LEFT FLOOR
    0x00230B =>     295,  #  ⌋  gc=Sm   sc=Common     RIGHT FLOOR
    0x00230C =>       2,  #  ⌌  gc=So   sc=Common     BOTTOM RIGHT CROP
    0x002313 =>     156,  #  ⌓  gc=So   sc=Common     SEGMENT
    0x002314 =>       4,  #  ⌔  gc=So   sc=Common     SECTOR
    0x002316 =>       5,  #  ⌖  gc=So   sc=Common     POSITION INDICATOR
    0x00231D =>      11,  #  ⌝  gc=So   sc=Common     TOP RIGHT CORNER
    0x00231E =>      29,  #  ⌞  gc=So   sc=Common     BOTTOM LEFT CORNER
    0x00231F =>      29,  #  ⌟  gc=So   sc=Common     BOTTOM RIGHT CORNER
    0x002320 =>       1,  #  ⌠  gc=Sm   sc=Common     TOP HALF INTEGRAL
    0x002322 =>     142,  #  ⌢  gc=So   sc=Common     FROWN
    0x002323 =>     121,  #  ⌣  gc=So   sc=Common     SMILE
    0x002337 =>      11,  #  ⌷  gc=So   sc=Common     APL FUNCTIONAL SYMBOL SQUISH QUAD
    0x002342 =>       3,  #  ⍂  gc=So   sc=Common     APL FUNCTIONAL SYMBOL QUAD BACKSLASH
    0x0023B4 =>      27,  #  ⎴  gc=So   sc=Common     TOP SQUARE BRACKET
    0x002423 =>      38,  #  ␣  gc=So   sc=Common     OPEN BOX
    0x002500 =>      26,  #  ─  gc=So   sc=Common     BOX DRAWINGS LIGHT HORIZONTAL
    0x002501 =>       2,  #  ━  gc=So   sc=Common     BOX DRAWINGS HEAVY HORIZONTAL
    0x002502 =>      52,  #  │  gc=So   sc=Common     BOX DRAWINGS LIGHT VERTICAL
    0x002504 =>       2,  #  ┄  gc=So   sc=Common     BOX DRAWINGS LIGHT TRIPLE DASH HORIZONTAL
    0x002514 =>       1,  #  └  gc=So   sc=Common     BOX DRAWINGS LIGHT UP AND RIGHT
    0x002524 =>      11,  #  ┤  gc=So   sc=Common     BOX DRAWINGS LIGHT VERTICAL AND LEFT
    0x00252C =>       4,  #  ┬  gc=So   sc=Common     BOX DRAWINGS LIGHT DOWN AND HORIZONTAL
    0x002534 =>       4,  #  ┴  gc=So   sc=Common     BOX DRAWINGS LIGHT UP AND HORIZONTAL
    0x00253C =>      32,  #  ┼  gc=So   sc=Common     BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL
    0x002540 =>       1,  #  ╀  gc=So   sc=Common     BOX DRAWINGS UP HEAVY AND DOWN HORIZONTAL LIGHT
    0x002550 =>       2,  #  ═  gc=So   sc=Common     BOX DRAWINGS DOUBLE HORIZONTAL
    0x002551 =>      67,  #  ║  gc=So   sc=Common     BOX DRAWINGS DOUBLE VERTICAL
    0x002559 =>       7,  #  ╙  gc=So   sc=Common     BOX DRAWINGS UP DOUBLE AND RIGHT SINGLE
    0x00255E =>      17,  #  ╞  gc=So   sc=Common     BOX DRAWINGS VERTICAL SINGLE AND RIGHT DOUBLE
    0x002560 =>      10,  #  ╠  gc=So   sc=Common     BOX DRAWINGS DOUBLE VERTICAL AND RIGHT
    0x002564 =>       4,  #  ╤  gc=So   sc=Common     BOX DRAWINGS DOWN SINGLE AND HORIZONTAL DOUBLE
    0x002566 =>       2,  #  ╦  gc=So   sc=Common     BOX DRAWINGS DOUBLE DOWN AND HORIZONTAL
    0x002568 =>      14,  #  ╨  gc=So   sc=Common     BOX DRAWINGS UP DOUBLE AND HORIZONTAL SINGLE
    0x00256A =>       8,  #  ╪  gc=So   sc=Common     BOX DRAWINGS VERTICAL SINGLE AND HORIZONTAL DOUBLE
    0x00256B =>      25,  #  ╫  gc=So   sc=Common     BOX DRAWINGS VERTICAL DOUBLE AND HORIZONTAL SINGLE
    0x00256C =>       2,  #  ╬  gc=So   sc=Common     BOX DRAWINGS DOUBLE VERTICAL AND HORIZONTAL
    0x00257A =>       1,  #  ╺  gc=So   sc=Common     BOX DRAWINGS HEAVY RIGHT
    0x002580 =>      16,  #  ▀  gc=So   sc=Common     UPPER HALF BLOCK
    0x002584 =>       1,  #  ▄  gc=So   sc=Common     LOWER HALF BLOCK
    0x002588 =>       9,  #  █  gc=So   sc=Common     FULL BLOCK
    0x002591 =>      39,  #  ░  gc=So   sc=Common     LIGHT SHADE
    0x002592 =>     116,  #  ▒  gc=So   sc=Common     MEDIUM SHADE
    0x002593 =>       9,  #  ▓  gc=So   sc=Common     DARK SHADE
    0x0025A0 =>    2988,  #  ■  gc=So   sc=Common     BLACK SQUARE
    0x0025A1 =>    6011,  #  □  gc=So   sc=Common     WHITE SQUARE
    0x0025A2 =>      37,  #  ▢  gc=So   sc=Common     WHITE SQUARE WITH ROUNDED CORNERS
    0x0025A4 =>      11,  #  ▤  gc=So   sc=Common     SQUARE WITH HORIZONTAL FILL
    0x0025A5 =>       3,  #  ▥  gc=So   sc=Common     SQUARE WITH VERTICAL FILL
    0x0025A7 =>      12,  #  ▧  gc=So   sc=Common     SQUARE WITH UPPER LEFT TO LOWER RIGHT FILL
    0x0025A8 =>      30,  #  ▨  gc=So   sc=Common     SQUARE WITH UPPER RIGHT TO LOWER LEFT FILL
    0x0025A9 =>      22,  #  ▩  gc=So   sc=Common     SQUARE WITH DIAGONAL CROSSHATCH FILL
    0x0025AA =>    7528,  #  ▪  gc=So   sc=Common     BLACK SMALL SQUARE
    0x0025AB =>     338,  #  ▫  gc=So   sc=Common     WHITE SMALL SQUARE
    0x0025AC =>      39,  #  ▬  gc=So   sc=Common     BLACK RECTANGLE
    0x0025AD =>      10,  #  ▭  gc=So   sc=Common     WHITE RECTANGLE
    0x0025AE =>       7,  #  ▮  gc=So   sc=Common     BLACK VERTICAL RECTANGLE
    0x0025AF =>      97,  #  ▯  gc=So   sc=Common     WHITE VERTICAL RECTANGLE
    0x0025B1 =>       2,  #  ▱  gc=So   sc=Common     WHITE PARALLELOGRAM
    0x0025B2 =>    1536,  #  ▲  gc=So   sc=Common     BLACK UP-POINTING TRIANGLE
    0x0025B3 =>     698,  #  △  gc=So   sc=Common     WHITE UP-POINTING TRIANGLE
    0x0025B4 =>    1177,  #  ▴  gc=So   sc=Common     BLACK UP-POINTING SMALL TRIANGLE
    0x0025B5 =>    1055,  #  ▵  gc=So   sc=Common     WHITE UP-POINTING SMALL TRIANGLE
    0x0025B6 =>   17388,  #  ▶  gc=So   sc=Common     BLACK RIGHT-POINTING TRIANGLE
    0x0025B7 =>      36,  #  ▷  gc=Sm   sc=Common     WHITE RIGHT-POINTING TRIANGLE
    0x0025B8 =>     154,  #  ▸  gc=So   sc=Common     BLACK RIGHT-POINTING SMALL TRIANGLE
    0x0025B9 =>      89,  #  ▹  gc=So   sc=Common     WHITE RIGHT-POINTING SMALL TRIANGLE
    0x0025BA =>     119,  #  ►  gc=So   sc=Common     BLACK RIGHT-POINTING POINTER
    0x0025BB =>       1,  #  ▻  gc=So   sc=Common     WHITE RIGHT-POINTING POINTER
    0x0025BC =>     689,  #  ▼  gc=So   sc=Common     BLACK DOWN-POINTING TRIANGLE
    0x0025BD =>     150,  #  ▽  gc=So   sc=Common     WHITE DOWN-POINTING TRIANGLE
    0x0025BE =>     500,  #  ▾  gc=So   sc=Common     BLACK DOWN-POINTING SMALL TRIANGLE
    0x0025BF =>     117,  #  ▿  gc=So   sc=Common     WHITE DOWN-POINTING SMALL TRIANGLE
    0x0025C0 =>      29,  #  ◀  gc=So   sc=Common     BLACK LEFT-POINTING TRIANGLE
    0x0025C1 =>      22,  #  ◁  gc=Sm   sc=Common     WHITE LEFT-POINTING TRIANGLE
    0x0025C2 =>      57,  #  ◂  gc=So   sc=Common     BLACK LEFT-POINTING SMALL TRIANGLE
    0x0025C3 =>      40,  #  ◃  gc=So   sc=Common     WHITE LEFT-POINTING SMALL TRIANGLE
    0x0025C6 =>    1103,  #  ◆  gc=So   sc=Common     BLACK DIAMOND
    0x0025C7 =>     375,  #  ◇  gc=So   sc=Common     WHITE DIAMOND
    0x0025C8 =>       2,  #  ◈  gc=So   sc=Common     WHITE DIAMOND CONTAINING BLACK SMALL DIAMOND
    0x0025C9 =>       3,  #  ◉  gc=So   sc=Common     FISHEYE
    0x0025CA =>     408,  #  ◊  gc=So   sc=Common     LOZENGE
    0x0025CB =>    5769,  #  ○  gc=So   sc=Common     WHITE CIRCLE
    0x0025CE =>      86,  #  ◎  gc=So   sc=Common     BULLSEYE
    0x0025CF =>    3259,  #  ●  gc=So   sc=Common     BLACK CIRCLE
    0x0025D0 =>      12,  #  ◐  gc=So   sc=Common     CIRCLE WITH LEFT HALF BLACK
    0x0025D2 =>       2,  #  ◒  gc=So   sc=Common     CIRCLE WITH LOWER HALF BLACK
    0x0025D3 =>       2,  #  ◓  gc=So   sc=Common     CIRCLE WITH UPPER HALF BLACK
    0x0025D6 =>       1,  #  ◖  gc=So   sc=Common     LEFT HALF BLACK CIRCLE
    0x0025D8 =>       5,  #  ◘  gc=So   sc=Common     INVERSE BULLET
    0x0025D9 =>       5,  #  ◙  gc=So   sc=Common     INVERSE WHITE CIRCLE
    0x0025E6 =>    1303,  #  ◦  gc=So   sc=Common     WHITE BULLET
    0x0025EC =>       1,  #  ◬  gc=So   sc=Common     WHITE UP-POINTING TRIANGLE WITH DOT
    0x0025EF =>      84,  #  ◯  gc=So   sc=Common     LARGE CIRCLE
    0x0025F8 =>      17,  #  ◸  gc=Sm   sc=Common     UPPER LEFT TRIANGLE
    0x0025FB =>      54,  #  ◻  gc=Sm   sc=Common     WHITE MEDIUM SQUARE
    0x0025FC =>      69,  #  ◼  gc=Sm   sc=Common     BLACK MEDIUM SQUARE
    0x002605 =>     207,  #  ★  gc=So   sc=Common     BLACK STAR
    0x002606 =>     118,  #  ☆  gc=So   sc=Common     WHITE STAR
    0x00260D =>       2,  #  ☍  gc=So   sc=Common     OPPOSITION
    0x002610 =>     317,  #  ☐  gc=So   sc=Common     BALLOT BOX
    0x002611 =>       2,  #  ☑  gc=So   sc=Common     BALLOT BOX WITH CHECK
    0x00263A =>       1,  #  ☺  gc=So   sc=Common     WHITE SMILING FACE
    0x00263C =>       6,  #  ☼  gc=So   sc=Common     WHITE SUN WITH RAYS
    0x00263F =>       1,  #  ☿  gc=So   sc=Common     MERCURY
    0x002640 =>    1472,  #  ♀  gc=So   sc=Common     FEMALE SIGN
    0x002642 =>    1424,  #  ♂  gc=So   sc=Common     MALE SIGN
    0x002660 =>      82,  #  ♠  gc=So   sc=Common     BLACK SPADE SUIT
    0x002661 =>      23,  #  ♡  gc=So   sc=Common     WHITE HEART SUIT
    0x002662 =>       4,  #  ♢  gc=So   sc=Common     WHITE DIAMOND SUIT
    0x002663 =>     147,  #  ♣  gc=So   sc=Common     BLACK CLUB SUIT
    0x002665 =>      19,  #  ♥  gc=So   sc=Common     BLACK HEART SUIT
    0x002666 =>     808,  #  ♦  gc=So   sc=Common     BLACK DIAMOND SUIT
    0x002709 =>     677,  #  ✉  gc=So   sc=Common     ENVELOPE
    0x002713 =>    5260,  #  ✓  gc=So   sc=Common     CHECK MARK
    0x002714 =>    1072,  #  ✔  gc=So   sc=Common     HEAVY CHECK MARK
    0x002715 =>       4,  #  ✕  gc=So   sc=Common     MULTIPLICATION X
    0x002716 =>       2,  #  ✖  gc=So   sc=Common     HEAVY MULTIPLICATION X
    0x002717 =>     265,  #  ✗  gc=So   sc=Common     BALLOT X
    0x002718 =>     164,  #  ✘  gc=So   sc=Common     HEAVY BALLOT X
    0x00271A =>       3,  #  ✚  gc=So   sc=Common     HEAVY GREEK CROSS
    0x00271D =>      12,  #  ✝  gc=So   sc=Common     LATIN CROSS
    0x00271E =>       6,  #  ✞  gc=So   sc=Common     SHADOWED WHITE LATIN CROSS
    0x00271F =>       1,  #  ✟  gc=So   sc=Common     OUTLINED LATIN CROSS
    0x002720 =>      11,  #  ✠  gc=So   sc=Common     MALTESE CROSS
    0x002727 =>       6,  #  ✧  gc=So   sc=Common     WHITE FOUR POINTED STAR
    0x002729 =>       4,  #  ✩  gc=So   sc=Common     STRESS OUTLINED WHITE STAR
    0x00272E =>       1,  #  ✮  gc=So   sc=Common     HEAVY OUTLINED BLACK STAR
    0x00272F =>       2,  #  ✯  gc=So   sc=Common     PINWHEEL STAR
    0x002730 =>       2,  #  ✰  gc=So   sc=Common     SHADOWED WHITE STAR
    0x002731 =>       1,  #  ✱  gc=So   sc=Common     HEAVY ASTERISK
    0x002733 =>       7,  #  ✳  gc=So   sc=Common     EIGHT SPOKED ASTERISK
    0x002734 =>       5,  #  ✴  gc=So   sc=Common     EIGHT POINTED BLACK STAR
    0x002736 =>      15,  #  ✶  gc=So   sc=Common     SIX POINTED BLACK STAR
    0x002737 =>       1,  #  ✷  gc=So   sc=Common     EIGHT POINTED RECTILINEAR BLACK STAR
    0x002738 =>      34,  #  ✸  gc=So   sc=Common     HEAVY EIGHT POINTED RECTILINEAR BLACK STAR
    0x00273B =>       5,  #  ✻  gc=So   sc=Common     TEARDROP-SPOKED ASTERISK
    0x002748 =>       2,  #  ❈  gc=So   sc=Common     HEAVY SPARKLE
    0x00274A =>       2,  #  ❊  gc=So   sc=Common     EIGHT TEARDROP-SPOKED PROPELLER ASTERISK
    0x00274D =>       8,  #  ❍  gc=So   sc=Common     SHADOWED WHITE CIRCLE
    0x002750 =>       4,  #  ❐  gc=So   sc=Common     UPPER RIGHT DROP-SHADOWED WHITE SQUARE
    0x002751 =>      59,  #  ❑  gc=So   sc=Common     LOWER RIGHT SHADOWED WHITE SQUARE
    0x002752 =>      38,  #  ❒  gc=So   sc=Common     UPPER RIGHT SHADOWED WHITE SQUARE
    0x002756 =>      38,  #  ❖  gc=So   sc=Common     BLACK DIAMOND MINUS WHITE X
    0x002794 =>      12,  #  ➔  gc=So   sc=Common     HEAVY WIDE-HEADED RIGHTWARDS ARROW
    0x00279D =>       3,  #  ➝  gc=So   sc=Common     TRIANGLE-HEADED RIGHTWARDS ARROW
    0x00279E =>       1,  #  ➞  gc=So   sc=Common     HEAVY TRIANGLE-HEADED RIGHTWARDS ARROW
    0x0027A1 =>       2,  #  ➡  gc=So   sc=Common     BLACK RIGHTWARDS ARROW
    0x0027A2 =>     194,  #  ➢  gc=So   sc=Common     THREE-D TOP-LIGHTED RIGHTWARDS ARROWHEAD
    0x0027A4 =>       2,  #  ➤  gc=So   sc=Common     BLACK RIGHTWARDS ARROWHEAD
    0x0027E1 =>       2,  #  ⟡  gc=Sm   sc=Common     WHITE CONCAVE-SIDED DIAMOND
    0x0027E6 =>      13,  #  ⟦  gc=Ps   sc=Common     MATHEMATICAL LEFT WHITE SQUARE BRACKET
    0x0027E7 =>      13,  #  ⟧  gc=Pe   sc=Common     MATHEMATICAL RIGHT WHITE SQUARE BRACKET
    0x0027E8 =>    1152,  #  ⟨  gc=Ps   sc=Common     MATHEMATICAL LEFT ANGLE BRACKET
    0x0027E9 =>    1151,  #  ⟩  gc=Pe   sc=Common     MATHEMATICAL RIGHT ANGLE BRACKET
    0x0027F5 =>      39,  #  ⟵  gc=Sm   sc=Common     LONG LEFTWARDS ARROW
    0x0027F6 =>      40,  #  ⟶  gc=Sm   sc=Common     LONG RIGHTWARDS ARROW
    0x0027F7 =>       5,  #  ⟷  gc=Sm   sc=Common     LONG LEFT RIGHT ARROW
    0x0027F9 =>       5,  #  ⟹  gc=Sm   sc=Common     LONG RIGHTWARDS DOUBLE ARROW
    0x0027FA =>       8,  #  ⟺  gc=Sm   sc=Common     LONG LEFT RIGHT DOUBLE ARROW
    0x002919 =>       1,  #  ⤙  gc=Sm   sc=Common     LEFTWARDS ARROW-TAIL
    0x002922 =>      11,  #  ⤢  gc=Sm   sc=Common     NORTH EAST AND SOUTH WEST ARROW
    0x00292A =>       1,  #  ⤪  gc=Sm   sc=Common     SOUTH WEST ARROW AND NORTH WEST ARROW
    0x002944 =>      33,  #  ⥄  gc=Sm   sc=Common     SHORT RIGHTWARDS ARROW ABOVE LEFTWARDS ARROW
    0x0029B0 =>       1,  #  ⦰  gc=Sm   sc=Common     REVERSED EMPTY SET
    0x0029C4 =>       2,  #  ⧄  gc=Sm   sc=Common     SQUARED RISING DIAGONAL SLASH
    0x0029E7 =>      12,  #  ⧧  gc=Sm   sc=Common     THERMODYNAMIC
    0x0029EB =>      97,  #  ⧫  gc=Sm   sc=Common     BLACK LOZENGE
    0x002A11 =>       4,  #  ⨑  gc=Sm   sc=Common     ANTICLOCKWISE INTEGRATION
    0x002A46 =>       1,  #  ⩆  gc=Sm   sc=Common     UNION ABOVE INTERSECTION
    0x002A52 =>       9,  #  ⩒  gc=Sm   sc=Common     LOGICAL OR WITH DOT ABOVE
    0x002A72 =>      10,  #  ⩲  gc=Sm   sc=Common     PLUS SIGN ABOVE EQUALS SIGN
    0x002A7D =>     787,  #  ⩽  gc=Sm   sc=Common     LESS-THAN OR SLANTED EQUAL TO
    0x002A7E =>    1606,  #  ⩾  gc=Sm   sc=Common     GREATER-THAN OR SLANTED EQUAL TO
    0x002AAF =>       1,  #  ⪯  gc=Sm   sc=Common     PRECEDES ABOVE SINGLE-LINE EQUALS SIGN
    0x002AB0 =>       2,  #  ⪰  gc=Sm   sc=Common     SUCCEEDS ABOVE SINGLE-LINE EQUALS SIGN
    0x002AB7 =>       1,  #  ⪷  gc=Sm   sc=Common     PRECEDES ABOVE ALMOST EQUAL TO
    0x002ABD =>       1,  #  ⪽  gc=Sm   sc=Common     SUBSET WITH DOT
    0x002AC2 =>       4,  #  ⫂  gc=Sm   sc=Common     SUPERSET WITH MULTIPLICATION SIGN BELOW
    0x002AC5 =>       3,  #  ⫅  gc=Sm   sc=Common     SUBSET OF ABOVE EQUALS SIGN
    0x002ADE =>       1,  #  ⫞  gc=Sm   sc=Common     SHORT LEFT TACK
    0x002AEB =>       8,  #  ⫫  gc=Sm   sc=Common     DOUBLE UP TACK
    0x002AEF =>       1,  #  ⫯  gc=Sm   sc=Common     VERTICAL LINE WITH CIRCLE ABOVE
    0x002AF2 =>       3,  #  ⫲  gc=Sm   sc=Common     PARALLEL WITH HORIZONTAL STROKE
    0x002B22 =>       1,  #  ⬢  gc=So   sc=Common     BLACK HEXAGON
    0x00266D =>       2,  #  ♭  gc=So   sc=Common     MUSIC FLAT SIGN
    0x00266E =>       2,  #  ♮  gc=So   sc=Common     MUSIC NATURAL SIGN
    0x00266F =>      16,  #  ♯  gc=Sm   sc=Common     MUSIC SHARP SIGN
    0x00FFFD =>       7,  #  �  gc=So   sc=Common     REPLACEMENT CHARACTER
    0x0002D0 =>       5,  #  ː  gc=Lm   sc=Common     MODIFIER LETTER TRIANGULAR COLON
    0x0000A4 =>    7856,  #  ¤  gc=Sc   sc=Common     CURRENCY SIGN
    0x0000A2 =>     554,  #  ¢  gc=Sc   sc=Common     CENT SIGN
    0x0000A3 =>    8059,  #  £  gc=Sc   sc=Common     POUND SIGN
    0x0000A5 =>     833,  #  ¥  gc=Sc   sc=Common     YEN SIGN
    0x0020A0 =>     133,  #  ₠  gc=Sc   sc=Common     EURO-CURRENCY SIGN
    0x0020A3 =>       2,  #  ₣  gc=Sc   sc=Common     FRENCH FRANC SIGN
    0x0020A4 =>      42,  #  ₤  gc=Sc   sc=Common     LIRA SIGN
    0x0020A6 =>      23,  #  ₦  gc=Sc   sc=Common     NAIRA SIGN
    0x00FFE6 =>       1,  #  ￦ gc=Sc   sc=Common     FULLWIDTH WON SIGN
    0x0020AB =>       2,  #  ₫  gc=Sc   sc=Common     DONG SIGN
    0x0020AC =>    7517,  #  €  gc=Sc   sc=Common     EURO SIGN
    0x002080 =>       1,  #  ₀  gc=No   sc=Common     SUBSCRIPT ZERO
    0x01D7D9 =>       1,  #  𝟙  gc=Nd   sc=Common     MATHEMATICAL DOUBLE-STRUCK DIGIT ONE
    0x002460 =>      95,  #  ①  gc=No   sc=Common     CIRCLED DIGIT ONE
    0x002780 =>       1,  #  ➀  gc=No   sc=Common     DINGBAT CIRCLED SANS-SERIF DIGIT ONE
    0x002776 =>       5,  #  ❶  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED DIGIT ONE
    0x0000B9 =>      28,  #  ¹  gc=No   sc=Common     SUPERSCRIPT ONE
    0x0000BD =>    2104,  #  ½  gc=No   sc=Common     VULGAR FRACTION ONE HALF
    0x002153 =>      32,  #  ⅓  gc=No   sc=Common     VULGAR FRACTION ONE THIRD
    0x0000BC =>     400,  #  ¼  gc=No   sc=Common     VULGAR FRACTION ONE QUARTER
    0x002155 =>       4,  #  ⅕  gc=No   sc=Common     VULGAR FRACTION ONE FIFTH
    0x002159 =>       1,  #  ⅙  gc=No   sc=Common     VULGAR FRACTION ONE SIXTH
    0x00215B =>       3,  #  ⅛  gc=No   sc=Common     VULGAR FRACTION ONE EIGHTH
    0x002469 =>       3,  #  ⑩  gc=No   sc=Common     CIRCLED NUMBER TEN
    0x00246A =>       2,  #  ⑪  gc=No   sc=Common     CIRCLED NUMBER ELEVEN
    0x00246B =>       1,  #  ⑫  gc=No   sc=Common     CIRCLED NUMBER TWELVE
    0x002461 =>     115,  #  ②  gc=No   sc=Common     CIRCLED DIGIT TWO
    0x002781 =>       1,  #  ➁  gc=No   sc=Common     DINGBAT CIRCLED SANS-SERIF DIGIT TWO
    0x002777 =>       5,  #  ❷  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED DIGIT TWO
    0x002082 =>      12,  #  ₂  gc=No   sc=Common     SUBSCRIPT TWO
    0x0000B2 =>     920,  #  ²  gc=No   sc=Common     SUPERSCRIPT TWO
    0x002154 =>      16,  #  ⅔  gc=No   sc=Common     VULGAR FRACTION TWO THIRDS
    0x002462 =>      61,  #  ③  gc=No   sc=Common     CIRCLED DIGIT THREE
    0x002778 =>       3,  #  ❸  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED DIGIT THREE
    0x00278C =>      61,  #  ➌  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED SANS-SERIF DIGIT THREE
    0x002083 =>       4,  #  ₃  gc=No   sc=Common     SUBSCRIPT THREE
    0x0000B3 =>     113,  #  ³  gc=No   sc=Common     SUPERSCRIPT THREE
    0x0000BE =>     223,  #  ¾  gc=No   sc=Common     VULGAR FRACTION THREE QUARTERS
    0x0006F4 =>       5,  #  ۴  gc=Nd   sc=Arabic     EXTENDED ARABIC-INDIC DIGIT FOUR
    0x000664 =>       2,  #  ٤  gc=Nd   sc=Common     ARABIC-INDIC DIGIT FOUR
    0x002463 =>     104,  #  ④  gc=No   sc=Common     CIRCLED DIGIT FOUR
    0x002074 =>       3,  #  ⁴  gc=No   sc=Common     SUPERSCRIPT FOUR
    0x002464 =>      25,  #  ⑤  gc=No   sc=Common     CIRCLED DIGIT FIVE
    0x002784 =>       1,  #  ➄  gc=No   sc=Common     DINGBAT CIRCLED SANS-SERIF DIGIT FIVE
    0x00278E =>      12,  #  ➎  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED SANS-SERIF DIGIT FIVE
    0x002075 =>       2,  #  ⁵  gc=No   sc=Common     SUPERSCRIPT FIVE
    0x00215D =>       1,  #  ⅝  gc=No   sc=Common     VULGAR FRACTION FIVE EIGHTHS
    0x0006F6 =>       6,  #  ۶  gc=Nd   sc=Arabic     EXTENDED ARABIC-INDIC DIGIT SIX
    0x002465 =>      30,  #  ⑥  gc=No   sc=Common     CIRCLED DIGIT SIX
    0x00278F =>      13,  #  ➏  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED SANS-SERIF DIGIT SIX
    0x002466 =>      54,  #  ⑦  gc=No   sc=Common     CIRCLED DIGIT SEVEN
    0x0006F8 =>       2,  #  ۸  gc=Nd   sc=Arabic     EXTENDED ARABIC-INDIC DIGIT EIGHT
    0x002467 =>       3,  #  ⑧  gc=No   sc=Common     CIRCLED DIGIT EIGHT
    0x002791 =>      18,  #  ➑  gc=No   sc=Common     DINGBAT NEGATIVE CIRCLED SANS-SERIF DIGIT EIGHT
    0x002468 =>       7,  #  ⑨  gc=No   sc=Common     CIRCLED DIGIT NINE
    0x01D4B6 =>       7,  #  𝒶  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL A
    0x0000AA =>      72,  #  ª  gc=Ll   sc=Latin      FEMININE ORDINAL INDICATOR
    0x0000E1 =>   53068,  #  á  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH ACUTE
    0x000103 =>     805,  #  ă  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH BREVE
    0x001EAF =>      37,  #  ắ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH BREVE AND ACUTE
    0x001EB7 =>       2,  #  ặ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH BREVE AND DOT BELOW
    0x0001CE =>      12,  #  ǎ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CARON
    0x0000E2 =>    2760,  #  â  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CIRCUMFLEX
    0x001EA5 =>       1,  #  ấ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CIRCUMFLEX AND ACUTE
    0x001EAD =>      24,  #  ậ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CIRCUMFLEX AND DOT BELOW
    0x001EA7 =>       1,  #  ầ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH CIRCUMFLEX AND GRAVE
    0x0000E4 =>   62227,  #  ä  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH DIAERESIS
    0x000227 =>      13,  #  ȧ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH DOT ABOVE
    0x001EA1 =>      31,  #  ạ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH DOT BELOW
    0x000201 =>       1,  #  ȁ  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH DOUBLE GRAVE
    0x0000E0 =>   11147,  #  à  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH GRAVE
    0x001EA3 =>       9,  #  ả  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH HOOK ABOVE
    0x000101 =>    1902,  #  ā  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH MACRON
    0x000105 =>     306,  #  ą  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH OGONEK
    0x0000E5 =>    9917,  #  å  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH RING ABOVE
    0x0000E3 =>   18112,  #  ã  gc=Ll   sc=Latin      LATIN SMALL LETTER A WITH TILDE
    0x01D538 =>       9,  #  𝔸  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL A
    0x01D49C =>     185,  #  𝒜  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL A
    0x00212B =>    3397,  #  Å  gc=Lu   sc=Latin      ANGSTROM SIGN
    0x0000C1 =>    1949,  #  Á  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH ACUTE
    0x000102 =>      37,  #  Ă  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH BREVE
    0x0000C2 =>     577,  #  Â  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH CIRCUMFLEX
    0x0000C4 =>    1198,  #  Ä  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH DIAERESIS
    0x000226 =>       1,  #  Ȧ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH DOT ABOVE
    0x0000C0 =>     163,  #  À  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH GRAVE
    0x001EA2 =>       1,  #  Ả  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH HOOK ABOVE
    0x000100 =>      32,  #  Ā  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH MACRON
    0x000104 =>       1,  #  Ą  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH OGONEK
    0x0000C5 =>   42397,  #  Å  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH RING ABOVE
    0x0001FA =>     206,  #  Ǻ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH RING ABOVE AND ACUTE
    0x0000C3 =>     204,  #  Ã  gc=Lu   sc=Latin      LATIN CAPITAL LETTER A WITH TILDE
    0x0024B6 =>       2,  #  Ⓐ  gc=So   sc=Common     CIRCLED LATIN CAPITAL LETTER A
    0x0000E6 =>    3589,  #  æ  gc=Ll   sc=Latin      LATIN SMALL LETTER AE
    0x0001FD =>       3,  #  ǽ  gc=Ll   sc=Latin      LATIN SMALL LETTER AE WITH ACUTE
    0x0000C6 =>     235,  #  Æ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER AE
    0x000251 =>       2,  #  ɑ  gc=Ll   sc=Latin      LATIN SMALL LETTER ALPHA
    0x01D539 =>      21,  #  𝔹  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL B
    0x01D505 =>       2,  #  𝔅  gc=Lu   sc=Common     MATHEMATICAL FRAKTUR CAPITAL B
    0x00212C =>     289,  #  ℬ  gc=Lu   sc=Common     SCRIPT CAPITAL B
    0x001E04 =>       1,  #  Ḅ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER B WITH DOT BELOW
    0x0024B7 =>       3,  #  Ⓑ  gc=So   sc=Common     CIRCLED LATIN CAPITAL LETTER B
    0x000181 =>       1,  #  Ɓ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER B WITH HOOK
    0x000183 =>       1,  #  ƃ  gc=Ll   sc=Latin      LATIN SMALL LETTER B WITH TOPBAR
    0x01D4B8 =>       1,  #  𝒸  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL C
    0x000107 =>    3372,  #  ć  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH ACUTE
    0x00010D =>    2377,  #  č  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH CARON
    0x0000E7 =>   17094,  #  ç  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH CEDILLA
    0x000109 =>      73,  #  ĉ  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH CIRCUMFLEX
    0x00010B =>      43,  #  ċ  gc=Ll   sc=Latin      LATIN SMALL LETTER C WITH DOT ABOVE
    0x00212D =>      70,  #  ℭ  gc=Lu   sc=Common     BLACK-LETTER CAPITAL C
    0x002102 =>     122,  #  ℂ  gc=Lu   sc=Common     DOUBLE-STRUCK CAPITAL C
    0x01D49E =>     544,  #  𝒞  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL C
    0x000106 =>      16,  #  Ć  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH ACUTE
    0x00010C =>     389,  #  Č  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH CARON
    0x0000C7 =>     897,  #  Ç  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH CEDILLA
    0x000108 =>      97,  #  Ĉ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH CIRCUMFLEX
    0x00010A =>       8,  #  Ċ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER C WITH DOT ABOVE
    0x002105 =>       1,  #  ℅  gc=So   sc=Common     CARE OF
    0x002146 =>      14,  #  ⅆ  gc=Ll   sc=Common     DOUBLE-STRUCK ITALIC SMALL D
    0x00010F =>       1,  #  ď  gc=Ll   sc=Latin      LATIN SMALL LETTER D WITH CARON
    0x001E0D =>      13,  #  ḍ  gc=Ll   sc=Latin      LATIN SMALL LETTER D WITH DOT BELOW
    0x000111 =>      50,  #  đ  gc=Ll   sc=Latin      LATIN SMALL LETTER D WITH STROKE
    0x0000F0 =>     140,  #  ð  gc=Ll   sc=Latin      LATIN SMALL LETTER ETH
    0x002145 =>      28,  #  ⅅ  gc=Lu   sc=Common     DOUBLE-STRUCK ITALIC CAPITAL D
    0x01D53B =>       4,  #  𝔻  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL D
    0x01D507 =>       3,  #  𝔇  gc=Lu   sc=Common     MATHEMATICAL FRAKTUR CAPITAL D
    0x01D49F =>     292,  #  𝒟  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL D
    0x00010E =>      11,  #  Ď  gc=Lu   sc=Latin      LATIN CAPITAL LETTER D WITH CARON
    0x001E0A =>       3,  #  Ḋ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER D WITH DOT ABOVE
    0x001E0C =>       1,  #  Ḍ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER D WITH DOT BELOW
    0x000110 =>      44,  #  Đ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER D WITH STROKE
    0x0000D0 =>       7,  #  Ð  gc=Lu   sc=Latin      LATIN CAPITAL LETTER ETH
    0x00217E =>       2,  #  ⅾ  gc=Nl   sc=Latin      SMALL ROMAN NUMERAL FIVE HUNDRED
    0x003397 =>       2,  #  ㎗ gc=So   sc=Common     SQUARE DL
    0x000189 =>       2,  #  Ɖ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER AFRICAN D
    0x00212F =>       7,  #  ℯ  gc=Ll   sc=Common     SCRIPT SMALL E
    0x0000E9 =>  173691,  #  é  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH ACUTE
    0x000115 =>      47,  #  ĕ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH BREVE
    0x00011B =>     248,  #  ě  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CARON
    0x000229 =>       7,  #  ȩ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CEDILLA
    0x0000EA =>    5500,  #  ê  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX
    0x001EBF =>      10,  #  ế  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX AND ACUTE
    0x001EC7 =>      12,  #  ệ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX AND DOT BELOW
    0x001EC1 =>       3,  #  ề  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX AND GRAVE
    0x001EC3 =>       1,  #  ể  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX AND HOOK ABOVE
    0x001EC5 =>       6,  #  ễ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH CIRCUMFLEX AND TILDE
    0x0000EB =>    3643,  #  ë  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH DIAERESIS
    0x000117 =>     281,  #  ė  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH DOT ABOVE
    0x001EB9 =>       3,  #  ẹ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH DOT BELOW
    0x0000E8 =>   20520,  #  è  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH GRAVE
    0x001EBB =>       1,  #  ẻ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH HOOK ABOVE
    0x000207 =>       1,  #  ȇ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH INVERTED BREVE
    0x000113 =>      56,  #  ē  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH MACRON
    0x000119 =>     486,  #  ę  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH OGONEK
    0x001EBD =>       9,  #  ẽ  gc=Ll   sc=Latin      LATIN SMALL LETTER E WITH TILDE
    0x01D53C =>     178,  #  𝔼  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL E
    0x002130 =>     301,  #  ℰ  gc=Lu   sc=Common     SCRIPT CAPITAL E
    0x0000C9 =>    2005,  #  É  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH ACUTE
    0x0000CA =>      70,  #  Ê  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH CIRCUMFLEX
    0x001EC6 =>       1,  #  Ệ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH CIRCUMFLEX AND DOT BELOW
    0x0000CB =>      11,  #  Ë  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH DIAERESIS
    0x000116 =>       5,  #  Ė  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH DOT ABOVE
    0x0000C8 =>     130,  #  È  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH GRAVE
    0x000112 =>      51,  #  Ē  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH MACRON
    0x000118 =>       6,  #  Ę  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH OGONEK
    0x001EBC =>      13,  #  Ẽ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH TILDE
    0x000246 =>       1,  #  Ɇ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER E WITH STROKE
    0x0001DD =>       3,  #  ǝ  gc=Ll   sc=Latin      LATIN SMALL LETTER TURNED E
    0x000259 =>      34,  #  ə  gc=Ll   sc=Latin      LATIN SMALL LETTER SCHWA
    0x00018F =>       4,  #  Ə  gc=Lu   sc=Latin      LATIN CAPITAL LETTER SCHWA
    0x00025B =>    5239,  #  ɛ  gc=Ll   sc=Latin      LATIN SMALL LETTER OPEN E
    0x002107 =>       5,  #  ℇ  gc=Lu   sc=Common     EULER CONSTANT
    0x000258 =>       1,  #  ɘ  gc=Ll   sc=Latin      LATIN SMALL LETTER REVERSED E
    0x01D4BB =>       3,  #  𝒻  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL F
    0x01D53D =>       1,  #  𝔽  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL F
    0x002131 =>     581,  #  ℱ  gc=Lu   sc=Common     SCRIPT CAPITAL F
    0x00FB00 =>       5,  #  ﬀ  gc=Ll   sc=Latin      LATIN SMALL LIGATURE FF
    0x00FB03 =>       1,  #  ﬃ  gc=Ll   sc=Latin      LATIN SMALL LIGATURE FFI
    0x00FB01 =>     182,  #  ﬁ  gc=Ll   sc=Latin      LATIN SMALL LIGATURE FI
    0x00FB02 =>     100,  #  ﬂ  gc=Ll   sc=Latin      LATIN SMALL LIGATURE FL
    0x000192 =>     137,  #  ƒ  gc=Ll   sc=Latin      LATIN SMALL LETTER F WITH HOOK
    0x00210A =>      92,  #  ℊ  gc=Ll   sc=Common     SCRIPT SMALL G
    0x0001F5 =>       2,  #  ǵ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH ACUTE
    0x00011F =>    1467,  #  ğ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH BREVE
    0x0001E7 =>      35,  #  ǧ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH CARON
    0x000123 =>       1,  #  ģ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH CEDILLA
    0x00011D =>     169,  #  ĝ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH CIRCUMFLEX
    0x000121 =>      10,  #  ġ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH DOT ABOVE
    0x001E21 =>     121,  #  ḡ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH MACRON
    0x01D53E =>       1,  #  𝔾  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL G
    0x01D4A2 =>     254,  #  𝒢  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL G
    0x00011E =>       3,  #  Ğ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER G WITH BREVE
    0x0001E6 =>       3,  #  Ǧ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER G WITH CARON
    0x00011C =>      42,  #  Ĝ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER G WITH CIRCUMFLEX
    0x000120 =>       3,  #  Ġ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER G WITH DOT ABOVE
    0x001E20 =>       2,  #  Ḡ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER G WITH MACRON
    0x000260 =>       2,  #  ɠ  gc=Ll   sc=Latin      LATIN SMALL LETTER G WITH HOOK
    0x0002E0 =>       7,  #  ˠ  gc=Lm   sc=Latin      MODIFIER LETTER SMALL GAMMA
    0x01D4BD =>       2,  #  𝒽  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL H
    0x00210F =>     577,  #  ℏ  gc=Ll   sc=Common     PLANCK CONSTANT OVER TWO PI
    0x000125 =>      19,  #  ĥ  gc=Ll   sc=Latin      LATIN SMALL LETTER H WITH CIRCUMFLEX
    0x001E23 =>       1,  #  ḣ  gc=Ll   sc=Latin      LATIN SMALL LETTER H WITH DOT ABOVE
    0x001E25 =>      30,  #  ḥ  gc=Ll   sc=Latin      LATIN SMALL LETTER H WITH DOT BELOW
    0x000127 =>     151,  #  ħ  gc=Ll   sc=Latin      LATIN SMALL LETTER H WITH STROKE
    0x00210C =>       6,  #  ℌ  gc=Lu   sc=Common     BLACK-LETTER CAPITAL H
    0x00210D =>      15,  #  ℍ  gc=Lu   sc=Common     DOUBLE-STRUCK CAPITAL H
    0x01D5A7 =>      19,  #  𝖧  gc=Lu   sc=Common     MATHEMATICAL SANS-SERIF CAPITAL H
    0x00210B =>     508,  #  ℋ  gc=Lu   sc=Common     SCRIPT CAPITAL H
    0x000124 =>     108,  #  Ĥ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER H WITH CIRCUMFLEX
    0x001E22 =>       1,  #  Ḣ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER H WITH DOT ABOVE
    0x001E24 =>       6,  #  Ḥ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER H WITH DOT BELOW
    0x000126 =>      29,  #  Ħ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER H WITH STROKE
    0x01D4BE =>       7,  #  𝒾  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL I
    0x0000ED =>   47405,  #  í  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH ACUTE
    0x00012D =>      59,  #  ĭ  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH BREVE
    0x0001D0 =>       2,  #  ǐ  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH CARON
    0x0000EE =>     698,  #  î  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH CIRCUMFLEX
    0x0000EF =>   21057,  #  ï  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH DIAERESIS
    0x001ECB =>       3,  #  ị  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH DOT BELOW
    0x000209 =>       1,  #  ȉ  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH DOUBLE GRAVE
    0x0000EC =>     858,  #  ì  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH GRAVE
    0x001EC9 =>       1,  #  ỉ  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH HOOK ABOVE
    0x00012B =>     617,  #  ī  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH MACRON
    0x00012F =>       7,  #  į  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH OGONEK
    0x000129 =>       6,  #  ĩ  gc=Ll   sc=Latin      LATIN SMALL LETTER I WITH TILDE
    0x002111 =>     134,  #  ℑ  gc=Lu   sc=Common     BLACK-LETTER CAPITAL I
    0x01D540 =>      11,  #  𝕀  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL I
    0x002110 =>     304,  #  ℐ  gc=Lu   sc=Common     SCRIPT CAPITAL I
    0x0000CD =>     174,  #  Í  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH ACUTE
    0x0000CE =>     278,  #  Î  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH CIRCUMFLEX
    0x0000CF =>      51,  #  Ï  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH DIAERESIS
    0x000130 =>     361,  #  İ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH DOT ABOVE
    0x0000CC =>      35,  #  Ì  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH GRAVE
    0x00012A =>      39,  #  Ī  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH MACRON
    0x000128 =>      48,  #  Ĩ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH TILDE
    0x002160 =>       8,  #  Ⅰ  gc=Nl   sc=Latin      ROMAN NUMERAL ONE
    0x002161 =>       5,  #  Ⅱ  gc=Nl   sc=Latin      ROMAN NUMERAL TWO
    0x002162 =>       4,  #  Ⅲ  gc=Nl   sc=Latin      ROMAN NUMERAL THREE
    0x000133 =>       1,  #  ĳ  gc=Ll   sc=Latin      LATIN SMALL LIGATURE IJ
    0x000132 =>       1,  #  Ĳ  gc=Lu   sc=Latin      LATIN CAPITAL LIGATURE IJ
    0x002163 =>       1,  #  Ⅳ  gc=Nl   sc=Latin      ROMAN NUMERAL FOUR
    0x002178 =>       1,  #  ⅸ  gc=Nl   sc=Latin      SMALL ROMAN NUMERAL NINE
    0x01D6A4 =>       1,  #  𝚤  gc=Ll   sc=Common     MATHEMATICAL ITALIC SMALL DOTLESS I
    0x000131 =>    1990,  #  ı  gc=Ll   sc=Latin      LATIN SMALL LETTER DOTLESS I
    0x00026A =>       9,  #  ɪ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL I
    0x000197 =>       6,  #  Ɨ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER I WITH STROKE
    0x01D4BF =>      13,  #  𝒿  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL J
    0x000135 =>       2,  #  ĵ  gc=Ll   sc=Latin      LATIN SMALL LETTER J WITH CIRCUMFLEX
    0x01D541 =>       2,  #  𝕁  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL J
    0x01D4A5 =>      56,  #  𝒥  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL J
    0x000134 =>       6,  #  Ĵ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER J WITH CIRCUMFLEX
    0x001E31 =>       2,  #  ḱ  gc=Ll   sc=Latin      LATIN SMALL LETTER K WITH ACUTE
    0x01D542 =>       3,  #  𝕂  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL K
    0x01D50E =>       2,  #  𝔎  gc=Lu   sc=Common     MATHEMATICAL FRAKTUR CAPITAL K
    0x01D4A6 =>      48,  #  𝒦  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL K
    0x000136 =>       2,  #  Ķ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER K WITH CEDILLA
    0x000198 =>      15,  #  Ƙ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER K WITH HOOK
    0x01D4C1 =>       1,  #  𝓁  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL L
    0x002113 =>    3261,  #  ℓ  gc=Ll   sc=Common     SCRIPT SMALL L
    0x00013A =>      13,  #  ĺ  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH ACUTE
    0x00013E =>       1,  #  ľ  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH CARON
    0x001E3B =>       1,  #  ḻ  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH LINE BELOW
    0x000142 =>    1967,  #  ł  gc=Ll   sc=Latin      LATIN SMALL LETTER L WITH STROKE
    0x01D543 =>       2,  #  𝕃  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL L
    0x002112 =>     564,  #  ℒ  gc=Lu   sc=Common     SCRIPT CAPITAL L
    0x000139 =>       1,  #  Ĺ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER L WITH ACUTE
    0x00013D =>       3,  #  Ľ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER L WITH CARON
    0x000141 =>     415,  #  Ł  gc=Lu   sc=Latin      LATIN CAPITAL LETTER L WITH STROKE
    0x00FF4C =>       1,  #  ｌ gc=Ll   sc=Latin      FULLWIDTH LATIN SMALL LETTER L
    0x00029F =>      11,  #  ʟ  gc=Ll   sc=Latin      LATIN LETTER SMALL CAPITAL L
    0x00019B =>       2,  #  ƛ  gc=Ll   sc=Latin      LATIN SMALL LETTER LAMBDA WITH STROKE
    0x01D4C2 =>       8,  #  𝓂  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL M
    0x001E3F =>       1,  #  ḿ  gc=Ll   sc=Latin      LATIN SMALL LETTER M WITH ACUTE
    0x001E41 =>       2,  #  ṁ  gc=Ll   sc=Latin      LATIN SMALL LETTER M WITH DOT ABOVE
    0x001E43 =>      10,  #  ṃ  gc=Ll   sc=Latin      LATIN SMALL LETTER M WITH DOT BELOW
    0x002133 =>    1203,  #  ℳ  gc=Lu   sc=Common     SCRIPT CAPITAL M
    0x01D4C3 =>      15,  #  𝓃  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL N
    0x000144 =>    1815,  #  ń  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH ACUTE
    0x000148 =>     217,  #  ň  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH CARON
    0x001E45 =>       4,  #  ṅ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH DOT ABOVE
    0x001E47 =>      17,  #  ṇ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH DOT BELOW
    0x0001F9 =>       1,  #  ǹ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH GRAVE
    0x0000F1 =>   15640,  #  ñ  gc=Ll   sc=Latin      LATIN SMALL LETTER N WITH TILDE
    0x002115 =>     146,  #  ℕ  gc=Lu   sc=Common     DOUBLE-STRUCK CAPITAL N
    0x01D4A9 =>     262,  #  𝒩  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL N
    0x000143 =>       4,  #  Ń  gc=Lu   sc=Latin      LATIN CAPITAL LETTER N WITH ACUTE
    0x000145 =>       1,  #  Ņ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER N WITH CEDILLA
    0x0000D1 =>      49,  #  Ñ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER N WITH TILDE
    0x002116 =>      17,  #  №  gc=So   sc=Common     NUMERO SIGN
    0x00014B =>      15,  #  ŋ  gc=Ll   sc=Latin      LATIN SMALL LETTER ENG
    0x002134 =>      21,  #  ℴ  gc=Ll   sc=Common     SCRIPT SMALL O
    0x0000F3 =>   42241,  #  ó  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH ACUTE
    0x00014F =>       5,  #  ŏ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH BREVE
    0x0001D2 =>       4,  #  ǒ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CARON
    0x0000F4 =>    9126,  #  ô  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX
    0x001ED1 =>       4,  #  ố  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX AND ACUTE
    0x001ED3 =>       4,  #  ồ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX AND GRAVE
    0x001ED5 =>       2,  #  ổ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX AND HOOK ABOVE
    0x001ED7 =>       2,  #  ỗ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH CIRCUMFLEX AND TILDE
    0x0000F6 =>   86074,  #  ö  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH DIAERESIS
    0x001ECD =>       1,  #  ọ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH DOT BELOW
    0x000151 =>     290,  #  ő  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH DOUBLE ACUTE
    0x0000F2 =>    2103,  #  ò  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH GRAVE
    0x0001A1 =>       9,  #  ơ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH HORN
    0x001EDB =>      23,  #  ớ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH HORN AND ACUTE
    0x001EDF =>       1,  #  ở  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH HORN AND HOOK ABOVE
    0x00014D =>     273,  #  ō  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH MACRON
    0x0000F8 =>   19049,  #  ø  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH STROKE
    0x0001FF =>      22,  #  ǿ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH STROKE AND ACUTE
    0x0000F5 =>    1293,  #  õ  gc=Ll   sc=Latin      LATIN SMALL LETTER O WITH TILDE
    0x0000BA =>    2832,  #  º  gc=Ll   sc=Latin      MASCULINE ORDINAL INDICATOR
    0x01D546 =>       3,  #  𝕆  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL O
    0x01D4AA =>     137,  #  𝒪  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL O
    0x0000D3 =>     261,  #  Ó  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH ACUTE
    0x0001D1 =>       1,  #  Ǒ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH CARON
    0x0000D4 =>      69,  #  Ô  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH CIRCUMFLEX
    0x0000D6 =>    4893,  #  Ö  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH DIAERESIS
    0x000150 =>      22,  #  Ő  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH DOUBLE ACUTE
    0x0000D2 =>      38,  #  Ò  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH GRAVE
    0x001ECE =>       1,  #  Ỏ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH HOOK ABOVE
    0x00014C =>       6,  #  Ō  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH MACRON
    0x0000D8 =>    5210,  #  Ø  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH STROKE
    0x0001FE =>       7,  #  Ǿ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH STROKE AND ACUTE
    0x0000D5 =>      37,  #  Õ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER O WITH TILDE
    0x000153 =>     281,  #  œ  gc=Ll   sc=Latin      LATIN SMALL LIGATURE OE
    0x000152 =>      27,  #  Œ  gc=Lu   sc=Latin      LATIN CAPITAL LIGATURE OE
    0x000254 =>       1,  #  ɔ  gc=Ll   sc=Latin      LATIN SMALL LETTER OPEN O
    0x01D4C5 =>       2,  #  𝓅  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL P
    0x001E57 =>       1,  #  ṗ  gc=Ll   sc=Latin      LATIN SMALL LETTER P WITH DOT ABOVE
    0x002119 =>     400,  #  ℙ  gc=Lu   sc=Common     DOUBLE-STRUCK CAPITAL P
    0x01D4AB =>     258,  #  𝒫  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL P
    0x001E54 =>       4,  #  Ṕ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER P WITH ACUTE
    0x001E56 =>      16,  #  Ṗ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER P WITH DOT ABOVE
    0x0024C5 =>       1,  #  Ⓟ  gc=So   sc=Common     CIRCLED LATIN CAPITAL LETTER P
    0x000278 =>      71,  #  ɸ  gc=Ll   sc=Latin      LATIN SMALL LETTER PHI
    0x00211A =>      47,  #  ℚ  gc=Lu   sc=Common     DOUBLE-STRUCK CAPITAL Q
    0x01D4AC =>      30,  #  𝒬  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL Q
    0x000138 =>      44,  #  ĸ  gc=Ll   sc=Latin      LATIN SMALL LETTER KRA
    0x000155 =>      36,  #  ŕ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH ACUTE
    0x000159 =>     624,  #  ř  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH CARON
    0x000157 =>       1,  #  ŗ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH CEDILLA
    0x001E59 =>       2,  #  ṙ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH DOT ABOVE
    0x001E5D =>       3,  #  ṝ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH DOT BELOW AND MACRON
    0x000213 =>       2,  #  ȓ  gc=Ll   sc=Latin      LATIN SMALL LETTER R WITH INVERTED BREVE
    0x00211C =>     322,  #  ℜ  gc=Lu   sc=Common     BLACK-LETTER CAPITAL R
    0x00211D =>    1252,  #  ℝ  gc=Lu   sc=Common     DOUBLE-STRUCK CAPITAL R
    0x00211B =>     483,  #  ℛ  gc=Lu   sc=Common     SCRIPT CAPITAL R
    0x000154 =>       3,  #  Ŕ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER R WITH ACUTE
    0x000158 =>      42,  #  Ř  gc=Lu   sc=Latin      LATIN CAPITAL LETTER R WITH CARON
    0x0024C7 =>       2,  #  Ⓡ  gc=So   sc=Common     CIRCLED LATIN CAPITAL LETTER R
    0x00015B =>     698,  #  ś  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH ACUTE
    0x000161 =>    2291,  #  š  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH CARON
    0x00015F =>    1465,  #  ş  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH CEDILLA
    0x00015D =>      72,  #  ŝ  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH CIRCUMFLEX
    0x000219 =>       1,  #  ș  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH COMMA BELOW
    0x001E61 =>       1,  #  ṡ  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH DOT ABOVE
    0x001E63 =>      17,  #  ṣ  gc=Ll   sc=Latin      LATIN SMALL LETTER S WITH DOT BELOW
    0x01D54A =>      23,  #  𝕊  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL S
    0x01D516 =>       7,  #  𝔖  gc=Lu   sc=Common     MATHEMATICAL FRAKTUR CAPITAL S
    0x01D4AE =>     385,  #  𝒮  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL S
    0x00015A =>     150,  #  Ś  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH ACUTE
    0x000160 =>    1454,  #  Š  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH CARON
    0x00015E =>     312,  #  Ş  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH CEDILLA
    0x00015C =>     132,  #  Ŝ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH CIRCUMFLEX
    0x000218 =>       1,  #  Ș  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH COMMA BELOW
    0x001E60 =>       1,  #  Ṡ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH DOT ABOVE
    0x001E62 =>       8,  #  Ṣ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER S WITH DOT BELOW
    0x0000DF =>    8462,  #  ß  gc=Ll   sc=Latin      LATIN SMALL LETTER SHARP S
    0x000283 =>       1,  #  ʃ  gc=Ll   sc=Latin      LATIN SMALL LETTER ESH
    0x000165 =>      20,  #  ť  gc=Ll   sc=Latin      LATIN SMALL LETTER T WITH CARON
    0x000163 =>     214,  #  ţ  gc=Ll   sc=Latin      LATIN SMALL LETTER T WITH CEDILLA
    0x00021B =>       3,  #  ț  gc=Ll   sc=Latin      LATIN SMALL LETTER T WITH COMMA BELOW
    0x001E97 =>       3,  #  ẗ  gc=Ll   sc=Latin      LATIN SMALL LETTER T WITH DIAERESIS
    0x001E6D =>      39,  #  ṭ  gc=Ll   sc=Latin      LATIN SMALL LETTER T WITH DOT BELOW
    0x01D54B =>       4,  #  𝕋  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL T
    0x01D517 =>      18,  #  𝔗  gc=Lu   sc=Common     MATHEMATICAL FRAKTUR CAPITAL T
    0x01D4AF =>     450,  #  𝒯  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL T
    0x000162 =>      11,  #  Ţ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER T WITH CEDILLA
    0x001E6C =>       1,  #  Ṭ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER T WITH DOT BELOW
    0x002122 =>   37280,  #  ™  gc=So   sc=Common     TRADE MARK SIGN
    0x000167 =>      28,  #  ŧ  gc=Ll   sc=Latin      LATIN SMALL LETTER T WITH STROKE
    0x000166 =>      37,  #  Ŧ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER T WITH STROKE
    0x01D4CA =>       3,  #  𝓊  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL U
    0x0000FA =>    7713,  #  ú  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH ACUTE
    0x00016D =>      26,  #  ŭ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH BREVE
    0x0001D4 =>       2,  #  ǔ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH CARON
    0x0000FB =>     493,  #  û  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH CIRCUMFLEX
    0x0000FC =>   81674,  #  ü  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DIAERESIS
    0x0001D8 =>       1,  #  ǘ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DIAERESIS AND ACUTE
    0x0001DC =>       1,  #  ǜ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DIAERESIS AND GRAVE
    0x001EE5 =>       2,  #  ụ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DOT BELOW
    0x000171 =>     210,  #  ű  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DOUBLE ACUTE
    0x000215 =>       1,  #  ȕ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH DOUBLE GRAVE
    0x0000F9 =>     465,  #  ù  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH GRAVE
    0x001EE7 =>       1,  #  ủ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH HOOK ABOVE
    0x0001B0 =>       8,  #  ư  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH HORN
    0x00016B =>     317,  #  ū  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH MACRON
    0x000173 =>      63,  #  ų  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH OGONEK
    0x00016F =>     104,  #  ů  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH RING ABOVE
    0x000169 =>      45,  #  ũ  gc=Ll   sc=Latin      LATIN SMALL LETTER U WITH TILDE
    0x01D54C =>       1,  #  𝕌  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL U
    0x01D4B0 =>      35,  #  𝒰  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL U
    0x0000DA =>     105,  #  Ú  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH ACUTE
    0x0000DB =>      16,  #  Û  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH CIRCUMFLEX
    0x0000DC =>    1677,  #  Ü  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH DIAERESIS
    0x000170 =>       5,  #  Ű  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH DOUBLE ACUTE
    0x0000D9 =>      18,  #  Ù  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH GRAVE
    0x00016A =>       4,  #  Ū  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH MACRON
    0x000168 =>      33,  #  Ũ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER U WITH TILDE
    0x00028A =>       3,  #  ʊ  gc=Ll   sc=Latin      LATIN SMALL LETTER UPSILON
    0x001E7D =>      14,  #  ṽ  gc=Ll   sc=Latin      LATIN SMALL LETTER V WITH TILDE
    0x01D54D =>       8,  #  𝕍  gc=Lu   sc=Common     MATHEMATICAL DOUBLE-STRUCK CAPITAL V
    0x01D4B1 =>      44,  #  𝒱  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL V
    0x001E7C =>       3,  #  Ṽ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER V WITH TILDE
    0x01D4CC =>       7,  #  𝓌  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL W
    0x000175 =>      23,  #  ŵ  gc=Ll   sc=Latin      LATIN SMALL LETTER W WITH CIRCUMFLEX
    0x01D4B2 =>      43,  #  𝒲  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL W
    0x000174 =>       5,  #  Ŵ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER W WITH CIRCUMFLEX
    0x001E84 =>       1,  #  Ẅ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER W WITH DIAERESIS
    0x001E86 =>      10,  #  Ẇ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER W WITH DOT ABOVE
    0x0024E6 =>       1,  #  ⓦ  gc=So   sc=Common     CIRCLED LATIN SMALL LETTER W
    0x01D535 =>      14,  #  𝔵  gc=Ll   sc=Common     MATHEMATICAL FRAKTUR SMALL X
    0x01D465 =>       9,  #  𝑥  gc=Ll   sc=Common     MATHEMATICAL ITALIC SMALL X
    0x001E8B =>      14,  #  ẋ  gc=Ll   sc=Latin      LATIN SMALL LETTER X WITH DOT ABOVE
    0x01D4B3 =>     285,  #  𝒳  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL X
    0x001E8A =>       2,  #  Ẋ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER X WITH DOT ABOVE
    0x002179 =>       1,  #  ⅹ  gc=Nl   sc=Latin      SMALL ROMAN NUMERAL TEN
    0x01D4CE =>       9,  #  𝓎  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL Y
    0x0000FD =>     974,  #  ý  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH ACUTE
    0x000177 =>      48,  #  ŷ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH CIRCUMFLEX
    0x0000FF =>      80,  #  ÿ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH DIAERESIS
    0x001E8F =>       7,  #  ẏ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH DOT ABOVE
    0x001EF3 =>       3,  #  ỳ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH GRAVE
    0x001EF7 =>       1,  #  ỷ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH HOOK ABOVE
    0x000233 =>      42,  #  ȳ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH MACRON
    0x001EF9 =>      36,  #  ỹ  gc=Ll   sc=Latin      LATIN SMALL LETTER Y WITH TILDE
    0x01D4B4 =>      42,  #  𝒴  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL Y
    0x0000DD =>      38,  #  Ý  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Y WITH ACUTE
    0x000176 =>      92,  #  Ŷ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Y WITH CIRCUMFLEX
    0x000178 =>       7,  #  Ÿ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Y WITH DIAERESIS
    0x001E8E =>       6,  #  Ẏ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Y WITH DOT ABOVE
    0x001EF2 =>       2,  #  Ỳ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Y WITH GRAVE
    0x000232 =>      32,  #  Ȳ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Y WITH MACRON
    0x001EF8 =>       4,  #  Ỹ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Y WITH TILDE
    0x01D4CF =>       4,  #  𝓏  gc=Ll   sc=Common     MATHEMATICAL SCRIPT SMALL Z
    0x00017A =>     333,  #  ź  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH ACUTE
    0x00017E =>     764,  #  ž  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH CARON
    0x001E91 =>       6,  #  ẑ  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH CIRCUMFLEX
    0x00017C =>     444,  #  ż  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH DOT ABOVE
    0x001E93 =>       1,  #  ẓ  gc=Ll   sc=Latin      LATIN SMALL LETTER Z WITH DOT BELOW
    0x002124 =>     114,  #  ℤ  gc=Lu   sc=Common     DOUBLE-STRUCK CAPITAL Z
    0x01D4B5 =>      41,  #  𝒵  gc=Lu   sc=Common     MATHEMATICAL SCRIPT CAPITAL Z
    0x000179 =>       1,  #  Ź  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Z WITH ACUTE
    0x00017D =>     338,  #  Ž  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Z WITH CARON
    0x00017B =>     119,  #  Ż  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Z WITH DOT ABOVE
    0x0001B5 =>      40,  #  Ƶ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER Z WITH STROKE
    0x000292 =>       3,  #  ʒ  gc=Ll   sc=Latin      LATIN SMALL LETTER EZH
    0x00021D =>       2,  #  ȝ  gc=Ll   sc=Latin      LATIN SMALL LETTER YOGH
    0x0000FE =>      61,  #  þ  gc=Ll   sc=Latin      LATIN SMALL LETTER THORN
    0x0000DE =>      25,  #  Þ  gc=Lu   sc=Latin      LATIN CAPITAL LETTER THORN
    0x0002BC =>      32,  #  ʼ  gc=Lm   sc=Common     MODIFIER LETTER APOSTROPHE
    0x0001C1 =>       7,  #  ǁ  gc=Lo   sc=Latin      LATIN LETTER LATERAL CLICK
    0x0001C2 =>       9,  #  ǂ  gc=Lo   sc=Latin      LATIN LETTER ALVEOLAR CLICK
    0x0002AC =>       1,  #  ʬ  gc=Ll   sc=Latin      LATIN LETTER BILABIAL PERCUSSIVE
    0x0003B1 =>  512312,  #  α  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA
    0x001FB1 =>       5,  #  ᾱ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH MACRON
    0x001FB6 =>       6,  #  ᾶ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH PERISPOMENI
    0x001F00 =>       4,  #  ἀ  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH PSILI
    0x0003AC =>     102,  #  ά  gc=Ll   sc=Greek      GREEK SMALL LETTER ALPHA WITH TONOS
    0x000391 =>     140,  #  Α  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ALPHA
    0x000386 =>       1,  #  Ά  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ALPHA WITH TONOS
    0x0003D0 =>       1,  #  ϐ  gc=Ll   sc=Greek      GREEK BETA SYMBOL
    0x0003B2 =>  519669,  #  β  gc=Ll   sc=Greek      GREEK SMALL LETTER BETA
    0x000392 =>     167,  #  Β  gc=Lu   sc=Greek      GREEK CAPITAL LETTER BETA
    0x0003B3 =>  191986,  #  γ  gc=Ll   sc=Greek      GREEK SMALL LETTER GAMMA
    0x000393 =>    5298,  #  Γ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER GAMMA
    0x0003B4 =>   58415,  #  δ  gc=Ll   sc=Greek      GREEK SMALL LETTER DELTA
    0x000394 =>  220464,  #  Δ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER DELTA
    0x0003F5 =>    2414,  #  ϵ  gc=Ll   sc=Greek      GREEK LUNATE EPSILON SYMBOL
    0x0003B5 =>   28136,  #  ε  gc=Ll   sc=Greek      GREEK SMALL LETTER EPSILON
    0x001F14 =>       2,  #  ἔ  gc=Ll   sc=Greek      GREEK SMALL LETTER EPSILON WITH PSILI AND OXIA
    0x0003AD =>      25,  #  έ  gc=Ll   sc=Greek      GREEK SMALL LETTER EPSILON WITH TONOS
    0x000395 =>      51,  #  Ε  gc=Lu   sc=Greek      GREEK CAPITAL LETTER EPSILON
    0x0003B6 =>    7757,  #  ζ  gc=Ll   sc=Greek      GREEK SMALL LETTER ZETA
    0x000396 =>       6,  #  Ζ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ZETA
    0x0003B7 =>   11342,  #  η  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA
    0x001FC6 =>       2,  #  ῆ  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA WITH PERISPOMENI
    0x0003AE =>      59,  #  ή  gc=Ll   sc=Greek      GREEK SMALL LETTER ETA WITH TONOS
    0x000397 =>      61,  #  Η  gc=Lu   sc=Greek      GREEK CAPITAL LETTER ETA
    0x0003B8 =>   28775,  #  θ  gc=Ll   sc=Greek      GREEK SMALL LETTER THETA
    0x0003D1 =>     550,  #  ϑ  gc=Ll   sc=Greek      GREEK THETA SYMBOL
    0x000398 =>    3610,  #  Θ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER THETA
    0x0003F4 =>       1,  #  ϴ  gc=Lu   sc=Greek      GREEK CAPITAL THETA SYMBOL
    0x0003B9 =>    1252,  #  ι  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA
    0x0003CA =>       6,  #  ϊ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH DIALYTIKA
    0x000390 =>       1,  #  ΐ  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS
    0x0003AF =>      62,  #  ί  gc=Ll   sc=Greek      GREEK SMALL LETTER IOTA WITH TONOS
    0x000399 =>     121,  #  Ι  gc=Lu   sc=Greek      GREEK CAPITAL LETTER IOTA
    0x0003AA =>      27,  #  Ϊ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER IOTA WITH DIALYTIKA
    0x0003BA =>   82276,  #  κ  gc=Ll   sc=Greek      GREEK SMALL LETTER KAPPA
    0x00039A =>      75,  #  Κ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER KAPPA
    0x0003BB =>   42333,  #  λ  gc=Ll   sc=Greek      GREEK SMALL LETTER LAMDA
    0x00039B =>    2478,  #  Λ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER LAMDA
    0x0000B5 =>  203225,  #  µ  gc=Ll   sc=Common     MICRO SIGN
    0x0003BC =>  528576,  #  μ  gc=Ll   sc=Greek      GREEK SMALL LETTER MU
    0x00039C =>      99,  #  Μ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER MU
    0x00338D =>       3,  #  ㎍ gc=So   sc=Common     SQUARE MU G
    0x003395 =>      12,  #  ㎕ gc=So   sc=Common     SQUARE MU L
    0x00339B =>       1,  #  ㎛ gc=So   sc=Common     SQUARE MU M
    0x0003BD =>   12220,  #  ν  gc=Ll   sc=Greek      GREEK SMALL LETTER NU
    0x00039D =>      62,  #  Ν  gc=Lu   sc=Greek      GREEK CAPITAL LETTER NU
    0x0003BE =>    4484,  #  ξ  gc=Ll   sc=Greek      GREEK SMALL LETTER XI
    0x00039E =>     329,  #  Ξ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER XI
    0x0003BF =>     582,  #  ο  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON
    0x001F45 =>       2,  #  ὅ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON WITH DASIA AND OXIA
    0x001F44 =>       7,  #  ὄ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON WITH PSILI AND OXIA
    0x0003CC =>      49,  #  ό  gc=Ll   sc=Greek      GREEK SMALL LETTER OMICRON WITH TONOS
    0x00039F =>      25,  #  Ο  gc=Lu   sc=Greek      GREEK CAPITAL LETTER OMICRON
    0x0003D6 =>      90,  #  ϖ  gc=Ll   sc=Greek      GREEK PI SYMBOL
    0x0003C0 =>   21146,  #  π  gc=Ll   sc=Greek      GREEK SMALL LETTER PI
    0x0003A0 =>    1582,  #  Π  gc=Lu   sc=Greek      GREEK CAPITAL LETTER PI
    0x0003F1 =>      55,  #  ϱ  gc=Ll   sc=Greek      GREEK RHO SYMBOL
    0x0003C1 =>   18253,  #  ρ  gc=Ll   sc=Greek      GREEK SMALL LETTER RHO
    0x0003A1 =>      17,  #  Ρ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER RHO
    0x0003C2 =>     288,  #  ς  gc=Ll   sc=Greek      GREEK SMALL LETTER FINAL SIGMA
    0x0003C3 =>   44186,  #  σ  gc=Ll   sc=Greek      GREEK SMALL LETTER SIGMA
    0x0003A3 =>    9392,  #  Σ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER SIGMA
    0x0003C4 =>   29633,  #  τ  gc=Ll   sc=Greek      GREEK SMALL LETTER TAU
    0x0003A4 =>      72,  #  Τ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER TAU
    0x0003C5 =>    1449,  #  υ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON
    0x001F55 =>       2,  #  ὕ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH DASIA AND OXIA
    0x0003CB =>      18,  #  ϋ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH DIALYTIKA
    0x0003B0 =>      12,  #  ΰ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND TONOS
    0x001F50 =>       4,  #  ὐ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH PSILI
    0x0003CD =>      27,  #  ύ  gc=Ll   sc=Greek      GREEK SMALL LETTER UPSILON WITH TONOS
    0x0003A5 =>      54,  #  Υ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER UPSILON
    0x0003D2 =>     117,  #  ϒ  gc=Lu   sc=Greek      GREEK UPSILON WITH HOOK SYMBOL
    0x0003D5 =>   10025,  #  ϕ  gc=Ll   sc=Greek      GREEK PHI SYMBOL
    0x0003C6 =>   13777,  #  φ  gc=Ll   sc=Greek      GREEK SMALL LETTER PHI
    0x0003A6 =>   12067,  #  Φ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER PHI
    0x0003C7 =>   32188,  #  χ  gc=Ll   sc=Greek      GREEK SMALL LETTER CHI
    0x0003A7 =>     767,  #  Χ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER CHI
    0x0003C8 =>    8392,  #  ψ  gc=Ll   sc=Greek      GREEK SMALL LETTER PSI
    0x0003A8 =>    7927,  #  Ψ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER PSI
    0x0003C9 =>   20779,  #  ω  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA
    0x0003CE =>      42,  #  ώ  gc=Ll   sc=Greek      GREEK SMALL LETTER OMEGA WITH TONOS
    0x0003A9 =>    8698,  #  Ω  gc=Lu   sc=Greek      GREEK CAPITAL LETTER OMEGA
    0x00038F =>       2,  #  Ώ  gc=Lu   sc=Greek      GREEK CAPITAL LETTER OMEGA WITH TONOS
    0x002126 =>     267,  #  Ω  gc=Lu   sc=Greek      OHM SIGN
    0x0003EC =>      35,  #  Ϭ  gc=Lu   sc=Coptic     COPTIC CAPITAL LETTER SHIMA
    0x000430 =>      27,  #  а  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER A
    0x000410 =>       4,  #  А  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER A
    0x0004D9 =>       8,  #  ә  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER SCHWA
    0x000431 =>      10,  #  б  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER BE
    0x000432 =>       4,  #  в  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER VE
    0x000433 =>       2,  #  г  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER GHE
    0x000413 =>      46,  #  Г  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER GHE
    0x000434 =>       3,  #  д  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER DE
    0x000452 =>       1,  #  ђ  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER DJE
    0x000435 =>      10,  #  е  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER IE
    0x000415 =>       1,  #  Е  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER IE
    0x000454 =>      19,  #  є  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER UKRAINIAN IE
    0x000404 =>      23,  #  Є  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER UKRAINIAN IE
    0x000436 =>      11,  #  ж  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER ZHE
    0x000416 =>      28,  #  Ж  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER ZHE
    0x000437 =>       3,  #  з  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER ZE
    0x000417 =>       2,  #  З  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER ZE
    0x000438 =>      12,  #  и  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER I
    0x000418 =>      18,  #  И  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER I
    0x000456 =>       3,  #  і  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER BYELORUSSIAN-UKRAINIAN I
    0x000406 =>      30,  #  І  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER BYELORUSSIAN-UKRAINIAN I
    0x000457 =>      15,  #  ї  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER YI
    0x000439 =>       4,  #  й  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER SHORT I
    0x00043A =>      93,  #  к  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER KA
    0x00041A =>      21,  #  К  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER KA
    0x00043B =>       6,  #  л  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER EL
    0x00041B =>      21,  #  Л  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER EL
    0x00043C =>       4,  #  м  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER EM
    0x00041C =>      11,  #  М  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER EM
    0x00043D =>       5,  #  н  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER EN
    0x00041D =>       8,  #  Н  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER EN
    0x00043E =>       6,  #  о  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER O
    0x00041E =>       6,  #  О  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER O
    0x0004E7 =>       3,  #  ӧ  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER O WITH DIAERESIS
    0x0004E8 =>       1,  #  Ө  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER BARRED O
    0x00043F =>       2,  #  п  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER PE
    0x00041F =>      26,  #  П  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER PE
    0x000440 =>      16,  #  р  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER ER
    0x000420 =>       4,  #  Р  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER ER
    0x000441 =>       7,  #  с  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER ES
    0x000421 =>      25,  #  С  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER ES
    0x000442 =>       4,  #  т  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER TE
    0x000422 =>       5,  #  Т  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER TE
    0x00045B =>       2,  #  ћ  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER TSHE
    0x000443 =>       4,  #  у  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER U
    0x00045E =>       1,  #  ў  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER SHORT U
    0x0004B1 =>       6,  #  ұ  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER STRAIGHT U WITH STROKE
    0x0004B0 =>       7,  #  Ұ  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER STRAIGHT U WITH STROKE
    0x000444 =>       7,  #  ф  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER EF
    0x000424 =>     234,  #  Ф  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER EF
    0x000445 =>       5,  #  х  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER HA
    0x0004B3 =>       1,  #  ҳ  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER HA WITH DESCENDER
    0x000447 =>       2,  #  ч  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER CHE
    0x000428 =>      19,  #  Ш  gc=Lu   sc=Cyrillic   CYRILLIC CAPITAL LETTER SHA
    0x00044A =>       1,  #  ъ  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER HARD SIGN
    0x00044B =>       5,  #  ы  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER YERU
    0x00044C =>       1,  #  ь  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER SOFT SIGN
    0x00044E =>       1,  #  ю  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER YU
    0x00044F =>       3,  #  я  gc=Ll   sc=Cyrillic   CYRILLIC SMALL LETTER YA
    0x002135 =>      42,  #  ℵ  gc=Lo   sc=Common     ALEF SYMBOL
    0x0005D0 =>       1,  #  א  gc=Lo   sc=Hebrew     HEBREW LETTER ALEF
    0x0005D1 =>       1,  #  ב  gc=Lo   sc=Hebrew     HEBREW LETTER BET
    0x002138 =>       2,  #  ℸ  gc=Lo   sc=Common     DALET SYMBOL
    0x0005DA =>       1,  #  ך  gc=Lo   sc=Hebrew     HEBREW LETTER FINAL KAF
    0x0005DB =>       9,  #  כ  gc=Lo   sc=Hebrew     HEBREW LETTER KAF
    0x0005DD =>       1,  #  ם  gc=Lo   sc=Hebrew     HEBREW LETTER FINAL MEM
    0x0005DE =>       1,  #  מ  gc=Lo   sc=Hebrew     HEBREW LETTER MEM
    0x0005DF =>       1,  #  ן  gc=Lo   sc=Hebrew     HEBREW LETTER FINAL NUN
    0x0005E0 =>       1,  #  נ  gc=Lo   sc=Hebrew     HEBREW LETTER NUN
    0x0005E3 =>       1,  #  ף  gc=Lo   sc=Hebrew     HEBREW LETTER FINAL PE
    0x0005E4 =>       2,  #  פ  gc=Lo   sc=Hebrew     HEBREW LETTER PE
    0x0005E5 =>       3,  #  ץ  gc=Lo   sc=Hebrew     HEBREW LETTER FINAL TSADI
    0x0005E6 =>       1,  #  צ  gc=Lo   sc=Hebrew     HEBREW LETTER TSADI
    0x0005E7 =>       1,  #  ק  gc=Lo   sc=Hebrew     HEBREW LETTER QOF
    0x000627 =>       1,  #  ا  gc=Lo   sc=Arabic     ARABIC LETTER ALEF
    0x000628 =>       1,  #  ب  gc=Lo   sc=Arabic     ARABIC LETTER BEH
    0x00062A =>       1,  #  ت  gc=Lo   sc=Arabic     ARABIC LETTER TEH
    0x00062B =>       1,  #  ث  gc=Lo   sc=Arabic     ARABIC LETTER THEH
    0x000646 =>       1,  #  ن  gc=Lo   sc=Arabic     ARABIC LETTER NOON
    0x000647 =>       4,  #  ه  gc=Lo   sc=Arabic     ARABIC LETTER HEH
    0x000648 =>       1,  #  و  gc=Lo   sc=Arabic     ARABIC LETTER WAW
    0x00064A =>       1,  #  ي  gc=Lo   sc=Arabic     ARABIC LETTER YEH
    0x003131 =>       1,  #  ㄱ gc=Lo   sc=Hangul     HANGUL LETTER KIYEOK
    0x00AC00 =>       2,  #  가 gc=Lo   sc=Hangul     HANGUL SYLLABLE GA
    0x00AC01 =>       4,  #  각 gc=Lo   sc=Hangul     HANGUL SYLLABLE GAG
    0x00AC04 =>       5,  #  간 gc=Lo   sc=Hangul     HANGUL SYLLABLE GAN
    0x00AC19 =>       2,  #  같 gc=Lo   sc=Hangul     HANGUL SYLLABLE GAT
    0x00AC83 =>       3,  #  것 gc=Lo   sc=Hangul     HANGUL SYLLABLE GEOS
    0x00AC8C =>       2,  #  게 gc=Lo   sc=Hangul     HANGUL SYLLABLE GE
    0x00ACBD =>       1,  #  경 gc=Lo   sc=Hangul     HANGUL SYLLABLE GYEONG
    0x00ACE0 =>       7,  #  고 gc=Lo   sc=Hangul     HANGUL SYLLABLE GO
    0x00ACFC =>       5,  #  과 gc=Lo   sc=Hangul     HANGUL SYLLABLE GWA
    0x00AD50 =>       2,  #  교 gc=Lo   sc=Hangul     HANGUL SYLLABLE GYO
    0x00AD6C =>       2,  #  구 gc=Lo   sc=Hangul     HANGUL SYLLABLE GU
    0x00AD6D =>      37,  #  국 gc=Lo   sc=Hangul     HANGUL SYLLABLE GUG
    0x00ADDC =>       2,  #  규 gc=Lo   sc=Hangul     HANGUL SYLLABLE GYU
    0x00ADFC =>       2,  #  근 gc=Lo   sc=Hangul     HANGUL SYLLABLE GEUN
    0x00AE4C =>      20,  #  까 gc=Lo   sc=Hangul     HANGUL SYLLABLE GGA
    0x00B098 =>       5,  #  나 gc=Lo   sc=Hangul     HANGUL SYLLABLE NA
    0x00B0B8 =>       1,  #  낸 gc=Lo   sc=Hangul     HANGUL SYLLABLE NAEN
    0x00B144 =>       6,  #  년 gc=Lo   sc=Hangul     HANGUL SYLLABLE NYEON
    0x00B290 =>       4,  #  느 gc=Lo   sc=Hangul     HANGUL SYLLABLE NEU
    0x00B294 =>       8,  #  는 gc=Lo   sc=Hangul     HANGUL SYLLABLE NEUN
    0x00B2C8 =>      21,  #  니 gc=Lo   sc=Hangul     HANGUL SYLLABLE NI
    0x00B2E4 =>      18,  #  다 gc=Lo   sc=Hangul     HANGUL SYLLABLE DA
    0x00B2F9 =>       3,  #  당 gc=Lo   sc=Hangul     HANGUL SYLLABLE DANG
    0x00B300 =>      10,  #  대 gc=Lo   sc=Hangul     HANGUL SYLLABLE DAE
    0x00B354 =>       5,  #  더 gc=Lo   sc=Hangul     HANGUL SYLLABLE DEO
    0x00B358 =>       2,  #  던 gc=Lo   sc=Hangul     HANGUL SYLLABLE DEON
    0x00B3C4 =>       4,  #  도 gc=Lo   sc=Hangul     HANGUL SYLLABLE DO
    0x00B418 =>       2,  #  되 gc=Lo   sc=Hangul     HANGUL SYLLABLE DOE
    0x00B41C =>       6,  #  된 gc=Lo   sc=Hangul     HANGUL SYLLABLE DOEN
    0x00B429 =>       2,  #  됩 gc=Lo   sc=Hangul     HANGUL SYLLABLE DOEB
    0x00B458 =>       1,  #  둘 gc=Lo   sc=Hangul     HANGUL SYLLABLE DUL
    0x00B4E4 =>       3,  #  들 gc=Lo   sc=Hangul     HANGUL SYLLABLE DEUL
    0x00B514 =>       2,  #  디 gc=Lo   sc=Hangul     HANGUL SYLLABLE DI
    0x00B54C =>       2,  #  때 gc=Lo   sc=Hangul     HANGUL SYLLABLE DDAE
    0x00B5A4 =>       3,  #  떤 gc=Lo   sc=Hangul     HANGUL SYLLABLE DDEON
    0x00B77C =>       6,  #  라 gc=Lo   sc=Hangul     HANGUL SYLLABLE RA
    0x00B78C =>       3,  #  람 gc=Lo   sc=Hangul     HANGUL SYLLABLE RAM
    0x00B838 =>       2,  #  렸 gc=Lo   sc=Hangul     HANGUL SYLLABLE RYEOSS
    0x00B85C =>       9,  #  로 gc=Lo   sc=Hangul     HANGUL SYLLABLE RO
    0x00B85D =>       2,  #  록 gc=Lo   sc=Hangul     HANGUL SYLLABLE ROG
    0x00B958 =>       2,  #  류 gc=Lo   sc=Hangul     HANGUL SYLLABLE RYU
    0x00B9C8 =>       2,  #  마 gc=Lo   sc=Hangul     HANGUL SYLLABLE MA
    0x00B9CC =>       8,  #  만 gc=Lo   sc=Hangul     HANGUL SYLLABLE MAN
    0x00B9D0 =>       6,  #  말 gc=Lo   sc=Hangul     HANGUL SYLLABLE MAL
    0x00BA70 =>       1,  #  며 gc=Lo   sc=Hangul     HANGUL SYLLABLE MYEO
    0x00BA74 =>       2,  #  면 gc=Lo   sc=Hangul     HANGUL SYLLABLE MYEON
    0x00BA87 =>       6,  #  몇 gc=Lo   sc=Hangul     HANGUL SYLLABLE MYEOC
    0x00BAA8 =>       1,  #  모 gc=Lo   sc=Hangul     HANGUL SYLLABLE MO
    0x00BAA9 =>       2,  #  목 gc=Lo   sc=Hangul     HANGUL SYLLABLE MOG
    0x00BBF8 =>       5,  #  미 gc=Lo   sc=Hangul     HANGUL SYLLABLE MI
    0x00BC18 =>       6,  #  반 gc=Lo   sc=Hangul     HANGUL SYLLABLE BAN
    0x00BC30 =>       1,  #  배 gc=Lo   sc=Hangul     HANGUL SYLLABLE BAE
    0x00BCF4 =>       2,  #  보 gc=Lo   sc=Hangul     HANGUL SYLLABLE BO
    0x00BCF8 =>       7,  #  본 gc=Lo   sc=Hangul     HANGUL SYLLABLE BON
    0x00BD80 =>      14,  #  부 gc=Lo   sc=Hangul     HANGUL SYLLABLE BU
    0x00BD84 =>      10,  #  분 gc=Lo   sc=Hangul     HANGUL SYLLABLE BUN
    0x00BE44 =>       4,  #  비 gc=Lo   sc=Hangul     HANGUL SYLLABLE BI
    0x00C0AC =>       5,  #  사 gc=Lo   sc=Hangul     HANGUL SYLLABLE SA
    0x00C0B4 =>       3,  #  살 gc=Lo   sc=Hangul     HANGUL SYLLABLE SAL
    0x00C0DD =>       4,  #  생 gc=Lo   sc=Hangul     HANGUL SYLLABLE SAENG
    0x00C11C =>       8,  #  서 gc=Lo   sc=Hangul     HANGUL SYLLABLE SEO
    0x00C120 =>       2,  #  선 gc=Lo   sc=Hangul     HANGUL SYLLABLE SEON
    0x00C12F =>       2,  #  섯 gc=Lo   sc=Hangul     HANGUL SYLLABLE SEOS
    0x00C131 =>       1,  #  성 gc=Lo   sc=Hangul     HANGUL SYLLABLE SEONG
    0x00C138 =>       1,  #  세 gc=Lo   sc=Hangul     HANGUL SYLLABLE SE
    0x00C168 =>       6,  #  셨 gc=Lo   sc=Hangul     HANGUL SYLLABLE SYEOSS
    0x00C218 =>       1,  #  수 gc=Lo   sc=Hangul     HANGUL SYLLABLE SU
    0x00C2B5 =>       8,  #  습 gc=Lo   sc=Hangul     HANGUL SYLLABLE SEUB
    0x00C2B7 =>       2,  #  슷 gc=Lo   sc=Hangul     HANGUL SYLLABLE SEUS
    0x00C2DC =>       1,  #  시 gc=Lo   sc=Hangul     HANGUL SYLLABLE SI
    0x00C2E0 =>       3,  #  신 gc=Lo   sc=Hangul     HANGUL SYLLABLE SIN
    0x00C2E4 =>       1,  #  실 gc=Lo   sc=Hangul     HANGUL SYLLABLE SIL
    0x00C2ED =>       7,  #  십 gc=Lo   sc=Hangul     HANGUL SYLLABLE SIB
    0x00C4F0 =>       3,  #  쓰 gc=Lo   sc=Hangul     HANGUL SYLLABLE SSEU
    0x00C500 =>       1,  #  씀 gc=Lo   sc=Hangul     HANGUL SYLLABLE SSEUM
    0x00C529 =>       1,  #  씩 gc=Lo   sc=Hangul     HANGUL SYLLABLE SSIG
    0x00C544 =>       2,  #  아 gc=Lo   sc=Hangul     HANGUL SYLLABLE A
    0x00C545 =>      14,  #  악 gc=Lo   sc=Hangul     HANGUL SYLLABLE AG
    0x00C57D =>       1,  #  약 gc=Lo   sc=Hangul     HANGUL SYLLABLE YAG
    0x00C591 =>       1,  #  양 gc=Lo   sc=Hangul     HANGUL SYLLABLE YANG
    0x00C5B4 =>      22,  #  어 gc=Lo   sc=Hangul     HANGUL SYLLABLE EO
    0x00C5D0 =>      13,  #  에 gc=Lo   sc=Hangul     HANGUL SYLLABLE E
    0x00C5EC =>       2,  #  여 gc=Lo   sc=Hangul     HANGUL SYLLABLE YEO
    0x00C601 =>       8,  #  영 gc=Lo   sc=Hangul     HANGUL SYLLABLE YEONG
    0x00C624 =>       1,  #  오 gc=Lo   sc=Hangul     HANGUL SYLLABLE O
    0x00C678 =>      10,  #  외 gc=Lo   sc=Hangul     HANGUL SYLLABLE OE
    0x00C6B8 =>       2,  #  울 gc=Lo   sc=Hangul     HANGUL SYLLABLE UL
    0x00C73C =>       4,  #  으 gc=Lo   sc=Hangul     HANGUL SYLLABLE EU
    0x00C740 =>       3,  #  은 gc=Lo   sc=Hangul     HANGUL SYLLABLE EUN
    0x00C744 =>      13,  #  을 gc=Lo   sc=Hangul     HANGUL SYLLABLE EUL
    0x00C74C =>      15,  #  음 gc=Lo   sc=Hangul     HANGUL SYLLABLE EUM
    0x00C758 =>       4,  #  의 gc=Lo   sc=Hangul     HANGUL SYLLABLE YI
    0x00C774 =>      11,  #  이 gc=Lo   sc=Hangul     HANGUL SYLLABLE I
    0x00C778 =>      14,  #  인 gc=Lo   sc=Hangul     HANGUL SYLLABLE IN
    0x00C77C =>       1,  #  일 gc=Lo   sc=Hangul     HANGUL SYLLABLE IL
    0x00C77D =>       6,  #  읽 gc=Lo   sc=Hangul     HANGUL SYLLABLE ILG
    0x00C785 =>       2,  #  입 gc=Lo   sc=Hangul     HANGUL SYLLABLE IB
    0x00C788 =>       3,  #  있 gc=Lo   sc=Hangul     HANGUL SYLLABLE ISS
    0x00C790 =>       3,  #  자 gc=Lo   sc=Hangul     HANGUL SYLLABLE JA
    0x00C798 =>       4,  #  잘 gc=Lo   sc=Hangul     HANGUL SYLLABLE JAL
    0x00C7A5 =>       1,  #  장 gc=Lo   sc=Hangul     HANGUL SYLLABLE JANG
    0x00C801 =>       2,  #  적 gc=Lo   sc=Hangul     HANGUL SYLLABLE JEOG
    0x00C804 =>       4,  #  전 gc=Lo   sc=Hangul     HANGUL SYLLABLE JEON
    0x00C815 =>       4,  #  정 gc=Lo   sc=Hangul     HANGUL SYLLABLE JEONG
    0x00C885 =>       4,  #  종 gc=Lo   sc=Hangul     HANGUL SYLLABLE JONG
    0x00C8FC =>       1,  #  주 gc=Lo   sc=Hangul     HANGUL SYLLABLE JU
    0x00C911 =>       7,  #  중 gc=Lo   sc=Hangul     HANGUL SYLLABLE JUNG
    0x00C9C0 =>       6,  #  지 gc=Lo   sc=Hangul     HANGUL SYLLABLE JI
    0x00CC45 =>       7,  #  책 gc=Lo   sc=Hangul     HANGUL SYLLABLE CAEG
    0x00CD5C =>       2,  #  최 gc=Lo   sc=Hangul     HANGUL SYLLABLE COE
    0x00CE58 =>       2,  #  치 gc=Lo   sc=Hangul     HANGUL SYLLABLE CI
    0x00CE5C =>       2,  #  친 gc=Lo   sc=Hangul     HANGUL SYLLABLE CIN
    0x00D0C0 =>       1,  #  타 gc=Lo   sc=Hangul     HANGUL SYLLABLE TA
    0x00D2B9 =>       1,  #  특 gc=Lo   sc=Hangul     HANGUL SYLLABLE TEUG
    0x00D3B8 =>       1,  #  편 gc=Lo   sc=Hangul     HANGUL SYLLABLE PYEON
    0x00D558 =>       7,  #  하 gc=Lo   sc=Hangul     HANGUL SYLLABLE HA
    0x00D559 =>       4,  #  학 gc=Lo   sc=Hangul     HANGUL SYLLABLE HAG
    0x00D55C =>      24,  #  한 gc=Lo   sc=Hangul     HANGUL SYLLABLE HAN
    0x00D560 =>       1,  #  할 gc=Lo   sc=Hangul     HANGUL SYLLABLE HAL
    0x00D56D =>       2,  #  항 gc=Lo   sc=Hangul     HANGUL SYLLABLE HANG
    0x00D574 =>       4,  #  해 gc=Lo   sc=Hangul     HANGUL SYLLABLE HAE
    0x00D638 =>       2,  #  호 gc=Lo   sc=Hangul     HANGUL SYLLABLE HO
    0x00D6C4 =>       1,  #  후 gc=Lo   sc=Hangul     HANGUL SYLLABLE HU
    0x00FF95 =>       1,  #  ﾕ  gc=Lo   sc=Katakana   HALFWIDTH KATAKANA LETTER YU
    0x006240 =>       2,  #  所 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-6240
    0x006587 =>       2,  #  文 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-6587
    0x006709 =>       2,  #  有 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-6709
    0x00689D =>       2,  #  條 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-689D
    0x007368 =>       1,  #  獨 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-7368
    0x007974 =>       1,  #  祴 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-7974
    0x008230 =>       1,  #  舰 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-8230
    0x008713 =>       3,  #  蜓 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-8713
    0x009792 =>       1,  #  鞒 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-9792
    0x009794 =>       1,  #  鞔 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-9794
    0x0036E7 =>       1,  #  㛧 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-36E7
    0x0036E8 =>       1,  #  㛨 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-36E8
    0x0036E9 =>       1,  #  㛩 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-36E9
    0x0036EA =>       1,  #  㛪 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-36EA
    0x0036EB =>       1,  #  㛫 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-36EB
    0x0036EC =>       1,  #  㛬 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-36EC
    0x0036ED =>       1,  #  㛭 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-36ED
    0x0036EE =>       1,  #  㛮 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-36EE
    0x0036EF =>       1,  #  㛯 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-36EF
    0x003B12 =>       1,  #  㬒 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-3B12
    0x003B21 =>       1,  #  㬡 gc=Lo   sc=Han        CJK UNIFIED IDEOGRAPH-3B21
    0x000085 =>     264,  # <--->gc=Cc   sc=Common     <control>
    0x000086 =>      14,  # <--->gc=Cc   sc=Common     <control>
    0x002061 =>   10097,  # <--->gc=Cf   sc=Common     FUNCTION APPLICATION
    0x00206C =>      17,  # <--->gc=Cf   sc=Common     INHIBIT ARABIC FORM SHAPING
    0x00206A =>       1,  # <--->gc=Cf   sc=Common     INHIBIT SYMMETRIC SWAPPING
    0x002062 =>     204,  # <--->gc=Cf   sc=Common     INVISIBLE TIMES
    0x00202A =>       1,  # <--->gc=Cf   sc=Common     LEFT-TO-RIGHT EMBEDDING
    0x00200E =>       5,  # <--->gc=Cf   sc=Common     LEFT-TO-RIGHT MARK
    0x0000AD =>    3587,  # <--->gc=Cf   sc=Common     SOFT HYPHEN
    0x00FEFF =>       9,  # <--->gc=Cf   sc=Common     ZERO WIDTH NO-BREAK SPACE
    0x00200B =>     128,  # <--->gc=Cf   sc=Common     ZERO WIDTH SPACE
    0x00200D =>      59,  # <--->gc=Cf   sc=Inherited  ZERO WIDTH JOINER
    0x100002 =>       2,  # <--->gc=Co   sc=Unknown    <unnamed code point in block=Supplementary Private Use Area-B>
    0x002028 =>   10940,  # <--->gc=Zl   sc=Common     LINE SEPARATOR
    0x002003 =>  602377,  # <--->gc=Zs   sc=Common     EM SPACE
    0x002000 =>       1,  # <--->gc=Zs   sc=Common     EN QUAD
    0x002002 =>    8517,  # <--->gc=Zs   sc=Common     EN SPACE
    0x002007 =>     422,  # <--->gc=Zs   sc=Common     FIGURE SPACE
    0x002005 =>   21027,  # <--->gc=Zs   sc=Common     FOUR-PER-EM SPACE
    0x00200A =>  491842,  # <--->gc=Zs   sc=Common     HAIR SPACE
    0x003000 =>      17,  # <--->gc=Zs   sc=Common     IDEOGRAPHIC SPACE
    0x00205F =>      28,  # <--->gc=Zs   sc=Common     MEDIUM MATHEMATICAL SPACE
    0x00202F =>    1682,  # <--->gc=Zs   sc=Common     NARROW NO-BREAK SPACE
    0x0000A0 => 1065594,  # <--->gc=Zs   sc=Common     NO-BREAK SPACE
    0x002008 =>     702,  # <--->gc=Zs   sc=Common     PUNCTUATION SPACE
    0x002006 =>      90,  # <--->gc=Zs   sc=Common     SIX-PER-EM SPACE
    0x002009 =>  420888,  # <--->gc=Zs   sc=Common     THIN SPACE
    0x002004 =>      26,  # <--->gc=Zs   sc=Common     THREE-PER-EM SPACE
    0x0020DE =>     217,  # ◌ ⃞  gc=Me   sc=Inherited  COMBINING ENCLOSING SQUARE
    0x000597 =>       2,  # ◌ ֗  gc=Mn   sc=Hebrew     HEBREW ACCENT REVIA
    0x0005BF =>       2,  # ◌ ֿ  gc=Mn   sc=Hebrew     HEBREW POINT RAFE
    0x000652 =>       1,  # ◌ ْ  gc=Mn   sc=Inherited  ARABIC SUKUN
    0x000301 =>      40,  # ◌ ́  gc=Mn   sc=Inherited  COMBINING ACUTE ACCENT
    0x000341 =>       5,  # ◌ ́  gc=Mn   sc=Inherited  COMBINING ACUTE TONE MARK
    0x000306 =>      19,  # ◌ ̆  gc=Mn   sc=Inherited  COMBINING BREVE
    0x00030C =>       3,  # ◌ ̌  gc=Mn   sc=Inherited  COMBINING CARON
    0x000327 =>       8,  # ◌ ̧  gc=Mn   sc=Inherited  COMBINING CEDILLA
    0x000302 =>    1249,  # ◌ ̂  gc=Mn   sc=Inherited  COMBINING CIRCUMFLEX ACCENT
    0x000308 =>       6,  # ◌ ̈  gc=Mn   sc=Inherited  COMBINING DIAERESIS
    0x000307 =>     458,  # ◌ ̇  gc=Mn   sc=Inherited  COMBINING DOT ABOVE
    0x000358 =>       3,  # ◌ ͘  gc=Mn   sc=Inherited  COMBINING DOT ABOVE RIGHT
    0x000323 =>       7,  # ◌ ̣  gc=Mn   sc=Inherited  COMBINING DOT BELOW
    0x000323 =>       6,  # ◌ ̣  gc=Mn   sc=Inherited  COMBINING DOT BELOW
    0x00030B =>       3,  # ◌ ̋  gc=Mn   sc=Inherited  COMBINING DOUBLE ACUTE ACCENT
    0x000300 =>      85,  # ◌ ̀  gc=Mn   sc=Inherited  COMBINING GRAVE ACCENT
    0x000344 =>       1,  # ◌ ̈́  gc=Mn   sc=Inherited  COMBINING GREEK DIALYTIKA TONOS
    0x000343 =>       1,  # ◌ ̓  gc=Mn   sc=Inherited  COMBINING GREEK KORONIS
    0x000342 =>      55,  # ◌ ͂  gc=Mn   sc=Inherited  COMBINING GREEK PERISPOMENI
    0x000311 =>       9,  # ◌ ̑  gc=Mn   sc=Inherited  COMBINING INVERTED BREVE
    0x000332 =>     150,  # ◌ ̲  gc=Mn   sc=Inherited  COMBINING LOW LINE
    0x000304 =>     624,  # ◌ ̄  gc=Mn   sc=Inherited  COMBINING MACRON
    0x000304 =>       1,  # ◌ ̄  gc=Mn   sc=Inherited  COMBINING MACRON
    0x000328 =>       1,  # ◌ ̨  gc=Mn   sc=Inherited  COMBINING OGONEK
    0x000305 =>    1093,  # ◌ ̅  gc=Mn   sc=Inherited  COMBINING OVERLINE
    0x0020D7 =>     335,  # ◌ ⃗  gc=Mn   sc=Inherited  COMBINING RIGHT ARROW ABOVE
    0x0020D1 =>       8,  # ◌ ⃑  gc=Mn   sc=Inherited  COMBINING RIGHT HARPOON ABOVE
    0x00030A =>      35,  # ◌ ̊  gc=Mn   sc=Inherited  COMBINING RING ABOVE
    0x000337 =>       6,  # ◌ ̷  gc=Mn   sc=Inherited  COMBINING SHORT SOLIDUS OVERLAY
    0x000335 =>      11,  # ◌ ̵  gc=Mn   sc=Inherited  COMBINING SHORT STROKE OVERLAY
    0x0020DB =>       3,  # ◌ ⃛  gc=Mn   sc=Inherited  COMBINING THREE DOTS ABOVE
    0x000303 =>     440,  # ◌ ̃  gc=Mn   sc=Inherited  COMBINING TILDE
    0x00FE00 =>      12,  # ◌ ︀  gc=Mn   sc=Inherited  VARIATION SELECTOR-1
    0x001036 =>       1,  # ◌ ံ  gc=Mn   sc=Myanmar    MYANMAR SIGN ANUSVARA
    0x000EBC =>       1,  # ◌ ຼ  gc=Mn   sc=Lao        LAO SEMIVOWEL SIGN LO
    0x000F9E =>       1,  # ◌ ྞ  gc=Mn   sc=Tibetan    TIBETAN SUBJOINED LETTER NNA

);

%default_training_data = %pmcoa_training;

}


1; # End of Lingua::EN::ByteEncoded

__END__

=head1 NAME

Encode::Guess::Educated - do something

=head1 SYNOPSIS

XXX: this section needs to be written

=head1 DESCRIPTION

XXX: this section needs to be written

=head1 FILES

XXX: this section needs to be written

=head1 ENVIRONMENT

XXX: this section needs to be written

=head1 CAVEATS

XXX: this section needs to be written

=head1 BUGS

XXX: this section needs to be written

=head1 SEE ALSO

XXX: this section needs to be written

=head1 AUTHOR

Tom Christiansen <I<tchrist@perl.com>>

=head1 COPYRIGHT AND LICENCE

Copyright 2012 Tom Christiansen.

This program is free software; you may redistribute it 
and/or modify it under the same terms as Perl itself.
