package Apache::MVC;

our $VERSION = '2.121';

use strict;
use warnings;

use URI;
use URI::QueryParam;

use base 'Maypole';
use Maypole::Headers;
use Maypole::Constants;

__PACKAGE__->mk_accessors( qw( ar ) );

our $MODPERL2;
our $modperl_version;

BEGIN {
    $MODPERL2  = ( exists $ENV{MOD_PERL_API_VERSION} and
                        $ENV{MOD_PERL_API_VERSION} >= 2 );
    if ($MODPERL2) {
     eval 'use mod_perl2; $modperl_version = $mod_perl2::VERSION;';
     if ($@) {
      $modperl_version = $Apache2::RequestRec::VERSION;
     }
     require Apache2::RequestIO;
     require Apache2::RequestRec;
     require Apache2::RequestUtil;
     eval 'use Apache2::Const -compile => qw/REDIRECT/;'; # -compile 4 no import
     require APR::URI;
     require HTTP::Body;
    } else {
     eval ' use mod_perl; ';
     require Apache;
     require Apache::Request;
     eval 'use Apache::Constants -compile => qw/REDIRECT/;';
     $modperl_version = 1;
    }

}

=head1 NAME

Apache::MVC - Apache front-end to Maypole

=head1 SYNOPSIS

    package BeerDB;
    use Maypole::Application;

=head1 DESCRIPTION

A mod_perl platform driver for Maypole. Your application can inherit from
Apache::MVC directly, but it is recommended that you use
L<Maypole::Application>.

=head1 INSTALLATION

Create a driver module like the one illustrated in L<Maypole::Application>.

Put the following in your Apache config:

    <Location /beer>
        SetHandler perl-script
        PerlHandler BeerDB
    </Location>

Copy the templates found in F<templates/factory> into the F<beer/factory>
directory off the web root. When the designers get back to you with custom
templates, they are to go in F<beer/custom>. If you need to override templates
on a database-table-by-table basis, put the new template in F<beer/I<table>>.

This will automatically give you C<add>, C<edit>, C<list>, C<view> and C<delete>
commands; for instance, to see a list of breweries, go to

    http://your.site/beer/brewery/list

For more information about how the system works and how to extend it,
see L<Maypole>.

=head1 Implementation

This class overrides a set of methods in the base Maypole class to provide its
functionality. See L<Maypole> for these:

=over

=item get_request

=cut

sub get_request {
    my ($self, $r) = @_;
    my $request_options = $self->config->request_options || {};
    my $ar;
    if ($MODPERL2) {
      $ar = eval {require Apache2::Request} ? Apache2::Request->new($r,%{$request_options}) : $r;
    } else {
      if (keys %$request_options) {
	$ar = Apache::Request->new($r,%{$request_options});
      } else {
	$ar = Apache::Request->instance($r);
      }
    }
    $self->ar($ar);
}

=item warn

=cut

sub warn {
  my ($self,@args) = @_;
  my ($package, $line) = (caller)[0,2];
  my $ar = $self->parent ? $self->parent->{ar} : $self->{ar};
  if ( $args[0] and ref $self ) {
    $ar->warn("[$package line $line] ", @args) ;
  } else {
    print "warn called by ", caller, " with ", @_, "\n";
  }
  return;
}


=item parse_location

=cut

sub parse_location {
    my $self = shift;

    # Reconstruct the request headers
    $self->headers_in(Maypole::Headers->new);

    my %headers;
    if ($MODPERL2) { %headers = %{$self->ar->headers_in};
    } else { %headers = $self->ar->headers_in; }
    for (keys %headers) {
        $self->headers_in->set($_, $headers{$_});
    }

    $self->preprocess_location();

    my $path = $self->ar->uri;
    my $base  = URI->new($self->config->uri_base);
    my $loc = $base->path;

    {
        no warnings 'uninitialized';
        $path .= '/' if $path eq $loc;
	if ($loc =~ /\/$/) {
	  $path =~ s/^($loc)?//;
	} else {
	  $path =~ s/^($loc)?\///;
	}
    }

    $self->path($path);
    $self->parse_path;
    $self->parse_args;
}

=item parse_args

=cut

sub parse_args {
    my $self = shift;
    $self->params( { $self->_mod_perl_args( $self->ar ) } );
    $self->query( $self->params );
}

=item redirect_request

Sets output headers to redirect based on the arguments provided

Accepts either a single argument of the full url to redirect to, or a hash of
named parameters :

$r->redirect_request('http://www.example.com/path');

or

$r->redirect_request(protocol=>'https', domain=>'www.example.com', path=>'/path/file?arguments', status=>'302', url=>'..');

The named parameters are protocol, domain, path, status and url

Only 1 named parameter is required but other than url, they can be combined as
required and current values (from the request) will be used in place of any
missing arguments. The url argument must be a full url including protocol and
can only be combined with status.

=cut

sub redirect_request {
  my $r = shift;
  my $redirect_url = $_[0];
  my $status = $MODPERL2 ? eval 'Apache2::Const::REDIRECT;' : eval 'Apache::Constants::REDIRECT;';
  if ($_[1]) {
    my %args = @_;
    if ($args{url}) {
      $redirect_url = $args{url};
    } else {
      my $path = $args{path} || $r->path;
      my $host = $args{domain} || $r->ar->hostname;
      my $protocol = $args{protocol} || $r->get_protocol;

      $redirect_url = URI->new;
         $redirect_url->scheme($protocol);
         $redirect_url->host($host);
         $redirect_url->path($path);
    }
    $status = $args{status} if ($args{status});
  }

  $r->ar->status($status);
  $r->ar->headers_out->set('Location' => $redirect_url);
  $r->output('<html><head><title>redirecting...</title></head><body><h2>redirecting..</h2></body></html>') unless ($r->output);
  return OK;
}


=item get_protocol

=cut

sub get_protocol {
  my $self = shift;
  my $protocol = ( $self->ar->protocol =~ m/https/i ) ? 'https' : 'http' ;
  return $protocol;
}

=item send_output

=cut

sub send_output {
    my $r = shift;
    $r->ar->content_type(
          $r->content_type =~ m/^text/
        ? $r->content_type . "; charset=" . $r->document_encoding
        : $r->content_type
    );
    $r->ar->headers_out->set(
        "Content-Length" => do { use bytes; length $r->output }
    );

    foreach ($r->headers_out->field_names) {
        next if /^Content-(Type|Length)/;
        $r->ar->headers_out->set($_ => $r->headers_out->get($_));
    }

    $MODPERL2 || $r->ar->send_http_header;
    $r->ar->print( $r->output );
}

=item get_template_root

=cut

sub get_template_root {
    my $r = shift;
    $r->ar->document_root . "/" . $r->ar->location;
}

=back

=cut

#########################################################
# private / internal methods and subs


sub _mod_perl_args {
    my ( $self, $apr ) = @_;
    my %args;
    if ($apr->isa('Apache::Request')) {
      foreach my $key ( $apr->param ) {
        my @values = $apr->param($key);
        $args{$key} = @values == 1 ? $values[0] : \@values;
      }
    } else {
      my $body = $self->_prepare_body($apr);
      %args = %{$body->param};
      my $uri = URI->new($self->ar->unparsed_uri);
      foreach my $key ($uri->query_param) {
	if (ref $args{$key}) {
	  push (@{$args{$key}}, $uri->query_param($key));
	} else {
	  if ($args{$key}) {
	    $args{$key} = [ $args{$key}, $uri->query_param($key) ];
	  } else {
	    my @args = $uri->query_param($key);
	    if (scalar @args > 1) {
	      $args{$key} = [ $uri->query_param($key) ];
	    } else {
	      $args{$key} = $uri->query_param($key);
	    }
	  }
	}
      }
    }
    return %args;
}

sub _prepare_body {
    my ( $self, $r ) = @_;

    unless ($self->{__http_body}) {
        my $content_type   = $r->headers_in->get('Content-Type');
        my $content_length = $r->headers_in->get('Content-Length');
        my $body   = HTTP::Body->new( $content_type, $content_length );
        my $length = $content_length;
        while ( $length ) {
            $r->read( my $buffer, ( $length < 8192 ) ? $length : 8192 );
            $length -= length($buffer);
            $body->add($buffer);
        }
	$self->{__http_body} = $body;
    }
    return $self->{__http_body};
}



=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 CREDITS

Aaron Trevena
Marcus Ramberg, C<marcus@thefeed.no>
Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
