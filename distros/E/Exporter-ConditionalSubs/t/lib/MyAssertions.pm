package MyAssertions;

require Exporter::ConditionalSubs;
our @ISA = qw( Exporter::ConditionalSubs );

our @EXPORT    = ();
our @EXPORT_OK = qw( _assert_non_empty $some_scalar );

our $some_scalar = 42;

sub _assert_non_empty
{
    die "Found empty value\n" unless length(shift // '') > 0;
}

1;

