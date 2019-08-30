package Data::Object::String;

use Role::Tiny::With;

use overload (
  '""'     => 'detract',
  '~~'     => 'detract',
  fallback => 1
);

with qw(
  Data::Object::Role::Detract
  Data::Object::Role::Dumper
  Data::Object::Role::Functable
  Data::Object::Role::Output
  Data::Object::Role::Throwable
);

use parent 'Data::Object::String::Base';

our $VERSION = '1.09'; # VERSION

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::String

=cut

=head1 ABSTRACT

Data-Object String Class

=cut

=head1 SYNOPSIS

  use Data::Object::String;

  my $string = Data::Object::String->new('abcedfghi');

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 string data. This
package inherits all behavior from L<Data::Object::String::Base>.

=head1 ROLES

This package inherits all behavior from the following roles:

L<Data::Object::Role::Detract>

L<Data::Object::Role::Dumper>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Output>

L<Data::Object::Role::Throwable>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 append

  append() : StrObject

The append method modifies and returns the string with the argument list
appended to it separated using spaces. This method returns a
string object.

=over 4

=item append example

  # given 'firstname'

  $string->append('lastname'); # firstname lastname

=back

=cut

=head2 camelcase

  camelcase() : StrObject

The camelcase method modifies the string such that it will no longer have any
non-alphanumeric characters and each word (group of alphanumeric characters
separated by 1 or more non-alphanumeric characters) is capitalized. Note, this
method modifies the string. This method returns a L<Data::Object::String>
object.

=over 4

=item camelcase example

  # given 'hello world'

  $string->camelcase; # HelloWorld

=back

=cut

=head2 chomp

  chomp() : StrObject

The chomp method is a safer version of the chop method, it's used to remove the
newline (or the current value of $/) from the end of the string. Note, this
method modifies and returns the string. This method returns a
string object.

=over 4

=item chomp example

  # given "name, age, dob, email\n"

  $string->chomp; # name, age, dob, email

=back

=cut

=head2 chop

  chop() : StrObject

The chop method removes the last character of a string and returns the character
chopped. It is much more efficient than "s/.$//s" because it neither scans nor
copies the string. Note, this method modifies and returns the string. This
method returns a string value.

=over 4

=item chop example

  # given "this is just a test."

  $string->chop; # this is just a test

=back

=cut

=head2 concat

  concat(Any $arg1) : StrObject

The concat method modifies and returns the string with the argument list
appended to it. This method returns a string value.

=over 4

=item concat example

  # given 'ABC'

  $string->concat('DEF', 'GHI'); # ABCDEFGHI

=back

=cut

=head2 contains

  contains(Str | RegexpRef $arg1) : NumObject

The contains method searches the string for the string specified in the
argument and returns true if found, otherwise returns false. If the argument is
a string, the search will be performed using the core index function. If the
argument is a regular expression reference, the search will be performed using
the regular expression engine. This method returns a L<Data::Object::Number>
object.

=over 4

=item contains example

  # given 'Nullam ultrices placerat nibh vel malesuada.'

  $string->contains('trices'); # 1; true
  $string->contains('itrices'); # 0; false

  $string->contains(qr/trices/); # 1; true
  $string->contains(qr/itrices/); # 0; false

=back

=cut

=head2 defined

  defined() : NumObject

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
number object.

=over 4

=item defined example

  # given $string

  $string->defined; # 1

=back

=cut

=head2 eq

  eq(Any $arg1) : NumObject

The eq method returns true if the argument provided is equal to the value
represented by the object. This method returns a number value.

=over 4

=item eq example

  # given 'exciting'

  $string->eq('Exciting'); # 0

=back

=cut

=head2 ge

  ge(Any $arg1) : NumObject

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=over 4

=item ge example

  # given 'exciting'

  $string->ge('Exciting'); # 1

=back

=cut

=head2 gt

  gt(Any $arg1) : NumObject

The gt method returns true if the argument provided is greater-than the value
represented by the object. This method returns a number value.

=over 4

=item gt example

  # given 'exciting'

  $string->gt('Exciting'); # 1

=back

=cut

=head2 hex

  hex() : Str

The hex method returns the value resulting from interpreting the string as a
hex string. This method returns a data type object to be determined after
execution.

=over 4

=item hex example

  # given '0xaf'

  string->hex; # 175

=back

=cut

=head2 index

  index(Str $arg1, Num $arg2) : NumObject

The index method searches for the argument within the string and returns the
position of the first occurrence of the argument. This method optionally takes a
second argument which would be the position within the string to start
searching from (also known as the base). By default, starts searching from the
beginning of the string. This method returns a data type object to be determined
after execution.

=over 4

=item index example

  # given 'unexplainable'

  $string->index('explain'); # 2
  $string->index('explain', 0); # 2
  $string->index('explain', 1); # 2
  $string->index('explain', 2); # 2
  $string->index('explain', 3); # -1
  $string->index('explained'); # -1

=back

=cut

=head2 lc

  lc() : StrObject

The lc method returns a lowercased version of the string. This method returns a
string object. This method is an alias to the lowercase method.

=over 4

=item lc example

  # given 'EXCITING'

  $string->lc; # exciting

=back

=cut

=head2 lcfirst

  lc() : StrObject

The lcfirst method returns a the string with the first character lowercased.
This method returns a string value.

=over 4

=item lcfirst example

  # given 'EXCITING'

  $string->lcfirst; # eXCITING

=back

=cut

=head2 le

  le(Any $arg1) : NumObject

The le method returns true if the argument provided is less-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=over 4

=item le example

  # given 'exciting'

  $string->le('Exciting'); # 0

=back

=cut

=head2 length

  length() : NumObject

The length method returns the number of characters within the string. This
method returns a number value.

=over 4

=item length example

  # given 'longggggg'

  $string->length; # 9

=back

=cut

=head2 lines

  lines() : ArrayObject

The lines method breaks the string into pieces, split on 1 or more newline
characters, and returns an array reference consisting of the pieces. This method
returns an array value.

=over 4

=item lines example

  # given "who am i?\nwhere am i?\nhow did I get here"

  $string->lines; # ['who am i?','where am i?','how did i get here']

=back

=cut

=head2 lowercase

  lowercase() : StrObject

The lowercase method is an alias to the lc method. This method returns a
string object.

=over 4

=item lowercase example

  # given 'EXCITING'

  $string->lowercase; # exciting

=back

=cut

=head2 lt

  lt(Any $arg1) : NumObject

The lt method returns true if the argument provided is less-than the value
represented by the object. This method returns a number value.

=over 4

=item lt example

  # given 'exciting'

  $string->lt('Exciting'); # 0

=back

=cut

=head2 ne

  ne(Any $arg1) : NumObject

The ne method returns true if the argument provided is not equal to the value
represented by the object. This method returns a number value.

=over 4

=item ne example

  # given 'exciting'

  $string->ne('Exciting'); # 1

=back

=cut

=head2 replace

  replace(Str $arg1, Str $arg2) : StrObject

The replace method performs a smart search and replace operation and returns the
modified string (if any modification occurred). This method optionally takes a
replacement modifier as it's final argument. Note, this operation expects the
2nd argument to be a replacement String. This method returns a
string object.

=over 4

=item replace example

  # given 'Hello World'

  $string->replace('World', 'Universe'); # Hello Universe
  $string->replace('world', 'Universe', 'i'); # Hello Universe
  $string->replace(qr/world/i, 'Universe'); # Hello Universe
  $string->replace(qr/.*/, 'Nada'); # Nada

=back

=cut

=head2 reverse

  reverse() : ArrayObject

The reverse method returns a string where the characters in the string are in
the opposite order. This method returns a string value.

=over 4

=item reverse example

  # given 'dlrow ,olleH'

  $string->reverse; # Hello, world

=back

=cut

=head2 rindex

  rindex(Str $arg1, Num $arg2) : NumObject

The rindex method searches for the argument within the string and returns the
position of the last occurrence of the argument. This method optionally takes a
second argument which would be the position within the string to start
searching from (beginning at or before the position). By default, starts
searching from the end of the string. This method returns a data type object to
be determined after execution.

=over 4

=item rindex example

  # given 'explain the unexplainable'

  $string->rindex('explain'); # 14
  $string->rindex('explain', 0); # 0
  $string->rindex('explain', 21); # 14
  $string->rindex('explain', 22); # 14
  $string->rindex('explain', 23); # 14
  $string->rindex('explain', 20); # 14
  $string->rindex('explain', 14); # 0
  $string->rindex('explain', 13); # 0
  $string->rindex('explain', 0); # 0
  $string->rindex('explained'); # -1

=back

=cut

=head2 snakecase

  snakecase() : StrObject

The snakecase method modifies the string such that it will no longer have any
non-alphanumeric characters and each word (group of alphanumeric characters
separated by 1 or more non-alphanumeric characters) is capitalized. The only
difference between this method and the camelcase method is that this method
ensures that the first character will always be lowercased. Note, this method
modifies the string. This method returns a string value.

=over 4

=item snakecase example

  # given 'hello world'

  $string->snakecase; # helloWorld

=back

=cut

=head2 split

  split(RegexpRef $arg1, Num $arg2) : ArrayObject

The split method splits the string into a list of strings, separating each
chunk by the argument (string or regexp object), and returns that list as an
array reference. This method optionally takes a second argument which would be
the limit (number of matches to capture). Note, this operation expects the 1st
argument to be a Regexp object or a String. This method returns a
array object.

=over 4

=item split example

  # given 'name, age, dob, email'

  $string->split(', '); # ['name', 'age', 'dob', 'email']
  $string->split(', ', 2); # ['name', 'age, dob, email']
  $string->split(qr/\,\s*/); # ['name', 'age', 'dob', 'email']
  $string->split(qr/\,\s*/, 2); # ['name', 'age, dob, email']

=back

=cut

=head2 strip

  strip() : StrObject

The strip method returns the string replacing occurences of 2 or more
whitespaces with a single whitespace. This method returns a
string object.

=over 4

=item strip example

  # given 'one,  two,  three'

  $string->strip; # one, two, three

=back

=cut

=head2 titlecase

  titlecase() : StrObject

The titlecase method returns the string capitalizing the first character of
each word (group of alphanumeric characters separated by 1 or more whitespaces).
Note, this method modifies the string. This method returns a
string object.

=over 4

=item titlecase example

  # given 'mr. john doe'

  $string->titlecase; # Mr. John Doe

=back

=cut

=head2 trim

  trim() : StrObject

The trim method removes 1 or more consecutive leading and/or trailing spaces
from the string. This method returns a string value.

=over 4

=item trim example

  # given ' system is   ready   '

  $string->trim; # system is   ready

=back

=cut

=head2 uc

  uc() : StrObject

The uc method returns an uppercased version of the string. This method returns a
string object. This method is an alias to the uppercase method.

=over 4

=item uc example

  # given 'exciting'

  $string->uc; # EXCITING

=back

=cut

=head2 ucfirst

  uc() : StrObject

The ucfirst method returns a the string with the first character uppercased.
This method returns a string value.

=over 4

=item ucfirst example

  # given 'exciting'

  $string->ucfirst; # Exciting

=back

=cut

=head2 uppercase

  uppercase() : StrObject

The uppercase method is an alias to the uc method. This method returns a
string object.

=over 4

=item uppercase example

  # given 'exciting'

  $string->uppercase; # EXCITING

=back

=cut

=head2 words

  words() : ArrayObject

The words method splits the string into a list of strings, separating each
group of characters by 1 or more consecutive spaces, and returns that list as an
array reference. This method returns an array value.

=over 4

=item words example

  # given "is this a bug we're experiencing"

  $string->words; # ["is","this","a","bug","we're","experiencing"]

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<On GitHub|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Reporting|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

=cut