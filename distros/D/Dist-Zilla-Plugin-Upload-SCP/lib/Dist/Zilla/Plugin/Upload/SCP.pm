use 5.008001;
use strict;
use warnings;

package Dist::Zilla::Plugin::Upload::SCP;
# ABSTRACT: Dist::Zilla release plugin to upload via scp
our $VERSION = '0.002'; # VERSION

use autodie 2.00;
use Moose;
use MooseX::Types::Moose qw/Str Bool/;
use MooseX::Types::Path::Tiny qw/Path/;
use Net::OpenSSH 0.60;
use Path::Tiny;

use namespace::autoclean;

with 'Dist::Zilla::Role::Releaser';


has connection => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has directory => (
    is       => 'ro',
    isa      => Path,
    coerce   => 1,
    required => 1,
);


has clobber => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has atomic => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has _ssh => (
    is         => 'ro',
    isa        => 'Net::OpenSSH',
    lazy_build => 1,
);

sub _build__ssh {
    my $self = shift;
    my $ssh  = Net::OpenSSH->new( $self->connection );
    $self->log_fatal( "Couldn't establish an ssh connection: " . $ssh->error )
      if $ssh->error;
    return $ssh;
}

sub release {
    my ( $self, $archive ) = @_;
    my $ssh = $self->_ssh;

    my $dest = $self->directory->child( $archive->basename );
    my $upload_name = $self->atomic ? "$dest.part." . int(rand(2**31)) : $dest;

    if ( $ssh->test( "/bin/ls", "$dest" ) && !$self->clobber ) {
        $self->log_fatal("dest file $dest exists.  Halting!");
    }

    $ssh->scp_put( "$archive", "$upload_name" )
      or $self->log_fatal( "Error uploading: " . $ssh->error );

    if ( $self->atomic ) {
        $ssh->system( "/bin/mv", "-f", "$upload_name", "$dest" )
            or $self->log_fatal( "Error renaming uploaded file: " . $ssh->error );
    }

    $self->log( "$archive uploaded to " . join( ":", $self->connection, $dest ) );

    return;
}

__PACKAGE__->meta->make_immutable();
1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::Upload::SCP - Dist::Zilla release plugin to upload via scp

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  [Upload::SCP]
  connection = david@example.com
  directory = public_html

=head1 DESCRIPTION

This module uploads a distribution tarball to a remote host via scp on release.

It does not manage passwords.  You can put that in your connection string if you're nuts,
but you really should use an SSH key and C<ssh-agent>.

=head1 ATTRIBUTES

=head2 connection (required)

An ssh connection string, either C<host> or C<user@host> or anything else L<Net::OpenSSH>
supports as a C<host> parameter.

=head2 directory (required)

Remote directory to receive the upload.

=head2 clobber

Boolean for whether an existing destination path should be clobbered.
Defaults to false.

=head2 atomic

Boolean for whether the file should be uploaded with a temporary name
and then renamed when the upload is complete.  Defaults to false.

=for Pod::Coverage release

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::UploadToSFTP> -- very similar but allows you to set passwords via F<.netrc>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/dist-zilla-plugin-upload-scp/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/dist-zilla-plugin-upload-scp>

  git clone git://github.com/dagolden/dist-zilla-plugin-upload-scp.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
