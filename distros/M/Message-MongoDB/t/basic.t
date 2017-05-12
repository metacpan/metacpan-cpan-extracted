#!perl
use 5.006;
use strict; use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Message::MongoDB') || print "Bail out!\n";
    use_ok('Message::MongoDB::Test') || print "Bail out!\n";
}

ok our $mongo = Message::MongoDB->new(), 'constructor worked';

my $test_db_name = Message::MongoDB::Test::test_db_name();
my $test_collection_name = Message::MongoDB::Test::test_collection_name();

#let's find out if MongoDB is running on localhost; if not, we need
#to just pass right away
eval {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 3;
    $mongo->_collection($test_db_name, $test_collection_name)
        or die "MongoDB isn't running!\n";
};
alarm 0;
if($@) {
    ok 1, 'MongoDB is not running, so we just smile and pass';
    done_testing();
    exit 0;
}

#insert
eval {
    ok $mongo->message({
        mongo_db => $test_db_name,
        mongo_collection => $test_collection_name,
        mongo_method => 'insert',
        mongo_write => { a => 'b' }
    });
};
print STDERR "Error: $@\n" if $@;
ok not $@;

eval {
    ok my $ret = $mongo->_get_documents($test_db_name,$test_collection_name);
    ok $ret->[0]->{a} eq 'b';
};
print STDERR "Error: $@\n" if $@;
ok not $@;

#remove the previous insert
eval {
    ok $mongo->message({
        mongo_db => $test_db_name,
        mongo_collection => $test_collection_name,
        mongo_method => 'remove',
        mongo_search => { a => 'b' }
    });
};
print STDERR "Error: $@\n" if $@;
ok not $@;

eval {
    ok my $ret = $mongo->_get_documents($test_db_name,$test_collection_name);
    ok scalar @$ret == 0;
};
print STDERR "Error: $@\n" if $@;
ok not $@;

#update
#first need to do an insert
eval {
    ok $mongo->message({
        mongo_db => $test_db_name,
        mongo_collection => $test_collection_name,
        mongo_method => 'insert',
        mongo_write => { a => 'b' }
    });
};
print STDERR "Error: $@\n" if $@;
ok not $@;

eval {
    ok my $ret = $mongo->_get_documents($test_db_name,$test_collection_name);
    ok $ret->[0]->{a} eq 'b';
};
print STDERR "Error: $@\n" if $@;
ok not $@;

#now the update
eval {
    ok $mongo->message({
        mongo_db => $test_db_name,
        mongo_collection => $test_collection_name,
        mongo_method => 'update',
        mongo_search => { a => 'b' },
        mongo_write => { a => 'c' },
    });
};
print STDERR "Error: $@\n" if $@;
ok not $@;

eval {
    ok my $ret = $mongo->_get_documents($test_db_name,$test_collection_name);
    ok $ret->[0]->{a} eq 'c';
};
print STDERR "Error: $@\n" if $@;
ok not $@;

#find
#make sure we don't have a stray emit
ok not scalar @Message::MongoDB::return_messages;

eval {
    ok $mongo->message({
        mongo_db => $test_db_name,
        mongo_collection => $test_collection_name,
        mongo_method => 'find',
        mongo_search => { a => 'c' },
    });
};
print STDERR "Error: $@\n" if $@;
ok not $@;

eval {
    ok my $ret = $mongo->_get_documents($test_db_name,$test_collection_name);
    ok $ret->[0]->{a} eq 'c';
};
print STDERR "Error: $@\n" if $@;
ok not $@;

ok scalar @Message::MongoDB::return_messages == 1;
ok $Message::MongoDB::return_messages[0][0]->{a} eq 'c';

done_testing();
