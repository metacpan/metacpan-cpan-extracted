#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Feature::Compat::Class;

my $MATCH_ARGCOUNT =
   # Perl since 5.33.6 adds got-vs-expected counts to croak message
   $] >= 5.033006 ? qr/ \(got \d+; expected \d+\)/ : "";

# readers
{
   class AllTheTypesReader {
      field $sv :reader = 123;
      field @av :reader = qw( one two three );
      field %hv :reader = (one => 1, two => 2);
   }

   my $allthetypes = AllTheTypesReader->new;
   is( $allthetypes->sv, 123, ':reader on scalar field' );
   is( [ $allthetypes->av ], [qw( one two three )],  ':reader on array field' );
   is( { $allthetypes->hv }, { one => 1, two => 2 }, ':reader on hash field' );

   is( scalar $allthetypes->av, 3,   ':reader on array field in scalar context' );

   # On perl 5.26 onwards this yields the number of keys; before that it
   # stringifies to something like "2/8" but that's not terribly reliable, so
   # don't bother testing that
   is( scalar $allthetypes->hv, 2, ':reader on hash field in scalar context' ) if $] >= 5.028;

   # Reader complains if given any arguments
   my $LINE = __LINE__+1;
   ok( !defined eval { AllTheTypesReader->new->sv(55); 1 },
      'reader method complains if given any arguments' );
   like( $@, qr/^Too many arguments for subroutine 'AllTheTypesReader::sv'$MATCH_ARGCOUNT(?: at \S+ line $LINE\.)?$/,
      'exception message from too many arguments to reader' );
}

# writers
{
   class AllTheTypesWriter {
      field $sv :reader :writer;
      # only scalars support for now
   }

   my $allthetypes = AllTheTypesWriter->new;
   $allthetypes->set_sv( 456 );
   is( $allthetypes->sv, 456, ':writer set value of scalar field' );
}

# writers are not currently permitted on non-scalar fields
{
   ok( !defined eval <<'EOF',
      class WriterOnArray { field @av :writer; }
      1
EOF
      ':writer not permitted on array field' );

   ok( !defined eval <<'EOF',
      class WriterOnHash { field %hv :writer; }
      1
EOF
      ':writer not permitted on hash field' );
}

done_testing;
