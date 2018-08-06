# NAME

Email::Extractor - Fast email crawler

# VERSION

version 0.01

# SYNOPSIS

    my $crawler = Email::Extractor->new( only_language => 'ru' );
    
    $crawler->search_until_attempts('https://example.com' , 5);

    my $arrayref = $crawler->get_emails_from_uri($website);

    while (!@$arrayref) {
        my $urls_array = extract_contact_links($website);
        for my $url (@$urls_array) {
            $arrayref = $crawler->get_emails_from_uri($url);
        }
    }

# DESCRIPTION

Speedy crawler that can be used for extraction of email addresses from html pages

Sharpen for russian language but you are welcome to send me MR with support of your own language, 
just modify ["contacts" in Email::Extractor](https://metacpan.org/pod/Email::Extractor#contacts) and ["url\_with\_contacts" in Email::Extractor](https://metacpan.org/pod/Email::Extractor#url_with_contacts)

# NAME

Email::Extractor

# AUTHORS

Pavel Serkov <pavelsr@cpan.org>

## new

Constructor

Params:

    only_lang - array of languages to check, by default is C<ru>

## search\_until\_attempts

Search for email until number of search\_until\_attempts

## get\_emails\_from\_uri

High-level function uses [Email::Find](https://metacpan.org/pod/Email::Find)

Found all emails in html page

    $emails = $crawler->get_emails_from_uri('https://example.com');
    $emails = $crawler->get_emails_from_uri('user/test.html');

Function can accept http(s) uri or file paths both

Return `ARRAYREF`

## extract\_contact\_links

Extract links that may contain company contacts

    $crawler->get_emails_from_uri('http://example.com');
    $crawler->extract_contact_links;

or you can load html manually and call this method with param:

    $crawler->extract_contact_links($html)

But in that case method will not remove external links and make absolute

Technically, this method to three things:

1) Extract all links that from html document (accepted as string)

2) Remove external links.

3) Store links that assumed to be contact separately. 
Assumption is made by looking on href and body of a tags

Support both absolute or relative links

Use [Mojo::DOM](https://metacpan.org/pod/Mojo::DOM) currently

Veriables for debug:

    $crawler->{last_all_links}  # all links that was get in start of extract_contact_links method
    $self->{non_contact_links}  # links assumed not contained company contacts
    $self->{last_uri}

Return `ARRAYREF`

## contacts

Return hash with contacts word in different languages

    perl -Ilib -E "use Email::Extractor; use Data::Dumper; print Dumper Email::Extractor::contacts();"

## url\_with\_contacts

Return array of words that may contain contact url

## get\_encoding

Return encoding of last loaded html

For detection uses ["encoding\_from\_html\_document" in HTML::Encoding](https://metacpan.org/pod/HTML::Encoding#encoding_from_html_document)

    $self->get_encoding;
    $self->get_encoding($some_html_code);

If called without parametes it return encoding of last text loaded by function load\_addr\_to\_str()

## contacts

Return hash with contacts word in different languages

    perl -Ilib -E "use Email::Extractor; use Data::Dumper; print Dumper Email::Extractor::contacts();"

## get\_encoding

Return encoding of last loaded html

For detection uses ["encoding\_from\_html\_document" in HTML::Encoding](https://metacpan.org/pod/HTML::Encoding#encoding_from_html_document)

    $self->get_encoding;
    $self->get_encoding($some_html_code);

If called without parametes it return encoding of last text loaded by function load\_addr\_to\_str()

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
