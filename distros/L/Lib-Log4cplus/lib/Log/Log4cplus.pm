package Log::Log4cplus;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.001';

use Carp           ();
use Lib::Log4cplus ();

our @CARP_NOT = qw(Log::Log4cplus Lib::Log4cplus);

=head1 NAME

Log::Log4cplus - Perl logger via Log4cplus

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

  use Log::Log4cplus;

  my $logger = Log::Log4cplus->new(config_file => "/path/to/config.properties");
  $logger->log_info("main", "Lib::Log4cplus works great!");

=head1 METHODS

=head2 new

  my $logger = Log::Log4cplus->new(name => "foo", config_file => "foo.properties");

Creates a new logger which is named C<foo> and reads the configuration
from C<foo.properties>.

The different ways to configure Lib::Log4cplus backend are:

=over 4

=item *

C<config_basic> - basic configuration, nothing individual.
See L<http://log4cplus.sourceforge.net/docs/html/classlog4cplus_1_1BasicConfigurator.html> for more details.

=item *

C<config_file> - configuration based on properties read from specified file
See L<http://log4cplus.sourceforge.net/docs/html/classlog4cplus_1_1PropertyConfigurator.html> for more details.

=item *

C<config_string> - configuration based on properties parsed from given string
See L<http://log4cplus.sourceforge.net/docs/html/classlog4cplus_1_1PropertyConfigurator.html> for more details.

=back

=cut

my %config_dispatch = (
    config_basic  => 'basic_configure',
    config_file   => 'file_configure',
    config_string => 'static_configure',
);

sub new
{
    my $class = shift;
    my $self  = bless {@_}, $class;
    $self->_reconfigure;
    return $self;
}

sub _reconfigure
{
    my $self = shift;

    my @conf_ways = grep { m/^config_/ } keys %$self;
    scalar @conf_ways or return;
    scalar @conf_ways > 1
      and Carp::croak("To many ways to configure given: '" . join("', '", @conf_ways) . "' - please specify only one.");
    defined $config_dispatch{$conf_ways[0]}
      or Carp::croak(
        "Unknown way for configuration: '$conf_ways[0]' - valid ones are '" . join("', '", keys %config_dispatch) . "'");

    my $rc = Lib::Log4cplus->can($config_dispatch{$conf_ways[0]})->($self->{$conf_ways[0]});
    $rc != 0 and Carp::croak("Error $rc running $config_dispatch{$conf_ways[0]}($self->{$conf_ways[0]})");

    return;
}

=head2 emergency

  $logger->emerg($message)

Processes log C<$message> using severity C<FATAL>.

=head2 is_emergency

  say "logging fatal messages is enabled" if $logger->is_emergency

Tell whether fatal log level is enabled or not.

=head2 panic

  $logger->panic($message)

Processes log C<$message> using severity C<FATAL>.

=head2 is_panic

  say "logging fatal messages is enabled" if $logger->is_panic

Tell whether fatal log level is enabled or not.

=head2 fatal

  $logger->fatal($message)

Processes log C<$message> using severity C<FATAL>.

=head2 is_fatal

  say "logging fatal messages is enabled" if $logger->is_fatal

Tell whether fatal log level is enabled or not.

=head2 critical

  $logger->critical($message)

Processes log C<$message> using severity C<FATAL>.

=head2 is_critical

  say "logging fatal messages is enabled" if $logger->is_critical

Tell whether fatal log level is enabled or not.

=head2 error

  $logger->error($message)

Processes log C<$message> using severity C<ERROR>.

=head2 is_error

  say "logging error messages is enabled" if $logger->is_error

Tell whether error log level is enabled or not.

=head2 warning

  $logger->warning($message)

Processes log C<$message> using severity C<WARN>.

=head2 is_warning

  say "logging warning messages is enabled" if $logger->is_warning

Tell whether warning log level is enabled or not.

=head2 notice

  $logger->notice($message)

Processes log C<$message> using severity C<(INFO+WARN) / 2>.

=head2 is_notice

  say "logging notice messages is enabled" if $logger->is_notice

Tell whether notice log level is enabled or not.

=head2 basic

  $logger->basic($message)

Processes log C<$message> using severity C<INFO+1>.

=head2 is_basic

  say "logging basic messages is enabled" if $logger->is_basic

Tell whether basic log level is enabled or not.

=head2 info

  $logger->info($message)

Processes log C<$message> using severity C<INFO>.

=head2 is_info

  say "logging info messages is enabled" if $logger->is_info

Tell whether info log level is enabled or not.

=head2 debug

  $logger->debug($message)

Processes log C<$message> using severity C<DEBUG>.

=head2 is_debug

  say "logging debug messages is enabled" if $logger->is_debug

Tell whether debug log level is enabled or not.

=head2 trace

  $logger->trace($message)

Processes log C<$message> using severity C<TRACE>.

=head2 is_trace

  say "logging trace messages is enabled" if $logger->is_trace

Tell whether trace log level is enabled or not.

=cut

no strict "refs";

my @log_levels = (qw(emergency panic fatal critical error warning notice basic info debug trace));
my %log_levels = map {    ## no critic (BuiltinFunctions::ProhibitComplexMappings)
    my ($error, $val) = Lib::Log4cplus::constant(uc($_) . "_LOG_LEVEL");
    $error and die $error;
    $_ => $val
} @log_levels;
foreach my $ll (keys %log_levels)
{
    *$ll = sub {
        my $self = shift;
        my $msg  = scalar @_ > 1 ? "@_" : shift;
        return Lib::Log4cplus::logger_log($self->{name}, $log_levels{$ll}, $msg);
    };

    my $dll = "is_$ll";
    *$dll = sub {
        return Lib::Log4cplus::logger_exists($_[0]->{name})
          && Lib::Log4cplus::logger_is_enabled_for($_[0]->{name}, $log_levels{$ll});
    };
}

use strict;

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lib-log4cplus at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lib-Log4cplus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lib::Log4cplus

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lib-Log4cplus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lib-Log4cplus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lib-Log4cplus>

=item * Search CPAN

L<http://search.cpan.org/dist/Lib-Log4cplus/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
