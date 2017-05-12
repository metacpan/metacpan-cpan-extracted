
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
      'NAME' => 'Graphics::VTK::Tk::vtkGlue',

    'VERSION'  => $VERSION,
    'XS_VERSION' => $VERSION,
    'DISTNAME' => "VTK",
    'LIBS'    => \@libs,
    'OBJECT'  => '$(O_FILES)',
    'LINKTYPE' => 'static',
    @macro,
    'CONFIGURE' => sub { my $configHash = {%vtkConfigMacro};
    			 $configHash->{INC} = "-I../../ -I$ptkPath -I../pTk ".$configHash->{INC};
			 return $configHash; },
    'OPTIMIZE'   => ' ', # Turn optimize off, optimization on cause very large
    			# memory consumption when compiling VTK.c
    'CCFLAGS'   => $CCFLAGS,
    'SKIP'	=> [qw( distclean dist makeaperl xs_o)],

      );

# Fix the dependancies for vTkGlue
# Current version of Tk::MakeDepend assumes all source files have .c 
#  extension, so we change it to .cpp here
system("perl -p -i.bak -e 's/vtkGlue\.c\\b/vtkGlue.cpp/g' Makefile");

sub MY::post_constants 
{
 '
INST_STATIC=libvtkGlue$(LIB_EXT)
';
};

sub MY::install {
'
install :: all
';
}

sub MY::dynamic_lib { my $self = shift; "dynamic_lib :: static_lib\n\t".$self->{'NOECHO'}."\$(NOOP)\n" }

sub MY::dynamic     { my $self = shift; "dynamic :: static\n\t".$self->{'NOECHO'}."\$(NOOP)\n" }

sub MY::static 
{
  my $self = shift;
  my $str  = $self->MM::static(@_);
  if ($win_arch eq 'open32' or $win_arch eq 'pm')
   {
    $str .= '
static :: dllInit$(LIB_EXT)
dllInit$(LIB_EXT): dllMain$(OBJ_EXT)
	$(AR) $(AR_STATIC_ARGS) $@ dllMain$(OBJ_EXT) && $(RANLIB) $@
';
   }
 return $str; 
}

# Fix the dependancies for vTkGlue
# Current version of Tk::MakeDepend assumes all source files have .c 
#  extension, so we change it to .cpp here
system('perl -p -i.bak -e "s/vtkGlue\.c\b/vtkGlue.cpp/g" Makefile');

