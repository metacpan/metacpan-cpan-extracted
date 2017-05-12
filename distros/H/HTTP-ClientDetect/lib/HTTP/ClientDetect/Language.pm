package HTTP::ClientDetect::Language;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Moo;

use Locale::Language;
use Locale::Country;

my @languages = all_language_codes();
my @countries = all_country_codes();

my %langs = map { $_ => 1 } @languages;
my %countrs  = map { $_ => 1 } @countries;

=head1 NAME

HTTP::ClientDetect::Language - Lookup the client's preferred language

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

    use HTTP::ClientDetect::Language;
    my $lang_detect = HTTP::ClientDetect::Language->new(server_default => "en_US");
    # inside a Dancer route
    get '/detect' => sub {
        my $req = request;
        my $lang = $lang_detect->language($req);
    }


=head1 ACCESSORS

=head2 server_default

The C<server_default> should be set in the constructor and defaults to
C<en_US>. This will be always returned if the lookup fails

=cut


has server_default => (is => 'rw',
                       default => sub { return "en_US" },
                       isa => sub {
                           die "Bad language $_[0]\n"
                             unless __PACKAGE__->check_language_name($_[0]);
                       });


=head2 available_languages

Accessor to an arrayref of languages available on the server side.
Please use the short version (C<de>, not C<de_DE>), otherwise the
check will be too restrictive.

=cut

has available_languages => (is => 'rw',
                            isa => sub {
                                my $aref = $_[0];
                                die "Not an arrayref" unless ref($aref) eq 'ARRAY';
                                foreach my $l (@$aref) {
                                    die "Bad language $l\n"
                                      unless __PACKAGE__->check_language_name($l);
                                }
                            },
                            default => sub { [] },
                           );


=head1 SUBROUTINES/METHODS

=head2 language($request_obj)

Return the preferred language of the request. The request object
should an object which has the methods C<accept_language> or C<header>

From L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html>:

 The Accept-Language request-header field is similar to Accept, but
 restricts the set of natural languages that are preferred as a
 response to the request. Language tags are defined in section 3.10.

       Accept-Language = "Accept-Language" ":"
                         1#( language-range [ ";" "q" "=" qvalue ] )
       language-range  = ( ( 1*8ALPHA *( "-" 1*8ALPHA ) ) | "*" )

 Each language-range MAY be given an associated quality value which
 represents an estimate of the user's preference for the languages
 specified by that range. The quality value defaults to "q=1". For
 example,

       Accept-Language: da, en-gb;q=0.8, en;q=0.7

 would mean: "I prefer Danish, but will accept British English and
 other types of English." A language-range matches a language-tag if
 it exactly equals the tag, or if it exactly equals a prefix of the
 tag such that the first tag character following the prefix is "-".
 The special range "*", if present in the Accept-Language field,
 matches every tag not matched by any other range present in the
 Accept-Language field.

      Note: This use of a prefix matching rule does not imply that
      language tags are assigned to languages in such a way that it is
      always true that if a user understands a language with a certain
      tag, then this user will also understand all languages with tags
      for which this tag is a prefix. The prefix rule simply allows the
      use of prefix tags if this is the case.

 The language quality factor assigned to a language-tag by the
 Accept-Language field is the quality value of the longest language-
 range in the field that matches the language-tag. If no language-
 range in the field matches the tag, the language quality factor
 assigned is 0. If no Accept-Language header is present in the
 request, the server

 SHOULD assume that all languages are equally acceptable. If an
 Accept-Language header is present, then all languages which are
 assigned a quality factor greater than 0 are acceptable.

  It might be contrary to the privacy expectations of the user to send
  an Accept-Language header with the complete linguistic preferences
  of the user in every request

=cut

sub language {
    my ($self, $obj) = @_;
    my @browser_langs = $self->browser_languages($obj);
    my @avail = @{$self->available_languages};
    if (@avail) {
        foreach my $ua_lang (@browser_langs) {
            foreach my $avail_lang (@avail) {
                if ($ua_lang =~ m/^\Q$avail_lang\E(_[A-Z]+)?$/) {
                    return $ua_lang;
                }
            }
        }
        # nothing? then return the server default
        return $self->server_default;
    }
    else {
        return $browser_langs[0];
    }
}

=head2 browser_languages($request)

This method returns the parsed and sorted list of language preferences
set in the browser, when the first element has higher priority.

=cut

sub browser_languages {
    my ($self, $obj) = @_;
    return $self->server_default unless $obj;
    my $accept_str;
    if ($obj->can("accept_language")) {
        $accept_str = $obj->accept_language;
    }
    # nothing? try with header, but don't count too much on this
    if (!$accept_str and $obj->can("header")) {
        $accept_str = $obj->header('Accept-Language');
    }
    return $self->server_default unless $accept_str;
    
    # split the string at ,
    my @langs = split(/\s*,\s*/, $accept_str);
    my @to_order;
    foreach my $lang_str (@langs) {
        next unless $lang_str;
        my ($q, $code);
        if ($lang_str =~ m/([a-zA-Z]+([-_][a-zA-Z]+)?)\s*(;\s*q\s*=\s*([0-9\.]+))?/) {
            $code = $self->check_language_name($1);
            $q = $4 || 1;
        }
        next unless $code;
        push @to_order, [ $code => $q ];
        # sort by q
    }
    return $self->server_default unless @to_order;
    my @ordered = sort { $b->[1] <=> $a->[1] } @to_order;
    return map { $_->[0] } @ordered;
}

=head3 language_short($request_obj)

Return the short language version (i.e.), the language name without
the country part.

=cut

sub language_short {
    my ($self, $obj) = @_;
    my $lang = $self->language($obj);
    # strip the second part
    $lang =~ s/_.*$//;
    return $lang;
}


=head3 check_language_name

Returns a normalized version of the language name, lower case for the
language, upper case for the country. Undef it was not possible to
validate it.

=cut

sub check_language_name {
    my ($self, $code) = @_;
    my ($lang, $country);
    return unless $code;
    if ($code =~ m/([a-zA-Z]{2})([_-]([a-zA-Z]*))?/) {
        $lang = $1;
        $country = $3 || "";
    }
    else {
        $lang = $code;
        $country = $code; # eg. fr fr
    }
    # lowercase;
    $lang = lc($lang);
    $country = lc($country);
    # check the lang;
    return unless $langs{$lang};
    # if the country doesn't validate, we fix the common scenario (en
    # => US), and append the same
    if ($countrs{$country}) {
        return $lang . "_" . uc($country);
    }
    # then do some heuristics, if the country didn't match
    if ($lang eq 'en') {
        return $lang . "_US";
    }
    # then try the language as a country
    if ($countrs{$lang}) {
        return $lang . "_" . uc($lang);
    }
    # if we are still here, return the language, there are cases we
    # can't catch, like ja_JP
    return $lang;
}


=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-interchange6-plugin-autodetect at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-ClientDetect>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::ClientDetect::Language


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-ClientDetect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-ClientDetect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-ClientDetect>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-ClientDetect/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Marco Pessotto.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of HTTP::ClientDetect::Language
