package corpus::Foo;

# for Dist::Zilla 6.x this needs to be in corpus/DZ2/corpus/Foo.pm
# this copy of the file can be removed when/if we drop support for
# Dist::Zilla 5.x

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
