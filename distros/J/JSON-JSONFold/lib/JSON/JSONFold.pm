package JSON::JSONFold ;

use strict;
use warnings;
use 5.014 ;
use JSON::PP ();

use Exporter 'import';

our $VERSION = '0.2.0';
our @EXPORT = qw(
    format_json write_json fold_text
    encode_json to_json) ;

our @EXPORT_OK = qw(
	jsonfold_config
	create_writer
) ;
# Object Orient Interface

sub new {
    my ($class, %overrides) = @_ ;

    # Required parameters
    my $width = delete $overrides{width} ;
    my $config = delete $overrides{config} ;

    my $gold = delete $overrides{gold} // 1 ;
    my $indent = delete $overrides{indent} ;
    my $json = delete $overrides{json} // _json_coder($gold, $indent, %overrides) ;
    my $do_close = delete $overrides{do_close} ;
    return bless {
        json => $json,
        width => $width,
        config => _config($config, $width),
        do_close => $do_close,
    }, ref($class) || $class || __PACKAGE__ ;
}

sub format {
    my($self, $data) = @_ ;

    my $config = $self->{config} ;

    my $output = '' ;
    open my $out, '>', \$output or die "open output: $!" ;

    my $stream = _stream($out, $config, 0) ;
    my $json = $self->{json} ;
    my $text = $json->encode($data) ;

    $stream->write($text);

    close $out or die "close output: $!" ;
    $output .= "\n" unless $output =~ /\n\z/;
    return $output ;
}

sub fold {
    my ($self, $text) = @_ ;

    my $config = $self->{config} ;

    my $output = '' ;
    open my $out, '>', \$output or die "open output: $!" ;

    my $stream = _stream($out, $config, 0) ;

    $stream->write($text);

    close $out or die "close output: $!" ;
    $output .= "\n" unless $output =~ /\n\z/;
    return $output ;
}

sub write {
    my($self, $data, $fh) = @_ ;

    my $config = $self->{config} ;

    my $do_close = $self->{do_close} ;
    my $stream = _stream($fh, $config, $do_close) ;
    my $json = $self->{json} ;

    my $text = $json->encode($data) ;
    $stream->write($text);
    $stream->finish;
    $stream->flush;
    my $info = $stream->stats ;
    $stream->close() ;

    return $info ;
}

# Functional Interface

# Not exportable. Allow using DEV::JSONFold::config(...)
sub config {
    my($base_config, $width, %overrides) = @_ ;
    $width //= $overrides{width} ;
    return _config($base_config, $width, %overrides) ;
}

sub jsonfold_config {       
    my($base_config, $width, %overrides) = @_ ;
    $width //= $overrides{width} ;
    return _config($base_config, $width, %overrides) ;
}

sub format_json {
    my($data, $width, $config, %overrides) = @_ ;

    my $fmt = __PACKAGE__->new(width => $width, config => $config, %overrides) ;
    my $output = $fmt->format($data) ;
    return $output ;
}

sub write_json {
    my($data, $fh, $width, $config, %overrides) = @_ ;

    my $fmt = __PACKAGE__->new(width => $width, config => $config, %overrides) ;
    my $info = $fmt->write($data, $fh) ;
    return $info ;
}

sub fold_text {
    my($text, $width, $config) = @_ ;
    my $fmt = __PACKAGE__->new(width => $width, config => $config) ;

    return $fmt->fold($text) ;
}

sub create_writer {
    my($fh, $width, $config, %overrides) = @_ ;
    my $do_close = delete $overrides{close_fp} ;
    return _stream($fh, _config($config, $width, %overrides), $do_close) ;
}

# Helper for Function/OO interface methods

sub _config {
	my ($preset, $width, %overrides) = @_ ;
	$overrides{width} = $width if defined $width ;
	return JSON::JSONFold::Config::config($preset, %overrides) ;
}

sub _stream {
    my ($fp, $config, $close_fp) = @_ ;
    return JSON::JSONFold::Writer->new($fp, $config, $close_fp) ;
}

sub _json_coder {
    my ($gold, $indent, %opt) = @_;
    # Must have valid indent, otherwise cannot parse the data
    my $json = JSON::PP->new->pretty ;
    if ( $gold ) {
        my $sort_keys = $opt{sort_keys} // 1 ;
        $indent //=2 ;
        $json->allow_nonref->canonical($sort_keys);
        $json->space_before(0)->space_after(1);
    }
    $json->indent_length($indent) if defined $indent ;
    return $json;
}

# JSON compatible API - OO

sub encode {
    my ($self, $data) = @_ ;
    return $self->format($data) ;
}


# JSON compatiable API - Functional

sub encode_json {
    my ($data, $opts) = @_ ;
    my %overrides = %$opts if $opts ;
    my $width = delete $overrides{width} ;
    my $compact = delete $overrides{compact} ;

    my $fmt = __PACKAGE__->new(width => $width, config => $compact, %overrides) ;
    my $output = $fmt->format($data) ;
    return $output ;
}

# Same as encode_json - for users of legacy "JSON" wrapper.

sub to_json {
    my ($data, $opts) = @_ ;
    my %overrides = %$opts if $opts ;
    my $width = delete $overrides{width} ;
    my $compact = delete $overrides{compact} ;

    my $fmt = __PACKAGE__->new(width => $width, config => $compact, %overrides) ;
    my $output = $fmt->format($data) ;
    return $output ;
}
 
sub run {
    JSON::JSONFold::CLI::run() ;
}

package JSON::JSONFold::Kind;

use strict ;
use warnings ;
use Exporter 'import';

our @EXPORT_OK = qw(
    KIND_NONE
    KIND_DICT
    KIND_LIST
    %OPENING_KIND
    %CLOSING_KIND
);

use constant KIND_NONE => 0;
use constant KIND_DICT => 1;
use constant KIND_LIST => 2;

our %OPENING_KIND = (
    '{' => KIND_DICT,
    '[' => KIND_LIST,
);

our %CLOSING_KIND = (
    '}'  => KIND_DICT,
    '},' => KIND_DICT,
    ']'  => KIND_LIST,
    '],' => KIND_LIST,
);

# -------------------------------------------------------------------------
# Internal package: immutable-ish configuration record
# -------------------------------------------------------------------------

package JSON::JSONFold::Config;

use strict;
use warnings;
use Exporter 'import';

use constant DEFAULT_WIDTH   => 100 ;
use constant MAX_ARRAY_ITEMS => 1000 ;
use constant MAX_OBJ_ITEMS   => 1000 ;
use constant MAX_NESTING     => 10 ;
use constant MAX_GRID_LINES  => 1000 ;
use constant MAX_WIDTH       => 255 ;

our $SEQ = 0 ;
use constant {
	C_OFF               => $SEQ++,
	C_WIDTH             => $SEQ++,

	C_PACK_ARRAY_ITEMS  => $SEQ++,
	C_PACK_OBJ_ITEMS    => $SEQ++,
	C_PACK_NESTING      => $SEQ++,

	C_FOLD_ARRAY_ITEMS  => $SEQ++,
	C_FOLD_OBJ_ITEMS    => $SEQ++,
	C_FOLD_NESTING      => $SEQ++,

	C_GRID_ARRAY_ITEMS  => $SEQ++,
	C_GRID_OBJ_ITEMS    => $SEQ++,
	C_GRID_MIN_LINES    => $SEQ++,
	C_GRID_MAX_LINES    => $SEQ++,
	C_GRID_ARRAY_MIN    => $SEQ++,
	C_GRID_OBJ_MIN      => $SEQ++,

	C_JOIN_ARRAY_ITEMS  => $SEQ++,
	C_JOIN_OBJ_ITEMS    => $SEQ++,
	C_JOIN_NESTING      => $SEQ++,
	C_UNUSED_LAST       => $SEQ++,
} ;

BEGIN {

    our @EXPORT = qw(
        C_OFF
        C_WIDTH
		C_PACK_ARRAY_ITEMS C_PACK_OBJ_ITEMS C_PACK_NESTING

		C_FOLD_ARRAY_ITEMS C_FOLD_OBJ_ITEMS	C_FOLD_NESTING

		C_GRID_ARRAY_ITEMS C_GRID_OBJ_ITEMS C_GRID_MIN_LINES
		C_GRID_MAX_LINES C_GRID_ARRAY_MIN C_GRID_OBJ_MIN

		C_JOIN_ARRAY_ITEMS C_JOIN_OBJ_ITEMS C_JOIN_NESTING
	) ;
}

our @FIELDS = (
    [ 'off',              C_OFF ],
    [ 'width',            C_WIDTH ],
    [ 'pack_array_items', C_PACK_ARRAY_ITEMS ],
    [ 'pack_obj_items',   C_PACK_OBJ_ITEMS ],
    [ 'pack_nesting',     C_PACK_NESTING ],
    [ 'fold_array_items', C_FOLD_ARRAY_ITEMS ],
    [ 'fold_obj_items',   C_FOLD_OBJ_ITEMS ],
    [ 'fold_nesting',     C_FOLD_NESTING ],
	[ grid_array_items => C_GRID_ARRAY_ITEMS ],
	[ grid_obj_items   => C_GRID_OBJ_ITEMS ],
	[ grid_min_lines   => C_GRID_MIN_LINES ],
	[ grid_max_lines   => C_GRID_MAX_LINES ],
	[ grid_array_min   => C_GRID_ARRAY_MIN ],
	[ grid_obj_min     => C_GRID_OBJ_MIN ],
    [ 'join_array_items', C_JOIN_ARRAY_ITEMS ],
    [ 'join_obj_items',   C_JOIN_OBJ_ITEMS ],
    [ 'join_nesting',     C_JOIN_NESTING ],
) ;

our %NAME_TO_INDEX = map { @$_ } @FIELDS ;
our %PRESETS ;
our ($NONE, $DEFAULT) ;

sub as_hash {
    my ($self) = @_ ;
    map { my ($name, $idx) = @$_ ; ($name => $self->[$idx]) ; } @FIELDS ;
}

sub _make {
    my ($class, %arg) = @_;
    my @d;
    $#d = $SEQ;
    $d[C_OFF] = $arg{off} ;
    $d[C_WIDTH] = $arg{width};

    $d[C_PACK_ARRAY_ITEMS] = $arg{pack_array_items};
    $d[C_PACK_OBJ_ITEMS]   = $arg{pack_obj_items};
    $d[C_PACK_NESTING]     = $arg{pack_nesting};

    $d[C_FOLD_ARRAY_ITEMS] = $arg{fold_array_items};
    $d[C_FOLD_OBJ_ITEMS]   = $arg{fold_obj_items};
    $d[C_FOLD_NESTING]     = $arg{fold_nesting};

	$d[C_GRID_ARRAY_ITEMS] = $arg{grid_array_items} ;
	$d[C_GRID_OBJ_ITEMS]   = $arg{grid_obj_items} ;
	$d[C_GRID_MIN_LINES]   = $arg{grid_min_lines} ;
	$d[C_GRID_MAX_LINES]   = $arg{grid_max_lines} ;
	$d[C_GRID_ARRAY_MIN]   = $arg{grid_array_min} ;
	$d[C_GRID_OBJ_MIN]     = $arg{grid_obj_min} ;

    $d[C_JOIN_ARRAY_ITEMS] = $arg{join_array_items};
    $d[C_JOIN_OBJ_ITEMS]   = $arg{join_obj_items};
    $d[C_JOIN_NESTING]     = $arg{join_nesting};
    return bless \@d, $class;
}

sub _replace {
	my ($base, $validate) = (shift, shift) ;
	return $base unless @_ ;
	my $overrides = @_ == 1 && ref($_[0]) ? $_[0] : { @_ } ;
	return $base unless %$overrides ;

	my @d = @$base ;
	for my $key (keys %$overrides) {
		unless (exists $NAME_TO_INDEX{$key}) {
			die "unknown JSON::JSONFold config key: $key\n" if $validate ;
			next ;
		}
		$d[$NAME_TO_INDEX{$key}] = $overrides->{$key} ;
	}
	return bless \@d, ref($base) || __PACKAGE__ ;
}

sub _resolve_config {
	my ($config) = @_ ;
	return $config if ref($config) ;

	my $name = $config // '' ;
	die "unknown JSON::JSONFold preset: $name\n"
		unless exists $PRESETS{$name} ;
	return $PRESETS{$name} ;
}

sub config {
	my ($preset, %overrides) = @_ ;
	return _replace(_resolve_config($preset), 0, \%overrides) ;
}

sub new {
	my ($class, $config, @args) = @_ ;
	return config($config, @args) ;
}

sub _new_preset {
	my $base = shift ;
	return _replace($base, 1, @_) ;
}

sub _class_init {
	my $class = shift ;

	$DEFAULT = $class->_make(
		width => DEFAULT_WIDTH,

		pack_array_items => 10,
		pack_obj_items   => 5,
		pack_nesting     => 1,

		fold_array_items => 10,
		fold_obj_items   => 5,
		fold_nesting     => 2,

		grid_array_items => MAX_ARRAY_ITEMS,
		grid_obj_items   => MAX_OBJ_ITEMS,
		grid_min_lines   => 3,
		grid_max_lines   => 100,
		grid_array_min   => 3,
		grid_obj_min     => 3,

		join_array_items => 8,
		join_obj_items   => 4,
		join_nesting     => 1,
	) ;

	$NONE = $class->_make(
		width => DEFAULT_WIDTH,

		pack_array_items => 0,
		pack_obj_items   => 0,
		pack_nesting     => 0,

		fold_array_items => 0,
		fold_obj_items   => 0,
		fold_nesting     => 0,

		grid_array_items => 0,
		grid_obj_items   => 0,
		grid_min_lines   => 0,
		grid_max_lines   => 0,
		grid_array_min   => 0,
		grid_obj_min     => 0,

		join_array_items => 0,
		join_obj_items   => 0,
		join_nesting     => 0,
	) ;

	my %pack_max = (
		pack_array_items => MAX_ARRAY_ITEMS,
		pack_obj_items   => MAX_OBJ_ITEMS,
		pack_nesting     => MAX_NESTING,
	) ;
	my %fold_max = (
		fold_array_items => MAX_ARRAY_ITEMS,
		fold_obj_items   => MAX_OBJ_ITEMS,
		fold_nesting     => MAX_NESTING,
	) ;
	my %join_max = (
		join_array_items => MAX_ARRAY_ITEMS,
		join_obj_items   => MAX_OBJ_ITEMS,
		join_nesting     => MAX_NESTING,
	) ;
	my %grid_max = (
		grid_array_items => MAX_ARRAY_ITEMS,
		grid_obj_items   => MAX_OBJ_ITEMS,
		grid_min_lines   => 3,
		grid_max_lines   => MAX_GRID_LINES,
	) ;

	%PRESETS = (
		off     => $class->_make(off => 1),
		''      => $DEFAULT,
		default => $DEFAULT,
		none    => $NONE,

		low     => _new_preset($DEFAULT,
			fold_nesting   => 0,
			join_nesting   => 0,
			grid_max_lines => 0,
		),
		med     => _new_preset($DEFAULT,
			join_nesting   => 0,
			grid_max_lines => 0,
		),
		classic => _new_preset($DEFAULT,
			grid_max_lines => 0,
		),
		high    => _new_preset($DEFAULT,
			pack_array_items => 20, pack_obj_items => 10, pack_nesting => 4,
			fold_array_items => 20, fold_obj_items => 10, fold_nesting => 4,
			grid_array_min   => 4,  grid_obj_min   => 4,
			join_array_items => 16, join_obj_items => 8,  join_nesting => 2,
		),
		max     => _new_preset($DEFAULT,
			width => MAX_WIDTH,
			%pack_max, %fold_max, %join_max, %grid_max,
			grid_array_min => 4,
			grid_obj_min   => 4,
		),
		pack    => _new_preset($NONE, %pack_max),
		fold    => _new_preset($NONE, %fold_max),
		grid    => _new_preset($NONE, %pack_max, %fold_max, %grid_max),
		join    => _new_preset($NONE,
			%fold_max,
			join_array_items => MAX_ARRAY_ITEMS,
			join_obj_items   => MAX_OBJ_ITEMS,
			join_nesting     => MAX_NESTING,
		),
	) ;
}

__PACKAGE__->_class_init ;

# -------------------------------------------------------------------------
# Internal package: one physical pretty-printed line
# -------------------------------------------------------------------------

package JSON::JSONFold::Line ;

use strict ;
use warnings ;
use Exporter 'import' ;

use constant KIND_NONE => $JSON::JSONFold::Kind::KIND_NONE ;
use constant KIND_DICT => $JSON::JSONFold::Kind::KIND_DICT ;
use constant KIND_LIST => $JSON::JSONFold::Kind::KIND_LIST ;

our $SEQ = 0 ;
use constant {
	L_INDENT         => $SEQ++,
	L_PARTS          => $SEQ++,
	L_PARTS_LENGTH   => $SEQ++,
	L_KIND           => $SEQ++,
	L_ITEMS          => $SEQ++,
	L_LEAFS          => $SEQ++,
	L_CHILD_NESTING  => $SEQ++,
	L_OPENER         => $SEQ++,
	L_CLOSER         => $SEQ++,
	L_CAN_JOIN       => $SEQ++,
	L_CAN_PACK       => $SEQ++,
	L_CAN_GRID       => $SEQ++,
} ;

BEGIN {
	our @EXPORT = qw(
		L_INDENT
		L_PARTS
		L_PARTS_LENGTH
		L_KIND 
        L_ITEMS
        L_LEAFS
        L_CHILD_NESTING
        L_OPENER
        L_CLOSER
        L_CAN_JOIN
        L_CAN_PACK
        L_CAN_GRID
	) ;
}

my $KEY_RE = qr/^\s*(?:(?:"[^"\\]*")|(?:'[^'\\]*')|(?:[A-Za-z_\$][A-Za-z0-9_\$]*)|)\s*:/ ;

sub _calc_parts_length {
	my ($parts) = @_ ;
	return 0 unless @$parts ;
	my $n = -1 ;
	$n += 1 + length($_) for @$parts ;
	return $n ;
}

sub parse {
	my ($class, $s) = @_ ;

    my ($spaces) = $s =~ /^(\s*)/;
    my $body = substr($s, length($spaces));
    $body =~ s/\s+\z//;

	my $last = length($body) ? substr($body, -1, 1) : '' ;
	my $opener = $JSON::JSONFold::Kind::OPENING_KIND{$last} // KIND_NONE ;
	my $closer = $JSON::JSONFold::Kind::CLOSING_KIND{$body} // KIND_NONE ;
    my $is_body = !$opener && !$closer ? 1 : 0;

    my @d ;
    $#d = $SEQ ;
    $d[L_INDENT]      = length($spaces);
 
	$d[L_PARTS]         = [ $body ] ;
	$d[L_PARTS_LENGTH]  = length($body) ;
	$d[L_KIND]          = KIND_NONE ;
	$d[L_ITEMS]         = $is_body ? 1 : 0 ;
	$d[L_LEAFS]         = $is_body ? 1 : 0 ;
    $d[L_CHILD_NESTING] = -1;
    $d[L_OPENER]      = $opener;
    $d[L_CLOSER]      = $closer;
    $d[L_CAN_JOIN]    = $is_body;
    $d[L_CAN_PACK]    = $is_body;
	$d[L_CAN_GRID]      = 0 ;

    return bless \@d, $class ;
}

sub raw   {
    return (' ' x $_[0][L_INDENT]) . join(' ', @{ $_[0][L_PARTS] }) . "\n"
}

sub width {
    return $_[0][L_INDENT] + $_[0][L_PARTS_LENGTH]
}

sub can_merge {
	my ($self, $other, $item_limit, $width_limit) = @_ ;
	return $self->[L_INDENT] == $other->[L_INDENT]
		&& $self->[L_ITEMS] + $other->[L_ITEMS] <= $item_limit
		&& $self->[L_INDENT] + $self->[L_PARTS_LENGTH] + 1 + $other->[L_PARTS_LENGTH] <= $width_limit ;
}

sub merge_line {
    my ($self, $other) = @_;
	push @{ $self->[L_PARTS] }, @{ $other->[L_PARTS] } ;
	$self->[L_PARTS_LENGTH] += 1 + $other->[L_PARTS_LENGTH] if @{ $other->[L_PARTS] } ;
    $self->[L_ITEMS] += $other->[L_ITEMS];
    $self->[L_LEAFS] += $other->[L_LEAFS];
    if ($other->[L_CHILD_NESTING] > $self->[L_CHILD_NESTING]) {
        $self->[L_CHILD_NESTING] = $other->[L_CHILD_NESTING];
        $self->[L_CAN_PACK] = 0;
    }
    return $self;
}

sub set_parts {
	my ($self, $parts) = @_ ;
	$self->[L_PARTS] = $parts ;
	$self->[L_PARTS_LENGTH] = _calc_parts_length($parts) ;
	return $self ;
}

sub dict_signature {
	my ($self) = @_ ;
	my @parts = @{ $self->[L_PARTS] } ;
	return undef if @parts < 3 ;

	my @signature ;
	for my $part (@parts[1 .. $#parts - 1]) {
		return undef unless $part =~ /($KEY_RE)/ ;
		push @signature, $1 ;
	}
	return join("\x1e", @signature) ;
}

sub _format_parts {
	my ($parts, $widths) = @_ ;
	my $last = $#$widths ;
	my @out ;
	for my $i (0 .. $#$parts) {
		my $part = $parts->[$i] ;
		my $w = $widths->[$i] ;
		if ($part =~ /^[\-0-9]/) {
			push @out, sprintf("%*s", $w, $part) ;
		}
		elsif ($i < $last) {
			push @out, sprintf("%-*s", $w, $part) ;
		}
		else {
			push @out, $part ;
		}
	}
	return \@out ;
}

sub apply_grid {
	my ($self, $widths) = @_ ;
	return $self->set_parts(_format_parts($self->[L_PARTS], $widths)) ;
}

# -------------------------------------------------------------------------
# Internal package: stack frame for a currently open JSON container
# -------------------------------------------------------------------------



package JSON::JSONFold::Frame;
use strict;
use warnings;
use Exporter 'import' ;

BEGIN {
    JSON::JSONFold::Line->import() ;
}

our $SEQ = 0 ;
use constant {
	F_KIND           => $SEQ++,
	F_INDENT         => $SEQ++,
    F_DEPTH         => $SEQ++,
    F_LINES         => $SEQ++,
	F_PARTS_LENGTH   => $SEQ++,
	F_PACK_LIMIT     => $SEQ++,
    F_FOLD_LIMIT    => $SEQ++,
    F_JOIN_LIMIT    => $SEQ++,
	F_GRID_LIMIT     => $SEQ++,
	F_GRID_MIN_ITEMS => $SEQ++,
    F_CONTENT_LINES => $SEQ++,
    F_ITEMS         => $SEQ++,
    F_LEAFS         => $SEQ++,
    F_FOLD_OK       => $SEQ++,
	F_GRID_OK        => $SEQ++,
    F_CHILD_NESTING => $SEQ++,
} ;

BEGIN {
	our @EXPORT = qw(
		F_KIND F_INDENT F_DEPTH F_LINES F_PARTS_LENGTH
		F_PACK_LIMIT F_FOLD_LIMIT F_JOIN_LIMIT F_GRID_LIMIT F_GRID_MIN_ITEMS
		F_CONTENT_LINES F_ITEMS F_LEAFS F_FOLD_OK F_GRID_OK F_CHILD_NESTING
	) ;
}

sub new {
    my ($class, %arg) = @_;
    my @d ;
    $#d = $SEQ ;
	$d[F_KIND]           = $arg{kind} // 0 ;
	$d[F_INDENT]         = $arg{indent} // 0 ;
    $d[F_DEPTH]         = $arg{depth} // 0;
    $d[F_LINES]         = $arg{lines} // [];
	$d[F_PARTS_LENGTH]   = 0 ;
    $d[F_PACK_LIMIT]    = $arg{pack_limit} // 0;
    $d[F_FOLD_LIMIT]    = $arg{fold_limit} // 0;
    $d[F_JOIN_LIMIT]    = $arg{join_limit} // 0;
	$d[F_GRID_LIMIT]     = $arg{grid_limit} // 0 ;
	$d[F_GRID_MIN_ITEMS] = $arg{grid_min_items} // 0 ;
    $d[F_CONTENT_LINES] = 0;
    $d[F_ITEMS]         = 0;
    $d[F_LEAFS]         = 0;
    $d[F_FOLD_OK]       = 1;
	$d[F_GRID_OK]        = 0 ;
    $d[F_CHILD_NESTING] = -1;
    return bless \@d, $class;
}

sub is_empty  { return @{ $_[0][F_LINES] } == 0 }
sub last_line { return $_[0][F_LINES][-1] }

sub update_stats {
    my ($self, $line) = @_ ;
    $self->[F_ITEMS] += $line->[L_ITEMS];
    $self->[F_LEAFS] += $line->[L_LEAFS];
	$self->[F_PARTS_LENGTH] += $line->[L_PARTS_LENGTH] + ($self->[F_PARTS_LENGTH] ? 1 : 0) ;
    if ($line->[L_CHILD_NESTING] >= $self->[F_CHILD_NESTING]) {
        $self->[F_CHILD_NESTING] = $line->[L_CHILD_NESTING] + 1;
    }
	return ;
}

sub add_line {
	my ($self, $line) = @_ ;
	push @{ $self->[F_LINES] }, $line ;
	if (!$line->[L_OPENER] && !$line->[L_CLOSER]) {
		$self->[F_CONTENT_LINES]++ ;
	}
	$self->update_stats($line) ;
	return ;
}

sub check_fold_limits {
	my ($self, $cfg) = @_ ;
	return 0 if $self->[F_PARTS_LENGTH] > $cfg->[JSON::JSONFold::Config::C_WIDTH] ;
	return 0 if $self->[F_ITEMS] > $self->[F_FOLD_LIMIT] ;
	return 0 if $self->[F_CHILD_NESTING] >= $cfg->[JSON::JSONFold::Config::C_FOLD_NESTING] ;
	return 1 ;
}

sub fold_lines {
	my ($self, $cfg) = @_ ;
	my @parts = map { @{ $_->[L_PARTS] } } @{ $self->[F_LINES] } ;

	my @d ;
	$#d = $JSON::JSONFold::Line::SEQ ;
	$d[L_INDENT]        = $self->[F_INDENT] ;
	$d[L_PARTS]         = \@parts ;
	$d[L_PARTS_LENGTH]  = $self->[F_PARTS_LENGTH] ;
	$d[L_KIND]          = $self->[F_KIND] ;
	$d[L_ITEMS]         = 1 ;
	$d[L_LEAFS]         = $self->[F_LEAFS] ;
	$d[L_CHILD_NESTING] = $self->[F_CHILD_NESTING] ;
	$d[L_OPENER]        = JSON::JSONFold::Kind::KIND_NONE ;
	$d[L_CLOSER]        = JSON::JSONFold::Kind::KIND_NONE ;
	$d[L_CAN_PACK]      = 0 ;
	$d[L_CAN_JOIN]      = $self->[F_CHILD_NESTING] < $cfg->[JSON::JSONFold::Config::C_JOIN_NESTING] ? 1 : 0 ;
	$d[L_CAN_GRID]      = ($cfg->[JSON::JSONFold::Config::C_GRID_MAX_LINES] > 0
						   && $self->[F_ITEMS] <= $self->[F_GRID_LIMIT]) ? 1 : 0 ;

	@{ $self->[F_LINES] } = (bless \@d, 'JSON::JSONFold::Line') ;
	return ;
}

sub join_lines {
	my ($self, $cfg) = @_ ;
	my $lines = $self->[F_LINES] ;
	my $n = @$lines ;
	return if $n < 2 ;

	my $prev = $lines->[0] ;
	my $write_pos = 1 ;

	for (my $read_pos = 1; $read_pos < $n; $read_pos++) {
		my $line = $lines->[$read_pos] ;
		if ($prev->[L_CAN_JOIN]
			&& $line->[L_CAN_JOIN]
			&& $prev->can_merge($line, $self->[F_JOIN_LIMIT], $cfg->[JSON::JSONFold::Config::C_WIDTH])) {
			$prev->merge_line($line) ;
			$prev->[L_CAN_PACK] = 0 ;
		}
		else {
			$lines->[$write_pos] = $line if $read_pos != $write_pos ;
			$prev = $line ;
			$write_pos++ ;
		}
	}

	splice(@$lines, $write_pos) if $write_pos < @$lines ;
	$self->[F_CONTENT_LINES] -= ($n - $write_pos) ;
	return ;
}

# -------------------------------------------------------------------------
# Internal package: counters
# -------------------------------------------------------------------------

package JSON::JSONFold::Stats;
use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {
        bytes_in  => 0,
        bytes_out => 0,
        lines_in  => 0,
        lines_out => 0,
    }, $class;
}

sub bytes_in  { $_[0]{bytes_in}  }
sub bytes_out { $_[0]{bytes_out} }
sub lines_in  { $_[0]{lines_in}  }
sub lines_out { $_[0]{lines_out} }

sub as_hash { return %{ $_[0] } }

# -------------------------------------------------------------------------
# Internal package: streaming folding filter/writer
# -------------------------------------------------------------------------

package JSON::JSONFold::Writer;
use strict;
use warnings;

BEGIN {
    JSON::JSONFold::Line->import() ;
    JSON::JSONFold::Frame->import() ;
    JSON::JSONFold::Config->import() ;
}

our $SEQ = 0 ;
use constant {
    W_UNUSED_FIRST => $SEQ++,
    W_FH           => $SEQ++,
    W_CFG          => $SEQ++,
    W_PENDING      => $SEQ++,
    W_STACK        => $SEQ++,
    W_STATS        => $SEQ++,
    W_DO_CLOSE      => $SEQ++,
    W_UNUSED_LAST  => $SEQ++,
} ;

sub new {
    my ($class, $fh, $config, $do_close) = @_;

    my $cfg = JSON::JSONFold::Config::config($config) ;
    my @d ;
    $#d = $SEQ ;
    $d[W_FH]      = $fh;
    $d[W_CFG]     = $cfg unless $cfg->[C_OFF] ;
    $d[W_PENDING] = '';
    $d[W_STACK]   = [];
    $d[W_STATS]   = JSON::JSONFold::Stats->new;
    $d[W_DO_CLOSE] = $do_close;
    return bless \@d, $class;
}

sub stats  { return $_[0][W_STATS] }

sub write {
    my ($self, $s) = @_;
    $s = '' unless defined $s;
    my $len = length($s);
    $self->[W_STATS]{bytes_in} += $len;

    unless ($self->[W_CFG]) {
        $self->[W_STATS]{lines_in} += _count_newlines($s);
        return $self->_write_str($s);
    }

    my $nl = index($s, "\n");
    if ($nl < 0) {
        $self->[W_PENDING] .= $s;
        return $len;
    }

    my $nl2 = index($s, "\n", $nl + 1);
    if ($nl2 < 0) {
        $self->[W_STATS]{lines_in}++;
        my $line_text = $self->[W_PENDING] . substr($s, 0, $nl);
        $self->[W_PENDING] = substr($s, $nl + 1);
        $self->_feed(JSON::JSONFold::Line->parse($line_text));
        return $len;
    }

    # We have multiple lines - at least 2 new lines in the new buffer
    my @lines = split("\n", $s, -1) ;
    $lines[0] = $self->[W_PENDING] . $lines[0] ;
    $self->[W_PENDING] = pop @lines ;
    for my $part ( @lines ) {
        $self->_feed(JSON::JSONFold::Line->parse($part));

    }    
    $self->[W_STATS]{lines_in} += @lines;

    return $len;
}

sub finish {
    my ($self) = @_;
    if (length $self->[W_PENDING]) {
        $self->_feed(JSON::JSONFold::Line->parse($self->[W_PENDING], $self->_parent_kind));
        $self->[W_PENDING] = '';
    }

    for my $frame (@{ $self->[W_STACK] }) {
        $self->_write_line($_) for @{ $frame->[F_LINES] };
    }
    @{ $self->[W_STACK] } = ();
}

sub flush {
    my ($self) = @_;
    my $fh = $self->[W_FH];
    $fh->flush if $fh && $fh->can('flush');
}

sub close {
    my ($self) = @_;
    $self->finish;
    $self->flush;
    $self->[W_FH]->close if $self->[W_DO_CLOSE] ;
}

sub _feed {
    my ($self, $line) = @_;
    # Opener
    if ($line->[L_OPENER]) {
		my $frame = JSON::JSONFold::Frame->new(
            kind       => $line->[L_OPENER],
			indent         => $line->[L_INDENT],
            depth      => scalar(@{ $self->[W_STACK] }),
            pack_limit => $self->_pack_limit($line->[L_OPENER]),
            fold_limit => $self->_fold_limit($line->[L_OPENER]),
            join_limit => $self->_join_limit($line->[L_OPENER]),
			grid_limit     => $self->_grid_limit($line->[L_OPENER]),
			grid_min_items => $self->_grid_min_items($line->[L_OPENER]),
		) ;
		$frame->add_line($line) ;
		push @{ $self->[W_STACK] }, $frame ;

		$self->_mark_no_fold if $line->width > $self->[W_CFG][C_WIDTH] ;
		return ;
	}

	unless (@{ $self->[W_STACK] }) {
		$self->_write_line($line) ;
		return ;
	}

	my $frame = $self->[W_STACK][-1] ;

	if ($line->[L_CLOSER]) {
		if ($frame->[F_KIND] != $line->[L_CLOSER]) {
			$frame->[F_FOLD_OK] = 0 ;
			$frame->[F_GRID_OK] = 0 ;
		}
		$frame->add_line($line) ;
		$self->_close_frame ;
		return ;
	}

	$line->[L_CAN_PACK] = 0 if $line->[L_ITEMS] >= $frame->[F_PACK_LIMIT] ;
	$line->[L_CAN_JOIN] = 0 if $line->[L_ITEMS] >= $frame->[F_JOIN_LIMIT] ;
	$self->_add_to_frame($frame, $line) ;
	return ;
}

sub _emit_lines {
    my ($self, $lines, $depth) = @_;
    return unless @$lines;
    $depth = @{ $self->[W_STACK] } - 1 unless defined $depth;

    if ($depth < 0) {
        $self->_write_line($_) for @$lines;
        return
    }

    my $frame = $self->[W_STACK][$depth];
    $self->_add_to_frame($frame, $_) for @$lines;
    return
}

sub _add_to_frame {
    my ($self, $frame, $line) = @_;

	if (!$frame->is_empty) {
		unless ($frame->[F_GRID_OK]) {
			my $prev = $frame->last_line ;
			return if $line->[L_CAN_PACK] && $prev->[L_CAN_PACK] && $self->_try_pack($frame, $prev, $line) ;
			return if $line->[L_CAN_JOIN] && $prev->[L_CAN_JOIN] && $self->_try_join($frame, $prev, $line) ;
		}
        # If frame is empty, may be it's in "streaming" mode, which
        # mean that lines that can not be packed/joined can be sent
        # directly to the output:
    } elsif (
        !$frame->[F_FOLD_OK] && !$line->[L_CAN_PACK] && !$line->[L_CAN_JOIN]
        ) {
        $self->_write_line($line);
        return;
    }

	$frame->add_line($line) ;

    if ( $frame->[F_FOLD_OK] && $line->width > $self->[W_CFG][C_WIDTH] ) {
        $self->_mark_no_fold ;
    }

	unless ($line->[L_CLOSER]) {
		if ($frame->[F_FOLD_OK] && !$frame->check_fold_limits($self->[W_CFG])) {
			$self->_mark_no_fold ;
		}

		if ($frame->[F_GRID_OK] && !$line->[L_CAN_GRID]) {
			$self->_mark_no_grid ;
			$frame->join_lines($self->[W_CFG]) ;
		}
	}

	$self->_stream_frame($frame) unless $frame->[F_FOLD_OK] || $frame->[F_GRID_OK] ;
	return ;
}

sub _merge_into_frame {
    my ($self, $frame, $prev, $line) = @_;
	$prev->merge_line($line) ;

	$prev->[L_CAN_PACK] = 0
		if $prev->[L_ITEMS] >= $frame->[F_PACK_LIMIT]
		|| $prev->[L_CHILD_NESTING] >= $self->[W_CFG][C_PACK_NESTING] ;

	$prev->[L_CAN_JOIN] = 0
		if $prev->[L_ITEMS] >= $frame->[F_JOIN_LIMIT]
		|| $prev->[L_CHILD_NESTING] >= $self->[W_CFG][C_JOIN_NESTING] ;

	$frame->update_stats($line) ;

	if ($frame->[F_FOLD_OK] && !$frame->check_fold_limits($self->[W_CFG])) {
            $self->_mark_no_fold ;
            $self->_stream_frame($frame) ;
    }
}

sub _try_pack {
	my ($self, $frame, $prev, $line) = @_ ;
	return 0 if $frame->[F_PACK_LIMIT] <= 1 ;
	return 0 unless $prev->can_merge($line, $frame->[F_PACK_LIMIT], $self->[W_CFG][C_WIDTH]) ;
    $self->_merge_into_frame($frame, $prev, $line);
    $prev->[L_CAN_JOIN] = 0 unless $prev->[L_CAN_PACK] ;
    return 1;
}

sub _try_grid {
	my ($self, $frame) = @_ ;
	return 0 if $frame->[F_KIND] != JSON::JSONFold::Kind::KIND_LIST ;

	my $line_count = @{ $frame->[F_LINES] } - 2 ;
	return 0 if $line_count < 2
		|| $line_count < $self->[W_CFG][C_GRID_MIN_LINES]
		|| $line_count > $self->[W_CFG][C_GRID_MAX_LINES] ;

	my @lines = @{ $frame->[F_LINES] }[1 .. @{ $frame->[F_LINES] } - 2] ;
	return 0 unless @lines ;

	my $first = $lines[0] ;
	my $part_count = @{ $first->[L_PARTS] } ;
	return 0 if $part_count < 4 || ($part_count - 2) < $frame->[F_GRID_MIN_ITEMS] ;

	for my $line (@lines) {
		return 0 if @{ $line->[L_PARTS] } != $part_count ;
	}

	if ($first->[L_KIND] == JSON::JSONFold::Kind::KIND_DICT) {
		my $sig = $first->dict_signature ;
		return 0 unless defined $sig ;
		for my $line (@lines) {
			my $line_sig = $line->dict_signature ;
			return 0 unless defined $line_sig && $line_sig eq $sig ;
		}
	}

	my @widths ;
	for my $i (0 .. $part_count - 1) {
		my $max = 0 ;
		for my $line (@lines) {
			my $len = length($line->[L_PARTS][$i]) ;
			$max = $len if $len > $max ;
		}
		push @widths, $max ;
	}

	my $grided_length = -1 ;
	$grided_length += 1 + $_ for @widths ;
	return 0 if $frame->[F_LINES][0][L_INDENT] + $grided_length > $self->[W_CFG][C_WIDTH] ;

	for my $line (@lines) {
		$line->apply_grid(\@widths) ;
		$line->[L_CAN_PACK] = 0 ;
		$line->[L_CAN_JOIN] = 0 ;
		$line->[L_CAN_GRID] = 0 ;
	}
	return 1 ;
}

sub _try_join {
    my ($self, $frame, $prev, $line) = @_;
	return 0 if $frame->[F_JOIN_LIMIT] <= 1 ;
	return 0 unless $prev->can_merge($line, $frame->[F_JOIN_LIMIT], $self->[W_CFG][C_WIDTH]) ;
    $self->_merge_into_frame($frame, $prev, $line);
    return 1;
}



sub _close_frame {
	my ($self) = @_ ;

    my $frame = pop @{ $self->[W_STACK] };

	if ($frame->[F_GRID_OK]) {
		if ($self->_try_grid($frame)) {
			$self->_mark_no_grid ;
		}
		else {
			$self->_mark_no_grid ;
			$frame->join_lines($self->[W_CFG]) ;
			$frame->[F_FOLD_OK] = $frame->check_fold_limits($self->[W_CFG]) ;
		}
	}

	if ($frame->[F_FOLD_OK]) {
		if ($self->_try_fold($frame)) {
			if (@{ $self->[W_STACK] } && $frame->[F_LINES][0][L_CAN_GRID]) {
				my $parent = $self->[W_STACK][-1] ;
				$parent->[F_GRID_OK] = 1 if $parent->[F_CONTENT_LINES] == 0 ;
			}
		}
	}

	$self->_emit_lines($frame->[F_LINES]) ;
	return ;
}

sub _try_fold {
	my ($self, $frame) = @_ ;
	return 0 if !$frame->[F_FOLD_OK]
		|| $frame->[F_CONTENT_LINES] != 1
		|| @{ $frame->[F_LINES] } != 3
		|| $frame->[F_INDENT] + $frame->[F_PARTS_LENGTH] > $self->[W_CFG][C_WIDTH] ;

	$frame->fold_lines($self->[W_CFG]) ;
	return 1 ;
}

sub _stream_frame {
    my ($self, $frame) = @_;
    my $lines = $frame->[F_LINES];
    return unless @$lines ;

    my $last = $lines->[-1] ;
    my $keep_last = $last->[L_CAN_PACK] || $last->[L_CAN_JOIN] ;
    pop @$lines if $keep_last ;
    if ( @$lines ) {
        $self->_emit_lines($lines, $frame->[F_DEPTH] - 1) ;
        @$lines = ();
    }
    push @$lines, $last if $keep_last ;
    return
}

sub _mark_no_fold {
    my ($self) = @_;
    $_->[F_FOLD_OK] = 0 for @{ $self->[W_STACK] };
}

sub _mark_no_grid {
	my ($self) = @_ ;
	$_->[F_GRID_OK] = 0 for @{ $self->[W_STACK] } ;
	return ;
}

sub _write_line {
    my ($self, $line) = @_ ;
    $self->[W_STATS]{lines_out} ++ ;
    return $self->_write_str($line->raw) ;
}

sub _write_str {
    my ($self, $s) = @_;

    $self->[W_FH]->print($s) ;
    $self->[W_STATS]{bytes_out} += length($s);
    return length($s);
}


sub _choose_limit {
    my ($kind, $list, $dict) = @_;
    return $kind == JSON::JSONFold::Kind::KIND_LIST() ? $list
         : $kind == JSON::JSONFold::Kind::KIND_DICT() ? $dict
         : 0;
}

sub _pack_limit { _choose_limit($_[1], $_[0][W_CFG][C_PACK_ARRAY_ITEMS], $_[0][W_CFG][C_PACK_OBJ_ITEMS]) }
sub _fold_limit { _choose_limit($_[1], $_[0][W_CFG][C_FOLD_ARRAY_ITEMS], $_[0][W_CFG][C_FOLD_OBJ_ITEMS]) }
sub _join_limit { _choose_limit($_[1], $_[0][W_CFG][C_JOIN_ARRAY_ITEMS], $_[0][W_CFG][C_JOIN_OBJ_ITEMS]) }
sub _grid_limit { _choose_limit($_[1], $_[0][W_CFG][C_GRID_ARRAY_ITEMS], $_[0][W_CFG][C_GRID_OBJ_ITEMS]) }
sub _grid_min_items { _choose_limit($_[1], $_[0][W_CFG][C_GRID_ARRAY_MIN], $_[0][W_CFG][C_GRID_OBJ_MIN]) }
sub _count_newlines { return ($_[0] =~ tr/\n//) }

# -------------------------------------------------------------------------
# CLI
# -------------------------------------------------------------------------

package JSON::JSONFold::CLI ;

use strict ;
use warnings ;
use Exporter 'import';

our @EXPORT_OK = qw(
    demo_data
    run
) ;

sub setup {
    require Carp ;

    $SIG{__DIE__} = sub {
        return if $^S;
        local $SIG{__DIE__};
        Carp::confess(@_);
    };

    $SIG{__WARN__} = sub {
        local $SIG{__WARN__};
        Carp::cluck(@_);
    };

    require Getopt::Long ;

}

sub demo_data {
    return {
        meta  => { version => 1, ok => JSON::PP::true, name => "jsonfold demo" },
        ids => [ 1, 2, 3, 4, 5, 6 ],
        items => [ { id => 1, name => "alpha" }, { id => 2, name => "beta" }, ],
        matrix => [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
        long   => [
            "this is a long message that may force the block to stay expanded",
            "second",
            "third",
            "fourth",
        ],
        "single-array" => [1],
        "single-obj"   => { x => 2 },
        long_array     => [ map { "a$_" } 1..50 ],
        wide_array     => [ map { "abcdefghijklmnopqrstuvwxyz$_" } 1 .. 9 ],
        wide_object    => { map { ; "abcdefghijk$_" => "lmnopqrstuvwxyz$_" } 1 .. 9 },

    };
}

sub parse_options {
    my %opt = (
        compact   => 'default',
        indent    => 2,
        sort_keys => 1,
    );

    Getopt::Long::GetOptions(
        'demo'       => \$opt{demo},
        'verbose|v'  => \$opt{verbose},
        'help|h'     => \$opt{help},
        'input|i=s'  => \$opt{input},
        'compact=s'  => \$opt{compact},
        'indent=i'   => \$opt{indent},
        'sort-keys!' => \$opt{sort_keys},
    );

	return \%opt ;
}

sub usage {
    my $out = shift ;
    $out->print(<<___
Usage: json-jsonfold [options] < input.json

  --demo
  --compact=default|classic|none|low|med|high|max|grid|pack|fold|join|off
  --width=N
  --indent=N
  --sort-keys
  --input=FILE
___
    ) ;
}

sub read_input {
    my ($input) = @_ ;

    my $json_text;
    if (defined $input) {
        open my $fh, '<', $input or die "$input: $!\n";
        local $/;
        $json_text = <$fh>;
        close $fh or die "$input: $!\n";
    } else {
        local $/;
        $json_text = <STDIN>;
    }

    return JSON::PP->new->allow_nonref->decode($json_text);
}

sub show_verbose {
    require Data::Dumper ;

    my ($label) = shift ;
    my $dumper = new Data::Dumper([])->Terse(1)->Indent(1)->Sortkeys(1)->Pair('=')->Quotekeys(0) ;

    my $s = $dumper->Values( \@_)->Dump ;
    $s =~ s/\s+/ /gsm ;

    print STDERR "$label: $s\n" ;

}

sub run {
    setup() ;
    my $opt = parse_options();

    if ($opt->{help}) {
        usage(\*STDOUT);
        return 0;
    }

    my $data = $opt->{demo} ? demo_data() : read_input($opt->{input});
    my %cfg ;
    my $config = JSON::JSONFold::config($opt->{compact}, $opt->{width}, %cfg);
    my $verbose = $opt->{verbose} ;

    show_verbose("config", { $config->as_hash } ) if $verbose ;
 
    my $info = JSON::JSONFold::write_json($data, \*STDOUT, $opt->{width}, $config, sort_keys => $opt->{sort_keys});

    show_verbose("stats", { % $info }) if $verbose ;
    return 0;
}

run() unless caller() ;

1;

__END__

=head1 NAME

JSON::JSONFold - compact, readable JSON formatting

=head1 SYNOPSIS

    use JSON::JSONFold;

    # Functional interface

    my $text = format_json($data, 100, 'default');

    write_json($data, \*STDOUT, 100, 'default');

    my $folded = fold_text($pretty_json, 100, 'default');

    # Object interface

    my $fmt = JSON::JSONFold->new(
        width  => 100,
        config => 'default',
    );

    my $text = $fmt->format($data);

    # JSON-compatible interface

    my $text = encode_json($data, {
        width   => 100,
        compact => 'default',
    });

    # Streaming interface

    my $formatter = create_writer(\*STDOUT, 100, 'default');

    $formatter->write($text);
    $formatter->finish;

=head1 DESCRIPTION

C<JSON::JSONFold> formats JSON using a regular pretty-printer and then folds
the output into a more compact layout.

It is intended to preserve readability while reducing unnecessary vertical
space in arrays, objects, and simple nested structures.

JSONFold may be used as:

=over

=item *

A functional API.

=item *

An object-oriented formatter.

=item *

A streaming post-processor.

=item *

A drop-in replacement for C<encode_json> and C<to_json>.

=back

=head1 EXPORTED FUNCTIONS

The following functions are exported by default:

    format_json
    write_json
    fold_text
    encode_json
    to_json

The following functions are exported on request:

    jsonfold_config
    create_writer


=head1 FUNCTIONAL INTERFACE

=head2 jsonfold_config

    my $config = jsonfold_config($preset, $width, %overrides);

Creates a JSONFold configuration object.

C<$preset> may be a preset name or an existing configuration object.
Additional named arguments override individual configuration settings.

=head2 format_json

    my $text = format_json($data, $width, $config, %overrides);

Formats a Perl data structure as folded JSON and returns the resulting text.

=head2 write_json

    my $stats = write_json($data, $fh, $width, $config, %overrides);

Formats a Perl data structure and writes the folded JSON to C<$fh>.

Returns formatting statistics.

=head2 fold_text

    my $text = fold_text($pretty_json, $width, $config);

Folds existing pretty-printed JSON text and returns the folded result.

=head1 OBJECT INTERFACE

=head2 new

    my $fmt = JSON::JSONFold->new(
        width     => 100,
        config    => 'default',
        indent    => 2,
        sort_keys => 1,
    );

Creates a formatter object.

Recognized options include:

    width
        Target line width.

    config
        Preset name or configuration object.

    indent
        Pretty-print indentation width.

    sort_keys
        Sort object keys before formatting.

    gold
        Use JSONFold reference formatting (indent=2, space_before=0, space_after=1). default = true

    json
        Custom JSON encoder object.

    do_close
        Close the underlying filehandle when writing finishes.

If C<json> is not supplied, a default pretty-printing JSON encoder is created.

=head2 format

    my $text = $fmt->format($data);

Formats a Perl data structure and returns folded JSON text.

=head2 fold

    my $text = $fmt->fold($pretty_json);

Folds existing pretty-printed JSON text.

=head2 write

    my $stats = $fmt->write($data, $fh);

Formats a Perl data structure and writes the result to C<$fh>.

Returns formatting statistics.

=head2 encode

    my $text = $fmt->encode($data);

Alias for C<format>, provided for compatibility with JSON-style APIs.

=head1 STREAMING INTERFACE

=head2 create_writer

    my $formatter = create_writer($fh, $width, $config, %overrides);

Creates a streaming formatter around an existing filehandle.

The C<$config> parameter may be a preset name or a
L<JSON::JSONFold::Config> object.


The returned object accepts pretty-printed JSON text incrementally and writes
folded JSON to C<$fh>. This allows JSONFold to be used as a streaming
post-processor without buffering the entire document in memory.

    my $formatter = create_writer(\*STDOUT, 100, 'default');

    $formatter->write("{\n");
    $formatter->write(qq(  "name": "Alice"\n));
    $formatter->write("}\n");

    $formatter->finish;
    $formatter->flush;

The returned object is a L<JSON::JSONFold::Writer> and supports:

    write($text)
    finish()
    flush()
    close()
    stats()

Normally, users should prefer C<format_json>, C<write_json>, or the object
interface. C<create_writer> is intended for advanced use cases and
integration with existing serializers and streaming APIs.

=head1 JSON-COMPATIBLE FUNCTIONS

=head2 encode_json

This function may be used as a drop-in replacement for C<JSON::encode_json>.
The optional second argument controls JSONFold formatting.

    my $text = encode_json($data);

    my $text = encode_json($data, {
        width   => 100,
        compact => 'default',
    });

Encodes C<$data> as folded JSON.

When called without a second argument, C<encode_json> is compatible with
C<JSON::encode_json> and uses the default JSONFold settings.

The optional second argument is a hash reference containing JSONFold options.

JSONFold-specific options:

=over

=item * C<width>

Target output width.

=item * C<compact>

Preset name or configuration object.

=back

=head2 to_json

This function may be used as a drop-in replacement for C<JSON::to_json>.
The optional second argument controls JSONFold formatting.
It will ignore other legacy C<JSON> options (canonical, etc).

    my $text = to_json($data);

    my $text = to_json($data, {
        canonical => 1,
        pretty    => 1,
    });

    my $text = to_json($data, {
        width     => 100,
        compact   => 'high',
        canonical => 1,
    });

Compatibility wrapper similar to C<JSON::to_json>.

When called without a second argument, C<to_json> behaves like
C<JSON::to_json> followed by JSONFold formatting using the default settings.

The optional hash reference may contain both JSON options and JSONFold
options. JSONFold-specific options are removed before the remaining options
are forwarded to C<JSON::to_json>.

JSONFold-specific options:

=over

=item * C<width>

Target output width.

=item * C<compact>

Preset name or configuration object.

=back

=head1 SEE ALSO

L<JSON>,
L<JSON::PP>,
L<JSON::JSONFold::Config>,
L<JSON::JSONFold::Writer>

=head1 AUTHOR

Yair Lenga

=head1 COPYRIGHT AND LICENSE

See the distribution license.

=cut
