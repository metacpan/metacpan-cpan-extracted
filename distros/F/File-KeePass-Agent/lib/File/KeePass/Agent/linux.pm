package File::KeePass::Agent::linux;

=head1 NAME

File::KeePass::Agent::linux - platform specific utilities for Agent

=cut

use File::KeePass::Agent::unix;
use base qw(File::KeePass::Agent::unix);

1;

__END__

=head1 DESCRIPTION

This module linux based support for the File::KeePassAgent.  It should
not normally be used on its own.

See L<File::KeePass::Agent::unix>.

=head1 AUTHOR

Paul Seamons <paul at seamons dot com>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
