use Test::More tests => 3;

BEGIN { 
    use_ok( 'File::Find::Rule::DIZ' );
}

my $dir = 't/data';
my @files;

@files = find( diz => { text => qr/test DIZ/ }, in => $dir );
is_deeply( \@files, [ "$dir/test.zip" ], 'text => qr/test DIZ/' );

@files = find( diz => { text => qr/foo bar/ }, in => $dir );
is_deeply( \@files, [ ], 'text => qr/foo bar/' );

