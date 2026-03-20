package IO::K8s::Manifest;
# ABSTRACT: Internal collector for loading .pk8s manifest files
our $VERSION = '1.009';
use v5.10;
use strict;
use warnings;
use Moo;

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
    my ($class, $file, $k8s) = @_;

    # Read file content
    open my $fh, '<', $file or die "Cannot open $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    # Create manifest collector
    my $m = $class->new;

    {
        local $_collector = $m;

        # Build the DSL code with functions for all resource types
        my $dsl_code = _build_dsl_code($k8s);

        # Eval the file content with DSL available
        my $pkg = "IO::K8s::Manifest::_LOADER_$$" . "_" . int(rand(100000));
        my $eval_code = qq{
            package $pkg;
            use strict;
            use warnings;
            $dsl_code
            $content
        };

        eval $eval_code;
        die "Error loading $file: $@" if $@;
    }

    return [ $m->items ];
}

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

version 1.009

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

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
