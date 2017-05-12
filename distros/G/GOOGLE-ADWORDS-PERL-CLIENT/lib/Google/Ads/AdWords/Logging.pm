# Copyright 2011, Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Ads::AdWords::Logging;

use strict;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::AdWords::Constants; our $VERSION = ${Google::Ads::AdWords::Constants::VERSION};

use File::HomeDir;
use File::Spec;
use Log::Log4perl qw(get_logger :levels);

# Module initialization.
# This the log4perl configration format.
my $logs_folder =  File::Spec->catfile(File::HomeDir->my_home, "logs");
my $awapi_log_file =  File::Spec->catfile($logs_folder, "aw_api_lib.log");
my $soap_log_file =  File::Spec->catfile($logs_folder, "soap_xml.log");
my $default_conf = <<TEXT;
  log4perl.category.Google.Ads.AdWords.AWAPI = INFO, LogAWfile
  log4perl.appender.LogAWfile = Log::Log4perl::Appender::File
  log4perl.appender.LogAWfile.filename = ${awapi_log_file}
  log4perl.appender.LogAWfile.create_at_logtime = 1
  log4perl.appender.LogAWfile.layout = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.LogAWfile.layout.ConversionPattern = [%d{DATE} - %-5p] %m%n

  log4perl.category.Google.Ads.AdWords.SOAP_XML = INFO, LogSOAPfile
  log4perl.appender.LogSOAPfile = Log::Log4perl::Appender::File
  log4perl.appender.LogSOAPfile.filename = ${soap_log_file}
  log4perl.appender.LogSOAPfile.create_at_logtime = 1
  log4perl.appender.LogSOAPfile.layout = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.LogSOAPfile.layout.ConversionPattern = [%d{DATE} - %-5p] %m%n
TEXT

# Static module-level variables.
my ($awapi_logger, $soap_logger);

# Initializes Log4Perl infrastructure
sub initialize_logging {
  # Only initialize once
  unless (Log::Log4perl->initialized()) {
    # Trying to read from the log4perl.conf file if not configuring the
    # defaults.
    my $log4perl_conf =
        File::Spec->catfile(File::HomeDir->my_home, "log4perl.conf");
    if (-r $log4perl_conf) {
      Log::Log4perl->init($log4perl_conf);
    } else {
      mkdir ${logs_folder} unless -d ${logs_folder};
      Log::Log4perl->init(\$default_conf);
    }
  }

  # Log4Perl may be initialized by another package; check that our loggers are
  # set up
  unless ($awapi_logger and $soap_logger) {
    $awapi_logger = get_logger("Google::Ads::AdWords::AWAPI");
    $soap_logger  = get_logger("Google::Ads::AdWords::SOAP_XML");
    $awapi_logger->level($OFF);
    $soap_logger->level($OFF);
  }
}

# Enables the logging of the AdWords API takes one boolean
# parameter, if true enables the logging in debug (more verbose) mode.
sub enable_awapi_logging {
  initialize_logging();
  if ($_[0]) {
    $awapi_logger->level($DEBUG);
  } else {
    $awapi_logger->level($INFO);
  }
}

# Disables all AdWords API logging.
sub disable_awapi_logging {
  $awapi_logger->level($OFF);
}

# Enables the logging of the SOAP Traffic (request and responses).
sub enable_soap_logging {
  initialize_logging();
  if ($_[0]) {
    $soap_logger->level($DEBUG);
  } else {
    $soap_logger->level($INFO);
  }
}

# Disables all SOAP Traffic logging.
sub disable_soap_logging {
  $soap_logger->level($OFF);
}

# Enables all logging which includes SOAP Traffic logging and API Errors
# logging.
sub enable_all_logging {
  initialize_logging();
  if ($_[0]) {
    $awapi_logger->level($DEBUG);
    $soap_logger->level($DEBUG);
  } else {
    $awapi_logger->level($INFO);
    $soap_logger->level($INFO);
  }
}

# Disables all logging which includes SOAP Traffic logging and API Errors
# logging.
sub disable_all_logging {
  $soap_logger->level($OFF);
  $awapi_logger->level($OFF);
}

# Retrieves the SOAP logger used to log SOAP requests and responses.
sub get_soap_logger {
  initialize_logging();
  return $soap_logger;
}

# Retrieves the AWAPI logger used to log messages and errors.
sub get_awapi_logger {
  initialize_logging();
  return $awapi_logger;
}

return 1;

=pod

=head1 NAME

Google::Ads::AdWords::Logging

=head1 DESCRIPTION

The class L<Google::Ads::AdWords::Logging> allows logging of outgoing and
incoming SOAP XML messages as API calls are executed. It initializes loggers
based on a provided log4perl.conf file or if the file is not found then based
on default parameters. It contains method to retrieve the message loggers.

=head1 METHODS

=head2 disable_all_logging

Stops all logging.

=head2 disable_awapi_logging

Disables all logging for program errors and messages.

=head2 disable_soap_logging

Disables all logging for soap traffic, request and responses.

=head2 enable_all_logging

Enables all logging.

=head3 Parameters

A boolean if true will also include the logging of low level DEBUG messages.

=head2 enable_awapi_logging

Enables all logging for program errors and messages.

=head3 Parameters

A boolean if true will also include the logging of low level DEBUG messages.

=head2 enable_soap_logging

Enables all logging for soap traffic, request and responses.

=head3 Parameters

A boolean if true will also include the logging of low level DEBUG messages.

=head2 get_awapi_logger

Retrieves the program errors/messages logger.

=head3 Returns

A log4perl logger for program errors/messages logger.

=head2 get_soap_logger

Retrieves the soap request/response logger.

=head3 Returns

A log4perl logger for logging soap traffic.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 AUTHOR

David Torres E<lt>api.davidtorres at gmail.comE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
