package GOBO::Doc::FAQ;

# no code here, only POD docs.
# best read on CPAN

=head1 NAME

GOBO::Doc::FAQ - Frequently Asked Questions

=head1 BASIC

=head2 What is this?

A perl library for dealing with ontologies and annotations, geared towards the Gene Ontology (GO) and OBO ontologies.

L<http://geneontology.org>

It is a rewrite of go-perl using the perl MOOSE framework

It is currently in the early stages of development

=head2 What is MOOSE?

L<MOOSE>

=head1 RELATIONSHIP TO OTHER PROJECTS

=head2 What is the relationship between this and go-perl?

go-perl (L<::GO::Parser>) and go-db-perl (L<GO::AppHandle>) are the
predecessors of GOBO. They are nearly 10 years old and due for an overhaul.

GOBO will gradually replace these projects

=head2 What is the relationship between this and bioperl?

There is currently an experimental overhaul of bioperl called
Bio::Moose. GOBO is intended to slot in to this project, as a
replacement for L<Bio::Ontology>

=head2 What is the relationship between this and onto-perl?

=head2 What is the relationship between this and RDF libraries?



=head2 What is the relationship between this and OWL?

=head1 OBJECT MODEL

=head2 What is an instance?

=head2 What is an ontology graph?

=head1 DATABASE CONNECTIVITY

=head2 Is there an object-relational mapping layer?

The plan is to use L<DBIx::Class> to connect to a variety of databases.

=head2 Can I use this in combination with the GO database?

L<GOBO::DBIC::GODBModel>

=head2 Can I use this in combination with the Chado database?

This will use the Chado DBIx layer when it becomes standardized

=head1 ADVANCED

=head2 What does the InferenceEngine do?

The inference engine will take as input a graph (typically consisting
of asserted statements) and compute inferred statements.

=head2 What is an asserted statement?

A statement that has been explicitly asserted by an ontology editor

=head2 What is an inferred statement?

A statement that follows logically from other statement (based on
logical axioms in the ontology), and that has been computed by a
reasoner/inference engine

=head2 What is a ClassExpression?

See L<GOBO::ClassExpression>


 * L<GOBO::Node>
 ** L<GOBO::ClassNode>
 *** L<GOBO::TermNode>
 *** L<GOBO::ClassExpression>
 **** L<GOBO::ClassExpression::Intersection>
 **** L<GOBO::ClassExpression::Union>
 **** L<GOBO::ClassExpression::RelationalExpression>
 ** L<GOBO::RelationNode>
 ** L<GOBO::InstanceNode>

=head2 What is a logical definition?

=head2 What is the connection between logical definitions and intersection links?

If we have an ontology that contains the logical definition:

	blue_car = car AND <has_color blue>

the LHS is a L<GOBO::Term>, the RHS is a L<GOBO::ClassExpression>
(specifically, a L<GOBO::ClassExpression::Intersection>)

This would be represented in OBO as

  id: blue_car
  intersection_of: car
  intersection_of: has_color blue

The logical definition can be extracted as follows:

  $class_expr = $my_class->logical_definition;

(See L<GOBO::Definable>)

This is equivalent to 2 intersection statements

	blue_car is_a car
	blue_car has_color blue

Sometimes you want to treat your ontology as a graph rather than as a
collection of logical axioms relation named entities and
expressions. It's much simpler, and makes sense, e.g. for
visualization of so-xp.

GOBO allows both.

* Each intersection_of tag is treated as a GOBO::LinkStatement, with the specified relationship (is_a for genus), with the is_intersection boolean set

* There are methods in the graph object to collapse these links into ClassExpressions (and to go back) using the semantics:

	$term->logical_definition($ce)
		iff
	$ce = Intersection([@args])
		where
	@args = grep { $_->is_intersection } @{$graph->get_outgoing_links($term)}

(that's an approximation, we need to use the class itself for is_a and a RelationalExpression for the differentia)

See

L<GOBO:::Graph#convert_intersection_links_to_logical_definitions>


=head1 APPLICATIONS

=head2 What is this used for?

Current applications in production:

=over

=item Inference of GO biological process from GO molecular function using part_of

See L<GOBO::bin::go-gaf-inference>

=item Inference of GO biological process from GO molecular function using part_of

See L<GOBO::bin::go-gaf-inference>

=item Slimming

See L<GOBO::bin::go-slimdown>

=back

Planned future applications



=head1 SEE ALSO

 * L<GOBO>
 * L<GOBO::Graph>


=cut




