package Lingua::Translate::InterTran;
BEGIN {
  $Lingua::Translate::InterTran::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $Lingua::Translate::InterTran::VERSION = '0.05';
}

use strict;
use warnings FATAL => 'all';
use Carp qw(croak);
use Encode qw(encode decode);
use LWP::UserAgent ();
use URI ();
use base qw(Lingua::Translate);

# languages supported by InterTran as of February 2008
my %lang = (
    'bg'    => ['bul', 'cp1251'],     # Bulgarian (CP 1251)
    'cs'    => ['che', 'cp1250'],     # Czech (CP 1250)
    'cy'    => ['wel', 'cp1252'],     # Welsh
    'da'    => ['dan', 'cp1252'],     # Danish
    'de'    => ['ger', 'cp1252'],     # German
    'el'    => ['grk', 'cp1252'],     # Greek
    'en'    => ['eng', 'cp1252'],     # English
    'es-es' => ['spa', 'cp1252'],     # Spanish
    'es-us' => ['spl', 'cp1252'],     # Latin American Spanish
    'fi'    => ['fin', 'cp1252'],     # Finnis
    'fr'    => ['fre', 'cp1252'],     # Frenchh
    'hr'    => ['cro', 'cp1250'],     # Croatian (CP 1250)
    'hu'    => ['hun', 'cp1250'],     # Hungarian (CP 1250)
    'is'    => ['ice', 'cp1252'],     # Icelandic
    'it'    => ['ita', 'cp1252'],     # Italian
    'ja'    => ['jpn', 'shiftjis'],   # Japanese (Shift JIS)
    'la'    => ['ltt', 'cp1252'],     # Latin
    'nl'    => ['dut', 'cp1252'],     # Dutch
    'no'    => ['nor', 'cp1252'],     # Norwegian
    'pl'    => ['pol', 'iso-8859-2'], # Polish (ISO 8859-2)
    'pt-br' => ['pob', 'cp1252'],     # Brazilian Portuguese
    'pt-pt' => ['poe', 'cp1252'],     # Portuguese
    'ro'    => ['rom', 'cp1250'],     # Romanian (CP 1250)
    'ru'    => ['rus', 'cp1251'],     # Russian (CP 1251)
    'sl'    => ['slo', 'cp1250'],     # Slovenian (CP 1250)
    'sr'    => ['sel', 'cp1250'],     # Serbian (CP 1250)
    'sv'    => ['swe', 'cp1252'],     # Swedish
    'tl'    => ['tag', 'cp1252'],     # Filipino (Tagalog)
    'tr'    => ['tur', 'cp1254'],     # Turkish (CP 1254)
);

sub new {
    my ($package, %args) = @_;
    my $self = bless \%args, $package;
    
    if (!exists $lang{ $self->{src} }) {
        croak "Source language '" . $self->{src} . "' is not supported";
    }
   
    if (!exists $lang{ $self->{dest} }) {
        croak "Destination language '" . $self->{dest} . "' is not supported";
    }
    
    @{ $self }{'src_lang', 'src_enc'} = @{ $lang{ $self->{src} } };
    @{ $self }{'dest_lang', 'dest_enc'} = @{ $lang{ $self->{dest} } };
    $self->{agent} = LWP::UserAgent->new();
    $self->{uri} = URI->new('http://www.tranexp.com:2000/InterTran');

    return $self;
}

sub translate {
    my ($self, $text) = @_;
    $text = encode($self->{src_enc}, $text);

    # Construct GET parameters
    $self->{uri}->query_form(
        type => 'text',
        text => $text,
        from => $self->{src_lang},
        to   => $self->{dest_lang},
    );

    my $response = $self->{agent}->get($self->{uri}->as_string);
    croak 'Failed to get response from server' if !$response->is_success;
    my $content = $response->content;
    $content = decode($self->{dest_enc}, $content);

    my $translated;
    
    # Try to parse it with TreeBuilder
    eval {
        require HTML::TreeBuilder;
        my $tree = HTML::TreeBuilder->new_from_content($content);
        $translated = $tree->look_down(
            _tag => 'textarea',
            name => 'translation',
        )->attr('_content')->[0];
    };
    return $translated if $translated;
    
    # fall back to parsing it with a regex
    ($translated) = $content =~ m[
        <textarea .*? name="translation" \s* >(.*?)</textarea>
    ]xs;

    return $translated;
}

1;

=head1 NAME

Lingua::Translate::InterTran - A L<Lingua::Translate|Lingua::Translate> backend for InterTran.

=head1 SYNOPSIS

 use Lingua::Translate;

 my $en2is = Lingua::Translate->new(
     back_end => 'InterTran',
     src      => 'en',
     dest     => 'is',
 );

 my $is2en = Lingua::Translate->new(
     back_end => 'InterTran',
     src      => 'is',
     dest     => 'en',
 );

 # prints 'ÉG vilja til hafa kynlíf í kvöld'
 print $en2is->translate('I want to have sex tonight') . "\n";

 # prints 'Myself yearn snuggle up to pursue sex this evening'
 print $is2en->translate('Mig langar að stunda kynlíf i kvöld') . "\n";

=head1 DESCRIPTION

Lingua::Translate::InterTran is a translation back-end for
L<Lingua::Translate|Lingua::Translate> that uses the online translator available
at L<http://www.tranexp.com:2000/Translate/result.shtml>. The author felt
compelled to write a CPAN module for it since it is the only online translator
that can handle his native language, Icelandic (albeit amusingly poorly).

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2008 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
