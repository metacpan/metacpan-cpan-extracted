package Math::Lapack::Expr;
use warnings;
use strict;
use strictures 2;
use Scalar::Util 'blessed';
use Data::Dumper;
use parent 'Exporter';
our $_debug_counts;

our @EXPORT = qw.$_debug_counts transpose inverse sum abs T.;

use overload
  '0+' => \&eval_ast,
  '""' => \&to_string,
  '**' => \&pow_ast,
  '-'  => \&sub_ast,
  '+'  => \&add_ast,
  '*'  => \&mul_ast,
  '/'  => \&div_ast,
  'x'  => \&dot_ast,
  log  => \&log_ast,
	exp  => \&exp_ast;

our $AUTOLOAD;





sub to_string {
  &eval_ast
}

sub add_ast {
	my ($a, $b) = @_;
	return bless { type => 'add', args => [$a,$b] } => __PACKAGE__;
}

sub sub_ast {
	my ($a, $b, $s) = @_;
	return bless { type => 'sub', args =>  [$a,$b,$s] } => __PACKAGE__;
}

sub mul_ast {
	my ($a, $b) = @_;
	return bless { type => 'mul', args => [$a, $b] } => __PACKAGE__;
}

sub div_ast {
	my ($a, $b, $s) = @_;
	return bless { type => 'div', args => [$a,$b,$s] } => __PACKAGE__;
}

sub dot_ast {
	my ($a, $b) = @_;
	return bless { type => 'dot', args => [$a, $b] } => __PACKAGE__;
}

sub T { &transpose }
sub transpose {
	my $a = shift;
	return bless { type => 'transpose', args => [$a] } => __PACKAGE__;
}

sub inverse {
	my $a = shift;
	return bless { type => 'inverse', args => [$a] } => __PACKAGE__;
}

sub pow_ast {
	my ($a, $b) = @_;
	return bless { type => 'pow', args => [$a, $b] } => __PACKAGE__;
}

sub sum {
	my ($a, $b) = @_;
	return bless { type => 'sum', args => [$a, $b] } => __PACKAGE__;
}

sub log_ast {
	my ($a) = @_;
	return bless { type => 'log', args => [$a] } => __PACKAGE__;
}

sub exp_ast {
	my ($a) = @_;
	return bless { type => 'exp', args => [$a] } => __PACKAGE__;
}

## Special cases (for now)
our %evaluators = (
                   dot => sub {
                     my $tree = shift;
                     return Math::Lapack::Matrix::eval_dot($tree->{args}[0],
                                                           $tree->{args}[1],
                                                           $tree->{transpose_left},
                                                           $tree->{transpose_right});
                   }
                  );

sub eval_ast {
  my $tree = shift;
  $_debug_counts->{eval_ast}++;

  if(blessed($tree) && $tree->isa(__PACKAGE__)) { # Is this an Expr?
    return $tree->{evaluated} if exists($tree->{evaluated}); # return it if we did evaluate it already

    if ($tree->{type} ne "matrix") {
      my $evaluated = exists($tree->{simplified}) ? $tree->{simplified} : _optimize_ast($tree);

      if (exists($tree->{args})) {
        $tree->{args} = [ map {eval_ast($_)} @{$tree->{args}} ];
      }


      my $ans;
      if (exists($evaluators{$tree->{type}})) {
        $ans = $evaluators{$tree->{type}}->($tree);
      }
      else {
        no strict 'refs';
        my $package = exists($tree->{package}) ? $tree->{package} : "Math::Lapack::Matrix";
        # print STDERR "Calling $package with eval_$tree->{type}\n\n";  ## DEBUG
        $ans = "${package}::eval_$tree->{type}"->(@{$tree->{args}});
      }
      $tree->{evaluated} = $ans;
      return $ans;
    } 
  }
  return $tree;
}


sub _is_transpose {
  my $child = shift;
  return blessed($child) && $child->isa(__PACKAGE__) && $child->{type} eq "transpose";
}

sub _optimize_ast {

  my ($tree) = @_;
  $_debug_counts->{optimize}++;

  if (blessed($tree) && $tree->isa(__PACKAGE__)) {

    if (exists($tree->{evaluated})) {
      $tree = $tree->{evaluated};
    } elsif (exists($tree->{simplified})) {
      $tree = $tree->{simplified};

    } elsif (exists($tree->{args})) {  ## Autovivification is a thing

      my @child = map { _optimize_ast($_) } @{$tree->{args}};

      ## check if we are a dot
      if ($tree->{type} eq "dot") {

        ## Dot has just two children

        ## is the left side transposed?
        if (_is_transpose($child[0])) {
          ## save flag
          $tree->{transpose_left} = 1;
          ## take the transpose child, and make it ours
          $tree->{args}[0] = $child[0]{args}[0];
        }

        if (_is_transpose($child[1])) {
          ## save flag
          $tree->{transpose_right} = 1;
          ## take the transpose child, and make it ours
          $tree->{args}[1] = $child[1]{args}[0];
        }
      }
      else {
        $tree->{args} = [@child];
      }

      # Cache simplified tree
   #  $tree->{simplified} = $tree;
    }
    elsif (blessed($tree) && ref($tree) !~ /Matrix/) { die ref($tree) }
  }
  return $tree
}

sub DESTROY {
  my $self = shift;
  ## nothing for now
}

AUTOLOAD {
  my $method = $AUTOLOAD;

  our $Depth //= 0; local $Depth = $Depth + 1;

  $method =~ s/.*:://;  # transform Math::Lapack::Expr::get_element into get_element (for example)
  my $obj = shift;      # get object where unknown method was called

  if (blessed($obj)) {
    my $evaluated_tree = $obj->eval_ast;

    if ($Depth > 100) {
      my $ref = ref($obj);
      my $ref_tree = ref($evaluated_tree);
      die <<"EOD"
*** AUTOLOAD[$method] in deep recursion.
*** OBJ is a $ref.
*** TREE is a $ref_tree.
EOD
    }

    if (blessed($evaluated_tree)) {
      return $evaluated_tree->$method(@_); # evaluate the object, and invoke method on resulting value
    } else {
      no strict 'refs';
      return &$method($evaluated_tree);
    }
  } else {
    return $obj;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::Lapack::Expr

=head1 VERSION

version 0.001

=for Pod::Coverage T add_ast div_ast dot_ast eval_ast exp_ast log_ast mul_ast pow_ast sub_ast sum to_string transpose inverse

=head1 AUTHOR

Rui Meira

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2019 by Rui Meira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
