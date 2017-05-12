package Log::Dump::Functions;

use strict;
use warnings;
use Log::Dump;
use Sub::Install 'install_sub';

our @CARP_NOT;

sub import {
  my $class = shift;
  my $caller = caller;

  my @methods = qw( logger log logfile logfilter logcolor logtime );
  foreach my $method (@methods) {
    install_sub({
      as   => $method,
      into => $caller,
      code => sub { $class->$method(@_) },
    });
  }
}

1;

__END__

=head1 NAME

Log::Dump::Functions

=head1 SYNOPSIS

  use Log::Dump::Functions;

  log( debug => 'foo' );

=head1 DESCRIPTION

You usually want to use this for a simple script. Usage is the same as L<Log::Dump>, except that you don't need to write C<< __PACKAGE__-> >> or C<< $self-> >>.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
