package Log::Contextual::Easy::Package;
use strict;
use warnings;

our $VERSION = '0.009001';

use Log::Contextual ();
BEGIN { our @ISA = qw(Log::Contextual); }

sub arg_package_logger {
  if ($_[1]) {
    return $_[1];
  }
  else {
    require Log::Contextual::WarnLogger;
    my $package = uc $_[2];
    $package =~ s/::/_/g;
    return Log::Contextual::WarnLogger->new({env_prefix => $package});
  }
}

sub default_import { qw(:dlog :log ) }

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Arthur Axel "fREW" Schmidt

=head1 NAME

Log::Contextual::Easy::Package - Import all logging methods with WarnLogger as default package logger

=head1 VERSION

version 0.009001

=head1 SYNOPSIS

In your module:

  package My::Module;
  use Log::Contextual::Easy::Package;

  log_debug { "your message" };
  Dlog_trace { $_ } @vars;

In your program:

  use My::Module;

  # enable warnings
  $ENV{MY_MODULE_UPTO}="TRACE";

  # or use a specific logger with set_logger / with_logger

=head1 DESCRIPTION

By default, this module enables a L<Log::Contextual::WarnLogger>
with C<env_prefix> based on the module's name that uses
Log::Contextual::Easy. The logging levels are set to C<trace> C<debug>,
C<info>, C<warn>, C<error>, and C<fatal> (in this order) and all
logging functions (L<log_...|Log::Contextual/"log_$level">,
L<< C<logS_...>|Log::Contextual/"logS_$level" >>,
L<< C<Dlog_...>|Log::Contextual/"Dlog_$level" >>, and
L<< C<Dlog...>|Log::Contextual/"DlogS_$level" >>) are exported.

For what C<::Package> implies, see L<Log::Contextual/-package_logger>.

=head1 SEE ALSO

=over 4

=item L<Log::Contextual::Easy::Default>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/haarg/Log-Contextual/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
