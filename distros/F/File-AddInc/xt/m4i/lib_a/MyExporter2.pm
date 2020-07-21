package MyExporter2;
use mro qw/c3/;
use MOP4Import::Declare -as_base, [parent => 'File::AddInc'];
use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};

mro::method_changed_in(__PACKAGE__);

if (DEBUG) {
  print STDERR join("\n", our @ISA), "\n";
  print STDERR __PACKAGE__->can("declare_file_inc"), "\n";
  print STDERR File::AddInc->can("declare_file_inc"), "\n";
}
1;
