package Method::Traits::Meta::Provider;
# ABSTRACT: Traits for Trait Providers

use strict;
use warnings;

our $VERSION   = '0.05';
our $AUTHORITY = 'cpan:STEVAN';

sub OverwritesMethod { () }

1;

__END__

=pod

=head1 NAME

Method::Traits::Meta::Provider - Traits for Trait Providers

=head1 VERSION

version 0.05

=head1 DESCRIPTION

This is a trait provider which contains some useful traits
for people who are writing trait providers.

=head1 TRAITS

=head2 OverwritesMethod

This means that the trait handler will overwrite the
method with another copy. This means we need to re-fetch
the method before we run additional trait handlers.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
