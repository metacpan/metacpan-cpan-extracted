use strict;
use warnings;

package Getopt::Long::Spec::Builder;
{
  $Getopt::Long::Spec::Builder::VERSION = '0.002';
}

# ABSTRACT: Build a Getopt::Long option spec from a set of attributes
use Carp;
use Data::Dumper;

our %DATA_TYPE_MAP = (
    integer => 'i',
    int     => 'i',
    string  => 's',
    str     => 's',
    float   => 'f',
    extint  => 'o',
    ext     => 'o',
);

our %DEST_TYPE_MAP = (
    'array'  => '@',
    'hash'   => '%',
    'scalar' => '',
);

sub new {
    my ( $class, %params ) = @_;
    my $self = bless {%params}, $class;
    return $self;
}

sub build {
    my ( $self, %params ) = @_;

    my $name_spec = $self->_build_name_spec( \%params );

    my $spec_type = $self->_spec_type( \%params );

    croak "default only valid when spec type is ':'\n"
        if $params{default_num} and $spec_type ne ':';

    my $arg_spec = ( $spec_type =~ /[:=]/ ) ? $self->_build_arg_spec( \%params ) : '';

    my $spec = $name_spec . $spec_type . $arg_spec;

    return $spec;
}

sub _build_name_spec {
    my ( $self, $params ) = @_;

    $params->{aliases} ||= [] unless exists $params->{aliases};
    croak "option parameter [aliases] must be an array ref\n"
        unless ref $params->{aliases} eq 'ARRAY';

    my $name_spec = join( '|',
        grep { defined $_ and length $_ }
        $params->{long},
        $params->{short},
        @{ $params->{aliases} }
    );

    return $name_spec;
}

sub _spec_type {
    my ( $self, $params ) = @_;

    # note: keep in mind - order is important here!
    return ':' if defined $params->{val_required} and $params->{val_required} == 0;
    return '=' if $params->{val_required};
    return '!' if $params->{negatable};
    return ''  unless defined $params->{opt_type};
    return '+' if $params->{opt_type} =~ '^incr';
    return ''  if $params->{opt_type} eq 'flag';
    return ':' if defined $params->{default_num}
        or defined $params->{val_type}
        or defined $params->{destination}
        or defined $params->{dest_type};

    die "Could not determine option type from spec!\n";
}

sub _build_arg_spec {
    my ( $self, $params ) = @_;

    my $val_type = $DATA_TYPE_MAP{ lc( $params->{val_type} || 'str' ) }
        or croak "invalid value type [$params->{val_type}]\n";

    # special cases for incremental opts or opts with default numeric value
    $val_type = $params->{default_num} if $params->{default_num};
    $val_type = '+' if $params->{opt_type} =~ /^incr/ and !$params->{val_type};

    # empty or missing destination type is allowable, so this accounts for that.
    my $dest_type = !$params->{dest_type} ? '' : $DEST_TYPE_MAP{ $params->{dest_type} };
    croak "invalid destination type [@{[ $params->{dest_type} || '' ]}]\n"
        unless defined $dest_type;

    # ah, the little-understood "repeat" clause
    my $repeat = '';
    if ( defined $params->{min_vals} || defined $params->{max_vals} ) {
        croak "repeat spec not valid when using default value\n" if $params->{default_num};
        $repeat .= '{';
        $repeat .= $params->{min_vals} if defined $params->{min_vals};
        $repeat .= "," . ( defined $params->{max_vals} ? $params->{max_vals} : '' )
            if exists $params->{max_vals};
        $repeat .= '}';
    }
    elsif ( defined $params->{num_vals} ) {
        $repeat .= "{$params->{num_vals}}";
    }

    return $val_type . $dest_type . $repeat;
}

1 && q{this is probably crazier than the last thing I wrote};  # truth


=pod

=head1 NAME

Getopt::Long::Spec::Builder - Build a Getopt::Long option spec from a set of attributes

=head1 VERSION

version 0.002

=head1 SYNOPSIS

This module builds a Getopt::Long option specification from a hash of option
parameters as would be returned by Getopt::Long::Spec::Parser->parse($spec)
and/or Getopt::Nearly::Everything->opt($opt_name)->attrs().

Here's an example of use:

    use Getopt::Long::Spec::Builder;

    my %opt_attrs = (
        opt_type       => 'simple'
        value_required => 1,
        value_type     => 'string',
        max_vals       => '5',
        dest_type      => 'array',
        min_vals       => '1',
        short          => [ 'f' ],
        long           => 'foo',
    );

    my $builder   = Getopt::Long::Spec::Builder->new();
    my $spec      = $builder->build( %opt_attrs );
    print $spec;  # output: 'foo|f=s@{1,5}'

    # OR...

    my $spec =
        Getopt::Long::Spec::Builder->build( %opt_attrs );

=head1 METHODS

=head2 new

Create a new builder object.

=head2 build

Build a Getopt::Long option specification from the attributes passed in
and return the spec as a string

=head1 SEE ALSO

=over 4

=item * Getopt::Long - info on option specifications

=item * Getopt::Long::Spec - parse and build GoL specifications

=item * Getopt::Long::Spec::Parser - parse GoL specifications

=item * Getopt::Nearly::Everything - the module for which this module was created

=back

=head1 AUTHOR

Stephen R. Scaffidi <sscaffidi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Stephen R. Scaffidi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

