
=head1 NAME

Math::Symbolic::Custom::DumpToFastEval - Compile Math::Symbolic trees fast RPN form

=head1 SYNOPSIS

  use Math::Symbolic::Custom::DumpToFastEval;

=head1 DESCRIPTION

FIXME documentation!

=head2 EXPORT

None by default, but you may choose to import the compile(), compile_to_sub(),
and compile_to_code() subroutines to your namespace using the standart
Exporter semantics including the ':all' tag.

=head1 SUBROUTINES

=cut

package Math::Symbolic::Custom::DumpToFastEval;
use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use Math::SymbolicX::FastEvaluator;
use Math::Symbolic::Custom::Base;
BEGIN {*import = \&Math::Symbolic::Custom::Base::aggregate_import}

our $Aggregate_Export = [qw/to_fasteval/];

use Math::Symbolic::ExportConstants qw/:all/;

sub to_fasteval {
    my $tree = shift;
    $tree = shift if not ref $tree and $tree eq __PACKAGE__;

    my $order = shift || [];
    my %order;
    if (ref($order) eq 'HASH') {
        %order = %$order;
    }
    elsif (ref($order) eq 'ARRAY') {
        my $count = 0;
        %order = map { ( $_, $count++ ) } @$order;
    }

    no warnings 'recursion';

    my $vars = [ $tree->explicit_signature() ];

    my %vars;
    my @not_placed;
    foreach (@$vars) {
        my $pos = $order{$_};
        if ( defined $pos ) {
            $vars{$_} = $pos;
        }
        else {
            push @not_placed, $_;
        }
    }

    my $count = 0;
    foreach ( sort @not_placed ) {
        $vars{$_} = @$vars - @not_placed + $count++;
    }

    # The user is to do that himself. Left in to show that it would be
    # a sensible (if slow) thing to do.
    # $tree = $tree->simplify();
    # $tree = $tree->apply_derivatives();
    # $tree = $tree->simplify();

    my @trees;

    my $expr = Math::SymbolicX::FastEvaluator::Expression->new();
    my $success = _rec_ms_to_expr( $expr, $tree, \%vars );
    return() if not $success;
    
    $expr->SetNVars(scalar keys %vars);

    return($expr);
}


{
  no warnings 'recursion';
  sub _rec_ms_to_expr {
    my $expr = shift;
    my $tree  = shift;
    my $vars  = shift;

    my $op = Math::SymbolicX::FastEvaluator::Op->new();

    eval {
      $tree->descend(
        in_place => 1,
        after => sub {
          my $t = shift;
          my $ttype = $t->term_type;
          if ($ttype == T_VARIABLE) {
            $op->SetVariable();
            $op->SetValue($vars->{$t->name});
            #print $t->name, " ";
          }
          elsif ($ttype == T_CONSTANT) {
            $op->SetNumber();
            $op->SetValue($t->value);
            #print $t->value, " ";
          }
          else {
            my $type = $t->type;
            if ($type == U_P_DERIVATIVE || $type == U_T_DERIVATIVE) {
              die "Can't convert dertivatives to RPN for the FastEvaluator!";
            }
            $op->SetOpType($type);
            #print $Math::Symbolic::Operator::Op_Types[$type]{prefix_string}, " ";
          }
          $expr->AddOp($op);
        },
      );
    };
    if ($@) {
      warn "Caught exception while converting Math::Symbolic tree to RPN: $@";
      return();
    }
    return 1;
  }
}

1;
__END__

=head1 AUTHOR

Please send feedback, bug reports, and support requests to the Math::Symbolic
support mailing list:
math-symbolic-support at lists dot sourceforge dot net. Please
consider letting us know how you use Math::Symbolic. Thank you.

If you're interested in helping with the development or extending the
module's functionality, please contact the developers' mailing list:
math-symbolic-develop at lists dot sourceforge dot net.

Steffen Müller, E<lt>smueller@cpan.orgE<gt>

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN. The module development takes place on
Sourceforge at http://sourceforge.net/projects/math-symbolic/

L<Math::Symbolic>, L<Math::SymbolicX::FastEvaluator>,
L<Math::SymbolicX::FastEvaluator::Expression>


=cut

