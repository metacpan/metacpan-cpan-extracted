#!perl

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;

use Perl::Critic;

use Test::More;

Readonly::Scalar my $POLICY_NAME => 'Perl::Critic::Policy::Mardem::ProhibitLargeSub';

Readonly::Scalar my $STATEMENT_COUNT_LIMIT_VALUE_1  => 1;
Readonly::Scalar my $STATEMENT_COUNT_LIMIT_VALUE_2  => 2;
Readonly::Scalar my $STATEMENT_COUNT_LIMIT_VALUE_26 => 26;
Readonly::Scalar my $STATEMENT_COUNT_LIMIT_VALUE_99 => 99;

plan 'tests' => 12;

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
    my ( $code_ref, $statement_count_limit ) = @_;

    my @params;
    if ( $statement_count_limit ) {
        @params = ( '-params' => { 'statement_count_limit' => $statement_count_limit } );
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

    my @violations = _check_perl_critic( \$code );

    ok !@violations, 'no violation with empty code';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            # empty sub
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !@violations, 'no violation with only comment in sub';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            return 1;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !@violations, 'no violation with single return sub';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            my $x = 1;
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !@violations, 'no violation with two statements in sub';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            # some first stuff
            print "DEBUG: " . __LINE__;
            my $x = 1;

            $x+=1;
            $x+=2;
            $x+=3;
            $x+=5;

            # some other stuff
            print "DEBUG: " . __LINE__;
            my $y = 1;

            $y+=1;
            $y+=2;
            $y+=3;
            $y+=5;

            $x *= $y;

            # some more other stuff
            print "DEBUG: " . __LINE__;
            my $z = 1.1;

            $z+=1.1;
            $z+=2.2;
            $z+=3.3;
            $z+=5.5;

            $x *= $z;

            if(0) {
                # not happen
                print "DEBUG: " . __LINE__;
                $x = 0;
            }

            # return something
            print "DEBUG: " . __LINE__;
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code );

    ok !!@violations, 'violation with some large sub';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/subroutine\s"my_test"\s.*\sstatement\scount\s[(]26[)]/aaixmso,
        'description correct count 26 not allowed';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            # some first stuff
            print "DEBUG: " . __LINE__;
            my $x = 1;

            $x+=1;
            $x+=2;
            $x+=3;
            $x+=5;

            # some other stuff
            print "DEBUG: " . __LINE__;
            my $y = 1;

            $y+=1;
            $y+=2;
            $y+=3;
            $y+=5;

            $x *= $y;

            # some more other stuff
            print "DEBUG: " . __LINE__;
            my $z = 1.1;

            $z+=1.1;
            $z+=2.2;
            $z+=3.3;
            $z+=5.5;

            $x *= $z;

            if(0) {
                # not happen
                print "DEBUG: " . __LINE__;
                $x = 0;
            }

            # return something
            print "DEBUG: " . __LINE__;
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_99 );

    ok !@violations, 'not violation with some large sub when 99 statements allowed via config';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            my $x = 1;
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_2 );

    ok !@violations, 'no violation with two statements in sub when 2 statements as config set';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            my $x = 1;
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'violation with two statements in sub when 1 statements as config set';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/subroutine\s"my_test"\s.*\sstatement\scount\s[(]2[)]/aaixmso,
        'description correct count 2 not allowed';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            # some first stuff
            print "DEBUG: " . __LINE__;
            my $x = 1;

            $x+=1;
            $x+=2;
            $x+=3;
            $x+=5;

            # some other stuff
            print "DEBUG: " . __LINE__;
            my $y = 1;

            $y+=1;
            $y+=2;
            $y+=3;
            $y+=5;

            $x *= $y;

            # some more other stuff
            print "DEBUG: " . __LINE__;
            my $z = 1.1;

            $z+=1.1;
            $z+=2.2;
            $z+=3.3;
            $z+=5.5;

            $x *= $z;

            if(0==1) { # 2 statements if + 0==1
                # not happen
                print "DEBUG: " . __LINE__;
                $x = 0;
            }

            # return something
            print "DEBUG: " . __LINE__;
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_26 );

    ok !@violations, 'no violation with some large sub when 26 allowed';
}

#####

{
    my $code = <<'END_OF_STRING';
        my $my_test_sub = sub {
            my $x = 1;
            return $x;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !@violations, 'no violation for anonymous sub';
}

#####

done_testing();

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

40-large-sub.t

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
