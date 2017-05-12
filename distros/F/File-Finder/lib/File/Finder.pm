package File::Finder;

use 5.006;
use strict;
use warnings;

use base qw(Exporter);

## no exports

our $VERSION = '0.53';

use Carp qw(croak);

## public methods:

sub new {
  my $class = shift;
  bless {
	 options => {},
	 steps => [],
	}, $class;
}

sub as_wanted {
  my $self = shift;
  return sub { $self->_run };
}

use overload
  '&{}' => 'as_wanted',
  # '""' => sub { overload::StrVal(shift) },
  ;

sub as_options {
  my $self = shift;
  return { %{$self->{options}}, wanted => sub { $self->_run } };
}

sub in {
  my $self = _force_object(shift);

  ## this must return count in a scalar context
  $self->collect(sub { $File::Find::name }, @_);
}

sub collect {
  my $self = _force_object(shift);
  my $code = shift;

  my @result;
  my $self_store = $self->eval( sub { push @result, $code->() } );

  require File::Find;
  File::Find::find($self_store->as_options, @_);

  ## this must return count in a scalar context
  return @result;
}

## private methods

sub _force_object {
  my $self_or_class = shift;
  ref $self_or_class ? $self_or_class : $self_or_class->new;
}

sub _clone {
  my $self = _force_object(shift);
  bless {
	 options => {%{$self->{options}}},
	 steps => [@{$self->{steps}}],
	}, ref $self;
}

## we set this to ensure that _ is correct for all tests
$File::Find::dont_use_nlink = 1;
## otherwise, we have to lstat/stat($_) inside _run
## thanks, tye!

sub _run {
  my $self = shift;

  my @stat;
  @stat = stat if defined $_;

  my @state = (1);
  ## $state[-1]:
  ## if 2: we're in a true state, but we've just seen a NOT
  ## if 1: we're in a true state
  ## if 0: we're in a false state
  ## if -1: we're in a "skipping" state (true OR ...[here]...)

  for my $step(@{$self->{steps}}) {

    ## verify underscore handle is good:
    if (@stat) {
      my @cache_stat = stat _;
      stat unless "@stat" eq "@cache_stat";
    }

    if (ref $step) {		# coderef
      if ($state[-1] >= 1) {	# true state
	if ($self->$step) {	# coderef ran returning true
	  if ($state[-1] == 2) {
	    $state[-1] = 0;
	  }
	} else {
	  $state[-1]--;		# 2 => 1, 1 => 0
	}
      }
    } elsif ($step eq "or") {
      # -1 => -1, 0 => 1, 1 => -1, 2 is error
      croak "not before or?" if $state[-1] > 1;
      if ($state[-1] == 0) {
	$state[-1] = 1;
      } elsif ($state[-1] == 1) {
	$state[-1] = -1;
      }
    } elsif ($step eq "left") {
      ## start subrule
      ## -1 => -1, 0 => -1, 1 => 1, 2 => 1
      push @state, ($state[-1] >= 1) ? 1 : -1;
    } elsif ($step eq "right") {
      ## end subrule
      croak "right without left" unless @state > 1;
      croak "not before right" if $state[-1] > 1;
      my $result = pop @state;
      if ($state[-1] >= 1) {
	if ($result) { # 1 or -1, so counts as true
	  if ($state[-1] == 2) {
	    $state[-1] = 0;
	  }
	} else {
	  $state[-1]--;		# 2 => 1, 1 => 0
	}
      }
    } elsif ($step eq "comma") {
      croak "not before comma" if $state[-1] > 1;
      if (@state < 2) {		# not in parens
	$state[-1] = 1;		# reset to true
      } else {			# in parens, reset as if start of parens
	$state[-1] = (($state[-2] >= 1) ? 1 : -1);
      }
    } elsif ($step eq "not") {
      # -1 => -1, 0 => 0, 1 => 2, 2 => 1
      if ($state[-1] >= 1) {
	$state[-1] = $state[-1] > 1 ? 1 : 2;
      }
    } else {
      die "internal error at $step";
    }
  }
  croak "left without right" unless @state == 1;
  croak "trailing not" if $state[-1] > 1;
  return $state[-1] != 0;	# true and skipping are both true
}

sub AUTOLOAD {
  my $self = _force_object(shift);

  my ($method) = our $AUTOLOAD =~ /(?:.*::)?(.*)/;
  return if $method eq "DESTROY";

  my $clone = $self->_clone;

  ## bring in the steps
  my $steps_class = $clone->_steps_class;
  $steps_class =~ /[^\w:]/
    and die "bad value for \$steps_class: $steps_class";
  eval "require $steps_class"; die $@ if $@;

  my $sub_method = $steps_class->can($method)
    or croak "Cannot add step $method";

  push @{$clone->{steps}}, $sub_method->($clone, @_);
  $clone;
}

sub _steps_class { "File::Finder::Steps" }

1;
__END__

=head1 NAME

File::Finder - nice wrapper for File::Find ala find(1)

=head1 SYNOPSIS

  use File::Finder;
  ## simulate "-type f"
  my $all_files = File::Finder->type('f');

  ## any rule can be extended:
  my $all_files_printer = $all_files->print;

  ## traditional use: generating "wanted" subroutines:
  use File::Find;
  find($all_files_printer, @starting_points);  

  ## or, we can gather up the results immediately:
  my @results = $all_files->in(@starting_points);

  ## -depth and -follow are noted, but need a bit of help for find:
  my $deep_dirs = File::Finder->depth->type('d')->ls->exec('rmdir','{}');
  find($deep_dirs->as_options, @places);

=head1 DESCRIPTION

C<File::Find> is great, but constructing the C<wanted> routine can
sometimes be a pain.  This module provides a C<wanted>-writer, using
syntax that is directly mappable to the I<find> command's syntax.

Also, I find myself (heh) frequently just wanting the list of names
that match.  With C<File::Find>, I have to write a little accumulator,
and then access that from a closure.  But with C<File::Finder>, I can
turn the problem inside out.

A C<File::Finder> object contains a hash of C<File::Find> options, and
a series of steps that mimic I<find>'s predicates.  Initially, a
C<File::Finder> object has no steps.  Each step method clones the
previous object's options and steps, and then adds the new step,
returning the new object.  In this manner, an object can be grown,
step by step, by chaining method calls.  Furthermore, a partial
sequence can be created and held, and used as the head of many
different sequences.

For example, a step sequence that finds only files looks like:

  my $files = File::Finder->type('f');

Here, C<type> is acting as a class method and thus a constructor.  An
instance of C<File::Finder> is returned, containing the one step to
verify that only files are selected.  We could use this immediately
as a C<File::Find::find> wanted routine, although it'd be uninteresting:

  use File::Find;
  find($files, "/tmp");

Calling a step method on an existing object adds the step, returning
the new object:

  my $files_print = $files->print;

And now if we use this with C<find>, we get a nice display:

  find($files_print, "/tmp");

Of course, we didn't really need that second object: we could
have generated it on the fly:

  find($files->print, "/tmp");

C<File::Find> supports options to modify behavior, such as depth-first
searching.  The C<depth> step flags this in the options as well:

  my $files_depth_print = $files->depth->print;

However, the C<File::Finder> object needs to be told explictly to
generate an options hash for C<File::Find::find> to pass this
information along:

  find($files_depth_print->as_options, "/tmp");

A C<File::Finder> object, like the I<find> command, supports AND, OR,
NOT, and parenthesized sub-expressions.  AND binds tighter than OR,
and is also implied everywhere that it makes sense.  Like I<find>, the
predicates are computed in a "short-circuit" fashion, so that a false
to the left of the (implied) AND keeps the right side from being
evaluated, including entire parenthesized subexpressions.  Similarly,
if the left side of an OR is false, the right side is evaluated, and
if the left side of the OR is true, the right side is skipped.  Nested
parens are handled properly.  Parens are indicated with the rather
ugly C<left> and C<right> methods:

  my $big_or_old_files = $files->left->size("+50")->or->atime("+30")->right;

The parens here correspond directly to the parens in:

  find somewhere -type f '(' -size +50 -o -atime +30 ')'

and are needed so that the OR and the implied ANDs have the right
nesting.

Besides passing the constructed C<File::Finder> object to
C<File::Finder::find> directly as a C<wanted> routine or an options
hash, you can also call C<find> implictly, with C<in>.  C<in> provides
a list of starting points, and returns all filenames that match the
criteria.

For example, a list of all names in /tmp can be generated simply with:

 my @names = File::Finder->in("/tmp");

For more flexibility, use C<collect> to execute an arbitrary block
in a list context, concatenating all the results (similar to C<map>):

  my %sizes = File::Finder
    ->collect(sub { $File::Find::name => -s _ }, "/tmp");

That's all I can think of for now.  The rest is in the detailed
reference below.

=head2 META METHODS

All of these methods can be used as class or instance methods, except
C<new>, which is usually not needed and is class only.

=over

=item new

Not strictly needed, because any instance method called on a class
will create a new object anyway.

=item as_wanted

Returns a subroutine suitable for passing to C<File::Find::find> or
C<File::Find::finddepth> as the I<wanted> routine.  If the object is
used in a place that wants a coderef, this happens automatically
through overloading.

=item as_options

Returns a hashref suitable for passing to C<File::Find::find> or
C<File::Find::finddepth> as the I<options> hash. This is necessary if
you want the meta-information to carry forward properly.

=item in(@starting_points)

Calls C<< File::Find::find($self->as_options, @starting_points) >>,
gathering the results, and returns the results as a list.  At the
moment, it also returns the count of those items in a scalar context.
If that's useful, I'll maintain that.

=item collect($coderef, @starting_points)

Calls C<$coderef> in a list context for each of the matching items,
gathering and concatenating the results, and returning the results as
a list.

  my $f = File::Finder->type('f');
  my %sizes = $f->collect(sub { $File::Find::name, -s _ }, "/tmp");

In fact, C<in> is implemented by calling C<collect> with a coderef
of just C<sub { $File::Find::name }>.

=back

=head2 STEPS

See L<File::Finder::Steps>.

=head2 SPEED

All the steps can have a compile-time and run-time component.  As
much work is done during compile-time as possible.  Runtime consists
of a simple linear pass executing a series of closures representing
the individual steps (not method calls).  It is hoped that this will
produce a speed that is within a factor of 2 or 3 of a handcrafted
monolithic C<wanted> routine.

=head1 SEE ALSO

L<File::Finder::Steps>, L<File::Find>, L<find2perl>, L<File::Find::Rule>

=head1 BUGS

Please report bugs to C<bug-File-Finder@rt.cpan.org>.

=head1 AUTHOR

Randal L. Schwartz, E<lt>merlyn@stonehenge.comE<gt>, with a tip
of the hat to Richard Clamp for C<File::Find::Rule>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003,2004 by Randal L. Schwartz,
Stonehenge Consulting Services, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
