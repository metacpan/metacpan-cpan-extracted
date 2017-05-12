# Extract test snippets from the POD documentation

eval "use Test::Pod::Snippets";
if ($@) {
    print
        "Looks like Test::Pod::Snippets isn't installed; skipping some tests\n";
} else { 
  my $tps = Test::Pod::Snippets->new;
  $tps->generate_snippets( qw{
                               lib/Fortran/F90Namelist.pm
                               lib/Fortran/F90Namelist/Group.pm
                             } );
}
