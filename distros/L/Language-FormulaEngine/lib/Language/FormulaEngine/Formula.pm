package Language::FormulaEngine::Formula;
use Moo;
use Carp;
use overload '""' => sub { shift->to_string };


has engine     => ( is => 'rw', required => 1 );
has orig_text  => ( is => 'rw' );
has parse_tree => ( is => 'rw', required => 1 );
has functions  => ( is => 'lazy' );
has symbols    => ( is => 'lazy' );

sub _count_refs {
	my $node= shift;
	my (%fn_set, %var_set, @todo);
	while (defined $node) {
		$var_set{$node->symbol_name}++ if $node->can('symbol_name');
		if ($node->can('function_name')) {
			$fn_set{$node->function_name}++;
			push @todo, @{ $node->parameters };
		}
		$node= pop @todo;
	}
	(\%fn_set, \%var_set);
}

sub _build_symbols {
	my $self= shift;
	@{$self}{'functions','symbols'}= _count_refs( $self->parse_tree );
	$self->{symbols};
}

sub _build_functions {
	my $self= shift;
	@{$self}{'functions','symbols'}= _count_refs( $self->parse_tree );
	$self->{functions};
}


sub evaluate {
	my ($self, $ns_or_vars)= @_;
	my $ns= !$ns_or_vars? $self->engine->namespace
		: !ref $ns_or_vars && @_ > 2? $self->engine->namespace->clone_and_merge(variables => { @_[1..$#_] })
		: ref $ns_or_vars eq 'HASH'? $self->engine->namespace->clone_and_merge(variables => $ns_or_vars)
		: ref($ns_or_vars)->can('get_function')? $ns_or_vars
		: croak "Can't evaluate for $ns_or_vars";
	return $self->parse_tree->evaluate($ns);
}


sub simplify {
	my ($self, $ns_or_vars)= @_;
	my $ns= !$ns_or_vars? $self->engine->namespace
		: !ref $ns_or_vars && @_ > 2? $self->engine->namespace->clone_and_merge(variables => { @_[1..$#_] })
		: ref $ns_or_vars eq 'HASH'? $self->engine->namespace->clone_and_merge(variables => $ns_or_vars)
		: ref($ns_or_vars)->can('get_function')? $ns_or_vars
		: croak "Can't evaluate for $ns_or_vars";
	my $parse_tree= $self->parse_tree->simplify($ns);
	return $self if $parse_tree == $self->parse_tree;
	return Language::FormulaEngine::Formula->new(
		engine => $self->engine,
		parse_tree => $parse_tree,
	);
}


sub compile {
	my ($self, $subname)= @_;
	$self->engine->compiler->compile($self->parse_tree, $subname)
		or croak $self->engine->compiler->error;
}


sub deparse {
	my $self= shift;
	$self->parse_tree->deparse($self->engine->parser);
}


sub to_string {
	my $orig= $_[0]->orig_text;
	return defined $orig? $orig : $_[0]->deparse;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::FormulaEngine::Formula

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  $formula= $engine->parse($text_expression);
  
  $value= $formula->evaluate(x => 1);
  
  $formula2= $formula->simplify(y => 2);
  
  $coderef= $formula2->compile;

=head1 DESCRIPTION

This is a convenient way to carry around the details of a parsed formula and later
evaluate it, simplify it, or compile it.  It's simply a wrapper around the engine
that created it + the parse tree.

=head1 ATTRIBUTES

=head2 engine

Reference to a L<Language::FormulaEngine> instance.

=head2 orig_text

Original string of text that was parsed into this formula.  This may be
C<undef> if the formula was generated.  In that case, see L</deparse>
or L</to_string>.

=head2 parse_tree

Reference to the output of L<Language::FormulaEngine::Parser/parse>

=head2 functions

A set of { $name => 1 } for each named function used in this formula.

=head2 symbols

A set of { $name => 1 } for each named variable used in this formula.

=head1 CONSTRUCTOR

Standard Moo constructor accepts any of the attributes above.

=head1 METHODS

=head2 evaluate

  $raw_value= $formula->evaluate;
  $raw_value= $formula->evaluate(\%alt_vars);
  $raw_value= $formula->evaluate($alt_namespace);

Evaluate the formula, optionally specifying variables or a different namespace in which
to evaluate it.

=head2 simplify

  $formula2= $formula1->simplify;
  $formula2= $formula1->simplify(\%alt_vars);
  $formula2= $formula1->simplify($alt_namespace);

Simplify the formula by substituting known variable values and evaluating pure functions.
You can optionally specify variables or a different namespace which should be used.

=head2 compile

  my $sub= $formula->compile;
  my $sub= $formula->compile($subname);

Return an optimized perl coderef for the formula.  The signature of the coderef
depends on the settings of the C<< $formula->engine->compiler >>.  Throws an
exception if the compile fails.

=head2 deparse

Re-stringify the formula, using C<< $self->engine->parser >>.

=head2 to_string

Return either C<orig_text>, or C<deparse>.  This is used when stringifying the object.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
