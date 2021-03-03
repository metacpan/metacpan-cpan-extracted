package Google::ISBNNumbers;

use HTTP::Tiny;
use Cpanel::JSON::XS;
use Carp;
use strict;
use warnings;

our $VERSION = "1.00";

sub new {
	my ($class, $google_api_key) = @_;
	
	# the API key is required
	croak "Google API Key is required to use Google::ISBNNumbers.\n".
		"Please set up a key at https://console.cloud.google.com/apis/credentials" unless $google_api_key;

	# become self, with an HTTP::Tiny and Cpanel::JSON objects
	my $self = bless {
		'api_key' => $google_api_key,
		'http' => HTTP::Tiny->new,
		'json_coder' => Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed,
	}, $class;
		
	return $self;	
}

# method to query the open library for an ISBN number
sub lookup_isbn {
	my ($self, $isbn_number) = @_;

	# can't do much with a valid number
	$isbn_number =~ s/\-|\s//g;
	croak "Valid ISBN number required for lookup_book()" unless $isbn_number =~ /^97/ && $isbn_number !~ /\D/;
	
	# do the lookup!
	my $response = HTTP::Tiny->new->get( 'https://www.googleapis.com/books/v1/volumes?q=isbn:'.$isbn_number.'&key='.$self->{api_key} );
	
	# alert if failure
	croak "Lookup failed: ".$response->{reason} unless $response->{success};
	
	# translate JSON to data struct
	my $results = $self->{json_coder}->decode( $response->{content} );
	
	# must be an array
	croak "Invalid results returned.  Check your API key." unless ref($$results{items}) eq 'ARRAY';

	# we have a book: simplify and return
	my $book_info = $$results{items}[0]{volumeInfo};
	return {
		'title' => $$book_info{title},
		'author_name' => $$book_info{authors}[0],
		'publication_date' => $$book_info{publishedDate},
		'description' => $$book_info{description},
		'cover_link' => $$book_info{imageLinks}{smallThumbnail},
	};

}

1;
__END__

=encoding utf-8

=head1 NAME

Google::ISBNNumbers - Retrieve book info by ISBN number

=head1 SYNOPSIS

    use Google::ISBNNumbers;
    
    $books = Google::ISBNNumbers->new($your_google_api_key);

    $isbn_number = 9781680500882; # may include dashes and spaces
    $book_info = $books->lookup_isbn( $isbn_number );

	# or, if you prefer
	$book_info = Google::ISBNNumbers->new($your_google_api_key)->lookup_isbn($isbn_number); 
    
    # $book_info now has keys for 'title', 'author_name',
    # 'description','publication_date', and 'cover_link'
    say $$book_info{title}; # says 'Modern Perl'

=head1 DESCRIPTION

This module uses the Google Books API to retrieve basic information on a book by its
ISBN Number.  The Google Books API seems to be more complete and reliable than other
resources for searching ISBN numbers.

You will need a Google API key from L<https://console.cloud.google.com/apis/credentials>.
This requires setting up a basic 'Project' in that console, but no sensitive scopes are required,
so you should be able to get the key instantly.  You can read up on the Google Books API
here: L<https://developers.google.com/books>

This should be one of the simplest modules you'll encounter.  The synopsis above pretty 
much covers it. You pass your Google API key to new() and you pass a valid ISBN number
to lookup_isbn(), and you get back a key/value hash of basic info on your book.
FYI: The ISBN number should be found on the back cover, above the bar code, and
starts with '978'.

=head1 SEE ALSO

L<App::isbn>

L<WWW::Scraper::ISBN>

L<Business::ISBN>

=head1 AUTHOR

Eric Chernoff E<lt>eric@weaverstreet.net<gt>

Please send me a note with any bugs or suggestions.

=head1 LICENSE

MIT License

Copyright (c) 2021 Eric Chernoff

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut