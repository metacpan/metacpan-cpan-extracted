use ExtUtils::MakeMaker;
our $MORE_MAKERULES = '';

# Append any additional Makefile rules added by the following.
sub MY::postamble {
  my ($self, @rules) = @_;
  return $self->MY::SUPER::postamble(@rules) . $MORE_MAKERULES; }

# Rules to build the SENNA library, and the new SENNA_API:
$MORE_MAKERULES .= <<'EOL';

pure_all :: SENNA_API$(OBJ_EXT)
SENNA_API$(OBJ_EXT):
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) lib/Lingua/EN/SENNA/third-party/senna/*.c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) SENNA_API/SENNA_API.c
EOL

WriteMakefile (
    NAME => 'Lingua::EN::SENNA',
    VERSION_FROM => 'lib/Lingua/EN/SENNA.pm',
    INC => "-ISENNA_API -Ilib/Lingua/EN/SENNA/third-party/senna",
    # LIBS => "-LSENNA_API -Lsenna",
    CCFLAGS=>"-ffast-math -Wall",
    OPTIMIZE =>'-O3',
    clean => {FILES=>'*$(OBJ_EXT)'},
    OBJECT => 'SENNA_CHK$(OBJ_EXT) SENNA_Hash$(OBJ_EXT) SENNA_main$(OBJ_EXT) SENNA_NER$(OBJ_EXT) SENNA_nn$(OBJ_EXT) 
							 SENNA_POS$(OBJ_EXT) SENNA_PSG$(OBJ_EXT) SENNA_PT0$(OBJ_EXT) SENNA_Scores2Treillis$(OBJ_EXT)
							 SENNA_SRL$(OBJ_EXT) SENNA_Tokenizer$(OBJ_EXT) SENNA_Treillis$(OBJ_EXT)
							 SENNA_utils$(OBJ_EXT) SENNA_VBS$(OBJ_EXT)  SENNA_API$(OBJ_EXT) SENNA$(OBJ_EXT)',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'https://github.com/dginev/p5-Lingua-EN-Senna.git',
          web => 'https://github.com/dginev/p5-Lingua-EN-Senna',
        }}})
  : ())
);