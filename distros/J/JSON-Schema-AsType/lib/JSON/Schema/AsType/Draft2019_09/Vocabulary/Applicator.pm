package JSON::Schema::AsType::Draft2019_09::Vocabulary::Applicator;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft2019_09::Vocabulary::Applicator::VERSION = '1.0.0';
# ABSTRACT: Applicator vocabulary for draft 2019-09 schemas


use 5.42.0;
use warnings;

use feature qw/ module_true /;

use Moose::Role;

with 'JSON::Schema::AsType::Draft7::Keywords' => {
    -excludes => [
        map { "_keyword_$_" } qw/ minimum /,
        '$id',
        '$ref',

        # "properties",
        # "items",
        # "patternProperties",
        # "additionalProperties",
        # "additionalItems",
        # "allOf",
        # "anyOf",
        # "oneOf",
        # "if",
        "multipleOf",
        "uniqueItems",
        "minItems",
        "exclusiveMaximum",

        # "const",
        # "dependencies",
        "exclusiveMinimum",
        "maxProperties",
        "minLength",
        "pattern",

        # "enum",
        # "definitions",
        # "required",
        "contains",
        "maximum",
        "maxItems",
        "propertyNames",
        "minProperties",
        "maxLength",

        # "type",
        # "not"
    ]
};

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft2019_09::Vocabulary::Applicator - Applicator vocabulary for draft 2019-09 schemas

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION

This role is not intended to be used directly. It is used internally
by L<JSON::Schema::AsType> objects.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
