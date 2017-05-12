package Git::Gitalist::HasUtils;

use Moose::Role;

use Method::Signatures;

use Git::Gitalist::Util;

method BUILD {}

after BUILD => method(...) {
  # Force value build
  $self->meta->get_attribute('_util')->get_read_method_ref->($self);
};

has _util => (
  isa => 'Git::Gitalist::Util',
  lazy => 1,
  is => 'bare',
  builder => '_build_util',
  handles => [qw(
    run_cmd
    run_cmd_fh
    run_cmd_list
    get_gpp_object
    gpp
  )],
  traits => ['DoNotSerialize']
);

method _build_util { confess(shift() . " cannot build _util") }

1;

__END__

=head1 NAME

Git::Gitalist::HasUtils - Role for classes with an instance of Git::Gitalist::Util

=head1 AUTHORS

See L<Git::Gitalist> for authors.

=head1 LICENSE

See L<Git::Gitalist> for the license.

=cut
