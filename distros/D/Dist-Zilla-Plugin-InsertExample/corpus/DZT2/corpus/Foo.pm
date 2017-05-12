package corpus::Foo;

use Moose;
use Dist::Zilla::File::InMemory;

with 'Dist::Zilla::Role::FileGatherer';

sub gather_files
{
  my($self) = @_;
  
  $self->add_file(
    Dist::Zilla::File::InMemory->new(
      name => 'example/foo.txt',
      content => "here is a generated file\n",
    ),
  );
}

1;
