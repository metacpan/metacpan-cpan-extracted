package Log::Stderr;

use 5.008000;
use strict;
use warnings;

use Carp ;

use base 'Exporter' ;

our $VERSION = '1.01';

my @LOG_CONSTANTS = qw{
			LOG_NONE   LOG_EMERG LOG_ALERT
			LOG_CRIT   LOG_ERR   LOG_WARNING
			LOG_NOTICE LOG_INFO  LOG_DEBUG
		    } ;

my @LOG_ALIASES   = qw{
			LOG_ERROR  LOG_WARN
		    } ;

my @FUNCTIONS     = qw{ logger } ;

my @TAGS          = qw{all constants aliases} ;

my @SYMBOLS       = ( @LOG_CONSTANTS, @LOG_ALIASES, @FUNCTIONS ) ;

our @EXPORT_OK    = ( @SYMBOLS, @TAGS ) ;

our %EXPORT_TAGS  = (
		     all       => \@SYMBOLS,
		     constants => \@LOG_CONSTANTS,
		     aliases   => \@LOG_ALIASES,
		    ) ;

sub LOG_NONE    { return 0 } ;
sub LOG_EMERG   { return 1 } ;
sub LOG_ALERT   { return 2 } ;
sub LOG_CRIT    { return 3 } ;
sub LOG_ERR     { return 4 } ;
sub LOG_WARNING { return 5 } ;
sub LOG_NOTICE  { return 6 } ;
sub LOG_INFO    { return 7 } ;
sub LOG_DEBUG   { return 8 } ;

# Aliases
*LOG_ERROR = \&LOG_ERR ;
*LOG_WARN  = \&LOG_WARNING ;

# Default DEBUGLEVEL = LOG_NOTICE
our $DEBUGLEVEL = LOG_NOTICE ;


sub logger {
    my ($level,$message) = @_ ;
    my $caller = (caller(1))[3] ;

    $caller = "-e" if not $caller ;

    return if $level > $DEBUGLEVEL ;

    $message .= qq{\n} if not $message =~ m{\n$} ;
    my $now   = scalar localtime ;

    my $log ;
    $log  = qq{[$now] } ;
    $log .= qq{[$caller] } if $DEBUGLEVEL >= LOG_DEBUG ;
    $log .= $message ;

    print STDERR $log ;
}


1;
__END__

=head1 NAME

Log::Stderr - Simple logging to Stderr

=head1 SYNOPSIS

To use the logger function and constants (with aliases):

  use Log::Stderr qw{:all} ;
  $Log::Stderr::DEBUGLEVEL = 2 ;
  
  logger(LOG_INFO,"Starting") ;


To just import the constants (without aliases):
  use Log::Stderr qw{:constants} ;


To just use the logger function:

  use Log::Stderr qw{logger} ;
  $Log::Stderr::DEBUGLEVEL = 4 ;
  
  logger(2,"This message will be printed") ;
  logger(5,"This one will not") ;

  # This is equivalent to set the DEBUGLEVEL to 6
  $Log::Stderr::DEBUGLEVEL = LOG_NOTICE ;


Note that nothing will prevent you from importing the aliases only,
but that would be a sub-smart idea (probably).


=head1 DESCRIPTION

This module provides a convenient way to have a timestamped log output
on STDERR. It also defines some mnemonic constants that you may want to
use to name the log levels (these were shamelessly stolen from the
syslog(3) man page)

This is a tiny module that I find convenient to use to implement logging
to STDERR for small-sized scripts. It is mainly a debugging tool. For
bigger scripts, or in case you need more elaborated logging (e.g.: to
a file, to syslog...), then use another one of the powerful modules in 
the Log:: hierarchy on CPAN.


=over 4

=item LOG_NONE

Don't log at all


=item LOG_EMERG

system is unusable


=item LOG_ALERT

action must be taken immediately


=item LOG_CRIT

critical conditions


=item LOG_ERR

error conditions


=item LOG_ERROR

alias of LOG_ERR


=item LOG_WARNING

warning conditions


=item LOG_WARN

alias for LOG_WARNING


=item LOG_NOTICE

normal, but significant, condition


=item LOG_INFO

informational message


=item LOG_DEBUG

debug-level message


=back

By default, DEBUGLEVEL is set to LOG_NOTICE. The higher the value, the
chattier the program.



=head1 SEE ALSO

This module uses Carp.


=head1 AUTHOR

Marco Marongiu, E<lt>bronto@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2015 by Marco Marongiu

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.



=cut
