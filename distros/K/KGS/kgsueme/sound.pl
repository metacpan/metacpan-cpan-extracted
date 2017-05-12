package sound;

use KGS::Constants;

my %sound;
$SIG{CHLD} = 'IGNORE';

for (qw(alarm warning info move pass ring connect user_unknown gamestart resign outoftime)) {
   my $path = KGS::Constants::findfile "KGS/kgsueme/sounds/$_";

   open my $snd, "<", $path
      or die "$path: $!";
   binmode $snd;

   $sound{$_} = new Audio::Data;
   $sound{$_}->Load ($snd);
}

sub play {
   my ($annoyancy, $sound) = @_;
   # annoyany 1 => important, annoyance 2 => useful, annoyancy 3 => not useful
   if (fork == 0) {
      eval {
         if (my $audioserver = new Audio::Play (1)) {
            $audioserver->play ($sound{$sound});
            $audioserver->flush;
            undef $audioserver;
         }
      };
      use POSIX ();
      POSIX::_exit(0);
   }
}

1;
