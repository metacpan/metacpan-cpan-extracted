package GOBO::Parsers::OBOParser;
use Moose;
use strict;
extends 'GOBO::Parsers::Parser';
with 'GOBO::Parsers::GraphParser';

use GOBO::Graph;
=cut
use GOBO::Node;
use GOBO::InstanceNode;
use GOBO::Synonym;
use GOBO::Subset;
use GOBO::Formula;
use GOBO::LinkStatement;
use GOBO::LiteralStatement;
use GOBO::ClassExpression;
use GOBO::ClassExpression::Union;
=cut
use Data::Dumper;

has default_namespace => (is=>'rw', isa=>'Str');
has format_version => (is=>'rw', isa=>'Str');


sub parse_header {
	my $self = shift;
	my $g = $self->graph;
	my $header_check = sub { return 1; };

	if ($self->has_header_parser_options)
	{	if ($self->header_parser_options->{ignore_all})
		{	$header_check = sub {
				return undef;
			};
		}
		elsif ($self->header_parser_options->{ignore})
		{	my $arr = $self->header_parser_options->{ignore};
			$header_check = sub {
				my $t = shift;
				return 1 unless grep { $t eq $_ } @$arr;
				return undef;
			};
		}
		else
		{	my $arr = $self->header_parser_options->{parse_only};
			$header_check = sub {
				my $t = shift;
				return 1 if grep { $t eq $_ } @$arr;
				return undef;
			};
		}
	}

	$/ = "\n";
	while($_ = $self->next_line) {
		next unless /\S/;

		if (/^\[/) {
			$self->unshift_line($_);
			# set the parse_header to 1
			$self->parsed_header(1);
			return;
		}

		if (/^(\S+):\s*(.*?)$/) {
			next unless &$header_check($1);
			my ($t,$v) = ($1,$2);
			if ($1 eq 'default-namespace') {
				$self->default_namespace($2);
			}
			elsif ($t eq 'subsetdef') {
				# subsetdef: gosubset_prok "Prokaryotic GO subset"
				if ($v =~ /^(\S+)\s+\"(.*)\"/) {
					my ($id,$label) = ($1,$2);
					my $ss = new GOBO::Subset(id=>$id,
											  label=>$label);
					$g->subset_index->{$id} = $ss;
				}
				else {
					warn $v;
				}
			}
			elsif ($t eq 'date') {
				$g->date($v);
			}
			elsif ($t eq 'remark') {
				$g->comment($v);
			}
			elsif ($t eq 'format-version') {
				$self->format_version($v);
			}
			elsif ($t eq 'data-version') {
				$g->version($v);
			}
			else {
				$g->set_property_value($t,$v);
			}
		}
	}
	return;
}


sub parse_body {
	my $self = shift;

	my $stanza_check = sub { return 1; };
	my $tag_check = sub { return 1; }; 

	if ($self->has_body_parser_options)
	{	if ($self->body_parser_options->{ignore_all})
		{	# ignore the whole thing
			# no more body parsing required
		#	warn "Found that I don't have to parse the body. Returning!";
			return;
		}
		elsif ($self->body_parser_options->{ignore})
		{	my $h = $self->body_parser_options->{ignore};
			
			my @ignore_all = grep { $h->{$_}[0] eq '*' } keys %$h;
			
			if (@ignore_all)
			{	# ignore this stanza if the stanza type exists in the ignore all set
				$stanza_check = sub {
					my $s_type = shift;
					if (grep { $s_type eq $_ } @ignore_all)
					{	$self->next_stanza(\@ignore_all, 'ignore');
						return undef;
					}
					return 1;
				};
			}

			# ignore the stanza if the stanza type exists in the ignore set
			# skip the line if the line type exists or the full stanza is to be ignored
			$tag_check = sub {
				my ($s_type, $t) = @_;
#				print STDERR "\n$s_type $t";
				return 1 if ! $h->{$s_type};
				return undef if ( $h->{$s_type}[0] eq '*' || grep { /^$t$/i } @{$h->{$s_type}} );
#				print STDERR "=> OK\n";
				return 1;
			};
		}
		elsif ($self->body_parser_options->{parse_only})
		{	my $h = $self->body_parser_options->{parse_only};

		#	print STDERR "h: " . Dumper($h) . "\n";

			# parse this stanza if the stanza type exists in the parse_only set
			# otherwise, go to the next stanza
			$stanza_check = sub {
				my $s_type = shift;
				return 1 if $h->{$s_type};
				$self->next_stanza([ keys %$h ]);
				return undef;
			};

			# if the stanza type exists and the tag exists, we're good
			# otherwise, go to the next stanza
			$tag_check = sub {
				my ($s_type, $t) = @_;
				if ($h->{$s_type})
				{	if ( $h->{$s_type}[0] eq '*' || grep { $t eq $_ } @{$h->{$s_type}} )
					{	return 1;
					}
					return undef;
				}
				# we should have already caught incorrect stanzas, but n'mind...
				warn "Incorrect stanza type!\n";
				$self->next_stanza([ keys %$h ]);
				return undef;
			};
		}
	}

	my $stanzaclass;
	my $id;
	my $n;
	my %union_h = ();
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
		
		
		if (/^(.*?):\s*/) {
			next unless &$tag_check( $stanzaclass, $1 );
#			print STDERR "passed the tag check!\n";
		}

		chomp;
		s/\!.*//; # TODO
		s/\s+$//;
		if (/^id:\s*(.*)\s*$/) {
			$id = $1;
			if ($stanzaclass eq 'term') {
				#$n = $g->term_noderef($id);
				$n = $g->add_term($id);
			}
			elsif ($stanzaclass eq 'typedef') {
				#$n = $g->relation_noderef($id);
				$n = $g->add_relation($id);
			}
			elsif ($stanzaclass eq 'instance') {
				$n = $g->instance_noderef($id);
				$g->add_instance($n);
			}
			elsif ($stanzaclass eq 'annotation') {
				# TODO
			}
			else {
			}

			if (!$n) {
				die "cannot parse: $_";
			}
			
			$n->namespace($self->default_namespace)
				if (!$n->namespace &&
					$self->default_namespace);
			next;
		}

		my $vals = [];
		if (/^name:\s*(.*)/) {
			$n->label($1);
		}
		elsif (/^namespace:\s*(.*)/) {
			$n->namespace($1);
		}
		elsif (/^alt_id:\s*(.*)/) {
			$n->add_alt_ids($1);
		}
		elsif (/^def:\s*(.*)/) {
			_parse_vals($1,$vals);
			$n->definition($vals->[0]); # TODO
				if ($vals->[1] && @{$vals->[1]}) {
					$n->definition_xrefs( [ map { $_ = new GOBO::Node({ id => $_ }) } @{$vals->[1]} ]);
				}
		}
		elsif (/^property_value:\s*(.*)/) {
			_parse_vals($1,$vals);
			$n->add_property_value($vals->[0], $vals->[1]); # TODO
		}
		elsif (/^comment:\s*(.*)/) {
			$n->comment($1);
		}
		elsif (/^subset:\s*(\S+)/) {
			my $ss = $g->subset_noderef($1);
			$n->add_subsets($ss);

			if ($self->liberal_mode && ! $g->subset_index->{$ss->id})
			{	print STDERR "$1 was not in the subset index. Crap!\n";
				$g->subset_index->{$1} = $ss;
			}
		}
		elsif (/^consider:\s*(\S+)/) {
			$n->add_considers($1);
		}
		elsif (/^replaced_by:\s*(\S+)/) {
			$n->add_replaced_bys($1);
		}
		elsif (/^created_by:\s*(\S+)/) {
			$n->created_by($1);
		}
		elsif (/^creation_date:\s*(\S+)/) {
			$n->creation_date($1);
		}
		elsif (/^synonym:\s*(.*)/) {
			_parse_vals($1,$vals);
			my $syn = new GOBO::Synonym(label=>shift @$vals);
			$n->add_synonym($syn);
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
		}
		elsif (/^xref:\s*(\S+)/) {
			$n->add_xrefs($1);
		}
		elsif (/^is_a:\s*(\S+)(.*)/) {
			#my $tn = $stanzaclass eq 'typedef' ? $g->relation_noderef($1) : $g->term_noderef($1);
			my $tn = $self->getnode($1, $stanzaclass eq 'typedef' ? 'r' : 'c');
			my $s = new GOBO::LinkStatement(node=>$n,relation=>'is_a',target=>$tn);
			$self->add_metadata($s,$2);
			$g->add_link($s);
			if ($stanzaclass eq 'typedef') {
				$n->add_subrelation_of($tn);
			}
		}
		elsif (/^relationship:\s*(\S+)\s+(\S+)(.*)/) {
			my $rn = $g->relation_noderef($1);
			#my $tn = $stanzaclass eq 'typedef' ? $g->relation_noderef($2) : $g->term_noderef($2);
			my $tn = $self->getnode($2, $stanzaclass eq 'typedef' ? 'r' : 'c');
			#my $tn = $g->term_noderef($2);
			my $s = new GOBO::LinkStatement(node=>$n,relation=>$rn,target=>$tn);
			$self->add_metadata($s,$3);
			$g->add_link($s);
		}
		elsif (/^complement_of:\s*(\S+)/) {
			my $tn = $self->getnode($1, $stanzaclass eq 'typedef' ? 'r' : 'c');
			$n->complement_of($tn);
		}
		elsif (/^disjoint_from:\s*(\S+)/) {
			my $tn = $self->getnode($1, $stanzaclass eq 'typedef' ? 'r' : 'c');
			$n->add_disjoint_from($tn);
		}
		elsif (/^domain:\s*(\S+)/) {
			my $tn = $self->getnode($1, 'c');
			$n->domain($tn);
		}
		elsif (/^range:\s*(\S+)/) {
			my $tn = $self->getnode($1, 'c');
			$n->range($tn);
		}
		elsif (/^disjoint_over:\s*(\S+)/) {
			my $tn = $self->getnode($1, 'r');
			$n->add_disjoint_over($tn);
		}
		elsif (/^inverse_of:\s*(\S+)/) {
			my $tn = $self->getnode($1, 'r');
			$n->add_inverse_of($tn);
		}
		elsif (/^inverse_of_on_instance_level:\s*(\S+)/) {
			my $tn = $self->getnode($1, 'r');
			$n->add_inverse_of_on_instance_level($tn);
		}
		elsif (/^instance_of:\s*(\S+)/) {
			my $tn = $self->getnode($1, 'c');
			$n->add_type($tn);
		}
		elsif (/^equivalent_to:\s*(\S+)/) {
			my $tn = $self->getnode($1, $stanzaclass eq 'typedef' ? 'r' : 'c');
			$n->add_equivalent_to($tn);
		}
		elsif (/^intersection_of:/) {
			# TODO: generalize
			if (/^intersection_of:\s*(\S+)\s+(\S+)/) {
				my $rn = $g->relation_noderef($1);
				#my $tn = $g->term_noderef($2);
				my $tn = $self->getnode($2, $stanzaclass eq 'typedef' ? 'r' : 'c');
				#my $tn = $stanzaclass eq 'typedef' ? $g->relation_noderef($2) : $g->term_noderef($2);
				my $s = new GOBO::LinkStatement(node=>$n,relation=>$rn,target=>$tn, is_intersection=>1);
				$g->add_link($s);
			}
			elsif (/^intersection_of:\s*(\S+)/) {
				#my $tn = $g->term_noderef($1);
				#my $tn = $stanzaclass eq 'typedef' ? $g->relation_noderef($1) : $g->term_noderef($1);
				my $tn = $self->getnode($1, $stanzaclass eq 'typedef' ? 'r' : 'c');
				my $s = new GOBO::LinkStatement(node=>$n,relation=>'is_a',target=>$tn, is_intersection=>1);
				$g->add_link($s);
			}
			else {
				$self->throw("badly formatted intersection: $_");
			}
		}
		elsif (/^union_of:\s*(\S+)/) {
			my $u = $self->getnode($1, $stanzaclass eq 'typedef' ? 'r' : 'c');
			my $ud = $n->union_definition;
			if (!$ud) {
				$ud = new GOBO::ClassExpression::Union;
				$n->union_definition($ud);
			}
			$ud->add_argument($u);
		}
		elsif (/^is_(\w+):\s*(\w+)/) {
			my $att = $1;
			$n->$att(1) if $2 eq 'true';
			#$n->{$att} = $val; # TODO : check
		}
		elsif (/^transitive_over:\s*(\w+)/) {
			my $rn = $g->relation_noderef($1);
			$n->transitive_over($rn);
		}
		elsif (/^(holds_over_chain|equivalent_to_chain):\s*(.*)/) {
			my $ct = $1;
			my @rels  = map { $self->getnode($_,'r') } split(' ',$2);
			$ct eq 'holds_over_chain' ? $n->add_holds_over_chain(\@rels) : $n->add_equivalent_to_chain(\@rels);
		}
		# following for annotation stanzas only
		elsif (/^subject:\s*(.*)/) {
			$n->node($self->getnode($1));
		}
		elsif (/^relation:\s*(.*)/) {
			$n->relation($self->getnode($1,'r'));
		}
		elsif (/^object:\s*(.*)/) {
			$n->target($self->getnode($1));
		}
		elsif (/^description:\s*(.*)/) {
			$n->description($1);
		}
		elsif (/^source:\s*(.*)/) {
			$n->provenance($self->getnode($1));
		}
		elsif (/^assigned_by:\s*(.*)/) {
			$n->source($self->getnode($1));
		}
		elsif (/^formula:\s*(.*)/) {
			_parse_vals($1,$vals);
			my $f = new GOBO::Formula(text=>$vals->[0],
									  language=>$vals->[1]);
			$f->associated_with($n);
			$g->add_formula($f);
		}
		else {
#			warn "ignored: $_";
			# ...
		}
	}
	if (@anns) {
		$g->add_annotations(\@anns);
	}
	return;
}



sub getnode {
	my $self = shift;
	my $id = shift;
	my $metatype = shift || '';
	my $g = $self->graph;
	my $n;
	if ($metatype eq 'c') {
		$n = $g->term_noderef($id);
	}
	elsif ($metatype eq 'r') {
		$n = $g->relation_noderef($id);
	}
	elsif ($metatype eq 'i') {
		$n = $g->instance_noderef($id);
	}
	else {
		$n = $g->noderef($id);
	}
	return $n;
}

sub add_metadata {
	my $self = shift;
	my $s = shift;
	my $v = shift;
	if ($v =~ /^\s*\{(.*)\}/) {
		my $tq = $1;
		my @tvs = ();
		while ($tq) {
			if ($tq =~ /(\w+)=\"([^\"]*)\"(.*)/) {
				push(@tvs,[$1,$2]);
				$tq = $3;
			}
			elsif ($tq =~ /(\w+)=(\w+)(.*)/) {
				push(@tvs,[$1,$2]);
				$tq = $3;
			}
			else {
				$self->throw($v);
			}
			if ($tq =~ /^s*\,\s*(.*)/) {
				$tq = $1;
			}
			elsif ($tq =~ /^\s*$/) {
				# ok
			}
			else {
				$self->throw($v);
			}
		}
		my @sub_statements = ();
		foreach (@tvs) {
			my ($t,$v) = @$_;
			my $ss = new GOBO::LiteralStatement(relation=>$t,target=>$v);
			push(@sub_statements,$ss);
		}
		$s->sub_statements(\@sub_statements);
	}
	return;
}

sub _parse_vals {
	my $s = shift;
	my $vals = shift;

#	print STDERR "input: s: $s\nvals: $vals\n";
#
	# optionally leads with quoted sections
	if ($s =~ /^(\".*)/) {
		$s = _parse_quoted($s,$vals);
	}

	# follows with optional list of atoms
	while ($s =~ /^([^\{\[]\S*)\s*(.*)/) {
		push(@$vals,$1);
		$s = $2;
	}

	# option xrefs
	if ($s =~ /^(\[)/) {
		$s = _parse_xrefs($s,$vals);
	}
#	print STDERR "now: s: $s\nvals: ". Dumper($vals);
#
}

sub _parse_quoted {
	my $s = shift;
	my $vals = shift;
	if ($s =~ /^\"(([^\"\\]|\\.)*)\"\s*(.*)/) {
		push(@$vals,$1);
		return $3;
	}
	else {
		die "$s";
	}
}

sub _parse_xrefs {
	my $s = shift;
	my $vals = shift;
	if ($s =~ /^\[(([^\]\\]|\\.)*)\]\s*(.*)/) {
		$s = $2;
		push(@$vals, [split(/,\s*/,$1)]); # TODO
	}
	else {
		die "$s";
	}
}


## validate the options that we have

sub check_options {
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
				}
				else
				{	warn "wrong header options format";
				}
			}
			elsif ($options->{header}{ignore})
			{	if (! ref $options->{header}{ignore} && $options->{header}{ignore} eq '*')
				{	$self->set_header_parser_options({ ignore_all => 1 });
				}
				elsif (ref $options->{header}{ignore} && ref $options->{header}{ignore} eq 'ARRAY')
				{	$self->set_header_parser_options({ ignore => $options->{header}{ignore} });
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
					$self->set_body_parser_options({ parse_only => $b_hash }) if $b_hash;
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
					$self->set_body_parser_options({ ignore => $b_hash }) if $b_hash;
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
}

=head2 next_stanza

Skip the rest of this stanza and go to the next

input:  self, optional hashref of stanza types to parse

if the hashref is specified, will continue to skip stanzas until the stanza type
matches one of those in the hash ref

=cut

sub next_stanza {
	my $self = shift;
	my $s_types = shift;
	my $ignore = shift || undef;

	if ($s_types)
	{	if ($ignore)
		{	while($_ = $self->next_line)
			{	if ($_ =~ /^\[(\S+)\]/ && ! grep { lc($1) eq $_ } @$s_types)
				{	$self->unshift_line($_);
					return;
				}
				next;
			}
		}
		else
		{	while($_ = $self->next_line)
			{	next unless $_ =~ /^\[(\S+)\]/ && grep { lc($1) eq $_ } @$s_types;
				$self->unshift_line($_);
				return;
			}
		}
	}
	else
	{	while($_ = $self->next_line) {
			next unless $_ =~ /^\[(\S+)\]/;
			$self->unshift_line($_);
			return;
		}
	}
}





1;

=head1 NAME

GOBO::Parsers::OBOParser

=head1 SYNOPSIS

  my $parser = new GOBO::Parsers::OBOParser(file => "t/data/cell.obo");
  $parser->parse;
  print $parser->graph;

  my $writer = new GOBO::Writers::OBOWriter;
  $writer->graph($parser->graph);
  $writer->write();

=head1 DESCRIPTION

An GOBO::Parsers::Parser that parses OBO Files.

The goal is to be obof1.3 compliant:

http://www.geneontology.org/GO.format.obo-1_3.shtml

however, obof1.2 and obof1.0 are also supported

=head2 Term stanzas

These are converted to GOBO::TermNode objects

=head2 Typedef stanzas

These are converted to GOBO::RelationNode objects

=head2 Instance stanzas

These are converted to GOBO::InstanceNode objects

=head2 Statements

is_a and relationship tags are converted to GOBO::LinkStatement objects and added to the graph

=head2 intersection_of tags

These are added to the graph as GOBO::LinkStatement objects, with is_intersection=>1

You can call 

  $g->convert_intersection_links_to_logical_definitions

To move these links from the graph to $term->logical_definition

TBD: do this as the default?
TBD: generalize for all links? sometimes it is convenient to have the links available in the Node object...?

=cut

=head2 Parser options

The default behaviour of the parser is to parse everything it comes across.
Customized parsing can be achieved by giving the parser a hash ref of options
encoding the parsing preferences:

$parser->set_options($options);

To set parser options, use the following structures:

=head3 Header-related parsing options

Header parsing instructions should be contained in the options hash with the key
'header':

 $options->{header} = ...

# parse only tag_1, tag_2 and tag_3, and ignore any other tags in the header
 $options->{header} = { 
 	parse_only => [ 'tag_1', 'tag_2', 'tag_3' ],
 }


# parse everything apart from tag_4, tag_5 and tag_6
 $options->{header} = {
 	ignore =>  [ 'tag_4', 'tag_5', 'tag_6' ],
 }


# ignore all information in the header
 $options->{header}{ignore} = '*';

There is no need to specify $options->{header}{parse_only} = '*' : this is the
default behaviour. There is also no need to specify both 'ignore' and 'parse_only'.


=head3 Body parsing options

Body parsing instructions should be contained in the options hash with the key
'body':

 $options->{body} = ...


## parsing or ignore tags

# parse only tag_1, tag_2 and tag_3 from $stanza_type stanzas
 $options->{body}{parse_only}{$stanza_type} = [ 'tag_1', 'tag_2', 'tag_3' ],


# ignore 'tag_4', 'tag_5', 'tag_6' from $stanza_type stanzas
 $options->{body}{ignore}{$stanza_type} = [ 'tag_4', 'tag_5', 'tag_6' ],


## parsing or ignoring stanzas

# parse only stanzas where the type matches the key $stanza_type
 $options->{body}{parse_only}{ $stanza_type } = '*'


# ignore stanzas where the type matches the key $stanza_type
 $options->{body}{ignore}{ $stanza_type } = '*'

# ignore all information in the body
 $options->{body}{ignore} = '*';

There is no need to specify $options->{body}{parse_only} = '*' : this is the
default behaviour. There is also no need to specify both 'ignore' and 'parse_only'.


=head3 Examples

# parse everything from the header; parse only instance stanzas and the id, name and namespace tags from term stanzas
 $parser->set_options({ body => { parse_only => { term => [ qw(id name namespace) ] }, instance => '*' } });


# ignore the header; parse everything in the body
 $parser->set_options({ header => { ignore => '*' } });


# parse the date from the header; ignore instance and annotation stanzas
 $parser->set_options({
   header => { parse_only => [ 'date' ] },
   body => { 
     ignore => { instance => '*', annotation => '*' },
   },
 });

=cut
