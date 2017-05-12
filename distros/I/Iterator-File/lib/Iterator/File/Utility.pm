package Iterator::File::Utility;

## $Id: Utility.pm,v 1.4 2008/06/11 05:20:07 wdr1 Exp $

use 5.006;
use strict;
use warnings;

our $VERSION = substr(q$Revision: 1.4 $, 10);

our %default_config =
  (
   'verbose' => 0,
   'debug'   => 0,
  );

sub new {
  my ($class, %config) = @_;

  %config = (%config, %default_config);
  if ($ENV{'ITERATOR_FILE_DEBUG'}) {
    $config{'debug'} = $ENV{'ITERATOR_FILE_DEBUG'};
  }

  my $self =  bless(\%config, $class);
  

  return $self;
}


sub _verbose {
  my $self = shift;

  return unless ($self->{verbose} || $self->{debug});
  print @_, "\n";
}


sub _debug {
  my $self = shift;

  return unless ($self->{debug});
  print @_, "\n";
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Iterator::File::Utility - IF utility functions

=head1 DESCRIPTION

=over 4

Private mixin utility class for Iterator::File.

Not intended to be used directly or externally. 

=item B<new(%config)>

The constructor can take a hash as an argument.  If the hash contains
keys B<debug> or B<verbose>, with either set to true, those types of
messages will be enabled.  Note that enabling B<debug> automatically
enables B<verbose>.

To avoid temporary code changes, B<debug> can be also be enabled by
setting the environmental variable B<ITERATOR_FILE_DEBUG> to a true value.

=cut

=item B<_verbose(@text)>

Prints @text if B<verbose> or B<debug> is enabled.

=cut

=item B<_debug(@text)>

Prints @text if B<debug> is enabled.

=cut

=back

=head1 SEE ALSO

Iterator::File

=head1 AUTHOR

William Reardon, E<lt>wdr1@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by William Reardon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
