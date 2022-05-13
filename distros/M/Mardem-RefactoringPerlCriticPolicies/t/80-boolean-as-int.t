#!perl

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;
use Perl::Critic;

Readonly::Scalar my $POLICY_NAME => 'Perl::Critic::Policy::Mardem::ProhibitReturnBooleanAsInt';

use Test::More;

plan 'tests' => 22;

#####

sub _get_perl_critic_object
{
    my $pc = Perl::Critic->new(
        '-profile'  => 'NONE',
        '-only'     => 1,
        '-severity' => 1,
        '-force'    => 0
    );

    $pc->add_policy( '-policy' => $POLICY_NAME );

    return $pc;
}

#####

sub _check_perl_critic
{
    my ( $code_ref ) = @_;

    my $pc = _get_perl_critic_object();

    return $pc->critique( $code_ref );
}

#####

{
    my $code = <<'END_OF_STRING';
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !@violations, 'empty code nothing found';
}

#####

{
    my $code = <<'END_OF_STRING';
        returns;
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !@violations, 'returns not found';
}

#####

{
    my $code = <<'END_OF_STRING';
        my %hash = ( 'return' => 1 );
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !@violations, 'return as hash-string-key not found';
}

#####

{
    my $code = <<'END_OF_STRING';
        my %hash = ( return => 1 );
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !@violations, 'return as hash-Bareword-key not found';
}

#####

{
    my $code = <<'END_OF_STRING';
        return;
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !@violations, 'return; alone should not violate';
}

#####

{
    my $code = <<'END_OF_STRING';
        return 0;
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !!@violations, 'return 0; violates correctly';
}

#####

{
    my $code = <<'END_OF_STRING';
        return 1;
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !!@violations, 'return 1; violates correctly';
}

#####

{
    my $code = <<'END_OF_STRING';
        return 3;
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !@violations, 'return 3; should not violate';
}

#####

{
    my $code = <<'END_OF_STRING';
        return -1;
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !@violations, 'return -1; should not violate';
}

#####

{
    my $code = <<'END_OF_STRING';
        return 0 + 1;
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !@violations, 'return 0 + 1; should not violate';
}

#####

{
    my $code = <<'END_OF_STRING';
        return (0);
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !!@violations, 'return (0); violates correctly';
}

#####

{
    my $code = <<'END_OF_STRING';
        return (1);
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !!@violations, 'return (1); violates correctly';
}

#####

{
    my $code = <<'END_OF_STRING';
        return (2);
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !@violations, 'return (2); should not violate';
}

#####

{
    my $code = <<'END_OF_STRING';
        return (10);
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !@violations, 'return (10); should not violate';
}

#####

{
    my $code = <<'END_OF_STRING';
        return (01);
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !@violations, 'return (01); should not violate - mean something?';
}

#####

{
    my $code = <<'END_OF_STRING';
        return 0 if 1;
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !!@violations, 'return 0 if 1; violates correctly';
}

#####

{
    my $code = <<'END_OF_STRING';
        return 0 if (1);
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !!@violations, 'return 0 if (1); violates correctly';
}

######

{
    my $code = <<'END_OF_STRING';
        return (0) if 1;
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !!@violations, 'return (0) if 1; violates correctly';
}

######

{
    my $code = <<'END_OF_STRING';
        return (0) if (1);
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !!@violations, 'return (0) if (1); violates correctly';
}

#####

{
    my $code = <<'END_OF_STRING';
        return 0 unless (1);
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !!@violations, 'return 0 unless (1); violates correctly';
}

######

{
    my $code = <<'END_OF_STRING';
        return (0) unless 1;
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !!@violations, 'return (0) unless 1; violates correctly';
}

######

{
    my $code = <<'END_OF_STRING';
        return (0) unless 1; # some comment
END_OF_STRING

    my @violations = _check_perl_critic( \$code );
    ok !!@violations, 'return (0) unless 1; # some comment - violates correctly';
}

######

done_testing();

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

70-boolean-as-int.t

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
