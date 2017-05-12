
use Test::More tests => 9;
use_ok('Linux::Fuser');


eval 
{
   my $f = Linux::Fuser->new();

   open(F,">$$.tmp");
   my @procs = $f->fuser("$$.tmp");
   
   ok(@procs,"The file has users");
   my ($proc ) =   @procs;
   isa_ok($proc,'Linux::Fuser::Procinfo');
   my $pid  = $proc->pid();
   is($pid,$$,"Got the right PID");
   my $user = $proc->user();
   is($user,scalar getpwuid($>), "And I'm the right user");
   my $filedes = $proc->filedes();
   isa_ok($filedes, 'Linux::Fuser::FileDescriptor');
   like($filedes->fd(),qr/\d+/, "fd() is a number");
   close F;
};
ok(!$@, "Works for existing file");

my $f = Linux::Fuser->new();

eval
{
   my @procs = $f->fuser('ThIsHaDbEtTeRnOtExIsT');

   die "Whoah!" if ( @procs );
};

ok(!$@,"Non-existent file");

END 
{
   unlink "$$.tmp";
};

