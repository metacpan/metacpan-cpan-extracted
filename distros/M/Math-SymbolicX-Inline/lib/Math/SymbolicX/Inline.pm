package Math::SymbolicX::Inline;

use 5.006001;
use strict;
use warnings;
use Carp qw/cluck confess/;
use Math::Symbolic qw/parse_from_string U_P_DERIVATIVE U_T_DERIVATIVE/;
use Math::Symbolic::Custom::Contains;
use Math::Symbolic::Compiler qw/compile_to_code/;

our $VERSION = '1.11';

sub import {

    # Just using the module shouldn't throw a fatal error.
    if ( @_ != 2 ) {
        return ();
    }

    my ( $class, $code ) = @_;
    my ( $pkg, undef ) = caller;

    my %definitions;

    if ( not defined $code ) {
        confess "undef passed to Math::SymbolicX::Inline as source\n"
          . "code. Can't compile undef to something reasonable, can you?";
    }

    my @lines = split /\n+/, $code;
    my $lastsymbol = undef;
    foreach my $line (@lines) {

        # prepare the line, skip empty lines, strip comments...
        chomp $line;
        $line =~ s/\#.*$//;
        next if $line =~ /^\s*$/;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        # new definitions
        if ( $line =~ /^([A-Za-z_][A-Za-z0-9_]*)\s*(\(:?=\)|:?=)(.*)$/ ) {
            my ( $symbol, $type, $codestart ) = ( $1, $2, $3 );
            if ( exists $definitions{$1} ) {
                confess "(Math::SymbolicX::Inline:) Symbol "
                  . "'$symbol' redefined in package '$pkg'.";
            }

            $definitions{$symbol} = {
                code => $codestart,
                type => $type,
            };

            # Check syntax of the finished piece of code here
            _check_syntax( \%definitions, $lastsymbol );

            $lastsymbol = $symbol;
        }
        else {
            if ( not defined $lastsymbol ) {
                confess "Math::SymbolicX::Inline code must "
                  . "start with a symbol.";
            }
            $definitions{$lastsymbol}{code} .= ' ' . $line;
        }
    }

    # Check the syntax of the last piece of code
    _check_syntax( \%definitions, $lastsymbol );

    # Now we start distinguishing between the different operator types.

    my %early;
    my %late;

    foreach my $s ( keys %definitions ) {
        if ( $definitions{$s}{type} eq '=' ) {
            $early{$s} = $definitions{$s};
        }
        elsif ( $definitions{$s}{type} eq ':=' ) {
            $late{$s} = $definitions{$s};
        }
        elsif ( $definitions{$s}{type} eq '(=)' ) {
            $early{$s} = $definitions{$s};
        }
        elsif ( $definitions{$s}{type} eq '(:=)' ) {
            $late{$s} = $definitions{$s};
        }
        else {
            confess "Something went wrong: We parsed an invalid "
              . "operator type '"
              . $definitions{$s}{type}
              . "' for "
              . "symbol '$s'";
        }
    }

    # Implement early replace dependencies
    my @pairs;
    foreach my $s ( keys %early ) {
        my @sig = $early{$s}{parsed}->explicit_signature();
        foreach (@sig) {

            # Exclude the late and external dependencies
            next if not exists $early{$_};
            push @pairs, [ $_, $s ];
        }
    }
    my @sort = _topo_sort( \@pairs );

    # Detect cycles
    if ( @sort == 1 and not defined $sort[0] ) {
        confess "Detected cycle in definitions. Cannot do topological "
          . "sort";
    }

    # actually implement symbolic dependencies of early replaces
    foreach my $sym (@sort) {
        my $f   = $early{$sym}{parsed};
        my @sig = $f->explicit_signature();
        $f->implement(
            map { ( $_ => $early{$_}{parsed}->new() ) }
              grep { exists $early{$_} } @sig
        );

        $early{$sym}{parsed} = $f;
    }

    # apply derivatives
    foreach my $sym ( keys %early ) {
        my $f = $early{$sym}{parsed};
        $f = $f->simplify()->apply_derivatives()->simplify();
        if (   $f->contains_operator(U_P_DERIVATIVE)
            or $f->contains_operator(U_T_DERIVATIVE) )
        {
            confess "Could not apply all derivatives in function '$sym'.";
        }

        $early{$sym}{parsed} = $f;
    }

    # Implement late replace dependencies
    @pairs = ();
    foreach my $s ( keys %late ) {
        my @sig = $late{$s}{parsed}->explicit_signature();
        foreach (@sig) {

            # Die on dependencies on early replaced functions
            confess "Dependency on outer scope function '$_' "
              . "found in function '$s'."
              if exists $early{$_};

            # Exclude the external dependencies
            next if not exists $late{$_};
            push @pairs, [ $_, $s ];
        }
    }

    @sort = _topo_sort( \@pairs );

    # Detect cycles
    if ( @sort == 1 and not defined $sort[0] ) {
        confess "Detected cycle in definitions. Cannot do topological "
          . "sort";
    }

    # actually implement symbolic dependencies of late replaces
    foreach my $sym (@sort) {
        my $f   = $late{$sym}{parsed};
        my @sig = $f->explicit_signature();
        $f->implement(
            map { ( $_ => $late{$_}{parsed}->new() ) }
              grep { exists $late{$_} } @sig
        );
        $f = $f->simplify()->apply_derivatives()->simplify();
        $late{$sym}{parsed} = $f;
    }

    # apply derivatives
    foreach my $sym ( keys %late ) {
        my $f = $late{$sym}{parsed};
        $f = $f->simplify()->apply_derivatives()->simplify();
        if (   $f->contains_operator(U_P_DERIVATIVE)
            or $f->contains_operator(U_T_DERIVATIVE) )
        {
            confess "Could not apply all derivatives in function '$sym'.";
        }

        $late{$sym}{parsed} = $f;
    }

    # implement symbolic dependencies of early replaces on late replaces
    foreach my $s ( keys %early ) {
        $early{$s}{parsed}->implement(
            map { ( $_ => $late{$_}{parsed}->new() ) }
              keys %late
        );
    }

    # external dependencies, compilation and subs
    foreach my $obj (
        ( map { [ $_ => $early{$_} ] } keys %early ),
        ( map { [ $_ => $late{$_} ] } keys %late )
      )
    {
        my ( $sym, $h ) = @$obj;

        # don't compile anything with parens in the operator.
        next if $h->{type} =~ /^\(:?=\)$/;

        # external dependencies
        my @external = $h->{parsed}->explicit_signature();

        # actual arguments
        my @args =
          map  { "arg$_" }
          sort { $a <=> $b }
          map  { /^arg(\d+)$/; $1 }
          grep { /^arg\d+$/ } @external;
        my $highest = $args[-1];
        if ( not defined $highest or $highest eq '' ) {
            $highest = 0;
        }
        else {
            $highest =~ s/^arg(\d+)$/$1/;
        }

        # number of arguments.
        my $num_args = @args==0 ? 0 : $highest+1;

        # external sub calls
        my @real_external     = sort grep { $_ !~ /^arg\d+$/ } @external;
        my $num_real_external = @real_external;

        # This is where it gets really fancy!
        # ... and This is not the Right Way To Do It! FIXME!!!
        my $final_code = "sub {\n";
        $final_code .= "my \@args = \@_;\n" if $num_real_external;

        if (@args) {
          $final_code .= <<HERE;
if (\@_ < $highest+1) {
	cluck(
		"Warning: Math::SymbolicX::Inline compiled sub "
		."'${pkg}::${sym}'\nrequires $num_args argument(s) "
		."but received only " . scalar(\@_)
	);
}
if (grep {!defined} \@_[0..$highest]) {
	cluck(
		"Warning: Undefined value passed to '${pkg}::${sym}'"
	);
}
HERE
        }

        my $num_argsm1 = $num_args - 1;

        $final_code .= "local \@_[0..$num_argsm1+$num_real_external] = ("
          . join( ', ',
            @args ? ( map { "\$_[$_]" } 0..$highest ) : (),
            ( map { "${pkg}::$_(\@args)" } @real_external ) )
          . ");\n"
          if $num_real_external;

        my $vars = [ @args?(map {"arg$_"} 0..$highest):(), @real_external ];

        my ( $mcode, $trees );
        eval { ( $mcode, $trees ) = compile_to_code( $h->{parsed}, $vars ); };
        if ( $@ or not defined $mcode ) {
            confess "Could not compile Perl code for function " . "'$sym'.";
        }
        if ( defined $trees and @$trees ) {
            confess <<HERE;
Could not resolve all trees in Math::Symbolic expression. That means, the
compiler encountered operators that could not be compiled to Perl code.
These include derivatives, but those should usually be applied before
compilation. Details can be found in the Math::Symbolic::Compiler man-page.
The expression that should have been compiled is:
---
$code
---
HERE
        }
        $final_code .= $mcode . "\n};\n";

        # DEBUG OUTPUT
        # warn "$sym = $final_code\n\n";

        my $anon_sub = _make_sub($final_code);
        if ($@) {
            confess <<HERE;
Something went wrong compiling the code for '${pkg}::$sym'.
This was the source:
---
$code
---
And the cluttery generated code is:
---
$final_code
---
HERE
        }

        do {
            no strict;
            *{"${pkg}::${sym}"} = \&$anon_sub;
        };
    }
}

# create an anonymous sub in a clean environment.
sub _make_sub {
    return eval $_[0];
}

# Takes array of pairs as argument (1 pair: ['x', 'y'])
# returns topological sort
# returns undef in case of cycles
sub _topo_sort {
    my $pairs = shift;

    my %pairs;    # all pairs ($l, $r)
    my %npred;    # number of predecessors
    my %succ;     # list of successors

    foreach my $p (@$pairs) {
        my ( $l, $r ) = @$p;
        next if defined $pairs{$l}{$r};
        $pairs{$l}{$r}++;
        $npred{$l} += 0;
        ++$npred{$r};
        push @{ $succ{$l} }, $r;
    }

    # create a list of nodes without predecessors
    my @list = grep { !$npred{$_} } keys %npred;

    my @return;
    while (@list) {
        $_ = pop @list;
        push @return, $_;
        foreach my $child ( @{ $succ{$_} } ) {
            unshift @list, $child unless --$npred{$child};
        }
    }

    return (undef) if grep { $npred{$_} } keys %npred;
    return @return;
}

# Check the syntax of a definition
sub _check_syntax {
    my ( $definitions, $lastsymbol ) = @_;
    if ( defined $lastsymbol ) {
        my $parsed;
        eval {
            $parsed = parse_from_string( $definitions->{$lastsymbol}{code} );
        };
        if ($@) {
            confess "Parsing of Math::SymbolicX::Inline "
              . "section failed. Error:\n$@";
        }
        elsif ( not defined $parsed ) {
            my $t = $definitions->{$lastsymbol}{code};
            confess <<HERE;
Parsing of Math::SymbolicX::Inline section failed due to an unknown error.
The offending expression (for symbol '$lastsymbol') is:
---
$t
---
HERE
        }
        $definitions->{$lastsymbol}{parsed} = $parsed;
    }
}

1;
__END__

=head1 NAME

Math::SymbolicX::Inline - Inlined Math::Symbolic functions

=head1 SYNOPSIS

  use Math::SymbolicX::Inline <<'END';
  foo = x * bar
  bar = partial_derivative(x^2, x)
  x (:=) arg0 + 1
  END
  
  print bar(3);
  # prints '8' which is 2*(3+1)...
  
  print foo(3);
  # prints '32' which is 2*(3+1)*(3+1)
  
  print x(3);
  # Throws an error because the parenthesis around the operator make
  # the declaration of x private.

=head1 DESCRIPTION

This module is an extension to the Math::Symbolic module. A basic
familiarity with that module is required.

Math::SymbolicX::Inline allows easy creation of Perl functions from
symbolic expressions in the context of Math::Symbolic. That means
you can define arbitrary Math::Symbolic trees (including derivatives)
and let this module compile them to package subroutines.

There are relatively few syntax elements that aren't standard in
Math::Symbolic expressions, but those that exist are easier to
explain using examples. Thus, please refer to the discussion of
a simple example below.

=head2 EXPORT

This module does not export any functions, but its intended usage is
to create functions in the current namespace for you.

=head2 A SIMPLE EXAMPLE

A contrived sample usage would be to create a function that computes
the derivative of the square of the sine. You could do the math
yourself and find that the x-derivative of C<sin(x)*sin(x)> is
C<2*sin(x)*cos(x)>. On the other hand, you might want to change the
source function later or the derivative is very complicated or you
are just too lazy to do the math. Then you can write the following
code to do allow of this for you:

  use Math::SymbolicX::Inline <<'HERE';
  myfunction = partial_derivative( sin(arg0) * sin(arg0), arg0 )
  HERE

After that, you can use your appropriately named function from Perl.
This has almost no performance penalty compared to the version you
would write by hand since Math::Symbolic can compile trees to Perl
code. (You could, if you were crazy enough, compile it to C using
L<Math::Symbolic::Custom::CCompiler>.)

  print myfunction(2);

That would print C<-0.756802495307928>.

=head2 EXTENDED USAGE

You will have noticed the usage of the C<arg0> variable in the above
example. Rather unspectacularily, C<argX> refers to the X+1th argument
to the function. Thus, C<arg19> refers to the twentieth argument.

But it is atypical to use C<arg0> as a variable in a mathematical
expression. We want to use the names C<x> and C<y> to compute
the x-derivative of C<sin(x*y)*sin(x*y)>. Furthermore,
we want the sine to be exchangeable with a cosine with as little
effort as possible. That is rather simple to implement:

  my $function = 'sin';
  
  use Math::SymbolicX::Inline <<HERE;
  
  # Our function:
  myfunction = partial_derivative(inner, x)
  
  # Supportive declarations:
  inner (=) $function(x*y)^2
  x (:=) arg0
  y (:=) arg1
  HERE

This short piece of code adds three symbolic declarations. All of
these new declarations have their assignment operators enclosed in
parenthesis to signify that they are not to be exported. That means
you will not be able to call C<inner(2, 3)> afterwards. But you will
be able to call C<myfunction(2, 3)>. The variable $function is
interpolated into the HERE document. The manual pages that come with
Perl will tell you all the details about this kind of quoted string.

The declarations are relatively whitespace insensitive. All you need
to do is put a new declaration with the assignment operator on a new
line. It does not matter how man lines a single equation takes.
This is valid:

  myfunction =
               partial_derivative(
                                   inner, x
                                 )
  inner (=) $function(x*y)^2
  ...

Whereas this is not:

  myfunction
  = partial_derivative(inner, x)
  ...

It is relevant to note that the order of the declarations is
irrelevant. You could have written

  x (:=) arg0
  ...
  myfunction = partial_derivative(inner, x)

instead and you would have gotten the same result.

You can also remove any of the parenthesis around the assignment
operators to make the declared function accessible from your
Perl code.

You may have wondered about the C<:=> operator used in the
declaration of C<x> and C<y>. This operator is interesting
in the context of derivatives only. Say, you want to compute
the partial x-derivative of a function C<inner>. If you want to
be really correct about it, that derivative is C<0>! That's because
The term you are deriving (C<inner>) is - strictly speaking - 
not dependent on C<x>. You have to put the function definition
of C<inner> into place before deriving to get a sensible result.

Therefore, in general, you want to replace any usage of a function
with its definition in order to be able to derive it.

Now, this brings up another problem. If we do the same for C<x>, we
will have C<arg0> in its place and can't derive either. That's
where the C<:=> operator comes in. It replaces the function
B<after> the applying all derivatives.

The consequence of this is that you cannot reference a normal
function like C<inner> in the definitions for late-replace
functions like C<x>.

=head2 THE LAST BITS

All calls to functions that don't exist in the block of declarations
passed to Math::SymbolicX::Inline will be resolved to subroutine
calls in the current package. If the subroutines don't exist,
the module will throw an error with a stack backtrace.

=head1 SEE ALSO

New versions of this module can be found on http://steffen-mueller.net or CPAN.

L<Math::Symbolic>

L<Math::Symbolic::Compiler>, L<Math::Symbolic::Custom::CCompiler>

This module does not use the Inline module an thus is not in the
Inline:: hierarchy of modules. Nonetheless, similar modules usually
can be found in that hierarchy: L<Inline>

=head1 AUTHOR

Steffen Müller, E<lt>symbolic-module at steffen-mueller dot net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
