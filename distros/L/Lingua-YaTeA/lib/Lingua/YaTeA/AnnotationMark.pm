package Lingua::YaTeA::AnnotationMark;
use strict;
use warnings;
use Lingua::YaTeA::WordOccurrence;

our @ISA = qw(Lingua::YaTeA::WordOccurrence);

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$form,$id,$type) = @_;
    my $this = $class->SUPER::new($form);
    bless ($this,$class);
    $this->{ID} = $id;
    $this->{TYPE} = $type;
    return $this;
}

sub getType
{
    my ($this) = @_;
    return $this->{TYPE};
}

sub getID
{
    my ($this) = @_;
    return $this->{ID};
}

1;

__END__

=head1 NAME

Lingua::YaTeA::AnnotationMark - Perl extension for annotation marks

=head1 SYNOPSIS

  use Lingua::YaTeA::AnnotationMark;
  Lingua::YaTeA::AnnotationMark->new($form, $id, $type);

=head1 DESCRIPTION

The module implements annotation marks in the corpus. Objects inherit
of the module Lingua::YaTeA::WordOccurrence. Each annotation mark is
composed of a form, a identifier and a type ( its values are C<closer>
or C<opener>).

=head1 METHODS


=head2 new()

    new($form, $id, $type);

The method creates a new annotation mark having the form C<$form>, the
identifier C<$id> and the type C<$type>.


=head2 getType()

    getType();

This method returns the type of the annotation mark.

=head2 getID()

    getID();

This method returns the identifier of the annotation mark.


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
