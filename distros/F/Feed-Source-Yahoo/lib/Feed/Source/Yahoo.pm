package Feed::Source::Yahoo;

use warnings;
use strict;
use Carp;

use URI;
use constant {
  URL => "http://api.search.yahoo.com/WebSearchService/rss/webSearch.xml",
};

=head1 NAME

Feed::Source::Yahoo - Create a RSS feed based on a Yahoo query

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

If you query Yahoo regurlarly with the same search, maybe is it a good idea to
transform this query in a RSS feed. This simple module can help you :

    use Feed::Source::Yahoo;

    my $feed = Feed::Source::Yahoo->new( query => '"information retrieval"');
    print "The feed URL: " . $feed->url() . "\n";

=head1 FUNCTIONS

=head2 new

=cut

sub new {
  my ($class, %arg) = @_;
  my $self = {};
  
  $self->{URI} = URI->new(URL);
  $self->{params}{appid} = "yahoosearchwebrss";
  $self->{params}{query} = $arg{query} if exists $arg{query};
  bless $self, $class;
}

=head2 url

=cut

sub url {
  my ($self) = @_;
  if (exists $self->{params}{query}) {
    $self->{URI}->query_form($self->{params});
    $self->{URI}->as_string
  } else {
    croak "You must specify a query...";
  }
}

=head2 query

=cut

sub query {
  my $self = shift;
  $self->{params}{query} = shift if @_;
}


=head1 AUTHOR

Emmanuel Di Pretoro, C<< <<manu at bjornoya.net>> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-feed-source-yahoo at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Feed-Source-Yahoo>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Feed::Source::Yahoo

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Feed-Source-Yahoo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Feed-Source-Yahoo>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Feed-Source-Yahoo>

=item * Search CPAN

L<http://search.cpan.org/dist/Feed-Source-Yahoo>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Manu, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Feed::Source::Yahoo
