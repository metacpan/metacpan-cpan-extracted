package CGI::Maypole;
use base 'Maypole';

use strict;
use warnings;
use CGI::Simple;
use Maypole::Headers;
use Maypole::Constants;

our $VERSION = '2.13';

__PACKAGE__->mk_accessors( qw/cgi/ );

=head1 NAME

CGI::Maypole - CGI-based front-end to Maypole

=head1 SYNOPSIS

     package BeerDB;
     use Maypole::Application;

     ## example beer.cgi:

     #!/usr/bin/perl -w
     use strict;
     use BeerDB;
     BeerDB->run();

Now to access the beer database, type this URL into your browser:
http://your.site/cgi-bin/beer.cgi/frontpage

NOTE: this Maypole frontend requires additional modules that won't be installed
or included with Maypole. Please see below.

=head1 DESCRIPTION

This is a CGI platform driver for Maypole. Your application can inherit from
CGI::Maypole directly, but it is recommended that you use
L<Maypole::Application>.

This module requires CGI::Simple which you will have to install yourself via
CPAN or manually.

=head1 METHODS

=over

=item run

Call this from your CGI script to start the Maypole application.

=back

=cut

sub run  {
  my $self = shift;
  my $status = $self->handler;
  if ($status != OK) {
    print <<EOT;
Status: 500 Maypole application error
Content-Type: text/html

<title>Maypole application error</h1>
<h1>Maypole application error</h1>
EOT
  }
  return $status;
}

=head1 Implementation

This class overrides a set of methods in the base Maypole class to provide it's
functionality. See L<Maypole> for these:

=over

=item get_request

=cut

sub get_request {
  my $self = shift;
  my $request_options = $self->config->request_options || {};
  $CGI::Simple::POST_MAX = $request_options->{POST_MAX} if ($request_options->{POST_MAX});
  $self->cgi( CGI::Simple->new );
}

=item parse_location

=cut

sub parse_location 
{
    my $r = shift;
    my $cgi = $r->cgi;

    # Reconstruct the request headers (as far as this is possible)
    $r->headers_in(Maypole::Headers->new);
    for my $http_header ($cgi->http) {
        (my $field_name = $http_header) =~ s/^HTTPS?_//;
        $r->headers_in->set($field_name => $cgi->http($http_header));
    }

    $r->preprocess_location();

    my $path = $cgi->url( -absolute => 1, -path_info => 1 );
    my $loc = $cgi->url( -absolute => 1 );
    {
        no warnings 'uninitialized';
        $path .= '/' if $path eq $loc;
	if ($loc =~ /\/$/) {
	  $path =~ s/^($loc)?//;
	} else {
	  $path =~ s/^($loc)?\///;
	}
    }
    $r->path($path);
    
    $r->parse_path;
    $r->parse_args;
}

=item warn

=cut

sub warn {
    my ($self,@args) = @_;
    my ($package, $line) = (caller)[0,2];
    warn "[$package line $line] ", @args ;
    return;
}

=item parse_args

=cut

sub parse_args 
{
    my $r = shift;
    my (%vars) = $r->cgi->Vars;
    while ( my ( $key, $value ) = each %vars ) {
        my @values = split "\0", $value;
        $vars{$key} = @values <= 1 ? $values[0] : \@values;
    }
    $r->params( {%vars} );
    $r->query( $r->params );
}

=item redirect_request

=cut

# FIXME: use headers_in to gather host and other information?
sub redirect_request 
{
  my $r = shift;
  my $redirect_url = $_[0];
  my $status = "302";
  if ($_[1]) {
    my %args = @_;
    if ($args{url}) {
      $redirect_url = $args{url};
    } else {
      my $path = $args{path} || $r->cgi->url(-absolute => 1, -query=>1);
      my $host = $args{domain};
      ($host = $r->cgi->url(-base => 1)) =~ s/^https?:\/\///i unless ($host);
      my $protocol = $args{protocol} || $r->get_protocol;
      $redirect_url = "${protocol}://${host}/${path}";
    }
    $status = $args{status} if ($args{status});
  }

  $r->headers_out->set('Status' => $status);
  $r->headers_out->set('Location' => $redirect_url);

  return;
}

=item get_protocol

=cut

sub get_protocol 
{
  my $self = shift;
  my $protocol = ($self->cgi->https) ? 'https' : 'http';
  return $protocol;
}

=item send_output

Generates output (using C<collect_output>) and prints it. 

=cut

sub send_output 
{
    my $r = shift;
    print $r->collect_output;
}

=item collect_output

Gathers headers and output together into a string and returns it.

Splitting this code out of C<send_output> supports L<Maypole::HTTPD::Frontend>.

=cut

sub collect_output
{
    my $r = shift;
    
    # Collect HTTP headers
    my %headers = (
        -type            => $r->content_type,
        -charset         => $r->document_encoding,
        -content_length  => do { use bytes; length $r->output },
    );
    foreach ($r->headers_out->field_names) {
        next if /^Content-(Type|Length)/;
        $headers{"-$_"} = $r->headers_out->get($_);
    }

    return $r->cgi->header(%headers) . $r->output;
}

=item get_template_root

=cut

sub get_template_root {
    my $r = shift;
    $r->cgi->document_root . "/" . $r->cgi->url( -relative => 1 );
}

1;


=back

=head1 DEPENDANCIES

CGI::Simple

=head1 AUTHORS

Dave Ranney C<dave@sialia.com>

Simon Cozens C<simon@cpan.org>

=cut
