#TODO: prepare_again = 1:
#      a field may be substituted by a tag node that should be prepared!
#TODO: template/allow_dynamic_field_value_generation doesn't work
#      mixed static/dynamic fields currently don't work:
#      <& template src="bla" &>
#        <$ static_field $>foo<$ / $>
#        <& perl &>print '<$ dynamic_field $>bar<$ / $>'<& / &>
#      <& / &>
#      => fix doc?!
#FEATURE: substitute: recursively replace lists => lists in lists
#         <+@ items @+>
#            <+$ description / $+>
#            <+@ subitems @+>
#              <+$ title / $+>
#            <+@ / @+>
#         <+@ / @+>
#         
#         <@ items @>
#            <$ description $>foo<$ / $>
#            <@ subitems @>
#               <$ title $>a<$ / $>
#               <$ title $>b<$ / $>
#            <@ / @>
#            
#            <$ description $>bar<$ / $>
#            <@ subitems @>
#               <$ title $>c<$ / $>
#               <$ title $>d<$ / $>
#            <@ / @>
#         <@ / @>
#FEATURE: if a list value is not defined, use the field value if exists
#FEATURE: default value for empty lists (see above?)
#FEATURE: inherit templates from parent dirs? (mason/zope like)

=head1 NAME

Konstrukt::Plugin::template - Konstrukt templating engine

=head1 SYNOPSIS
	
=head2 Tag interface

	<& template src="some.template" &>
		<$ field $>will be inserted in the template<$ / $>
	<& / &>

=head2 Perl interface

	use_plugin 'template';
	$self->add_node($template->node('path/to/some.template', { 
		field1 => 'value1',
		some_list => [
			{ field1 => 'a', field2 => 'b' },
			{ field1 => 'c', field2 => 'd' },
			...
		]
	}));

=head1 DESCRIPTION

An important goal of this framework is the fast creation of maintainable static
content. Therefore the template (L<Konstrukt::Plugin::template>) plugin was developed.

You are enouraged to encapsulate your web site components that are used in several
places in templates, which then can be reused to avoid redundancy.
A website usually consists of several components, that are used in many pages
(layout, navigation, frames, tables, ...).

Each template consists of static text and variable parts, that can be
substituted on the usage of the template.

There are two interfaces to this plugin.
You may use special tags within your documents that will not annoy a non-programmer and
fit seemlessly into the other markup.
You may also use a perl-interface that will fit into your perl code
(plugins or embedded perl).

=head2 Tag interface / Syntax

=head3 Fields

Templates can contain single variable B<fields>, which can be substituted on the
usage of the template and may have a default value.

B<Definition>: some.template

	some text here
	this <+$ field_name $+>should be<+$ / $> replaced.
	some text there
	a field without a default value: <+$ no_default / $+>
	end

B<Usage>:
	
	here we will use the template:
	<& template src="some.template" &>
		<$ field_name $>has been<$ / $>
		<$ no_default $>foo<$ / $>
	<& / &>
	
	you can also define the field values with a tag attribute:
	<& template src="some.template" no_default="bar" / &>

B<Result>: (whitespaces may vary...)

	here we will use the template:
	
	some text here
	this has been replaced.
	some text there
	a field without a default value: foo
	end
	
	you can also define the field values with a tag attribute:
	
	some text here
	this should be replaced.
	some text there
	a field without a default value: bar
	end

=head3 Lists

You may define B<lists> to generate repetitive content inside a template.

B<Definition>: some.template

	<table>
		<tr><th><+$ head1 / $+></th><th><+$ head2 / $+></th></tr>
		<+@ items @+>
		<tr><td><+$ col1 / $+></td><td><+$ col2 / $+></td></tr>
		<+@ / @+>
	</table>

B<Usage>:

	<& template src="some.template" head1="Name" head2="Telephone number" &>
		<@ items @>
			<$ col1 $>foo<$ / $><$ col2 $>555-123456<$ / $>
			<$ col1 $>bar<$ / $><$ col2 $>555-654321<$ / $>
			<$ col1 $>baz<$ / $><$ col2 $>555-471123<$ / $>
		<@ / @>
	<& / &>

B<Result>: (whitespaces may vary...)

	<table>
		<tr><th>Name</th><th>Telephone number</th></tr>
		<tr><td>foo</td><td>555-123456</td></tr>
		<tr><td>bar</td><td>555-654321</td></tr>
		<tr><td>baz</td><td>555-471123</td></tr>
	</table>

Note that lists of lists are currently not supported.

B<Special values>:

Additionally to the explicitly specified values, you can access these additional
values in each row:

=over

=item * index - The sequential number of that row. Starts with 1.

=item * odd - 1 if it's an odd row. 0 otherwise. 

=item * even - 1 if it's an even row. 0 otherwise. 

=item * start - 1 if it's the first row. 0 otherwise.  

=item * end - 1 if it's the last row. 0 otherwise.  

=item * inner - 1 if it's not the first and not the last row. 0 otherwise.  

=back

Example:

	<table>
		<tr>
			<th>ID</th>
			<th>Name</th>
		</tr>
		<+@ items @+>
		<tr<& if condition="<+$ even / $+>" &> style="background-color: #8888FF;"<& / &>>
			<th><+$ index / $+></th>
			<th><+$ name / $+></th>
		</tr>
		<+@ / @+>
	</table>

=head2 Nested templates

Templates can be nested (as any Konstrukt tag):

	<& template src="layout.template" title="perl links" &>
		<$ content $>
			Some perl links:
			<& template src="linklist.template" &>
				<@ links @>
					<$ target      $>http://www.cpan.org/<$ / $>
					<$ description $>Comprehensive Perl Archive Network<$ / $>
					
					<$ target      $>http://dev.perl.org/perl6/<$ / $>
					<$ description $>Perl 6 Development Page<$ / $>
					
					<$ target      $>http://www.perlfoundation.org/<$ / $>
					<$ description $>The Perl Foundation<$ / $>
				<@ / @>
			<& / &>
		<$ / $>
	<& / &>

Each used template can in turn contain template tags (and other special Konstrukt tags):

B<linklist.template>:

	<ul>
	<+@ links @+>
		<li><a href="<+$ target / $+>"><+$ description $+>(No Description)<+$ / $+></a></li>
	<+@ / @+>
	<& template src="linkdisclaimer.template" / &>

The templates will be recursively processed.

=head2 Nested field definitions

You can also nest field definitions. So you can say that the default for one
field is the value of another field:

	<+$ some_field $+><+$ default_for_some_field / $+><+$ / $+>
	
So if no value for C<some_field> is defined, it will default to the value of
C<default_for_some_field>, which in turn could also have a default value and
so on.

=head2 Perl interface

You may also use a template from your perl code. It will be inserted at the
current position in the document where your perl code has been executed.
This will be done with the L</node> method:

	#get a plugin-object
	my $template = use_plugin 'template';
	
	#values that should be inserted to the template
	my $data = { 
		field1 => 'value1',
		field2 => 'value2'
		some_list => [
			{ field1 => 'a', field2 => 'b' },
			{ field1 => 'c', field2 => 'd' },
			...
		]
	};
	#insert the template
	$self->add_node($template->node('path/to/some.template', $data));
	
You may also pass tag nodes as the field's content, so nested templates are possible:

	$self->add_node($template->node('some.template', { some_field => $template->node('some_other.template') }));
	
If you want to pass several nodes as the field's content, you must put them
into a field node, which will act like a container:
	
	#create new field node as a container for some other nodes:
	my $container = Konstrukt::Parser::Node->new({ type => 'tag', handler_type => '$' });
	#add some nodes:
	$container->add_child($some_node);
	#...
	#create template node
	$self->add_node($template->node('some.template', { some_field => $container }));

Take a look at </node> (which has been used in the examples above), which
explains the passing of template values a bit more.

=head1 CONFIGURATION
	
For some uncommon situations you may control the behaviour of this plugin
with these settings:

	#this setting controls what to do when you have multiple <$ field $>-definitions:
	#0 = overwrite (default). only the last definition will be used
	#1 = join. join all values
	#2 = ignore. only the first definition will be used
	template/join_multiple_fields 0
	
	#this will allow the dynamic generation of <$ field $>'s like this:
	#<& template src="some.template" &>
	#	<$ static_field $>value<$ / $>
	#	<& perl &>print '<$ dynamic_field $>value<$ / $>'<& / &>
	#<& / &>
	#usally you shouldn't do this as it will slow down the execution.
	#if you want dynamic values, you should use the native perl-interface (L</node>) of this plugin.
	#FIXME: additionally this feature doesn't work correctly right now
	template/allow_dynamic_field_value_generation 0
	
=head1 SPEED

This plugin needs another modules to clone data structures. It will try to load
them in this order:

	1) Clone
	2) Clone::Fast
	3) Scalar::Util::Clone
	4) Storable
	5) Clone::More
	6) Clone::PP

This precedence list is approximateley built to try the module with the best
performance first. So you should check, if you've got any of the first modules
installed.

=cut

package Konstrukt::Plugin::template;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

use Konstrukt::Debug;

#bench: sorted by performance
use Devel::UseAnyFunc 'clone',
	'Clone'               => 'clone',
	'Clone::Fast'         => 'clone',
	'Scalar::Util::Clone' => 'clone',
	'Storable'            => 'dclone',
	'Clone::More'         => 'clone',
	'Clone::PP'           => 'clone',
;

BEGIN {
	require Data::Dump if Konstrukt::Debug::DEBUG;
}

=head1 METHODS

=head2 init

Initialization.

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default("template/join_multiple_fields", 0);
	$Konstrukt::Settings->default("template/allow_dynamic_field_value_generation", 0);
	
	return 1;
}
#= /init

=head2 execute_again

Yes, this plugin may return dynamic nodes. E.g. by loading a template containing
an perl node.

=cut
sub execute_again {
	return 1;
}
#= /execute_again

=head2 prepare

Prepare method

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare { 
	my ($self, $tag) = @_;
	return $self->process($tag, 0);
}
#= /prepare

=head2 execute

Execute method

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;
	return $self->process($tag, 1);
}
#= /execute

=head2 process

As prepare and execute are almost the same each run will just call this method.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=item * $execute - Should be a true value, when we're in the execute-run

=back

=cut
sub process {
	my ($self, $tag, $execute) = @_;
	
	my $filename = $tag->{tag}->{attributes}->{src};
	my $abs_filename = $Konstrukt::File->absolute_path($filename);
	
	#we can only finally parse for fields if there is no dynamic content which might generate fields:
	#<& template &><& perl &>print "<\$ field \$>value<\$ / \$>";<& / &><& / &>
	#there also exists a setting (template/allow_dynamic_field_value_generation) to disallow this case and gain a speed-up
	if (not $tag->{dynamic} or $execute or not $Konstrukt::Settings->get("template/allow_dynamic_field_value_generation")) {
		$Konstrukt::Debug->debug_message("Processing template $filename") if Konstrukt::Debug::DEBUG;
		
		#parse the content of the template tag for field/list values.
		#$tag->{template_values_node} is set if the template has been inserted by the node()-method.
		my $actions = { '$' => undef, '@' => undef };
		my $prepared = $Konstrukt::Parser->prepare($tag, $actions);
		my $values = $self->scan_for_values($prepared, $tag->{template_values_node});
		
		$Konstrukt::Debug->debug_message("===> TEMPLATE VALUES:\n" . Data::Dump::dump($values)) if Konstrukt::Debug::DEBUG;
		
		#data to put into the template has been collected.
		#load requested template file.
		#note: get_cache will also track the path of the read filename. so it must be pop()ed later.
		my $prepared_template = $Konstrukt::Cache->get_cache($abs_filename);
		if (not $prepared_template) {
			#no cached results available
			#read the input file and parse/prepare it.
			my $input = $Konstrukt::File->read_and_track($filename);
			if (defined($input)) {
				my $actions = { '&' => $Konstrukt::TagHandler::Plugin, '+$' => undef, '+@' => undef };
				$prepared_template = $Konstrukt::Parser->prepare(\$input, $actions);
				#scan for template fields
				$prepared_template->{template_fields} = $self->scan_for_templates($prepared_template);
				$Konstrukt::Debug->debug_message("===> TEMPLATE:\n" . Data::Dump::dump($prepared_template->{template_fields})) if Konstrukt::Debug::DEBUG;
				
				#cache results
				$Konstrukt::Cache->write_cache($abs_filename, $prepared_template);
			} else {
				$Konstrukt::Debug->error_message("Template \"$filename\" not readable!") if Konstrukt::Debug::ERROR;
				$Konstrukt::File->pop();
				$self->reset_nodes();
				#return error message
				$self->add_node("[ERROR: " . __PACKAGE__ . ": Template \"$filename\" not readable!]") if Konstrukt::Debug::ERROR;
				return $self->get_nodes();
			}
		}
		
		#add the field values and the path of the current template to every plugin node
		$self->set_hints($prepared_template, $values, $abs_filename);
		#we're done with this file
		$Konstrukt::File->pop();
		
		#put the values into the template fields
		$self->substitute($prepared_template->{template_fields}, $values, $tag, $prepared_template);
		
		#the substitution might have completed preliminary tags, so we can parse an prepare them now
		$self->check_preliminary_tags($prepared_template, { '&' => $Konstrukt::TagHandler::Plugin }) unless $execute;
		
		delete $prepared_template->{template_fields};
		return $prepared_template;
	} else {
		#don't do anything. process the template in the execute run.
		return undef;
	}
}
#= /process

=head2 check_preliminary_tags

Traverses the tree and looks for preliminary tags that now may have only plaintext
children (as a <+$ variable / $+> might have been replaced by a plaintext node)
and thus can be prepared.

B<Parameters>:

=over

=item * $tag - The root tag of the tree to process

=back

=cut
sub check_preliminary_tags {
	my ($self, $tag, $actions) = @_;
	
	$Konstrukt::Debug->debug_message("START") if Konstrukt::Debug::DEBUG;
	
	#recursively process the children first
	my $node = $tag->{first_child};
	my $dynamic = 0;
	while (defined $node) {
		if ($node->{type} eq 'tag') {
			#handle preliminary tags
			if (exists $node->{content}->{preliminary}) {
				$Konstrukt::Debug->debug_message("PREL REC") if Konstrukt::Debug::DEBUG;
				$self->check_preliminary_tags($node->{content}, $actions);
			}
			#check if this dynamic tag node is still in the tree or if it has been replaced
			if ($node eq $tag->{first_child} or defined $node->{prev}->{next} and $node->{prev}->{next} eq $node) {
				$Konstrukt::Debug->debug_message("DYN TAG $node->{handler_type} $node->{tag}->{type}") if Konstrukt::Debug::DEBUG;
				#dynamic node still in the tree
				$dynamic = 1;
			}
		}
		$node = $node->{next};
	}
	$Konstrukt::Debug->debug_message("CHECK: dynamic == $dynamic") if Konstrukt::Debug::DEBUG;
	#all children processed.
	#parse this node, if there are no dynamic children and it is a preliminary tag
	if (not $dynamic and defined $tag->{type} and $tag->{type} eq 'tagcontent' and exists $tag->{preliminary}) {
		$Konstrukt::Debug->debug_message("CHECK PRELIM NOW STATIC FOUND") if Konstrukt::Debug::DEBUG;
		$Konstrukt::Parser->parse_and_prepare_tag($tag->{parent}, $actions);
		#the tag has been prepared, if it was a singleclosing tag.
		#if we've had an opening preliminary tag, we have to prepare it now, as parse_and_prepare_tag didn't do this.
		unless ($tag->{parent}->{tag}->{singleclosing}) {
			$Konstrukt::Debug->debug_message("OPENING") if Konstrukt::Debug::DEBUG;
			$Konstrukt::Parser->prepare_tag($tag->{parent}, $actions);
			#my $result = $actions->{$tag->{handler_type}}->prepare($tag);
			##merge the result into the tree
			#$Konstrukt::Parser->merge_plugin_results($tag, $result);
		}
	}
	$Konstrukt::Debug->debug_message("END") if Konstrukt::Debug::DEBUG;
}
#= /check_preliminary_tags

=head2 scan_for_values

Traverses the tree and creates a handy data structure to easily access the values.

B<Parameters>:

=over

=item * $tag - The root tag of the tree to process

=item * $current - The current list values, which will be merged with the new ones

=back

=cut
sub scan_for_values {
	my ($self, $tag, $current) = @_;
	
	#collect the lists fields
	my $fields;
	my $lists;
	#"import" the existing values
	if (defined $current) {
		$fields = { map { $_ => [ $current->{fields}->{$_} ] } keys %{$current->{fields}} }; 
		$lists  = { map { $_ => [ $current->{lists}->{$_}  ] } keys %{$current->{lists}} }; 
	}
	$Konstrukt::Debug->debug_message("COLLECT") if Konstrukt::Debug::DEBUG;
	#process the children recursively
	my $node = $tag->{first_child};
	while (defined $node) {
		$Konstrukt::Debug->debug_message("CHILD") if Konstrukt::Debug::DEBUG;
		if ($node->{type} eq 'tag') {
			$Konstrukt::Debug->debug_message("TAG $node->{handler_type} $node->{tag}->{type}") if Konstrukt::Debug::DEBUG;
			if ($node->{handler_type} eq '$') {
				$Konstrukt::Debug->debug_message("FIELD") if Konstrukt::Debug::DEBUG;
				#push @{$result->{fields}->{$node->{tag}->{type}}}, $node;
				push @{$fields->{$node->{tag}->{type}}}, $node;
			} elsif ($node->{handler_type} eq '@') {
				$Konstrukt::Debug->debug_message("LIST") if Konstrukt::Debug::DEBUG;
				#$result->{lists}->{$node->{tag}->{type}} = $self->scan_for_values($node);
				push @{$lists->{$node->{tag}->{type}}}, $self->scan_for_values($node);
			}
		}
		$node = $node->{next};
	}
	
	#process result and return
	if (defined $tag->{handler_type} and $tag->{handler_type} eq '@') {
		#we collected fields for a list.
		#convert the hash of arrays into an array of hashes.
		my @list;
		my $values_exist;
		my $current_row = 0;
		do {
			#check, if there are values left
			$values_exist = 0;
			#check for fields
			foreach my $key (keys %{$fields}) {
				if (defined $fields->{$key}->[$current_row]) {
					$values_exist = 1;
					last;
				}
			}
			#check for lists
			unless ($values_exist) {
				foreach my $key (keys %{$lists}) {
					if (defined $lists->{$key}->[$current_row]) {
						$values_exist = 1;
						last;
					}
				}
			}
			#only proceed when we have values to insert
			my $row = {};
			if ($values_exist) {
				foreach my $key (keys %{$fields}) {
					$row->{fields}->{$key} = $fields->{$key}->[$current_row];
				}
				foreach my $key (keys %{$lists}) {
					$row->{lists}->{$key} = $lists->{$key}->[$current_row];
				}
				push @list, $row;
			}
			$current_row++;
		} until not $values_exist;
		return \@list;
	} else {
		#we collected fields not inside a list.
		my $join_multiple = $Konstrukt::Settings->get('template/join_multiple_fields');
		#join or overwrite multiple field definitions.
		foreach my $field (keys %{$fields}) {
			if ($join_multiple == 0) {
				#new definitions overwrite the old definition
				$fields->{$field} = $fields->{$field}->[-1];
			} elsif ($join_multiple == 1)	{
				#multiple definitions are joined
				foreach my $node (@{$fields->{$field}}[1 .. @{$fields->{$field}} - 1]) {
					$fields->{$field}->[0]->add_child($node);
					$node->replace_by_children();
				}
				$fields->{$field} = $fields->{$field}->[0];
			} elsif ($join_multiple == 2)	{
				#multiple definitions will be irgnored.
				$fields->{$field} = $fields->{$field}->[0];
			}
		}
		#join or overwrite multiple list definitions.
		foreach my $list (keys %{$lists}) {
			if ($join_multiple == 0) {
				#new definitions overwrite the old definition
				$lists->{$list} = $lists->{$list}->[-1];
			} elsif ($join_multiple == 1)	{
				#multiple definitions are joined
				foreach my $item (@{$lists->{$list}}[1 .. @{$lists->{$list}} - 1]) {
					push @{$lists->{$list}->[0]}, @{$item};
				}
				$lists->{$list} = $lists->{$list}->[0];
			} elsif ($join_multiple == 2)	{
				#multiple definitions will be irgnored.
				$lists->{$list} = $lists->{$list}->[0];
			}
		}
		#use the tag attributes as field values, if no appropriate field has been found
		foreach my $attr (keys %{$tag->{tag}->{attributes}}) {
			$fields->{$attr} = $tag->{tag}->{attributes}->{$attr}
				unless exists $fields->{$attr};
		}
		
		return { fields => $fields, lists => $lists };
	}
}
#= /scan_for_values

=head2 scan_for_templates

Traverses the tree (prepare-result of the block) and creates a handy data
structure to easily access the templates.

B<Parameters>:

=over

=item * $tag- The root tag of the result tree

=back

=cut
sub scan_for_templates {
	my ($self, $tag, $result) = @_;
	
	$result = {} if not defined $result;
	
	$Konstrukt::Debug->debug_message("TCOLLECT") if Konstrukt::Debug::DEBUG;
	#process the children recursively
	my $node = $tag->{first_child};
	while (defined($node)) {
		$Konstrukt::Debug->debug_message("TNODE") if Konstrukt::Debug::DEBUG;
		if ($node->{type} eq 'tag') {
			$Konstrukt::Debug->debug_message("TTAG $node->{handler_type} $node->{tag}->{type}") if Konstrukt::Debug::DEBUG;
			if ($node->{handler_type} eq '+$') {
				$Konstrukt::Debug->debug_message("TFIELD") if Konstrukt::Debug::DEBUG;
				push @{$result->{fields}->{$node->{tag}->{type}}}, $node;
			} elsif ($node->{handler_type} eq '+@') {
				$Konstrukt::Debug->debug_message("TLIST") if Konstrukt::Debug::DEBUG;
				my $list = $self->scan_for_templates($node);
				$list->{node} = $node;
				push @{$result->{lists}->{$node->{tag}->{type}}}, $list;
			} elsif (exists $node->{content}->{preliminary} and exists $node->{content}->{type} and $node->{content}->{type} = 'tagcontent') {
				#preliminary tag. recurse
				$Konstrukt::Debug->debug_message("TPRELTAGREC") if Konstrukt::Debug::DEBUG;
				$self->scan_for_templates($node->{content}, $result);
			}
			#recurse
			if (exists $node->{first_child} and defined $node->{first_child} and $node->{handler_type} ne '+@') {
				$Konstrukt::Debug->debug_message("TTAGREC") if Konstrukt::Debug::DEBUG;
				$self->scan_for_templates($node, $result);
			}
		} else {
			$Konstrukt::Debug->debug_message("NOTAG $node->{content}") if Konstrukt::Debug::DEBUG;
		}
		$node = $node->{next};
	}
	
	return $result;
}
#= /scan_for_templates

=head2 substitute

Does the template substitution.
It will do no parsing, it will just do the substitution on the passed trees.

B<Parameters>:

=over

=item * $template - The hashref which points to the template elements inside the
template file.

=item * $values - The hashref which points to the field elements.

=item * $tag - The template tag

=back

=cut
sub substitute {
	my ($self, $template, $values, $tag, $result) = @_; #TODO: remove $result

	$Konstrukt::Debug->debug_message("PRE SUBSTITUTION:\n".$result->tree_to_string()) if Konstrukt::Debug::DEBUG;
	
	#substitute fields
	$Konstrukt::Debug->debug_message("SUBSTITUTING FIELDS") if Konstrukt::Debug::DEBUG;
	foreach my $field (keys %{$template->{fields}}) {
		$Konstrukt::Debug->debug_message("S FIELD $field") if Konstrukt::Debug::DEBUG;
		foreach my $field_template (@{$template->{fields}->{$field}}) {
			if (exists $values->{fields}->{$field} and defined $values->{fields}->{$field}) {
				#replace by value
				$Konstrukt::Debug->debug_message("S FIELD SUBST $field") if Konstrukt::Debug::DEBUG;
				#save a copy of the value
				my $node = $values->{fields}->{$field};
				#eventually convert scalar to plaintext node
				my $copy;
				if (ref($node) eq 'Konstrukt::Parser::Node') {
					if ($node->{type} eq 'tag' and $node->{handler_type} ne '$') {
						#no field node. generate one
						$Konstrukt::Debug->debug_message("S FIELD SUBST $field: CONVERTING NON-FIELD NODE") if Konstrukt::Debug::DEBUG;
						my $new_node = Konstrukt::Parser::Node->new({ type => 'tag' });
						$new_node->add_child($node);
						$node = $new_node;
					}
					#cut the node out of its place and create a copy
					my @deleted = $node->remove_cross_references();
					$copy = clone($node);
					$copy->restore_cross_references(@deleted);
					$copy->{next} = $copy->{prev} = $copy->{parent} = undef;
				} else {
					#no node. assume plaintext
					$Konstrukt::Debug->debug_message("S FIELD SUBST $field: CONVERTING SCALAR TO NODE") if Konstrukt::Debug::DEBUG;
					my $new_node = Konstrukt::Parser::Node->new({ type => 'tag' });
					$new_node->add_child(Konstrukt::Parser::Node->new({ type => 'plaintext', content => $node }));
					$copy = $new_node;
				}
				#replace the template field by the value node
				$field_template->replace_by_node($copy);
				#replace the value node by its children
				$copy->replace_by_children();
			} else {
				#replace by default value
				$Konstrukt::Debug->debug_message("S FIELD SUBST $field: USING DEFAULT VALUE") if Konstrukt::Debug::DEBUG;
				$field_template->replace_by_children();
			}
		}
	}
	
	#substitute lists
	$Konstrukt::Debug->debug_message("SUBSTITUTING LISTS") if Konstrukt::Debug::DEBUG;
	foreach my $list (keys %{$template->{lists}}) {
		$Konstrukt::Debug->debug_message("S LIST $list") if Konstrukt::Debug::DEBUG;
		foreach my $list_template (@{$template->{lists}->{$list}}) {
			if (exists $values->{lists}->{$list}) {
				#remove the unneeded references as we'll make several copies of this node
				my @deleted = $list_template->{node}->remove_cross_references();
				#save the node after which we want to append the resulting rows
				my $last_node = $list_template->{node};
				#the last node needs a parent that will be copied to the appended nodes
				$last_node->{parent} = $deleted[0];
				#insert rows
				my $row_count = @{$values->{lists}->{$list}};
				my $current_row = 1;
				foreach my $value_row (@{$values->{lists}->{$list}}) {
					$Konstrukt::Debug->debug_message("S LIST_ROW SUBST $list") if Konstrukt::Debug::DEBUG;
					#create a copy of the list node (list row)
					my $row = clone($list_template);
					$row->{node}->restore_cross_references($deleted[0]);
					$row->{node}->{next} = $row->{node}->{prev} = $row->{node}->{parent} = undef;
					$Konstrukt::Debug->debug_message("ROW:\n".$row->{node}->tree_to_string()) if Konstrukt::Debug::DEBUG;
					#insert values
					foreach my $list_field (keys %{$row->{fields}}) {
						foreach my $list_field_template (@{$row->{fields}->{$list_field}}) {
							$Konstrukt::Debug->debug_message("S LIST_FIELD SUBST $list_field") if Konstrukt::Debug::DEBUG;
							my $list_field_value = $value_row->{fields}->{$list_field};
							if (defined $list_field_value) {
								if (ref($list_field_value) ne 'Konstrukt::Parser::Node') {
									#no node. assume plaintext
									$Konstrukt::Debug->debug_message("S LIST FIELD SUBST $list_field: CONVERTING SCALAR TO NODE") if Konstrukt::Debug::DEBUG;
									my $new_node = Konstrukt::Parser::Node->new({ type => 'tag' });
									$new_node->add_child(Konstrukt::Parser::Node->new({ type => 'plaintext', content => $list_field_value }));
									$list_field_value = $new_node;
								} elsif ($list_field_value->{type} eq 'tag' and $list_field_value->{handler_type} ne '$') {
									#no field node. generate one
									$Konstrukt::Debug->debug_message("S LIST FIELD SUBST $list_field: CONVERTING NON-FIELD NODE") if Konstrukt::Debug::DEBUG;
									my $new_node = Konstrukt::Parser::Node->new({ type => 'tag' });
									$new_node->add_child($list_field_value);
									$list_field_value = $new_node;
								}
								#use the specified value
								#create a copy of the data
								$list_field_value->remove_cross_references();
								delete $list_field_value->{next};
								my $copy = clone($list_field_value);
								$copy->restore_cross_references($row->{node});
								#$copy->{next} = $copy->{prev} = $copy->{parent} = undef;
								$copy->{next} = $copy->{prev} = undef;								
								#replace the template field by the children of the copy
								$list_field_template->replace_by_node($copy);
								$copy->replace_by_children();
							} elsif ($list_field eq 'index' or
									   $list_field eq 'odd'   or 
									   $list_field eq 'even'  or 
									   $list_field eq 'start' or 
									   $list_field eq 'end'   or 
									   $list_field eq 'inner') {
								my $value;
								$value = $current_row if $list_field eq 'index';
								$value = ($current_row % 2 ? 1 : 0) if $list_field eq 'odd';
								$value = ($current_row % 2 ? 0 : 1) if $list_field eq 'even';
								$value = ($current_row == 1 ? 1 : 0) if $list_field eq 'start';
								$value = ($current_row == $row_count ? 1 : 0) if $list_field eq 'end';
								$value = (($current_row != 1 and $current_row != $row_count) ? 1 : 0) if $list_field eq 'inner';
								#replace by node
								$list_field_template->replace_by_node(
									Konstrukt::Parser::Node->new({ type => 'plaintext', content => $value })
								);
							} else {
								#use default value
								$Konstrukt::Debug->debug_message("S LIST FIELD SUBST $list_field: USING DEFAULT VALUE") if Konstrukt::Debug::DEBUG;
								$list_field_template->replace_by_children();
							}
						}
					}
					$Konstrukt::Debug->debug_message("ROW NEW:\n".$row->{node}->tree_to_string()) if Konstrukt::Debug::DEBUG;
					#append the new row and replace it by its children
					$last_node->append($row->{node});
					$last_node = $row->{node}->{last_child};
					$row->{node}->replace_by_children();
					
					$current_row++;
				}
				#restore the deleted cross references
				$list_template->{node}->restore_cross_references(@deleted);
			} else {
				#no list defined for that list template
			}
			#delete list
			$list_template->{node}->delete();
		}
	}
	
	$Konstrukt::Debug->debug_message("POST SUBSTITUTION:\n".$result->tree_to_string()) if Konstrukt::Debug::DEBUG;
}
#= /substitute

=head2 set_hints

Traverses the tree and adds a reference to the field values to each plugin tag node
inside the template (if not already set). Also adds a hint with the path of the
current template, which will be used by the parser to track the correct current
directory.

The values will then be accessible through C<$tag-E<gt>{template_values}> and
C<$tag-E<gt>{template_path}>.

B<Parameters>:

=over

=item * $tag - The root tag of the tree to process

=item * $values - Reference to the template values

=item * $path - The absolute path of the template file

=back

=cut
sub set_hints {
	my ($self, $tag, $values, $path) = @_;
	
	#process the children recursively
	my $node = $tag->{first_child};
	while (defined $node) {
		$self->set_hints($node, $values, $path) if $node->{type} eq 'tag' and $node->{handler_type} eq '&';
		$node = $node->{next};
	}
	$tag->{template_values} = $values unless exists $tag->{template_values};
	$tag->{template_path}   = $path   unless exists $tag->{template_path};
}
#= /set_hints

=head2 node

Return a tag node that will load a template. See L</SYNOPSIS> for an example.

B<Parameters>:

=over

=item * $filename - The filename of the template to load

=item * $data - Hash reference with the data to put into the template. Will look
like this:
	
	#generic form (see SYNOPSIS):
	my $data = {
		fields => {
			field1 => 'value1',
			field2 => 'value2'
		},
		lists => {
			list1 => [
				{ fields => { field1 => 'a', field2 => 'b' } },
				{ fields => { field1 => 'c', field2 => 'd' } },
				...
			]
		}
	};
	
	#short form:
	#all hash keys that do not point to an hash- or array-reference will be interpreted as a field-value.
	#all hash keys that point to array references will be interpreted as lists.
	#so the short form of the example above would look like this:
	my $data = {
		field1 => 'value1',
		field2 => 'value2',
		list1 => [
			{ field1 => 'a', field2 => 'b' },
			{ field1 => 'c', field2 => 'd' },
			...
		]
	}
	#this will lead to some ambiguities in the short form:
	# - you cannot define a list and a field with the same name.
	# - you cannot define fields or lists with the name 'fields' or 'lists'
	#   as they will be interpreted as the container for those.

=back

=cut
sub node {
	my ($self, $filename, $data) = @_;
	
	$self->normalize_input_data($data);
	
	#compose tag
	my $tag = {
		type => 'tag',
		handler_type => '&',
		tag => {
			attributes => {
				src => $filename
			},
			type => 'template'
		},
		template_values_node => $data,
	};
	
	#return tag node
	return Konstrukt::Parser::Node->new($tag);
}
#= /node

=head2 normalize_input_data

Will convert the input data, that may be passed in a short form, into the
generic form.

Will only be used internally by L</node>.

B<Parameters>:

=over

=item * $data - Hash reference with the data to put into the template

=back

=cut
sub normalize_input_data {
	my ($self, $data) = @_;
	
	#look for every key in the data-hash that is not named "fields" or "lists" and save them as fields
	foreach my $key (keys %{$data}) {
		if ($key ne 'fields' and $key ne 'lists') {
			if (ref $data->{$key} ne 'ARRAY' and ref $data->{$key} ne 'HASH' and not exists $data->{fields}->{$key}) {
				#convert to field value
				$data->{fields}->{$key} = $data->{$key};
				delete $data->{$key};
			} elsif (ref $data->{$key} eq 'ARRAY' and not exists $data->{lists}->{$key}) {
				#convert to list
				$data->{lists}->{$key} = $data->{$key};
				delete $data->{$key};
			}
		}
	}
	
	#also look for lists and recursively normalize
	return unless exists $data->{lists};
	foreach my $list (keys %{$data->{lists}}) {
		foreach my $row (@{$data->{lists}->{$list}}) {
			$self->normalize_input_data($row);
		}
	}
}
#= /normalize_input_data

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt>

=cut
