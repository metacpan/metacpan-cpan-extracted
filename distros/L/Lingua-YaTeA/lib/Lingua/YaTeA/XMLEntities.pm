#!/usr/bin/perl

package Lingua::YaTeA::XMLEntities;
use strict;
use warnings;

our $VERSION=$Lingua::YaTeA::VERSION;

sub encode
{
    $_[0]=~s/&/&amp;/go;
    $_[0]=~s/\"/&quot;/go;
    $_[0]=~s/\'/&apos;/go;
    $_[0]=~s/</&lt;/go;
    $_[0]=~s/>/&gt;/go;

    return($_[0]);
}


=head2 decode($line)

This method decodes XML entities corresponding to special XML characters in the line C<$line> .

=cut


sub decode
{
    $_[0]=~s/&quot;/\"/go;
    $_[0]=~s/&apos;/\'/go;
    $_[0]=~s/&amp;/&/go;
    $_[0]=~s/&lt;/</go;
    $_[0]=~s/&gt;/>/go;

    return($_[0]);
}

1;

__END__

=head1 NAME

Lingua::YaTeA::XMLEntities - Perl extension for managing characters which can not be used in a XML document

=head1 SYNOPSIS


use Lingua::YaTeA::XMLEntities;

Lingua::YaTeA::XMLEntities::decode($line);

Lingua::YaTeA::XMLEntities::eecode($line);

=head1 DESCRIPTION

This module is used to encode or decode special XML characters
(C<&>, C<'>, C<">, E<gt>, E<lt>).

=head1 METHODS

=head2 encode($line)

This method encodes special XML characters as XML entities in the line C<$line>.

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
