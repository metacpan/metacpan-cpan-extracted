package GraphQL::Houtou::Validation;

use 5.014;
use strict;
use warnings;

use Exporter 'import';
use GraphQL::Houtou ();

our @EXPORT_OK = qw(check_query_cost validate);

sub validate {
  my ($schema, $source_or_ast, @rest) = @_;
  GraphQL::Houtou::_bootstrap_xs();
  # Loading the parser module installs the boolean/string factories used by
  # the validation parser. The source itself is still parsed exactly once,
  # inside validate_xs, so parser-time duplicate diagnostics are preserved.
  require GraphQL::Houtou::XS::Parser if !ref($source_or_ast);
  return GraphQL::Houtou::XS::Validation::validate_xs(
    $schema, $source_or_ast, @rest,
  );
}

sub check_query_cost {
  my ($schema, $source_or_ast, %options) = @_;
  GraphQL::Houtou::_bootstrap_xs();
  require GraphQL::Houtou::XS::Parser if !ref($source_or_ast);
  return GraphQL::Houtou::XS::Validation::check_cost_xs(
    $schema, $source_or_ast, \%options,
  );
}

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Validation - GraphQL document validation facade

=head1 SYNOPSIS

    use GraphQL::Houtou::Validation qw(check_query_cost validate);

    my $errors = validate($schema, $source_or_ast);

    my $cost_errors = check_query_cost(
        $schema, $source_or_ast,
        max_cost => 10_000,
        default_list_size => 10,
        operation_name => 'GetUsers',
    );

=head1 DESCRIPTION

This module is the public entry point for GraphQL validation. Validation is
implemented by the shared XS bundle; there is no Pure Perl validation pass.

C<check_query_cost> applies the schema's field costs and list-size multipliers
and returns validation-style error hashrefs when C<max_cost> is exceeded.

=cut
