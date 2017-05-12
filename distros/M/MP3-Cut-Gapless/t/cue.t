use strict;

use File::Path ();
use File::Spec::Functions;
use File::Temp ();
use FindBin ();
use Test::More tests => 24;

use MP3::Cut::Gapless;

# Test cue sheet parsing
{
    my $cut = MP3::Cut::Gapless->new(
        cue => _f('test.cue'),
    );
    
    my ($a, $b, $c, $d) = $cut->tracks;
    
    is( $a->{position}, '01', 'Track 1 position ok' );
    is( $a->{performer}, 'Test', 'Track 1 performer ok' );
    is( $a->{title}, 'One', 'Track 1 title ok' );
    is( $a->{start_ms}, 0, 'Track 1 start_ms ok' );
    is( $a->{end_ms}, 1600, 'Track 1 end_ms ok' );
    
    is( $b->{position}, '02', 'Track 2 position ok' );
    is( $b->{performer}, 'Test', 'Track 2 performer ok' );
    is( $b->{title}, 'Two', 'Track 2 title ok' );
    is( $b->{start_ms}, 1600, 'Track 2 start_ms ok' );
    is( $b->{end_ms}, 2000, 'Track 2 end_ms ok' );
    
    is( $c->{position}, '03', 'Track 3 position ok' );
    is( $c->{performer}, 'Test', 'Track 3 performer ok' );
    is( $c->{title}, 'Three', 'Track 3 title ok' );
    is( $c->{start_ms}, 2000, 'Track 3 start_ms ok' );
    is( $c->{end_ms}, 3986, 'Track 3 end_ms ok' );
    
    is( $d->{position}, '04', 'Track 4 position ok' );
    is( $d->{performer}, 'John Doe', 'Track 4 performer ok' );
    is( $d->{title}, 'Four', 'Track 4 title ok' );
    is( $d->{start_ms}, 3986, 'Track 2 start_ms ok' );
    ok( !$d->{end_ms}, 'Track 4 end_ms is empty' );
}

# Test splitting with cue sheet
{
    my @tmpfiles;
    my $cut = MP3::Cut::Gapless->new(
        cue => _f('test.cue'),
    );
    
    my $tmpdir = catdir( $FindBin::Bin, 'tmp' );
    
    if ( -d $tmpdir ) {
        File::Path::rmtree($tmpdir);
    }
    
    mkdir $tmpdir;
    
    for my $track ( $cut->tracks ) {
        my $tmpfile = catfile( $FindBin::Bin, 'tmp', $track->position . '.mp3' );
        push @tmpfiles, $track->position . '.mp3';
        $cut->write( $track, $tmpfile );
    }
    
    for my $tmpfile ( @tmpfiles ) {
        my $cut = _load( catfile( $FindBin::Bin, 'tmp', $tmpfile ) );
        is( _compare($cut, "cue-${tmpfile}"), 1, "Cue split $tmpfile ok" );
    }
    
    File::Path::rmtree($tmpdir);
}

sub _f {    
    return catfile( $FindBin::Bin, 'mp3', shift );
}

sub _load {
    my $path = shift;
    
    open my $fh, '<', $path or die "Cannot open $path";
    binmode $fh;
    my $data = do { local $/; <$fh> };
    close $fh;
    
    return \$data;
}    

sub _compare {
    my ( $test, $path ) = @_;
    
    my $ref = _load( catfile( $FindBin::Bin, 'ref', $path ) );
    
    return $$ref eq $$test;
}
