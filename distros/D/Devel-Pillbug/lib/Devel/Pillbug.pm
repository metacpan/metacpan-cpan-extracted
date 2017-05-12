package Devel::Pillbug::MasonHandler;

use strict;
use warnings;

use base qw| HTML::Mason::CGIHandler |;

### CGIHandler evals stuff before we can check on the result code,
### which can make it hard or impossible to trap specific errors.
###
### Avoid this by delegating to H~::M~::Request's exec method instead.
sub exec {
  my $self = shift;

  return HTML::Mason::Request::exec( $self, @_ );
}

package Devel::Pillbug;

our $VERSION = 0.006;

use strict;
use warnings;

use File::HomeDir;
use Media::Type::Simple;

### Media::Type::Simple's internal use of a cached filehandle makes
### it not usable when forking, and its internal use of private globals
### makes it hard to subclass.
###
### Sadly, Media::Type::Simple is currently the best thing going on CPAN
### in terms of guessing MIME types from file extensions, so... until
### its author applies a fix for this very common problem (or something
### better comes along), I am adapting Jos Boumans's workaround from
### rt.cpan.org #46474:
do {
  no strict "refs";

  *{"Media::Type::Simple::__new"} = sub {
    my $class = shift;
    my $self = { types => {}, extens => {}, };

    bless $self, $class;

    if (@_) {
      my $fh = shift;
      return $self->add_types_from_file($fh);
    } else {
      my $offset = tell Media::Type::Simple::DATA;

      $Media::Type::Simple::Default =
        $self->add_types_from_file( \*Media::Type::Simple::DATA );

      seek Media::Type::Simple::DATA, $offset, 0;

      return clone $Media::Type::Simple::Default;
    }
    }
};

use base qw| HTTP::Server::Simple::Mason |;

use constant DefaultServerType   => "Net::Server::PreFork";
use constant DefaultHandlerClass => "Devel::Pillbug::MasonHandler";

use constant DefaultIndexName => "index";
use constant DefaultCompExt   => "html";

our $serverType   = DefaultServerType;
our $handlerClass = DefaultHandlerClass;

#
#
#
sub net_server {
  my $class         = shift;
  my $newServerType = shift;

  if ($newServerType) {
    if ( !UNIVERSAL::isa( $newServerType, "Net::Server" ) ) {
      warn "net_server() requires a Net::Server subclass";
    }

    $serverType = $newServerType;
  }

  return $serverType;
}

#
#
#
sub handler_class {
  my $class           = shift;
  my $newHandlerClass = shift;

  if ($newHandlerClass) {
    if ( !UNIVERSAL::isa( $newHandlerClass, "HTML::Mason::Request" ) ) {
      warn "handler_class() requires a HTML::Mason::Request subclass";
    }

    $handlerClass = $newHandlerClass;
  }

  return $handlerClass;
}

#
#
#
sub pretty_html_header {
  my $self   = shift;
  my $header = shift;

  if ($header) {
    $self->{_html_header} = $header;

    return;
  }

  if ( defined $self->{_html_header} ) {
    print $self->{_html_header};

    return;
  }

  print "<html>\n";
  print "<head>\n";
  print "<style>\n";
  print "  body {\n";
  print "    background: #fff; color: #333;\n";
  print "  }\n";
  print "  body, td {\n";
  print "    font-family: verdana, sans-serif;\n";
  print "    font-size: 11px;\n";
  print "  }\n";
  print "  td {\n";
  print "    border-bottom: 1px dotted #999;\n";
  print "  }\n";
  print "  h1 {\n";
  print "    color: #999;\n";
  print "  }\n";
  print "  pre {\n";
  print "    white-space: pre-wrap;\n";
  print "    background: #ccc; color: #000;\n";
  print "    margin: 6px; padding: 6px;\n";
  print "  }\n";
  print "</style>\n";
  print "</head>\n";
  print "<body>\n";
}

#
#
#
sub pretty_html_footer {
  my $self   = shift;
  my $footer = shift;

  if ($footer) {
    $self->{_html_footer} = $footer;

    return;
  }

  if ( $self->{_html_footer} ) {
    print $self->{_html_footer};

    return;
  }

  my @time = localtime();
  my $time = sprintf(
    '%i-%02d-%02d %02d:%02d:%02d %s',
    $time[5] + 1900,
    $time[4] + 1,
    $time[3], $time[2], $time[1], $time[0], POSIX::strftime( '%Z', @time )
  );

  print "<p>$time</p>\n";
  print "</body>\n";
  print "</html>\n";
}

#
#
#
sub docroot {
  my $self    = shift;
  my $docroot = shift;

  $self->{_docroot} = $docroot if $docroot;

  if ( !$self->{_docroot} ) {
    my $home = File::HomeDir->my_home;

    my $pubHtml = join "/", $home, "public_html";
    my $sites   = join "/", $home, "Sites";

    $self->{_docroot} = ( -d $sites ) ? $sites : $pubHtml;
  }

  if ( !-d $self->{_docroot} ) {
    warn "docroot $self->{_docroot} is not a usable directory";
  }

  return $self->{_docroot};
}

#
#
#
sub allow_index {
  my $self = shift;

  $self->{_allow_index} ||= 0;

  if ( scalar(@_) ) {
    $self->{_allow_index} = $_[0] ? 1 : 0;
  }

  return $self->{_allow_index};
}

#
#
#
sub index_name {
  my $self  = shift;
  my $index = shift;

  $self->{_index} = $index if $index;

  $self->{_index} ||= DefaultIndexName;

  return $self->{_index};
}

#
#
#
sub comp_ext {
  my $self = shift;
  my $ext  = shift;

  $self->{_ext} = $ext if $ext;

  $self->{_ext} ||= DefaultCompExt;

  return $self->{_ext};
}

#
#
#
sub mason_config {
  my $self = shift;

  return ( comp_root => $self->docroot() );
}

#
#
#
sub _handle_mason_request {
  my $self = shift;
  my $cgi  = shift;
  my $path = shift;

  my $r = HTML::Mason::FakeApache->new( cgi => $cgi );
  my $buffer;

  ###
  ### Brutal and tempoorary workaround for undef warnings caused
  ### by anonymous components calling other components.
  ###
  ### https://rt.cpan.org/Public/Bug/Display.html?id=55159
  do {
    no strict "refs";
    no warnings "redefine";

    *{"HTML::Mason::Component::dir_path"} = sub { return "" };
  };

  eval {
    my $m = $self->mason_handler;

    my $comp = $m->interp->make_component( comp_file => $path );

    my $req = $m->interp->make_request(
      comp         => $comp,
      args         => [ $cgi->Vars ],
      cgi_request  => $r,
      out_method   => \$buffer,
      error_mode   => "fatal",
      error_format => "text",
    );

    $r->{http_header_sent} = 1;

    $m->interp->set_global( '$r', $r );

    $req->exec;
  };

  #
  #
  #
  if ( $@ && ( !$r->status || ( $r->status !~ /^302/ ) ) ) {
    $r->status("500 Internal Server Error");

    return $self->_handle_error( $r, $@ );
  } elsif ( !$r->status ) {
    $r->status("200 OK");
  }

  #
  #
  #
  my $header = $r->http_header;
  $header =~ s|^Status:|HTTP/1.0|;

  print $header;

  print $buffer if $buffer;
}

sub _handle_directory_request {
  my $self = shift;
  my $r    = shift;

  my $fsPath   = shift;
  my $compPath = shift;

  print "HTTP/1.0 200 OK\r\n";
  print "Content-Type: text/html\r\n";
  print "\r\n";

  $self->pretty_html_header();

  print "<h1>Index of $compPath</h1>\n";

  print "<table width=\"100%\" cellspacing=\"0\" cellpadding=\"2\">\n";
  print "  <tr>\n";
  print "    <td>Name</td>\n";
  print "    <td>Type</td>\n";
  print "    <td>Last Modified</td>\n";
  print "    <td>Size</td>\n";
  print "  </tr>\n";

  my %conf = $self->mason_config;

  my @files;

  if ( $compPath ne "/" ) { push @files, ".." }

  for (<$fsPath/*>) { push @files, $_ }

  for (@files) {
    my $path = $_;

    my @stat = stat($path);

    my $type;
    my $size;

    if ( -d $path ) {
      $path .= '/';
      $type = "directory";
      $size = "-";
    } else {
      my $ext = $path;
      $ext =~ s/.*\.//;
      my $o = Media::Type::Simple->__new();
      eval { $type = $o->type_from_ext($ext); };
      $type ||= "application/octet-stream";
      $size = $stat[7];
    }

    $path =~ s/^$conf{comp_root}$compPath\///;

    my @time = localtime( $stat[9] );
    my $time = sprintf(
      '%i-%02d-%02d %02d:%02d:%02d %s',
      $time[5] + 1900,
      $time[4] + 1,
      $time[3], $time[2], $time[1], $time[0], POSIX::strftime( '%Z', @time )
    );

    print "  <tr>\n";
    print "    <td><a href=\"$path\">$path</a></td>\n";
    print "    <td>$type</td>\n";
    print "    <td>$time</td>\n";
    print "    <td>${ size }</td>\n";
    print "  </tr>\n";
  }

  print "</table>\n";

  $self->pretty_html_footer();
}

sub _handle_document_request {
  my $self = shift;
  my $r    = shift;

  my $fsPath   = shift;
  my $compPath = shift;

  my $ext = $fsPath;
  $ext =~ s/.*\.//;
  my $o = Media::Type::Simple->__new();
  my $type;
  eval { $type = $o->type_from_ext($ext); };
  $type ||= "application/octet-stream";

  my @out;

  eval {
    open( IN, "<", $fsPath ) || die $!;
    while (<IN>) { push @out, $_ }
    close(IN);
  };

  if ($@) {
    return $self->_handle_error( $r, $@ );
  }

  print "HTTP/1.0 200 OK\r\n";
  print "Content-Type: $type\r\n";
  print "\r\n";

  while (@out) { print shift @out }
}

sub _handle_notfound_request {
  my $self = shift;
  my $r    = shift;

  my $fsPath   = shift;
  my $compPath = shift;

  print "HTTP/1.0 404 Not Found\r\n";
  print "Content-Type: text/html\r\n";
  print "\r\n";

  $self->pretty_html_header();

  print "<h1>Not Found</h1>\n";
  print "<p>The requested URL $compPath was not found on this server.\n";

  $self->pretty_html_footer();
}

sub _handle_error {
  my $self = shift;
  my $r    = shift;

  my $err = shift;

  # $err =~ s/at \S+ line \d+.*//;

  $err = HTML::Entities::encode_entities($err);

  print "HTTP/1.0 500 Internal Server Error\r\n";
  print "Content-type: text/html\r\n";
  print "\r\n";

  $self->pretty_html_header();

  print "<h1>Internal Server Error</h1>\n";
  print "<p>The server could not complete your request. The error was:</p>\n";
  print "<pre>$err</pre>\n";

  $self->pretty_html_footer();
}

sub _handle_directory_redirect {
  my $self     = shift;
  my $compPath = shift;

  my $url = sprintf 'http://%s:%s%s/', $self->host, $self->port, $compPath;

  print "HTTP/1.0 302 Moved\r\n";
  print "Location: $url\r\n";
  print "\r\n";

  $self->pretty_html_header();

  print "<h1>Moved</h1>\n";
  print "<p>The document is available <a href=\"$url\">here</a>.</p>\n";

  $self->pretty_html_footer();
}

#
# Override HTTP::Server::Simple::Mason to also deal with document requests,
# directory listings, and 404s
#
sub handle_request {
  my $self = shift;
  my $r    = shift;

  local $@;

  my %conf = $self->mason_config;
  my $m    = $self->mason_handler;

  my $compPath = $r->path_info;
  my $fsPath = join "", $conf{comp_root}, $compPath;

  my $ext = $self->comp_ext;

  my $indexFilename = join ".", $self->index_name, $ext;

  if ( -d $fsPath
    && $compPath !~ m{/$}
    && ( -e join( "/", $fsPath, $indexFilename ) || $self->allow_index ) )
  {
    return $self->_handle_directory_redirect($compPath);

  } elsif ( -d $fsPath ) {
    my $indexPath = join "/", $fsPath, $indexFilename;

    if ( -e $indexPath ) {
      $compPath .= $indexFilename;
      $fsPath   .= $indexFilename;

      $r->path_info($compPath);
    }
  }

  eval {
    if ( $compPath =~ /$ext$/ && $m->interp->comp_exists($compPath) )
    {
      $self->_handle_mason_request( $r, $fsPath, $compPath );

    } elsif ( $self->allow_index && -d $fsPath ) {
      $self->_handle_directory_request( $r, $fsPath, $compPath );

    } elsif ( !-d $fsPath && -e $fsPath ) {
      $self->_handle_document_request( $r, $fsPath, $compPath );

    } else {
      $self->_handle_notfound_request( $r, $fsPath, $compPath );

    }
  };

  if ($@) {
    warn $@;
  }
}

1;
__END__

=pod

=head1 NAME

Devel::Pillbug - Stand-alone HTML::Mason-enabled server

=head1 SYNOPSIS

Install Devel::Pillbug:

  > perl -MCPAN -e 'install Devel::Pillbug';

Start Devel::Pillbug:

  > pillbug;

All arguments are optional:

  > pillbug -host example.com -port 8080 -docroot /tmp/foo

Do it in Perl:

  use Devel::Pillbug;

  my $port = 8000; # Optional argument, default is 8080

  my $server = Devel::Pillbug->new($port);

  #
  # Optional: Use methods from HTTP::Server::Simple
  #
  # $server->host("example.com");

  #
  # Optional: Override the document root
  #
  # $server->docroot("/tmp/foo");

  #
  # See docs or "pillbug -h" for further options
  #

  $server->run;

=head1 DESCRIPTION

Devel::Pillbug is a stand-alone L<HTML::Mason> server, extending
L<HTTP::Server::Simple::Mason>. It is designed for zero configuration
and easy install from CPAN.

The "public_html" or "Sites" directory of the user who launched the
process will be used for the default document root. Files ending
in "html" are treated as Mason components. These and other behaviors
may be overridden as needed.

=head1 METHODS

See L<HTTP::Server::Simple> and L<HTTP::Server::Simple::Mason> for
inherited methods.

=head2 CLASS METHODS

=over 4

=item * $class->net_server($newServerType)

Returns the currently active L<Net::Server> subclass.

Sets the server type to the specified Net::Server subclass, if one
is supplied as an argument.

Default value is L<Net::Server::PreFork>.

=item * $class->handler_class($newHandlerClass)

Returns the currently active L<HTML::Mason::Request> subclass.

Sets the server type to the specified HTML::Mason::Request subclass,
if supplied as an argument.

Default value is L<Devel::Pillbug::MasonHandler>.

=back

=head2 INSTANCE METHODS

=over 4

=item * $self->docroot($docroot)

Returns the currently active docroot.

The server will set its docroot to the received absolute path, if
supplied as an argument.

=item * $self->index_name($name)

Returns currently used index name, without extension (default is
"index").

Sets this to the received name, if supplied as an argument.

=item * $self->comp_ext($extension)

Sets the file extension used for Mason components (default is "html")

=item * $self->allow_index($bool)

Returns the current allowed state for directory indexes.

Sets this to the received state, if supplied as an argument.

0 = Off, 1 = On

=item * $self->pretty_html_header($fragment)

Prints the HTML fragment used for everything up to and including
the "<body>" tag of internally-generated documents (errors and
directory listings).

Sets the fragment to the received string, if supplied as an argument.

=item * $self->pretty_html_footer($fragment)

Prints the HTML fragment used for everything below and including
the "</body>" tag of internally-generated documents.

Sets the fragment to the received string, if supplied as an argument.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The document root must exist and be readable, and Devel::Pillbug
must be able to bind to its listen port (default 8080).

=head1 BUGS

Absolutely...

Currently, several brutish hacks are employed to work around minor
issues in modules which Pillbug needs. These hacks will need to go
away and/or be revisited over time.

Please use the CPAN RT system or contact me if you find something
which isn't working as advertised.

=head1 VERSION

This document is for version .006 of Devel::Pillbug.

=head1 AUTHOR

Alex Ayars <pause@nodekit.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Alex Ayars <pause@nodekit.org>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.10.0 or later. See:
http://dev.perl.org/licenses/

=head1 SEE ALSO

L<File::HomeDir>, L<Media::Type::Simple>, L<Net::Server::PreFork>.

This module extends L<HTTP::Server::Simple::Mason>.

=cut
