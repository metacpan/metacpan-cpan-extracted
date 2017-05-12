package Lingua::PigLatin;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::PigLatin ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    piglatin
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub new {
  my $class = shift;
  bless {}, ref($class)||$class;
}

sub piglatin {
   local $_ = shift;
   local $_ = shift if ref($_);
   
    s/\b(qu|[cgpstw]h # First syllable, including digraphs
    |[^\W0-9_aeiou])  # Unless it begins with a vowel or number
    ?([a-z]+)/        # Store the rest of the word in a variable
    $1?"$2$1ay"       # move the first syllable and add -ay
    :"$2way"          # unless it should get -way instead 
    /iegx; 

   return $_;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::PigLatin - Perl extension for Pig Latin

=head1 SYNOPSIS

  use Lingua::PigLatin 'piglatin';
  print piglatin("Put the candle back.");

=head1 DESCRIPTION

This module translates strings into Pig Latin.

For any word starting with one or more consonants (including digraphs such as
qu-,  th-, sh-, ch-, gh-, wh-, or ph-), move the starting syllable to the end
of the word and append -ay.

For any word starting with a vowel do not move the syllable, but append -way.

orFay anyway ordway tartingsay ithway oneway orway oremay onsonantscay 
(includingway igraphsday uchsay asway uqay-,  htay-, hsay-, hcay-, hgay-, 
hway-, orway hpay-), ovemay ethay tartingsay yllablesay otay ethay endway
ofway ethay ordway andway appendway -ayway.

orFay anyway ordway tartingsay ithway away owelvay oday otnay ovemay ethay 
yllablesay, utbay appendway -ayway.

=head2 EXPORT

None by default.

Can export piglatin function for convenience.

=head1 SEE ALSO

http://www.perlmonks.org/?node_id=3586

=head1 KNOWN PROBLEMS

Capitalization.
Contractions.


=head1 AUTHOR

Jack Coates, E<lt>jack@monkeynoodle.orgE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Jack Coates

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
