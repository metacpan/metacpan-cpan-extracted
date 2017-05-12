package MSWord::ToHTML::HTML;
{
  $MSWord::ToHTML::HTML::VERSION = '0.010';
}

use Moose;
use namespace::autoclean;
use MSWord::ToHTML::Types::Library qw/:all/;
use MooseX::Types::IO::All 'IO_All';
use MooseX::Types::Path::Class qw/Dir/;

has "file" => (
    is       => 'ro',
    isa      => IO_All,
    required => 1,
    coerce => 1,
);

has "images" => (
    is       => 'ro',
    isa      => Dir,
    coerce => 1,
);

sub content {
    my $self = shift;
    return ${$self->file};
}

__PACKAGE__->meta->make_immutable;

1;
