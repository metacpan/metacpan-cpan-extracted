package Lingua::YaTeA::Message;

use strict;
use warnings;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$name,$content,$language) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{NAME} = $name;
    $this->{$language}= $content;
    return $this;
}



sub getContent
{
    my ($this,$language) = @_;
    return $this->{$language};
}

sub getName
{
    my ($this) = @_;
    return $this->{NAME};
}

1;

__END__

=head1 NAME

Lingua::YaTeA::Message - Perl extension for managing a message in the term extractor

=head1 SYNOPSIS

  use Lingua::YaTeA::Message;
  Lingua::YaTeA::Message->new($name, $content, $language);

=head1 DESCRIPTION

This module manages the message used in the interface. As the language
of the interface can be parametrized, the message can have several
contents. Each message is dedicated to a specific event in the term
extractor. Messages are defined in the file
C<share/YaTeA/locale/FR/Messages>.

=head1 METHODS

=head2 new()

    new($name, $content, $language);

This method creates and retusn a message named C<$name> with the content
C<$content> for the langage of the interface C<$language>.

=head2 getContent()

 getContent($language);

This method returns the content of the message according to the
language of the interface.

=head2 getName()
    
This method returns the name of the message.

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
