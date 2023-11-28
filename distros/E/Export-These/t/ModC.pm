package ModC;
use Export::These export_pass=>[];
use ModB;

# this module simply passes through to ModB
sub _reexport{
  shift;shift;
  ModB->import(@_);
}
1;
