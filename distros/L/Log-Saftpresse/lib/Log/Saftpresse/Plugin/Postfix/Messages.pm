package Log::Saftpresse::Plugin::Postfix::Messages;

use Moose::Role;

# ABSTRACT: plugin to gather postfix warning|fatal|panic messages
our $VERSION = '1.6'; # VERSION

use Log::Saftpresse::Plugin::Postfix::Utils qw( string_trimmer );

requires 'message_detail';
requires 'smtpd_warn_detail';

sub process_messages {
	my ( $self, $stash ) = @_;
	my $service = $stash->{'service'};
	my $message_detail = $self->message_detail;
	my $smtpd_warn_detail = $self->smtpd_warn_detail;

	if( $service eq 'master' ) { # gather all master messages
		$self->incr_host_one( $stash, 'master', $stash->{'message'});
		return;
	}

	if( my ($level, $msg) = $stash->{'message'} =~ /^(warning|fatal|panic): (.*)$/ )  {
		$msg = string_trimmer($msg, 66, $message_detail);
		if( $level eq 'warning' && $service eq 'smtpd' &&
	       			$smtpd_warn_detail == 0 ) {
			return;
		}
		$self->incr_host_one( $stash, $level, $service, $msg);
		$stash->{'postfix_level'} = $level;
	} 

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Postfix::Messages - plugin to gather postfix warning|fatal|panic messages

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
