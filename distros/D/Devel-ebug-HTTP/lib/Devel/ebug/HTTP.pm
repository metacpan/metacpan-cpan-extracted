package Devel::ebug::HTTP;
use strict;
use warnings;
use Catalyst qw/Static/;
#use Catalyst qw/-Debug Static/;
use Catalyst::View::TT;
use Cwd;
use Devel::ebug;
use HTML::Prototype;
use List::Util qw(max);
use Path::Class;
use PPI;
use PPI::HTML;
use Storable qw(dclone);
our $VERSION = "0.32";

# globals for now, sigh
my $codelines_cache;
our $ebug;
my $lines_visible_above_count = 10;
my $sequence = 1;
my $vars;


Devel::ebug::HTTP->config(
  name => 'Devel::ebug::HTTP',
);

# Catalyst has new template bundling code, but the following is
# necessary for now as our distribution is Devel::ebug but the
# application is Devel::ebug::HTTP (sigh)
my $root = Devel::ebug::HTTP->config->{root};
unless (-d $root) {
  my $home = Devel::ebug::HTTP->config->{home};
  $home = dir($home)->parent;
  $root = dir($home)->subdir('root');
  unless (-d $root) {
    $root = dir($home)->parent->parent->parent->subdir('root');
  }
  Devel::ebug::HTTP->config(
    home => $home,
    root => $root,
  );
}

Devel::ebug::HTTP->setup;

sub default : Private {
  my($self, $c) = @_;
  $c->stash->{template} = 'index';
  $c->forward('do_the_request');
}

sub ajax_variable : Regex('^ajax_variable$') {
  my ($self, $context, $variable) = @_;
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
  $context->response->content_type("text/xml");
  $context->response->output($xml);
}

sub ajax_eval : Regex('^ajax_eval$') {
  my ($self, $context) = @_;
  my $eval = $context->request->parameters->{eval};
  my $result = $ebug->eval($eval) || "No output";
  $result =~ s/ at \(eval .+$//;
  $context->response->content_type("text/html");
  $context->response->output($result);
}

sub css : Regex('(?i)\.(?:css)') {
  my($self, $c) = @_;
  $c->res->headers->header('Cache-Control' => 'max-age=60');
  $c->serve_static("text/css");
}

sub js : Regex('(?i)\.(?:js)') {
   my($self, $c) = @_;
   $c->res->headers->header('Cache-Control' => 'max-age=60');
   $c->serve_static("application/x-javascript");
}

sub ico : Regex('(?i)\.(?:ico)') {
  my($self, $c) = @_;
  $c->res->headers->header('Cache-Control' => 'max-age=60');
  $c->serve_static("image/vnd.microsoft.icon");
}

sub images : Regex('(?i)\.(?:gif|jpg|png)') {
  my($self, $c) = @_;
  $c->res->headers->header('Cache-Control' => 'max-age=60');
  $c->serve_static;
}

sub end : Private {
  my($self, $c) = @_;
  if ($c->stash->{template}) {
    $c->response->content_type("text/html");
    $c->forward('Devel::ebug::HTTP::View::TT');
  }
}

sub do_the_request : Private {
  my($self, $c) = @_;
  my $params = $c->request->parameters;

  # clear out template variables
  $vars = {};

  # pass commands we've been passed to the ebug
  my $action = lc($params->{myaction} || '');
  tell_ebug($c, $action);

  # check we're doing things in the right order
  my $cgi_sequence = $params->{sequence};
  if (defined $cgi_sequence && $cgi_sequence < $sequence) {
    $ebug->undo($sequence - $cgi_sequence);
    $sequence = $cgi_sequence;
  }
  $sequence++;

  set_up_stash($c);
}

sub tell_ebug {
  my ($c, $action) = @_;
  my $params = $c->request->parameters;
  
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

sub set_up_stash {
  my($c) = @_;
  my $params = $c->request->parameters;

  my $break_points;
  $break_points->{$_}++ foreach $ebug->break_points;

  my $url = $c->request->base;

  my($stdout, $stderr) = $ebug->output;

  my $codelines = codelines($c);

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

  foreach my $k (keys %$vars) {
    $c->stash->{$k} = $vars->{$k};
  }
}

sub codelines {
  my($c) = @_;
  my $filename = $ebug->filename;
  return $codelines_cache->{$filename} if exists $codelines_cache->{$filename};

  my $url = $c->request->base;
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

  # link module names to search.cpan.org
  @lines = map {
    $_ =~ s{<span class="word">([^<]+?::[^<]+?)</span>}{<span class="word"><a href="http://search.cpan.org/perldoc?$1">$1</a></span>};
    $_;
  } @lines;

  $codelines_cache->{$filename} = \@lines;
  return \@lines;
}

sub variable_html {
  my($url, $variable) = @_;
  return qq{<a href="#" style="text-decoration: none" onmouseover="return tooltip('$variable')" onmouseout="return nd();">$variable</a>};
}

sub line_html {
	my($url, $line) = @_;
	return qq{<a href="#" style="text-decoration: none" onClick="return break_point($line)">$line</a>};
}

1;

__END__

=head1 NAME

Devel::ebug::HTTP - A web front end to a simple, extensible Perl debugger

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

L<Devel::ebug>, L<ebug_http>

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
