package Devel::ebug::HTTP;

use strict;
use warnings;
use 5.016;
use Mojolicious::Lite;
use File::ShareDir::Dist qw( dist_share );
use PPI;
use PPI::HTML;
use List::Util qw( max );

# ABSTRACT: A web front end to a simple, extensible Perl debugger
our $VERSION = '0.37'; # VERSION

# global for now, sigh
my $codelines_cache;
my $ebug;
my $lines_visible_above_count = 10;
my $sequence = 1;
my $vars;

{
  my $share = dist_share('Devel-ebug-HTTP');

  unless(defined $share)
  {
    $share = -f "share/root/index.html.tt"  # TODO do relative to ebug?
      ? "share"
      : die "unable to find home or root";
  }

  push @{ app->static->paths }, "$share/root";
  push @{ app->renderer->paths }, "$share/root";
}

plugin 'TtRenderer';
app->renderer->default_handler('tt');

app->log->level('fatal');

any '/ajax_variable/:variable' => \&_ajax_variable;
any '/ajax_eval' => \&_ajax_eval;
any '/' => \&_do_the_request;
any '/*whatever' => \&_do_the_request;

sub _ajax_variable {
  my($c) = @_;
  my $variable = $c->stash('variable');
  $variable = '\\' . $variable if $variable =~ /^[%@]/;
  my $value = $ebug->yaml($variable);
  $value =~ s/^--- // unless $variable =~ /^[%@]/;
  $value = "Not defined" if $value =~ /^Global symbol/;
  $value =~ s{\n}{<br/>}g;
  my $xml = qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<response>
  <variable>$variable</variable>
  <value><![CDATA[$value]]></value>
</response>
  };
  $c->res->headers->content_type("text/xml");
  $c->render(data => $xml);
}

sub _ajax_eval {
  my($c) = @_;
  my $eval = $c->req->params->to_hash->{eval};
  my $result = $ebug->eval($eval) || "No output";
  $result =~ s/ at \(eval .+$//;
  $c->res->headers->content_type("text/html");
  $c->render(data => $result);
}

sub _do_the_request {
  my($c) = @_;
  my $params = $c->req->params->to_hash;

  # clear out template variables
  $vars = {};

  # pass commands we've been passed to the ebug
  my $action = lc($params->{myaction} || '');
  _tell_ebug($c, $action);

  # check we're doing things in the right order
  my $cgi_sequence = $params->{sequence};
  if (defined $cgi_sequence && $cgi_sequence < $sequence) {
    $ebug->undo($sequence - $cgi_sequence);
    $sequence = $cgi_sequence;
  }
  $sequence++;

  _set_up_stash($c);

  $c->render(template => 'index');
}

sub _tell_ebug {
  my ($c, $action) = @_;
  my $params = $c->req->params->to_hash;

  if ($ebug->finished &&
     ($action ne "restart") &&
     ($action ne "undo")) {
     return;
  }

  if ($action eq 'break point:') {
    $ebug->break_point($params->{'break_point'});
  } elsif ($action eq 'break_point') {
    $ebug->break_point($params->{line});
  } elsif ($action eq 'break_point_delete') {
    $ebug->break_point_delete($params->{line});
  } if ($action eq 'next') {
    $ebug->next;
  } elsif ($action eq 'restart') {
    $ebug->load;
  } elsif ($action eq 'return') {
    $ebug->return;
  } elsif ($action eq 'run') {
    $ebug->run;
  } if ($action eq 'step') {
    $ebug->step;
  } elsif ($action eq 'undo') {
    $ebug->undo;
  }
}

sub _set_up_stash {
  my($c) = @_;

  my $break_points;
  $break_points->{$_}++ foreach $ebug->break_points;

  my $url = $c->req->url->base->clone;
  $url->path('/');
  $url = $url->to_string;

  my($stdout, $stderr) = $ebug->output;

  my $codelines = _codelines($c);

  $vars = {
    %$vars,
    break_points => $break_points,
    codelines => $codelines,
    ebug => $ebug,
    sequence => $sequence,
    stack_trace_human => [$ebug->stack_trace_human],
    stdout => $stdout,
    stderr => $stderr,
    subroutine => $ebug->subroutine,
    top_visible_line => max(1, $ebug->line - $lines_visible_above_count + 1),
    url => $url,
  };

  $c->stash(%$vars);
}

sub _codelines {
  my($c) = @_;
  my $filename = $ebug->filename;
  return $codelines_cache->{$filename} if exists $codelines_cache->{$filename};

  my $url = $c->req->url->base->clone;
  $url->path('/');
  $url = $url->to_string;
  my $code = join "\n", $ebug->codelines;
  my $document = PPI::Document->new(\$code);
  my $highlight = PPI::HTML->new(line_numbers => 1);
  my $pretty =  $highlight->html($document);

  my $split = '<span class="line_number">';

  # turn significant whitespace into &nbsp;
  my @lines = map {
    $_ =~ s{</span>( +)}{"</span>" . ("&nbsp;" x length($1))}e;
    "$split$_";
  } split /$split/, $pretty;

  # right-justify the line number
  @lines = map {
    s{<span class="line_number"> ?(\d+) ?:}{
      my $line = $1;
      my $size = 4 - (length($1));
      $size = 0 if $size < 0;
      $line = line_html($url, $line);
      '<span class="line_number">' . ("&nbsp;" x $size) . "$line:"}e;
    $_;
  } @lines;

  # add the dynamic tooltips
  @lines = map {
    s{<span class="symbol">(.+?)</span>}{
      '<span class="symbol">' . variable_html($url, $1) . "</span>"
      }eg;
    $_;
  } @lines;

  # make us slightly more XHTML
  $_ =~ s{<br>}{<br/>} foreach @lines;

  # link module names to metacpan
  @lines = map {
    $_ =~ s{<span class="word">([^<]+?::[^<]+?)</span>}{<span class="word"><a href="https://metacpan.org/pod/$1">$1</a></span>};
    $_;
  } @lines;

  $codelines_cache->{$filename} = \@lines;
  return \@lines;
}

sub variable_html {
  my($url, $variable) = @_;
  return qq{<a href="#" style="text-decoration: none" onmouseover="highlight_variable('$variable'); return tooltip('$variable')" onmouseout="unhighlight_variable('$variable'); return nd();">$variable</a>};
}

sub line_html {
  my($url, $line) = @_;
  return qq{<a href="#" style="text-decoration: none" onClick="return break_point($line)">$line</a>};
}

package Devel::ebug::HTTP::App;

sub main {
  my $filename = shift @ARGV;
  die "Usage: ebug_http filename\n" unless $filename;

  require Devel::ebug;
  $ebug = Devel::ebug->new;
  $ebug->program($filename);
  $ebug->load;

  Devel::ebug::HTTP::app->start(@ARGV ? @ARGV : 'daemon');
}

sub ebug {
  my(undef, $new) = @_;
  $ebug = $new if @_ > 1;
  return $ebug;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::ebug::HTTP - A web front end to a simple, extensible Perl debugger

=head1 VERSION

version 0.37

=head1 SYNOPSIS

 ebug_http calc.pl

=head1 DESCRIPTION

A debugger is a computer program that is used to debug other
programs. L<Devel::ebug> is a simple, extensible Perl debugger with a
clean API. L<Devel::ebug::HTTP> is a web-based frontend to L<Devel::ebug> which
presents a simple, pretty way to debug programs. L<ebug_http> is
the command line program to launch the debugger. It will return a URL
which you should point a web browser to.

=head1 SEE ALSO

=over 4

=item L<Devel::ebug>

Simple extensible Perl debugger with clean API.

=item L<ebug_http>

Command-line interface to ebug/http debugger.

=item L<Devel::hdb>

Similar web based debugger for Perl

=back

=head1 AUTHOR

Original author: Leon Brocard E<lt>acme@astray.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2024 by Leon Brocard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
