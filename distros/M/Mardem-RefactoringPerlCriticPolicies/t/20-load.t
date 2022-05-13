#!perl

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Test::More;

plan 'tests' => 8;

BEGIN {
    my $error_txt = "Bail out!\n";

    use_ok( 'Mardem::RefactoringPerlCriticPolicies' )
        || print $error_txt;

    use_ok( 'Mardem::RefactoringPerlCriticPolicies::Util' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitConditionComplexity' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitBlockComplexity' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitLargeSub' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitLargeBlock' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitManyConditionsInSub' )
        || print $error_txt;

    use_ok( 'Perl::Critic::Policy::Mardem::ProhibitReturnBooleanAsInt' )
        || print $error_txt;
}

diag(
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitConditionComplexity $Mardem::RefactoringPerlCriticPolicies::VERSION, Perl $], $^X"
);

diag(
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitConditionComplexity $Mardem::RefactoringPerlCriticPolicies::Util::VERSION, Perl $], $^X"
);

diag(
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitConditionComplexity $Perl::Critic::Policy::Mardem::ProhibitConditionComplexity::VERSION, Perl $], $^X"
);

diag(
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitBlockComplexity $Perl::Critic::Policy::Mardem::ProhibitBlockComplexity::VERSION, Perl $], $^X"
);

diag(
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitBlockComplexity $Perl::Critic::Policy::Mardem::ProhibitLargeSub::VERSION, Perl $], $^X"
);

diag(
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitBlockComplexity $Perl::Critic::Policy::Mardem::ProhibitLargeBlock::VERSION, Perl $], $^X"
);

diag(
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitBlockComplexity $Perl::Critic::Policy::Mardem::ProhibitManyConditionsInSub::VERSION, Perl $], $^X"
);

diag(
    "\nTesting Perl::Critic::Policy::Mardem::ProhibitBlockComplexity $Perl::Critic::Policy::Mardem::ProhibitReturnBooleanAsInt::VERSION, Perl $], $^X"
);

done_testing();

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

10-load.t

=head1 DESCRIPTION

Test-Script

=head1 AFFILIATION

This policy is part of L<Mardem::RefactoringPerlCriticPolicies>.

=head1 AUTHOR

Markus Demml, mardem@cpan.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2022, Markus Demml

This library is free software; you can redistribute it and/or modify it 
under the same terms as the Perl 5 programming language system itself. 
The full text of this license can be found in the LICENSE file included
with this module.

=cut
