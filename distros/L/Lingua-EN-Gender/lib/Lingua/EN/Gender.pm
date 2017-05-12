package Lingua::EN::Gender;
#
# Does nifty things with inflecting pronouns for gender
#
# Last updated by gossamer on Wed Jan  6 21:56:31 EST 1999
#

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @genders %pronoun);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( pronoun genders is_valid_gender);
@EXPORT_OK = qw();
$VERSION = "0.02";

=head1 NAME

Lingua::EN::Gender - Inflect pronouns for gender

=head1 SYNOPSIS

   use Lingua::EN::Gender;

   print &genders();

   if (&is_valid_gender("male")) { ...

=head1 DESCRIPTION

Small module for inflecting pronouns for a bunch of different
genders.

Genders currently supported are:
   neuter
   male
   female
   either
   spivak
   splat
   plural
   egotistical
   royal
   2nd
   sie/hir
   zie/zir

=cut

###################################################################
# Some constants                                                  #
###################################################################

@genders = ("neuter", "male", "female", "either", "spivak", "splat", "plural", "egotistical", "royal", "2nd", "sie/hir", "zie/zir");

$pronoun{"subjective"} = ["it", "he", "she", "s/he", "e", "*e", "they", "I", "we", "you", "sie", "zie"];
$pronoun{"objective"} = ["it", "him", "her", "him/her", "em", "h*", "them", "me", "us", "you", "hir", "zir"];
$pronoun{"posessive-subjective"} = ["its", "his", "her", "his/her", "eir", "h*", "their", "my", "our", "your", "hirs", "har", "zir"];
$pronoun{"posessive-objective"} = ["its", "his", "hers", "his/hers", "eirs", "h*s", "theirs", "mine", "ours", "yours", "hars", "zirs"];
$pronoun{"reflexive"} = ["itself", "himself", "herself", "(him/herself", "emself", "h*self", "themselves", "myself", "ourselves", "yourself", "hirself", "zirself"];

=head1 FUNCTIONS

=item pronoun ( TYPE, GENDER )

Returns the appropriate pronoun word for that pronoun type and gender.

The types (examples for the male gender in brackets) are:
   subjective ("he")
   objective ("him")
   posessive-subjective ("his")
   posessive-objective ("his")
   reflexive ("himself")

=cut

sub pronoun {
   my $pro_type = shift;
   my $pro_gender = shift;

   my $index = &gender_index(lc($pro_gender));

   return undef unless defined($index);

   return $pronoun{$pro_type}[$index];

}


=pod
=item genders ( )

Simply returns an array containing all the valid genders.

=cut

sub genders {

   return @genders;

}

=pod
=item is_valid_gender ( TEXT )

Returns true/false depending if the argument is a gender we know
about.  Case is not significant.

=cut

sub is_valid_gender {
   my $gender = shift;

   foreach (@genders) {
      # NB case-insensitive match
      return 1 if lc($gender) eq $_;
   }
   return 0;
}


sub gender_index {
   my $gender = shift;

   foreach (my $i = 0; $i < @genders; $i++) {
      return $i if $gender eq $genders[$i];
   }

   return undef;
}

=head1 AUTHOR

Bek Oberin <bekj@netizen.com.au>

=head1 COPYRIGHT

Copyright (c) 1999 Bek Oberin.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#
# End.
#
1;
