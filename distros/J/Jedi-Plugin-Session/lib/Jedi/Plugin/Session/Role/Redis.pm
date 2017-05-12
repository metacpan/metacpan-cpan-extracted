#
# This file is part of Jedi-Plugin-Session
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Session::Role::Redis;

# ABSTRACT: Redis Backend

use strict;
use warnings;
our $VERSION = '0.05';    # VERSION

use Jedi::Plugin::Session::Backend::Redis;
use Moo::Role;

sub _build__jedi_session {
    my ($self)     = @_;
    my $class      = ref $self;
    my $expires_in = $self->jedi_config->{$class}{session}{expiration}
        // '3 hours';
    my $redis_config = $self->jedi_config->{$class}{session}{redis}{config};
    my $redis_prefix = $self->jedi_config->{$class}{session}{redis}{prefix};
    return Jedi::Plugin::Session::Backend::Redis->new(
        config     => $redis_config,
        expires_in => $expires_in,
        prefix     => $redis_prefix
    );
}

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Session::Role::Redis - Redis Backend

=head1 VERSION

version 0.05

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi-plugin-session/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
