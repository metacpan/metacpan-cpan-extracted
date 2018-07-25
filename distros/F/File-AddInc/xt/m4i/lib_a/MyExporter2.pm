package MyExporter2;
use mro qw/c3/;
use MOP4Import::Declare -as_base, [parent => 'File::AddInc'];
mro::method_changed_in(__PACKAGE__);
our @ISA;
print STDERR join("\n", @ISA), "\n";
print STDERR __PACKAGE__->can("declare_file_inc"), "\n";
print STDERR File::AddInc->can("declare_file_inc"), "\n";
1;
