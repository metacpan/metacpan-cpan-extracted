package Geo::Postcodes::NO::Tutorial;

1;

__END__

=encoding UTF-8

=head1 NAME

Geo::Postcodes::NO::Tutorial - How to use Geo::Postcodes::NO

=head1 SYNOPSIS

  use Geo::Postcodes::NO;

  my $postcode = '1178';
  my $location = Geo::Postcodes::NO::location_of($postcode);

=head1 INSTALLING

C<Geo::Postcodes::NO> is self-contained: unlike the historical module, it no
longer depends on the separate C<Geo::Postcodes> distribution, so installing it
pulls in nothing else. Install or update it from CPAN with C<cpanm>
(preferably as root):

  shell> cpanm Geo::Postcodes::NO

If you do not have C<cpanm> yet, install it first:

  shell> cpanm App::cpanminus

The module bundles Bring's postcode table. Bring refreshes that table from time
to time, so updating the module from CPAN is the easiest way to pick up a newer
table; see the C<DATA> section of the module documentation for details.

=head1 USING

Include the following line in the program, after installing the module:

  use Geo::Postcodes::NO;

=head1 VERIFYING

=head2 legal

Use the C<legal> procedure to check that the specified postcode is legal, i.e.
that it follows the syntax rules for Norwegian postcodes. Norwegian postcodes
are exactly four digits.

  $boolean = Geo::Postcodes::NO::legal('ABBA'); # 0 -> Illegal
  $boolean = Geo::Postcodes::NO::legal('0900'); # 1 -> Legal
  $boolean = Geo::Postcodes::NO::legal('1178'); # 1 -> Legal

=head2 valid

The C<valid> procedure checks if the postcode is valid, that it is in actual
use in the bundled Bring file. The code may or may not be legal.

  $boolean = Geo::Postcodes::NO::valid('1178'); # 1 -> In use
  $boolean = Geo::Postcodes::NO::valid('ABBA'); # 0 -> Not in use

=head1 FIELDS

Norwegian postcodes support the fields C<postcode>, C<location>, C<borough>,
C<borough_number>, C<county>, C<type>, and C<type_verbose>. Every field is
available as C<$P->xxx()> or C<xxx_of($postcode)>, where C<xxx> is the field
name. The procedures/methods return I<undef> if the value is unspecified for
the given postcode.

There is no C<owner> or C<address> field; those were used by other countries'
modules and are not part of the Norwegian data.

=head2 postcode - postcode_of

  $postcode = $P->postcode();
  $postcode = Geo::Postcodes::NO::postcode_of($postcode); # Silly

The actual C<postcode> value is available with the C<postcode> method, as the
object itself does not carry it in an obvious place. The corresponding
C<postcode_of> procedure is used internally by L<selection> and should be
avoided in applications.

=head2 location - location_of

  $location = $P->location();
  $location = Geo::Postcodes::NO::location_of($postcode);

The location (or postal location) of the postcode. This is the value shown
after the postcode in addresses.

=head2 borough_number - borough_number_of

  $borough_number = $P->borough_number();
  $borough_number = Geo::Postcodes::NO::borough_number_of($postcode);

The municipality (borough) number, a four-digit number. The first two digits
identify the county.

=head2 borough - borough_of

  $borough = $P->borough();
  $borough = Geo::Postcodes::NO::borough_of($postcode);

The name of the municipality (borough) where the postcode is located.

=head2 county - county_of

  $county = $P->county();
  $county = Geo::Postcodes::NO::county_of($postcode);

The name of the county where the postcode is located, derived from the first
two digits of the municipality number.

=head2 type - type_of

  $type = $P->type();
  $type = Geo::Postcodes::NO::type_of($postcode);

The type of the postcode, as a short (two-character) code. The legacy type
codes are:

=over

=item BX

Post Office box.

=item ST

Street address.

=item SX

Service box (as a Post Office box, but the mail is delivered to the customer).

=item IO

Individual owner (a company with its own postcode).

=item STBX

Either a Street address (ST) or a Post Office box (BX).

=item MU

Multiple usage (a mix of the other types).

=item PP

Porto Paye receiver (mail where the receiver pays the postage).

=item PN

Place name.

=back

Bring's own category letter is available separately with
L</bring_category_of>; the C<type_of> method maps those letters onto the legacy
codes above.

=head2 type_verbose - type_verbose_of

A textual description of the type code, as the codes themselves are not very
user friendly.

  $norwegian_description = $P->type_verbose();
  $norwegian_description = Geo::Postcodes::NO::type_verbose_of($postcode);

This gives the description in Norwegian. Use the C<type2verbose_english>
procedure for the English version:

  $english_description = Geo::Postcodes::NO::type2verbose_english($P->type());

=head2 bring_category_of

  $category = Geo::Postcodes::NO::bring_category_of($postcode);

Returns Bring's raw category letter for the postcode: C<G>, C<P>, C<B>, or
C<S>. These map to the legacy type codes as follows:

=over

=item G

Street address (C<ST>).

=item P

Post Office box (C<BX>).

=item B

Street address and Post Office box (C<STBX>).

=item S

Service box (C<SX>).

=back

=head1 MAKING

The module can be used as procedures on postcodes, or object oriented.

=head2 Example Using Procedures

  my $postcode = '1178';
  if (Geo::Postcodes::NO::valid($postcode))
  {
    printf "Postcode:         '%s'\n", $postcode;
    printf "Postal location:  '%s'\n", Geo::Postcodes::NO::location_of($postcode);
    printf "Borough number:   '%s'\n", Geo::Postcodes::NO::borough_number_of($postcode);
    printf "Borough:          '%s'\n", Geo::Postcodes::NO::borough_of($postcode);
    printf "County:           '%s'\n", Geo::Postcodes::NO::county_of($postcode);
    printf "Postcode type:    '%s'\n", Geo::Postcodes::NO::type_of($postcode);
    printf "- in norwegian:   '%s'\n", Geo::Postcodes::NO::type_verbose_of($postcode);
    printf "- in english:     '%s'\n",
        Geo::Postcodes::NO::type2verbose_english(Geo::Postcodes::NO::type_of($postcode));
  }

The fields are described in the previous section; L</FIELDS>.

=head2 Object Oriented Example

  if (Geo::Postcodes::NO::valid($postcode))
  {
    my $P = Geo::Postcodes::NO->new($postcode);
    printf "Postcode:         '%s'\n", $P->postcode();
    printf "Postal location:  '%s'\n", $P->location();
    printf "Borough number:   '%s'\n", $P->borough_number();
    printf "Borough:          '%s'\n", $P->borough();
    printf "County:           '%s'\n", $P->county();
    printf "Postcode type:    '%s'\n", $P->type();
    printf "- in norwegian:   '%s'\n", $P->type_verbose();
    printf "- in english:     '%s'\n",
        Geo::Postcodes::NO::type2verbose_english($P->type());
  }

If speed is a concern, use the procedure version.

=head2 new

  my $P = Geo::Postcodes::NO->new($postcode);

Create a new postcode object. Internally this calls the C<xxx_of> procedures
for the fields supported by Norwegian postcodes. The constructor returns
I<undef> if given an invalid or illegal postcode. Do not try method calls on
the result in that case, as it is not an object (and will result in a runtime
error). See the description of the I<legal> and I<valid> procedures above.

=head1 COMPACT

The test for a valid postcode can also be done on the object itself, as it will
be I<undef> when passed an illegal or invalid postcode (and thus no object at
all). The example in the previous section had a line for each field, but it is
possible to use a loop instead:

  if ($P = Geo::Postcodes::NO->new($postcode))
  {
    foreach my $field (Geo::Postcodes::NO::get_fields())
    {
      printf("%-20s %s\n", ucfirst($field), $P->$field());
    }
  }

This will B<not> show the English description of the type, and the printed
labels are slightly different than in the previous example.

=head2 get_fields

Use this procedure to get a list of the supported fields for Norwegian
postcodes.

  my @fields = Geo::Postcodes::NO::get_fields();

=head2 is_field

Use this procedure to check if the specified field exists for Norwegian
postcodes.

  my $boolean = Geo::Postcodes::NO::is_field($field);

=head2 A sample program

This sample program prints every supported field for each postcode given on the
command line. Specify one or more postcodes; for example
C<perl eg/basic.pl 1178 3201>. The full program is in the C<eg/> directory of
the distribution; the heart of it is:

  foreach my $postcode (@ARGV)
  {
    if (my $P = Geo::Postcodes::NO->new($postcode))
    {
      foreach my $field (Geo::Postcodes::NO::get_fields())
      {
        printf("%-10s\t%s\n", ucfirst($field), $P->$field() || "");
      }
    }
  }

The C<new> call returns an object reference on success and I<undef> on failure
(an illegal or unused postcode); the full program distinguishes the two cases
with C<legal>.

=head1 ADVANCED

The procedures and methods mentioned so far give one (or zero) postcode at a
time, but it is possible to get I<several postcodes> at once.

=head2 get_postcodes

  @postcodes =      Geo::Postcodes::NO::get_postcodes(); # Unsorted
  @postcodes = sort Geo::Postcodes::NO::get_postcodes(); # Sorted

This procedure returns an unsorted list of all the postcodes. It is possible to
use this call to write your own selection code:

  my @list;
  foreach my $postcode (Geo::Postcodes::NO::get_postcodes())
  {
    push(@list, $postcode) if check_the_postcode_for_something($postcode);
  }

Write the C<check_the_postcode_for_something> procedure to decide if the
postcode should be included, using the C<xxx_of> procedures or whatever else is
needed. Do I<not> create postcode objects inside this loop, as this will
increase the execution time quite a lot.

=head2 selection

The module has a selection procedure/method, that can be used if the check can
be expressed as a regular expression on one or more of the fields. See the
selection manual (C<perldoc Geo::Postcodes::NO::Selection> or C<man
Geo::Postcodes::NO::Selection>) for further information.

=head2 selection_loop

This procedure/method can be used to get rid of the loop in the following
example:

  my @list = Geo::Postcodes::NO::selection(...);
  foreach my $postcode (@list)
  {
    do_something($postcode);
  }

The following line of code does the same thing:

  Geo::Postcodes::NO::selection_loop(\&do_something, ...);

The loop can use postcode objects instead of plain postcodes, as with
L</selection>:

  Geo::Postcodes::NO->selection_loop(\&do_something, ...);

The benefit of this is that the C<selection> method generates all the postcode
objects before passing them on, while this method generates one at a time.

=head2 verify_selectionlist

This checks the list of arguments for correctness, and should be used before
calling C<selection> or C<selection_loop>. The procedure returns a modified
version of the arguments on success, and diagnostic messages on failure.

  my ($status, @modified) = Geo::Postcodes::NO::verify_selectionlist(@args);
  if ($status)
  {
    my @result = Geo::Postcodes::NO::selection(@modified);
    # And do something with the list of postcodes.
  }
  else
  {
    print "Diagnostic messages:\n";
    map { print " - $_\n" } @modified;
  }

=head2 A second program

This sample program prints a header line and one line per matching postcode for
a given field and value. Specify a field and a value on the command line, for
example C<perl eg/selection.pl county OSLO>. The full program is in the C<eg/>
directory; the heart of it is:

  Geo::Postcodes::NO->selection_loop(\&print_it, $field, $value);

  sub print_it
  {
    my $object = shift;
    foreach my $method (@fields)
    {
      printf("%-14s", $object->$method() || "");
    }
    print "\n";
  }

The C<selection_loop> method finds the matching postcodes and passes them on as
postcode objects to C<print_it>, one at a time. The C<|| ""> in the C<print>
statement traps warnings, as the accessor returns I<undef> when a value is
unspecified for the given postcode.

=head2 A third program

This sample program accepts a full selection argument list on the command line,
for example C<perl eg/multiselection.pl county OSLO "and not" type BX>. The full
program is in the C<eg/> directory; the heart of it is:

  my ($status, @lines) = Geo::Postcodes::NO::verify_selectionlist(@ARGV);
  # ... print usage and diagnostics if $status is 0 ...
  foreach my $P (Geo::Postcodes::NO->selection(@lines))
  {
    # print one line per field for each matching postcode
  }

Simply passing a list of arguments to C<selection> is not a good idea, as it
returns an empty list I<both on failure> (syntax errors, illegal modes or
fields) and when the call matched nothing. C<verify_selectionlist> checks the
argument list for errors first; the C<$status> variable is true if the list is
legal and false otherwise. The C<@lines> variable holds the (possibly
normalised) argument list on success, or the diagnostic messages on failure.

=head2 Advanced selection

The arguments to the C<selection> procedure/method are not restricted to pairs
of field/value combined with the logical operators C<and>, C<or>, and so on. It
is also possible to call an external procedure and have it decide if the
postcode should be included. Specify C<'procedure'> and
C<\&procedure_to_do_the_job> instead of a field/value pair. The procedure is
passed the postcode and must return true or false.

  sub procedure_to_do_the_job
  {
    my $postcode = shift;
    return 1 if ...;
    return 0;
  }

Passing a reference to a non-existing procedure to C<selection> results in an
empty list. C<verify_selectionlist> can be used to check that any specified
procedures actually exist.

=head2 A fourth program

This sample program combines a regular expression with an external procedure
that does something a regular expression cannot. The full program is in the
C<eg/> directory (C<eg/advanced.pl>); the heart of it is:

  my @arg1 = ('postcode' => '(..)\1');
  my @postcodes = Geo::Postcodes::NO::selection(@arg1);

  my @arg2 = (@arg1, 'procedure' => \&selector_procedure);
  @postcodes = Geo::Postcodes::NO::selection(@arg2);

  sub selector_procedure
  {
    my $postcode = shift;
    my $location = Geo::Postcodes::NO::location_of($postcode);
    my $digest   = Digest::SHA::sha1_hex($location);
    return 1 if substr($digest, 10, 5) =~ /[a-f]/;
    return 0;
  }

The procedure computes the SHA-1 digest of the postal location and returns true
if there is a hex digit among the 11th to 15th characters of the digest. This
may not be very useful in practice, but it shows how a procedure extends a
selection.

=head1 SEE ALSO

L<Geo::Postcodes::NO> and L<Geo::Postcodes::NO::Selection>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2026 by Arne Sommer - perl@bbop.org

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut