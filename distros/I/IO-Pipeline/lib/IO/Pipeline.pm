package IO::Pipeline;

use strict;
use warnings FATAL => 'all';
use 5.008001;
use Scalar::Util qw(blessed);
use IO::Handle;
use Exporter ();

our @ISA = qw(Exporter);

our @EXPORT = qw(pmap pgrep psink);

our $VERSION = '0.009002'; # 0.9.2

$VERSION = eval $VERSION;

sub import {
  warnings->unimport('void');
  shift->export_to_level(1, @_);
}

sub pmap (&) { IO::Pipeline->from_code_map($_[0]) }
sub pgrep (&) { IO::Pipeline->from_code_grep($_[0]) }
sub psink (&) { IO::Pipeline->from_code_sink($_[0]) }

use overload
  '|' => '_pipe_operator',
  fallback => 1;

sub IO::Pipeline::CodeSink::print {
  my $code = (shift)->{code};
  foreach my $line (@_) {
    local $_ = $line;
    $code->($line);
  }
}

sub from_code_map {
  bless({ map => [ $_[1] ] }, $_[0]);
}

sub from_code_grep {
  my ($class, $grep) = @_;
  $class->from_code_map(sub { $grep->($_) ? ($_) : () });
}

sub from_code_sink {
  bless({ code => $_[1] }, 'IO::Pipeline::CodeSink');
}

sub _pipe_operator {
  my ($self, $other, $reversed) = @_;
  if (blessed($other) && $other->isa('IO::Pipeline')) {
    my ($left, $right) = $reversed ? ($other, $self) : ($self, $other);
    my %new = (map => [ @{$left->{map}}, @{$right->{map}} ]);
    die "Right hand side has a source, makes no sense"
      if $right->{source};
    $new{source} = $left->{source} if $left->{source};
    die "Left hand side has a sink, makes no sense"
      if $left->{sink};
    $new{sink} = $right->{sink} if $right->{sink};
    return bless(\%new, ref($self));
  } else {
    my ($is, $isnt) = $reversed ? qw(source sink) : qw(sink source);
    if (my $fail = $self->{$is}) {
      die "Tried to add ${is} ${other} but we already had ${fail}";
    }
    my $new = bless({ $is => $other, %$self }, ref($self));
    if ($new->{$isnt}) {
      $new->run;
      return;
    } else {
      return $new;
    }
  }
}

sub run {
  my ($self) = @_;
  my $source = $self->{source};
  my $sink = $self->{sink};
  LINE: while (defined(my $line = $source->getline)) {
    my @lines = ($line);
    foreach my $map (@{$self->{map}}) {
      @lines = map $map->($_), @lines;
      next LINE unless @lines;
    }
    $sink->print(@lines);
  }
}

=head1 NAME

IO::Pipeline - map and grep for filehandles, unix pipe style

=head1 SYNOPSIS

  my $source = <<'END';
  2010-03-21 16:15:30 1NtNoI-000658-6V Completed
  2010-03-21 16:17:29 1NtNlx-00062B-0R Completed
  2010-03-21 16:20:37 1NtNtF-0006AE-G6 Completed
  2010-03-21 16:28:37 no host name found for IP address 218.108.42.254
  2010-03-21 16:28:51 H=(ZTZUWWCRQY) [218.108.42.254] F=<pansiesyd75@setupper.com> rejected RCPT <inline@trout.me.uk>: rejected because 218.108.42.254 is in a black list at zen.spamhaus.org 
  2010-03-21 16:28:51 unexpected disconnection while reading SMTP command from (ZTZUWWCRQY) [218.108.42.254] (error: Connection reset by peer)
  2010-03-21 16:35:57 no host name found for IP address 123.122.231.66
  2010-03-21 16:35:59 H=(LFMTSDM) [123.122.231.66] F=<belladonnai6@buybuildanichestore.com> rejected RCPT <tal@fyrestorm.co.uk>: rejected because 123.122.231.66 is in a black list at zen.spamhaus.org
  END 
  
  open my $in, '<', \$source
    or die "Failed to create filehandle from scalar: $!";
  
  my $out;
  
  $in
    | pmap { [ /^(\S+) (\S+) (.*)$/ ] }
    | pgrep { $_->[2] =~ /rejected|Completed/ }
    | pmap { [ @{$_}[0, 1], $_->[2] =~ /rejected/ ? 'Rejected' : 'Completed' ] }
    | pmap { join(' ', @$_)."\n" }
    | psink { $out .= $_ };
  
  print $out;

will print:

  2010-03-21 16:15:30 Completed
  2010-03-21 16:17:29 Completed
  2010-03-21 16:20:37 Completed
  2010-03-21 16:28:51 Rejected
  2010-03-21 16:35:59 Rejected

=head1 DESCRIPTION

IO::Pipeline was born of the idea that I really like writing map/grep type
expressions in perl, but writing:

  map { ... } <$fh>;

does a slurp of the filehandle, and when processing big log files I tend
to Not Want That To Happen. Plus, map restricts us to right-to-left processing
and I've always been fond of the shell metaphor of connecting commands
together left-to-read in a pipeline.

So, this module was born.

  use IO::Pipeline;

will export three functions - L</pmap>, L</pgrep> and L</psink>. The first
two are the meat of the module, the last one is a means to test by sending
results somewhere other than a filehandle (or to chain IO::Pipeline output
on to ... well, anywhere else, really).

pmap and pgrep both return pipeline objects (currently of class IO::Pipeline,
but this is considered an implementation detail, not a feature - so please
don't write code that relies on it) that provide an overloaded '|' operator.

  my $mapper = pmap { "[header] ".$_ };

  my $filter = pgrep { /ALERT/ };

When you use | to chain two pipeline objects together, you get another
pipeline object:

  my $combined = $mapper | $filter;

Although since we're going left to right, you probably want to do the grep
first:

  my $combined = $filter | $mapper;

(but it's all the same to IO::Pipeline, of course)

When you use | with a filehandle on one side, that sets the start or
finish of the pipeline, so:

  my $combined_with_input = $readable_fh | $combined;

  my $combined_with_output = $combined | $writeable_fh;

and if you don't want a real filehandle for the second option, you can use
psink:

  my $output = '';
  
  my $combined_with_output = $combined | psink { $output .= $_ };

Once both an input and an output have been provided, IO::Pipeline runs the
full pipeline, reading from the input and pushing one line at a time down
the pipe to the output until the input filehandle is exhausted.

Non-completed pipeline objects are completely re-usable though - so you can
(and are expected to) do things like:

  my $combined_to_stoud = $combined | \*STDOUT;
  
  foreach my $file (@files_to_process) {
  
    open my $in, '<', $file
      or die "Couldn't open ${file}: $!";
  
    $in | $combined_to_stdout;
  }

=head1 EXPORTED FUNCTIONS

=head2 pmap

  my $mapper = pmap { <return zero or more new lines based on $_> };

A pipeline part built with pmap gets invoked for each line on the pipeline,
with the line in both $_ and $_[0].

It may, as with perl's map operator, return zero or more elements. If it
returns nothing at all, IO::Pipeline will go back to the start of the pipe
chain and read another line to restart processing with. If it returns
one or more lines, each one is fed in turn into the rest of the pipe chain.

Most of the time, you probably just want to modify the line somehow and then
return it (note that $_ is a copy of the input line so this is safe):

  my $fix_teh = pmap { s/teh/the/g; $_; };

Note that you still need to actively return $_ for the pipe to continue
(again, as with perl's map operator).

=head2 pgrep

  my $filter = pgrep { <return true or false to keep or throw away $_> };

A pipeline part built with pgrep gets invoked for each line on the pipeline,
with the line in both $_ and $_[0].

If it returns a true value, the line is passed on to the next stage of the
pipeline. If it returns a false value, the line is thrown away and IO::Pipeline
will go back to the start of the pipe chain and read another line to restart
processing with.

The upshot of this is that any pgrep can be turned trivially into a pmap:

  my $filter = pgrep { /ALERT/ };

is precisely equivalent to:

  my $filter = pmap { /ALERT/ ? ($_) : () };

but the pgrep form is rather clearer.

=head2 psink

  my $output = '';
  
  my $sink = psink { $output .= $_ };

A pipe sink is an alternative to an output filehandle as the last element
of a pipeline. Where in the case of a normal filehandle a line would be
printed to the handle, given a sink IO::Pipeline will call the code block
provided. So:

  $pipeline | \*STDOUT;

and

  $pipeline | psink { print STDOUT $_; }

will have exactly the same end result.

If you're looking for the source version of this, there isn't one built in
because L<IO::Handle::Util|Yuval Kogman's IO::Handle::Util module> already
provides an io_from_getline construct that does that, along with a bunch
more things that you may find very useful.

=head1 DECONSTRUCTING THE SYNOPSIS

Start with an input filehandle:

  $in

Next, we split the line up - so

  2010-03-21 16:15:30 1NtNoI-000658-6V Completed

becomes

  [ '2010-03-21', '16:15:30', '1NtNoI-000658-6V Completed' ]

using a regexp in list context so that all the match values fall out into
a new anonymous array reference:

    | pmap { [ /^(\S+) (\S+) (.*)$/ ] }

Now we've separated out the message, we want to throw away anything that isn't
either a 'rejected' or 'Completed' line, so we test the last element of the
split line for that:

    | pgrep { $_->[2] =~ /rejected|Completed/ }

Now we know which is which, we want to turn

  [ '2010-03-21', '16:15:30', '1NtNoI-000658-6V Completed' ]

into

  [ '2010-03-21', '16:15:30', 'Completed' ]

and similarly for rejected lines. Since we know both lines are one or the
other, we can simply test for 'rejected' in the line -

  $_->[2] =~ /rejected/ ? 'Rejected' : 'Completed'

and then we construct a new array reference consisting of the first two
elements of the original array

  @{$_}[0, 1]

plus the new value for the third element:

    | pmap { [ @{$_}[0, 1], $_->[2] =~ /rejected/ ? 'Rejected' : 'Completed' ] }

This done, we can now reassemble the line using join (remembering to add a
newline since IO::Pipeline doesn't in case you didn't want one)

    | pmap { join(' ', @$_)."\n" }

and then in lieu of sending it somewhere else, since this is just a
demonstration code fragment, add a sink that appends things onto the end of
a variable so that we can examine the results:

    | psink { $out .= $_ };

=head1 AUTHOR

Matt S. Trout (mst) <mst@shadowcat.co.uk>

=head2 CONTRIBUTORS

None as yet, though I'm sure that'll change as soon as people spot the
giant gaping holes that inevitably exist in any software only used by
the author so far.

=head1 COPYRIGHT

Copyright (c) 2010 the IO::Pipeline L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=head1 SUPPORT

Right now, your best routes are probably (a) to come ask questions on
#perl on irc.freenode.net or #perl-help on irc.perl.org (I'm on there with
nick mst if nobody else around at the time manages to help you first) or
(b) to email me directly at the address given in L</AUTHOR> above. You're
also welcome to use rt.cpan.org to report bugs (which you can do without
a login by mailing bugs-IO-Pipeline at that domain), but please cc my
email address as well on grounds of me being a Bad Person and thereby not
always spotting tickets.

=head1 SOURCE CODE

This code lives in git.shadowcat.co.uk and can be viewed via gitweb using

  http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/IO-Pipeline.git;a=summary

or checked out via git-daemon using

  git://git.shadowcat.co.uk/p5sagit/IO-Pipeline.git

=cut

1;
