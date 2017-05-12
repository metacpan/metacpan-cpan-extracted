use Test::More tests => 5;

BEGIN { use_ok( 'Hash::RenameKey' ); }

my %hash = (
    "key-1" => {
        "key-2" => [ {
            "key-3" => "Hello World" 
        } ],
    } );
my $hr = undef;
ok( $hr = Hash::RenameKey->new,             'Initiate Hash::RenameKey');
ok( defined $hash{"key-1"}->{"key-2"},      'Hash value is there');
ok( $hr->rename_key(\%hash, '-', '_'),      'Renaming the hash keys');
ok( defined $hash{"key_1"}->{"key_2"},      'Hash has new key');

