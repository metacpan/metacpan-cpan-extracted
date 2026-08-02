package LaTeX::Replicase;

use 5.010;
use strict;
use warnings;
# no warnings 'numeric';
use utf8;

use File::Basename qw(fileparse);
use File::Path qw(make_path);
use File::Compare;
use Carp;
# use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ('all' => [ qw(
		replication
		tex_escape
		REase
	) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.790';
our $DEBUG = 0;
$DEBUG += 0;

our $qs = qr/^|_|\b/o;
our $qe = qr/_|\b|$/o;

# for glue
our $q = qr/\{\\hskip0pt +plus +0?.02em\}/o;
our $p; $p = qr/\{\s*(?:(?>$q)|(??{$p}))*\s*\}/o;
our $m = '{\\hskip0pt plus .02em}';

# '!'=>\x21  '"'=>\x22  '#'=>\x23  '$'=>\x24  '%'=>\x25  '&'=>\x26  "'"=>\x27
# '('=>\x28  ')'=>\x29  '*'=>\x2A  '+'=>\x2B  ','=>\x2C  '-'=>\x2D  '.'=>\x2E  '/'=>\x2F
# ---
# ':'=>\x3A  ';'=>\x3B  '<'=>\x3C  '='=>\x3D  '>'=>\x3E  '?'=>\x3F  '@'=>\x40
# ---
# '['=>\x5B  '\'=>\x5C  ']'=>\x5D  '^'=>\x5E  '_'=>\x5F  '`'=>\x60
# ---
# '{'=>\x7B  '|'=>\x7C  '}'=>\x7D  '~'=>\x7E
our $sI = qr/[\s\x21-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]/o;
our $sII = qr/[a-zA-Z0-9,=:;!\>\<\)\(\/\.\s\+\-\*\?]+/o;


#-------------------
# External functions

# Masks (or replaces with equivalents) the active 9 TeX characters: &, %, $, #, _, {, }, ^, \
# with additionally replace character '~'
# INPUT:
# $_[0]	string
# $_[1]	HASH of options (only need 'esc' key) / SCALAR string with additional substitutions: '~_%_s_REase_'
# OUTPUT (and $_[1]->{mflag} if $_[1] is 'HASH'):
#	0 -- value NOT changed
#	1 -- value changed
sub tex_escape {
	$_[0] or return 0;

	our( $qs, $qe, $sI, $sII );

	my $opH = ref $_[1] eq 'HASH';
	my $mflag = 0;
	my $prm = '';

	if( $opH ) {

		if( $_[1]->{_MFLAGS_} ) {
			return 0 if $_[1]->{_MFLAGS_} & 0b0100; # SUPPER critical changes in TeX-commands before
			goto _tex_escape_to_REase if $_[1]->{_MFLAGS_} & 0b0010; # critical changes in TeX-commands before
		}

		$prm = $_[1]->{esc} // '';
	}
	elsif( ref \$_[1] eq 'SCALAR') {
		$prm = $_[1] // '';
	}

	goto _tex_escape_to_REase if $_[0] =~/\A${sII}\Z/m;

	my $stag = ''; # start tag

	if( $_[0] =~/\A%%%:/ and $prm !~/!stag(?:$qe)/) { # SKIP start tag

		if( $prm =~/\-stag(?:$qe)/) {
			$_[0] =~s/\A(%%%:)+//m; # remove ALL start tag(s)
			my $s = $1;
			$stag = $s if $prm =~/\+stag(?:$qe)/;
			$mflag |= 0b0001; # simple text changes
		}
		elsif( $prm =~/\+stag(?:$qe)/) { # save start tag '%%%:'
			return $mflag if $prm !~/(?:$qs)REase(?:$qe)/;

			goto _tex_escape_to_REase;
		}
		else {
			$_[0] =~s/\A%%%://m; # remove 1 start tag
			$mflag |= 0b0001; # simple text changes
			goto _tex_escape_to_REase;
		}

	}

	if( $_[0] =~/\\/ ) { # check '\' symbol

		my @arr = split /\\/, $_[0], -1;

		my $yes = 0;
		my $z;
		my $i;
		foreach( @arr ) {
			$z = length;

			if( ++$i > 1 ) {

				if( ! $z ) {
					$_ = 'char92\\/';
					next;
				}

				next if /^char92(?:\D|$)/ or /^textbackslash(?:[^a-zA-Z]|$)/
					or /^relax(?:[^a-zA-Z]|$)/
					or /^hskip\s*\d/;

				if( $prm !~/(?:$qs)strong(?:$qe)/ ) {
					if( $prm =~/(?:$qs)mutual(?:$qe)/ ) {
						next if /^[\$\t%&}{\-\*\/=\._\^~#'`"]/; # classic active TeX & LaTeX symbols, but without '\<space>' command
					}
					elsif( /^[\$\t%&}{\-\*\/=\._\^~#'`",;!\>]/ ) { # active symbols allowed in LaTeX
						next;
					}
				}

				$_ = 'char92'.(/^$sI/ ? '':'\\/'). $_;

			}
			elsif( ! $z ) {
				next;
			}

			s/[%}{_&#\$]/\\$&/g; # masking active symbols
			s|\^|\\^\\/|g; # ^ --> \^\/

			if( $prm =~/~/ ) {
				s|~|\\~\\/|g; # tilde (~) --> \~\/
			}

			if( $prm =~/(?:$qs)hyphen(?:$qe)/ ) {
				s/(?<=[[:alpha:]])\-(?=[[:alpha:]])/"=/gi #"# make compound words with 'active' hyphens
			}

		}
		continue {
			if( $z != length ) { # critical changes for TeX-commands
				$yes ||= 1;
				$mflag |= 0b0010;
			}
		}

		 if( $yes ) {
			$_[0] = join '\\', @arr;
			$_[0] =~s|(?<![~\^])\\/(?=\\)||g; # '\/\' --> '\'
		}

	}
	else {

		for( $_[0] ) {
			my $z = length;

			s/[%}{_&#\$]/\\$&/g; # masking active symbols
			s|\^|\\^\\/|g; # ^ --> \^\/

			if( $prm =~/~/ ) {
				s|~|\\~\\/|g; # tilde (~) --> \~\/
			}

			if( $prm =~/(?:$qs)hyphen(?:$qe)/ ) {
				s/(?<=[[:alpha:]])\-(?=[[:alpha:]])/"=/gi #"# make compound words with 'active' hyphens
			}

			s|(?<![~\^])\\/(?=\\)||g; # '\/\' --> '\'

			$mflag |= 0b0010 if $z != length; # critical changes for TeX-commands
		}

	}

	$_[0] = $stag . $_[0] if $stag; # add start tag

_tex_escape_to_REase:

	if( $prm =~/(?:$qs)REase(?:$qe)/ ) {
		if( $opH ) {
			$_[1]->{_MFLAGS_} += 0;
			$_[1]->{_MFLAGS_} |= $mflag;

			$mflag |= &REase;
		}
		else {
			$mflag |= &REase( $_[0], { _MFLAGS_ => $mflag, esc => $prm } );
		}

	}


	return $mflag if defined wantarray;
}

# REstrictase
# INPUT:
# $_[0]	string
# $_[1]	HASH of options
# OUTPUT:
#	0 -- value NOT changed
#	1 -- value changed
sub REase {
	$_[0] or return 0;

	our( $qs, $qe, $q, $p, $m, $sI );

	my $opH = ref $_[1] eq 'HASH';

	my $prm = '';
	my $n = 3; # size of tile, by default

	if( $opH ) {
		return 0 if $_[1]->{_MFLAGS_} and $_[1]->{_MFLAGS_} & 0b0100; # there were super critical changes in TeX-commands before

		$prm = $_[1]->{esc} // '';
		$n = $& if $_[1]->{tile} and $_[1]->{tile} =~/[2-9]/; # 2..9
	}
	elsif( ref \$_[1] eq 'SCALAR') {
		$prm = $_[1] // '';
	}

	my $mflag = 0;

	if( $_[0] =~/^%%%:/ and $prm !~/!stag(?:$qe)/) { # SKIP start tag

		if( $prm =~/\-stag(?:$qe)/) {
			$_[0] =~s/^(%%%:)+//; # remove ALL start tags
			$mflag |= 0b0001; # simple text changes (without TeX-commands)
		}
		else {
			$_[0] =~s/^%%%://; # remove 1 start tag only
			return 0b0001;
		}
	}

	return 0 if $_[0] =~/\\relax\\\/$/ # exists etag
					or $_[0] =~/^(?:%%%:)?$q/ # protection against reuse
					or length( $_[0] ) < $n + 2;

	my @arr = split /\s+/, $_[0], -1;

	my $stag = ($arr[0] =~s/^%%%://) ? $& : ''; # start tag
	my $etag = ($_[0] =~/\s+$/) ? $& : ''; # end tag


	for( @arr ) {
		next if $n + 2 > length
				or /\A\p{Alpha}\Z/;

		my $z = $_;

		s/(?:(?<b>.{2,$n}[^\x5C])|(?<b>[^\x5C]|\b))(?<s>[^\x5C\p{Alpha}\.><'`=_\"-])(?(1)|(?=\p{Alpha}))/$+{b}$m$+{s}$m/g; #'

		s/-{1,3}/$m$&$m/g; # don't touch the em dash
		s/\<{1,2}/$m$&/g;
		s/\>{1,2}/$&$m/g;

		# removal of excess glue:
		s/(?<=[\(\[\{])(?:$q)+(?=[[:alnum:]])//g; # after the opening parenthesis
		s/(?<=[[:alnum:]])(?:$q)+(?=[\)\]\}])//g; # before the closing parenthesis

		# Reducing of excess glue
		s/$p/$m/g;

		# final removal of excess glue:
		s/^(?:\s*$q\s*)+|(?:$q\s*)+$//g; # start & end glue
		s/\x5C(?:$q)+/\\/g; # JIC: glue after '\'

		s|(?<=\\char)(?:$q)?9(?:$q)?2(${sI}?)|'92'.$1//'\\/'|eg; # restore '/'

		# delete an extra:
		s|(?<=\\char92)($q)\\/|$1|g; # remove '\/'
		s|(?<=\\char92)\\(?!$q)/|$m|g; # '\/' --> glue
		s|(?<=\x5C\^)($q)\\/|$1|g; # '\^\/'
		s|(?<=\\~)($q)\\/|$1|g; # '\~\/'
		s/(?:$q){2,}/$m/g;

		$mflag |= 0b0111 if $z ne $_;
	}

	if( $mflag ) {
		$arr[0] = $stag . $m . $arr[0];
		$_[0] = join ' ', @arr;
		$_[0] =~s/ +$/$etag/ if $etag;
	}

	return $mflag if defined wantarray;
}


sub replication {
	my( $source, $info, %op ) = @_;

	our $DEBUG;
	$op{debug} //= $DEBUG + 0;

	our( $qs, $qe, $sI, $sII );

	my $rstype = ref \$source;
	my $stype = ref $source;

	my @logs;

	if( defined( $source ) && length( $source ) ) {

		if( $rstype eq 'SCALAR') {
			for( $source ) {
				s/^\s+//;
				s/\s+.*//s;

				$_ = (glob)[0] if $^O =~/(?:linux|bsd|darwin|solaris|sunos)/;
			}
		}
		elsif( $stype ne 'ARRAY')  {
			$_ = "!!! ERROR#6: invalid FILE or ARRAY input!";
			$op{silent} or carp $_;

			push @logs, $_;
			return \@logs;
		}

	}
	else {
		$_ = "!!! ERROR#0: undefined input FILE or ARRAY!";
		# uncoverable branch true
		$op{silent} or carp $_;

		push @logs, $_;
		return \@logs;
	}

push @logs, "--> Checking source data: '$source'" if $op{debug};

	if(( $rstype eq 'SCALAR' and ! -s $source) or ( $stype eq 'ARRAY' and ! @$source)) {
		$_ = "!!! ERROR#1: source ('$source') does NOT exist or is EMPTY!";
		# uncoverable branch true
		$op{silent} or carp $_;

		push @logs, $_;
		return \@logs;
	}

	# global data of TeX file
	my $dtype = ref $info;
	unless( $info
		and (( $dtype eq 'HASH' and %$info ) or ($dtype eq 'ARRAY' and @$info ))
	) {
		$_= "!!! ERROR#2: EMPTY or WRONG data!";
		$op{silent} or carp $_;

		push @logs, $_;
		return \@logs;
	}

	# environments: global for %%%V:, %%%VAR: ; and local for %%%VAR:
	my $data = my $vardata = $info;

	my( $filename, $dir );
	if( $rstype eq 'SCALAR') {
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

			# uncoverable branch true
			if ($err && @$err) {

				for my $diag (@$err) {
					my( $path, $message ) = %$diag;
					$_ = ( $path && length( $path ) ) ?
						"!!! ERROR#7: ('$path' creation problem) $message" :
						"!!! ERROR#8: (general error) $message";

					# uncoverable branch true
					# uncoverable branch false
					$op{silent} or carp $_;
					push @logs, $_;
				}

				return \@logs;
			}

		}

		$ofile = "$outdir/$filename";
	}

push @logs, "--> Using '$ofile' file as output" if $op{debug};

	# new file must be different
	if( -s $ofile and $rstype eq 'SCALAR'
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
	if( $rstype eq 'SCALAR') {
		my $mode = $op{utf8} ? ':utf8' : '';

push @logs, "--> Open '$source'" if $op{debug};

		open $TEMPLATE, "<:raw$mode", $source or do{
			$_= "!!! ERROR#4: $!";
			$op{silent} or carp $_;

			push @logs, $_;
			return \@logs;
		};
	}

	unless( $fh ) { # it's not "::STDOUT"
		my $mode = $op{utf8} ? ':encoding(utf8)' : '';

push @logs, "--> Open '$ofile'" if $op{debug};

		open $fh, ">$mode", $ofile or do{
			$_= "!!! ERROR#5: $!";
			$op{silent} or carp $_;

			push @logs, $_;
			return \@logs;
		};
	}

	my %actions = (
		tex_escape => \&tex_escape,
		REase => \&REase,
	);

	if( ref $op{_ACTIONS_} eq 'ARRAY' and @{ $op{_ACTIONS_} } ) {

		my %done;

		for my $f ( @{ $op{_ACTIONS_} } ) { # Check subs and setup
			$f or next;

			my $rftype = ref \$f;
			my $ftype = ref $f;

			if( $rftype eq 'SCALAR') {
				if( exists $actions{$f} ) {

					if( exists( $done{$f} ) or exists( $done{ $actions{$f} } ) ) {
						undef $f;
					}
					else {
						$done{ $actions{$f} } = $done{$f} = undef;
						$f = {
							_name_ => $f,
							_code_ => $actions{$f},
						};
					}
				}
				else {
					undef $f;
				}
				next;
			}
			elsif( $ftype eq 'CODE') {

				if( exists $done{$f} ) {
					undef $f;
				}
				else {
					$done{$f} = undef;
					$f = {
						_code_ => $f,
					};
				}
				next;
			}
			elsif( $ftype eq 'HASH' and ref $f->{_code_} eq 'CODE') {

				if( exists $done{ $f->{_code_} } ) {
					undef $f;
				}
				else {
					$done{ $f->{_code_} } = undef;
				}
			}
			else {
				undef $f;
			}

		}

		if( $op{esc} ) {
			unless( exists $done{tex_escape} ) {
				my $f = 'tex_escape';
				unshift @{ $op{_ACTIONS_} }, { # must be 1st if not specified
						_name_ => $f,
						_code_ => $actions{$f},
					};

				$done{$f} = undef;
			}

			my $f = 'REase';
			if( $op{esc} =~/(?:$qs)$f(?:$qe)/ and ! exists $done{$f} ) {
				push @{ $op{_ACTIONS_} }, { # must be last if not specified
						_name_ => $f,
						_code_ => $actions{$f},
					};

				$done{$f} = undef;
				$op{esc} =~s/$f//g;
			}
		}

		@{ $op{_ACTIONS_} } = grep{ defined } @{ $op{_ACTIONS_} }; # getting rid of uncertainties

	}
	elsif( $op{esc} ) {
		my $f = 'tex_escape';
		$op{_ACTIONS_} = [
			{ # must be 1st
				_name_ => $f,
				_code_ => $actions{$f},
			}
		];

		$f = 'REase';
		if( $op{esc} =~/(?:$qs)$f(?:$qe)/) {
			push @{ $op{_ACTIONS_} }, { # must be last
					_name_ => $f,
					_code_ => $actions{$f},
				};

			$op{esc} =~s/$f//g;
		}

	}
	else {
		$op{_ACTIONS_} = [];
	}

	$op{fh} = $fh;
	$op{logs} = \@logs;
	$op{nlo} = 1; # Number Line Output, start of 1

	my $chkVAR = 0; # check %%%VAR for ARRAY|HASH|SCALAR|REF->SCALAR type
	my $key;
	my $tdz; # flag of The Dead Zone
	my @columns;
	my $end = 0;

=for comment
=begin comment
@columns:
	[...]: -- table columns
	[...]{...} -- descriptions (properties) of table columns:
			{ki} -- name (key || index ) of a variable from $data->{ $key }
			{%} -- NO \par
			{v} -- to paste by default text (located in template) if variable =~/^\x{001}$/
			{p} -- to paste text on right
			{head}[...] -- TeX strings before %%%V:
			{tail}[...] -- TeX strings after %%%V:
			{eX}[...] -- indices of {head} that eXcept for the first and last elements and rows of %%%VAR:
=end comment
=cut

	if( $TEMPLATE )  {
		while( my $z = <$TEMPLATE> ) {

			$end = &_replisome( $info, \$z, \$data, \$vardata, \$chkVAR, \$key, \$tdz, \@columns, \%op );

			if( $end ) {
				print { $fh } <$TEMPLATE> if $end != 3; # NOT ( \endinput AND \end{document} )

				last; #--> Exit template
			}
			undef $z;

		}
		close $TEMPLATE;
	}
	else {
		for my $z ( @$source ) {

			if( $end ) {
				print { $fh } $z;
			}
			else {
				$end = &_replisome( $info, \$z, \$data, \$vardata, \$chkVAR, \$key, \$tdz, \@columns, \%op );

				last if $end == 3; # \endinput OR \end{document}
			}
		}
	}

	if( ! $end and defined( $key ) ) {
		&_var_output( $key, $vardata, \@columns, \%op );

		$_ = "~~> l.EOF. WARNING#1: Missing '%%%ENDx' tag for '$key'";
		$op{silent} or carp $_;
		push @logs, $_;
	}

	$ofile =~/::STDOUT$/ or close $fh;

	return @logs ? \@logs : undef;
}

#---------------------
# Internal functions

sub _replisome {
	my( $info, $z, $data, $vardata, $chkVAR, $key, $tdz, $columns, $op ) = @_;

	if( defined $$key ) { # We are in VAR-structure

		return 0 unless $$z =~/%%%[AETV]\S*:/; # Nope control tags --> drop TeX line

		my $vtype = ref $$vardata;

		if( $$z =~/%%%(?:END(?<t>[TZ]?)|TDZ|VAR):/) {
			my $t = $+{t};

			my $end = &_var_output( $$key, $$vardata, $columns, $op );

			# Clear the VAR-structure for the next external VARiable
			$$chkVAR = 0;
			undef $$key;
			@$columns = ();

			return $end if $end;

			return 1 if $t && $t eq 'T'; # END of Template area --> output everything to the end of template without substitution

			undef $$tdz if $t && $t eq 'Z';

			return 0 if $$z =~/%%%ENDZ?:/; # end of %%%VAR: tag

			if( $$z =~/%%%+TDZ:/) { # The Dead Zone
				$$tdz = 1;
				return 0;
			}

		}
		elsif( ( $vtype eq 'HASH' and (
					   ref( $$vardata->{ $$key } ) =~/^(?:HASH|ARRAY|SCALAR)$/ # REF->SCALAR
					or ref \$$vardata->{ $$key } eq 'SCALAR'
				)
			)
			or ( $vtype eq 'ARRAY' and (
					   ref( $$vardata->[ $$key ] ) =~/^(?:HASH|ARRAY|SCALAR)$/ # REF->SCALAR
					or ref \$$vardata->[ $$key ] eq 'SCALAR'
				)
			)
		) {
			my $vk = $vtype eq 'HASH' ? $$vardata->{ $$key } : $$vardata->[ $$key ];
			my $sclr = (ref(\$vk) eq 'SCALAR' or ref($vk) eq 'SCALAR');

			# Index of column in target table
			my $j = ( @$columns && exists( $columns->[-1]{ki} ) ) ?
						@$columns :
						($#$columns // 0);
			$j = 0 if $j < 0 or $sclr;

			if( ! $sclr and $$z =~/^(.*?)\s?%%%+V:\s*([^\s:%#]+)(%?)\s?(.*)/) {
				# the non-SCALAR V-variable is nested in a VAR-structure
				my $dV = $1; # Value, by default
				my $ki = $2; # name (key or index) of V-variable
				my $Np = $3; # NO \par
				my $paste = $4; # on right

				if( $$chkVAR == 0b0001
					or $$chkVAR == 0b0100
					or $$chkVAR == 0b01000
				) { # V-variable is in {HASH|ARRAY}.ARRAY or SCALAR or REF->SCALAR in regular ARRAY of VAR-structure

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
push @{$op->{logs}}, "~~> l.$. WARNING#8: ARRAY index is not numeric in %%%V:". $ki if $op->{debug} or ! $op->{ignore};
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
				elsif( ref $vk eq 'HASH'
						and exists( $vk->{$ki} )
						and ( ref \$vk->{$ki} eq 'SCALAR'
							or ref $vk->{$ki} eq 'SCALAR'
							or ( $ki eq '@'
								and ref $vk->{$ki} eq 'ARRAY'
							)
						)
				) {
					$columns->[$j]{ki} = $ki; # save variable key in j-th element
				}

				&_set_column( $dV, $Np, $paste, $columns->[$j] ) if exists $columns->[$j]{ki};
			}
			elsif( $$z =~/(?<s>.+?)\s?%%%+ADD(?<t>[AEX]?):(?<p>%?)/
				or $$z =~/^\s*%%%+ADD(?<t>[AEX]?):(?<p>%?)\s?(?<s>.*?)[\r\n]*$/
			) {
				my $s = $+{s};

				if( $+{p} ) {
					length($s) or return 0;
				}
				else {
					$s .= "\n";
				}

				if( $+{t} eq 'A') { # %%%ADDA:
					push @{ $columns->[$j]{head} }, $s;
					$columns->[$j]{ki} = '%%%ADDA'; # phantom
					$columns->[$j]{'%'} = 1;
				}
				elsif( $+{t} eq 'E') { # %%%ADDE:
					if( @$columns && ( $sclr or (exists( $columns->[-1]{ki} ) && ! $columns->[$j]) ) ) {
						push @{ $columns->[-1]{tail} }, $s;
					}
					else {
						push @{ $columns->[$j]{head} }, $s;
					}
				}
				else { # %%%ADD[X]:
					push @{ $columns->[$j]{head} }, $s;
					$columns->[$j]{eX}{ $#{ $columns->[$j]{head} } } = undef if ! $sclr and $+{t} eq 'X'; # $$chkVAR && ...  %%%ADDX:
				}
			}

			return 0;
		}
		else {
			return 0;
		}

	}
	elsif( $$z =~/%%%+END(?<t>[TZ]?):/) { # end of template area

		# Clear the VAR-structure for the next external variable
		$$chkVAR = 0;
		undef $$key;
		@$columns = ();

		return 1 if $+{t} eq 'T'; # END of Template area --> output everything to the end of template without substitution

		undef $$tdz if $+{t} eq 'Z'; # End of TDZ
		return 0;
	}

	$$tdz = 1 if $$z =~s/^\s*%%%+TDZ:\s?[\r\n]*//; # The Dead Zone

	if( $$tdz ) { # The Dead Zone is ON
		if( length $$z ) {# Output TeX
			print { $op->{fh} } $$z;
			++$op->{nlo};
		}
		return 0;
	}

	if( $$z =~/(.*?)\s?%%%+VAR:\s*([^\s:%#]+)(%?)\s?(.*)/) {
		my $before = $1;
		my $k = $2; # name (key)
		my $Np = $3; # NO \par
		my $paste = $4; # on right text for SCALAR only

		# root or global structure (environment)
		my $vd = ( $k =~s/^\/+//) ? $info : $$data;

		my $xk; # for unknown/undefined sub-key

		# Search nested sub-keys
		for my $sk ( split '/', $k ) {
			$$vardata = $vd;
			length( $sk ) or next;

			my $vtype = ref $vd;

			if( $sk =~/^\d+$/ and $vtype eq 'ARRAY' and defined( $vd->[$sk] )) {
				last if &_data_redef( $sk, $vd->[$sk], \$k, \$vd, \$xk );
			}
			elsif( $vtype eq 'HASH' and exists( $vd->{$sk} )) {
				last if &_data_redef( $sk, $vd->{$sk}, \$k, \$vd, \$xk );
			}
			else {
				$xk = $sk;
				last;
			}
		}

		# Clear the VAR-structure for a new variable
		$$chkVAR = 0;
		undef $$key;
		@$columns = ();

		if( $xk ) {
push @{$op->{logs}}, "~~> l.$. WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key '$xk' in %%%VAR:". $k if $op->{debug} or ! $op->{ignore};

			$$vardata = $$data;
			print { $op->{fh} } $$z;
			++$op->{nlo};
			return 0;
		}

		# key or sub-...sub-key is found
push @{$op->{logs}}, "--> l.$. Found %%%VAR:". $k if $op->{debug};

		my $vk = ref $$vardata eq 'HASH' ? $$vardata->{$k} : $$vardata->[$k];

push @{$op->{logs}}, "~~> l.$. NOT defined key in %%%VAR:". $k if ! defined($vk) && $op->{debug};

		return 0 if &_chk_var( $k, $vk, $Np, \$paste, \$before, $chkVAR, $columns, $z, $op );

# push @{$op->{logs}}, "--> l.$. Remember key = '$k' (chkVAR=$$chkVAR), type: ".ref($vk) if $op->{debug}; ###AG

		$$key = $k; # save key name
		return 0;

	}
	elsif( $$z =~/%%%V:\s*=(def|esc|ignore|silent|debug)=\s*([\d~%]*)/) { # setting up facultative options
		my $k = $1;
		my $x = $2 || 0;
		my $i = ( $op->{$k} && $op->{$k} =~/\d\d?/ ) ? $& : 0;

		$op->{$k} = $x if $i < 2;
		return 0;
	}
	elsif( $$z =~/^(?<v>.*?)\s?%%%+V:\s*(?<k>[^\s:%#]+)(?<p>%?)\s?(?<s>.*)/) {
		my $k = $+{k};

		my %el;
		&_set_column( $+{v}, $+{p}, $+{s}, \%el );

		my $inidata = $$data; # save initial environment

		if( $k =~s/^\/+//) {
			$$data = $info; # reset to root environment

			length($k) or return 0;
		}

		# Search nested sub-keys
		my $x = 0; # for unknown sub-key
		for my $sk ( split '/', $k ) {
			length( $sk ) or next;

			my $dtype = ref $$data;

			my $d;
			if( $sk =~/^\-*(\d+)$/
				 and $dtype eq 'ARRAY'
				 and ( $1 < @{$$data} or ( $sk+0 < 0 and $1 == @{$$data} ))
			) {
				$d = $$data->[$sk];
			}
			elsif( $dtype eq 'HASH' && exists( $$data->{$sk} )) {
				$d = $$data->{$sk};
			}
			else {
push @{$op->{logs}}, "~~> l.$. WARNING#3: unknown sub-key '$sk' in %%%V:". $k if $op->{debug} or ! $op->{ignore};

				print { $op->{fh} } $$z;
				++$op->{nlo};

				$x = 1;
				last;
			}

			my $dtp = ref $d;

			# Check type
			if( $dtp =~/^(?:ARRAY|HASH)$/ ) {
				$$data = $d; #  sub-key (path) found: redefined
				next;
			}

			my $v;
			if( ref \$d eq 'SCALAR') {
				$v = $d;
			}
			elsif( $dtp eq 'SCALAR') { # REF->SCALAR
				$v = $$d;
			}
			else {
push @{$op->{logs}}, "~~> l.$. WARNING#4: wrong type (not SCALAR|ARRAY|HASH) of '$sk' in %%%V:". $k if $op->{debug} or ! $op->{ignore};

				print { $op->{fh} } $$z;
				++$op->{nlo};

				$x = 1;
				last;
			}

			$_ = &_v_print( $k, $v, \%el, $op ) and return $_;

			$x = 1;
			last;
		}

		$$data = $inidata if $x; # value found or unknown sub-key: reset to initial environment

		return 0;
	}

	print { $op->{fh} } $$z;
	++$op->{nlo};

	return 0;
}


sub _set_column {
	my( $dV, $Np, $paste, $column ) = @_;

	$column->{v} = $dV if length $dV;
	$column->{'%'} = 1 if $Np;
	$column->{p} = $paste if length $paste;
}


sub _data_redef {
	my( $sk, $d, $k, $data, $xk ) = @_;

	if( ref $d eq 'ARRAY' or ref $d eq 'HASH') {
		$$data = $d; # redefined for %%%VAR:
		return 0;
	}

	if( ref \$d eq 'SCALAR' or ref $d eq 'SCALAR') {
		$$k = $sk;
	}
	else {
		$$xk = $sk;
	}
	return 1;
}

sub _chk_var {
	my( $k, $vk, $Np, $paste, $before, $chkVAR, $columns, $z, $op ) = @_;

	if( ref $vk eq 'ARRAY') {

		if( @{ $vk } ) {
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
				elsif(ref $d eq 'SCALAR') { # REF->SCALAR
					$$chkVAR |= 0b01000;
				}
				else {
					$$chkVAR |= 0b10000;
				}
			}
		}
		else {
			$$chkVAR |= 0b00100; # by default, SCALAR
		}

		if( ! $$chkVAR or $$chkVAR > 0b01000 or ($$chkVAR & ($$chkVAR - 1)) ) {
push @{$op->{logs}}, "~~> l.$. WARNING#6: mixed types (ARRAY with HASH with SCALAR or other) of %%%VAR:". $k if $op->{debug} or ! $op->{ignore};

			print { $op->{fh} } $$z;
			++$op->{nlo};
			return 1;
		}
	}
	elsif( ref \$vk eq 'SCALAR' or ref $vk eq 'SCALAR') {
		$columns->[0]{ki} = $k;
		&_set_column('', $Np, $$paste, $columns->[0] );
	}

	if( $$before ) {# Output prefix TeX
		print { $op->{fh} } $$before;
#		++$op->{nlo};
	}

	return 0;
}

# VALUE output
sub _v_print {
	my( $k, $v, $el, $op ) = @_;
	$v = $$v if ref $v eq 'SCALAR';

	unless( defined $v ) {
		if( $op->{def} ) {
push @{$op->{logs}}, "~~> l.$.".' NOT defined %%%V[AR]:'. $k if $op->{debug};

			return 0;
		}
		$v = '';
	}

	if( $v =~s/^\x{01}//) { # by default text from template
		if( exists $el->{v} ) {
			print { $op->{fh} } $el->{v};

push @{$op->{logs}}, "--> l.$.>". $op->{nlo} .' Insert text by default %%%V[AR]:'. $k .'= '. $el->{v} if $op->{debug};
		}
	}

	if( $v =~/^\x{03}(\x{03}?)/) { # END of INPUT template
		say { $op->{fh} } $1 ? '\bye' : '\endinput';
		++$op->{nlo};

		return 3;
	}
	elsif( $v =~/^\x{04}/) { # END of INPUT template, similar to \bye
		say { $op->{fh} } '\end{document}';
		++$op->{nlo};

		return 3;
	}
	elsif( length $v ) {
		$op->{_MFLAGS_} = 0; # value modification (change) flag: 0 is 'NO', 1 -- 'YES' for ordinary text, 2 -- 'YES' for TeX-commands
		for my $f ( @{ $op->{_ACTIONS_} } ) {
			$f or next;

			$_ = int( $f->{_code_}->( $v, $op ) // 0 );
			$op->{_MFLAGS_} += 0;
			$op->{_MFLAGS_} |= $_;
		}


push @{$op->{logs}}, "--> l.$.>". $op->{nlo} .' Insert %%%V[AR]:'. $k .'= '. $v if $op->{debug};

		print { $op->{fh} } $v;
		++$op->{nlo} while $v =~/\n/g;

		print { $op->{fh} } $el->{p} if exists $el->{p};
	}

	unless( $el->{'%'} ) {
		print { $op->{fh} } "\n"; # NO:YES \par
		++$op->{nlo};
	}

	return 0;
}

# HEAD-TAIL output
sub _ht_print {
	my( $el, $ht, $op, $border ) = @_;

	$el->{$ht} or return;

	my $i = 0;
	foreach( @{ $el->{$ht} } ) {
		next if $ht eq 'head' and $border && exists( $el->{eX} ) && exists( $el->{eX}{$i} );

push @{$op->{logs}}, "-->\tl.$.>". $op->{nlo} ." Insert $ht: ". $_ if $op->{debug};

		print { $op->{fh} } $_;
		++$op->{nlo};
	}
	continue {
		++$i;
	}

}

# HEAD-VALUE-TAIL output
sub _hvt_print {
	my( $ki, $val, $el, $op, $border ) = @_;

	if( length($ki) and ! defined $val ) {
		if( $op->{def} ) {
			push @{$op->{logs}}, "~~> l.$.".' NOT defined %%%V:'. $ki if $op->{debug};
			return 0;
		}

		$val = '';
	}

	# output head of variable
	&_ht_print( $el, 'head', $op, $border );

	# output value of variable ( $ki, $val, $el, $op )
	$_ = &_v_print and return $_;

	# output tail of variable
	&_ht_print( $el, 'tail', $op, 0);

	return 0;
}


sub _s_a_prn {
	my( $i, $values, $el, $op, $border, $col ) = @_;

	my $val = $values->[$i];
	$val = $$val if ref $val eq 'SCALAR';

	my $end = 0;

	if( ref \$val eq 'SCALAR') {
		$end = &_hvt_print( $i, $val, $el, $op, $$border );

		++$$col;
		$$border = 0;
	}
	elsif( ref $val eq 'ARRAY') { # [...].ARRAY.ARRAY

		for( @$val ) {
			next if ref \$_ ne 'SCALAR';

			$end = &_hvt_print( $i, $_, $el, $op, $$border );

			++$$col;
			$$border = 0;

			last if $end;
		}

	}

	return $end;
}


sub _mixed_indices {
	my( $ki, $values, $el, $op, $border ) = @_;

	my $nd = @$values;
	my $col = my $end = 0;

	for my $ii ( split ',', $ki ) { # e.g. -1-,1-3,6-7-9,-,4,-5,0,7-
		next if $ii eq '-';

		if( $ii =~/^(\-[1-9]\d*)\-(\d*)$/) { # -1- i.e. reverse: -1,-2,..-@arr (i.e. arr_start)
			my $s = $1;
			my $e = -1*($2 || $nd);
			$s = -1*$nd if abs($s) > $nd;
			$e = -1*$nd if abs($e) > $nd;
			($s, $e) = ($e, $s) if $e > $s;

			for( my $i = $s; $i >= $e; --$i ) {
				$end = &_s_a_prn( $i, $values, $el, $op, \$border, \$col ) and last;
			}

			$end ? last : next;
		}

		if( $ii =~/^\-[0-9]+$/ ) { # -5
			my $i = $ii+0;

			if( abs($i) <= $nd ) {
				$end = &_s_a_prn( $i, $values, $el, $op, \$border, \$col ) and last;
			}

			next;
		}

		my @n = grep{length} sort{$a <=> $b} split '-', $ii;

		if( @n < 2 and $n[0] < $nd ) { # e.g. 4 || 0 || 7(-)
			if( $ii =~/\-$/) { # 7(-)

				for( my $i = $n[0]; $i < $nd; ++$i ) {
					$end = &_s_a_prn( $i, $values, $el, $op, \$border, \$col ) and last;
				}

			}
			else { # 4 || 0
				$end = &_s_a_prn( $n[0], $values, $el, $op, \$border, \$col ) and last;
			}

		}
		else { # 1-3 ->(1..3) || 6-7-9 ->(6..9)
			for( my $i = $n[0]; $i <= $n[-1]; ++$i ) {
				$end = &_s_a_prn( $i, $values, $el, $op, \$border, \$col ) and last;
			}
		}

		last if $end;
	}

	return( $col, $end );
}


sub _var_output {
	my( $key, $vardata, $columns, $op ) = @_;
	my $values =  (ref $vardata eq 'HASH') ? $vardata->{ $key } : $vardata->[ $key ];

	@$columns or return;

	my $end = 0;

	if( ref \$values eq 'SCALAR' or ref $values eq 'SCALAR') { # key => SCALAR
		return &_hvt_print( $key, $values, $columns->[0], $op );
	}

	if( ref $values eq 'ARRAY') { # key => ARRAY

		unless( @$values ) {
push @{$op->{logs}}, "~~> l.$. WARNING#7: empty ARRAY of %%%VAR:". $key if $op->{debug} or ! $op->{ignore};
			return 0;
		}

		# Forming a table
		my $row = 0;
		my $nd = @$values;

_var_output_M0:
		foreach my $d ( @$values ) { # loop through table rows

push @{$op->{logs}}, '--> Table row = '. $row if $op->{debug};

			my $col = 0;
			foreach my $el ( @$columns ) { # loop through table columns (for ARRAY.HASH) or rows (for ARRAY.SCALAR)

				my $ki = $el->{ki};
				my $border = ((! $row and ! $col) or ($row >= $#{ $values } and (!defined( $ki ) or !length( $ki )) ) ) ? 1 : 0;

				my $val;
				if( defined $ki ) {
					if( $ki eq '%%%ADDA') {
						$val = '';
					}
					elsif( ref \$d eq 'SCALAR' or ref $d eq 'SCALAR') { # (ARRAY.SCALAR or ARRAY.REF->SCALAR) in regular vector

						if( $ki =~/^[\d,\-]+$/) {
						# mixed indices, e.g.: 1-3,6-7-9,-,4,-5,0,7- or 3- (i.e. 3..arr_end) or 0-5 (0..5) or -1- (-1,-2,..arr_start)
							last _var_output_M0 if $row;

							($_, $end) = &_mixed_indices( $ki, $values, $el, $op, $border );
							$col += $_ - 1 if $_;
						}

						$end ? last _var_output_M0 : next;
					}
					elsif( ref $d eq 'HASH') { # ARRAY.HASH
						$val = $d->{$ki};

						if( defined( $val ) && ref $val eq 'ARRAY') { # ARRAY.HASH.ARRAY
							for my $vv ( @$val ) {
								next unless ref \$vv eq 'SCALAR';

								$end = &_hvt_print( $ki, $vv, $el, $op, $border ) and last _var_output_M0;
								++$col;
							}

							$end ? last _var_output_M0 : next;
						}
						elsif( ref \$val ne 'SCALAR' and ref $val ne 'SCALAR') {
							next;
						}
					}
					elsif( ref $d eq 'ARRAY') { # ARRAY.ARRAY

						if( $ki =~/^[\d,\-]+$/) {
						# mixed indices, e.g.: 1-3,6-7-9,-,4,-5,0,7- or 3- (i.e. 3..arr_end) or 0-5 (0..5) or -1- (-1,-2,..arr_start)
							($_, $end) = &_mixed_indices( $ki, $d, $el, $op, $border );
							$col += $_ - 1 if $_;
						}

						$end ? last _var_output_M0 : next;
					}
					elsif( $op->{def} ) {

push @{$op->{logs}}, "~~> l.$. NOT defined %%%V:". $ki if $op->{debug};

						next;
					}
				}
				else {
				# empty parameter -- at the very end of the columns (parameters)
					$ki = '';
				}

				$end = &_hvt_print( $ki, $val, $el, $op, $border ) and last _var_output_M0;
			}
			continue {
				++$col;
			}

			last if $end;
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
				if( $ki eq '%%%ADDA') {
					$val = '';
				}
				elsif( ref \$values->{$ki} eq 'SCALAR' and ( !$op->{def} or defined( $values->{$ki} ) ) ) { # HASH.SCALAR
					$val = $values->{$ki};
				}
				elsif( ref $values->{$ki} eq 'SCALAR' and ( !$op->{def} or defined( ${ $values->{$ki} } ) ) ) { # HASH.REF->SCALAR
					$val = ${ $values->{$ki} };
				}
				elsif( $ki eq '@' and ref $values->{'@'} eq 'ARRAY') {
					for my $k ( @{ $values->{'@'} } ) {
						next unless defined($k) && exists( $values->{$k} );

						my $v;
						if( ref \$values->{$k} eq 'SCALAR') {
							$v = $values->{$k};
						}
						elsif( ref $values->{$k} eq 'SCALAR') {
							$v = ${ $values->{$k} };
						}
						elsif( $op->{def} ) {
push @{$op->{logs}}, "-->\tl.$. ". 'NOT HASH.ARRAY.SCALAR %%%V:@->{'.$k.'} in %%%VAR:'. $key if $op->{debug};

							next;
						}

						$end = &_hvt_print( $k, $v, $el, $op, $border ) and last _var_output_M0;
						$border = 0;
					}

					$end ? last : next;
				}
				elsif( $op->{def} ) {
push @{$op->{logs}}, "~~> l.$. NOT HASH.SCALAR or NOT defined %%%V:". $ki if $op->{debug};

					next;
				}
			}
			else {
			# empty parameter -- at the very end of the columns (parameters)
				$ki = '';
			}

			$end = &_hvt_print( $ki, $val, $el, $op, $border ) and last;
		}
		continue {
			++$col;
		}
	}

	return $end;
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

  SPECIFY VALUE of myParam! %%%V: myParam  %-- substitutes SCALAR var

  etc...

  \begin{tcolorbox}
  \rule{0mm}{4.5em}%%%VAR: myParam -- substitutes SCALAR var as well
  ...
  ... SPECIFY VALUE of myParam!
  ...
  %%%END:
  \end{tcolorbox}

  %%%VAR: myParam %-- SCALAR substitution with support for internal ADD[E] tags
  \mbox{ %%%ADD:%
  \rule{0mm}{4.5em} %%%ADD:
  head \ldots %%%ADD:
  ... SPECIFY VALUE of myParam!
  tail \ldots %%%ADDE:%
  } %%%ADDE:
  %%%END:

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

  \mbox{\rule{0mm}{4.5em}
  head \ldots
  Blah-blah blah-blah blah-blah%-- SCALAR substitution with support for internal ADD[E] tags
  tail \ldots}

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
then C<ready.tex> file will be created in a B<random subdirectory> 
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

Currently, symbols: C<< % >>, C<< @ >>, C<< : >>, C<< = >>, and C<< / >> have a special purpose.


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
(they are B<hidden in the properties> of the variable designated I<key> or I<index> for C<%%%V:> and C<%%%VAR:> tags)
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
However, if there is text after this variable
(separated by at least one space character, which is "eaten" and will not be in the output stream),
it will be added to the right of its value:

  Before blah, blah, \ldots blah. %%%V: myParam   After blah, \ldots blah.

here 'C<  After blah, \ldots blah.>' will remain to the right of C<myParam> value in the line.

This construct can be used as an ON or OFF switch, for example by setting C<myParam>
to C<"~"> (i.e. C<" ">) or C<"%"> the text 'C<  After blah, \ldots blah.>' will be present or absent 
in the finished (e.g. compiled by C<pdflatex>, C<latex> or C<tex>) PDF or DVI document.

Another trick is to use the magic value C<"\x{001}"> (or C<chr(0x01)>) at the beginning of a variable that acts as a trigger,
i.e., output the value to the left of C<%%%V:> in the template to the finished document.
Such a trigger can work like this:

  Default value %%%V: myParam

If C<< myParam => "some text" >> then this template (pattern) will produce a TeX snippet like this:

  some text

If C<< myParam => "\x{001}" >> (or C<< "\x{001}some text" >>), the result will be as folllow:

  Default value

This trick can also be performed in a more complex way - without using a magic C<"\x{001}">, 
but using the C<%%%ADD:> tag and an additional variable C<phantom>,
the value of which should be adjusted to the value of C<myParam> inside C<area>:

  %%%VAR: area
  ...
  Default value %%%ADD:%
  %%%V: phantom%
  %%%V: myParam
  ...
  %%%END:

which, you must admit, is extremely inconvenient :(

It is very important to understand that there are four (4) states for C<%%%V: variable> (or C<%%%VAR>)
when the C<def> option is B<enabled>:

=over 6

=item 1.

complete absence, i.e. C<variable> B<does not exist>;

=item 2.

presence (B<exists>) with an B<undefined> value;

=item 3.

B<exists> and B<defined> value and B<empty> (i.e. C<value = ''>, C<length of value == 0>);

=item 4.

B<defined> value and B<not empty>.

=back

BTW: if C<def> option is B<disabled>, then state (2) is identical to state (3).

These states influence the final  outcome.
The following example demonstrate this.

  YES %%%V: param  NO

(1) C<unless exists param>, then output as is C<'YES %%%V: param  NO'>, i.e. C<YES>.

(2) C<if param == undef>, then output C<''>, i.e. empty (and text is NOT saved in C<%%%ADD[E]:> tags, if specified).

(3) C<if param eq ''>, then output C<''>, i.e. empty also (but text is saved in C<%%%ADD[E]:> tags, if specified).

(4) C<if param eq ' '> then, output C<' NO'>, i.e. it is actually C<'NO'> (with text is saved in C<%%%ADD[E]:> tags, if specified).

(4) C<if param eq 'there will be '> then, output C<'there will be NO'> (with text is saved in C<%%%ADD[E]:> tags, if specified).

(4) C<if param eq '%'>, then output C<'% NO'>, i.e. commented out 'NO' and it is actually empty (with text is saved in C<%%%ADD[E]:> tags, if specified).

(4) C<if param eq "\x{001}">, then output C<YES> (with text is saved in C<%%%ADD[E]:> tags, if specified).


There are two more magic values of C<%%%V:> (or C<%%%VAR:>) tag
for forced completion (ending) of a finished TeX document:

=over 6

=item 1.

starting C<"\x{003}"> (or C<chr(0x03)>) - inserts C<\endinput> command into TeX document and cuts off the rest of the template.
Starting C<"\x{003}\x{003}"> (or C<chr(0x03)chr(0x03)>) - inserts C<\bye> command into TeX document and cuts off the rest of the template.

=item 2.

starting C<"\x{004}"> (or C<chr(0x04)>) - inserts C<\end{document}> command into TeX document and cuts off the rest of the template.

=back

Let me repeat:
the B<difference> between C<"\x{003}"> (C<"\x{004}">) and directly inserting 
C<\endinput> (C<\end{document}> ) command is that B<remaining part of the template is cut off>.

These magical values can be set separately (singly) or together with the first C<"\x{001}"> such as
C<"\x{001}\x{003}"> and C<"\x{001}\x{004}">.


Besides, if a C<variable_name> ends in C<%> (i.e. C<variable_name%>), a newline is suppressed.
By default, a newline always occurs after value substitution and 'After blah, \ldots blah.' if it exists.

Also in C<variable_name> you can use the special character "C</>", which denotes the "path" 
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

B<CONCLUSION>: standalone C<%%%V:> tag (outside C<%%%VAR:> scope) can be used to set the B<global variable lookup environment>.

C<%%%V:> can be nested in an ARRAY or HASH C<%%%VAR:> tag,
but in SCALAR (or REF.SCALAR) C<%%%VAR:> it will not work and will be discarded.

There's a special C<variable_name> = C<@>, which means to "B<use all elements of an ARRAY>".
Therefore, this only makes sense for ARRAY variables or HASH that have C<@> key (see example above).

Using C<@> for HASH variables is also acceptable.
In this case, it is assumed that a key with this name exists in the hash, 
which stores a list (vector) of the keys of this hash in the order 
they are inserted into TeX template.


=item *
B< C<%%%VAR: variable_name> > is start of full form of regular (SCALAR, REF.SCALAR) or complex (HASH, ARRAY) C<variable_name>,
preserving preceding TeX up to C<%%%VAR:> but completely replacing everything up to first C<%%%END:> 
(C<%%%ENDT:>, C<%%%ENDZ:>, or a new C<%%%VAR:>, or C<%%%TDZ:>) tag inclusive.

  External Blah, blah, \ldots blah:  %%%VAR: myParam
  Internal Blah, blah, \ldots
  \ldots
  Internal Blah, \ldots %%%END:

or a template like this with additional internal C<%%%ADD:> and C<%%%ADDE:> tags:

  %%%VAR: myParam
  \mbox{ %%%ADD:%
  \rule{0mm}{4.5em} %%%ADD:
  head \ldots %%%ADD:
  ... SPECIFY VALUE of myParam!
  tail \ldots %%%ADDE:%
  } %%%ADDE:
  %%%END:

If C<myParam = 1234567890> (it's SCALAR), then that template will lead to the creation of such a TeX fragment:

  External Blah, blah, \ldots blah: 1234567890

or respectively:

  \mbox{\rule{0mm}{4.5em}
  head \ldots
  1234567890
  tail \ldots}

BTW: if C<myParam = undef> (i.e. B<undefined>) and facultative option (see below) C<def> is set (e.g. 1),
then these fragments B<will be missing> from the finished TeX.

Usually HASH and ARRAY I<variable_name> are used in the template to create (fill) tables.

C<%%%VAR:> tag is similar to C<%%%V:> tag, where the variable name can be used to specify its search 
"path" using a special symbol, "C</>". However, this "path" does not affect the I<global environment>.
It only sets the I<local environment> within the scope of C<%%%VAR:> tag.

Nested C<%%%VAR:> tags will not work and are treated as C<%%%END:> tags,
i.e. tags for early termination of the scope.

It is very important to understand that there are four (4) states for C<%%%VAR: variable> (or C<%%%V>)
when the C<def> option is B<enabled>:

=over 6

=item 1.

complete absence, i.e. C<variable> B<does not exist>;

=item 2.

presence (B<exists>) with an B<undefined> value;

=item 3.

B<exists> and B<defined> value and B<empty> (i.e. C<value = ''>, C<length of value == 0>);

=item 4.

B<defined> value and B<not empty>.

=back

BTW: If C<def> option is B<disabled>, then state (2) is identical to state (3).

These states influence the final  outcome (see above for C<%%%V:> tag).


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

The following tags can be located within the block limited by ARRAY and HASH of C<%%%VAR:> and
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
By default, a newline always occurs after value substitution and additional text to the right of C<%%%V:> if it exists.

=item *
There are four (4) options for B< C<%%%ADDx> > tags:

=over 6

=item 1.
B< C<%%%ADD:> > adds text B<before> variable specified in C<%%%V:> tag.

The added text is taken from the beginning of the line to the beginning of C<%%%ADD:>
(i.e. text located on the left), e.g.

  Head blah, blah, \ldots blah. %%%ADD: Tail blah, blah, \ldots

this text will be added: C<< 'Head blah, blah, \ldots blah.' >>

Or, if C<%%%ADD:> is located at the very beginning of line, then after it to the end of line
(i.e. text located on the right), e.g.

  %%%ADD: Tail blah, blah, \ldots

this text will be added: C<< 'Tail blah, blah, \ldots' >>.

If the following C<%%%V:> tag is not present, then the text is output B<at the end of all> C<keys> or C<indexes> (columns)
each table (filled area) row.

C<%%%ADD:> can also be used for SCALAR and REF.SCALAR variable,
but without C<%%%V:> tag because it is redundant and not supported:

  %%%VAR: myParam
  \mbox{ %%%ADD:%
  \rule{0mm}{4.5em} %%%ADD:
  head \ldots %%%ADD:
  ... SPECIFY VALUE of myParam!
  tail \ldots %%%ADDE:%
  } %%%ADDE:
  %%%END:

If C<myParam = 1234567890> (it's SCALAR), then that template will lead to the creation of such a TeX fragment:

  \mbox{\rule{0mm}{4.5em}
  head \ldots
  1234567890
  tail \ldots}

i.e. the SCALAR value will be located after C<%%%ADD:> tags and before C<%%%ADDE:> tags,
in other words, between them, if they exist.

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
B< C<%%%ADDE:> > is similar to C<%%%ADD:>.

Means B<Ending> C<%%%ADD>, but it differs in that text is added B<after> variable specified in C<%%%V:> tag.

This C<%%%ADDE:> tag must follow immediately after C<%%%V:> tag 
(i.e. there should not be C<%%%ADD:> tag before it), otherwise it will also become 
a regular C<%%%ADD:> tag, for example for the next C<%%%V:>.

C<%%%ADDE:> can also be used for SCALAR and REF.SCALAR variable, 
but without C<%%%V:> tag because it is redundant and not supported.
Here you must correctly place C<%%%ADD:> and C<%%%ADDE:> tags yourself:
C<%%%ADD:> denotes what will come before the variable value,
and C<%%%ADDE:> - after it (see above).

=item 3.
B< C<%%%ADDX:> > is similar to C<%%%ADD:>.

For all lines (records) B<eXcept the first column (0) of first record (0)> or B<after the last column of last record>.

=item 4.
B< C<%%%ADDA:> > is similar to C<%%%ADD:>.

Means that C<%%%ADD> is B<Always> present, but it is not linked to any C<%%%V:> in the block of C<%%%VAR:>,
meaning its contents will not depend on the variable's uncertainty of C<%%%V:>,
and its value will be output in any case and in the appropriate order.

  %%%VAR: myHash
  \mbox{ %%%ADDA:%
  \rule{0mm}{4.5em} %%%ADDA:%
  head \ldots %%%ADD:
  ... SPECIFY VALUE of myKey! %%%V: myKey
  tail \ldots %%%ADDE:%
  } %%%ADDA:
  ...
  %%%END:

If C<< myHash = { myKey => undef, ... } >>, then that template will lead to the creation of such a TeX fragment:

  \mbox{\rule{0mm}{4.5em}}


=back


If any C<%%%ADDx:> tag ends in C<%> (e.g. C<%%%ADD:%>, C<%%%ADDA:%>, C<%%%ADDE:%>, or C<%%%ADDX:%> ), a newline is suppressed.
(By default, a newline always occurs after adding text).

=back

Only B<ONE tag> can be located on B<ONE line> of input template.

Tag names must be in C<%%%UPPERCASE:>.

Tags can "absorb" one whitespace character around them (left and/or right), if present.


=head1 SUBROUTINES

LaTeX::Replicase provides these subroutines:

    replication( $source, $info [, %hash_options ] );
    tex_escape( $value [, $options ] );
    REase( $value [, $options ] );


=head2 replication( $source, $info [, %hash_options ] )

Creates a new output file from the specified TeX-document C<$source>, which is a template.
The TeX-template C<$source> can be either a TeX-file or an array reference,
each element of which is a TeX-string (with line break C<\n> if necessary).

File name of C<$source> can be absolute,
i.e. with a full path (include directories and subdirectories).
File and directory names and paths to them must not contain space characters.
It is also recommended to use only ASCII characters in the file name.

The output file name is extracted from C<$source>.
Under no circumstances will C<$source> be overwritten by the new one.

If C<$source> is an array reference and no target file name is specified by C<ofile> option,
then C<ready.tex> file will be created in a B<random subdirectory> 
(its name is stored in C<$$> variable) of current directory.

C<$info> HASH or ARRAY is used to fill template:

  $info = { };
  # or
  $info = [ ];

When C<replication> processes C<$source> it identifies tags and replaces them with the result of whatever 
the tag represents (e.g. variable value for C<%%%V:> or from C<%%%VAR:> to C<%%%END:>). Anything outside the tag(s),
including newline characters, are left intact.

After C<replication> completes, the input C<$info> of remains unchanged,
i.e. all internal modifications do not affect the original values.

The following C<%hash_options> can be used when calling C<replication>:

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

This option forces specifies the template and output files' character encoding as utf8:

  my $msg = replication( $source, $info, utf8 =>1 );

=item C<esc>

This option applies C<tex_escape()> subroutine to all incoming values to mask 9 active TeX characters
C<&> C<%> C<$> C<#> C<_> C<{> C<}> C<^> C<\> (see description of L<tex_escape()|tex_escape( $value [, $options ] )> subroutine below).

For example, the simplest way to use C<esc> is:

  replication( $source, $info, esc =>1 );
  replication( $source, $info, esc =>'~');

BTW:
If a number >1 is specified in this option (e.g. C<< esc => 2 >>),
then it cannot be overridden (replaced) from the template via C<< %%%V:=esc= 0|1|2|~|... >> tag.

In general, the C<esc> option can contain the following keys:

  replication( $source, $info, esc =>'~ hyphen !stag -stag +stag;REase, strong mutual');

i.e. in C<esc> these keys can be separated by spaces, '_', and word boundaries.
For a description of these keys, see the sections on
L<tex_escape()|tex_escape( $value [, $options ] )> and L<REase()|REase( $value [, $options ] )>.

This option can also be changed dynamically in the template itself using global C<< %%%V:=esc= 0|1|~|... >> tag,
but
can be changed only if when calling C<replication()> for C<esc> option the priority is not specified C<< >1 >>,
e.g. C<< esc => 2... >>.


=item C<tail>

This option specifies the size (in characters) of the maximum 
uncut non-alphabetic sections in the range from 1 to C<< tail + 1 >>,
e.g.

  $msg = replication( $source, $info, esc => 'REase', tail => 2 );

By default, C<< tail = 3 >>.
C<tail> option has meaning if C<replication()> is called with C<REase>
in C<esc> or C<< _ACTIONS_ >> option.

For a description of C<tail>, see the section on L<REase()|REase( $value [, $options ] )>.


=item C<< _ACTIONS_ >>

This option is an array of names (scalars), references, and hashes to internal (C<tex_escape>, C<REase>) and
external user-defined subroutines that will be run in the order specified by this array (like a pipeline)
during the actual template filling with the C<%%%V: variable_name> (or C<%%%VAR:>) value from C<$info>.
For example:

  my $actions = [
       \&mySub_1st,
       'tex_escape',
       'REase',
       {
         _name_ => 'mySub_2nd', # optional sub name
         _code_ => sub{
           # $_[0] is $value of variable_name
           # $_[1] is $hash_options of replication(), e.g. $_[1]->{_MFLAGS_}
           #
           # ... we do something with $_[0] ...
           #
           my $mflag = 0b00... ; # set the value modification bit flag (see below)
           return $mflag;
         }
       },
       {
         _code_ => \&mySub_3th,
       },
   ];

  $msg = replication( $source, $info, _ACTIONS_ => $actions );

For example, the following C<replication()> calls will be executed completely equivalently:

  $msg = replication( $source, $info, esc => 'REase');
  $msg = replication( $source, $info, _ACTIONS_ => ['tex_escape', 'REase', ] );
  $msg = replication( $source, $info, esc => 'REase', _ACTIONS_ => ['REase', ]);
  $msg = replication( $source, $info, esc => 'REase', _ACTIONS_ => ['tex_escape', ]);
  $msg = replication( $source, $info, esc => 'REase', _ACTIONS_ => ['tex_escape', 'REase', ]);

but this option will differ from them in the order of calling subroutines:

  $msg = replication( $source, $info, _ACTIONS_ => ['REase', 'tex_escape', ] );

first C<REase()> will be executed, then C<tex_escape()>.

Thus, C<< _ACTIONS_ >> helps to finely control the template filling process.
Duplicate or erroneous subroutines will be discarded.

It's also important to return C<$mflag>, which then goes into the C<< _MFLAGS_ >> option 
and is needed for C<tex_escape()> and C<REase()> if they are called later in the pipeline.
These subroutines will not be executed if C<< _MFLAGS_ & 0b0100 >>.
C<tex_escape()> will also not work if C<< _MFLAGS_ & 0b0110 >>.


=item C<def>

This option specifies B<discarding> (ignoring) C<undefined> values and associated structures (C<%%%ADD...>),
i.e. dictates that only C<defined> values be B<into account>.

  my $msg = replication( $source, $info, def =>1 );

This option is useful, for example, to remove blocks of text and for creating merged cells in tables (using C<\multicolumn> LaTeX-command)
and applies to all incoming data. Also this option can be used as an ON or OFF switch (see above).

If C<def> option is not specified or is 0, then all undefined values are replaced with an empty value, i.e. C<''> (length is 0).

This option can also be changed dynamically in the template itself using global C<%%%V:=def= 0|1 > tag,
but
can be changed only if when calling C<replication()> for C<def> option the priority is not specified C<< >1 >>,
e.g. C<< def => 2 >>.


=item C<ignore>

This option specifies silently ignore undefined B<name|key|index> of C<%%%V:> and C<%%%VAR:> tags:

  my $msg = replication( $source, $info, ignore =>1 );

This option can also be changed dynamically in the template itself using global C<%%%V:=ignore= 0|1 > tag.
but
can be changed only if when calling C<replication()> for C<ignore> option the priority is not specified C<< >1 >>,
e.g. C<< ignore => 2 >>.


=item C<silent>

This option activates silent mode of operation:

  my $msg = replication( $source, $info, silent =>1 );

This option can also be changed dynamically in the template itself using global C<%%%V:=silent= 0|1 > tag.
but
can be changed only if when calling C<replication()> for C<silent> option the priority is not specified C<< >1 >>,
e.g. C<< silent => 2 >>.


=item C<debug>

This option sets local debug mode:

  my $msg = replication( $source, $info, debug =>1 );
  if( ! $msg ) {
    say 'Ok';
  }
  else {
    say for @$msg;
  }

This option can also be changed dynamically in the template itself using global C<%%%V:=debug= 0|1 > tag.
but
can be changed only if when calling C<replication()> for C<debug> option the priority is not specified C<< >1 >>,
e.g. C<< debug => 2 >>.

Another way is to set the C<$DEBUG> package variable to enable debugging messages (global debug mode).

    $LaTeX::Replicase::DEBUG = 1;

=back

C<replication> returns C<undef> or a reference to an error (and/or debug) message(s) array.


=head2 tex_escape( $value [, $options ] );

Masks (or replaces with equivalents) the active 9 TeX characters: C<&> C<%> C<$> C<#> C<_> C<{> C<}> C<^> C<\>
with the corresponding: C<\&> C<\%> C<\$> C<\#> C<\_> C<\{> C<\}> C<\^\/> C<\char92\/> in the input C<$value>:

  tex_escape( $value );

With the facultative (optional) option C<~>, you can additionally replace 
the character C<~> with the corresponding C<\~\/}>, e.g.:

  tex_escape( $value, '~');

C<$options> is optional and can be specified as a SCALAR or a HASH.
For example, C<$options> is a HASH:

  my $mflag = tex_escape( $value, {
                  esc => '~ hyphen; !stag -stag, +stag REase, strong,mutual',
                  tail => 4,
                  _MFLAGS_ => 0b0001,
                }
              );

For example, C<$options> is a SCALAR:

  my $mflag = tex_escape( $value, '~hyphen !stag -stag +stag;REase, strong mutual');

i.e. the SCALAR form of C<$options> allows passing additional options only as C<esc>.
Key separators in C<esc> option can be spaces, '_', and word boundaries.

=over 3

=item %%%:

If the C<$value> starts with the C<%%%:> tag, then this tag is removed
(e.g. C<$value = '%%%:$\frac{12345}{67890}$'> is converted to C<$value = '$\frac{12345}{67890}$'>),
and the value itself is not masked, it is skipped without changes.
By default (without additional C<< -stag >> option), only ONE 1st B<start tag> C<%%%:> is removed.
This means that the following start tags (stag) will remain untouched if they are set.

Three options (C<< !stag >>, C<< -stag >>, and C<< +stag >>) affect the action of the start tag (C<%%%:>):

=over 6

=item !stag

This option means to ignore the start tag and skip it as if it does not exist,
and masking of active symbols.

=item -stag

This option means to remove all start tags,
and masking of active symbols

=item +stag

This option means to keep the 1st start tag.

=item I<undef>

Their (stags) absence means deleting the 1st start tag (C<%%%:>) and exiting C<tex_escape()>
without masking active symbols.

=back

All three options, or just some of them, may be present at the same time, but C<< !stag >> suppresses the others.

By default, if already masked active symbols (C<< \& >> C<< \% >> C<< \$ >> C<< \# >> C<< \_ >>
C<< \{ >> C<< \} >> C<< \^ >> C<< \char92 >>), they are skipped.

Also classic TeX-LaTeX-commands:
C<< \textbackslash >> C<< \relax >> C<< \hskip >>
C<< \<tab> >> C<< \- >> C<< \* >> C<< \/ >> C<< \= >> C<< \. >> C<< \~ >>
C<< \' >> C<< \` >> C<< \" >>
C<< \, >> C<< \; >> C<< \! >> C<< \> >>
are skipped in this case.

This means that when C<< tex_escape() >> re-processes a previously processed C<< $value >>,
no additional escaping of these command symbols will occur. 
However, other TeX objects will be affected, if they exist.

Two additional options -- C<strong> and C<mutual> influence this behavior.

=over 6

=item strong

ignores all previously masked characters listed above,
except for the TeX-LaTeX-commands:
C<< \char92 >>, C<< \textbackslash >>, C<< \relax >>, and C<< \hskip >>.

=item mutual

does not pay attention to the smaller number of characters and TeX-LaTeX-commands:
C<< \& >> C<< \% >> C<< \$ >> C<< \# >> C<< \_ >>
C<< \{ >> C<< \} >> C<< \^ >>
C<< \<tab> >> C<< \- >> C<< \* >> C<< \/ >> C<< \= >> C<< \. >> C<< \~ >>
C<< \' >> C<< \` >> C<< \" >>
C<< \char92 >> C<< \textbackslash >> C<< \relax >> C<< \hskip >>

=back


=item hyphen

This option makes compound words with "active" hyphens, 
i.e. makes a replacement C<< ...abc-def... >> with C<< ...abc"=def... >>.

=item REase

includes an internal call to the C<REase> routine. (See below).

=back

C<tex_escape()> returns a bit flag C<$mflag> indicating whether C<$value> is modified:

=over 3

=item 0b0000

there were no changes (modifications).

=item 0b0001

there were changes and they affected only non-TeX structures.

=item 0b0010

changes were made and affected TeX structures and/or the start tag.

=back

C<tex_escape()> will not be executed if input C<< _MFLAGS_ & 0b0110 >>.


=head2 REase( $value [, $options ] )

"Cuts" ("splits") C<$value>, recognizing non-alphabetic sections in it (except for the '\' character, 
a sequence of characters that TeX cannot break with ordinary word breaks) and
glues the "cut" sections together with stretchable "glue" (i.e., a "spring" --- C<< {\hskip0pt plus .02em} >>).

For example, this gibberish:

 my $value = '~$&,%,$,#,_,{,},^,\2qw\ea-sdf-124-590\\\\\\>>>>---1';
 my $mflag = REase( $value );

converts to a sequence (by default, C<< tail = 3 >>)

  '{\hskip0pt plus .02em}~$&,'.
  '{\hskip0pt plus .02em}%'.
  '{\hskip0pt plus .02em},$,#'.
  '{\hskip0pt plus .02em},'.
  '{\hskip0pt plus .02em}_,{,'.
  '{\hskip0pt plus .02em}}'.
  '{\hskip0pt plus .02em},^,\2'.
  '{\hskip0pt plus .02em}qw\ea'.
  '{\hskip0pt plus .02em}-'.
  '{\hskip0pt plus .02em}sdf'.
  '{\hskip0pt plus .02em}-'.
  '{\hskip0pt plus .02em}1'.
  '{\hskip0pt plus .02em}24'.
  '{\hskip0pt plus .02em}-'.
  '{\hskip0pt plus .02em}5'.
  '{\hskip0pt plus .02em}9'.
  '{\hskip0pt plus .02em}0\\\\\\>>'.
  '{\hskip0pt plus .02em}>>'.
  '{\hskip0pt plus .02em}---'.
  '{\hskip0pt plus .02em}1'

This will allow TeX, when creating (layout) the finished document, 
to break such sequences into separate small fragments and lines and 
place them in very narrow TeX blocks, such as narrow table cells, 
without "manual adjustment" (intervention by I<Homo sapiens>).

C<$options> is optional and can be specified as a SCALAR or a HASH.
For example, C<$options> is a HASH:

  my $mflag = REase( $value, { tile => 2, esc => '!stag -stag', _MFLAGS_ => 0 } );

For example, C<$options> is a SCALAR:

  my $mflag = REase( $value, '!stag -stag');

i.e. the SCALAR form of C<$options> allows passing additional options only as C<esc>.

Here, the main auxiliary option is C<tail>, which specifies the size (in characters) of the maximum 
uncut non-alphabetic sections in the range from 1 to C<< tail + 1 >>.
For example, for C<< tail = 5 >>, the sizes of uncut non-alphabetic sections will be 
from 1 to 6 characters, e.g.:

  $mflag = REase( $value, { tile => 5 } );

Valid values for C<tail> are from 2 to 9.

C<REase()> simultaneously "cleans" C<$value> from excess "glue", 
excessively nested and empty TeX-blocks specified by curly braces C<< {} >>,
e.g.:

  '{{{124244234}}sdsdfdsfsdf{}{}'

converts to a sequence (C<< tail = 3 >>)

  '{\hskip0pt plus .02em}{{{1{\hskip0pt plus .02em}2'.
  '{\hskip0pt plus .02em}4244'.
  '{\hskip0pt plus .02em}2'.
  '{\hskip0pt plus .02em}34}'.
  '{\hskip0pt plus .02em}}'.
  '{\hskip0pt plus .02em}sdsdfdsfsdf'

If the $value ends with TeX-command C<< \relax\/ >>, then the value itself is not modified, it is skipped.
C<< \relax\/ >> remains untouched at the end.

C<REase()> also depends on C<%%%:> start tag and the C<< !stag >>, C<< -stag >> options
(but not the C<< +stag >> option), similar to C<tex_escape()>.

C<REase()> returns a bit flag C<$mflag> indicating whether C<$value> is modified:

=over 3

=item 0b0000

there were no changes (modifications).

=item 0b0001

there were changes and they affected only non-TeX structures.

=item 0b0010

changes were made and affected TeX structures and/or the start tag.

=item 0b0100

changes were made and greatly affected TeX structures.

=back

C<REase()>  will not be executed if C<< _MFLAGS_ & 0b0100 >>.


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
