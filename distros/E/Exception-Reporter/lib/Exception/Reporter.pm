use strict;
use warnings;
package Exception::Reporter 0.015;
# ABSTRACT: a generic exception-reporting object

#pod =head1 SYNOPSIS
#pod
#pod B<Achtung!>  This is an experimental refactoring of some long-standing internal
#pod code.  It might get even more refactored.  Once I've sent a few hundred
#pod thousand exceptions through it, I'll remove this warning...
#pod
#pod First, you create a reporter.  Probably you stick it someplace globally
#pod accessible, like MyApp->reporter.
#pod
#pod   my $reporter = Exception::Reporter->new({
#pod     always_dump => { env => sub { \%ENV } },
#pod     senders     => [
#pod       Exception::Reporter::Sender::Email->new({
#pod         from => 'root@example.com',
#pod         to   => 'SysAdmins <sysadmins@example.com>',
#pod       }),
#pod     ],
#pod     summarizers => [
#pod       Exception::Reporter::Summarizer::Email->new,
#pod       Exception::Reporter::Summarizer::File->new,
#pod       Exception::Reporter::Summarizer::ExceptionClass->new,
#pod       Exception::Reporter::Summarizer::Fallback->new,
#pod     ],
#pod   });
#pod
#pod Later, some exception has been thrown!  Maybe it's an L<Exception::Class>-based
#pod exception, or a string, or a L<Throwable> object or who knows what.
#pod
#pod   try {
#pod     ...
#pod   } catch {
#pod     MyApp->reporter->report_exception(
#pod       [
#pod         [ exception => $_ ],
#pod         [ request   => $current_request ],
#pod         [ uploading => Exception::Reporter::Dumpable::File->new($filename) ],
#pod       ],
#pod     );
#pod   };
#pod
#pod The sysadmins will get a nice email report with all the dumped data, and
#pod reports will thread.  Awesome, right?
#pod
#pod =head1 OVERVIEW
#pod
#pod Exception::Reporter takes a bunch of input (the I<dumpables>) and tries to
#pod figure out how to summarize them and build them into a report to send to
#pod somebody.  Probably a human being.
#pod
#pod It does this with two kinds of plugins:  summarizers and senders.
#pod
#pod The summarizers' job is to convert each dumpable into a simple hashref
#pod describing it.  The senders' job is to take those hashrefs and send them to
#pod somebody who cares.
#pod
#pod =cut

use Data::GUID guid_string => { -as => '_guid_string' };

#pod =method new
#pod
#pod   my $reporter = Exception::Reporter->new(\%arg);
#pod
#pod This returns a new reporter.  Valid arguments are:
#pod
#pod   summarizers  - an arrayref of summarizer objects; required
#pod   senders      - an arrayref of sender objects; required
#pod   dumper       - a Exception::Reporter::Dumper used for dumping data
#pod   always_dump  - a hashref of coderefs used to generate extra dumpables
#pod   caller_level - if given, the reporter will look n frames up; see below
#pod
#pod The C<always_dump> hashref bears a bit more explanation.  When
#pod C<L</report_exception>> is called, each entry in C<always_dump> will be
#pod evaluated and appended to the list of given dumpables.  This lets you make your
#pod reporter always include some more useful information.
#pod
#pod I<...but remember!>  The reporter is probably doing its job in a C<catch>
#pod block, which means that anything that might have been changed C<local>-ly in
#pod your C<try> block will I<not> be the same when evaluated as part of the
#pod C<always_dump> code.  This might not matter often, but keep it in mind when
#pod setting up your reporter.
#pod
#pod In real code, you're likely to create one Exception::Reporter object and make
#pod it globally accessible through some method.  That method adds a call frame, and
#pod Exception::Reporter sometimes looks at C<caller> to get a default.  If you want
#pod to skip those intermedite call frames, pass C<caller_level>.  It will be used
#pod as the number of frames up the stack to look.  It defaults to zero.
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;

  my $self = {
    summarizers  => $arg->{summarizers},
    senders      => $arg->{senders},
    dumper       => $arg->{dumper},
    always_dump  => $arg->{always_dump},
    caller_level => $arg->{caller_level} || 0,
  };

  if ($self->{always_dump}) {
    for my $key (keys %{ $self->{always_dump} }) {
      Carp::confess("non-coderef entry in always_dump: $key")
        unless ref($self->{always_dump}{$key}) eq 'CODE';
    }
  }

  $self->{dumper} ||= do {
    require Exception::Reporter::Dumper::YAML;
    Exception::Reporter::Dumper::YAML->new;
  };

  Carp::confess("entry in dumper is not an Exception::Reporter::Dumper")
    unless $self->{dumper}->isa('Exception::Reporter::Dumper');

  for my $test (qw(Summarizer Sender)) {
    my $class = "Exception::Reporter::$test";
    my $key   = "\L${test}s";

    Carp::confess("no $key given") unless $arg->{$key} and @{ $arg->{$key} };
    Carp::confess("entry in $key is not an $class")
      if grep { ! $_->isa($class) } @{ $arg->{$key} };
  }

  bless $self => $class;

  $_->register_reporter($self) for $self->_summarizers;

  return $self;
}

sub _summarizers { return @{ $_[0]->{summarizers} }; }
sub _senders     { return @{ $_[0]->{senders} }; }

sub dumper { return $_[0]->{dumper} }

#pod =method report_exception
#pod
#pod   $reporter->report_exception(\@dumpables, \%arg);
#pod
#pod This method makes the reporter do its job: summarize dumpables and send a
#pod report.
#pod
#pod Useful options in C<%arg> are:
#pod
#pod   reporter    - the program or authority doing the reporting; defaults to
#pod                 the calling package
#pod
#pod   handled     - this indicates that this exception has been handled and that
#pod                 the user has not seen a terrible crash; senders might use
#pod                 this to decide who needs to get woken up
#pod
#pod   extra_rcpts - this can be an arrayref of email addresses to be used as
#pod                 extra envelope recipients by the Email sender
#pod
#pod Each entry in C<@dumpables> is expected to look like this:
#pod
#pod   [ $short_name, $value, \%arg ]
#pod
#pod The short name is used for a few things, including identifying the dumps inside
#pod the report produced.  It's okay to have duplicated short names.
#pod
#pod The value can, in theory, be I<anything>.  It can be C<undef>, any kind of
#pod object, or whatever you want to stick in a scalar.  It's possible that
#pod extremely exotic values could confuse the "fallback" summarizer of last resort,
#pod but for the most part, anything goes.
#pod
#pod The C<%arg> entry isn't used for anything by the core libraries that ship with
#pod Exception::Reporter, but you might want to use it for your own purposes.  Feel
#pod free.
#pod
#pod The reporter will try to summarize each dumpable by asking each summarizer, in
#pod order, whether it C<can_summarize> the dumpable.  If it can, it will be asked
#pod to C<summarize> the dumpable.  The summaries are collected into a structure
#pod that looks like this:
#pod
#pod   [
#pod     [ dumpable_short_name => \@summaries ],
#pod     ...
#pod   ]
#pod
#pod If a given dumpable can't be dumped by any summarizer, a not-very-useful
#pod placeholder is put in its place.
#pod
#pod The arrayref constructed is passed to the C<send_report> method of each sender,
#pod in turn.
#pod
#pod =cut

sub report_exception {
  my ($self, $dumpables, $arg) = @_;
  $dumpables ||= [];
  $arg ||= {};

  my $guid = _guid_string;

  my @caller = caller( $self->{caller_level} );
  $arg->{reporter} ||= $caller[0];

  my $summaries = $self->collect_summaries($dumpables);

  for my $sender ($self->_senders) {
    $sender->send_report(
      $summaries,
      $arg,
      {
        guid   => $guid,
        caller => \@caller,
      }
    );
  }

  return $guid;
}

#pod =method collect_summaries
#pod
#pod   $reporter->report_exception(\@dumpables);
#pod
#pod This method is used by L</report_exception> to convert dumpables into
#pod summaries. It may be called directly by summarizers through
#pod C<< $self->reporter->collect_summaries(\@dumpables); >> if your
#pod summarizers receive dumpables that may be handled by another summarizer. Be
#pod wary though, because you could possibly create an endless loop...
#pod
#pod =cut

sub collect_summaries {
  my ($self, $dumpables) = @_;

  my @sumz = $self->_summarizers;

  my @summaries;

  DUMPABLE: for my $dumpable (
    @$dumpables,
    map {; [ $_, $self->{always_dump}{$_}->() ] }
      sort keys %{$self->{always_dump}}
  ) {
    for my $sum (@sumz) {
      next unless $sum->can_summarize($dumpable);
      push @summaries, [ $dumpable->[0], [ $sum->summarize($dumpable) ] ];
      next DUMPABLE;
    }

    push @summaries, [
      $dumpable->[0],
      [ {
        ident => "UNKNOWN",
        body  => "the entry for <$dumpable->[0]> could not be summarized",
        mimetype => 'text/plain',
        filename => 'unknown.txt',
      } ],
    ];
  }

  return \@summaries;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter - a generic exception-reporting object

=head1 VERSION

version 0.015

=head1 SYNOPSIS

B<Achtung!>  This is an experimental refactoring of some long-standing internal
code.  It might get even more refactored.  Once I've sent a few hundred
thousand exceptions through it, I'll remove this warning...

First, you create a reporter.  Probably you stick it someplace globally
accessible, like MyApp->reporter.

  my $reporter = Exception::Reporter->new({
    always_dump => { env => sub { \%ENV } },
    senders     => [
      Exception::Reporter::Sender::Email->new({
        from => 'root@example.com',
        to   => 'SysAdmins <sysadmins@example.com>',
      }),
    ],
    summarizers => [
      Exception::Reporter::Summarizer::Email->new,
      Exception::Reporter::Summarizer::File->new,
      Exception::Reporter::Summarizer::ExceptionClass->new,
      Exception::Reporter::Summarizer::Fallback->new,
    ],
  });

Later, some exception has been thrown!  Maybe it's an L<Exception::Class>-based
exception, or a string, or a L<Throwable> object or who knows what.

  try {
    ...
  } catch {
    MyApp->reporter->report_exception(
      [
        [ exception => $_ ],
        [ request   => $current_request ],
        [ uploading => Exception::Reporter::Dumpable::File->new($filename) ],
      ],
    );
  };

The sysadmins will get a nice email report with all the dumped data, and
reports will thread.  Awesome, right?

=head1 OVERVIEW

Exception::Reporter takes a bunch of input (the I<dumpables>) and tries to
figure out how to summarize them and build them into a report to send to
somebody.  Probably a human being.

It does this with two kinds of plugins:  summarizers and senders.

The summarizers' job is to convert each dumpable into a simple hashref
describing it.  The senders' job is to take those hashrefs and send them to
somebody who cares.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 new

  my $reporter = Exception::Reporter->new(\%arg);

This returns a new reporter.  Valid arguments are:

  summarizers  - an arrayref of summarizer objects; required
  senders      - an arrayref of sender objects; required
  dumper       - a Exception::Reporter::Dumper used for dumping data
  always_dump  - a hashref of coderefs used to generate extra dumpables
  caller_level - if given, the reporter will look n frames up; see below

The C<always_dump> hashref bears a bit more explanation.  When
C<L</report_exception>> is called, each entry in C<always_dump> will be
evaluated and appended to the list of given dumpables.  This lets you make your
reporter always include some more useful information.

I<...but remember!>  The reporter is probably doing its job in a C<catch>
block, which means that anything that might have been changed C<local>-ly in
your C<try> block will I<not> be the same when evaluated as part of the
C<always_dump> code.  This might not matter often, but keep it in mind when
setting up your reporter.

In real code, you're likely to create one Exception::Reporter object and make
it globally accessible through some method.  That method adds a call frame, and
Exception::Reporter sometimes looks at C<caller> to get a default.  If you want
to skip those intermedite call frames, pass C<caller_level>.  It will be used
as the number of frames up the stack to look.  It defaults to zero.

=head2 report_exception

  $reporter->report_exception(\@dumpables, \%arg);

This method makes the reporter do its job: summarize dumpables and send a
report.

Useful options in C<%arg> are:

  reporter    - the program or authority doing the reporting; defaults to
                the calling package

  handled     - this indicates that this exception has been handled and that
                the user has not seen a terrible crash; senders might use
                this to decide who needs to get woken up

  extra_rcpts - this can be an arrayref of email addresses to be used as
                extra envelope recipients by the Email sender

Each entry in C<@dumpables> is expected to look like this:

  [ $short_name, $value, \%arg ]

The short name is used for a few things, including identifying the dumps inside
the report produced.  It's okay to have duplicated short names.

The value can, in theory, be I<anything>.  It can be C<undef>, any kind of
object, or whatever you want to stick in a scalar.  It's possible that
extremely exotic values could confuse the "fallback" summarizer of last resort,
but for the most part, anything goes.

The C<%arg> entry isn't used for anything by the core libraries that ship with
Exception::Reporter, but you might want to use it for your own purposes.  Feel
free.

The reporter will try to summarize each dumpable by asking each summarizer, in
order, whether it C<can_summarize> the dumpable.  If it can, it will be asked
to C<summarize> the dumpable.  The summaries are collected into a structure
that looks like this:

  [
    [ dumpable_short_name => \@summaries ],
    ...
  ]

If a given dumpable can't be dumped by any summarizer, a not-very-useful
placeholder is put in its place.

The arrayref constructed is passed to the C<send_report> method of each sender,
in turn.

=head2 collect_summaries

  $reporter->report_exception(\@dumpables);

This method is used by L</report_exception> to convert dumpables into
summaries. It may be called directly by summarizers through
C<< $self->reporter->collect_summaries(\@dumpables); >> if your
summarizers receive dumpables that may be handled by another summarizer. Be
wary though, because you could possibly create an endless loop...

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Matthew Horsfall Ricardo Signes Tomohiro Hosaka

=over 4

=item *

Matthew Horsfall <wolfsage@gmail.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Tomohiro Hosaka <bokutin@bokut.in>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
