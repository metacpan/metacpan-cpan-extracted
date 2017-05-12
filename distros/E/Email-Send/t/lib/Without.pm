use strict;

package Without;

use File::Path ();
use File::Spec ();
use File::Temp ();
use Symbol ();

my $tempdir;
BEGIN { $tempdir = File::Temp::tempdir(DIR => 't', CLEANUP => 1); }
use lib $tempdir;

sub import {
  my ($self, @modules) = @_;

  foreach my $module (@modules) {
    my @parts = split /::/, $module;
    my $pm_file = pop(@parts) . '.pm';
    my $pm_path = File::Spec->catdir(@parts); 
    my $path = @parts ? File::Spec->catdir($tempdir, $pm_path) : $tempdir;

    File::Path::mkpath($path, 0, 0755) unless -d $path;
    
    my $file = File::Spec->catfile($path, $pm_file);

    return if -e $file;
    
    my $new_pm_fh = Symbol::gensym;
    open $new_pm_fh, ">$file" or die "couldn't open $file for output: $!";
    print $new_pm_fh "die;\n"   or die "couldn't write to $file: $!";
    close $new_pm_fh          or die "error closing $file: $!";

    my $pm_relname =
      File::Spec->abs2rel( File::Spec->catfile($pm_path, $pm_file) );
    delete $INC{$pm_relname};
  }
}

1;
