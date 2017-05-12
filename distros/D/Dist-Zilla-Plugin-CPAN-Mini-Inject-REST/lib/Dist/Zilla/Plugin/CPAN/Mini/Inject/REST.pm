use strict;
use warnings;
package Dist::Zilla::Plugin::CPAN::Mini::Inject::REST;

our $VERSION = '0.004';

use Moose;
use Data::Dump;
extends 'CPAN::Mini::Inject::REST::Client::API';

with 'Dist::Zilla::Role::Releaser';

has '+port' => ( default => 80 );
has '+protocol' => ( default => 'http' );

sub release {
    my ($self, $archive) = @_;

    if($ENV{ALREADY_UPLOADED_PRETEND_THIS_HAPPENED_ALREADY})
    {
        # sometimes the CPAN::Mini::Inject::REST reports an error
        # despite successfully uploading and indexing a distribution.
        # this leaves us in an awkward state as we can't re-upload it
        # and we need this step to pass to get the rest of the release
        # tasks accomplished.
        # NOTE: this often a 504 because the timeouts on the frontend
        # nginx are too low.  Since the server does the whole indexing
        # during the processing of the REST call itself this can take a
        # while.
        $self->log("Pretending we succesfully uploaded $archive");
        return;
    }
    if($self->host =~ qr|//|)
    {
        # stop a common goof that was being reported as a 500.
        # despite not actually reaching a server.
        $self->log_fatal(sprintf "host looks like a url (%s), please change it to a hostname.", $self->host);
    }
    $self->log_debug(sprintf "Sending %s to %s://%s:%d", $archive, $self->protocol, $self->host, $self->port);

    my ($code, $result) = $self->post(
        qq(repository/$archive) => {
            file => ["$archive"]
        }
    );
    
    if ($code >= 500) {
        # FIXME - does it give us info?
        $self->log_fatal("$code: Server error");
    }
    elsif ($code >= 400) {
        my $error = ref $result ? $result->{error} : $result;

        $error = pp $error if ref $error;

        $self->log_fatal("$code: Client error: $error");
    }
    elsif ($code >= 300) {
        $self->log_fatal("Unexpected $code that wasn't followed");
    }
    else {
        $self->log("Successfully indexed $archive");
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::CPAN::Mini::Inject::REST - Uploads to a
L<CPAN::Mini::Inject> mirror using L<CPAN::Mini::Inject::REST>

=head1 DESCRIPTION

Like L<Dist::Zilla::Plugin::Inject>, this plugin is a release-stage plugin that
uploads to a L<CPAN::Mini> mirror. This one expects that the remote is a
L<CPAN::Mini::Inject::REST> server, since it uses
L<CPAN::Mini::Inject::REST::Client::API> to do it.

=head1 ATTRIBUTES

This plugin extends L<CPAN::Mini::Inject::REST::Client::API> and therefore all of its properties can be provided. A summary:

=over

=item host - Required - without the protocol.

=item protocol - Optional. Defaults to C<http>. This differs from the parent class, where it is required.

=item port - Optional. Defaults to C<80>. This differs from the parent class, where it is required.

=item username - Optional. Username for HTTP basic auth.

=item password - Optional. Password for HTTP basic auth.

=back
