package IO::Ftp;
require 5.005_62;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

use vars qw/$VERSION/;

$VERSION = 0.06;
our %EXPORT_TAGS = ( 'all' => [ qw(
		new	
		delete
		rename_to
		mdtm
		size
		filename
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();


use File::Basename;
use URI;
use Symbol;
use Net::FTP;
use Carp;


sub new {
	my ($src, $mode, $uri_string, %args) = @_;
	my $class = ref $src || 'IO::Ftp';
	if (ref $src and not $src->isa('IO::Ftp')) {
		carp "Can't make an IO::FTP from a ", ref $src;
		return;
	}

	my $uri;
	if (ref $uri_string) {
		unless ($uri_string->isa('URI')) {
			carp "can' t make a URI from a ", ref $uri_string;
			return;
		}
		$uri = $uri_string;
	} else {
		$uri = URI->new('ftp:' . $uri_string);
	}

	my $ftp;
	if (ref $src and not $uri->host) {
		if ($src->connected) {
			warn "Can't reuse host with open connection";
			return;
		}
		$ftp = ${*$src}{'io_ftp_ftp'};
	} else {		
		$ftp = Net::FTP->new(
			$uri->host, 
			Port => $uri->port,
			Debug => $args{DEBUG},
			Timeout => $args{Timeout},
			BlockSize => $args{BlockSize},
			Passive => $args{Passive},
		);
	}
	
	unless ($ftp) {
		carp "Can't connect to host ", $uri->host;
		return;
	}
	
	my $self = __open($ftp, $mode, $uri, %args);
	return unless $self;
	
	${*$self}{'io_ftp_ftp'} = $ftp;
	${*$self}{'io_ftp_uri'} = $uri;

	return bless $self, $class;
}

sub __open {
	my ($ftp, $mode, $uri, %args) = @_;

	my $id = $uri->user || 'anonymous';
	my $pwd = $uri->password || 'anon@anon.org';
	
	unless ($ftp->login($id, $pwd)) {
		warn "Can't login: ", $ftp->message;
		return;
	}
	
	fileparse_set_fstype($args{OS}) if $args{OS};
	
	my ($file, $path) = fileparse($uri->path);
	warn "File: $file, Path: $path" if $args{DEBUG};

	if ($path =~ m{^//(.*)}) {		# initial single / is relative path, // is absolute	
		$path = $1;
		warn "cwd /" if $args{DEBUG};
		unless ($ftp->cwd('/')) {
			warn "Can't cwd to /";
			return;
		}
	}
			
	foreach (split '/', $path) {
		next unless $_;		#ignore embedded back-to-back /.  else will cwd with no parm, which will default to 'cwd /'
		warn "cwd $_" if $args{DEBUG};
		unless ($ftp->cwd($_)) {
			warn "Can't cwd to $_";
			return;
		}
	}
	if ($args{type}) {
		$args{type} = uc $args{type};
		unless ($args{type} =~ /^[AI]$/) {
			carp "Invalid type: $args{type}";
			return;
		}
		unless ($ftp->type($args{type}) ) {
			carp "Can't set type $args{type}: ", $ftp->message;
		}
	}

	if ($mode eq '<<') {
		$file = __find_file($ftp, $file);
		return unless $file;
	}

	# cache these in case user wants initial values.  Can't get them once the data connection is open.
	my $size = $ftp->size($file);
	my $mdtm = $ftp->mdtm($file);
	
	
	my $dataconn;
	if ($mode eq '<' or $mode eq '<<') {
		$dataconn = $ftp->retr($file);
	} elsif ($mode eq '>') {
		$dataconn = $ftp->stor($file);
	} elsif ($mode eq '>>') {
		$dataconn = $ftp->appe($file);
	} else {
		carp "Invalid mode $mode";
		return;
	}

	unless ($dataconn) {
		carp "Can't open $file: ", $ftp->message ;
		return;
	}

	# we want to be a subclass of the dataconn, but its class is dynamic.
	push @ISA, ref $dataconn;
	
	${*$dataconn}{'io_ftp_file'} = $file;
	${*$dataconn}{'io_ftp_path'} = $path;
	${*$dataconn}{'io_ftp_size'} = $size;
	${*$dataconn}{'io_ftp_mdtm'} = $mdtm;
	
	return $dataconn;
}

sub __find_file {
	my ($ftp,$pattern) = @_;

	my @files = $ftp->ls($pattern);	
	return $files[0];
}


sub filename {
	my $self = shift;
	return ${*$self}{'io_ftp_file'};
}

sub path {
	my $self = shift;
	return ${*$self}{'io_ftp_path'};
}

sub uri {
	my $self = shift;
	return ${*$self}{'io_ftp_uri'};
}

### allow shortcuts to Net::FTP's rename and delete, but only if data connection not open.  OTW we'll hang.

sub rename_to {
	my ($self, $new_name) = @_;
	return if $self->connected;
	
	my $ret = ${*$self}{'io_ftp_ftp'}->rename(${*$self}{'io_ftp_file'}, $new_name);
	${*$self}{'io_ftp_file'} = $new_name;
	return $ret;
}

sub delete {
	my ($self) = @_;
	return if $self->connected;
	
	return ${*$self}{'io_ftp_ftp'}->delete(${*$self}{'io_ftp_file'});
}


### return cached stats if connected, or real ones if connection closed.

sub mdtm {
	my ($self) = @_;
	return ${*$self}{'io_ftp_mdtm'} if $self->connected;
	
	return ${*$self}{'io_ftp_ftp'}->mdtm(${*$self}{'io_ftp_file'});
}

sub size {
	my ($self) = @_;
	return ${*$self}{'io_ftp_size'} if $self->connected;
	
	return ${*$self}{'io_ftp_ftp'}->size(${*$self}{'io_ftp_file'});
}


1;


=head1 NAME

IO::Ftp - A simple interface to Net::FTP's socket level get/put (DEPRECATED)

=head1 SYNOPSIS


 use IO::Ftp;
 
 my $out = IO::Ftp->new('>','//user:pwd@foo.bar.com/foo/bar/fu.bar', TYPE=>'a');
 my $in = IO::Ftp->new('<','//foo.bar.com/foo/bar/fu.bar', TYPE=>'a');	#anon access example
  
 while (<$in>) {
 	s/foo/bar/g;
 	print $out;
 }
 
 close $in;
 close $out;


### for something along the lines of 'mget': 
 
while (my $in = IO::Ftp->new('<<','//foo.bar.com/foo/bar/*.txt', TYPE=>'a') {
	print "processing ",$in->filename, "\n";
	#...
	$in->close;
	$in->delete;
}


=head1 DESCRIPTION

Deprecated.  Other better options exist.  See, for example, IO::All::FTP

=head2 EXPORTS

None by default.

=head2 REQUIRES

L<Net::FTP>
L<File::Basename>
L<URI>
L<Symbol>


=head1 CONSTRUCTOR

=over 4

=item new (  MODE, URI [,OPTIONS] )

C<MODE> indicates the FTP command to use, and is one of

=over 4

=item <		get

=item >		put

=item >>	append

=item <<	get with wildcard match.  This allows fetching a file when the name is not known, 
or is partially known.  Wildcarding is as performed by Net::FTP::ls.  If more than one file matches,
the same one will always be returned.  To process a number of files, they must be deleted 
or renamed to not match the wildcard.

=back

C<URI> is an FTP format URI without the leading 'ftp:'.
C<OPTIONS> are passed in hash format, and can be one or more of

=over 4

=item TYPE		force ASCII (a) or binary (i) mode for the transfer.

=item DEBUG	Enables debug messages.  Also enabled Net::FTP's Debug flag.

=item Timeout	Passed to Net::FTP::new

=item BlockSize	Passed to Net::FTP::new

=item Passive	Passed to Net::FTP::new

=back

=back

=head1 METHODS

=over 4

=item rename_to (NEW_NAME)
Renames the file.	

=item delete
Deletes the file.

=item size	
Returns the size of the file.

=item mdtm	
Returns the modification time of the fiile.  

=back

Note: These methods cannot be performed while the connection is open.  
rename_to and delete will fail and return undef if used before the socket is closed.

size and mdtm cache their values before the socket is opened.  
After the socket is closed, they call the Net::FTP methods of the same name.

=head1 CREDITS

Graham Barr for his Net::FTP module, which does all the 'real work'.

tye at PerlMonks

=head1 COPYRIGHT

(c) 2003 Mike Blackwell.  All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 AUTHOR

Mike Blackwell <mikeb@cpan.org>

=head1 SEE ALSO

Net::FTP
perl(1).

=cut
