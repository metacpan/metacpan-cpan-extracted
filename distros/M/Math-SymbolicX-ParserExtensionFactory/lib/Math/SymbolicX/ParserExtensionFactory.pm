package Math::SymbolicX::ParserExtensionFactory;

use 5.006;
use strict;
use warnings;
use Carp;
use Math::Symbolic;
use Text::Balanced;

our $BeenUsedBefore    = {};
our $Functions         = {};
our $Order             = [];
our $RegularExpression = qr/(?!)/;

our $VERSION = '3.02';

sub import {
  my $package = shift;
  croak("Uneven number of arguments in usage of "
    . "Math::SymbolicX::ParserExtensionFactory")
    if @_ % 2;

  my %args = @_;

  _extend_parser();

  foreach my $key ( keys %args ) {
    croak("Invalid keys => value pairs as arguments in usage of "
      . "Math::SymbolicX::ParserExtensionFactory")
      if not ref( $args{$key} ) eq 'CODE';
    if ( not exists $Functions->{$key} ) {
      push @$Order, $key;
    }
    $Functions->{$key} = $args{$key};
  }

  $RegularExpression = _regenerate_regex($Order);

  return ();
}

sub _extend_parser {

  my $parser = shift;
  $parser = $Math::Symbolic::Parser if not defined $parser;

  # make sure there is a parser
  if (not defined $parser) {
    $parser = $Math::Symbolic::Parser = Math::Symbolic::Parser->new();
  }

  if ( not exists $BeenUsedBefore->{"$parser"} ) {
    if ($parser->isa('Parse::RecDescent')) {
      _extend_parser_recdescent($parser)
    }
    elsif ($parser->isa('Math::Symbolic::Parser::Yapp')) {
      _extend_parser_yapp($parser);
    }
    else {
      die "Unsupported parser type!";
    }
    $BeenUsedBefore->{"$parser"} = 1;
  }
}

sub _extend_parser_yapp {
  # This is a no-op since ::Parser::Yapp has built-in support for
  # ::ParserExtensionFactory. This would probably not be possible
  # otherwise.
  return(1);
}

sub _extend_parser_recdescent {
  my $parser = shift;
  $parser->{__PRIV_EXT_FUNC_REGEX} = qr/(?!)/;
  $parser->Extend(<<'EXTENSION');
function: /$thisparser->{__PRIV_EXT_FUNC_REGEX}\s*(?=\()/ {extract_bracketed($text, '(')}
  {
    warn 'function_private_msx_parser_extension_factory ' 
      if $Math::Symbolic::Parser::DEBUG;
    my $function = $item[1];
    $function =~ s/\s+$//;
    my $argstring = substr($item[2], 1, length($item[2])-2);
    die "Invalid extension function and/or arguments '$function$item[2]' ".
        "(Math::SymbolicX::ParserExtensionFactory)"
      if not exists
         $thisparser->{__PRIV_EXT_FUNCTIONS}{$function};
    my $result = $thisparser->{__PRIV_EXT_FUNCTIONS}{$function}->($argstring);
    die "Invalid result of extension function application "
        ."('$item[1]($argstring)'). Also refer to the "
        ."Math::SymbolicX::ParserExtensionFactory manpage."
      if ref($result) !~ /^Math::Symbolic/;
    $return = $result;
  }

  | /$Math::SymbolicX::ParserExtensionFactory::RegularExpression\s*(?=\()/ {extract_bracketed($text, '(')}
  {
    warn 'function_global_msx_parser_extension_factory ' 
      if $Math::Symbolic::Parser::DEBUG;
    my $function = $item[1];
    $function =~ s/\s+$//;
    my $argstring = substr($item[2], 1, length($item[2])-2);
    die "Invalid extension function and/or arguments '$function$item[2]' ".
        "(Math::SymbolicX::ParserExtensionFactory)"
      if not exists
         $Math::SymbolicX::ParserExtensionFactory::Functions->{$function};
    my $result = $Math::SymbolicX::ParserExtensionFactory::Functions->{$function}->($argstring);
    die "Invalid result of extension function application "
        ."('$item[1]($argstring)'). Also refer to the "
        ."Math::SymbolicX::ParserExtensionFactory manpage."
      if ref($result) !~ /^Math::Symbolic/;
    $return = $result;
  }

EXTENSION
  return(1);
}

sub _regenerate_regex {
  my @arrays = @_;
  my $string = join '|', map {"\Q$_\E"} map {@$_} @arrays;
  return qr/(?!)/ if $string eq '';
  return qr/(?:$string)/;
}

sub add_private_functions {
  shift if not ref $_[0] and $_[0] eq __PACKAGE__;
  my $parser = shift;
  croak("Invalid number of arguments!") if @_ % 2;

  $parser->{__PRIV_EXT_FUNCTIONS}  ||= {};
  $parser->{__PRIV_EXT_FUNC_ORDER} ||= [];
  while (@_) {
    my $name = shift;
    push @{$parser->{__PRIV_EXT_FUNC_ORDER}}, $name;
    $parser->{__PRIV_EXT_FUNCTIONS}{$name} = shift;
  }

  $parser->{__PRIV_EXT_FUNC_REGEX} = _regenerate_regex( $parser->{__PRIV_EXT_FUNC_ORDER} );
}

1;
__END__

=head1 NAME

Math::SymbolicX::ParserExtensionFactory - Generate parser extensions

=head1 SYNOPSIS

  use Math::Symbolic qw/parse_from_string/;
  
  # This will extend all parser objects in your program:
  use Math::SymbolicX::ParserExtensionFactory (
  
    functionname => sub {
      my $argumentstring = shift;
      my $result = construct_some_math_symbolic_tree( $argumentstring );
      return $result;
    },
  
    anotherfunction => sub {
      ...
    },
  
  );
  
  # ...
  # Later in your code
  
  my $formula = parse_from_string('variable * 4 * functionname(someargument)');
  
  # use $formula as a Math::Symbolic object.
  # Refer to Math::SymbolicX::BigNum (arbitrary precision arithmetic
  # support through the Math::Big* modules) or to
  # Math::SymbolicX::ComplexNumbers (complex number support) for examples.
  
  
  # Alternative: modify a single parser object only:
  my $parser = Math::Symbolic::Parser->new();
  
  Math::SymbolicX::ParserExtensionFactory->add_private_functions(
    $parser,
    fun_function => sub {...},
    my_function  => sub {...},
    ...
  );

=head1 DESCRIPTION

This module provides a simple way to extend the Math::Symbolic parser with
arbitrary functions that return any valid Math::Symbolic tree.
The return value of the function call is
inserted into the complete parse tree at the point at which the function
call is parsed. Familiarity with the Math::Symbolic module will be
assumed throughout the documentation.

This module is not object oriented. It does not export anything. You should
not call any subroutines directly nor should you modify any class data
directly. The complete interface is the call to
C<use Math::SymbolicX::ParserExtensionFactory> and its arguments. The reason
for the long module name is that you should not have to call it multiple times
in your code because it modifies the parser for good. It is intended to be
a pain to type. :-)

The aim of the module is to allow for hooks into the parser without modifying
the parser yourself because that requires rather in-depth knowledge of the
module code. By specifying key => value pairs of function names and
function implementations (code references) as arguments to the use() call
of the module, this module extends the parser that is stored in the
C<$Math::Symbolic::Parser> variable with the specified functions and whenever
"C<yourfunction(any argument string with balanced parenthesis)>" occurs
in the code, the subroutine reference is called with the argument string as
argument.

The subroutine is expected to return any Math::Symbolic tree. That means,
as of version 0.506 of Math::Symbolic, a Math::Symbolic::Operator, a
Math::Symbolic::Variable,
or a Math::Symbolic::Constant object. The returned object will be incorporated
into the Math::Symbolic tree that results from the parse at the exact position
at which the custom function call was parsed.

Please note that the usage of this module will be quite slow at compile time
because it has to regenerate the complete Math::Symbolic parser the first
time you use this module in your code. The run time performance penalty
should be low, however.

=head1 FUNCTIONS

=head2 add_private_functions

Callable as class method or function. First argument must be the parser
object to modify (either a Parse::RecDescent or a Parse::Yapp based
Math::Symbolic parser), followed by key/value pairs of function names
and code refs (implementations).

Modifies only the parser passed in as first argument. For an example,
see synopsis above.

=head1 CAVEATS

Since version 2.00 of this module, the old, broken parsing of the argument
string which would fail on nested, unescaped parenthesis was replaced
by a better routine which will correctly parse nested pairs of parenthesis.

On the flip side, if the argument string contains unmatched parenthesis,
the parse will fail. Examples:

  "myfunction(foo(bar)" # fails because missing closing parenthesis

Escaping of parenthesis in the argument string B<is no longer supported>.

=head1 AUTHOR

Copyright (C) 2003-2009 Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

You may contact the author at symbolic-module at steffen-mueller dot net

Please send feedback, bug reports, and support requests to the Math::Symbolic
support mailing list:
math-symbolic-support at lists dot sourceforge dot net. Please
consider letting us know how you use Math::Symbolic. Thank you.

If you're interested in helping with the development or extending the
module's functionality, please contact the developers' mailing list:
math-symbolic-develop at lists dot sourceforge dot net.

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN.

Also have a look at L<Math::Symbolic>,
and at L<Math::Symbolic::Parser>

Refer to L<Math::SymbolicX::BigNum> (arbitrary precision
arithmetic support through the Math::Big* modules) or to
L<Math::SymbolicX::ComplexNumbers> (complex number support) for examples.

=cut
