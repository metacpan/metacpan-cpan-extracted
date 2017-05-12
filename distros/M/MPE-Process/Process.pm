package MPE::Process;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# This allows declaration	use MPE::Process ':all';
our %EXPORT_TAGS = ( 'all' => [ qw(
   $CreateStatus getorigin
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';

bootstrap MPE::Process $VERSION;

my %parmmap = (
      entry    =>     1,
      parm     =>     2,
      loadflag =>     3,
      pri      =>     7,
      stdin    =>     8,
      stdlist  =>     9,
      activate =>    10,
      info     =>    11,
      stderr   =>    14,
      xl       =>    19,
      unsat    =>    23,
      nmstack  =>    26,
      nmheap   =>    27,
      lib      =>    99,
);

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new {
  my $class = shift;
  my $progname = shift;
  my $pin;
  my @parmnums;
  my @parmvals;
  my @holdstrings;
  my $hasloadflag=0;
  my $loadflag=0;
  my @params;

  if (defined $_[0] && ref($_[0]) eq 'HASH') {
    @params = %{$_[0]};
  } else {
    @params = @_;
  }

  while (my $nextparm = shift @params) {
    $nextparm =~ s/^-//;
    my $nextparmval = shift @params;
    my $whichparm;
    if (!defined($whichparm = $parmmap{lc $nextparm})) {
      warn "Unknown option: $nextparm\n";
      $MPE::CreateProcess::CreateStatus = 5;
      return 0;
    }
    if ($whichparm == 1 || $whichparm == 23) {
      $nextparmval =~ s/([^ ])$/$1 /;
      push @holdstrings, $nextparmval;
      push @parmnums, $whichparm;
      push @parmvals, unpack "L", pack "p", $holdstrings[$#holdstrings];
    } elsif ($whichparm == 8 || $whichparm == 9 || $whichparm == 14) {
      $nextparmval =~ s/([^\r])$/$1\r/;
      push @holdstrings, $nextparmval;
      push @parmnums, $whichparm;
      push @parmvals, unpack "L", pack "p", $holdstrings[$#holdstrings];
    } elsif ($whichparm == 11 || $whichparm == 19) {
      push @holdstrings, $nextparmval;
      push @parmnums, $whichparm;
      push @parmvals, unpack "L", pack "p", $holdstrings[$#holdstrings];
      push @parmnums, ($whichparm == 11?12:24);
      push @parmvals, length($nextparmval);
    } elsif ($whichparm == 3) {
       $hasloadflag = 1;
       $loadflag |= $nextparmval;
    } elsif ($whichparm == 2 || $whichparm == 10 
           || $whichparm == 26 || $whichparm == 27) {
      push @parmnums, $whichparm;
      push @parmvals, $nextparmval;
    } elsif ($whichparm == 7) {
      if ($nextparmval =~ m/[A-Z][A-Z]/i) {
        $nextparmval = unpack "S", uc($nextparmval);
      }
      push @parmnums, $whichparm;
      push @parmvals, $nextparmval;
    } elsif ($whichparm == 99) {
      $hasloadflag = 1;
      $nextparmval = uc($nextparmval);
      if ($nextparmval eq 'P') {
	$loadflag |= 16;
      } elsif ($nextparmval eq 'G') {
	$loadflag |= 32;
      }
    }
  }
  if ($hasloadflag) {
    push @parmnums, 3;
    push @parmvals, $loadflag;
  }
  push @parmnums, 0;
  push @parmvals, 0; # not necessary but prevents err on empty parmval
  my $itemnums = pack("L*", @parmnums);
  my $itemvals = pack("L*", @parmvals);
  $pin =  createprocess($progname, $itemnums, $itemvals);
  if (!defined($pin) || $pin == 0) {
    return undef;
  }
  return bless {pin => $pin}, $class;
}

sub activate {
  my $self = shift;
  my $allow = shift || 0;
  activate1($$self{pin}, $allow);
}

sub kill {
  my $self = shift;
  kill1($$self{pin});
}

sub DESTROY {
  my $self = shift;
  $self->kill;
}


1;
__END__

=head1 NAME

MPE::Process - Perl extension for MPE Process Handling

=head1 SYNOPSIS

  use MPE::Process;

  MPE::Process->new("CI.PUB.SYS", 
                            info => 'echo hi',
			    parm => 3, 
			    loadflag => 1,
			    activate=>2)
     or die "Createprocess failed: $MPE::Process::$CreateStatus\n";
  # Only for example purposes: there are easier ways to run CI commands!


  my $proc = MPE::Process->new("QEDIT.PUB.ROBELLE", stdin => "QPROGIN")
     or die "Createprocess failed: $MPE::Process::$CreateStatus\n";
  $proc->activate(2);
  $proc->kill;



=head1 DESCRIPTION
  
  MPE::Process->new(programfile,   options ...)

  Calls the MPE/iX CREATEPROCESS intrinsic.

  If it fails, it returns undef and stores the status returned
  by CREATEPROCESS in $MPE::Process::CreateStatus

  See the following manuals for details:
    MPE/iX Intrinsics Reference Manual 
    Process Management Programmer's Guide
  Both available at: http://docs.hp.com/mpeix/all

  Options are specified as name value pairs.  String values will
  be changed to have the correct terminating character.

  String options
      entry    =>    "BASICENTRY"
      stdin    =>    "*INFILE"
      stdlist  =>    "*OUTFILE"
      info     =>    "info string"
      stderr   =>    "*ERRFILE"
      xl       =>    "XL.PUB,ST2XL.PUB.ROBELLE"
      unsat    =>    "whatever"

  These options are converted to a numeric value
      pri      =>    "DS"
      lib      =>    "G"
  (The 'lib' parameter is combined (bitwise-or) with 'loadflag')

  These options are passed through numerically
      parm     =>    2
      loadflag =>    3
      activate =>    0
      nmstack  =>    125000
      nmheap   =>    325000

  $proc->activate(0)
  $proc->activate(1)
  $proc->activate(2)

  $proc->activate      same as $proc->activate(0)

  $proc->kill
    'kill' is called automatically when the object is destroyed, so
    you usually don't need to call it.



=head2 EXPORT

None by default.


=head1 AUTHOR

Ken Hirsch E<lt>F<kenhirsch@myself.com>E<gt>

=head1 SEE ALSO

perl(1)
MPE::Spoonfeed

=cut
