package File::PidSimple;

$VERSION = '0.06';

BEGIN { require 5.006; };

use warnings;
use strict;

use File::Spec;
use File::Basename qw/basename/;
use Carp qw/croak/;

=head1 NAME

File::PidSimple - Handle and create pidfiles easy


=head1 VERSION

This document describes File::PidSimple version 0.05


=head1 SYNOPSIS

    use File::PidSimple;

  # create a pid object, but do not write anything
  my $pid = File::PidSimple->new( piddir => File::Spec->tmpdir );
  
  # exit if we runnig already
  exit 0 if ( $pid->running );
  $pid->write;
  

  my $pid = File::PidSimple->new( piddir => File::Spec->tmpdir )->write_unless_running;
  exit 0 unless $pid;
  
  # for a daemon this is enough
  File::PidSimple->new->write_unless_running || exit 0;
  
=head1 DESCRIPTION

This module make the handling of pidfiles simple.

=head1 INTERFACE 

=head2 pidfile_name

  filename of the pidfiles.

=cut

sub pidfile_name {
  my $self = shift;
  return $self->{file} if $self->{file};
  return $self->{file} =
    File::Spec->catfile( $self->piddir, $self->progname . '.pid' );
}

=head2 piddir

return the directory, where the pidfile is stored

see C<new> to set the piddir

=cut

sub piddir {
  my $self   = shift;
  my $piddir = $self->{piddir}
    || File::Spec->catfile( File::Spec->rootdir, qw/var run/ );
}

=head2 new

  piddir         ( default => '/var/run' )
  progname       default basename($0)

=cut

sub new {
  my $class = shift;
  my $self  = {};

  if ( scalar(@_) ) {
    $self = ref( $_[0] ) ? $_[0] : {@_};
  }

  bless $self, $class;
  
  return $self;
}

=head2 running

=cut

sub running {
  my $file = shift->pidfile_name;
  return unless -f $file; # the file did not exisit
  open my $fh, '<', $file or croak( "$! ( $file )");
  chomp( my $pid = <$fh> );
  return unless $pid;
  kill( 0, $pid ) ? $pid : undef;
}

=head2 write

writes a new pidfile. by default with the actual pid ( $$ ) or with

$pidfile->write

$pidfile->write(1234); # force to write 

=cut

sub write {
  my ( $self, $pid ) = @_;
  my $file = shift->pidfile_name;
  open my $fh, '>', $file or croak( "$! ( $file )" );
  print {$fh} $pid || $$, $/ or croak( $! );
  close $fh or croak ($!);
  $self;
}

=head2 write_unless_running

write the pidfile, but only if no old pidfile exists, or the 
process described in the old pidfile is not running anymore

=cut

sub write_unless_running {
  my $self = shift;
  return if $self->running;
  return $self->write;
}

=head2 progname

progname ( basename )

=cut

sub progname {
  my $self = shift;
  return $self->{progname} || basename($0);
}

=head2 remove

remove the pidfile

=cut

sub remove {
  unlink shift->pidfile_name;
}

=head1 DIAGNOSTICS

This module Croak on fatal errors. Thats any failed IO operation on the pidfiles. 
C<open>, C<close> and C<print>.

=head1 CONFIGURATION AND ENVIRONMENT
  
File::PidSimple requires no configuration files or environment variables.


=head1 DEPENDENCIES 

only core modules

  Carp
  File::Basename
  File::Spec


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-file-pidsimple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Boris Zentner  C<< <bzm@2bz.de> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Boris Zentner C<< <bzm@2bz.de> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
