package inc::Doco;

use Moose;
use Pod::Abstract;

with 'Dist::Zilla::Role::FileMunger';

sub munge_files
{
  my($self) = @_;
  
  my $pod = "\n__END__\n\n";
  $self->fetch_pod($_, $pod) for grep { $_->name =~ /^ffi\/.*\.c$/ } @{ $self->zilla->files };
  $pod .= "=cut\n";  
  
  my($main) = grep { $_->name eq 'lib/FFI/Util.pm' } @{ $self->zilla->files };
  $self->log("putting POD into " . $main->name);
  $main->content($main->content . $pod);
}

sub fetch_pod
{
  my($self, $file) = @_;

  $self->log('fetching POD from ' . $file->name);
  my $pa = Pod::Abstract->load_string(
    $file->content,
  );
  
  $_->detach for $pa->select('//#cut');
  
  $_[2] .= $pa->pod;
}

1;
