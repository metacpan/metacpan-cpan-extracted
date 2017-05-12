package GunMojo::Content;

use warnings;
use strict;
use Mojo::Base qw/Mojolicious::Controller Mojolicious::Session/;

my ($self, $class) = @_;
bless $self, $class;

our $VERSION = 0.01;

# This action will render a template
sub normalroute {
	my $self = shift;

	processContent( $self );

	my $header = $self->req->headers->header('X-Requested-With');
	if ( $header && $header eq 'XMLHttpRequest' ) {
		$self->app->log->debug( "AJAX / JSON Response triggered!" );
		$self->render_json({
			dyncontent	=> $self->stash( 'content' ),
			headline	=> $self->stash( 'headline' ),
			permalink	=> $self->stash( 'permalink' ),
		});
		return 1;
	}

	if ( $self->is_iphone ) {
		$self->render( 'iphone_content' );
	}
	else {
		$self->render( 'content' );
	}
	return 1;
}

sub processContent {
	my $self = shift;
        if ( my $cres = rawContent( $self, $self->req->url ) ) {
                $self->stash(
                        'content' => $cres->{content},
                        'headline' => $cres->{headline},
                        'subpage' => $cres->{subpage},
			'permalink' => '<a href="'. $self->req->url->clone .'">Permalink</a>',
			'url' => $self->req->url->clone,
                );
        }
        else {
                $self->stash(
                        'content' => 'The requested URL has no content',
                        'headline' => 'Error',
                        'subpage' => 'Error',
			'permalink' => '',
			'url' => $self->req->url->clone,
                );
        }

        if ( my $nres = rawNews( $self ) ) {
                $self->stash( 'news' => $nres );
        }
        else {
                $self->stash( 'news' => [ 'None', 'There are no news items, yet...' ] );
        }
	stashStuffer( $self );

	return 1;
}

sub rawNews {
	my $self = shift;
	my $sth = $self->db->prepare( 'SELECT n.headline, n.content FROM news n ORDER BY n.ts DESC' );
	$sth->execute;
	my $res = $sth->fetchall_arrayref;
	$sth->finish;
	return $res ? $res : undef;
}

sub rawContent {
	my ( $self, $path ) = @_;
	my $sth = $self->db->prepare( 'SELECT c.subpage, c.headline, c.content FROM content c WHERE c.path = ?' );
	$sth->execute( $path );
	my $res = $sth->fetchrow_hashref;
	$sth->finish;
	return $res ? $res : undef;
}

sub stashStuffer {
	my $self = shift;

	# Dynamic <head>
	#..<title> comes from config file
	$self->stash( 'headTitle' => $self->app->config( 'title' ) );
	#..<meta> tags come from the headMeta SQL table
	my $sth = $self->db->prepare( 'SELECT m.seq, m.group, m.type, m.key, m.value FROM headMeta m ORDER BY m.group ASC' );
	$sth->execute;
	my $res = $sth->fetchall_arrayref;
	$sth->finish;
	$self->stash( 'headMeta' => $res ) if $res;
	undef $res;
	#..<link> tags come from the headLink SQL table
	$sth = $self->db->prepare( 'SELECT l.seq, l.group, l.linkType, l.key, l.href, l.contentType, l.media FROM headLink l ORDER BY l.group ASC' );
	$sth->execute;
	$res = $sth->fetchall_arrayref;
	$sth->finish;
	$self->stash( 'headLink' => $res ) if $res;
	undef $res;
	#..<script> tags come from the headJS SQL table
	$sth = $self->db->prepare( 'SELECT j.seq, j.group, j.type, j.src, j.async, j.id FROM headJS j ORDER BY j.group ASC' );
	$sth->execute;
	$res = $sth->fetchall_arrayref;
	$sth->finish;
	$self->stash( 'headJS' => $res ) if $res;
	undef $res;

	# Dynamic <body>
	#..<script> tags come first, so they can initialize and modify the DOM as needed; they come from the bodyJS SQL table
	$sth = $self->db->prepare( 'SELECT j.seq, j.desc, j.js FROM bodyJS j ORDER BY j.desc ASC' );
	$sth->execute;
	$res = $sth->fetchall_arrayref;
	$sth->finish;
	$self->stash( 'bodyJs' => $res ) if $res;
	undef $res;

	#..Navigation Links: Social
	$sth = $self->db->prepare( 'SELECT j.seq, j.group, j.link FROM bodyNavSocialLinks ORDER BY j.group ASC' );
	$sth->execute;
	$res = $sth->fetchall_hashref;
	$sth->finish;
	$self->stash( 'bodyNavSocialLinks' => $res ) if $res;
	undef $res;

	#..Navigation Links: Site Sections -- TODO: clean this up; remove hard-coded values
	my $bodyNavSectionLinks = {
		'AR-15 Rifles'		=> { path => '/custom/ar15/%' },
		'Bolt-Action Rifles'	=> { path => '/custom/model700/%' },
		'AR-15 Pistols'		=> { path => '/custom/ar15pistol/%' },
		'1911 Pistols'		=> { path => '/custom/1911pistol/%' },
		'Services'		=> { path => '/services/%' },
		'External Links'	=> { path => 'http%' },
	};
	$sth = $self->db->prepare( 'SELECT CONCAT(c.weight, "-", c.seq) AS c.id, c.path, c.subpage FROM content c WHERE c.path LIKE ? ORDER BY c.weight ASC' );
	for ( keys %{ $bodyNavSectionLinks } ) {
		$sth->execute( ${ $_ }->{path} );
		$res = $sth->fetchall_arrayref;
		$res ? ${ $_ }->{content} = $res : next;
	}
	$sth->finish;
	$self->stash( 'bodyNavSectionLinks' => $bodyNavSectionLinks ) if $bodyNavSectionLinks;

	return 1;
}

1;

