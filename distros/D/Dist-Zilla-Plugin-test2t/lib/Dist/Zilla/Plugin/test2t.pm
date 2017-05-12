package Dist::Zilla::Plugin::test2t;
{
  $Dist::Zilla::Plugin::test2t::VERSION = '0.001032';
}
# VERSION

use Moose;
with('Dist::Zilla::Role::FileMunger');
use namespace::autoclean;

sub munge_file {
    my ( $self, $file ) = @_;

    return unless $file->name =~ qr{^test/};

    (my $name = $file->name) =~ s/^test/t/;
    $file->name( $name );
    $self->log_debug(
        [ 'Renaming file', $file->name ] );
}

__PACKAGE__->meta->make_immutable;
1;

