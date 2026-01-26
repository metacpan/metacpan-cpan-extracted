package LaTeX::Replicase;

use 5.010;
use strict;
use warnings;
use utf8;

use File::Basename qw(fileparse);
use File::Path qw(make_path);
use File::Compare;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ('all' => [ qw(
		replication
		tex_escape
	) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.590';
our $DEBUG; $DEBUG = 0 unless defined $DEBUG;
our @logs;
our $nlo = 1; # Number Line Output, start of 1

sub tex_escape {
	return if ! $_[0] or $_[0] =~/^[a-zA-Z0-9,=:;!\.\s\+\-\*]+$/ or $_[0] =~s/^%%%://;

	for( $_[0] ) {
		s/\\/\\textbackslash/g;
		s/([%}{_&\$\#])/\\$1/g; # masking active symbols
		s/\^/\\$&\{\}/g; # ^ --> \^{}

		s/~/\\texttt\{\\~\{\}\}/g if $_[1] && $_[1] =~/~/; # tilde (~) --> \texttt{\~{}}
	}
}


sub replication {
	my( $source, $info, %op ) = @_;

	our $DEBUG; $DEBUG = $op{debug} if defined $op{debug};
	$DEBUG += 0;
	our @logs = ();

	if( defined( $source ) && length( $source ) ) {

		if(ref \$source eq 'SCALAR') {
			for( $source ) {
				s/^\s+//;
				s/\s+.*//s;

				$_ = (glob)[0] if $^O =~/(?:linux|bsd|darwin|solaris|sunos)/;
			}
		}
		elsif(ref $source ne 'ARRAY')  {
			$_ = "!!! ERROR#6: invalid FILE or ARRAY input!";
			$op{silent} or carp $_;

			push @logs, $_;
			return \@logs;
		}

	}
	else {
		$_ = "!!! ERROR#0: undefined input FILE or ARRAY!";
		$op{silent} or carp $_;

		push @logs, $_;
		return \@logs;
	}

push @logs, "--> Checking source data: '$source'" if $DEBUG;

	if((ref \$source eq 'SCALAR' and ! -s $source) or (ref $source eq 'ARRAY' and ! @$source)) {
		$_ = "!!! ERROR#1: source ('$source') does NOT exist or is EMPTY!";
		$op{silent} or carp $_;

		push @logs, $_;
		return \@logs;
	}

	# global data of TeX file
	unless( $info
		and (( ref $info eq 'HASH' and %$info ) or (ref $info eq 'ARRAY' and @$info ))
	) {
		$_= "!!! ERROR#2: EMPTY or WRONG data!";
		$op{silent} or carp $_;

		push @logs, $_;
		return \@logs;
	}

	# environments: global for %%%V:, %%%VAR: ; and local for %%%VAR:
	my $data = my $vardata = $info;

	my( $filename, $dir );
	if( ref \$source eq 'SCALAR') {
		( $filename, $dir, my($ext)) = fileparse( $source );
	}
	else { # for ARRAY input
		$filename = 'ready.tex';
		$dir = '.';
	}

	my( $fh, $ofile );
	if( defined( $_ = $op{ofile} ) && length ) {
		if(/::STDOUT$/) {
			$fh = $ofile = $_;
		}
		else {
			s/^\s+//;
			s/\s+.*//s;
			$ofile = ( $^O =~/(?:linux|bsd|darwin|solaris|sunos)/ ) ? (glob)[0] : $_;
		}
	}
	else {
		my $outdir = $op{outdir} // "$dir/$$"; # Target dir for ready TeX file
		if( length $outdir ) {
			for( $outdir ) {
				s/^\s+//;
				s/\s+.*//s;

				$_ = (glob)[0] if $^O =~/(?:linux|bsd|darwin|solaris|sunos)/;
			}
		}
		else { # for $outdir = ''
			$outdir = "./$$";
		}

		unless( -d $outdir ) {
			make_path( $outdir, {error => \my $err} );

			if ($err && @$err) {

				for my $diag (@$err) {
					my( $path, $message ) = %$diag;
					$_ = ( $path && length( $path ) ) ?
						"!!! ERROR#7: ('$path' creation problem) $message" :
						"!!! ERROR#8: (general error) $message";
					$op{silent} or carp $_;
					push @logs, $_;
				}

				return \@logs;
			}

		}

		$ofile = "$outdir/$filename";
	}

push @logs, "--> Using '$ofile' file as output" if $DEBUG;

	# new file must be different
	if( -s $ofile and ref \$source eq 'SCALAR'
		and (
			( $source eq $ofile and compare( $source, $ofile ) == 0 )
			or
			( join(',', stat $source) eq join(',', stat $ofile) )
		)
	) {
		$_= "!!! ERROR#3: Input (template) & output files match. Can't overwrite template file!";
		$op{silent} or carp $_;

		push @logs, $_;
		return \@logs;
	}

	my $TEMPLATE;
	if( ref \$source eq 'SCALAR') {
		my $mode = $op{utf8} ? ':utf8' : '';

push @logs, "--> Open '$source'" if $DEBUG;

		open $TEMPLATE, "<:raw$mode", $source or do{
			$_= "!!! ERROR#4: $!";
			$op{silent} or carp $_;

			push @logs, $_;
			return \@logs;
		};
	}

	unless( $fh ) { # it's not "::STDOUT"
		my $mode = $op{utf8} ? ':encoding(utf8)' : '';

push @logs, "--> Open '$ofile'" if $DEBUG;

		open $fh, ">$mode", $ofile or do{
			$_= "!!! ERROR#5: $!";
			$op{silent} or carp $_;

			push @logs, $_;
			return \@logs;
		};
	}

	$nlo = 1;
	my $chkVAR = 0; # check %%%VAR for ARRAY|HASH|SCALAR|REF->SCALAR type
	my $key;
	my $tdz; # flag of The Dead Zone
	my @columns;

=for comment
=begin comment
@columns:
	[...]: -- table columns
	[...]{...} -- descriptions (properties) of table columns:
			{ki} -- name (key || index ) of a variable from $data->{ $key }
			{%} -- NO \par
			{p} -- to paste text on right
			{head}[...] -- TeX strings before %%%V:
			{tail}[...] -- TeX strings after %%%V:
			{eX}[...] -- indices of {head} that eXcept for the first and last elements and rows of %%%VAR:
=end comment
=cut

	if( $TEMPLATE )  {
		while( my $z = <$TEMPLATE> ) {

			if( &_line_decryption( $fh, $info, \$z, \$data, \$vardata, \$chkVAR, \$key, \$tdz, \@columns, \%op ) ) {
				print { $fh } <$TEMPLATE>;
				last; #--> Exit template
			}
			undef $z;

		}
		close $TEMPLATE;
	}
	else {
		my $e;
		for my $z ( @$source ) {

			if( $e ) {
				print { $fh } $z;
			}
			else {
				$e = &_line_decryption( $fh, $info, \$z, \$data, \$vardata, \$chkVAR, \$key, \$tdz, \@columns, \%op );
			}
		}
	}

	if( defined $key ) {
		&_var_output( $fh, $key, $vardata, \@columns, \%op );

		$_ = "~~> l.$. WARNING#1: Missing '%%%ENDx' tag for '$key'";
		$op{silent} or carp $_;
		push @logs, $_;
	}

	$ofile =~/::STDOUT$/ or close $fh;

	@logs or return;
	return \@logs;
}

#---------------------
# Internal function(s)

sub _line_decryption {
	my( $fh, $info, $z, $data, $vardata, $chkVAR, $key, $tdz, $columns, $op ) = @_;

	our $DEBUG;
	our @logs;
	our $nlo;

	if( defined $$key ) { # We are in VAR-structure

		return unless $$z =~/%%%[AETV]\S*:/; # Nope control tags --> drop TeX line

		if( $$z =~/%%%(?:END(?<t>[TZ]?)|TDZ|VAR):/) {
			my $t = $+{t};
			&_var_output( $fh, $$key, $$vardata, $columns, $op );

			# Clear the VAR-structure for the next external VARiable
			$$chkVAR = 0;
			undef $$key;
			@$columns = ();

			return 1 if $t && $t eq 'T'; # end of template area --> Exit template

			undef $$tdz if $t && $t eq 'Z';

			return if $$z =~/%%%ENDZ?:/; # end of %%%VAR: tag

			if( $$z =~/%%%+TDZ:/) { # The Dead Zone
				$$tdz = 1;
				return;
			}

		}
		elsif( (ref $$vardata eq 'HASH' and ( ref $$vardata->{ $$key } eq 'HASH' or ref $$vardata->{ $$key } eq 'ARRAY'))
			or (ref $$vardata eq 'ARRAY' and ( ref $$vardata->[ $$key ] eq 'HASH' or ref $$vardata->[ $$key ] eq 'ARRAY'))
		) {
			# Index of column in target table
			my $j = ( @$columns && exists( $columns->[-1]{ki} ) ) ?
						@$columns :
						($#$columns // 0);
			$j = 0 if $j < 0; # JIC

			my $vk = ref $$vardata eq 'HASH' ? $$vardata->{ $$key } : $$vardata->[ $$key ];

			if( $$z =~/%%%V:\s*([^\s:%#]+)(%?)\s?(.*)/) {
				# this V-variable is nested in a VAR-structure
				my $ki = $1; # name (key or index) of V-variable
				my $Np = $2; # NO \par
				my $paste = $3; # on right

				if( $$chkVAR == 0b0001) { # V-variable is in {HASH|ARRAY}.ARRAY of VAR-structure

					if( $ki eq '@') {
						$ki = '0-'; # ALL elements
						$columns->[$j]{ki} = $ki; # starting index (unnamed meaning)
					}
					elsif( $ki =~/^\-*(\d+)$/ && ($1 < @$vk or ($ki < 0 && $1 == @$vk)) ) {
						# specific indices, e.g.: 0 or 3 or -1
						$columns->[$j]{ki} = $ki;
					}
					elsif( $ki =~/^[\d,\-]+$/) {
					# mixed indexes, e.g.: 1-3,6-7-9,-,4,-5,0,7- or 3- (i.e. 3..arr_end) or 0-5 (0..5) or -1- (-1,-2,..arr_start)
						for( $ki ) {
							s/\-+/-/g;
							s/,+/,/g;
						}
						$columns->[$j]{ki} = $ki;
					}
					else {
push @logs, "~~> l.$. WARNING#8: ARRAY index is not numeric in %%%V:". $ki if $DEBUG or ! $op->{ignore};
					}

				}
				elsif( $$chkVAR == 0b0010) { # V-variable is in {HASH|ARRAY}.HASH of VAR-structure

					for my $d ( @$vk ) {
						if( exists $d->{$ki} ) {
							$columns->[$j]{ki} = $ki; # save variable name in j-th column
							last;
						}
					}
				}
				elsif( $$chkVAR == 0b0100 or $$chkVAR == 0b01000 ) { # V-variable is SCALAR (or REF->SCALAR) in regular ARRAY of VAR-structure

					if( $ki eq '@') {
						$ki = '0-'; # ALL elements
						$columns->[$j]{ki} = $ki; # starting index (unnamed meaning)
					}
					elsif( $ki =~/^\-*(\d+)$/ && ($1 < @$vk or ($ki < 0 && $1 == @$vk)) ) {
						# specific indices, e.g.: 0 or 3 or -1
						$columns->[$j]{ki} = $ki;
					}
					elsif( $ki =~/^[\d,\-]+$/) {
					# mixed indexes, e.g.: 1-3,6-7-9,-,4,-5,0,7- or 3- (i.e. 3..arr_end) or 0-5 (0..5) or -1- (-1,-2,..arr_start)
						for( $ki ) {
							s/\-+/-/g;
							s/,+/,/g;
						}
						$columns->[$j]{ki} = $ki;
					}

				}
				elsif( ref $vk eq 'HASH'
						and ( (ref \$vk->{$ki} eq 'SCALAR' and defined( $vk->{$ki} ) )
							or (ref \$vk->{$ki} eq 'REF'
								and ref $vk->{$ki} eq 'SCALAR'
								and defined( ${ $vk->{$ki} } )
							)
							or ( $ki eq '@'
								and exists($vk->{$ki})
								and ref $vk->{$ki} eq 'ARRAY'
							)
							)
				) {
					$columns->[$j]{ki} = $ki; # save variable key in j-th element
				}

				&_set_column( $Np, $paste, $columns->[$j] ) if exists $columns->[$j]{ki};
			}
			elsif( $$z =~/(?<s>.+?)\s?%%%+ADD(?<t>[EX]?):(?<p>%?)/
				or $$z =~/^\s*%%%+ADD(?<t>[EX]?):(?<p>%?)\s?(?<s>.*?)[\r\n]*$/
			) {
				my $s = $+{s};

				if( $+{p} ) {
					length($s) or return;
				}
				else {
					$s .= "\n";
				}

				if( $+{t} eq 'E') { # %%%ADDE:
					if( @$columns && exists( $columns->[-1]{ki} ) && ! $columns->[$j] ) {
						push @{ $columns->[-1]{tail} }, $s;
					}
					else {
						push @{ $columns->[$j]{head} }, $s;
					}
				}
				else {
					push @{ $columns->[$j]{head} }, $s;
					$columns->[$j]{eX}{ $#{ $columns->[$j]{head} } } = undef if $+{t} eq 'X'; # $$chkVAR && ...  %%%ADDX:
				}
			}

			return;
		}
		else {
			return;
		}

	}
	elsif( $$z =~/%%%+END(?<t>[TZ]?):/) { # end of template area

		# Clear the VAR-structure for the next external variable
		$$chkVAR = 0;
		undef $$key;
		@$columns = ();

		return 1 if $+{t} eq 'T'; # end of template area --> Exit template

		undef $$tdz if $+{t} eq 'Z'; # End of TDZ
		return;
	}

	$$tdz = 1 if $$z =~s/^\s*%%%+TDZ:\s?[\r\n]*//; # The Dead Zone

	if( $$tdz ) { # The Dead Zone is ON
		if( length $$z ) {# Output TeX
			print { $fh } $$z;
			++$nlo;
		}
		return;
	}

	if( $$z =~/(.*?)\s?%%%+VAR:\s*([^\s:%#]+)(%?)\s?(.*)/) {
		my $before = $1;
		my $k = $2; # name (key)
		my $Np = $3; # NO \par
		my $paste = $4; # on right text for SCALAR only

		# root or global structure (environment)
		my $vd = ( $k =~s/^\/+//) ? $info : $$data;

		my $x; # for unknown/undefined sub-key

		# Search nested sub-keys
		for my $sk ( split '/', $k ) {
			$$vardata = $vd;
			length( $sk ) or next;

			if( $sk =~/^\d+$/ && ref $vd eq 'ARRAY' and defined( $vd->[$sk] )) {
				last if &_data_redef( $sk, $vd->[$sk], \$k, \$vd, \$x );
			}
			elsif( ref $vd eq 'HASH' and exists( $vd->{$sk} )) {
				last if &_data_redef( $sk, $vd->{$sk}, \$k, \$vd, \$x );
			}
			else {
				$x = $sk;
				last;
			}
		}

		# Clear the VAR-structure for a new variable
		$$chkVAR = 0;
		undef $$key;
		@$columns = ();

		if( $x ) {
push @logs, "~~> l.$. WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key '$x' in %%%VAR:". $k if $DEBUG or ! $op->{ignore};

			$$vardata = $$data;
			print { $fh } $$z;
			++$nlo;
			return;
		}

		# key or sub-...sub-key is found
push @logs, "--> l.$. Found %%%VAR:". $k if $DEBUG;

		my $vk = ref $$vardata eq 'HASH' ? $$vardata->{$k} :
			(ref $$vardata eq 'ARRAY' ? $$vardata->[$k] : undef);

		unless( $vk ) {
push @logs, "~~> l.$. NOT defined key in %%%VAR:". $k if $DEBUG && $op->{def};
			return;
		}

		return if &_chk_var( $fh, $k, $vk, $Np, \$paste, \$before, $chkVAR, $columns, $z, $op );

# push @logs, "--> l.$. Remember key = '$k' (chkVAR=$$chkVAR), type: ".ref($vk) if $DEBUG; ###AG

		$$key = $k; # save key name
		return;

	}
	elsif( $$z =~/%%%V:\s*(?<k>[^\s:%#]+)(?<p>%?)\s?(?<s>.*)/) {
		my $k = $+{k};

		my %el;
		&_set_column( $+{p}, $+{s}, \%el );

		my $inidata = $$data; # save initial environment

		if( $k =~s/^\/+//) {
			$$data = $info; # reset to root environment

			length($k) or return;
		}

		# Search nested sub-keys
		my $x = 0; # for unknown sub-key
		for my $sk ( split '/', $k ) {
			length( $sk ) or next;

			my $d;
			if( $sk =~/^\d+$/ && ref $$data eq 'ARRAY' && defined( $$data->[$sk] )) {
				$d = $$data->[$sk];
			}
			elsif( ref $$data eq 'HASH' && exists( $$data->{$sk} )) {
				$d = $$data->{$sk};
			}
			else {
push @logs, "~~> l.$. WARNING#3: unknown sub-key '$sk' in %%%V:". $k if $DEBUG or ! $op->{ignore};

				print { $fh } $$z;
				++$nlo;

				$x = 1;
				last;
			}

			# Check type
			if( (ref $d eq 'ARRAY' or ref $d eq 'HASH') ) {
				$$data = $d; #  sub-key (path) found: redefined
				next;
			}

			my $v;
			if( ref \$d eq 'SCALAR') {
				$v = $d;
			}
			elsif( ref \$d eq 'REF' and ref $d eq 'SCALAR') { # REF->SCALAR
				$v = $$d;
			}
			else {
push @logs, "~~> l.$. WARNING#4: wrong type (not SCALAR|ARRAY|HASH) of '$sk' in %%%V:". $k if $DEBUG or ! $op->{ignore};

				print { $fh } $$z;
				++$nlo;

				$x = 1;
				last;
			}

			&_v_print( $fh, $k, $v, \%el, $op );

			$x = 1;
			last;
		}

		$$data = $inidata if $x; # value found or unknown sub-key: reset to initial environment

		return;
	}

	print { $fh } $$z;
	++$nlo;

	return;
}


sub _set_column {
	my( $Np, $paste, $column ) = @_;

	$column->{'%'} = 1 if $Np;
	$column->{p} = $paste if length $paste;
}

sub _data_redef {
	my( $sk, $d, $k, $data, $x ) = @_;

	if( ref $d eq 'ARRAY' or ref $d eq 'HASH') {
		$$data = $d; # redefined for %%%VAR:
		return 0;
	}

	if( ref \$d eq 'SCALAR' or (ref \$d eq 'REF' and ref $d eq 'SCALAR')) {
		$$k = $sk;
	}
	else {
		$$x = $sk;
	}
	return 1;
}

sub _chk_var {
	my( $fh, $k, $vk, $Np, $paste, $before, $chkVAR, $columns, $z, $op ) = @_;

	our $DEBUG;
	our @logs;
	our $nlo;

	if( ref $vk eq 'ARRAY') {

		unless( @{ $vk } ) {
push @logs, "~~> l.$. WARNING#7: empty ARRAY of %%%VAR:". $k if $DEBUG or ! $op->{ignore};

			print { $fh } $$z;
			++$nlo;
			return 1;
		}

	# Check ARRAY.{ARRAY|HASH|SCALAR[.REF]}
		for my $d ( @{ $vk } ) {
			if(ref $d eq 'ARRAY'){
				$$chkVAR |= 0b00001;
			}
			elsif(ref $d eq 'HASH') {
				$$chkVAR |= 0b00010;
			}
			elsif(ref \$d eq 'SCALAR') {
				$$chkVAR |= 0b00100;
			}
			elsif(ref \$d eq 'REF' and ref $d eq 'SCALAR') {
				$$chkVAR |= 0b01000;
			}
			else {
				$$chkVAR |= 0b10000;
			}
		}

		if( ! $$chkVAR or $$chkVAR > 0b01000 or ($$chkVAR & ($$chkVAR - 1)) ) {
push @logs, "~~> l.$. WARNING#6: mixed types (ARRAY with HASH with SCALAR or other) of %%%VAR:". $k if $DEBUG or ! $op->{ignore};

			print { $fh } $$z;
			++$nlo;
			return 1;
		}
	}
	elsif( ref \$vk eq 'SCALAR') {
		$columns->[0]{ki} = $k;
		&_set_column( $Np, $$paste, $columns->[0] );
	}

	if( $$before ) {# Output prefix TeX
		print { $fh } $$before;
#		++$nlo;
	}

	return 0;
}

# VALUE output
sub _v_print {
	my( $fh, $k, $v, $el, $op ) = @_;

	our $DEBUG;
	our @logs;
	our $nlo;

	if( defined $v ) {
		tex_escape( $v, $op->{esc} ) if $op->{esc};

push @logs, "--> l.$.>$nlo".' Insert %%%V[AR]:'. $k .'= '. $v if $DEBUG;

		print { $fh } $v;
		print { $fh } $el->{p} if exists $el->{p};

		++$nlo while $v =~/\n/g;

		return if $el->{'%'};

		print { $fh } "\n"; # NO:YES \par
		++$nlo;
	}
	else {
push @logs, "~~> l.$.".' NOT defined %%%V[AR]:'. $k if $DEBUG && $op->{def};
	}

}

# HEAD-TAIL output
sub _ht_print {
	my( $fh, $el, $ht, $border ) = @_;

	$el->{$ht} or return;

	our $DEBUG;
	our @logs;
	our $nlo;

	my $i = 0;
	foreach( @{ $el->{$ht} } ) {
		next if $ht eq 'head' and $border && exists( $el->{eX} ) && exists( $el->{eX}{$i} );

push @logs, "-->\tl.$.>$nlo Insert $ht: ". $_ if $DEBUG;

		print { $fh } $_;
		++$nlo;
	}
	continue {
		++$i;
	}

}

# HEAD-VALUE-TAIL output
sub _hvt_print {
	my( $fh, $ki, $val, $el, $op, $border ) = @_;

	our $DEBUG;
	our @logs;
	our $nlo;

	if( length($ki) and ! defined $val ) {
		push @logs, "~~> l.$.".' NOT defined %%%V:'. $ki if $DEBUG && $op->{def};
		return;
	}

	# output head of variable
	&_ht_print( $fh, $el, 'head', $border );

	# output value of variable
	&_v_print; # ( $fh, $ki, $val, $el, $op );

	# output tail of variable
	&_ht_print( $fh, $el, 'tail', 0);
}


sub _s_a_prn {
	my( $fh, $i, $values, $el, $op, $border, $col ) = @_;

	my $val = $values->[$i];
	if( ref \$val eq 'REF' and ref $val eq 'SCALAR') {
		$val = $$val;
	}

	if( ref \$val eq 'SCALAR') {
		&_hvt_print( $fh, $i, $val, $el, $op, $$border );
		++$$col;
		$$border = 0;
	}
	elsif( ref $val eq 'ARRAY') { # [...].ARRAY.ARRAY
		for( @$val ) {
			next if ref \$_ ne 'SCALAR';

			&_hvt_print( $fh, $i, $_, $el, $op, $$border );
			++$$col;
			$$border = 0;
		}
	}

}


sub _mixed_indices {
	my( $fh, $ki, $values, $el, $op, $border ) = @_;

	my $nd = @$values;
	my $col = 0;

	for my $ii ( split ',', $ki ) { # e.g. -1-,1-3,6-7-9,-,4,-5,0,7-
		next if $ii eq '-';

		if( $ii =~/^(\-[1-9]\d*)\-(\d*)$/) { # -1- i.e. reverse: -1,-2,..-@arr (i.e. arr_start)
			my $s = $1;
			my $e = -1*($2 || $nd);
			$s = -1*$nd if abs($s) > $nd;
			$e = -1*$nd if abs($e) > $nd;
			($s, $e) = ($e, $s) if $e > $s;

			for( my $i = $s; $i >= $e; --$i ) {
				&_s_a_prn( $fh, $i, $values, $el, $op, \$border, \$col );
			}
			next;
		}

		if( $ii =~/^\-[0-9]+$/ ) { # -5
			my $i = $ii+0;

			if( abs($i) <= $nd ) {
				&_s_a_prn( $fh, $i, $values, $el, $op, \$border, \$col );
			}
			next;
		}

		my @n = grep{length} sort{$a <=> $b} split '-', $ii;

		if( @n < 2 and $n[0] < $nd ) { # e.g. 4 || 0 || 7(-)
			if( $ii =~/\-$/) { # 7(-)

				for( my $i = $n[0]; $i < $nd; ++$i ) {
					&_s_a_prn( $fh, $i, $values, $el, $op, \$border, \$col );
				}

			}
			else { # 4 || 0
				&_s_a_prn( $fh, $n[0], $values, $el, $op, \$border, \$col );
			}

		}
		else { # 1-3 ->(1..3) || 6-7-9 ->(6..9)
			for( my $i = $n[0]; $i <= $n[-1]; ++$i ) {
				&_s_a_prn( $fh, $i, $values, $el, $op, \$border, \$col );
			}
		}

	}

	return $col;
}


sub _var_output {
	my( $fh, $key, $vardata, $columns, $op ) = @_;
	my $values =  (ref $vardata eq 'HASH') ? $vardata->{ $key } : $vardata->[ $key ];

	@$columns or return;

	our $DEBUG;
	our @logs;
	our $nlo;

	if( ref \$values eq 'SCALAR') { # key => SCALAR
		&_v_print( $fh, $key, $values, $columns->[0], $op );
		return;
	}

	if( ref $values eq 'ARRAY') { # key => ARRAY

		# Forming a table
		my $row = 0;
		my $nd = @$values;

_var_output_M0:
		foreach my $d ( @$values ) { # loop through table rows

push @logs, '--> Table row = '. $row if $DEBUG;

			my $col = 0;
			foreach my $el ( @$columns ) { # loop through table columns (for ARRAY.HASH) or rows (for ARRAY.SCALAR)

				my $ki = $el->{ki};
				my $border = ((! $row and ! $col) or ($row >= $#{ $values } and (!defined( $ki ) or !length( $ki )) ) ) ? 1 : 0;

				my $val;
				if( defined $ki ) {
					if((ref \$d eq 'SCALAR') or (ref \$d eq 'REF' and ref $d eq 'SCALAR')) { # (ARRAY.SCALAR or ARRAY.REF->SCALAR) in regular vector

						if( $ki =~/^[\d,\-]+$/) {
						# mixed indices, e.g.: 1-3,6-7-9,-,4,-5,0,7- or 3- (i.e. 3..arr_end) or 0-5 (0..5) or -1- (-1,-2,..arr_start)
							last _var_output_M0 if $row;

							if( $_ = &_mixed_indices( $fh, $ki, $values, $el, $op, $border ) ) {
								$col += $_ - 1;
							}
						}
						next;
					}
					elsif( ref $d eq 'HASH' and defined( $d->{$ki} ) ) { # ARRAY.HASH
						$val = $d->{$ki};

						if( ref $val eq 'ARRAY') { # ARRAY.HASH.ARRAY
							for my $vv ( @$val ) {
								next unless ref \$vv eq 'SCALAR';

								&_hvt_print( $fh, $ki, $vv, $el, $op, $border );
								++$col;
							}
							next;
						}
						elsif( ref \$val ne 'SCALAR') { # TODO for REF
							next;
						}
					}
					elsif( ref $d eq 'ARRAY') { # ARRAY.ARRAY

						if( $ki =~/^[\d,\-]+$/) {
						# mixed indices, e.g.: 1-3,6-7-9,-,4,-5,0,7- or 3- (i.e. 3..arr_end) or 0-5 (0..5) or -1- (-1,-2,..arr_start)
							$_ = &_mixed_indices( $fh, $ki, $d, $el, $op, $border ) and $col += $_ - 1;
						}

						next;
					}
					elsif( $op->{def} ) {

push @logs, "~~> l.$. NOT defined %%%V:". $ki if $DEBUG;

						next;
					}
				}
				else {
				# empty parameter -- at the very end of the columns (parameters)
					$ki = '';
				}

				&_hvt_print( $fh, $ki, $val, $el, $op, $border );
			}
			continue {
				++$col;
			}
		}
		continue {
			++$row;
		}

	}
	elsif( ref $values eq 'HASH') {

		my $col = 0;
		foreach my $el ( @$columns ) { # loop through parameters of %%%VAR-structure

			my $ki = $el->{ki};
			my $border = ( ! $col or ($col >= $#{ $columns } and (!defined( $ki ) or !length( $ki )) )) ? 1 : 0;

			my $val;
			if( defined $ki ) {
				if( ref \$values->{$ki} eq 'SCALAR' and defined( $values->{$ki} )) { # HASH.SCALAR
					$val = $values->{$ki};
				}
				elsif( ref \$values->{$ki} eq 'REF' and ref $values->{$ki} eq 'SCALAR') { # HASH.REF->SCALAR
					$val = ${ $values->{$ki} };
				}
				elsif( $ki eq '@' and ref $values->{'@'} eq 'ARRAY') {
					for my $k ( @{ $values->{'@'} } ) {
						next unless defined($k) && exists( $values->{$k} );

						my $v;
						if( ref \$values->{$k} eq 'SCALAR') {
							$v = $values->{$k};
						}
						elsif( ref \$values->{$k} eq 'REF' and ref $values->{$k} eq 'SCALAR') {
							$v = ${ $values->{$k} };
						}
						elsif( $op->{def} ) {
push @logs, "-->\tl.$. ". 'NOT HASH.ARRAY.SCALAR %%%V:@->{'.$k."} in %%%VAR:". $key if $DEBUG;

							next;
						}

						&_hvt_print( $fh, $k, $v, $el, $op, $border );
						$border = 0;
					}
					next;
				}
				elsif( $op->{def} ) {
push @logs, "~~> l.$. NOT HASH.SCALAR or NOT defined %%%V:". $ki if $DEBUG;

					next;
				}
			}
			else {
			# empty parameter -- at the very end of the columns (parameters)
				$ki = '';
			}

			&_hvt_print( $fh, $ki, $val, $el, $op, $border );
		}
		continue {
			++$col;
		}
	}

}

1;

__END__

=head1 NAME

LaTeX::Replicase - Perl extension implementing a minimalistic engine
for filling real TeX-LaTeX files that act as templates.

=encoding utf8

=head1 SYNOPSIS

Activate the module:

  use LaTeX::Replicase qw( replication );

or

  use LaTeX::Replicase qw(:all);

Usage examples:

=over 3

=item 1.
Using C<replication()> with default options.

The following pseudo-code extract demonstrates this:

=over 6

=item *
Fragment of the original (source) TeX file (or an array of strings, each of which is an element of this array)
with fillable fields C<myParam>, C<myArray>, C<myHash>, C<myTable_array>, and C<myTable_hash>:

  %%%TDZ:  %-- beginning of The Dead Zone
  \documentclass[10pt,a4paper]{article}
  \usepackage[english]{babel}
  \usepackage{amsmath}
  \usepackage{color}
  \usepackage{url}

  \title{ChiTaRS-${}_{3.1}$-the enhanced chimeric transcripts and RNA-seq database etc...}
  \author{Alessandro Gorohovski, etc...}

  \begin{document}
  \maketitle
  %%%ENDZ: -- end of The Dead Zone

  SPECIFY VALUE of myParam! %%%V: myParam  %-- substitutes Variable

  etc...

  \begin{tcolorbox}
  \rule{0mm}{4.5em}%%%VAR: myParam -- substitutes Variable as well
  ...
  ... SPECIFY VALUE of myParam!
  ...
  %%%END:
  \end{tcolorbox}

  \begin{tabular}{%
  c
  %%%VAR: myArray
  l %%%ADD:%  -- column "l" type will repeat as many times as myArray size, e.g. 'lll...l'
  lllll
  %%%END:
  }
  % head of table
  Expense item &
  %%%VAR: myArray
  %-- eXcept 1st (0) row (record)
  %%%ADDX: &
  \multicolumn{1}{c}{ %%%ADD:%  -- there will be no line break
  % there will be no line break also
  2020 %%%V:@%
  } %%%ADDE:  -- final part of '@' variables
  & 2021 & 2022 & 2023 & 2024 & 2025  % All of this will be replaced until %%%END:
  %%%END:
  \\ \hline

  etc...

  \\ \hline
  HASH Summary
  %%%VAR: myHash
  & %%%ADD:
  00000 %%%V: year0
  & %%%ADD:
  11111 %%%V: year1
  & %%%ADD:
  22222 %%%V: year2%
   &  %%%ADD:%
  33333 %%%V: year3
  & 44444  &  55555
  %%%END:

  %%%VAR: myTable_array
  \\ \hline %%%ADD:
   SPECIFY VALUE 0!  %%%V:0
  &  %%%ADD:
  \multicolumn{1}{c}{ %%%ADD:% -- there will be no line break
   SPECIFY VALUES from 3 to last element of array! %%%V:3-%
  } %%%ADDE:
  & %%%ADD:%
   SPECIFY VALUES 1 and 2 %%%V:1,2
  &  22222  &  33333  & 44444  &  55555

  %%%TDZ: -- beginning of The Dead Zone. Yes, you can use this instead of %%%END:

  \\ \hline
  \end{tabular}
  ...
  \begin{tabular}{cccc}
   column2 & column1 & column0 \\\\
   \toprule
  %%%ENDZ: -- end of The Dead Zone

  %%%VAR: myTable_array
  SPECIFY VALUE 4 %%%V: 4
   & %%%ADD:%  % add " &" without line breaks ("\n")
  SPECIFY VALUES 2, 1, and 0! %%%V: -3-%
   & VALUE 1
   & VALUE 0
  \\ %%%ADD:
  \midrule %%%ADDX:
  ...
  VALUE 4 & VALUE 2 & VALUE 1 & VALUE 0
  \\
  \midrule
  ...
  %%%TDZ: %-- beginning of The Dead Zone.
  \end{tabular}
  ...
  \begin{tabbing}
  %%%ENDZ: -- end of The Dead Zone
  %%%VAR: myTable_hash
  %%%ADDX: \\\\
     SPECIFY VALUE 'A'! %%%V: A%
   \= %%%ADD:%
     SPECIFY VALUE 'B'! %%%V: B%
   \= %%%ADD:%
     SPECIFY VALUE 'C'! %%%V: C
  %%%ENDT: -- end of Template area (and myTable_hash also)
  \end{tabbing}

  etc...

  \end{document}


=item *
Dataset to fill TeX file (see above):

  my $info = {
       myParam => 'Blah-blah blah-blah blah-blah',
       myArray => [2024, 2025, 2026, 2027],
       myHash => {year0 => 123456, year1 => 789012, year2 => 345678, year3 => 901234},
       myTable_array => [ # custom user variable ARRAY-ARRAY
          ['00','01','02','03','04',], # row 0
          [10, 11, 12, 13, 14,], # row 1
          [20, 21, 22, 23, 24,], # row 2
       ],
       myTable_hash => [ # custom user variable ARRAY-HASH
         {A=>'00',B=>'01',C=>'02',}, # row 0
         {A=>10, B=>11, C=>12, }, # row 1
       ],
  };

  my $msg = replication( $file, $info );


=item *
Ready (filled, completed) TeX file (or the console output result, i.e. STDOUT):

  %-- beginning of The Dead Zone
  \documentclass[10pt,a4paper]{article}
  \usepackage[english]{babel}
  \usepackage{amsmath}
  \usepackage{color}
  \usepackage{url}

  \title{ChiTaRS-${}_{3.1}$-the enhanced chimeric transcripts and RNA-seq database etc...}
  \author{Alessandro Gorohovski, etc...}

  \begin{document}
  \maketitle

  Blah-blah blah-blah blah-blah %-- substitutes Variable

  etc...

  \begin{tcolorbox}
  \rule{0mm}{4.5em}Blah-blah blah-blah blah-blah-- substitutes Variable as well
  \end{tcolorbox}
  \begin{tabular}{%
  c
  llll}
  % head of table
  Expense item &
  \multicolumn{1}{c}{2024}
  &
  \multicolumn{1}{c}{2025}
  &
  \multicolumn{1}{c}{2026}
  &
  \multicolumn{1}{c}{2027}
  \\ \hline

  etc...

  \\ \hline
  HASH Summary
  &
  123456
  &
  789012
  &
  345678 & 901234
  \\ \hline
  00
  & 
  \multicolumn{1}{c}{03}
  & 
  \multicolumn{1}{c}{04}
  &01
  &02
  \\ \hline
  10
  & 
  \multicolumn{1}{c}{13}
  & 
  \multicolumn{1}{c}{14}
  &11
  &12
  \\ \hline
  20
  & 
  \multicolumn{1}{c}{23}
  & 
  \multicolumn{1}{c}{24}
  &21
  &22
  \\ \hline
  \end{tabular}
  ...
  \begin{tabular}{cccc}
   column2 & column1 & column0 \\
   \toprule
  04
   &02 &01 &00\\
  \midrule
  14
   &12 &11 &10\\
  \midrule
  24
   &22 &21 &20\\
  \end{tabular}
  ...
  \begin{tabbing}
  00 \=01 \=02
  \\
  10 \=11 \=12
  \end{tabbing}
  etc...
  \end{document}


=back

A new TeX C<base_file> from the template C<$file> (or C<$arr>) filled with data from C<$info> will be created in
B<random subdirectory> (its name is stored in C<$$> variable) of current directory.
File name of source C<$file> can be absolute,
i.e. with a full path (include directories and subdirectories).
C<base_file> name is extracted (same) from source C<$file>.
Under no circumstances will source C<$file> be overwritten by new C<base_file>.

If the source is an array reference and no target file name is specified by C<ofile> option,
then 'ready.tex' file will be created in a B<random subdirectory> 
(its name is stored in C<$$> variable) of current directory.

=item 2.
Using C<outdir> option:

  my $msg = replication( $file, $info, outdir => $target_dir );

A new C<$file> will be created in C<$target_dir> directory.

=item 3.
Using C<ofile> option:

  my $msg = replication( $file, $info, ofile => $ofile );

A new C<$ofile> will be created.
C<ofile> option suppresses (eliminates) C<outdir> option, i.e.
file name of C<$ofile> can be absolute.
Under no circumstances will source C<$file> be overwritten by new C<$ofile>.

If the completed template (ready TeX) needs to be output directly to the console
(or, for example, for the Web), you can specify:

  ofile => *STDOUT

Of course, in this case C<outdir> option will not be valid either.

=item 4.
Set the C<$DEBUG> package variable to enable debugging messages (global debug mode):

    $LaTeX::Replicase::DEBUG = 1;

=back

=head1 LIMITATIONS

This module have reason only for C<SCALAR>, C<REF>, C<ARRAY>, C<HASH>, C<ARRAY.ARRAY>, C<ARRAY.HASH>, C<ARRAY.REF>, C<ARRAY.ARRAY.ARRAY>, C<ARRAY.HASH.ARRAY> 
data with perl 5.10 and higher.

File and directory names and paths to them must not contain space characters.

In the names of C<%%%V:> and C<%%%VAR:> tags (keys and indexes), it is possible (preferably) to use 
only C<[a-zA-Z0-9_]> symbols, since other symbols are currently or will be reserved in the future.

Currently, symbols: C<%>, C<@>, C<:>, and C</> have a special purpose.


=head1 ABSTRACT

Replicase is minimalistic (ascetic) interpreter (uses only 3-4 basic control tags,
like the system of 4 bases (nucleotides) and 3 codons, it is an optimal balance between diversity and stability)
that can be used to process (fill) real TeX-LaTeX files that act as templates.


=head1 DESCRIPTION

This module is a Perl 5 extension implementing Replicase subroutines which processes TeX-LaTeX files, 
interpreting and executing built-in control directives (tags) of Replicase.

Replicase can: define and substitute variable values, execute conditional actions and capture 
the resulting output into a new document.
Replicase was originally designed for creating programmatically configurable TeX-LaTeX documents.

Unlike other template engines, here conditionals (logic) and loops are completely separated from TeX-LaTeX document
and are moved to your Perl program using this module. It's well suited for this and similar tasks,
allowing you to dynamically create PDF or PostScript documents that are consistent with each other, yet easily customisable.

Replicase is a standalones, safe as a TeX-LaTeX, and fast template engine with remarkable features.
All markup is based on following basic "three pillars" (directives, tags):

=over 3

=item *
B< C<%%%V: variable_name> > is a short form of a regular (SCALAR) I<variable_name>
which replaces the text located to the left of it, in the line where it is located, e.g.

  Before blah, blah, \ldots blah. %%%V: myParam

will be replaced by contents of C<myParam> variable.
However, if there is text after this variable, it will be added to the right of its value:

  Before blah, blah, \ldots blah. %%%V: myParam   After blah, \ldots blah.

here 'After blah, \ldots blah.' will remain to the right of C<myParam> value in the line.

This construct can be used as an ON or OFF switch, for example by setting C<myParam>
to "~" (i.e. " ") or "%" the text 'After blah, \ldots blah.' will be present or absent 
in the finished PDF or PostScript document.

If a C<variable_name> ends in C<%> (i.e. C<variable_name%>), a newline is suppressed.
By default, a newline always occurs after value substitution and 'After blah, \ldots blah.' if it exists.

In C<variable_name> you can use the special character "C</>", which denotes the "path" 
to the variable(s) in the passed dataset (C<$info>) structure, e.g.
C<%%%V: key/myParam>, C<%%%V: key/index/myParam>, etc.

If this "path" to C<variable_name> begins with "C</>", then it is I<absolute> and the variable is searched for 
from the root (initial) C<$info> structure. Otherwise, the "path" is determined I<relative> to 
the current I<global environment>, previously established in the same way.

For example, using this trick, C<< %%%V:/key/subkey >>, you can move (shift) the I<global environment> of all
subsequent (further down) C<%%%V:> and C<%%%VAR:> variables into the C<< $info->{key}{subkey} >> area (scope).
To return to the root (initial) C<$info> I<global environment> of all variables, call C<< %%%V: / >>.

If this "path" ends with a regular (scalar) variable or a reference to one, 
then the I<global environment> is not redefined, 
e.g. C<%%%V: key/index/myParam>, here C<key/index> "path" is exclusively 
the I<local environment> of C<myParam> variable.

C<%%%V:> nested within the scope of C<%%%VAR:> tag do not change the I<global environment>,
and the "C</>" character is not a separator in the "path".
It is a normal character in the C<variable_name>.

CONCLUSION: standalone C<%%%V:> tag (outside C<%%%VAR:> scope) can be used to set the B<global variable lookup environment>.

C<%%%V:> can be nested in an ARRAY or HASH C<%%%VAR:> tag,
but in SCALAR or REF C<%%%VAR:> it will not work and will be discarded.

There's a special C<variable_name> - C<@>, which means to "B<use all elements of an ARRAY>".
Therefore, this only makes sense for ARRAY variables (see example above).

Using C<@> for HASH variables is also acceptable.
In this case, it is assumed that a key with this name exists in the hash, 
which stores a list (vector) of the keys of this hash in the order 
they are inserted into TeX template.


=item *
B< C<%%%VAR: variable_name> > is start of full form of regular (SCALAR) or complex (HASH, ARRAY) C<variable_name>,
preserving preceding TeX up to C<%%%VAR:> but completely replacing everything up to first C<%%%END:> 
(C<%%%ENDT:>, C<%%%ENDZ:>, or a new C<%%%VAR:>, or C<%%%TDZ:>) tag inclusive.

  Blah, blah, \ldots blah. %%%VAR: myParam
  Blah, blah, \ldots
  \ldots

  Blah, \ldots %%%END:

Usually HASH and ARRAY I<variable_name> are used in the template to create (fill) tables.

C<%%%VAR:> tag is similar to C<%%%V:> tag, where the variable name can be used to specify its search 
"path" using a special symbol, "C</>". However, this "path" does not affect the I<global environment>.
It only sets the I<local environment> within the scope of C<%%%VAR:> tag.

Nested C<%%%VAR:> tags will not work and are treated as C<%%%END:> tags,
i.e. tags for early termination of the scope.


=item *
There are three options for B< C<%%%ENDx> > tags:

=over 6

=item 1.
B< C<%%%END:> > is used to specify the end of C<%%%VAR:> tag.

BTW: if this tag is omitted and there are no further C<%%%ENDT:>, C<%%%ENDZ:>, C<%%%VAR:>, and C<%%%TDZ:> tags,
all text to the end of document will be replaced by C<variable_name> specified in C<%%%VAR:> tag.

=item 2.
B< C<%%%ENDZ:> > is used to mark the end of the C<%%%TDZ:> tag.

C<%%%TDZ:> marks B<The Dead Zone> in the template free from any tag searches.
It can also be used to disable (deactivate) tags.

=item 3.
B< C<%%%ENDT:> > is used to mark the end of a template.

It is typically applied to the bottom of a document to terminate tag searches and speed up processing.
It can also be used to disable (deactivate) tags.

=back

B<ATTENTION!> Text (and newline) located in line with any C<%%%END:>, C<%%%ENDZ:>, and C<%%%ENDT:> tags will be discarded.

=item *
B< C<%%%TDZ:> > marks the start of B<The Dead Zone> in the template free from any tag searches.
This tag must start at the very beginning of the line and be single on the line.

It can also be used to disable other tags.

=back

The following tags can be located within the block limited by ARRAY and HASH C<%%%VAR:> and
any C<%%%ENDx>, C<%%%TDZ:>, or a new C<%%%VAR:> tags:

=over 3

=item *
B< C<%%%V: key|index> > with setting of C<key> (in case of HASH C<%%%VAR:>, i.e. C<%%%V: keyA>, C<%%%V:keyB>, etc.)
or C<index> (in case ARRAY C<%%%VAR:>, i.e. C<%%%V:0>, C<%%%V:1>, C<%%%V:2>, C<%%%V:-7>, etc.).
Here C<keys> or C<indexes> are columns (or positions) of the table (filled area) being created.

C<index> can also be specified as a comma-separated list of numbers (array indices, e.g., 1, -7, 3, 5, -9),
or as a closed (0-7, 4-10), left-open (-3-), or right-open (0-) range of array indices.
In this case, spaces are also not allowed.

Negative values and left-open range indicate the reverse order of the array indices,
i.e., counting from the end. For example, -1- means from -1,-2,-3,... to the initial element of the array (vector).

There's C<@> - a special name of C<index> which means "B<to use all elements of an ARRAY>".
It's actually short for right-open range: C<< 0- >>.
Therefore, this only makes sense for ARRAY variables.

Using C<@> for HASH variables is also acceptable.
In this case, it is assumed that a key with this name exists in the hash, 
which stores a list (vector) of the keys of this hash in the order 
they are inserted into TeX template.

If a C<key|index> ends in C<%> (e.g. C<keyA%>, C<%%%V:0%>, C<%%%V:@%>, etc. ), a newline is suppressed.
(By default, a newline always occurs after value substitution and 'After blah, ... blah.' if it exists).


=item *
There are three options for B< C<%%%ADDx> > tags:

=over 6

=item 1.
B< C<%%%ADD:> > adds text B<before> variable specified in C<%%%V:> tag.

The added text is taken from the beginning of the line to the beginning of C<%%%ADD:>
(i.e. text located on the left), e.g.

  Head blah, blah, \ldots blah. %%%ADD: Tail blah, blah, \ldots

this text will be added here: C<Head blah, blah, \ldots blah.>

Or, if C<%%%ADD:> is located at the very beginning of line, then after it to the end of line
(i.e. text located on the right), e.g.

  %%%ADD: Tail blah, blah, \ldots

this text will be added here: C<Tail blah, blah, \ldots>.

If the following C<%%%V:> tag is not present, then the text is output B<at the end of all> C<keys> or C<indexes> (columns)
each table (filled area) row.

BTW: 
By combining auxiliary parameters and the C<def> facultative option (see below), which specifies discarding (ignoring) 
C<undefined> values and their associated C<%%%ADD:> structures, you can create a logic scheme for disabling C<%%%ADD:> tags.
For example:

  %%%VAR: myTable
  \\  %%%ADD:
  % %%%V: head

  etc...

  \\  %%%ADD:
  \midrule  %%%ADD:
  %  %%%V: rule

  my $info = {
       myTable => [
        {head =>'%', ... }, # 'rule' is undefined
        {rule =>'%', ... }, # 'head' is undefined
        ...
       ]
       ...
    };

   my $msg = replication( $file, $info, def =>1 );

=item 2.
B< C<%%%ADDE:> > is similar to C<%%%ADD:>, but
it differs in that text is added B<after> variable specified in C<%%%V:> tag.

This C<%%%ADDE:> tag must follow immediately after C<%%%V:> tag 
(i.e. there should not be C<%%%ADD:> tag before it), otherwise it will also become 
a regular C<%%%ADD:> tag, for example for the next C<%%%V:>.


=item 3.
B< C<%%%ADDX:> > is similar to C<%%%ADD:> for all lines (records)
B<eXcept the first column (0) of first record (0)> or B<after the last column of last record>.

=back

If any C<%%%ADDx:> ends in C<%> (e.g. C<%%%ADD:%>, C<%%%ADDE:%>, or C<%%%ADDX:%> ), a newline is suppressed.
(By default, a newline always occurs after adding text).

=back

Only B<ONE tag> can be located on B<ONE line> of input C<$file> (document).

Tag names must be in C<%%%UPPERCASE:>.

Tags can "absorb" one whitespace character around them (left and/or right), if present.


=head1 SUBROUTINES

LaTeX::Replicase provides these subroutines:

    replication( $source, $info [, %facultative_options ] );
    tex_escape( $value [, '~'] );


=head2 replication( $source, $info [, %facultative_options ] )

Creates a new output file from the specified TeX C<$source>, which is a template.
The TeX-template C<$source> can be either a TeX-file or an array reference,
each element of which is a TeX-string ((with line break C<\n> if necessary).

File name of C<$source> can be absolute,
i.e. with a full path (include directories and subdirectories).
File and directory names and paths to them must not contain space characters.

The output file name is extracted (the same) from C<$source>.
Under no circumstances will C<$source> be overwritten by the new one.

If C<$source> is an array reference and no target file name is specified by C<ofile> option,
then 'ready.tex' file will be created in a B<random subdirectory> 
(its name is stored in C<$$> variable) of current directory.

C<$info> HASH or ARRAY is used to fill template:

  $info = { };
  # or
  $info = [ ];

When C<replication> processes C<$source> it identifies tags and replaces them with the result of whatever 
the tag represents (e.g. variable value for C<%%%V:> or from C<%%%VAR:> to C<%%%END:>). Anything outside the tag(s),
including newline characters, are left intact.

The following C<%facultative_options> can be used when calling C<replication>:

=over 3

=item C<outdir>

  my $msg = replication( $source, $info, outdir => $target_dir );

A new C<$source> will be created in C<$target_dir> directory.
File and directory names and paths to them must not contain space characters.

=item C<ofile>

  my $msg = replication( $source, $info, ofile => $ofile );

A new C<$ofile> will be created.
C<ofile> option suppresses (eliminates) C<outdir> option, i.e.
file name of C<$ofile> can be absolute.
File and directory names and paths to them must not contain space characters.

If the completed template (ready TeX) needs to be output directly to the console
(or, for example, for the Web), you can specify:

  ofile => *STDOUT

Of course, in this case C<outdir> option will not be valid either.

=item C<utf8>

This option specifies the template and output files' character encoding as utf8:

  my $msg = replication( $source, $info, utf8 =>1 );

=item C<esc>

This option applies C<tex_escape()> subroutine to all incoming values to mask active TeX characters:
C<&> C<%> C<$> C<#> C<_> C<{> C<}> C<~> C<^> C<\>.

  my $msg = replication( $source, $info, esc =>1 ); # or esc =>'~'

BTW: if the value starts with the C<%%%:> tag, then this tag is removed 
(e.g. C<%%%:$\frac{12345}{67890}$> is converted to C<$\frac{12345}{67890}$>),
and the value itself is not masked, it is skipped.

=item C<def>

This option specifies B<discarding> (ignoring) C<undefined> values and associated structures (C<%%%ADD...>),
i.e. dictates that only C<defined> values be B<into account>.

  my $msg = replication( $source, $info, def =>1 );

This option is useful, for example, for creating merged cells in tables (using C<\multicolumn> LaTeX-command)
and applies to all incoming data. Also this option can be used as an ON or OFF switch (see above).

=item C<ignore> 

This option specifies silently ignore undefined B<name|key|index> of C<%%%V:> and C<%%%VAR:> tags:

  my $msg = replication( $source, $info, ignore =>1 );

=item C<silent> 

This option activates silent mode of operation:

  my $msg = replication( $source, $info, silent =>1 );

=item C<debug>

This option sets local debug mode:

  my $msg = replication( $source, $info, debug =>1 );
  if( ! $msg ) {
    say 'Ok';
  }
  else {
    say for @$msg;
  }


Another way is to set the C<$DEBUG> package variable to enable debugging messages (global debug mode).

    $LaTeX::Replicase::DEBUG = 1;

=back

C<replication> returns C<undef> or a reference to an error (and/or debug) message(s) array.


=head2 tex_escape( $value [, '~'] )

Masks (or replaces with equivalents) the active TeX characters C<&> C<%> C<$> C<#> C<_> C<{> C<}> C<^> C<\>
to C<\&> C<\%> C<\$> C<\#> C<\_> C<\{> C<\}> C<\^{}> C<\textbackslash> in the input C<$value>.

  tex_escape( $value );

With the facultative (optional) option C<~> you can additionally replace the character C<~> with C<\texttt{\~{}}>.

  tex_escape( $value, '~');

If the C<$value> starts with the C<%%%:> tag, then this tag is removed
(e.g. C<$value = '%%%:$\frac{12345}{67890}$'> is converted to C<$value = '$\frac{12345}{67890}$'>),
and the value itself is not masked, it is skipped.


=head1 EXPORT

LaTeX::Replicase exports nothing by default.
Each of the subroutines can be exported on demand, as in

  use LaTeX::Replicase qw( replication );

and the tag C<all> exports them all:

  use LaTeX::Replicase qw( :all );


=head1 DEPENDENCIES

LaTeX::Replicase is known to run under perl 5.10.0 on Linux.
The distribution uses L<File::Basename>,
L<File::Path>,
L<File::Compare>,
and L<Carp>.

=head1 SEE ALSO

Perl modules that offer similar functionality:

L<Template::Latex>, L<LaTeX::Easy::Templates>


=head1 SUPPORT AND BUGS

You can find documentation for this module with the perldoc command.

  perldoc LaTeX::Replicase

Please bug reports, comments or feature requests to: L<https://github.com/AlessandroGorohovski/LaTeX-Replicase>

The original bug tracker can be found at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=LaTeX-Replicase>


=head1 AUTHOR

Alessandro N. Gorohovski, E<lt>an.gorohovski@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2026 by Alessandro N. Gorohovski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
