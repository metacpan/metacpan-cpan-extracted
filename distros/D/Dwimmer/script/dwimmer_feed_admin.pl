#!/usr/bin/perl
use strict;
use warnings;
use v5.8;

use Dwimmer::Feed::Admin;

use Data::Dumper qw(Dumper);
use Getopt::Long qw(GetOptions);

my %opt;
GetOptions(\%opt,
	'store=s',

	'setup',

	'site=s',

	'addsite=s',
	'listsite',

	'listsource:s',
	'enable=i',
	'disable=i',
	'update=i',
	'add',

	'listconfig',
	'config=s',
	'unconfig=s',

	'listqueue=s',
	'listentries',
) or usage();
usage() if not $opt{store};

if ($opt{setup}) {
	setup($opt{store});
	exit;
}

usage("Database ($opt{store}) does NOT exist") if not -e $opt{store};

my $admin = Dwimmer::Feed::Admin->new(%opt);

if ($opt{addsite}) {
	$admin->db->addsite( name => $opt{addsite} );
	exit;
}
if ($opt{listsite}) {
	$admin->list_sites();
	exit;
}

$opt{site} ||= '';

if (exists $opt{listsource}) {
	$admin->list_source( filter => ($opt{listsource} || ''), site => $opt{site} );
} elsif ( defined $opt{enable} ) {
#	usage('--site SITE  required for this operation') if not $opt{site};
	$admin->update( id => $opt{enable},  field => 'status', value =>'enabled' );
} elsif ( defined $opt{disable} ) {
#	usage('--site SITE  required for this operation') if not $opt{site};
	$admin->update( id => $opt{disable}, field => 'status', value => 'disabled' );
} elsif ( defined $opt{update} ) {
	my $str = shift;
	usage('Need update value') if not $str;
	my ($field, $value) = split /=/, $str;
	$admin->update( id => $opt{update}, field => $field, value => $value );
} elsif (exists $opt{add}) {
	usage('--site SITE  required for this operation') if not $opt{site};
	$admin->add( site => $opt{site} );
} elsif ($opt{listconfig}) {
	$admin->list_config($opt{site});
} elsif ($opt{unconfig}) {
	usage('--site SITE  required for this operation') if not $opt{site};
	my $site_id = $admin->db->get_site_id($opt{site});
	$admin->db->delete_config( key => $opt{unconfig}, site_id => $site_id );
} elsif ($opt{config}) {
	usage('--site SITE  required for this operation') if not $opt{site};
	my $value = shift;
	usage('') if not defined $value;

	my $site_id = $admin->db->get_site_id( $opt{site} );
	die("Could not find site '$opt{site}'") if not $site_id;
	$admin->db->set_config( key => $opt{config}, value => $value, site_id => $site_id );
} elsif ($opt{listqueue}) {
	my $entries = $admin->db->get_queue( $opt{listqueue} );
	print Dumper $entries;
} elsif ($opt{listentries}) {
	my $entries = $admin->db->get_all_entries;
	print Dumper $entries;
} else {
	usage();
}
exit;
##############################

sub setup {
	my ($store) = @_;

	usage("Database ($store) already exists") if -e $store;

my $SCHEMA = <<'SCHEMA';
CREATE TABLE sites (
	id        INTEGER PRIMARY KEY,
	name      VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE sources (
	id        INTEGER PRIMARY KEY,
	title     VARCHAR(100),
	url       VARCHAR(100) NOT NULL,
	feed      VARCHAR(100) NOT NULL,
	comment   BLOB,
	twitter   VARCHAR(30),
	status    VARCHAR(30),
	site_id   INTEGER NOT NULL,
	last_fetch_time VARCHAR(10),
	last_fetch_status VARCHAR(10),
	last_fetch_error BLOB,
	CONSTRAINT url_site UNIQUE (url, site_id),
	CONSTRAINT feed_site UNIQUE (feed, site_id),
	FOREIGN KEY (site_id) REFERENCES sites(id)
);

CREATE TABLE entries (
	id        INTEGER PRIMARY KEY,
	source_id INTEGER NOT NULL,
	link      VARCHAR(100) NOT NULL,
	site_id   INTEGER NOT NULL,
	remote_id VARCHAR(100),
	author    VARCHAR(100),
	issued    VARCHAR(100),
	title     VARCHAR(100),
	summary   BLOB,
	content   BLOB,
	tags      VARCHAR(100),
	FOREIGN KEY (source_id) REFERENCES sources(id),
	FOREIGN KEY (site_id) REFERENCES sites(id)
);
CREATE TABLE delivery_queue (
	channel  VARCHAR(30) NOT NULL,
	entry    INTEGER     NOT NULL,
	site_id   INTEGER NOT NULL,
	FOREIGN KEY (site_id) REFERENCES sites(id),
	FOREIGN KEY (entry) REFERENCES entries(id)
);
CREATE TABLE config (
	key VARCHAR(100) NOT NULL,
	value VARCHAR(255),
	site_id   INTEGER NOT NULL,
	CONSTRAINT key_site UNIQUE (key, site_id),
	FOREIGN KEY (site_id) REFERENCES sites(id)
)
SCHEMA

	my $db = Dwimmer::Feed::DB->new( store => $store );
	$db->connect;

	foreach my $sql (split /;/, $SCHEMA) {
		$db->dbh->do($sql);
	}
}


sub usage {
	my $text = shift || '';

	die <<"END_USAGE";
$text

Usage: $0

Required:
       --store storage.db              (link to the SQLite database holding everyting)

Optional:
       --site [SITE|ID]
                    (optional for --listsource and --listconfig, --config, --unconfig)
                    (required for --add)
                    (irrelevant to --setup, --addsite and --update --endable --disable)

Actions:

       --setup               (creating the empty database)

       --addsite SITE        (one word, not only digits!)
       --listsite            (listing all the sites in the database)


       --add                    (add a new feed, will prompt questions)
       --listsource [filter]    (list sources.   the filter is optional)
       --enable ID
       --disable ID

       --update ID "feed=http://..."
       --update ID "comment=some text here"
       --update ID "twitter=twitter_id"

       --listconfig
       --config key value
       --unconfig key

       --listqueue CHANNEL    (e.g. mail)

       --listentries         Show all the entries
END_USAGE
}
