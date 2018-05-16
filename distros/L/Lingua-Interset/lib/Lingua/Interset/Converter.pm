# ABSTRACT: Implements a converter between two physical tagsets via Interset.
# Copyright © 2015 Univerzita Karlova v Praze / Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Converter;
use strict;
use warnings;
our $VERSION = '3.012';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose 2;
use MooseX::SemiAffordanceAccessor; # attribute x is written using set_x($value) and read using x()
use Lingua::Interset qw(decode encode list);

has 'from'   => ( isa => 'Str', is => 'ro', required => 1, documentation => 'Source tagset identifier, e.g. cs::multext' );
has 'to'     => ( isa => 'Str', is => 'ro', required => 1, documentation => 'Target tagset identifier, e.g. cs::pdt' );
has '_cache' => ( isa => 'HashRef', is => 'ro', default => sub { return {} } );



#------------------------------------------------------------------------------
# Converts tag from tagset A to tagset B via Interset. Caches tags converted
# previously.
#------------------------------------------------------------------------------
sub convert
{
    my $self = shift;
    my $stag = shift;
    my $cache = $self->_cache();
    my $ttag = $cache->{$stag};
    if(!defined($ttag))
    {
        my $stagset = $self->from();
        my $ttagset = $self->to();
        $ttag = encode($ttagset, decode($stagset, $stag));
        $cache->{$stag} = $ttag;
    }
    return $ttag;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Converter - Implements a converter between two physical tagsets via Interset.

=head1 VERSION

version 3.012

=head1 SYNOPSIS

  use Lingua::Interset::Converter;

  my $c = new Lingua::Interset::Converter ('from' => 'cs::multext', 'to' => 'cs::pdt');
  while (<CONLL_IN>)
  {
      chomp ();
      my @fields = split (/\t/, $_);
      my $source_tag = $fields[4];
      $fields[4] = $c->convert ($source_tag);
      print (join("\t", @fields), "\n");
  }

=head1 DESCRIPTION

C<Converter> is a simple class that implements Interset-based conversion of tags
between two physical tagsets. It includes caching, which will improve performance
when converting tags in a large corpus.

=head1 ATTRIBUTES

=head2 from

Identifier of the source tagset (composed of language code and tagset id, all
lowercase, for example C<cs::multext>). It must be provided upon construction.

=head2 from

Identifier of the target tagset (composed of language code and tagset id, all
lowercase, for example C<cs::pdt>). It must be provided upon construction.

=head1 METHODS

=head2 convert()

  my $tag1  = convert ($tag0);

Converts tag from the source tagset to the target tagset via Interset.
Tags once converted are cached so the (potentially costly) Interset decoding-encoding
methods are called only once per source tag.

=head1 SEE ALSO

L<Lingua::Interset>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
