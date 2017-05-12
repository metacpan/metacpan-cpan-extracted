# xxx need 'raw' format, like plain but no wrap for resolve mode
# xxx or need 'granvl' format, like anvl but no wrap for resolve mode?
# xxx need 'null' format, to do ...?

package File::OM;

use 5.006;
use strict;
use warnings;

our $VERSION;
$VERSION = sprintf "%d.%02d", q$Name: Release-1-05 $ =~ /Release-(\d+)-(\d+)/;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw();

our @EXPORT_OK = qw();

our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

use Text::Wrap;		# which recommends localizing next two settings
			# local $Text::Wrap::columns = $self->{wrap};
			# local $Text::Wrap::huge = 'overflow';

our %outputformats = (
	anvl	=> 'ANVL',
	csv	=> 'CSV',
	json	=> 'JSON',
	plain	=> 'Plain',
	psv	=> 'PSV',
	turtle	=> 'Turtle',
	xml	=> 'XML',
);

sub listformats {
	return map $outputformats{$_}, sort keys %outputformats;
}

sub om_opt_defaults { return {

	anvl_mode	=>	# which flavor, eg, ANVL, ANVLR, ANVLS
		'ANVL',		# vanilla (unused for now)
	elemsref	=> [],	# one array to store record elements
	indent_start	=> '',	# overall starting indent
	indent_step	=>	# how much to increment/decrement indent
		'  ',		# for XML, JSON
	outhandle	=> '',	# return string by default
	turtle_indent	=>	# turtle has one indent width
		'    ',
	turtle_predns	=>	# turtle predicate namespaces
		'http://purl.org/kernel/elements/1.1/',
	turtle_nosubject =>	# a default subject
		'default',	# XXX not a URI -- what should this be?
	turtle_subjelpat =>	# pattern for matching a subject element
		'',
	turtle_stream_prefix => # symbol we use for turtle
		'erc',
	xml_stream_name	=>	# for XML output, stream tag
		'recs',
	xml_record_name	=>	# for XML output, record tag
		'rec',
	wrap		=> 72,	# at which column to wrap elements (0=nowrap)
	wrap_indent	=> '',	# current indent for wrap, but "\t" for ANVL
				# xxx is this even used?
	verbose		=> 0,	# more output (default less)

	# The following keys are maintained internally.
	#
	elemnum		=> 0,	# current element number
	indent		=> '',	# current ident
	recnum		=> 0,	# current record number
	record_is_open	=> 0,	# whether a record is open
	stream_is_open	=> 0,	# whether a stream is open
	};
}

sub new {
	my $class = shift || '';	# XXX undefined depending on how called
	my $self = om_opt_defaults();
	my $format = lc (shift || '');
	if ($format) {
		$format = $outputformats{$format};	# canonical name
		$format		or return undef;
		$class = "File::OM::$format";
	}
	else {					# if no format given, expect
		$class =~ /^File::OM::\S/	# to be called from subclass
			or return undef;
	}
	bless $self, $class;

	my $options = shift;
	my ($key, $value);
	$self->{$key} = $value
		while ($key, $value) = each %$options;

	return $self;
}

# xxxx should refactor subclass methodes to more generic SUPER methods
#      there's lots of repeated code

sub DESTROY {
	my $self = shift;
	my ($s, $z) = ('', '');		# built string and catchup string
	$self->{stream_is_open} and	# wrap up any loose ends
		$z = $self->cstream();	# which calls crec()
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub elems {
	# XXX why do 4 bytes (instead of 2) show up in wget??
	# # %-encode any chars that need it
	# my $except_re = qr/([\001-\037\177-\377])/; XXX needed any more?
	# $s =~ s/$except_re/ "%" . join("", unpack("H2", $1)) /ge;

	my $self = shift;
	my $sequence = '';
	my ($name, $value);
	while (1) {
		($name, $value) = (shift, shift);	# next arg pair
		last	unless $name or $value;		# done if null
		$sequence .= $self->elem($name, $value);
	}
	return $sequence;
}

# Shared routine to construct a header ordering based on the record
# in the given element array.  Used by CSV and PSV formats.
#
sub rec2hdr { my( $r_elems )			= (shift);

	my ($n, $nmax) = (0, scalar @$r_elems);
	my $r_elem_order = [ ];		# create an array reference

	for ($n = 0; $n < $nmax; $n += 3) {

		$n > 0 and	# normal element case
			push(@$r_elem_order, $$r_elems[$n + 1]),
			next;

		# If we get here, $n == 0 (record start).  If the record
		# starts with a label-less value, use '_' as the name.
		#
		$$r_elems[$n + 2] and
			push(@$r_elem_order, '_'),
	}
	return $r_elem_order;
}

# Called in place of TextWrap::Wrap::wrap, returns string without wrapping.
# Second arg is a dummy.
#
sub text_nowrap { my( $line1ind, $line2ind, $val)=(shift, shift, shift);
		return $line1ind . $val;
}

package File::OM::ANVL;

our @ISA = ('File::OM');

sub elem {	# OM::ANVL
	my $self = shift;
	my ($name, $value, $lineno, $elemnum) = (shift, shift, shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{record_is_open} or	# call orec() to open record first
		($z =  $self->orec(undef, $lineno),	# may call ostream()
		$self->{record_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status

	defined($elemnum) and
		$self->{elemnum} = $elemnum
	or
		$self->{elemnum}++;

	# Parse $lineno, which is empty or has form LinenumType, where
	# Type is either ':' (real element) or '#' (comment).
	defined($lineno)	or $lineno = '1:';
	my ($num, $type) =
		$lineno =~ /^(\d*)\s*(.)/;

	local ($Text::Wrap::columns, $Text::Wrap::huge, $Text::Wrap::unexapand);
	my $wrapper;
	$self->{wrap} and
		($wrapper, $Text::Wrap::columns, $Text::Wrap::huge,
			$Text::Wrap::unexpand) =
		(\&Text::Wrap::wrap, $self->{wrap}, 'overflow', 0)
	or
		$wrapper = \&File::OM::text_nowrap;
	;

	if ($type eq '#') {
		$self->{element_name} = undef;	# indicates comment
		$self->{elemnum}--;		# doesn't count as an element
		#$s .= Text::Wrap::wrap(		# wrap lines with '#' as
		$s .= &$wrapper(		# wrap lines with '#' as
			'#',			# first line "indent" and
			'# ',			# '# ' for all other indents
			$self->comment_encode($value)	# main part to wrap
		);
		$s .= "\n";			# close comment
	}
# XXX what if ref($value) eq "ARRAY" -> can be used for repeated vals?
# XXX does undefined $name mean comment?
# XXX document what undef for $name means
	elsif (defined $name) {			# no element if no name
	# XXX would it look cooler with :\t after the label??
		# xxx this should be stacked
		$self->{element_name} = $self->name_encode($name);
		my $enc_val = $self->value_encode($value);	# encoded value

		$s .= $enc_val =~ /^\s*$/ ?		# wrap() loses label of
			"$self->{element_name}:$enc_val" :	# blank value
			&$wrapper(			# wrap lines; this 1st
				$self->{element_name}	# "indent" won't break
					. ':',		# label across lines
				"\t",			# tab for other indents
				$enc_val)		# main part to wrap
		;
		$s .= "\n";
		# M_ELEMENT and C_ELEMENT would start here
	}
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

# XXX need something that will spit out whole input ANVL record
sub anvl_rec {	# OM::ANVL
	my $self = shift;
	my $rec = shift;
# XXX ignore lineno for now
	my ($name, $value, $lineno, $elemnum) = (shift, shift, shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{record_is_open} or	# call orec() to open record first
		($z =  $self->orec(undef, $lineno),	# may call ostream()
		$self->{record_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status

	#defined($elemnum) and
	#	$self->{elemnum} = $elemnum
	#or
	#	$self->{elemnum}++;

	# Parse $lineno, which is empty or has form LinenumType, where
	# Type is either ':' (real element) or '#' (comment).
	defined($lineno)	or $lineno = '1:';
	my ($num, $type) =
		$lineno =~ /^(\d*)\s*(.)/;

	local ($Text::Wrap::columns, $Text::Wrap::huge);
	my $wrapper;
	$self->{wrap} and
		($wrapper, $Text::Wrap::columns, $Text::Wrap::huge) =
			(\&Text::Wrap::wrap, $self->{wrap}, 'overflow')
	or
		$wrapper = \&File::OM::text_nowrap;
	;


	if ($type eq '#') {
		$self->{element_name} = undef;	# indicates comment
		$self->{elemnum}--;		# doesn't count as an element
		#$s .= Text::Wrap::wrap(		# wrap lines with '#' as
		$s .= &$wrapper(		# wrap lines with '#' as
			'#',			# first line "indent" and
			'# ',			# '# ' for all other indents
			$self->comment_encode($value)	# main part to wrap
		);
		$s .= "\n";			# close comment
	}
# XXX what if ref($value) eq "ARRAY" -> can be used for repeated vals?
# XXX does undefined $name mean comment?
# XXX document what undef for $name means
	elsif (defined $name) {			# no element if no name
	# XXX would it look cooler with :\t after the label??
		# xxx this should be stacked
		$self->{element_name} = $self->name_encode($name);
		my $enc_val = $self->value_encode($value);	# encoded value
		$s .= $enc_val =~ /^\s*$/ ?		# wrap() loses label of
			"$self->{element_name}:$enc_val" :	# blank value
			&$wrapper(			# wrap lines; this 1st
				$self->{element_name}	# "indent" won't break
					. ':',		# label across lines
				"\t",			# tab for other indents
				$enc_val)		# main part to wrap
		;
		$s .= "\n";
		# M_ELEMENT and C_ELEMENT would start here
	}
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub orec {	# OM::ANVL
	my $self = shift;
	my ($recnum, $lineno) = (shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{elemnum} = 0;
	$self->{stream_is_open} or	# call ostream() to open stream first
		($z = $self->ostream(),
		$self->{stream_is_open} = 1);
	$self->{record_is_open} = 1;
	$self->{outhandle}	or $s .= $z;	# don't retain print status

	defined($recnum) and
		$self->{recnum} = $recnum
	or
		$self->{recnum}++;

	defined($lineno)	or $lineno = '1:';
	# xxxx really? will someone pass that in?

	$self->{verbose} and
		$s .= "# from record $self->{recnum}, line $lineno\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub crec {	# OM::ANVL
	my ($self, $recnum) = (shift, shift);
	$self->{record_is_open} = 0;
	my $s = "\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

# xxx anvl -m anvln? n=normalized?
sub ostream {	# OM::ANVL
	my $self = shift;

	$self->{recnum} = 0;
	$self->{stream_is_open} = 1;
	my $s = '';
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub cstream {	# OM::ANVL
	my $self = shift;
	my ($s, $z) = ('', '');		# built string and catchup string
	$self->{record_is_open} and	# wrap up any loose ends
		$z = $self->crec();
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{stream_is_open} = 0;
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub name_encode {	# OM::ANVL
	my ($self, $s) = (shift, shift);
	defined($s)		or return '';
	#$s =~ s/^\s+//;
	#$s =~ s/\s+$//;		# trim both ends
	#$s =~ s/\s+/ /g;	# squeeze multiple \s to one space
# xxx keep doubling %?
	$s =~ s/%/%%/g;		# to preserve literal %, double it
# xxx what about granvl?
				# yyy must be decoded by receiver
	#$s =~ s/:/%3a/g;	# URL-encode all colons (%cn)

	$s =~ s{		# URL-encode all colons and whitespace
		([=:<\s])	# \s matches [ \t\n\f] etc.
	}{			# = and < anticipate ANVL extensions
		sprintf("%%%02x", ord($1))	# replacement hex code
	}xeg;

	# This next line takes care of the mainstream case of names that
	# contain spaces.  It makes sure that for every run of one or more
	# spaces, the first space won't be encoded.
	#
	$s =~ s/%20((?:%20)*)/ $1/g;
	$s =~ s/^ /%20/;	# but make sure any initial space is encoded
	$s =~ s/ $/%20/;	# and make sure any final space is encoded

	return $s;

	# XXXX must convert XML namespaces to make safe for ANVL
	# foo:bar ->? bar.foo (sort friendly, and puts namespace into
	#     proper subordinate position similar to dictionaries)?
	#     or if not namespace, foo:bar ->? foo%xxbar
}

# Encoding of names and values is done upon output in ANVL.
# Default is to wrap long lines.

sub value_encode {	# OM::ANVL
	my ($self, $s, $anvl_mode) = (shift, shift, shift);
	defined($s)		or return '';
	$anvl_mode ||= 'ANVL';

	my $value = $s;			# save original value
	#my ($initial_newlines) =	# save initial newlines
	#	$s =~ /^(\n*)/;		# always defined, often ""

	## value after colon starts with either preserved newlines,
	#	a space, or, if value is "" (as opposed to 0), nothing
	#
	#my $value_start = $initial_newlines || ($value eq "" ? '' : ' ');
	#my $value_start = $initial_newlines || ($value eq "" ? '' : ' ');
	my $value_start = $value eq "" ? '' : ' ';

	#my $value_start = $initial_newlines || ($value ? ' ' : '');
	# xxxx is this the right place to enforce the space after ':'?

	# xxx is there a linear whitespace char class??
	#     problem is that \s includes \n
	#$s =~ s/^\s+//;
	#$s =~ s/\s+$//;		# trim both ends

	$s =~ s/%/%%/g;		# to preserve literal %, double it
				# yyy must be decoded by receiver
	$s =~ s{		# URL-encode newlines in portable way
		(\n)		# \n matches all platforms' ends of lines
	}{			#
		sprintf("%%%02x", ord($1))	# replacement hex code
	}xeg;
	if ($anvl_mode eq 'ANVLS') {
		$s =~ s/\|/%7c/g;	# URL-encode all vertical bars (%vb)
		$s =~ s/;/%3b/g;	# URL-encode all semi-colons (%sc)
		# XXX what about others, such as (:...) (=...)
	};
	return $value_start . $s;
}

sub comment_encode {	# OM::ANVL
	my ($self, $s) = (shift, shift);
	defined($s)	or return '';
	$s =~ s/\n/\\n/g;			# escape \n  yyy??
	return $s;
}

package File::OM::CSV;

our @ISA = ('File::OM');

sub elem {	# OM::CSV
	my $self = shift;
	my ($name, $value, $lineno, $elemnum) = (shift, shift, shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{record_is_open} or	# call orec() to open record first
		($z =  $self->orec(undef, $lineno),	# may call ostream()
		$self->{record_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status

	defined($elemnum) and
		$self->{elemnum} = $elemnum
	or
		$self->{elemnum}++;

	# Parse $lineno, which is empty or has form LinenumType, where
	# Type is either ':' (real element) or '#' (comment).
	defined($lineno)	or $lineno = '1:';
	my ($num, $type) =
		$lineno =~ /^(\d*)\s*(.)/;

	local ($Text::Wrap::columns, $Text::Wrap::huge);
	my $wrapper;
	$self->{wrap} and
		($wrapper, $Text::Wrap::columns, $Text::Wrap::huge) =
			(\&Text::Wrap::wrap, $self->{wrap}, 'overflow')
	or
		$wrapper = \&File::OM::text_nowrap;
	;


	$self->{elemnum} > 1 and	# we've output an element already,
		$s .= ",";		# so output a separator character

	if ($type eq '#') {
		$self->{element_name} = undef;	# indicates comment
		$s .= &$wrapper(		# wrap lines with '#' as
			'#',			# first line "indent" and
			'# ',			# '# ' for all other indents
			$self->comment_encode($value)	# main part to wrap
		);
	}
	elsif (defined $name) {			# no element if no name
		# xxx this should be stacked
		$self->{element_name} = $self->name_encode($name);
		my $enc_val = 
		$s .= &$wrapper('', '',
			$self->value_encode($value));	# encoded value
		# M_ELEMENT and C_ELEMENT would start here
	}
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub orec {	# OM::CSV
	my $self = shift;
	my ($recnum, $lineno) = (shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{elemnum} = 0;
	$self->{stream_is_open} or	# call ostream() to open stream first
		($z = $self->ostream(),
		$self->{stream_is_open} = 1);
	$self->{record_is_open} = 1;
	$self->{outhandle}	or $s .= $z;	# don't retain print status

	defined($recnum) and
		$self->{recnum} = $recnum
	or
		$self->{recnum}++;

	defined($lineno)	or $lineno = '1:';
	# xxxx really? will someone pass that in?

	if ($self->{recnum} == 1) {

		# We're one of the few orec's that use these args.
		# We do it only to output and possibly define headers.
		#
		my ($r_elems, $r_elem_order) = (shift, shift);

		# If the number and order of elements are not defined,
		# construct them from the ordering implied by record 1.
		#
		$r_elem_order or
			$r_elem_order = File::OM::rec2hdr($r_elems);

		# We're at record 1 in a CVS file, so output a header.
		#
		$s .= join(",", map(name_encode($self, $_), @$r_elem_order))
			. "\n";
	}

	$self->{verbose} and
		$s .= "# from record $self->{recnum}, line $lineno\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub crec {	# OM::CSV
	my ($self, $recnum) = (shift, shift);
	$self->{record_is_open} = 0;
	my $s = "\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub ostream {	# OM::CSV
	my $self = shift;

	$self->{recnum} = 0;
	$self->{stream_is_open} = 1;
	my $s = '';
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub cstream {	# OM::CSV
	my $self = shift;
	my ($s, $z) = ('', '');		# built string and catchup string
	$self->{record_is_open} and	# wrap up any loose ends
		$z = $self->crec();
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{stream_is_open} = 0;
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub name_encode {	# OM::CSV
	# CSV names used only in header line
	my ($self, $s) = (shift, shift);
	defined($s)		or return '';

	# yyy should names be put inside double quotes?
	#$s =~ s/^\s+//;
	#$s =~ s/\s+$//;		# trim both ends
	#$s =~ s/\s+/ /g;	# squeeze multiple \s to one space
	$s =~ s/"/""/g;		# double all internal double-quotes

	return $s;
}

sub value_encode {	# OM::CSV
	my ($self, $s) = (shift, shift);
	defined($s)		or return '';

	$s =~ s/"/""/g;		# double all internal double-quotes
	$s =~ s/^/"/;
	$s =~ s/$/"/;
	#$s =~ s/^\s*/"/;
	#$s =~ s/\s*$/"/;	# trim both ends and double-quote

	return $s;
}

sub comment_encode {	# OM::CSV
	# in CSV this would be a pseudo-comment
	my ($self, $s) = (shift, shift);
	defined($s)		or return '';

	$s =~ s/"/""/g;		# double all internal double-quotes
	$s =~ s/^/"/;
	$s =~ s/$/"/;
	#$s =~ s/^\s*/"/;
	#$s =~ s/\s*$/"/;	# trim both ends and double-quote

	return $s;
}

package File::OM::JSON;

our @ISA = ('File::OM');

sub elem {	# OM::JSON
	my $self = shift;
	my ($name, $value, $lineno, $elemnum) = (shift, shift, shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{record_is_open} or	# call orec() to open record first
		($z = $self->orec(undef, $lineno),	# may call ostream()
		$self->{record_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status

	defined($elemnum) and
		$self->{elemnum} = $elemnum
	or
		$self->{elemnum}++;

	# Parse $lineno, which is empty or has form LinenumType, where
	# Type is either ':' (real element) or '#' (comment).
	defined($lineno)	or $lineno = '1:';
	my ($num, $type) =
		$lineno =~ /^(\d*)\s*(.)/;

	$type eq '#'		and $name = '#';	# JSON pseudo-comment!
	$type eq '#'	and $self->{elemnum}--;		# doesn't count as elem
	if (defined $name) {				# no element if no name
		$self->{element_name} = $self->name_encode($name);
		# either real element or pseudo-comment element was used
		$self->{elemnum} > 1 || $self->{verbose} and
			$s .= ',';
		$s .= "\n" . $self->{indent};
		$s .= '"' . $self->{element_name} . '": "'
			. $self->value_encode($value) . '"';
	}
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub orec {	# OM::JSON
	my $self = shift;
	my ($recnum, $lineno) = (shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{elemnum} = 0;
	$self->{stream_is_open} or	# call ostream() to open stream first
		($z = $self->ostream(),
		$self->{stream_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{record_is_open} = 1;

	defined($recnum) and
		$self->{recnum} = $recnum
	or
		$self->{recnum}++;

	defined($lineno)	or $lineno = '1:';
	# yyy really? will someone pass that in?

	$self->{recnum} > 1		and $s .= ',';
	$s .= "\n" . $self->{indent} . '{';		# use indent and
	$self->{verbose} and
		$s .= qq@ "#": "from record $self->{recnum}, line $lineno"@;
	$self->{indent} =~ s/$/$self->{indent_step}/;	# increase indent
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub crec {	# OM::JSON
	my ($self, $recnum) = (shift, shift);
	$self->{record_is_open} = 0;
	$self->{indent} =~ s/$self->{indent_step}$//;	# decrease indent
	my $s = "\n" . $self->{indent} . '}';		# and use indent
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub ostream {	# OM::JSON
	my $self = shift;

	$self->{recnum} = 0;
	$self->{stream_is_open} = 1;
	$self->{indent_step} ||= '  ';		# standard indent width
	$self->{indent} = $self->{indent_step};		# current indent width
	my $s = '[';
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub cstream {	# OM::JSON
	my $self = shift;
	my ($s, $z) = ('', '');		# built string and catchup string
	$self->{record_is_open} and	# wrap up any loose ends
		$z = $self->crec();
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{stream_is_open} = 0;
	$self->{indent} =~ s/$self->{indent_step}$//;	# decrease indent
	$s .= "\n]\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub name_encode {	# OM::JSON
	my ($self, $s) = (shift, shift);
	defined($s)	or return '';
	$s =~ s/(["\\])/\\$1/g;			# excape " and \
	$s =~ s{
		([\x00-\x1f])			# escape all control chars
	}{
		sprintf("\\u00%02x", ord($1))	# replacement hex code
	}xeg;
	return $s;
}

sub value_encode {	# OM::JSON
	my $self = shift;
	return $self->name_encode(@_);
}

sub comment_encode {	# OM::JSON
	my $self = shift;
	return $self->name_encode(@_);
}

package File::OM::Plain;

our @ISA = ('File::OM');

sub elem {	# OM::Plain
	my $self = shift;
	my ($name, $value, $lineno, $elemnum) = (shift, shift, shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{record_is_open} or	# call orec() to open record first
		($z =  $self->orec(undef, $lineno),	# may call ostream()
		$self->{record_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status

	defined($elemnum) and
		$self->{elemnum} = $elemnum
	or
		$self->{elemnum}++;

	# Parse $lineno, which is empty or has form LinenumType, where
	# Type is either ':' (real element) or '#' (comment).
	defined($lineno)	or $lineno = '1:';
	my ($num, $type) =
		$lineno =~ /^(\d*)\s*(.)/;

	local ($Text::Wrap::columns, $Text::Wrap::huge);
	my $wrapper;
	$self->{wrap} and
		($wrapper, $Text::Wrap::columns, $Text::Wrap::huge) =
			(\&Text::Wrap::wrap, $self->{wrap}, 'overflow')
	or
		$wrapper = \&File::OM::text_nowrap;
	;

	if ($type eq '#') {			# Plain pseudo-comment!
		$self->{element_name} = undef;	# indicates comment
		$self->{elemnum}--;		# doesn't count as an element
		$s .= &$wrapper(		# wrap lines with '#' as
			'#',			# first line "indent" and
			'# ',			# '# ' for all other indents
			$self->comment_encode($value)	# main part to wrap
		);
		$s .= "\n";			# close comment
	}
	elsif (defined($value) and defined($name)) {	# no element if no name
		# It is a feature of Plain not to print if value is empty.
		$self->{element_name} = $self->name_encode($name);
		$s .= &$wrapper(		# wrap lines with '' as
			'',			# first line "indent" and
			'',			# '' for all other indents
			$self->value_encode($value)	# main part to wrap
		);
		$s .= "\n";
	}
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub orec {	# OM::Plain
	my $self = shift;
	my ($recnum, $lineno) = (shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{elemnum} = 0;
	$self->{stream_is_open} or	# call ostream() to open stream first
		($z = $self->ostream(),
		$self->{stream_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{record_is_open} = 1;

	defined($recnum) and
		$self->{recnum} = $recnum
	or
		$self->{recnum}++;

	defined($lineno)	or $lineno = '1:';

	$self->{verbose} and
		$s .= "# from record $recnum, line $lineno\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub crec {	# OM::Plain
	my ($self, $recnum) = (shift, shift);
	$self->{record_is_open} = 0;
	my $s = "\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub ostream {	# OM::Plain
	my $self = shift;
	my $s = '';

	$self->{recnum} = 0;
	$self->{stream_is_open} = 1;
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
	#$$o{indent_step} ||= '';		# standard indent width
	#$$o{indent} = $$o{indent_step};		# current indent width
}

sub cstream {	# OM::Plain
	my $self = shift;
	my ($s, $z) = ('', '');		# built string and catchup string
	$self->{record_is_open} and	# wrap up any loose ends
		$z = $self->crec();
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{stream_is_open} = 0;
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub name_encode {	# OM::Plain
	my ($self, $s) = (shift, shift);
	return $s;
}

sub value_encode {	# OM::Plain
	my ($self, $s) = (shift, shift);
	return $s;
}

sub comment_encode {	# OM::Plain
	my ($self, $s) = (shift, shift);
	return $s;
}

# XXXXXXXXXX just a copy of CSV for now
package File::OM::PSV;

our @ISA = ('File::OM');

sub elem {	# OM::PSV
	my $self = shift;
	my ($name, $value, $lineno, $elemnum) = (shift, shift, shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{record_is_open} or	# call orec() to open record first
		($z =  $self->orec(undef, $lineno),	# may call ostream()
		$self->{record_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status

	defined($elemnum) and
		$self->{elemnum} = $elemnum
	or
		$self->{elemnum}++;

	# Parse $lineno, which is empty or has form LinenumType, where
	# Type is either ':' (real element) or '#' (comment).
	defined($lineno)	or $lineno = '1:';
	my ($num, $type) =
		$lineno =~ /^(\d*)\s*(.)/;

	local ($Text::Wrap::columns, $Text::Wrap::huge);
	my $wrapper;
	$self->{wrap} and
		($wrapper, $Text::Wrap::columns, $Text::Wrap::huge) =
			(\&Text::Wrap::wrap, $self->{wrap}, 'overflow')
	or
		$wrapper = \&File::OM::text_nowrap;
	;


	$self->{elemnum} > 1 and	# we've output an element already,
		$s .= "|";		# so output a separator character

	if ($type eq '#') {
		$self->{element_name} = undef;	# indicates comment
		$s .= &$wrapper(		# wrap lines with '#' as
			'#',			# first line "indent" and
			'# ',			# '# ' for all other indents
			$self->comment_encode($value)	# main part to wrap
		);
	}
	elsif (defined $name) {			# no element if no name
		# xxx this should be stacked
		$self->{element_name} = $self->name_encode($name);
		my $enc_val = 
		$s .= &$wrapper('', '',
			$self->value_encode($value));	# encoded value
		# M_ELEMENT and C_ELEMENT would start here
	}
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub orec {	# OM::PSV
	my $self = shift;
	my ($recnum, $lineno) = (shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{elemnum} = 0;
	$self->{stream_is_open} or	# call ostream() to open stream first
		($z = $self->ostream(),
		$self->{stream_is_open} = 1);
	$self->{record_is_open} = 1;
	$self->{outhandle}	or $s .= $z;	# don't retain print status

	defined($recnum) and
		$self->{recnum} = $recnum
	or
		$self->{recnum}++;

	defined($lineno)	or $lineno = '1:';
	# xxxx really? will someone pass that in?

	if ($self->{recnum} == 1) {

		# We're one of the few orec's that use these args.
		# We do it only to output and possibly define headers.
		#
		my ($r_elems, $r_elem_order) = (shift, shift);

		# If the number and order of elements are not defined,
		# construct them from the ordering implied by record 1.
		#
		$r_elem_order or
			$r_elem_order = File::OM::rec2hdr($r_elems);

		# We're at record 1 in a CVS file, so output a header.
		#
		$s .= join("|", map(name_encode($self, $_), @$r_elem_order))
			. "\n";
	}

	$self->{verbose} and
		$s .= "# from record $self->{recnum}, line $lineno\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub crec {	# OM::PSV
	my ($self, $recnum) = (shift, shift);
	$self->{record_is_open} = 0;
	my $s = "\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub ostream {	# OM::PSV
	my $self = shift;

	$self->{recnum} = 0;
	$self->{stream_is_open} = 1;
	my $s = '';
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub cstream {	# OM::PSV
	my $self = shift;
	my ($s, $z) = ('', '');		# built string and catchup string
	$self->{record_is_open} and	# wrap up any loose ends
		$z = $self->crec();
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{stream_is_open} = 0;
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub name_encode {	# OM::PSV
	# PSV names used only in header line
	my ($self, $s) = (shift, shift);
	defined($s)		or return '';

	# xxx document how we don't trim, but encode spaces
	# xxxxxxx and then encode!!
	#$s =~ s/^\s+//;
	#$s =~ s/\s+$//;		# trim both ends
	#$s =~ s/\s+/ /g;	# squeeze multiple \s to one space
	$s =~ s/%/%%/g;		# to preserve literal %, double it
				# yyy must be decoded by receiver
	$s =~ s/\|/%7c/g;	# URL-encode all colons
	$s =~ s/\n/%0a/g;	# URL-encode all newlines

	return $s;
}

sub value_encode {	# OM::PSV
	my ($self, $s) = (shift, shift);
	defined($s)		or return '';

	# xxx document how we don't trim, but encode spaces
	# xxxxxxx and then encode!!
	#$s =~ s/^\s+//;
	#$s =~ s/\s+$//;		# trim both ends
	#$s =~ s/\s+/ /g;	# squeeze multiple \s to one space
	$s =~ s/%/%%/g;		# to preserve literal %, double it
				# yyy must be decoded by receiver
	$s =~ s/\|/%7c/g;	# URL-encode all colons
	$s =~ s/\n/%0a/g;	# URL-encode all newlines

	return $s;
}

sub comment_encode {	# OM::PSV
	# in PSV this would be a pseudo-comment
	my ($self, $s) = (shift, shift);
	defined($s)		or return '';

	$s =~ s/%/%%/g;		# to preserve literal %, double it
				# yyy must be decoded by receiver
	$s =~ s/\|/%7c/g;	# URL-encode all colons
	$s =~ s/\n/%0a/g;	# URL-encode all newlines

	return $s;
}

package File::OM::Turtle;

our @ISA = ('File::OM');

sub elem {	# OM::Turtle

	my $self = shift;
	my ($name, $value, $lineno, $elemnum) = (shift, shift, shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{record_is_open} or	# call orec() to open record first
		($z =  $self->orec(undef, $lineno),	# may call ostream()
		$self->{record_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status

	defined($elemnum) and
		$self->{elemnum} = $elemnum
	or
		$self->{elemnum}++;

	# Parse $lineno, which is empty or has form LinenumType, where
	# Type is either ':' (real element) or '#' (comment).
	defined($lineno)	or $lineno = '1:';
	my ($num, $type) =
		$lineno =~ /^(\d*)\s*(.)/;

	if ($type eq '#') {
		$self->{element_name} = undef;	# indicates comment
		$self->{elemnum}--;		# doesn't count as an element
		$s .= "\n#" . $self->comment_encode($value) . "\n";
		#
		# To create syntactically correct Turtle, we need
		# to end a comment with a newline at the end; this
		# can, however, result in ugly Turtle, since the
		# ';' or '.' that ends an element will have to
		# follow on the next line after that, and the only
		# remedy is to peek ahead at the next element.
	}
	elsif (defined $name) {			# no element if no name
		$self->{element_name} = $self->name_encode($name);
		$self->{elemnum} > 1		and $s .= ' ;';
		$s .= "\n" . $self->{turtle_indent};
		$s .= $self->{turtle_stream_prefix}
			. ":$self->{element_name} "
			. '"""'
			. $self->value_encode($value)
			. '"""';
	}
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub orec {	# OM::Turtle
	my $self = shift;
	my ($recnum, $lineno) = (shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{elemnum} = 0;
	$self->{stream_is_open} or	# call ostream() to open stream first
		($z = $self->ostream(),
		$self->{stream_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{record_is_open} = 1;

	defined($recnum) and
		$self->{recnum} = $recnum
	or
		$self->{recnum}++;

	defined($lineno)	or $lineno = '1:';

	$self->{verbose} and
		$s .= "# from record $recnum, line $lineno\n";
	defined($self->{subject}) or
		$self->{subject} = $self->{turtle_nosubject};
	$s .= "<$self->{subject}>";

	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub crec {	# OM::Turtle
	my ($self, $recnum) = (shift, shift);
	$self->{record_is_open} = 0;
	my $s = " .\n\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub ostream {	# OM::Turtle
	my $self = shift;
	my $s = '';;

	$self->{recnum} = 0;
	$self->{stream_is_open} = 1;
	# add the Turtle preamble
	$s .= "\@prefix $self->{turtle_stream_prefix}: <"
		. $self->{turtle_predns} .  "> .\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub cstream {	# OM::Turtle
	my $self = shift;
	my ($s, $z) = ('', '');		# built string and catchup string
	$self->{record_is_open} and	# wrap up any loose ends
		$z = $self->crec();
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{stream_is_open} = 0;
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub name_encode {	# OM::Turtle
	my ($self, $s) = (shift, shift);
	defined($s)	or return '';
	$s =~ s/(["\\])/\\$1/g;
	return $s;
	# \" \\
}

sub value_encode {	# OM::Turtle
	my ($self, $s) = (shift, shift);
	defined($s)	or return '';
	$s =~ s/(["\\])/\\$1/g;
	return $s;
}

sub comment_encode {	# OM::Turtle
	my ($self, $s) = (shift, shift);
	defined($s)	or return '';
	$s =~ s/\n/\\n/g;			# escape \n
	return $s;
}

package File::OM::XML;

our @ISA = ('File::OM');

sub elem {	# OM::XML
	my $self = shift;
	my ($name, $value, $lineno, $elemnum) = (shift, shift, shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{record_is_open} or	# call orec() to open record first
		($z = $self->orec(undef, $lineno),	# may call ostream()
		$self->{record_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status

	defined($elemnum) and
		$self->{elemnum} = $elemnum
	or
		$self->{elemnum}++;

	# Parse $lineno, which is empty or has form LinenumType, where
	# Type is either ':' (real element) or '#' (comment).
	defined($lineno)	or $lineno = '1:';
	my ($num, $type) =
		$lineno =~ /^(\d*)\s*(.)/;

	local ($Text::Wrap::columns, $Text::Wrap::huge);
	my $wrapper;
	$self->{wrap} and
		($wrapper, $Text::Wrap::columns, $Text::Wrap::huge) =
			(\&Text::Wrap::wrap, $self->{wrap}, 'overflow')
	or
		$wrapper = \&File::OM::text_nowrap;
	;


	if ($type eq '#') {
		# xxx this should be stacked
		$self->{element_name} = undef;	# indicates comment
		$self->{elemnum}--;		# doesn't count as an element

		my $enc_com = $self->comment_encode($value);	# encoded value
		$s .= $enc_com =~ /^\s*$/ ?		# wrap() loses label of
			$self->{indent} .		# a blank value so put
				"<!--$enc_com" :	# here instead
			&$wrapper(		# wrap lines; this 1st
				"$self->{indent}<!--",	# "indent" won't break
				$self->{indent},	# other line indents
				$enc_com)		# main part to wrap
		;
		#$s .= "$self->{indent}<!-- " .
		#	$self->comment_encode($value);
		# M_ELEMENT and C_ELEMENT would start here
		$s .= "-->\n";			# close comment
	}
	elsif (defined $name) {			# no element if no name
		# xxx we're saving this to no end; in full form
		# (open and close element) the element name would
		# be saved on a stack and the indent increased
		# across all outformat types.
		#
		$self->{element_name} = $self->name_encode($name);
		my $enc_val = $self->value_encode($value);	# encoded value
		$s .= $enc_val =~ /^\s*$/ ?		# wrap() loses label of
			$self->{indent} .		# a blank value so put
				"<$self->{element_name}>" :	# here instead
			&$wrapper(		# wrap lines; this 1st
				$self->{indent} .	# "indent" won't break
					"<$self->{element_name}>",	# label
				$self->{indent},	# other line indents
				$enc_val)		# main part to wrap
		;
		#$s .= $self->{indent} . "<$self->{element_name}>"
		#	. $self->value_encode($value);
		# M_ELEMENT and C_ELEMENT would start here
		$s .= "</$self->{element_name}>\n";
	}
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub orec {	# OM::XML
	my $self = shift;
	my ($recnum, $lineno) = (shift, shift);
	my ($s, $z) = ('', '');		# built string and catchup string

	$self->{elemnum} = 0;
	$self->{stream_is_open} or	# call ostream() to open stream first
		($z = $self->ostream(),
		$self->{stream_is_open} = 1);
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{record_is_open} = 1;

	defined($recnum) and
		$self->{recnum} = $recnum
	or
		$self->{recnum}++;

	defined($lineno)	or $lineno = '1:';

	$s .= $self->{indent} .			# use indent and
		"<$self->{xml_record_name}>";
	$self->{indent} =~ s/$/$self->{indent_step}/;	# increase indent
	$self->{verbose} and
		$s .= "   <!-- from record $self->{recnum}, line $lineno -->";
	$s .= "\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub crec {	# OM::XML
	my ($self, $recnum) = (shift, shift);
	$self->{record_is_open} = 0;
	$self->{indent} =~ s/$self->{indent_step}$//;	# decrease indent
	my $s = $self->{indent} .			# and use indent
		"</$self->{xml_record_name}>\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub ostream {	# OM::XML
	my $self = shift;

	$self->{recnum} = 0;
	$self->{stream_is_open} = 1;
	$self->{indent} = $self->{indent_start};	# current indent width
	$self->{indent} =~ s/$/$self->{indent_step}/;	# increase indent
	my $s = "<$self->{xml_stream_name}>\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub cstream {	# OM::XML
	my $self = shift;
	my ($s, $z) = ('', '');		# built string and catchup string
	$self->{record_is_open} and	# wrap up any loose ends
		$z = $self->crec();
	$self->{outhandle}	or $s .= $z;	# don't retain print status
	$self->{stream_is_open} = 0;
	$self->{indent} =~ s/$self->{indent_step}$//;	# decrease indent
	$s .= "</$self->{xml_stream_name}>\n";
	$self->{outhandle} and
		return (print { $self->{outhandle} } $s)
	or
		return $s;
}

sub name_encode {	# OM::XML
	my $self = shift;
	local $_ = shift(@_);
	defined($_)		or $_ = '';

	s/&/&amp;/g;
	s/'/&apos;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	s/\\/\\\\/g;
	s/"/\\"/g;

	return $_;

	# &apos; &amp; &lt; &gt; (unparsed \" \\ )
	# XXXX CDATA sections begin with the string " <![CDATA[  "
	# and end with the string " ]]>  "
}

sub value_encode {	# OM::XML
	my $self = shift;
	return $self->name_encode(@_);
}

sub comment_encode {	# OM::XML
	my ($self, $s) = (shift, shift);
	defined($s)	or return '';
	$s =~ s/-->/--&gt;/g;
	return $s;
}

1;

__END__

=head1 NAME

File::OM - Output Multiplexer routines

=head1 SYNOPSIS

 use File::OM;              # to import routines into a Perl script

 $om = File::OM->new(       # make output object that creates strings in
       $format, {           # XML, Turtle, JSON, ANVL, CSV, PSV, or Plain
   outhandle => *STDOUT,    # (opt) print string instead of returning it
   verbose => 1 });         # (opt) also output record and line numbers

 $om->ostream();            # open stream

 $om->cstream();            # close stream

 $om->orec(                 # open record
       $recnum);            # record number (normally tracked from 1)

 $om->crec();               # close record

 $om->elem(                 # output entire element, unless $name undefined
       $name,               # string representing element name
       $value,              # string representing element value
       $lineno,             # input line number/type (default '1:')
       $elemnum);           # element number (normally tracked from 1))

 $om->elems(                # output elements; wrap ANVL/Plain/XML lines
       $name,               # string representing first element name
       $value,              # string representing first element value
       ...);                # other element names and values

 $om->name_encode($s);      # encode a name
 $om->value_encode($s);     # encode a value
 $om->comment_encode($s);   # encode a comment or pseudo-comment

 om_opt_defaults();         # get hash reference with factory defaults

=head1 DESCRIPTION

The B<OM> (Output Multiplexer) Perl module provides a general output
formatting framework for data that can be represented as a stream of
records consisting of element names, values, and comments.  Specific
conversions are possible to XML, Turtle, JSON, CSV, PSV (Pipe Separated
Value) and "Plain" unlabeled text.

The internal element structure is currently identical to the structure
returned by L<File::ANVL::anvl_recarray>.  The C<n>-th element
corresponds to three Perl array elements as follows:

     INDEX   CONTENT
     3n + 0  input file line number
     3n + 1  n-th ANVL element name
     3n + 2  n-th ANVL element value

This means, for example, that the first two ANVL element names would be
found at Perl array indices 4 and 7.  The first triple is special; array
elements 0 and 2 are undefined unless the record begins with an unlabeled
value, such as (in a quasi-ANVL record),

     Smith, Jo
     home: 555-1234
     work: 555-9876

in which case they contain the line number and value, respectively. Array
element 1 always contains a string naming the format of the input, such
as, "ANVL", "JSON", "XML", etc.

The remaining triples are free form except that the values will have been
drawn from the original format and possibly decoded.  The first item
("lineno") in each remaining triple is a number followed by a letter,
such as "34:" or "6#".  The number indicates the line number (or octet
offset, depending on the origin format) of the start of the element.  The
letter is either ':' to indicate a real element or '#' to indicate a
comment; if the latter, the element name has no defined meaning and the
comment is contained in the value.  To output an element as a comment
without regard to line number, give $lineno as "#".

B<OM> presents an object oriented interface.  The object constructor
takes a format argument and returns C<undef> if the format is unknown.
The returned object has methods for creating format-appropriate output
corresponding (currently) to seven output modes; for a complete
application of these methods, see L<File::ANVL::anvl_om>.  Nonetheless,
an application can easily call no method but C<elem()>, as the
necessary open (C<orec()> and C<ostream>) and close (C<crec()> and
C<cstream()>) methods will be invoked automatically before the first
element is output and before the object is destroyed, respectively.
Passing an undefined first argument ($name) to C<elem()> is useful for
skipping an element in a position-based format such as CSV or PSV, which
indicate a missing element by outputing a separator character; when the
format is not position-based, the method usually outputs nothing.

Constructor options include 'verbose', which causes the methods to insert
record and line numbers as comments or pseudo-comments (e.g., for JSON,
an extra element called "#" since JSON doesn't support comments).
Normally output is returned as a string, but if the 'outhandle' option
(defaults to '') contains a file handle, for example,

     { outhandle => *STDOUT }

the string will be printed to the file handle and the method will return
the status of the print call.  Constructor options and defaults:

 {
 outhandle        => '',        # return string instead of printing it
 indent_start     => '',        # overall starting indent
 indent_step      => '  ',      # how much to increment/decrement indent

 # Format specific options.
 turtle_indent    => '    ',    # turtle has one indent width
 turtle_predns    =>            # turtle predicate namespaces
        'http://purl.org/kernel/elements/1.1/',
 turtle_nosubject => 'default', # a default subject (change this)
 turtle_subjelpat => '',        # pattern for matching subject element
 turtle_stream_prefix => 'erc', # symbol we use for turtle
 wrap             => 72,        # wrap text to 72 cols (ANVL, Plain, XML)
 wrap_indent      => '',        # Text::Wrap will insert; "\t" for ANVL
 xml_stream_name  => 'recs',    # for XML output, stream tag
 xml_record_name  => 'rec',     # for XML output, record tag

 # Used to maintain object state.
 elemnum          => 0,         # current element number
 elemsref         => [],        # one array to store record elements
 indent           => '',        # current ident
 recnum           => 0,         # current record number
 }

In this release of the B<OM> package, objects carry limited state
information.  Maintained are the current indention level, element number,
and record number, but there is no stack of "open elements".  Right now
there is only a "whole element at once" method (C<elem()>) that takes
name and value arguments to construct a complete element.  Future
releases may support methods for opening and closing elements.

The B<OM> package automatically tracks element and record numbers, but
the optional C<$recnum> and C<$elemnum> method arguments can be used to
set them to specific values.  They help with formats that put separators
before every element or record except for the first one (e.g., JSON uses
commas).  The C<$lineno> argument is meant to refer to input line numbers
that may be useful with the 'verbose' option and creating diagnostic
messages.

=head1 SEE ALSO

A Name Value Language (ANVL)
	L<http://www.cdlib.org/inside/diglib/ark/anvlspec.pdf>

=head1 HISTORY

This is a beta version of OM package.  It is written in Perl.

=head1 AUTHOR

John A. Kunze I<jak at ucop dot edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2011 UC Regents.  Open source BSD license.

=head1 PREREQUISITES

Perl Modules: L<Text::Wrap>

Script Categories:

=pod SCRIPT CATEGORIES

UNIX : System_administration

=cut
