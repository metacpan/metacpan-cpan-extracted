#############################################################################
## Name:        DynaLoader.pm
## Purpose:     LibZip::DynaLoader
## Author:      Graciliano M. P.
## Modified by:
## Created:     2004-06-06
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package LibZip::DynaLoader ;
use 5.006 ;

$VERSION = '1.04' ;
no warnings ;

##############
# DYNALOADER #
##############

package DynaLoader;

BEGIN { $INC{'DynaLoader.pm'} = 1 if !$INC{'DynaLoader.pm'} ;}

#########
# BEGIN #
#########

sub BEGIN {
 $sep = $^O eq 'MSWin32' ? '\\' : '/';
 $dlext = $^O eq 'MSWin32' ? 'dll' : 'so';
}

sub dl_load_flags { 0x00 }

# cut'n' paste from DynaLoader
sub bootstrap_inherit {
    my $module = $_[0];
    local *isa = *{"$module\::ISA"};
    local @isa = (@isa, 'DynaLoader');
    # Cannot goto due to delocalization.  Will report errors on a wrong line?
    bootstrap(@_);
}


sub croak { die @_ }

# does not handle .bs files
sub bootstrap {
  boot_DynaLoader('DynaLoader') if defined(&boot_DynaLoader) &&
                                  !defined(&dl_error);
                                  
  my $module = $_[0];
  
  print "DYN>> @_\n" if $LibZip::DEBUG ;

  LibZip::check_pack_dep("$module.pm") if defined &LibZip::check_pack_dep ;
  
  my @modparts = split(/::/,$module);

  my $path = join '/', 'auto', @modparts, $modparts[-1]; $path .= ".$dlext";

  my $file ;
  
  foreach my $INC_i ( @INC ) {
    next if ref $INC_i ;
    my $fl = "$INC_i/$path" ;
    ##print "** $fl [". (-e $fl) ."]\n" ;
    if (-e $fl) { $file = $fl ; last ;}
  }
  
  my $bootname = "boot_$module"; $bootname =~ s/\W/_/g;
  @dl_require_symbols = ($bootname);
  my $boot_symbol_ref;
  
  if (!-e $file || $file eq '') { return( undef ) ;}
  
  print "DYN FILE>> $file\n" if $LibZip::DEBUG ;
  
  my $libref = dl_load_file($file, $module->dl_load_flags) or
    croak("Can't load '$file' for module $module: ".dl_error());
  push(@dl_librefs,$libref);  # record loaded object
  
  if ( defined &dl_undef_symbols ) {
    my @unresolved = dl_undef_symbols();
    if (@unresolved) {
      warn("Undefined symbols present after loading $file: @unresolved\n");
    }
  }
  


  $boot_symbol_ref = dl_find_symbol($libref, $bootname) or
    croak("Can't find '$bootname' symbol in $file\n");

  push(@dl_modules, $module); # record loaded module

 boot:
  my $xs = dl_install_xsub("${module}::bootstrap", $boot_symbol_ref, $file);
  
  ##print "DYN END! ${module}::bootstrap >> $xs\n" ;

  # See comment block above
  &$xs(@args);  
}

package XSLoader;

BEGIN { $INC{'XSLoader.pm'} = 1 if !$INC{'XSLoader.pm'} ;}

sub load {
  DynaLoader::bootstrap_inherit(@_);
}

#######
# END #
#######

1;


