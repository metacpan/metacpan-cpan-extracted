package Dist::Zilla::Plugin::Upload::OrePAN2;
use Modern::Perl;
our $VERSION = '0.0001'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
# ABSTRACT: Dist::Zilla release plugin to inject into a local OrePAN2 repository
use Carp;

use Moose;
use MooseX::Types::Moose qw/Str Bool/;
use MooseX::Types::Path::Tiny qw/AbsPath/;
use OrePAN2;
use OrePAN2::CLI::Indexer;
use OrePAN2::Injector;
use Path::Tiny;

use namespace::autoclean;

with 'Dist::Zilla::Role::Releaser';

has clobber => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has directory => (
    is       => 'ro',
    isa      => AbsPath,
    coerce   => 1,
    required => 1,
);

has username => (
  is   => 'ro',
  isa  => 'Str',
  default => 'DUMMY',
);

sub release {
    my ( $self, $archive ) = @_;
    if (path($self->directory)->is_relative ) {
        $self->log_fatal('The directory path appears to be relative. It must be absolute.  Halting!');
    }

    my $dest = $self->directory->child( $archive->basename );
    my $upload_name = $dest;

    if ( $dest->is_file && !$self->clobber ) {
        $self->log_fatal("dest file $dest exists.  Halting!");
    }

    my $injector = OrePAN2::Injector->new(directory => $self->directory, author => $self->username );
    $injector->inject( $archive )
      or $self->log_fatal( "Error uploading: $!" );

    $self->log( "$archive uploaded to $dest.");

    OrePAN2::CLI::Indexer->new()->run($self->directory);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Upload::OrePAN2 - Dist::Zilla release plugin to inject into a local OrePAN2 repository

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

   [Upload::OrePAN2]
   directory = /home/geekruthie/path/to/my/orepan2     # mandatory; must be absolute!
   username = GEEKRUTH                                 # default: DUMMY

=head1 DESCRIPTION

This L<Dist::Zilla> plugin lets you inject a completed release into an L<OrePAN2> repository.

=head1 ATTRIBUTES

=over 4

=item C<clobber>

If this attribute is set to true, it will allow the releaser to overwrite the file if it already
exists. The default is false.

=item C<directory>

This mandatory attribute must be the absolute path to your OrePAN2 repository.

=item C<username>

Use this attribute to set the CPAN-like username that is used in the OrePAN2 repository. It is
optional; the default is C<DUMMY>, which, while it may or may not be descriptive, might also be
good enough for a small, private OrePAN2 repo.

=back

=head1 DIAGNOSTICS

If the file already exists and C<clobber> is not set to true, or if the file cannot properly be
injected into the repository, the release will halt at that point.

=head1 BUGS AND LIMITATIONS

I'm not at all certain what this will do if you're on Windows; I don't have a Windows machine handy
to test on, so if someone would let me know, that'd be great. I'd like to enhance this later to
install to an L<OrePAN2::Server> instance using POST requests, but it cannot do that...yet.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<OrePAN2>

=item L<OrePAN2::Server>

=back

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
