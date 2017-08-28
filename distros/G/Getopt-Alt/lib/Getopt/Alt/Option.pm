package Getopt::Alt::Option;

# Created on: 2009-07-17 14:52:26
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Moose::Role;
use Carp;
use English qw/ -no_match_vars /;
use Getopt::Alt::Exception;

Moose::Exporter->setup_import_methods(
    as_is     => [qw/build_option/],
    #with_meta => ['operation'],
);

our $VERSION = version->new('0.4.5');

Moose::Util::meta_attribute_alias('Getopt::Alt::Option');

has opt => (
    is       => 'ro',
    required => 1,
);
has name => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);
has names => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    required => 1,
);
has increment => (
    is  => 'rw',
    isa => 'Bool',
);
has number => (
    is  => 'rw',
    isa => 'Bool',
);
has negatable => (
    is  => 'rw',
    isa => 'Bool',
);
has nullable => (
    is  => 'rw',
    isa => 'Bool',
);
has config => (
    is  => 'ro',
    isa => 'Bool',
);
has project => (
    is  => 'ro',
    isa => 'Bool',
);
has ref => (
    is  => 'ro',
    isa => 'Str',
);
has type => (
    is  => 'ro',
    isa => 'Str',
);
has value => (
    is        => 'rw',
    isa       => 'Any',
    predicate => 'has_value',
);
has values => (
    is        => 'rw',
    isa       => 'ArrayRef',
    predicate => 'has_values',
);

my $r_name     = qr/ [^|\s=+!?@%-][^|\s=+!?@%]* /xms;
my $r_alt_name = qr/ $r_name | \\d /xms;
my $r_names    = qr/ $r_name (?: [|] $r_alt_name)* /xms;
my $r_type     = qr/ [nifsd] /xms;
my $r_ref      = qr/ [%@] /xms;
my $r_sub_val  = qr/ [\w-]+ /xms;
my $r_values   = qr/ \[ $r_sub_val (?: [|] $r_sub_val )* \] /xms;
my $r_type_ref = qr/ = (?: $r_type $r_ref? | $r_values ) /xms;
my $r_inc      = qr/ [+] /xms;
my $r_number   = qr/ [+][+] /xms;
my $r_neg      = qr/ [!] /xms;
my $r_null     = qr/ [?] /xms;
my $r_spec     = qr/^ ( $r_names ) ( $r_inc | $r_number | $r_neg | $r_type_ref )? ( $r_null )? $/xms;

# calling new => ->new( 'test|t' )
#                ->new( name => 'text', names => [qw/test tes te t/], ... )
#                ->new({ name => 'text', names => [qw/test tes te t/], ... )
sub build_option {
    my ($class, @params) = @_;

    if (@params == 1 && ref $params[0]) {
        @params =
              ref $params[0] eq 'ARRAY' ? @{ $params[0] }
            : ref $params[0] eq 'HASH'  ? %{ $params[0] }
            :                             confess "Can't supply a " . (ref $params[0]) . " ref to new!";
    }

    # construct attribute params string if one element
    if (@params == 1) {
        my $spec = pop @params;
        push @params, (opt => $spec);

        confess "$spec doesn't match the specification definition! (qr/$r_spec/)" if $spec !~ /$r_spec/xms;

        my ($names, $options, $null) = $spec =~ /$r_spec/xms;
        my @names = split /\|/xms, $names;
        push @params, 'names', \@names;
        push @params, 'name', $names[0];

        if ($null) {
            push @params, 'nullable' => 1;
        }

        if ($options) {
            my ($type, $extra);
            my ($option) = substr $options, 0, 1;

            if ($option eq '=') {
                ($type, $extra) = split /;/xms, $options;
            }
            elsif ($options eq '++') {
                push @params, 'increment' => 1;
                push @params, 'number'    => 1;
                push @params, 'type'      => 'Int';
            }
            elsif ($option eq '+') {
                push @params, 'increment' => 1;
            }
            else {
                # $option == !
                push @params, 'negatable' => 1;
            }

            if ($type) {
                my ($text, $ref);
                $type =~ s/^=//xms;

                if ( length $type == 1 ) {
                    ($text) = $type =~ /^ ($r_type) $/xms;
                }
                elsif ( length $type == 2 ) {
                    ($text, $ref) = $type =~ /^ ($r_type) ($r_ref) $/xms;
                    push @params, ref => $ref eq '%' ? 'HashRef' : 'ArrayRef';
                }
                else {
                    $type =~ s/(?: ^\[ | \]$ )//gxms;
                    my @values = split /[|]/, $type;
                    $text = 's';
                    push @params, values => \@values;
                }

                push @params,
                    type =>
                          $text eq 'd' ? 'Int'
                        : $text eq 'i' ? 'Int'
                        : $text eq 'f' ? 'Num'
                        : $text eq 'n' ? 'Num'
                        :                'Str';
            }
        }
    }

    my %params = @params;
    $params{traits} = ['Getopt::Alt::Option'];

    my $type
        = $params{type} && $params{ref} ? "$params{ref}\[$params{type}\]"
        : $params{type}                 ? $params{type}
        :                                 'Str';

    if ( $params{nullable} ) {
        $type = "Maybe[$type]";
    }

    $class->add_attribute(
        $params{name},
        is   => 'rw',
        isa  => $type,
        %params,
    );

    return $class->get_attribute( $params{name} );
}

sub process {
    my ($self, $long, $short, $arg_data, $args) = @_;

    my $name = $long ? "--$long" : "-$short";
    my $value;
    my $used = 0;
    if ($self->type) {
        $used = 1;
        if ( !defined $arg_data || length $arg_data == 0 ) {
            if (
                ( ! defined $args->[0]  && !$self->nullable )
                || (
                    $args->[0]
                    && $args->[0] =~ /^-/xms
                    && !( $self->type eq 'Int' || $self->type eq 'Num' )
                )
            ) {
                die [
                    Getopt::Alt::Exception->new(
                        message => "The option '$name' requires an " . $self->type . " argument\n",
                        option  => $name,
                        type    => $self->type
                    )
                ];
            }

            $arg_data = shift @$args;
        }
        elsif ( $arg_data && !$self->nullable ) {
            $arg_data =~ s/^=//xms;
        }

        my $key;
        if ($self->ref && $self->ref eq 'HashRef') {
            ($key, $arg_data) = split /=/xms, $arg_data, 2;
        }

        $DB::single = 1;
        $value = $arg_data;

        if ( $self->nullable && ( ! defined $arg_data || $arg_data eq '' ) ) {
            $value = undef;
        }
        elsif ( $self->type eq 'Int' ) {
            confess "$name '$arg_data' is not an integer!" if $arg_data !~ /^ -? \d+ $/xms;
        }
        elsif ( $self->type eq 'Num' ) {
            confess "$name '$arg_data' is not a number!" if $arg_data !~ /^ -? (?: \d* (?: [.]\d+ )? | \d+ ) $/xms;
        }
        elsif ( $self->type ne 'Str' ) {
            confess "Unknown type '".$self->type."'\n";
        }

        if ($self->values && !grep { $value eq $_ } @{ $self->values }) {
            die [ Getopt::Alt::Exception->new(
                    message => "The option '$name' must be one of " . ( join ', ', @{ $self->values } ) . "\n",
                    option  => $name,
                    type    => $self->type
                ) ]
        }

        if ($self->ref) {
            my $old;
            if ($self->ref eq 'ArrayRef') {
                $old = $self->value || [];
                push @$old, $value;
            }
            else {
                $old = $self->value || {};
                $old->{$key} = $value;
            }
            $value = $old;
        }
    }
    elsif ($self->increment) {
        $value = ($self->value || 0) + 1;
    }
    elsif ($self->negatable) {
        $value = $long && $long =~ /^no-/xms ? 0 : 1;
    }
    else {
        $value = 1;
    }

    $self->value($value);

    return ( $self->value, $used );
}

1;

__END__

=head1 NAME

Getopt::Alt::Option - Sets up a particular command line option

=head1 VERSION

This documentation refers to Getopt::Alt::Option version 0.4.5.

=head1 SYNOPSIS

   use Getopt::Alt::Option;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<build_option ( $class, @params )>

This is a helper function to create an C<Getopt::Alt::Option> attribute on the
supplied C<$class> object.

=head2 C<process ($long, $short, $arg_data, $args)>

Processes the option against the supplied $arg_data or $args->[0] if no $arg_data is set

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
