package Froody::Logger;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(get_logger);

=head1 NAME

Froody::Logger - logging wrapper

=head1 SYNOPSIS

  use Froody::Logger;
  my $logger = get_logger;

=head1 DESCRIPTION

Fotango internally use a Log4perl subclass, Logger.  We don't want to
impose this on the world when we release our external modules.  So we have
this module that uses Logger if it can, otherwise, it warns on warnings,
dies on error or fatal, and ignores everything else.

=head2 METHODS

=over

=item get_logger

=back

=cut

# try to load logger
eval { require Logger; require Test::Logger };

# if that didn't work, pretend with the compat module
*Logger::get_logger = sub { 'Froody::Logger::Compat' }
  unless Logger->can('get_logger');

use List::Util 'sum';

unless (Test::Logger->can('expect')) {
  *Test::Logger::expect =
    sub {
      my $class = shift;
      my $Tester = Test::Builder->new();
      $Tester->skip('Logger not available');
    };
  $INC{'Test/Logger.pm'} = __FILE__;
}
# our get logger is the same as whatever Logger's is
*get_logger = *Logger::get_logger;

########
# compat package.

package Froody::Logger::Compat;
require Carp;

BEGIN {

my $ignore  = sub { return };
my $warn    = sub { shift; goto \&Carp::carp };
my $carp    = sub { shift; goto \&Carp::carp };
my $die     = sub { shift; goto \&CORE::die };
my $confess = sub { shift; goto \&Carp::confess };
my $croak   = sub { shift; goto \&Carp::croak };

*debug      = $ignore;
*info       = $ignore;
*warn       = $warn;
*error      = $die;
*fatal      = $die;
*logconfess = $confess;
*logdie     = $die;
*logcarp    = $carp;
*logcroak   = $croak;

}

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>

=cut

1;

