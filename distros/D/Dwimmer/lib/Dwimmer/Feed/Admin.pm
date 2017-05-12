package Dwimmer::Feed::Admin;
use Moose;

use 5.008005;

our $VERSION = '0.32';

use Carp ();
use Dwimmer::Feed::DB;

use Data::Dumper qw(Dumper);

has 'store'   => (is => 'ro', isa => 'Str', required => 1);
has 'db'      => (is => 'rw', isa => 'Dwimmer::Feed::DB');

sub BUILD {
	my ($self) = @_;

	$self->db( Dwimmer::Feed::DB->new( store => $self->store ) );
	$self->db->connect;

	return;
}

sub list_source {
	my ($self, %args) = @_;
	my $sources = $self->db->get_sources;

	#my $site_id = $args{site} ? $self->db->get_site_id($args{site}) : undef;
	my $site_id;
	if (defined $args{site} and $args{site} ne '') {
		if ($args{site} =~ /^\d+$/) {
			my $site = $self->db->get_site_by_id($args{site});
			die "Invalid site id '$args{site}'\n" if not $site;
			#die Dumper $site;
			# check if id is correct
			$site_id = $args{site};
		} else {
			$site_id = $self->db->get_site_id($args{site});
			if (not defined $site_id) {
				die "Could not find site '$args{site}'\n";
			}
		}
	}

	foreach my $s (@$sources) {
		my $show;
		if (defined $site_id) {
			next if $s->{site_id} != $site_id;
		}
		if ($args{filter}) {
			foreach my $field (qw(feed url status title)) {
				$show++ if $s->{$field} =~ /$args{filter}/i;
			}
		} else {
			$show++;
		}
		if ($show) {
			_dump($s);
		}
	}
	return;
}

sub update {
	my ($self, %args) = @_;

	my $s = $self->db->get_source_by_id($args{id});
	if (not $s) {
		die "ID '$args{id}' not found\n";
	}

	_dump($self->db->get_source_by_id($args{id}));
	$self->db->update($args{id}, $args{field}, $args{value});
	_dump($self->db->get_source_by_id($args{id}));

	return;
}

sub get_site_id {
	my ($self, %args) = @_;

	Carp::croak('No site provides')
		if not defined $args{site};
	if ($args{site} =~ /^\d+$/) {
		# TODO check if exists in the database
		return $args{site};
	}

	return $self->db->get_site_id($args{site});
}

sub add {
	my ($self, %args) = @_;


	my %data;
	$data{url}     = prompt('URL');
	$data{feed}    = prompt('Feed (Atom or RSS)');
	$data{title}   = prompt('Title');
	$data{twitter} = prompt('Twitter');
	$data{status}  = 'enabled';
	$data{comment} = prompt('Comment');
	$data{twitter} =~ s/\@//;
	$data{site_id} = $self->get_site_id( site => $args{site} );

	Carp::Croak("Could not find site $args{site}")
		if not $data{site_id};

	my $id = $self->db->add_source(\%data);
	_dump($self->db->get_source_by_id($id));

	return;
}


sub _dump {
	local $Data::Dumper::Sortkeys = 1;
	print Dumper shift;
	return;
}

sub prompt {
	my ($text) = @_;

	print "$text :";
	my $input = <STDIN>;
	chomp $input;

	return $input;
}

sub list_sites {
	my ($self) = @_;

	my $sites =$self->db->get_sites;
	_dump($sites);

	return;
}


sub list_config {
	my ($self, $site) = @_;

	use Dwimmer::Feed::Config;
	die "site is required now" if not $site;
	my $site_id = $self->db->get_site_id($site);
	my $config = Dwimmer::Feed::Config->get_config($self->db, $site_id);
	_dump($config);
}


1;

