package FFI::TinyCC::Inline;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus;
use FFI::TinyCC;
use Carp qw( croak );
use base qw( Exporter );

our @EXPORT_OK = qw( tcc_inline tcc_eval );
our @EXPORT = @EXPORT_OK;

# ABSTRACT: Embed Tiny C code in your Perl program
our $VERSION = '0.24'; # VERSION


my $ffi = FFI::Platypus->new;
$ffi->load_custom_type( 'StringArray' => 'string_array' );

# TODO: support platypus types like pointers and arrays
my %typemap = (
  'int'            => 'int',
  'signed int'     => 'signed int',
  'unsigned int'   => 'unsigned int',
  'void'           => 'void',
  'short'          => 'short',
  'signed short'   => 'signed short',
  'unsigned short' => 'unsigned short',
  'long'           => 'long',
  'signed long'    => 'signed long',
  'unsigned long'  => 'unsigned long',
  'char'           => 'char',
  'signed char'    => 'signed char',
  'unsigned char'  => 'unsigned char',
  'float'          => 'float',
  'double'         => 'double',
  'char *'         => 'string',
);

sub _typemap ($)
{
  my($type) = @_;
  $type =~ s{^const }{};
  return $typemap{$type}
    if defined $typemap{$type};
  return 'opaque' if $type =~ /\*$/;
  croak "unknown type: $type";
}

sub _generate_sub ($$$)
{
  my($func_name, $func, $tcc) = @_;
  my $sub;
  
  my $address = $tcc->get_symbol($func_name);
  
  if(@{ $func->{arg_types} } == 2
  && $func->{arg_types}->[0] eq 'int'
  && $func->{arg_types}->[1] =~ /^(const |)char \*\*$/)
  {
    my $f = $ffi->function($address => ['int','string_array'] => _typemap $func->{return_type});
    $sub = sub {
      $f->call(scalar @_, \@_);
    };
  }
  else
  {
    my $f = $ffi->function($address => [map { _typemap $_ } @{ $func->{arg_types} }] => _typemap $func->{return_type});
    $sub = sub { $f->call(@_) };
  }
  
  $sub;
}


sub import
{
  my($class, @rest) = @_;
  
  if(defined $rest[0] && defined $rest[1]
  && $rest[0] eq 'options')
  {
    if($] >= 5.010)
    {
      shift @rest;
      $^H{"FFI::TinyCC::Inline/options"} = shift @rest;
    }
    else
    {
      croak "options not supported on Perl 5.8";
    }
  }
  
  return unless @rest > 0;

  @_ = ($class, @rest);
  goto &Exporter::import;
}


sub tcc_inline ($)
{
  my($code) = @_;
  my $caller = caller;
  
  my $tcc = FFI::TinyCC->new(_no_free_store => 1);
  
  my $h = (caller(0))[10];
  if($h->{"FFI::TinyCC::Inline/options"})
  { $tcc->set_options($h->{"FFI::TinyCC::Inline/options"}) }

  $tcc->compile_string($code);
  my $meta = FFI::TinyCC::Parser->extract_function_metadata($code);
  foreach my $func_name (keys %{ $meta->{functions} })
  {
    my $sub = _generate_sub($func_name, $meta->{functions}->{$func_name}, $tcc);
    no strict 'refs';
    *{join '::', $caller, $func_name} = $sub;
  }
  ();
}


sub tcc_eval ($;@)
{
  my($code, @args) = @_;
  my $tcc = FFI::TinyCC->new;
  
  my $h = (caller(0))[10];
  if($h->{"FFI::TinyCC::Inline/options"})
  { $tcc->set_options($h->{"FFI::TinyCC::Inline/options"}) }

  $tcc->compile_string($code);
  my $meta = FFI::TinyCC::Parser->extract_function_metadata($code);
  my $func = $meta->{functions}->{main};
  croak "no main function" unless defined $func;
  my $sub = _generate_sub('main', $meta->{functions}->{main}, $tcc);
  $sub->(@args);
}

package
  FFI::TinyCC::Parser;

# this parser code stolen shamelessly
# from XS::TCC, which I strongly suspect
# was itself shamelessly "borrowed"
# from Inline::C::Parser::RegExp

# Copyright 2002 Brian Ingerson
# Copyright 2008, 2010-2012 Sisyphus
# Copyright 2013 Steffen Muellero

# This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

use strict;
use warnings;

# These regular expressions were derived from Regexp::Common v0.01.
my $RE_comment_C   = q{(?:(?:\/\*)(?:(?:(?!\*\/)[\s\S])*)(?:\*\/))};
my $RE_comment_Cpp = q{(?:\/\*(?:(?!\*\/)[\s\S])*\*\/|\/\/[^\n]*\n)};
my $RE_quoted      = (q{(?:(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\")}
                     .q{|(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\'))});
my $RE_balanced_brackets;
$RE_balanced_brackets =
  qr'(?:[{]((?:(?>[^{}]+)|(??{$RE_balanced_brackets}))*)[}])';
my $RE_balanced_parens;
$RE_balanced_parens =
  qr'(?:[(]((?:(?>[^()]+)|(??{$RE_balanced_parens}))*)[)])';


sub _normalize_type {
  # Normalize a type for lookup in a typemap.
  my($type) = @_;

  # Remove "extern".
  # But keep "static", "inline", "typedef", etc,
  #  to cause desirable typemap misses.
  $type =~ s/\bextern\b//g;

  # Whitespace: only single spaces, none leading or trailing.
  $type =~ s/\s+/ /g;
  $type =~ s/^\s//; $type =~ s/\s$//;

  # Adjacent "derivative characters" are not separated by whitespace,
  # but _are_ separated from the adjoining text.
  # [ Is really only * (and not ()[]) needed??? ]
  $type =~ s/\*\s\*/\*\*/g;
  $type =~ s/(?<=[^ \*])\*/ \*/g;

  return $type;
}

sub extract_function_metadata {
  my (undef, $code) = @_;

  my $results = {
    function_names => [],
    functions => {},
  };

  # First, we crush out anything potentially confusing.
  # The order of these _does_ matter.
  $code =~ s/$RE_comment_C/ /go;
  $code =~ s/$RE_comment_Cpp/ /go;
  $code =~ s/^\#.*(\\\n.*)*//mgo;
  #$code =~ s/$RE_quoted/\"\"/go; # Buggy, if included.
  $code =~ s/$RE_balanced_brackets/{ }/go;

  # The decision of what is an acceptable declaration was originally
  # derived from Inline::C::grammar.pm version 0.30 (Inline 0.43).

  my $re_plausible_place_to_begin_a_declaration = qr {
    # The beginning of a line, possibly indented.
    # (Accepting indentation allows for C code to be aligned with
    #  its surrounding perl, and for backwards compatibility with
    #  Inline 0.43).
    (?m: ^ ) \s*
  }xo;

  # Instead of using \s , we dont tolerate blank lines.
  # This matches user expectation better than allowing arbitrary
  # vertical whitespace.
  my $sp = qr{[ \t]|\n(?![ \t]*\n)};

  my $re_type = qr {(
    (?: \w+ $sp* )+? # words
    (?: \*  $sp* )*  # stars
  )}xo;

  my $re_identifier = qr{ (\w+) $sp* }xo;
  while( $code =~ m{
          $re_plausible_place_to_begin_a_declaration
          ( $re_type $re_identifier $RE_balanced_parens $sp* (\;|\{) )
         }xgo)
  {
    my($type, $identifier, $args, $what) = ($2,$3,$4,$5);
    $args = "" if $args =~ /^\s+$/;

    my $need_threading_context = 0;
    my $is_decl     = $what eq ';';
    my $function    = $identifier;
    my $return_type = _normalize_type($type);
    my @arguments   = split ',', $args;

    #goto RESYNC if $is_decl && !$self->{data}{AUTOWRAP};
    goto RESYNC if exists $results->{functions}{$function};
    #goto RESYNC if !defined $self->{data}{typeconv}{valid_rtypes}{$return_type};

    my(@arg_names,@arg_types);
    my $dummy_name = 'arg1';

    my $argno = 0;
    foreach my $arg (@arguments) {
      # recognize threading context passing as part of first arg
      if ($argno++ == 0 and $arg =~ s/^\s*pTHX_?\s*//) {
        $need_threading_context = 1;
        next if $arg !~ /\S/;
      }

      my $arg_no_space = $arg;
      $arg_no_space =~ s/\s+//g;

      # If $arg_no_space is 'void', there will be no identifier.
      if( my($type, $identifier) =
          $arg =~ /^\s*$re_type(?:$re_identifier)?\s*$/o )
      {
        my $arg_name = $identifier;
        my $arg_type = _normalize_type($type);

        if((!defined $arg_name) && ($arg_no_space ne 'void')) {
          goto RESYNC if !$is_decl;
          $arg_name = $dummy_name++;
        }
        #goto RESYNC if ((!defined
        #    $self->{data}{typeconv}{valid_types}{$arg_type}) && ($arg_no_space ne 'void'));

        # Push $arg_name onto @arg_names iff it's defined. Otherwise ($arg_no_space
        # was 'void'), push the empty string onto @arg_names (to avoid uninitialized
        # warnings emanating from C.pm).
        defined($arg_name) ? push(@arg_names,$arg_name)
                           : push(@arg_names, '');
        if($arg_name) {push(@arg_types,$arg_type)}
        else {push(@arg_types,'')} # $arg_no_space was 'void' - this push() avoids 'uninitialized' warnings from C.pm
      }
      elsif($arg =~ /^\s*\.\.\.\s*$/) {
        push(@arg_names,'...');
        push(@arg_types,'...');
      }
      else {
        goto RESYNC;
      }
    }

    # Commit.
    push @{$results->{function_names}}, $function;
    $results->{functions}{$function}{return_type}= $return_type;
    $results->{functions}{$function}{arg_names} = [@arg_names];
    $results->{functions}{$function}{arg_types} = [@arg_types];
    $results->{functions}{$function}{need_threading_context} = $need_threading_context if $need_threading_context;

    next;

RESYNC:  # Skip the rest of the current line, and continue.
    $code =~ /\G[^\n]*\n/gc;
  }

  return $results;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::TinyCC::Inline - Embed Tiny C code in your Perl program

=head1 VERSION

version 0.24

=head1 SYNOPSIS

 use FFI::TinyCC::Inline qw( tcc_inline );
 
 tcc_inline q{
   int square(int num)
   {
     return num*num;
   }
 };
 
 print square(4), "\n"; # prints 16

 use FFI::TinyCC::Inline qw( tcc_eval );
 
 # sets value to 6:
 my $value = tcc_eval q{
   int main(int a, int b, int c)
   {
     return a + b + c;
   }
 }, 1, 2, 3;

=head1 DESCRIPTION

This module provides a simplified interface to FFI::TinyCC, that allows you
to write Perl subs in C.  It is inspired by L<XS::TCC>, but it uses L<FFI::Platypus>
to create bindings instead of XS.

=head1 OPTIONS

[requires Perl 5.10.0 or better]

You can specify Tiny C options using the scoped pragmata, like so:

 use FFI::TinyCC::Inline options => "-I/foo/include -L/foo/lib -DFOO=1";
 
 # prints 1
 print tcc_eval q{
 #include <foo.h> /* will search /foo/include
 int main()
 {
   return FOO; /* defined and set to 1 */
 }
 };

=head1 FUNCTIONS

=head2 tcc_inline

 tcc_inline $c_code;

Compile the given C code using Tiny C and inject any functions found into the
current package.  An exception will be thrown if the code fails to compile, or if
L<FFI::TinyCC::Inline> does not recognize one of the argument or return
types.

 tcc_inline q{
   int foo(int a, int b, int c)
   {
     return a + b + c;
   }
 };
 
 print foo(1,2,3), "\n"; # prints 6

The special argument type of C<(int argc, char **argv)> is recognized and
will be translated from the list of arguments passed in.  Example:

 tcc_inline q{
   void foo(int argc, const char **argv)
   {
     int i;
     for(i=0; i<argc; i++)
     {
       puts(argv[i]);
     } 
   }
 };
 
 foo("one", "two", "three"); # prints "one\ntwo\nthree\n"

=head2 tcc_eval

 tcc_eval $c_code, @arguments;

This compiles the C code and executes the C<main> function, passing in the given arguments.
Returns the result.

=head1 SEE ALSO

=over 4

=item L<FFI::TinyCC>

=item L<C::Blocks>

=back

=head1 BUNDLED SOFTWARE

This package also comes with a parser that was shamelessly stolen from L<XS::TCC>,
which I strongly suspect was itself shamelessly "borrowed" from 
L<Inline::C::Parser::RegExp>

The license details for the parser are:

Copyright 2002 Brian Ingerson
Copyright 2008, 2010-2012 Sisyphus
Copyright 2013 Steffen Muellero

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

aero

Dylan Cali (calid)

pipcet

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
