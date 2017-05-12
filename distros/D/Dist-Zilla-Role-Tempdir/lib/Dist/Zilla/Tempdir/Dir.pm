use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Tempdir::Dir;

our $VERSION = '1.001003';

# ABSTRACT: A temporary directory with a collection of item states

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Moose qw( has );
use Carp qw( croak );
use File::chdir;
use Dist::Zilla::Tempdir::Item::State;
use Dist::Zilla::Tempdir::Item;
use Path::Iterator::Rule;
use Dist::Zilla::File::InMemory;
use Path::Tiny qw(path);

has '_tempdir' => (
  is         => ro =>,
  lazy_build => 1,
);

has '_tempdir_owner' => (
  is        => ro =>,
  predicate => '_has_tempdir_owner',
);

sub _build__tempdir {
  my ($self) = @_;

  my $template = 'DZ_R_Tempdir_';
  if ( $self->_has_tempdir_owner ) {
    my $owner = $self->_tempdir_owner;
    $owner =~ s/[^[:alpha:]\d]+/_/xmsg;
    $template .= $owner . '_';
  }
  $template .= 'XXXXXX';
  return Path::Tiny->tempdir( TEMPLATE => $template );
}

has '_input_files' => (
  isa     => 'HashRef',
  traits  => [qw( Hash )],
  is      => ro =>,
  lazy    => 1,
  default => sub { {} },
  handles => {
    '_set_input_file'  => 'set',
    '_all_input_files' => 'values',
    '_has_input_file'  => 'exists',
  },
);







has '_output_files' => (
  isa     => 'HashRef',
  traits  => [qw( Hash )],
  is      => ro =>,
  lazy    => 1,
  default => sub { {} },
  handles => {
    '_set_output_file' => 'set',
    'files'            => 'values',
  },
);










sub add_file {
  my ( $self, $file ) = @_;
  my $state = Dist::Zilla::Tempdir::Item::State->new(
    file           => $file,
    storage_prefix => $self->_tempdir,
  );
  $state->write_out;
  $self->_set_input_file( $file->name, $state );
  return;
}










sub update_input_file {
  my ( $self, $file ) = @_;

  my $update_item = Dist::Zilla::Tempdir::Item->new( name => $file->name, file => $file->file, );
  $update_item->set_original;

  if ( not $file->on_disk ) {
    $update_item->set_deleted;
  }
  elsif ( $file->on_disk_changed ) {
    $update_item->set_modified;
    my %params = ( name => $file->name, content => $file->new_content );
    if ( Dist::Zilla::File::InMemory->can('encoded_content') ) {
      $params{encoded_content} = delete $params{content};
    }
    $update_item->file( Dist::Zilla::File::InMemory->new(%params) );
  }
  $self->_set_output_file( $file->name, $update_item );
  return;
}









sub update_disk_file {
  my ( $self, $fullname ) = @_;
  my $fullpath  = path($fullname);
  my $shortname = $fullpath->relative( $self->_tempdir );

  my %params = ( name => "$shortname", content => $fullpath->slurp_raw );
  if ( Dist::Zilla::File::InMemory->can('encoded_content') ) {
    $params{encoded_content} = delete $params{content};
  }
  my $item = Dist::Zilla::Tempdir::Item->new(
    name => "$shortname",
    file => Dist::Zilla::File::InMemory->new(%params),
  );
  $item->set_new;
  $self->_set_output_file( "$shortname", $item );
  return;
}









sub update_input_files {
  my ($self) = @_;
  for my $file ( $self->_all_input_files ) {
    $self->update_input_file($file);
  }
  return;
}










sub update_disk_files {
  my ($self) = @_;
  for my $filename ( Path::Iterator::Rule->new->file->all( $self->_tempdir->stringify ) ) {
    next if $self->_has_input_file( path($filename)->relative( $self->_tempdir ) );
    $self->update_disk_file($filename);
  }
  return;
}











sub run_in {
  my ( $self, $code ) = @_;
  ## no critic ( ProhibitLocalVars )
  local $CWD = $self->_tempdir->stringify;
  return $code->($self);
}

















sub keepalive {
  my $nargs = my ( $self, $keep ) = @_;

  my $path = $self->_tempdir;

  if ( $nargs < 2 ) {
    return $path;
  }

  if ($keep) {
    $path->[Path::Tiny::TEMP]->unlink_on_destroy(0);
  }
  else {
    $path->[Path::Tiny::TEMP]->unlink_on_destroy(1);
  }
  return $path;
}











sub keepalive_fail {
  my ( $self, $message ) = @_;

  if ( not $message ) {
    $message = q[];
  }
  else {
    $message .= qq[\n];
  }
  $message .= q[Role::Tempdir's scratch directory preserved at ] . $self->keepalive(1);
  croak $message;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Tempdir::Dir - A temporary directory with a collection of item states

=head1 VERSION

version 1.001003

=head1 SYNOPSIS

  my $dir = Dist::Zilla::Tempdir::Dir->new();
  $dir->add_file( $zilla_file );
  $dir->run_in(sub {  });
  $dir->update_input_files;
  $dir->update_disk_files;

  my @file_states = $dir->files();

=head1 METHODS

=head2 C<files>

Returns a list of L<< C<Dist::Zilla::Tempdir::Item>|Dist::Zilla::Tempdir::Item >>

=head2 C<add_file>

  $dir->add_file( $dzil_file );

Adds C<$dzil_file> to the named temporary directory, written out to disk, and records
it internally as an "original" file.

=head2 C<update_input_file>

  $dir->update_input_file( $dzil_file );

Refreshes the C<$dzil_file> from its written out context, determining if that file has been changed since
addition or not, recording the relevant data for C<< ->files >>

=head2 C<update_disk_file>

  $dir->update_disk_file( $disk_path );

Assume C<$disk_path> is a path of a B<NEW> file and record it in C<< ->files >>

=head2 C<update_input_files>

  $dir->update_input_files

Refresh the state of all written out files and record them ready for C<< ->files >>

=head2 C<update_disk_files>

  $dir->update_disk_files

Scan the temporary directory for files that weren't added as an C<input> file, and record their status
and information ready for C<< ->files >>

=head2 C<run_in>

  my $rval = $dir->run_in(sub {
    return 1;
  });

Enter the temporary directory and run the passed code block, which is assumed to be creating/modifying/deleting files.

=head2 C<keepalive>

Utility method: Marks the temporary directory for preservation.

  $dir->keepalive()  # simply returns the path to the tempdir
  $dir->keepalive(1) # mark for retention
  $dir->keepalive(0) # mark for erasure

This is mostly an insane glue layer for

  $dir->_tempdir->[Path::Tiny::TEMP]->unlink_on_destroy($x)

Except the insanity of poking too many internal guts is well encapsulated.

=head2 C<keepalive_fail>

A utility method to invoke a croak (heh) that preserves the scratch directory, and tells
the croak recipient where to find it.

  $dir->keepalive_fail();
  $dir->keepalive_fail("Some Diagnostic Reason");

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
