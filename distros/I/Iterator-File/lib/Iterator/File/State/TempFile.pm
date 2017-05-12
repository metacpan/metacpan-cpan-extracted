package Iterator::File::State::TempFile;

## $Id: TempFile.pm,v 1.8 2008/06/11 05:20:07 wdr1 Exp $

use 5.006;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use IO::File;
use Digest::MD5 qw|md5_hex|;

use Iterator::File::State::Interface;

our @ISA = qw(Iterator::File::State::Interface);
our $VERSION = substr(q$Revision: 1.8 $, 10);

our %default_config = ();


sub new {
  my ($class, %config) = @_;

  confess("No file name given!")
    unless ($config{'filename'} || $config{'marker_file'});

  %config = (%default_config, %config);
  unless ($config{'marker_file'}) {
    $config{'marker_file'} = ($ENV{'TMPDIR'} || $ENV{'TEMPDIR'} || '/tmp')
      . '/iterator-file-' . md5_hex( $config{filename}) . '.tmp';
  }
  
  my $self = $class->SUPER::new( %config );
  bless($self, $class);

  $self->_verbose("Marker file is '", $self->{'marker_file'}, "'...\n");

  return $self;
}



sub initialize {
  my ($self) = @_;

  $self->_debug( __PACKAGE__ . " initializing... ");
  
  my $marker_file = $self->{'marker_file'};

  ## What's our marker (possibly from prior run)
  my $marker = 0;
  if (-f $marker_file) {
    my $fh = new IO::File ($self->{'marker_file'}, "r")
      || croak("Couldn't open '", $self->{'marker_file'}, "': $!");
    $marker = <$fh>;
    $fh->close();
  }

  my $fh = new IO::File ($self->{'marker_file'}, "w")
    || croak("Couldn't open '", $self->{'marker_file'}, "': $!");
  
  $self->{'marker_filehandle'} = $fh;
  $self->{'marker'}            = $marker;
  
  $self->_verbose( "Starting marker location is '$marker'..." );
}



sub finish {
  my ($self) = @_;
  
  my $fh = $self->{'marker_filehandle'};
  $fh->close() || warn("Couldn't close '", $self->{'marker_file'}, "': $!");
  $self->_debug("Removing '", $self->{'marker_file'}, "'...");
  unlink( $self->{'marker_file'} ) ||
    warn("Couldn't unlink '", $self->{'marker_file'}, "': $!");
}



sub marker {
  my ($self) = @_;
  
  return $self->{'marker'};
}



sub set_marker {
  my ($self, $num) = @_;
  
  $self->{'marker'} = $num;
  my $fh = $self->{'marker_filehandle'};
  $fh->seek(0, SEEK_SET)
    || confess("Unable to set position in marker file!");
  print $fh $self->{'marker'};
}



sub marker_file {
  my ($self) = @_;

  return $self->{'marker_file'};
}



# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!


=head1 NAME

Iterator::File::Source::TempFile

=head1 DESCRIPTION

An Iterator::File state class based on using a temporary file as the
persistant store.

Iterator::File::Source::TempFile is a subclass of Iterator::File::Source::Interface.

=over 4

=item B<new(%config)>

Constructor options:

=over 4

=item B<marker_file> (optional)

Name of temporary file used to store state.  The default value is a file
placed your temporary directory (determined by TMPDIR, TEMPDIR, or /tmp),
with the name 'iterator-file-' & a unique id based on the source data file.

=back

=cut

=item B<marker_file()>

Read-only.  Returns the name of the temporary marker file.

=cut

=back

=head1 SEE ALSO

Iterator::File, Iterator::File::Source::Interface

=head1 AUTHOR

William Reardon, E<lt>wdr1@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by William Reardon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut  
