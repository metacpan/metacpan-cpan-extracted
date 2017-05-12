
# See the POD documentation at the end of this
# document for detailed copyright information.
# (c) 2002-2006 Steffen Mueller, all rights reserved.

package Math::Project3D::Function;

use strict;
use warnings;
use vars qw/$VERSION/;

$VERSION = 1.02;

use Carp;


# Uncreatively named public class method "new"
# 
# One of three syntaxes may be used:
# new(coderefs)
# new(param_names, expressions)
# new(param_names, expressions_and_coderefs_mixed)
# Returns a compiled anonymous subroutine

sub new {
   my @components = @_;

   # 'tis a class method after all, so remove the
   # class name if necessary.
   shift @components if $components[0] eq __PACKAGE__;

   # Check for the existance of plaintext components
   my $has_uncompiled_components = 0;
   foreach my $component (@components) {
      $has_uncompiled_components++, last
        if ref $component ne 'CODE';
   }

   my $function;

   # Call another subroutine to do the dirty work of
   # compiling plaintext expressions if necessary.
   if ($has_uncompiled_components) {
      my $param_names = shift @components;
      $function = _from_uncompiled_components($param_names, \@components);
   } else {

      # Have the function return whatever the applied components
      # return. @components is accessible because
      # the function in $function is a closure.
      $function = sub {
         return map { $_->(@_) } @components;
      };
   }

   return $function;
}


# internal subroutine _from_uncompiled_components
# 
# Does the dirty work of compiling plaintext expressions.
# Ugly. Very Ugly.
# Takes a string of parameter names (without dollar)
# separated by commas and an array reference to an
# array of components as arguments.
# Returns compiled function (anon sub).

sub _from_uncompiled_components {
   # parameter names separated by commas
   my @param_names = split /,/, shift;
   my $components  = shift;

   # This var will hold the plaintext of the function we will compile
   # later.
   my $function_string   = "sub {\n";

   # For all declared parameter names, alias the n-th function
   # argument to a lexical of the n-th name.
   for (my $param_no = 0; $param_no < @param_names; $param_no++ ) {
      $function_string   .= "   my \$$param_names[$param_no] = \$_[$param_no];\n";
   }

   # Return results of the applied component functions or expressions.
   $function_string   .= "   return ";

   my $component_count = 0;

   foreach my $component (@$components) {

      if (ref $component eq 'CODE') {

         # We're a coderef. Run the anon sub associated with this
         # component number and supply it with all function args.
         $function_string .= "\$components[$component_count]->(\@_), ";

      } else {

         # We're a plaintext expression. Insert it, but wrap a
         # "scalar()" around it to prevent expressions like "x,y"
         # from screwing up the order of return values.
         $function_string .= "scalar($component), ";

      }

      $component_count++;

   }

   $function_string .= "\n};";
   
   # Call yet another subroutine to make sure the number
   # of lexicals in scope is minimal.
   return _compile_function($components, $function_string);
}


# Evil evaluator subroutine _compile_function
# 
# Takes an array ref of components and a function_string
# as arguments.
# Returns compiled function or croaks about evaluation errors.

sub _compile_function {

   # We want an array for speed. Dereferencing every time is
   # quite a bit slow IIRC.
   # This array will be accessed by the function (closure) in
   # order to call the precompiled component functions.
   my @components = @{+shift(@_)};

   # Do it. Mwaha.
   my $function = eval shift;
   croak $@ if $@;

   # All went well.
   return $function;
}



1;

__END__

=pod

=head1 NAME

Math::Project3D::Function -
Generate anonymous subroutines for use as functions with Math::Project3D

=head1 SYNOPSIS

  use Math::Project3D;
  
  # Looks like a screw
  my $function = Math::Project3D->new_function(
    'u,v',     # list of parameter names
    '$u',      # first component
    'sin($v)', # more components
    'cos($v)',
  );
  
  # or as an anonymous sub / closure!
  {
      # This is a sphere
      my $radius = 5;

      my $x_component = sub {
          my $theta = shift;
          my $phi   = shift;
          return $radius * sin($theta) * cos($phi);
      };
      my $y_component = sub {
          my $theta = shift;
          my $phi   = shift;
          return $radius * sin($theta) * sin($phi);
      };
      my $z_component = sub {
          my $theta = shift;
          return $radius * cos($theta);
      };
      
      $function = Math::Project3D->new_function(
        $x_component, $y_component, $z_component         
      );
  }

=head1 DESCRIPTION

This package contains the code for generating anonymous subroutines
for use as functions with the Math::Project3D module. The package
has no public subroutines and you should use it indirectly through
the C<new_function> method of Math::Project3D.

Oh, yes, I almost forgot. I<Do not read the source>. :-)

=head1 METHODS

Public methods

=head2 new

The C<new> method takes exactly the same arguments as the C<new_function>
method of L<Math::Project3D>.

It returns a new Math::Project3D::Function object.

=head1 AUTHOR

Steffen Mueller, mail at steffen-mueller dot net

=head1 COPYRIGHT

Copyright (c) 2002-2006 Steffen Mueller. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Math::Project3D>

=cut

