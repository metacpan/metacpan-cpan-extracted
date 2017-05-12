package Lyrics::Fetcher::Google;
use strict;
use warnings;
use Exporter;
use Net::Google;
use LWP::UserAgent;
use String::Similarity;
use HTML::LinkExtractor;
use HTML::TokeParser::Simple;

our @ISA = qw(Exporter);
our $VERSION = '0.02';

use constant MIN_STRING_LENGTH    => 200;
use constant MAX_BLOCKS_TO_SEARCH => 4;

my ($class) = @_;
my $ua      = new LWP::UserAgent;
my $lx      = new HTML::LinkExtractor;
$Lyrics::Fetcher::Error = 'OK';

sub fetch($$$) {
    my $self = shift;
    my ( $artist, $song ) = @_;
    my @links = &links( $artist, $song );

    $Lyrics::Fetcher::Error =
      "Could not get any results from google. Did you supply a gid?"
      unless (@links);

    my $totaltext;

    foreach my $link (@links) {
        $totaltext .= &get($link);
    }

    my @biggest = &biggest_blocks($totaltext);
    my %songs   = &most_similar( splice( @biggest, 0, MAX_BLOCKS_TO_SEARCH ) );

#@results contains multiple entries. Only the first(highest weighted) entry is returned.
    my @results = sort { $songs{$b} <=> $songs{$a} } keys %songs;
    return shift(@results);
}

sub links {
    my ( $artist, $song ) = @_;
    my $google = Net::Google->new( key => $Lyrics::Fetcher::gid );
    my $search = $google->search();
    $search->max_results(5);
    $search->query( $artist, $song, 'lyrics' );
    return map { $_ = $_->{__URL} } @{ $search->results() };
}

sub get {
    my ($url) = @_;
    $ua->timeout(6);
    $ua->agent("Mozilla/5.0");
    my $res = $ua->get($url);
    if ( $res->is_success ) {
        return $res->content;
    }
}

sub biggest_blocks {
    my ($html) = @_;
    my $p      = HTML::TokeParser::Simple->new( \$html );
    my @blocks = ();

    my $tc = '';
    while ( my $token = $p->get_token ) {

        if ( $token->is_tag('br') ) { $tc .= "\n"; next; }

        if ( $token->is_text ) {
            my $t = $token->as_is;
            $t =~ s/\&\#\d+\;//gs;
            $t =~ s/<\/*.*?>//gs;
            $t =~ s/([a-z])([A-Z])/$1\n$2/gs;
            $t =~ s/\s+/ /gs;
            $tc .= " $t";
        }
        else {
            push( @blocks, $tc ) if ( length($tc) > MIN_STRING_LENGTH );
            $tc = '';
        }
    }
    return sort { length $b <=> length $a } @blocks;
}

sub most_similar {
    my (@strings) = @_;
    my %rank;
    foreach my $outside (@strings) {
        foreach my $inside (@strings) {
            $rank{$outside} += similarity( $outside, $inside );
        }
    }
    return %rank;
}

1;

=pod

=head1 NAME

Lyrics::Fetcher::Google - Get some lyrics. Maybe.


=head1 SYNOPSIS

  use Lyrics::Fetcher;

  $Lyrics::Fetcher::gid = '<your google API id>';

  print Lyrics::Fetcher->fetch("<artist>","<song>","Google");


=head1 DESCRIPTION

This module tries to find lyrics on the web.
Sometimes it works. But it probably won't.

It searches google for an initial set. It then
finds the largest block of plain text in the top
5 results. Those results are then compared to
one another and weighted. The idea being that
a large block of text on one site may be a bunch
of poo, but a large area of similar text on multiple
sites most likely is the lyrics for which you are
looking.


=head1 BUGS

Yes. I would be happy to hear that this worked for someone.
Let me know if it does. I may even respond if you let me 
know that it doesn't.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

John Lifsey <nebulous@crashed.net>

=cut

__END__


