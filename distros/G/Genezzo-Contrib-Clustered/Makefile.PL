#use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Genezzo::Contrib::Clustered',
    VERSION_FROM      => 'lib/Genezzo/Contrib/Clustered.pm', # finds $VERSION
    PREREQ_PM         => { FreezeThaw => '0.0', Genezzo::GenDBI => '0.71' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  =>    'Shared Data Cluster support for Genezzo', 
       AUTHOR         => 'Eric Rollins (rollins@acm.org)',
       'EXE_FILES' => [ 'lib/Genezzo/Contrib/Clustered/genprepundo.pl']):()),
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
     $self->echo('abstract: Shared data cluster support for Genezzo',
                 'META.yml', 1);
    my ($e3) =
     $self->echo('author: Eric Rollins (rollins@acm.org)',
                 'META.yml', 1);

    return "$meta\t$extra\n\t$e2\n\t$e3\n";
}
