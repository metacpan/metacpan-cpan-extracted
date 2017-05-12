package Dwimmer::Tools;
use strict;
use warnings;
use Dancer ':syntax';

use base 'Exporter';
use Digest::SHA;
use YAML;

use Dwimmer::DB;

our $VERSION = '0.32';

our $SCHEMA_VERSION = 2;

our @EXPORT_OK = qw(sha1_base64 _get_db _get_site _get_redirect
	save_page create_site read_file trim $SCHEMA_VERSION);

our $dbfile;

sub _get_db {

	my $root = config->{appdir} || $ENV{DWIMMER_ROOT};

	if ($root) {
		$dbfile = path( $root, 'db', 'dwimmer.db' );
	}

	die "Could not figure out dbfile" if not $dbfile;

	Dwimmer::DB->connect( "dbi:SQLite:dbname=$dbfile", '', '' );
}

sub _get_redirect {
	my $host_name = request->host;

	$host_name =~ s/:\d+.*//;

	my $db = _get_db();
	my $host = $db->resultset('Host')->find( { name => $host_name } );
	return if not $host;

	my $new = $host->main->name;
	my $url = 'http://' . $new .  ':' . request->port . request->path_info;
	return ($new, $url);
}


sub _get_site {
	my $site_name = 'www';

	# based on hostname?
	my $host = request->host;

	# development and testing:
	if ( $host =~ /^localhost:\d+$/ ) {
		$host = 'www';
	}

	if ( params->{_dwimmer} ) {
		$host = params->{_dwimmer};
	}
	if ( $host =~ /^([\w.-]+)/ ) {
		$site_name = $1;
	}

	my $db = _get_db();
	my $site = $db->resultset('Site')->find( { name => $site_name } );

	# for now, let's default to www if the site isn't in the database
	if ( not $site ) {
		$site_name = 'www';
		$site = $db->resultset('Site')->find( { name => $site_name } );
	}

	return ( $site_name, $site );
}


sub sha1_base64 {
	return Digest::SHA::sha1_base64(shift);
}

sub save_page {
	my ( $site_id, $params ) = @_;

	# TODO check if the user has the right to save this page!
	my $db = _get_db();
	my $cpage = $db->resultset('Page')->find( { siteid => $site_id, filename => $params->{filename} } );

	my $create = $params->{create};
	if ( $cpage and $create ) {
		return to_json { error => 'page_already_exists', details => $params->{filename} };
	}
	if ( not $cpage and not $create ) {
		return to_json { error => 'page_does_not_exist', details => $params->{filename} };
	}

	# TODO transaction!
	my $revision = 1;
	if ($cpage) {
		$revision = $cpage->revision + 1;
		$cpage->revision($revision);
		$cpage->update;
	} else {
		$cpage = $db->resultset('Page')->create(
			{   filename => $params->{filename},
				siteid   => $site_id,
				revision => $revision,
			}
		);
	}


	my $time = time;
	$db->resultset('PageHistory')->create(
		{   pageid    => $cpage->id,
			title     => $params->{editor_title},
			filename  => $params->{filename},
			body      => $params->{editor_body},
			author    => $params->{author},
			siteid    => $site_id,
			timestamp => $time,
			revision  => $revision,
		}
	);
	return to_json { success => 1 };
}

sub create_site {
	my ( $hostname, $title, $ownerid ) = @_;

	my $time = time;

	my $db = _get_db();

	my $site = $db->resultset('Site')->create( { name => $hostname, owner => $ownerid, creation_ts => $time } );

	save_page(
		$site,
		{   create       => 1,
			editor_title => 'Welcome to your Dwimmer installation',
			editor_body  => "<h1>Welcome to $title</h1>",
			author       => $ownerid,
			filename     => '/',
		}
	);

	return;
}

sub trim { $_[0] =~ s/^\s+|\s+$//g }

sub read_file {
	my $file = shift;
	open my $fh, '<', $file or die "Could not open '$file' $!";
	local $/ = undef;
	my $cont = <$fh>;
	close $fh;
	return $cont;
}

1;
