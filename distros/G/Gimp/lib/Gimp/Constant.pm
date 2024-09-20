package Gimp::Constant;

use Exporter 'import';
use strict qw(vars);
our ($VERSION, @EXPORT, @PARAMS, @INXS);

BEGIN {
   $VERSION = "2.38";
# XS code in Gimp.xs... for now
#   eval {
#      require XSLoader;
#      XSLoader::load Gimp::Constant $VERSION;
#   } or do {
#      require DynaLoader;
#      @ISA = qw(DynaLoader);
#      bootstrap Gimp::Constant $VERSION;
#   }
}

my %sub2value;

for my $class (Gimp->enums_get_type_names) {
  if ($class =~ m#^(?:GimpRunMode|GimpPDBProcType)#) {
    # done in XS - special case as need in Gimp::Net
    next;
  }
  my %gname2value = Gimp->enums_list_type($class);
  map {
    my $gname = $_;
    s#^GIMP_##;
    $sub2value{$_} = $gname2value{$gname};
    push @PARAMS, $_ if $class eq 'GimpPDBArgType';
  } keys %gname2value;
}

@EXPORT = (@INXS, keys %sub2value);

map { my $sub = $_; *{$sub} = sub () { $sub2value{$sub} }; } keys %sub2value;

1;
