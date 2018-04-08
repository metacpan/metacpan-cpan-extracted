package Finance::TickerSymbols;

use strict;
use warnings;
use bytes ;

use Carp ;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw'symbols_list
                 industries_list
                 industry_list
                ' ;

our $VERSION = '3.11';

our $long;

our %inds ;

sub _carp(@) { carp "@_\n" ; ()}

sub _http2name($){
    my  $n = shift ;
    for($n) {
        s/^\s+//s ;
        s/\s+$//s ;
        s/\s+/ /sg ;
        s/\&amp\;/&/g ;
    }
    $n
}

my  $_ua ;
sub  _ua() {

    use LWP ;
    use HTTP::Cookies;
    use File::Temp 'tempfile' ;
    my $ua = new LWP::UserAgent(Accept => "text/html, */*;q=0.1", referer => 'http://google.com') ;
    # my $ua = new LWP::UserAgent() ;
    $ua -> env_proxy() ;
    $ua -> cookie_jar( new HTTP::Cookies (file => tempfile()));
    # print STDERR "I am chrome\n";
    # $ua -> agent("");
    $ua
}

sub  _brws(@) {
    warn "\n@_\n" ; # if $ENV{DEBUG_TICKER_SYMBOL_URL};
    $_ua ||= _ua() ;
    my $res = $_ua->get(@_) ;
    return $res -> content() if $res -> is_success() ;
       $res = $_ua->get(@_) ;
    return $res -> content() if $res -> is_success() ;
    return _carp "download (@_):", $res->status_line() ;
}

sub _gimi($$;@) {
    my $prs = shift ;

    local $_ = _brws(@_) or return ;

    if ($prs eq 'nas' and $long) {
        my @ret ;
        while ( m/^
                  \s* \" ([\w+\.]+) \" \s* \,
                  \s* \" (.*? (?:[^\\] | \\ \\ )) \"
                 /xgm ) { push @ret, "$1:$2" }
        shift  @ret if @ret and $ret[0] eq 'Symbol:Name' ;
        return @ret
    }
    elsif ($prs eq 'nas') {
        my @ret ;
        while (m/^ \s* \" ([\w+\.]+) \"
                /xgm ) { push @ret, $1 }
        shift  @ret if @ret and $ret[0] eq 'Symbol' ;
        return @ret ;
    }
    elsif ($prs eq 'ind' and $long) {
        my @ret ;
        while ( m{ a \s+
                   href\=\"/quote/(\w+)\?p\=\w+\" \s+
                   title\=\"([^\"]+)\"
             }xgs ) {push @ret, $1 . ':'. _http2name $2 }
        return @ret
    }
    elsif ($prs eq 'ind') {
        return
          m{a \s+
            href\=\"/quote/(\w+)\?p\=\w+\" \s+
            title\=\"[^\"]+\"
            }xgs
    }
    elsif ($prs eq 'inds') {

        while (m{href\=\"/industry/([^\"]+)\"\s+title=\"([^\"]+)\"}g) {
            my ($d, $n) = ($1, $2) ;
            $inds{ _http2name $n } = $d if $d =~ /\w/ and $n =~ /\w/;
        }
        return keys %inds;
    }
}

sub _gimi_nasdaq($) {
    my $url = 'http://www.nasdaq.com/screening/companies-by-name.aspx?letter=0&exchange=' . shift ;
    # my $dummy = _brws($url);
    _gimi nas => $url . '&render=download';
}

sub symbols_list($) {

    my $wt = shift || '?';
    my @all = qw/nasdaq amex nyse/ ;
    return _gimi_nasdaq uc $wt            if grep {$_ eq $wt } @all ;
    return map {_gimi_nasdaq uc $_ } @all if $wt eq 'all';
    return _carp "bad parameter: should be " . join '|', @all, 'all' ;
}

sub industries_list { _gimi inds => 'https://finance.yahoo.com/industries/' }

sub industry_list($) {
    %inds or industries_list() ;
    my $name = shift ;
    $name or return _carp "Illegal arg" ; # undef, 0, ''
    my $n = $inds{$name} or return _carp "'$name' is not recognized" ;

    # my $p = 'pub' ; # shift || ''; $p = 'pub' unless $p eq 'prv' or $p eq 'all' ;
    #                 # ?? TODO ??
    #                 # support Private/Foreign ? what for?
    _gimi ind => "https://finance.yahoo.com/industry/$n"
}

1;

__END__

=head1 NAME

Finance::TickerSymbols - Perl extension for getting symbols lists
                         from web resources

=head1 SYNOPSIS


  use Finance::TickerSymbols;
  for my $symbol ( symbols_list('all') ) {

     # do something with this $symbol
  }

  for my $industry ( industries_list()) {

     for my $symbol ( industry_list( $industry ) ) {

         # do something with $symbol and $industry

     }
  }

=head1 DESCRIPTION

get lists of ticker symbols. this list can be used for market queries.

=over 2

=item symbols_list

symbols_list( 'nasdaq' | 'amex' | 'nyse' | 'all' )
returns the apropriate array of symbols.

=item industries_list

industries_list()
returns array of industries names.

=item industry_list

industry_list( $industry_name )
returns array of symbols related with $industry_name

=item $Finance::TickerSymbols::long

setting $Finance::TickerSymbols::long to non-false would attach company name to each symbol
  (as "ARTNA:Basin Water, Inc." compare to "ARTNA")

=back

=head2 PROXY

Users may define proxy using environment variables.
examples (from LWP::UserAgent manuel):

      gopher_proxy=http://proxy.my.place/
      wais_proxy=http://proxy.my.place/
      no_proxy="localhost,my.domain"


=head2 TODO

=over 2

=item more markets

=back

=head1 SEE ALSO

  LWP
  http://quotes.nasdaq.com
  http://biz.yahoo.com/ic
  Finance::*

=head1 AUTHOR

Josef Ezra, E<lt>jezra@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Josef Ezra

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head2 NOTES

- the returned data depends upon availability and format of
  external web sites. Needless to say, it is not guaranteed.


=head1 BUGS, REQUESTS, NICE IMPLEMENTATIONS, ETC.

Please email me about any of the above. I'll be more then happy to share
interesting implementation of this module.

=cut
