#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Method::Traits');
    # load from t/lib
    use_ok('DAO::Trait::Provider');
    use_ok('Accessor::Trait::Provider');
}

=pod

=cut

BEGIN {
    package Person;
    use strict;
    use warnings;

    use Method::Traits 'Accessor::Trait::Provider';

    our @ISA = ('UNIVERSAL::Object');
    our %HAS = (
        id   => sub {},
        name => sub { "" },
    );

    sub id   : Accessor(ro => 'id');
    sub name : Accessor(rw => 'name');

    package My::DAO::PeopleDB {
        use strict;
        use warnings;

        use Method::Traits 'DAO::Trait::Provider';

        sub find_name_by_id : FindOne(
            'SELECT name FROM Person WHERE id = ?',
            accepts => [ 'Int' ],
            returns => 'Str'
        );

        sub find_all_by_last_name : FindMany(
            'SELECT id, name FROM Person WHERE last_name = ?'
            accepts => [ 'Str' ],
            returns => 'ArrayRef[Person]'
        );
    }
}

done_testing;
