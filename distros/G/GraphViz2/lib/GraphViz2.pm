package GraphViz2;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Section::Simple 'get_data_section';
use File::Temp;		# For newdir().
use File::Which;	# For which().
use Moo;
use IPC::Run3; # For run3().
use Types::Standard qw/Any ArrayRef HasMethods HashRef Int Str/;

our $VERSION = '2.66';

my $DATA_SECTION = get_data_section; # load once
my $DEFAULT_COMBINE = 1; # default for combine_node_and_port
my %CONTEXT_QUOTING = (
	label => '\\{\\}\\|<>\\s"',
	label_legacy => '"',
);
my %PORT_QUOTING = map +($_ => sprintf "%%%02x", ord $_), qw(% \\ : " { } | < >);
my $PORT_QUOTE_CHARS = join '', '[', (map quotemeta, sort keys %PORT_QUOTING), ']';

has command =>
(
	default  => sub{[]},
	is       => 'ro',
	isa      => ArrayRef,
	required => 0,
);

has dot_input =>
(
	is       => 'lazy',
	isa      => Str,
	required => 0,
);

sub _build_dot_input {
	my ($self) = @_;
	join('', @{ $self->command }) . "}\n";
}

has dot_output =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has edge =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has edge_hash =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has global =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has graph =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has im_meta =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has logger =>
(
	is       => 'rw',
	isa      => HasMethods[qw(debug error)],
	required => 0,
);

has node =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has node_hash =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has scope =>
(
	default  => sub{[]},
	is       => 'ro',
	isa      => ArrayRef,
	required => 0,
);

has subgraph =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has verbose =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

my $VALID_ATTRIBUTES = _build_valid_attributes();
sub valid_attributes { $VALID_ATTRIBUTES }
sub _build_valid_attributes {
	my %data = map +($_ => [
		grep !/^$/ && !/^(?:\s*)#/, split /\n/, $$DATA_SECTION{$_}
	]), keys %$DATA_SECTION;
	# Reorder them so the major key is the context and the minor key is the attribute.
	# I.e. $attribute{global}{directed} => undef means directed is valid in a global context.
	my %attribute;
	# Common attributes are a special case, since one attribute can be valid is several contexts...
	# Format: attribute_name => context_1, context_2.
	for my $a (@{ delete $data{common_attribute} }) {
		my ($attr, $contexts) = split /\s*=>\s*/, $a;
		$attribute{$_}{$attr} = undef for split /\s*,\s*/, $contexts;
	}
	@{$attribute{$_}}{ @{$data{$_}} } = () for keys %data;
	@{$attribute{subgraph}}{ keys %{ delete $attribute{cluster} } } = ();
	\%attribute;
}

has valid_output_format => (
	is       => 'lazy',
	isa      => HashRef,
	required => 0,
);

sub _build_valid_output_format {
	my ($self) = @_;
	run3
		['dot', "-T?"],
		undef,
		\my $stdout,
		\my $stderr,
		;
	$stderr =~ s/.*one of:\s+//;
	+{ map +($_ => undef), split /\s+/, $stderr };
}

sub _dor { return $_[0] if defined $_[0]; $_[1] } # //

sub BUILD
{
	my($self)    = @_;
	my($globals) = $self -> global;
	my($global)  =
	{
		combine_node_and_port	=> _dor($$globals{combine_node_and_port}, $DEFAULT_COMBINE),
		directed		=> $$globals{directed} ? 'digraph' : 'graph',
		driver			=> $$globals{driver} || scalar(which('dot')),
		format			=> $$globals{format} ||	'svg',
		im_format		=> $$globals{im_format} || 'cmapx',
		label			=> $$globals{directed} ? '->' : '--',
		name			=> _dor($$globals{name}, 'Perl'),
		record_shape	=> ($$globals{record_shape} && $$globals{record_shape} =~ /^(M?record)$/) ? $1 : 'Mrecord',
		strict			=> _dor($$globals{strict},  0),
		timeout			=> _dor($$globals{timeout}, 10),
	};
	my($im_metas)	= $self -> im_meta;
	my($im_meta)	=
	{
		URL => $$im_metas{URL} || '',
	};

	$self -> global($global);
	$self -> im_meta($im_meta);
	$self->validate_params('global',	$self->global);
	$self->validate_params('graph',		$self->graph);
	$self->validate_params('im_meta',	$self->im_meta);
	$self->validate_params('node',		$self->node);
	$self->validate_params('edge',		$self->edge);
	$self->validate_params('subgraph',	$self->subgraph);
	push @{ $self->scope }, {
		edge     => $self -> edge,
		graph    => $self -> graph,
		node     => $self -> node,
		subgraph => $self -> subgraph,
	 };

	my(%global)		= %{$self -> global};
	my(%im_meta)	= %{$self -> im_meta};

	$self -> log(debug => "Default global:  $_ => $global{$_}")	for sort keys %global;
	$self -> log(debug => "Default im_meta: $_ => $im_meta{$_}")	for grep{$im_meta{$_} } sort keys %im_meta;

	my($command) = (${$self -> global}{strict} ? 'strict ' : '')
		. (${$self -> global}{directed} . ' ')
		. ${$self -> global}{name}
		. " {\n";

	for my $key (grep{$im_meta{$_} } sort keys %im_meta)
	{
		$command .= _indent(qq|$key = "$im_meta{$key}"; \n|, $self->scope);
	}

	push @{ $self->command }, $command;

	$self -> default_graph;
	$self -> default_node;
	$self -> default_edge;

} # End of BUILD.

sub _edge_name_port {
	my ($self, $name) = @_;
	$name = _dor($name, '');
	# Remove :port:compass, if any, from name.
	# But beware Perl-style node names like 'A::Class'.
	my @field = split /(:(?!:))/, $name;
	$field[0] = $name if !@field;
	# Restore Perl module names:
	# o A: & B to A::B.
	# o A: & B: & C to A::B::C.
	splice @field, 0, 3, "$field[0]:$field[2]" while $field[0] =~ /:$/;
	# Restore:
	# o : & port to :port.
	# o : & port & : & compass to :port:compass.
	$name = shift @field;
	($name, join '', @field);
}

sub add_edge
{
	my($self, %arg) = @_;
	my $from    = _dor(delete $arg{from}, '');
	my $to      = _dor(delete $arg{to}, '');
	my $label   = _dor($arg{label}, '');
	$label      =~ s/^\s*(<)\n?/$1/;
	$label      =~ s/\n?(>)\s*$/$1/;
	$arg{label} = $label if (defined $arg{label});

	$self->validate_params('edge', \%arg);

	my @nodes;
	for my $tuple ([ $from, 'tailport' ], [ $to, 'headport' ]) {
		my ($name, $argname) = @$tuple;
		my $port = '';
		if ($self->global->{combine_node_and_port}) {
			($name, $port) = $self->_edge_name_port($name);
		} elsif (defined(my $value = delete $arg{$argname})) {
			$port = join ':', '', map qq{"$_"}, map escape_port($_), ref $value ? @$value : $value;
		}
		push @nodes, [ $name, $port ];
		next if (my $nh = $self->node_hash)->{$name};
		$self->log(debug => "Implicitly added node: $name");
		$nh->{$name}{attributes} = {};
	}

	# Add this edge to the hashref of all edges.
	push @{$self->edge_hash->{$nodes[0][0]}{$nodes[1][0]}}, {
		attributes => \%arg,
		from_port  => $nodes[0][1],
		to_port    => $nodes[1][1],
	};

	# Add this edge to the DOT output string.
	my $dot = $self->stringify_attributes(join(" ${$self->global}{label} ", map qq|"$_->[0]"$_->[1]|, @nodes), \%arg);
	push @{ $self->command }, _indent($dot, $self->scope);
	$self -> log(debug => "Added edge: $dot");

	return $self;
} # End of add_edge.

sub _indent {
	my ($text, $scope) = @_;
	return '' if $text !~ /\S/;
	(' ' x @$scope) . $text;
}

sub _compile_record {
	my ($port_count, $item, $add_braces, $quote_more) = @_;
	my $text;
	if (ref $item eq 'ARRAY') {
		my @parts;
		for my $l (@$item) {
			($port_count, my $t) = _compile_record($port_count, $l, 1, $quote_more);
			push @parts, $t;
		}
		$text = join '|', @parts;
		$text = "{$text}" if $add_braces;
	} elsif (ref $item eq 'HASH') {
		my $port = $item->{port} || 0;
		$text = escape_some_chars(_dor($item->{text}, ''), $CONTEXT_QUOTING{$quote_more ? 'label' : 'label_legacy'});
		if ($port) {
			$port =~ s/^\s*<?//;
			$port =~ s/>?\s*$//;
			$port = escape_port($port);
			$text = "<$port> $text";
		}
	} else {
		$text = "<port".++$port_count."> " . escape_some_chars($item, $CONTEXT_QUOTING{$quote_more ? 'label' : 'label_legacy'});
	}
	($port_count, $text);
}

sub add_node {
	my ($self, %arg) = @_;
	my $name = _dor(delete $arg{name}, '');
	$self->validate_params('node', \%arg);
	my $node                  = $self->node_hash;
	%arg                      = (%{$$node{$name}{attributes} || {}}, %arg);
	$$node{$name}{attributes} = \%arg;
	my $label                 = _dor($arg{label}, '');
	$label                    =~ s/^\s*(<)\n?/$1/;
	$label                    =~ s/\n?(>)\s*$/$1/;
	$arg{label}               = $label if defined $arg{label};
	# Handle ports.
	if (ref $label eq 'ARRAY') {
		(undef, $arg{label}) = _compile_record(0, $label, 0, !$self->global->{combine_node_and_port});
		$arg{shape} ||= $self->global->{record_shape};
	} elsif ($arg{shape} && ( ($arg{shape} =~ /M?record/) || ( ($arg{shape} =~ /(?:none|plaintext)/) && ($label =~ /^</) ) ) ) {
		# Do not escape anything.
	} elsif ($label) {
		$arg{label} = escape_some_chars($arg{label}, $CONTEXT_QUOTING{label_legacy});
	}
	my $dot = $self->stringify_attributes(qq|"$name"|, \%arg);
	push @{ $self->command }, _indent($dot, $self->scope);
	$self->log(debug => "Added node: $dot");
	return $self;
}

sub default_edge
{
	my($self, %arg) = @_;

	$self->validate_params('edge', \%arg);

	my $scope    = $self->scope->[-1];
	$$scope{edge} = {%{$$scope{edge} || {}}, %arg};

	push @{ $self->command }, _indent($self->stringify_attributes('edge', $$scope{edge}), $self->scope);
	$self -> log(debug => 'Default edge: ' . join(', ', map{"$_ => $$scope{edge}{$_}"} sort keys %{$$scope{edge} }) );

	return $self;

} # End of default_edge.

# -----------------------------------------------

sub default_graph
{
	my($self, %arg) = @_;

	$self->validate_params('graph', \%arg);

	my $scope    = $self->scope->[-1];
	$$scope{graph} = {%{$$scope{graph} || {}}, %arg};

	push @{ $self->command }, _indent($self->stringify_attributes('graph', $$scope{graph}), $self->scope);
	$self -> log(debug => 'Default graph: ' . join(', ', map{"$_ => $$scope{graph}{$_}"} sort keys %{$$scope{graph} }) );

	return $self;

} # End of default_graph.

# -----------------------------------------------

sub default_node
{
	my($self, %arg) = @_;

	$self->validate_params('node', \%arg);

	my $scope    = $self->scope->[-1];
	$$scope{node} = {%{$$scope{node} || {}}, %arg};

	push @{ $self->command }, _indent($self->stringify_attributes('node', $$scope{node}), $self->scope);
	$self -> log(debug => 'Default node: ' . join(', ', map{"$_ => $$scope{node}{$_}"} sort keys %{$$scope{node} }) );

	return $self;

} # End of default_node.

# -----------------------------------------------

sub default_subgraph
{
	my($self, %arg) = @_;

	$self->validate_params('subgraph', \%arg);

	my $scope    = $self->scope->[-1];
	$$scope{subgraph} = {%{$$scope{subgraph} || {}}, %arg};

	push @{ $self->command }, _indent($self->stringify_attributes('subgraph', $$scope{subgraph}), $self->scope);
	$self -> log(debug => 'Default subgraph: ' . join(', ', map{"$_ => $$scope{subgraph}{$_}"} sort keys %{$$scope{subgraph} }) );

	return $self;

} # End of default_subgraph.

sub escape_port {
	my ($s) = @_;
	$s =~ s/($PORT_QUOTE_CHARS)/$PORT_QUOTING{$1}/g;
	$s;
}

sub escape_some_chars {
	my ($s, $quote_chars) = @_;
	return $s if substr($s, 0, 1) eq '<'; # HTML label
	$s =~ s/(\\.)|([$quote_chars])/ defined($1) ? $1 : '\\' . $2 /ge;
	return $s;
}

sub log
{
	my($self, $level, $message) = @_;
	$level   ||= 'debug';
	$message ||= '';

	if ($self->logger) {
		$self->logger->$level($message);
	} else {
		die $message if $level eq 'error';
		print "$level: $message\n" if $self->verbose;
	}

	return $self;

} # End of log.

# -----------------------------------------------

sub pop_subgraph
{
	my($self) = @_;

	pop @{ $self->scope };
	push @{ $self->command }, _indent("}\n", $self->scope);

	return $self;

}	# End of pop_subgraph.

# -----------------------------------------------

sub push_subgraph
{
	my($self, %arg) = @_;
	my($name) = delete $arg{name};
	$name     = defined($name) && length($name) ? qq|"$name"| : '';

	$self->validate_params('graph',    $arg{graph});
	$self->validate_params('node',     $arg{node});
	$self->validate_params('edge',     $arg{edge});
	$self->validate_params('subgraph', $arg{subgraph});

	$arg{subgraph} = { %{ $self->subgraph||{} }, %{$arg{subgraph}||{}} };

	push @{ $self->command }, "\n" . _indent(join(' ', grep length, "subgraph", $name, "{\n"), $self->scope);
	push @{ $self->scope }, \%arg;
	$self -> default_graph;
	$self -> default_node;
	$self -> default_edge;
	$self -> default_subgraph;

	return $self;

}	# End of push_subgraph.

# -----------------------------------------------

sub run
{
	my($self, %arg)		= @_;
	my($driver)			= delete $arg{driver}			|| ${$self -> global}{driver};
	my($format)			= delete $arg{format}			|| ${$self -> global}{format};
	my($im_format)		= delete $arg{im_format}		|| ${$self -> global}{im_format};
	my($timeout)		= delete $arg{timeout}			|| ${$self -> global}{timeout};
	my($output_file)	= delete $arg{output_file}		|| '';
	my($im_output_file)	= delete $arg{im_output_file}	|| '';

	for ($format, $im_format) {
		my $prefix = $_;
		$prefix =~ s/:.+$//; # In case of 'png:gd', etc.
		$self->log(error => "Error: '$prefix' is not a valid output format")
			if !exists $self->valid_output_format->{$prefix};
	}

	$self -> log(debug => $self -> dot_input);

	# Warning: Do not use $im_format in this 'if', because it has a default value.

	if ($im_output_file)
	{
		return $self -> run_map($driver, $output_file, $format, $timeout, $im_output_file, $im_format);
	}
	else
	{
		return $self -> run_mapless($driver, $output_file, $format, $timeout);
	}

} # End of run.

# -----------------------------------------------

sub run_map
{
	my($self, $driver, $output_file, $format, $timeout, $im_output_file, $im_format) = @_;
	$self -> log(debug => "Driver: $driver. Output file: $output_file. Format: $format. IM output file: $im_output_file. IM format: $im_format. Timeout: $timeout second(s)");
	# The EXLOCK option is for BSD-based systems.
	my($temp_dir)	= File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
	my($temp_file)	= File::Spec -> catfile($temp_dir, 'temp.gv');
	open(my $fh, '> :raw', $temp_file) || die "Can't open(> $temp_file): $!";
	print $fh $self -> dot_input;
	close $fh;
	my(@args) = ("-T$im_format", "-o$im_output_file", "-T$format", "-o$output_file", $temp_file);
	system($driver, @args);
	return $self;
} # End of run_map.

# -----------------------------------------------

sub run_mapless
{
	my($self, $driver, $output_file, $format, $timeout) = @_;
	$self -> log(debug => "Driver: $driver. Output file: $output_file. Format: $format. Timeout: $timeout second(s)");
	# Usage of utf8 here relies on ISO-8859-1 matching Unicode for low chars.
	# It saves me the effort of determining if the input contains Unicode.
	run3
		[$driver, "-T$format"],
		\$self -> dot_input,
		\my $stdout,
		\my $stderr,
		{
			binmode_stdin  => ':utf8',
			binmode_stdout => ':raw',
			binmode_stderr => ':raw',
		};
	die $stderr if ($stderr);
	$self -> dot_output($stdout);
	if ($output_file)
	{
		open(my $fh, '> :raw', $output_file) || die "Can't open(> $output_file): $!";
		print $fh $stdout;
		close $fh;
		$self -> log(debug => "Wrote $output_file. Size: " . length($stdout) . ' bytes');
	}
	return $self;
} # End of run_mapless.

sub stringify_attributes {
	my($self, $context, $option) = @_;
	# Add double-quotes around anything (e.g. labels) which does not look like HTML.
	my @pairs;
	for my $key (sort keys %$option) {
		my $text = _dor($$option{$key}, '');
		$text =~ s/^\s+(<)/$1/;
		$text =~ s/(>)\s+$/$1/;
		$text = qq|"$text"| if $text !~ /^<.+>$/s;
		push @pairs, qq|$key=$text|;
	}
	return join(' ', @pairs) . "\n" if $context eq 'subgraph';
	return join(' ', $context, '[', @pairs, ']') . "\n" if @pairs;
	$context =~ /^(?:edge|graph|node)/ ? '' : "$context\n";
}

sub validate_params
{
	my($self, $context, $attributes) = @_;
	my $valid = $VALID_ATTRIBUTES->{$context};
	my @invalid = grep !exists $valid->{$_}, keys %$attributes;
	$self->log(error => "Error: '$_' is not a valid attribute in the '$context' context") for sort @invalid;
	return $self;

} # End of validate_params.

sub from_graph {
	my ($self, $g) = @_;
	die "from_graph: '$g' not a Graph" if !$g->isa('Graph');
	my %g_attrs = %{ $g->get_graph_attribute('graphviz') || {} };
	my $global = { directed => $g->is_directed, %{delete $g_attrs{global}||{}} };
	my $groups = delete $g_attrs{groups} || [];
	if (ref $self) {
		for (sort keys %g_attrs) {
			my $method = "default_$_";
			$self->$method(%{ $g_attrs{$_} });
		}
	} else {
		$self = $self->new(global => $global, %g_attrs);
	}
	for my $group (@$groups) {
		$self->push_subgraph(%{ $group->{attributes} || {} });
		$self->add_node(name => $_) for @{ $group->{nodes} || [] };
		$self->pop_subgraph;
	}
	my ($is_multiv, $is_multie) = map $g->$_, qw(multivertexed multiedged);
	my ($v_attr, $e_attr) = qw(get_vertex_attribute get_edge_attribute);
	$v_attr .= '_by_id' if $is_multiv;
	$e_attr .= '_by_id' if $is_multie;
	my %first2edges;
	for my $e (sort {$a->[0] cmp $b->[0] || $a->[1] cmp $b->[1]} $g->unique_edges) {
		my @edges = $is_multie
			? map $g->$e_attr(@$e, $_, 'graphviz') || {}, sort $g->get_multiedge_ids(@$e)
			: $g->$e_attr(@$e, 'graphviz')||{};
		push @{ $first2edges{$e->[0]} }, map [ from => $e->[0], to => $e->[1], %$_ ], @edges;
	}
	for my $v (sort $g->unique_vertices) {
		my @vargs = $v;
		if ($is_multiv) {
			my ($found_id) = grep $g->has_vertex_attribute_by_id($v, $_, 'graphviz'), sort $g->get_multivertex_ids($v);
			@vargs = defined $found_id ? (@vargs, $found_id) : ();
		}
		my $attrs = @vargs ? $g->$v_attr(@vargs, 'graphviz') || {} : {};
		$self->add_node(name => $v, %$attrs) if keys %$attrs or $g->is_isolated_vertex($v);
		$self->add_edge(@$_) for @{ $first2edges{$v} };
	}
	$self;
}

# -----------------------------------------------

1;

=pod

=head1 NAME

GraphViz2 - A wrapper for AT&T's Graphviz

=head1 Synopsis

=head2 Sample output

See L<https://graphviz-perl.github.io/>.

=head2 Perl code

=head3 Typical Usage

	use strict;
	use warnings;
	use File::Spec;
	use GraphViz2;

	use Log::Handler;
	my $logger = Log::Handler->new;
	$logger->add(screen => {
		maxlevel => 'debug', message_layout => '%m', minlevel => 'error'
	});

	my $graph = GraphViz2->new(
		edge   => {color => 'grey'},
		global => {directed => 1},
		graph  => {label => 'Adult', rankdir => 'TB'},
		logger => $logger,
		node   => {shape => 'oval'},
	);

	$graph->add_node(name => 'Carnegie', shape => 'circle');
	$graph->add_node(name => 'Murrumbeena', shape => 'box', color => 'green');
	$graph->add_node(name => 'Oakleigh',    color => 'blue');
	$graph->add_edge(from => 'Murrumbeena', to    => 'Carnegie', arrowsize => 2);
	$graph->add_edge(from => 'Murrumbeena', to    => 'Oakleigh', color => 'brown');

	$graph->push_subgraph(
		name  => 'cluster_1',
		graph => {label => 'Child'},
		node  => {color => 'magenta', shape => 'diamond'},
	);
	$graph->add_node(name => 'Chadstone', shape => 'hexagon');
	$graph->add_node(name => 'Waverley', color => 'orange');
	$graph->add_edge(from => 'Chadstone', to => 'Waverley');
	$graph->pop_subgraph;

	$graph->default_node(color => 'cyan');

	$graph->add_node(name => 'Malvern');
	$graph->add_node(name => 'Prahran', shape => 'trapezium');
	$graph->add_edge(from => 'Malvern', to => 'Prahran');
	$graph->add_edge(from => 'Malvern', to => 'Murrumbeena');

	my $format      = shift || 'svg';
	my $output_file = shift || File::Spec->catfile('html', "sub.graph.$format");
	$graph->run(format => $format, output_file => $output_file);

=head1 Description

=head2 Overview

This module provides a Perl interface to the amazing L<Graphviz|http://www.graphviz.org/>, an open source graph visualization tool from AT&T.

It is called GraphViz2 so that pre-existing code using (the Perl module) GraphViz continues to work.

To avoid confusion, when I use L<GraphViz2> (note the capital V), I'm referring to this Perl module, and
when I use L<Graphviz|http://www.graphviz.org/> (lower-case v) I'm referring to the underlying tool (which is in fact a set of programs).

Version 1.00 of L<GraphViz2> is a complete re-write, by Ron Savage, of GraphViz V 2, which was written by Leon Brocard. The point of the re-write
is to provide access to all the latest options available to users of L<Graphviz|http://www.graphviz.org/>.

GraphViz2 V 1 is not backwards compatible with GraphViz V 2, despite the considerable similarity. It was not possible to maintain compatibility
while extending support to all the latest features of L<Graphviz|http://www.graphviz.org/>.

To ensure L<GraphViz2> is a light-weight module, L<Moo> has been used to provide getters and setters,
rather than L<Moose>.

As of V 2.43, C<GraphViz2> supports image maps, both client and server side.

See L</Image Maps> below.

=head2 What is a Graph?

An undirected graph is a collection of nodes optionally linked together with edges.

A directed graph is the same, except that the edges have a direction, normally indicated by an arrow head.

A quick inspection of L<Graphviz|http://www.graphviz.org/>'s L<gallery|http://www.graphviz.org/gallery/> will show better than words
just how good L<Graphviz|http://www.graphviz.org/> is, and will reinforce the point that humans are very visual creatures.

=head1 Installation

Of course you need to install AT&T's Graphviz before using this module.
See L<http://www.graphviz.org/download/>.

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = GraphViz2 -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2>.

Key-value pairs accepted in the parameter list:

=head3 edge => $hashref

The I<edge> key points to a hashref which is used to set default attributes for edges.

Hence, allowable keys and values within that hashref are anything supported by L<Graphviz|http://www.graphviz.org/>.

The default is {}.

This key is optional.

=head3 global => $hashref

The I<global> key points to a hashref which is used to set attributes for the output stream.

This key is optional.

Valid keys within this hashref are:

=head4 combine_node_and_port

New in 2.58. It defaults to true, but in due course (currently planned
May 2021) it will default to false. When true, C<add_node> and C<add_edge>
will escape only some characters in the label and names, and in particular
the "from" and "to" parameters on edges will combine the node name
and port in one string, with a C<:> in the middle (except for special
treatment of double-colons).

When the option is false, any name may be given to nodes, and edges can
be created between them. To specify ports, give the additional parameter
of C<tailport> or C<headport>. To specify a compass point in addition,
give array-refs with two values for these parameters. Also, C<add_node>'s
treatment of labels is more DWIM, with C<{> etc being transparently
quoted.

=head4 directed => $Boolean

This option affects the content of the output stream.

directed => 1 outputs 'digraph name {...}', while directed => 0 outputs 'graph name {...}'.

At the Perl level, directed graphs have edges with arrow heads, such as '->', while undirected graphs have
unadorned edges, such as '--'.

The default is 0.

This key is optional.

=head4 driver => $program_name

This option specifies which external program to run to process the output stream.

The default is to use L<File::Which>'s which() method to find the 'dot' program.

This key is optional.

=head4 format => $string

This option specifies what type of output file to create.

The default is 'svg'.

Output formats of the form 'png:gd' etc are also supported, but only the component before
the first ':' is validated by L<GraphViz2>.

This key is optional.

=head4 label => $string

This option specifies what an edge looks like: '->' for directed graphs and '--' for undirected graphs.

You wouldn't normally need to use this option.

The default is '->' if directed is 1, and '--' if directed is 0.

This key is optional.

=head4 name => $string

This option affects the content of the output stream.

name => 'G666' outputs 'digraph G666 {...}'.

The default is 'Perl' :-).

This key is optional.

=head4 record_shape => /^(?:M?record)$/

This option affects the shape of records. The value must be 'Mrecord' or 'record'.

Mrecords have nice, rounded corners, whereas plain old records have square corners.

The default is 'Mrecord'.

See L<Record shapes|http://www.graphviz.org/doc/info/shapes.html#record> for details.

=head4 strict => $Boolean

This option affects the content of the output stream.

strict => 1 outputs 'strict digraph name {...}', while strict => 0 outputs 'digraph name {...}'.

The default is 0.

This key is optional.

=head4 timeout => $integer

This option specifies how long to wait for the external program before exiting with an error.

The default is 10 (seconds).

This key is optional.

=head3 graph => $hashref

The I<graph> key points to a hashref which is used to set default attributes for graphs.

Hence, allowable keys and values within that hashref are anything supported by L<Graphviz|http://www.graphviz.org/>.

The default is {}.

This key is optional.

=head3 logger => $logger_object

Provides a logger object so $logger_object -> $level($message) can be called at certain times. Any object with C<debug> and C<error> methods
will do, since these are the only levels emitted by this module.
One option is a L<Log::Handler> object.

Retrieve and update the value with the logger() method.

By default (i.e. without a logger object), L<GraphViz2> prints warning and debug messages to STDOUT,
and dies upon errors.

However, by supplying a log object, you can capture these events.

Not only that, you can change the behaviour of your log object at any time, by calling
L</logger($logger_object)>.

See also the verbose option, which can interact with the logger option.

This key is optional.

=head3 node => $hashref

The I<node> key points to a hashref which is used to set default attributes for nodes.

Hence, allowable keys and values within that hashref are anything supported by L<Graphviz|http://www.graphviz.org/>.

The default is {}.

This key is optional.

=head3 subgraph => $hashref

The I<subgraph> key points to a hashref which is used to set attributes for all subgraphs, unless overridden
for specific subgraphs in a call of the form push_subgraph(subgraph => {$attribute => $string}).

Valid keys within this hashref are:

=over 4

=item * rank => $string

This option affects the content of all subgraphs, unless overridden later.

A typical usage would be new(subgraph => {rank => 'same'}) so that all nodes mentioned within each subgraph
are constrained to be horizontally aligned.

See scripts/rank.sub.graph.1.pl for sample code.

Possible values for $string are: max, min, same, sink and source.

See the L<Graphviz 'rank' docs|http://www.graphviz.org/doc/info/attrs.html#d:rank> for details.

=back

The default is {}.

This key is optional.

=head3 verbose => $Boolean

Provides a way to control the amount of output when a logger is not specified.

Setting verbose to 0 means print nothing.

Setting verbose to 1 means print the log level and the message to STDOUT, when a logger is not specified.

Retrieve and update the value with the verbose() method.

The default is 0.

See also the logger option, which can interact with the verbose option.

This key is optional.

=head2 Validating Parameters

The secondary keys (under the primary keys 'edge|graph|node') are checked against lists of valid attributes (stored at the end of this
module, after the __DATA__ token, and made available using L<Data::Section::Simple>).

This mechanism has the effect of hard-coding L<Graphviz|http://www.graphviz.org/> options in the source code of L<GraphViz2>.

Nevertheless, the implementation of these lists is handled differently from the way it was done in V 2.

V 2 ships with a set of scripts, scripts/extract.*.pl, which retrieve pages from the
L<Graphviz|http://www.graphviz.org/> web site and extract the current lists of valid attributes.

These are then copied manually into the source code of L<GraphViz2>, meaning any time those lists change on the
L<Graphviz|http://www.graphviz.org/> web site, it's a trivial matter to update the lists stored within this module.

See L<GraphViz2/Scripts Shipped with this Module>.

=head2 Alternate constructor and object method

=head3 from_graph

	my $gv = GraphViz2->from_graph($g);

	# alternatively
	my $gv = GraphViz2->new;
	$gv->from_graph($g);

	# for handy debugging of arbitrary graphs:
	GraphViz2->from_graph($g)->run(format => 'svg', output_file => 'output.svg');

Takes a L<Graph> object. This module will figure out various defaults from it,
including whether it is directed or not.

Will also use any node-, edge-, and graph-level attributes named
C<graphviz> as a hash-ref for setting attributes on the corresponding
entities in the constructed GraphViz2 object. These will override the
figured-out defaults referred to above.

For a C<multivertexed> graph, will only create one node per vertex,
but will search all the multi-IDs for a C<graphviz> attribute, taking
the first one it finds (sorted alphabetically).

For a C<multiedged> graph, will create one edge per multi-edge.

Will only set the C<global> attribute if called as a constructor. This
will be dropped from any passed-in graph-level C<graphviz> attribute
when called as an object method.

A special graph-level attribute (under C<graphviz>) called C<groups> will
be given further special meaning: it is an array-ref of hash-refs. Those
will have keys, used to create subgraphs:

=over

=item * attributes

Hash-ref of arguments to supply to C<push_subgraph> for this subgraph.

=item * nodes

Array-ref of node names to put in this subgraph.

=back

Example:

	$g->set_graph_attribute(graphviz => {
		groups => [
			{nodes => [1, 2], attributes => {subgraph=>{rank => 'same'}}},
		],
		# other graph-level attributes...
	});

=head1 Attribute Scope

=head2 Graph Scope

The graphical elements graph, node and edge, have attributes. Attributes can be set when calling new().

Within new(), the defaults are graph => {}, node => {}, and edge => {}.

You override these with code such as new(edge => {color => 'red'}).

These attributes are pushed onto a scope stack during new()'s processing of its parameters, and they apply thereafter until changed.
They are the 'current' attributes. They live at scope level 0 (zero).

You change the 'current' attributes by calling any of the methods default_edge(%hash), default_graph(%hash) and default_node(%hash).

See scripts/trivial.pl (L<GraphViz2/Scripts Shipped with this Module>) for an example.

=head2 Subgraph Scope

When you wish to create a subgraph, you call push_subgraph(%hash). The word push emphasises that you are moving into a new scope,
and that the default attributes for the new scope are pushed onto the scope stack.

This module, as with L<Graphviz|http://www.graphviz.org/>, defaults to using inheritance of attributes.

That means the parent's 'current' attributes are combined with the parameters to push_subgraph(%hash) to generate a new set of 'current'
attributes for each of the graphical elements, graph, node and edge.

After a single call to push_subgraph(%hash), these 'current' attributes will live a level 1 in the scope stack.

See scripts/sub.graph.pl (L<GraphViz2/Scripts Shipped with this Module>) for an example.

Another call to push_subgraph(%hash), I<without> an intervening call to pop_subgraph(), will repeat the process, leaving you with
a set of attributes at level 2 in the scope stack.

Both L<GraphViz2> and L<Graphviz|http://www.graphviz.org/> handle this situation properly.

See scripts/sub.sub.graph.pl (L<GraphViz2/Scripts Shipped with this Module>) for an example.

At the moment, due to design defects (IMHO) in the underlying L<Graphviz|http://www.graphviz.org/> logic, there are some tiny problems with this:

=over 4

=item * A global frame

I can't see how to make the graph as a whole (at level 0 in the scope stack) have a frame.

=item * Frame color

When you specify graph => {color => 'red'} at the parent level, the subgraph has a red frame.

I think a subgraph should control its own frame.

=item * Parent and child frames

When you specify graph => {color => 'red'} at the subgraph level, both that subgraph and it children have red frames.

This contradicts what happens at the global level, in that specifying color there does not given the whole graph a frame.

=item * Frame visibility

A subgraph whose name starts with 'cluster' is currently forced to have a frame, unless you rig it by specifying a
color the same as the background.

For sample code, see scripts/sub.graph.frames.pl.

=back

Also, check L<the pencolor docs|http://www.graphviz.org/doc/info/attrs.html#d:pencolor> for how the color of the frame is
chosen by cascading thru a set of options.

I've posted an email to the L<Graphviz|http://www.graphviz.org/> mailing list suggesting a new option, framecolor, so deal with
this issue, including a special color of 'invisible'.

=head1 Image Maps

As of V 2.43, C<GraphViz2> supports image maps, both client and server side.
For web use, note that these options also take effect when generating SVGs,
for a much lighter-weight solution to hyperlinking graph nodes and edges.

=head2 The Default URL

See the L<Graphviz docs for 'cmapx'|http://www.graphviz.org/doc/info/output.html#d:cmapx>.

Their sample code has a dot file - x.gv - containing this line:

	URL="http://www.research.att.com/base.html";

The way you set such a url in C<GraphViz2> is via a new parameter to C<new()>. This parameter is called C<im_meta>
and it takes a hashref as a value. Currently the only key used within that hashref is the case-sensitive C<URL>.

Thus you must do this to set a URL:

	my($graph) = GraphViz2 -> new
	             (
	                ...
	                im_meta =>
	                {
	                    URL => 'http://savage.net.au/maps/demo.3.1.html', # Note: URL must be in caps.
	                },
	             );

See maps/demo.3.pl and maps/demo.4.pl for sample code.

=head2 Typical Code

Normally you would call C<run()> as:

	$graph -> run
	(
	    format      => $format,
	    output_file => $output_file
	);

That line was copied from scripts/cluster.pl.

To trigger image map processing, you must include 2 new parameters:

	$graph -> run
	(
	    format         => $format,
	    output_file    => $output_file,
	    im_format      => $im_format,
	    im_output_file => $im_output_file
	);

That line was copied from maps/demo.3.pl, and there is an identical line in maps/demo.4.pl.

=head2 The New Parameters to run()

=over 4

=item * im_format => $str

Expected values: 'imap' (server-side) and 'cmapx' (client-side).

Default value: 'cmapx'.

=item * im_output_file => $file_name

The name of the output map file.

Default: ''.

If you do not set it to anything, the new image maps code is ignored.

=back

=head2 Sample Code

Various demos are shipped in the new maps/ directory:

Each demo, when FTPed to your web server displays some text with an image in the middle. In each case
you can click on the upper oval to jump to one page, or click on the lower oval to jump to a different
page, or click anywhere else in the image to jump to a third page.

=over 4

=item * demo.1.*

This set demonstrates a server-side image map but does not use C<GraphViz2>.

You have to run demo.1.sh which generates demo.1.map, and then you FTP the whole dir maps/ to your web server.

URL: your.domain.name/maps/demo.1.html.

=item * demo.2.*

This set demonstrates a client-side image map but does not use C<GraphViz2>.

You have to run demo.2.sh which generates demo.2.map, and then you manually copy demo.2.map into demo.2.html,
replacing any version of the map already present. After that you FTP the whole dir maps/ to your web server.

URL: your.domain.name/maps/demo.2.html.

=item * demo.3.*

This set demonstrates a server-side image map using C<GraphViz2> via demo.3.pl.

Note line 54 of demo.3.pl which sets the default C<im_format> to 'imap'.

URL: your.domain.name/maps/demo.3.html.

=item * demo.4.*

This set demonstrates a client-side image map using C<GraphViz2> via demo.4.pl.

As with demo.2.* there is some manually editing to be done.

Note line 54 of demo.4.pl which sets the default C<im_format> to 'cmapx'. This is the only important
difference between this demo and the previous one.

There are other minor differences, in that one uses 'svg' and the other 'png'. And of course the urls
of the web pages embedded in the code and in those web pages differs, just to demonstate that the maps
do indeed lead to different pages.

URL: your.domain.name/maps/demo.4.html.

=back

=head1 Methods

=head2 add_edge(from => $from_node_name, to => $to_node_name, [label => $label, %hash])

Adds an edge to the graph.

Returns $self to allow method chaining.

Here, [] indicate optional parameters.

Add a edge from 1 node to another.

$from_node_name and $to_node_name default to ''.

%hash is any edge attributes accepted as
L<Graphviz attributes|https://www.graphviz.org/doc/info/attrs.html>.
These are validated in exactly the same way as the edge parameters in the calls to
default_edge(%hash), new(edge => {}) and push_subgraph(edge => {}).

To make the edge start or finish on a port, see L</combine_node_and_port>.

=head2 add_node(name => $node_name, [%hash])

	my $graph = GraphViz2->new(global => {combine_node_and_port => 0});
	$graph->add_node(name => 'struct3', shape => 'record', label => [
		{ text => "hello\\nworld" },
		[
			{ text => 'b' },
			[
				{ text => 'c{}' }, # reproduced literally
				{ text => 'd', port => 'here' },
				{ text => 'e' },
			]
			{ text => 'f' },
		],
		{ text => 'g' },
		{ text => 'h' },
	]);

Adds a node to the graph.

Returns $self to allow method chaining.

If you want to embed newlines or double-quotes in node names or labels, see scripts/quote.pl in L<GraphViz2/Scripts Shipped with this Module>.

If you want anonymous nodes, see scripts/anonymous.pl in L<GraphViz2/Scripts Shipped with this Module>.

Here, [] indicates an optional parameter.

%hash is any node attributes accepted as
L<Graphviz attributes|https://www.graphviz.org/doc/info/attrs.html>.
These are validated in exactly the same way as the node parameters in the calls to
default_node(%hash), new(node => {}) and push_subgraph(node => {}).

The attribute name 'label' may point to a string or an arrayref.

=head3 If it is a string...

The string is the label. If the C<shape> is a record, you can give any
text and it will be passed for interpretation by Graphviz. This means
you will need to quote E<lt> and E<gt> (port specifiers), C<|> (cell
separator) and C<{> C<}> (structure depth) with C<\> to make them appear
literally.

For records, the cells start horizontal. Each additional layer of
structure will switch the orientation between horizontal and vertical.

=head3 If it is an arrayref of strings...

=over 4

=item * The node is forced to be a record

The actual shape, 'record' or 'Mrecord', is set globally, with:

	my($graph) = GraphViz2 -> new
	(
		global => {record_shape => 'record'}, # Override default 'Mrecord'.
		...
	);

Or set locally with:

	$graph -> add_node(name => 'Three', label => ['Good', 'Bad'], shape => 'record');

=item * Each element in the array defines a field in the record

These fields are combined into a single node

=item * Each element is treated as a label

=item * Each label is given a port name (1 .. N) of the form "port$port_count"

=item * Judicious use of '{' and '}' in the label can make this record appear horizontally or vertically, and even nested

=back

=head3 If it is an arrayref of hashrefs...

=over 4

=item * The node is forced to be a record

The actual shape, 'record' or 'Mrecord', can be set globally or locally, as explained just above.

=item * Each element in the array defines a field in the record

=item * Each element is treated as a hashref with keys 'text' and 'port'

The 'port' key is optional.

=item * The value of the 'text' key is the label

=item * The value of the 'port' key is the port

=item * Judicious use of '{' and '}' in the label can make this record appear horizontally or vertically, and even nested

=back

See scripts/html.labels.*.pl and scripts/record.*.pl for sample code.

See also L</How labels interact with ports>.

For more details on this complex topic, see L<Records|http://www.graphviz.org/doc/info/shapes.html#record> and L<Ports|http://www.graphviz.org/doc/info/attrs.html#k:portPos>.

=head2 default_edge(%hash)

Sets defaults attributes for edges added subsequently.

Returns $self to allow method chaining.

%hash is any edge attributes accepted as
L<Graphviz attributes|https://www.graphviz.org/doc/info/attrs.html>.
These are validated in exactly the same way as the edge parameters in the calls to new(edge => {})
and push_subgraph(edge => {}).

=head2 default_graph(%hash)

Sets defaults attributes for the graph.

Returns $self to allow method chaining.

%hash is any graph attributes accepted as
L<Graphviz attributes|https://www.graphviz.org/doc/info/attrs.html>.
These are validated in exactly the same way as the graph parameter in the calls to new(graph => {})
and push_subgraph(graph => {}).

=head2 default_node(%hash)

Sets defaults attributes for nodes added subsequently.

Returns $self to allow method chaining.

%hash is any node attributes accepted as
L<Graphviz attributes|https://www.graphviz.org/doc/info/attrs.html>.
These are validated in exactly the same way as the node parameters in the calls to new(node => {})
and push_subgraph(node => {}).

=head2 default_subgraph(%hash)

Sets defaults attributes for clusters and subgraphs.

Returns $self to allow method chaining.

%hash is any cluster or subgraph attribute accepted as
L<Graphviz attributes|https://www.graphviz.org/doc/info/attrs.html>.
These are validated in exactly the same way as the subgraph parameter in the calls to
new(subgraph => {}) and push_subgraph(subgraph => {}).

=head2 dot_input()

Returns the output stream, formatted nicely, to be passed to the external program (e.g. dot).

=head2 dot_output()

Returns the output from calling the external program (e.g. dot).

You I<must> call run() before calling dot_output(), since it is only during the call to run() that the output of the
external program is stored in the buffer controlled by dot_output().

This output is available even if run() does not write the output to a file.

=head2 edge_hash()

Returns, at the end of the run, a hashref keyed by node name, specifically the node at the arrowI<tail> end of
the hash, i.e. where the edge starts from.

Use this to get a list of all nodes and the edges which leave those nodes, the corresponding destination
nodes, and the attributes of each edge.

	my($node_hash) = $graph -> node_hash;
	my($edge_hash) = $graph -> edge_hash;

	for my $from (sort keys %$node_hash)
	{
		my($attr) = $$node_hash{$from}{attributes};
		my($s)    = join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr);

		print "Node: $from\n";
		print "\tAttributes: $s\n";

		for my $to (sort keys %{$$edge_hash{$from} })
		{
			for my $edge (@{$$edge_hash{$from}{$to} })
			{
				$attr = $$edge{attributes};
				$s    = join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr);

				print "\tEdge: $from$$edge{from_port} -> $to$$edge{to_port}\n";
				print "\t\tAttributes: $s\n";
			}
		}
	}

If the caller adds the same edge two (or more) times, the attributes from each call are
I<not> coalesced (unlike L</node_hash()>), but rather the attributes from each call are stored separately
in an arrayref.

A bit more formally then, $$edge_hash{$from_node}{$to_node} is an arrayref where each element describes
one edge, and which defaults to:

	{
		attributes => {},
		from_port  => $from_port,
		to_port    => $to_port,
	}

If I<from_port> is not provided by the caller, it defaults to '' (the empty string). If it is provided,
it contains a leading ':'. Likewise for I<to_port>.

See scripts/report.nodes.and.edges.pl (a version of scripts/html.labels.1.pl) for a complete example.

=head2 log([$level, $message])

Logs the message at the given log level.

Returns $self to allow method chaining.

Here, [] indicate optional parameters.

$level defaults to 'debug', and $message defaults to ''.

If called with $level eq 'error', it dies with $message.

=head2 logger($logger_object)

Gets or sets the log object.

Here, [] indicates an optional parameter.

=head2 node_hash()

Returns, at the end of the run, a hashref keyed by node name. Use this to get a list of all nodes
and their attributes.

	my($node_hash) = $graph -> node_hash;

	for my $name (sort keys %$node_hash)
	{
		my($attr) = $$node_hash{$name}{attributes};
		my($s)    = join(', ', map{"$_ => $$attr{$_}"} sort keys %$attr);

		print "Node: $name\n";
		print "\tAttributes: $s\n";
	}

If the caller adds the same node two (or more) times, the attributes from each call are
I<coalesced> (unlike L</edge_hash()>), meaning all attributes from all calls are combined under the
I<attributes> sub-key.

A bit more formally then, $$node_hash{$node_name} is a hashref where each element describes one node, and
which defaults to:

	{
		attributes => {},
	}

See scripts/report.nodes.and.edges.pl (a version of scripts/html.labels.1.pl) for a complete example,
including usage of the corresponding L</edge_hash()> method.

=head2 pop_subgraph()

Pop off and discard the top element of the scope stack.

Returns $self to allow method chaining.

=head2 push_subgraph([name => $name, edge => {...}, graph => {...}, node => {...}, subgraph => {...}])

Sets up a new subgraph environment.

Returns $self to allow method chaining.

Here, [] indicate optional parameters.

name => $name is the name to assign to the subgraph. Name defaults to ''.

So, without $name, 'subgraph {' is written to the output stream.

With $name, 'subgraph "$name" {' is written to the output stream.

Note that subgraph names beginning with 'cluster' L<are special to Graphviz|http://www.graphviz.org/doc/info/attrs.html#d:clusterrank>.

See scripts/rank.sub.graph.[1234].pl for the effect of various values for $name.

edge => {...} is any edge attributes accepted as
L<Graphviz attributes|https://www.graphviz.org/doc/info/attrs.html>.
These are validated in exactly the same way as the edge parameters in the calls to
default_edge(%hash), new(edge => {}) and push_subgraph(edge => {}).

graph => {...} is any graph attributes accepted as
L<Graphviz attributes|https://www.graphviz.org/doc/info/attrs.html>.
These are validated in exactly the same way as the graph parameters in the calls to
default_graph(%hash), new(graph => {}) and push_subgraph(graph => {}).

node => {...} is any node attributes accepted as
L<Graphviz attributes|https://www.graphviz.org/doc/info/attrs.html>.
These are validated in exactly the same way as the node parameters in the calls to
default_node(%hash), new(node => {}) and push_subgraph(node => {}).

subgraph => {..} is for setting attributes applicable to clusters and subgraphs.

Currently the only subgraph attribute is C<rank>, but clusters have many attributes available.

See the second column of the
L<Graphviz attribute docs|https://www.graphviz.org/doc/info/attrs.html> for details.

A typical usage would be push_subgraph(subgraph => {rank => 'same'}) so that all nodes mentioned within the subgraph
are constrained to be horizontally aligned.

See scripts/rank.sub.graph.[12].pl and scripts/sub.graph.frames.pl for sample code.

=head2 valid_attributes()

Returns a hashref of all attributes known to this module, keyed by type
to hashrefs to true values.

Stored in this module, using L<Data::Section::Simple>.

These attributes are used to validate attributes in many situations.

You wouldn't normally need to use this method.

See scripts/report.valid.attributes.pl. See L<GraphViz2/Scripts Shipped with this Module>.

=head2 run([driver => $exe, format => $string, timeout => $integer, output_file => $output_file])

Runs the given program to process the output stream.

Returns $self to allow method chaining.

Here, [] indicate optional parameters.

$driver is the name of the external program to run.

It defaults to the value supplied in the call to new(global => {driver => '...'}), which in turn defaults
to L<File::Which>'s which('dot') return value.

$format is the type of output file to write.

It defaults to the value supplied in the call to new(global => {format => '...'}), which in turn defaults
to 'svg'.

$timeout is the time in seconds to wait while the external program runs, before dieing with an error.

It defaults to the value supplied in the call to new(global => {timeout => '...'}), which in turn defaults
to 10.

$output_file is the name of the file into which the output from the external program is written.

There is no default value for $output_file. If a value is not supplied for $output_file, the only way
to recover the output of the external program is to call dot_output().

This method performs a series of tasks:

=over 4

=item * Run the chosen external program on the L</dot_input>

=item * Capture STDOUT and STDERR from that program

=item * Die if STDERR contains anything

=item * Copies STDOUT to the buffer controlled by the dot_output() method

=item * Write the captured contents of STDOUT to $output_file, if $output_file has a value

=back

=head2 stringify_attributes($context, $option)

Returns a string suitable to writing to the output stream.

$context is one of 'edge', 'graph', 'node', or a special string. See the code for details.

You wouldn't normally need to use this method.

=head2 validate_params($context, \%attributes)

Validate the given attributes within the given context.

Also, if $context is 'subgraph', attributes are allowed to be in the 'cluster' context.

Returns $self to allow method chaining.

$context is one of 'edge', 'global', 'graph', or 'node'.

You wouldn't normally need to use this method.

=head2 verbose([$integer])

Gets or sets the verbosity level, for when a logging object is not used.

Here, [] indicates an optional parameter.

=head1 MISC

=head2 Graphviz version supported

GraphViz2 targets V 2.34.0 of L<Graphviz|http://www.graphviz.org/>.

This affects the list of available attributes per graph item (node, edge, cluster, etc) available.

See the second column of the
L<Graphviz attribute docs|https://www.graphviz.org/doc/info/attrs.html> for details.

=head2 Supported file formats

Parses the output of C<dot -T?>, so depends on local installation.

=head2 Special characters in node names and labels

L<GraphViz2> escapes these 2 characters in those contexts: [].

Escaping the 2 chars [] started with V 2.10. Previously, all of []{} were escaped, but {} are used in records
to control the orientation of fields, so they should not have been escaped in the first place.

It would be nice to also escape | and <, but these characters are used in specifying fields and ports in records.

See the next couple of points for details.

=head2 Ports

Ports are what L<Graphviz|http://www.graphviz.org/> calls those places on the outline of a node where edges
leave and terminate.

The L<Graphviz|http://www.graphviz.org/> syntax for ports is a bit unusual:

=over 4

=item * This works: "node_name":port5

=item * This doesn't: "node_name:port5"

=back

Let me repeat - that is Graphviz syntax, not GraphViz2 syntax. In Perl, you must do this:

	$graph -> add_edge(from => 'struct1:f1', to => 'struct2:f0', color => 'blue');

You don't have to quote all node names in L<Graphviz|http://www.graphviz.org/>, but some, such as digits, must be quoted, so I've decided to quote them all.

=head2 How labels interact with ports

You can specify labels with ports in these ways:

=over 4

=item * As a string

	$graph -> add_node(name => 'struct3', label => "hello\nworld |{ b |{c|<here> d|e}| f}| g | h");

Here, the string contains a port (<here>), field markers (|), and orientation markers ({}).

Clearly, you must specify the field separator character '|' explicitly. In the next 2 cases, it is implicit.

Then you use $graph -> add_edge(...) to refer to those ports, if desired:

	$graph -> add_edge(from => 'struct1:f2', to => 'struct3:here', color => 'red');

The same label is specified in the next case.

=item * As an arrayref of hashrefs

From scripts/record.2.pl:

	$graph -> add_node(name => 'struct3', label =>
	[
		{
			text => "hello\nworld",
		},
		{
			text => '{b',
		},
		{
			text => '{c',
		},
		{
			port => '<here>',
			text => 'd',
		},
		{
			text => 'e}',
		},
		{
			text => 'f}',
		},
		{
			text => 'g',
		},
		{
			text => 'h',
		},
	]);

Each hashref is a field, and hence you do not specify the field separator character '|'.

Then you use $graph -> add_edge(...) to refer to those ports, if desired. Again, from scripts/record.2.pl:

	$graph -> add_edge(from => 'struct1:f2', to => 'struct3:here', color => 'red');

The same label is specified in the previous case.

=item * As an arrayref of strings

From scripts/html.labels.1.pl:

	$graph -> add_node(name => 'Oakleigh', shape => 'record', color => 'blue',
		label => ['West Oakleigh', 'East Oakleigh']);

Here, again, you do not specify the field separator character '|'.

What happens is that each string is taken to be the label of a field, and each field is given
an auto-generated port name of the form "<port$n>", where $n starts from 1.

Here's how you refer to those ports, again from scripts/html.labels.1.pl:

	$graph -> add_edge(from => 'Murrumbeena', to => 'Oakleigh:port2',
		color => 'green', label => '<Drive<br/>Run<br/>Sprint>');

=back

See also the docs for the C<< add_node(name => $node_name, [%hash]) >> method.

=head2 Attributes for clusters

Just use subgraph => {...}, because the code (as of V 2.22) accepts attributes belonging to either clusters or subgraphs.

An example attribute is C<pencolor>, which is used for clusters but not for subgraphs:

	$graph->push_subgraph(
		graph    => {label => 'Child the Second'},
		name     => 'cluster Second subgraph',
		node     => {color => 'magenta', shape => 'diamond'},
		subgraph => {pencolor => 'white'}, # White hides the cluster's frame.
	);
	# other nodes or edges can be added within it...
	$graph->pop_subgraph;

=head1 TODO

=over 4

=item * Handle edges such as 1 -> 2 -> {A B}, as seen in L<Graphviz|http://www.graphviz.org/>'s graphs/directed/switch.gv

But how?

=item * Validate parameters more carefully, e.g. to reject non-hashref arguments where appropriate

Some method parameter lists take keys whose value must be a hashref.

=back

=head1 A Extremely Short List of Other Graphing Software

L<Axis Maps|http://www.axismaps.com/>.

L<Polygon Map Generation|http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/>.
Read more on that L<here|http://blogs.perl.org/users/max_maischein/2011/06/display-your-data---randompoissondisc.html>.

L<Voronoi Applications|http://www.voronoi.com/wiki/index.php?title=Voronoi_Applications>.

=head1 Thanks

Many thanks are due to the people who chose to make L<Graphviz|http://www.graphviz.org/> Open Source.

And thanks to L<Leon Brocard|http://search.cpan.org/~lbrocard/>, who wrote L<GraphViz>, and kindly gave me co-maint of the module.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/GraphViz2.git>

=head1 Author

L<GraphViz2> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut

__DATA__
@@ arrow_modifier
l
o
r

@@ arrow
box
crow
curve
diamond
dot
inv
none
normal
tee
vee

@@ common_attribute
Damping => graph
K => graph, cluster
URL => edge, node, graph, cluster
area => node, cluster
arrowhead => edge
arrowsize => edge
arrowtail => edge
bb => graph
bgcolor => graph, cluster
center => graph
charset => graph
clusterrank => graph
color => edge, node, cluster
colorscheme => edge, node, cluster, graph
comment => edge, node, graph
compound => graph
concentrate => graph
constraint => edge
decorate => edge
defaultdist => graph
dim => graph
dimen => graph
dir => edge
diredgeconstraints => graph
distortion => node
dpi => graph
edgeURL => edge
edgehref => edge
edgetarget => edge
edgetooltip => edge
epsilon => graph
esep => graph
fillcolor => node, edge, cluster
fixedsize => node
fontcolor => edge, node, graph, cluster
fontname => edge, node, graph, cluster
fontnames => graph
fontpath => graph
fontsize => edge, node, graph, cluster
forcelabels => graph
gradientangle => node, cluster, graph
group => node
headURL => edge
head_lp => edge
headclip => edge
headhref => edge
headlabel => edge
headport => edge
headtarget => edge
headtooltip => edge
height => node
href => graph, cluster, node, edge
id => graph, cluster, node, edge
image => node
imagepath => graph
imagescale => node
inputscale => graph
label => edge, node, graph, cluster
labelURL => edge
label_scheme => graph
labelangle => edge
labeldistance => edge
labelfloat => edge
labelfontcolor => edge
labelfontname => edge
labelfontsize => edge
labelhref => edge
labeljust => graph, cluster
labelloc => node, graph, cluster
labeltarget => edge
labeltooltip => edge
landscape => graph
layer => edge, node, cluster
layerlistsep => graph
layers => graph
layerselect => graph
layersep => graph
layout => graph
len => edge
levels => graph
levelsgap => graph
lhead => edge
lheight => graph, cluster
lp => edge, graph, cluster
ltail => edge
lwidth => graph, cluster
margin => node, cluster, graph
maxiter => graph
mclimit => graph
mindist => graph
minlen => edge
mode => graph
model => graph
mosek => graph
nodesep => graph
nojustify => graph, cluster, node, edge
normalize => graph
nslimit => graph
ordering => graph, node
orientation => node
orientation => graph
outputorder => graph
overlap => graph
overlap_scaling => graph
overlap_shrink => graph
pack => graph
packmode => graph
pad => graph
page => graph
pagedir => graph
pencolor => cluster
penwidth => cluster, node, edge
peripheries => node, cluster
pin => node
pos => edge, node
quadtree => graph
quantum => graph
rank => subgraph
rankdir => graph
ranksep => graph
ratio => graph
rects => node
regular => node
remincross => graph
repulsiveforce => graph
resolution => graph
root => graph, node
rotate => graph
rotation => graph
samehead => edge
sametail => edge
samplepoints => node
scale => graph
searchsize => graph
sep => graph
shape => node
shapefile => node
showboxes => edge, node, graph
sides => node
size => graph
skew => node
smoothing => graph
sortv => graph, cluster, node
splines => graph
start => graph
style => edge, node, cluster, graph
stylesheet => graph
tailURL => edge
tail_lp => edge
tailclip => edge
tailhref => edge
taillabel => edge
tailport => edge
tailtarget => edge
tailtooltip => edge
target => edge, node, graph, cluster
tooltip => node, edge, cluster
truecolor => graph
vertices => node
viewport => graph
voro_margin => graph
weight => edge
width => node
xdotversion => graph
xlabel => edge, node
xlp => node, edge
z => node

@@ global
combine_node_and_port
directed
driver
format
im_format
label
name
record_shape
strict
timeout

@@ im_meta
URL

@@ node
Mcircle
Mdiamond
Msquare
assembly
box
box3d
cds
circle
component
diamond
doublecircle
doubleoctagon
egg
ellipse
fivepoverhang
folder
hexagon
house
insulator
invhouse
invtrapezium
invtriangle
larrow
lpromoter
none
note
noverhang
octagon
oval
parallelogram
pentagon
plaintext
point
polygon
primersite
promoter
proteasesite
proteinstab
rarrow
rect
rectangle
restrictionsite
ribosite
rnastab
rpromoter
septagon
signature
square
star
tab
terminator
threepoverhang
trapezium
triangle
tripleoctagon
underline
utr
