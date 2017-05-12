package GOBO;

our $VERSION='0.03';

# no code here, only POD docs.
# best read on CPAN
# http://search.cpan.org/~cmungall/GOBO/GOBO.pm


=head1 NAME

GOBO

=head1 SYNOPSIS

  my $parser = new GOBO::Parsers::OBOParser(file => "t/data/cell.obo");
  $parser->parse;
  my $g =  $parser->graph;

  foreach my $t (@{$g->terms}) {
    printf '%s "%s"\n", $t->id, $t->name;
  }

=head1 DESCRIPTION

=head2 OBJECT MODEL

=head3 Basic overview

 * L<GOBO::Node>
 ** L<GOBO::ClassNode>
 *** L<GOBO::TermNode>
 *** L<GOBO::ClassExpression>
 ** L<GOBO::RelationNode>
 ** L<GOBO::InstanceNode>
 * L<GOBO::Statement>
 ** L<GOBO::LinkStatement>

=head2 INPUT/OUTPUT

=head3 Parsers

 * L<GOBO::Parsers::OBOParser>
 * L<GOBO::Writers::OBOWriter>

=head1 FAQ

 * L<GOBO::Doc::FAQ>


=head1 SEE ALSO

 * L<GOBO::Doc::FAQ>
 * L<GOBO::Graph>


=cut




