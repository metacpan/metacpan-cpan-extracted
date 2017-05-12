use Test::More tests => 3;

BEGIN { 
    use_ok( 'File::Find::Rule::SAUCE' );
}

my $dir = 't/data';

my @expected_no  = (
    "$dir/bogus.dat",
    "$dir/bogus_long.dat"
);

my @expected_yes = (
    "$dir/test.dat",
    "$dir/test_no_comments.dat"
);

@expected_no  = sort @expected_no;
@expected_yes = sort @expected_yes;

my @files;

@files = find( sauce => { has_sauce => 0 }, in => $dir );
@files = sort @files;
is_deeply( \@files, \@expected_no, 'has_sauce => 0' );

@files = find( sauce => { has_sauce => 1 }, in => $dir );
@files = sort @files;
is_deeply( \@files, \@expected_yes, 'has_sauce => 1' );
