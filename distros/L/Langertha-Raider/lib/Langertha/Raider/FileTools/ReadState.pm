package Langertha::Raider::FileTools::ReadState;
# ABSTRACT: Internal record of the files a run has read, for read-before-write in the file tools
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Digest::SHA qw( sha256_hex );
use Path::Tiny;
use Time::HiRes ();


has _files => ( is => 'ro', isa => 'HashRef', default => sub { {} }, init_arg => undef );

my $NOT_READ = 'File has not been read yet. Read it first before writing to it.';
my $MODIFIED = 'File has been modified since read, either by the user or by a linter. '
  .'Read it again before attempting to write it.';

sub record {
  my ( $self, $path, %arg ) = @_;
  croak __PACKAGE__.'->record needs a path' unless defined $path && length $path;
  my @st = Time::HiRes::stat($path) or return;
  $self->_files->{$path} = {
    mtime   => $st[9],
    size    => $st[7],
    partial => $arg{partial} ? 1 : 0,
    ( !$arg{partial} && defined $arg{bytes} ? ( sha => sha256_hex( $arg{bytes} ) ) : () ),
  };
  return;
}


sub has_read { exists $_[0]->_files->{ $_[1] } ? 1 : 0 }


sub write_problem {
  my ( $self, $path ) = @_;
  return unless -e $path;
  my $seen = $self->_files->{$path} or return $NOT_READ;
  my @st = Time::HiRes::stat($path) or return;
  return if $st[9] == $seen->{mtime} && $st[7] == $seen->{size};
  if ( defined $seen->{sha} ) {
    my $bytes = eval { path($path)->slurp_raw };
    return if defined $bytes && sha256_hex($bytes) eq $seen->{sha};
  }
  return $MODIFIED;
}


sub forget { delete $_[0]->_files->{ $_[1] }; return }


sub clear { %{ $_[0]->_files } = (); return }


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::FileTools::ReadState - Internal record of the files a run has read, for read-before-write in the file tools

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $state = Langertha::Raider::FileTools::ReadState->new;
    $state->record( '/abs/real/path', bytes => $raw );          # a whole read
    $state->record( '/abs/real/path', partial => 1 );           # offset / limit
    my $problem = $state->write_problem('/abs/real/path');      # undef: may write
    $state->clear;                                              # a new run

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

What the file tools (L<Langertha::Raider::FileTools>) know about the files
the model has seen in this run (ADR 0023): for each real absolute path the
modification time and size it had when it was read or written, and for a
whole read the SHA-256 of its bytes. C<write_file>, C<edit_file> and
C<multi_edit> ask L</write_problem> before they change a file that exists:
a file that was never read, or that changed on disk since, is refused with
Claude Code's words. A read with C<offset> / C<limit> counts as read, as in
Claude Code; a write or an edit by the tools counts as a whole read of what
they wrote. The application empties the record at the start of every run
(L<Langertha::Raider::Application/begin_run>).

=head2 record

    $state->record( $real_path, bytes => $raw );     # whole file, as read or written
    $state->record( $real_path, partial => 1 );      # part of it

Notes that the file at C<$real_path> (absolute, symbolic links resolved) is
known as it is on disk now. C<bytes> are the raw bytes the tool read or
wrote; with them a later change of the modification time alone (C<touch>,
a save without change) is not taken for a change.

=head2 has_read

    $state->has_read($real_path);

True when the file was read (or written by the tools) in this run.

=head2 write_problem

    my $text = $state->write_problem($real_path);

Nothing when a tool may change the file at C<$real_path>: it does not exist,
or it was read in this run and is unchanged since. Otherwise Claude Code's
error text: C<File has not been read yet. Read it first before writing to
it.> or C<File has been modified since read, either by the user or by a
linter. Read it again before attempting to write it.> A file read whole
whose modification time or size changed but whose bytes did not still
counts as unchanged.

=head2 forget

Drops what is known about one path.

=head2 clear

Forgets every file: the start of a new run.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::FileTools>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut
