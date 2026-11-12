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
		AGLkit
		font_metrics
		onecell
	) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.803';
our $DEBUG = 0;

our $qs = qr/^|_|\b/o;
our $qe = qr/_|\b|$/o;

# for glue
our $q = qr/\{\\hskip0pt +plus +0?.02em\}/o;
# our $p; $p = qr/\{\s*(?:(?>$q)|(??{$p}))*\s*\}/o;
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

# font sizes, depending on the document's base font size (pt), see \documentclass[...pt]
our $fontSizeTeX = {
	names => {tiny=>0, scriptsize=>1, footnotesize=>2, small=>3, normalsize=>4, large=>5, Large=>6, LARGE=>7, huge=>8, Huge=>9},
	#      0  1  2   3      4      5     6      7      8      9
	10 => [5, 7, 8,  9,     10,    12,   14.4,  17.28, 20.74, 24.88],
	11 => [6, 8, 9,  10,    10.95, 12,   14.4,  17.28, 20.74, 24.88],
	12 => [6, 8, 10, 10.95, 12,    14.4, 17.28, 20.74, 24.88, 24.88],
};

our $refHypMsk = {
	en => qr/[a-zA-Z\-]+/o,
	ru => qr/[а-яёА-ЯЁ\-]+/o,
};

#-------------------
# External functions
#-------------------

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
				s/(?<=[[:alpha:]])\-(?=[[:alpha:]])/"=/gi; #"# make compound words with 'active' hyphens
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
				s/(?<=[[:alpha:]])\-(?=[[:alpha:]])/"=/gi; #"# make compound words with 'active' hyphens
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

	our( $qs, $qe, $q, $m, $sI );

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
				or /^\p{Alpha}+$/;

		my $z = $_;

		s/(?:(?<b>.{2,$n}[^\x5C])|(?<b>[^\x5C]|\b))(?<s>[^\x5C\p{Alpha}\.><\}\{'`=_\"-])(?(1)|(?=\p{Alpha}))/$+{b}$m$+{s}$m/g; #'

		s/-{1,3}/$m$&$m/g; # don't touch the em dash
		s/\<{1,2}/$m$&/g;
		s/\>{1,2}/$&$m/g;

		# removal of excess glue:
		s/(?<=[\(\[\{«])(?:$q)+(?=[[:alnum:]])//g; # after the opening parenthesis
		s/(?<=[[:alnum:]])(?:$q)+(?=[\)\]\}»])//g; # before the closing parenthesis

		s/(?<=\p{Alpha})(?:$q)+([,\.:!;])/$1$m/g; # permutation for these symbols

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
	$op{debug} //= $DEBUG;

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
						$done{$f} = $done{ $actions{$f} } = undef;
						undef $f;
					}
					else {
						$done{$f} = $done{ $actions{$f} } = undef;
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
			my $f = 'tex_escape';
			if( ! exists $done{$f} ) {
				unshift @{ $op{_ACTIONS_} }, { # must be 1st if not specified
						_name_ => $f,
						_code_ => $actions{$f},
					};

				$done{$f} = undef;
			}

			$f = 'REase';
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
			{x} -- check the eXistence of Value (or eXpanded)
			{v} -- to paste by default text (located in template) if variable =~/^\x{001}$/
			{p} -- to paste text on right
			{head}[...] -- TeX strings before %%%V:
			{tail}[...] -- TeX strings after %%%V:
			{eX}[...] -- indices of {head} that eXcept for the first and last elements and rows of %%%VAR:
=end comment
=cut

	if( $TEMPLATE )  { # source is file
		while( my $z = <$TEMPLATE> ) {

			$end = &_replisome( $info, \$z, \$data, \$vardata, \$chkVAR, \$key, \$tdz, \@columns, \%op );

			if( $end ) {
				print { $fh } <$TEMPLATE> if $end != 3; # %%%ENDT:

				last; #--> Exit template: \endinput AND \end{document}
			}
			undef $z;

		}
		close $TEMPLATE;
	}
	else { # source is ARRAY
		for my $z ( @$source ) {

			if( $end ) { # %%%ENDT:
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

			if( $t ) {
				return 1 if $t eq 'T'; # END of Template area --> output everything to the end of template without substitution
				undef $$tdz; # if $t eq 'Z';
			}

			return 0 if $$z =~/%%%ENDZ?:/; # end of %%%VAR: tag

			if( $$z =~/%%%+TDZ:/) { # The Dead Zone
				$$tdz = 1;
				return 0;
			}
		}
		else {
			my $vk = $vtype eq 'HASH' ? $$vardata->{ $$key } : $$vardata->[ $$key ];
			my $sclr = (ref(\$vk) eq 'SCALAR' or ref($vk) eq 'SCALAR');

			# Index of column in target table
			my $j = ( @$columns && exists( $columns->[-1]{ki} ) ) ?
						@$columns :
						$#$columns; # ($#$columns // 0);
			$j = 0 if $j < 0 or $sclr;

			if( ! $sclr and $$z =~/^(.*?)\s?%%%+V:\s*(\*?)([^\s:%#\*]+)(%?)\s?(.*)/) {
				# the non-SCALAR V-variable is nested in a VAR-structure
				my $dV = $1; # Value, by default
				my $eXi = $2; # check the eXistence of Value (or eXpanded)
				my $ki = $3; # name (key or index) of V-variable
				my $Np = $4; # NO \par
				my $paste = $5; # on right

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
							or ( $ki eq '@' and ref $vk->{'@'} eq 'ARRAY')
						)
				) {
					$columns->[$j]{ki} = $ki; # save variable key in j-th element
				}

				&_set_column( $dV, $eXi, $Np, $paste, $columns->[$j] ) if exists $columns->[$j]{ki};
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
#		else {
#			return 0;
#		}

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

	if( $$z =~/(.*?)\s?%%%+VAR:\s*(\*?)([^\s:%#\*]+)(%?)\s?(.*)/) {
		my $before = $1; # Value, by default
		my $eXi = $2; # eXistence of Value
		my $k = my $k0 = $3; # name (key)
		my $Np = $4; # NO \par
		my $paste = $5; # on right text for SCALAR only

		# root or global structure (environment)
		my $vd = ( $k =~s/^\/+//) ? $info : $$data;

		my $xk; # for unknown/undefined sub-key
		my @kk = grep length, split '/', $k;

		# Search nested sub-keys
		foreach my $sk ( @kk ) {
			$$vardata = $vd;

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
push @{$op->{logs}}, "~~> l.$. WARNING#2: unknown or undef ARRAY|HASH|SCALAR|REF.SCALAR of sub-key '$xk' in %%%VAR:". $k0 if $op->{debug} or ! $op->{ignore};

			$$vardata = $$data;
			print { $op->{fh} } $$z;
			++$op->{nlo};
			return 0;
		}

		# key or sub-...sub-key is found
push @{$op->{logs}}, "--> l.$. Found %%%VAR:". $k0 if $op->{debug};

		my $vk = ref $$vardata eq 'HASH' ? $$vardata->{$k} : $$vardata->[$k];

push @{$op->{logs}}, "~~> l.$. NOT defined key in %%%VAR:". $k0 if ! defined($vk) && $op->{debug};

		return 0 if &_chk_var( $k, $vk, $eXi, $Np, \$paste, \$before, $chkVAR, $columns, $z, $op );

# push @{$op->{logs}}, "--> l.$. Remember key = '$k' (chkVAR=$$chkVAR), type: ".ref($vk) if $op->{debug}; ###AG

		$$key = $k; # save key name
		return 0;

	}
	elsif( $$z =~/%%%V:\s*=(def|esc|ignore|silent|debug)=\s*([\d~%]*)/) { # setting up facultative options
		my $k = $1;
		my $x = $2 || 0;
		my $i = ( $op->{$k} && $op->{$k} =~/\d\d?/ ) ? $& : 0;

		if( $i < 2) {
			$op->{$k} = $x ;

push @{$op->{logs}}, "~~> l.$. Option =$k= set to $x" if $op->{debug};

		}

		return 0;
	}
	elsif( $$z =~/^(?<v>.*?)\s?%%%+V:\s*(?<x>\*?)(?<k>[^\s:%#\*]+)(?<p>%?)\s?(?<s>.*)/) {
		my $k = $+{k};

		my %el;
		&_set_column( $+{v}, $+{x}, $+{p}, $+{s}, \%el );

		my $inidata = $$data; # save initial environment

		my $slash;
		if( $k =~s/^\/+//) {
			$slash = 1;
			$$data = $info; # reset to root environment

			length($k) or return 0;
		}
		elsif( $k =~/\//) {
			$slash = 1;
		}

		# Search nested sub-keys
		my $x = 0; # 1 is SCALAR value found or unknown sub-key
		my @kk = grep length, split '/', $k;

		my $i = 0;
		foreach my $sk ( @kk ) {

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

				if( $slash ) {
					$$data = $d; #  sub-key (path) found: redefined
					next;
				}

push @{$op->{logs}}, "~~> l.$. WARNING#5: (ARRAY|HASH) w/o '/' is wrong type of '$sk' in %%%V:". $k if $op->{debug} or ! $op->{ignore};

				print { $op->{fh} } $$z;
				++$op->{nlo};

				$x = 1;
				last;
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

push @{$op->{logs}}, "~~> l.$. WARNING#9: '$sk' is not at the end of %%%V:". $k if $i < $#kk and ( $op->{debug} or ! $op->{ignore} );

			$x = 1;
			last;
		}
		continue {
			++$i;
		}

		$$data = $inidata if $x; # SCALAR value found or unknown sub-key: reset to initial environment

		return 0;
	}

	print { $op->{fh} } $$z;
	++$op->{nlo};

	return 0;
}


sub _set_column {
	my( $dV, $eXi, $Np, $paste, $column ) = @_;

	$column->{v} = $dV if length $dV; # Value, by default
	$column->{x} = 1 if $eXi; # check the eXistence of Value
	$column->{'%'} = 1 if $Np; # NO \par
	$column->{p} = $paste if length $paste; # on right text for SCALAR only
}


sub _data_redef {
	my( $sk, $d, $k, $data, $xk ) = @_;

	if( ref $d eq 'ARRAY' or ref $d eq 'HASH') {
		$$data = $d; # redefined for %%%VAR:
		$$k = $sk;
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
	my( $k, $vk, $eXi, $Np, $paste, $before, $chkVAR, $columns, $z, $op ) = @_;

	if( ref $vk eq 'ARRAY') {

		if( @{ $vk } ) {
		# Check ARRAY.{ARRAY|HASH|SCALAR[.REF]}

			for my $d ( @{ $vk } ) {
				my $dtype = ref $d;

				if($dtype eq 'ARRAY'){
					$$chkVAR |= 0b00001;
				}
				elsif($dtype eq 'HASH') {
					$$chkVAR |= 0b00010;
				}
				elsif(ref \$d eq 'SCALAR') {
					$$chkVAR |= 0b00100;
				}
				elsif($dtype eq 'SCALAR') { # REF->SCALAR
					$$chkVAR |= 0b01000;
				}
				else {
					$$chkVAR |= 0b10000; # other
				}
			}
		}
		else {
			$$chkVAR |= 0b00100; # by default, SCALAR
		}

		if( $$chkVAR > 0b01000 or ($$chkVAR & ($$chkVAR - 1)) ) { # ! $$chkVAR or 
push @{$op->{logs}}, "~~> l.$. WARNING#6: mixed types (ARRAY with HASH with SCALAR or other) of %%%VAR:". $k if $op->{debug} or ! $op->{ignore};

			print { $op->{fh} } $$z;
			++$op->{nlo};
			return 1;
		}
	}
	elsif( ref \$vk eq 'SCALAR' or ref $vk eq 'SCALAR') {
		$columns->[0]{ki} = $k;
		&_set_column('', $eXi, $Np, $$paste, $columns->[0] );
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

	if( $el->{x} && length($v) ) { # for '*param'

		my $f;
		for('v','p') {
			exists( $el->{$_} ) or next;

			print { $op->{fh} } $el->{$_};
			$f = 1;
		}

push @{$op->{logs}}, "--> l.$.>". $op->{nlo} .' Insert by eXistence condition (*) of %%%V[AR]:'. $k .'= '. $el->{v} if $f && $op->{debug};

	}
	else {
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

			# [...].ARRAY.ARRAY.SCALAR
			$end = &_hvt_print( $i, $_, $el, $op, $$border ); 

			++$$col;
			$$border = 0;

			last if $end;
		}
	}
	else {
push @{$op->{logs}}, "~~> l.$. WARNING#10: ...ARRAY.ARRAY[$i] is NOT a SCALAR in %%%V:$i ...skipped" if $op->{debug} or ! $op->{ignore};
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

								last _var_output_M0 if $end = &_hvt_print( $ki, $vv, $el, $op, $border );
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

				last _var_output_M0 if $end = &_hvt_print( $ki, $val, $el, $op, $border );
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

						last if $end = &_hvt_print( $k, $v, $el, $op, $border );
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

			last if $end = &_hvt_print( $ki, $val, $el, $op, $border );
		}
		continue {
			++$col;
		}
	}

	return $end;
}


sub _get_mate {
	my( $glyph, $agl, $op ) = @_;

	%$agl or return $glyph;

	return $agl->{ $glyph } if exists( $agl->{ $glyph } ) && defined( $agl->{ $glyph } );

	my $mate = $glyph;

	if( $glyph =~/^uni([0-9A-F]{4}|[0-9A-F]{8})/ ) { # sprintf("uni0%X", $_)# , uniXXXX
		my $code = $1;

		if( $op->{mate} =~/^sym/) {
			$mate = chr(hex( $code ));
		}
		elsif( $op->{mate} =~/^hex/) {
			$mate = $code;
		}
		else { # dec
			$mate = hex $code;
		}
	}
	else {
		carp "Undefined glyph: '$glyph'";
		undef $mate;
	}

	return $mate;
}

#-------------------
# External functions
#-------------------
# Get kit/set of 'Adobe Glyph List'
# $op->{glyphlist} -- glyphlist file
# $op->{mate} = 'symbol' of Unicode | 'hex' Unicode number (native). By default, decimal Unicode number

sub AGLkit {
	my( $op ) = @_;
	my $agl = {};

	if( $op->{glyphlist} ) {
		open( my $AGL, '<', $op->{glyphlist} ) or croak "Can't find the AGL file: '$op->{glyphlist}'";

		while( <$AGL> ) {
			next if /^\s*$/ or /^\s*#/;

			my( $glyph, $codes ) = split /\s*;\s*/;
			next unless $glyph && $codes;

			$glyph =~s/\s+//g;
			$codes =~s/^\s+|\s+$//g;
			$codes =~s/\s+/ /g;

			next if ! $glyph or $glyph =~/^\.notdef$/i or $glyph =~/[^0-9A-Za-z]/
					or ! $codes or length( $codes ) < 4 or $codes !~/^[0-9A-Fa-f\s]+$/;

#			$codes =~y/0-9A-Fa-f //cd;
#			next if ! $codes or length( $codes ) < 4;

			my $mate;
			if( $op->{mate} ) {
				if( $op->{mate} =~/^sym/) {
					$mate = join('', map{ chr hex } split /\s+/, $codes );
				}
				elsif( $op->{mate} =~/^hex/) {
					($mate = $codes) =~s/\s+/ /g;
					$mate = uc $mate;
				}
			}

			$agl->{ $glyph } = $mate // join(' ', map{ hex } split /\s+/, $codes );
#			push @{ $agl->{'@'}{ $arr[0] } } = $agl->{ $glyph } if @arr > 1; # ???
		}

		close $AGL;
	}
	else {
		$agl = {
exclamdown => ord('¡'), # \u00A1
cent => ord('¢'), # \u00A2
sterling => ord('£'), # \u00A3
currency => ord('¤'), # \u00A4
yen => ord('¥'), # \u00A5
brokenbar => ord('¦'), # \u00A6
section => ord('§'), # \u00A7
dieresis => ord('¨'), # \u00A8
copyright => ord('©'), # \u00A9
ordfeminine => ord('ª'), # \u00AA
guillemotleft => ord('«'), # \u00AB
logicalnot => ord('¬'), # \u00AC
#	sfthyphen => ord(''), # \u00AD
registered => ord('®'), # \u00AE
macron => ord('¯'), # \u00AF
		#---
degree => ord('°'), # \u00B0
plusminus => ord('±'), # \u00B1
twosuperior => ord('²'), # \u00B2
threesuperior => ord('³'), # \u00B3
acute => ord('´'), # \u00B4
mu => ord('µ'), # \u00B5
paragraph => ord('¶'), # \u00B6
periodcentered => ord('·'), # \u00B7
cedilla => ord('¸'), # \u00B8
onesuperior => ord('¹'), # \u00B9
ordmasculine => ord('º'), # \u00BA
guillemotright => ord('»'), # \u00BB
onequarter => ord('¼'), # \u00BC
onehalf => ord('½'), # \u00BD
threequarters => ord('¾'), # \u00BE
questiondown => ord('¿'), # \u00BF
		#---
Agrave => ord('À'), # \u00C0
Aacute => ord('Á'), # \u00C1
Acircumflex => ord('Â'), # \u00C2
Atilde => ord('Ã'), # \u00C3
Adieresis => ord('Ä'), # \u00C4
		#---
Aring => ord('Å'), # \u00C5
AE => ord('Æ'), # \u00C6
Ccedilla => ord('Ç'), # \u00C7
Egrave => ord('È'), # \u00C8
Eacute => ord('É'), # \u00C9
Ecircumflex => ord('Ê'), # \u00CA
Edieresis => ord('Ë'), # \u00CB
Igrave => ord('Ì'), # \u00CC
Iacute => ord('Í'), # \u00CD
Icircumflex => ord('Î'), # \u00CE
Idieresis => ord('Ï'), # \u00CF
		#---
Eth => ord('Ð'), # \u00D0
Ntilde => ord('Ñ'), # \u00D1
Ograve => ord('Ò'), # \u00D2
Oacute => ord('Ó'), # \u00D3
Ocircumflex => ord('Ô'), # \u00D4
Otilde => ord('Õ'), # \u00D5
Odieresis => ord('Ö'), # \u00D6
multiply => ord('×'), # \u00D7
Oslash => ord('Ø'), # \u00D8
Ugrave => ord('Ù'), # \u00D9
Uacute => ord('Ú'), # \u00DA
Ucircumflex => ord('Û'), # \u00DB
Udieresis => ord('Ü'), # \u00DC
Yacute => ord('Ý'), # \u00DD
Thorn => ord('Þ'), # \u00DE
germandbls => ord('ß'), # \u00DF
		#---
agrave => ord('à'), # \u00E0
aacute => ord('á'), # \u00E1
acircumflex => ord('â'), # \u00E2
atilde => ord('ã'), # \u00E3
adieresis => ord('ä'), # \u00E4
aring => ord('å'), # \u00E5
ae => ord('æ'), # \u00E6
ccedilla => ord('ç'), # \u00E7
egrave => ord('è'), # \u00E8
eacute => ord('é'), # \u00E9
ecircumflex => ord('ê'), # \u00EA
edieresis => ord('ë'), # \u00EB
igrave => ord('ì'), # \u00EC
iacute => ord('í'), # \u00ED
icircumflex => ord('î'), # \u00EE
idieresis => ord('ï'), # \u00EF
		#---
eth => ord('ð'), # \u00F0
ntilde => ord('ñ'), # \u00F1
ograve => ord('ò'), # \u00F2
oacute => ord('ó'), # \u00F3
ocircumflex => ord('ô'), # \u00F4
otilde => ord('õ'), # \u00F5
odieresis => ord('ö'), # \u00F6
divide => ord('÷'), # \u00F7
oslash => ord('ø'), # \u00F8
ugrave => ord('ù'), # \u00F9
uacute => ord('ú'), # \u00FA
ucircumflex => ord('û'), # \u00FB
udieresis => ord('ü'), # \u00FC
yacute => ord('ý'), # \u00FD
thorn => ord('þ'), # \u00FE
ydieresis => ord('ÿ'), # \u00FF
		#---
afii10064 => ord('δ'), # echo -e "\u03B4" # a.? \uF6C5 see "Adobe Standard Cyrillic Font Specification"
afii10063 => ord('ι'), # a.? \uF6C4
afii10192 => ord('g'), # a.? \uF6C6
afii10831 => ord('й'), # a.? \uF6C7
afii10832 => ord('ш'), # a.? \uF6C8
afii10846 => ord('ә'), # \u04D9
afii61352 => ord('№'), # \u2116
		# Symbol and Punctuation Glyph
minus => ord('−'), # \u2212
trademark => ord('™'), # 2122
bullet => ord('•'), # echo -e "\u2022"
ellipsis => ord('…'), # \u2026
endash => ord('–'), # \u2013
emdash => ord('—'), # \u2014
dagger => ord('†'), # \u2020
daggerdbl => ord('‡'), # \u2021
quotedblbase => ord('„'), # \u201E
quotedblleft => ord('“'), # \u201C
quotedblright => ord('”'), # \u201D
quoteleft => ord("‘"), # \u2018
quoteright => ord("’"), # \u2019
quotesinglbase => ord('‚'), # \u201A
perthousand => ord('‰'), # \u2030
guilsinglleft => ord('‹'), # \u2039
guilsinglright => ord('›'), # \u203A
circumflex => ord('ˆ'), # \u02C6
tilde => ord('˜'), # \u02DC
hungarumlaut => ord('˝'), # \u02DD
ring => ord('˚'), # \u02DA
caron => ord('ˇ'), # \u02C7
breve => ord('˘'), # \u02D8
dotaccent => ord('˙'), # \u02D9
ogonek => ord('˛'), # \u02DB
dotlessi => ord('ı'), # \u0131
dotlessj => ord(''), # \uF6BE
fi => ord('ﬁ'), # \uFB01
fl => ord('ﬂ'), # \uFB02

		};

		$agl->{$_} = ord($_) for 'A'..'Z', 'a'..'z'; # ASCII Glyph Names: 65..90, 97..122

		# also ASCII Glyph Names, but 32..64, 91..96, 123..126
		@{$agl}{qw(
space exclam quotedbl numbersign dollar percent ampersand quotesingle parenleft parenright
asterisk plus comma hyphen period slash zero one two three four five six seven eight nine
colon semicolon less equal greater question at
	bracketleft backslash bracketright asciicircumb underscore grave
braceleft bar braceright asciitilde
)} = ( ord(' ')..ord('@'), ord('[')..ord('`'), ord('{')..ord('~') ); #}

		# Cyrillic Glyph Names: Uppercase (afiiXXXXX)
		my $x = 10017; # start of 'А'...'Я' from afii10017 to afii10049
		for( ord('А')..ord('Е'), ord('Ё'), ord('Ж')..ord('Я') ) {
			$agl->{"afii$x"} = $_;
			++$x;
		}
		for('Ґ','Ђ','Ѓ','Є','Ѕ','І','Ї','Ј','Љ','Њ','Ћ','Ќ','Ў') { # from afii10050 to afii10062
			$agl->{"afii$x"} = ord $_;
			++$x;
		}
		$x = 10145;
		for('Џ','Ѣ','Ѳ','Ѵ') { # from afii10145 to afii10148
			$agl->{"afii$x"} = ord $_;
			++$x;
		}

		# Cyrillic Glyph Names: Lowercase
		$x = 10065; # start of "а"..."я" from afii10065 to afii10097
		for( ord('а')..ord('е'), ord('ё'), ord('ж')..ord('я') ) {
			$agl->{"afii$x"} = $_;
			++$x;
		}
		for('ґ','ђ','ѓ','є','ѕ','і','ї','ј','љ','њ','ћ','ќ','ў') { # from afii10098 to afii10110
			$agl->{"afii$x"} = ord $_;
			++$x;
		}
		$x = 10193;
		for('џ','ѣ','ѳ','ѵ') { # from afii10193 to afii10196
			$agl->{"afii$x"} = ord $_;
			++$x;
		}

		if( $op->{mate} && $op->{mate} =~/^(?:(sym)|hex)/ ) {
			my $f = $1 ? 1 : 0;

			for( values %$agl ) {
				$_ = $f ? chr : sprintf("%04X", $_);
			}
		}

	}

	return $agl;
}

# Get font metrics from Adobe Font Metric file
# IN:
#	$op->{glyphlist} -- glyphlist file
#	$op->{noBbox} -- without 'B'-box
#	$op->{noKPX} -- without 'KPX'
#	$op->{mate} = 'glyph' of Adobe | 'symbol' of Unicode | 'hex' Unicode number (native). By default, decimal Unicode number
# OUT:
#	$font_metrics->
#		{WX}{ $mate } -- symbol width of mate
#		{Bbox}{ $mate } -- Bounding Box of mate
#		{KPX}{ $mateA }{ $mateB } -- paired kerning of mateA & mateB

sub font_metrics {
	my( $AFMfile, $op ) = @_;

	$op->{mate} //= '';
	my $agl = ($op->{mate} =~/^glyph/) ? {} : &AGLkit( $op );

	my %font_metrics;

	open( my $AFM, '<', $AFMfile ) or croak "Can't find the AFM file";
	while( <$AFM> ) {
#		next if /^StartComposites/ .. /^EndComposites/; # composites not parsed yet

		if( /^StartCharMetrics/i .. /^EndCharMetrics/i ) {
			/^CH?\s/ or next; # only lines that start with "C" or "CH" are parsed

			# C 32 ; WX 300 ; N space ; B 0 0 0 0 ;
			/;\s*WX\s*(\d+)\s*;\s*N\s+([\w.]{1,63})\s*;/ or next;
			my( $wx, $glyph ) = ($1, $2);

			my $bbox = /;\s*B\s*([^;]+)\s*;/ ? $1 : '';
			$bbox =~ s/\s+/ /g;
			$bbox =~ s/^\s+|\s+$//g;

			my $mate = &_get_mate( $glyph, $agl, $op );

			if( defined $mate ) {
				$font_metrics{WX}{ $mate } = $wx;
				$op->{noBbox} or $font_metrics{Bbox}{ $mate } = $bbox; # 'B'-box
			}

			next;
		}

		next if $op->{noKPX}; # without 'KPX'

		if( /^StartKernPairs/i .. /^EndKernPairs/i ) {
			/^KPX\s/ or next; # only lines that start with "KPX" are parsed

			# KPX space A -55
			my( undef, $glyphA, $glyphB, $kpx ) = split /\s+/o;

			$kpx =~y/0-9-//cd;
			$kpx or next;

			my $mateA = &_get_mate( $glyphA, $agl, $op );
			my $mateB = &_get_mate( $glyphB, $agl, $op );

			$font_metrics{KPX}{ $mateA }{ $mateB } ||= $kpx
				if defined( $mateA ) && defined( $mateB ) && ! exists( $font_metrics{KPX}{ $mateA }{ $mateB } );

			next;
		}

		last if /^EndFontMetrics/;
	}
	close $AFM;

	return \%font_metrics;
}


# IN:
#	$str -- string (strand)
#	$op->
#		{cell_width} -- width of cell/box (pt).
#		{font_metrics} -- table of font metrics with {WX} key -- for decimal Unicode number, and {KPX} key -- for paired kerning.
#		{base_font_size} -- depending on the document's base font size (pt), see \documentclass[...pt].
#		{font_size} -- TeX-font size of text in cell/box, e.g. 'small', 'normalsize', 'large', etc.
#		{shrink} -- space compressibility (the extent to which a space can become narrower than its base value if the line is compressed).
#		{merge} = 1 -- return a combined string (paragraph) and its total width (length) in (pt), rather than an array of strings.
#		{offset} -- offset from the beginning of $str from which characters for cell are extracted. By default, 0.
#		{limit} -- the maximum allowable number of lines for a cell.
#		{hyphenation} => # a array of methods for hyphenating words in specified languages, e.g.:
#		   [
#				{ name =>'en', action => $hyp_en, },
#				{ name =>'ru', action => $hyp_ru, },
#		   ]
#		OR
#		   [
#				{ msk => qr/[a-zA-Z]+/o, action => $hyp_en, },
#				{ msk => qr/[а-яА-Я]+/o, action => $hyp_ru, },
#		   ]

# OUT:
#	HASH with keys:
#		'lines' -- arrays of no empty lines.
#		'wxL'   -- arrays of line widths (*100pt) from 'lines'.
#		'numL'  -- number of no empty lines.
#		'stop'  -- position in $str where the extraction of symbols into cell stopped.
#		     If all non-whitespace characters have been extracted from $str and 'limit' option is specified, then '-1' is returned.
#	or
#	SCALAR is number of lines

sub onecell {
	return if ! defined( $_[0] )
					 or ref \$_[0] ne 'SCALAR'
					 or ! $_[1]
					 or ref $_[1] ne 'HASH';

	my $ArSc = wantarray;

	my $op = $_[1];

	if( $_[0] =~/^\s*$/ ) {
		return $ArSc ? {lines => [ $_[0] ], wxL => [0], numL => 0, stop => 0,} : 0;
	}

	$op->{cell_width} or croak "Cell width is NOT specified!";

	my $offset = $op->{offset} // 0;
	my $szStr = length $_[0];

	return if $offset < 0 or $offset >= $szStr;

	my $limit = $op->{limit} // 0;
	$limit += 0;
	$limit = 0 if $limit < 0;

	# font character width table
	my $symWX = $op->{font_metrics}{WX} or croak "Font metrics are NOT specified!";
	my $symKPX = $op->{font_metrics}{KPX} || {};

	our( $q, $m );

	my $space = ($op->{space} // 0) * 100 || $symWX->{32} or croak "Base whitespace width is NOT specified!";
	$space -= ($op->{shrink} // 0) * 100; # reduce by the maximum whitespace compression, if specified
	my $spcKPX = $symKPX->{32} || {}; # paired kerning for whitespace

	my $hyphen = $symWX->{45}; # ord('-') -- hyphen width
	my $wideS = $symWX->{64}; # ord('@') -- width of the average-to-maximum-width character

	our $fontSizeTeX;
	our $refHypMsk;

	my $base_font_size = $op->{base_font_size} || 10; # base document font size (pt)

	my $font_id = $fontSizeTeX->{names}{ $op->{font_size} || 'normalsize'}; # for 'normalsize' = 4

	# cell-to-'normalsize' scaling factor
	my $scale = ( $font_id == 4) ?
		1 :
		$fontSizeTeX->{ $base_font_size }[4] / $fontSizeTeX->{ $base_font_size }[ $font_id ]; # to 'normalsize'

	my $cell_width = $op->{cell_width} * $scale * 100; # scale the cell width to 'normalsize' (*100pt)

	my @lines = (''); # cell/box with filled lines
	my @wxL; # line width (*100pt)
	my $numL = 0; # number of lines
	my $numSeq = 0; # number of sequences in input string

	my $prevKPX = {}; # KPX previous (prev) symbol
	my $curKPX = {}; # KPX current (cur) symbol
	my $curSize = 0; # width of current (fillable) string

	my $yhp = 0; # > 0 -- flag for the presence/necessity of hyphenation in $word:
			#	1 -- hyphenation method(s) is specified;
			#	2 -- hyphenation points have already been inserted in the word;
			#	3 -- short word (<4 characters) | 4 -- word NOT found | 5 -- NO hyphens

	# checking for the presence of method(s) for hyphenating words
	if( $_ = $op->{hyphenation}
		and ref $_ eq 'ARRAY'
		and @$_
	) {
		my $hyp = $_;
		@$hyp = grep{ ( ($_->{msk} or ( $_->{name} && exists( $refHypMsk->{lc $_->{name}} ) ))
					&& exists( $_->{action} )
					&& ( ref( $_->{action} ) eq 'CODE'
						or ( ref( $_->{action} ) =~/::Hyphen/ and $_->{action}->can('hyphenate') )
					)
			) } @$hyp;

		$yhp = @$hyp ? 1 : 0;
	}

	pos $_[0] = $offset;
	my $stop = $offset;
	my $new; # 1 = new sequence

_onecell_M0:
	while( $_[0] =~/(\S+)/g ) { # extracting character words from input string
		$_ = $1;
		$stop = pos $_[0];
		$new = 1;

		my @cage = grep{ length } split /(\p{Alpha}{4,})/; # to split words into alphabetic and non-alphabetic words

		$yhp &&= 1;

		while( defined( my $word = shift @cage ) ) {

			my $szl = length $lines[-1];

			my $alpha; # 1 -- alphabetic word
			if( $word =~/^[\p{Alpha}\-]+$/) {
				$alpha = 1;
			}
			else {
				$alpha = 0;
				$yhp &&= 1; # Reset settings
			}

			my $delta = $cell_width - $curSize;

			# in a cell line, there are preceding word(s), and this is not a fragment
			$delta -= $space if $szl
									and ($new or ! ~~@cage)
									and $lines[-1] !~/(?:\\-|$q)$/;

			my $wS; # width of current symbol (*100pt)
			my $wH; # width of hyphen taking pair kerning into account (*100pt)
			my $wW = 0; # width of word/fragment (*100pt)
			my $f = 1; # flag that the word fits into a cell line
			my $nS = 0; # ordinal number (position) of symbol in word 

			my @ss = split //, $word;

			# to split word into symbols and get its decimal ID
			foreach my $sid ( map{ ord($_) } @ss ) { # current symbol id 
				$wH = @cage ? $hyphen : 0;

				if( exists $symWX->{ $sid } ) {
					$wS = $symWX->{ $sid };
					$curKPX = $symKPX->{ $sid } || {};

					# to take pair kerning into account: prev+cur
					$wS += $prevKPX->{ $sid } // 0;
					$wH += $curKPX->{45} // 0 if @cage; # for cur+hyphen
				}
				else {
					carp 'Undefined width for symbol with hexcode: '. sprintf("%04X",  $sid);
					$wS = $wideS;
					$curKPX = {};
				}

# say "1=> word='$word', symbol='". chr($sid) ."', curSize=$curSize, delta=$delta, wW=$wW, wS=$wS, nS=$nS, f=$f, yhp=$yhp, cage=".~~@cage;
# say Dumper \@cage;

				# это: 'буквенный фрагмент/слово' И 'не последняя буква' И 'следующий фрагмент тоже буквенныы'
				my $cnd = ($alpha && ($nS < $#ss or (@cage && $cage[0] =~/^\p{Alpha}+$/)) ) ? 1 : 0;

				# symbol width or (+hyphen) > cell width
				if( $wS > $cell_width
					or ($cnd and $wS + $wH > $cell_width)
				) {
					$f = -1;
					last;
				}

				# width of fragment > remaining (unfilled portion) cell width 
				if( $wW + $wS > $delta
					or ($cnd and $wW + $wS + $wH > $delta)
				) {
					$f = 0;
					last;
				}

				$wW += $wS;
				$prevKPX = $curKPX; # for pair kerning next symbol
				++$nS;
			}
			$numL ||= 1; # JIC

# if( $word =~/^WA$/) {
#	say "2=> word='$word', curSize=$curSize, delta=$delta, wW=$wW, wS=$wS, nS=$nS, #ss=".$#ss.", f=$f, yhp=$yhp, cage=".~~@cage;
#	say Dumper \@lines;
# }

			if( $f > 0 ) { # word (or fragment) is placed into the cell line in its entirety
				if( $szl && $lines[-1] !~/(?:\\-|$q)$/ ) { # there is prev.word(s) in the cell line and it is not fragment
					
					# add whitespace for prev.word
					$curSize += $space; # + ($prevKPX->{32} // 0);
					$lines[-1] .= ' ';
				}

				# add cur.word in cell line
				$curSize += $wW;
				$lines[-1] .= $word;

				if( @cage ) { # this is fragment (word continues further on)
					$lines[-1] .= ($alpha && $cage[0] =~/^\p{Alpha}+$/) ? '\\-' : $m; # + supposed hyphen or glue (\hskip)
				}

				next;
			}

			my @chunks = $word=~/(.{$nS})(.)(.*)/;

			if( $f < 0 ) { # symbol width > cell width

				if( (! defined( $chunks[2] ) or ! length( $chunks[2] )) && ! @cage ) { # NOT "tail" or fragments
					 # add whitespace
					$chunks[1] .= ' ';
					$wS += $space; # + ($prevKPX->{32} // 0);
					$prevKPX = $spcKPX; # for paired kerning of space + next.symbol

				}
				else { # exists "tail"
					if( $alpha && ($chunks[2] =~/^\p{Alpha}+$/ or $cage[0] =~/^\p{Alpha}+$/)) {
						$chunks[1] .= '\\-'; # symbol + hyphen
#						$wS += $wH; # width of (cur.symbol + hyphen + paired kerning): cur+hyphen
					}
					else {
						$chunks[1] .= $m; # +glue
					}
				}

				if( $nS ) { # exists "head" (prefix)

					$lines[-1] .= $chunks[0];

					if( $chunks[0] =~/^\p{Alpha}+$/) {
						$lines[-1] .= '\\-'; # + hyphen
#						push @wxL, $curSize + $wW + $hyphen + ($prevKPX->{45} // 0) if $ArSc; # taking paired kerning into account: prev+hyphen
					}
					else {
						$lines[-1] .= $m; # + glue
					}
					push @wxL, $curSize + $wW if $ArSc;

					if( $limit && @lines >= $limit ) {
						$stop -= (length( join('', $word, @cage) ) - $nS);
						last _onecell_M0;
					}

					# Next up is a new cell line
					++$numL;
					push @lines, $chunks[1];
				}
				else { # NO "head" (prefix)
					if( $szl ) { # and cell line is NOT empty (partially filled)

						my $add = 0;
						if( $lines[-1] !~/(?:\\-|$q)$/ and ! ~~@cage ) {
						# In cell line no word fragment at the beginning, but there is a complete word
							$lines[-1] .= ' ';
							$add = $space; # + ($prevKPX->{32} // 0);
						}
						push @wxL, $curSize + $add if $ArSc;

						if( $limit && @lines >= $limit ) {
							$stop -= length( join('', $word, @cage) );
							last _onecell_M0;
						}

						# Next up is a new cell line
						++$numL;
						push @lines, $chunks[1]; # with hyphen or glue (see above)
					}
					else { # cell line is EMPTY
						$lines[-1] .= $chunks[1]; # with posible? hyphen or glue
					}
				}

				push @wxL, $wS if $ArSc; # width of symbol + space

				if( $limit && @lines >= $limit ) {
					$stop -= ( length( join('', $word, @cage) ) - ($nS + 1));
					last _onecell_M0;
				}

				# Next up is a new cell line
				++$numL;
				$curSize = 0;
				$prevKPX = {};
				push @lines, '';

				if( $chunks[2] ) {
					$word = $chunks[2];

# say "3=> word='$word', chunks[2]=$chunks[2]";

					redo;
				}

# say "4=> word='$word', chunks[2]=$chunks[2]";

				next;
			}

			if( $alpha && $yhp && $yhp < 3) {
			# This is alphabetic word, and a method (action) for breaking words into hyphens is specified

				if( $yhp == 2 ) { # for word it was already broken by hyphens

					if( $szl ) { # and cell line is not empty (partially filled)

						my $add = 0;
						if( $lines[-1] !~/(?:\\-|$q)$/) { # there is a full word :  and ! ~~@cage 
							$lines[-1] .= ' ';
							$add = $space; # + ($prevKPX->{32} // 0);
						}
						push @wxL, $curSize + $add if $ArSc;

						if( $limit && @lines >= $limit ) {
							$stop -= length( join('', $word, @cage) );
							last _onecell_M0;
						}

						# Try placing it into 
						# Next up is a new cell line
						++$numL;
						$curSize = 0;

#						$lines[-1] =~/.$/;
						$prevKPX = {}; # $symKPX->{ord($&)} || ;
						push @lines, '';

						redo; # repeat in a new cell line
					}
				}
				elsif( $#ss > 2 ) { # length of word/fragment > 3 symbols
					for my $h ( @{ $op->{hyphenation} } ) {
						my $msk;
						if( $h->{msk} ) {
							$msk = $h->{msk};
						}
						elsif( $h->{name} ) {
							$msk = $refHypMsk->{lc $h->{name}};
						}

						if( $msk && $word =~/^$msk$/) {

							my @arr = ( ref( $h->{action} ) eq 'CODE') ?
								$h->{action}( $word ) :
								$h->{action}->hyphenate( $word );

							if( @arr > 1 ) {
								$yhp = 2; # YES word breaks (hyphenations)
								unshift @cage, @arr;
							}
							else {
								$yhp = 3; # NO word breaks (hyphenations)
							}
							last;
						}
						else {
							$yhp = 4; # word NOT found
						}
					}
					next if $yhp == 2; # hyphenation has been added to the words
				}
				else {
					$yhp = 5; # a small word (<4 symbols)
				}

			}

			# symbol < cell width, but did not fit into the current cell line

			if( $szl && $lines[-1] !~/(?:\\-|$q)$/) { # In cell line no word fragment at the beginning, but there is a complete word.
				$lines[-1] .= ' ';
				$curSize += $space; # + ($prevKPX->{32} // 0);
			}

			my $alpha_0 = $chunks[0] =~/^\p{Alpha}+$/ ? 1 : 0;


# if( $word =~/^A$/) {
#	say "5=> word='$word', wW=$wW, wS=$wS, nS=$nS, #ss=".$#ss.", f=$f, yhp=$yhp, szl=$szl, alpha_0=$alpha_0, cage=".~~@cage;
#	say Dumper \@lines;
# exit;
# }

			if( $nS && ($nS > 1 or ! $curSize or ! $alpha_0) ) {
			# hyphenation allowed only after the first 2 letters, or cell is EMPTY, or if the character is not a letter
				$lines[-1] .= $chunks[0];

#				my $add = 0;
				if( $alpha_0 && $alpha ) {
					$lines[-1] .= '\\-'; # + hyphen
#					$add = $hyphen + ($prevKPX->{45} // 0);
				}
				else {
					$lines[-1] .= $m; # + glue
				}

				push @wxL, $curSize + $wW if $ArSc; # taking into account kerning pairs prev+hyphen

				$word = $chunks[1].$chunks[2];
			}
			elsif( $ArSc ) { # current synbol is the 1st character of the word/fragment
				push @wxL, $curSize;
			}

			if( $limit && @lines >= $limit ) {
				$stop -= length( join('', $word, @cage) );
				last _onecell_M0;
			}

			# Next up is a new cell line
			++$numL;
			$curSize = 0;
			$prevKPX = $curKPX; # for paired kerning of the next symbol
			push @lines, '';

			redo; # repeat in a new cell line
		}
		continue {
			$new = 0;
		}
	}
	continue {
		++$numSeq;
	}

	push @wxL, $curSize if $ArSc && $curSize && $#wxL < $#lines;

	$stop = -1 if $limit
		and ( $stop >= $szStr or @lines < $limit or $_[0] =~/\A.{$stop}\s+\z/ );

	# Final preparations
	@lines = grep{ ! /^\s*$/ } @lines;

	my $i = 0;
	for( @lines ) {
		s/(?<=[[:alpha:]])$q(?=[\.,\?!:;%'])//g; #'
		s/(?<=[[:alpha:]])$q$// if $i < $#lines and $lines[$i+1] =~/^[\.,\?!:;%']/; #'
		s/(?:\\-|$q)(?=\S+\s\S)//g;
		++$i;
	}

	if( $lines[-1] =~s/ $// && $ArSc ) {
		$wxL[-1] -= $space;
	}

	my $wxLsum = 0;
	if( $ArSc && $op->{merge} ) {
		$wxLsum += $_ for @wxL;
	}

	return $ArSc ?
		{
			lines => ($op->{merge} ? [ join '', @lines ] : \@lines),
			wxL => ($op->{merge} ? [ $wxLsum ] : \@wxL),
			numL => ~~@lines, # $numL,
			stop => $stop,
		} :
		~~@lines; # $numL
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

  my $target_dir = 'sandbox';
  my $msg = replication( $file, $info, outdir => $target_dir );

A new C<$file> will be created in C<$target_dir> directory.

=item 3.
Using C<ofile> option:

  my $ofile = 'sandbox/ready_good.tex';
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

In a general sense, there are no restrictions on the complexity of C<$info> structure.
This is because you can point to the nested structure you need by redefining the global and/or local environment
(see C<%%%V:> and C<%%%VAR:> tags below).

However, for populating TeX template with direct values (without regard to the nesting path),
C<replication()> supports only the following structures included in C<$info>.

=over 6

=item 1.
single-level:

C<SCALAR>, C<REF>, C<ARRAY>, C<HASH>, and their combinations, e.g.

  my $v = 'Blah-blah';
  my @ell = (11, 22, 33);

  my $info = {
       Param => 'Blah-blah blah-blah',
       Ref => \$v,
       Array1 => [2025, 2026, 2027, 2028,],
       Array2 => [1..5],
       Array3 => \@ell,
       Array4 => [ \$ell[2], \$ell[0], \$ell[1], ],
       Hash => {year0 => 123456, year1 => 789012, year2 => 345678,},
       ...
  };

=item 2.
two-level:

C<ARRAY.ARRAY>, C<ARRAY.HASH>, C<ARRAY.REF>, C<HASH.ARRAY>, and their combinations, e.g.

  my $info = {
       Array_array => [ # custom user variable ARRAY-ARRAY
          ['00','01','02','03','04',], # row 0
          [10, 11, 12, 13, 14,], # row 1
          [20, 21, 22, 23, 24,], # row 2
          ...
       ],
       Array_hash => [ # variable ARRAY-HASH
          {A=>'00',B=>'01',C=>'02',}, # row 0
          {A=>10, B=>11, C=>12,}, # row 1
          ...
       ],
       Array_ref => [ # variable ARRAY-REF
          \@ell, # row 0
          \@ell, # row 1
          ...
       ],
       Array_mixed => [
          0, {A=>1}, \$ell[2], [5..9], ...
       ],
       Hash_array => { # variable HASH-ARRAY
          0 => ['00','01','02','03','04',], # row 0
          ...
       },
       Hash_mixed => {
          A=>\$v, B=>2, C=>3, D=>4, E=>5,
          '@' => ['C','B','D','A','E'],
          ...
       },
  };

=item 3.
three-level:

C<ARRAY.ARRAY.ARRAY>, C<ARRAY.HASH.ARRAY>, and their combinations, e.g.

  my $info = {
       Array_array_array => [
          [
            [1..9],
          ],
          [
            undef,
            [10..13],
            ...
          ],
          ...
      ],
      Array_hash_array => [
          {
            B=>[2,6..8],
            ...
          },
          ...
      ],
  };

=item 4.
the combinations of the above 1..3

=back

File and directory names and paths to them must not contain space characters.

In the names of C<%%%V:> and C<%%%VAR:> tags (keys and indexes), it is possible (preferably) to use 
only C<[a-zA-Z0-9_]> symbols, since other symbols are currently or will be reserved in the future.

Currently, symbols: C<< * >>, C<< % >>, C<< @ >>, C<< : >>, C<< = >>, and C<< / >> have a special purpose.

This module have reason only with perl 5.10 and higher.

=head1 ABSTRACT

Replicase in the form of the main subroutine L</"replication()"> is minimalistic (ascetic) interpreter (uses only 3-4 basic control tags,
like the system of 4 bases (nucleotides) and 3 codons, it is an optimal balance between diversity and stability)
that can be used to process (fill) real TeX-LaTeX files that act as templates.


=head1 DESCRIPTION

This module is a Perl 5 extension implementing Replicase subroutines which processes TeX-LaTeX files, 
interpreting and executing built-in control directives (tags) of C<replication()>.

Additional subroutines (L</"tex_escape()">, L</"REase()">, L</"AGLkit()">, L</"font_metrics()">, L</"onecell()">) 
serve an auxiliary role, making it possible to prepare data for populating TeX templates.

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
but using the C<%%%ADD:> tag and an additional variable (e.g. C<phantom>),
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
when the C<def> option is B<enabled>: X<anchor_item_1st>

=over 6

=item 1st.

complete absence, i.e. C<variable> B<does not exist>;

=item 2nd.

presence (B<exists>) with an B<undefined> value;

=item 3th.

B<exists> and B<defined> value and B<empty> (i.e. C<value = ''>, C<length of value == 0>);

=item 4th state.

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

Additionally, if a C<variable_name> starts with C<*> (i.e. C<*variable_name>),
then only the existence of that variable and its definition are checked. 
These conditions will confirm the insertion of the BEFORE (left) and AFTER (right, if any) 
values from the template, as well as the values of the surrounding C<%%%ADD:> and C<%%%ADDE:> tags.

In effect, this trick helps to extend the action of a variable (and its state) beyond the immediate 
vicinity of C<%%%ADD:> and C<%%%ADDE:> tags, e.g.:

  \begin{tabular}{ccc}
  %%%VAR: area
  \mbox{ %%%ADD:%
  1 Mandatory component %%%V: *leader  ...continuation...
  } & %%%ADDE:
  2 Blah of slave %%%V: slave
  & %%%ADD:
  3 Blah of leader %%%V: leader
  \\ %%%ADDE:
  ...
  %%%END:
  \end{tabular}

Thus, the new property (*) at the beginning of variable names (keys) confirms the existence of the variable 
but does not substitute its value into the template.

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
the I<local environment> of C<myParam> variable, the value of which is inserted into the template.

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
keeping the template text in the line preceding up to C<%%%VAR:> but completely replacing everything up to first C<%%%END:> 
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

Usually HASH and ARRAY I<variable_name> are used in the template to create (fill) tables or table-like boxes.

C<%%%VAR:> tag is similar to C<%%%V:> tag, where the variable name can be used to specify its search 
"path" using a special symbol, "C</>". However, this "path" does not affect the I<global environment>.
It only sets the I<local environment> within the scope of C<%%%VAR:> tag.

Nested C<%%%VAR:> tags will not work and are treated as C<%%%END:> tags,
i.e. tags for early termination of the scope.

It is very important to understand that there are four (4) states for C<%%%VAR: variable>
(just as for C<%%%V>, but with a nuance of 1st state) when the C<def> option is B<enabled>:

=over 6

=item 1st.

complete absence, i.e. C<variable> B<does not exist>;

=item 2nd.

presence (B<exists>) with an B<undefined> value;

=item 3th.

B<exists> and B<defined> value and B<empty> (i.e. C<value = ''>, C<length of value == 0>);

=item 4th state.

B<defined> value and B<not empty>.

=back

BTW: If C<def> option is B<disabled>, then state (2) is identical to state (3).

These states affect the final result C<%%%V:> of C<%%%VAR:> similarly to 
simple (SCALAR and REF.SCALAR variable) C<%%%V:> or C<%%%VAR:> (L<see above|/"anchor_item_1st">),
but there is a slight difference for the 1st state when a non-existent (complete absence)
key/name is specified. In this case, everything on the line along with C<%%%V:> is discarded
(it will not appear in the final document), while any surrounding context defined by 
C<%%%ADD:> and C<%%%ADDE:> is passed on to the next existing key/name belonging to C<%%%VAR:>.

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

this text will be added: C<< 'Head blah, blah, \ldots blah.' >>,
and the text located to the right of C<%%%ADD:> (i.e. C<Tail blah, blah, \ldots> in this case) will be discarded.

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

For all lines (records) B<eXcept for the outermost elements>: column (0) of first record (0) or after the last column of last record.

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

Tags can "absorb" B<ONE whitespace> character around them (left and/or right), if present.


=head1 SUBROUTINES

LaTeX::Replicase provides these subroutines:

    replication( $source, $info [, %hash_options ] );
    tex_escape( $value [, $options ] );
    REase( $value [, $options ] );
    AGLkit( [ $options ] );
    font_metrics( $AFMfile [, $options ] );
    onecell( $string, $options );


=head2 replication()

  my $msg = replication( $source, $info [, %hash_options ] )

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
C<&> C<%> C<$> C<#> C<_> C<{> C<}> C<^> C<\> (see description of L</"tex_escape()"> subroutine below).

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
L</"tex_escape()"> and L</"REase()">.

This option can also be changed dynamically in the template itself using global C<< %%%V:=esc= 0|1|~|... >> tag,
but
can be changed only if when calling C<replication()> for C<esc> option the priority is not specified C<< >1 >>,
e.g. C<< esc => 2... >>.


=item C<tile>

This option specifies the size (in characters) of the maximum 
uncut non-alphabetic sections in the range from 1 to C<< tile + 1 >>,
e.g.

  $msg = replication( $source, $info, esc => 'REase', tile => 2 );

By default, C<< tile = 3 >>.
C<tile> option has meaning if C<replication()> is called with C<REase>
in C<esc> or C<< _ACTIONS_ >> option.

Valid values for C<tile> are from 2 to 9.
For a description of C<tile>, see the section on L</"REase()">.


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

If a custom user subroutine is used in C<< _ACTIONS_ >> pipeline, it is important to return C<$mflag> value,
which then goes into the C<< _MFLAGS_ >> option and is needed for C<tex_escape()> and C<REase()> 
if they are called later in the pipeline.
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


=head2 tex_escape()

  my $mflag = tex_escape( $value [, $options ] );

Masks (or replaces with equivalents) the active 9 TeX characters: C<&>, C<%>, C<$>, C<#>, C<_>, C<{>, C<}>, C<^>, C<\>
with the corresponding: C<\&>, C<\%>, C<\$>, C<\#>, C<\_>, C<\{>, C<\}>, C<\^\/>, C<\char92\/> in the input C<$value>

With the facultative (optional) option C<~>, you can additionally replace 
the character C<~> with the corresponding C<\~\/>, e.g.:

  tex_escape( $value, '~');

C<$options> is optional and can be specified as a SCALAR or a HASH.
For example, C<$options> is a HASH:

  my $mflag = tex_escape( $value, {
                  esc => '~ hyphen; !stag -stag, +stag REase, strong,mutual',
                  tile => 4,
                  _MFLAGS_ => 0b0001,
                }
              );

For example, C<$options> is a SCALAR:

  my $mflag = tex_escape( $value, '~hyphen, REase !stag -stag +stag; strong mutual');

i.e. the SCALAR form of C<$options> allows passing additional options only as C<esc>.
Key separators in C<esc> option can be spaces, '_', and word boundaries.

=head3 hyphen

This option makes compound words with "active" hyphens, 
i.e. makes a replacement C<< ...abc-def... >> with C<< ...abc"=def... >>.

=head3 REase

includes an internal call to L</"REase()"> subroutine. (See below).


=head3 start tag C<%%%:>

If the C<$value> starts with the C<%%%:> tag, then this tag is removed
(e.g. C<$value = '%%%:$\frac{12345}{67890}$'> is converted to C<$value = '$\frac{12345}{67890}$'>),
and the value itself is not masked, it is skipped without changes.
By default (without additional C<< -stag >> option), only ONE 1st B<start tag> C<%%%:> is removed.
This means that the following start tags (stag) will remain untouched if they are set.

Three options (C<< !stag >>, C<< -stag >>, and C<< +stag >>) affect the action of the start tag (C<%%%:>):

=over 3

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


=head3 Re-masking active symbols

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

=over 3

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


=head3 return codes

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


=head2 REase()

  my $mflag = REase( $value [, $options ] );

"Cuts" ("splits") C<$value>, recognizing non-alphabetic sections in it 
(except for these characters: C<< . >>, C<< > >>, C<< < >>, C<< } >>, C<< { >>, C<'>, C<`>, C<">, C<< = >>, C<< _ >>, C<< - >>, 
and finally C<< \ >> character, a sequence of characters that TeX cannot break with ordinary word breaks) and
glues the "cut" sections together with stretchable "glue" (i.e., a "spring" --- C<< {\hskip0pt plus .02em} >>).

For example, this gibberish:

 my $value = '~$&,%,$,#,_,{,},^,\2qw\ea-sdf-124-590\\\\\\>>>>---1';
 my $mflag = REase( $value );

converts to a sequence (by default, C<< tile = 3 >>)

  '{\hskip0pt plus .02em}~$&,'.
  '{\hskip0pt plus .02em}%'.
  '{\hskip0pt plus .02em},$,#'.
  '{\hskip0pt plus .02em},'.
  '{\hskip0pt plus .02em}_,{'.
  '{\hskip0pt plus .02em},'.
  '{\hskip0pt plus .02em}},^'.
  '{\hskip0pt plus .02em},'.
  '{\hskip0pt plus .02em}\2'.
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

=head3 tile

Here, the main auxiliary option is C<tile>, which specifies the size (in characters) of the maximum 
uncut non-alphabetic sections in the range from 1 to C<< tile + 1 >>.
For example, for C<< tile = 5 >>, the sizes of uncut non-alphabetic sections will be 
from 1 to 6 characters, e.g.:

  $mflag = REase( $value, { tile => 5 } );

Valid values for C<tile> are from 2 to 9.

If the $value ends with TeX-command C<< \relax\/ >>, then the value itself is not modified, it is skipped.
C<< \relax\/ >> remains untouched at the end.

C<REase()> also depends on C<%%%:> start tag and the C<< !stag >>, C<< -stag >> options
(but not the C<< +stag >> option), similar to C<tex_escape()>.


=head3 return codes

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


=head2 AGLkit()

  my $agl = AGLkit( [ $options ] );

Returns a hash table that maps glyph names to a numeric character Unicode (in decimal (default) or hexadecimal format)
or the corresponding character equivalents for the glyphs defined by Adobe in what is known as 
the 'Adobe Glyph List' (AGL), contained in the well-known 'glyphlist.txt' file.
(see L<https://github.com/adobe-type-tools/agl-aglfn/blob/master/glyphlist.txt>)

By default (i.e., without any additional options), a hash is returned using the ISO-8859-1 character set (also known as ISO-Adobe),
supplemented by the 'Adobe Standard Cyrillic Glyph Names' character set, with character codes represented in B<decimal> format.
(see L<https://en.wikipedia.org/wiki/Adobe_Glyph_List> and
L<https://adobe-type-tools.github.io/font-tech-notes/pdfs/5013.Cyrillic_Font_Spec.pdf>).
For example:

  my $agl = AGLkit();
  say Dumper $agl;

Output a hash of 325 glyphs:

  $VAR1 = {
          'Atilde' => 195,
          'D' => 68,
          'afii10100' => 1107,
          'acute' => 180,
  ...
          'sterling' => 163,
          'Ucircumflex' => 219,
          'H' => 72,
          'R' => 82,
          'V' => 86
        };

This subroutine accepts a list of optional settings in the form of a hash C<$options>.
For example:

  my $options = { 
    glyphlist => 'glyphlist.txt', # glyph list file
    mate => 'symbol', # of Unicode | 'hex' Unicode number (native). By default, decimal Unicode number
  };

  $agl = AGLkit( $options );

Output:

  $VAR1 = {
          'ringhalfrightbelowcmb' => "\x{339}",
          'afii10831' => "\x{f6c7}",
          'thorn' => 'þ',
          'brokenbar' => '¦',
          'E' => 'E',
          'two' => '2',
          'exclam' => '!',
          'twosuperior' => '²',
...
        };


=head3 glyphlist

This option allows you to transfer a file containing glyphs and their corresponding Unicode character codes,
similar the well-known 'glyphlist.txt' file.
(see L<https://github.com/adobe-type-tools/agl-aglfn/blob/master/glyphlist.txt>).
E.g., in Debian (with the TeX Live system installed), the file you are looking for is located at the path
C</usr/share/texlive/texmf-dist/fonts/map/glyphlist/>

And the most reliable way to find a file is to use the C<kpsewhich> command in the terminal:

  $ kpsewhich glyphlist.txt

=head3 mate

This option allows you to specify which mapping to set for glyphs: Unicode C<'symbol'> or C<'hex'> Unicode number.
By default, B<decimal> Unicode number (for undefined C<mate>). For example:

  $agl = AGLkit( {mate =>'hex',} );

Output:

  $VAR1 = {
          'exclam' => '21',
          'twosuperior' => 'B2',
          'brokenbar' => 'A6',
          'E' => '45',
          'two' => '32',
          'thorn' => 'FE',
          'afii10831' => '439',
...
        };

Invalid glyph names and names beginning with a dot ('.'), are discarded.


=head2 font_metrics()

  my $font_metrics = font_metrics( $AFMfile [, $options ] );

This subroutine allows you to obtain information about a font and the metrics of various glyphs
within that font from an AFM (Adobe Font Metrics) file --- C<$AFMfile>. All measurements in AFM files are expressed 
in units equal to 1/1000 of the font's scale factor.

This subroutine accepts a list of optional settings in the form of a hash C<$options>.
For example:

  my $font_metrics = font_metrics('PTC55F.afm'); # to get the metrics of 'PT Sans Caption' font
  # or
  $font_metrics = font_metrics('PTC55F.afm', { glyphlist =>'glyphlist.txt',} );

  say Dumper $font_metrics;

Returns a hash containing three hashes: 'WX' -- character widths, 'Bbox' -- Bounding box information, and
'KPX' -- kerning pairs ash contains the kerning values for adjacent characters:

  $VAR1 = {
          'WX' => {
                    '118' => '535',
                    '1060' => '857',
  ...
                    '177' => '554',
                  },
          'Bbox' => {
                      '118' => '0 -11 535 525 ',
                      '1060' => '43 -20 813 720 ',
  ...
                      '177' => '43 168 511 699 ',
                    },
          'KPX' => {
                     '118' => {
                                '32' => '-36',
                                '382' => '-10',
  ...
                                '118' => '7',
                                '44' => '-72'
                              },
  ...
                     '1060' => {
                                 '62669' => '-16',
                                 '1199' => '-16',
  ...
                                 '8218' => '-31'
                               },
                   }
        };



=head3 glyphlist

This option is similar to the one in L</"AGLkit()"> subroutine (see above).

=head3 mate

This option is similar to the one in L</"AGLkit()"> subroutine (see above),
i.e. the allowed values are 'symbol', 'hex', and an additional 'glyph' of Adobe.
By default, decimal Unicode number (undefined C<mate>).

=head3 noBbox, noKPX

These options mean not to generate 'Bbox' and 'KPX' hashes respectively.


=head2 onecell()

  my( $cell ) = onecell( $string, $options );

This method places (lays out) a given plain-text C<$string> (i.e., a paragraph, with no TeX/LaTeX commands!
and no C<< \n >> characters) into a cell (or box) of a specified width, returning an array of lines or 
the number of lines occupied within the cell.

These lines, including their word breaks (in the form of TeX command 'C<< \- >>'), will largely correspond to 
their actual layout in a PDF document generated from them --- for instance, when using a LaTeX table environment
(such as 'C<tabular>' or 'C<longtable>') processed with the 'C<pdflatex>' command.

The formation of these lines (or more precisely, the hyphenation of words at the end of lines) is influenced by 
the 'C<hyphenation>' parameter, which results in two ways of arranging lines within a cell:
"compact" (A) and "natural" (B).

=over 3

=item (A)

If 'C<hyphenation>' is missing or 'C<action>' for hyphenating words of the language of the given text (C<$string>) are not specified,
then a case of the most compact packing of lines into a cell/box is formed, with the minimum possible number of hyphenations in words.
In PDF output, this is achieved by setting the 'C<\looseness>' parameter for a paragraph within a cell/box to B<-3> or lower
(e.g., C<\looseness=-4>, etc.).

=item (B)

If 'C<action>' (from modules such as L<Text::Hyphen>, L<Text::Hyphen::RU>, L<TeX::Hyphen>, etc. with C<hyphenate()> method), are specified in the 'C<hyphenation>' parameter
to handle word hyphenation for the languages present in the given text, the result will include natural, language-appropriate word breaks.
In this scenario, the number of hyphenated words is kept to a reasonable minimum; however, unlike in case (A), the total number of lines 
within a cell/box may increase by one or two. This depends on the width of the cell/box: the narrower (smaller) the width (e.g. option C<< cell_width < 10mm >>),
the more likely it is that the number of lines will exceed that of case (A).

If the strings obtained in case (B) are not used for PDF creation (via the 'C<pdflatex>' command) --- and the original text C<$string> is used
instead -- then the results from (B) will match the PDF output (in terms of word hyphenation and the number of lines within a cell) only
if the text language is correctly specified -- either for the entire document (in the preamble) or specifically for that cell (for instance,
by using the 'C<otherlanguage>' environment or commands such as 'C<\foreignlanguage{}{}>' and 'C<\selectlanguage{}>') --- and provided that
the hyphenation patterns used in both cases are identical.

=back

The following options are mandatory:

=head3 cell_width

Width of cell/box (pt).

=head3 font_metrics

Hash (table) of font metrics with 'C<WX>' (pairs of B<decimal> Unicode number to horizontal (X) width of a character),
and optional 'C<KPX>' -- Kern Pair X. This table can be obtained using  L</"font_metricst()"> subroutine with 
default parameters (see above).

The following parameters are optional:

=head3 base_font_size

Depending on the document's base font size (pt), e.g. 12pt (see \documentclass[...pt]).
By default, this value is 10 (i.e. 10pt).

=head3 font_size

TeX-font size of text in cell/box: 'tiny', 'scriptsize', 'footnotesize', 'small', 'normalsize', 'large', 'Large', 'LARGE', 'huge', and 'Huge'.
By default, this value is 'normalsize'.


=head3 space

Regular space between words (pt) -- fontdimen 2.
In LaTeX, you can determine the compressibility parameters for the space between words by accessing 
the font parameters (see above C<\fontdimen> 2)

You can output the current interword space parameters to the compilation log or directly onto the page using 
the C<\the\fontdimen> command:

  \documentclass{article}
  \begin{document}
    Regular whitespace (fontdimen 2): \the\fontdimen 2 \font\\
    Whitespace stretching (fontdimen 3): \the\fontdimen 3 \font\\
    Whitespace shrink (fontdimen 4): \the\fontdimen 4 \font
  \end{document}

If this parameter is not specified, the value of C<space> from the C<font_metrics> is used.

=head3 shrink

Space compressibility (pt) --- the extent to which a space can become narrower than its base value if the line is compressed (fontdimen 4).
A standard space in LaTeX is a flexible space (glue) and consists of three components: a normal width, a stretch component, 
and a shrink component. In LaTeX, you can determine the compressibility parameters for the space between words by accessing 
the font parameters (see above C<\fontdimen> 4).

By default, this value is 0.

=head3 merge

If C<< merge => 1 >> -- return a combined string (paragraph) and its total width (length) in (*100pt),
rather than an array of lines.

=head3 offset

Offset from the beginning of $str from which characters for cell are extracted.
By default, this value is 0.

=head3 limit

The maximum allowable number of lines for a cell.
By default, the number of lines is unlimited.

=head3 hyphenation

Array of methods which hyphenates words in specified languages,
e.g.:

  use Text::Hyphen;
  use Text::Hyphen::RU;

  my $hyp_en = new Text::Hyphen( min_word =>4);
  my $hyp_ru = new Text::Hyphen::RU( min_word =>4);

  my $hyphenation = [
         { name =>'en', action => $hyp_en, }, # English
       # OR
       # { msk => qr/[a-zA-Z]+/o, action => $hyp_en, },

         { name =>'ru', action => $hyp_ru, }, # Russian
       # OR
       #  { msk => qr/[а-яА-Я]+/o, action => $hyp_ru, },
      ];

The primary requirement for C<action> used for this C<hyphenation> option is that their interface must resemble that of L<Text::Hyphen> module;
specifically, when called in a list context, the object-oriented subroutine C<$hyp->hyphenate($word)> should break the C<$word> into parts at 
the hyphenation points and return a list of these parts.

It is also acceptable to use a regular function rather than an object-oriented subroutine C<$hyp->hyphenate($word)>,
provided that its interface matches the one specified above—that is, it must return a list of word fragments.

For C<name> key, two predefined values are currently permissible: B<'en'> (English) and B<'ru'> (Russian).

To typeset non-English and non-Russian texts, pass in a Text::Hyphen-like object which responds to the hyphenate method, 
returning a list of hyphen positions for that particular language (native Text::Hyphen defaults to American English hyphenation rules). 
See L<Text::Hyphen> for the interface.

For non-English and non-Russian languages, you need to use the C<msk> key, in which you specify a mask for identifying the language based on a C<$word>.

Examples #1:

  use utf8;
  use open ":std", ":encoding(utf8)";

  use LaTeX::Replicase qw(font_metrics onecell); # :all
  use Text::Hyphen;
  use Text::Hyphen::RU;
  use Data::Dumper;

  my $mm2pt = 2.845276; # 1mm ~= 2.845276pt
  my $cell_width = 30; # (mm)
  $cell_width *= $mm2pt; # (mm) to (pt)

  my $hyp_en = new Text::Hyphen( min_word =>4);
  my $hyp_ru = new Text::Hyphen::RU( min_word =>4);

  my $op = {
      cell_width => $cell_width, # width of cell/box, (pt)
      font_metrics => font_metrics('PTC55F.afm', { glyphlist => 'glyphlist.txt', noBbox =>1 }),
      base_font_size => 10, # depending on the document's base font size (pt), see \documentclass[...pt]
      # font_size => 'normalsize', # TeX-font size of text in cell/box
      space => 2.43, # Regular space between words (pt), see fontdimen 2
      shrink => 0.81, # whitespace shrink (pt), see fontdimen 4
      # merge => 1,
      # offset => 0,
      # limit => 25,
      hyphenation => [
         { name =>'en', action => $hyp_en, }, # English
       # OR
       # { msk => qr/[a-zA-Z]+/o, action => $hyp_en, },

         { name =>'ru', action => $hyp_ru, }, # Russian
       # OR
       #  { msk => qr/[а-яА-Я]+/o, action => $hyp_ru, },
      ],
  };

  my $string = "I was going to do something today but I haven't finished doing nothing from yesterday.
  Я собирался кое-что сделать сегодня, но еще не закончил ничегонеделание со вчерашнего дня    ";
  say 'size of string = ', length( $string );

  my $nLines = onecell( $string, $op );
  say "number of lines = $nLines";

  my( $cell ) = onecell( $string, $op );
  say Dumper $cell;

  $op->{merge} => 1;
  my( $cell ) = onecell( $string, $op );
  say Dumper $cell;

OUTPUT:

  size of string = 180
  number of lines = 12
  $VAR1 = {
          'lines' => [ # arrays of no empty lines
                       'I was going to do ',
                       'something today ',
                       'but I haven\'t fin\-',
                       'ished doing noth\-',
                       'ing from yes\-ter\-',
                       'day. Я собирался ',
                       'кое-что сделать ',
                       'сегодня, но еще ',
                       'не закончил ни\-',
                       'че\-го\-не\-де\-ла\-ние ',
                       'со вчерашнего ',
                       'дня'
                     ],
          'stop' => 176, # position in $string where the extraction of symbols into cell stopped
          'wxL' => [ # arrays of line widths (*100pt) for 'lines'
                     8106,
                     8247,
                     7530,
                     8171,
                     7243,
                     8257,
                     7901,
                     7882,
                     7490,
                     7692,
                     7423,
                     1826
                   ],
          'numL' => 12 # number of no empty lines
        };

  $VAR1 = {
          'wxL' => [
                     87768
                   ],
          'lines' => [
    "I was going to do something today but I haven't fin\\-ished doing noth\\-ing from yes\\-ter\\-day. Я собирался
      кое-что сделать сегодня, но еще не закончил ни\\-че\\-го\\-не\\-де\\-ла\\-ние со вчерашнего дня"
                     ],
          'numL' => 12,
          'stop' => 176
        };


The output hash contains the position in C<$string> where the extraction of symbols into cell stopped under 'C<stop>' key.
If all non-whitespace characters have been extracted from C<$string> and 'C<limit>' option is specified,
then C<stop = -1> is returned.

B<LIMITATIONS:>
The strings in 'lines' will have no leading spaces. The last string will have no trailing spaces.
Words in 'lines' will be separated by exactly ONE SPACE and may contain TeX hyphenation commands ('\-').


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

For LaTeX2e details see this unofficial reference manual:
L<https://tug.org/texinfohtml/latex2e.html>

For 'Adobe Glyph List' (ISO-8859-1 character set, also known as ISO-Adobe) see L<https://en.wikipedia.org/wiki/Adobe_Glyph_List>,
L<https://github.com/adobe-type-tools/agl-aglfn>

For 'Adobe Standard Cyrillic Glyph Names' character set see L<https://adobe-type-tools.github.io/font-tech-notes/pdfs/5013.Cyrillic_Font_Spec.pdf>

Perl modules that offer similar functionality:

L<Template::Latex>, L<LaTeX::Easy::Templates>,
L<PostScript::DecodeGlyphName>, L<Font::GlyphNames>,
L<Font::AFM>


=head1 SUPPORT AND BUGS

You can find documentation for this module with the perldoc command:

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
