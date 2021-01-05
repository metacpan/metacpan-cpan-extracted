package Devel::WatchVars;

=encoding utf8

=cut

use utf8;
use strict;
use warnings;
no overloading;

use Carp;
use Scalar::Util qw(weaken readonly reftype);

use namespace::clean;

###########################################################

our $VERSION = "v1.0.5";

use Exporter qw(import);
our @EXPORT = qw(watch unwatch);

###########################################################

my $TIE_PACKAGE = __PACKAGE__ . "::Tie::Scalar";
{ 
    local $@;
    die unless eval "require $TIE_PACKAGE; 1";
}

###########################################################

sub watch(\$;$) {
    my($sref, $name) = @_;
    my $reftype = ref($sref) && reftype($sref);

    $reftype =~ /^(?:SCALAR|REF)\z/ || 
        croak "You didn't pass a SCALAR (by reference), you passed a ",
              $reftype       ? "$reftype (by reference)"
            : defined($sref) ? "non-reference"
            :                  "undef";

    !readonly($$sref)           || croak "Can't watch a readonly scalar";

    my $value = $$sref;
    my $self  = tie $$sref, $TIE_PACKAGE, $name, $value;
    weaken($$self{sref} = $sref);
}

###########################################################

sub unwatch(\$) {
    my($tref) = @_;
    ref($tref) eq "SCALAR"      || croak "You didn't pass a scalar (by reference)";
    my $self = tied $$tref      || croak "Can't unwatch something that isn't tied";
    $self->isa($TIE_PACKAGE)    || croak "Can't unwatch something that isn't watched";
    my($sref, $value) = @$self{sref => "value"};
    undef $self;
    untie $$tref;
    $$sref = $value if ref($sref) eq "SCALAR";
}

###########################################################

1;

__END__

=head1 NAME

Devel::WatchVars - trace access to scalar variables

=head1 SYNOPSIS

    use Devel::WatchVars qw(watch unwatch);

Start tracing:

    watch $some_var,    '$some_var'; # single quotes so it knows its name
    watch $nums[2],     'element[2] of the @nums array';
    watch $color{blue}, 'the blue element of the %color hash';

    ######################################
    # Do things that access those, then...
    ######################################

End tracing:

    unwatch $color{blue};
    unwatch $nums[2];
    unwatch $some_var;

=head1 DESCRIPTION

The C<Devel::WatchVars> module provides simple tracing of scalars.
The C<watch> function takes the scalar you want traced followed by 
the descriptive string to use as its name in traces.

Here's a simple illustration using a short program, here named F<examples/simple>:

     1	#!/usr/bin/env perl
     2	use v5.10;
     3	use strict;
     4	use warnings;
     5	
     6	use Devel::WatchVars;
     7	sub twice { return 2 * shift  }
     8	
     9	my $x = 10;
    10	watch($x, '$x');
    11	say "starting watched value is $x";
    12	$x = 5 + twice(++$x);
    13	say "ending watched value is $x";
    14	unwatch $x;

When run, that produces the following output:

    WATCH $x = 10 at examples/simple line 10.
    FETCH $x --> 10 at examples/simple line 11.
    starting watched value is 10
    FETCH $x --> 10 at examples/simple line 12.
    STORE $x <-- 11 at examples/simple line 12.
    FETCH $x --> 11 at examples/simple line 7.
    STORE $x <-- 27 at examples/simple line 12.
    FETCH $x --> 27 at examples/simple line 13.
    ending watched value is 27
    UNWATCH $x = 27 at examples/simple line 14.

The trace appears on standard error, one line per access
consisting of the following elements:

=over

=item * 

A word in all capital letters for the type of access, one 
of C<WATCH>, C<FETCH>, C<STORE>, C<UNWATCH>, or C<DESTROY>.

=item *

Whatever string you passed in the second argument.
passed the initial call to C<watch>.

=item *

A bit of intervening text (C<=> or C<< --> >> 
or C<< <-- >>).

=item * 

The scalar value.

=item *

The origin by file and line.

=back

The first argument to C<watch> must be a scalar variable, or a
single scalar element from an array or a hash.  In other words,
that argument needs to begin with a literal dollar sign.

The second argument to C<watch> is an arbitrary string.
Normally its the name of that watched scalar, however you
choose to represent that. This can be useful if you just want to
watch one element from some larger data structure. For example,

    watch $nums[2],     "element[2] of array";

    watch $color{blue}, "the blue color element";

The argument to C<unwatch> must match one that you have previously
called C<watch> with and which you have not yet called C<unwatch> with.

The tracing lasts until you call the C<unwatch> function on the
watched variable to discontinue that tracing, or when that scalar
is destroyed through garbage collection. If it is destroyed while
the program is running, it will say something like:

    DESTROY $x = 9 at examples/destroyed line 15.

but if is destroyed during global destruction, it indicates
this like so:

    DESTROY (during global destruction) $x = 9 at examples/global-destruction line 0.

The C<watch> function is implemented using an internal C<tie>, and 
the C<unwatch> function is implemented using an internal C<untie>.

=head1 EXAMPLES

See the example scripts in the F<examples> subdirectory of 
this module's source distribution.

=head1 ENVIRONMENT

=over

=item DEVEL_WATCHVARS_VERBOSE

Normally, the traces include only a L<shortmess|Carp/shortmess> at the end,
no matter what you've may have set the value of C<$Carp::Verbose> to.
But if the environment variable C<DEVEL_WATCHVARS_VERBOSE> has a true
value, a full L<longmess|Carp/shortmess> will be used instead.

=back

=head1 DIAGNOSTICS

=over

=item "Can't unwatch something that isn't tied"

Runtime error because the scalar you passed is not being watched right now.

=item "Can't unwatch something that isn't watched"

Runtime error because the scalar you passed is tied to some other class.

=item "Can't watch a readonly scalar"

The scalar variable you want to watch contains a readonly value.

=item "Type of arg 1 to Devel::WatchVars::unwatch must be scalar (not %s)"

Attempting to pass something to C<unwatch> that does
not begin with a literal dollar sign will produce a compilation 
error in your code like this:

    Type of arg 1 to Devel::WatchVars::unwatch must be scalar (not hash dereference) at -e line 1

=item "Type of arg 1 to Devel::WatchVars::watch must be scalar (not %s)"

Attempting to pass something to C<watch> that does not begin with
a literal dollar sign will produce a compilation error in your code
like these:

    Type of arg 1 to Devel::WatchVars::watch must be scalar (not constant item) at -e line 1

    Type of arg 1 to Devel::WatchVars::watch must be scalar (not array dereference) at -e line 1

=item "You didn't pass a scalar (by reference)";

=item "You didn't pass a SCALAR (by reference), you passed a %s (by reference)"

These are both runtime errors, and usually possible only if you're
cheating by calling the functions without prototypes being checked.

=back

=head1 TODO

Devise a curried subclassing mechanism.

Add watching entire aggregate arrays and hashes I<en masse>.

=head1 SEE ALSO

=over

=item L<Tie::Watch> 

Place watchpoints on Perl variables using PerlTK.

=item L<Devel::TraceVars>

Mode of the perl debugger to print each line of code with variables evaluated.

=back

=head1 AUTHOR

Tom Christiansen C<< <tchrist53147@gmail.com> >>.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2020-2021 by Tom Christiansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
