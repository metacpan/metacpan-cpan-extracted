
#
# Setup and initialization is done with objects, but execution
# proceedural code using local() variables for state.  This
# imposes a recusion model on the control flow, but allows
# previous states to automatically resume.
#

package HTML::Transmorgify;

use strict;
use warnings;

use List::Util qw(first);
use Image::Size;
use Scalar::Util qw(reftype blessed);
use File::Slurp;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
require Exporter;
use Module::Load;
use HTML::Transmorgify::Symbols;

our $VERSION = 0.12;

our @ISA = qw(Exporter);
our @EXPORT = qw(dangling);
our @EXPORT_OK = qw(
	dstring
	run
	compile
	dangling
	continue_compile
	capture_compile
	queue_intercept
	queue_capture
	allocate_result_type
	eat_cr
	rbuf
	postbuf
	module_bits
	boolean
	bomb
	%variables
	%transformations
	%dispatch
	%priorities
	@post_intercept_push
	$xml_quoting
	$textref
	$rbuf
	$debug
	$tagset
	$input_file
	$input_line
	$modules
	$result
	$query_param
	$original_file
	$original_line
	$invocation_options
	$process_text_ref
	);

our $tagset;
our $textref;
our $result;
our %variables;
our $rbuf;
our $modules;
our $debug = 0;
our %compiled;			# cache of compiled text -> $rbuf
our $intercept_okay = 0;
our $input_file;
our $input_line;
our $original_file;
our $original_line;
our $xml_quoting = 0;
our @result_array;
our %dispatch;
our %priorities;
our %queued_intercepts;
our @queued_captures;
our @post_intercept_push;
our $invocation_options;
our $wrap_compile_cb;
our $process_text_ref;

our %result_index = ( text => 0, script => 1 );
our %reverse_result_index = reverse %result_index;
our $result_key_count = 2;

our $query_param;

my %base_tags;

#### PUBLIC FUNCTIONS

sub allocate_result_type
{
	my ($type) = @_;
	return $result_index{$type} if defined $result_index{$type};
	$result_index{$type} = $result_key_count;
	$reverse_result_index{$result_key_count} = $type;
	return $result_key_count++;
}

sub rbuf
{
	die if grep { ref($_) && reftype($_) ne 'CODE' } @_;
	push (@$rbuf, @_);
}

sub postbuf
{
	push (@post_intercept_push, @_);
}

#
# True if defined and true or defined and empty
# False if 0 or 
#
sub boolean
{
	my ($b, $default) = @_;
	return $default unless defined $b;
	$b = lc($b);
	return 0 if $b eq 'false';
	return 0 if $b eq 'no';
	return 0 if $b eq 'off';
	return 1 if $b eq '';
	return 1 if $b;
	return 0;
}

#### METHODS

sub new
{
	my ($pkg, %opts) = @_;
	my $self = bless {
		tagset		=> new_hash(%base_tags),
		modules		=> 1,
		packages	=> {},
		modules		=> '',
		options		=> \%opts,
		pre_compile_cb	=> [],
	}, $pkg;
	return $self;
}

my $module_count = 0;
my %module_bits;

sub module_bits
{
	my ($pkg) = @_;
	$pkg = ref($pkg) if ref($pkg);
	return $module_bits{$pkg} if defined $module_bits{$pkg};
#print STDERR "# Allocating module bits for $pkg (at $module_count)\n";
	$module_bits{$pkg} = '';
	vec($module_bits{$pkg}, $module_count++, 1) = 1;
	return $module_bits{$pkg};
}

sub intercept_exclusive
{
	my ($self, $tobj, $tag_pkg, $priority, %tags) = @_;
	$self->intercept($tobj, $tag_pkg, %tags);
	for my $t (keys %tags) {
		if (! $dispatch{$t}) {
			$dispatch{$t} = HTML::Transmorgify::Exclusive->new($tag_pkg);
		} elsif ($dispatch{$t}->exclusive) {
			$dispatch{$t} = HTML::Transmorgify::MutuallyExclusive->more($tag_pkg);
		} else {
			die;
		}
	}
}

sub intercept_shared
{
	my ($self, $tobj, $tag_pkg, $priority, %tags) = @_;
	die if $priorities{$tag_pkg} && $priorities{$tag_pkg} != $priority;
	$priorities{$tag_pkg} = $priority;
	$self->intercept($tobj, $tag_pkg, %tags);
	for my $t (keys %tags) {
		if (! $dispatch{$t}) {
			$dispatch{$t} = HTML::Transmorgify::Stack->new($tag_pkg);
		} elsif ($dispatch{$t}->exclusive) {
			die;
		} else {
			$dispatch{$t} = HTML::Transmorgify::Stack->more($tag_pkg);
		}
	}
}

sub intercept_pre_compile
{
	my ($self, $cb) = @_;
	push(@{$self->{pre_compile_cb}}, $cb);
}

sub queue_capture
{
	my ($cb) = @_;
	push(@queued_captures, $cb);
}

sub queue_intercept
{
	my ($tag_pkg, %new) = @_;
	my @k = $tag_pkg
		? (map { "$tag_pkg $_" } keys %new)
		: (keys %new);
	@queued_intercepts{@k} = values %new;
}

sub intercept
{
	my ($self, $tobj, $tag_pkg, %new) = @_;
	my %opts;
	if (ref $_[0]) {
		%opts = %{shift(@_)};
	}
	my $ts;
	if (ref $tobj) {
		$tobj->{modules} |= $self->module_bits;
		$ts = $tobj->{tagset};
	} elsif ($intercept_okay) {
		$modules |= $self->module_bits;
		$ts = $tagset;
	} else {
		die;
	}
	my @k = $tag_pkg
		? (map { "$tag_pkg $_" } keys %new)
		: (keys %new);
	my %old = map { $_ => $ts->{$_} } @k;
	@$ts{@k} = values %new;
	return %old;
}

sub add_tags { die "must redefine" }

sub mixin
{
	my ($self, $module) = @_;
	load $module;
	$module->add_tags($self);
}

sub process
{
	my $self = shift;
	die unless blessed $self;
	local($tagset) = $self->{tagset};
	local($modules) = $self->{modules};
	local($process_text_ref) = \$_[0];
	local($intercept_okay) = 1;
	shift;
	local($invocation_options) = {};
	$invocation_options = shift if ref $_[0];
	local(%variables) = @_;
	local($query_param) = $invocation_options->{query_param} || {};
	local($original_file) = local($input_file) = $invocation_options->{input_file} || (caller())[1];
	local($original_line) = local($input_line) = $invocation_options->{input_line} || (caller())[2];
	local($xml_quoting) = first_key('xml_quoting', 0, $invocation_options, $self->{options});
	$_->($self) for @{$self->{pre_compile_cb}};
	my $buf = compile($modules, $process_text_ref);
	local(@result_array) = ( '' );
#print Dumper([__FILE__, __LINE__, $rbuf]) if $debug;
	run($buf);
	return map { $_ => $result_array[$result_index{$_}] } keys %result_index
		if wantarray;
	return $result_array[0];
}


#### (SEMI)PRIVATE FUNCTIONS

sub run
{
	my $buf = shift;

	return run($buf, \@result_array) unless $_[0];

	local $result = shift;

	for my $i (@$buf) {
		if (ref $i) {
use Data::Dumper;
die Dumper($buf) unless reftype($i) eq 'CODE';
			$i->();
		} else {
			printf STDERR "# Appending %s\n", dstring($i) if $debug;
			$result->[0] .= $i;
		}
	}
}

sub first_key
{
	my ($key, $default, @hashes) = @_;
	for my $h (@hashes) {
		next unless exists $h->{$key};
		return $h->{$key};
	}
	return $default;
}

sub dstring
{
use Carp qw(confess);
	my ($s, @pos) = @_;
	return "UNDEF" unless defined $s;
confess() if grep { $_ > length($s) } @pos; # XXX
	substr($s, $_, 0) = "*##*" for (reverse sort { $a <=> $b } @pos);
	$s =~ s/\n/\\n/g;
	return $s;
}

sub eat_cr
{
my $o = pos($$textref);
	$$textref =~ /\G\n/gcs;
my $n = pos($$textref);
	printf STDERR "# EAT_CR %s\n", dstring($$textref, $o, $n) if $debug;
}

sub compile
{
	my $cacheline = shift;
	local $textref = shift;

	printf STDERR "# Invoking compile(%s, %s) for %s\n", tobits($cacheline), scalar(%$tagset), dstring($$textref, 0) if $debug;
	my $md5;
confess() unless defined $$textref;
	$md5 = md5_hex($$textref);
	my $cached = $compiled{$cacheline}{$md5};
	if ($cached) {
		print STDERR "# returning cached result\n" if $debug;
		return $cached;
	}
	local($rbuf) = \my @rbuf;
	pos($$textref) = 0;
	my $ccb = sub {
		continue_compile(undef, undef, undef);
	};
	if ($wrap_compile_cb) {
		local($wrap_compile_cb);
		$wrap_compile_cb->($ccb);
	} else {
		$ccb->();
	}
	$compiled{$cacheline}{$md5} = \@rbuf;
	printf STDERR "# Done compile(%s, %s) now at %d\n", tobits($cacheline), scalar(%$tagset), pos($$textref) if $debug;
	return $rbuf;
}

sub capture_compile
{
	my $onetag = $_[0];
	die unless $onetag;
	local($dispatch{"/$onetag"}) = HTML::Transmorgify::Deferred->new($dispatch{"/$onetag"});
	my $buf = [];
	{
		local($rbuf) = $buf;
		continue_compile(@_);
	}
	return $buf unless wantarray;
	return ($buf, $dispatch{"/$onetag"});
}

my $no_opts = {};

sub continue_compile
{
	my ($onetag, $starting_attr, $opts, %tags) = @_;
	$opts ||= $no_opts;
	my @ks = $opts->{tag_package}
		? (map { "$opts->{tag_package} $_" } keys %tags)
		: (keys %tags);

print STDERR "# overriding ".join(';', @ks)."\n" if $debug;
	local(@$tagset{@ks}) = values %tags;
	my $start = pos($$textref);
	printf STDERR "# Invoking continue_compile(%s/%s) at %d for %s from %d\n", $onetag || '?', scalar(%$tagset), $start, dstring($$textref, $start), (caller())[2] if $debug;
	if ($onetag) {
		local($dispatch{"/$onetag"}) = HTML::Transmorgify::CloseTag->new($dispatch{"/$onetag"});
		my $finaltag = do_compile();
		bomb("Could not find closing </$onetag>", starting_attr => $starting_attr) 
			unless defined($finaltag) && $finaltag eq "/$onetag";
	} else {
		do_compile();
	}
	printf STDERR "# Done continue_compile(%s/%s) at %d, now at %d\n", $onetag || '?', scalar(%$tagset), $start, pos($$textref) if $debug;
}

sub do_compile
{
	my $copied = pos($$textref);
	print STDERR "# starting compile, pos = $copied\n" if $debug;
	while (pos($$textref) < length($$textref)) {
		printf STDERR "## pos = %d\n", pos($$textref) if $debug;
		$$textref =~ m{ \G [^<]+ }xgc;
		my $before = pos($$textref);
		unless ($$textref =~ m{ \G < ( /? [^>\s]+ ) }xgc) {
			$$textref =~ m{ \G < }xgc;
			next;
		}
		my $tag = $1;
		$$textref =~ m{ \G \s+ }xgc;
		if ($dispatch{$tag}) {
			my $boring = substr($$textref, $copied, $before-$copied);

			if ($before-$copied) {
				printf STDERR "# pushing pre-tag stuff %d-%d: %s (%s)\n", $copied, $before, dstring($boring), dstring($$textref, $copied, $before) if $debug;
				push(@$rbuf, $boring);
			}

			my @atvals;
			while ( $$textref =~ m{ 
				\G 
				([\w\.]+)
				(?: 
					=
					(?: ([\w\.]*) | '([^']+)' | "([^"]+)" )   	
				)?
				(?=[\s>]) 
				}xgc  
			) {
				my $name = $1;
				my $val = (first { defined $_} ($2, $3, $4));
				push(@atvals, $name => $val);
				$$textref =~ m{ \G \s+ }xgc;
			}
			$$textref =~ m{ \G (/?) > }xgc;

			my $closed = $1;

			printf STDERR "# callback for %s at %d: %s\n", $tag, $copied, dstring($$textref, $copied, pos($$textref)) if $debug;
			my $attr = HTML::Transmorgify::Attributes->new($tag, \@atvals, $closed);
			my $r = $dispatch{$tag}->call($tag, $attr, $closed);
			if ($r && $r == 22) {
				printf STDERR "# %s indicates - done wih compile() pos is %d\n", $tag, pos($$textref) if $debug;
				return $tag;
			}
			printf STDERR "# continuing compile at %d: %s\n", pos($$textref), dstring($$textref, $copied, pos($$textref)) if $debug;
			$copied = pos($$textref);
		} elsif ($dispatch{macro}) {
			if ($$textref =~ m{ \G (?: [^'">] | '[^'<>]*' | "[^"<>]*" )* > }xgc) {
				# easy skip
				printf STDERR "# advancing past tag with no callback & no macros (%s), now at %d: %s\n", $tag, pos($$textref), dstring($$textref, pos($$textref)) if $debug;
			} else {
				printf STDERR "# Tag with <> inside quotes found (%s) %s\n", pos($$textref), dstring($$textref, pos($$textref)) if $debug;
				my @atvals;
				while ( $$textref =~ m{ 
					\G 
					([\w\.]+)
					(?: 
						=
						(?: ([\w\.]*) | '([^']+)' | "([^"]+)" )   	
					)?
					(?=[\s>]) 
					}xgc  
				) {
					my $name = $1;
					my $val = (first { defined $_} ($2, $3, $4));
					push(@atvals, $name => $val);
					$$textref =~ m{ \G \s+ }xgc;
				}
				$$textref =~ m{ \G (/?) > }xgc;
				my $closed = $1;

				if (grep { /<macro\s/ } @atvals) {
					printf STDERR "# There are <macro> calls in the tag, compiling\n" if $debug;
					my $boring = substr($$textref, $copied, $before-$copied);

					if ($before-$copied) {
						printf STDERR "# Pushing pre-tag stuff %d-%d: %s (%s)\n", $copied, $before, $boring, dstring($$textref, $copied, $before) if $debug;
						push(@$rbuf, $boring);
					}
					my $attr = HTML::Transmorgify::Attributes->new($tag, \@atvals, $closed);
					push(@$rbuf, sub { $result->[0] .= "$attr" });
					$copied = pos($$textref);
					printf STDERR "# Continuing compile at %d\n", pos($$textref) if $debug;
				} else {
					printf STDERR "# advancing past tag with no macros (%s), now at %d: %s\n", $tag, pos($$textref), dstring($$textref, pos($$textref)) if $debug;
				}
			}
		} else {
			# advance to the end of the tag
			$$textref =~ m{ \G (?: [^'">] | '[^']*' | "[^"]*" )* > }xgc;
			printf STDERR "# Advancing past tag with no callback (%s), now at %d: %s\n", $tag, pos($$textref), dstring($$textref, pos($$textref)) if $debug;
		}
		if (@$rbuf > 1 && ! ref($rbuf->[-1]) && ! ref($rbuf->[-2])) {
			$rbuf->[-2] .= pop(@$rbuf);
		}
	}
	my $boring = substr($$textref, $copied);
	printf STDERR "# pushing final stuff %d-%d: %s (%s)\n", $copied, length($$textref), $boring, dstring($$textref, $copied) if $debug;
	push(@$rbuf, $boring) if length($boring);
	return;
}

sub bomb
{
	my ($message, %context) = @_;
	my $c = '';
	if ($context{attr}) {
		$c .= sprintf(" at <%s> from at %s, line %d",
			$context{starting_attr}->tag,
			$context{starting_attr}->location,
		);
	} 
	if ($context{starting_attr}) {
		$c .= sprintf(" from <%s> starting at %s, line %d",
			$context{starting_attr}->tag,
			$context{starting_attr}->location,
		);
	} 
	my $clev = $context{caller_level} || 0;
	die sprintf("Erorr: %s%s at %s:%d\n", $message, $c, (caller($clev))[1], (caller($clev))[2]);
}

sub dangling
{
	my ($attr, $closed) = @_;
	bomb(sprintf("<%s> found without a preceeding start tag in %s:%d", $attr->tag, $input_file, $input_line));
}

sub tobits
{
	join('', unpack("b*", $_[0]));
}

package HTML::Transmorgify::Attributes;

use strict;
use warnings;
use HTML::Transmorgify::Symbols;

import HTML::Transmorgify qw($tagset $textref $debug run dstring $rbuf $input_file $input_line $xml_quoting module_bits compile rbuf);

our @rtmp;
our %tagset_hash;

my $module_bits = module_bits('tag expand');

#
# $atvals are pairs representing the attributes.
# a value of undef indicates that the attribute 
# didn't have a value at all.  For example:
# <option selected> would be [ 'selected' => undef ]
#
#
# Boolean values like "selected", "checked", etc 
# are represented by having an undef value internally.
# If you request their value though, they return their
# own name.  get('selected') will return 'selected'.
#
# This mans you should not set values to the return value from
# get!
#

sub new
{
	my ($pkg, $tag, $atvals, $closed) = @_;

	use integer;

	my $dbug = $HTML::Transmorgify::debug;

	my $numattr = scalar(@$atvals)/2;

	my @callbacks;

	my $lastpos;
	{
		my $i = 1;
		while ($i <= @$atvals && ! defined($atvals->[$i])) {
			$i += 2;
		}
		$lastpos = ($i - 3) / 2;
	}

	my %vals;
	for (my $j = 0; $j < @$atvals; $j+=2) {
		$vals{lc($atvals->[$j])} = $atvals->[$j+1];
	}

	my %needs_cooking = map { $_ => scalar($vals{$_} =~ /<\w+\s/) } grep { defined($vals{$_}) } keys %vals;

	my %cooked;
	my @hidden;
	my %hidden;

	my $f_raw = sub {
		my ($at, $pos) = @_;
		if (defined($pos) && $pos <= $lastpos) {
			return $atvals->[$pos*2];
		}
		if (exists $vals{$at}) {
			return $vals{$at} if defined $vals{$at};
			return $at; # boolean
		}
		return;
	};

	my $f_get = sub {
		my ($at, $pos) = @_;
		if (defined($pos) && $pos <= $lastpos) {
			return $atvals->[$pos*2];
		}
		return unless exists $vals{$at};
		unless ($needs_cooking{$at}) {
			return $vals{$at} if defined $vals{$at};
			return $at; # boolean
		}

		printf "# Cooking %s for get attr=%s\n", HTML::Transmorgify::dstring($vals{$at}), $at if $dbug;

		unless ($cooked{$at}) {
			$cooked{$at} = compile($HTML::Transmorgify::modules, \$vals{$at});
		}

		local(@rtmp) = ( '' );
		run($cooked{$at}, \@rtmp);

		use Data::Dumper;
		print STDERR Dumper([ __FILE__, __LINE__, $cooked{$at}]) if $dbug;

		printf "# get(%s) = '%s'\n", $at, dstring($rtmp[0]) if $dbug;

		die if @rtmp > 1;

		return $rtmp[0];
	};

	my $f_static = sub {
		my ($at, $pos) = @_;
		if (defined($pos) && $pos <= $lastpos) {
			return $atvals->[$pos*2];
		}
		return unless exists $vals{$at};
		return $at unless defined $vals{$at}; # boolean
		return $vals{$at} unless $needs_cooking{$at};
		return;
	};

	# stringify
	my $f_stringify = sub {
		my ($self) = @_;
		my $rv;
		for my $cb (@callbacks) {
			my $res = $cb->($self);
			if (defined $res) {
				die "multiple callbacks providing results for $tag" if defined $rv;
				$rv = $res;
			}
		}
		return $rv if defined $rv;
		my $text = "<$tag";
		for(my $i = 0; $i <= $lastpos; $i++) {
			next if defined($hidden[$i]);
			$text .= " " . _safe($atvals->[$i*2]);
		}
		for(my $j = $lastpos+1; $j < $numattr; $j++) {
			my $a = $atvals->[$j*2];
			next if defined($hidden{$a});
			if (defined($atvals->[$j*2+1])) {
				$text .= " $a=" . _safe($f_get->($atvals->[$j*2]), 1);
			} else {
				$text .= " $a";
			}
		}
# use Scalar::Util qw(refaddr);
# $text .= ' refaddr="' . refaddr($atvals) . '"' if $dbug;

		$text .= ">";
		printf STDERR "# tag text = '%s'\n", dstring($text) if $dbug;
		return $text;
	};

	my $f_hide_position = sub {
		@hidden[@_] = @_;
	};

	my $f_set = sub {
		while (my ($k, $v) = splice(@_, 0, 2)) {
			unless (exists $vals{$k}) {
				push(@$atvals, $k, $v);
				$numattr++;
			}
			print STDERR "# Setting $tag attribute $k = '$v'\n" if $dbug;
			$vals{$k} = $v;
		}
	};

	my $invoking_textref = $textref;
	my $invoking_pos = pos($$textref);
	my $invoking_file = $input_file;
	my $invoking_line = $input_line;
	my $lines_in;

	my $f_location = sub {
		$lines_in ||= (substr($$invoking_textref, 0, $invoking_pos) =~ tr/\n/\n/);
		($invoking_file, $invoking_line + $lines_in)
	};

	my $eval_at_runtime = grep { $_ } values %needs_cooking;

	return bless [ 
		$f_raw, 			# 0
		$f_get, 			# 1
		$f_stringify, 			# 2
		$closed,			# 3
		$f_static,			# 4
		\%vals,				# 5
		sub { @hidden[@_] = @_ },	# 6
		$lastpos,			# 7
		sub { @hidden{@_} = @_ },	# 8
		$f_set,				# 9
		$tag, 				# 10
		$f_location, 			# 11
		$eval_at_runtime,		# 12
		\%needs_cooking,		# 13
		\@callbacks,			# 14
	], $pkg;
}

# XXX add runtime pre-stringify callback funcs

sub raw			{ my $self = shift; $self->[0]->(@_) };
sub get			{ my $self = shift; $self->[1]->(@_) };
sub as_string		{ my $self = shift; $self->[2]->($self, @_) };
sub closed		{ my $self = shift; $self->[3]       };
sub static		{ my $self = shift; $self->[4]->(@_) };
sub vals		{ my $self = shift; $self->[5]       };
sub hide_position	{ my $self = shift; $self->[6]->(@_) };
sub last_position	{ my $self = shift; return @_ ? ($_[0] <= $self->[7]) : $self->[7] };
sub hide		{ my $self = shift; $self->[8]->(@_) };
sub set			{ my $self = shift; $self->[9]->(@_) };
sub tag			{ my $self = shift; $self->[10]       };
sub location		{ my $self = shift; $self->[11]->(@_) };
sub needs_cooking	{ my $self = shift; $self->[13]	     };
sub output_callback	{ my $self = shift; push(@{$self->[14]}, @_); $self->[12] = 2 };

sub eval_at_runtime
{
	my $self = shift;
	my $r = $self->[12];
	$self->[12] = $_[0] if @_;
	return $r;
}

sub boolean
{
	my ($self, $name, $pos, $default, %opts) = @_;
	my $b = $opts{raw}
		? $self->raw($name, $pos, %opts)
		: $self->get($name, $pos, %opts);
	$default = 0 unless defined $default;
	return HTML::Transmorgify::boolean($b, $default);
}

sub static_action
{
	my ($attr, $tag, $sub) = @_;
	my @tags = ref($tag) ? @$tag : $tag;
	for my $t (@tags) {
		unless ($attr->static($t) || ! defined $attr->raw($t)) {
			rbuf($sub);
			return;
		}
	}
	$sub->(1);
}
	
sub add_to_result 
{
	my $self = shift;
	if ($self->[12]) {
		rbuf(sub { $HTML::Transmorgify::result->[0] .= $self->as_string });
	} else {
		push(@$HTML::Transmorgify::rbuf, $self->as_string);
	}
}

use overload
	'""' => \&as_string,
	;

sub _safe
{
	my ($val, $is_val) = @_;

	if (! defined($val)) {
		return '""';
	} elsif ($val !~ /[^\w.]/ && ! ($is_val && $xml_quoting)) {
		return $val;
	} elsif ($val =~ /'/) {
		return qq{'$val'};
	} else {
		return qq{"$val"};
	}
	
}


package HTML::Transmorgify::MutuallyExclusive;

use strict;
use warnings;
import HTML::Transmorgify qw($debug);

sub call
{
	my $self = shift;
	my $tag = shift;
	my $attr = shift;
	my $i = 0;
	print STDERR "Callback MUTUALLY EXCLUSIVE for $tag\n" if $debug;
	while ($i < @$self) {
		my $cb = $HTML::Transmorgify::tagset->{"$self->[$i] $tag"};
		$i++;
		next unless $cb;
		my $rv = $cb->($attr, @_);
		while ($i < @$self) {
			my $cb2 = $HTML::Transmorgify::tagset->{"$self->[$i] $tag"};
			$i++;
			die if $cb2;
		}
		if ($rv) {
			printf STDERR "# Will interpolate $tag later, current value is $attr\n" if $debug;
			$attr->add_to_result;
		}
		return 0;
	}
	$attr->add_to_result;
	return 0;
}

sub exclusive { 1 };

sub new
{
	my ($pkg, @tags) = @_;
	return bless \@tags, $pkg;
}

sub more
{
	my ($self, @tags) = @_;
	push(@$self, @tags);
}

package HTML::Transmorgify::Exclusive;

use strict;
use warnings;
import HTML::Transmorgify qw($debug);

sub new
{
	my ($pkg, $tag_pkg) = @_;
	return bless \$tag_pkg, $pkg;
}

sub call
{
	my $self = shift;
	my $tag = shift;
	my $attr = shift;
	print STDERR "# Callback EXCLUSIVE for $tag\n" if $debug;
	my $cb = $HTML::Transmorgify::tagset->{"$$self $tag"};
	unless ($cb) {
		print STDERR "# No <$$self $tag> callback\n" if $debug;
		push(@$rbuf, "$attr");
		return 0;
	}
	my $rv = $cb->($attr, @_);
	if ($rv) {
		$attr->add_to_result;
		printf STDERR "# Including exclusive attribute for $attr\n" if $debug;
	} elsif ($debug) {
		printf STDERR "# NOT Including exclusive attribute for $attr\n" if $debug;
	}
	return 0;
}

sub exclusive { 1 };

sub more
{
	my ($self, $tag) = @_;
	return HTML::Transmorgify::MutuallyExclusive->new($$self, $tag);
}

package HTML::Transmorgify::Stack;

use strict; 
use warnings;
import HTML::Transmorgify qw(%priorities $debug continue_compile capture_compile rbuf);

#
# Tags for shared callbacks are always included in the output stream
#

sub call 
{
	my $self = shift;
	my $tag = shift;
	my $attr = shift;
	my $i = 0;
	local(%HTML::Transmorgify::queued_intercepts);
	local(@HTML::Transmorgify::queued_captures);
	local(@HTML::Transmorgify::post_intercept_push);

	print STDERR "Callback STACK for $tag\n" if $debug;
	my @rt_callback;
	while ($i < @$self) {
		my $cb = $HTML::Transmorgify::tagset->{"$self->[$i] $tag"};
		$i++;
		unless ($cb) {
			print STDERR "NO callback for ".$self->[$i-1]." <$tag>\n" if $debug;
			next;
		}
		print STDERR "Calling ".$self->[$i-1]." <$tag>...\n" if $debug;
		my $r = $cb->($attr, @_);
		if (ref($r) && ref($r) eq 'CODE') {
			push(@rt_callback, $r);
		}
	}
	if (@rt_callback) {
		rbuf (sub { $_->($attr) for @rt_callback });
		$attr->eval_at_runtime(1);
	}
	$attr->add_to_result;
	printf STDERR "# Including attribute for $attr\n" if $debug;
	if (@HTML::Transmorgify::queued_captures) {
		print STDERR "# Capturing to /$tag with queued intercepts in play: ".join(';', keys %HTML::Transmorgify::queued_intercepts)."\n" if $debug;
		my ($b, $deferred) = capture_compile($tag, $attr, undef, %HTML::Transmorgify::queued_intercepts);
		for my $ccb (@HTML::Transmorgify::queued_captures) {
			$ccb->($b);
		}
		push(@$HTML::Transmorgify::rbuf, @$b);
		$deferred->doit();
	} elsif (keys %HTML::Transmorgify::queued_intercepts) {
		print STDERR "# Processing to /$tag with queued intercepts in play: ".join(';', keys %HTML::Transmorgify::queued_intercepts)."\n" if $debug;
		continue_compile($tag, $attr, undef, %HTML::Transmorgify::queued_intercepts);
	}
	push(@$HTML::Transmorgify::rbuf, @HTML::Transmorgify::post_intercept_push);

	return 0;
}

sub exclusive { 0 };

sub new
{
	my ($pkg, @tag_pkgs) = @_;
	my $self = bless \@tag_pkgs, $pkg;
	$self->more;
	return $self;
}

sub more
{
	my ($self, @tag_pkgs) = @_;
	@$self = sort { $priorities{$a} <=> $priorities{$b} } @$self, @tag_pkgs;
}

package HTML::Transmorgify::CloseTag;

use strict;
use warnings;
import HTML::Transmorgify qw($debug);

sub new 
{
	my ($pkg, $oldval) = @_;
	return bless \$oldval, $pkg;
}

sub call 
{
	my $self = shift;
	if ($$self) {
print STDERR "# CLOSE TAG WILL CALL CALLBACK\n" if $debug;
		$$self->call(@_);
	} else {
print STDERR "# CLOSE TAG NO CALLBACK TO CALL\n" if $debug;
		my $attr = shift;
		$attr->add_to_result;
	}
	return 22;
}

package HTML::Transmorgify::Deferred;

use strict;
use warnings;

import HTML::Transmorgify qw($debug);

sub new 
{
	my ($pkg, $oldval) = @_;
	return bless [$oldval], $pkg;
}

sub call 
{
	my $self = shift;
	push(@$self, @_);
	return 0;
}

sub doit
{
	my $self = shift;
	if ($self->[0]) {
		my $cb = shift(@$self);
		$cb->call(@$self);
	} else {
		my $attr = shift(@$self);
		$attr->add_to_result;
	}
	return 0;
}

1;
