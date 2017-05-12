package Lingua::Translate::Yandex;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use XML::Simple;
use LWP::UserAgent;

use utf8;
use 5.010;

=head1 NAME

Lingua::Translate::Yandex - class for access to Yandex Translation Api.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

    use Lingua::Translate::Yandex;

    my $translator = Lingua::Translate::Yandex->new();
    say $translator->translate("Hello", "ru");
    ...

=cut

=head1 CONSTRUCTORS

=head2 new()

=cut

sub new {
   my ($class) = @_;
   my $self = {
       browser => LWP::UserAgent->new(),
       xml => XML::Simple->new(),
   };
   bless $self, $class;
   return $self;
}

=head1 METHODS

=head2 getLanguages 

Return array with all supported pairs of languages.

=cut

sub getLanguages {
    my ($self) = @_;
    my $response = $self->getXmlResponse("http://translate.yandex.net/api/v1/tr/getLangs");
    return $response->{dirs}->{string};

}

=head2 detectLanguage($text)

Return language of B<$text>.

=cut

sub detectLanguage {
    my ($self, $text) = @_;
    my $response = $self->getXmlResponse("http://translate.yandex.net/api/v1/tr/detect?text=$text");
    unless ($response->{code} == 200) {
        croak "Unsupported language"
    }
    return $response->{lang};
}

=head2 translate($text, $to)

Translate B<$text> to  B<$to> target language and return translated text in utf8 encoding. B<$text> must be in utf8 encoding.

=cut

sub translate {
    my ($self, $text, $to) = @_;
    utf8::decode($text);
    my $language_pairs = $self->getLanguages();
    my $text_lang = $self->detectLanguage($text);
    my $pair = lc($text_lang . "-" . $to);
    unless (@$language_pairs ~~ /($pair)/) {
       croak "Unsupported languege pair";
    }

    my $response = $self->getXmlResponse("http://translate.yandex.net/api/v1/tr/translate?lang=$pair&text=$text");
    my $code = $response->{code}; 
    given ($code) {
        when (200) {break;}
        when (413) {croak "The text size exceeds the maximum.";}
        when (422) {croak "The text could not be translated.";}
        when (501) {croak "The specified translation direction is not supported.";}
    }

    my $result = $response->{text};
    utf8::encode($result);
    return $result;
}



=head2 getXmlResponse($url)

Return response from request to B<$url> in XML format.

=cut

sub getXmlResponse {
    my ($self, $url) = @_;
    return $self->{xml}->XMLin($self->{browser}->get($url)->content);
}


=head1 AUTHOR

Milovidov Mikhail, C<< <milovidovwork at yandex.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-translate-yandex at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Translate-Yandex>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::Translate::Yandex


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Translate-Yandex>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-Translate-Yandex>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-Translate-Yandex>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-Translate-Yandex/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Milovidov Mikhail.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lingua::Translate::Yandex
