package FFI::Platypus::Type::Enum;

use strict;
use warnings;
use constant 1.32 ();
use 5.008001;
use Ref::Util qw( is_plain_arrayref is_plain_hashref is_ref );
use Carp qw( croak );

# ABSTRACT: Custom platypus type for dealing with C enumerated types
our $VERSION = '0.04'; # VERSION


our @CARP_NOT = qw( FFI::Platypus );

sub ffi_custom_type_api_1
{
  my %config = defined $_[2] && is_plain_hashref $_[2]
    ? %{ splice(@_, 2, 1) }
    : ();
  my(undef, undef, @values) = @_;

  my $index = 0;
  my %str_lookup;
  my %int_lookup;
  my $prefix = defined $config{prefix} ? $config{prefix} : '';
  $config{rev} ||= 'str';
  ($config{rev} =~ /^(int|str)$/) or croak("rev must be either 'int', or 'str'");

  foreach my $value (@values)
  {
    my $name;
    my @aliases;

    if(is_plain_arrayref $value)
    {
      my %opt;
      if(@$value % 2)
      {
        ($name,%opt) = @$value;
      }
      else
      {
        ($name,$index,%opt) = @$value;
      }
      @aliases = @{ delete $opt{alias} || [] };
      croak("unrecognized options: @{[ sort keys %opt ]}") if %opt;
    }
    elsif(!is_ref $value)
    {
      $name = $value;
    }
    else
    {
      croak("not a array ref or scalar: $value");
    }

    if($index < 0)
    {
      $config{type} ||= 'senum';
    }

    if(my $package = $config{package})
    {
      foreach my $name ($name,@aliases)
      {
        my $full = join '::', $package, $prefix . uc($name);
        constant->import($full, $index);
      }
    }

    croak("$name declared twice") if exists $str_lookup{$name};

    $int_lookup{$index} = $name unless exists $int_lookup{$index};
    $str_lookup{$_}     = $index for @aliases;
    $str_lookup{$name}  = $index++;
  }

  $config{type} ||= 'enum';

  if(defined $config{maps})
  {
    if(is_plain_arrayref $config{maps})
    {
      @{ $config{maps} } = (\%str_lookup, \%int_lookup, $config{type});
    }
    else
    {
      croak("maps is not an array reference");
    }
  }

  my %type = (
    native_type    => $config{type},
    perl_to_native => sub {
      exists $str_lookup{$_[0]}
        ? $str_lookup{$_[0]}
        : exists $int_lookup{$_[0]}
          ? $_[0]
          : croak("illegal enum value $_[0]");
    },
  );

  unless($config{rev} eq 'int')
  {
    $type{native_to_perl} = sub {
      exists $int_lookup{$_[0]}
        ? $int_lookup{$_[0]}
        : $_[0];
    }
  }

  \%type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Type::Enum - Custom platypus type for dealing with C enumerated types

=head1 VERSION

version 0.04

=head1 SYNOPSIS

C:

 enum {
   DEFAULT,
   BETTER,
   BEST = 12
 } foo_t;
 
 foo_t
 f(foo_t arg)
 {
   return foo_t;
 }

Perl with strings:

 use FFI::Platypus 1.00;
 my $ffi = FFI::Platypus->new( api => 1 );
 
 $ffi->load_custom_type('::Enum', 'foo_t',
   'default',
   'better',
   ['best' => 12],
 );
 
 $ffi->attach( f => ['foo_t'] => 'foo_t' );
 
 f("default") eq 'default';  # true
 f("default") eq 'better';   # false
 
 print f("default"), "\n";   # default
 print f("better"),  "\n";   # better
 print f("best"),    "\n";   # best

Perl with constants:

 use FFI::Platypus 1.00;
 my $ffi = FFI::Platypus->new( api => 1 );
 
 $ffi->load_custom_type('::Enum', 'foo_t',
   { rev => 'int', package => 'Foo', prefix => 'FOO_' },
   'default',
   'better',
   ['best' => 12],
 );
 
 $ffi->attach( f => ['foo_t'] => 'foo_t' );
 
 f(Foo::FOO_DEFAULT) == Foo::FOO_DEFAULT;   # true
 f(Foo::FOO_DEFAULT) == Foo::FOO_BETTER;    # false

=head1 DESCRIPTION

This type plugin is a helper for making enumerated types.  It makes the most sense
to use this when you have an enumerated type with a small number of possible values.
For a large set of enumerated values or constants, see L<FFI::Platypus::Constant>.

This type plugin has two modes:

=over 4

=item string

In string mode, string representations of the enum values are converted into
the integer enum values when passed into C, and the enums are converted back
into strings when coming from C back into Perl.  You can also pass in the
integer values.

=item constant

In constant mode, constants are defined in the specified package, and with
the optional prefix.  The string representation or integer constants can
be passed into C, but the integer constants are returned from C back into
Perl.

=back

In both modes, if you attempt to pass in a value that isn't one of the possible
enum values, an exception will be thrown.

=head1 OPTIONS

The general form of the custom type load is:

 $ffi->load_custom_type('::Enum', $name, \%options, @values);
 $ffi->load_custom_type('::Enum', $name, @values);

The enumerated values are specified as a list of strings and array references.

=over 4

=item string

 $ffi->load_custom_type('::Enum', $name, $string1, $string2, ... );

For strings the constant value starts at zero (0) and increases by one for each
possible value.

=item array reference

 $ffi->load_custom_type('::Enum', $name, [ $value_name, $value, %options ]);
 $ffi->load_custom_type('::Enum', $name, [ $value_name, %options ]);

You can use an array reference to include an explicit integer value, rather
than using the implicit incremented value.  You can also use the array
reference for value options.  If the value isn't included (that is if
there are an odd number of values in the array reference), then the
implicit incremented value will be used.

Value options:

=over 4

=item alias

 $ffi->load_custom_type('::Enum, $name, [ $value_name, $value, alias => \@aliases ]);
 $ffi->load_custom_type('::Enum, $name, [ $value_name, alias => \@aliases ]);

The C<alias> option lets you specify value aliases.  For example, suppose you have
an enum definition like:

 enum {
   FOO,
   BAR,
   BAZ=BAR,
   ABC,
   XYZ
 } foo_t;

The Perl definition would be:

 $ffi->load_custom_type('::Enum', 'foo_t',
   'foo',
   ['bar', alias => ['baz']],
   'abc',
   'xyz',
 );

=back

=back

Type options may be passed in as a hash reference after the type name.

Type options:

=over 4

=item maps

 my @maps;
 $ffi->load_custom_type('::Enum', $name, { maps => \@maps }, ... );
 my($str,$int,$type) = @maps;

If set to an empty array reference, this will be filled with the string, integer
and native type for the enum.

=item package

 $ffi->load_custom_type('::Enum', $name, { package => $package }, ... );

This option specifies the Perl package where constants will be defined.
If not specified, then not constants will be generated.  As per the usual
convention, the constants will be the upper case of the value names.

=item prefix

 $ffi->load_custom_type('::Enum', $name, { prefix => $prefix }, ... );

This specifies an optional prefix to give each constant.  If not specified,
then no prefix will be used.

=item rev

 $ffi->load_custom_type('::Enum', $name, { rev => 'int' }, ... );
 $ffi->load_custom_type('::Enum', $name, { rev => 'str' }, ... );

This specifies what should be returned for C functions that return the
enumerated type.  For strings, use C<str>, and for integer constants
use C<int>.

(C<rev> is short for "reverse")

=item type

 $ffi->load_custom_type('::Enum', $name, { type => $type }, ... );

This specifies the integer type that should be used for the enumerated
type.  The default is to use C<enum> for types that only have positive
possible values and C<senum> for types that have possible negative values.
(Note that on some platforms these two types may actually be the same).

You can also use other integer types, which is useful if the enum is
only used to define constants, and the values are stored in a type
smaller than the default for C<enum> or C<senum>.  For example:

C:

 enum {
   DEFAULT,
   BETTER,
   BEST = 12
 } foo_enum;
 typedef uint8_t foo_t;
 
 /*
  * you are expected to use the constants from foo_enum,
  * but the signature actually uses a uint8_t
  */
 void f(foo_t);

Perl:

 $ffi->load_custom_type('::Enum', 'foo_t',
   { type => 'uint8' },
   'default',
   'better',
   [best => 12],
 );
 
 $ffi->attach( f => [ 'foo_t' ] => 'void' );

=back

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=item L<FFI::C>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
