package Dist::Dzpl::Parser;

use strict;
use warnings;

use Dist::Zilla;
use Dist::Zilla::Chrome::Term;
use Dist::Zilla::Util;
use Class::MOP;
use Moose::Autobox;

sub parse {
    my $self = shift;
    
    my ( %zilla, @prerequisite );
    while( @_ ) {
        local $_ = shift;
        if      ( m/\A(?:authors?|by)\z/ )  { $self->_parse_author( \%zilla, shift ) }
        elsif   ( m/\Acopyright\z/)         { $self->_parse_copyright( \%zilla => shift ) }
        elsif   ( m/\Alicense\z/)           { $self->_parse_license( \%zilla => shift ) }
        elsif   ( m/\Arequire\z/)           { $self->_parse_prerequisite( \@prerequisite => require => shift ) }
        elsif   ( m/\Arecommend\z/)         { $self->_parse_prerequisite( \@prerequisite => recommend => shift ) }
        elsif   ( m/\Aprefer\z/)            { $self->_parse_prerequisite( \@prerequisite => prefer => shift ) }
        else                                { $zilla{$_} = shift }
    }

    $zilla{ chrome } ||= Dist::Zilla::Chrome::Term->new;
    $zilla{ root } ||= '.';

    my $zilla = Dist::Zilla->new( %zilla );
    for my $prerequisite (@prerequisite) {
        my ( $phase, $type, $manifest ) = @$prerequisite{qw/ phase type manifest /};
        $phase = lc $phase;
        $type = "${type}s";
        $zilla->register_prereqs( { phase => $phase, type => $type }, @$manifest );
    }

    return $zilla;
}

sub _parse_prerequisite {
    my $self = shift;
    my $stash = shift;
    my $importance = shift;
    my $input = shift;

    die "Missing input" unless defined $input && length $input;

    my @stash;
    my $manifest = [];
    push @stash, { phase => 'runtime', type => $importance, manifest => $manifest };
    for my $line ( split m/\n/, $input ) {
        s/^\s*//, s/\s*$// for $line;
        next if $line =~ m/^#/ || $line !~ m/\S/;
        if (
            $line =~ m/\A\@([\w\-]+):\z/ || # @Test:
            $line =~ m/\A\[([\w\-]+)\]\z/   # [Test]
        ) {
            push @stash, { phase => lc $1, type => $importance, manifest => ( $manifest = [] ) };
        }
        else {
            my ( $package, $version ) = split m/\s+/, $line, 2;
            $package = $line unless defined $package;
            $version ||= 0;
            push @$manifest, ( $package => $version );
        }
    }

    push @$stash, grep { @{ $_->{manifest} } > 0 } @stash;
}

sub _parse_author {
    my $self = shift;
    my $zilla = shift;
    my $input = shift;

    my @author;
    if ( ref $input eq 'ARRAY' ) {
        @author = @$input;
    }
    elsif ( $input =~ m/\n/ ) {
        for my $line ( split m/\n/, $input ) {
            local $_ = $line;
            next unless m/\S/;
            $line =~ s/^\s*//, s/\s*$//;
            push @author, $line;
        }
    }
    else {
        @author = ($input);
    }

    $zilla->{authors} = \@author;
}

sub _parse_copyright {
    my $self = shift;
    my $zilla = shift;
    my $input = shift;

    if ( $input =~ m/\A\s*(\d{4})\s+(.+?)\s*\z/ ) {
        $zilla->{copyright_year} = $1;
        $zilla->{copyright_holder} = $2;
    }
    else {
        $zilla->{copyright_holder} = $input;
    }
}

sub _parse_license {
    my $self = shift;
    my $zilla = shift;
    my $input = shift;

    my $license = $input;
    if ( $license =~ m/\APerl[\-_]?5/ ) {
        $license = 'Perl_5';
    }

    $zilla->{license} = $license;

}

1;

