use ExtUtils::MakeMaker;

@scripts = grep {-f } glob("Scripts/*");

# incantation to enable MY::pm_to_blib later on
push(@ExtUtils::MakeMaker::Overridable, qw(pm_to_blib)) if ($^O eq 'MSWin32');

%extras = ();

$extras{'PREREQ_PM'} = {'Win32::API' => 0} if ($^O eq 'MSWin32');

WriteMakefile (
        NAME => "Encode::Registry",
        VERSION => "0.13",
        EXE_FILES => \@scripts,
        AUTHOR => "martin_hosken\@sil.org",
        ABSTRACT => "Encoding Registry module",
        %extras,
        dist => { 'TO_UNIX' => 'perl -Mtounix -e "tounix(\"$(DISTVNAME)\")"' }
    );

if ($^O eq 'MSWin32') {
# incantation to solve the problem of everyone's $Config{make} being 'nmake'
# when we want 'pmake'. And $Config{} is read only.
# actually, this is just a copy of the code from ExtUtiles::MM_Win32 tidied
# up (to expose tabs) and the dependency on Config removed
sub MY::pm_to_blib
{
    my $self = shift;
    my($autodir) = $self->catdir('$(INST_LIB)','auto');
    return <<"EOT";

pm_to_blib: \$(TO_INST_PM)
\t$self->{NOECHO}\$(PERL) \"-I\$(INST_ARCHLINE)\" \"-I\$(INST_LIB)\" \\
\t\"-I\$(PERL_ARCHLIB)\" \"-I\$(PERL_LIB)\" -MExtUtils::Install \\
\t-e \"pm_to_blib({ qw[\$(PM_TO_BLIB)] }, '$autodir')
\t$self->{NOECHO}\$(TOUCH) \$@

EOT
}

}


