package JMAP::Tester::Sugar 0.107;

use v5.20.0;
use warnings;

use experimental 'signatures';

use Sub::Exporter -setup => [ qw( jset jcreate json_literal ) ];

sub jset ($type, $arg, $call_id = undef) {
  my %method_arg = %$arg;
  if (my $create_spec = delete $method_arg{create}) {
    unless (ref $create_spec eq 'ARRAY') {
      $create_spec = [ $create_spec ];
    }

    $method_arg{create} = {};

    my $i = 0;
    for my $creation (@$create_spec) {
      $method_arg{create}{"$type-" . $i++} = $creation;
    }
  }

  return [
    "$type/set",
    \%method_arg,
    (defined $call_id ? $call_id : ()),
  ];
}

sub jcreate ($type, $create, $call_id = undef) {
  return jset($type, { create => $create }, $call_id);
}

package JMAP::Tester::JSONLiteral 0.107 {
  sub new {
    my ($class, $bytes) = @_;

    bless { _bytes => $bytes }, $class;
  }

  sub bytes { return $_[0]{_bytes} }

  sub TO_JSON {
    # Some day, somebody is going to think that they can do this:
    # $tester->request([[ json_literal(...), {...} ]]);
    #
    # ...but they can't, because you can't supply the JSON encoder a hunk of
    # bytes to stick in the middle.  We can only decline to encode *at all*.
    # Because TO_JSON can't really die to abort JSON encoding, we just put some
    # obvious "you did it wrong" text into the output, and then we hope that
    # the user reads the logging! -- rjbs, 2025-12-11
    return "ERROR: a JMAP::Tester json_literal was passed to a JSON encoder"
  }
}

sub json_literal ($bytes) {
  return JMAP::Tester::JSONLiteral->new($bytes);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Sugar

=head1 VERSION

version 0.107

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
