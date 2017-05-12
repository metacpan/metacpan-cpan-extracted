package MarpaX::Simple::Rules;
use strict;

our $VERSION='0.2.7';

use Marpa::XS;
use Data::Dumper;
use base 'Exporter';

our @EXPORT_OK = qw/parse_rules/;

sub Rules { my $m = shift; return { m => $m, rules => \@_ }; } 
sub Rule { shift; return { @{$_[0]}, @{$_[2]}, @{$_[3]||[]} }; }
sub Rule2 { shift; return { @{$_[0]}, rhs => [], @{$_[2]||[]} }; }
sub Lhs { shift; return [lhs => $_[0]];}
sub Rhs { shift; return [rhs => $_[0]];}
sub Star { shift; return [rhs => [ $_[0] ], min => 0]; }
sub Plus { shift; return [rhs => [ $_[0] ], min => 1]; }
sub Names { shift; return [@_];}
sub Null { shift; return [rhs => []]; }
sub Action {
    my (undef, $arrow, $name) = @_;
    return [action => $name];
}

sub parse_rules {
    my ($string) = @_;

    my $grammar = Marpa::XS::Grammar->new({
        start   => 'Rules',
        actions => __PACKAGE__,
        rules => [
            { lhs => 'Rules',     rhs => [qw/Rule/],                                     action => 'Rules', min => 1 },

            { lhs => 'Rule',      rhs => [qw/Lhs DeclareOp Rhs Action/],                 action => 'Rule' },
            { lhs => 'Rule',      rhs => [qw/Lhs DeclareOp Action/],                     action => 'Rule2' },

            { lhs => 'Action',    rhs => [],                                             action => 'Action' },
            { lhs => 'Action',    rhs => [qw/ActionArrow ActionName/],                   action => 'Action' },
            { lhs => 'Action',    rhs => [qw/ActionArrow Name/],                         action => 'Action' },

            { lhs => 'Lhs',       rhs => [qw/Name/],                                     action => 'Lhs' },

            { lhs => 'Rhs',       rhs => [qw/Names/],                                    action => 'Rhs' },
            { lhs => 'Rhs',       rhs => [qw/Name Plus/],                                action => 'Plus' },
            { lhs => 'Rhs',       rhs => [qw/Name Star/],                                action => 'Star' },
            { lhs => 'Rhs',       rhs => [qw/Null/],                                     action => 'Null' },

            { lhs => 'Names',     rhs => [qw/Name/],                                     action => 'Names', min => 1 },
        ],
        terminals => [qw/DeclareOp ActionArrow Name ActionName Plus Star Null/],
    });
    $grammar->precompute;

    my $rec = Marpa::XS::Recognizer->new({grammar => $grammar});

    my @lines  = split /\n/, $string;
    if (!@lines) {
        return [];
    }

    my @terminals = (
        [ 'DeclareOp', '::=' ],
        [ 'ActionName', qr/(::(whatever|undef))/ ],
        [ 'Null', 'Null' ],
        [ 'ActionArrow', '=>' ],
        [ 'Plus', '\+' ],
        [ 'Star', '\*' ],
        [ 'Name', qr/\w+/, ],
    );

    my $nr = 1;

    LINE: for my $line (@lines) {
        my @tokens = split /\s+/, $line;

        TOKEN: for my $token (@tokens) {
            next if $token =~ m/^\s*$/;

            for my $t (@terminals) {
                if ($token =~ m/^($t->[1])/) {

                    if (!$rec->read($t->[0], $2 // $1)) {
                        if ($t->[0] eq 'DeclareOp') {
                            die "Error: Parse exhausted, " . (join ", ", @{$rec->terminals_expected}) 
                                . " expected before '::=' at line $nr";
                        }
                        else {
                            die "Error: Parse exhausted, " . (join ", ", @{$rec->terminals_expected})
                                . " expected at line $nr";
                        }
                    }

                    $token =~ s/$t->[1]//;

                    if ($token) {
                        redo TOKEN;
                    }

                    next TOKEN;
                }
            }

            die "Error: Found '$token', " . (join ", ", @{$rec->terminals_expected}) . " expected at line $nr";
        }
    }
    continue {
        $nr++;
    }

    #if (grep {$_ eq 'DeclareOp'} @{$rec->terminals_expected}) {
    #print Dumper($rec->terminals_expected);
    #$nr--;
    #die "Input incomplete DeclareOp expected at line $nr";
    #}

    #$rec->end_input;

    my $parse_ref = $rec->value;

    if (!defined $parse_ref) {
        return [];
    }

    my $parse = $$parse_ref;

#    if (ref($parse->{m}{error}) eq 'ARRAY' && @{$parse->{m}{error}}) {
#        die join ": ", @{$parse->{m}{error}};
#    }
    return $parse->{rules};
}

1;

__END__

=head1 NAME

MarpaX::Simple::Rules - Simple definition language for rules

=head1 WARNING

MarpaX::Simple::Rules depends on a deprecated module called Marpa::XS. That
module will be (or is already) removed from CPAN.

MarpaX::Simple::Rules served as an inspiration to a new interface called
L<Marpa::R2::Scanless> (SLIF), which features similar syntax and more features.
Where MarpaX::Simple::Rules only parsed BNF rules, SLIF will also tokenize your
input. SLIF is the way forward for all new projects.

=head1 SYNOPSYS

    use Marpa::XS;
    use MarpaX::Simple::Rules 'parse_rules';

    sub numbers {
        my (undef, @numbers) = @_;
        return \@numbers;
    }

    my $rules = parse_rules(<<"RULES");
    parser   ::= number+  => numbers
    RULES

    my $grammar = Marpa::XS::Grammar->new({
        start   => 'parser',
        rules   => $rules,
        actions => __PACKAGE__,
    });
    $grammar->precompute();

    # Read tokens
    my $rec = Marpa::XS::Recognizer->new({grammar => $grammar });
    $rec->read('number', 1);
    $rec->read('number', 2);

    # Get the return value
    my $val = ${$rec->value()};
    print @{$val} . "\n";

=head1 DESCRIPTION

MarpaX::Simple::Rules is a specification language that allows us to write the
parameter for the rules argument of Marpa::XS grammar as a string.

=head1 FUNCTION

=head2 parse_rules(GRAMMAR-STRING)

Parses the argument and returns a values that can be used as the C<rules> argument in
Marpa::XS::Grammar constructor.

=head1 SYNTAX

A rule is a line that consists of two or three parts. These parts are called
the left-hand side (LHS), the right-hand side (RHS) and the action. Every rule
should contain a LHS and RHS. The action is optional.

The LHS and RHS are separated by the declare operator C<::=>. A LHS begins with
a Name. A name is anything that matches the following regex: C<\w+>.

The RHS can be specified in four ways: multiple names, a name with a plus C<+>, a name
with a star C<*>, or C<Null>.

=head1 TRANSFORMATION

This is a list of the patterns that can be specified. On the left of C<becomes>
we see the rule as used in the grammar string and on the right we see perl data
structure that it becomes.

    A ::= B                   becomes      { lhs => 'A', rhs => [ qw/B/ ] }
    A ::= B C                 becomes      { lhs => 'A', rhs => [ qw/B C/ ] }
    A ::= B+                  becomes      { lhs => 'A', rhs => [ qw/B/ ], min => 1 }
    A ::= B*                  becomes      { lhs => 'A', rhs => [ qw/B/ ], min => 0 }
    A ::= B* => return_all    becomes      { 
                                              lhs => 'A',  
                                              rhs => [ qw/B/ ],
                                              min => 0,
                                              action => 'return_all',
                                           }

=head1 TOKENS

MarpaX::Simple::Rules doesn't help you getting from a stream to tokens. See
L<MarpaX::Simple::Lexer> for that or L<MarpaX::Simple::Rules>, which contains a
very simple lexer.

=head1 SEE ALSO

L<Marpa::XS>, L<MarpaX::Simple::Lexer>

=head1 HOMEPAGE

L<http://github.com/pstuifzand/MarpaX-Simple-Rules>

=head1 LICENSE 

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Peter Stuifzand E<lt>peter@stuifzand.euE<gt>

=head1 COPYRIGHT

Copyright (c) 2012-2014 Peter Stuifzand.  All rights reserved.

=cut

