=head1 NAME

GOBO::Parsers::OBOParserDispatchHash


=head1 DESCRIPTION

An GOBO::Parsers::Parser that parses OBO Files.

Mostly identical to GOBO::Parsers::OBOParser but uses a dispatch table rather than an if/else cascade

=cut

package GOBO::Parsers::OBOParserDispatchHash;

use Moose;
#use base 
extends 'GOBO::Parsers::OBOParser';

has header_check_sub => (is=>'rw', isa=>'CodeRef', writer => 'set_header_check_sub', reader => 'get_header_check_sub', default=>sub{ return sub { return 1 }; });
has stanza_check_sub => (is=>'rw', isa=>'CodeRef', writer => 'set_stanza_check_sub', reader => 'get_stanza_check_sub', default=>sub{ return sub { return 1 }; });
has tag_check_sub    => (is=>'rw', isa=>'CodeRef', writer => 'set_tag_check_sub', reader => 'get_tag_check_sub', default=>sub{ return sub { return 1 }; });

use Data::Dumper;

my $body_subs = {
	"id" => sub {
		my ($self, $args) = @_;
#		print STDERR "node before: " . Dumper(${$args->{node}}) . "\n";
		if ($args->{stanzaclass} eq 'term') {
			${$args->{node}} = ${$args->{graph}}->add_term($args->{value});
		}
		elsif ($args->{stanzaclass} eq 'typedef') {
			${$args->{node}} = ${$args->{graph}}->add_relation($args->{value});
		}
		elsif ($args->{stanzaclass} eq 'instance') {
			${$args->{node}} = ${$args->{graph}}->instance_noderef($args->{value});
			${$args->{graph}}->add_instance(${$args->{node}});
		}
		elsif ($args->{stanzaclass} eq 'annotation') {
			# TODO
		}
		else {
			warn "Unknown stanza class " . $args->{stanzaclass};
		}

		if (!${$args->{node}}) {
			die "cannot parse: $_";
		}
		
		${$args->{node}}->namespace($self->default_namespace) if (!${$args->{node}}->namespace && $self->default_namespace);
#		print STDERR "node now: " . Dumper(${$args->{node}}) . "\n";
	},
	"name" => sub {
		my ($self, $args) = @_;
		$args->{node}->label($args->{value});
	},
	"namespace" => sub {
		my ($self, $args) = @_;
		$args->{node}->namespace($args->{value});
	},
	"alt_id" => sub {
		my ($self, $args) = @_;
		$args->{node}->add_alt_ids($args->{value});
	},

	"def" => sub {
		my ($self, $args) = @_;
		my $vals = [];
		_parse_vals($args->{value},$vals);
		$args->{node}->definition($vals->[0]); # TODO
		if ($vals->[1] && @{$vals->[1]}) {
			$args->{node}->definition_xrefs( [ map { $_ = new GOBO::Node({ id => $_ }) } @{$vals->[1]} ]);
		}
	},
	"is_obsolete" => sub {
		my ($self, $args) = @_;
		if ($args->{value} eq 'true')
		{	$args->{node}->obsolete(1);
		}
	},
	"property_value" => sub {
		my ($self, $args) = @_;
		my $vals = [];
		_parse_vals($args->{value},$vals);
		$args->{node}->add_property_value($vals->[0], $vals->[1]); # TODO
	},
	"comment" => sub {
		my ($self, $args) = @_;
		$args->{node}->comment($args->{value});
	},
	"subset" => sub {
		my ($self, $args) = @_;
		my $ss = $args->{graph}->subset_noderef($args->{value});
		$args->{node}->add_subsets($ss);
	
		if ($self->liberal_mode && ! $args->{graph}->subset_index->{$ss->id})
		{	print STDERR $args->{value} . " was not in the subset index. Crap!\n";
			$args->{graph}->subset_index->{$args->{value}} = $ss;
		}
	},
	"consider" => sub {
		my ($self, $args) = @_;
		$args->{node}->add_considers($args->{value});
	},
	"replaced_by" => sub {
		my ($self, $args) = @_;
		$args->{node}->add_replaced_bys($args->{value});
	},
	"created_by" => sub {
		my ($self, $args) = @_;
		$args->{node}->created_by($args->{value});
	},
	"creation_date" => sub {
		my ($self, $args) = @_;
		$args->{node}->creation_date($args->{value});
	},
	"synonym" => sub {
		my ($self, $args) = @_;
		my $vals = [];
		_parse_vals($args->{value},$vals);
		my $syn = new GOBO::Synonym(label=>shift @$vals);
		$args->{node}->add_synonym($syn);
		my $xrefs = pop @$vals;
		if (@$vals) {
			$syn->scope(shift @$vals);
		}
		else {
			warn "no scope specified: $_";
		}
		if ($vals->[0] && !ref($vals->[0])) {
			$syn->type(shift @$vals);
		}
		$syn->xrefs($xrefs);
	},
	"xref" => sub {
		my ($self, $args) = @_;
		$args->{node}->add_xrefs($args->{value});
	},
	"is_a" => sub {
		my ($self, $args) = @_;
		if ($args->{value} =~ /^(\S+)(.*)/) {
			#	my $tn = $self->getnode($1, $args->{stanzaclass} eq 'typedef' ? 'r' : 'c');
			my $tn;
			if ($args->{stanzaclass} eq 'typedef')
			{	$tn = $args->{graph}->relation_noderef($1);
			}
			else
			{	$tn = $args->{graph}->term_noderef($1);
			}
			my $s = new GOBO::LinkStatement(node=>$args->{node},relation=>'is_a',target=>$tn);
			$self->add_metadata($s,$2);
			$args->{graph}->add_link($s);
			if ($args->{stanzaclass} eq 'typedef') {
				$args->{node}->add_subrelation_of($tn);
			}
		}
	},
	"relationship" => sub {
		my ($self, $args) = @_;
		if ($args->{value} =~ /(\S+)\s+(\S+)(.*)/) {
			my $rn = $args->{graph}->relation_noderef($1);
			#	my $tn = $self->getnode($2, $args->{stanzaclass} eq 'typedef' ? 'r' : 'c');
			my $tn;
			if ($args->{stanzaclass} eq 'typedef')
			{	$tn = $args->{graph}->relation_noderef($2);
			}
			else
			{	$tn = $args->{graph}->term_noderef($2);
			}
			my $s = new GOBO::LinkStatement(node=>$args->{node},relation=>$rn,target=>$tn);
			$self->add_metadata($s,$3);
			$args->{graph}->add_link($s);
		}
	},
	"complement_of" => sub {
		my ($self, $args) = @_;
		#	my $tn = $self->getnode($args->{value}, $args->{stanzaclass} eq 'typedef' ? 'r' : 'c');
		my $tn;
		if ($args->{stanzaclass} eq 'typedef')
		{	$tn = $args->{graph}->relation_noderef($args->{value});
		}
		else
		{	$tn = $args->{graph}->term_noderef($args->{value});
		}
		$args->{node}->complement_of($tn);
	},
	"disjoint_from" => sub {
		my ($self, $args) = @_;
		#	my $tn = $self->getnode($args->{value}, $args->{stanzaclass} eq 'typedef' ? 'r' : 'c');
		my $tn;
		if ($args->{stanzaclass} eq 'typedef')
		{	$tn = $args->{graph}->relation_noderef($args->{value});
		}
		else
		{	$tn = $args->{graph}->term_noderef($args->{value});
		}
		$args->{node}->add_disjoint_from($tn);
	},
	"domain" => sub {
		my ($self, $args) = @_;
#		my $tn = $self->getnode($args->{value}, 'c');
		my $tn = $args->{graph}->term_noderef($args->{value});
		$args->{node}->domain($tn);
	},
	"range" => sub {
		my ($self, $args) = @_;
#		my $tn = $self->getnode($args->{value}, 'c');
		my $tn = $args->{graph}->term_noderef($args->{value});
		$args->{node}->range($tn);
	},
	"disjoint_over" => sub {
		my ($self, $args) = @_;
#		my $tn = $self->getnode($args->{value}, 'r');
		my $tn = $args->{graph}->relation_noderef($args->{value});
		$args->{node}->add_disjoint_over($tn);
	},
	"inverse_of" => sub {
		my ($self, $args) = @_;
#		my $tn = $self->getnode($args->{value}, 'r');
		my $tn = $args->{graph}->relation_noderef($args->{value});
		$args->{node}->add_inverse_of($tn);
	},
	"inverse_of_on_instance_level" => sub {
		my ($self, $args) = @_;
#		my $tn = $self->getnode($args->{value}, 'r');
		my $tn = $args->{graph}->relation_noderef($args->{value});
		$args->{node}->add_inverse_of_on_instance_level($tn);
	},
	"instance_of" => sub {
		my ($self, $args) = @_;
		if ($args->{value} =~ /^(\S+)/)
		{	#my $tn = $self->getnode($1, 'c');
			my $tn = $args->{graph}->term_noderef($1);
			$args->{node}->add_type($tn);
		}
	},
	"equivalent_to" => sub {
		my ($self, $args) = @_;
		#	my $tn = $self->getnode($args->{value}, $args->{stanzaclass} eq 'typedef' ? 'r' : 'c');
		my $tn;
		if ($args->{stanzaclass} eq 'typedef')
		{	$tn = $args->{graph}->relation_noderef($args->{value});
		}
		else
		{	$tn = $args->{graph}->term_noderef($args->{value});
		}
		$args->{node}->add_equivalent_to($tn);
	},

	"intersection_of" => sub {
		my ($self, $args) = @_;
		# TODO: generalize
		if ($args->{value} =~ /^(\S+)\s+(\S+)/) {
			my $rn = $args->{graph}->relation_noderef($1);
			#	my $tn = $self->getnode($2, $args->{stanzaclass} eq 'typedef' ? 'r' : 'c');
			my $tn;
			if ($args->{stanzaclass} eq 'typedef')
			{	$tn = $args->{graph}->relation_noderef($2);
			}
			else
			{	$tn = $args->{graph}->term_noderef($2);
			}
			my $s = new GOBO::LinkStatement(node=>$args->{node},relation=>$rn,target=>$tn, is_intersection=>1);
			$args->{graph}->add_link($s);
		}
		elsif ($args->{value} =~ /^(\S+)/) {
			#	my $tn = $self->getnode($1, $args->{stanzaclass} eq 'typedef' ? 'r' : 'c');
			my $tn;
			if ($args->{stanzaclass} eq 'typedef')
			{	$tn = $args->{graph}->relation_noderef($1);
			}
			else
			{	$tn = $args->{graph}->term_noderef($1);
			}
			my $s = new GOBO::LinkStatement(node=>$args->{node},relation=>'is_a',target=>$tn, is_intersection=>1);
			$args->{graph}->add_link($s);
		}
		else {
			$self->throw("badly formatted intersection: $_");
		}
	},
	"union_of" => sub {
		my ($self, $args) = @_;
		#	my $u = $self->getnode($args->{value}, $args->{stanzaclass} eq 'typedef' ? 'r' : 'c');
		my $u;
		if ($args->{stanzaclass} eq 'typedef')
		{	$u = $args->{graph}->relation_noderef($args->{value});
		}
		else
		{	$u = $args->{graph}->term_noderef($args->{value});
		}
		my $ud = $args->{node}->union_definition;
		if (!$ud) {
			$ud = new GOBO::ClassExpression::Union;
			$args->{node}->union_definition($ud);
		}
		$ud->add_argument($u);
	},
	"transitive_over" => sub {
		my ($self, $args) = @_;
		my $rn = $args->{graph}->relation_noderef($args->{value});
		$args->{node}->transitive_over($rn);
	},
	"holds_over_chain" => sub {
		my ($self, $args) = @_;
#		my @rels  = map { $self->getnode($_,'r') } split(' ',$args->{value});
		my @rels  = map { $args->{graph}->relation_noderef($_) } split(' ',$args->{value});
		$args->{node}->add_holds_over_chain(\@rels);
	},
	"equivalent_to_chain" => sub {
		my ($self, $args) = @_;
#		my @rels  = map { $self->getnode($_,'r') } split(' ',$args->{value});
		my @rels  = map { $args->{graph}->relation_noderef($_) } split(' ',$args->{value});
		$args->{node}->add_equivalent_to_chain(\@rels);
	},
	"is_" => sub {
		my ($self, $args) = @_;
		my $att = $args->{tag};
		if ($args->{value} eq 'true')
		{	$args->{node}->$att( 1 );
		}
		# TODO: check!
	},
	# following for annotation stanzas only
	"subject" => sub {
		my ($self, $args) = @_;
#		$args->{node}->node($self->getnode($args->{value}));
		$args->{node}->node($args->{graph}->noderef($args->{value}));
	},
	"relation" => sub {
		my ($self, $args) = @_;
#		$args->{node}->relation($self->getnode($args->{value},'r'));
		$args->{node}->relation($args->{graph}->relation_noderef($args->{value}));
	},
	"object" => sub {
		my ($self, $args) = @_;
#		$args->{node}->target($self->getnode($args->{value}));
		$args->{node}->target($args->{graph}->noderef($args->{value}));
	},
	"description" => sub {
		my ($self, $args) = @_;
		$args->{node}->description($args->{value});
	},
	"source" => sub {
		my ($self, $args) = @_;
#		$args->{node}->provenance($self->getnode($args->{value}));
		$args->{node}->provenance($args->{graph}->noderef($args->{value}));
	},
	"assigned_by" => sub {
		my ($self, $args) = @_;
#		$args->{node}->source($self->getnode($args->{value}));
		$args->{node}->source($args->{graph}->noderef($args->{value}));
	},
	"formula" => sub {
		my ($self, $args) = @_;
		my $vals = [];
		_parse_vals($args->{value},$vals);
		my $f = new GOBO::Formula(text=>$vals->[0],
								  language=>$vals->[1]);
		$f->associated_with($args->{node});
		$args->{graph}->add_formula($f);
	},

};


my $header_subs = {
	'subsetdef' => sub {
		my ($self, $args) = @_;
		# subsetdef: gosubset_prok "Prokaryotic GO subset"
		if ($args->{value} =~ /^(\S+)\s+\"(.*)\"/)
		{	my ($id,$label) = ($1,$2);
			my $ss = new GOBO::Subset(id=>$id, label=>$label);
			$args->{graph}->subset_index->{$id} = $ss;
		}
		else {
			warn "Uh-oh... subset value " . $args->{value};
		}
	},
	'date' => sub {
		my ($self, $args) = @_;
		$args->{graph}->date($args->{value});
	},
	'remark' => sub {
		my ($self, $args) = @_;
		$args->{graph}->comment($args->{value});
	},
	'data-version' => sub {
		my ($self, $args) = @_;
		$args->{graph}->version($args->{value});
	},
	'default' => sub {
		my ($self, $args) = @_;
		$args->{graph}->set_property_value($args->{tag},$args->{value});
	},
	'default-namespace' => sub {
		my ($self, $args) = @_;
		$self->default_namespace($args->{value});
	},
	'format-version' => sub {
		my ($self, $args) = @_;
		$self->format_version($args->{value});
	},
};


override 'parse_header' => sub {
#sub parse_header {
	my $self = shift;
	my $g = $self->graph;
	my $header_check = $self->get_header_check_sub;

	$/ = "\n";
	while($_ = $self->next_line) {
		next unless /\S/;

		if (/^\[/) {
			$self->unshift_line($_);
			last;
		}

		if (/^(\S+):\s*(.*?)$/) {
			next unless &$header_check($1);
			if ($header_subs->{$1})
			{	$header_subs->{$1}->($self, { tag => $1, value => $2, graph => $g });
			}
			else
			{	$header_subs->{default}->($self, { tag => $1, value => $2, graph => $g });
			}
		}
	}

	# set the parse_header to 1
	$self->parsed_header(1);
	return;
};


=head2 parse_header_from_array

Get a header from an array of lines, rather than passing in a file

input:  self, args with $args->{graph} being a Graph object
output: the Graph object

=cut

sub parse_header_from_array {
	my $self = shift;
	my $args = shift;
	my $g = $args->{graph} || new GOBO::Graph;
	my $header_check = $self->get_header_check_sub;
	
	foreach (@{$args->{array}})
	{	next unless /\S/;

		if (/^\[/) {
			# body starts here
			last;
		}

		if (/^(\S+):\s*(.*?)$/) {
			next unless &$header_check($1);
			if ($header_subs->{$1})
			{	$header_subs->{$1}->($self, { tag => $1, value => $2, graph => $g });
			}
			else
			{	$header_subs->{default}->($self, { tag => $1, value => $2, graph => $g });
			}
		}
	}
	return $g;
}




override 'parse_body' => sub {
#sub parse_body {
	my $self = shift;

	my $stanza_check = $self->get_stanza_check_sub;
	my $tag_check = $self->get_tag_check_sub;

	if ($self->has_body_parser_options && $self->body_parser_options->{ignore_all})
	{	# ignore the whole thing
		# no more body parsing required
	#	warn "Found that I don't have to parse the body. Returning!";
		return;
	}

	my $stanzaclass;
	my $n;
	my @anns = ();
	my $g = $self->graph;

	while($_ = $self->next_line) {
		next unless /\S/;

		if (/^\[(\S+)\]/) {
			undef $n;
			$stanzaclass = lc($1);
			next unless &$stanza_check( $stanzaclass );
#			print STDERR "passed the stanza check!\n";
			if ($stanzaclass eq 'annotation') {
				$n = new GOBO::Annotation;
				push(@anns, $n);
			}
			next;
		}
		
		if (/^id:\s*(.*)\s*$/) {
#			print STDERR "id: $1; stanzaclass: $stanzaclass; node: " . Dumper($n) . "\n";
			$body_subs->{id}->($self, { value => $1, graph => \$g, node => \$n, stanzaclass => $stanzaclass });
#			print STDERR "node: " . Dumper($n) . "\n";
			next;
		}

		if (/^(.*?):\s*/) {
			next unless &$tag_check( $stanzaclass, $1 );
#			print STDERR "passed the tag check!\n";
		}

		s/\!.*//; # TODO
		s/\s+$//;

		if (/^(.*?):\s*(.*)$/) {
			if ($body_subs->{$1}) {
				$body_subs->{$1}->($self, { tag => $1, value => $2, graph => $g, node => $n, stanzaclass => $stanzaclass });
				next;
			}
			elsif (/^is_(\w+):\s*(\w+)/) {
				$body_subs->{'is_'}->($self, { tag => $1, value => $2, graph => $g, node => $n } );
				next;
			}
		}

		# we don't know what's going on here!
		warn "ignored: $_";
	}
	if (@anns) {
		$g->add_annotations(\@anns);
	}
	return;
};


=head2 parse_body_from_array

Get a graph from an array of lines, rather than passing in a file

input:  self, args with $args->{graph} being a Graph object
output: the Graph object

=cut

sub parse_body_from_array {
	my $self = shift;
	my $args = shift;
	my $g = $args->{graph} || new GOBO::Graph;

	confess( (caller(0))[3] . ": missing required arguments" ) unless defined $g && $args->{array} && @{$args->{array}};

	my $stanza_check = $self->get_stanza_check_sub;
	my $tag_check = $self->get_tag_check_sub;

	if ($self->has_body_parser_options && $self->body_parser_options->{ignore_all})
	{	# ignore the whole thing
		# no more body parsing required
	#	warn "Found that I don't have to parse the body. Returning!";
		return;
	}

	my $stanzaclass;
	my $n;
	my @anns = ();

	foreach (@{$args->{array}})
	{	next unless /\S/;

		if (/^\[(\S+)\]/) {
			undef $n;
			$stanzaclass = lc($1);
			next unless &$stanza_check( $stanzaclass );
#			print STDERR "passed the stanza check!\n";
			if ($stanzaclass eq 'annotation') {
				$n = new GOBO::Annotation;
				push(@anns, $n);
			}
			next;
		}
		
		if (/^id:\s*(.*)\s*$/) {
#			print STDERR "id: $1; stanzaclass: $stanzaclass; node: " . Dumper($n) . "\n";
			$body_subs->{id}->($self, { value => $1, graph => \$g, node => \$n, stanzaclass => $stanzaclass });
#			print STDERR "node: " . Dumper($n) . "\n";
			next;
		}

		if (/^(.*?):\s*/) {
			next unless &$tag_check( $stanzaclass, $1 );
#			print STDERR "passed the tag check!\n";
		}

		s/\!.*//; # TODO
		s/\s+$//;

		if (/^(.*?):\s*(.*)$/) {
			if ($body_subs->{$1}) {
				$body_subs->{$1}->($self, { tag => $1, value => $2, graph => $g, node => $n, stanzaclass => $stanzaclass });
				next;
			}
			elsif (/^is_(\w+):\s*(\w+)/) {
				$body_subs->{'is_'}->($self, { tag => $1, value => $2, graph => $g, node => $n } );
				next;
			}
		}

		# we don't know what's going on here!
		warn "ignored: $_";
	}
	if (@anns) {
		$g->add_annotations(\@anns);
	}
	return $g;
}




sub _parse_vals {
	GOBO::Parsers::OBOParser::_parse_vals(@_);
}



## validate the options that we have

override 'check_options' => sub {
#sub check_my_options {
	my $self = shift;
	my $options = $self->options;
	if ($options && values %$options)
	{	# get rid of any existing options
		$self->clear_header_parser_options;
		$self->clear_body_parser_options;
		## see if we have any settings for parsing the header
		if ($options->{header} && keys %{$options->{header}})
		{	
			if ($options->{header}{ignore} && $options->{header}{parse_only})
			{	warn "Warning: both ignore and parse_only specified in header parsing options; using setting in parse_only";
			}

			# parse_only takes priority
			if ($options->{header}{parse_only})
			{	if (ref $options->{header}{parse_only} && ref $options->{header}{parse_only} eq 'ARRAY')
				{	$self->set_header_parser_options({ parse_only => $options->{header}{parse_only} });

					my $arr = $options->{header}{parse_only};
					$self->set_header_check_sub( sub {
						my $t = shift;
						return 1 if grep { $t eq $_ } @$arr;
						return undef;
					} );

				}
				else
				{	warn "wrong header options format";
				}
			}
			elsif ($options->{header}{ignore})
			{	if (! ref $options->{header}{ignore} && $options->{header}{ignore} eq '*')
				{	$self->set_header_parser_options({ ignore_all => 1 });
					$self->set_header_check_sub( sub { return undef; } );
				}
				elsif (ref $options->{header}{ignore} && ref $options->{header}{ignore} eq 'ARRAY')
				{	$self->set_header_parser_options({ ignore => $options->{header}{ignore} });
					my $arr = $self->header_parser_options->{ignore};
					$self->set_header_check_sub( sub {
						my $t = shift;
						return 1 unless grep { $t eq $_ } @$arr;
						return undef;
					} );
				}
				else
				{	warn "wrong header options format";
				}
			}
		}



		## check the body parsing options
		if ($options->{body} && keys %{$options->{body}})
		{	my $b_hash;
			
			if ($options->{body}{ignore} && $options->{body}{parse_only})
			{	warn "Warning: both ignore and parse_only specified in body parsing options; using setting in parse_only";
			}

			# parse_only takes priority
			if ($options->{body}{parse_only})
			{	if (ref $options->{body}{parse_only} && ref $options->{body}{parse_only} eq 'HASH')
				{	## stanza types
					foreach my $s_type (keys %{$options->{body}{parse_only}})
					{	# s_type = '*'
						if (! ref $options->{body}{parse_only}{$s_type} && $options->{body}{parse_only}{$s_type} eq '*')
						{	$b_hash->{$s_type} = ['*'];
						}
						# s_type = [ tag, tag, tag ]
						elsif (ref $options->{body}{parse_only}{$s_type} && ref $options->{body}{parse_only}{$s_type} eq 'ARRAY')
						{	$b_hash->{$s_type} = $options->{body}{parse_only}{$s_type};
						}
					}
					
#					print STDERR "b hash: " . Dumper($b_hash);
					if ($b_hash)
					{	$self->set_body_parser_options({ parse_only => $b_hash });
		
						# parse this stanza if the stanza type exists in the parse_only set
						# otherwise, go to the next stanza
						$self->set_stanza_check_sub( sub {
							my $s = shift;
							return 1 if $b_hash->{$s};
							$self->next_stanza([ keys %$b_hash ]);
							return undef;
						} );
			
						# if the stanza type exists and the tag exists, we're good
						# otherwise, go to the next stanza
						$self->set_tag_check_sub( sub {
							my ($s, $t) = @_;
							if ($b_hash->{$s})
							{	if ( $b_hash->{$s}[0] eq '*' || grep { $t eq $_ } @{$b_hash->{$s}} )
								{	return 1;
								}
								return undef;
							}
							# we should have already caught incorrect stanzas, but n'mind...
							warn "Incorrect stanza type!\n";
							$self->next_stanza([ keys %$b_hash ]);
							return undef;
						} );
					}
				}
				else
				{	warn "wrong body options format";
				}
			}
			elsif ($options->{body}{ignore})
			{	if (ref $options->{body}{ignore} && ref $options->{body}{ignore} eq 'HASH')
				{	## stanza types
					foreach my $s_type (keys %{$options->{body}{ignore}})
					{	# s_type = '*'
						if (! ref $options->{body}{ignore}{$s_type} && $options->{body}{ignore}{$s_type} eq '*')
						{	$b_hash->{$s_type} = ['*'];
						}
						# s_type = [ tag, tag, tag ]
						elsif (ref $options->{body}{ignore}{$s_type} && ref $options->{body}{ignore}{$s_type} eq 'ARRAY')
						{	$b_hash->{$s_type} = $options->{body}{ignore}{$s_type};
						}
					}
					if ($b_hash)
					{	$self->set_body_parser_options({ ignore => $b_hash });

						my @ignore_all = grep { $b_hash->{$_}[0] eq '*' } keys %$b_hash;
						if (@ignore_all)
						{	# ignore this stanza if the stanza type exists in the ignore all set
							$self->set_stanza_check_sub( sub {
								my $s = shift;
								if (grep { $s eq $_ } @ignore_all)
								{	$self->next_stanza(\@ignore_all, 'ignore');
									return undef;
								}
								return 1;
							} );
						}
			
						# ignore the stanza if the stanza type exists in the ignore set
						# skip the line if the line type exists or the full stanza is to be ignored
						$self->set_tag_check_sub( sub {
							my ($s, $t) = @_;
			#				print STDERR "\n$s_type $t";
							return 1 if ! $b_hash->{$s};
							return undef if ( $b_hash->{$s}[0] eq '*' || grep { /^$t$/i } @{$b_hash->{$s}} );
			#				print STDERR "=> OK\n";
							return 1;
						} );
					}
				}
				elsif (! ref $options->{body}{ignore} && $options->{body}{ignore} eq '*')
				{	$self->set_body_parser_options({ ignore_all => 1 });
				}
				else
				{	warn "wrong body options format";
				}
			}
		}
	}
	$self->checked_options(1);
};

## alter the reset_parser function so that the check subs are reset

after 'reset_parser' => sub {
	my $self = shift;
	$self->set_header_check_sub( sub { return 1 } );
	$self->set_stanza_check_sub( sub { return 1 } );
	$self->set_tag_check_sub( sub { return 1 } );
};


sub get_header_check_sub {
	my $self = shift;
	$self->check_options if ! $self->checked_options;
	return $self->header_check_sub;
}

sub get_stanza_check_sub {
	my $self = shift;
	$self->check_options if ! $self->checked_options;
	return $self->stanza_check_sub;
}

sub get_tag_check_sub {
	my $self = shift;
	$self->check_options if ! $self->checked_options;
	return $self->tag_check_sub;
}


1;





