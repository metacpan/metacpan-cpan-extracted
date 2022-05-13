#!perl

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;
use Perl::Critic;
use Perl::Critic::Utils qw{ :severities };

use Test::More;

Readonly::Scalar my $POLICY_NAME => 'Perl::Critic::Policy::Mardem::ProhibitBlockComplexity';

Readonly::Scalar my $MCC_VALUE_1 => 1;
Readonly::Scalar my $MCC_VALUE_4 => 4;

plan 'tests' => 40;

#####

sub _get_perl_critic_object
{
    my @configs = @_;

    my $pc = Perl::Critic->new(
        '-profile'  => 'NONE',
        '-only'     => 1,
        '-severity' => 1,
        '-force'    => 0
    );

    $pc->add_policy( '-policy' => $POLICY_NAME, @configs );

    return $pc;
}

#####

sub _check_perl_critic
{
    my ( $code_ref, $max_mccabe ) = @_;

    my @params;
    if ( $max_mccabe ) {
        @params = ( '-params' => { 'max_mccabe' => $max_mccabe } );
    }

    my $pc = _get_perl_critic_object( @params );

    return $pc->critique( $code_ref );
}

#####

sub _get_description_from_violations
{
    my @violations = @_;

    if ( @violations ) {
        my $violation = shift @violations;
        my $desc      = $violation->description();

        if ( $desc ) {
            return $desc;
        }
    }

    return q{};
}

#####

{
    my $code = <<'END_OF_STRING';
        # empty code
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !@violations, 'empty code ok';
}

#####

{
    my $code = <<'END_OF_STRING';
        if(1) {
            # empty code block
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !@violations, 'empty code block ok';
}

#####

{
    my $code = <<'END_OF_STRING';
        if( 1 == 0 && 2 == 3 || 4 == 6 ) {
            print 'test not reached';
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !@violations, 'simple if code block ok';
}

#####

{
    my $code = <<'END_OF_STRING';
        if( 1 ) {
            if( 1 == 0 && 2 == 3 || 4 == 6 ) {
                print 'test not reached';
            }
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex if code block with inner if';
}

#####

{
    my $code = <<'END_OF_STRING';
        if( 1 ) {
            if( 1 == 0 && 2 == 3 || 4 == 6 ) {
                print 'test not reached';
            }
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_4 );

    ok !@violations, 'complex if code block with inner if but mcc value 4 allowed';
}

#####

{
    my $code = <<'END_OF_STRING';
        if( 1 ) {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within if block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"if"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso, 'violation description correct with if';
}

#####

{
    my $code = <<'END_OF_STRING';
        while( 1==0 ) {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within while block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"while"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with while';
}

#####

{
    my $code = <<'END_OF_STRING';
        unless( 1 ) {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within unless block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"unless"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with unless';
}

#####

{
    my $code = <<'END_OF_STRING';
        until( 1==1 ) {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within until block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"until"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with until';
}

#####

{
    my $code = <<'END_OF_STRING';
        do {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        } while( 1==0 );
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within do block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"do"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with do-while';
}

#####

{
    my $code = <<'END_OF_STRING';
        for( my $i=0; $i<10; $i++ ) {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within c-for-loop block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"for"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with for';
}

#####

{
    my $code = <<'END_OF_STRING';
        foreach( 1 .. 10 ) {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within foreach block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"foreach"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with foreach';
}

#####

{
    my $code = <<'END_OF_STRING';
        eval {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within eval block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"eval"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with eval';
}

#####

{
    my $code = <<'END_OF_STRING';
        my @a = (1,2,3);
        my @x = sort { 1 == 0 && 2 == 3 || 4 == 6 } @a;
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex sort block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"sort"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with sort';
}

#####

{
    my $code = <<'END_OF_STRING';
        my @a = (1,2,3);
        my @x = map { 1 == 0 && 2 == 3 || 4 == 6 } @a;
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex map block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"map"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with map';
}

#####

{
    my $code = <<'END_OF_STRING';
        my @a = (1,2,3);
        my @x = grep { 1 == 0 && 2 == 3 || 4 == 6 } @a;
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex grep block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"grep"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with grep';
}

#####

{
    my $code = <<'END_OF_STRING';
        BEGIN {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within BEGIN block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"BEGIN"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with BEGIN';
}

#####

{
    my $code = <<'END_OF_STRING';
        UNITCHECK {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within UNITCHECK block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"UNITCHECK"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with UNITCHECK';
}

#####

{
    my $code = <<'END_OF_STRING';
        CHECK {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within CHECK block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"CHECK"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with CHECK';
}

#####

{
    my $code = <<'END_OF_STRING';
        INIT {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within INIT block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"INIT"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with INIT';
}

#####

{
    my $code = <<'END_OF_STRING';
        END {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within END block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"END"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with END';
}

#####

{
    my $code = <<'END_OF_STRING';
        PACKAGE MyTest {
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !!@violations, 'complex tinaray within PACKAGE block';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"PACKAGE"\scode-block\s.*\scomplexity\sscore\s[(]\d+[)]/aaixmso,
        'violation description correct with PACKAGE';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test{
            print 'test ' . ( 1 == 0 && 2 == 3 || 4 == 6 ? '' : 'not ') . 'reached'."\n";
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $MCC_VALUE_1 );

    ok !@violations, 'no complex violation for sub-block';
}

#####

done_testing();

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

30-complex-block.t

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
