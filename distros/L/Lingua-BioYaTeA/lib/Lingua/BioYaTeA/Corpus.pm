package Lingua::BioYaTeA::Corpus;

use strict;
use warnings;
use utf8;

use Lingua::YaTeA::Corpus;

our @ISA = qw(Lingua::YaTeA::Corpus);

our $VERSION=$Lingua::BioYaTeA::VERSION;

sub new
{
    my ($class,$path,$option_set,$message_set) = @_;

    my $this = $class->SUPER::new($path,$option_set,$message_set);
    bless ($this,$class);

    return $this;
}


1;

__END__

=encoding utf8

=head1 NAME

Lingua::BioYaTeA::Corpus - Perl extension for managing corpus of texts

=head1 SYNOPSIS

  use Lingua::BioYaTeA::Corpus;
  Lingua::BioYaTeA::Corpus->new($path,$option_set,$message_set);

=head1 DESCRIPTION

This module is an extension which inherits of all the methods and
attributes of the module C<Lingua::YaTeA>.

=head1 METHODS

=head2 new()

     new($path,$option_set,$message_set);

This method creates a new object regarding the corpus file
C<$path>. C<$option_set> contains the list of BioYaTeA options which
could be required while processing the corpus. C<$message_set> is the
message set which is used for displaying information during the corpus processing.

=head1 SEE ALSO

Documentation of C<Lingua::YaTeA> and C<Lingua::YaTeA::Corpus>

=head1 AUTHORS

Wiktoria Golik <wiktoria.golik@jouy.inra.fr>, Zorana Ratkovic <Zorana.Ratkovic@jouy.inra.fr>, Robert Bossy <Robert.Bossy@jouy.inra.fr>, Claire Nédellec <claire.nedellec@jouy.inra.fr>, Thierry Hamon <thierry.hamon@univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2012 Wiktoria Golik, Zorana Ratkovic, Robert Bossy, Claire Nédellec and Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut


