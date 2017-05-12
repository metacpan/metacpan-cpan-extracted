package Echo::StreamServer::Settings;

use 5.008008;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw( $ECHO_HOST $ECHO_VERSION $ECHO_TIMEOUT $ECHO_API_KEY $ECHO_API_SECRET );

our $VERSION = '0.01';

# Echo StreamServer Host and Version Settings
# ======================================================================
our $ECHO_HOST = 'api.echoenabled.com';
our $ECHO_VERSION = 'v1';
our $ECHO_TIMEOUT = 5; # seconds

# Echo StreamServer Account
# ======================================================================
our $ECHO_API_KEY = 'test.echoenabled.com';
our $ECHO_API_SECRET = '';

1;
__END__

=head1 Echo StreamServer API Settings

Echo::StreamServer::Settings - Echo StreamServer API Constants

=head1 SYNOPSIS

  use Echo::StreamServer::Settings;
  print "REST API Hostname: $ECHO_HOST\n";
  print "REST API Version: $ECHO_VERSION\n";

=head1 DESCRIPTION

Echo StreamServer API Settings

The Echo StreamServer has a REST API hostname and version configured here.
They form the base REST URL for the service.

The Echo StreamServer Account requires an API key and Secret code.
They must be set to your default account information here.

=head2 EXPORT

$ECHO_HOST $ECHO_VERSION $ECHO_TIMEOUT $ECHO_API_KEY

=head1 AUTHOR

Andrew Droffner, E<lt>adroffne@advance.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andrew Droffner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

