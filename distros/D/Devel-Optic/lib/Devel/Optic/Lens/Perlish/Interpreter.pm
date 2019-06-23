package Devel::Optic::Lens::Perlish::Interpreter;
$Devel::Optic::Lens::Perlish::Interpreter::VERSION = '0.012';
# ABSTRACT: Basic recursive interpreter for Perlish lens

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(run);

use Carp qw(croak);
our @CARP_NOT = qw(Devel::Optic::Lens::Perlish Devel::Optic);

use Devel::Optic::Lens::Perlish::Constants qw(:all);

use Scalar::Util qw(looks_like_number);
use Ref::Util qw(is_arrayref is_hashref is_refref is_scalarref is_ref);

sub run {
    my ($scope, $ast) = @_;
    my ($type, $payload) = @$ast;
    if ($type eq OP_ACCESS) {
        return _access($scope, undef, $ast, $payload);
    }

    if ($type eq SYMBOL) {
        return _symbol($scope, $payload);
    }

    croak sprintf("invalid query: %s does not start with access or symbol",
        _ast_to_code($ast),
    );
}

sub _access {
    my ($scope, $parent, $self, $children) = @_;

    my ($left, $right) = @$children;

    my ($l_arg, $r_arg);
    my ($l_type, $l_val) = @$left;
    my ($r_type, $r_val) = @$right;

    if ($l_type eq SYMBOL) {
        $l_arg = _symbol($scope, $l_val);
    }

    if ($l_type eq OP_ACCESS) {
        $l_arg = _access($scope, $self, $left, $l_val);
    }

    if ($r_type eq OP_ACCESS) {
        die "an access can't be followed directly by another access. the parser admitted an invalid program. please report this!";
    }

    if ($r_type eq OP_HASHKEY) {
        return _hashkey($scope, $self, $left, $right, $l_arg, $r_val);
    }

    if ($r_type eq OP_ARRAYINDEX) {
        return _arrayindex($scope, $self, $left, $right, $l_arg, $r_val, $left);
    }
}

sub _arrayindex {
    my ($scope, $access_node, $array_node, $index_node, $arrayref, $child) = @_;
    my ($type, $value) = @$child;

    if (!is_arrayref($arrayref)) {
        croak sprintf("invalid array access: '%s' is %s, not array",
            _ast_to_code($array_node),
            _sample_or_ref($arrayref),
        );
    }

    if ($type eq STRING) {
        croak sprintf("invalid array access: can't index '%s' with string '%s'",
            _ast_to_code($array_node),
            $value,
        );
    }

    my $index;
    if ($type eq NUMBER) {
        $index = $value;
    }

    if ($type eq SYMBOL) {
        my $resolved = _symbol($scope, $value);
        if (!looks_like_number($resolved)) {
            croak sprintf("invalid array index in '%s': %s (not a number)",
                _ast_to_code($access_node),
                _resolved_node_or_literal($child, $resolved),
            );
        }

        $index = $resolved;
    }

    if ($type eq OP_ACCESS) {
        my $resolved = _access($scope, $index_node, $child, $value);
        if (!looks_like_number($resolved)) {
            croak sprintf("invalid array index in '%s': %s (not a number)",
                _ast_to_code($access_node),
                _resolved_node_or_literal($child, $resolved),
            );
        }
        $index = $resolved;
    }

    if (defined $index) {
        my $len = scalar @$arrayref;
        # negative indexes need checking too
        if ($len <= $index || ($index < 0 && ((-1 * $index) > $len))) {
            croak sprintf("out of bounds: index %s, but len(%s) == %s",
                _resolved_node_or_literal($child, $index),
                _ast_to_code($array_node),
                $len,
            );
        }

        return $arrayref->[$index];
    }

    # this should only happen when the parser admits an invalid program. which should never happen. in theory.
    die "array index unexpected contents '$type'. please report this, it's a bug in the parser that this query was allowed in";
}

sub _hashkey {
    my ($scope, $access_node, $hash_node, $index_node, $hashref, $key_node) = @_;
    my ($type, $value) = @$key_node;

    if (!is_hashref($hashref)) {
        croak sprintf("invalid hash access: '%s' is %s, not hash",
            _ast_to_code($hash_node),
            defined $hashref ? _sample_or_ref($hashref) : "undef",
        );
    }

    my $key;
    if ($type eq STRING || $type eq NUMBER) {
        $key = $value;
    }

    if ($type eq SYMBOL) {
        my $resolved = _symbol($scope, $value);
        if (is_ref($resolved)) {
            croak sprintf("invalid hash key in '%s': %s",
                _ast_to_code($access_node),
                _resolved_node_or_literal($key_node, $resolved),
            );
        }

        $key = $resolved;
    }

    if ($type eq OP_ACCESS) {
        my $resolved = _access($scope, $index_node, $key_node, $value);
        if (is_ref($resolved)) {
            my $type = ref $resolved;
            my $code = _ast_to_code($value);
            croak sprintf("%s is a(n) %s ref. can't use this to index into hash %s",
                _ast_to_code($key_node),
                ref $resolved,
                _ast_to_code($index_node)
            );
        }

        $key = $resolved;
    }

    if (defined $key) {
        if (!exists $hashref->{$key}) {
            my $hash_source = _ast_to_code($hash_node);
            my $key_source = _ast_to_code($key_node);
            my $key_type = $key_node->[NODE_TYPE];
            my $is_primitive = $key_type eq STRING || $key_type eq NUMBER;
            croak sprintf("invalid hash key: %s is not in %s",
                _resolved_node_or_literal($key_node, $key),
                _ast_to_code($hash_node)
            );
        }

        return $hashref->{$key};
    }

    # this should only happen when the parser admits an invalid program. which should never happen. in theory.
    die "hash key unexpected contents '$type'. please report this, it's a bug in the parser that this query was allowed in";
}

sub _symbol {
    my ($scope, $name) = @_;

    croak "no symbol '$name' in scope" if !exists $scope->{$name};
    my $val = $scope->{$name};
    if (is_refref($val) || is_scalarref($val)) {
        return $$val;
    }

    return $val;
}

sub _resolved_node_or_literal {
    my ($node, $value) = @_;
    my ($type, $payload) = @$node[NODE_TYPE,NODE_PAYLOAD];
    if ($type eq STRING || $type eq NUMBER) {
        return sprintf "'%s'", $payload;
    }

    return sprintf("%s == '%s'",
        _ast_to_code($node),
        _sample_or_ref($value),
    );
}

sub _ast_to_code {
    my ($op) = @_;
    my ($type, $value) = @$op;
    return $value if ($type eq SYMBOL || $type eq NUMBER);
    return "'$value'" if $type eq STRING;

    return '{' . _ast_to_code($value) . '}' if $type eq OP_HASHKEY;
    return '[' . _ast_to_code($value) . ']' if $type eq OP_ARRAYINDEX;

    if ($type eq OP_ACCESS) {
        my ($left, $right) = @$value;
        return sprintf("%s->%s", _ast_to_code($left), _ast_to_code($right));
    }
}

sub _sample_or_ref {
    my $raw = shift;

    if (!defined $raw) {
        return "undefined";
    }

    if (is_ref($raw)) {
        return ref($raw) . "REF";
    }

    if ($raw eq "") {
        return "(empty string)";
    }

    if (length $raw > RAW_DATA_SAMPLE_SIZE) {
        return substr($raw, 0, RAW_DATA_SAMPLE_SIZE) . "...";
    }
    return $raw;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Optic::Lens::Perlish::Interpreter - Basic recursive interpreter for Perlish lens

=head1 VERSION

version 0.012

=head1 AUTHOR

Ben Tyler <btyler@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ben Tyler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
