package Math::RPN::Simple;

use strict;
use warnings;
use Carp qw(croak);
use Exporter;
use List::Util qw(any);

our @ISA=qw(Exporter);
our @EXPORT=qw(to_infix to_postfix evaluate_infix evaluate_postfix);

our $VERSION='1.1.15';
our $LIBRARY=__PACKAGE__;

sub to_infix{
	my @stack;
	while($_[0]=~/([a-zA-Z]+)|(\d+)|([\+\-\/\*])/g){
		if($& eq $2){push(@stack,$&)}
		elsif($& eq $3){
			my @args=(pop @stack,pop @stack);
			push(@stack,"($args[1]$&$args[0])");
		}elsif(any {$& eq $_} ('abs','int','cos','sin')){push(@stack,$&.'('.pop(@stack).')')}
		else{croak "Undefined function \"$&\""}
	}
	return $stack[0];
}

sub to_postfix{
	my @output;
	my @stack;
	while($_[0]=~/([a-zA-Z]+)|(\d+)|(\*\*|[\+\-\/\*])|([\(\)])/g){
		if($& eq $1){push(@stack,$&)}
		elsif($& eq $2){push(@output,$&)}
		elsif($& eq $3){
			while(@stack and ($stack[-1]=~/[a-zA-Z]+/ or any {$& eq $_} ('+','-') or any {$stack[-1] eq $_} ('*','/','**')) and $stack[-1]ne'('){
				push(@output,pop @stack);
			}
			push(@stack,$&);
		}
		elsif($& eq '('){push(@stack,$&)}
		elsif($& eq ')'){
			push(@output,pop @stack) while(@stack and $stack[-1]ne'(');
			pop @stack if @stack;
		}
	}
	push(@output,pop @stack) while @stack;
	return join(' ',@output);
}
sub evaluate_infix{return eval(to_infix to_postfix @_)}
sub evaluate_postfix{return evaluate_infix to_infix @_}

1;

__END__

=encoding UTF-8

=head1 NAME

Math::RPN::Simple - Simpler implementation of L<Math::RPN>.

=head1 VERSION

Version 1.1.14

=head1 DESCRIPTION

Math::RPN::Simple is used to convert infix and postfix notations and to evaluate them.

=head1 METHODS

=head2 to_infix(expression)

=over 2

=item *

expression - Postfix expression to convert.

=item *

return value - Infix representation of expression.

=back

=head2 to_postfix(expression)

=over 2

=item *

expression - Infix expression to convert.

=item *

return value - Postfix representation of expression.

=back

=head2 evaluate_infix(expression)

=over 2

=item *

expression - Infix expression to evaluate.

=item *

return value - Value of infix expression.

=back

=head2 evaluate_postfix(expression)

=over 2

=item *

expression - Postfix expression to evaluate.

=item *

return value - Value of postfix expression.

=back

=head1 OPERATORS

=over 5

=item *

x+y - Sum of x and y.

=item *

x-y - Difference of x and y.

=item *

x*y - Product of x and y.

=item *

x/y - Quotient of x and y

=item *

x**y - x to the power of y.

=back

=head1 FUNCTIONS

=over 4

=item *

abs(x) - Returns absolute value of x.

=item *

int(x) - Returns int representation of x.

=item *

cos(x) - Returns cos of x.

=item *

sin(x) - Returns sin of x.

=back

=head1 BUGS

Please report any bugs here:

=over 4

=item *

debos@cpan.org

=item *

L<GitHub|https://github.com/DeBos99/Math-RPN-Simple/issues>

=item *

L<@DeBos99|https://t.me/DeBos99>

=item *

L<Reddit|https://www.reddit.com/user/DeBos99>

=back

=head1 AUTHOR

Michał Wróblewski <debos@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2019 Michał Wróblewski

=head1 LICENSE

This project is licensed under the MIT License - see the L<LICENSE|https://github.com/DeBos99/Math-RPN-Simple/blob/master/LICENSE> file for details.

=cut
