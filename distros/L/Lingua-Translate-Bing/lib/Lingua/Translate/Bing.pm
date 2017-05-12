package Lingua::Translate::Bing;

use 5.010;
use strict;
use warnings;
use utf8;
use Carp;

use LWP::UserAgent;
use LWP::Protocol::https;
use JSON::XS;
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use SOAP::Lite; #+trace => 'debug'; 

=head1 NAME

Lingua::Translate::Bing - Class for accessing the functions of translation, provided by the "Bing Translation Api".

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

    use Lingua::Translate::Bing;

    my $translator = Lingua::Translate::Bing->new(client_id => "1111111", client_secret => "111111");

    print $translator->translate("Hello", "ru");
    ...


=cut


=head1 CONSTRUCTORS

=head2 new(%args)

%args contains: 

=over 1

=item client_id 

=item client_secret 

=back

that you will must get in L<http://datamarket.azure.com/dataset/bing/microsofttranslator>.

B<ATTENTION!>
Microsoft offers free access to Bing Translator for no more than 2,000,000 characters/month. 

=cut

sub new {
    my ($class, %args) = @_;

	my $self = { 
        client_id => $args{'client_id'},
        client_secret => $args{'client_secret'},
        token_time => undef,
        token_update_period => 600,
        token => undef,
    };
    bless $self, $class;
    return $self;
}

=head2 getLanguagesForTranslate()

Return array of supported languages.

=cut

sub getLanguagesForTranslate {
    my ($self) = @_;
    my $answer = $self->_sendRequest("GetLanguagesForTranslate", "appId" => "");
    return $answer->{string};
}

=head2 detect($text)

Return text input language code.

=over 1

=item $text  

Undetected text.

=back

=cut

sub detect {
    my ($self, $text) = @_;
    my $answer = $self->_sendRequest("Detect", "text" => $text);
    return $answer;
}

=head2 translate($text, $to, $from)

Return translation of input text.

=over 1

=item $text  

Text for translation.

=item $to

Target language code.

=item $from

Language code of input text. Not requeried, but may by mistakes if don't set this argument. It will may be occure because <B>detect</B> method don't define correct language always.

=back

=cut

sub translate {
    my ($self, $text, $to, $from) = @_;
    my $answer = $self->_sendRequest("Translate", "text" => $text, "from" => $from, "to" => $to, "contentType" =>
        "text/plain");
    return $answer;
}

sub _setUpdateTokenPeriod {
    my ($self, $period) = @_;
    $self->{token_update_period} = $period;
    return;
}

sub _initAccessToken {
    my ($self) = @_;
    my $result;
    my $browser = LWP::UserAgent->new();

    my $url = "https://datamarket.accesscontrol.windows.net/v2/OAuth2-13";
    my $scope = "http://api.microsofttranslator.com";       
    my $grant_type = "client_credentials";                 

    my $response = $browser->post( $url,
             [
              'grant_type' => $grant_type,
              'scope' => $scope,
              'client_id' => $self->{client_id},
              'client_secret' => $self->{client_secret}
             ],
     );
    if ($response) {
        my $content = $response->content;
        my $json_xs = JSON::XS->new();
        $result = $json_xs->decode($content)->{'access_token'};
    }
    unless (defined($result)) {
        croak "Failed init access token";
    }

    if ($result) {
        $self->{token_time} = clock_gettime(CLOCK_MONOTONIC);
        $result = "Bearer " . $result;
        $self->{token} = $result;
    }
    return $result;
}

sub _getAccessToken {
    my ($self) = @_;
    
    if (!$self->{token} || (clock_gettime(CLOCK_MONOTONIC) - $self->{token_time} > $self->{token_update_period})) {
        $self->_initAccessToken();
    }
    return $self->{token};
}

sub _sendRequest {
    my ($self, $function, %args) = @_;

    my $token = $self->_getAccessToken();
    my $soap = SOAP::Lite->proxy('http://api.microsofttranslator.com/V2/Soap.svc')
                         ->on_action(sub {return
                                 "\"http://api.microsofttranslator.com/V2/LanguageService/$function\""})
                         ->readable(1)
                         ->encodingStyle("")
                         ->encoding(undef)
                         ->default_ns(undef);

    $soap->transport->http_request->header("Authorization" => $token);
    my $method = SOAP::Data->name($function)->attr({xmlns => 'http://api.microsofttranslator.com/V2'});
    my @all_arguments = qw /appId locale languageCodes text from to contentType category/;
    my @params; 
    foreach (@all_arguments) {
        my ($key, $value) = ($_, $args{$_});
        if (defined $value) { 
            my $argument = SOAP::Data->name($key)->uri(undef)->value($value)->type("");
            push @params, $argument;
        }
    }
    my $answer = $soap->call($method => @params);
    return $answer->result;
}

1;

=head1 AUTHOR

Milovidov Mikhail, C<< <milovidovwork at yandex.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bingtranslationapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BingTranslationApi>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::Translate::Bing


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BingTranslationApi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/BingTranslationApi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/BingTranslationApi>

=item * Search CPAN

L<http://search.cpan.org/dist/BingTranslationApi/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Milovidov Mikhail.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lingua::Translate::Bing
