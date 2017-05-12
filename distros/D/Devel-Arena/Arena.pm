package Devel::Arena;

use 5.005;
use strict;

require Exporter;
require DynaLoader;
use vars qw($VERSION @ISA @EXPORT_OK @EXPORT_FAIL $sizes);
@ISA = qw(Exporter DynaLoader);

$VERSION = '0.23';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

my $info; # collect info early, before option processing
BEGIN { $info = { exe => $^X, prog => $0, args => [@ARGV] } }

@EXPORT_OK = qw(sv_stats shared_string_table sizes HEK_size
		shared_string_table_effectiveness write_stats_at_END);
@EXPORT_FAIL = qw(write_stats_at_END);

sub _write_stats_at_END {
    my $file = $$ . '.sv_stats';
    my $stats = {sv_stats => &sv_stats,
		 shared_string_table_effectiveness =>
		 &shared_string_table_effectiveness};
    $stats->{info} = $info;
    $stats->{info}{inc} = \@INC;
    require Storable;
    Storable::lock_nstore($stats, $file);
    $stats;
}

sub export_fail {
    shift;
    grep {$_ ne 'write_stats_at_END' ? 1
	      : do {eval "END {_write_stats_at_END}; 1" or die $@; 0;}} @_;
}

sub HEK_size {
    my $string = shift;
    $sizes ||= sizes();
    # 5.8 and later have a flag byte after the hash key.
    $sizes->{'hek_key offset'} + length ($string) + ($] >= 5.008 ? 2 : 1);
}

sub shared_string_table_effectiveness {
    my ($raw_shared, $raw_unshared) = (0,0);
    my ($hv_unshared, $pv_unshared);
    my ($pvs, $heks) = (0, 0);
    $sizes ||= sizes();
    my $HE = $sizes->{HE};
    my $stats = sv_stats(1); # Don't use shared hash keys.
    my $sst = shared_string_table();
    while (my ($k, $count) = each %$sst) {
	my $hek_size = HEK_size($k);
	$raw_shared += $HE + $hek_size;
	$raw_unshared += $count * $hek_size;
    }
    my $HEK_overhead = HEK_size('');
    foreach my $type ('symtab_', '') {
	my ($keys, $keylen)
	    = @{$stats->{types}{PVHV}{$type.'shared_keys'}}{qw(keys keylen)};
	$hv_unshared += $keys * $HEK_overhead + $keylen;
	$heks += $keys;
    }
    {
	my ($total, $length)
	    = @{$stats->{PVX}{'shared hash key'}}{qw(total length)};
	$pv_unshared = $total * $HEK_overhead + $length;
	$pvs = $total;
    }
    return {
	    raw_shared => $raw_shared,
	    raw_unshared => $raw_unshared,
	    hv_unshared => $hv_unshared,
	    pv_unshared => $pv_unshared,
	    pv_hv => $hv_unshared + $pv_unshared,
	    heks => $heks,
	    pvs => $pvs,
	    raw => scalar keys %$sst,
	   };
}

bootstrap Devel::Arena $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Devel::Arena - Perl extension for inspecting the core's arena structures

=head1 SYNOPSIS

  use Devel::Arena 'sv_stats';
  # Get hash ref describing the arenas for SV heads
  $sv_stats = sv_stats;

=head1 DESCRIPTION

Inspect the arena structures that perl uses for SV allocation.

HARNESS_PERL_SWITCHES=-MDevel::Arena=write_stats_at_END make test

=head2 EXPORT

None by default.

=over 4

=item * sv_stats [DONT_SHARE]

Returns a hashref giving stats derived from inspecting the SV heads via the
arena pointers. Details of the contents of the hash subject to change.

If the optional argument I<DONT_SHARE> is true then none of the hashes in
the returned structure have shared hash keys. This is less efficient, but
is needed to calculate the effectiveness of the shared string table.

=item * shared_string_table

Returns a hashref giving the share counts for each entry in the shared string
table. The hashref doesn't use shared keys itself, so it doesn't affect the
thing that it is measuring.

=item * sizes

Returns a hashref containing sizes of various core perl types, C types, and
other size related info (specifically 'hek_key offset')

=item * HEK_size STRING

Calculates the size of the hash key needed to store I<STRING>.

=item * shared_string_table_effectiveness

Calculates the effectiveness of the shared string table. Returns a hashref of
stats. Currently this is

        {
          'pv_unshared' => 7185,
          'raw_unshared' => 77264,
          'heks' => 3748,
          'pv_hv' => 77264,
          'hv_unshared' => 70079,
          'raw_shared' => 57675,
          'pvs' => 434,
          'raw' => 1833
        };

It ignores malloc() overhead, and the possibility that some shared strings
aren't used as hash keys or shared hash key scalars.

=item * write_stats_at_END

Not really a function, but if you import C<write_stats_at_END> then
Devel::Arena will write out a Storable dump of all stats at C<END> time.
The file is written into a file into a file in the current directory named
C<$$ . '.sv_stats'>. This allows you to do things such as

    HARNESS_PERL_SWITCHES=-MDevel::Arena=write_stats_at_END make test

to analyse the resource usage in regression tests.

=back

=head1 SEE ALSO

F<sv.c> in the perl core.

=head1 AUTHOR

Nicholas Clark, E<lt>nick@ccl4.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2006 by Nicholas Clark

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
