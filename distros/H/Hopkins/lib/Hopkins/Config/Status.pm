package Hopkins::Config::Status;

use strict;
use warnings;

=head1 NAME

Hopkins::Config::Status - results of config status check

=head1 DESCRIPTION

Hopkins::Config::Status encapsulates the results of a check
on the hopkins configuration, including information on the
results of any attempted reload of the configuration.

=cut

use Class::Accessor::Fast;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(ok parsed updated failed store_modified errmsg));

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;
