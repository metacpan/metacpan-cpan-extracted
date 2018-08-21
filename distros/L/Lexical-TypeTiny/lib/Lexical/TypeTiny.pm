use 5.008006;
use strict;
use warnings;

package Lexical::TypeTiny;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';
	
use Types::Standard qw(Any);
use Lexical::Types qw();
use Type::Registry qw();
use Import::Into qw();
use Variable::Magic qw(wizard cast);
use Carp qw();

sub import {
	my $me = shift;
	my $caller = caller;
	$me->setup_for($caller, @_);
}

sub setup_for {
	my $me = shift;
	my ($caller, @args) = @_;
	my %args = map { $_ => 1 } @args;
	
	my $reg = Type::Registry->for_class($caller);
	/\W/ or eval "package $_" for keys %$reg;
	
	if ($args{-nocheck}) {
		Lexical::Types->import::into($caller, as => sub { Any });
	}
	else {
		Lexical::Types->import::into($caller, as => sub { $reg->lookup($_[0]) });
	}
}

sub Type::Tiny::TYPEDSCALAR {
	my $type  =  $_[0];
	
	return if $type == Any;
	
	my $var   = \$_[1];
	my $check = $type->compiled_check;
	my $wiz   = wizard(
		set => sub {
			package # hide from PAUSE
				Type::Tiny;
			$check->(${$_[0]}) or Carp::croak($type->get_message(${$_[0]}));
		},
	);
	cast $_[1], $wiz;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lexical::TypeTiny - my Int $n

=head1 SYNOPSIS

  use Types::Standard qw(Int);
  use Lexical::TypeTiny;
  
  my Int $n = 42;
  $n += 0.5;   # dies, not an Int

=head1 DESCRIPTION

Lexical::TypeTiny is similar in spirit to L<Type::Tie>, but:

=over

=item *

It's a lot faster because it uses L<Variable::Magic> instead of C<tie>.

=item *

It's limited to only scalar variables, no arrays or hashes.
(Of course, those scalars may be arrayrefs or hashrefs.)

=item *

Does not (currently) support coercion.

=item *

It's limited to simple type constraints like C<ArrayRef>, and not
parameterized type constraints like C<< ArrayRef[Int] >>. (This is
a limitation of the syntax Perl will parse, not a limitation of the
complexity of type constraints supported. You can define a 
C<ArrayRef_of_Int> type constraint in your own type library, and
it will work.)

=item *

Although an exception is thrown if you try to assign an invalid
value to the variable, the assignment still happens. In the L</SYNOPSIS>,
if you caught the exception and then examined C<< $n >>, it would be
42.5.

(This particular aspect of Lexical::TypeTiny's behaviour is not fixed
in stone and may change in a future version.)

=back

Because of the way Perl parses lexical variable types, if you wish to
declare, say C<< my Int $x >>, there needs to exist a class called
C<Int>. That class doesn't have to actually I<do> anything; it doesn't
need constructors, methods, etc.

Lexical::TypeTiny will create such classes for you at import time,
however to do so, it needs to know what type constraints you are planning
on using. This means B<< you need to import your type libraries before
importing Lexical::TypeTiny >>.

Good:

  use Types::Standard qw(Int);
  use Lexical::TypeTiny;

Bad:

  use Lexical::TypeTiny;
  use Types::Standard qw(Int);

=head2 Disabling Type Checks

  use Lexical::TypeTiny -nocheck;

=head1 BUGS

There currently seem to be issues with threaded Perls. Hopefully these can
be solved pretty soon.

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Lexical-TypeTiny>.

=head1 SEE ALSO

L<Type::Tie>, L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

