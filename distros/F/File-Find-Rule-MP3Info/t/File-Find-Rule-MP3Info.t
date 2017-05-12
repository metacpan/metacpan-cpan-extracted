use strict;
use File::Find::Rule::MP3Info;
use Test::More tests => 11;

# Single criterion, procedural interface.
my @mp3s = find( mp3info => { YEAR => '1998' }, in => 't' );
is_deeply( [sort @mp3s], ["t/test1.mp3", "t/test2.mp3"],
           "found mp3s from 1998" );

@mp3s = find( mp3info => { YEAR => '1983' }, in => 't' );
is( scalar @mp3s, 0, "...but none from 1983" );

# Multiple criteria, procedural interface.
@mp3s = find( mp3info => { TITLE => 'Test 1', YEAR => '1998' }, in => 't' );
is_deeply( [sort @mp3s], ["t/test1.mp3"],
           "found mp3 called 'Test 1' from 1998" );

# OO interface.
@mp3s = File::Find::Rule::MP3Info->file()
                                 ->mp3info( TITLE => 'Test 2' )
                                 ->in( 't' );
is_deeply( [sort @mp3s], ["t/test2.mp3"],
           "found mp3 on title with OO interface" );

# With explicit instantiation.
my $rule = File::Find::Rule->new;
$rule->file;
$rule->mp3info( TITLE => 'Test 1' );
@mp3s = $rule->in( 't' );
is_deeply( [sort @mp3s], ["t/test1.mp3"],
           "...and again without method chaining" );

# Blank tags.
@mp3s = find( mp3info => { ALBUM => '' }, in => 't' );
is( scalar @mp3s, 3, "can match on blank tags" );

# Criteria from both mp3tag and mp3info.
@mp3s = File::Find::Rule::MP3Info->file()
                                 ->mp3info( ARTIST  => 'Pudge',
					    BITRATE => 128 )
                                 ->in( 't' );
is_deeply( [sort @mp3s], ["t/test1.mp3", "t/test2.mp3"],
	   "found mp3s on mixed criteria" );

# Number::Compare
@mp3s = File::Find::Rule::MP3Info->file()
                                 ->mp3info( SS => '>=1' )
                                 ->in( 't' );
is_deeply( [sort @mp3s], ["t/test2.mp3"],
	   "Number::Compare >=" );

@mp3s = File::Find::Rule::MP3Info->file()
                                 ->mp3info( SIZE => '<15k' )
                                 ->in( 't' );
is_deeply( [sort @mp3s], ["t/test1.mp3", "t/test3.mp3", "t/test4.mp3"],
	   "Number::Compare < with magnitude" );

# Regexes
@mp3s = File::Find::Rule::MP3Info->file()
                                 ->mp3info( ARTIST => qr/Pudg/ )
                                 ->in( 't' );
is_deeply( [sort @mp3s], ["t/test1.mp3", "t/test2.mp3"],
           "regexes work" );

@mp3s = find( mp3info => { ARTIST => qr/kristin\s+hersh/i }, in => 't' );
is( scalar @mp3s, 1, "...with flags" );
