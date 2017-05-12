use strict;
use warnings;
use GRID::Machine;

  #my $command = shift || q{ssh -p 2048 -l invitado1 localhost 'PERLDB_OPTS="RemotePort=localhost:4445" perl -d'};
  my $command = shift || q{ssh -p 2048 -l casiano localhost 'PERLDB_OPTS="RemotePort=localhost:12344" perl -d'};

  my $machine = GRID::Machine->new(command => $command, 
    uses => [ 'Sys::Hostname' ]);

  # Install function 'rmap' on remote.machine
  my $r = $machine->sub( 
    rmap => q{
      $DB::single=1;
      my $f = shift;        
      die "Code reference expected\n" unless UNIVERSAL::isa($f, 'CODE');

      my @result;
      for (@_) {
        die "Array reference expected\n" unless UNIVERSAL::isa($_, 'ARRAY');

        print hostname().": processing row [ @$_ ]\n";
        push @result, [ map { $f->($_) } @$_ ];
      }
      return @result;
    },
  );
  die $r->errmsg unless $r->ok;

  my $cube = sub { $_[0]**3 };

  # RPC involving code references and nested structures ...
  $r = $machine->rmap($cube, [1..3], [4..6], [7..9]);
  print $r; # Dumps remote stdout and stderr

  for ($r->Results) {               # Output:
    my $format = "%5d"x(@$_)."\n";  #    1    8   27
    printf $format, @$_             #   64  125  216
  }                                 #  343  512  729


