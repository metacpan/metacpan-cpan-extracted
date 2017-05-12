package Dwimmer::Feed::Collector;
use Moose;

use 5.008005;

our $VERSION = '0.32';

my $MAX_SIZE = 500;
my $TRIM_SIZE = 400;

use Cwd            qw(abs_path);
use Data::Dumper   qw(Dumper);
use File::Basename qw(dirname);
use File::Path     qw(mkpath);
use List::Util     qw(min);
use MIME::Lite     ();
use Template;
use XML::Feed      ();

use Dwimmer::Feed::DB;
use Dwimmer::Feed::Config;

my $URL = '';
my $TITLE = '';
my $DESCRIPTION = '';
my $ADMIN_NAME = '';
my $ADMIN_EMAIL = '';
my $FRONT_PAGE_SIZE = 20;


#has 'sources' => (is => 'ro', isa => 'Str', required => 1);
has 'store'   => (is => 'ro', isa => 'Str', required => 1);
has 'db'      => (is => 'rw', isa => 'Dwimmer::Feed::DB');
has 'error'   => (is => 'rw', isa => 'Str');

sub BUILD {
	my ($self) = @_;

	$self->db( Dwimmer::Feed::DB->new( store => $self->store ) );
	$self->db->connect;

	return;
}

sub collect_all {
	my ($self) = @_;

	my $sites = $self->db->get_sites;
	foreach my $site (@$sites) {
		$self->collect($site->{id});
	}

	return;
}

sub collect {
	my ($self, $site_id) = @_;

	my $INDENT = ' ' x 11;
    $self->error('');

	my $sources = $self->db->get_sources( status => 'enabled', site_id => $site_id );
	main::LOG("sources loaded: " . @$sources);

	for my $e ( @$sources ) {
		main::LOG('');
		next if not $e->{status} or $e->{status} ne 'enabled';
		if (not $e->{feed}) {
			main::LOG("ERROR: No feed for $e->{title}");
            $self->error( $self->error . "No feed for title $e->{title}\n\n");
			next;
		}
		my $feed;
		eval {
			local $SIG{ALRM} = sub { die 'TIMEOUT' };
			alarm 10;

			main::LOG("Processing feed");
			#main::LOG(Dumper $e);
			main::LOG("$INDENT $e->{feed}");
			main::LOG("$INDENT Title by us  : $e->{title}");
			$feed = XML::Feed->parse(URI->new($e->{feed}));
		};
		my $err = $@;
		alarm 0;
		if ($err) {
			main::LOG("   EXCEPTION: $err");
            $self->error( $self->error . "Feed $e->{feed}\n   $err\n\n" );
			if ($err =~ /TIMEOUT/) {
				$self->db->update_last_fetch($e->{id}, 'fail_timeout', $err);
			} else {
				$self->db->update_last_fetch($e->{id}, 'fail_fetch', $err);
			}
			next;
		}
		if (not $feed) {
			main::LOG("   ERROR: " . XML::Feed->errstr);
            $self->error( $self->error . "Feed $e->{feed}\n   " . XML::Feed->errstr . "\n\n" );
			$self->db->update_last_fetch($e->{id}, 'fail_nofeed', XML::Feed->errstr);
			next;
		}
		if ($feed->title) {
			main::LOG("$INDENT Title by them: " . $feed->title);
		} else {
			main::LOG("   WARN: no title");
		}


		for my $entry ($feed->entries) {
			#print $entry, "\n";
			eval {
				# checking for new hostname
				my $hostname = $entry->link;
				$hostname =~ s{^(https?://[^/]+).*}{$1};
				#main::LOG("HOST: $hostname");
				#if ( not $self->db->find( link => "$hostname%" ) ) {
				#	main::LOG("   ALERT: new hostname ($hostname) in URL: " . $entry->link);
				#	my $msg = MIME::Lite->new(
				#		From    => 'dwimmer@dwimmer.com',
				#		To      => 'szabgab@gmail.com',
				#		Subject => "Dwimmer: new URL noticed $hostname",
				#		Data    => $entry->link,
				#	);
				#	$msg->send;
				#}
				if ( not $self->db->find( link => $entry->link ) ) {
					my %current = (
						source_id => $e->{id},
						link      => $entry->link,
						author    => ($entry->author || ''),
						remote_id => ($entry->id || ''),
						issued    => ($entry->issued || $entry->modified),
						title     => ($entry->title || ''),
						summary   => ($entry->summary->body || ''),
						content   => ($entry->content->body || ''),
						tags    => '', #$entry->tags,
						site_id   => $site_id,
					);
					main::LOG("   INFO: Adding $current{link}");
					$self->db->add_entry(%current);
				}
			};
            $err = $@;
			if ($err) {
				main::LOG("   EXCEPTION: $err");
                $self->error( $self->error . "Feed $e->{feed}\n   $err\n\n" );
			}
		}
		$self->db->update_last_fetch($e->{id}, 'success', '');
	}

	return;
}

# should be in its own class?
# plan: N item on front page or last N days?
# every day gets its own page in archice/YYYY/MM/DD
sub generate_html_all {
	my ($self) = @_;

	my $sites = $self->db->get_sites;
	foreach my $site (@$sites) {
		$self->generate_html($site->{id});
	}

	return;
}

sub generate_html {
	my ($self, $site_id) = @_;
	die if not defined $site_id;

	my $dir = Dwimmer::Feed::Config->get($self->db, $site_id, 'html_dir');
	die 'Missing directory name' if not $dir;
	die "Not a directory '$dir'" if not -d $dir;

	my $sources = $self->db->get_sources( status => 'enabled', site_id => $site_id );
	my %src = map { $_->{id } => $_  } @$sources;


	my $all_entries = $self->db->get_all_entries;
	my $size = min($FRONT_PAGE_SIZE, scalar @$all_entries);

	foreach my $e (@$all_entries) {
		$e->{source_name} = $src{ $e->{source_id} }{title};
		$e->{source_url} = $src{ $e->{source_id} }{url};
		$e->{twitter} = $src{ $e->{source_id} }{twitter};
		$e->{display} = $e->{summary};
		if (not $e->{display} and $e->{content} and length $e->{content} < $MAX_SIZE) {
			$e->{display} = $e->{content};
		}
		# trimming needs more work to ensure all the tags in the content are properly closed.

#		$e->{display} = $e->{summary} || $e->{content};
#		if ($e->{display} and length $e->{display} > $MAX_SIZE) {
#			$e->{display} = substr $e->{display}, 0, $TRIM_SIZE;
#		}
	}


	my @entries = @$all_entries[0 .. $size-1];

	my $clicky_enabled = Dwimmer::Feed::Config->get($self->db, $site_id, 'clicky_enabled');
	my $clicky_code    = Dwimmer::Feed::Config->get($self->db, $site_id, 'clicky_code');

	my %site = (
		url             => $URL,
		title           => $TITLE,
		description     => $DESCRIPTION,
		language        => 'en',
		admin_name      => $ADMIN_NAME,
		admin_email     => $ADMIN_EMAIL,
		id              => $URL,
		dwimmer_version => $VERSION,
		last_update     => scalar localtime,
		clicky          => ($clicky_enabled and $clicky_code ? $clicky_code : ''),
	);

	$site{last_build_date} = localtime;

	my @feeds = sort {lc($a->{title}) cmp lc($b->{title})}
			grep { $_->{status} and $_->{status} eq 'enabled' }
			@$sources;


	my %latest_entry_of;
	my %entries_on;
	foreach my $e (@$all_entries) {
		my $field = $e->{source_id};
		my ($date) = split / /, $e->{issued};
		push @{$entries_on{$date}}, $e;
		next if $latest_entry_of{ $field } and $latest_entry_of{ $field } gt $e->{issued};
		$latest_entry_of{ $field } = $e;
	}

	foreach my $f (@feeds) {
		$f->{latest_entry} = $latest_entry_of{ $f->{id} };
        #$f->{last_fetch_time} = localtime $f->{last_fetch_time};
		##commented out on 2013.4.26 on the live site as it was generating uninitialized warnings
		##and in the 0.31 hotfix
	}


	my $root = dirname dirname abs_path $0;

	my $t = Template->new({ ABSOLUTE => 1, });

	my $header_tt = Dwimmer::Feed::Config->get($self->db, $site_id, 'header_tt');
	my $footer_tt = Dwimmer::Feed::Config->get($self->db, $site_id, 'footer_tt');
	my $index_tt = $header_tt . Dwimmer::Feed::Config->get($self->db, $site_id, 'index_tt') . $footer_tt;
	my $feeds_tt = $header_tt . Dwimmer::Feed::Config->get($self->db, $site_id, 'feeds_tt') . $footer_tt;

	$t->process(\$feeds_tt, {entries => \@feeds,   %site}, "$dir/feeds.html") or die $t->error;
	$t->process(\$index_tt, {entries => \@entries, %site}, "$dir/index.html") or die $t->error;

	foreach my $date (keys %entries_on) {
		my ($year, $month, $day) = split /-/, $date;
		my $path = "$dir/archive/$year/$month";
		mkpath $path;
		$t->process(\$index_tt, {entries => $entries_on{$date}, %site}, "$path/$day.html") or die $t->error;
	}

	$t->process(\Dwimmer::Feed::Config->get($self->db, $site_id, 'rss_tt'),   {entries => \@entries, %site}, "$dir/rss.xml")    or die $t->error;
	$t->process(\Dwimmer::Feed::Config->get($self->db, $site_id, 'atom_tt'),  {entries => \@entries, %site}, "$dir/atom.xml")   or die $t->error;

	return;
}


1;

