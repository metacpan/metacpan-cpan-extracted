use ExtUtils::MakeMaker;

BEGIN
{
    die "Filters needs Perl version 5.005 or better, you have $]\n"
	if $] < 5.005 ;

    warn "Perl 5.6.0 or better is strongly recommended for Win32\n"
	if $^O eq 'MSWin32' && $] < 5.006 ;
}

use strict;

my @files = qw( t/filter-util.pl
             Call/Call.pm 
             Exec/Exec.pm 
             decrypt/decrypt.pm decrypt/decr decrypt/encrypt
             tee/tee.pm
             lib/Filter/cpp.pm lib/Filter/exec.pm lib/Filter/m4.pm lib/Filter/sh.pm
             examples/filtdef
             examples/method/Count.pm
             examples/method/NewSubst.pm
             examples/method/UUdecode.pm
             examples/method/Decompress.pm
             examples/method/Joe2Jim.pm
             examples/method/Subst.pm
             examples/closure/Count.pm
             examples/closure/NewSubst.pm
             examples/closure/UUdecode.pm
             examples/closure/Decompress.pm
             examples/closure/Include.pm
             examples/closure/Joe2Jim.pm
             examples/closure/Subst.pm
             examples/filtdef
             examples/filtuu
             t/call.t
             t/cpp.t
             t/decrypt.t
             t/exec.t
             t/m4.t
             t/order.t
             t/sh.t
             t/tee.t         
           );
             
if ($] < 5.006001) { oldWarnings(@files) }
# keep the src in the new-warnings style
#else { newWarnings(@files) }

WriteMakefile
  (
   DISTNAME     => 'Filter',
   NAME         => 'Filter::Util::Call',
   VERSION_FROM => 'Call/Call.pm',
   'linkext'    => {LINKTYPE => ''},
   'dist'       => {COMPRESS=>'gzip', SUFFIX=>'gz',
		   DIST_DEFAULT => 'tardist'},
   ($] >= 5.005
    ? (ABSTRACT	=> 'Source Filters',
       AUTHOR  	=> 'Paul Marquess <pmqs@cpan.org>')
    : ()
   ),

   INSTALLDIRS  => ($] >= 5.00703 && $] < 5.011 ? 'perl' : 'site'),

   ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
    ('LICENSE'  => 'perl', SIGN => 1)  : ()),
   ((ExtUtils::MakeMaker->VERSION() gt '6.46') ?
    ('META_MERGE'  =>
     {recommends =>
      {
	'Filter::Simple'          => '0.88',
        'Test::More'        => '0.88',
      },
      resources =>
      {
	license     => 'http://dev.perl.org/licenses/',
	repository  => 'https://github.com/rurban/Filter',
      }}) : ()),
   clean =>
   { FILES =>
       "t/FilterTry.pm *~ "
       ."META.yml MYMETA.yml MYMETA.json "
       ."decrypt/MYMETA.yml decrypt/MYMETA.json decrypt/Makefile.old decrypt/pm_to_blib decrypt/*.c decrypt/*.o "
       ."tee/MYMETA.yml tee/MYMETA.json tee/Makefile.old tee/pm_to_blib tee/*.c tee/*.o "
       ."Exec/MYMETA.yml Exec/MYMETA.json Exec/Makefile.old Exec/pm_to_blib Exec/*.c Exec/*.o "
       ."Call/MYMETA.yml Call/MYMETA.json Call/Makefile.old Call/pm_to_blib Call/*.c Call/*.o"
   }
  );

sub MY::libscan
{
    my $self = shift;
    my $path = shift;

    return undef
        if $path =~ /(~|\.bak)$/ || 
           $path =~ /^\..*\.swp$/ ;

    return $path;    
}

#sub MY::postamble 
#{
#	'
#
#MyDoubleCheck:	
#	@echo Checking for $$^W in files
#	@perl -ne \'						\
#	    exit 1 if /^\s*local\s*\(\s*\$$\^W\s*\)/;		\
#         \' ' . " @files || " . '				\
#	(echo found unexpected $$^W ; exit 1)
#	@echo All is ok.
#
#' ;
#}

sub MY::depend {
  "
release : test dist
	-git tag -f \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags
";
}

sub oldWarnings
{
    local ($^I) = ".bak" ;
    local (@ARGV) = @_ ;

    while (<>)
    {
	if (/^__END__/)
	{
	    print ;
	    my $this = $ARGV ;
    	    while (<>)
	    {
		last if $ARGV ne $this ;
		print ;
	    }
	}

	s/^(\s*)(no\s+warnings)/${1}local (\$^W) = 0; #$2/ ;
	s/^(\s*)(use\s+warnings)/${1}local (\$^W) = 1; #$2/ ;
	print ;
    }
}

sub newWarnings
{
    local ($^I) = ".bak" ;
    local (@ARGV) = @_ ;

    while (<>)
    {
	if (/^__END__/)
	{
	    my $this = $ARGV ;
	    print ;
    	    while (<>)
	    {
		last if $ARGV ne $this ;
		print ;
	    }
	}

	s/^(\s*)local\s*\(\$\^W\)\s*=\s*\d+\s*;\s*#\s*((no|use)\s+warnings.*)/$1$2/ ;
	print ;
    }
}
