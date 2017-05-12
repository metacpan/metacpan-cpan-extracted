use strict;
use warnings;
use Test::More;
use Scalar::Util qw(looks_like_number);

my $class = 'Linux::Info::DiskUsage';
require_ok($class);
can_ok( $class, (qw(new get default_fs _is_valid _read)) );

my @diskusage = qw(
  total
  usage
  free
  usageper
  mountpoint
);

my $sys = Linux::Info::DiskUsage->new( undef, 1 );
my $stats = $sys->get;
ok( $sys->{has_inode}, 'instance has inodes information' );

SKIP: {
    skip "Nothing was returned. Might be in a chroot."
      unless ( ( defined($stats) )
        and ( ref($stats) eq 'HASH' )
        and ( keys( %{$stats} ) > 0 ) );

    for my $dev ( keys %{$stats} ) {
        note("Testing $dev");
        ok( defined $stats->{$dev}->{$_}, "checking if $_ is defined" )
          for @diskusage;
        ok(
            (
                     ( looks_like_number( $stats->{$dev}->{$_} ) )
                  or ( $stats->{$dev}->{$_} eq '-' )
            ),
            "checking if $_ looks like correct"
        ) for (qw(total usage free usageper));
        note('Inode validations');
        ok(
            (
                     ( looks_like_number( $stats->{$dev}->{$_} ) )
                  or ( $stats->{$dev}->{$_} eq '-' )
            ),
            "checking if $_ looks like correct"
        ) for (qw(files ffree favail fused fper));
    }

}

done_testing;
