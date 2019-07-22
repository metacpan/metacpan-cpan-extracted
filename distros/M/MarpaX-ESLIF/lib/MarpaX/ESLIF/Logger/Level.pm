use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::Logger::Level;

# ABSTRACT: ESLIF Logger levels

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY


use Carp qw/croak/;

our $VERSION = '3.0.14'; # VERSION

# This section should be replaced on-the-fly at build time
# AUTOLOAD

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::Logger::Level - ESLIF Logger levels

=head1 VERSION

version 3.0.14

=head1 SYNOPSIS

  use MarpaX::ESLIF;

  my $loggerLevelType;
  $loggerLevelType = MarpaX::ESLIF::Logger::Level->GENERICLOGGER_LOGLEVEL_TRACE;      #  0
  $loggerLevelType = MarpaX::ESLIF::Logger::Level->GENERICLOGGER_LOGLEVEL_DEBUG;      #  1
  $loggerLevelType = MarpaX::ESLIF::Logger::Level->GENERICLOGGER_LOGLEVEL_INFO;       #  2
  $loggerLevelType = MarpaX::ESLIF::Logger::Level->GENERICLOGGER_LOGLEVEL_NOTICE;     #  3
  $loggerLevelType = MarpaX::ESLIF::Logger::Level->GENERICLOGGER_LOGLEVEL_WARNING;    #  4
  $loggerLevelType = MarpaX::ESLIF::Logger::Level->GENERICLOGGER_LOGLEVEL_ERROR;      #  5
  $loggerLevelType = MarpaX::ESLIF::Logger::Level->GENERICLOGGER_LOGLEVEL_CRITICAL;   #  6
  $loggerLevelType = MarpaX::ESLIF::Logger::Level->GENERICLOGGER_LOGLEVEL_ALERT;      #  7
  $loggerLevelType = MarpaX::ESLIF::Logger::Level->GENERICLOGGER_LOGLEVEL_EMERGENCY;  #  8

=head1 DESCRIPTION

ESLIF logger levels are mapped to constants. This module is giving access to them.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
