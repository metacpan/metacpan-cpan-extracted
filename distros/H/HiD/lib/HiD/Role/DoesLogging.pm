#ABSTRACT: Logging role

package HiD::Role::DoesLogging;
our $AUTHORITY = 'cpan:GENEHACK';
$HiD::Role::DoesLogging::VERSION = '1.992';
use Moose::Role;

use 5.014;  # strict, unicode_strings

use Log::Log4perl;

requires 'get_config';


has logger_config => (
  is      => 'ro' ,
  isa     => 'HashRef',
  lazy    => 1 ,
  default => sub {
    my $self = shift;
    my $config = $self->get_config('logger_config');

    return $config
      if ( $config && %$config );

    return {
      'log4perl.logger'                                   => 'WARN, Screen' ,
      'log4perl.appender.Screen'         => 'Log::Log4perl::Appender::Screen',
      'log4perl.appender.Screen.layout'                   => 'PatternLayout' ,
      'log4perl.appender.Screen.layout.ConversionPattern' => '[%d] %5p %m%n' ,
    };
  },
);


has logger => (
  is      => 'ro' ,
  isa     => 'Log::Log4perl::Logger',
  lazy    => 1 ,
  builder => '_build_logger' ,
  handles  => {
    DEBUG => 'debug' ,
    WARN  => 'warn'  ,
    INFO  => 'info'  ,
    ERROR => 'error' ,
    FATAL => 'fatal' ,
    LOGWARN => 'logwarn' ,
  },
);

sub _build_logger {
  my $self = shift;

  Log::Log4perl->init( $self->logger_config );
  Log::Log4perl->get_logger();
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::Role::DoesLogging - Logging role

=head1 ATTRIBUTES

=head2 logger_config

Configuration for logging. Defaults to:

  log4perl.logger                                   = DEBUG, Screen
  log4perl.appender.Screen                          = Log::Log4perl::Appender::Screen
  log4perl.appender.Screen.layout                   = PatternLayout
  log4perl.appender.Screen.layout.ConversionPattern = [%d] %5p %m%n

=head2 logger

Log4perl object for logging. Handles:

=over

=item * DEBUG

=item * WARN

=item * INFO

=item * ERROR

=item * FATAL

=back

=head1 VERSION

version 1.992

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
