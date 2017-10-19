package Defined::KV;
$Defined::KV::VERSION = '0.001';
# ABSTRACT: Create a KV pair, but only if the value is defined

use warnings;
use strict;

use Exporter 'import';
our @EXPORT = qw(defined_kv);

sub defined_kv ($$) {
  return (defined $_[1] ? @_[0,1] : ());
}

1;

__END__

=pod

=encoding UTF-8

=for markdown [![Build Status](https://secure.travis-ci.org/robn/Defined-KV.png)](http://travis-ci.org/robn/Defined-KV)

=head1 NAME

Defined::KV - Create a KV pair, but only if the value is defined

=head1 SYNOPSIS

    use Defined::KV;
    use Test::More;

    my $foo;
    my $bar = 1;
    my $baz = 0;

    my %dict = (
      defined_kv(foo => $foo),
      defined_kv(bar => $bar),
      defined_kv(baz => $baz),
    );

    is_deeply(\%dict, { bar => 1, baz => 0 });

=head1 DESCRIPTION

C<Defined::KV> exports a single function, C<defined_kv>. Call it with two arguments. If the second argument is defined, both are returned, otherwise nothing is returned.

This exists to replace this construct:

    (defined $v ? ($k => $v) : ())

with something less awkward and repetetive, namely:

    defined_kv($k => $v)

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/Defined-KV/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/Defined-KV>

  git clone https://github.com/robn/Defined-KV.git

=head1 AUTHORS

=over 4

=item *

Rob N ★ <robn@robn.io>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Rob N ★

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
