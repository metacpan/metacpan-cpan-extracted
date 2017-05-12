package HTML::Mason::PlackHandler;
BEGIN {
  $HTML::Mason::PlackHandler::VERSION = '0.103070';
}

use strict;
use warnings;

use HTML::Mason;
use Plack::Request;
use Plack::Response;

use parent qw(Class::Container);

use HTML::Mason::Exceptions;
use HTML::Mason::MethodMaker (    ##
  read_write => [qw( interp document_root special_file )]
);

__PACKAGE__->valid_params(        ##
  interp => {isa => 'HTML::Mason::Interp'},
);

__PACKAGE__->contained_objects(    ##
  interp => 'HTML::Mason::Interp',
);


sub new {
  my $package = shift;
  my %p       = @_;

  my $document_root = delete $p{document_root};
  my $self = $package->SUPER::new(
    comp_root     => $document_root,
    request_class => 'HTML::Mason::Request::Plack',
    error_mode    => 'output',
    error_format  => 'html',
    %p
  );

  my $interp       = $self->interp;
  my %request_args = $interp->delayed_object_params('request');

  my %special;
  $special{$request_args{dhandler_name} || 'dhandler'} = 1;
  $special{$interp->autohandler_name} = 1;
  $self->special_file(\%special);

  $interp->compiler->add_allowed_globals('$res', '$req');

  # If no document root given, use MAIN comp_root or first comp_root
  $document_root ||= do {
    my $comp_root = $interp->comp_root;
    if (ref($comp_root)) {
      my ($droot) = grep { $_->[0] eq 'MAIN' } @$comp_root;
      $droot ||= $comp_root->[0];
      $comp_root = $droot->[1];
    }
    $comp_root;
  };

  $self->document_root($document_root);

  return $self;
}

sub _find_comp {
  my ($self, $env) = @_;

  my $comp_root = $self->document_root;

  my $comp = '';
  my $path_info = $env->{PATH_INFO} || '';
  $path_info =~ s!^([^/])!/$1!;

  while(length $path_info) {
    return ($comp, $path_info) if -f "$comp_root/$comp";
    last unless -d _;
    $path_info =~ s!^(/+[^/]*)!!;
    $comp .= $1;
  }

  return ($env->{PATH_INFO},'');
}


sub handle_request {
  my ($self, $env) = @_;

  my ($comp_path, $path_info) = _find_comp($self, $env);

  local $env->{SCRIPT_NAME} = $env->{SCRIPT_NAME} . $comp_path;
  local $env->{PATH_INFO}   = $path_info;

  my $req    = Plack::Request->new($env);
  my $res    = Plack::Response->new;
  my $interp = $self->interp;

  my @output = ('');
  $res->body(\@output);

  $interp->set_global('$req', $req);
  $interp->set_global('$res', $res);
  $interp->out_method(\$output[0]);

  my %args = %{ $req->parameters };

  $comp_path =~ s!^/*!/!;
  my ($file) = $comp_path =~ m!([^/]+)/*$!;

  my $retval = ($file and $self->special_file->{$file})
    ? 404 
    : eval { $self->interp->exec($comp_path, %args) || 200 };

  if (!defined($retval) and my $err = $@) {
    $retval =
        isa_mason_exception($err, 'Abort') ? $err->aborted_value
      : isa_mason_exception($err, 'Decline') ? $err->declined_value
      :                                        rethrow_exception $err;
  }

  $res->header(Location => $retval->{url})
    if ref($retval) eq 'HTML::Mason::Request::Plack::Redirect';

  my $status = (0 + $retval) || 500;
  my $len = length($output[0]);

  $res->status($status);
  $res->content_length($len);

  return $res->finalize;
}


###########################################################
package HTML::Mason::Request::Plack;
BEGIN {
  $HTML::Mason::Request::Plack::VERSION = '0.103070';
}

use base qw(HTML::Mason::Request);

sub redirect {
  my $self = shift;

  my $url = shift;
  my $status = shift || 302;

  $self->clear_buffer;

  $self->abort(
    bless {
      status => $status,
      url    => $url,
    },
    'HTML::Mason::Request::Plack::Redirect'
  );
}

###########################################################
package HTML::Mason::Request::Plack::Redirect;
BEGIN {
  $HTML::Mason::Request::Plack::Redirect::VERSION = '0.103070';
}

use overload '0+' => sub { shift->{status} }, fallback => 1;

1;

__END__
=head1 NAME

HTML::Mason::PlackHandler - HTML::Mason handler using Plack::Request and Plack::Response

=head1 VERSION

version 0.103070

=head1 SYNOPSIS

  use HTML::Mason::PlackHandler;
  use Plack::Builder;

  my $mason = HTML::Mason::PlackHandler->new(comp_root => $ENV{PWD});

  builder {
    mount "/" => sub {
      my $env = shift;
      $mason->handle_request($env);
    };
  };

=head1 DESCRIPTION

C<HTML::Mason::PlackHandler> will process mason templates making
available a L<Plack::Request> object as C<$req> and a L<Plack::Response>
object as C<$res>. See L<HTML::Mason::Params> for details of
parameters for configuring L<HTML::Mason>

A redirect may be performed by calling C<< $m->redirect($url, $code) >>.
C<$code> will default to C<302> if not specified.

=head1 SEE ALSO

L<HTML::Mason>, L<HTML::Mason::Params>, L<Plack::Request>, L<Plack::Response>

=head1 AUTHOR

Graham Barr <gbarr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Graham Barr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut