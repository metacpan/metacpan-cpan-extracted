package Email::Extractor;
$Email::Extractor::VERSION = '0.01';

# ABSTRACT: Fast email crawler


use HTML::Encoding 'encoding_from_html_document';
use List::Compare;
use List::Util qw(uniq);
use Email::Find;
use Mojo::DOM;

use Email::Extractor::Utils qw[:ALL];


sub new {
    my ( $class, %param ) = @_;
    $param{ua} = LWP::UserAgent->new;
    $param{only_lang} = 'ru' if !defined $param{only_lang};
    bless {%param}, $class;
}


sub search_until_attempts {
    my ( $self, $uri, $attempts ) = @_;

    $attempts = 10 if !defined $attempts;
    my $links_checked = 1;
    my $a             = $self->get_emails_from_uri($uri);

    return $a if @$a;

    while ( !@$a && $links_checked <= $attempts )
    {    # but no more than 10 iterations

        my $urls = $crawler->extract_contact_links;
        for my $u (@$urls) {
            $a = $crawler->get_emails_from_uri($u);
            $links_checked++;
        }
    }

    $self->{last_attempts} = $links_checked;
    return $a;
}


sub get_emails_from_uri {
    my ( $self, $addr ) = @_;
    @emails = ();
    $self->{last_uri} = $addr;
    my $text = load_addr_to_str($addr);
    $self->{last_text} =
      $text;    # store html in memory to speed up further search
    my $finder = Email::Find->new(
        sub {
            my ( $email, $orig_email ) = @_;
            push @emails, $orig_email;
        }
    );
    $finder->find( \$text );
    @emails = uniq @emails;
    return \@emails;
}


sub extract_contact_links {
    my ( $self, $text ) = @_;

    $text = $self->{last_text} if !defined $text;

    my $all_links = find_all_links($text);
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
          @{ find_links_by_text( $text, $contacts_loc ) };
    }
    else {
        for my $c ( @{ $self->contacts } ) {
            my $res = find_links_by_text( $text, $c );
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
      contacts
      kontaktyi
      kontakty
      about
      /;
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

version 0.01

=head1 SYNOPSIS

    my $crawler = Email::Extractor->new( only_language => 'ru' );
    
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

=head2 search_until_attempts

Search for email until number of search_until_attempts

=head2 get_emails_from_uri

High-level function uses L<Email::Find>

Found all emails in html page

    $emails = $crawler->get_emails_from_uri('https://example.com');
    $emails = $crawler->get_emails_from_uri('user/test.html');

Function can accept http(s) uri or file paths both

Return C<ARRAYREF>

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

Return C<ARRAYREF>

=head2 contacts

Return hash with contacts word in different languages

    perl -Ilib -E "use Email::Extractor; use Data::Dumper; print Dumper Email::Extractor::contacts();"

=head2 url_with_contacts

Return array of words that may contain contact url

=head2 get_encoding

Return encoding of last loaded html

For detection uses L<HTML::Encoding/encoding_from_html_document>

    $self->get_encoding;
    $self->get_encoding($some_html_code);

If called without parametes it return encoding of last text loaded by function load_addr_to_str()

=head2 contacts

Return hash with contacts word in different languages

    perl -Ilib -E "use Email::Extractor; use Data::Dumper; print Dumper Email::Extractor::contacts();"

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
