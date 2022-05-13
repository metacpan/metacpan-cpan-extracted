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

Readonly::Scalar my $POLICY_NAME => 'Perl::Critic::Policy::Mardem::ProhibitManyConditionsInSub';

Readonly::Scalar my $CONDITION_COUNT_LIMIT_VALUE_1 => 1;
Readonly::Scalar my $CONDITION_COUNT_LIMIT_VALUE_2 => 2;

plan 'tests' => 14;

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
    my ( $code_ref, $condition_count_limit ) = @_;

    my @params;
    if ( $condition_count_limit ) {
        @params = ( '-params' => { 'condition_count_limit' => $condition_count_limit } );
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

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !@violations, 'empty code ok';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            # empty code block
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !@violations, 'empty sub block ok';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            if( 1 == 0 && 2 == 3 || 4 == 6 ) {
                print 'test not reached';
            }
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !@violations, 'sub with one if';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            if( 1 ) {
                if( 1 == 0 && 2 == 3 || 4 == 6 ) {
                    print 'test not reached';
                }
            }
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'sub with if and inner if';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/subroutine\s"my_test"\s.+\scondition\scount\s[(]2[)]/aaixmso,
        'violation description correct with value 2';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            if( 1 ) {
                if( 1 == 0 && 2 == 3 || 4 == 6 ) {
                    print 'test not reached';
                }
            }
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_2 );

    ok !@violations, 'sub with if and inner if but two allowed';
}

#####

{
    my $code = <<'END_OF_STRING';
       sub my_test {
            while( 1==0 ) {
                print __LINE__;
            }

            if( 1 ) {
                print __LINE__;
                return;
            }

            return;
       }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'sub with if and while';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            unless( 1==1 ) {
                print __LINE__;
            }

            if( 1 ) {
                print __LINE__;
                return;
            }

            return;
       }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'sub with if and unless';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            until( 1==1 ) {
                print __LINE__;
            }

            if( 1 ) {
                print __LINE__;
                return;
            }

            return;
       }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'sub with if and until';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            do {
                print __LINE__;
            } while ( 1!=1 );

            if( 1 ) {
                print __LINE__;
                return;
            }

            return;
       }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'sub with if and do-while';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            for( my $i=0; $i<10; $i++ ) {
                print __LINE__;
                return;
            }

            if( 1 ) {
                print __LINE__;
                return;
            }

            return;
       }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'sub with if and c-for-loop';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            if( 1 ) {
                print __LINE__;
                return;
            }

            eval {
                while( 1==0 ) {
                    print __LINE__;
                    return;
                }

                print __LINE__;
                return;
            };
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'sub with if and while in eval';
}

#####

{
    my $code = <<'END_OF_STRING';
        my $my_test_sub = sub {
            if( 1 ) {
                print __LINE__;
                return;
            }

            if( 1 ) {
                print __LINE__;
                return;
            }

            return 1;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !@violations, 'no violation for anonymous-sub';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            if( 1 ) {
                print __LINE__;
                return;
            }

            my $day_code = 1;
            given ($day_code) {
                when (1) { print 'Monday' ;}
                when (7) { print 'Sunday' ;}
                default { print 'Invalid day-code';}
            }
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $CONDITION_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'sub with if and given';
}

#####

done_testing();

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

60-many-conditions-in-sub.t

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
