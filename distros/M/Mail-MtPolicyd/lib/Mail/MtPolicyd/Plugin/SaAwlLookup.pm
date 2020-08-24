package Mail::MtPolicyd::Plugin::SaAwlLookup;

use Moose;
use namespace::autoclean;

our $VERSION = '2.05'; # VERSION
# ABSTRACT: mtpolicyd plugin for querying a spamassassin AWL database for reputation

extends 'Mail::MtPolicyd::Plugin';

use Mail::MtPolicyd::Plugin::Result;

use BerkeleyDB;
use BerkeleyDB::Hash;

use NetAddr::IP;


has 'db_file' => ( is => 'rw', isa => 'Str',
    default => '/var/lib/amamvis/.spamassassin/auto-whitelist'
);

has '_awl' => (
	is => 'ro', isa => 'HashRef', lazy => 1,
	default => sub {
		my $self = shift;
		my %map;
		my $db = tie %map, 'BerkeleyDB::Hash',
			-Filename => $self->db_file,
			-Flags => DB_RDONLY
		or die "Cannot open ".$self->db_file.": $!\n" ;
		return(\%map);
	},
);

sub truncate_ip_v4 {
    my ( $self, $ip ) = @_;
    if( $ip =~ m/^(\d+\.\d+).\d+.\d+$/ ) {
        return( $1 );
    }
    return;
}

sub truncate_ip_v6 {
    my ( $self, $ip ) = @_;
    my $addr = NetAddr::IP->new6( $ip.'/48' );
    if( ! defined $addr ) {
        return;
    }
    my $result = $addr->network->full6;
    $result =~ s/(:0000)+/::/;
    return $result;
}

sub truncate_ip {
    my ( $self, $ip ) = @_;

    if( $ip =~ /:/) {
        return $self->truncate_ip_v6($ip);
    }
    return $self->truncate_ip_v4($ip);
}

sub query_awl {
    my ( $self, $addr, $ip ) = @_;
    my $ip_key = $self->truncate_ip( $ip );
    if( ! defined $ip_key ) {
        return;
    }
    my $count = $self->_awl->{$addr.'|ip='.$ip_key};
    if( ! defined $count ) { return; }

    my $total = $self->_awl->{$addr.'|ip='.$ip_key.'|totscore'};
    if( ! defined $total ) { return; }

    my $score = $total / $count;

    return( $count, $score );
}

sub run {
	my ( $self, $r ) = @_;
	my $addr = $r->attr('sender');
	my $ip = $r->attr('client_address');
	my $session = $r->session;

    if( ! defined $addr || ! defined $ip ) {
        return;
    }

	my ( $count, $score ) = $r->do_cached('sa-awl-'.$self->name.'-result',
		sub { $self->query_awl( $addr, $ip ) } );

	if( ! defined $count || ! defined $score ) {
		$self->log($r, 'no AWL record for '.$addr.'/'.$ip.' found');
		return;
	}

	$self->log($r, 'AWL record for '.$addr.'/'.$ip.' count='.$count.', score='.$score);

	return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Plugin::SaAwlLookup - mtpolicyd plugin for querying a spamassassin AWL database for reputation

=head1 VERSION

version 2.05

=head1 DESCRIPTION

This plugin queries the auto_whitelist database used by spamassassins AWL
plugin for the reputation of sender ip/address combination.

Based on the AWL score a score or action in mtpolicyd can be applied in combination
with the SaAwlAction plugin.

=head1 PARAMETERS

=over

=item db_file (default: /var/lib/amavis/.spamassassin/auto-whitelist)

The path to the auto-whitelist database file.

=back

=head1 EXAMPLE

To read reputation from amavis/spamassassin AWL use:

  <Plugin amavis-awl>
    module = "SaAwlLookup"
    db_file = "/var/lib/amamvis/.spamassassin/auto-whitelist"
  </Plugin>

The location of auto-whitelist may be different on your system.
Make sure mtpolicyd is allowed to read the db_file.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
