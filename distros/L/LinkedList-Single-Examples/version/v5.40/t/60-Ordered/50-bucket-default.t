########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Test::More;

use LinkedList::Single::Example::Ordered;
use LinkedList::Single::Example::Ordered::Buckets;

########################################################################
# tests
#
# the bucket size comes from the argument, else $ENV{ LLS_BUCKET_SIZE },
# else 3, the fastest found for lists of up to 100,000 entries.
########################################################################

for my $class ( qw( LinkedList::Single::Example::Ordered LinkedList::Single::Example::Ordered::Buckets ) )
{
    {
        local $ENV{ LLS_BUCKET_SIZE };

        delete $ENV{ LLS_BUCKET_SIZE };

        is $class->new->{ bucket }, 3, "$class: default is 3";
    }

    {
        local $ENV{ LLS_BUCKET_SIZE } = 7;

        is $class->new->{ bucket }, 7, "$class: LLS_BUCKET_SIZE sets the default";

        is $class->new( bucket => 5 )->{ bucket }, 5, "$class: an argument beats the environment";
    }

    {
        local $ENV{ LLS_BUCKET_SIZE } = 0;

        eval { $class->new };

        like $@, qr{not positive}, "$class: a bad LLS_BUCKET_SIZE is refused";
    }
}

done_testing
__END__
