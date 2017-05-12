package Geo::TigerLine::Abbreviations;
BEGIN {
  $Geo::TigerLine::Abbreviations::VERSION = '0.04';
}
use strict;
use warnings;
use Cache::FileCache;
use LWP::Simple;
use vars qw(%Dict);

init();

sub init {
    for my $abbr ( @{_get_dictionary()} ) {
	push @{$Dict{$abbr->{$_}}}, $abbr for keys %$abbr;
    }
    for ( keys %Dict ) {
	@{$Dict{$_}} = unique( @{$Dict{$_}} );
    }
}

sub unique {
    my %seen;
    $seen{$_} = $_ for @_;
    return values %seen;
}

sub _get_dictionary {
    my $cache = Cache::FileCache->new
	( { namespace => 'TigerLINE',
	    default_expires_in => $Cache::Cache::EXPIRES_NEVER } );
    my $dict = $cache->get( 'Dictionary' );
    if ( not $dict ) {
	$dict = _fetch_dictionary();
	$cache->set( 'Dictionary', $dict );
    }
    return $dict;
}

sub _fetch_dictionary {
    no warnings 'uninitialized';
    return
	[ ( map { local $_ = $_;
		  s/\t/        /g;
		  s/^\s+//;
		  s/\s+$//;
		  my %h;
		  @h{qw(feature_type
			standard_abbreviation
			short_abbreviation
			translation)} = split /\s{2,}/;
		  delete @h{ grep $h{$_} !~ /\w/, keys %h };
		  \ %h }
	    split /^(?=\S)/m,
	    ( get( 'http://www2.census.gov/geo/tiger/tiger2k/a2kapd.txt' )
	      =~ /(^Acad.+)/ms )[0] ) ];
}

1;

__END__

=head1 NAME

Geo::TigerLine::Abbreviations - Tiger/LINE feature abbreviations

=head1 SYNOPSIS

  use Geo::TigerLine::Abbreviations;
  print $Geo::TigerLine::Abbreviations::Dict{'Av'}[0]{'feature_type'}, "\n";

=head1 DESCRIPTION

Geo::TigerLine::Abbreviations provides a single hash %Dict whose keys are
values from the US Census bureau's set of standard abbreviations. All the
values are the possible results of the lookup.

Each value may have any of the following keys: feature_type,
standard_abbreviation, short_abbreviation, and translation.

=head1 SEE ALSO

L<http://www.census.gov/geo/tiger/>

=cut
