package Getopt::EX::RPN;

our $VERSION = "0.01";

=encoding utf-8

=head1 NAME

Getopt::EX::RPN - RPN calculation module for Getopt::EX command option

=head1 SYNOPSIS

    use Getopt::EX::RPN qw(rpn_calc);

=head1 DESCRIPTION

Getopt::EX::RPN is a wrapper for L<Math::RPN> package which implement
Reverse Polish Notation calculation.  B<rpn_calc> function in this
package takes additional C<HEIGHT> and C<WIDTH> token which describe
terminal height and width.

B<rpn_calc> recognize following tokens (case-insensitive) and numbers,
and ignore anything else.  So you can use any other character as a
delimiter.  Delimiter is not necessary if token boundary is clear.

    HEIGHT  WIDTH
    {   }
    +,ADD  ++,INCR  -,SUB  --,DECR  *,MUL  /,DIV  %,MOD  POW  SQRT
    SIN  COS  TAN
    LOG  EXP
    ABS  INT
    &,AND  |,OR  !,NOT  XOR  ~
    <,LT  <=,LE  =,==,EQ  >,GT  >=,GE  !=,NE
    IF
    DUP  EXCH  POP
    MIN  MAX
    TIME
    RAND  LRAND

Since module L<Getopt::EX::Func> uses comma to separate parameters,
you can't use comma as a token separator in RPN expression.  This
package accept expression like this:

    &set(width=WIDTH:2/,height=HEIGHT:DUP:2%-2/)

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw( rpn_calc );

my @operator = sort { length $b <=> length $a } split /[,\s]+/, <<'END';
HEIGHT WIDTH
{   }
+,ADD  ++,INCR  -,SUB  --,DECR  *,MUL  /,DIV  %,MOD  POW  SQRT
SIN  COS  TAN
LOG  EXP
ABS  INT
&,AND  |,OR  !,NOT  XOR  ~
<,LT  <=,LE  =,==,EQ  >,GT  >=,GE  !=,NE
IF
DUP  EXCH  POP
MIN  MAX
TIME
RAND  LRAND
END

use Data::Dumper;

my $operator_re = join '|', map quotemeta, @operator;
my $term_re     = qr/(?:\d*\.)?\d+|$operator_re/i;
my $rpn_re      = qr/(?: $term_re ,* ){2,}/xi;

tie my %terminal, __PACKAGE__;

sub rpn_calc {
    use Math::RPN ();
    my @terms = map { /$term_re/g } @_;
    for (@terms) {
	if (/^(?:HEIGHT|WIDTH)$/i) {
	    $_ = $terminal{$_}
	}
    }
    my @ans = do { local $_; Math::RPN::rpn @terms };
    if (@ans == 1 && defined $ans[0] && $ans[0] !~ /[^\.\d]/) {
	$ans[0];
    } else {
	undef;
    }
}

sub TIEHASH {
    my $pkg = shift;
    bless { HEIGHT => undef, WIDTH => undef }, $pkg;
}

sub FETCH {
    my $obj = shift;
    my $key = uc shift;
    if (not defined $obj->{$key}) {
	($obj->{HEIGHT}, $obj->{WIDTH}) = terminal_size();
    }
    $obj->{$key} // die;
}

sub terminal_size {
    use Term::ReadKey;
    my @default = (80, 24);
    my @size;
    if (open my $tty, ">", "/dev/tty") {
	# Term::ReadKey 2.31 on macOS 10.15 has a bug in argument handling
	# and the latest version 2.38 fails to install.
	# This code should work on both versions.
	@size = GetTerminalSize $tty, $tty;
    }
    @size ? @size : @default;
}

1;

#  LocalWords:  RPN rpn calc
