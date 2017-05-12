package HTTP::DAV::Nginx;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use Carp;

our $VERSION = '0.1.6';

use constant C_BUF_SIZE => 8192;

#-----------
sub new
#-----------
{
	my $class = shift;
	my $url   = shift;
	my %param = @_;

	my $self = {};
	
	$self -> {'ua'} = new LWP::UserAgent;
	
	$url = _add_trailing_slash($url);
	$self -> {'url'} = $url;

	$self -> {'die_on_errors'} = $param{'die_on_errors'} || 0;
	$self -> {'warn_on_errors'} = $param{'warn_on_errors'} || 0;

	bless $self, $class;

	return $self;
	
}

#------------
sub _error
#------------
{
	my $self  = shift;
	my $error = shift;
	
	if ($self -> {'die_on_errors'}) 
	{
		croak $error;
	}
	if ($self -> {'warn_on_errors'}) 
	{
		carp $error;
	}
	
		$self -> {'err'} = $error; 
}

#------------------------
sub _add_trailing_slash
#------------------------
{
	my $url = shift;
	
	$url =~ s|/$||;

	$url .= '/'; 

	return $url;
}

#--------------------------
sub _clear_begining_slash
#--------------------------
{
	my $uri = shift;

	$uri =~ s/^\///;

	return $uri;
}

#------------------
sub _read_file_cb
#------------------
{
	my $fh = shift;
	
	my $buffer;
	read($fh, $buffer, C_BUF_SIZE);
	
	return $buffer;
}



#----------
sub err
#----------
{
	my $self = shift;
	
	return $self -> {'err'};
}

#-----------
sub mkcol
#-----------
{
	my $self  = shift;
	my $uri   = shift;

	my $request = HTTP::Request->new();
	$request -> method('MKCOL');
	$request -> uri($self -> {'url'} . _clear_begining_slash($uri));
	
	my $response = $self -> {'ua'} -> request($request);
	
	unless ($response -> is_success)
	{
		$self -> _error("METHOD:MKCOL URI:$uri Status:" . $response -> status_line);
		return undef;
	}
	
	return 1;
}

#-------------
sub delete
#-------------
{
	my $self   = shift;
	my $uri    = shift;
	my %params = @_;

	my $request = HTTP::Request->new();
	$request -> method('DELETE');
	$request -> uri($self -> {'url'} . _clear_begining_slash($uri));
	
	$request -> header('Depth' => $params{'depth'}) if defined $params{'depth'};

	my $response = $self -> {'ua'} -> request($request);

	unless ($response -> is_success)
	{
		$self -> _error("METHOD:DELETE URI:$uri Status:" . $response -> status_line);
		return undef;
	}

	return 1;
}

#---------
sub put
#---------
{
	my $self      = shift;
	my $uri       = shift;
	my $data_type = shift;
	my $data      = shift;

	unless ($data && $data_type)
	{
		$self -> _error('METHOD:PUT ERROR:data not specified');
		return;
	}
	
	my $request = HTTP::Request -> new();
	$request -> method('PUT');
	$request -> uri($self -> {'url'} . _clear_begining_slash($uri));
	
	my $content;
	my $fh;
	
	if (lc($data_type) eq 'data')
	{	
		$content = $data;
	}
	elsif (lc($data_type) eq 'file')
	{

		my $filename = $data;
		
		open($fh, '<:raw', $filename) or do
		{
			$self -> _error("Can't open file $data for reading");
			return;
		};
		binmode($fh);

		$request -> header('Content-length' => -s $filename);

		$content = sub { return _read_file_cb($fh) };
	}
	elsif (lc($data_type) eq 'fh')
	{
		my $fh = $data;
		my $filesize = (stat($fh))[7];

		binmode($fh);
		
		$request -> header('Content-length' => $filesize);
		
		$content = sub { return _read_file_cb($fh) };
	}
	
	$request -> content($content);

	my $response = $self -> {'ua'} -> request($request);

	unless ($response -> is_success)
	{
		$self -> _error("METHOD:PUT URI:$uri Status:" . $response -> status_line);
		return undef;
	}
	
	return 1;
}

#----------
sub copy
#----------
{
	my $self     = shift;
	my $uri      = shift;
	my $dest_uri = shift;
	my %params = @_;
	
	my $request = HTTP::Request->new();
	$request -> method('COPY');
	$request -> uri($self -> {'url'} . _clear_begining_slash($uri));
	$request -> header('Destination' => $dest_uri);
	
	$request -> header('Depth' => $params{'depth'}) if defined $params{'depth'};
	if (defined $params{'overwrite'})
	{
		$params{'overwrite'} =~ tr/01/FT/;
		$request -> header('Overwrite' => $params{'overwrite'});
	}
		
	my $response = $self -> {'ua'} -> request($request);
	unless ($response -> is_success)
	{
		$self -> _error("METHOD:COPY URI:$uri Status:" . $response -> status_line);
		return undef;
	}
	
	return 1;
}

#---------
sub move
#---------
{
	my $self     = shift;
	my $uri      = shift;
	my $dest_uri = shift;
	my %params = @_;

	my $request = HTTP::Request->new();
	$request -> method('MOVE');
	$request -> uri($self -> {'url'} . _clear_begining_slash($uri));
	$request -> header('Destination' => $dest_uri);
	
	$request -> header('Depth' => $params{'depth'}) if defined $params{'depth'};
	if (defined $params{'overwrite'})
	{
		$params{'overwrite'} =~ tr/01/FT/;
		$request -> header('Overwrite' => $params{'overwrite'});
	}
	my $response = $self -> {'ua'} -> request($request);
	unless ($response -> is_success)
	{
		$self -> _error("METHOD:MOVE URI:$uri Status:" . $response -> status_line);
		return undef;
	}
	
	return 1;
}

#--------------
sub useragent
#--------------
{
	my $self = shift;
	
	return $self -> {'ua'};
}

1;
__END__

=head1 NAME

HTTP::DAV::Nginx - Client library for Nginx WebDAV server 

=head1 SYNOPSIS

  use HTTP::DAV::Nginx;
  
  $dav = HTTP::DAV::Nginx -> new('http://host.org:8080/dav/');
  or
  $dav = HTTP::DAV::Nginx -> new('http://host.org:8080/dav/', die_on_errors => 1);
  
  unless ($dav -> mkcol('/test'))
  {
    print "ERROR:" . $dav -> err;
  }
  
  $dav -> put('/test/123', data => 'Hello');

  $dav -> copy('/test/123', '/test2/12345');
  
  $dav -> move('/test/123', '/test3/123456');
  
  $dav -> delete('/test2/12345');
  
  $ua = $dav -> useragent;

=head1 DESCRIPTION

NGINX "supports" WebDAV by means of a module, but this support is incomplete: 
it only handles the WebDAV methods PUT, DELETE, MKCOL, COPY, and MOVE, 
and leaves the necessary OPTIONS and PROPFIND (and the optional LOCK, UNLOCK, and PROPPATCH) 
methods unimplemented.

This module doesn't uses PROPFIND and OPTIONS commands for work.


=head1 METHODS

=over 4

=item B<new(URI, [PARAMS])>

Create a new HTTP::DAV::Nginx object;

    my $dav = HTTP::DAV::Nginx -> new('http://host.org:8080/dav/');
    or 
    HTTP::DAV::Nginx -> new('http://host.org:8080/dav/', die_on_errors => 1);

PARAMS:

C<die_on_errors> - die if error

C<warn_on_errors> - warn if error

=item B<mkcol(URI)>

creates a new dir at the location specified by the URI

=item B<copy(SRC_URI, DEST_URI)>

creates a duplicate of the source resource identified by URI

    $dav -> copy('/uri', '/uri2');

C<SRC_URI> - source URI

C<DEST_URI> - destination URI

PARAMS:

C<depth> - copy depth (0, infinity)

C<owerwrite> - overwrite existing files (1 - overwrite, 0 - don't)


=item B<move(SRC_URI, DEST_URI, [PARAMS])>

used to move a resource to the location specified by a URI

    $dav -> move('/uri', '/uri2');
    $dav -> move('/uri', '/uri2', overwrite => 1);

C<SRC_URI> - source URI

C<DEST_URI> - destination URI

PARAMS:

C<depth> - move depth (0, infinity)

C<overwrite> - overwrite existing files (1 - overwrite, 0 - don't)

=item B<put(URI, DATA_TYPE =E<gt> DATA)>

used to put data in a new resource specified by a URI

    $dav -> put('/uri', data => 'Hello');
    $dav -> put('/uri', file => '/etc/passwd');
    $dav -> put('/uri', fh => $fh);

DATA_TYPE - type of data:

C<data> - scalar data

C<file> - filename

C<fh> - filehandle

DATA - scalar data or filename or filehandle

=item B<delete(URI, [PARAMS])>

deletes a resource at the specified

    $dav -> delete('/uri');
    $dav -> delete('uri', depth => 'infinity');

=item B<useragent>

return LWP::UserAgent object for custom options (i.e. proxy, cookie etc)

=item B<err>

return last error string

=back

=head1 SEE ALSO

LWP::UserAgent

=head1 AUTHOR

Dmitry Kosenkov, C<< <d.kosenkov AT rambler-co.ru> >>, C<< <junker AT front.ru> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dmitry Kosenkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
