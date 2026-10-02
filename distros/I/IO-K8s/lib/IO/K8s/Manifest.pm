package IO::K8s::Manifest;
# ABSTRACT: Internal collector for loading .pk8s manifest files
our $VERSION = '1.110';
use v5.10;
use strict;
use warnings;
use Moo;
use Carp qw(croak);
use Package::Stash;

# Carp treats IO::K8s as part of this module (k175), the way IO::K8s::CRD
# does (k165): the "Cannot open" IO::K8s->_slurp_utf8 raises for a manifest
# that cannot be read names the line that called IO::K8s->load, not the
# read in _load_file below. A caller in any other package -- the manifest
# calling var(), say -- still sees its own line.
our @CARP_NOT = ('IO::K8s');

# Runs a manifest's source, returning $@ (k163). Defined here, above every
# lexical of this file, so the string eval sees none of them: it used to
# run inside _load_file, where a manifest could read -- and under
# `use strict` compile against -- $file, $k8s, $vars and the collector $m,
# and the `our $_collector` alias below. `our $VERSION` above stays in
# view: it has to come first in every module of the distribution, and a
# stray $VERSION in a manifest only reaches this package's version string.
# No `my` on purpose: the invocant is dropped and the source shifted off,
# so @_ is empty by the time the manifest runs.
sub _eval_manifest {
    shift;
    eval shift;
    return $@;
}

# Current collector during evaluation
our $_collector;

# Items collected in this manifest
has '_items' => (is => 'ro', default => sub { [] });

# Add resources to manifest
sub add {
    my ($self, @objs) = @_;
    push @{$self->_items}, @objs;
    return $self;
}

# Get all items
sub items {
    my $self = shift;
    return @{$self->_items};
}

# Load .pk8s file - called from IO::K8s->load
sub _load_file {
    my ($class, $file, $k8s, $vars) = @_;

    # Read as UTF-8 (k160), the way load_yaml reads a file (k159): a
    # non-ASCII literal in a manifest gives the same characters as the same
    # value in YAML instead of its UTF-8 bytes. A manifest that says
    # `use utf8;` itself gets the same characters -- the source handed to
    # the eval below already is characters.
    my $content = $k8s->_slurp_utf8($file);

    # Create manifest collector
    my $m = $class->new;

    # Each load evaluates the file in a package of its own and removes that
    # package again afterwards, also when the load fails (k160). It holds
    # one DSL sub per known Kind, about 850 KB, and used to stay behind after
    # every call, so a process reloading manifests in a loop grew without
    # bound. Only the stash entry is deleted, not Symbol::delete_package:
    # that one undefs every glob first, which would empty the subs and
    # package variables a closure the manifest handed out still calls. With
    # just the entry gone, whatever is still referenced -- such closures,
    # the globs they use, an object blessed into the package -- lives on,
    # and the rest is freed.
    my $leaf = "_LOADER_$$" . "_" . int(rand(100000));
    my $pkg  = __PACKAGE__ . '::' . $leaf;

    my $ok = eval {
        local $_collector = $m;

        $class->_install_var($pkg, $file, $vars);

        # Build the DSL code with functions for all resource types
        my $dsl_code = _build_dsl_code($k8s);

        # Eval the file content with DSL available, its own line numbers
        # restarting at 1 under the file's name (k163).
        my $failure = $class->_eval_manifest(join "\n",
            'package '.$pkg.';',
            'use strict;',
            'use warnings;',
            $dsl_code,
            $class->_line_directive($file),
            $content);
        die "Error loading $file: $failure" if $failure;
        1;
    };
    my $error = $@;
    delete $IO::K8s::Manifest::{ $leaf . '::' };
    die $error unless $ok;

    return [ $m->items ];
}

# The #line directive in front of a manifest's source, so that die, warn
# and compile errors in it name the file and the manifest's own line
# instead of "(eval 273) line 1848" behind the generated DSL subs (k163).
# The directive has no escaping: a name with a double quote or a line
# break cannot be written into it, and one outside printable ASCII would
# come out re-encoded, because the evaluated source is a character string.
# Such a name gets the line numbers alone, under the "(eval N)"
# pseudo-file; the "Error loading <file>:" prefix still names the file.
sub _line_directive {
    my ($class, $file) = @_;
    return $file =~ /\A[\x20\x21\x23-\x7e]+\z/ ? '#line 1 "'.$file.'"' : '#line 1';
}

# var() for the manifest evaluated in $pkg (k160): var($name) returns the
# value passed as load($file, vars => { $name => ... }), var($name,
# $default) falls back to $default, and a name with neither dies naming the
# file. A closure over this load's own copy of the values, installed before
# the file compiles so that var(...) parses as a call -- and lower case, so
# it can never be taken for a Kind function. The values are never
# interpolated into code.
sub _install_var {
    my ($class, $pkg, $file, $vars) = @_;
    my %vars = %{ $vars // {} };
    Package::Stash->new($pkg)->add_symbol('&var', sub {
        my ($name, @default) = @_;
        croak 'var() needs a name in '.$file unless defined $name;
        return $vars{$name} if exists $vars{$name};
        return $default[0] if @default;
        croak "var('".$name."'): no value passed to ".$file.' and no default given';
    });
    return;
}

# The package the bodies of the generated Kind functions are compiled in,
# while the functions themselves are named in the loader package (k163).
# It trusts IO::K8s for Carp, so an error new_object croaks with for a Kind
# call -- a field of the wrong shape -- skips the generated function and is
# reported at the manifest line of the call, not at "(eval 273) line 1674".
# The functions themselves have to be named in the loader package, where
# the manifest calls them unqualified, and that package cannot be the one
# to trust IO::K8s: Carp never stops between two frames of one package, so
# it would skip the manifest's own frames too and land in this file.
my $DSL_BODY_PACKAGE = __PACKAGE__.'::_DSL';
Package::Stash->new($DSL_BODY_PACKAGE)->add_symbol('@CARP_NOT', ['IO::K8s']);

# Build DSL code with resource functions
sub _build_dsl_code {
    my ($k8s) = @_;

    my $code = '';

    # Get all resource types from the k8s instance
    my $map = $k8s->resource_map;

    for my $kind (keys %$map) {
        # Skip domain-qualified names (contain /) - not valid Perl identifiers
        next if $kind =~ m{/};

        $code .= qq{
            sub $kind (&@) {
                package $DSL_BODY_PACKAGE;
                my \$block = shift;
                my \$api_version = shift;
                my \%args = \$block->();

                # Convenience: move name/namespace/labels/annotations to metadata
                for my \$key (qw(name namespace labels annotations)) {
                    if (exists \$args{\$key}) {
                        \$args{metadata}{\$key} = delete \$args{\$key};
                    }
                }

                my \$k8s = \$IO::K8s::Manifest::_k8s_instance;
                my \$obj = \$api_version
                    ? \$k8s->new_object('$kind', \\\%args, \$api_version)
                    : \$k8s->new_object('$kind', \\\%args);

                \$IO::K8s::Manifest::_collector->add(\$obj)
                    if \$IO::K8s::Manifest::_collector;

                return \$obj;
            }
        };
    }

    return $code;
}

# K8s instance for DSL functions (set during load)
our $_k8s_instance;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Manifest - Internal collector for loading .pk8s manifest files

=head1 VERSION

version 1.110

=head1 DESCRIPTION

This is an internal class used by L<IO::K8s/load> to load C<.pk8s> manifest
files. You should not use this class directly.

See L<IO::K8s/load> for documentation on loading manifest files.

=head1 NAME

IO::K8s::Manifest - Internal collector for loading .pk8s manifest files

=head1 SEE ALSO

L<IO::K8s>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
