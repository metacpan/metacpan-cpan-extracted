package Google::Ranker;

use warnings;
use strict;

=head1 NAME

Google::Ranker - Find the ranking of a site/result against a search

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Google::Ranker;
    
    my $rank = Google::Ranker->rank("search.cpan.org", { q => "perl network", key => ..., referer => ... });
    # (Make sure to get a valid key and referer from http://code.google.com/apis/ajaxsearch/signup.html first)

    # Or pass in a prepared search:
    
    my $search = Google::Search->Local(...);
    my $rank = Google::Ranker->rank("example.com", $search);

    # You can also rank against different criteria:
    
    my $search = Google::Search->Video(q => "tay zonday", ...);
    my $rank = Google::Ranker->rank(sub { $_[0]->titleNoFormatting =~ m/Chocolate Rain/i }, $search);

=head1 DESCRIPTION

Google::Ranker will determine the rank of a result matching some criteria within a search. The search
can be done on any of Google's search services, including web, local, news, blogs, images, videos, and books.

This connects to Google's AJAX Search API (L<http://code.google.com/apis/ajaxsearch/>) and is built upon
L<Google::Search>

=cut

use Google::Search;
use Scalar::Util qw/blessed/;
use Carp;

=head1 METHODS

=head2 Google::Rank->rank( <match>, <search> )

Returns the numeric rank for <match> in <search>

Returns undef if <match> is not found (very possible, since the Google AJAX API only returns a limited
number of results at this time)

The first result from Google is ranked at 1

The parameter <match> can either be a string converted into a regular expression, 
a regular expression to be matched against the uri of each result, or a code reference
passed each result (in turn) as the first parameter.

The parameter <search> should be a L<Google::Search> or a hash reference to be passed to 
Google::Search->new(...)

At minimum you must pass in a C<key>, a C<referer>, and a C<q> (the actual query)

=cut

sub rank {
    my $class = shift;
    my $matcher = shift;
    my $search = shift;

    if (defined $search && ref $search eq "") {
        warn "\n# ", __FILE__, ":", __LINE__, "\n", <<_END_;
# Running a search without a valid API key/referer
# Pass in a key => ... and referer => ... to disable this warning
# You can get both at http://code.google.com/apis/ajaxsearch/signup.html

_END_
        $search = { q => $search };
    }
    if (ref $search eq "HASH") {
        $search = Google::Search->Web(%$search);
    }

    croak "Don't have a search to rank with" unless $search;
    croak "Don't understand search \"$search\"" unless blessed $search && $search->isa("Google::Search");
    croak "Don't have a matcher to find ranking position with" unless $matcher;

    $matcher = qr/$matcher/ if ref $matcher eq "";
    if (ref $matcher eq "Regexp") {
        my $re = $matcher;
        $matcher = sub {
            return $_[0]->uri->as_string =~ $re;
        };
    }
    unless (ref $matcher eq "CODE") {
        croak "Don't understand matcher \"$matcher\"";
    }

    my $result = $search->first_match($matcher);

    return undef unless defined $result;

    return $result->number + 1;
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SEE ALSO

L<Google::Search>

=head1 BUGS

Please report any bugs or feature requests to C<bug-google-ranker at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Google-Ranker>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Google::Ranker


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Google-Ranker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Google-Ranker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Google-Ranker>

=item * Search CPAN

L<http://search.cpan.org/dist/Google-Ranker>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Google::Ranker
