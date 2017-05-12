#!/usr/bin/perl

=head1 NAME

Log::Message::JSON - structured messages that stringify to JSON

=head1 SYNOPSIS

  package My::Application::Module;

  use Log::Log4perl;
  use Log::Message::JSON qw{logmsg};

  sub do_something {
    my ($self, $foo, $bar, @rest) = @_;

    my $logger = Log::Log4perl->get_logger();

    $logger->info(logmsg message => "do_something entered",
                         foo => $foo, bar => $bar, rest => \@rest);

    # ...
  }

  # in flat-file logs entry would look like:
  # Dec 28 00:24:52 example.net My-Application[1587]: {"message":"do_something entered","foo":"value of foo","bar":"value of bar","rest":["value","of","rest"]}

=head1 DESCRIPTION

Good logging requires today a lot more than in Good Ol' Times[tm]. Each log
entry should have a structure and be machine-parseable. On the other hand,
there are lot of logging libraries that don't quite support structured logs
and only process flat strings.

L<Log::Log4perl(3)> architecture allows both, flat strings and structured
entries. It's up to appender module whether it accepts one or another form.
Unfortunately, this makes application developer to decide in advance, which
appenders could be in use and defeats much of Log::Log4perl's flexibility.

Log::Message::JSON is an attempt to solve this problem. Developer can create
a message that has an internal structure (i.e. is a hash(ref)), and at the
same time it can be used as a simple string, instantly serializing to
single-line JSON. This way the developer don't need to decide on appenders in
advance. Moreover, flat string logfiles are easier to parse, especially if
entries have this form.

Of course, you don't need Log::Log4perl to use this module. It could be used
wherever a hashref needs to be sensibly stringified while preserving its all
hash-like features.

=cut

#-----------------------------------------------------------------------------

package Log::Message::JSON;

use warnings;
use strict;

use base qw{Exporter};
our @EXPORT_OK = qw{&logmsg &logmess &msg &json};

use overload ('""' => \&to_json);

use Log::Message::JSON::Hash;
use Carp;

#-----------------------------------------------------------------------------

our $VERSION = '0.30.01';

#-----------------------------------------------------------------------------

=head1 API

The preferred way is the short way. Object-oriented API is described here
mainly for reference.

=head2 Short Way

=over

=cut

#-----------------------------------------------------------------------------

=item C<logmsg(...)>

=item C<logmess(...)>

=item C<msg(...)>

=item C<json(...)>

These are plain functions. They all are exported (but none by default, you
need to specifically ask for them), they all do the same and they all accept
the same arguments. They are provided for your convenience. Choose the one
that don't clash with your methods (but please, make your life easier in
future and choose one for whole application).

These functions accept either a reference to a hash or a list of
C<< key => value >> pairs. The latter form preserves keys order, so I believe
it's more useful. Also, in the latter form you may skip the first key name;
the value will be stored under C<message> key in such case.

Returned value is an object created with C<new()> method (see
L</"Object-Oriented API">), so it's a reference to a hash (blessed, but still
hashref, with all its consequences).

Usage example:

  use Log::Message::JSON qw{logmsg};
  use Log::Log4perl;

  my $msg1 = logmsg { key1 => 1, key2 => 2 };
  my $msg2 = logmsg foo => 1, bar => 2, text => "some text";
  my $msg3 = logmsg "my log message", host => hostname();

  my $logger = Log::Log4perl->get_logger();
  $logger->info($msg1);
  $logger->debug($msg2);
  $logger->warn($msg3);

  print $msg1;
  printf "%s => %s\n", $_, $msg2->{$_} for keys %$msg2;

=cut

sub json {
  return __PACKAGE__->new(@_);
}

sub logmsg {
  return __PACKAGE__->new(@_);
}

sub logmess {
  return __PACKAGE__->new(@_);
}

sub msg {
  return __PACKAGE__->new(@_);
}

=back

=cut

#-----------------------------------------------------------------------------

=head2 Object-Oriented API

=over

=cut

#-----------------------------------------------------------------------------

=item C<< new(key => value, ...) >>

=item C<< new({ key => value, ... }) >>

Constructor.

This method creates a new hash reference. The underlying hash is tied to
L<Tie::IxHash(3)> (actually, to a proxy class that uses L<Tie::IxHash(3)> as
a backend) and filled with arguments. Because of overloaded stringification
operator, reference is blessed with Log::Message::JSON package.

If the first call form (list of pairs) was used, the order of key/value pairs
is preserved. If the number of elements is odd, the first element is believed
to be value of C<message> key.

If the second call form (hashref) was used, key/value pairs are sorted using
C<cmp> operator, unless the referred hash was tied to L<Tie::IxHash(3)>.

=cut

sub new {
  my ($class, @args) = @_;

  tie my %self, 'Log::Message::JSON::Hash';

  if (@args == 1 && (ref $args[0] eq 'HASH' || eval {$args[0]->isa('HASH')})) {
    if (eval { tied(%{ $args[0] })->isa("Tie::IxHash") }) {
      # no sort, hash probably tied to Tie::IxHash or something
      %self = %{ $args[0] };
    } else {
      # sort keys from the hash
      %self = map { $_ => $args[0]{$_} } sort keys %{ $args[0] };
    }
  } else {
    # keep the order
    if (@args % 2 == 1) {
      %self = ("message", @args);
    } else {
      %self = @args;
    }
  }

  return bless \%self, $class;
}

#-----------------------------------------------------------------------------
#
# auxiliary functions
#
#-----------------------------------------------------------------------------

=begin Test::Pod::Coverage

=item C<quote()>

Helper function for quoting strings in JSON.

=end Test::Pod::Coverage

=cut

sub quote($) {
  my ($str) = @_;

  my %q = (
    "\\" => "\\\\",
    '"'  => '\"',
    "\n" => "\\n",
    "\r" => "\\r",
    "\t" => "\\t",
  );
  $str =~ s/([\\"\n\r\t])/$q{$1}/g;

  return $str;
}

=item C<to_json()>

JSON encoding method. This method returns a JSON string that contains no tabs
nor newlines. Just a single line of text.

=cut

# This is my own JSON encoder. This serves as two purposes: first, it relaxes
# dependencies on external modules; second, it detects object of class
# Log::Message::JSON (at root level, possibly) to preserve keys order when
# JSON-infying.
sub to_json($) {
  my ($value) = @_;

  if (ref $value eq __PACKAGE__) { # plain hash, tied
    my $tied = tied %$value;

    # store cache for this object if there was no cache for it
    if (not defined $tied->cache) {
      my @pairs = map {
        sprintf '%s:%s', to_json($_), to_json($value->{$_})
      } keys %$value;
      $tied->cache(sprintf "{%s}", join ",", @pairs);
    }

    return $tied->cache;
  } elsif (ref $value eq "HASH") { # plain hash
    my @pairs = map {
      sprintf '%s:%s', to_json($_), to_json($value->{$_})
    } sort keys %$value;
    return sprintf "{%s}", join ",", @pairs;
  } elsif (ref $value eq "ARRAY") {   # plain array
    my @elems = map { to_json($_) } @$value;
    return sprintf "[%s]", join ",", @elems;
  } elsif (ref $value eq "SCALAR") {  # plain scalar (reference)
    return sprintf '"%s"', quote($$value);
  } elsif (not defined $value) {      # undef (null)
    return 'null';
  } elsif (not ref $value) {          # plain scalar
    return sprintf '"%s"', quote($value);
  } else {                            # compound object
    # TODO
    croak "Type @{[ref $value]} unsupported yet\n";
  }
}

=back

=cut

#-----------------------------------------------------------------------------

=head1 C<die()> NOTES

To use Log::Message::JSON as a reason for C<die()>, you need to assign it to
C<$@> variable and call C<die()> without arguments (works for Perl 5.8+).

  unless (open my $f, "<", $file) {
    $@ = msg "error opening file",
             filename => $file,
             error => "$!", errno => $! + 0;
    die;
  }

Of course just calling C<die(msg(...))> will work as well, but it will result
in a message without end-of-line character.

=begin Test::Pod::Coverage

=item C<PROPAGATE($file, $line)>

B<SEE ALSO>: C<perldoc -f die>

=end Test::Pod::Coverage

=cut


sub PROPAGATE {
  my ($self, $file, $line) = @_;

  return sprintf "died at %s line %d, %s\n", $file, $line, $self;
}

#-----------------------------------------------------------------------------

=head1 C<Log::Log4perl> NOTES

You might be tempted to use custom I<message output filter> to stringify the
message. It would look like this:

  my $logger = Log::Log4perl->get_logger();
  $logger->info({ filter => \&dumper, value => $mydata });

This won't work too well: the filter gets called before appender module, so
the appender gets a string instead of a structured message. The better way
would be:

  my $logger = Log::Log4perl->get_logger();
  $logger->info(logmsg $mydata);

Log::Log4perl only processes C<filter> and C<value> when the object is
a plain, unblessed hash, so you may safely use these two key names.

=cut

#-----------------------------------------------------------------------------

=head1 AUTHOR

Stanislaw Klekot, C<< <cpan at jarowit.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Stanislaw Klekot.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Log::Log4perl(3)>, L<Log::Log4perl::Appender::Fluent(3)>,
L<Log::Message::JSON::Hash(3)>, L<Tie::IxHash(3)>,
L<Log::Message::Structured(3)>.

=cut

#-----------------------------------------------------------------------------
1;
# vim:ft=perl
