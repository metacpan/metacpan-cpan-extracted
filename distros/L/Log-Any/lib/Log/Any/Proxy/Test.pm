use 5.008001;
use strict;
use warnings;

package Log::Any::Proxy::Test;

our $VERSION = '1.710';

use Log::Any::Proxy;
our @ISA = qw/Log::Any::Proxy/;

my @test_methods = qw(
  msgs
  clear
  contains_ok
  category_contains_ok
  does_not_contain_ok
  category_does_not_contain_ok
  empty_ok
  contains_only_ok
);

foreach my $name (@test_methods) {
    no strict 'refs';
    *{$name} = sub {
        my $self = shift;
        $self->{adapter}->$name(@_);
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Proxy::Test

=head1 VERSION

version 1.710

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

David Golden <dagolden@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=item *

Daniel Pittman <daniel@rimspace.net>

=item *

Stephen Thirlwall <sdt@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jonathan Swartz, David Golden, and Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
