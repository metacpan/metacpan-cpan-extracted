
use Cwd;
use Config;
no  lib '.';
BEGIN
 {
 
  warn("### Note: 'Building Outside of Tk itself' Messages are Expected Here ####\n");

  $IsWin32 = ($^O eq 'MSWin32' || $Config{'ccflags'} =~ /-D_?WIN32_?/);

  #$VERSION = '3.2.001';
  $win_arch = shift @ARGV if @ARGV and $ARGV[0] =~ /^(open32|pm|x|MSWin32)$/;
  require('fix_4_os2.pl'), OS2_massage() if $^O eq 'os2';

  $win_arch = ($IsWin32) ? 'MSWin32' : 'x'
    if not defined $win_arch; # Currently 'x', 'pm', 'open32', 'MSWin32'

  require "./myConfig";
  # use lib ($Tk::MMutil::dir=getcwd);
 }

use Tk::MMutil;

my $dynamic_lib;


if ($IsWin32)
 {
  *MY::makeaperl = \&makeWin32perl;
  if ($Config{cc} =~ /^gcc/i)
   {
    @libs = ('');
   }
 }
else
 {
  my $plibs = $Config{'libs'};
  my $libs  = "$xlib -lX11 -lpt";
  my @try   = qw(-lsocket -lnsl -lm);
  push(@try,'-lc') if $^O =~ /svr4/i;
  my $lib;
  # perl needs sockets and math library too
  # so only include these if they made it through perl's Configure
  foreach $lib (@try)
   {
    $libs .= " $lib" if ($plibs =~ /$lib\b/);
   }
  @libs = ("$libs");
 }

my $dir = Tk::MMutil::find_subdir();
delete $dir->{'pTk'};

# Find path to existing pTk include files
$ptkPath = Tk::MMutil::findINC('Tk/tkGlue.h');
$ptkPath =~ s/\/tkGlue.h$//g;


Tk::MMutil::TkExtMakefile(
    'VERSION'  => $VERSION,
    'XS_VERSION' => $VERSION,
    'EXE_FILES' => [],
    'NAME'     => 'Graphics::VTK::Tk',
    'DIR'      => ['pTk','vtkGlue',reverse(sort(keys %$dir))],
    'DISTNAME' => "VTK",
    'MYEXTLIB' => 'pTk/libpTk$(LIB_EXT)' . ($win_arch =~ /^(open32|pm)$/
					    ? ' pTk/dllInit$(LIB_EXT)'
					    : ''),
    'LIBS'    => \@libs,
    'OBJECT'  => '$(O_FILES)',
    'clean'      => { FILES => 'pTk/tkConfig.h ' },
    @macro,
    'CONFIGURE' => sub { my $configHash = {%vtkConfigMacro};
    			 $configHash->{INC} = "-I../ -I$ptkPath -IpTk -I$ptkPath/pTk ".$configHash->{INC};
			 return $configHash; },
    'OPTIMIZE'   => ' ', # Turn optimize off, optimization on cause very large
    			# memory consumption when compiling VTK.c
    'CCFLAGS'   => $CCFLAGS,

   );


sub MY::top_targets
{
 my ($self) = @_;
 my $str = $self->MM::top_targets;
 $str =~ s/\bmanifypods\b/html/g;
 return $str;
}

sub MY::post_initialize
{
 my ($self) = @_;
 my ($ret) = '';
 my %files = ();
 my $dir = $self->catdir('$(INST_ARCHLIBDIR)','Tk');
 my $name;
 foreach $name (grep /(%|\.q4|\.bck|\.old)$/,keys %{$self->{PM}})
  {
   delete $self->{PM}->{$name};
  }
 # delete $self->{PM}->{'Tk/Config.pm'};
 # $self->{PM}->{'Tk/Config.pm'} = $self->catfile($dir,'Config.pm');
 # $files{'typemap'} = 1;
 foreach $name ($self->lsdir("."))
  {
   next if ($name =~ /^\./);
   next unless (-f $name);
   $files{$name} = 1 if ($name =~ /\.[tm]$/);
   $files{$name} = 1 if ($name =~ /\.def$/);
  }
 foreach $name (sort(@{$self->{H}},keys %files))
  {
   $self->{PM}->{$name} = $self->catfile($dir,$name);
  }
 $ret;
}

sub needs_Test
{
 my $file = shift;
 local $_;
 unless (open(TFILE,"$file"))
  {
   warn "Cannot open $file:$!";
   return 1;
  }
 my $code = 0;
 while (<TFILE>)
  {
   last if ($code = /^\s*(use|require)\s+Test\b/);
  }
 close(TFILE);
 warn "Skipping test $file needs 'Test.pm':$_" if $code;
 return $code;
}

sub MY::test
{
 my ($self,%attrib) = @_;
 #my @tests = sort glob($self->catfile('t','*.t'));
 my @tests; # no Tests defined at this level
 eval { require Test };
 if ($@)
  {
   @tests = grep(!needs_Test($_),@tests);
  }
 $attrib{'TESTS'} = join(' ',@tests);

 # Temporarily remove sub-dirs from $self as we 'know'
 # there are no tests down there
 my $dir  = delete $self->{'DIR'};
 my $str  = $self->MM::test(%attrib);
 # Put sub-dirs back
 $self->{'DIR'} = $dir;
 return $str;
}

sub MY::postamble {
    '

html : subdirs manifypods
	@cd pod && $(MAKE) html $(PASTHRU)


Makefile     : myConfig


$(MYEXTLIB)  : config FORCE
	cd pTk && $(MAKE)

perlmain.c : config Makefile

pTk/tk.res : $(MYEXTLIB)

basic      : $(INST_DYNAMIC) pm_to_blib

MANIFEST : MANIFEST.SKIP $(FIRST_MAKEFILE)
	$(MAKE) manifest

';
}


