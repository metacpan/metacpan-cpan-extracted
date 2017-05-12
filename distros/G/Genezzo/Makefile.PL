use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Genezzo',
    'ABSTRACT'          => 'extensible database system',
    'AUTHOR'            => 'Jeffrey I Cohen (jcohen@cpan.org)',
#    'LICENSE'           => 'gpl',
    'VERSION_FROM'	=> 'lib/Genezzo.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Text::ParseWords' => '0.0',
        'Text::Soundex'    => '0.0',
        'Term::ReadLine'   => '0.0',
        'File::Copy'       => '0.0',
        'File::Compare'    => '0.0',
        'File::Path'       => '0.0',
        'File::Spec'       => '0.0',
#        'IO::File'         => '0.0',
        'IO::Handle'       => '0.0',
        'Parse::RecDescent' => '1.94'
    }, # e.g., Module::Name => 1.1

   'EXE_FILES' => [ 'lib/Genezzo/gendba.pl', 'lib/Genezzo/genexp.pl' ], # install in /usr/bin
);

package MY;
# Alter the Makefile to be more like Module::Build
# See ExtUtils::MM_Any
# From Chris Reinhardt NET::DNS

sub metafile {

    my $self    = shift;
    my $meta    = $self->SUPER::metafile_target(@_);
    my ($extra) = $self->echo('license: gpl', 'META.yml', 1);
    my ($e2)    = 
     $self->echo('abstract: an extensible database system (with SQL and DBI)',
                 'META.yml', 1);
    my ($e3) = 
     $self->echo('author: Jeffrey I Cohen (jcohen@cpan.org)',
                 'META.yml', 1);

    return "$meta\t$extra\n\t$e2\n\t$e3\n";

}

# use postamble to build havok.sql, syshook.sql, SQL.pm
sub postamble { <<'END_POSTAMBLE'; }
#pm_to_blib: GENEZZO_SPECIAL
GENEZZO_SPECIAL: GENEZZO_HAVOK GENEZZO_SYSHOOK GENEZZO_SQL
GENEZZO_HAVOK: lib/Genezzo/Havok.pm
	$(PERLRUNINST) -MGenezzo::Havok -e 'print Genezzo::Havok::MakeSQL();' > lib/Genezzo/havok.sql
GENEZZO_SYSHOOK: lib/Genezzo/Havok/SysHook.pm
	$(PERLRUNINST) -MGenezzo::Havok::SysHook -e 'print Genezzo::Havok::SysHook::MakeSQL();' > lib/Genezzo/syshook.sql
  GENEZZO_SQL: lib/Genezzo/Parse/SQLGrammar.pl
	($(PERLRUNINST) lib/Genezzo/Parse/SQLGrammar.pl ; mv SQL.pm lib/Genezzo/Parse)
END_POSTAMBLE


##   GENEZZO_SQL: lib/Genezzo/Parse/SQLGrammar.pl
##	($(PERLRUN)  lib/Genezzo/Parse/SQLGrammar.pl; $(PERLRUN) -MExtUtils::Install -e 'pm_to_blib({SQL.pm => blib/Genezzo/Parse/SQL.pm})')
