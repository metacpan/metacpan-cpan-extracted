package IO::K8s::Role::SpecBuilder;
# ABSTRACT: Role for deep-path spec manipulation on CRD objects
our $VERSION = '1.008';
use Moo::Role;
use Scalar::Util qw(looks_like_number);

sub _walk_path {
    my ($data, $path, $vivify) = @_;
    my @parts = split /\./, $path;
    my $last_key = pop @parts;
    my $current = $data;

    for my $part (@parts) {
        if (ref $current eq 'ARRAY' && $part =~ /^\d+$/) {
            if ($vivify && !defined $current->[$part]) {
                $current->[$part] = {};
            }
            $current = $current->[$part];
        } elsif (ref $current eq 'HASH') {
            if ($vivify && !defined $current->{$part}) {
                # Look ahead: if next step is numeric, create array
                my $idx = 0;
                for my $p (@parts, $last_key) {
                    last if $p eq $part;
                    $idx++;
                }
                $current->{$part} = {};
            }
            $current = $current->{$part};
        } else {
            return (undef, undef) unless $vivify;
            return (undef, undef);
        }
    }

    return ($current, $last_key);
}

sub spec_get {
    my ($self, $path) = @_;
    my $spec = $self->spec;
    return undef unless ref $spec eq 'HASH';

    my @parts = split /\./, $path;
    my $current = $spec;

    for my $part (@parts) {
        if (ref $current eq 'ARRAY' && $part =~ /^\d+$/) {
            $current = $current->[$part];
        } elsif (ref $current eq 'HASH') {
            $current = $current->{$part};
        } else {
            return undef;
        }
        return undef unless defined $current;
    }

    return $current;
}

sub spec_set {
    my ($self, $path, $value) = @_;
    my $spec = $self->spec;
    unless (ref $spec eq 'HASH') {
        $spec = {};
        $self->spec($spec);
    }

    my @parts = split /\./, $path;
    my $last_key = pop @parts;
    my $current = $spec;

    for my $part (@parts) {
        if (ref $current eq 'ARRAY' && $part =~ /^\d+$/) {
            $current->[$part] = {} unless ref $current->[$part];
            $current = $current->[$part];
        } elsif (ref $current eq 'HASH') {
            $current->{$part} = {} unless ref $current->{$part};
            $current = $current->{$part};
        }
    }

    if (ref $current eq 'ARRAY' && $last_key =~ /^\d+$/) {
        $current->[$last_key] = $value;
    } elsif (ref $current eq 'HASH') {
        $current->{$last_key} = $value;
    }

    return $self;
}

sub spec_push {
    my ($self, $path, @values) = @_;
    my $spec = $self->spec;
    unless (ref $spec eq 'HASH') {
        $spec = {};
        $self->spec($spec);
    }

    my @parts = split /\./, $path;
    my $last_key = pop @parts;
    my $current = $spec;

    for my $part (@parts) {
        if (ref $current eq 'ARRAY' && $part =~ /^\d+$/) {
            $current->[$part] = {} unless ref $current->[$part];
            $current = $current->[$part];
        } elsif (ref $current eq 'HASH') {
            $current->{$part} = {} unless ref $current->{$part};
            $current = $current->{$part};
        }
    }

    if (ref $current eq 'ARRAY' && $last_key =~ /^\d+$/) {
        $current->[$last_key] = [] unless ref $current->[$last_key] eq 'ARRAY';
        push @{$current->[$last_key]}, @values;
    } elsif (ref $current eq 'HASH') {
        $current->{$last_key} = [] unless ref $current->{$last_key} eq 'ARRAY';
        push @{$current->{$last_key}}, @values;
    }

    return $self;
}

sub spec_merge {
    my ($self, %data) = @_;
    my $spec = $self->spec;
    unless (ref $spec eq 'HASH') {
        $spec = {};
        $self->spec($spec);
    }
    @{$spec}{keys %data} = values %data;
    return $self;
}

sub spec_delete {
    my ($self, $path) = @_;
    my $spec = $self->spec;
    return $self unless ref $spec eq 'HASH';

    my @parts = split /\./, $path;
    my $last_key = pop @parts;
    my $current = $spec;

    for my $part (@parts) {
        if (ref $current eq 'ARRAY' && $part =~ /^\d+$/) {
            $current = $current->[$part];
        } elsif (ref $current eq 'HASH') {
            $current = $current->{$part};
        } else {
            return $self;
        }
        return $self unless defined $current;
    }

    if (ref $current eq 'HASH') {
        delete $current->{$last_key};
    } elsif (ref $current eq 'ARRAY' && $last_key =~ /^\d+$/) {
        splice @$current, $last_key, 1;
    }

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::SpecBuilder - Role for deep-path spec manipulation on CRD objects

=head1 VERSION

version 1.008

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
