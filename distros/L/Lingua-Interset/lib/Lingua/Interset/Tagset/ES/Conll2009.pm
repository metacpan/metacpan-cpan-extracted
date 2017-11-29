# ABSTRACT: Driver for the Spanish tagset of the CoNLL 2009 Shared Task.
# Copyright © 2011, Zdeněk Žabokrtský <zabokrtsky@ufal.mff.cuni.cz>
# Copyright © 2011, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Originally Italian decoder written by Dan Zeman and Loganathan Ramasamy
# adapted for Spanish by Zdeněk Žabokrtský
# further developed by Dan Zeman

package Lingua::Interset::Tagset::ES::Conll2009;
use strict;
use warnings;
our $VERSION = '3.010';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::CA::Conll2009';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Interset::Tagset::ES::Conll2009 - Driver for the Spanish tagset of the CoNLL 2009 Shared Task.

=head1 VERSION

version 3.010

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::ES::Conll2009;
  my $driver = Lingua::Interset::Tagset::ES::Conll2009->new();
  my $fs = $driver->decode("n\tpostype=common|gen=m|num=s");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('es::conll2009', "n\tpostype=common|gen=m|num=s");

=head1 DESCRIPTION

Interset driver for the Spanish tagset of the CoNLL 2009 Shared Task.
CoNLL 2009 tagsets in Interset are traditionally two values separated by tabs.
The values come from the CoNLL 2009 columns POS and FEAT.

Note that the C<ca::conll2009> and C<es::conll2009> tagsets are identical as
they both come from the AnCora Catalan-Spanish corpus. For convenience,
separate drivers called CA::Conll2009 and ES::Conll2009 are provided, but one
is derived from the other.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::CA::Conll2009>,
L<Lingua::Interset::FeatureStructure>

=head1 AUTHOR

Dan Zeman <zeman@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Univerzita Karlova (Charles University).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
