package Linux::InitFS::Spec;
use warnings;
use strict;

use File::ShareDir;

my $BASE = File::ShareDir::dist_dir( 'Linux-InitFS' );

sub new {
	my ( $this, $name ) = @_;

	my $class = ref( $this ) || $this;

	my $self = bless [], $class;

	return $self->init( lc $name ) ? $self : undef;
}

sub init {
	my ( $this, $name ) = @_;

	my $file = $BASE . '/specs/' . $name . '.cfg';

	return unless -f $file && -r $file;

	my $rc = open my $fh, '<', $file;
	return unless defined $rc;

	while ( <$fh> ) {
		chomp;
		s/#.*//;
		s/^\s+//;
		s/\s+$//;
		next unless $_;

		my @parts = split /\s+/;

		push @{$this}, [ @parts ];

	}

	return 1;
}


1;
