package # hide from PAUSE
	Hopkins::Plugin::HMI::Log;
BEGIN {
  $Hopkins::Plugin::HMI::Log::VERSION = '0.900';
}

use strict;
use warnings;

=head1 NAME

Hopkins::Plugin::HMI::Log - log4perl wrapper to appease Catalyst

=head1 DESCRIPTION

not a whole lot going on here.  just a dumb wrapper around
the Hopkins logging in order to interace with Catalyst::Log.

=cut

use base 'Class::Accessor::Fast';

sub debug	{ return Hopkins->get_logger->debug(@_[1..$#_])	}
sub info	{ return Hopkins->get_logger->info(@_[1..$#_])	}
sub warn	{ return Hopkins->get_logger->warn(@_[1..$#_])	}
sub error	{ return Hopkins->get_logger->error(@_[1..$#_])	}
sub fatal	{ return Hopkins->get_logger->fatal(@_[1..$#_])	}

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

Copyright (c) 2009 Mike Eldridge.  All rights reserved.

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;

