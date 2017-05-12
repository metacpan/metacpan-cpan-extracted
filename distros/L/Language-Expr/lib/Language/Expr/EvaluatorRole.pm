package Language::Expr::EvaluatorRole;

our $DATE = '2016-07-03'; # DATE
our $VERSION = '0.29'; # VERSION

use 5.010;
use strict;
use warnings;

use Role::Tiny;

requires 'rule_pair_simple';
requires 'rule_pair_string';
requires 'rule_or_xor';
requires 'rule_ternary';
requires 'rule_and';
requires 'rule_bit_or_xor';
requires 'rule_bit_and';
requires 'rule_comparison3';
requires 'rule_comparison';
requires 'rule_bit_shift';
requires 'rule_add';
requires 'rule_mult';
requires 'rule_unary';
requires 'rule_power';
requires 'rule_subscripting_var';
requires 'rule_subscripting_expr';
requires 'rule_array';
requires 'rule_hash';
requires 'rule_undef';
requires 'rule_squotestr';
requires 'rule_dquotestr';
requires 'rule_var';
requires 'rule_func';
requires 'rule_func_map';
requires 'rule_func_grep';
requires 'rule_func_usort';
requires 'rule_bool';
requires 'rule_num';
requires 'rule_parenthesis';
requires 'expr_preprocess';
requires 'expr_postprocess';

sub parse_dquotestr {
    my ($self, @parts) = @_;
    if (ref($parts[0]) eq 'ARRAY') { splice @parts, 0, 1, @{ $parts[0] } }
    my @res;
    my @sbuf;

    #say "D:parse_dquotestr:parts = ", join(", ", @parts);
    #for (grep {defined} @parts) {
    for (@parts) {
        no warnings;
        my $s01 = substr($_, 0, 1);
        my $s02 = substr($_, 0, 2);
        my $l = length();
        if    ($_ eq "\\'" ) { push @sbuf, "'"  }
        elsif ($_ eq "\\\"") { push @sbuf, '"'  }
        elsif ($_ eq "\\\\") { push @sbuf, "\\" }
        elsif ($_ eq "\\\$") { push @sbuf, '$'  }
        elsif ($_ eq "\\t" ) { push @sbuf, "\t" }
        elsif ($_ eq "\\n" ) { push @sbuf, "\n" }
        elsif ($_ eq "\\f" ) { push @sbuf, "\f" }
        elsif ($_ eq "\\b" ) { push @sbuf, "\b" }
        elsif ($_ eq "\\a" ) { push @sbuf, "\a" }
        elsif ($_ eq "\\e" ) { push @sbuf, "\e" }
        elsif ($l >= 2 && $l <= 4 && $s01 eq "\\" &&
                   substr($_, 1, 1) >= "0" && substr($_, 1, 1) <= "7") {
            # \000 octal escape
            push @sbuf, chr(oct(substr($_, 1))) }
        elsif ($l >= 3 && $l <= 4 && $s02 eq "\\x") {
            # \xFF hex escape
            push @sbuf, chr(hex(substr($_, 1))) }
        elsif ($l >= 5 && $l <= 8 && substr($_, 0, 3) eq "\\x{") {
            # \x{1234} wide hex escape
            push @sbuf, chr(hex(substr($_, 3, length()-4))) }
        elsif ($s02 eq '${') {
            # ${var}
            push @res, {type=>"STR", value=>join("", @sbuf)} if @sbuf; @sbuf=();
            push @res, {type=>"VAR", value=>substr($_, 2, length()-3)} }
        elsif ($s01 eq '$') {
            # $var
            push @res, {type=>"STR", value=>join("", @sbuf)} if @sbuf; @sbuf=();
            push @res, {type=>"VAR", value=>substr($_, 1, length()-1)} }
        else {
            push @sbuf, $_;
        }
    }
    push @res, {type=>"STR", value=>join("", grep {defined} @sbuf)} if @sbuf;
    \@res;
}

sub parse_squotestr {
    my ($self, @parts) = @_;
    if (ref($parts[0]) eq 'ARRAY') { splice @parts, 0, 1, @{ $parts[0] } }
    my @res;
    my @sbuf;

    #say "D:parse_dquotestr:parts = ", join(", ", @parts);
    #for (grep {defined} @parts) {
    for (@parts) {
        no warnings;
        if    ($_ eq "\\'" ) { push @sbuf, "'"  }
        elsif ($_ eq "\\\\") { push @sbuf, "\\" }
        else                 { push @sbuf, $_   }
    }
    push @res, {type=>"STR", value=>join("", grep {defined} @sbuf)} if @sbuf;
    \@res;
}

1;
# ABSTRACT: Specification for Language::Expr interpreter/compiler

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Expr::EvaluatorRole - Specification for Language::Expr interpreter/compiler

=head1 VERSION

This document describes version 0.29 of Language::Expr::EvaluatorRole (from Perl distribution Language-Expr), released on 2016-07-03.

=head1 METHODS

=head2 parse_dquotestr($raw_parts) -> [{type=>"STR"|"VAR"}, value=>...}, ...]

Instead of parsing parts themselves, consumers can use this method (typically in
their rule_dquotestr). This method converts each Expr escapes into Perl string
and variables. For example:

 parse_dquotestr('abc', "\\t", '\\\\', '$foo', ' ', '${bar baz}') -> (
   {type=>"STR", value=>'abc\t\\'},
   {type=>"VAR", value=>'foo'},
   {type=>"STR", value=>' '},
   {type=>"VAR", value=>'bar baz'},
 )

=head2 parse_squotestr($raw_parts) => [{type=>STR, value=>...}, ...]

Instead of parsing parts themselves, consumers can use this method (typically in
their rule_squotestr). This method converts Expr single quoted string into Perl
string.

 parse_dquotestr('abc', "\\t", '\\\\', '$foo', ' ', '${bar baz}') -> (
   {type=>"STR", value=>'abc\t\\$foo ${bar baz}'},
 )

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
