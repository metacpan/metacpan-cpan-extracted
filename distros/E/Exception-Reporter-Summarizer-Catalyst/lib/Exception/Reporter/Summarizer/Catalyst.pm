use strict;
use warnings;
package Exception::Reporter::Summarizer::Catalyst 0.005;
use parent 'Exception::Reporter::Summarizer';
# ABSTRACT: a summarizer for Catalyst applications

#pod =head1 OVERVIEW
#pod
#pod If added as a summarizer to an L<Exception::Reporter>, this plugin will
#pod summarize Catalyst objects, adding summaries for the request, stash, errors,
#pod user, and session.
#pod
#pod =attr resolve_hostname
#pod
#pod If true, the summary will include the hostname of the remote client.  Catalyst
#pod I<always> resolves this hostname the first time it's requested and I<never>
#pod accepts it from the server.  That means it might be slow.
#pod
#pod Right now, this defaults to true.  It might default to false later.  Consider
#pod being explicit if you're concerned about this behavior.
#pod
#pod =cut

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

=encoding UTF-8

=head1 NAME

Exception::Reporter::Summarizer::Catalyst - a summarizer for Catalyst applications

=head1 VERSION

version 0.005

=head1 OVERVIEW

If added as a summarizer to an L<Exception::Reporter>, this plugin will
summarize Catalyst objects, adding summaries for the request, stash, errors,
user, and session.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 resolve_hostname

If true, the summary will include the hostname of the remote client.  Catalyst
I<always> resolves this hostname the first time it's requested and I<never>
accepts it from the server.  That means it might be slow.

Right now, this defaults to true.  It might default to false later.  Consider
being explicit if you're concerned about this behavior.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords fREW Schmidt Ricardo Signes

=over 4

=item *

fREW Schmidt <frioux@gmail.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
