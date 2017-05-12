package Log::Shiras::Types;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare("v0.48.0");
use strict;
use warnings;
#~ use lib '../../';
#~ use Log::Shiras::Unhide qw( :InternalTypeSShirasFormat :InternalTypeSFileHash :InternalTypeSReportObject :InternalTypeSHeadeR);
###InternalTypeSShirasFormat	use Data::Dumper;
###InternalTypeSFileHash		use Data::Dumper;
###InternalTypeSReportObject	use Data::Dumper;
###InternalTypeSHeadeR			use Data::Dumper;
use utf8;
use Carp qw( confess );
use IO::File;
use FileHandle;
use Fcntl qw( :flock LOCK_EX );# SEEK_END
use MooseX::ShortCut::BuildInstance v1.42 qw( build_instance should_re_use_classes );
should_re_use_classes( 1 );
use MooseX::Types::Moose qw(
		ArrayRef			Int					Str					HashRef
		Object				Undef				GlobRef				FileHandle
	);
#~ use MooseX::Types::Structured qw( Optional );
use MooseX::Types -declare =>[qw(
		ElevenArray			PosInt				NewModifier			ElevenInt
		ShirasFormat		TextFile			HeaderString		YamlFile
		FileHash			JsonFile			ArgsHash			ReportObject
		NameSpace			CSVFile				XLSXFile			XLSFile
		XMLFile				IOFileType			HeaderArray
	)];#
#~ use YAML::Any qw( Dump LoadFile );
use JSON::XS;

#########1 Package Variables  3#########4#########5#########6#########7#########8#########9

my	$standard_char	= qr/[csduoxefgXEGbB]/;		# Legacy conversions not supported
my	$producer_char	= qr/[pn%]/;  				# sprintf standards that don't take arguments
my	$new_type_char	= qr/[MPO]/;				# M = method style, P = passed data style, O = object style
my	$split_regex	= qr/
        ([^%]*)							# inserted string
        (%([^%]*?)			# get modifiers
			(	($producer_char)|		# get terminator characters
				($standard_char)))	#
    /x;
my	$sprintf_dispatch =[
		[ \&_append_to_string, ],# 0
		[ \&_alt_position, \&_does_not_consume, \&_append_to_string, ], # 1
		[ sub{ $_[1] }, ],# pass through # 2
		[ sub{ $_[1] }, ],# pass through # 3
		[ \&_append_to_string, \&_set_consumption, ], # 4
		[ \&_append_to_string, \&_remove_consumption, ],# 5
		[ \&_append_to_string, ], # 6
		[ sub{ $_[1] }, ],# pass through # 7
		[ sub{ $_[1] }, ],# pass through # 8
		[ \&_append_to_string, \&_set_consumption, ], # 9
		[ \&_append_to_string, \&_remove_consumption, ], # 10
		[ \&_append_to_string, ],# 11
		[ sub{ $_[1] }, ],# pass through # 12
		[ \&_append_to_string, ], # 13
		[ sub{ $_[1] }, ],# pass through # 14
		[ \&_append_to_string, \&_set_consumption, ], # 15
		[ \&_append_to_string, ], # 17
		[ \&_test_for_position_change, \&_does_not_consume, \&_set_insert_call, ], # 18
		[ sub{ $_[1] }, ],# pass through # 19
		[ \&_append_to_string, \&_set_consumption, ], # 20
		[ \&_append_to_string, ], # 21
		[ sub{ confess "No methods here!!" }, ],# 22
		[ sub{ confess "No methods here!!" }, ],# 23
	];
my  $sprintf_regex 	= qr/
		\A[%]      					# (required) sequence start
        ([\s\-\+0#]{0,2})       	# (optional) flag(s)
        ([1-9]\d*\$)?				# (optional) get the formatted value from
									#		some position other than the next position
        (((\*)([1-9]\d*\$)?)?		# (optional) vector flag with optional index and reference
			(v))?					#		for gathering a defined vector separator
        (							# (optional) minimum field width formatting
			((\*)([1-9]\d*\$)?)|	# 		get field from input with possible position call
            ([1-9]\d*)			)?	# 		fixed field size definition
        ((\.)(                  	# (optional) maximum field width formatting
			(\*)|					# 		get field from input with possible position call
            ([0-9]\d*)		))?		# 		fixed field size definition
			($new_type_char)?		# (optional) get input from a method or passed source
		(							# (required) conversion type
			($standard_char)|		#		standard character
			($producer_char)	)	#		producer character
        \Z                  		# End of the line
    /sxmp;
my	$shiras_format_ref = {
		final 		=> 1,
		alt_input 	=> 1,
		bump_list	=> 1,
	};
my  $TextFileext    = qr/[.](txt|csv)/;
my  $yamlextention	= qr/\.(?i)(yml|yaml)/;
my  $jsonextention	= qr/\.(?i)(jsn|json)/;
my  $coder 			= JSON::XS->new->ascii->pretty->allow_nonref;#
my 	$switchboard_attributes = [ qw(
		name_space_bounds reports buffering
		conf_file logging_levels
	) ];
our $recursion_block = 0;
use constant IMPORT_DEBUG => 1; # Author testing only

#########1 subtype Library    3#########4#########5#########6#########7#########8#########9

subtype ElevenArray, as ArrayRef,
    where{ scalar( @$_ ) < 13 },
    message{ "This goes past the eleventh position! :O" };

subtype PosInt, as Int,
    where{ $_ >= 0 },
    message{ "$_ is not a positive integer" };

subtype ElevenInt, as PosInt,
    where{ $_ < 12 },
    message{ "This goes past eleven! :O" };

subtype NewModifier, as Str,
    where{ $_ =~ /\A$new_type_char\Z/sxm },
    message{ "'$_' does not match $new_type_char" };

subtype ShirasFormat, as HashRef,
	where{ _has_shiras_keys( $_ ) },
    message { $_ };

###InternalTypeSShirasFormat	warn "You uncovered internal logging statements for the Type ShirasFormat in Log::Shiras::Types-$VERSION" if !$ENV{hide_warn};
coerce ShirasFormat, from Str,
    via {
        my ( $input, ) = @_;
###InternalTypeSShirasFormat	warn "passed: $input";
        my ( $x, $finished_ref, ) = ( 1, {} );
		my $escape_off = 1;
###InternalTypeSShirasFormat	warn "check for a pure sprintf string";
		if( $input !~ /{/ ){
###InternalTypeSShirasFormat	warn "no need to pre parse this string ...";
			return { final => $input };
		}else{
###InternalTypeSShirasFormat	warn "manage new formats ...";
			my $start = 1;
			while( $input =~ /([^%]*)%([^%]*)/g ){
				my  $pre = $1;
				my  $post = $2;
###InternalTypeSShirasFormat	warn "pre: $pre";
###InternalTypeSShirasFormat	warn "post: $post";
				if( $start ){#
					push @{$finished_ref->{init_parse}}, $pre;
					$start = 0;
				}elsif( $pre ){
					return "Coersion to 'ShirasFormat' failed for section -$pre- in " .
						__FILE__ . " at line " . __LINE__ . ".\n";
				}
				if( $post =~ /^([^{]*)\{([^}]*)\}(.)(\(([^)]*)\))?(.*)$/ ){
					my @list = ( $1, $2, $3, $4, $5, $6 );
###InternalTypeSShirasFormat	warn "list:" . Dumper( @list );
					if( !is_NewModifier( $list[2] ) ){
						return "Coersion to 'ShirasFormat' failed because of an " .
						"unrecognized modifier -$list[2]- found in format string -" .
						$post . "- by ". __FILE__ . " at line " . __LINE__ . ".\n";
					}
					push @{$finished_ref->{alt_input}}, [ @list[1,2,4] ];
					push @{$finished_ref->{init_parse}}, join '', @list[0,2,5];
				}elsif( $post =~ /[{}]/ ){
					return "Coersion to 'ShirasFormat' failed for section -$post- " .
					"using " . __FILE__ . " at line " . __LINE__ . ".\n";
				}else{
					push @{$finished_ref->{init_parse}}, $post;
				}
###InternalTypeSShirasFormat	warn "finished ref:" . Dumper( $finished_ref );
			}
			$input = join '%', @{$finished_ref->{init_parse}};
			delete $finished_ref->{init_parse};
###InternalTypeSShirasFormat	warn "current sprintf ref:" . Dumper( $input );
		}
###InternalTypeSShirasFormat	warn "build input array modifications ...";
		my	$parsed_length = 0;
		my  $total_length = length( $input );
		while( $input =~ /$split_regex/g ){
			my @list = ( $1, $2, $3, $4, $5, $6 );#
###InternalTypeSShirasFormat	warn "matched:" . Dumper( @list );
###InternalTypeSShirasFormat	warn "for segment: $&";
			if( $list[2] and $list[4] and $list[4] eq '%' ){
				return "Coersion to 'ShirasFormat' failed for the segment: " .
					$list[1] . " using " . __FILE__ . " at line " .
					__LINE__ . ".\n";
			}
			my  $pre_string				= $list[0];
			$finished_ref->{string}   .= $list[0] if $list[0];
			$finished_ref->{new_chunk}	= $list[1];
			my 	$consumer_format 		= $list[5];
			my	$producer_format		= $list[4];
				$parsed_length	   	   +=
					length( $finished_ref->{new_chunk} ) + length( $pre_string );
				$input					= ${^POSTMATCH};
			my  $pre_match				= ${^PREMATCH};
			my  $finished_length		= $total_length - length( $input );
###InternalTypeSShirasFormat	warn "length of chunk: $finished_ref->{new_chunk}";
###InternalTypeSShirasFormat	warn "parsed length: $parsed_length";
###InternalTypeSShirasFormat	warn "finished length: $finished_length";
###InternalTypeSShirasFormat	warn "pre match: $pre_match";
###InternalTypeSShirasFormat	warn "remaining: $input";
###InternalTypeSShirasFormat	warn "producer: $producer_format";
###InternalTypeSShirasFormat	warn "consumer: $consumer_format";
			if( $finished_length != $parsed_length ){
				return "Coersion to 'ShirasFormat' failed for the modified " .
					"sprintf segment -$pre_match- using " .
					__FILE__ . " at line " . __LINE__ . ".\n";
			}
			if( $producer_format or $consumer_format ){
			#	$finished_ref = _process_producer_format( $finished_ref );
			# }elsif( $consumer_format ){
				$finished_ref = _process_sprintf_format( $finished_ref );
			}else{
				delete $finished_ref->{new_chunk};
				next;
			}

			if( !is_HashRef( $finished_ref ) ){
###InternalTypeSShirasFormat	warn "fail:" . Dumper( $finished_ref );
				return $finished_ref;
			}
			delete $finished_ref->{new_chunk};
###InternalTypeSShirasFormat	warn "current:" . Dumper( $finished_ref);
			$x++;
###InternalTypeSShirasFormat	warn "current input:" . Dumper( $input );
        }
###InternalTypeSShirasFormat	warn "finished ref:" . Dumper( $finished_ref );
###InternalTypeSShirasFormat	warn "input length: " . length( $input );
		if( $input and $finished_ref->{string} !~ /$input$/ ){
			$finished_ref->{string} .= $input;
		}
###InternalTypeSShirasFormat	warn "reviewing:" . Dumper( $finished_ref );
		my	$parsing_string = $finished_ref->{string};
###InternalTypeSShirasFormat	warn "parsing_string: $parsing_string";
		delete $finished_ref->{bump_count};
		delete $finished_ref->{alt_position};
		while( $parsing_string =~ /(\d+)([\$])/ ){
			$finished_ref->{final} .= ${^PREMATCH};
			$parsing_string = ${^POSTMATCH};
###InternalTypeSShirasFormat	warn "updated:" . Dumper( $finished_ref );
###InternalTypeSShirasFormat	warn "parsing string: $parsing_string";
			my $digits = $1;
			my $position = $digits - 1;
			if( exists $finished_ref->{bump_list}->[$position] ){
				$digits += $finished_ref->{bump_list}->[$position];
			}
###InternalTypeSShirasFormat	warn "digits: $digits";
###InternalTypeSShirasFormat	warn "position: $position";
			$finished_ref->{final} .= $digits;
			$finished_ref->{final} .= '$';
###InternalTypeSShirasFormat	warn "updated:" . Dumper( $finished_ref );
		}
		$finished_ref->{final} .= $parsing_string;
		delete $finished_ref->{string};
###InternalTypeSShirasFormat	warn "returning:" . Dumper( $finished_ref );
		return $finished_ref;
    };

subtype TextFile, as Str,
    message {  "$_ does not have the correct suffix (\.txt or \.csv)"   },
    where { $_ =~ /$TextFileext\Z/sxm };

subtype HeaderString, as Str,
    where{ $_ =~ /^[a-z\_][a-z0-9\_^\n\r]*$/sxm  };

###InternalTypeSShirasFormat	warn "You uncovered internal logging statements for the Types HeaderString and HeaderArray in Log::Shiras::Types-$VERSION" if !$ENV{hide_warn};
coerce HeaderString, from Str,
    via {
        if( is_Str( $_ ) ) {
			my $header = $_;
###InternalTypeSHeadeR warn "Initital header: $header";
			$header = lc( $header );
###InternalTypeSHeadeR warn "Updated header: $header";
            $header =~ s/\n/ /gsxm;
###InternalTypeSHeadeR warn "Updated header: $header";
            $header =~ s/\r/ /gsxm;
###InternalTypeSHeadeR warn "Updated header: $header";
            $header =~ s/\s/_/gsxm;
###InternalTypeSHeadeR warn "Updated header: $header";
            chomp $header;
###InternalTypeSHeadeR warn "Final header: $header";
            return $header;
        } else {
            return "Can not coerce -$_- into a 'HeaderString' since it is " .
				"a -" . ref $_ . "- ref (not a string) using " .
				"Log::Shiras::Types 'ShirasFormat' line " . __LINE__ . ".\n";
        }
    };

subtype HeaderArray, as ArrayRef[HeaderString];

coerce HeaderArray, from ArrayRef,
    via {
		my $array_ref = $_;
###InternalTypeSHeadeR warn "Received data:" . Dumper( @_ );
		my $new_ref = [];
		for my $header ( @$array_ref ){
###InternalTypeSHeadeR warn "Initital header: $header";
			$header = lc( $header );
###InternalTypeSHeadeR warn "Updated header: $header";
            $header =~ s/\n/ /gsxm;
###InternalTypeSHeadeR warn "Updated header: $header";
            $header =~ s/\r/ /gsxm;
###InternalTypeSHeadeR warn "Updated header: $header";
            $header =~ s/\s/_/gsxm;
###InternalTypeSHeadeR warn "Updated header: $header";
            chomp $header;
###InternalTypeSHeadeR warn "Final header: $header";
			push @$new_ref, $header;
		}
		return $new_ref;
    };

subtype YamlFile, as Str,
	where{ $_ =~ $yamlextention and -f $_ },
	message{ $_ };

subtype JsonFile, as Str,
	where{ $_ =~ $jsonextention and -f $_ },
	message{ $_ };

subtype FileHash, as HashRef;
###InternalTypeSFileHash	warn "You uncovered internal logging statements for the Type FileHash in Log::Shiras::Types-$VERSION" if !$ENV{hide_warn};
coerce FileHash, from YamlFile,
	via{
		my @Array = LoadFile( $_ );
###InternalTypeSFileHash	warn "downloaded file:" . Dumper( @Array );
		return ( ref $Array[0] eq 'HASH' ) ?
			$Array[0] : { @Array } ;
	};

coerce FileHash, from JsonFile,
	via{
###InternalTypeSFileHash	warn "input: $_";
		open( my $fh, "<", $_ );
		my 	@Array = <$fh>;
		chomp @Array;
###InternalTypeSFileHash	warn "downloaded file:" . Dumper( @Array );
		my  $ref = $coder->decode( join '', @Array );
###InternalTypeSFileHash	warn "converted file:" . Dumper( $ref );
		return $ref ;
	};

subtype ArgsHash, as HashRef,
	where{
		my  $result = 0;
		for my $key ( @$switchboard_attributes ){
			if( exists $_->{$key} ){
				$result = 1;
				last;
			}
		}
		return $result;
	},
	message{ 'None of the required attributes were passed' };

coerce ArgsHash, from FileHash,
	via{ $_ };

subtype ReportObject, as Object,
	where{ $_->can( 'add_line' ) },
	message{ $_ };
###InternalTypeSReportObject	warn "You uncovered internal logging statements for the Type ReportObject in Log::Shiras::Types-$VERSION" if !$ENV{hide_warn};
coerce ReportObject, from FileHash,
	via{
###InternalTypeSReportObject	warn "the passed value is:" . Dumper( @_ );
		return build_instance( %$_ );
	};

subtype NameSpace, as Str,
	where{
		my  $result = 1;
		$result = 0 if( !$_ or $_ =~ / / );
		return $result;
	},
	message{
		my $passed = ( ref $_ eq 'ARRAY' ) ? join( '::', @$_ ) : $_;
		return "-$passed- could not be coerced into a string without spaces";
	};

coerce NameSpace, from ArrayRef,
	via{ return join( '::', @$_ ) };

subtype CSVFile,
	as Str,
	where{ $_ =~ /\.(csv)$/i and -r $_};

coerce CSVFile,
	from Str,
	via{	my $fh = IO::File->new;
			$fh->open( "> $_" );# Vivify the file!
			$fh->close;
			return $_;							};

subtype XMLFile,
	as Str,
	where{ $_ =~ /\.(xml|rels)$/i and -r $_};

subtype XLSXFile,
	as Str,
	where{ $_ =~ /\.x(ls(x|m)|ml)$/i and -r $_ };

subtype XLSFile,
	as Str,
	where{ $_ =~ /\.xls$/i and -r $_ };

subtype IOFileType,
	as FileHandle;
	#~ { class => 'IO::File' };

#~ coerce IOFileType,
	#~ from GlobRef,
	#~ via{	my $fh = bless( $_, 'IO::File' );
			#~ $fh->binmode();
			#~ return $fh;							};

#~ coerce IOFileType,
	#~ from CSVFile,
	#~ via{	my $fh = IO::File->new( $_, 'r' );
			#~ $fh->binmode();
			#~ flock( $fh, LOCK_EX );
			#~ return $fh;							};

#~ coerce IOFileType,
	#~ from XLSXFile,
	#~ via{	my $fh = IO::File->new( $_, 'r' );
			#~ $fh->binmode();
			#~ flock( $fh, LOCK_EX );
			#~ return $fh;							};

#~ coerce IOFileType,
	#~ from XLSFile,
	#~ via{	my $fh = IO::File->new( $_, 'r' );
			#~ $fh->binmode();
			#~ flock( $fh, LOCK_EX );
			#~ return $fh;							};

#~ coerce IOFileType,
	#~ from XMLFile,
	#~ via{	my $fh = IO::File->new( $_, 'r' );
			#~ $fh->binmode();
			#~ flock( $fh, LOCK_EX );
			#~ return $fh;							};


#########1 Private Methods	  3#########4#########5#########6#########7#########8#########9

sub _has_shiras_keys{
	my ( $ref ) =@_;
###InternalTypeSShirasFormat	warn "passed information is:" . Dumper( $ref );
	my 	$result = 1;
	if( ref $ref eq 'HASH' ){
###InternalTypeSShirasFormat	warn "found a hash ref...";
		for my $key ( keys %$ref ){
###InternalTypeSShirasFormat	warn "testing key: $key";
			if( !(exists $shiras_format_ref->{$key}) ){
###InternalTypeSShirasFormat	warn "failed at key: $key";
				### <where> -
				$result = 0;
				last;
			}
		}
	}else{
		$result = 0;
	}
	return $result;
}

sub _process_sprintf_format{
    my ( $ref ) = @_;
###InternalTypeSShirasFormat	warn "passed information is:" . Dumper( $ref );
    if( my @list = $ref->{new_chunk} =~ $sprintf_regex ) {
###InternalTypeSShirasFormat	warn "results of the next regex element are:" .Dumper( @list );
		$ref->{string} .= '%';
		my $x = 0;
		for my $item ( @list ){
			if( defined $item ){
###InternalTypeSShirasFormat	warn "processing: $item";
###InternalTypeSShirasFormat	warn "position: $x";
				my $i = 0;
				for my $method ( @{$sprintf_dispatch->[$x]} ){
###InternalTypeSShirasFormat	warn "running the -$i- method: $method";
					$ref = $method->( $item, $ref );
###InternalTypeSShirasFormat	warn "updated ref:" . Dumper( $ref );
					return $ref if ref $ref ne 'HASH';
					$i++;
				}
			}
			$x++;
		}
    } else {
        $ref = "Failed to match -" . $ref->{new_chunk} .
					"- as a (modified) sprintf chunk";
    }
###InternalTypeSShirasFormat	warn "after _process_sprintf_format:" . Dumper( $ref );
    return $ref;
}

sub _process_producer_format{
	my ( $ref ) = @_;
###InternalTypeSShirasFormat	warn "passed information is:" . Dumper( $ref );
	$ref->{string} .= $ref->{new_chunk};
	delete $ref->{new_chunk};
###InternalTypeSShirasFormat	warn "after _process_producer_format:" . Dumper( $ref );
    return $ref;
}

sub _append_to_string{
	my ( $item, $item_ref ) = @_;
###InternalTypeSShirasFormat	warn "reached _append_to_string with:" . Dumper( $item );
	$item_ref->{string} .= $item;
	return $item_ref;
}

sub _does_not_consume{
	my ( $item, $item_ref ) = @_;
###InternalTypeSShirasFormat	warn "reached _does_not_consume with:" . Dumper( $item );
	$item_ref->{no_primary_consumption} = 1;
	return $item_ref;
}

sub _set_consumption{
	my ( $item, $item_ref ) = @_;
###InternalTypeSShirasFormat	warn "reached _set_consumption with:" . Dumper( $item );
	if( !$item_ref->{no_primary_consumption} ){
		push @{$item_ref->{bump_list}},
			((exists $item_ref->{bump_count})?$item_ref->{bump_count}:0);
	}
	delete $item_ref->{no_primary_consumption};
	return $item_ref;
}

sub _remove_consumption{
	my ( $item, $item_ref ) = @_;
###InternalTypeSShirasFormat	warn "reached _remove_consumption with:" . Dumper( $item );
	pop @{$item_ref->{bump_list}};
	return $item_ref;
}

sub _set_insert_call{
	my ( $item, $item_ref ) = @_;
	$item_ref->{alt_position} = ( $item_ref->{alt_position} ) ?
		$item_ref->{alt_position} : 0 ;
	$item_ref->{bump_count}++;
###InternalTypeSShirasFormat	warn "reached _set_insert_call with:" . Dumper( $item );
###InternalTypeSShirasFormat	warn "using position:" . Dumper( $item_ref->{alt_position} );
###InternalTypeSShirasFormat	warn "with new bump level:" . Dumper( $item_ref->{bump_count} );
	my $new_ref = [
		$item_ref->{alt_input}->[$item_ref->{alt_position}]->[1],
		$item_ref->{alt_input}->[$item_ref->{alt_position}]->[0],
	];
	if( $item_ref->{alt_input}->[$item_ref->{alt_position}]->[2] ){
		my $dispatch = undef;
		for my $value (
			split /,|=>/,
				$item_ref->{alt_input}->[$item_ref->{alt_position}]->[2] ){
			$value =~ s/\s//g;
			$value =~ s/^['"]([^'"]*)['"]$/$1/g;
			push @$new_ref, $value;
			if( $dispatch ){
				$item_ref->{bump_count} -=
					( $value =~/^\d+$/ )? $value :
					( $value =~/^\*$/ )? 1 : 0 ;
				$dispatch = undef;
			}else{
				$dispatch = $value;
			}
		}
	}
	$item_ref->{alt_input}->[$item_ref->{alt_position}] = { commands => $new_ref };
	$item_ref->{alt_input}->[$item_ref->{alt_position}]->{start_at} =
		( exists $item_ref->{bump_list} ) ?
			$#{$item_ref->{bump_list}} + 1 : 0 ;
	$item_ref->{alt_position}++;
###InternalTypeSShirasFormat	warn "item ref:" . Dumper( $item_ref );
	return $item_ref;
}

sub _test_for_position_change{
	my ( $item, $item_ref ) = @_;
###InternalTypeSShirasFormat	warn "reached _test_for_position_change with:" . Dumper( $item );
	if( exists $item_ref->{conflict_test} ){
		$item_ref = "You cannot call for alternative location pull -" .
		$item_ref->{conflict_test} . "- and get data from the -$item- " .
		"source in ShirasFormat type coersion at line " . __LINE__ . ".\n";
	}
	return $item_ref;
}

sub _alt_position{
	my ( $item, $item_ref ) = @_;
###InternalTypeSShirasFormat	warn "reached _alt_position with:" . Dumper( $item );
	$item_ref->{conflict_test} = $item if $item;
	return $item_ref;
}

#########1 Phinish    	      3#########4#########5#########6#########7#########8#########9

1;
# The preceding line will help the module return a true value

#########1 main pod docs      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Log::Shiras::Types - The Type::Tiny library for Log::Shiras

=head1 SYNOPSIS

	#!perl
	package Log::Shiras::Report::MyRole;

	use Modern::Perl;#suggested
	use Moose::Role;
	use Log::Shiras::Types v0.013 qw(
		ShirasFormat
		JsonFile
	);

	has	'someattribute' =>(
			isa     => ShirasFormat,#Note the lack of quotes
		);

	sub valuetestmethod{
		return is_JsonFile( 'my_file.jsn' );
	}

	no Moose::Role;

	1;

=head1 DESCRIPTION

This is the custom type class that ships with the L<Log::Shiras> package.

There are only subtypes in this package!  B<WARNING> These types should be
considered in a beta state.  Future type fixing will be done with a set of tests in
the test suit of this package.  (currently few are implemented)

See L<MooseX::Types> for general re-use of this module.

=head1 Types

=head2  PosInt

=over

=item B<Definition: >all integers equal to or greater than 0

=item B<Coercions: >no coersion available

=back

=head2  ElevenInt

=over

=item B<Definition: >any posInt less than 11

=item B<Coercions: >no coersion available

=back

=head2  ElevenArray

=over

=item B<Definition: >an array with up to 12 total positions [0..11]
L<I<This one goes to eleven>|https://en.wikipedia.org/wiki/This_Is_Spinal_Tap>

=item B<Coercions: >no coersion available

=back

=head2  ShirasFormat

=over

=item B<Definition: >this is the core of the L<Log::Shiras::Report::ShirasFormat> module.
When prepared the final 'ShirasFormat' definition is a hashref that contains three keys;

=over

=item B<final> - a sprintf compliant format string

=item B<alt_input> - an arrayref of input definitions and positions for all the additional
'ShirasFormat' modifications allowed

=item B<bump_list> - a record of where and how many new inputs will be inserted
in the passed data for formatting the sprintf compliant string

=back

In order to simplify sprintf formatting I approached the sprintf definition as having
the following sequence;

=over

=item B<Optional - Pre-string, > any pre-string that would be printed as it stands
(not interpolated)

=item B<Required - %, >this indicates the start of a formating definition

=item B<Optional - L<Flags|http://perldoc.perl.org/functions/sprintf.html#flags>, >
any one or two of the following optional flag [\s\-\+0#] as defined in the sprintf
documentation.

=item B<Optional -
L<Order of arguments|http://perldoc.perl.org/functions/sprintf.html#order-of-arguments>, >
indicate some other position to obtain the formatted value.

=item B<Optional -
L<Vector flag|http://perldoc.perl.org/functions/sprintf.html#vector-flag>, >to treat
each input character as a value in a vector then you use the vector flag with it's
optional vector separator definition.

=item B<Optional -
L<Minimum field width|http://perldoc.perl.org/functions/sprintf.html#(minimum)-width>, >
This defines the space taken for presenting the value

=item B<Optional -
L<Maximum field width|http://perldoc.perl.org/functions/sprintf.html#precision%2c-or-maximum-width>, >
This defines the maximum length of the presented value.  If maximum width is smaller
than the minimum width then the value is truncatd to the maximum width and presented
in the mimimum width space as defined by the flags.

=item B<Required -
L<Data type definition|http://perldoc.perl.org/functions/sprintf.html#sprintf-FORMAT%2c-LIST>, >
This is done with an upper or lower case letter as described in the sprintf documentation.  Only
the letters defined in the sprintf documentation are supported.  These letters close the
sprintf documentation segment started with '%'.

=back

The specific combination of these values is defined in the perldoc
L<sprintf|http://perldoc.perl.org/functions/sprintf.html>.

The module ShirasFormat expands on this definitions as follows;

=over

=item B<Word in braces {}, > just prior to the L</Data type definition> you can
begin a sequence that starts with a word (no spaces) enclosed in braces.  This word will
be the name of the source data used in this format sequence.

=item B<Source indicator qr/[MP]/, > just after the L</Word in braces {}> you must indicate
where the code should look for this information.  There are only two choices;

=over

=item B<P> - a passed value in the message hash reference.  The word in braces should be an
exact match to a key in the message hashref. The core value used for this ShirasFormat
segemnt will be the value assigned to that key.

=item B<M> - a method name to be discovered by the class.  I<This method must exist at the
time the format is set!>  When the Shiras format string is set the code will attempt to
locate the method and save the location for calling this method to speed up implementation of
ongoing formatting operations.  If the method does not exist when the format string is
set even if it will exist before data is passed for formatting then this call will fail.
if you want to pass a closure (subroutine reference) then pass it as the value in the mesage
hash L<part
of the message ref|/a passed value in the message hash reference> and call it with 'P'.

=back

=item B<Code pairs in (), following the source indicator> often the passed information
is a code reference and for that code to be useful it needs to accept input.  These code
pairs are a way of implementing the code.  The code pairs must be in intended use sequence.
The convention is to write these in a fat comma list.  There is no limit to code pairs
quatities. There are three possible keys for these pairs;

=over

=item B<m> this indicates a method call.  If the code passed is actually an object with
methods then this will call the value of this pair as a method on the code.

=item B<i> this indicates regular input to the method and input will be provided to a
method using the value as follows;

	$method( 'value' )

=item B<l> this indicates lvalue input to the method and input will be provided to a
method using the value as follows;

	$method->( 'value' )

=item B<[value]> Values to the methods can be provided in one of three ways. A B<string>
that will be sent to the method directly. An B<*> to indicate that the method will consume
the next value in the passed message array ref.  Or an B<integer> indicating how many of the
elements of the passed messay array should be consumed.  When elements of the passed
message array are consumed they are consumed in order just like other sprintf elements.

=back

When a special ShirasFormat segment is called the braces and the Source indicator are
manditory.  The code pairs are optional.

=item B<Coercions: >from a modified sprintf format string

=back

=back

=head2  TextFile

=over

=item B<Definition: >a file name with a \.txt or \.csv extention that exists

=item B<Coercions: >no coersion available

=back

=head2  HeaderString

=over

=item B<Definition: >a string without any newlines

=item B<Coercions: >if coercions are turned on, newlines will be stripped (\n\r)

=back

=head2  YamlFile

=over

=item B<Definition: >a file name with a qr/(\.yml|\.yaml)/ extention that exists

=item B<Coercions: >none

=back

=head2  JsonFile

=over

=item B<Definition: >a file name with a qr/(\.jsn|\.json)/ extention that exists

=item B<Coercions: >none

=back

=head2  ArgsHash

=over

=item B<Definition: >a hashref that has at least one of the following keys

	name_space_bounds
	reports
	buffering
	ignored_caller_names
	will_cluck
	logging_levels

This are the primary switchboard settings.

=item B<Coersion >from a L</JsonFile> or L</YamlFile> it will attempt to open the file
and turn the file into a hashref that will pass the ArgsHash criteria

=back

=head2  ReportObject

=over

=item B<Definition: >an object that passes $object->can( 'add_line' )

=item B<Coersion 1: >from a hashref it will use
L<MooseX::ShortCut::BuildInstance|http://search.cpan.org/~jandrew/MooseX-ShortCut-BuildInstance/lib/MooseX/ShortCut/BuildInstance.pm>
to build a report object if the necessary hashref is passed instead of an object

=item B<Coersion 2: >from a L</JsonFile> or L</YamlFile> it will attempt to open the file
and turn the file into a hashref that can be used in L</Coersion 1>.

=back

=head1 GLOBAL VARIABLES

=over

=item B<$ENV{hide_warn}>

The module will warn when debug lines are 'Unhide'n.  In the case where the you
don't want these notifications set this environmental variable to true.

=back

=head1 TODO

=over

=item * write a test suit for the types to fix behavior!

=item * write a set of tests for combinations of %n and {string}M

=back

=head1 SUPPORT

=over

=item L<Github Log-Shiras/issues|https://github.com/jandrew/Log-Shiras/issues>

=back

=head1 AUTHOR

=over

=item Jed Lund

=item jandrew@cpan.org

=back

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DEPENDANCIES

=over

=item L<Carp> - confess

=item L<version>

=item L<YAML::Any> - ( Dump LoadFile )

=item L<JSON::XS>

=item L<MooseX::Types>

=item L<MooseX::Types::Moose>

=item L<MooseX::ShortCut::BuildInstance> - 1.044

=back

=head1 SEE ALSO

=over

=item L<Type::Tiny>

=back

=cut

#########1 Main POD ends      3#########4#########5#########6#########7#########8#########9
