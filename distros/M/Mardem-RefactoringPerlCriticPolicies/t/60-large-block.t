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

Readonly::Scalar my $POLICY_NAME => 'Perl::Critic::Policy::Mardem::ProhibitLargeBlock';

Readonly::Scalar my $STATEMENT_COUNT_LIMIT_VALUE_1  => 1;
Readonly::Scalar my $STATEMENT_COUNT_LIMIT_VALUE_4  => 4;
Readonly::Scalar my $STATEMENT_COUNT_LIMIT_VALUE_26 => 26;

plan 'tests' => 43;

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

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !@violations, 'empty code ok';
}

#####

{
    my $code = <<'END_OF_STRING';
        if(1) {
            # empty code block
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !@violations, 'empty code block ok';
}

#####

{
    my $code = <<'END_OF_STRING';
        if( 1 == 0 && 2 == 3 || 4 == 6 ) {
            print 'test not reached';
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !@violations, 'if with one statement';
}

#####

{
    my $code = <<'END_OF_STRING';
        if( 1 ) {
            print __LINE__;
            return;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'if with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"if"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso, 'violation description correct with if';
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

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'if with inner if of one statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"if"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso, 'violation description correct with if';
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

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_4 );

    ok !@violations, 'if code block with inner if and statement count 4 allowed';
}

#####

{
    my $code = <<'END_OF_STRING';
        while( 1==0 ) {
            print __LINE__;
            return;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'while with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"while"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with while';
}

#####

{
    my $code = <<'END_OF_STRING';
        unless( 1 ) {
            print __LINE__;
            return;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'unless with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"unless"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with unless';
}

#####

{
    my $code = <<'END_OF_STRING';
        until( 1==1 ) {
            print __LINE__;
            return;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'until with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"until"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with until';
}

#####

{
    my $code = <<'END_OF_STRING';
        do {
            print __LINE__;
            return;
        } while( 1==0 );
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'do-while with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"do"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with do-while';
}

#####

{
    my $code = <<'END_OF_STRING';
        for( my $i=0; $i<10; $i++ ) {
            print __LINE__;
            return;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'c-for-loop with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"for"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso, 'violation description correct with for';
}

#####

{
    my $code = <<'END_OF_STRING';
        foreach( 1 .. 10 ) {
            print __LINE__;
            return;
        }
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'foreach with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"foreach"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with foreach';
}

#####

{
    my $code = <<'END_OF_STRING';
        eval {
            print __LINE__;
            return;
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'eval with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"eval"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with eval';
}

#####

{
    my $code = <<'END_OF_STRING';
        my @a = (1,2,3);
        my @x = sort {
            my $x = 1 == 2;
            return $_ > $x ? "x" : "y";
        } @a;
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'sort with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"sort"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with sort';
}

#####

{
    my $code = <<'END_OF_STRING';
        my @a = (1,2,3);
        my @x = map {
            my $x = 1 == 2;
            return "$x $_";} @a;
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'map with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"map"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso, 'violation description correct with map';
}

#####

{
    my $code = <<'END_OF_STRING';
        my @a = (1,2,3);
        my @x = grep {
            my $x = 1 == 2;
            return $x && $_;} @a;
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'grep with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"grep"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with grep';
}

#####

{
    my $code = <<'END_OF_STRING';
        BEGIN {
            print __LINE__;
            return;
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'BEGIN with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"BEGIN"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with BEGIN';
}

#####

{
    my $code = <<'END_OF_STRING';
        UNITCHECK {
            print __LINE__;
            return;
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'UNITCHECK with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"UNITCHECK"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with UNITCHECK';
}

#####

{
    my $code = <<'END_OF_STRING';
        CHECK {
            print __LINE__;
            return;
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'CHECK with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"CHECK"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with CHECK';
}

#####

{
    my $code = <<'END_OF_STRING';
        INIT {
            print __LINE__;
            return;
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'INIT with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"INIT"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with INIT';
}

#####

{
    my $code = <<'END_OF_STRING';
        END {
            print __LINE__;
            return;
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'END with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"END"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso, 'violation description correct with END';
}

#####

{
    my $code = <<'END_OF_STRING';
        PACKAGE MyTest {
            print __LINE__;
            return;
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !!@violations, 'PACKAGE with two statements';

    my $desc = _get_description_from_violations( @violations );

    like $desc, qr/"PACKAGE"\scode-block\s.*\sstatement\scount\s[(]\d+[)]/aaixmso,
        'violation description correct with PACKAGE';
}

#####

{
    my $code = <<'END_OF_STRING';
        sub my_test {
            print __LINE__;
            return;
        };
END_OF_STRING

    my @violations = _check_perl_critic( \$code, $STATEMENT_COUNT_LIMIT_VALUE_1 );

    ok !@violations, 'no violation for sub';
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

    ok !@violations, 'no violation for anonymous-sub';
}

#####

{
    my $code = <<'END_OF_STRING';
        if ( 1 ) {
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

done_testing();

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

50-large-block.t

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
