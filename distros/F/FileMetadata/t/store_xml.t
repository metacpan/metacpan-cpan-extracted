use strict;
use FileMetadata::Store::XML;
use Test;
use File::Temp;
use XML::Simple;

BEGIN { plan tests => 20}

my $file = mktemp("temp.XXXX");

# 1. Test construction with verbose hash - Ok
my $config1 = {file => $file,
	       root_element => 'meta-info',
	       item_element => 'item',
	       store => [{name => 'id',
			  property => 'ID'},
			 {name => 'timestamp',
			  property => 'TIMESTAMP'},
			 {name => 'author',
			  property => 'FileMetadata::Miner::HTML::author',
			  default => 'Jules Verne'}]};
my $store1;
eval {$store1 = FileMetadata::Store::XML->new ($config1)};
ok (("$@" eq '') and defined $store1, 1);

my $file2 = mktemp("temp.XXXX");

# 2. Test with the default element omitted - Ok
my $config2 = {file => $file2,
	       root_element => 'meta-info',
	       item_element => 'item',
	       store => [{name => 'id',
			  property => 'ID'},
			 {name => 'timestamp',
			  property => 'TIMESTAMP'},
			 {name => 'author',
			  property => 'FileMetadata::Miner::HTML::author'}]};
my $store2;
eval {$store2 = FileMetadata::Store::XML->new ($config2)};
ok (("$@" eq '') and defined $store2, 1);

# 3. Test with the name element of third store element omitted - Fails
my $config3 = {file => $file,
	       root_element => 'meta-info',
	       item_element => 'item',
	       store => [{name => 'id',
			  property => 'ID'},
			 {name => 'timestamp',
			  property => 'TIMESTAMP'},
			 {property => 'FileMetadata::Miner::HTML::author',
			  default => 'Jules Verne'}]};
my $store3;
eval {$store3 = FileMetadata::Store::XML->new ($config3)};
ok (! ($@ eq '') and !defined $store3);

# 4. Test with property element of third store element omitted - FAIL
my $config4 = {file => $file,
	       root_element => 'meta-info',
	       item_element => 'item',
	       store => [{name => 'id',
			  property => 'ID'},
			 {name => 'timestamp',
			  property => 'TIMESTAMP'},
			 {name => 'author',
			  default => 'Jules Verne'}]};

my $store4;
eval {$store4 = FileMetadata::Store::XML->new ($config4)};
ok (!(($@ eq '') or defined $store4));

# 5. Test with property element='ID' not present - FAIL
my $config5 = {file => $file,
	       root_element => 'meta-info',
	       item_element => 'item',
	       store => [{name => 'timestamp',
			  property => 'TIMESTAMP'},
			 {name => 'author',
			  property => 'FileMetadata::Miner::HTML::author',
			  default => 'Jules Verne'}]};

my $store5;
eval {$store5 = FileMetadata::Store::XML->new ($config5)};
ok (!(($@ eq '') or defined $store5));

# 6. Test with property element='TIMESTAMP' not present - FAIL
my $config6 = {file => $file,
	       root_element => 'meta-info',
	       item_element => 'item',
	       store => [{name => 'id',
			  property => 'ID'},
			 {name => 'author',
			  property => 'FileMetadata::Miner::HTML::author',
			  default => 'Jules Verne'}]};

my $store6;
eval {$store6 = FileMetadata::Store::XML->new ($config6)};
ok (!(($@ eq '') or defined $store6));

#
# Test store functionality with config1
#

# 7. Testing with the property FileMetadata::Miner::HTML::author omitted
my $meta1 = {ID => 'one', TIMESTAMP => '12345'};
eval {$store1->store ($meta1)};
ok ("$@" eq '', 1);

# 8. Testing has() on store in which a single item was inserted
my $temp = $store1->has ('one');
ok ($temp, '12345');

# 9. Testing list
my @list = @{$store1->list()};
ok (($#list == 0) && ($list[0] eq 'one'), 1);

# 10. Checking to see if the default value made it in.
$store1->finish();
my $temp = XMLin ($file, keyattr => {});
ok (   ($temp->{'item'}->{'author'} eq 'Jules Verne')
    && ($temp->{'item'}->{'id'} eq 'one')
    && ($temp->{'item'}->{'timestamp'} eq '12345'), 1);

# Remaking the store for the next test
my $file = mktemp("temp.XXXX");
my $config1 = {file => $file,
	       root_element => 'meta-info',
	       item_element => 'item',
	       store => [{name => 'id',
			  property => 'ID'},
			 {name => 'timestamp',
			  property => 'TIMESTAMP'},
			 {name => 'author',
			  property => 'FileMetadata::Miner::HTML::author',
			  default => 'Jules Verne'}]};
my $store1 = FileMetadata::Store::XML->new ($config1);

# Now we do multiple inserts
my $meta1 = {ID => 'one', TIMESTAMP => '12345',
	     'FileMetadata::Miner::HTML::author' => 'Mark Twain'};
my $meta2 = {ID => 'two', TIMESTAMP => '12346'};

$store1->store ($meta1);
$store1->store ($meta2);

# 11. Make usre we have both items in the store
ok (defined ($store1->has ('one')) && defined ($store1->has ('two')));

# 12. Look for a key that does not exist
ok (defined ($store1->has('three')), '');

# 13. Remove 'one' and make sure 'two' is there
$store1->remove ('one');
ok (defined ($store1->has ('two')));

# 14. Clear the store
$store1->clear();
ok (defined($store1->has ('two')), '');

# 15. Get a list from the store. Should be empty
my @temp = @{$store1->list()};
ok ($#temp, -1);

# Insert two meta hashes again
$store1->store ($meta1);

# 16. Make sure store works after a remove
my @temp = @{$store1->list()};
ok ($temp[0] eq 'one');

$store1->store ($meta2);

# 17. Write this hash and make sure it works
$store1->finish ();
my @temp = @{XMLin ($file, keyattr => {})->{'item'}};
ok (   ($temp[0]->{'author'} eq 'Mark Twain')
    && ($temp[0]->{'id'} eq 'one')
    && ($temp[0]->{'timestamp'} eq '12345'));

# 18. Make sure we have two items
ok ($#temp, 1);

#
# Test with config2 to make sure we are working without the default
#

# 19. Checking to see if the default value made it in.
$store2->store ($meta1);
$store2->finish();
my $temp = XMLin ($file2, keyattr => {});
ok (   ($temp->{'item'}->{'author'} eq 'Mark Twain')
    && ($temp->{'item'}->{'id'} eq 'one')
    && ($temp->{'item'}->{'timestamp'} eq '12345'), 1);

# 20. Make sure reading back the file and inserting a new meta item works
my $store2;
eval {$store2 = FileMetadata::Store::XML->new ($config2)};
ok (("$@" eq '') and defined $store2, 1);


#
# TODO : Need more read back tests
#
