package LWP::Authen::OAuth2::Args;

# ABSTRACT: Args
our $VERSION = '0.20'; # VERSION

use warnings;
use strict;

use Carp qw(croak confess);

use Exporter qw(import);

our @EXPORT_OK = qw(extract_option copy_option assert_options_empty);

# Blessed empty hash.
sub new {
    return bless {}, shift;
}

sub extract_option {
    my $obj = shift;
    my $opts = shift;
    my $name = shift;
    my $has_default = @_;
    my $default = shift;

    if (exists $opts->{$name}) {
        return delete $opts->{$name};
    }
    elsif ($has_default) {
        return $default;
    }
    else {
        croak("'$name' is required, cannot be missing");
    }
}

sub copy_option {
    my $obj = shift;
    my $opts = shift;
    my $name = shift;
    my $has_default = @_;
    my $default = shift;

    if (not exists $obj->{$name}) {
        if (exists $opts->{$name}) {
            my $value = delete $opts->{$name};
            if (defined($value)) {
                $obj->{$name} = $value;
            }
            elsif ($has_default) {
                $obj->{$name} = $default;
            }
            else {
                croak("'$name' is required, cannot be undef");
            }
        }
        elsif ($has_default) {
            $obj->{$name} = $default;
        }
        else {
            croak("'$name' is required, cannot be missing");
        }
    }
    elsif (exists $opts->{$name}) {
        # This should not be hit, but if it was, it would be confusing
        confess("Refusing to copy '$name' that is already in hash");
    }
}

sub assert_options_empty {
    my ($obj, $opts) = @_;
    my @keys = sort keys %$opts;
    if (1 == @keys) {
        croak("Unexpected parameter: '$keys[0]'");
    }
    elsif (@keys) {
        my $extra = "'" . (join "', '", @keys) . "'";
        croak("Extra parameters: $extra");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Authen::OAuth2::Args - Args

=head1 VERSION

version 0.20

=head1 AUTHORS

=over 4

=item *

Ben Tilly, <btilly at gmail.com>

=item *

Thomas Klausner <domm@plix.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2022 by Ben Tilly, Rent.com, Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
