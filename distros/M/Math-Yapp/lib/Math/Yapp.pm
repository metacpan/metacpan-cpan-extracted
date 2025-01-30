# Package: Math::Yapp.pm: Yet another Polynomial Package
#
package Math::Yapp;

use overload
  '+'   => Yapp_add,
  '+='  => Yapp_plus,
  '!'   => Yapp_negate,       # Negate
  '-'   => Yapp_sub,
  '-='  => Yapp_minus,
  '*'   => Yapp_times,
  '*='  => Yapp_mult,
  '/'   => Yapp_dividedby,
  '/='  => Yapp_divide,
  '~'   => Yapp_conj,       # Conjugate complex coefficients
  '**'  => Yapp_power,      # Raise a polynomial to an integer power
  '.'   => Yapp_innerProd   # Inner product, for vector operations.
;

# use 5.014002;         # Let's not tie ourselves to a release.
use strict;
use warnings;
use Carp;
use Math::Complex;
#use Math::BigFloat;        # Needed for accuracy(), though I don't do
#                           # anything with that yet.
use Storable 'dclone';
use Data::Dumper;               # For debugging
use Scalar::Util qw(refaddr);   # Gets pointer values. Also for debugging.

require Exporter;

our @ISA = ('Exporter');

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration   use Math::Yapp ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#
our %EXPORT_TAGS = ( 'all' => [ qw(Yapp Yapp_decimals Yapp_print0
                                   Yapp_start_high) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#our @EXPORT = qw(all);
our @EXPORT = qw(Yapp Yapp_interpolate Yapp_by_roots
                 Yapp_testmode
                 Yapp_decimals Yapp_print0 Yapp_start_high Yapp_margin
                 Yapp_Orthogonal
                 Csprint); # Unexport Csprint after debug

our $VERSION = '1.08';
#
my $class_name = "Math::Yapp";  # So I don't have to use the literal in tests
my $class_cplx = "Math::Complex";   # Same idea - avoid literal use

# Here are the patterns I need to validate and parse the terms of a polynomial:
# They will be used by str2yapp() and str2cplx()
#
my $sign_pat = qr/[+-]/;        # Allows me to isolate the optional sign

# Combine integer_pat and decimal_pat for real_pat
#
my $integer_pat = qr/\d+/;      # Integer is one or more digits
my $decimal_pat = qr/\.\d+/;    # Decimal: A period followed by digits
my $decnum_pat  = qr/($integer_pat)($decimal_pat)/; # Complete decimal number

# A real number may be:
# - An integer /\d+/
# - A pure decimal number: /\.\d+/
# - An integer followd by a pure decimal i.e. a complete decimal number
# I am checking these in reverse of above order, testing for the more
# complicated pattern first.
# Of course, all the above may be preceeded by an optinal sign
#
my $real_pat = qr/(($decnum_pat)|($decimal_pat)|($integer_pat))/;

my $cplx_pat = qr/\([+-]?$real_pat[+-]($real_pat)i\)/; # Cplx: (+-real+-real-i)

# Now a coefficient is a real or complex number at the beginning of a term,
# optionally preceeded by a sign.  If sign is omitted we will assume positive.
# On the other hand, it may be an implicit 1 with only a sign.  Hence, both
# parts are basically optional; if omitted e.g. x^31, then coefficient is +1
#
# As to a regex pattern: A coefficient is at the start of the term and
# may be:
# - A sign alone => an implicit coefficient of 1.0        ($sign_only_pat)
# - A complex or real number alone => implicit sign of +1 ($usigned_coef_pat)
# - A real or complex number preceded by a sign.          ($signed_coef_pat)
# The proper pattern tests for the most complicated possibility first
#
my $signed_real_pat  = qr/^(($sign_pat)?($real_pat))$/;
my $signed_coef_pat  = qr/((^$sign_pat)(($cplx_pat)|($real_pat)))/;
my $usigned_coef_pat = qr/^(($cplx_pat)|($real_pat))/;
my $sign_only_pat    = qr/(^$sign_pat)/;
my $coef_pat = qr/($signed_coef_pat)|($usigned_coef_pat)|($sign_only_pat)/;

my $varia_pat = qr/[A-Za-z]+/;  # The "variable" part of the term
my $power_pat = qr/\^\d+$/;     # Power: caret (^) followed by am integer.
                                # Must be at the end of the term
#
# With apologies: This is a patch to fix a bug in Ysprint(): It was printing
# the 0-term as <coefficient>X^0 when formatting starting at low-degree terms.
# This will help get rid of that.
#
my $zero_power_pat = qr/($varia_pat)(\^0)$/;

my $const_pat = qr/^$coef_pat$/; # Coefficient only; no variable or exponent

# Now that I have defined the patterns for the parts of a term, I can define
# the pattern for a complete term.  Each part is optional.
#
my $term_pat = qr/($coef_pat)?($varia_pat)?($power_pat)?/;

# However, one pattern not allowed is a $power_pat (exponent) without a
# variable.  Since, at the moment, I cannot think of a regex to test for
# this condition, I'll have to handle it in the code.  (Sigh)

# Format strings for printf-ing the terms of the polynomial.
# First: For a real coefficient: Assume the data to printf includes:
# - Width of the coefficient, including decimal point and decimal places
# - Number of decimal places alone
# - The coeficient, a floating point number
# - The variable string (like X, Z, GIZORP etc.) This is omitted for the
#   constant term
# - The exponent (Omitted for the constant term of the polynomial)
#
my $zero_term_fmt  = "%+*.*f";      # No X term in here
my $one_term_fmt   = "%+*.*f%s";    # For 1st degree term, omit the exponent
my $term_fmt       = "%+*.*f%s^%d"; # For other terms, always use sign
my $first_term_fmt = "%*.*f%s^%d";  # For first term, skip + for first if
                                    # it is positive anyway
# Now for a complex coefficient: Here format gets a bit more, er, complex;
# Each term includes the following in the data portion of printf:
# - Width of the real part of the coeficient
# - Number of decimal places in the real part
# - The real part itself
# - Width of the imaginary part of the coeficient
# - Number of decimal places in the imaginary part
# - The imaginary part itself
# - The variable string (Omitted in the constant term)
# - The exponent (Omitted in the constant term)
#
my $zero_term_fmt_i = "+(%*.*f%+*.*fi)";     # No variable or exponent
my $one_term_fmt_i  = "+(%*.*f%+*.*fi)%s";   # +(Re+/-Im_i)X Variable, no
                                             # exponent
my $term_fmt_i      = "+(%*.*f%+*.*fi)%s^%d";# Sign, Variable, exponent
my $first_term_fmt_i = "(%*.*f%+*.*fi)%s^%d";# No sign but variable and
                                             # exponent
# Some other constants I need for this module, before starting the work in
# earnest:
#
our $czero = Math::Complex->make(0,0);      # Complex zero
our $inner_prod = "(generic)";  # Default inner product type; set with
                                # inner_prod()
# These globals control behavior of Ysprint.  Changed by indicated functions
our $dec_places  = 3;   # Can be changed with call to Yapp_decimals()
our $dec_width = 4;     # Minimum width: 4, with 3 decimal paces
our $print_zero = 0;    # Default: FALSE: Skip zero-coefficient terms
                        # Changed by Yapp_print0()
our $start_high = 1;    # Default: True: Start printing from high-degree terms.
                        # If FALSE, start from low-degree terms. Set by
                        # Yapp_start_high()
our $margin = 1/(10**10);   # What is close enough to ignore rounding error?
#our $margin = 1/(10**8);    # What is close enough to ignore rounding error?
our $testmode = 0;      # Turned on by class method Yapp_testmode()

BEGIN
{
 #Math::BigFloat->accuracy(32);   # In case I decide on a way to use complex
                                  # numbers with BigFloat
 #$DB::simple = 1;                #### Comment out after debugging
}
#
#------------------------------------------------------------------------------
# Class setting functions: These functions set [semi] global variables used
# only by other function this package.
#------------------------------------------------------------------------------
# Yapp_testmode() Turns on or off the semi-global variable $testmode.
# This is not a class method - it is a straightforward function call.
#
sub Yapp_testmode
{
  $testmode = $_[0] if (defined($_[0]));    # Set the variable, if user sent
                                            # a value to stick in there
  return $testmode;
}
#------------------------------------------------------------------------------
# Yapp_margin(): Set the threshold for how close to require something be to
# a solution in order to be considered close enough.  This sets the variable
# $margin, whcih is set to 1.0/(10.0 ** 10). It is intended to compensate
# for inevitable rounding errors that, for example, make a real number look
# like a complex number with a really tiny imaginary part (like 1.23456e-15i).
# Parameter:
# - (Optional) The floating point value to be the closeness factor.
# Returns:
# - The current (or new) setting for this margin.
#
sub Yapp_margin
{ # If caller passed a parameter, use it.  If not, just get the current setting
  #
  my $new_margin = (defined($_[0])) ? $_[0] : $margin;
  $margin = $new_margin;        # May be wasted but checking if different
                                # also costs.
  return $margin;
}
#------------------------------------------------------------------------------
# dec_places(): Set or retrieve the precision to be used when
# printing coefficients of the polynomial.  Default is 3.
# - To set precision:
#   yapp_ref->dec_places(17);           # Set output precision of 17 decimal
#                                       # places to the right of the point,
#   Math::Yapp->dec_places(17);        # Will have the same effect.
#
# - To retrieve it:
#   $int_var = jpoly_ref->dec_places();
# In both cases, it returns the precision to the caller.
#
sub dec_places
{
  my $self = shift(@_);
  if (@_ != 0)                  # Passed a parameter
  {
    $dec_places = $_[0];            # Set the number of places to that
    $dec_width  = $dec_places + 1;  # Add 1 place for decimal point. (Probably
                                    # not needed but cleaner logic)
  }
  return $dec_places;           # Either way, that's the return value
}
#
#------------------------------------------------------------------------------
sub Yapp_decimals
{                               # (Replaces dec_places method)
  if (defined($_[0]))           # If user passed a parameter
  {
    $dec_places = $_[0];            # Set global decimal places for printf()
    $dec_width  = $dec_places + 1;  # Add 1 place for decimal point. (Probably
  }                                 # not needed but cleaner logic)
# else                          # No parameter; just want to know it
# { }                           # (Nothing really; just a placeholder
  return $dec_places;           # Either way, send that back to caller
}
#------------------------------------------------------------------------------
# Yapp_print0(): Function to dictate if Ysprint will print terms with 0
# coefficient.
# Parameters:
# - (Optional) 1 (TRUE) or 0 (FALSE)
#   If called w/no parameter, just returns the current value
# Returns:
# The current or newley set value.
sub Yapp_print0
{
  if (defined($_[0])) {$print_zero = $_[0]; }
  return $print_zero;
}
#------------------------------------------------------------------------------
# Yapp_start_high() - Sets $start_high to 0 or 1, or just returns that value.
# This decides if Ysprint will generate output starting from high-degree
# terms (default) or start low and work its way up in degree.
#
sub Yapp_start_high
{
  if (defined($_[0])) {$start_high = $_[0]; }
  return $start_high;
}
#
#------------------------------------------------------------------------------
# Constructors:
#------------------------------------------------------------------------------
# Math::Yapp::new(): Create a new polynomial#
# This method is heavily overloaded but it alwys returns the same type: a
# reference to a Yapp polynomial object.  It will accept the following
# parameters:
# - Nothing; It returns a degenerate polynomial with no coefficients of
#   degree, the equivalent of a NULL polynomial.
# - A list of numbers, real or complex. The first number is the 0-degree
#   coefficient and the last, [n], is the coefficient of the highest-degree
#   term.
# - A reference to a list of numbers i.e. \@list.  THis list is identical
#   to the explicit list described above.
# - A string in the form nnnX^m1 + nnnX^m2 .. etc.
#
# A note about complex coefficients:
# - In the string-form parameter, it must be in the form +-(REAL+-IMAGi)
# - In the list (or list-reference) form, a complex may be of the above
#   string form or a true complex object, as returned by Math::Complex
#
sub new
{
  my $class = shift(@_);    # Get class name out of the way
  my $self = {};            # Create new entity
  bless $self;              # Makes it an object
  my $lc;                   # Loop counter (general purpose here)

  $self->{degree} = 0;      # Initially IS a 0-degree polynomial
  $self->{variable} = "X";  # For printing, use this variable.  Can be set
  $self->{coeff}[0] = 0;    # Even a degenerate polynomial needs a coefficient
                            # to any string using the method variable()
  my $aref = 0;             # Will step through one array or another
  my $coef_count = @_;      # How many coefficients were passed to me?

  if ($coef_count > 1)      # If caller passed me a list of numbers
  { $aref = \@_; }          # Point to the parameter list, save for soon
  elsif ($coef_count == 1)  # Passed only one parameter: Our possibilities:
  {
    if (ref($_[0]) eq "ARRAY")  # I got a reference to a list
    { $aref = shift(@_); }      # Reference that list with same $aref
    else                        # Next possibility: The parameter is a string
    { $self->str2yapp($_[0]); } # Turn the string into a polynomial
  }
  # Remaining possibility: That $coef_count == 0 and user wants that degenerate
  # polynommial.  Do nothing for now; Will return a zero polynomial
  #
  if ($aref != 0)           # If we have an array pointer
  {                         # step through the array to build the polynomial
    $self->{degree} = -1;   # Degree shall end up 1 less than count of terms
    for ($lc = 0; $lc <= $#{$aref}; $lc++)  # Build array of coefficients
    {
      # Note: I am adding the 0.0 to force Perl to store the value as a
      # number (real or ref(complex))
      #
      $self->{coeff}[$lc] = $aref->[$lc] + 0.0; # Use next number on list
      $self->{degree}++;                        # Don't lose track of degree
    }
  }

  $self->refresh();         # Last minute bookkeeping on our new object
  return $self;             # See? Even the empty object gets passed back
}
#
#------------------------------------------------------------------------------
# A neater version of calling new() - Just call Yapp(parameter[s]).
# Accepts all types that new() accepts.
#
sub Yapp
{
  my $class = $_[0];        # Most likely the class name, may be string, array
  my $ryapp;                # Alternative return object to caller

  if (ref($class) eq $class_name)       # If this is copy-call, then the param
  {                                     # is not really a class name but a Yapp
    $ryapp = $class->Yapp_copy();       # instance; construct clone of original
  }
  else                                  # Not a reference
  { $ryapp =  __PACKAGE__->new(@_); }   # Just pass all parameter(s) to new()
  return $ryapp;                  # However we got it, return it to caller
}

#------------------------------------------------------------------------------
# Yapp_copy() - Internal utility function, should be called by new() in case
#               a copy-constructor is called for.
# Parameters:
# - (Implict) A reference to the source Yapp-polynomial for the copy
# Returns:
# - A referecne to a new Yapp object identical to the source
#
sub Yapp_copy
{
  my $self = shift(@_);         # Capture the object
  my $new_yapp = dclone($self); # Duplicate object, get back reference
  return $new_yapp;
}
#
#------------------------------------------------------------------------------
# refresh() - (Internal?) Method to perform two smoothing operations on
#             the given Yapp polynomial:
# - In case it got omitted in a contructor, if a coefficient between 0 and
#   the degree is still undefined, stick a 0.0 in there.
# - If any complex coefficients have a 0 imaginary part, replace it with the
#   real part only, as a real coefficient. e.g. cplx(-2.13,0.0) => -2.13
# - It looks for any 0 coefficient in the highest-degree places so that a 5th
#   degree polynomial with 0 coefficients in the 6th and 7th dregee places
#   does not appear to be a 7th degree polynomial
# Parameter:
# - (Implicit) The Yapp to thus fixed up
# Returns:
# - The same reference but it has been mutated as described.
#
sub refresh
{
  my $self = shift(@_); #(Lose the class name; concentrate on the array)
  my $slc;              # Loop counter for counting up my own array

  # This first loop can handle the undefined coefficient problem as well as the
  # disguised real-number problem
  #
  for ($slc = 0; $slc <= $self->{degree}; $slc++)
  {
    # Make sure there are no undefined coefficients in there.
    # (Zero is better than nothing.)
    #
    $self->{coeff}[$slc] = 0.0 if (! defined($self->{coeff}[$slc]));

    realify($self->{coeff}[$slc]);  # In case of complex coeff w Im == 0
  }

  # Next: Make sure the highest-degree term has a non-zero coefficient;
  # adjust the degree to match this. (Except if degree == 0. That's legit)
  #
  for ($slc = $self->{degree}; $slc > 0; $slc--)
  {
    last if ($self->{coeff}[$slc] != 0);    # Found my non-0 highest term; done

    # Still here: The current high-order term is a degenerate term with a
    # zero-coefficient. Lose it!
    #
   #undef($self->{coeff}[$slc]);    #(No, this does not lose the element)
    delete($self->{coeff}[$slc]);   # *This* loses the element
    $self->{degree}--;              # Make sure this coef will be skipped
  }

  # Finally: Since the coefficients may have been diddled, the coefficients of
  # the derivative and integral, if they have been generated, are unreliable.
  # Rather than regenerate them now, just lose them.  If they are needed again
  # they will be automatically and transparently regenreated.
  #
  undef $self->{derivative} if (defined($self->{derivative}[0]));
  undef $self->{integral}   if (defined($self->{integral}[0]));

  # After all that, it is *still* possible for {variable} to be undefined.
  # This will be the case for a constant term alone, a 0-degree polynomial
  # string.  Put the default in there now.
  #
  $self->{variable} = "X" if (!defined($self->{variable}));
  return ($self);
}
#
#------------------------------------------------------------------------------
# Ysprint(): Returns a string with the polynomial in some standard form,
#            suitable for printing.
# Parameters:
# - (Implicit) The Yapp opject
# - (Optional) The number of decimal places to use for the coefficients. If
#   omitted, we will use the module global $dec_places.  See Yapp_decimals for
#   more information on that.
# Default options:
# - Use X as the variable
# - Skip terms with 0-coefficients
# - Output highest powers first, as one would write in algebra class
# Funtions have been provided to change these behaviors.  These are:
# - Yapp_decimals(), so that you may call method Ysprint() without a parameter.
# - Yapp_print0()
# - Yapp_start_high()
#
sub Ysprint
{
  my $self = shift(@_);
  my $places = (defined($_[0])) ? $_[0] : $dec_places;
  my $dwidth = (defined($_[0])) ? $places + 1 : $dec_width;

  my $var_name = $self->variable();
  my $out_string = "";
  my $use_fmt = \$first_term_fmt;   # Make sure I use this first

  my $lc_start;             # Start loop at high or low degree terms?
  my $lc_finish = 0;        # And where do I finish, based on above?
  my $lc_diff  = -1;        # and in which direction doed my loop counter go?

  if ($start_high)                  # Default: Start from high-degree terms
  {
    $lc_start  = $self->{degree};   # Start loop at high-power term
    $lc_finish = 0;                 # End loop at 0-power term
    $lc_diff  = -1;                 # Normal behavior: Start high, step low
  }
  else
  {
    $lc_start  = 0;                 # Start loop at 0-degree term
    $lc_finish = $self->{degree};   # End loop at high-degree term
    $lc_diff  = 1;                  # work my way UP the degrees
  }
#
  for (my $lc = $lc_start; ; $lc += $lc_diff)   #(Check value of $lc inside
  {                                             # loop, not in loop header)
    last if ( ($lc > $self->{degree}) || ($lc < 0) );

    # How to format the coefficient depends on whether it is real or complex
    #
    my $term = "";      # Start the term as a null string and build from there
    if (ref($self->{coeff}[$lc]) eq $class_cplx)
    {
      # Note: The constructor should have set any "almost 0" complex
      # coefficients to real 0.0 so there is no need to account here for a
      # complex number with really tiny imaginary part.
      #
      # First term should not have a + sign if coefficient is positive
      # Constant term should not dislay X to the 0th degree
      # First degree term should display as X, not X^1
      # All other terms should include both aspects.
      #
      if    ($lc == $lc_start)          # If I'm generating the first term
      {
        $term = sprintf($first_term_fmt_i,
                        $dwidth, $places, ($self->coefficient($lc))->Re(),
                        $dwidth, $places, ($self->coefficient($lc))->Im(),
                        $var_name, $lc);    # No + sign for first term
      }
      elsif ($lc == 1)
      {
        $term = sprintf($one_term_fmt_i,
                        $dwidth, $places, ($self->coefficient($lc))->Re(),
                        $dwidth, $places, ($self->coefficient($lc))->Im(),
                        $var_name);         # No exponent for X^1 term
      }
      elsif ($lc == 0 )
      {
        $term = sprintf($zero_term_fmt_i,
                        $dwidth, $places, ($self->coefficient($lc))->Re(),
                        $dwidth, $places, ($self->coefficient($lc))->Im());
                                # No variable or exponent in 0-degree term
      }
      else
      {
        $term = sprintf($term_fmt_i,
                        $dwidth, $places, ($self->coefficient($lc))->Re(),
                        $dwidth, $places, ($self->coefficient($lc))->Im(),
                        $var_name, $lc);    # Always a + before a complex num-
                                            # ber in a middle term
      }
    }
#
    else                    # The ref() function did not say "Complex".  So it
    {                       # must be a real coefficient.
      # Note: Same sign, variable, exponent conventions apply as above
      #
      if    ($lc == $lc_start)          # If I'm generating the first term
      {
        $term = sprintf($first_term_fmt,
                        $dwidth, $places, $self->coefficient($lc),
                        $var_name, $lc);    # eg 34.145X^3
      }
      elsif ($lc == 1)
      {
        $term = sprintf($one_term_fmt,
                        $dwidth, $places, $self->coefficient($lc),
                        $var_name);         # eg. 34.145X (exponent == 1)
      }
      elsif ($lc == 0)
      {
        $term = sprintf($zero_term_fmt,
                        $dwidth, $places,
                        $self->coefficient($lc) );   # eg. 34.145
      }
      else
      {
        $term = sprintf($term_fmt,
                        $dwidth, $places, $self->coefficient($lc),
                        $var_name, $lc);    # eg. +34.145X^7
      }
      if ($self->coefficient($lc) == 0.0)   # What to do with a real 0.0
      {                                     # coefficient?
        # If $print_zero flag is set then the term has already been
        # formatted.  If it is not set (default) I want to null the string.
        #
        $term = "" unless ($print_zero);
      }
    }
    # Second part of the patch I described when I defined $zero_power_pat:
    # Lose the X^0 part of the term if I am on the 0-degree term.
    #
    $term =~ s/($zero_power_pat)$// if ($lc == 0);

    # If the output target string is still empty, this is the first occupant
    #
    if ("$out_string" eq "") { $out_string = $term; }
    else                            # Something alrady in there;
    {                               # Append blank and current term
      $out_string = sprintf("%s %s", $out_string, $term)
        if ($term ne "");           #(Provided our term has substance also)
    }
  }                             #(End of loop; at exit, $out_string is built)
  return $out_string;
}
#
#------------------------------------------------------------------------------
# print(): Method to print a formatted Yapp polynomial.  Basically, just a
#          wrapper for Ysprint.  I expected this to be used mainly in debugging
#          sessions so that I can say "p $something" but that doesn't work.
#          (And I'm not ready to start with Tie::Handle at this juncture,
#          although that seems to be the way to override the built-in print
#          function.)
# Parameters:
# - (Implicit) Ref to a Yapp object
# - (Optional) Number of decimal places for the coefficients
# Returns: (Whatever)
#
sub print
{
  my $yobj = shift(@_);
  my $ystring = $yobj->Ysprint($_[0]);  # There may be a places paremeter
  print $ystring;                       # Output it - no automatic \n
}
#------------------------------------------------------------------------------
# Csprint(): Utility function to format a complex number in my display format
#            e.g. (-3.24+6.03i), including the parenteses.  The number of
#            decimal places is based on the same Yapp_decimals() settings of
#            $dec_places and $dec_width used by Ysprint.
# Parameters:
# - [Reference to] a complex number of type Math::Complex
# - (Optional) Number of decimal places to display.  If omitted, use the
#   number in $dec_places
# Returns:
# - A parenthesized string in the form shown in the above blurb.
# Note: If a scalar is passed instead, it will be returned as received
#
sub Csprint
{
  my $cnum = shift(@_);
  my $places = (defined($_[0])) ? $_[0] : $dec_places;
  my $dwidth = (defined($_[0])) ? $places + 1 : $dec_width;
  return $cnum if (ref($cnum) ne $class_cplx);  # Don't bother with non-complex

  my $rstring = sprintf("(%*.*f%+*.*fi)",
                        $dwidth, $places, $cnum->Re(),
                        $dwidth, $places, $cnum->Im());
  return $rstring;
}
#
#------------------------------------------------------------------------------
#
# realify(): Internal utility function.  Loses extremely small real or imaginary
#            component of a complex number, since we can assume it came from
#            a rounding error.
# Parameter:
# - A real number or [Ref to] a Math::Complex number
#   OR
# - An array of numbers that each may be real or complex. In this case we
#   assume it was called in a list context.  Violate that assumption and die!
# Returns:
# - If real:
#   o If non-trivial, just return that number.
#   o If trivial, return 0.0
# - If complex:
#   o If the imaginary part is very small, less than $margin in absolute value,
#     return only the real part as a real.
#   o If real part is trivial, set it to 0.0 outright
#   o If both components are non-trivial, return the reference unscathed.
# - If an array;
#   o And array of numbers thus transformed
# If called with no return (void context like the chomp function) operate
# directly on the parameter or the array of numbers.
#
sub realify
{
  my $thing = $_[0];            # Don't shift, we might need to modify in place
  my $rval  = 0.0;

  die "You may not pass a list to realify(); use array reference"
    if ($#_ > 0);

  # Real or complex, if absolute value is really tiny, "correct" to 0
  #
  if (wantarray)                # Array context: Assume $thing  is an
  {                             # array reference.
   #my @rlist = map {realify($_)} @$thing;             # Return list
    # Don't use map for this recursive call. Apparently because there is an
    # array as the lvalue to the map{}, realify thinks it was called in the
    # list context.  Rather resort to brute force loop.
    #
    my @rlist;                  # List to be returned
    for (my $rlc = 0; $rlc <= $#$thing; $rlc++)
    {
      $rlist[$rlc] = realify($thing->[$rlc]);
    }
    return @rlist;
  }
  elsif (defined(wantarray))    # Scalar context: assume $thing is a scalar
  {                             # and caller wants a new value returned
    return (0.0) if (abs($thing) < $margin);    # Just tiny abs value: Quickie

    # If either component of a complex number is really tiny, set it to 0.
    # And if it's the imaginary component, lose it altogether
    #
    if (ref($thing) eq $class_cplx)     # If I have not zeroed it above then
    {                                   # I am permitted to check its components
      $rval = $thing;                   # Preserve original complex number
      if (abs($thing->Re) < $margin)    # Need to keep real part, even if tiny
      {
        $rval = cplx(0.0, $thing->Im)   # So just zero it out
      }
      if (abs($thing->Im) < $margin)    # If imaginary component is tiny
      {
        $rval = $thing->Re;             # lose it completely and return a real
      }
    }
    else                        # So it is real and its abs val is >= $margin
    {                           # ==> I already know in can't zero it.
      $rval = $thing;           # So the return value is the original number
    }
    return $rval;
  }
  else                          # Void context: Operate on the passed object.
  {
    if (ref($thing) eq "ARRAY") # Realifying every element in an array?
    {
      @{$thing} = realify($thing);  # Tickle the wantarray code above
    }
    else                            # Realify only one object
    {                               # Just work on that one
      $_[0] = realify($_[0]);       # Tickle the defined(wantarray) code above
    }
    # Note: No return statement.
  }
}
#
#------------------------------------------------------------------------------
# all_real() - Method to just know if a Yapp polynomial has strictly real
#              coefficients.
# Parameter:
# - [Ref to] a Yapp polynomial object
# Returns:
# - 1 (true)  if all coeffienents are real
# - 0 (false) if even one os complex
#
sub all_real
{
  my $self = shift(@_);
  my $allreal = 1;      # OK to start optimistic
  foreach my $coef (@{$self->{coeff}})
  {
    if (ref($coef) eq $class_cplx)
    {
      $allreal = 0;         # Not all real
      last;                 # No point in continuing
    }
  }
  return $allreal;
}
#
#------------------------------------------------------------------------------
# Yapp_equiv(): Method to compare a pair of Yapp polynomials, but only by the
#               aspects that count: the degree and the coefficients. I don't
#               care about the variable name nor about {deviative} or {integral}
#               for this comparison
# Parameters:
# - (Implicit) One Yapp to compare against
# - The Yapp to compare to the first.
# (At this time, I am not overloading the == operator)
#
sub Yapp_equiv
{
  my ($self, $compr) = @_;
  my $comp_ok = 1;          # Start by assuming true

  if ($self->{degree} == $compr->{degree})
  {
    for (my $dlc = 0; $dlc <= $self->{degree}; $dlc++)
    {
      $comp_ok = 0 if ($self->{coeff}[$dlc] != $compr->{coeff}[$dlc]);
      last unless $comp_ok; # If found unequal coefficients, quit
    }
  }
  else {$comp_ok = 0;}  # If even degrees don't agree, soooo not equivalent!

  return $comp_ok;
}
#
#------------------------------------------------------------------------------
# str2cplx() - Internal utility function, not an object method.
# This function accepts a string and converts it to a complex number.
#
# Parameter:
# - A string already determined to match our syntax for a complex number
# Returns:
# - A [reference to] a proper Math::Complex::cplx complex number
#
sub str2cplx
{
  my $c_string = shift(@_);     # Grab the string

  # Plan: I will need to take apart the string, first stripping the parentheses
  # and the letter i, then separating the components by splitting it by the
  # sign between the components.  But take care to not be fooled by a possible
  # sign before the real component
  #
  my $rsign = 1;                # Initially assume real component is positive
  my $rval = $czero;            # Return value: Establish it as a complex number
  $c_string =~ s/[\(\)i]//g;    # First, lose the parentheses and "i"
  if ($c_string =~ /^($sign_pat)/)  # Now, if there *is* a sign before the
  {                                 # real component
    $rsign = ($1 eq "-") ? -1 : 1;  # then [re]set the multiplier accordingly
    $c_string =~ s/$sign_pat//;     # and lose sign preceding the real
  }

  # And now the complex number (still a string) looks like A[+-]Bi
  #
  my @c_pair = split /([+-])/, $c_string;   # Split by that sign, but enclose
                                            # the pattern in ()
  # The effect of ([+-]), as opposed to [+-] without the parentheses:
  # I capture the actual splitting string; the array produced by the split
  # includes the splitting string itself.  Thus, my array contains [A, -, B]
  # (or +plus) as element[1] and the imaginary component is actually
  # element[2].  We'll change that after we use it.
  #
  my $isign = ($c_pair[1] eq "-") ? -1 : 1; # But what was that sign?
  $c_pair[2] *= $isign;                 # Recover correct sign of
                                        # imaginary component
  @c_pair = @c_pair[0,2];               # Now lose that im sign
  $c_pair[0] *= $rsign;                 # Good time to recall the sign
                                        # on the real component
  $rval = Math::Complex::cplx(@c_pair); # Turn pair into complex ref
  return $rval;                         # QED
}
#
#------------------------------------------------------------------------------
# Method: degree(): Just return the degree of the Yapp polynomial
# Usage:
#   ivar = jpoly_ref->degree();
sub degree
{
  my $self = shift(@_);
  return ($self->{degree});
}

#------------------------------------------------------------------------------
# Method: coefficient(): Return the coefficient of the inticated term.
# - If the coefficientis a real number, returns the number
# - If the coefficient is complex, returns the reference
# Usage:
#   float_var   = jpoly_ref->coefficient(n); # Retrieve nth-degree coefficient
#   complex_var = jpoly_ref->coefficient(n); # Retrieve nth-degree coefficient
#
# Error condition: If the n is higher than the degree or negative,
#
sub coefficient
{
  my $self = shift(@_);
  my $term_id = shift(@_);
  if ( ($term_id > $self->{degree}) || ($term_id < 0) )
  {
    my $msg = "Indicated degree is out of range [0, $self->{degree}]";
    croak $msg;
  }
  return ($self->{coeff}[$term_id]);    # Degree desired is valid
}

#------------------------------------------------------------------------------
# Method: variable(): Retrieve or set the character [string] that will be used
# to display the polynomial in Ysprint.
# Usage:
# - To set the string:
#   $jpoly_ref->variable("Y");          #(Default is "X")
#   $jpoly_ref->variable("squeal");
# - To retrieve the string:
#   $var_str = $jpoly_ref->variable();
# In both cases, the method returns the string.
#
sub variable
{
  my $self = shift(@_);
  my $rval = "";                        # Value to return
  if (@_ == 0)                          # No parameter?
  { $rval = $self->{variable}; }        # User wants to know it
  else
  { $rval = shift(@_);                  # Lop it off parameter list and
    $self->{variable} = $rval;          # set it as the variable symbol
  }
  return ($rval);
}
#
#------------------------------------------------------------------------------
# Method: str2yapp(): Accepts a string and converts it to a polynomial object.
# The implicit "self" parameter is asssumed to be referenceing a degenerate
# polynomial and that's where the member items will go.  If you already have an
# initialized polynomial object in there, it is *so* gone.
#
# Parameter:
# - A string of terms in the form <decimal><variable>^<integer>.
#   separated by white-spaces
# Returns:
# - The Yapp reference, if successful
# - undef if failed anywhere
#
# Usage:    This is not intended to be called from outside. Rather, new() will
#           call it in the following sequence:
#   1. new() creates and blesses the empty Yapp object referenced by $self
#   2. $self->str2yapp(The string>
#
# Note that the exponents do not need to be in any order; the exponent will
# decide the position within the array.
#
# Plan: Parsing presents a problem: I wish to impose no requirement that the
# terms and operators be blank-separated.  And while the terms are surely
# separated by + and -, the split function will remove the separators so I
# won't know what was the sign of each term in the polynomial string.  However,
# for my initial phase, I will require a white-space separator between terms.
# Also, each term mus match one of the patterns below, $real_term_pat or
# cplx_term_pat.
# For real coefficient it must look like:
#   +/-<decimal><variable>^<integer>
#  The sign will be optional for all terms.  (But don't tell that to the users.)
#
# For complex coefficient, it must look
#   +/-(<decimal>+<decimal>i)<variable>^<integer>
#
sub str2yapp
{
  my $self = shift(@_);             # Get myself out of the parameter list
  my $poly_string = shift(@_);      # and get the string into my locale

  my $tlc = 0;                  # Term loop counter

  my $rval = undef;             # Off to a pessimistic start
  my $const_term = 0;

  my $cur_term;                 # Current term from the input polynomial
  my $cur_sign   = 1;           # Assume positive if sign is omitted
  my $cur_coeff  = 0.0;         # Current coefficient
  my $cur_varia  = "";          # Current variable name; should change only
                                # once - the first time I see it.
  my $cur_degree = -1;          # For stepping into coeficient array
  my $hi_deg     = 0;           # For determining the highest exponent used

  undef($self->{variable});     # Leave it for user to name the variable
  $self->{degree} = 0;          # and for input to dictate the degree

  printf("String polynomial is:\n<%s>\n", $poly_string)
    if ($testmode);
  my @pterms = split /\s+/, $poly_string;   # Separate the terms
#
  for ($tlc = 0; $tlc <= $#pterms; $tlc++)
  {
    # Plan: For each term I parse out, determine the coefficient (including the
    # sign, of course), the  variable name and the exponent. This determines the
    # position and value in the @coeff array
    #
    # Afterthought: During debugging I discovererd that a + or - not
    # connected to the following term would also pass all the pattern
    # checks.  Rather than complain or reject the string, I'd rather be nice
    # about it.
    # So here's the scheme:
    # - If the +/- is the last term of the string, ignore it.
    # - Not the last:
    #   o If the following term *is* properly signed, threat this solitary
    #     sign like a multiplier for the following term
    #   o If the term following term is unsigned, prepend this solitary sign
    #     to that term.
    #   Either way, skip reat of this round and handle that following term
    #
    if ($pterms[$tlc] =~ m/^[-\+]$/)    # If it is a + or - alone
    {
      last if ($tlc == $#pterms);       # It is already last term: Ignore it

      # Still here: It is not the last term.  Peek ahead at next term
      #
      if ($pterms[$tlc+1] =~ m/^[-\+]/) # If next term is signed
      {                                 # Use this signs as multiplier
        if ($pterms[$tlc] eq substr($pterms[$tlc+1], 0, 1)) # Signs alike?
        { substr($pterms[$tlc+1], 0, 1) = '+'; }            # Next is positive
        else                            # Signs not alike: Whichever way,
        { substr($pterms[$tlc+1], 0, 1) = '-'; }            # Next is negative
        next;                           # Now handle that next term
      }
      else                              # But if next term is unsigned;
      {                                 # use this to make it a signed term
        $pterms[$tlc+1] = $pterms[$tlc] . $pterms[$tlc+1];  # Prepend this sign
        next;                                               # handle next term
      }
    }

    # following that afterthought...
    # Before anything else, check the sign; this makes it possible to specify
    # the negation of a complex coefficient eg. -(-6+4i)
    #
    $cur_term = $pterms[$tlc];  # Leave array enty intact; disect copy
#
    # Next: Fetch the coefficient, of there is one.
    #
    if ($cur_term =~ /($coef_pat)/) # Is there a coefficient?
    {
      $cur_coeff = $1;              # Isolate coefficient for more checking

      # First, see if there is a sign preceeding the coefficient.
      #
      if ($cur_coeff =~ /^($sign_pat)/) # If there is a sign
      {
        $cur_sign = ($1 eq "-") ? -1 : 1;   # Apply sign to coefficient later
        $cur_coeff =~ s/$sign_pat//;        # but for now, lose the sign
      }

      # Check if the coefficient is a complex number in ofr (a[+-]bi) where
      # a and b are reals
      #
      if ($cur_coeff =~ /$cplx_pat/) # If it looks like a complex number
      {
        $cur_coeff = str2cplx($cur_coeff);  # Convert it to complex object
      }
      else                      # Not complex: Must match a real or a sign
      {                         # What if it was just a sign? (Which is gone)
        $cur_coeff = 1.0 if ($cur_coeff eq ""); # Ths is implicitly 1
      }
      $cur_coeff *= $cur_sign;      # Finally, apply the original sign that
                                    # preceded the real or complex coefficient

      # Now that we have the coefficient for the current term, it's just in
      # the way. Lose it.
      #
      $cur_term =~ s/$coef_pat//;   # Leave the term w/o sign or coefficient.
    }
    else                            # No coefficient?
    { $cur_coeff = 1.0; }           # Implicitly, that is 1.  (If it had
                                    # been -1, it would be -X)
    # Now that the term has no coefficient (either by input or because it
    # has been stripped off), let's have a look at the variable component
    #
    if ($cur_term =~ /^($varia_pat)/)   # If there is a variable to speak of
    {
      $cur_varia = $1;                  # then captue that as variable name
      $cur_term =~ s/^($varia_pat)//;   # and remove it from the term.
    }
    else
    {
      undef($cur_varia);        # No variable => constant.  Make sure no expo-
      $cur_degree = 0;          # nent.  But we're getting ahead of ourselves..
    }
#
    # Next, see about the exponent part: ^integer, which is optional
    # but if provided, there had better be a variable as well.
    #
    if ($cur_term =~ /($power_pat)/)    # Is there an exponent
    {                                   # Some error checking, then work
      if (defined($cur_varia))          # If there is a variable
      {
        $cur_term =~ s/^\^//;           # Lose the exponent operator
        ($cur_degree) = $cur_term =~ m/(\d+)/;  # Capture the integer part
      }
      else
      { die "Term[$tlc] <$pterms[$tlc]> has an exponent w/o a variable"; }
    }
    else                    # No exponent.  Certainly OK.. But..
    {                       # Is the degree of the term 1 or 0? Well, is there
      $cur_degree = (defined($cur_varia)) ? 1 : 0;  # a variable? Yes => 1
    }

    # Finished parsing the term.  Our state at this point:  We have:
    # - The coefficient (be it real or # complex), inclduing its sign
    # - The variable name, which should not have changed.
    # - The degree of the curent term, which may match a term already there.
    #

    # Degree of polynomial is that of highest degree term, so:
    #
    $self->{degree} = $cur_degree if ($cur_degree > $self->{degree});


    # If variable name has changed in the string, complain but do it anyway.
    #
    if (   (defined($cur_varia))
        && (defined($self->{variable}))
        && ($self->{variable} ne $cur_varia))
    {
      my $mg;
      $mg = sprintf("Warning: Changing variable name from <%s> to <%s>\n",
                     $self->{variable}, $cur_varia);
      warn($mg);    # Complain but let it go
    }
    # Set the variable name for whole polynomial (if not already set in a
    # previous round of the loop)... provided that
    #
    $self->{variable} = $cur_varia
      if (defined($cur_varia)); # [Re]set the variable, even with grumble

    # If we already have a term at this degree, just add the new coefficient
    # to the existing one.  Otherwise, we are setting the coefficient now.
    #
    if (defined($self->{coeff}[$cur_degree]))   # Already have a term at
    {                                           # degree, then
      $self->{coeff}[$cur_degree] += $cur_coeff; # just add this one
    }
    else                                        # No term of this degree yet
    {                                           # This is new here
      $self->{coeff}[$cur_degree] = $cur_coeff; # Set the coefficient now
    }
  } # End of for-loop to parse individual terms

  # Bug fix (Too lazy to locate screw-up): Somehow I can get this far
  # without a variable component.  So just in case..
  #
  $self->{variable} = "X" if (!defined($self->{variable}));

  return $self;
}
#
#------------------------------------------------------------------------------
# Yapp_plus - Function to implement the += operator
# Parameters:
# - (Implicit) [Reference to] my target object
# - The object to added to my target object. This may be:
#   o Another Yapp polynomial object [reference]
#   o A constant, either real or complex (a different, albeit smaller can
#     of worms)
#
sub Yapp_plus
{
  my ($self, $added) = @_;  # Get relevant parameters. Swap is irrelevant

  # Now, what is $added?
  #
  if (ref($added) eq $class_name)   # If it is another polynomial
  {
    my $alc = 0;                        # Loop counter to step up added terms
    my $new_degree = $self->{degree};   # Track degree in case the added
                                        # polynomial has a higher degree
    my @builder = @{$self->{coeff}};    # Copy coefficients into temporary list
    for ($alc = 0; $alc <= $added->{degree}; $alc++)    # For all terms of the
    {                                                   # added polynomial
      if (defined($builder[$alc]))      # If target has term of this degree
           { $builder[$alc] += $added->{coeff}[$alc]; } # Just add these terms
      else { $builder[$alc]  = $added->{coeff}[$alc]; } # Or copy this term
      $new_degree = $alc if ($alc > $self->{degree});   # Maintain degree
    }
    # Temporary areas have been evaluated. Now plug these into target Yapp
    #
    $self->{degree} = $new_degree;      # Carry over the augmented (?) degree
    @{$self->{coeff}} = @builder;       # and the augmented polynomial
  }                                     # And I have my return value
  elsif (   ($added =~ m/^($coef_pat)$/)
         || (ref($added) eq $class_cplx) )  # Adding real or complex const
  {
    # As above: If the target term is defined, add the new term.
    # Otherwise, set the target term to the given value
    #
    if (defined($self->{coeff}[0])) {$self->{coeff}[0] += $added;}
    else                            {$self->{coeff}[0]  = $added;}
  }         # (Just needed to augment the constant term)
  else
  { die "Operator += requires a constant or a Yapp polynomial reference";}

  # Didn't die - I have a good value to return
  #
  return ($self);                       # (Ought to return something)
}

#------------------------------------------------------------------------------
# Yapp_add() - Function (and overloaded + operator) to add two polynomials.
# Parameters:
# - (Implicit) The polynomial on the left side of the + (self)
# - The polynomial to be added.  This may be:
#   o (Implicit) [A reference to] another Yapp polynomial object
#   o A constant, either real or complex  (See Yapp_plus)
# - (Implicit) The "swapped" flag, largely irrelevant for the + operator
# Returns:
# A reference to a new Yapp polynomial
#
sub Yapp_add
{
  my ($self, $adder, $swapped) = @_;    #(swap is irrelelvant for add)

  my $ryapp = Yapp($self);          # Clone the original
  $ryapp += $adder;                 # Let _plus() function handle details
  return $ryapp;                    # Assume $ryapp will be auto-destroyed?
}
#
#------------------------------------------------------------------------------
# Yapp_minus(): Function (and overloaded -= operator) to subtract the passed
#               polybnomial from the object polynomial in place.  That is,
#               it modifies the $self object
# - (Implicit) [Reference to] my target object
# - The object to added to my target object. This may be:
#   o Another Yapp polynomial object [reference]
#   o A constant, either real or complex
# Returns:
# - The same reference.  But the target Yapp ahs been "deminished"
#
sub Yapp_minus
{
  my ($self, $subtractor) = @_[0 .. 1];

  if (ref($subtractor) eq $class_name)  # Subtracting another polynimal
  {                                     # just use the add method
    my $temp_subt = $subtractor->Yapp_negate(); # Quickie way out: Negate and
                                                # add,  However I cant
    my $temp_self = Yapp($self);                # use -= on $sef. Dunno why
    $temp_self += $temp_subt;                   # Add the negated Yapp
    @{$self->{coeff}} = @{$temp_self->{coeff}}; # Restore subtracted
                                                # coeffiecient array
  }
  else                                  # Otherwise, just assume a constant
  {                                     # be it real or complex.
    # If our polynomial has no constant term, this is it, after negation.
    #
    $self->{coeff}[0] = (defined($self->{coeff}[0]))
                      ? $self->{coeff}[0] - $subtractor
                      : - $subtractor ;
  }
  return $self;
}

#------------------------------------------------------------------------------
# Yapp_sub(): Function (and overloaded - operator) to subtract one polynomia
# from another bot not in place.
# Parameters:
# - (Implicit) The polynomial on the left side of the - (self)
# - The polynomial to be added.  This may be:
#   o (Implicit) [A reference to] another Yapp polynomial object
#   o A constant, either real or complex  (See Yapp_plus)
# - (Implicit) The "swapped" flag
# Returns:
#  - A reference to a new Yapp polynomial
#
sub Yapp_sub
{
  my ($self, $subtractor, $swapped) = @_;

  my $ryapp = Yapp($self);          # Clone the original
  $ryapp -= $subtractor;            # Let _plus() function handle details
  $ryapp = $ryapp->Yapp_negate() if ($swapped); # Negate of $self was on
                                                # right of the - sign
  return $ryapp;                    # Assume $ryapp will be auto-destroyed?
}
#
#------------------------------------------------------------------------------
# Yapp_mult(): Function to implement the overloaded *= operator: Perform in-
# place multiplication of the target Yapp my a constant or another Yapp
# Parameters:
# - (Implicit) The target object ($self)
# - The multiplier.  This may be:
#   o Another Yapp object (Happiest with this parameter type)
#   o A real or complex constant
# Returns:
# The $self-same reference, but it has been "mutated" by the method.
#
sub Yapp_mult
{
  my ($self, $multiplier) = @_;
  my $aux_yapp;             # I may have to create another Yapp
  my $ylc;                  # Loop counter for stepping up coefficients

  # Now what data type is the multiplier?
  #
#Xif (   (ref($multiplier) eq "$class_cplx")    # Complex number constant
#X    || (   (ref(\$multiplier) eq "SCALAR")    # or a scalar that happens
#X        && ($multiplier =~ /^($coef_pat)$/))) # to be a real constant
#X Note: The above logic is good but for very low floating point numbers it
#X was failing to match the corefficient pattern.  Hence, I relaxed the
#X matching requirement.  -- Jacob

  if (   (ref($multiplier)  eq "$class_cplx")   # Complex number constant
      || (ref(\$multiplier) eq "SCALAR"     ) ) # or a scalar (Assume numeric)
  {                                             # Just distribute multiplier
    for ($ylc = 0; $ylc <= $self->{degree}; $ylc++)
    {
      $self->{coeff}[$ylc] *= $multiplier
        if ($self->{coeff}[$ylc] != 0) ;    # Don't bother multiplying 0
    }
  }
  elsif (ref($multiplier) eq $class_name)   # Multiplying by a polynomial
  {
    my @builder = ();                       # Build result area from scratch
    my $new_degree = $self->{degree}
                   + $multiplier->{degree}; # (Remember your 9th grade algebra?)
    for ($ylc = 0; $ylc <= $self->{degree}; $ylc++)
    {                                   # Outer loop multiplies one target term
      for (my $mlc = 0; $mlc <= $multiplier->{degree}; $mlc++)
      {                                 # Inner loop multiplies by one
                                        # multiplier term
        my $term_degree = $ylc + $mlc;      # Degree of this target term
        $builder[$term_degree] = 0.0                # Make sure there is a
          if (! defined($builder[$term_degree]));   # value in here to start

        # Accumulate product term of that degree: Product of the terms whose
        # exponents add up to the [eventual] exponent of this term
        #
        $builder[$term_degree] += $self->{coeff}[$ylc]
                                * $multiplier->{coeff}[$mlc] ;

      }     # End loop multiplying one target term by term from multiplier
    }     # End loop multiplying whole polynomials
    # Done multiplication: Now put it back in place
    #
    $self->{degree} = $new_degree;  # Copy back degree of multiplied target Yapp
    @{$self->{coeff}} = @builder;   # and copy back array where we carried
                                    # out the multiplication.
  }                         # All done multiplying Yapps; product is in place
  else                      # No more permitted possibilities
  { die "Operator *= requires a constant or a Yapp polynomial reference";}

  # Afterthought: I have found that when I multiply two poly's with conjugate
  # complex constant terms, the result will include coefficients like like
  # (30.00+0.00i); which is a real, of course, but doesn't look that way.
  # Here's the fix:
  #
  realify(\@{$self->{coeff}});
  return $self;
}
#
#------------------------------------------------------------------------------
# Yapp_times(): Method to implement the overloaded '*' operator
# Parameters:
# - (Implicit) The operand (usually the left) to the multiplicaton
# - [Reference] to the multiplier, which may be:
#   o Another Yapp object (Happiest with this parameter type)
#   o A real or complex constant
# - Swapped-operands flag, largely irrelevant for multiplication
# Returns:
# - [Reference to] a new Yapp polynomial that is the product of the first
#   two parameters
#
sub Yapp_times
{
  my ($self, $multiplier, $swapped) = @_;
  my $ryapp;                # The object to be returned

  $ryapp = Yapp($self);     # Make a copy
  $ryapp *= $multiplier;    # Carry out operation
  return $ryapp;            #(Wasnt't that simple?)
}
#
#------------------------------------------------------------------------------
# Yapp_power(): Method to implement exponentiation of polynomial by an
#               integer power.
# Parameters:
# - (Implicit) The operand, a ref to the polynomial being multiplied by itself
# - The power, which must be an integer
# - Swapped-operands flag:  grounds for immediate death
# Returns:
# - A [ref to a] Yapp polynomial that is the original raised to the
#   indicated powert
#
sub Yapp_power
{
  my ($self, $power, $swapped) = @_;

  # Some validations:
  #
  die "You cannot raise a number to a polynomial power"
    if ($swapped);
  die "Power must be an integer"
    if ($power != int($power));

  # And now that that's been squared away: Get to work
  #
  my $ryapp = Yapp(1);          # Start with a unit polynomial
  while ($power-- > 0)          # (Decrement after testing)
  {
    $ryapp *= $self;            # Carry out the self-multiplication
  }
  return $ryapp;
}
#------------------------------------------------------------------------------
# Yapp_divide(): Method to implement the overloaded '/=' operator.  Unlike
#                the multiply operator, I am allowing only for deviding by a
#                constant value.  Scheme is simple: Take reciprocal of divisor
#                and multiply the Yapp by that.
# Parameters:
# - (Implicit) the Yapp object itself
# - The divisor, which may be real or complex
# Returns:
# - The original Yapp reference
#
sub Yapp_divide
{
  my ($self, $divisor) = @_;
  my $recipro = (1.0 / $divisor);   # Take reciprocal

  #$self *= $recipro;               # (This causes "No Method" error, so..)
  $self = $self * $recipro;         # Carry out that multiplication
  return $self;
}
#
#------------------------------------------------------------------------------
# Yapp_dividedby(): Method to implement the overloaded '/' operator.
# Scheme: Identical to the Yapp_times() method.
#
# Parameters:
# - (Implicit) the Yapp object itself
# - The divisor, which may be real or complex
# Returns:
# - A reference to a new Yapp object wherin the division has been carried # out
#
sub Yapp_dividedby
{
  my ($self, $multiplier, $swapped) = @_;   # $swapped is irrelevant
  my $ryapp;                # The object to be returned

  $ryapp = Yapp($self);     # Make a copy
  $ryapp /= $multiplier;    # Carry out operation
  return $ryapp;            #(Wasnt't that simple?)
}
#
#------------------------------------------------------------------------------
# Negation and conjagation of the coefficients of the polynomial:
#
# Yapp_negate(): Method to handle the overloaded ! operator, to give a Yapp
#                whose coefficientes are the negatives of the given Yapp.
# Parameter: (Implicit)
# - A Yapp reference
# Returns:
# - If called in scalar context: A new Yapp with the negated coefficcients
# - If called in void context, returns nothing but the coefficients of the
#   given Yapp have been negated.
# Well, that *was* the idea; unfortunately, I cannot seem to get in-place
# negation to work.
sub Yapp_negate
{
  my $self = shift(@_);
  my $ryapp;                    # Return reference, if non-void context
#  my $ryapp = Yapp($self);      # Make a copy

  if ($testmode)
  {
    if (defined(wantarray))
    {
      if (wantarray) {print "List context\n";}
      else           {print "Scalar context\n";}
    }
    else {print "Void context\n";}
  }
  # Depending on calling context, $ryapp is either a new Yapp [reference] or
  # a new reference to the same parameter
  #
  #Xmy $ryapp = (defined(wantarray)) ? Yapp($self) : $self;
  #$ryapp *= -1;                             # Multiply all coefficients by -1
  #X$ryapp = -1 * $ryapp;                     # Multiply all coefficients by -1
  if (defined(wantarray))           # List context would be silly so ..
  {                                 # treat list context like scalar context
    $ryapp = -1 * $self;            # Create a new Yapp, negative of $self
    return $ryapp;                  # Send that back to caller
  }
  else
  {
    $self = -1 * $self;             # Negate the given Yapp
    return $self;                   # Return (a wasted value)
  }
}
##------------------------------------------------------------------------------
# Yapp_conj(): Method to handle the ~ operator; Conjugate the complex
#              coefficents of the given yapp
# Parameter: (Implicit)
# - A Yapp reference
# Returns:
# - In scalar context: A new one with the conjugate coefficcients
# - In void context:   Nothing but the original Yapp has been conjugated
#                      That is, if I could get it to work. In-place
#                      conjugation is not working, however.
sub Yapp_conj
{
  my $self = shift(@_);
  #my $ryapp = Yapp($self);      # Make a copy

  # Depending on calling context, $ryapp is either a new Yapp [reference] or
  # a new reference to the same parameter
  #
  my $ryapp = (defined(wantarray)) ? Yapp($self) : $self;
  my $clc;                      # Loop counter

  for ($clc = 0; $clc <= $ryapp->{degree}; $clc++)
  {
    next unless (ref($ryapp->{coeff}[$clc]) eq $class_cplx);# Skip real coeffs
    $ryapp->{coeff}[$clc] = ~$ryapp->{coeff}[$clc];
  }
  return $ryapp if (defined(wantarray));    # Return a value if scalar context
}

#
#-------------------------------------------------------------------------------
# Evaluation: Plug a value into the polynimal and calculate the result
# This is a simple application of Horner's "Synthetic Division"
#
# Parameters:
# - (Implicit) Reference to the Yapp polynomial
# - A real number or reference to complex number
# Returns:
# - The result of the plugging it in.
# - Optionally, if caller specified ($value, $quotient) = $some_yapp(number)
#   also returns [a refernce to] the quotient polynomial
#
sub Yapp_eval
{
  my ($self, $in_val) = @_;     # (Assuming correct parameters or Phzzzt!)
  my $elc;          # Exponent loop counter for countdown
  my $addval = 0.0; # Intermediate value in synthetic division step
  my $sumval = 0.0; # A term in the "quotient" line
  my @quotient = ();# Array representing the quotient sans remainder

  for ($elc = $self->{degree}; $elc >= 0; $elc--)
  {
    $quotient[$elc] = $self->{coeff}[$elc] + $addval;   # A term in quotient
    $addval = $quotient[$elc] * $in_val;                # Add this in next round
  }
  # Last term of the quotient is the evaluation of the polynomial at that
  # input value.  The rest is the quotient polynomial, albeit looking like a
  # degree too high.  Use shift to solve both issues:
  #
  my $result = shift(@quotient);    # Get value and reduce degree
  realify($result);                 # In case of rounding error, if result
                                    # is near zero, make it zero
  if (wantarray())                  # Did caller specify two return values?
  {
    my $y_quotient = Yapp(\@quotient);  # Turn the quotient array into poly
    return($result, $y_quotient);       # and return both to caller
  }
  else {return $result;}                # Otherwise, we happy with result alone

#  for ($elc = $self->{degree}; $elc >= 0; $elc--)
#  {
#    $sumval = $self->{coeff}[$elc] + $addval;
#    $addval = $in_val * $sumval;    # Add this to the next coefficient
#  }
#  return $sumval;               #(OK last addition was wasted)
}
#
#-------------------------------------------------------------------------------
# Yapp_reduce: Reduce the roots of a polynomial by the indicated amount.
# This is part of Horner's method for approximating the roots but will not
# be used here for that purpose.
#
# Parameters:
# - (Implicit) Reference to the Yapp polynomial
# - Value by which to reduce the roots. May be real or [reference to]
#   complex
# Reurns:
# - A [ref to a] new Yapp object, whose roots are the same as those of the
#   original but reduced by the indicated amount,
#
# Scheme:  This will use an array of successive arrays representing
# intermdiate quitient polynomials, as well as an array or remainders to
# build the final result
#
sub Yapp_reduce
{
  my ($self, $reduce_by) = @_;  # Get my parameters
  my @remainders;
  my @degrees;      # Make it easier to track the degree of each quotient
  my ($qlc, $tlc);  # Loop counters for outer and inner loops
  my $q_count = $self->{degree};    # How many quotients I will calculate
  my $lead_coeff = $self->{coeff}[$q_count];    # Will divide by this and
                                                # multiply it back later
  my @rlist = ();   # Result list, the raw polynomial we build up
  my $rcount = 0;   # Counter to make it easier to keep track to that build
  my @coeffs = @{$self->{coeff}};               # Will start with synthetic

  # Divide whole new "poly" by leading coefficient that that new leading
  # coefficient is 1.
  #
  for (my $clc=0; $clc <= $q_count; $clc++) {$coeffs[$clc] /= $lead_coeff;}

  for ($qlc = $self->{degree}; $qlc > 0; $qlc--)
  {
    my $addval = 0.0;       # Set up for synthetic division
    my $q_deg = $qlc - 1;   # Degree of new quotient
    my @quotient;           # Quotient of a synthetic division operation

    # Note: This inner loop uses the same synthetic division used in function
    # Yapp_eval().  But the moving expression $quotient[$tlc] stands in place
    # of $sumval
    #
    for ($tlc = $qlc; $tlc >= 0; $tlc--)
    {
      # First add $addval to a term to determine next coefficient.
      # Then determine next $addval
      #
      $quotient[$tlc] = $coeffs[$tlc] + $addval;
      $addval = $reduce_by * $quotient[$tlc];
    }
    # When I come out of above inner loop, two items of interest:
    # - The last value in the quotient array, which is the remainder of the
    #   synthetic division operation, is the next coefficient in the final
    #   polynomial.
    # - The quotient array represents the next polynomial to be "divided" by
    #   the divisor, once I get rid of the remainder term.
    #
    $rlist[$rcount++] = shift(@quotient);   # Pull remainder into the polynomial
                                            # I am building up, an drop it out
                                            # of the next polynomial.
    @coeffs = @quotient;                    # Will next divide *this* polynomial
    @quotient = ();                         # Neatness: Clear for next round
  }
  $rlist[$q_count] = 1;         # The inevitable final quotient

  # (Whew) I now have our list or remainders from the above sequence of
  # synthetic divisions.  Create a polynomial out of that list
  #
  my $ryapp = Yapp(\@rlist);    # This creates the polynomial
  $ryapp *= $lead_coeff;        # Remember that? Multiply it back out
  return $ryapp;                # This has the roots reduced.
}
#
#-------------------------------------------------------------------------------
# Yapp_negate_roots(): Returns a polynomial whose roots are the nagatives of the
#                      roots of the given polynomial.  Easy trick: Negate the
#                      coefficient of every odd-exponent term.
#
# Parameter:
# - (Implicit) The Yapp reference
# Returns:
# - A new Yapp with negated roots
#-------------------------------------------------------------------------------
#
sub Yapp_negate_roots
{
  my $self = shift(@_);         # The only parameter I care about
  my $ryapp = Yapp($self);      # Copy to another polynomial
  my $coefref = $ryapp->{coeff};
  for (my $clc = 1; $clc <=$#{$coefref}; $clc+=2)   # Odd indexed terms only
  {
    $coefref->[$clc] = - ($coefref->[$clc]) #(If it was 0, no harm done)
  }
  return $ryapp
}
#
#-------------------------------------------------------------------------------
# Derivative and antiderivative i.e. indefinite integral.
# In both cases, we will store the transformed polybnomial back into the
# Yapp structure because they will very likely be resused for other stuff.
# For example, Newton's method for finding roots uses the first derivative,
# and laGuerre's method uses the second derivative.
#
# Yapp_derivative()
# Parameters:
# - (Implicit) Reference to the Yapp to differentiated
# - Order of derivative.  If omitted, assume caller meant first derivative
# Returns:
# - A [reference to a] Yapp polynomial that is the indicated derivative of
#   the given Yapp.
# - Side effect: A new array of Yapp references to all the derivatives is
#   now hanging off the given Yapp structure. @{derivatives}
#-------------------------------------------------------------------------------
#
sub Yapp_derivative
{
  my $self = shift(@_);
  my $order = defined($_[0]) ? shift(@_) : 1;   # Get nth derivative or assume 1
  my $start_n;      # Highest order derivative we already have
  my $coefref;      # Use as array reference as I step into each polynomial
  my $dlc;          # Loop counter for derivatives

  if (defined($self->{derivative}[$order]))     # If I have already derived this
  { return($self->{derivative}[$order]); }      # just give it again, no work

  # Still here?  Two possibilities:
  # 1. Previous derivatives have been derived, just not this order
  # 2. This is the first time a derivative it being requested, so I have to
  #    create the derivatives array from scratch
  #
  if (defined($self->{derivative}[1]))
  {                                     # If we already have derivatives saved
    $start_n = $#{$self->{derivative}}; # Start past highest we already have
  }
  else
  {                                     # Starting derivatives from scratch
    $self->{derivative}[0] = Yapp();    # Empty placeholder for 0th deriv
    $start_n = 0;                       # 'Cause we got none yet
  }

  for ($dlc = $start_n; $dlc < $order; $dlc++)
  {
    last if ($dlc >= $self->{degree});      # No more derivatives than degree
    my @new_list;
    if ($dlc == 0) {$coefref = $self->{coeff}; }    # -> my coeffiecients
    else
    {
      my $cur_deriv = $self->{derivative}[$dlc];    # -> (lc)th derivative
      $coefref = \@{$cur_deriv->{coeff}};           # and to *its* coefficients
    }
    for (my $tlc = 1; $tlc <= $#{$coefref}; $tlc++) # Skip 0th term
    {
      $new_list[$tlc-1] = $tlc * $coefref->[$tlc];  # Coeff * its exponent
    }
    $self->{derivative}[$dlc+1] = Yapp(\@new_list); # New Yapp in deriv slot
  }
  return ($self->{derivative}[$dlc]);
}
#
#-------------------------------------------------------------------------------
# Yapp_integral(): Method to calculate the first integral of the given Yapp
#                  polynomial.
# Let's clarify: This serves as two functions:
# - The indefinite integral AKA the antiderivative, returning a Yapp polynomial
#   for the given polynomial.  Will not include the arbitrary constant you were
#   taught to always include with your antiderivative.
# - A definite integral: That is, supplying two numbers that represent the
#   endpoints of an interval i.e. the limits of the integral.
# Returns:  Well, that depends:
# - For indefinte integral, returns a reference to the antiderivative polynomial
#   (which as been stored in $self anyway.)
# - For definite integral: Returns the value of that integral between the
#   limits.
# In both cases, the antiderivative polynomial is cached along with the given
# Yapp so it may be re-used for various limits.
#
# Note: Unlike with derivatives, I see no need to code for additional order
# of integral. (I'm not anticipating a Laurent series)
#
sub Yapp_integral
{
  die ("Must supply either no integral limits or exactly two points")
    unless ( ($#_ == 2) || ($#_ == 0));     # Bail if wrong parameters given
  my $self = shift(@_);                     # If $#_ was 2, it is now 1
  my ($l_limit, $u_limit) = (undef, undef); # Don't know yet if user called
                                            # me for a definite integral.
  my $ryapp;                                # My return reference for indefinite
  my $rval= 0.0;                            # My return value for definite


  ($l_limit, $u_limit) = @_ if ($#_ == 1);  # Now is when I find out about
                                            # those endpoint parameters

  # Note: If I never calculated the integral for this polynomial (or if it
  # has "refreshed"), the {integral} component may be an array or undefined.
  # But it *won't" be Yapp.
  #
  if (ref($self->{integral}) ne $class_name)    # Ever calculated the indefinite
                                                # integral for this polynomial?
  {                                 # No: Do it now.
    my @new_list = (0);             # 0 in place of arbitrary constant
    for (my $ilc = 0; $ilc <= $self->{degree}; $ilc++)
    {
      push (@new_list, ($self->{coeff}[$ilc] / ($ilc + 1)));
    }
    $ryapp = Yapp(\@new_list);              # Create the polynomial
    $self->{integral} = $ryapp;             # and cache that for re-use
  }
  else {$ryapp = $self->{integral}; }       # Already computed: Just re-use it

  # Part 2: What does the user want? Definite or indefinite integral?
  #
  return ($ryapp) unless (defined($l_limit));   # No limits? Wants indefinite

  # Still here: Wants the value of that integral
  #
  my $u_val = $ryapp->Yapp_eval($u_limit);  # Value of antideriv at upper limit
  my $l_val = $ryapp->Yapp_eval($l_limit);  # Value of antideriv at lower limit
  $rval = $u_val - $l_val;                  # And that's the integral value
  return $rval;
}
#
#-------------------------------------------------------------------------------
# Solving for the zeros of a polynomial:
# Method Yapp_solve() is the only method that should be called byt he users.
# This, in turn calls appropriate other methods.  For example, for a quadratic
# polynomial, Yapp_dolve() will call Yapp_solve_quad(), which will simply use
# the quadratic formula. For a cubic, it uses the algorithm of Gerolamo Cardano
# and for the quartic (4th degree) that of Lodovico Ferrari.  After that, we
# resort to bisection to locate a solution, then go to Newton's method.  (A
# future release may switch to laGuerre's method.)
#
# For degree >= 5 we are guranteed at least one real root only for odd-degree
# polynomials so bisection is a sure thing.  However, for an even-degree poly-
# nomial, there is no such guarantee.  I have tried to discuss and analyze
# methods that might be analogous to bisection for complex numbers but to no
# avail.  I have bitten the bullet and coded Laguerre's method as a starting
# point for even-degree polynomials of degree >= 6
#
# Short cuts:
# - When a complex root is found, we will also evaluate the quotient for the
#   conjugate of that root.
# - In all cases, when any root is found, we evaluate quotient for the same root
#   in case it's a multiple root.
# - Whenever a root (or set of roots, as bove) is found, we make a recursive
#   call to Yapp_solve() to get the roots of the quotient polynomial. (I have
#   read that the technique is called deflation.)  However, after getting the
#   roots of the deflated polynomial, I still apply Newton's method on the roots
#   with respect to the polynmomial at hand.  This is to compensate for rounding
#   errors that have crept in while solving the deflated polynomial
#
# Parameter:
# - (Implicit) The Yapp polynomial to solved
# Returns:
# - An array of solutions, which may include repeated values owing to repeated
#   roots.  (Not a reference but the array otself.)
#-------------------------------------------------------------------------------
#
sub Yapp_solve
{
  my $self = shift(@_);
  my $solu_end = $self->{degree}    # The degree the polynomial came it with
                  - 1;              # Top index of solutions array
  my @solutions = ();               # Array to be returned starts empty
  my $solu_begin = 0;               # Where to start pushing solutions in
                                    # the @soultions array
  if ($solu_end == 0)
  {
    carp("0-degree polynomial <$self->Ysprint()> has no solution");
    return @solutions;              # Don't bother with it anymore
  }

  # Quick check: If the constant term of the polynomial is 0, then we know
  # that 0 is a solution. In that case, shift the polynomial down a degree
  # and test again.  This is the point of the following loop.. Except that I
  # am assuming that constant term is zero if it is sufficiently small; that
  # it is the result of a rounding error in a previous computation is this
  # highly recursive function.
  #
#
  while (abs($self->{coeff}[0]) <= $margin)
  {
    $solutions[$solu_begin++] = 0.0; # Zero *is* a solution to *this* polynomial
    shift(@{$self->{coeff}});       # Knock it down a degree for next round
    --($self->{degree});            # Register the lowered degree
  }
  my $degree = $self->{degree};     #(Just neater for successive if/elsif)

  # After this, we go structured; no returning from within "if" blocks
  #
  if ($degree == 1)                 # b + ax = 0
  {
    $solutions[$solu_begin] = - $self->{coeff}[0]/$self->{coeff}[1] ;   # -b/a
  }
  elsif ($degree == 2)
  {
    @solutions[$solu_begin .. $solu_end]  = $self->Yapp_solve_quad();
  }
  elsif ($degree == 3)
  {
    @solutions[$solu_begin .. $solu_end] = $self->Yapp_solve_cubic();
  }
  elsif ($degree == 4)
  {
    @solutions[$solu_begin .. $solu_end] = $self->Yapp_solve_quartic();
  }

  # We've just run out of fomulaic methods and we must resort to pure numerical
  # methods.  Oh Joy!
  #
  elsif (! $self->all_real)
  { # Complex Coefficients: Some theorems go out the window
    @solutions[$solu_begin .. $solu_end] = $self->Yapp_solve_complex();
  }
  elsif (($degree % 2) == 1)
  {
    @solutions[$solu_begin .. $solu_end] = $self->Yapp_solve_odd();
  }
  else
  {
    @solutions[$solu_begin .. $solu_end] = $self->Yapp_solve_even();
  }
  # Apply this filter to the @solutions array: If we have reason to suspect
  # that a complex number looks complex only due to rounding errors i.e. the
  # imaginary part is so small that it looks ignorable, then do ignore it.
  # Similarly, we can nullify (but not ignore) a trivial real component of a
  # complex number.
  #
  realify(\@solutions);

  return @solutions;
}
#
#-------------------------------------------------------------------------------
# Yapp_newton(): Internal method. If we already have a crude (in the eye of
#                the beholder) appoximation of a root, let's get much closer
#                by using Newton's method.  This is especially a problem
#                with the Ferrari and Cardano's algorithms when applied as
#                algorithms and rounding error are inevitable.
# Parameters:
# - (Implicit) The Yapp object
# - The initial value
# Returns:
# - A refined value, with $margin of being correct.
#
sub Yapp_newton
{
  my ($self, $xn) = @_;             # Get object an our starting X-value

  my $func_name = (caller(0))[3];   #(For debugging)
  my $yprime = $self->Yapp_derivative(1);
  my $valxn = $self->Yapp_eval($xn); # Evaluation at starting point
  while (abs($valxn) >= $margin)    # Continue this loop until I'm REALLY close
  {                                 # to a solution.
    my $xc = $xn;                       # Hold a copy of current tested value
    my $yp = $yprime->Yapp_eval($xn);   # Get derivative at current $xn
    last if (abs($yp) == 0);            # Beware of zero-divide!
    my $correction = $valxn / $yp;      # Current value / current derivative
    $xn -= $correction;                 # X[n+1] = X[n] - Y(X[n])/Y'(X[n])
    last if (abs($xn - $xc) < $margin); # Another exit condition: Almost no diff
                                        # between this x and previous x
    $valxn = $self->Yapp_eval($xn); # Ready for test or use atop next round
    printf("%s: xn = <%s>; valxn = <%s>\n",
           $func_name, Csprint($xn), Csprint($valxn))
        if ($testmode);
  }
  return($xn);                      # Close enough to send back to caller
}
#
#-------------------------------------------------------------------------------
# Yapp_laguerre(): Internal method. If we start with just about any starting
#                  point - it doesen't even have to be all that close we can
#                  get much closer by using Laguerre's method.
# Source of the mathetics I am using:
# Numerical Recipes in C; The Art of Scientific Computing
#   Second Edition (C) 1988, 1992`
# Authors: William H. Press
#          Saul A. Teukolsky
#          William T. Vetterling
#          Brian P. Flannery
#   Pages: 372-374
# Note: I made the chagrined discovery that rounding errors cause the test
# values to fluctuate a few decimal places out of my desired margin.
# Experiment: Use Laguerre's method to within .001, then switch to Newton's
# method.
# ...
# Parameters:
# - (Implicit) The Yapp object
# - The initial value
# Returns:
# - A refined value, with $margin of being correct.
#
sub Yapp_laguerre
{
  my ($self, $xn) = @_;             # Get object an our starting X-value
  my $func_name = (caller(0))[3];   #(For debugging)

  my $degree = $self->{degree};             # This will figure in recalculations
  my $yprime = $self->Yapp_derivative(1);   # First derivative of self
  my $yprime2 = $self->Yapp_derivative(2);  # And second derivative
  my $valxn = $self->Yapp_eval($xn);        # Evaluation at starting point
  my $crude_margin = .001;                  # Quite close - might as well take
                                            # advantage of Laguerre's faster
                                            # convergence.
  while (abs($valxn) >= $crude_margin)      # Bet this looks familiar so far :)
  {                                         # Well, hang on to your seats!
    # Correction factor is:
    # Degree / (G +/- sqrt((Degree - 1) * (Degree * H - G**2)))
    # See evaluation of $gxn for G and $hxn for H below
    # Ugly, ain't it? ;-)
    #
    my $prev_xn = $xn;              # Keep current estimate for comparison
    my $gxn = $yprime->Yapp_eval($xn) / $valxn;
    my $hxn = $gxn**2 - ($yprime2->Yapp_eval($xn) / $valxn);
    my $under_rad = ($degree -1)
                  * ($degree * $hxn - $gxn ** 2);   # May be negative or complex
    my @rad_roots = root($under_rad, 2);            # Take square roots of that
    my @denoms = ($gxn - $rad_roots[0],     # Choose a denominator for fraction
                  $gxn + $rad_roots[0]);    # to be used in a correction.
    my @norms = (abs($denoms[0]), abs($denoms[1])); # Which denominator has the
                                                    # bigger absolute value?
    my $denom = ($norms[0] > $norms[1]) ? $denoms[0] : $denoms[1];  # Pick that
    my $correction = $degree / $denom;      # Correct previous estimate by this
    $xn -= $correction;                     # "amount" by subtracting it
#?  last if (abs($prev_xn - $xn) < $margin); # Quit if correction was teeny
    $valxn = $self->Yapp_eval($xn);         # Otherwise, re-evaluate at new
                                            # estimate and plug in next round
    printf("%s: xn = <%s>; valxn = <%s>\n",
           $func_name, Csprint($xn), Csprint($valxn))
        if ($testmode);
  }
  # Came out of loop: I guess we're close enough to start with Newton?
  #
  $xn = realify($xn);                       # NUllify tiny Im component
  $xn = $self->Yapp_newton($xn);            # before feeding it to Newton
  realify($xn);                             # and correct again afterward
  return $xn;
}
#
#-------------------------------------------------------------------------------
# Yapp_solve_quad(): Solve a quadratic equation
#
sub Yapp_solve_quad
{
  my $self = shift(@_);
  my ($real_part, $discr, $rad_part);
  my @solutions = ();       # Look familiar? :-)
  my $i = cplx(0, 1);       # The familiar imaginary unit, "i"
  my ($c, $b, $a) = @{$self->{coeff}};  # Copy the array, for neatness

  $real_part = -$b / (2 * $a);      # This part is always guaranteed real
                                    # (assuming real coefficients, of course)
  $discr = $b ** 2 - (4 * $a * $c);  # Discriminant: b^2 - 4ac
  if ($discr == 0)
  {
    @solutions = ($real_part, $real_part);  # Repeated roots.  We're done!
  }
  elsif ($discr > 0)
  {
    $rad_part = sqrt($discr)/ (2 * $a);     # The part under the radical
    @solutions = ($real_part - $rad_part, $real_part + $rad_part);
  }
  else                              # Negative discriminant => complex roots
  {
    my @i_roots = root($discr, 2);  # Get both imaginary roots

    # Because the root() function is too *&&^% comfortable in polar form, we
    # get a miniscule (but still there) real part.  Get rid of it!
    #
    @i_roots = (cplx(0.0, $i_roots[0]->Im), cplx(0.0, $i_roots[1]->Im));
    printf("Roots of discriminant <%f> are: <@i_roots>\n", $discr)
      if ($testmode);
    @i_roots = (($i_roots[0]/(2 * $a)),
                ($i_roots[1]/(2 * $a)) );   # Recall: All parts divided by 2a
    @solutions = ($real_part + $i_roots[0], $real_part + $i_roots[1]);
  }
  return @solutions;
}
#
#-------------------------------------------------------------------------------
# Yapp_solve_cubic()
#
sub Yapp_solve_cubic
{
  my $self = shift(@_);
  my @solutions;                # I will return this array
  my $monic;                    # Original Yapp with 1 as leading coefficient
  my $reduced;                  # $monic with roots reduced, if needed
  my $reduced_by = 0;           # By how much to reduce the roots in order
                                # to eliminate the degree[2] term
  my ($zero, $quotient_2, $quotient_1); # zero is mainly a placeholder.
                                        # the two quotients are for after an
                                        # evaluation to get the next lower
                                        # degree polynomials.
  my $allreal = $self->all_real;        # Optimistic start

  # 2 transformations:
  # - Make sure leading coefficient is 1 (monic)
  # - Reduce roots by 1/3 of the x^2 coefficient. This sets the x^2 coefficient
  #   (Which is always the negative of the sum of the roots) to 0
  #
  if ($self->{coeff}[3] == 1)   # If this is alrady a monic polynomial
  {
    $monic = Yapp($self);       # Use a copy before reducing roots
  }
  else
  {                                         # Divide by leading coefficent
    $monic = $self / ($self->{coeff}[3]);   # to *make* it monic
    printf("Self:  <%s>\nMonic: <%s>\n", $self->Ysprint(), $monic->Ysprint())
      if ($testmode);                       # TESTMODE
  }
  if ($monic->{coeff}[2] != 0)  # If we have a degree[2] term
  {
    $reduced_by = -($monic->{coeff}[2])/3;  # Reduce by 1/3 of x^2 term
    $reduced = $monic->Yapp_reduce($reduced_by);
    printf("Original <%s>, with roots reduced by <%.5f>\nYields: <%s>\n",
            $self->Ysprint(), $reduced_by, $reduced->Ysprint())
      if($testmode)                         # TESTMODE
  }
  else
  {
    $reduced = Yapp($monic);    # Had no X^2 term.
  }
  my $p = $reduced->{coeff}[1];
  my $q = $reduced->{coeff}[0];
#
  # In Cardano's algorithm, I set X = U + V, which lets me play games with
  # these new variables.  After I pluck in (U+V) for X in the reduced monic
  # polynomial, I collect terms and get an expression like this:
  # U^3 + (U + V)(3*U*V + p) + V^3 + q = 0
  # If I set (3*U*V + p) to 0 I get a much simpler expression:
  # U^3 + V^3 + q = 0.  But, in light of the 0 setting above, I need to
  # substitute V = -p/(3*U).  This results in the 6th degre equation:
  # 27U^6 + 27q*U^3 - p^3 = 0.
  # Hey! This is quadratic in U^3.  I can solve this!
  #
  my $u_six = Yapp((-$p ** 3), (27 * $q), 27);
  $u_six->variable("U-Cubed");  # Set this variable for clarity
   printf("U-Cubed quadratic is <%s>\n", $u_six->Ysprint())
     if ($testmode);                        # TESTMODE
  my @u_solution = $u_six->Yapp_solve();    # I only need one of these
  my $u_cubed = $u_solution[0];             # Pick first one - Easy
  my ($u, $v);                              # Components for X = U + V

  # $u_cubed may be a complex number; I need to be circumspect about taking
  # its cube root.
  #
  my @u_roots = root($u_cubed, 3);      # Get all three cube roots

  # Note: Even the real cube root of a real number may come back as a complex
  # with an extremely small imaginary part, on the order of 10^-15 or so. This
  # is a legitimate rounding error, which I can lose with relative impunity.
  #
  my $use_this_u = $u_roots[0];         # Ready to use first root, even complex
  realify(\@u_roots);                       # Lose insignificant imaginary com-
                                            # ponents from rounding errors.
  for (my $rlc = 0; $rlc < 3; $rlc++)       # Search for a real cube root
  {
    if (ref($u_roots[$rlc]) ne $class_cplx) # Fair to assume: If it ain't
    {                                       # complex, it's the real we prefer
      $use_this_u = $u_roots[$rlc];         # If we found it, grab it and run
      last;
    }
  }

  # Now I can set $u and $v properly. $u may be real or complex as per above
  # loop.  But if it is complex, $v seems to inevitable end up as the
  # conjugate of $u.  Prefer to use a real root but if none is available,
  # one root is as good as another for this purpose; in that case, use the
  # first cube root.
  #
  $u = $use_this_u;             # This is the cube root to work with.

  # Now recall that V = -p/(3*U) from the 3*U*V +p = 0 setting
  #
  $v = -$p / (3 * $u);          # The other component ox X = U + V
  $solutions[0] = $u + $v       # Almost there; but remember this is the root
                + $reduced_by;  # reduced in the second transformation
                                # Now THAT's a root! .. er, almost.
  $solutions[0] = realify($solutions[0]);   # Lose trivial imaginary component
#
  # OK, I have my first solution.  If it is complex *and* the original
  # coefficients are all real, math guarantees me that the comjugate is also
  # a solution.  In that case, [synthetic] divide by this complex solution
  # as well so we are left with a simple linear equation to solve.
  # Otherwise (Either this one is real or we had complex coefficients) just
  # [synthetic] divide by this solution and solve the rusulting quadratic
  # quotient.
  #
  if (  (ref($solutions[0]) eq $class_cplx) # First solution is complex
      &&($allreal) )                        # and no complex coefficients
  {                                         # Conjugate is also a solution
    $solutions[1] = ~ $solutions[0];        # from the original monic
    ($zero, $quotient_2) = $monic->Yapp_eval($solutions[0]);
                                            # Had *better* evaluate to 0!
    ($zero, $quotient_1) = $quotient_2->Yapp_eval($solutions[1]);

    # $quotient_1 is a [ref to a] 1st degree polynomial.
    #
    ($solutions[3]) = $quotient_1->Yapp_solve();    # This is kinda trivial
  }
  else                          # If I can't depend on conjugate, for what-
  {                             # ever reason, just divide this one out
    ($zero, $quotient_2) = $monic->Yapp_eval($solutions[0]);    # -> quadratic

    # $quotient_2 is a quadratic expression. Just solve that.
    #
    @solutions[1,2] = $quotient_2->Yapp_solve();
  }
  return @solutions;
}
#
#-------------------------------------------------------------------------------
sub Yapp_solve_quartic
{ # Much of the setup here is similar to that of Yapp_solve_cubic, but with
  # tiny differences, enough to not try to make subroutins of this code.
  my $self = shift(@_);
  my @solutions;                # I will return this array
  my $monic;                    # Original Yapp with 1 as leading coefficient
  my $reduced;                  # $monic with roots reduced, if needed
  my $reduced_by = 0;           # By how much to reduce the roots in order
                                # to eliminate the degree[2] term
  my ($zero, $quotient_2, $quotient_1); # zero is mainly a placeholder.
                                        # the two quotients are for after an
                                        # evaluation to get the next lower
                                        # degree polynomials.

  # 2 transformations:
  # - Make sure leading coefficient is 1 (monic)
  # - Reduce roots by 1/4 of the x^3 coefficient. This sets the x^3 coefficient
  #   (Which is always the negative of the sum of the roots) to 0
  #
  if ($self->{coeff}[4] == 1)   # If this is already a monic polynomial
  {
    $monic = Yapp($self);       # Use a copy before reducing roots
  }
  else
  {                                         # Divide by leading coefficent
    $monic = $self / ($self->{coeff}[4]);   # to *make* it monic
    printf("Self:  <%s>\nMonic: <%s>\n", $self->Ysprint(), $monic->Ysprint())
      if ($testmode);                       #TESTMODE
  }
  if ($monic->{coeff}[3] != 0)  # If we have a degree[3] term
  {
    $reduced_by = -($monic->{coeff}[3])/4;  # Reduce by -1/4 of x^3 term
    $reduced = $monic->Yapp_reduce($reduced_by);
    printf("Original <%s>, with roots reduced by <%.5f>\nYields: <%s>\n",
            $self->Ysprint(), $reduced_by, $reduced->Ysprint())    #TESTMODE
      if($testmode);
  }
  else
  {
    $reduced = Yapp($monic);    # Had no X^3 term.
  }
#
  # In Ferrari's algorithm, we transpose the X^2, X^1 and constant term to the
  # right side.  Of course, it is not expected to be perfect square.  However,
  # we can add a new variable, u, to the left side so that it becomes
  # (1)     (X^2 + u)^2.
  # That is, add 2*u*X^2 + u^2 to the left side, keeping it a perfect square.
  # The right side, with the transposed 3 terms, had been:
  # (2)     -cX^2 -d*X -e
  # now becomes (after collecting terms):
  # (3)     (2u -c)X^2 -d*X + (u^2 -e)
  # (3a)          A     B            C
  # Is this a perfect square? Well, that depends: Is *is* a quadradic
  # expression but it *can* be a perfect square if is discriminant is 0;
  # that is: B^2 - 4*A*C, which is an expression containing that unknown u
  # term, can be set to 0. That is:
  # (4)     (-d)^2 - 4*(2u -c)*(u^2 -e) == 0
  # Multiplying out and collecting terms, this becomes:
  # (4a)    8*u^3 -4*c*u^2 -8*e*u +(d^2 -4c*e)
  # A cubic equation in the unknown u.  This is called the resolvent cubic
  # of the original polynomial. (The last two terms in parentheses comprise
  # the constant of that cubic equation.)
  # The point is that: Any solution to (4a) can be plugged back into (3) to
  # make it a perfect square to match against the perfect square left hand side
  # (LHS) in (1).
  # Here goes!
  #
  my $c = $reduced->{coeff}[2];     # X^2 coefficient
  my $d = $reduced->{coeff}[1];     # X^1 coefficient
  my $e = $reduced->{coeff}[0];     # Constant term

  my @rca = ();         # Array that will generate the resolvent cubic equation
  push @rca, 4*$c*$e - $d**2;   # Constant term
  push @rca, -8*$e;             # u^1 term
  push @rca, -4*$c;             # u^2 term
  push @rca, 8;                 # u^3 term
  my $rc = Yapp(\@rca);         # Turn that into a polynomial
  $rc->variable("u");           # Just for clarity: With variable letter u
  my @rc_solutions = $rc->Yapp_solve();   # (Obvious purpose)
  my $rc_plug;                  # The one we wil plug in to (3)

  # Now life is easier (with fewer rounding errors) if I choose a real solution.
  # I can't be sure it won't return a complex with a *very* low Im part (on the
  # order of 10^-15 ir so) due to rounding errors.  So I merely look for a root
  # with # sufficiently low Im part that I would ignore it.
  #
  foreach my $rc_val (@rc_solutions)        #(Had used $rc_plug here but it went
  {                                         # undefined after loop exit.  Hence
    $rc_plug = $rc_val;                     # using throwaway variable $rv_val
    last if (ref($rc_plug) ne $class_cplx); # It came back as a real! Use it
  }
#
  # Truth be known, *any* one of the roots is usable but I would prefer a real
  # Now plug the found value, $rc_plug, back into (3);
  # Reminder: (3)       (2u -c)X^2 -d*X + (u^2 -e)
  #
  my @rhsa = ();            # Array that will become the above quadratic
  push @rhsa, ($rc_plug**2 -$e);    # Constant term of above quadratic
  push @rhsa, -$d;                  # X^1 term of the quadratic is original
                                    # X^1 term of the root-reduced monic
  push @rhsa, (2*$rc_plug -$c);     # The X^2 term of above quadratic
  if ($testmode)
  {
    my $rhs = Yapp(\@rhsa); #(Actually, it is not necessary to generate
                            # this right-had-side polynomial.)
    printf("RHS Yapp is <%s>\n", $rhs->Ysprint);
  }

  # Testing has confirmed that $rhs is indeed a quadratric perfect square.
  # and that it is the square of yapp(sqrt(c), sqrt(a))
  #
  my $c_sqrt = sqrt($rhsa[0]);      # Since the $rhs polynomial is a square
  my $a_sqrt = sqrt($rhsa[2]);      # I'm guaranteed these are positive.

  # The above quadratic polynomial is the square of either:
  # * +$c_sqrt*X+$a_sqrt      or
  # * -$c_sqrt*X-$a_sqrt
  #
  # Now the perfect square on left-had side, is the square of (X^2 + U) and
  # so the binomia itself may be set equal to either of these:
  # X^2 + U =  AX + C or: X^2 -AX + (U - C) = 0
  # X^2 + U = -Ax - C or: X^2 +AX + (U + C) = 0
  # Where:
  # * U is $rc_plug
  # * A is $a_sqrt
  # * C is $c_sqrt
  # Solve these two quadratics and I have *almost* solved the original quartic.
  #
  my @quad1_a = ( ($rc_plug - $c_sqrt), -$a_sqrt, 1);   # Well, in order to
  my @quad2_a = ( ($rc_plug + $c_sqrt),  $a_sqrt, 1);   # them, it helps to
  my $quad1 = Yapp(\@quad1_a);                          # generate them
  my $quad2 = Yapp(\@quad2_a);
  printf("quad1 = <%s>;\nquad2 = <%s>\n", $quad1->Ysprint, $quad2->Ysprint)
    if ($testmode);
  @solutions[0..1] = $quad1->Yapp_solve();
  @solutions[2..3] = $quad2->Yapp_solve();

  # Not there yet: Remember, I reduced the roots to produce the monic.  Now
  # undo that:
  #
  @solutions = map {$_ + $reduced_by} @solutions;   # Restore what has been
                                                    # taken from them
  return @solutions;
}
#
#-------------------------------------------------------------------------------
# Yapp_solve_odd(): Method to solve polynomial equations of odd degree >= 5
#                   with all real coeficcients.
#
# Parameter:
# - [Ref to] a Yapp polynomial
# Returns:
# - Array of solution set
# Note: Initially, this function supports only polynomials with real-only
# coefficients, although I am leaving a stub block for handling complex
# coefficients as well.
#
sub Yapp_solve_odd
{
  my $self = shift(@_);
  my $crude_margin = 0.1;   # Just get close enough to start using Newton
  my @solutions = ();       # Array that I return to the caller

  # The following pair of betw variables will be set during a bisection
  # algorithm and used for initial values once we start wuth Newton's method.
  # Hence, we need to define them waaaay before they will be used, in order to
  # find them in scope anyplace in this function.
  #
  my $betw_try;               # X-value at midpoint of an interval
  my $betw_eval;              # Y-value at that X midpoint

  # Find one real root and check if it is duplicated.
  # Set up for a bisection algorithm: Starting with some initial guess at
  # 0, 1, and maybe -1, start doubling the interval until I get a + on one
  # side and - on the other.  Then start bisecting until I get pretty
  # close, like within 1/10 or so.  Then start using Newton.
  #
  my $left_try = 0.0;     # First & easiest point to test is X = 0
  my $left_eval = $self->{coeff}[0];  # 'cause I don't need to evaluate
  my $right_try = 1.0;
  my $right_eval = $self->Yapp_eval($right_try);

  # Search for an interval such that the Yapp evaluates to opposite signs
  # at the two endpoints of the interval
  #
  until (($left_eval * $right_eval) < 0)
  { # Entering loop body [again] means both tries evauated to the same
    # sign.  Sweep wider intervals..
    #
    if ($left_try == 0.0)     # At first round of this loop, don't double
    {                         # both enpoints of the interval;
      $left_try = -1.0;       # just expand in negative direction
    }
    else                      # But if we are well into the round
    {                         # we will double both enpoints of the interval
      $left_try *= 2;
      $right_try *= 2;
    }
    # Either way, re-evaluate at both endpoints.  (OK, one wasted,
    # repeated evaluateion at $right_try == 1).  Minor, IMO
    #
    $left_eval  = $self->Yapp_eval($left_try);
    $right_eval = $self->Yapp_eval($right_try);
  }

  # OK, we have found X-values that evaluate to opposite signs.  Now start
  # bisecting scheme.
  #
  until (abs($right_try - $left_try) <= $crude_margin)
  {
    $betw_try  = ($left_try + $right_try)/2 ;     # Bisect the interval
    $betw_eval = $self->Yapp_eval($betw_try);     # Evaluate @ midpoint
    last if ($betw_eval == 0);                    # Hey! We hit an exact root!
    my $left_sign  = $left_eval  >= 0 ? 1 : -1;   # and determine the signs
    my $right_sign = $right_eval >= 0 ? 1 : -1;   # at the endpoints and
    my $betw_sign  = $betw_eval  >= 0 ? 1 : -1;   # midpoint

    # Now mathematically, the sign at the midpoint evaluation must match
    # exactly one (never both) of the endpoint evaluation signs.  Ergo, it
    # must be be different from exactly one of the endpoint evaluations
    #
    if ($left_sign != $betw_sign)                 # Changes sign to left
    {                                             # of the midpoint
      $right_try = $betw_try;                     # Then move right end to
      $right_eval = $betw_eval;                   # middle, with its evaluate
    }
    else                                          # Changed sign to right
    {                                             # of the midpoint
      $left_try  = $betw_try;                     # Then move left end to
      $left_eval = $betw_eval;                    # middle, with its evaluate
    }
  }

  # OK, however we got here, we are now close enough to a solution to start
  # using the Newton method. That is, unless we actually hit an exact root!
  #
  $solutions[0] = ($betw_eval == 0.0) ?     # Start at latest midpoint
                  $betw_try : $self->Yapp_newton($betw_try);
  my ($zero, $quotient) = $self->Yapp_eval($solutions[0]);
                                    #(A good debugging step would be to check
                                    # that $zero is indeed 0.0)
  my $xn = $solutions[0];           #(Shorter var name for neater code)

  # So $xn is a root.  Question: Is it a multiple root?
  #
  while($quotient->{degree} > 0)    # Keep reducing it as we loop
  {
    my ($zzero, $quotient2) = $quotient->Yapp_eval($xn);    # Solves quotient?
    last if (abs($zzero) >= $margin);   # Clearly not. Done checking; Outahere!

    # Still here: It is a solution again!
    #
    $quotient = $quotient2;             # This is next quotient to use
    push (@solutions, $xn);             # and add same root into solutions set
  }
  # OK, I've exhausted my repeated copies of first root.
  # If anything's left, solve it separately.  But first: How many times was
  # that first root repeated?
  #
#?my $rest_roots = @solutions;          # This will be the starting index
                                        # for a newton-refinement for the
                                        # remaining roots.
  if ($quotient->{degree} > 0)
  {                                     # as repeated and conjugate roots
    my @q_solutions = $quotient->Yapp_solve();  # Solve the deflated polynomial

    # Now, to compensate for additional rounding errors that creep in when
    # solving the lower-degree quotient polynomials, let's up the accuracy;
    # apply Newtons's method to the roots returned by the recursive calls.
    # Laguerre has already been applied to this first root (plus duplicates
    # and conjugates).
    #
    @q_solutions = map {$self->Yapp_newton($_)} @q_solutions;
    push (@solutions, @q_solutions);            # THOSE solutions go into my set
  }
  return @solutions;
}
#
#-------------------------------------------------------------------------------
# Yapp_solve_even(): Method to solve polynomial equations of even degree >= 6
#                    with real-only coefficients
# Also good for solving polynomials with complex coefficients; the only
# difference is that for real-ony, the conjugate of of a complex root is
# guaranteed by theorem to be a root as well.
#
# Parameter:
# - [Ref to] a Yapp polynomial
# Returns:
# - Array of solution set
#
sub Yapp_solve_even
{
  my $self = shift(@_);
  my @solutions = ();       # Array that I return to the caller

  my $start = cplx(.1, .1); # Dumb starting point but we gotta start someplace!
  $solutions[0] = $self->Yapp_laguerre($start);
  my ($zero, $quotient) = $self->Yapp_eval($solutions[0]);  # Deflate a degree
  my ($zzero, $quotient2);          # To test for repeated roots
  my $xn = $solutions[0];           #(Shorter var name for neater code)

  # So $xn is a root.  3 questions:
  # 1. Is it a complex root?  If yes, we can just use its conjugate & # deflate
  # 2. Is it a multiple complex root?
  # 3. If real, is it a multiple real root?
  #
  if (ref($xn) eq $class_cplx)      # Yes to question[1]: Is complex
  {                                 # We have a work-free next solution
    push(@solutions, ~ $xn);        # The conjugate is also a root: Stash it
    ($zero, $quotient) = $quotient->Yapp_eval(~ $xn);   # and deflate a degree
                                                        # $zero == 0; toss it

    # Now start checking for repeats of this complex root. (Question[2])
    #
    while($quotient->{degree} > 0)  # Keep reducing it as we loop
    {
      # Question 2 rephrased: Does the same complex number solve the quotient?
      ($zzero, $quotient2) = $quotient->Yapp_eval($xn); # Evaluate to find out
      last if (abs($zzero) >= $margin); # Clearly not. Done checking; Outahere!

      # Still here: Same complex number *is* a solution again!
      #
      push (@solutions, $xn);       # First, push same root into solutions set
      $quotient = $quotient2;       # Point $quotient to above-deflated version
                                    # Of course, its conjugate is also a root
      push (@solutions, ~ $xn);     # Push its conjugate again into @solutions
      ($zero, $quotient)            # and deflate by the conjugate root
        = $quotient->Yapp_eval(~ $xn);
    }
  }
  else                              # Solution is real.  No free conjugate ride
  {
    while($quotient->{degree} > 0)  # Keep reducing it as we loop
    {
      ($zzero, $quotient2) = $quotient->Yapp_eval($xn); # Also solves quotient?
      last if (abs($zzero) >= $margin); # Clearly not. Done checking; Outahere!

      # Still here: Same real is a solution again!
      #
      $quotient = $quotient2;             # This is next deflated quotient
      push (@solutions, $xn);             # and add same root into solutions set
    }
  }
  # OK, I've exhausted my repeated and/or conjugate copies of first root.
  # If anything's left, solve it separately.
  #
  if ($quotient->{degree} > 0)          # If I have not solved for all roots
  {                                     # as repeated and conjugate roots
    my @q_solutions = $quotient->Yapp_solve();  # Solve the deflated polynomial

    # Now, to compensate for additional rounding errors that creep in when
    # solving the lower-degree quotient polynomials, let's up the accuracy;
    # apply Newtons's method to the roots returned by the recursive calls.
    # Laguerre has already been applied to this first root (plus duplicates
    # and conjugates).
    #
    @q_solutions = map {$self->Yapp_newton($_)} @q_solutions;
    push (@solutions, @q_solutions);            # THOSE solutions go into my set
  }

  return @solutions;
}
#
#-------------------------------------------------------------------------------
# Yapp_solve_complex(): Method to solve for the zeroes of a polynomial with
# complex coeffiecients.  The theorem about roots in conjugate pairs flies
# out the window.
# Same parameter/returns as all others.
#
sub Yapp_solve_complex
{
  my $self = shift(@_);
  my @solutions = ();       # Array that I return to the caller

  my $start = cplx(.1, .1); # Dumb starting point but we gotta start someplace!
  $solutions[0] = $self->Yapp_laguerre($start);
  my ($zero, $quotient) = $self->Yapp_eval($solutions[0]);  # Deflate a degree
  my ($zzero, $quotient2);          # To test for repeated roots
  my ($conj_zero, $conj_quotient);  # To test if conjugate is also a root
  my $xn = $solutions[0];           #(Shorter var name for neater code)

  # So $xn is a root.  3 questions:
  # 1. Is it a complex root?  If yes, we can just use its conjugate & # deflate
  # 2. Is it a multiple complex root?
  # 3. If real, is it a multiple real root?
  #
  if (ref($xn) eq $class_cplx)      # Yes to question[1]: Is complex
  {                                 # We don't have a work-free next solution
    ($conj_zero, $conj_quotient)    # Check: Is conjugate is also a root?
      = $quotient->Yapp_eval(~$xn);   # Create a copy deflated by conjugate
    if (abs($conj_zero) < $margin)    # If conjugate is also a root (Not
    {                                 # likely with complex coefficients)
      push(@solutions, ~$xn);         # Aha! Conjugate is also a solution
      $quotient = $conj_quotient;     # Now $quotient is the deflated Yapp
    }

    # Now start checking for repeats of this complex root. (Question[2])
    #
    while($quotient->{degree} > 0)  # Keep reducing it as we loop
    {
      ($zzero, $quotient2) = $quotient->Yapp_eval($xn); # Solves quotient?
      last if (abs($zzero) >= $margin); # Clearly not. Done checking; Outahere!

      # Still here: Same complex number *is* a solution again!
      #
      push (@solutions, $xn);       # First, push same root into solutions set
      $quotient = $quotient2;       # Point $quotient to above-deflated version
                                    # But is its conjugate also a root?
      ($conj_zero, $conj_quotient)      # Is conjugate is also a root?  Create
        = $quotient->Yapp_eval(~$xn);   # a copy deflated by conjugate
      if (abs($conj_zero) < $margin)    # If conjugate is also a root (Not
      {                                 # likely with complex coefficients)
        push(@solutions, ~$xn);         # Aha! Conjugate is also a solution
        $quotient = $conj_quotient;     # Now $quotient is the deflated Yapp
      }
    }
  }
  else                              # Solution is real; just check for duplicate
  {
    while($quotient->{degree} > 0)  # Keep reducing it as we loop
    {
      ($zzero, $quotient2) = $quotient->Yapp_eval($xn); # Also solves quotient?
      last if (abs($zzero) >= $margin); # Clearly not. Done checking; Outahere!

      # Still here: Same real is a solution again!
      #
      $quotient = $quotient2;             # This is next deflated quotient
      push (@solutions, $xn);             # and add same root into solutions set
    }
  }
  # OK, I've exhausted my repeated and/or conjugate copies of first root.
  # If anything's left, solve it separately.
  #
  if ($quotient->{degree} > 0)          # If I have not solved for all roots
  {                                     # as repeated and conjugate roots
    my @q_solutions = $quotient->Yapp_solve();  # Solve the deflated polynomial

    # Now, to compensate for additional rounding errors that creep in when
    # solving the lower-degree quotient polynomials, let's up the accuracy;
    # apply Newtons's method to the roots returned by the recursive calls.
    # Laguerre has already been applied to this first root (plus duplicates
    # and conjugates).
    #
    @q_solutions = map {$self->Yapp_newton($_)} @q_solutions;
    push (@solutions, @q_solutions);            # THOSE solutions go into my set
  }

  return @solutions;
}
#
#-------------------------------------------------------------------------------
# Interpolation: Effectively a new kind of constuctor, though not pacakged
# as such.  The parameters will always be references to arrays of numbers.
# The 0th array is a set of X values, the 1st array is a set of Y values.
# This is sufficient for laGrange interpolation - the basic colocation
# polynomial,  Additional arrays are for first and successive derivatives.
# The goal is to generate a polynomial of minimum degree whose Y values and
# derivatives at the indicated X-values match the arrays.  All will be
# called via the function Yapp_interpolate(). This will call Yapp_lagrange()
# or Yapp_hermite() as the case requires.
# Calling sequence:
# $yap_interp = Yapp_interpolate(\@x_vals, \@y_vals [,\@d1_vals, # \@d2_vals]);
# Returns:
# - A polynomial whose y values and derivatives match the input.
#
sub Yapp_interpolate
{
  my $self = Yapp("1");     # Create a 0-degree polynomial - just 1
  my $ryapp;                # Polynomial to be returned to caller

  # One validation: All arrays must have the name number of elements

  my $pcount = @_;          # Number of arrays passed to me
  die "Must supply at least two arrays (X and Y values) for interpolation"
    unless $pcount >= 2;

  my $x_vals = $_[0];       # Get -> X-values array
  my $xcount = @{$x_vals};  # How many X-values were given?

  # Validate that all arrays have the same number of elements
  #
  for (my $plc = 1; $plc < $pcount; $plc++)
  {
    my $y_list = $_[$plc];      # -> next array in parameter list
    my $ycount = @{$y_list};    # How many elements does this Y array have?
    die "Y-list[$plc] has $ycount elements; should have $xcount"
      unless ($ycount == $xcount);
  }

  # Still here: OK, we may proceed
  #
  my $y_vals = $_[1];       # Get first set of Y values
  my $derivs = @_;          # How many levels of derivative are wanted?

  $ryapp = ($derivs == 2) ? $self->Yapp_lagrange($x_vals, $y_vals)
                          : $self->Yapp_hermite(@_);
  return ($ryapp);
}
#
#-------------------------------------------------------------------------------
# Yapp_lagrange() - Generate a polynomial using laGrange interpolattion
# Not intended for public use
#
# Parameters:
# - (implicit) A token polynomial,
# - Reference to an array of X-Values
# - Reference to array of Y-values
# Both arrays must be the same size or a fatal error will be generated
# Returns:
# - A polynomial that satisfies all those points.
#
sub Yapp_lagrange
{
  my $self = shift(@_);         # Get my token polynomial
  my ($x_vals, $y_vals) = @_;   # Get my X & Y array references
  my $ryapp = Yapp(0);          # 0-degree poly, with constant: 0


  my $lag_list = Yapp_lag($x_vals, $y_vals);    # Generate laGrange multipliers

  # In case you have not read the long comment in Yapp_lag:
  # Each laGrange multiplier polynomial evaluates to 1 at its designated
  # point and 0 at all the other points.  I will multiply it by the Y-value
  # at that point before adding it to the final polynomial. That way, each
  # laGrange multiplier has a value of Y[i] at X[i]
  #
  my $lagp;
  for (my $xlc = 0; $xlc <= $#{$x_vals}; $xlc++)
  { $ryapp += $lag_list->[$xlc] * $y_vals->[$xlc]; } # Add multilpied multiplier
                                                    # to the result
  return $ryapp;                    # Show what I have built up
}
#
#-------------------------------------------------------------------------------
# Yapp_hermite() - Generate a polynomial using Hermite interpolattion
# Not intended for public use
#
# Parameters:
# - (implicit) A token polynomial,
# - Reference to an array of X-Values
# - Reference to array of Y-values
# - As many references to derivative values.
# Note that as of this release, only a first derivative is supported.
# Others will be ignored.
#
# Returns:
# - A polynomial that satisfies all those points.
#
sub Yapp_hermite
{
  my $self = shift(@_);                 # Get my token polynomial
  my ($x_vals, $y_vals, $yp_vals) = @_; # Get my X, Y, Y' array references

  my $xlc;                              # Loop counter for a few loops below
  my (@U_herm, @V_herm);        # -> arrays of Hermite components

  my $lag_list = Yapp_lag($x_vals, $y_vals);    # Generate laGrange multipliers
  my $lag_prime = ();                           # Array: Derivatives of above
  for ($xlc = 0; $xlc <= $#{$x_vals}; $xlc++)
  {
    $lag_prime->[$xlc] = ($lag_list->[$xlc])->Yapp_derivative(1);
  }

  # Each additive to the Hermite polynomial is the sum of U and V polynomials,
  # as denerated below
  #
  for ($xlc = 0; $xlc <= $#{$x_vals}; $xlc++)
  {
    # First component: V[i](X) = (X - x[i])(Lagrange[i]^2)
    #
    my $lag_squared = ($lag_list->[$xlc])**2;
    my $v_herm1 = Yapp(-$x_vals->[$xlc], 1);  # X - x_vals[i];
    $V_herm[$xlc] = $v_herm1 * $lag_squared;

    # Second component: U[i](X) = [1 - 2L'(x[i])(X-X[i])](Lagrange[i]^2)
    # (Ugly, but it gets you there, like the old Volkswagon slogan :-)
    #
    # Evaluate derivative of current Lagrange multiplier polynomial at x[i]
    #
    my $l_prime = $lag_prime->[$xlc]->Yapp_eval($x_vals->[$xlc]);
    my $u_herm1 = (1 - 2*$l_prime * $v_herm1);  # Still a degree 1 polynomial
    $U_herm[$xlc] = $u_herm1 * $lag_squared;
  }
  # I now have the components for the Hermite polynomial. Now I need to start
  # using the Y and Y' values given>  (Yes, I could have done this addition
  # within the above loop. Clarity over elegance here.)
  #
  my $ryapp = Yapp(0);          # Start with a constant 0 and add to it
  for ($xlc = 0; $xlc <= $#{$x_vals}; $xlc++)
  {
    $ryapp += $y_vals->[$xlc]  * $U_herm[$xlc]
           +  $yp_vals->[$xlc] * $V_herm[$xlc] ;
  }
  return $ryapp;
}
#
#-------------------------------------------------------------------------------
# Yapp_lag() - Function to generate the laGrange polynomials that add up to the
#              laGrange interpolating polynimal.  This code was originally in
#              Yapp_lagrange() but was separated out because it will be useful
#              for the Hermite inerpolation scheme as well.
# This function is not a method and will not be exported, since its use is
# strictly internal.
# Parameters:
# - Reference to an array of X values
# - Reference to array of corresponding Y values
# Returns:
# - Reference to an array of component laGrange polynomials
#
sub Yapp_lag
{
  my ($x_vals, $y_vals) = @_;
  my $xcount = @{$x_vals};      # Number of points in my lists
  my @x_minus;                  # Array of x-x[i] polynomials
  my @grange;                   # Array of largrange 1-point polynomials
                                # I will be returning a reference to this array

  for (my $mlc = 0; $mlc < $xcount; $mlc++)
  {
    $x_minus[$mlc] = Yapp(-($x_vals->[$mlc]), 1);   # X - x_val[mlc]
  }

  # Now build the laGrange set for this set of X points
  #
  for (my $xlc = 0; $xlc < $xcount; $xlc++)
  {
    $grange[$xlc] = Yapp(1);    # Starting point for each laGrange poly
    for (my $mlc = 0; $mlc < $xcount; $mlc++)
    {
      next if ($mlc == $xlc);   # Product of all but current point
      $grange[$xlc] *= $x_minus[$mlc];
    }
    # Coming out of above inner loop, $grange[$xlc] is the product of all
    # the (X - x_val[i]) except the i for the current point ($mlc)
    # The correct laGrange multiplier polynomial is 0 at all but the current
    # point but 1 at the current point. To force this one into that mold:
    # Divide the polynomial by its evaluation at x_val[xlc] (so it is 1 at
    # this point)
    #
    $grange[$xlc]
      /= ($grange[$xlc])->Yapp_eval($x_vals->[$xlc]);
  }
  # Coming out above outer loop, array @grange has all the lagrange polynomials
  # pertaining to this set of points.  That's what the calling function wants.
  #
  return \@grange;              # Return reference to that array
}
#
# Yapp_by_roots(): Constructor to build a polynomial whose roots are in the
# passed array or referenced array.
# Parameter[s]:  Either:
# - A complete array of the roots of the desired polynomial
# - A reference to such an array.
# It is the caller's responsibility to include conjugate pairs of complex roots
# if only real coefficients are desired.
#
sub Yapp_by_roots
{
  # Question: Did user pass me an array or array reference?  Either way I will
  # be stepping through the array using an array reference. That is:
  # - If user passed me a nice array reference, just use it.
  # - Passed me a naked array? Create reference the parameter array.
  #
  my $roots = (ref($_[0]) eq "ARRAY") ? shift(@_) :  \@_ ;

  my $ryapp = Yapp(1);      # Start with nice unit Yapp - Just "1"

  for (my $rlc = 0; $rlc <= $#{$roots}; $rlc++)
  {
    $ryapp *= Yapp(- ($roots->[$rlc]), 1)   # Multiply by (X - $roots[i])
  }
  return $ryapp;            # Bet that looked easy! :-)
}
#
# New section: Orthogonal Polynomials.
# Although the plan is to have sub-classes for all classical kinds of orthognal
# polynomials, I am including all the operations with Legendre orthogonality.
# That is where the inner product is defined as the intergal of (P[1] * P[2])
# taken over the interval [-1,1].  More accurately, since we are allowing for
# complex coefficients, the intergral of (P[1] * conj(P[2]).  Hence, the
# complex inner product is not a commutative operation. (Finkbeiner)
#
# Based on this inner product as a starting point, we will define the following 
# methods:
# - Yapp_norm:     The square root of the inner product of the polynomial with
#                  itself
# - Yapp_normalize: Divide a polynomial by its norm to produce a polynomial
#                  whose norm == 1
# - Yapp_distance: The norm of the difference of two polynomials
# - Yapp_orthoganal: True-false: Are these two Yapp-polynomials orthoganal, that
#                  is, is their inner product 0?
# - Yapp_gramSchmidt: Apply the Gram-Schmidt algorithm to an arbitrary set of
#                 polynomials to produce an array of mutually orthonormal
#                 polynomials.
# - Yapp_genOrthogs: Generate orthogonals based on (1, X, X^2, .. X^n)
#------------------------------------------------------------------------------

# Yapp_innerProd() - Inner product of two Yapps, using the Legendre polynomials.
# Intended for use as an operator: The dot . operator
# Parameters:
# - (Implicit) - The first Yapp as a vector
# - The other Yapp
# Returns:
# - The inner product, which may be complex if any of the coefficients on
#   either side of the operator are complex
#
sub Yapp_innerProd
{
  my ($self, $yapp2) = @_;      # Get my parameters
  printf("\nCalculate inner product of polynomials:\n<%s>\n<%s>\n",
         $self->Ysprint(), $yapp2->Ysprint())
    if ($testmode);

  my $conj2 = ~ $yapp2;              # Conjugate the second parameter
  printf("\nStart with product of:\n<%s>\n\tand\n<%s>\n",
         $self->Ysprint(), $conj2->Ysprint())
    if ($testmode);

  my $yprod = $self * $conj2;   # Get product of yapp1, ~yapp2
  printf("That is:\n<%s>\n", $yprod->Ysprint())
    if ($testmode);

  my $rval = $yprod->Yapp_integral(-1, 1);  # Intergal of the product over
                                            # the classic interval [-1, 1]
  printf("Returning value <%s> as inner product\n", Csprint($rval))
    if ($testmode);

  return $rval;                 # That's the inner product!
}
#
# Yapp_Orthogonal() - True or false: Is one Yapp-vector orthogonal to the
# other? i.e. Is the inner product of the two vectors 0 (or close enough)?
# Parameters:
# - (Implicit) A first Yapp to compare
# - A second Yapp.
# Returns:
# - 0 if not orthogonal
# - 1 if they are
#
sub Yapp_Orthogonal
{
  my ($Y1, $Y2) = @_;           # Get the references
  my $rval = 0;                 # Off to a negative start

  my $innerprod = $Y1 . $Y2;    # Get the inner product of two vectors
  $rval = 1 if (abs($innerprod) <= $margin);    # Changing mind about that NO?
  return $rval;
}
#-----------------------------------------------------------------------------
# Yapp_norm() - The next step after defining an inner product function for a
# vector space is to then make it a normed vector space by defining a "norm"
# function.  The most cooperative norm function seems to be the square root
# of the inner product of a vector with itself.
# Parameter:
# - (Implicit): The Yapp reference
# Returns:
# - The norm value of that vector.
#
sub Yapp_norm
{
  my $self = shift(@_);
  my $norm_squared = $self . $self; # Inner product of vector with itself
  my $norm = sqrt($norm_squared);   # Relying on math to keep it real
  return $norm;                     # That's my return value
}
#-----------------------------------------------------------------------------
# Yapp_normalize(): Divide a Yapp vector by its norm so that the norm of the
# new vector is 1.
# Parameter:
# - (Implicit) The Yapp polynomial
# Returns:
# - A new Yapp, proportional to the original but whose norm == 1
#
sub Yapp_normalize
{
  my $self = shift;
  my $norm = $self->Yapp_norm();    # Get the norm of the Yapp as vector
  my $normed = $self / $norm;       # Create that new Yapp according to specs
  return $normed;                   # Send that back to the caller
}
#
# Yapp_distance() - How "far" is the passed Yapp from the object Yapp?
# Answer: That is the norm (Yapp_norm) of the difference between the two Yapps
#
# Parameters:
# - (Implicit) A Yapp [reference], arbitrarily chosen as the fixed vector
# - The [reference to the] other Yapp
# Returns:
# - The real value that is the norm of the difference
#
sub Yapp_distance
{
  my ($self, $vector) = @_;         # Get the parameter references
  my $diff = $self - $vector;       # Get the difference
  my $rval = $diff->Yapp_norm();    # Get "size" of that difference
  return $rval;
}
#
1;

__END__

=head1 NAME

Math::Yapp - Perl extension for working with Polynomials.  Yes, I know
there are *many!* Polynomial packages.  And like them, I started it for
(geeky) fun, then got obsessed with it as a learning experience.  Enjoy!

=head1 AUTHOR

Jacob Salomon, jakesalomon@yahoo.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, 2015, 2024 by Jacob Salomon

=head1 SYNOPSIS

C<use Math::Complex;>

C<use Math::Yapp;>

The "Math::Complex" is optional but a very strongly recommended, since solving a
polynomial often yields complex numbers

=head2 Constructors

C<< $yp = Math::Yapp->new(); >>        # Degenerate polynomial - no terms

While the new() method is certainly available, your code will look cleaner if
you use this form:

C<< $yp = Yapp(parameter(s)); >>       # Examples follow:

=head3 Real and complex coefficiencts

C<$yp = Yapp(1, -2.178, 3.14, -cplx(1,-3), 5);>    # Notice: Ascending in degree

Yields:  5x^4 +(-1+3i)x^3 +3.14x^2 -2.178x +1

=head3 Same as above, only passed as a I<reference> to an array:

C<my @coef_list = (1, -2.178, 3.14, -cplx(1,-3), 5);>

C<$yp = Yapp(\@coef_list);>

=head3 Generated from a string

You can also generate the polynomial from a string: Note that the sign MUST
precede each term with no intervening space; a space separating the sign from
the term may mess up the matching pattern. Yes, the + sign is optional for the
first term in the string.

C<$yp =  Yapp("5x^4 +(-1+3i)x^3 +3.14x^2 -2.178x +1");>

Note that the order of the terms is unimportant; they get sorted out
automatically as I piece together the structure by exponent.

=head3 Copy Constructor

C<$yp1 = Yapp($yp);>   # Clones $yp to an identical copy w a different reference

=head3 Constructors by interpolation

C<$ypl = Yapp_interpolate(\@xvals, \@yvals);>  # Perform Lagrange interpolation

C<$yph = Yapp_interpolate(\@xvals, \@yvals, \@ypvals);> # Hermite interpolation

Note that the interpolating constructors require array references; otherwise
you run into the elementary error of array-mashing. The Lagrange form, just
X and Y values, generates a polynomial that colocates at each of the points
indicated in the X-Y pairs represented by the arrays.  For The Hermite version
the third array [reference] if for the desired derivative at each point.

Notes on Hermite Interpolation:

=over 3

=item 1. At this time, the author waives Hermite interpolation for more than
the first derivative. :-)

=item 2. The author has succssfully tested Hermite interpolation for up to 6
points in a 64-bit CygWin environment; at 7 points, the calculations seem to
have run into some instability, possibly caused by rounding errors.

=back

=head2 Limitations on interpolation

Ordinary Lagrange interpolation has been tested in 32- and 64-bit Cygwin
environments for up to 7 points with accuracy to 11 decimal places. On the other
hand, with Hermite interpolation with 1 derivative, testing began to fail at
5 points in the 32-bit and at 7 points in the 64-bit environment.  And I'm not
talking about missing by 6th decimal place; the errors became quite gross at
the last points in the arrays.  Hence, in the 64-bit environment, I limited
the Hermite interpolation test to 6 points.  Disappointing.  (I really needed
a Math::BigComplex module based on Math::BigFloat and demand 60-digit accuracy
for some of this stuff!)

My plans for higher-derivative interpolation are hold for this.  (Also for
when I grok the "finite differences" algorithms.)

=head3 Constructing a Yapp polynomial from its roots

C<$yp = Yapp_by_roots(\@root_list);> # Pass reference to an array of roots

C<$yp = Yapp_by_roots(1, 2, -4, cplx(3,4), cplx(3,-1));> # Pass a complete array
to constructor

=head2 Arithmetic of Yapp Polynomials

=head3 Unary Operations

C<$yp2 = !$yp;>                # Change the signs of all coefficients

C<$yp2 = ~$yp;>                # Conjugate complex coefficients

=head3 Addition and Subtraction

C<$yp += 13;>                # Add a real value to the constant term

C<$yp += cplx(2, -5);>       # Add a complex number to the constant term

C<$yp += $yp3;>              # Add another polynomial to this one

C<$yp = $yp1 + $yp2;>        # Add two polynomials, term-by-term

Subtracting polynomials:  Behaves pretty much like the adds so we are
not including all possible examples

C<$yp -= $yp3;>              # Subtract $yp3 from $yp in place

C<$yp = $yp1 - $yp2;>        # Subtract two polynomials, term-by-term

=head3 Multiplication and division:

C<$yp *= 42;>                # Multiply each coefficient by the same number

C<$yp = $yp1 * 42;>          # Multiply as above but return a new polynomial

C<$yp = 42 * $yp1;>          # (Same idea as above)

C<$yp *= $yp2;>   # In-place multiplication of a Yapp polynomial by another

C<$yp = $yp1 * $yp2;>        # Same as above, but not in-place

C<$yp /= 10;>                # Divide all coefficients by a number

Division by a polynomial is not defined in this package, although when I
evaluate a polynomials at, say, x = 3, it is equivalent to dividing by the
small polynomial (x - 3).  Hence, for Yapp_eval (described later), you have
the option of getting the quotient besides the evaluation

=head3 Inner Product

C<$fnum = $yapp1 . $yapp2>  # Notice the dot-operator in place of *.

The inner product depends on the integral method, described later. This is
the inner product for Legendre orhogonality, that is:
Integral[-1,+1]($Y1 * $Y2)dx for real coefficients.

For complex coefficients, it is:
Integral[-1,+1]($Y1 * ~$Y2)dz

Other inner product alternatives, like Laguerre, Hermite and others, are on the
back burner but in separate modules yet to be written (at this time) like
Math::Yapp::Laguerre and other, that inherit all basic methods but differ in
the the inner product operator/method.

=head2 Documented methods and functions:

=head3 Format a polynomial for printing

Ysprint() formats a Yapp object into a string, suitable for printing:
Example: C<< printf("My yapp is: %s\n", $yp1->Ysprint()); >>

By default, Ysprint formats the polynomial as follows:

=over 3

=item * Starting from the high-order exponent, working its way down

=item * All coefficients are displayed with 3 decimal places

=item * Zero coefficients are skipped.

=back

This can be controlled by the following functions, which affect module-global
variables:

=over 3

=item * Yapp_start_high(0);     # Setting FALSE: Start from low-degree terms

=item * Yapp_decimals(2);       # Set number of decimal places to display

=item * Yapp_print0(1);         # Ysprint shall display 0-value coefficients

=back

In all three cases, the newly setvalue is returned.  Oh, and if you call
it without a parameter, it will just return the currently set value.

You can also override the default precision by supplying a parameter to Ysprint;

C<< printf("My yapp is: %s\n", $yp1->Ysprint(6)); >>

The above example will print the coefficients with 6 decimal places, ignoring
the default set by Yapp_decimals(),

=head3 Setting and retrieving the display variable

By default, when formatting the polynomial for display, the "variable" will be
the letter "X".  You can change this to any other string using the variable()
method:

$yp->variable("Xy");      # Sets the "variable" to "Xy"

If you just want to know what variable is set for display, call variable()
with no parameter:

my $varname = $yp->variable();  # Returns that variable string

=head3 Query individual coefficients

my $nterm = $yp->coefficient(3);    # Retrieve the X^3 coefficient

=head3 Retrieve the nth degree coefficient:

my $high_expon = $yp->degree(); # Returns the degree of the polynomial

=head3 Evaluating a polynomial at specified values

my $realvar = $yp->Yapp_eval($areal);

The above plugs the parameter into the polynomial and return the value of the
polynomial at that point.  This works identically when plugging in a complex
number but you should be prepared to have a complex number returned:

my $cplxvar = $yp->Yapp_eval($acplx); 

(Of course, if the polynomial has complex coefficients and you plug in a real
number, you are obviously at high risk of getting back a complex number.)

When you evaluate a polynomial at a certain value, say 3, it is like dividing
the polynomial by (X - 3); the returned value is the "remainder".  (You surely
learned this in high school.)  Now, what of the quotient?  Well, just ask and
you shall receive:

my ($eval, $quotient) = $yp->Yapp_eval($areal);

Of course, this quotient is of reduced degree.

=head3 Reduce the roots of a polynomial by a number

my $ypr = $yp->Yapp_reduce(3);

This applies Horner's method of successive synthetic division to the polyomial.

=head3 Negate the roots of a polynomial

$nr_yapp = $yp->Yapp_negate_roots();

This produces a polynomial whose roots are the negatives of the roots of the
original polynomial.

=head3 Derivatives and Integrals

my $dyp = $yp->Yapp_derivative(n);

This returns [a ref to] another polynomial that is the nth derivative of this
one.  A couple of little notes on this:

=over 3

=item * If n is 0, it just returns the original Yapp reference and you've
accomplished very little.

=item * If n is omitted, it assumes a default value of 1:

=back

my $i_ref = $yp->Yapp_integral();

This returns a reference to a polynomial whose derivative is the given Yapp.
We insert a 0 for the arbitrary constant.

my $i_val = $yp->Yapp_integral($low, $high);

This calculates the value of the definite integral of the given Yapp in the
given interval.

=head3 Solution Set for Polynomials

my @solutions = $yp->Yapp_solve(); # Solve for all real and complex roots

=head2 Inner Product space of Yapp polynomials

=head3 The inner-product operator

For these simplest of orthogonal polynomials, the inner product is the
integral of ($Y1 * ~($Y2)) over the interval [-1, 1].

C<$cplx_num = $Y1 . $Y2;                   # Inner product of two Yapps>

C<< $cplx_num = $Y1->Yapp_innerProd($Y2);    # Alternative form of above >>

C<< $cplx_num = Yapp_innerProd($Y1, $Y2);    # Another alternative form >>

But it's really intended to be invoked by the first form, with the "dot"
operator.

Note: At this time I am not prepared to define the subclasses of polynomals
that depend on the inner product, like the laGuerre, Hermite and some others.

=head3 The norm function

The simplest norm function in any inner-product space is simply the square
root of the inner product of a vector with itself.  This will always
return a real number, even with complex coefficients.

my $norm = $Yp->Yapp_Norm();    # Returns the (Legendre) norm of a polynomial

=head3 Orthognality:

my $perp = $Y1->Yapp_Orthogonal($Y2);   # True/False: Is $Y2 orthogonal to $Y1?
my $perp = Yapp_Orthogonal($Y1, $Y2);   # Either form is just fine

Note: With complex coefficients, $Y1 . $Y2 and $Y2 . $Y1 are conjugates.  This
is consistent with the definition of the inner product of vectors over the
field of complex numbers. (I still remember that from Finkbeiner's Linear
Algebra.)

=head3 Missing functions:

=over 3

=item * A Gram-Schmidt orthogonalization process

=item * Corrolary to above: A Gram-Schmidt orthonormalization process

=item * Generation of a sequence of the first N orthogonal Yapp polynomials
using the recursion relation common to all classes orthogonal polynomials.

=back

I've rushed (ahem ;-) this out before getting those done because I found a
nasty bug in the conjugation operator function.

=head1 DESCRIPTION

Man, if that synopsis don't say it all, what can I possibly add? :-)

OK, as mentioned above, this is a fun project.  The plan, not necessarily all
implemented at the first release, is to provide many kinds of operations on the
polynomials that intimidated us in high school and even college (if you took PDE
or Numerical Analysis).  The usual high-school functions are ordinary arithmetic
on these algebraic expressions, as well as plugging a value in there to get the
result.  (Horner's synthetic division saves a lot of work.)

=head2 Addendum: A Note on Inner products and orthogonal polynomials;

At this stage, the plan is to provide the inner product algorithms for various
classes of inner-product spaces but in separate modules, for example:
Math::Yapp:Tchebycheff or Math::Yapp::Laguerre.
These will use the overloaded "dot" operator.

Once I get around to defining other inner product spaces, this might be a good
place to exercise polymorphism: Use only one norm method and only one
orthogonality test method and have the correct inner product method called
depending on the class of polynomials in the operands.

=head2 EXPORT

This package export the following functions by default. (They are few enough
to be an unlikey source of name-space pollution, IMHO)

=over 3

=item * Yapp(): The constructor that is NOT a method, so you don't have to
                type Math::Yapp::new().

=item * Yapp_interpolate(): The constructor by Lagrange and Hermite
                            interpolation

=item * Yapp_by_roots(): Construct a polynomial by its roots

=item * Yapp_decimals(): Sets or retrives a global setting for how many decimal
                         places to display with each %f-formatted variable.

=item * Yapp_print0(): By default, printing a Yapp will skip any term whose
coefficient is 0. This exported function sets an internal global flag to
either display 0-coefficient terms (1) or to skip them (0)

=item * Yapp_start_high(): By default, printing a Yapp will start from the
highest coefficient, the way we are accustomed to writing a polynomial.  For
some testing purposes and, I imagine, some other applications, it may be neater
to start printing from the low-degree coefficients. This functions sets an
intenal global flag to print high-to-low (default: 1) or low-to-high (0).

=back

=head1 Bugs

Note that the current release of Math::Yapp uses the default floating-point
library of its host system.  It was developed in a Cygwin environment running
under Windows-7.  I discovered some limitations to the 64-bit FP operations
when solving polynomials of degree higher than 8 or using Hermite
interpolation of more than 6 points.  I have researched Math::MPC a bit and
hope to use that in a future release of this module.  However, I encountered
some errors when trying to compile the required MPC, MPFR and GMP C libraries.
So that plan is going on the back burner.

There is some sloppy code in method Ysprint() which produces the correct output
but I would really rather figure out why I needed to add said sloppy code.
The bug this covers up is that the first degree term should display without
exponent, not as X^1.  Similarly, the constant term should display with neither
variable nor exponent, rather than as X^0.  ANd it does, but only due to the
afterthought corrections.

It might be argued that my failure to include higher-order derivatives in the
Hermite interpolation scheme is a bug.  Perhaps by the time I publish the next
release of this module I will have an understanding of  Newton's Method of
Divided Differences.  (Sorry, no promises on that account.)

I have been unable to get unary negation and conjugation operators (! and ~)
to work in-place.  That is: While I can happily set $Y1 = ~ $Y1, I cannot
simply say ~$Y1.

=head1 The usual disclaimers :-)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 Acknowledements

Thanks to John Altom, formerly of CCM Consulting Services, for his help in some
basic (but arguably forgettable) details of the EXPORT behavior.

An old debt of gratitude to [the presumably late] Professor Stanley Preisler,
who taught Numerical Analysis at Polytechnic University in the late '70s.
The course was quite over my head but some stuff remained, as you can see.

=cut
