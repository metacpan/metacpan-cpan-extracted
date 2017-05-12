package Log::Saftpresse::Plugin::Postfix::Service;

use Moose::Role;

# ABSTRACT: plugin to parse postfix service
our $VERSION = '1.6'; # VERSION

sub process_service {
	my ( $self, $stash ) = @_;
	my $program = $stash->{'program'};

	( $stash->{'service'} ) = $stash->{'program'} =~ /([^\/]+)$/;

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Postfix::Service - plugin to parse postfix service

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
