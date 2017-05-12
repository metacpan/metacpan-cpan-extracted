package Log::Saftpresse::Plugin::LimitProgram;

use Moose;

# ABSTRACT: plugin to limit messages by syslog program name
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::Plugin';

has 'regex' => ( is => 'rw', isa => 'Str', required => 1 );

sub process {
	my ( $self, $stash ) = @_;
	my $regex = $self->regex;

	if( ! defined $stash->{'program'} ) {
		return;
	}
	if( $stash->{'program'} !~ /$regex/ ) {
		return('next');
	}
	
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::LimitProgram - plugin to limit messages by syslog program name

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
