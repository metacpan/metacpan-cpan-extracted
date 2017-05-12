#!perl
use strict;
use warnings;

use Test::More;

my @packages = qw(
  Math::Symbolic
  Math::Symbolic::AuxFunctions
  Math::Symbolic::Base
  Math::Symbolic::Compiler
  Math::Symbolic::Constant
  Math::Symbolic::Custom
  Math::Symbolic::Custom::Base
  Math::Symbolic::Custom::DefaultDumpers
  Math::Symbolic::Custom::DefaultMods
  Math::Symbolic::Custom::DefaultTests
  Math::Symbolic::Derivative
  Math::Symbolic::ExportConstants
  Math::Symbolic::MiscAlgebra
  Math::Symbolic::MiscCalculus
  Math::Symbolic::Operator
  Math::Symbolic::Parser
  Math::Symbolic::Variable
  Math::Symbolic::VectorCalculus
);

eval { require Test::Pod::Coverage; };
if ($@) {
    plan skip_all => 'Test::Pod::Coverage not installed';
    exit;
}
else {
    import Test::Pod::Coverage;
    plan tests => (4+scalar(@packages));
}

use_ok('Math::Symbolic');
use_ok('Math::Symbolic::MiscAlgebra');
use_ok('Math::Symbolic::VectorCalculus');
use_ok('Math::Symbolic::MiscCalculus');


my $also_private = {also_private=> [qr/^_/, qr/^\(/, qr/^AUTOLOAD$/, qr/^DESTROY$/, '^can$']};
foreach my $namespace (@packages) {
    pod_coverage_ok(
        $namespace, $also_private
    );
}

