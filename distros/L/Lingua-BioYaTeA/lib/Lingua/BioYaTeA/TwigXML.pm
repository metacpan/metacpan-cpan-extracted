package Lingua::BioYaTeA::TwigXML;

use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

Lingua::BioYaTeA::TwigXML - Perl extension of Twig::XML for BioYaTeA.

=head1 SYNOPSIS

use Lingua::BioYaTeA;

my $twig_parser = Lingua::BioYaTeA::TwigXML->new(%xmltwig_options);
$twi_parser->$twig_parser->objectSelf($PostProcself);

=head1 DESCRIPTION

This module is a extention of implements C<XML::Twig>. The
C<Lingua::BioYaTeA::TwigXML> object inherits the C<XML::Twig>
object. A additional attribut (C<objectSelf>) is set to refer to the
calling object (C<Lingua::BioYaTeA::PostProcessing>).

=head1 METHODS

=head2 new()

    new(@twig_options);

This method creates a object which inherits of the C<XML::Twig> object.

=head2 objectSelf()

    objectSelf($objectSelf);

This method adds the calling object (C<$objectSelf>) to the attribute
C<objectSelf> and returns it. If C<$objectSelf> is not set, the method
only returns the value of the attrbut C<objectSelf>.

=head1 SEE ALSO

Documentation of Lingua::YaTeA

Documentation of Lingua::YaTeA

=head1 AUTHORS

Wiktoria Golik <wiktoria.golik@jouy.inra.fr>, Zorana Ratkovic <Zorana.Ratkovic@jouy.inra.fr>, Robert Bossy <Robert.Bossy@jouy.inra.fr>, Claire Nédellec <claire.nedellec@jouy.inra.fr>, Thierry Hamon <thierry.hamon@univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2012 Wiktoria Golik, Zorana Ratkovic, Robert Bossy, Claire Nédellec and Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

use XML::Twig;

our @ISA = qw(XML::Twig);



sub new {
    my $class = shift;

    my $this = $class->SUPER::new(@_);
    bless ($this,$class);

    return $this;
}


sub objectSelf {
    my ($twigself, $objectSelf) = @_;
    
    if (defined $objectSelf) {
	$twigself->{'objectSelf'} = $objectSelf;
    }
    return($twigself->{'objectSelf'});
}
