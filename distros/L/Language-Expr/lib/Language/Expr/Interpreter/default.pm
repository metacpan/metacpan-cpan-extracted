package Language::Expr::Interpreter::default;

our $DATE = '2016-07-03'; # DATE
our $VERSION = '0.29'; # VERSION

use 5.010;
use strict;
use warnings;

use Role::Tiny::With;
use Mo qw(build default);
extends 'Language::Expr::Interpreter::Base';
with 'Language::Expr::InterpreterRole';
use List::Util 'reduce';
use boolean;

has vars  => (is => 'rw', default => sub { {} });
has funcs => (is => 'rw', default => sub { {} });
has level => (is => 'rw', default => sub { 0 });

sub rule_pair_simple {
    my ($self, %args) = @_;
    my $match = $args{match};
    [$match->{key}, $match->{value}];
}

sub rule_pair_string {
    my ($self, %args) = @_;
    my $match = $args{match};
    [$match->{key}, $match->{value}];
}

sub rule_or_xor {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '||') { $res ||= $term          }
        elsif ($op eq '//') { $res //= $term          }
        elsif ($op eq '^^') { $res = ($res xor $term) }
    }
    $res;
}

sub rule_ternary {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $opd = $match->{operand};
    $opd->[0] ? $opd->[1] : $opd->[2];
}

sub rule_and {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '&&') { $res = $res && $term || false }
    }
    $res;
}

sub rule_bit_or_xor {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '|') { $res = $res+0 | $term }
        elsif ($op eq '^') { $res = $res+0 ^ $term }
    }
    $res;
}

sub rule_bit_and {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '&') { $res = $res+0 & $term }
    }
    $res;
}

sub rule_comparison3 {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    return $res unless @{$match->{operand}};
    my $last_term = $res;
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '<=>') { $res = ($last_term <=> $term) }
        elsif ($op eq 'cmp') { $res = ($last_term cmp $term) }
        $last_term = $term;
    }
    $res;
}

sub rule_comparison {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    return $res unless @{$match->{operand}};
    my $last_term = $res;
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '==' ) { return false unless $res = ($last_term == $term ? true:false) }
        elsif ($op eq '!=' ) { return false unless $res = ($last_term != $term ? true:false) }
        elsif ($op eq 'eq' ) { return false unless $res = ($last_term eq $term ? true:false) }
        elsif ($op eq 'ne' ) { return false unless $res = ($last_term ne $term ? true:false) }
        elsif ($op eq '<'  ) { return false unless $res = ($last_term <  $term ? true:false) }
        elsif ($op eq '<=' ) { return false unless $res = ($last_term <= $term ? true:false) }
        elsif ($op eq '>'  ) { return false unless $res = ($last_term >  $term ? true:false) }
        elsif ($op eq '>=' ) { return false unless $res = ($last_term >= $term ? true:false) }
        elsif ($op eq 'lt' ) { return false unless $res = ($last_term lt $term ? true:false) }
        elsif ($op eq 'gt' ) { return false unless $res = ($last_term gt $term ? true:false) }
        elsif ($op eq 'le' ) { return false unless $res = ($last_term le $term ? true:false) }
        elsif ($op eq 'ge' ) { return false unless $res = ($last_term ge $term ? true:false) }
        $last_term = $term;
    }
    $res ? true : false;
}

sub rule_bit_shift {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '>>') { $res >>= $term }
        elsif ($op eq '<<') { $res <<= $term }
    }
    $res;
}

sub rule_add {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '+') { $res += $term }
        elsif ($op eq '-') { $res -= $term }
        elsif ($op eq '.') { $res .= $term }
    }
    $res;
}

sub rule_mult {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '*') { $res *= $term }
        elsif ($op eq '/') { $res /= $term }
        elsif ($op eq '%') { $res %= $term }
        elsif ($op eq 'x') { $res x= $term }
    }
    $res;
}

sub rule_unary {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = $match->{operand};
    if ($match->{op}) {
        for my $op (reverse @{$match->{op}}) {
            if    ($op eq '!') { $res = $res ? false : true }
            elsif ($op eq '-') { $res = -$res }
            elsif ($op eq '~') { $res = ~($res+0) }
        }
    }
    $res;
}

sub rule_power {
    my ($self, %args) = @_;
    my $match = $args{match};
    reduce { $b ** $a } reverse @{$match->{operand}};
}

sub rule_subscripting_var {
    my ($self, %args) = @_;
    $self->rule_subscripting_expr(%args);
}

sub rule_subscripting_expr {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $res = $match->{operand};
    for my $i (@{$match->{subscript}}) {
        if (ref($res) eq 'ARRAY'  ) { $res = $res->[$i] }
        elsif (ref($res) eq 'HASH') { $res = $res->{$i} }
        else { die "Invalid subscript on nonhash/nonarray" }
    }
    $res;
}

sub rule_array {
    my ($self, %args) = @_;
    my $match = $args{match};
    $match->{element};
}

sub rule_hash {
    my ($self, %args) = @_;
    my $match = $args{match};
    return { map { $_->[0] => $_->[1] } @{ $match->{pair} } }
}

sub rule_undef {
    my ($self, %args) = @_;
    my $match = $args{match};
    undef;
}

sub rule_squotestr {
    my ($self, %args) = @_;
    join("",
         map { $_->{value} }
             @{ $self->parse_squotestr($args{match}{part}) });
}

sub rule_dquotestr {
    my ($self, %args) = @_;
    join("",
         map { $_->{type} eq 'VAR' ?
                   $self->rule_var(match=>{var=>$_->{value}}) :
                   $_->{value}
               }
             @{ $self->parse_dquotestr($args{match}{part}) });
}

sub rule_bool {
    my ($self, %args) = @_;
    my $match = $args{match};
    if ($match->{bool} eq 'true') { true } else { false }
}

sub rule_num {
    my ($self, %args) = @_;
    my $match = $args{match};
    if    ($match->{num} eq 'inf') { "Inf"+0 }
    elsif ($match->{num} eq 'nan') { "NaN"+0 }
    else                           { $match->{num}+0 }
}

sub rule_var {
    my ($self, %args) = @_;
    my $match = $args{match};
    $self->vars->{ $match->{var} };
}

sub rule_func {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $f = $match->{func_name};
    my $args = $match->{args};
    my $res;
    if ($self->funcs->{$f}) {
        return $self->funcs->{$f}->(@$args);
    } else {
        die "Unknown function $f";
    }
}

sub _map_grep_usort {
    my ($self, $which, %args) = @_;
    my $match = $args{match};
    my $ary = $match->{array};
    my $expr = $match->{expr};
    die "Second argument to map/grep/usort must be an array"
        unless ref($ary) eq 'ARRAY';
    local $self->{level} = $self->{level}+1;
    #print "DEBUG: _map_grep_usort: level=$self->{level}, expr=`$expr`, array=[".join(",", @$ary),"]\n";
    my $res;
    if ($which eq 'map') {
        $res = [];
        local $self->{vars}{_};
        for (@$ary) {
            $self->{vars}{_} = $_;
            push @$res, Language::Expr::Parser::parse_expr($expr, $self,
                                                           $self->level);
            push @$res, $_;
        }
    } elsif ($which eq 'grep') {
        local $self->{vars}{_};
        $res = [ grep {
            $self->{vars}{_} = $_;
            $self->Language::Expr::Parser::parse_expr($expr, $self,
                                                      $self->level)
        } @$ary];
    } elsif ($which eq 'usort') {
        local $self->{vars}{a};
        local $self->{vars}{b};
        $res = [ sort {
            $self->{vars}{a} = $a;
            $self->{vars}{b} = $b;
            Language::Expr::Parser::parse_expr($expr, $self,
                                               $self->level)
        } @$ary];
    }
    $res;
}

sub rule_func_map {
    my ($self, %args) = @_;
    $self->_map_grep_usort('map', %args);
}

sub rule_func_grep {
    my ($self, %args) = @_;
    $self->_map_grep_usort('grep', %args);
}

sub rule_func_usort {
    my ($self, %args) = @_;
    $self->_map_grep_usort('usort', %args);
}

sub rule_parenthesis {}

sub expr_preprocess {}

sub expr_postprocess {
    my ($self, %args) = @_;
    my $result = $args{result};
    $result;
}

1;
# ABSTRACT: A default interpreter for Language::Expr

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Expr::Interpreter::default - A default interpreter for Language::Expr

=head1 VERSION

This document describes version 0.29 of Language::Expr::Interpreter::default (from Perl distribution Language-Expr), released on 2016-07-03.

=head1 SYNOPSIS

 use Language::Expr::Interpreter::default;
 my $itp = Language::Expr::Interpreter::default->new;
 $itp->vars->{a} = 'A';
 say $itp->eval(q["$a b" . "c"]); # "A b c"

=head1 DESCRIPTION

Interprets Language::Expr expression. Some notes:

=over 4

=item * Uses L<boolean> module.

=item * Follows Perl's notion of true and false.

That is, this expression ' "" || "0" || 2 ' will result to 2 because
Perl thinks "" and "0" are false.

=back

=for Pod::Coverage ^(rule|expr)_.+

=head1 BUGS/TODOS

Currently subexpression (map/grep/usort) doesn't work yet.

=head1 ATTRIBUTES

=head2 vars => {NAME => VAL, ...}

Store variables.

=head2 funcs => {NAME => CODEREF, ...}

List known functions.

=head2 level => INT

Current recursion level.

=head1 METHODS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Language-Expr>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Language-Expr>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Language-Expr>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
