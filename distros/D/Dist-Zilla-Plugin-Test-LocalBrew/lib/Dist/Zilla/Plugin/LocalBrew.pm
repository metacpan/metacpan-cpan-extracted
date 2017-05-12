## no critic (RequireUseStrict)
package Dist::Zilla::Plugin::LocalBrew;
$Dist::Zilla::Plugin::LocalBrew::VERSION = '0.08';
## use critic (RequireUseStrict)
use Moose;

extends 'Dist::Zilla::Plugin::Test::LocalBrew';

before register_component => sub {
    warn "!!! [LocalBrew] is deprecated and may be removed in a future release; replace it with [Test::LocalBrew]\n";
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::LocalBrew - DEPRECATED - Use Test::LocalBrew instead

=head1 VERSION

version 0.08

=head1 SYNOPSIS

This module is deprecated; please use L<Dist::Zilla::Plugin::Test::LocalBrew>
instead.

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hoelzro/dist-zilla-plugin-test-localbrew/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__END__

# ABSTRACT: DEPRECATED - Use Test::LocalBrew instead

