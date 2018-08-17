package Email::Extractor;
$Email::Extractor::VERSION = '0.03';

# ABSTRACT: Fast email crawler


use HTML::Encoding 'encoding_from_html_document';
use List::Compare;
use List::Util qw(uniq);
use Email::Find;
use Email::Valid;
use Mojo::DOM;

use Email::Extractor::Utils qw[:ALL];


sub new {
    my ( $class, %param ) = @_;
    $param{ua} = LWP::UserAgent->new;
    $param{timeout} = 20 if !defined $param{timeout};
    $param{ua}->timeout( $param{timeout} );
    $param{only_lang} = 'ru' if !defined $param{only_lang};
    $Email::Extractor::Utils::Verbose = 1 if $param{verbose};
    bless {%param}, $class;
}


sub search_until_attempts {
    my ( $self, $uri, $attempts ) = @_;

    $attempts = 10 if !defined $attempts;
    my $emails = $self->get_emails_from_uri($uri);

    my $links_checked = 1;
    print "No emails found on specified url\n"
      if ( !@$emails && $self->{verbose} );
    return $emails if @$emails;

    my $urls = $self->extract_contact_links;

    print "Contact links found: " . scalar @$urls . "\n"
      if ( @$urls && $self->{verbose} );
    print "No contact links found\n" if ( !@$urls && $self->{verbose} );
    return if !@$urls;

    for my $u (@$urls) {

        $emails = $self->get_emails_from_uri($u);
        $links_checked++;
        $self->{last_attempts} = $links_checked;
        return $emails if @$emails;
        return $emails if ( $links_checked >= $attempts );
    }

    return $emails;    # can be empty array

}


sub get_emails_from_uri {
    my ( $self, $addr ) = @_;
    @emails = ();
    $self->{last_uri} = $addr;
    my $text = load_addr_to_str($addr);
    $self->{last_text} =
      $text;    # store html in memory to speed up further search
    return $self->_get_emails_from_text($text);
}

sub _get_emails_from_text {
    my ( $self, $text ) = @_;
    my $finder = Email::Find->new(
        sub {
            my ( $email, $orig_email ) = @_;
            push @emails, $orig_email;
        }
    );
    $finder->find( \$text );
    @emails = uniq @emails;

    # remove values that passes email validation but in fact are not emails
    # L<Email::Extractor/get_exceptions>
    @emails = grep { !isin( $_, $self->get_exceptions ) } @emails;

    # MX record checking
    @emails =
      grep { defined Email::Valid->address( -address => $_, -mxcheck => 1 ) }
      @emails;

    return \@emails;
}


sub extract_contact_links {
    my ( $self, $text ) = @_;

    $text = $self->{last_text} if !defined $text;
    return if !defined $text;

    my $all_links = find_all_links($text);
    return if ( !@$all_links );

    $self->{last_all_links} = $all_links;

    # TO-DO: do not remove links on social networks since there can be email too
    if ( $self->{last_uri} ) {
        $all_links = remove_external_links( $all_links, $self->{last_uri} );
        $all_links = absolutize_links_array( $all_links, $self->{last_uri} );
    }

    $all_links = remove_query_params($all_links);
    $all_links = drop_asset_links($all_links);
    $all_links = drop_anchor_links($all_links);

    my @potential_contact_links;

    if ( $self->{only_lang} ) {
        my $contacts_loc = $self->contacts->{ $self->{only_lang} };
        push @potential_contact_links,
          @{ find_links_by_text( $text, $contacts_loc, 1 ) };
    }
    else {
        for my $c ( @{ $self->contacts } ) {
            my $res = find_links_by_text( $text, $c, 1 );
            push @potential_contact_links, @$res;
        }
    }

    my $grep_url_expr = join( '|', $self->url_with_contacts );
    my @potential_contact_links_by_url =
      grep { $_ =~ /$grep_url_expr/ } @$all_links;

    my @contact_links =
      ( @potential_contact_links_by_url, @potential_contact_links );
    @contact_links = uniq @contact_links;

    $self->{non_contact_links} =
      List::Compare->new( $all_links, \@contact_links )->get_symdiff;

    return \@contact_links;

}


sub contacts {
    return {
        'en' => 'Contacts',
        'ru' => 'Контакты',
    };
}


sub url_with_contacts {
    return qw/
      contact
      contacts
      kontaktyi
      kontakty
      kontakti
      about
      /;
}


sub get_exceptions {
    return [ '!--Rating@Mail.ru' ];
}


sub get_encoding {
    my ( $self, $html ) = @_;
    my $html_to_check = $html || $self->{last_text};
    return encoding_from_html_document($html_to_check);
}


sub contacts {
    return {
        'en' => 'Contacts',
        'ru' => 'Контакты',
    };
}


sub get_encoding {
    my ( $self, $html ) = @_;
    my $html_to_check = $html || $self->{last_text};
    return encoding_from_html_document($html_to_check);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::Extractor - Fast email crawler

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $crawler = Email::Extractor->new( only_language => 'ru', timeout => 30 );
    
    $crawler->search_until_attempts('https://example.com' , 5);

    my $arrayref = $crawler->get_emails_from_uri($website);

    while (!@$arrayref) {
        my $urls_array = extract_contact_links($website);
        for my $url (@$urls_array) {
            $arrayref = $crawler->get_emails_from_uri($url);
        }
    }

=head1 DESCRIPTION

Speedy crawler that can be used for extraction of email addresses from html pages

Sharpen for russian language but you are welcome to send me MR with support of your own language, 
just modify L<Email::Extractor/contacts> and L<Email::Extractor/url_with_contacts>

=head1 NAME

Email::Extractor

=head1 AUTHORS

Pavel Serkov <pavelsr@cpan.org>

=head2 new

Constructor

Params:

    only_lang - array of languages to check, by default is C<ru>
    timeout   - timeout of each request in seconds, by default is C<20>

=head2 search_until_attempts

Search for email until specified number of GET requests

    my $emails = $crawler->search_until_attempts( $uri, 5 );

Return C<ARRAYREF> or C<undef> if no emails found

=head2 get_emails_from_uri

High-level function uses L<Email::Find>

Found all emails (regexp accoding RFC 822 standart) in html page

    $emails = $crawler->get_emails_from_uri('https://example.com');
    $emails = $crawler->get_emails_from_uri('user/test.html');

Function can accept http(s) uri or file paths both

Return C<ARRAYREF> (can be empty)

=head2 extract_contact_links

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

Use L<Mojo::DOM> currently

Veriables for debug:

    $crawler->{last_all_links}  # all links that was get in start of extract_contact_links method
    $self->{non_contact_links}  # links assumed not contained company contacts
    $self->{last_uri}

Return C<ARRAYREF> or C<undef> if no contact links found

=head2 contacts

Return hash with contacts word in different languages

    perl -Ilib -E "use Email::Extractor; use Data::Dumper; print Dumper Email::Extractor::contacts();"

=head2 url_with_contacts

Return array of words that may contain contact url

    perl -Ilib -E "use Email::Extractor; use Data::Dumper; print Dumper Email::Extractor::url_with_contacts();"

=head2 get_exceptions

Return array of addresses that L<Email::Find> consider as email but in fact it is no

    perl -Ilib -E "use Email::Extractor; use Data::Dumper; print Dumper Email::Extractor::exceptions();"

=head2 get_encoding

Return encoding of last loaded html

For detection uses L<HTML::Encoding/encoding_from_html_document>

    $self->get_encoding;
    $self->get_encoding($some_html_code);

If called without parametes it return encoding of last text loaded by function load_addr_to_str()

=head2 contacts

Return hash with contacts word in different languages

    perl -Ilib -E "use Email::Extractor; use Data::Dumper; print Dumper Email::Extractor::contacts();"

Links checked in uppercase and lowecase also

=head2 get_encoding

Return encoding of last loaded html

For detection uses L<HTML::Encoding/encoding_from_html_document>

    $self->get_encoding;
    $self->get_encoding($some_html_code);

If called without parametes it return encoding of last text loaded by function load_addr_to_str()

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
