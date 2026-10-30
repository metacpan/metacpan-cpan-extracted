package Test::Raider::FakeProc;
# ABSTRACT: A /proc tree built in a temporary directory, so the loadguard tests create no load

use strict;
use warnings;
use Exporter 'import';
use Path::Tiny;

our @EXPORT_OK = qw( fake_proc );

=head1 SYNOPSIS

    use Test::Raider::FakeProc qw( fake_proc );

    my $dir = fake_proc(
      memory_full => 59.9,                     # full avg10 of pressure/memory
      swap        => 40,                       # percent of swap used
      cpus        => 8,
      processes   => [
        { pid => 100, ppid => 1,   comm => 'raider', argv => [ '/usr/bin/perl', '/x/bin/raider', 'go' ] },
        { pid => 101, ppid => 100, comm => 'prove',  argv => [ '/usr/bin/perl', '/usr/bin/prove', '-lr', 't' ] },
      ],
    );
    Langertha::Raider::Loadguard->new( proc_dir => "$dir", env => {} );

=head1 DESCRIPTION

Writes the files of F</proc> that L<Langertha::Raider::Loadguard> reads
(F<pressure/memory>, F<meminfo>, F<self/status>, and per process F<stat>
and F<cmdline>) into a new temporary directory and returns it as a
L<Path::Tiny>. The tests point the gate at it; nothing real is measured and
no load is created. Without C<memory_full> there is no F<pressure/memory>
(the host without PSI), without C<swap> no swap lines in F<meminfo>.

=cut

sub fake_proc {
  my ( %o ) = @_;
  my $dir = Path::Tiny->tempdir;
  if ( defined $o{memory_full} ) {
    $dir->child('pressure')->mkpath;
    $dir->child( 'pressure', 'memory' )->spew(
      "some avg10=0.00 avg60=0.00 avg300=0.00 total=0\n"
      .sprintf( "full avg10=%.2f avg60=0.00 avg300=0.00 total=0\n", $o{memory_full} ) );
  }
  my $meminfo = "MemTotal:       8000000 kB\nMemFree:        1000000 kB\n";
  if ( defined $o{swap} ) {
    my $total = 1_000_000;
    $meminfo .= "SwapTotal:      $total kB\nSwapFree:       ".( $total - int( $total * $o{swap} / 100 ) )." kB\n";
  }
  $dir->child('meminfo')->spew($meminfo);
  $dir->child('self')->mkpath;
  $dir->child( 'self', 'status' )->spew( "Name:\ttest\nCpus_allowed_list:\t0-".( ( $o{cpus} // 4 ) - 1 )."\n" );
  for my $p ( @{ $o{processes} // [] } ) {
    my $pd = $dir->child( $p->{pid} );
    $pd->mkpath;
    $pd->child('stat')->spew( "$p->{pid} ($p->{comm}) S $p->{ppid} 0 0 0\n" );
    $pd->child('cmdline')->spew( join( "\0", @{ $p->{argv} } )."\0" );
    symlink $p->{cwd}, $pd->child('cwd')->stringify if defined $p->{cwd};
  }
  return $dir;
}

1;
