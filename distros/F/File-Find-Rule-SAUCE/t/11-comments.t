use Test::More tests => 7;

BEGIN { 
    use_ok( 'File::Find::Rule::SAUCE' );
}

my $dir = 't/data';

my @expected_1 = ( );

my @expected_2 = (
    "$dir/test.dat"
);

my @expected_3 = (
    "$dir/test_no_comments.dat"
);

my @files;

@files = find( sauce => { comments => 'bogus' }, in => $dir );
is_deeply( \@files, \@expected_1, "comments => 'bogus'" );

@files = find( sauce => { comments => qr/bogus/ }, in => $dir );
is_deeply( \@files, \@expected_1, 'comments => qr/bogus/' );

@files = find( sauce => { comments => 'Test Comment' }, in => $dir );
is_deeply( \@files, \@expected_2, "comments => 'Test Comment'" );

@files = find( sauce => { comments => qr/Test/ }, in => $dir );
is_deeply( \@files, \@expected_2, 'comments => qr/Test/' );

@files = find( sauce => { comments => '' }, in => $dir );
is_deeply( \@files, \@expected_3, "comments => ''" );

@files = find( sauce => { comments => qr/^$/ }, in => $dir );
is_deeply( \@files, \@expected_3, 'comments => qr/^$/' );
