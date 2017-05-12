use Test::More tests => 5;

BEGIN { 
    use_ok( 'File::Find::Rule::SAUCE' );
}

my $dir = 't/data';

my @expected = (
    "$dir/test.dat"
);

my %fields_1 = (
    author => 'Test Author'
);

my %fields_2 = (
    author => qr/Test/
);

my %fields_3 = (
    author => 'Test Author',
    group  => 'Test Group',
    title  => 'Test Title'
);

my %fields_4 = (
    author => qr/Test/,
    group  => qr/Test/,
    title  => qr/Test/
);

my @files;

@files = find( sauce => { %fields_1 }, in => $dir );
is_deeply( \@files, \@expected, "match one string" );

@files = find( sauce => { %fields_2 }, in => $dir );
is_deeply( \@files, \@expected, 'match one regex' );

@files = find( sauce => { %fields_3 }, in => $dir );
is_deeply( \@files, \@expected, "match multiple strings" );

@files = find( sauce => { %fields_4 }, in => $dir );
is_deeply( \@files, \@expected, "match multiple regexes" );
