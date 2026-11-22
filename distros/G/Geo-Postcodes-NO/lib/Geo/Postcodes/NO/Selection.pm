package Geo::Postcodes::NO::Selection;

1;

__END__

=encoding UTF-8

=head1 NAME

Geo::Postcodes::NO::Selection - How to use the selection procedure/method of
Geo::Postcodes::NO

=head1 INTRODUCTION

This document explains the C<selection> procedure and method of
C<Geo::Postcodes::NO>, using real Norwegian postcodes. The field names are the
ones returned by C<Geo::Postcodes::NO::get_fields()>: C<postcode>, C<location>,
C<borough>, C<borough_number>, C<county>, C<type>, and C<type_verbose>.

=head1 SELECTION

=head2 selection procedure

  my @postcodes = Geo::Postcodes::NO::selection($field => $value);

This simple form returns a sorted list of postcodes matching the given field
and value. The field is one of those returned by
C<Geo::Postcodes::NO::get_fields()>, and the value is a literal string or a
regular expression (see L<"The Search Value">). An empty list is returned both
when one or more of the arguments are invalid and when nothing matches; use
L</verify_selectionlist> to tell the two cases apart.

It is possible to give more than one field/value pair. The mode then defaults
to C<and>, but it can be given initially, between the pairs, or omitted. The
following examples are equivalent:

  Geo::Postcodes::NO::selection('and', $field  => $value,
                                 $field2 => $value2);
  Geo::Postcodes::NO::selection(       $field  => $value,
                            'and', $field2 => $value2);
  Geo::Postcodes::NO::selection(       $field  => $value,
                                 $field2 => $value2);

The field/value pairs are evaluated in the given order, and the modes can be
mixed freely:

  Geo::Postcodes::NO::selection($field1 => $value1,
                  'and',    $field2 => $value2,
                  'or',     $field3 => $value3,
                  'or not', $field4 => $value4,
                  'and not', $field5 => $value5,
                  'xor',    $field6 => $value6);

=head3 Modes

The binary modes combine the current result set C<A> with the next criterion
C<B>. The truth table below shows, for each mode, whether a postcode that is in
C<A> and/or matches C<B> ends up in the result:

 A  B | and and nand nand nor nor  or or  xnor xnor xor xor
      |     not      not      not     not      not      not
 -----+----------------------------------------------------
 0  0 |  0   0   1    1    1   0   0   1   1    0    0   1
 0  1 |  0   0   1    1    0   1   1   0   0    1    1   0
 1  0 |  0   1   1    0    0   0   1   1   0    1    1   0
 1  1 |  1   0   0    1    0   0   1   1   1    0    0   1

A trailing C<not> negates the second criterion C<B> before it is combined, and
the C<n> variants (C<nand>, C<nor>, C<xnor>) negate the result of the
combination. The modes C<all>, C<none>, C<not>, and C<one> are initial modes
only and are not part of this table.

=over

=item all

All the postcodes. This mode is only legal as the first argument, and any
additional arguments are silently ignored.

  my @postcodes = Geo::Postcodes::NO::selection('all');

This returns I<all> the postcodes as a sorted list, the same as
C<sort Geo::Postcodes::NO::get_postcodes()>. The object-oriented form (see
L</selection method>) returns a postcode object for each postcode, which may be
handy if time and memory are of no concern; otherwise create the objects only
when needed, inside a loop over the procedure version, or use
L</selection_loop procedure>.

=item and

The postcode is included in the result if it is included in B<all> the
expressions.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'and', $field2 => $value2);

Return the postcodes matching I<all> the field/value pairs. The computation
works faster if the field/value pairs are given with the one producing the most
matches first and the one producing the least matches last.

=item and not

The postcode is included in the result if it is included in B<the first
expression, but not the second one>.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'and not', $field2 => $value2);

This is set difference, C<A - B>.

=item nand

The postcode is included in the result if it is I<not> included in B<both>
expressions. This is mathematical NAND: everything except the intersection of
C<A> and C<B>.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'nand', $field2 => $value2);

=item nand not

Mathematical NAND with the second criterion negated: the postcode is included
unless it is in C<A> and outside C<B>.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'nand not', $field2 => $value2);

=item oldnand

Legacy C<Geo::Postcodes> C<nand> behaviour. The historical base class treated
C<nand> as part of the C<and> family; this mode preserves that behaviour. For a
simple two-clause selection it is equivalent to C<and not>.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'oldnand', $field2 => $value2);

=item oldnand not

Legacy C<Geo::Postcodes> C<nand not> behaviour. For a simple two-clause
selection it is equivalent to C<and>.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'oldnand not', $field2 => $value2);

=item nor

The postcode is included in the result if it is included in B<none of> the
expressions.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'nor', $field2 => $value2);

=item nor not

The postcode is included in the result if it is included in B<the second
expression only>.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'nor not', $field2 => $value2);

=item none

This returns no postcodes at all. This mode is only legal as the first argument,
and any additional arguments are silently ignored.

  my @postcodes = Geo::Postcodes::NO::selection('none');

=item not

This initial mode negates the first field/value pair. It is also possible to use
C<and not> or any other C<xxx not> mode initially. Note that C<not> is not a
binary mode; for any additional field/value pair with no mode given, C<and> is
assumed. The following examples are equivalent:

  Geo::Postcodes::NO::selection('not',     $field  => $value,
                                'and',     $field2 => $value2);
  Geo::Postcodes::NO::selection('not',     $field  => $value,
                                           $field2 => $value2);
  Geo::Postcodes::NO::selection('or not',  $field  => $value,
                                'and',     $field2 => $value2);
  Geo::Postcodes::NO::selection('and not', $field  => $value,
                                'and',     $field2 => $value2);
  Geo::Postcodes::NO::selection('and not', $field  => $value,
                                           $field2 => $value2);

=item one

This initial mode limits the returned list to a single (or zero) postcode,
chosen at random from the matches.

  Geo::Postcodes::NO::selection('one', $field => $value);

It can also be used on its own, just to get a random postcode.

  Geo::Postcodes::NO::selection('one');

=item or

The postcode is included in the result if it is included in at least B<one of>
the expressions.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'or', $field2 => $value2);

Return the postcodes matching I<one or more> of the field/value pairs. The
computation works faster if the field/value pairs are given with the one
producing the least matches first and the one producing the most matches last.

=item or not

The postcode is included in the result unless it is B<included in the second
expression only>.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'or not', $field2 => $value2);

=item xnor

The postcode is included in the result if it is included in B<none or both>
expressions.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'xnor', $field2 => $value2);

=item xnor not

The postcode is included in the result if it is included in B<only one of> the
expressions. This mode is the same as C<xor>.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'xnor not', $field2 => $value2);

=item xor

The postcode is included in the result if it is included in B<only one of> the
expressions.

  my @postcodes = Geo::Postcodes::NO::selection(
     $field1 => $value1, 'xor', $field2 => $value2);

=item xor not

The postcode is included in the result if it is included in B<both or none> of
the expressions.

=back

=head3 The Search Value

The search value is parsed as the regular expression C<m{^$value$}i>. This has
the following implications:

=over

=item m{...}i

The trailing C<i> means the search is case-insensitive. This does not fold the
special Norwegian characters C<Æ>, C<Ø>, and C<Å> unless a C<use locale> is in
effect and the current locale supports them.

C<'as'> will match C<'AS'>, C<'As'>, C<'aS'>, and C<'as'>.

=item m{^...$}

The leading caret and trailing dollar sign force a match on the whole value.
C<'AS'> matches exactly the four variations above and nothing else, so C<'CHAS'>
or C<'ASIMOV'> will not match. Use L</Wildcards> or L</Regular expressions> to
match several characters at once.

=back

=head3 Wildcards

The character C<%> (percent) matches zero or more arbitrary characters (borrowed
from SQL). C<'%12'> matches C<'1112'> but not C<'1201'>. C<'O%D'> matches all
strings starting with an C<O> and ending with a C<D>. C<'%A%'> matches all
strings with an C<A> somewhere. (The module rewrites C<%> to the regular
expression C<.*>.)

=head3 Regular expressions

=over

=item C<.>

A single dot matches exactly one character. C<'..11'> matches a four-character
string whose first two characters can be anything, followed by C<11>.

=item C<?>

A question mark matches the previous character zero or one time. C<'%ØYA?'>
matches strings ending with C<ØY> or C<ØYA>.

=item C<*>

A star matches the previous character zero or more times.

=item C<[]>

The expression C<'[AB]'> matches one of C<A> or C<B>. C<%'[AB]'> matches all
names ending with an C<A> or a C<B>.

=item C<()>

The expression C<'(..)'> captures the part inside the parentheses, which can be
reused with the back references C<\1>, C<\2>, and so on. C<'(..)\1'> matches
postcodes starting with two characters and ending with the same two (for
example C<1919> or C<7272>, but not C<1221>). C<'(.)(.)\2\1'> matches postcodes
where the first and fourth digits are the same and the second and third digits
are the same.

=item C<|>

The expression C<'A|BBB'> matches either C<A> or C<BBB>. Be careful with this
construct, as C<'%ÅS|%SKOG'> does B<not> match C<%ÅS> or C<%SKOG>; because the
value is wrapped in C<^...$>, it matches everything starting with C<ÅS> or
ending with C<SKOG>. Use C<'%(ÅS|SKOG)'> to get the intended result.

=back

=head3 External Procedures

It is also possible to call an external procedure and let it decide whether a
postcode is included. Specify C<'procedure', \&procedure_to_do_the_job> instead
of a field/value pair. The procedure is passed the postcode and must return true
or false.

  sub procedure_to_do_the_job
  {
    my $postcode = shift;
    return 1 if ...;
    return 0;
  }

=head2 selection method

  my @postcode_objects = Geo::Postcodes::NO->selection($field => $value);

This works just as the procedure version (see above), but returns a list of
postcode objects instead of a list of postcodes.

=head2 When not to use selection

Do not use C<selection> when you are after a single postcode; use the
constructor (the C<new> call) or the C<xxx_of> procedures to read the fields
directly.

  my @obj_list = Geo::Postcodes::NO->selection(postcode => '1178');
  my $obj      = Geo::Postcodes::NO->new('1178');

C<selection> loops over all the postcodes, which is wasteful when you already
have the answer. Use the C<valid> procedure to check that a postcode exists (see
L<Geo::Postcodes::NO::Tutorial>).

=head1 SELECTION_LOOP

It is possible, and often advisable, to pass an external procedure in the
argument list to C<selection> itself when the procedure is only used to select
from the postcodes. The procedures in this section use a C<print> statement,
which is fine if somewhat contrived.

=head2 selection_loop procedure

The first argument is a reference to a procedure that is called for each postcode
returned by the C<selection> call, with the rest of the arguments.

  sub post_check
  {
    my $postcode = shift;
    print "$postcode\n" if something($postcode) > 3.14;
  }

  Geo::Postcodes::NO::selection_loop(\&post_check, $field, $value);

=head2 selection_loop method

As above, but the value passed to the procedure is a postcode object.

  sub post_check
  {
    my $object = shift;
    print $object->postcode(), "\n" if something($object->postcode()) > 3.14;
  }

  Geo::Postcodes::NO->selection_loop(\&post_check, $field, $value);

=head1 SUPPORTING PROCEDURES

=head2 verify_selectionlist

The C<selection> procedure/method returns an empty list both when there are
errors in the argument list and when the selection simply found no matches. Use
this procedure to verify that the arguments are valid for C<selection>.

  my ($status, @list) = Geo::Postcodes::NO::verify_selectionlist(@arguments);

A true (1) status is followed by a normalised version of the original arguments
(for example, C<and> and C<not> are folded into C<and not>), which C<selection>
accepts as well. A false (0) status is followed by a list of diagnostic messages
up to the point where verification failed. External procedures are recognised
and must actually exist for the test to accept them.

=head2 is_legal_selectionmode

Returns true if the mode is one of the binary modes returned by
C<get_selectionmodes>.

=head2 is_legal_initial_selectionmode

Returns true if the mode is one of the modes returned by
C<get_initial_selectionmodes>.

=head2 get_selectionmodes

A sorted list of the legal binary selection modes: C<and>, C<and not>, C<nand>,
C<nand not>, C<oldnand>, C<oldnand not>, C<nor>, C<nor not>, C<or>, C<or not>,
C<xnor>, C<xnor not>, C<xor>, and C<xor not>.

=head2 get_initial_selectionmodes

As L</get_selectionmodes>, with the addition of C<all>, C<none>, C<not>, and
C<one>. The list is sorted.

=head1 SEE ALSO

L<Geo::Postcodes::NO> and L<Geo::Postcodes::NO::Tutorial>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2026 by Arne Sommer - perl@bbop.org

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut