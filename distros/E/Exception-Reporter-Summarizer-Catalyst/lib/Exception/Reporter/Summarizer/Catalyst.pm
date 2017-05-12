use strict;
use warnings;
package Exception::Reporter::Summarizer::Catalyst;
{
  $Exception::Reporter::Summarizer::Catalyst::VERSION = '0.004';
}
use parent 'Exception::Reporter::Summarizer';
# ABSTRACT: a summarizer for Catalyst applications


use Try::Tiny;

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};

  return bless { resolve_hostname => !! $arg->{resolve_hostname} } => $class;
}

sub resolve_hostname { $_[0]->{resolve_hostname} }

sub can_summarize {
  my ($self, $entry) = @_;
  return try { $entry->[1]->isa('Catalyst') };
}

sub summarize {
  my ($self, $entry) = @_;
  my ($name, $c, $arg) = @$entry;

  my @summaries = ({
    filename => 'catalyst.txt',
    %{ 
      $self->dump(
        {
          class   => (ref $c),
          version => $c->VERSION,
        },
        { basename => 'catalyst' },
      )  
    },

    ident => 'Catalyst application ' . (ref $c),
  });

  push @summaries, $self->summarize_request($c);
  # push @summaries, $self->summarize_response($c);
  push @summaries, $self->summarize_stash($c);
  push @summaries, $self->summarize_errors($c);

  push @summaries, $self->summarize_user($c);
  push @summaries, $self->summarize_session($c);

  return @summaries;
}

sub summarize_request {
  my ($self, $c) = @_;
  my $req = $c->req;

  my $cookie_hash = $req->cookies;
  my %cookie_str = map {; $_ => $cookie_hash->{$_}->value } keys %$cookie_hash;

  my $to_dump = {
    action           => $req->action,
    address          => $req->address,
    arguments        => $req->arguments,
    body_parameters  => $req->body_parameters,
    cookies          => \%cookie_str,
    headers          => $req->headers,
    method           => $req->method,
    query_parameters => $req->query_parameters,
    uri              => "" . $req->uri,
    uploads          => $req->uploads,
    path             => $req->path,

    ($self->resolve_hostname ? (hostname => $req->hostname) : ()),
  };

  return {
    filename => 'request.txt',
    %{ $self->dump($to_dump, { basename => 'request' })  },
    ident    => 'catalyst request',
  };
}

sub summarize_response {
  my ($self, $c) = @_;
  Carp::confess("...unimplemented...");
  my $res = $c->res;
  return {
    filename => 'response.txt',
    %{ $self->dump($res, { basename => 'response' })  },
    ident    => 'catalyst response',
  };
}

sub summarize_stash {
  my ($self, $c) = @_;
  my $stash = $c->stash;
  return {
    filename => 'stash.txt',
    %{ $self->dump($stash, { basename => 'stash' })  },
    ident    => 'catalyst stash',
  };
}

sub summarize_errors {
  my ($self, $c) = @_;
  my $errors = $c->error;
  return unless @$errors;
  return {
    filename => 'errors.txt',
    %{ $self->dump($errors, { basename => 'errors' })  },
    ident    => 'catalyst errors',
  };
}

sub summarize_user {
  my ($self, $c) = @_;
  return unless $c->can('user');

  my $user = $c->user;
  return {
    filename => 'user.txt',
    %{ $self->dump($user, { basename => 'user' })  },
    ident    => 'authenticated catalyst user',
  };
}

sub summarize_session {
  my ($self, $c) = @_;
  return unless $c->can('session');

  my $session = $c->session;
  return {
    filename => 'session.txt',
    %{ $self->dump($session, { basename => 'session' })  },
    ident    => 'catalyst session',
  };
}

1;

__END__

=pod

=head1 NAME

Exception::Reporter::Summarizer::Catalyst - a summarizer for Catalyst applications

=head1 VERSION

version 0.004

=head1 OVERVIEW

If added as a summarizer to an L<Exception::Reporter>, this plugin will
summarize Catalyst objects, adding summaries for the request, stash, errors,
user, and session.

=head1 ATTRIBUTES

=head2 resolve_hostname

If true, the summary will include the hostname of the remote client.  Catalyst
I<always> resolves this hostname the first time it's requested and I<never>
accepts it from the server.  That means it might be slow.

Right now, this defaults to true.  It might default to false later.  Consider
being explicit if you're concerned about this behavior.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
