package Log::Dump::Class;

use strict;
use warnings;
use Log::Dump;
use Sub::Install 'install_sub';

our @CARP_NOT;

sub import {
  my $class = shift;
  my $caller = caller;

  return if $caller eq 'main';

  my @methods = qw( logger log logfile logfilter logcolor logtime );
  foreach my $method (@methods) {
    install_sub({
      as   => $method,
      into => $caller,
      code => \&{$method},
    });
  }

  install_sub({
    as   => 'import',
    into => $caller,
    code => sub {
      my $user_class  = shift;
      my $user_caller = caller;

      return if $user_caller eq 'main';

      foreach my $method (@methods) {
        install_sub({
          as   => $method,
          into => $user_caller,
          code => sub { shift; $user_class->$method(@_) },
        });
      }
    },
  });
}

1;

__END__

=head1 NAME

Log::Dump::Class

=head1 SYNOPSIS

prepare your logger class:

  package YourApp::Log;
  use Log::Dump::Class;

and use it in your application classes:

  package YourApp::ClassA;
  use YourApp::Log;

  package YourApp::ClassB;
  use YourApp::Log;

now if you enable/disable your logger in some class,
all the classes will be affected by that change.

  # this enables YourApp::ClassB's logger, too
  YourApp::ClassA->logger(1);

=head1 DESCRIPTION

You usually want to use this for a larger application, as this allows you to enable/disable a logger application-wide easily (not per a class). See SYNOPSIS for usage, and L<Log::Dump> for available methods.

Note that L<Log::Dump::Class>-based class stores its status in the class, not in an object that actually uses it (even if you call its methods from the object).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
