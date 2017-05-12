package Gtk::HTML::Simple;
use Gtk::HTML;
use LWP::UserAgent;
use URI;
use Gtk::LWP;

$VERSION = 0.1;

@ISA = qw(Gtk::HTML);

my $default_ua;

# TODO: handle page loading stopping nicely

sub new {
	my ($self, $url) = @_;

	$self = new Gtk::HTML;
	$self = bless $self, __PACKAGE__;
	$self->{_base} = new URI("file:./");
	$self->{_aborting} = {};
	$self->{_loading} = {};
	$self->{_history} = [];
	$self->{_histid} = undef;
	$self->signal_connect('url_requested', sub {shift->load_url(@_)});
	$self->signal_connect('link_clicked', sub {shift->load_url(@_)});
	$self->signal_connect('submit', sub {shift->submit(@_)});
	$self->signal_connect('load_done', sub {shift->load_done(@_)});
	$self->load_url($url) if $url;
	$self;
}

sub get_agent {
	my ($self) = shift;
	unless ($self->{_ua}) {
		unless ($default_ua) {
			$default_ua = LWP::UserAgent->new;
			$default_ua->agent("Gtk::HTML::Simple/$VERSION");
			$default_ua->env_proxy;
		}
		$self->{_ua} = $default_ua;
	}
	return $self->{_ua};
}

sub stop_loading {
	my ($self) = shift;
	warn "Aborting load...\n";
	# doesn't work...
#	foreach my $k (keys %{$self->{_loading}}) {
#		$self->{_aborting}{$k} = 1 if $k;
#	}
#	$self->{_aborting}{$self->{_loading}{0}} =1;
#	foreach my $k (keys %{$self->{_loading}}) {
#		$self->{_aborting}{$k} = 1 if $k;
#	}
	#Gtk->main_iteration while (Gtk->events_pending() || keys %{$self->{_aborting}});
	#warn "\ndone\n";

}

sub load_done {
	my ($self) = shift;
	$self->{_loading} = {};
}

sub load_url {
	my ($self, $url, $handle) = @_;
	my $ua = $self->get_agent;
	my ($req, $res);
	#Gtk->main_iteration while (Gtk->events_pending);
	if (ref($url) && $url->isa('HTTP::Request')) {
		$req = $url;
	} else {
		#warn "REQUEST: $url ($self->{_base})\n";
		$req = new HTTP::Request('GET', URI->new_abs($url, $self->{_base}));
	}
	unless ($handle) {
		$self->stop_loading() if ($self->{_loading}{0});
		# that is, load a new page
		$self->{_loading}{0} = $handle = $self->begin;
		$self->{_base} = $req->uri;
	} else {
		$self->{_loading}{$handle} = 1;
	}
	#warn "REQUEST: $handle\n";
	$res = $ua->request($req, sub {
		my ($d) = shift;
		warn "User interrupt of $handle\n",die "User interrupt\n" if delete $self->{_aborting}{$handle};
		$self->write($handle, $d) if (defined ($d) && length($d));
	}, 4096);
	delete $self->{_aborting}{$handle};
	if ($res->is_success) {
		$self->end($handle, 'ok');
	} else {
		$self->write($handle, $res->status_line);
		$self->end($handle, 'error');
	}
	return $res;
}

sub submit {
	my ($self, $method, $url, $encoding) = @_;
	my $req;
	# no POST yet
	$url .= '?'.$encoding if (defined $encoding && length($encoding));
	$self->{_base} = URI->new_abs($url, $self->{_base});
	$req = new HTTP::Request($method, $self->{_base});
	return $self->load_url($req);
}

1;
