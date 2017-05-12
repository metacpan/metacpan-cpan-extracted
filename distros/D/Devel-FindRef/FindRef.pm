package Devel::FindRef;

use common::sense;

use XSLoader;
use Scalar::Util;

BEGIN {
   our $VERSION = 1.44;
   XSLoader::load __PACKAGE__, $VERSION;
}

=head1 NAME

Devel::FindRef - where is that reference to my variable hiding?

=head1 SYNOPSIS

  use Devel::FindRef;

  print Devel::FindRef::track \$some_variable;

=head1 DESCRIPTION

Tracking down reference problems (e.g. you expect some object to be
destroyed, but there are still references to it that keep it alive) can be
very hard. Fortunately, perl keeps track of all its values, so tracking
references "backwards" is usually possible.

The C<track> function can help track down some of those references back to
the variables containing them.

For example, for this fragment:

   package Test;

   use Devel::FindRef;
   use Scalar::Util;
                         
   our $var = "hi\n";
   my $global_my = \$var;
   our %global_hash = (ukukey => \$var);
   our $global_hashref = { ukukey2 => \$var };
                           
   sub testsub {
      my $testsub_local = $global_hashref;
      print Devel::FindRef::track \$var;
   }

   my $closure = sub {
      my $closure_var = \$_[0];
      Scalar::Util::weaken (my $weak_ref = \$var);
      testsub;
   };

   $closure->($var);

The output is as follows (or similar to this, in case I forget to update
the manpage after some changes):

   SCALAR(0x7cc888) [refcount 6] is
   +- referenced by REF(0x8abcc8) [refcount 1], which is
   |  the lexical '$closure_var' in CODE(0x8abc50) [refcount 4], which is
   |     +- the closure created at tst:18.
   |     +- referenced by REF(0x7d3c58) [refcount 1], which is
   |     |  the lexical '$closure' in CODE(0x7ae530) [refcount 2], which is
   |     |     +- the containing scope for CODE(0x8ab430) [refcount 3], which is
   |     |     |  the global &Test::testsub.
   |     |     +- the main body of the program.
   |     +- the lexical '&' in CODE(0x7ae530) [refcount 2], which was seen before.
   +- referenced by REF(0x7cc7c8) [refcount 1], which is
   |  the lexical '$global_my' in CODE(0x7ae530) [refcount 2], which was seen before.
   +- the global $Test::var.
   +- referenced by REF(0x7cc558) [refcount 1], which is
   |  the member 'ukukey2' of HASH(0x7ae140) [refcount 2], which is
   |     +- referenced by REF(0x8abad0) [refcount 1], which is
   |     |  the lexical '$testsub_local' in CODE(0x8ab430) [refcount 3], which was seen before.
   |     +- referenced by REF(0x8ab4f0) [refcount 1], which is
   |        the global $Test::global_hashref.
   +- referenced by REF(0x7ae518) [refcount 1], which is
   |  the member 'ukukey' of HASH(0x7d3bb0) [refcount 1], which is
   |     the global %Test::global_hash.
   +- referenced by REF(0x7ae2f0) [refcount 1], which is
      a temporary on the stack.

It is a bit convoluted to read, but basically it says that the value
stored in C<$var> is referenced by:

=over 4

=item - the lexical C<$closure_var> (0x8abcc8), which is inside an instantiated
closure, which in turn is used quite a bit.

=item - the package-level lexical C<$global_my>.

=item - the global package variable named C<$Test::var>.

=item - the hash element C<ukukey2>, in the hash in the my variable
C<$testsub_local> in the sub C<Test::testsub> and also in the hash
C<$referenced by Test::hash2>.

=item - the hash element with key C<ukukey> in the hash stored in
C<%Test::hash>.

=item - some anonymous mortalised reference on the stack (which is caused
by calling C<track> with the expression C<\$var>, which creates the
reference).

=back

And all these account for six reference counts.

=head1 EXPORTS

None.

=head1 FUNCTIONS

=over 4

=item $string = Devel::FindRef::track $ref[, $depth]

Track the perl value pointed to by C<$ref> up to a depth of C<$depth> and
return a descriptive string. C<$ref> can point at any perl value, be it
anonymous sub, hash, array, scalar etc.

This is the function you most likely want to use when tracking down
references.

=cut

sub find($);

sub _f($) {
   "$_[0] [refcount " . (_refcnt $_[0]) . "]"
}

sub track {
   my ($ref, $depth) = @_;
   @_ = ();

   my $buf = "";
   my %seen;

   Scalar::Util::weaken $ref;

   my $track; $track = sub {
      my ($refref, $depth, $indent) = @_;

      if ($depth) {
         my (@about) = find $$refref;
         if (@about) {
            for my $about (@about) {
               $about->[0] =~ s/([^\x20-\x7e])/sprintf "\\{%02x}", ord $1/ge;
               $buf .= "$indent" . (@about > 1 ? "+- " : "") . $about->[0];
               if (@$about > 1) {
                  if ($seen{ref2ptr $about->[1]}++) {
                     $buf .= " " . (_f $about->[1]) . ", which was seen before.\n";
                  } else {
                     $buf .= " " . (_f $about->[1]) . ", which is\n";
                     $track->(\$about->[1], $depth - 1, $about == $about[-1] ? "$indent   " : "$indent|  ");
                  }
               } else {
                  $buf .= ".\n";
               }
            }
         } else {
            $buf .= "$indent   not found anywhere I looked :(\n";
         }
      } else {
         $buf .= "$indent   not referenced within the search depth.\n";
      }
   };

   $buf .= (_f $ref) . " is\n";

   $track->(\$ref, $depth || $ENV{PERL_DEVEL_FINDREF_DEPTH} || 10, "");
   $buf
}

=item @references = Devel::FindRef::find $ref

Return arrayrefs that contain [$message, $ref] pairs. The message
describes what kind of reference was found and the C<$ref> is the
reference itself, which can be omitted if C<find> decided to end the
search. The returned references are all weak references.

The C<track> function uses this to find references to the value you are
interested in and recurses on the returned references.

=cut

sub find($) {
   my ($about, $excl) = &find_;
   my %excl = map +($_ => undef), @$excl;
   grep !($#$_ && exists $excl{ref2ptr $_->[1]}), @$about
}

=item $ref = Devel::FindRef::ptr2ref $integer

Sometimes you know (from debugging output) the address of a perl value you
are interested in (e.g. C<HASH(0x176ff70)>). This function can be used to
turn the address into a reference to that value. It is quite safe to call
on valid addresses, but extremely dangerous to call on invalid ones.  I<No
checks whatsoever will be done>, so don't use this unless you really know
the value is the address of a valid perl value.

   # we know that HASH(0x176ff70) exists, so turn it into a hashref:
   my $ref_to_hash = Devel::FindRef::ptr2ref 0x176ff70;

=item $ptr = Devel::FindRef::ref2ptr $reference

The opposite of C<ptr2ref>, above: returns the internal address of the
value pointed to by the passed reference. This function is safe to call on
anything, and returns the same value that a normal reference would if used
in a numeric context.

=back

=head1 ENVIRONMENT VARIABLES

You can set the environment variable C<PERL_DEVEL_FINDREF_DEPTH> to an
integer to override the default depth in C<track>. If a call explicitly
specifies a depth, it is not overridden.

=head1 AUTHOR

Marc Lehmann <pcg@goof.com>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, 2008, 2009, 2013 by Marc Lehmann.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1

