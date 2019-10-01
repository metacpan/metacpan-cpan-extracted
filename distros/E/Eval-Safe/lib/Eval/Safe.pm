package Eval::Safe;

use 5.022;
use strict;
use warnings;

use Carp;
use Eval::Safe::Eval;
use Eval::Safe::Safe;
use List::Util qw(none);
use Scalar::Util qw(reftype refaddr);

our $VERSION = '0.02';

sub new {
  my ($class, %options) = @_;
  croak "Eval::Safe->new called with invalid class name: $class" unless $class eq 'Eval::Safe';
  my @known_options = qw(safe strict warnings debug package force_package);
  my @unknown_options = grep {my $k = $_; none { $k eq $_ } @known_options } keys %options; 
  if (@unknown_options) {
    croak "Unknown options: ".join(' ', @unknown_options);
  }
  $options{strict} = _make_pragma('strict', $options{strict});
  $options{warnings} = _make_pragma('warnings', $options{warnings});
  if ($options{package} and not $options{force_package}) {
    $options{package} = Eval::Safe::_validate_package_name($options{package});
    croak "Package $options{package} already exists" if eval "%$options{package}::";
  }
  if ($options{safe} // 0 > 0) {
    return Eval::Safe::Safe->new(%options);
  } else {
    return Eval::Safe::Eval->new(%options);
  }
}

sub package {
  my ($this) = @_;
  return $this->{package};
}

sub wrap {
  my ($this, $code) = @_;
  return $this->eval("sub { ${code} }");
}

sub share {
  my ($this, @vars) = @_;
  my $calling_package = caller;
  $this->share_from($calling_package, @vars);
}

sub share_from {
  my ($this, $package, @vars) = @_;
  $package = _validate_package_name($package);
  croak "Package $package does not exist" unless eval "%${package}::";
  for my $v (@vars) {
    croak "Variable has no leading sigil: $v" unless $v =~ m'^([&*$%@])(\w+)$';
    my ($sigil, $symbol) = ($1, $2);
    # There are only 5 different sigils, so we could skip the eval here and
    # instead branch on the $sigil and use a syntax like the one on the left of
    # the equal (e.g. \&{$package."::$symbol"}). See:
    # https://metacpan.org/source/MICB/Safe-b2/Safe.pm
    no strict 'refs';
    *{($this->package())."::${symbol}"} = eval "\\${sigil}${package}::${symbol}";
  }
}

sub var_ref {
  my ($this, $var) = @_;
  croak "Variable has no leading sigil: $var" unless $var =~ m'^([&*$%@])(\w+)$';
  # There are only 5 different sigils, so we could skip the eval here and
  # instead branch on the $sigil. See:
  # https://metacpan.org/source/MICB/Safe-b2/Safe.pm
  no strict 'refs';
  return eval sprintf '\%s%s::%s', $1, $this->package(), $2;
}

sub interpolate {
  my ($this, $str) = @_;
  # It's not clear if Text::Balanced could help here.
  my $r = $this->eval("<<\"EVAL_SAFE_EOF_WORD\"\n${str}\nEVAL_SAFE_EOF_WORD\n");
  $r =~ s/\n$//;
  return $r;
}

# _make_pragma('pragma', $arg)
# Returns a string saying "no pragma" if $arg is false, "use pragma" if arg is
# a `true` scalar, "use pragma $$arg" if arg is a scalar reference, and
# "use pragma @$arg" if arg is an array reference.
sub _make_pragma() {
  my ($pragma, $arg) = @_;
  my $reftype = reftype $arg;
  if (not defined $reftype) {
    if ($arg) {
      return "use ${pragma};";
    } else {
      return "no ${pragma};";
    }
  } elsif ($reftype eq 'SCALAR') {
    return "use ${pragma} '$arg';";
  } elsif ($reftype eq 'ARRAY') {
    # We should probably use Data::Dumper to format the arg list properly in
    # case some of the args contain a space.
    return ("use ${pragma} qw(".join(' ', @$arg).');');
  } elsif ($reftype eq 'HASH') {
    return ("use ${pragma} qw(".join(' ', %$arg).');');
  } else {
    croak "Invalid argument for '${pragma}' option, expected a scalar or array reference";
  }
}

# $safe->_wrap_code_refs('sub', @objects)
# will call $safe->sub($ref) for all code references found within @objects and
# store the result in place in @objects. The passed objects are crawled
# recursively.
# Finally, the modified array is returned.
#
# This is similar to the wrap_code_refs_within method in Safe.
sub _wrap_code_refs {
  my ($this, $wrapper) = splice @_, 0, 2;
  # We need to use @_ below (without giving it a new name) to retain its
  # aliasing property to modify the arguments in-place.
  my %seen_refs = ();
  my $crawler = sub {
    for my $item (@_) {
      my $reftype = reftype $item;
      next unless $reftype;
      next if ++$seen_refs{refaddr $item} > 1;
      if ($reftype eq 'ARRAY') {
          __SUB__->(@$item);  # __SUB__ is the current sub.
      } elsif ($reftype eq 'HASH') {
          __SUB__->(values %$item);
      } elsif ($reftype eq 'CODE') {
          $item = $this->$wrapper($item);
      }
      # We're ignoring the GLOBs for the time being.
    }
  };
  $crawler->(@_);
  if (defined wantarray) {
    return (wantarray) ? @_ : $_[0];
  }
  return;
}

# _validate_package_name('package::name')
# Croaks (dies) if the given package name does not look like a package name.
# Otherwise returns a cleaned form of the package name (trailing '::' are
# removed, and '' or '::' is made into 'main').
sub _validate_package_name {
  my ($p) = @_;
  $p =~ s/::$//;
  $p = 'main' if $p eq '';
  croak "${p} does not look like a package name" unless $p =~ m/^\w+(::\w+)*$/;
  return $p;
}

1;

__DATA__

=pod

=head1 NAME

Eval::Safe - Simplified safe evaluation of Perl code

=head1 SYNOPSIS

B<Eval::Safe> is a Perl module to allow executing Perl code like with the
B<eval> function, but in isolation from the main program. This is similar to the
L<Safe> module, but faster, as we don't try to be safe.

  my $eval = Eval::Safe->new();
  $eval->eval($some_code);
  $eval->share('$foo');  # 'our $foo' can now be used in code provided to eval.

=head1 DESCRIPTION

The standard B<Safe> module does 4 things when running user-provided code:
compiling and running the string as Perl code; running the code in a specific
package so that variables in the calling code are not modified by mistake;
hiding all the existing packages so that the executed code cannot modify them;
and limiting the set of operations that can be executed by the code to further
try to make it safe (prevents it from modifying the system, etc.).

By comparison, the B<Eval::Safe> module here only does the first two of these
things (compiling the code and changing the namespace in which it is executed)
to make it conveniant to run user-provided code, as long as you can trust that
code. The benefit is that this is around three times faster than using L<Safe>
(especially for small pieces of code).


=head2 CONSTRUCTOR/DESTRUCTOR

=head3 B<new(%options)>

Creates a new Eval::Safe object. Some options may be passed to this call:

=over 4

=item B<safe> => I<int>

If passed on positive value, then the evaluation of the code will use the
B<Safe> module instead of the B<eval> function. This is slower but means that
the code won't be able to read or modify variables from your code unless
explicitly shared.

=item B<strict> => I<options>

If passed a C<true> value then the code executed by the Eval::Safe object will
be compiled under C<use strict>. You can pass a reference to an array or hash
to provide options that are passed to the C<use strict> pragma.

=item B<warnings> => I<options>

If passed a C<true> value then the code executed by the Eval::Safe object will
be compiled under C<use warnings>. You can pass a reference to an array or hash
to provide options that are passed to the C<use warnings> pragma.

=item B<debug> => I<FILE>

Sets debug mode. You should pass this option a file reference to which the debug
output will be written. This is typically C<*STDERR>.

=item B<package> => I<string>

Specify explicitly the package that will be used to compile the code passed to
the Eval::Safe object. This must be a valid package name and the package itself
must not yet exist.

Note that if you have explicit mention of this package in your code then the
Perl compiler will auto-vivify the package and it will fail the "must not exist
yet" test. You can work around this limitation either by wrapping such reference
to the package in an C<eval(str)> call, or by using the B<force_package> option
below.

=item B<force_package> => I<boolean>

Remove all check on the package name specified with B<package> (both in term of
validity and of existance).

Be careful that by default the package will be deleted when the Eval::Safe
object is deleted. This means that existing variables that would refer to that
package are no longer valid, even assigning to these variable will not re-create
the package (unless the code setting the variable is compiled again through an
C<eval(str)> expression or you're using a string as a reference to the package
or variable).

=back

=head3 destructor

When the object goes out of scope, its main package and all its sub-packages are
deleted automatically.

=head2 METHODS

=head3 B<eval($code)>

Executes the given string as Perl code in the environment of the current object.

The current package seen by the code will be a package specific to the
Safe::Eval object (that is initially empty). How that package is exposed depends
on the value of the B<safe> option passed to the constructor, if any. If the
option was not passed (or was passed a C<false> value), then the code will have
access to the content of all the existing packages and will see the real name
of its package. If the B<safe> option was passed a C<true> value, then the code
will believe that it runs in the root package and it will not have access to the
content of any other existing packages.

In all cases, if the code passed to C<eval> cannot be compiled or if it dies
during its execution, then the call to C<eval> will return C<undef> and C<$@>
will be set.

If the call returns a code reference or a data-structure that contains code
references, these references are all modified so that when executed they will
run as if through this C<eval> method. In particular, exceptions will be trapped
and C<$@> will be set instead. This property is recursive to all the
code-references possibly returned in turn by these functions.

=head3 B<wrap($code)>

Returns a code-reference that, when executed, execute the content of the Perl
code passed in the string in the context of the Eval::Safe object. This call is
similar to C<$eval->eval("sub { STR }")>.

=head3 B<share('$var', '@foo', ...)>

Shares the listed variables from the current package with the Perl environment
of the Eval::Safe object. The list must be a list of strings containing the
names of the variables to share, including their leading sigils (one of B<$>,
B<@>, B<%>, B<&>, or B<*>). When sharing a glob (C<*foo>) then all the C<foo>
variables are shared.

=head3 B<share_from('Package', '$var', ...)>

Shares the listed variables from a specific package. The variables are shared
into the main package of the Perl environment of the Eval::Safe object as when
using the C<share> method.

=head3 B<package()>

Returns the name of the package used by the Eval::Safe object. This is the
package that was passed to the constructor if one was specified explicitly.

=head3 B<interpolate($str)>

Interpolates the given string in the environment of the Eval::Safe object.

=head3 B<var_ref('$var_name')>

Returns a reference to the variable whose name is given from the Eval::Safe
object package. The variable name must have its leading sigil (one of B<$>,
B<@>, B<%>, B<&>, or B<*>).

=head3 B<do('file_name')>

Loads the given file name into the environment of the Eval::Safe object. The
file name may be relative or absolute but the B<@INC> array is not used (as
opposed to the standard B<do> function).

If B<do> can read the file but cannot compile it, it returns undef and sets an
error message in B<$@>. If do cannot read the file, it returns undef and sets
B<$!> to the error. Always check B<$@> first, as compilation could fail in a
way that also sets B<$!>. If the file is successfully compiled, do returns the
value of the last expression evaluated.

=head1 CAVEATS

To bypass a bug with the Safe that hides all exceptions that could occur in code
wrapped by it, this module is currently using a forked version of the standard
Safe module. This may cause issues as that module relies on undocumented
internals of Perl that are maybe subject to change.

=head1 AUTHOR

This program has been written by L<Mathias Kende|mailto:mathias@cpan.org>.

=head1 LICENCE

Copyright 2019 Mathias Kende

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

L<Safe>, L<eval>

=cut