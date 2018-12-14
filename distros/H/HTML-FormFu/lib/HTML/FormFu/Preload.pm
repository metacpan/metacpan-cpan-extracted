use strict;

package HTML::FormFu::Preload;
# ABSTRACT: preload plugins
$HTML::FormFu::Preload::VERSION = '2.07';
use warnings;

use HTML::FormFu;

use Module::Pluggable (
    search_path => [ qw(
            HTML::FormFu::Element
            HTML::FormFu::Constraint
            HTML::FormFu::Deflator
            HTML::FormFu::Filter
            HTML::FormFu::Inflator
            HTML::FormFu::Transformer
            HTML::FormFu::Validator
            HTML::FormFu::Plugin
            HTML::FormFu::OutputProcessor
            )
    ],
    require => 1
);

__PACKAGE__->plugins;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Preload - preload plugins

=head1 VERSION

version 2.07

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
