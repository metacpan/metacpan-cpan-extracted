package Games::Nonogram::Base;

use strict;
use warnings;

my ($Conf, $Debug, $Stash, $Log);

sub conf  { shift; @_ ? $Conf  = shift : $Conf; }
sub debug { shift; @_ ? $Debug = shift : $Debug; }
sub stash { $Stash ||= {} }

sub clear_stash { $Stash = {} }

sub set_logfile {
  my ($self, $file) = @_;

  if ( $file ) {
    eval {
      require IO::File;
      $Log = IO::File->new( $file, 'w' ) or die "$file cannot open";
      $Log->autoflush;
    };
  }
  else {
    $Log->close if $Log;
    undef $Log;
  }
}

sub log {
  my ($self, @message) = @_;

  return unless $Debug;

  my ($package, $file, $line) = caller;

  print STDERR @message, "\n";

  if ( $Log ) {
    print $Log @message, " at line $line in $package\n";
  }
}

sub range {
  my ($self, %options) = @_;

  my $from   = $options{from} or die 'from is missing';
  my $to     = $options{to};
  my $length = $options{length};

  $to = $from + $length - 1 if !$to && $length;

  return ( $from .. $to );
}

1;

__END__

=head1 NAME

Games::Nonogram::Base

=head1 DESCRIPTION

This is a base class for various Games::Nonogram packages.

=head1 METHODS

=head2 conf

is not used at the moment.

=head2 debug

is a debug flag (true or false)

=head2 stash

is used to store temporary data while brute-forcing.

=head2 clear_stash

is used to clear the stash.

=head2 set_logfile

is used to set logfile, obviously.

=head2 log

dumps log messages while debugging.

=head2 range

is just a syntax sugar used internally to make an array.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Kenichi Ishigaki

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
