use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'         => 'correlations',
	      'CCFLAGS'      => '-Wall -ansi -O3',
	      'clean'        => {'FILES' => '$(NAME) *~ *.o'},
	      );


sub MY::top_targets {
'
all :: default

pure_all :: default

default:
	$(CC) $(CCFLAGS) correlations.c -o $(NAME) -lm

';
}
