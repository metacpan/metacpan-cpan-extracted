use strict;
use warnings;
package Email::Simple::Test::TraceHeaders;
{
  $Email::Simple::Test::TraceHeaders::VERSION = '0.091702';
}
# ABSTRACT: generate sample trace headers for testing

use Carp ();
use Email::Date::Format ();
use Email::Simple;
use Email::Simple::Creator;
use Sub::Exporter::Util ();

use Sub::Exporter -setup => {
  exports => [ prev    => \'_build_prev' ],
  groups  => [ helpers => [ qw(prev) ] ],
};

# For now, we'll only generate one style of Received header: postfix
# It's what I encounter the most, and it's simple and straightforward.
# In the future, we'll be flexible, maybe. -- rjbs, 2009-06-19
my %POSTFIX_FMT = (
  for   => q{from %s (%s [%s]) by %s (Postfix) with ESMTP id %s for <%s>; %s},
  nofor => q{from %s (%s [%s]) by %s (Postfix) with ESMTP id %s%s; %s},
);


sub trace_headers {
  my ($self, $arg) = @_;

  Carp::confess("no hops provided") unless $arg->{hops};

  my @received;
  my %last;
  for my $hop (@{ $arg->{hops} }) {
    my %hop = (%$hop);

    for my $key (keys %hop) {
      if (ref $hop->{$key} eq 'CODE') {
        $hop{ $key } = $hop{$key}->(\%last);
      }
    }

    my $env_to = ref $hop{env_to} ?   $hop{env_to}
               :     $hop{env_to} ? [ $hop{env_to} ]
               :                    [              ];

    my $fmt = @$env_to == 1 ? $POSTFIX_FMT{for} : $POSTFIX_FMT{nofor};

    push @received, sprintf $fmt,
      $hop{from_helo},
      $hop{from_rdns},
      $hop{from_ip},
      $hop{by_name}, # by_ip someday?
      $hop{queue_id},
      @$env_to == 1 ? $env_to->[0] : '',
      (Email::Date::Format::email_gmdate($hop{time}) . ' (GMT)');

    %last = %hop;
  }

  return [ reverse @received ];
}


sub create_email {
  my ($self, $arg) = @_;

  my $email = Email::Simple->create(
    header => [
      (map {; Received => $_ } @{ $self->trace_headers($arg) }),

      From => '"X. Ample" <xa@example.com>',
      To   => '"E. Xampe" <ex@example.org>',
    ],
    body    => "This is a test message.\n",
  );

  return $email;
}


sub _build_prev {
  my ($self) = @_;

  sub {
    my ($name) = @_;

    sub {
      my ($last) = @_;
      $last->{ $name };
    }
  }
}

1;

__END__

=pod

=head1 NAME

Email::Simple::Test::TraceHeaders - generate sample trace headers for testing

=head1 VERSION

version 0.091702

=head1 METHODS

=head2 trace_headers

  my $header_strings = Email::Simple::Test::TraceHeaders->trace_headers(\%arg);

This returns an arrayref of "Received" header strings.

At present, all headers are produced in Postfix style.

At present the only valid argument is C<hops>, which is an arrayref of hashrefs
describing hops.  Each hashref should have the following entries:

  from_helo - the hostname given in the sending host's HELO
  from_rdns - the hostname found by looking up the PTR for the sender's ip
  from_ip   - the IP addr of the sending host
  by_name   - the hostname of the receiving host
  queue_id  - the id of the mail queue entry created upon receipt
  env_to    - the recipient of the message (an email addr)
  time      - the timestamp on the header

At present, these are all required.  In the future they may have more flexible
semantics, and more formats for output of hops may be supported.

=head2 create_email

  my $email_simple = Email::Simple::Test::TraceHeaders->create_email(
    \%trace_arg
  );

This creates and returns an Email::Simple message with trace headers created by
C<L</trace_headers>>.

=head1 HELPERS

Some routines can be exported to make it easier to set up trace headers.

You can get them all with:

  use Email::Simple::Test::TraceHeaders -helpers;

=head2 prev

This helper gets a value from the previous hop.  So, given these hops:

  { ..., by_name => 'mx.example.com', ... },
  { ..., from_rdns => prev('by_name'), ... },

...the second hop will have F<mx.example.com> as its C<from_rdns> parameter.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
