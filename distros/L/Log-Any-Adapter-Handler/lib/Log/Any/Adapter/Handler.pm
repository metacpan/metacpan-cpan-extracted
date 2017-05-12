package Log::Any::Adapter::Handler;
# ABSTRACT: Log::Any::Adapter for Log::Handler
our $VERSION = '0.009';

use strict;
use warnings;

use Log::Any::Adapter::Util ();
use parent qw(Log::Any::Adapter::Base);
use Log::Handler;

sub init {
	my $self = shift;
	$self->{logger} ||= Log::Handler->new;
}

# logging methods
foreach my $method (Log::Any::Adapter::Util::logging_methods) {
	no strict 'refs';
	my $handler_method = $method;
	*$method = sub {
		my $self = shift;
		return $self->{logger}->$handler_method(@_);
	};
}

# detection methods
foreach my $method (Log::Any::Adapter::Util::detection_methods()) {
	my $self = shift;
	my $handler_method = $method;
	no strict 'refs';
	*$method = sub {
		my $self = shift;
		return $self->{logger}->$handler_method(@_);
	};
}

1;

__END__

=encoding utf8

=head1 NAME

Log::Any::Adapter::Handler

=head1 SYNOPSIS

  use Log::Handler;
  use Log::Any::Adapter;

  my $lh = Log::Handler->new(screen => {log_to => 'STDOUT'});
  Log::Any::Adapter->set('Handler', logger => $lh);
  my $log = Log::Any->get_logger();

  $log->warn('aaargh!');

=head1 DESCRIPTION

This is a L<Log::Any> adapter for L<Log::Handler>. Log::Handler should be
initialized before calling C<set>, otherwise your log messages will end up
nowhere. The Log::Handler object is passed via the C<logger> parameter.

Log levels are translated 1:1. Log::Handler's special logging methods are not
implemented.

=head1 SEE ALSO

L<Log::Any>, L<Log::Any::Adapter>, L<Log::Handler>

=head1 AUTHOR

Gelu Lupaş <gvl@cpan.org>

=head1 COPYRIGHT AND LICENSE
 
Copyright (c) 2013-2014 the Log::Any::Adapter::Handler L</AUTHOR> as listed
above.
 
This is free software, licensed under:
 
  The MIT License (MIT)

=cut
