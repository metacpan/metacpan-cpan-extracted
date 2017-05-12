package HTTP::AcceptLanguage;
use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.02';

our $MATCH_PRIORITY_0_01_STYLE;

my $LANGUAGE_RANGE = qr/(?:[A-Za-z0-9]{1,8}(?:-[A-Za-z0-9]{1,8})*|\*)/;
my $QVALUE         = qr/(?:0(?:\.[0-9]{0,3})?|1(?:\.0{0,3})?)/;

sub new {
    my($class, $header) = @_;

    my @parsed_header;
    if ($header) {
        @parsed_header = $class->_parse($header);
    }

    bless {
        header        => $header,
        parsed_header => \@parsed_header,
    }, $class;
}

sub _parse {
    my($class, $header) = @_;
    $header =~ s/\s//g; #loose

    my @elements;
    my %high_qualities;
    for my $element (split /,+/, $header) {
        my($language, $quality) = $element =~ /\A($LANGUAGE_RANGE)(?:;q=($QVALUE))?\z/;
        $quality = 1 unless defined $quality;
        next unless $language && $quality > 0;

        my($primary) = split /-/, $language;
        push @elements, {
            language            => $language,
            language_primary_lc => lc($primary),
            language_lc         => lc($language),
            quality             => $quality,
        };
        if ((not exists $high_qualities{$language}) || $quality >  $high_qualities{$language}) {
            $high_qualities{$language} = $quality;
        }
    }

    # RFC2616: The language quality factor assigned to a language-tag by the Accept-Language field is the quality value of the longest language- range in the field that matches the language-tag.
    grep {
        my $language = $_->{language};
        $high_qualities{$language} ? (
            $high_qualities{$language} == $_->{quality} ? delete $high_qualities{$language} : 0
        ) : 0;
    } @elements;
}

sub languages {
    my $self = shift;
    $self->{languages} ||= do {
        use sort 'stable';
        my @languages = map { $_->{language} } sort { $b->{quality} <=> $a->{quality} } @{ $self->{parsed_header} };
        \@languages;
    };
    @{ $self->{languages} };
}

sub match {
    my($self, @languages) = @_;
    my @normlized_languages = map {
        $_ ? ( +{
            tag    => $_,
            tag_lc => lc($_),
        } ) : ()
    } @languages;
    return undef unless scalar(@normlized_languages);

    unless (scalar(@{ $self->{parsed_header} })) {
        # RFC2616: SHOULD assume that all languages are equally acceptable. If an Accept-Language header is present, then all languages which are assigned a quality factor greater than 0 are acceptable.
        return $normlized_languages[0]->{tag};
    }

    $self->{sorted_parsed_header} ||= do {
        use sort 'stable';
        [ sort { $b->{quality} <=> $a->{quality} } @{ $self->{parsed_header} } ];
    };

    # If language-quality has the same value, is a priority order of the $self->{sorted_parsed_header}.
    # If you set $MATCH_PRIORITY_0_01_STYLE=1, takes is a priority order of the @languages
    if ($MATCH_PRIORITY_0_01_STYLE) {
        my %header_tags;
        my %header_primary_tags;
        my $detect_langguage = sub {
            if (scalar(%header_tags)) {
                # RFC give priority to full match.
                for my $tag (@normlized_languages) {
                    return $tag->{tag} if $header_tags{$tag->{tag_lc}};
                }
                for my $tag (@normlized_languages) {
                    return $tag->{tag} if $header_primary_tags{$tag->{tag_lc}};
                }
            }
        };
        my $current_quality = 0;
        for my $language (@{ $self->{sorted_parsed_header} }) {
            if ($current_quality != $language->{quality}) {
                # check of the last quality languages
                my $ret = $detect_langguage->();
                return $ret if $ret;

                # cleanup
                $current_quality = $language->{quality};
                %header_tags         = ();
                %header_primary_tags = ();
            }

            # wildcard
            return $normlized_languages[0]->{tag} if $language->{language} eq '*';

            $header_tags{$language->{language_lc}}                 = 1;
            $header_primary_tags{$language->{language_primary_lc}} = 1;
        }

        my $ret = $detect_langguage->();
        return $ret if $ret;
    } else {
        # 0.02 or more
        for my $language (@{ $self->{sorted_parsed_header} }) {
            # wildcard
            return $normlized_languages[0]->{tag} if $language->{language} eq '*';

            # RFC give priority to full match.
            for my $tag (@normlized_languages) {
                return $tag->{tag} if $language->{language_lc} eq $tag->{tag_lc};
            }
            for my $tag (@normlized_languages) {
                return $tag->{tag} if $language->{language_primary_lc} eq $tag->{tag_lc};
            }
        }
    }

    return undef; # not matched
}

1;
__END__

=encoding utf-8

=head1 NAME

HTTP::AcceptLanguage - Accept-Language header parser and find available language

=head1 HOW DO I USE THIS MODULE WITH

=head2 WITH CGI.pm

  use HTTP::AcceptLanguage;
  my $lang = HTTP::AcceptLanguage->new($ENV{HTTP_ACCEPT_LANGUAGE})->match(qw/ en fr es ja zh-tw /);

=head2 WITH raw PSGI

  use HTTP::AcceptLanguage;
  my $lang = HTTP::AcceptLanguage->new($env->{HTTP_ACCEPT_LANGUAGE})->match(qw/ en fr es ja zh-tw /);

=head2 WITH Plack::Request

  use HTTP::AcceptLanguage;
  my $lang = HTTP::AcceptLanguage->new($req->header('Accept-Language'))->match(qw/ en fr es ja zh-tw /);

=head1 SYNOPSIS

Good example of the input and output.

  # If language quality is the same then order by match method's input list
  my $accept_language = HTTP::AcceptLanguage->new('en;q=0.5, ja;q=0.1');
  $accept_language->match(qw/ th da ja /); # -> ja
  $accept_language->match(qw/ en ja /);    # -> en

  my $accept_language = HTTP::AcceptLanguage->new('en, da');
  $accept_language->match(qw/ da en /); # -> en
  $accept_language->match(qw/ en da /); # -> en

You can obtain the order of preference of the available languages ​​list of client

  my $accept_language = HTTP::AcceptLanguage->new('en, ja;q=0.3, da;q=1, *;q=0.29, ch-tw');
  $accept_language->languages; # -> en, da, ch-tw, ja, *

You can use the 0.01 version spec. (next version is deplicated)

  local $HTTP::AcceptLanguage::MATCH_PRIORITY_0_01_STYLE = 1;
  
  my $accept_language = HTTP::AcceptLanguage->new('en, da');
  $accept_language->match(qw/ da en /); # -> da
  $accept_language->match(qw/ en da /); # -> en

=head1 DESCRIPTION

HTTP::AcceptLanguage is HTTP Accept-Language header parser And you can find available language by Accept-Language header.

=head1 METHODS

=head2 new($ENV{HTTP_ACCEPT_LANGUAGE})

It to specify a string of Accept-Language header.

=head2 match(@available_language)

By your available language list, returns the most optimal language.

If language-quality has the same value, is a priority order of the new($ENV{HTTP_ACCEPT_LANGUAGE}).

=head2 languages

Returns are arranged in order of quality language list parsed.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 COPYRIGHT

Copyright 2013- Kazuhiro Osawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

RFC2616, L<I18N::AcceptLanguage>

=cut
