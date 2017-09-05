#! perl

use utf8;

# Author          : Johan Vromans
# Created On      : Tue Oct  6 13:55:54 2015
# Last Modified By: Johan Vromans
# Last Modified On: Fri Feb  3 21:26:38 2017
# Update Count    : 92
# Status          : Unknown, Use with caution!

package main;

our $dbh;
our $config;

package EB::Tools::Attachments;

use strict;
use warnings;
use Fcntl qw(O_RDONLY O_WRONLY O_CREAT);
use File::Temp;

use EB;

sub new {
    my ( $pkg, %init ) = @_;
    bless { id => 0,
	    name => undef, path => undef,
	    encoding => 0, checksum => undef,
	    content => undef, %init }, $pkg;
}

sub store {
    my ( $self, $id ) = @_;

    $self->{id} ||= $id || $dbh->get_sequence("attachments_id_seq");
    $self->{encoding} ||= ATTENCODING_BASE64;
    $self->{size} ||=
      $self->{encoding} == ATTENCODING_URI
	? length( $self->{name} )
	: length( ${ $self->{content} } );
    my $att_id = $dbh->store_attachment($self);
    $self->set_sequence( "attachments_id_seq", $self->{id} ) if $id;
    return $self->{id};
}

sub store_from_uri {
    my ( $self, $uri, $id ) = @_;
    $id ||= $self->{id};
    $self->{encoding} = ATTENCODING_URI;
    $self->{name} = $uri;
    $self->store;
}

sub store_from_file {
    my ( $self, $filename, $id ) = @_;
    $id ||= $self->{id};
    my $file = $filename;
    sysopen( my $fd, $file, O_RDONLY )
      or die(__x("Bijlage {file} kan niet worden opgeslagen: {err}",
		 file => $filename, err => "".$!)."\n");

    my $cnt;
    my $buf = "";
    my $offset = 0;
#    my $ctx = Digest::MD5->new;
    while ( ( $cnt = sysread( $fd, $buf, 20480, $offset ) ) > 0 ) {

=begin later

	unless ( defined $type ) {
	    if ( $buf =~ /^\%PDF-/ ) {
		$type = ATTTYPE_PDF;
	    }
	    elsif ( $buf =~ /^\x89PNG\x0d\x0a\x1a\x0a/ ) {
		$type = ATTTYPE_PNG;
	    }
	    elsif ( $buf =~ /^\xff\xd8/ ) {
		$type = ATTTYPE_JPG;
	    }
	    elsif ( $buf =~ /^[[:print:]\s]*$/ ) {
		$type = ATTTYPE_TEXT;
	    }
	    else {
		die(__x("Bijlage {file} is van een niet-ondersteund type",
			file => $filename)."\n");
	    }
	}

=cut

	$offset += $cnt;
    }
    die(__x("Bijlage {file} kon niet worden gelezen: {err}",
	    file => $filename, err => $!)."\n") unless $cnt == 0;
    close($fd);

#    $ctx->add($buf);
#    $self->{checksum} = $ctx->hexdigest;

    $self->{content} = \$buf;
    $self->{name} ||= File::Basename::fileparse($file);
    $self->{size} = $offset;
    $self->store;
}

sub drop {
    my ( $self, $id ) = @_;
    $dbh->drop_attachment( $id || $self->{id} );
}

sub get {
    my ( $self, $id ) = @_;
    my $href = $dbh->get_attachment( $id || $self->{id} );
    # { name => $name, encoding => $enc, content => \$data }
    return $href;
}

sub save_to_file {
    my ( $self, $filename, $id )  = @_;
    my $atts = $self->get( $id || $self->{id} ); # HashRef!
    for ( qw( name content ) ) {
	$self->{$_} = $atts->{$_};
    }

    if ( $atts->{encoding} == ATTENCODING_URI ) {
	my $content = $self->{name} . "\n";
	$self->{content} = \$content;
    }

    my $fd;
    if ( $filename ) {
	sysopen( $fd, $filename, O_WRONLY|O_CREAT, 0666 )
	  or die("?".__x("Fout bij aanmaken bestand {file}: {err}",
			 file => $filename, err => $!)."\n");
    }
    else {
	$fd = File::Temp->new( UNLINK => 0,
			       SUFFIX => "__" . $self->{name} );
	$filename = $fd->filename;
    }

    syswrite( $fd, ${ $self->{content} }, length( ${ $self->{content} } ) ) == length( ${ $self->{content} } )
      or die("?".__x("Fout bij schrijven bestand {file}: {err}",
		     file => $filename, err => $!)."\n");
    $fd->close
      or die("?".__x("Fout bij afsluiten bestand {file}: {err}",
		     file => $filename, err => $!)."\n");
    return $filename;
}

sub save_to_zip {
    my ( $self, $zip, $membername, $id ) = @_;
    my $atts = $self->get( $id || $self->{id} ); # HashRef!
    my $m = $zip->addString( $atts->{content}, $membername );
    # Error check not needed?
    $m->desiredCompressionMethod(8);
}

sub open {
    my ( $self, $id, $output ) = @_;
    $id ||= $self->{id};
    my $href = EB::Tools::Attachments->new->get($id);

    my $file = $self->save_to_file( $output, $id );
    return if defined $output;

    if ( $^O eq "MSWin32" ) {
	if ( $Wx::VERSION ) {
	    Wx::LaunchDefaultBrowser("$file");
	}
	else {
	    system("start", $file);	# ????
	}
	unlink($file);
    }
    elsif ( $^O eq "OSX" ) {
	# Do we need to sleep here?
	system("sh -c 'open \"$file\"; rm -f \"$file\"'&");
    }
    else {
	# xdg-open spawns the right tool and exits immediately.
	system("sh -c 'xdg-open \"$file\"; sleep 5; rm -f \"$file\"'&");
    }
}

sub attachments {
    my ( $self ) = @_;
    my $ret = [];
    my $sth = $dbh->sql_exec("SELECT att_id,att_name,att_encoding FROM Attachments ORDER BY att_id");
    while ( my $rr = $sth->fetchrow_arrayref ) {
	push( @$ret, { id => $rr->[0], name => $rr->[1], encoding => $rr->[2] } );
    }
    $ret;
}

1;
