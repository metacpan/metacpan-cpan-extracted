package HTML::Element::Library;
use strict;
use warnings;

our $VERSION = '5.220000';
our $DEBUG = 0;

use Array::Group ':all';
use Carp 'confess';
use Data::Dumper;
use Data::Rmap 'rmap_array';
use HTML::Element;
use HTML::FillInForm;
use List::MoreUtils ':all';
use List::Rotation::Cycle;
use List::Util 'first';
use Params::Validate ':all';
use Scalar::Listify;

# https://rt.cpan.org/Ticket/Display.html?id=44105
sub HTML::Element::fillinform {
	my ($tree, $hashref, $return_tree, $guts) = @_;
	(ref $hashref) eq 'HASH' or confess 'hashref not supplied as argument' ;

	my $html = $tree->as_HTML;
	my $new_html = HTML::FillInForm->fill(\$html, $hashref);

	if ($return_tree) {
		$tree = HTML::TreeBuilder->new_from_content($new_html);
		$tree = $guts ? $tree->guts : $tree ;
	} else {
		$new_html;
	}
}

sub HTML::Element::siblings {
	my $element = shift;
	my $p = $element->parent;
	return () unless $p;
	$p->content_list;
}

sub HTML::Element::defmap {
	my($tree, $attr, $hashref, $debug) = @_;

	while (my ($k, $v) = (each %$hashref)) {
		warn "defmap looks for ($attr => $k)" if $debug;
		my $found = $tree->look_down($attr => $k);
		if ($found) {
			warn "($attr => $k) was found.. replacing with '$v'" if $debug;
			$found->replace_content( $v );
		}
	}
}

sub HTML::Element::_only_empty_content {
	my ($self) = @_;
	my @c = $self->content_list;
	my $length  = scalar @c;

	scalar @c == 1 and not length $c[0];
}

sub HTML::Element::prune {
	my ($self) = @_;

	for my $c ($self->content_list) {
		next unless ref $c;
		$c->prune;
	}

	# post-order:
	$self->delete if ($self->is_empty or $self->_only_empty_content);
	$self;
}

sub HTML::Element::newchild {
	my ($lol, $parent_label, @newchild) = @_;
	rmap_array {
		if ($_->[0] eq $parent_label) {
			$_ = [ $parent_label => @newchild ];
			Data::Rmap::cut($_);
		} else {
			$_;
		}
	} $lol;
}

sub HTML::Element::crunch { ## no critic (RequireArgUnpacking)
	my $container = shift;

	my %p = validate(@_, {
		look_down => { type => ARRAYREF },
		leave     => { default => 1 },
	});

	my @look_down = @{$p{look_down}} ;
	my @elem = $container->look_down(@look_down) ;

	my $detached;

	for my $elem (@elem) {
		$elem->detach if $detached++ >= $p{leave};
	}
}

sub HTML::Element::hash_map { ## no critic (RequireArgUnpacking)
	my $container = shift;

	my %p = validate(@_, {
		hash      => { type => HASHREF },
		to_attr   => 1,
		excluding => { type => ARRAYREF , default => [] },
		debug     => { default => 0 },
	});

	warn 'The container tag is ', $container->tag if $p{debug} ;
	warn 'hash' . Dumper($p{hash}) if $p{debug} ;
	#warn 'at_under' . Dumper(\@_) if $p{debug} ;

	my @same_as = $container->look_down( $p{to_attr} => qr/.+/s ) ;

	warn 'Found ' . scalar(@same_as) . ' nodes' if $p{debug} ;

	for my $same_as (@same_as) {
		my $attr_val = $same_as->attr($p{to_attr}) ;
		if (first { $attr_val eq $_ } @{$p{excluding}}) {
			warn "excluding $attr_val" if $p{debug} ;
			next;
		}
		warn "processing $attr_val" if $p{debug} ;
		$same_as->replace_content($p{hash}->{$attr_val});
	}
}

sub HTML::Element::hashmap {
	my ($container, $attr_name, $hashref, $excluding, $debug) = @_;

	$excluding ||= [] ;

	$container->hash_map(
		hash      => $hashref,
		to_attr   => $attr_name,
		excluding => $excluding,
		debug     => $debug);
}


sub HTML::Element::passover {
	my ($tree, @to_preserve) = @_;

	warn "ARGS: my ($tree, @to_preserve)" if $DEBUG;
	warn $tree->as_HTML(undef, ' ') if $DEBUG;

	my $exodus = $tree->look_down(id => $to_preserve[0]);

	warn "E: $exodus" if $DEBUG;

	my @s = HTML::Element::siblings($exodus);

	for my $s (@s) {
		next unless ref $s;
		$s->delete unless first { $s->attr('id') eq $_ } @to_preserve;
	}

	return $exodus; # Goodbye Egypt! http://en.wikipedia.org/wiki/Passover
}

sub HTML::Element::sibdex {
	my $element = shift;
	firstidx { $_ eq $element } $element->siblings
}

sub HTML::Element::addr { goto &HTML::Element::sibdex }

sub HTML::Element::replace_content {
	my $elem = shift;
	$elem->delete_content;
	$elem->push_content(@_);
}

sub HTML::Element::wrap_content {
	my($self, $wrap) = @_;
	my $content = $self->content;
	if (ref $content) {
		$wrap->push_content(@$content);
		@$content = ($wrap);
	}
	else {
		$self->push_content($wrap);
	}
	$wrap;
}

sub HTML::Element::Library::super_literal {
	my($text) = @_;
	HTML::Element->new('~literal', text => $text);
}

sub HTML::Element::position {
	# Report coordinates by chasing addr's up the
	# HTML::ElementSuper tree.  We know we've reached
	# the top when a) there is no parent, or b) the
	# parent is some HTML::Element unable to report
	# it's position.
	my $p = shift;
	my @pos;
	while ($p) {
		my $a = $p->addr;
		unshift @pos, $a if defined $a;
		$p = $p->parent;
	}
	@pos;
}

sub HTML::Element::content_handler {
	my ($tree, %content_hash) = @_;

	for my $k (keys %content_hash) {
		$tree->set_child_content(id => $k, $content_hash{$k});
	}
}

sub HTML::Element::assign { goto &HTML::Element::content_handler }

sub make_counter {
	my $i = 1;
	sub {
		shift() . ':' . $i++
	}
}

sub HTML::Element::iter {
	my ($tree, $p, @data) = @_;

	#	 warn 'P: ' , $p->attr('id') ;
	#	 warn 'H: ' , $p->as_HTML;

	#	 my $id_incr = make_counter;
	my @item = map {
		my $new_item = clone $p;
		$new_item->replace_content($_);
		$new_item;
	} @data;

	$p->replace_with(@item);
}

sub HTML::Element::itercb {
	my ($self, $data, $code) = @_;
	my $orig = $self;
	my $prev = $orig;
	for my $el (@$data) {
		my $current = $orig->clone;
		$code->($el, $current);
		$prev->postinsert($current);
		$prev = $current;
	}
	$orig->detach;
}

sub HTML::Element::iter2 { ## no critic (RequireArgUnpacking)
	my $tree = shift;

	#warn "INPUT TO TABLE2: ", Dumper \@_;

	my %p = validate(
		@_, {
			wrapper_ld   => { default => ['_tag' => 'dl'] },
			wrapper_data => 1,
			wrapper_proc => { default => undef },
			item_ld      => {
				default => sub {
					my $tr = shift;
					[
						$tr->look_down('_tag' => 'dt'),
						$tr->look_down('_tag' => 'dd')
					];
				}},
			item_data   => {
				default => sub {
					my ($wrapper_data) = @_;
					shift @{$wrapper_data};
				}},
			item_proc   => {
				default => sub {
					my ($item_elems, $item_data, $row_count) = @_;
					$item_elems->[$_]->replace_content($item_data->[$_]) for (0,1) ;
					$item_elems;
				}},
			splice      => {
				default => sub {
					my ($container, @item_elems) = @_;
					$container->splice_content(0, 2, @item_elems);
				}
			},
			debug => {default => 0}
		}
	);

	warn 'wrapper_data: ' . Dumper $p{wrapper_data} if $p{debug} ;

	my $container = ref_or_ld($tree, $p{wrapper_ld});
	warn 'container: ' . $container if $p{debug} ;
	warn 'wrapper_(preproc): ' . $container->as_HTML if $p{debug} ;
	$p{wrapper_proc}->($container) if defined $p{wrapper_proc} ;
	warn 'wrapper_(postproc): ' . $container->as_HTML if $p{debug} ;

	my $_item_elems = $p{item_ld}->($container);

	my $row_count;
	my @item_elem;
	while(1){
		my $item_data  = $p{item_data}->($p{wrapper_data});
		last unless defined $item_data;

		warn Dumper('item_data', $item_data) if $p{debug};

		my $item_elems = [ map { $_->clone } @{$_item_elems} ] ;

		if ($p{debug}) {
			for (@{$item_elems}) {
				warn 'ITEM_ELEMS ', $_->as_HTML if $p{debug};
			}
		}

		my $new_item_elems = $p{item_proc}->($item_elems, $item_data, ++$row_count);

		if ($p{debug}) {
			for (@{$new_item_elems}) {
				warn 'NEWITEM_ELEMS ', $_->as_HTML if $p{debug};
			}
		}

		push @item_elem, @{$new_item_elems} ;
	}

	warn 'pushing ' . @item_elem . ' elems' if $p{debug} ;

	$p{splice}->($container, @item_elem);
}

sub HTML::Element::dual_iter {
	my ($parent, $data) = @_;

	my ($prototype_a, $prototype_b) = $parent->content_list;

	#	 my $id_incr = make_counter;

	my $i;

	@$data %2 == 0 or confess 'dataset does not contain an even number of members';

	my @iterable_data = ngroup 2 => @$data;

	my @item = map {
		my ($new_a, $new_b) = map { clone $_ } ($prototype_a, $prototype_b) ;
		$new_a->splice_content(0,1, $_->[0]);
		$new_b->splice_content(0,1, $_->[1]);
		#$_->attr('id', $id_incr->($_->attr('id'))) for ($new_a, $new_b) ;
		($new_a, $new_b)
	} @iterable_data;

	$parent->splice_content(0, 2, @item);
}

sub HTML::Element::set_child_content { ## no critic (RequireArgUnpacking)
	my $tree      = shift;
	my $content   = pop;
	my @look_down = @_;

	my $content_tag = $tree->look_down(@look_down);

	unless ($content_tag) {
		warn "criteria [@look_down] not found";
		return;
	}

	$content_tag->replace_content($content);
}

sub HTML::Element::highlander {
	my ($tree, $local_root_id, $aref, @arg) = @_;

	ref $aref eq 'ARRAY' or confess 'must supply array reference';

	my @aref = @$aref;
	@aref % 2 == 0 or confess 'supplied array ref must have an even number of entries';

	warn __PACKAGE__ if $DEBUG;

	my $survivor;
	while (my ($id, $test) = splice @aref, 0, 2) {
		warn $id if $DEBUG;
		if ($test->(@arg)) {
			$survivor = $id;
			last;
		}
	}

	my @id_survivor = (id => $survivor);
	my $survivor_node = $tree->look_down(@id_survivor);
	#  warn $survivor;
	#  warn $local_root_id;
	#  warn $node;

	warn "survivor: $survivor" if $DEBUG;
	warn 'tree: ' . $tree->as_HTML if $DEBUG;

	$survivor_node or die "search for @id_survivor failed in tree($tree): " . $tree->as_HTML;

	my $survivor_node_parent = $survivor_node->parent;
	$survivor_node = $survivor_node->clone;
	$survivor_node_parent->replace_content($survivor_node);

	warn 'new tree: ' . $tree->as_HTML if $DEBUG;

	$survivor_node;
}

sub HTML::Element::highlander2 { ## no critic (RequireArgUnpacking)
	my $tree = shift;

	my %p = validate(@_, {
		cond        => { type => ARRAYREF },
		cond_arg    => {
			type    => ARRAYREF,
			default => []
		},
		debug       => { default => 0 }
	});

	my @cond = @{$p{cond}};
	@cond % 2 == 0 or confess 'supplied array ref must have an even number of entries';

	warn __PACKAGE__ if $p{debug};

	my @cond_arg = @{$p{cond_arg}};

	my $survivor; my $then;
	while (my ($id, $if_then) = splice @cond, 0, 2) {
		warn $id if $p{debug};
		my ($if, $_then);

		if (ref $if_then eq 'ARRAY') {
			($if, $_then) = @$if_then;
		} else {
			($if, $_then) = ($if_then, sub {});
		}

		if ($if->(@cond_arg)) {
			$survivor = $id;
			$then = $_then;
			last;
		}
	}

	my @ld = (ref $survivor eq 'ARRAY') ? @$survivor : (id => $survivor);

	warn 'survivor:    ', $survivor if $p{debug};
	warn 'survivor_ld: ', Dumper \@ld if $p{debug};

	my $survivor_node = $tree->look_down(@ld);

	$survivor_node or confess "search for @ld failed in tree($tree): " . $tree->as_HTML;

	my $survivor_node_parent = $survivor_node->parent;
	$survivor_node = $survivor_node->clone;
	$survivor_node_parent->replace_content($survivor_node);

	# **************** NEW FUNCTIONALITY *******************
	# apply transforms on survivor node

	warn 'SURV::pre_trans '  . $survivor_node->as_HTML if $p{debug};
	$then->($survivor_node, @cond_arg);
	warn 'SURV::post_trans ' . $survivor_node->as_HTML if $p{debug};
	# **************** NEW FUNCTIONALITY *******************

	$survivor_node;
}

sub overwrite_action {
	my ($mute_node, %X) = @_;

	$mute_node->attr($X{local_attr}{name} => $X{local_attr}{value}{new});
}

sub HTML::Element::overwrite_attr {
	my $tree = shift;

	$tree->mute_elem(@_, \&overwrite_action);
}

sub HTML::Element::mute_elem {
	my ($tree, $mute_attr, $closures, $post_hook) = @_;

	my @mute_node = $tree->look_down($mute_attr => qr/.*/s) ;

	for my $mute_node (@mute_node) {
		my ($local_attr,$mute_key)   = split /\s+/s, $mute_node->attr($mute_attr);
		my $local_attr_value_current = $mute_node->attr($local_attr);
		my $local_attr_value_new     = $closures->{$mute_key}->($tree, $mute_node, $local_attr_value_current);
		$post_hook->(
			$mute_node,
			tree => $tree,
			local_attr => {
				name => $local_attr,
				value => {
					current => $local_attr_value_current,
					new     => $local_attr_value_new
				}
			}
		) if ($post_hook) ;
	}
}



sub HTML::Element::table {
	my ($s, %table) = @_;
	my $table = {};

	# Get the table element
	$table->{table_node} = $s->look_down(id => $table{gi_table});
	$table->{table_node} or confess "table tag not found via (id => $table{gi_table}";

	# Get the prototype tr element(s) 
	my @table_gi_tr = listify $table{gi_tr} ;
	my @iter_node = map {
		my $tr = $table->{table_node}->look_down(id => $_);
		$tr or confess "tr with id => $_ not found";
		$tr;
	} @table_gi_tr;

	warn 'found ' . @iter_node . ' iter nodes ' if $DEBUG;
	my $iter_node =  List::Rotation::Cycle->new(@iter_node);

	# warn $iter_node;
	warn Dumper ($iter_node, \@iter_node) if $DEBUG;

	# $table->{content} = $table{content};
	# $table->{parent}  = $table->{table_node}->parent;

	# $table->{table_node}->detach;
	# $_->detach for @iter_node;

	my @table_rows;

	while (1) {
		my $row = $table{tr_data}->($table, $table{table_data});
		last unless defined $row;

		# get a sample table row and clone it.
		my $I = $iter_node->next;
		warn  "I: $I" if $DEBUG;
		my $new_iter_node = $I->clone;

		$table{td_data}->($new_iter_node, $row);
		push @table_rows, $new_iter_node;
	}

	if (@table_rows) {
		my $replace_with_elem = $s->look_down(id => shift @table_gi_tr) ;
		$s->look_down(id => $_)->detach for @table_gi_tr;
		$replace_with_elem->replace_with(@table_rows);
	}
}

sub ref_or_ld {
	my ($tree, $slot) = @_;

	if (ref($slot) eq 'CODE') {
		$slot->($tree);
	} else {
		$tree->look_down(@$slot);
	}
}

sub HTML::Element::table2 { ## no critic (RequireArgUnpacking)
	my $tree = shift;

	my %p = validate(
		@_, {
			table_ld    => { default => ['_tag' => 'table'] },
			table_data  => 1,
			table_proc  => { default => undef },
			tr_ld       => { default => ['_tag' => 'tr'] },
			tr_data     => {
				default => sub {
					my ($self, $data) = @_;
					shift @{$data};
				}},
			tr_base_id  => { default => undef },
			tr_proc     => { default => sub {} },
			td_proc     => 1,
			debug       => {default => 0}
		}
	);

	warn 'INPUT TO TABLE2: ', Dumper \@_ if $p{debug};
	warn 'table_data: ' . Dumper $p{table_data} if $p{debug} ;

	my $table = {};

	# Get the table element
	$table->{table_node} = ref_or_ld( $tree, $p{table_ld} ) ;
	$table->{table_node} or confess 'table tag not found via ' . Dumper($p{table_ld}) ;

	warn 'table: ' . $table->{table_node}->as_HTML if $p{debug};

	# Get the prototype tr element(s)
	my @proto_tr = ref_or_ld( $table->{table_node},  $p{tr_ld} ) ;

	warn 'found ' . @proto_tr . ' iter nodes' if $p{debug};

	return unless @proto_tr;

	if ($p{debug}) {
		warn $_->as_HTML for @proto_tr;
	}
	my $proto_tr =  List::Rotation::Cycle->new(@proto_tr);

	my $tr_parent = $proto_tr[0]->parent;
	warn 'parent element of trs: ' . $tr_parent->as_HTML if $p{debug};

	my $row_count;

	my @table_rows;

	while(1) {
		my $row = $p{tr_data}->($table, $p{table_data}, $row_count);
		warn 'data row: ' . Dumper $row if $p{debug};
		last unless defined $row;

		# wont work: my $new_iter_node = $table->{iter_node}->clone;
		my $new_tr_node = $proto_tr->next->clone;
		warn "new_tr_node: $new_tr_node" if $p{debug};

		$p{tr_proc}->($tree, $new_tr_node, $row, $p{tr_base_id}, ++$row_count) if defined $p{tr_proc};

		warn 'data row redux: ' . Dumper $row if $p{debug};

		$p{td_proc}->($new_tr_node, $row);
		push @table_rows, $new_tr_node;
	}

	$_->detach for @proto_tr;

	$tr_parent->push_content(@table_rows) if (@table_rows) ;
}

sub HTML::Element::unroll_select {
	my ($s, %select) = @_;

	my $select = {};
	warn 'Select Hash: ' . Dumper(\%select) if $select{debug};

	my $select_node = $s->look_down(id => $select{select_label});
	warn "Select Node:  $select_node" if $select{debug};

	unless ($select{append}) {
		for my $option ($select_node->look_down('_tag' => 'option')) {
			$option->delete;
		}
	}

	my $option = HTML::Element->new('option');
	warn "Option Node: $option" if $select{debug};

	$option->detach;

	while (my $row = $select{data_iter}->($select{data})) {
		warn 'Data Row: ' . Dumper($row) if $select{debug};
		my $o = $option->clone;
		$o->attr('value', $select{option_value}->($row));
		$o->attr('SELECTED', 1) if (exists $select{option_selected} and $select{option_selected}->($row));

		$o->replace_content($select{option_content}->($row));
		$select_node->push_content($o);
		warn $o->as_HTML if $select{debug};
	}
}

sub HTML::Element::set_sibling_content {
	my ($elt, $content) = @_;

	$elt->parent->splice_content($elt->pindex + 1, 1, $content);
}

sub HTML::TreeBuilder::parse_string {
	my ($package, $string) = @_;

	my $h = HTML::TreeBuilder->new;
	HTML::TreeBuilder->parse($string);
}

sub HTML::Element::fid    { shift->look_down(id    => $_[0]) }
sub HTML::Element::fclass { shift->look_down(class => qr/\b$_[0]\b/s) }

1;
__END__

=encoding utf-8

=head1 NAME

HTML::Element::Library - HTML::Element convenience functions

=head1 SYNOPSIS

  use HTML::Element::Library;
  use HTML::TreeBuilder;

=head1 DESCRIPTION

HTML:::Element::Library provides extra methods for HTML::Element.

=head1 METHODS

=head2 Aliases

These are short aliases for common operations:

=over

=item I<$el>->B<fid>(I<$id>)

Finds an element given its id. Equivalent to C<< $el->look_down(id => $id) >>.

=item I<$el>->B<fclass>(I<$class>)

Finds one or more elements given one of their classes. Equivalent to C<< $el->look_down(class => qr/\b$class\b/s) >>

=back

=head2 Positional Querying Methods

=head3 $elem->siblings

Return a list of all nodes under the same parent.

=head3 $elem->sibdex

Return the index of C<$elem> into the array of siblings of which it is
a part. L<HTML::ElementSuper> calls this method C<addr> but I don't
think that is a descriptive name. And such naming is deceptively close
to the C<address> function of C<HTML::Element>. HOWEVER, in the
interest of backwards compatibility, both methods are available.

=head3 $elem->addr

Same as sibdex

=head3 $elem->position()

Returns the coordinates of this element in the tree it inhabits. This
is accomplished by succesively calling addr() on ancestor elements
until either a) an element that does not support these methods is
found, or b) there are no more parents. The resulting list is the
n-dimensional coordinates of the element in the tree.

=head2 Element Decoration Methods

=head3 HTML::Element::Library::super_literal($text)

In L<HTML::Element>, Sean Burke discusses super-literals. They are
text which does not get escaped. Great for includng Javascript in
HTML. Also great for including foreign language into a document.

So, you basically toss C<super_literal> your text and back comes your
text wrapped in a C<~literal> element.

One of these days, I'll around to writing a nice C<EXPORT> section.

=head2 Tree Rewriting Methods

=head3 "de-prepping" HTML

Oftentimes, the HTML to be worked with will have multiple sample rows:

  <OL>
   <LI>bread
   <LI>butter
   <LI>beer
   <LI>bacon
  </OL>

But, before you begin to rewrite the HTML with your model data, you
typically only want 1 or 2 sample rows.

Thus, you want to "crunch" the multiple sample rows to a specified
amount. Hence the C<crunch> method:

  $tree->crunch(look_down => [ '_tag' => 'li' ], leave => 2) ;

The C<leave> argument defaults to 1 if not given. The call above would
"crunch" the above 4 sample rows to:

  <OL>
   <LI>bread
   <LI>butter
  </OL>

=head3 Simplifying calls to HTML::FillInForm

Since HTML::FillInForm gets and returns strings, using HTML::Element
instances becomes tedious:

   1. Seamstress has an HTML tree that it wants the form filled in on
   2. Seamstress converts this tree to a string
   3. FillInForm parses the string into an HTML tree and then fills in the form
   4. FillInForm converts the HTML tree to a string
   5. Seamstress re-parses the HTML for additional processing

I've filed a bug about this:
L<https://rt.cpan.org/Ticket/Display.html?id=44105>

This function, fillinform, allows you to pass a tree to fillinform
(along with your data structure) and get back a tree:

  my $new_tree = $html_tree->fillinform($data_structure);

=head3 Mapping a hashref to HTML elements

It is very common to get a hashref of data from some external source -
flat file, database, XML, etc. Therefore, it is important to have a
convenient way of mapping this data to HTML.

As it turns out, there are 3 ways to do this in
HTML::Element::Library. The most strict and structured way to do this
is with C<content_handler>. Two other methods, C<hashmap> and
C<datamap> require less manual mapping and may prove even more easy to
use in certain cases.

As is usual with Perl, a practical example is always best. So let's
take some sample HTML:

  <h1>user data</h1>
  <span id="name">?</span> 
  <span id="email">?</span> 
  <span id="gender">?</span> 

Now, let's say our data structure is this:

  $ref = { email => 'jim@beam.com', gender => 'lots' } ;

And let's start with the most strict way to get what you want:

 $tree->content_handler(email => $ref->{email} , gender => $ref->{gender}) ;

In this case, you manually state the mapping between id tags and
hashref keys and then C<content_handler> retrieves the hashref data
and pops it in the specified place.

Now let's look at the two (actually 2 and a half) other hash-mapping
methods.

 $tree->hashmap(id => $ref);

Now, what this function does is super-destructive. It finds every
element in the tree with an attribute named id (since 'id' is a
parameter, it could find every element with some other attribute also)
and replaces the content of those elements with the hashref value.

So, in the case above, the

   <span id="name">?</span>

would come out as

  <span id="name"></span>

(it would be blank) - because there is nothing in the hash with that
value, so it substituted

  $ref->{name}

which was blank and emptied the contents.

Now, let's assume we want to protect name from being auto-assigned.
Here is what you do:

 $tree->hashmap(id => $ref, ['name']);

That last array ref is an exclusion list.

But wouldnt it be nice if you could do a hashmap, but only assigned
things which are defined in the hashref? C<< defmap() >> to the
rescue:

 $tree->defmap(id => $ref);

does just that, so

   <span id="name">?</span>

would be left alone.

=head4 $elem->hashmap($attr_name, \%hashref, \@excluded, $debug)

This method is designed to take a hashref and populate a series of
elements. For example:

  <table>
    <tr sclass="tr" class="alt" align="left" valign="top">
      <td smap="people_id">1</td>
      <td smap="phone">(877) 255-3239</td>
      <td smap="password">*********</td>
    </tr>
  </table>

In the table above, there are several attributes named C<< smap >>. If
we have a hashref whose keys are the same:

  my %data = (people_id => 888, phone => '444-4444', password => 'dont-you-dare-render');

Then a single API call allows us to populate the HTML while excluding
those ones we don't:

  $tree->hashmap(smap => \%data, ['password']);

Note: the other way to prevent rendering some of the hash mapping is
to not give that element the attr you plan to use for hash mapping.

Also note: the function C<< hashmap >> has a simple easy-to-type API.
Interally, it calls C<< hash_map >> (which has a more verbose keyword
calling API). Thus, the above call to C<hashmap()> results in this
call:

  $tree->hash_map(hash => \%data, to_attr => 'sid', excluding => ['password']);

=head4 $elem->defmap($attr_name, \%hashref, $debug)

C<defmap> was described above.

=head3 $elem->replace_content(@new_elem)

Replaces all of C<$elem>'s content with C<@new_elem>.

=head3 $elem->wrap_content($wrapper_element)

Wraps the existing content in the provided element. If the provided
element happens to be a non-element, a push_content is performed
instead.

=head3 $elem->set_child_content(@look_down, $content)

This method looks down $tree using the criteria specified in
@look_down using the the HTML::Element look_down() method.

After finding the node, it detaches the node's content and pushes
$content as the node's content.

=head3 $tree->content_handler(%id_content)

This is a convenience method. Because the look_down criteria will
often simply be:

  id => 'fixme'

to find things like:

  <a id=fixme href=http://www.somesite.org>replace_content</a>

You can call this method to shorten your typing a bit. You can simply
type

  $elem->content_handler( fixme => 'new text' )

Instead of typing:

  $elem->set_child_content(sid => 'fixme', 'new text')

ALSO NOTE: you can pass a hash whose keys are C<id>s and whose values
are the content you want there and it will perform the replacement on
each hash member:

  my %id_content = (name => "Terrence Brannon",
                    email => 'tbrannon@in.com',
                    balance => 666,
                    content => $main_content);
  $tree->content_handler(%id_content);

=head3 $tree->highlander($subtree_span_id, $conditionals, @conditionals_args)

This allows for "if-then-else" style processing. Highlander was a
movie in which only one would survive. Well, in terms of a tree when
looking at a structure that you want to process in C<if-then-else>
style, only one child will survive. For example, given this HTML
template:

 <span klass="highlander" id="age_dialog">
    <span id="under10">
       Hello, does your mother know you're
       using her AOL account?
    </span>
    <span id="under18">
       Sorry, you're not old enough to enter
       (and too dumb to lie about your age)
    </span>
    <span id="welcome">
       Welcome
    </span>
 </span>

We only want one child of the C<span> tag with id C<age_dialog> to
remain based on the age of the person visiting the page.

So, let's setup a call that will prune the subtree as a function of
age:

 sub process_page {
  my $age = shift;
  my $tree = HTML::TreeBuilder->new_from_file('t/html/highlander.html');

  $tree->highlander
    (age_dialog =>
     [
      under10 => sub { $_[0] < 10},
      under18 => sub { $_[0] < 18},
      welcome => sub { 1 }
     ],
     $age
    );

And there we have it. If the age is less than 10, then the node with
id C<under10> remains. For age less than 18, the node with id
C<under18> remains. Otherwise our "else" condition fires and the child
with id C<welcome> remains.

=head3 $tree->passover(@id_of_element)

In some cases, you know exactly which element(s) should survive. In
this case, you can simply call C<passover> to remove it's (their)
siblings. For the HTML above, you could delete C<under10> and
C<welcome> by simply calling:

  $tree->passover('under18');

Because passover takes an array, you can specify several children to
preserve.

=head3 $tree->highlander2($tree, $conditionals, @conditionals_args)

Right around the same time that C<table2()> came into being,
Seamstress began to tackle tougher and tougher processing problems. It
became clear that a more powerful highlander was needed... one that
not only snipped the tree of the nodes that should not survive, but
one that allows for post-processing of the survivor node. And one that
was more flexible with how to find the nodes to snip.

Thus (drum roll) C<highlander2()>.

So let's look at our HTML which requires post-selection processing:

 <span klass="highlander" id="age_dialog">
    <span id="under10">
       Hello, little <span id=age>AGE</span>-year old,
    does your mother know you're using her AOL account?
    </span>
    <span id="under18">
       Sorry, you're only <span id=age>AGE</span>
       (and too dumb to lie about your age)
    </span>
    <span id="welcome">
       Welcome, isn't it good to be <span id=age>AGE</span> years old?
    </span>
</span>

In this case, a branch survives, but it has dummy data in it. We must
take the surviving segment of HTML and rewrite the age C<span> with
the age. Here is how we use C<highlander2()> to do so:

  sub replace_age {
    my $branch = shift;
    my $age = shift;
    $branch->look_down(id => 'age')->replace_content($age);
  }

  my $if_then = $tree->look_down(id => 'age_dialog');

  $if_then->highlander2(
    cond => [
      under10 => [
        sub { $_[0] < 10} ,
        \&replace_age
       ],
      under18 => [
        sub { $_[0] < 18} ,
        \&replace_age
       ],
      welcome => [
        sub { 1 },
        \&replace_age
       ]
     ],
    cond_arg => [ $age ]
  );

We pass it the tree (C<$if_then>), an arrayref of conditions (C<cond>)
and an arrayref of arguments which are passed to the C<cond>s and to
the replacement subs.

The C<under10>, C<under18> and C<welcome> are id attributes in the
tree of the siblings of which only one will survive. However, should
you need to do more complex look-downs to find the survivor, then
supply an array ref instead of a simple scalar:

  $if_then->highlander2(
    cond => [
      [class => 'r12'] => [
        sub { $_[0] < 10} ,
        \&replace_age
       ],
      [class => 'z22'] => [
        sub { $_[0] < 18} ,
        \&replace_age
       ],
      [class => 'w88'] => [
        sub { 1 },
        \&replace_age
       ]
     ],
    cond_arg => [ $age ]
  );

=head3 $tree->overwrite_attr($mutation_attr => $mutating_closures)

This method is designed for taking a tree and reworking a set of nodes
in a stereotyped fashion. For instance let's say you have 3 remote
image archives, but you don't want to put long URLs in your img src
tags for reasons of abstraction, re-use and brevity. So instead you do
this:

  <img src="/img/smiley-face.jpg" fixup="src lnc">
  <img src="/img/hot-babe.jpg"    fixup="src playboy">
  <img src="/img/footer.jpg"      fixup="src foobar">

and then when the tree of HTML is being processed, you make this call:

  my %closures = (
     lnc     => sub { my ($tree, $mute_node, $attr_value)= @_; "http://lnc.usc.edu$attr_value" },
     playboy => sub { my ($tree, $mute_node, $attr_value)= @_; "http://playboy.com$attr_value" }
     foobar  => sub { my ($tree, $mute_node, $attr_value)= @_; "http://foobar.info$attr_value" }
  )

  $tree->overwrite_attr(fixup => \%closures) ;

and the tags come out modified like so:

  <img src="http://lnc.usc.edu/img/smiley-face.jpg" fixup="src lnc">
  <img src="http://playboy.com/img/hot-babe.jpg"    fixup="src playboy">
  <img src="http://foobar.info/img/footer.jpg"      fixup="src foobar">

=head3 $tree->mute_elem($mutation_attr => $mutating_closures, [ $post_hook ] )

This is a generalization of C<overwrite_attr>. C<overwrite_attr>
assumes the return value of the closure is supposed overwrite an
attribute value and does it for you. C<mute_elem> is a more general
function which does nothing but hand the closure the element and let
it mutate it as it jolly well pleases :)

In fact, here is the implementation of C<overwrite_attr> to give you a
taste of how C<mute_attr> is used:

  sub overwrite_action {
    my ($mute_node, %X) = @_;

    $mute_node->attr($X{local_attr}{name} => $X{local_attr}{value}{new});
  }


  sub HTML::Element::overwrite_attr {
    my $tree = shift;

    $tree->mute_elem(@_, \&overwrite_action);
  }

=head2 Tree-Building Methods

=head3 Unrolling an array via a single sample element (<ul> container)

This is best described by example. Given this HTML:

 <strong>Here are the things I need from the store:</strong>
 <ul>
   <li class="store_items">Sample item</li>
 </ul>

We can unroll it like so:

  my $li = $tree->look_down(class => 'store_items');

  my @items = qw(bread butter vodka);

  $tree->iter($li => @items);

To produce this:

 <html>
  <head></head>
  <body>Here are the things I need from the store:
    <ul>
      <li class="store_items">bread</li>
      <li class="store_items">butter</li>
      <li class="store_items">vodka</li>
    </ul>
  </body>
 </html>

Now, you might be wondering why the API call is:

  $tree->iter($li => @items)

instead of:

  $li->iter(@items)

and there is no good answer. The latter would be more concise and it
is what I should have done.

=head3 Unrolling an array via a single sample element and a callback (<ul> container)

This is a more advanced version of the previous method. Instead of
cloning the sample element several times and calling
C<replace_content> on the clone with the array element, a custom
callback is called with the clone and array element.

Here is the example from before.

 <strong>Here are the things I need from the store:</strong>
 <ul>
   <li class="store_items">Sample item</li>
 </ul>

Code:

  sub cb {
    my ($data, $li) = @_;
    $li->replace_content($data);
  }

  my $li = $tree->look_down(class => 'store_items');
  my @items = qw(bread butter vodka);
  $li->itercb(\@items, \&cb);

Output is as before:

 <html>
  <head></head>
  <body>Here are the things I need from the store:
    <ul>
      <li class="store_items">bread</li>
      <li class="store_items">butter</li>
      <li class="store_items">vodka</li>
    </ul>
  </body>
 </html>

Here is a more complex example (unrolling a table). HTML:

  <table><thead><th>First Name<th>Last Name<th>Option</thead>
  <tbody>
  <tr><td class="first">First<td class="last">Last<td class="option">1
  </tbody></table>

Code:

  sub tr_cb {
    my ($data, $tr) = @_;
    $tr->look_down(class => 'first')->replace_content($data->{first});
    $tr->look_down(class => 'last')->replace_content($data->{last});
    $tr->look_down(class => 'option')->replace_content($data->{option});
  }

  my @data = (
    {first => 'Foo', last => 'Bar', option => 2},
    {first => 'Bar', last => 'Bar', option => 3},
    {first => 'Baz', last => 'Bar', option => 4},
  );

  my $tr = $tree->find('table')->find('tbody')->find('tr');
  $tr->itercb(\@data, \&tr_cb);

Produces:

  <table><thead><th>First Name<th>Last Name<th>Option</thead>
  <tbody>
  <tr><td class="first">Foo<td class="last">Bar<td class="option">2
  <tr><td class="first">Bar<td class="last">Bar<td class="option">3
  <tr><td class="first">Baz<td class="last">Bar<td class="option">4
  </tbody></table>

=head3 Unrolling an array via n sample elements (<dl> container)

C<iter()> was fine for awhile, but some things (e.g. definition lists)
need a more general function to make them easy to do. Hence
C<iter2()>. This function will be explained by example of unrolling a
simple definition list.

So here's our mock-up HTML from the designer:

  <dl class="dual_iter" id="service_plan">
    <dt>Artist</dt>
    <dd>A person who draws blood.</dd>

    <dt>Musician</dt>
    <dd>A clone of Iggy Pop.</dd>

    <dt>Poet</dt>
    <dd>A relative of Edgar Allan Poe.</dd>

    <dt class="adstyle">sample header</dt>
    <dd class="adstyle2">sample data</dd>
</dl>


And we want to unroll our data set:

  my @items = (
    ['the pros'   => 'never have to worry about service again'],
    ['the cons'   => 'upfront extra charge on purchase'],
    ['our choice' => 'go with the extended service plan']
  );


Now, let's make this problem a bit harder to show off the power of
C<iter2()>. Let's assume that we want only the last <dt> and it's
accompanying <dd> (the one with "sample data") to be used as the
sample data for unrolling with our data set. Let's further assume that
we want them to remain in the final output.

So now, the API to C<iter2()> will be discussed and we will explain
how our goal of getting our data into HTML fits into the API.

=over 4

=item * wrapper_ld

This is how to look down and find the container of all the elements we
will be unrolling. The <dl> tag is the container for the dt and dd
tags we will be unrolling.

If you pass an anonymous subroutine, then it is presumed that
execution of this subroutine will return the HTML::Element
representing the container tag. If you pass an array ref, then this
will be dereferenced and passed to C<HTML::Element::look_down()>.

default value: C<< ['_tag' => 'dl'] >>

Based on the mock HTML above, this default is fine for finding our
container tag. So let's move on.

=item * wrapper_data

This is an array reference of data that we will be putting into the
container. You must supply this. C<@items> above is our
C<wrapper_data>.

=item * wrapper_proc

After we find the container via C<wrapper_ld>, we may want to
pre-process some aspect of this tree. In our case the first two sets
of dt and dd need to be removed, leaving the last dt and dd. So, we
supply a C<wrapper_proc> which will do this.

default: undef

=item * item_ld

This anonymous subroutine returns an array ref of C<HTML::Element>s
that will be cloned and populated with item data (item data is a "row"
of C<wrapper_data>).

default: returns an arrayref consisting of the dt and dd element
inside the container.

=item * item_data

This is a subroutine that takes C<wrapper_data> and retrieves one
"row" to be "pasted" into the array ref of C<HTML::Element>s found via
C<item_ld>. I hope that makes sense.

default: shifts C<wrapper_data>.

=item * item_proc

This is a subroutine that takes the C<item_data> and the
C<HTML::Element>s found via C<item_ld> and produces an arrayref of
C<HTML::Element>s which will eventually be spliced into the container.

Note that this subroutine MUST return the new items. This is done So
that more items than were passed in can be returned. This is useful
when, for example, you must return 2 dts for an input data item. And
when would you do this? When a single term has multiple spellings for
instance.

default: expects C<item_data> to be an arrayref of two elements and
C<item_elems> to be an arrayref of two C<HTML::Element>s. It replaces
the content of the C<HTML::Element>s with the C<item_data>.

=item * splice

After building up an array of C<@item_elems>, the subroutine passed as
C<splice> will be given the parent container HTML::Element and the
C<@item_elems>. How the C<@item_elems> end up in the container is up
to this routine: it could put half of them in. It could unshift them
or whatever.

default: C<< $container->splice_content(0, 2, @item_elems) >> In other
words, kill the 2 sample elements with the newly generated @item_elems

=back

So now that we have documented the API, let's see the call we need:

 $tree->iter2(
  # default wrapper_ld ok.
  wrapper_data => \@items,
  wrapper_proc => sub {
    my ($container) = @_;

    # only keep the last 2 dts and dds
    my @content_list = $container->content_list;
    $container->splice_content(0, @content_list - 2);
  },

  # default item_ld is fine.
  # default item_data is fine.
  # default item_proc is fine.
  splice       => sub {
    my ($container, @item_elems) = @_;
    $container->unshift_content(@item_elems);
  },
  debug => 1,
 );

=head3 Select Unrolling

The C<unroll_select> method has this API:

   $tree->unroll_select(
      select_label    => $id_label,
      option_value    => $closure, # how to get option value from data row
      option_content  => $closure, # how to get option content from data row
      option_selected => $closure, # boolean to decide if SELECTED
      data            => $data     # the data to be put into the SELECT
      data_iter       => $closure  # the thing that will get a row of data
      debug           => $boolean,
      append          => $boolean, # remove the sample <OPTION> data or append?
    );

Here's an example:

  $tree->unroll_select(
    select_label     => 'clan_list',
    option_value     => sub { my $row = shift; $row->clan_id },
    option_content   => sub { my $row = shift; $row->clan_name },
    option_selected  => sub { my $row = shift; $row->selected },
    data             => \@query_results,
    data_iter        => sub { my $data = shift; $data->next },
    append => 0,
    debug => 0
  );

=head2 Tree-Building Methods: Table Generation

Matthew Sisk has a much more intuitive (imperative) way to generate
tables via his module L<HTML::ElementTable|HTML::ElementTable>.

However, for those with callback fever, the following method is
available. First, we look at a nuts and bolts way to build a table
using only standard L<HTML::Tree> API calls. Then the C<table> method
available here is discussed.

=head3 Sample Model

  package Simple::Class;

  use Set::Array;

  my @name   = qw(bob bill brian babette bobo bix);
  my @age    = qw(99  12   44    52      12   43);
  my @weight = qw(99  52   80   124     120  230);


  sub new {
    my $this = shift;
    bless {}, ref($this) || $this;
  }

  sub load_data {
    my @data;

    for (0 .. 5) {
      push @data, {
        age    => $age[rand $#age] + int rand 20,
        name   => shift @name,
        weight => $weight[rand $#weight] + int rand 40
      }
    }

    Set::Array->new(@data);
  }

  1;

=head4 Sample Usage:

  my $data = Simple::Class->load_data;
  ++$_->{age} for @$data

=head3 Inline Code to Unroll a Table

=head4 HTML

  <html>
    <table id="load_data">
      <tr>  <th>name</th><th>age</th><th>weight</th> </tr>
      <tr id="iterate">
          <td id="name">   NATURE BOY RIC FLAIR  </td>
          <td id="age">    35                    </td>
          <td id="weight"> 220                   </td>
      </tr>
    </table>
  </html>


=head4 The manual way (*NOT* recommended)

  require 'simple-class.pl';
  use HTML::Seamstress;

  # load the view
  my $seamstress = HTML::Seamstress->new_from_file('simple.html');

  # load the model
  my $o = Simple::Class->new;
  my $data = $o->load_data;

  # find the <table> and <tr>
  my $table_node = $seamstress->look_down('id', 'load_data');
  my $iter_node  = $table_node->look_down('id', 'iterate');
  my $table_parent = $table_node->parent;


  # drop the sample <table> and <tr> from the HTML
  # only add them in if there is data in the model
  # this is achieved via the $add_table flag

  $table_node->detach;
  $iter_node->detach;
  my $add_table;

  # Get a row of model data
  while (my $row = shift @$data) {

    # We got row data. Set the flag indicating ok to hook the table into the HTML
    ++$add_table;

    # clone the sample <tr>
    my $new_iter_node = $iter_node->clone;

    # find the tags labeled name age and weight and
    # set their content to the row data
    $new_iter_node->content_handler($_ => $row->{$_})
     for qw(name age weight);

    $table_node->push_content($new_iter_node);

  }

  # reattach the table to the HTML tree if we loaded data into some table rows

  $table_parent->push_content($table_node) if $add_table;

  print $seamstress->as_HTML;

=head3 $tree->table() : API call to Unroll a Table

  require 'simple-class.pl';
  use HTML::Seamstress;

  # load the view
  my $seamstress = HTML::Seamstress->new_from_file('simple.html');
  # load the model
  my $o = Simple::Class->new;

  $seamstress->table
    (
     # tell seamstress where to find the table, via the method call
     # ->look_down('id', $gi_table). Seamstress detaches the table from the
     # HTML tree automatically if no table rows can be built

       gi_table    => 'load_data',

     # tell seamstress where to find the tr. This is a bit useless as
     # the <tr> usually can be found as the first child of the parent

       gi_tr       => 'iterate',

     # the model data to be pushed into the table

       table_data  => $o->load_data,

     # the way to take the model data and obtain one row
     # if the table data were a hashref, we would do:
     # my $key = (keys %$data)[0]; my $val = $data->{$key}; delete $data->{$key}

       tr_data     => sub {
         my ($self, $data) = @_;
         shift @{$data} ;
       },

     # the way to take a row of data and fill the <td> tags

       td_data     => sub {
         my ($tr_node, $tr_data) = @_;
         $tr_node->content_handler($_ => $tr_data->{$_})
        for qw(name age weight)
       }
    );

  print $seamstress->as_HTML;

=head4 Looping over Multiple Sample Rows

* HTML

  <html>
    <table id="load_data" CELLPADDING=8 BORDER=2>
    <tr>  <th>name</th><th>age</th><th>weight</th> </tr>
    <tr id="iterate1" BGCOLOR="white" >
      <td id="name">   NATURE BOY RIC FLAIR  </td>
      <td id="age">    35                    </td>
      <td id="weight"> 220                   </td>
    </tr>
    <tr id="iterate2" BGCOLOR="#CCCC99">
      <td id="name">   NATURE BOY RIC FLAIR  </td>
      <td id="age">    35                    </td>
      <td id="weight"> 220                   </td>
    </tr>
  </table>
</html>

* Only one change to last API call.

This:

  gi_tr       => 'iterate',

becomes this:

  gi_tr       => ['iterate1', 'iterate2']

=head3 $tree->table2() : New API Call to Unroll a Table

After 2 or 3 years with C<table()>, I began to develop production
websites with it and decided it needed a cleaner interface,
particularly in the area of handling the fact that C<id> tags will be
the same after cloning a table row.

First, I will give a dry listing of the function's argument
parameters. This will not be educational most likely. A better way to
understand how to use the function is to read through the incremental
unrolling of the function's interface given in conversational style
after the dry listing. But take your pick. It's the same information
given in two different ways.

=head4 Dry/technical parameter documentation

C<< $tree->table2(%param) >> takes the following arguments:

=over

=item * C<< table_ld => $look_down >> : optional

How to find the C<table> element in C<$tree>. If C<$look_down> is an
arrayref, then use C<look_down>. If it is a CODE ref, then call it,
passing it C<$tree>.

Defaults to C<< ['_tag' => 'table'] >> if not passed in.

=item * C<< table_data => $tabular_data >> : required

The data to fill the table with. I<Must> be passed in.

=item * C<< table_proc => $code_ref >> : not implemented

A subroutine to do something to the table once it is found. Not
currently implemented. Not obviously necessary. Just created because
there is a C<tr_proc> and C<td_proc>.

=item * C<< tr_ld => $look_down >> : optional

Same as C<table_ld> but for finding the table row elements. Please
note that the C<tr_ld> is done on the table node that was found
I<instead> of the whole HTML tree. This makes sense. The C<tr>s that
you want exist below the table that was just found.

Defaults to C<< ['_tag' => 'tr'] >> if not passed in.

=item * C<< tr_data => $code_ref >> : optional

How to take the C<table_data> and return a row. Defaults to:

  sub { my ($self, $data) = @_;
    shift(@{$data}) ;
  }

=item * C<< tr_proc => $code_ref >> : optional

Something to do to the table row we are about to add to the table we
are making. Defaults to a routine which makes the C<id> attribute
unique:

  sub {
    my ($self, $tr, $tr_data, $tr_base_id, $row_count) = @_;
    $tr->attr(id => sprintf "%s_%d", $tr_base_id, $row_count);
  }

=item * C<< td_proc => $code_ref >> : required

This coderef will take the row of data and operate on the C<td> cells
that are children of the C<tr>. See C<t/table2.t> for several usage
examples.

Here's a sample one:

  sub {
    my ($tr, $data) = @_;
    my @td = $tr->look_down('_tag' => 'td');
    for my $i (0..$#td) {
      $td[$i]->splice_content(0, 1, $data->[$i]);
    }
  }

=back

=head4 Conversational parameter documentation

The first thing you need is a table. So we need a look down for that.
If you don't give one, it defaults to

  ['_tag' => 'table']

What good is a table to display in without data to display?! So you
must supply a scalar representing your tabular data source. This
scalar might be an array reference, a C<next>able iterator, a DBI
statement handle. Whatever it is, it can be iterated through to build
up rows of table data. These two required fields (the way to find the
table and the data to display in the table) are C<table_ld> and
C<table_data> respectively. A little more on C<table_ld>. If this
happens to be a CODE ref, then execution of the code ref is presumed
to return the C<HTML::Element> representing the table in the HTML
tree.

Next, we get the row or rows which serve as sample C<tr> elements by
doing a C<look_down> from the C<table_elem>. While normally one sample
row is enough to unroll a table, consider when you have alternating
table rows. This API call would need one of each row so that it can
cycle through the sample rows as it loops through the data.
Alternatively, you could always just use one row and make the
necessary changes to the single C<tr> row by mutating the element in
C<tr_proc>, discussed below. The default C<tr_ld> is C<< ['_tag' =>
'tr'] >> but you can overwrite it. Note well, if you overwrite it with
a subroutine, then it is expected that the subroutine will return the
C<HTML::Element>(s) which are C<tr> element(s). The reason a
subroutine might be preferred is in the case that the HTML designers
gave you 8 sample C<tr> rows but only one prototype row is needed. So
you can write a subroutine, to splice out the 7 rows you don't need
and leave the one sample row remaining so that this API call can clone
it and supply it to the C<tr_proc> and C<td_proc> calls.

Now, as we move through the table rows with table data, we need to do
two different things on each table row:

=over 4

=item * get one row of data from the C<table_data> via C<tr_data>

The default procedure assumes the C<table_data> is an array reference
and shifts a row off of it:

  sub {
     my ($self, $data) = @_;
     shift @{$data};
  }

Your function MUST return undef when there is no more rows to lay out.

=item * take the C<tr> element and mutate it via C<tr_proc>

The default procedure simply makes the id of the table row unique:

  sub {
    my ($self, $tr, $tr_data, $row_count, $root_id) = @_;
    $tr->attr(id => sprintf "%s_%d", $root_id, $row_count);
  }

=back

Now that we have our row of data, we call C<td_proc> so that it can
take the data and the C<td> cells in this C<tr> and process them. This
function I<must> be supplied.

=head3 Whither a Table with No Rows

Often when a table has no rows, we want to display a message
indicating this to the view. Use conditional processing to decide what
to display:

  <span id=no_data>
    <table><tr><td>No Data is Good Data</td></tr></table>
  </span>
  <span id=load_data>
     <html>
       <table id="load_data">
         <tr>  <th>name</th><th>age</th><th>weight</th> </tr>
         <tr id="iterate">
           <td id="name">   NATURE BOY RIC FLAIR  </td>
           <td id="age">    35                    </td>
           <td id="weight"> 220                   </td>
         </tr>
       </table>
     </html>
  </span>

=head2 Tree-Killing Methods

=head3 $tree->prune

This removes any nodes from the tree which consist of nothing or
nothing but whitespace. See also delete_ignorable_whitespace in
L<HTML::Element>.

=head2 Loltree Functions

A loltree is an arrayref consisting of arrayrefs which is used by C<<
new_from__lol >> in L<HTML::Element> to produce HTML trees. The CPAN
distro L<XML::Element::Tolol> creates such XML trees by parsing XML
files, analogous to L<XML::Toolkit>. The purpose of the functions in
this section is to allow you manipulate a loltree programmatically.

These could not be methods because if you bless a loltree, then
HTML::Tree will barf.

=head3 HTML::Element::newchild($lol, $parent_label, @newchild)

Given this initial loltree:

  my $initial_lol = [ note => [ shopping => [ item => 'sample' ] ] ];

This code:

  sub shopping_items {
    my @shopping_items = map { [ item => _ ] } qw(bread butter beans);
    @shopping_items;
  }

  my $new_lol = HTML::Element::newnode($initial_lol, item => shopping_items());

 will replace the single sample with a list of shopping items:

     [
          'note',
          [
            'shopping',
              [
                'item',
                'bread'
              ],
              [
                'item',
                'butter'
              ],
              [
                'item',
                'beans'
              ]

          ]
        ];

Thanks to kcott and the other Perlmonks in this thread:
http://www.perlmonks.org/?node_id=912416


=head1 SEE ALSO

=head2 L<HTML::Tree>

A perl package for creating and manipulating HTML trees.

=head2 L<HTML::ElementTable>

An L<HTML::Tree> - based module which allows for manipulation of HTML
trees using cartesian coordinations.

=head2 L<HTML::Seamstress>

An L<HTML::Tree> - based module inspired by XMLC
(L<http://xmlc.enhydra.org>), allowing for dynamic HTML generation via
tree rewriting.

=head2 Push-style templating systems

A comprehensive cross-language
L<list of push-style templating systems|http://perlmonks.org/?node_id=674225>.

=head1 TODO

=over

=item * highlander2

currently the API expects the subtrees to survive or be pruned to be
identified by id:

  $if_then->highlander2([
    under10 => sub { $_[0] < 10} ,
    under18 => sub { $_[0] < 18} ,
    welcome => [
      sub { 1 },
      sub {
        my $branch = shift;
        $branch->look_down(id => 'age')->replace_content($age);
      }
     ]
   ], $age);

but, it should be more flexible. the C<under10>, and C<under18> are
expected to be ids in the tree... but it is not hard to have a check
to see if this field is an array reference and if it, then to do a
look down instead:

  $if_then->highlander2([
    [class => 'under10'] => sub { $_[0] < 10} ,
    [class => 'under18'] => sub { $_[0] < 18} ,
    [class => 'welcome'] => [
      sub { 1 },
      sub {
        my $branch = shift;
        $branch->look_down(id => 'age')->replace_content($age);
      }
     ]
   ], $age);

=back

=head1 AUTHOR

Original author Terrence Brannon, E<lt>tbone@cpan.orgE<gt>.

Adopted by Marius Gavrilescu C<< <marius@ieval.ro> >>.

I appreciate the feedback from M. David Moussa Leo Keita regarding
some issues with the test suite, namely (1) CRLF leading to test
breakage in F<t/crunch.t> and (2) using the wrong module in
F<t/prune.t> thus not having the right functionality available.

Many thanks to BARBIE for his RT bug report.

Many thanks to perlmonk kcott for his work on array rewriting:
L<http://www.perlmonks.org/?node_id=912416>. It was crucial in the
development of newchild.

=head1 COPYRIGHT AND LICENSE

Coypright (C) 2014-2016 by Marius Gavrilescu

Copyright (C) 2004-2012 by Terrence Brannon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
