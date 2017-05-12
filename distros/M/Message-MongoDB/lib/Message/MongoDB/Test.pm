package Message::MongoDB::Test;
$Message::MongoDB::Test::VERSION = '1.142810';
use strict;use warnings;
use MongoDB;
use Test::More;

=head2 test_db_name
=cut
sub test_db_name {
    return "perl_test_$$";
}

=head2 test_collection_name
=cut
sub test_collection_name {
    return "perl_test_collection_$$";
}


END {
    if($main::mongo->{connection}) {
        $main::mongo->{connection}->get_database(test_db_name())->drop;
    }
};
1;
