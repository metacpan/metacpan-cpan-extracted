package HTML::Highlighter;

use strict;
use warnings;

use HTML::Parser;
use Plack::Request;
use Plack::Util::Accessor qw/param callback/;
use List::Util qw/first/;

use parent 'Plack::Middleware';

use 5.008_001;
our $VERSION = "0.05";
$VERSION = eval $VERSION;

sub call {
  my ($self, $env) = @_;

  my $res = $self->app->($env);

  $self->response_cb( $res, sub {
    my $res = shift;
    my $h = Plack::Util::headers($res->[1]);

    my $type = $h->get("Content-Type");
    return $res unless $type and $type =~ /html/i;

    $self->callback->($env) if $self->callback;

    my $req = Plack::Request->new($env);
    $self->param("") unless defined $self->param;

    my $highlights = do {
      if ($env->{'psgix.highlight'}) {
        $env->{'psgix.highlight'};
      } else {
        my $param = first {$req->parameters->{$_}} ($self->param, qw/q query search highlight/);
        $param ? $req->parameters->{$param} : undef;
      }
    };

    return $res unless $highlights;
    my @highlights = split /\s+/, $highlights;

    my $html;
    my $p = HTML::Parser->new(
      api_version => 3,
      handlers => {
        default => [
          sub {
            $html .= $_[0]
          }, "text"
        ],
        text => [
          sub {
            for my $highlight (@highlights) {
              $_[0] =~ s/(\Q$highlight\E)/<span class="highlight">$1<\/span>/gi;
            }
            $html .= $_[0]
          }, "text"
        ],
        end_document => [
          sub {
            $res->[2] = [$html];
            $h->set('Content-Length' => length $html)
          }
        ],
      }
    );

    my $done;

    return sub {
      my $chunk = shift;
      return if $done;

      if (defined $chunk) {
        $p->parse($chunk);
        return '';
      } else {
        $p->eof;
        $done = 1;
        return $html;
      }
    };
  });
}

1;

__END__
=head1 NAME

HTML::Highlighter - PSGI middleware to highlight text in an HTML response

=head1 SYNOPSIS

    use Plack::Builder;
    use HTML::Highlighter;

    # highlight the "search" query param

    builder {
      enable "+HTML::Highlighter", param => "search";
      ...
      $app;
    };

    # or highlight the user stored in session

    builder {
      enable "+HTML::Highlighter", callback => sub {
        my $env = shift;
        $env->{'psgix.highlight'} = $env->{'psgix.session'}{user};
      };
      ...
      $app;
    };

=head1 DESCRIPTION

The C<HTML::Highlighter> module is a piece of PSGI middleware that
will inspect an HTML response and highlight parts of the page based
on a query parameter or other request data. This is very much like
what Google does when you load a page from their cache. Any text
that matches your original query is highlighted.

    <span class="highlight">[matching text]</span>

If no param or callback are provided to C<HTML::Highlighter>, it
will look for commonly used search parameters (e.g. q, query, search,
and highlight.)

This module also includes a javascript file called highlighter.js
which gives you a class with methods to jump (scroll) through the
highlights.

=head1 CONSTRUCTOR PARAMETERS

=over

=item B<param>

This option allows you to specify a query parameter to be used for
the highlighting. For example, if you specify "search" as the param,
each response will look for a query parameter called "search" will
highlight that value in the response.

=item B<callback>

This option lets you specify a function that will be called on each
request to generate the text used for highlighting. The function
will be passed the $env hashref, and should set 'psgix.highlight'
on it. This value will be used for the highlighting. This could be
useful if you want to highlight a username that is stored in a
session, or something similar.

=back

=head1 SEE ALSO

L<Plack::Builder>

L<HTML::Parser>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 Lee Aylward <leedo at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Lee Aylward, <leedo@cpan.org>

=cut
