package Lingua::YaTeA::ForbiddenStructure;
use strict;
use warnings;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$form) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{FORM} = $form;
    $this->{LENGTH} = $this->setLength($form);
    return $this;
}

sub setLength
{
    my ($this,$form) = @_;
    my @words = split (/ /,$form);
    return scalar @words;
}

sub getLength
{
    my ($this) = @_;
    return $this->{LENGTH};
}
1;

__END__

=head1 NAME

Lingua::YaTeA::ForbiddenStructure - Perl extension for the forbidden structures.

=head1 SYNOPSIS

  use Lingua::YaTeA::ForbiddenStructure;
  Lingua::YaTeA::ForbiddenStructure->new();

=head1 DESCRIPTION

This module represents the forbidden structures used in the chunking
steps. Forbidden structures are exceptions for more complex
structures and are used to prevent from extracting sequences that look
like terms (syntactically valid) but are known not to be terms or
parts of terms like I<of course>.

The C<ForbiddenStructure> object is composed of two fields: the
forbiddent structure C<FORM> and its length C<LENGTH>.

=head1 METHODS

=head2 new()

    new($form);

This method creates a new forbidden structure from C<$form>. The length is set as well as the from.

=head2 setLength()

    setLength($form);

The method is used to set the length field according to the corresponding C<$form>.

=head2 getLength')

    getLenght();

The method is used to get the length of the forbidden structure.


=head1 SEE ALSO

Sophie Aubin and Thierry Hamon. Improving Term Extraction with
Terminological Resources. In Advances in Natural Language Processing
(5th International Conference on NLP, FinTAL 2006). pages
380-387. Tapio Salakoski, Filip Ginter, Sampo Pyysalo, Tapio Pahikkala
(Eds). August 2006. LNAI 4139.


=head1 AUTHOR

Thierry Hamon <thierry.hamon@univ-paris13.fr> and Sophie Aubin <sophie.aubin@lipn.univ-paris13.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
