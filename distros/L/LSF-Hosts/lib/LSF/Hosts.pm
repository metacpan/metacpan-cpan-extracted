package LSF::Hosts;

use strict;
use warnings;
use base qw( LSF );
use IPC::Run qw( run );
our $VERSION = '0.01';

sub import
{
  my ( $self, %p ) = @_;
  $p{RaiseError}  ||= 1;
  $p{PrintOutput} ||= 1;
  $p{PrintError}  ||= 1;
  $self->PrintOutput( $p{PrintOutput} ) if exists $p{PrintOutput};
  $self->PrintError( $p{PrintError} )   if exists $p{PrintError};
  $self->RaiseError( $p{RaiseError} )   if exists $p{RaiseError};
}

sub new
{
  my ( $class, @params ) = @_;
  my @output = $class->do_it( 'bhosts', '-l' );
  return unless @output;
  my @hosts;
  my $host;
  my @keys = qw(STATUS CPUF JL/U MAX NJOBS RUN SSUSP USUSP RSV DISPATCH_WINDOW);
  foreach ( split( /\n/, $output[0] ) ) {
    if ( /HOST/ .. /^\s*$/ ) {
      my $hostline = $_;
      if (/HOST\s+(\S+)/) {
        $host = {};
        $host->{HOST_NAME} = $1;
      }
      if ( !( /HOST/ || /STATUS/ || /^\s*$/ ) ) {
        my @values = split /\s+/, $hostline;
        for ( 0 .. @keys - 1 ) { $host->{ $keys[$_] } = $values[$_]; }
        bless $host, $class;
        push @hosts, $host;
      }
    }
  }
  return @hosts;
}

1;

__END__

=head1 NAME

LSF::Hosts - Retrieve information about LSF hosts.

=cut

=head1 VERSION

 0.1

=cut

=head1 SYNOPSIS

use LSF::Hosts;

use LSF::Hosts RaiseError => 0, PrintError => 1, PrintOutput => 0;

($hinfo) = LSF::Hosts->new( [HOST_NAME] );

@hosts = LSF::Hosts->new();

=cut

=head1 DESCRIPTION

C<LSF::Hosts> is a wrapper arround the LSF 'bhosts' command used to obtain
information about lsf hosts. The hash keys of the object are LSF bhosts header
values. See the 'bhosts' man page for more information.

=cut

=head1 INHERITS FROM

B<LSF>

=cut

=head1 CONSTRUCTOR

=over 4

=item new( [ [HOST_NAME] ] );

With a valid hostname, creates a new C<LSF::Hosts> object. Without a hostname 
returns a list of LSF::Hosts objects for all the hosts in the system. Takes no
arguments (jet).

=back

=cut


=head1 HISTORY

Based on (read ripped from) LSF::Queues by Mark Southern (mark_southern@merck.com).

=cut


=head1 SEE ALSO

L<LSF>,
L<bhosts>

=cut

=head1 AUTHOR

Aukjan van Belkum (aukjan@cpan.org)

=cut

=head1 COPYRIGHT

Copyright (c) 2005, Aukjan van Belkum. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=cut
