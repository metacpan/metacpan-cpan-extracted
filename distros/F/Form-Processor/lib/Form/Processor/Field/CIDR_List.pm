package Form::Processor::Field::CIDR_List;
$Form::Processor::Field::CIDR_List::VERSION = '1.162360';
use strict;
use warnings;
use base 'Form::Processor::Field::Text';


use Net::CIDR;

sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $input = $self->input || return 1;

    for my $addr ( split /\s+/, $input ) {

        # Is it a plain ip address?
        next if Net::CIDR::cidrvalidate( $addr );

        # If not see if it blows up in a cidr check
        eval { Net::CIDR::cidrlookup( '192.168.1.1', $addr ) };
        next unless $@;


        return $self->add_error( "Failed to parse address '[_1]'", $addr );
    }

    return 1;
}


# ABSTRACT: Muliplt CIDR addresses



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Processor::Field::CIDR_List - Muliplt CIDR addresses

=head1 VERSION

version 1.162360

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Allow entry of multiple CIDR formatted IP addresses and masks.
This field simply splits and validates the addresses using L<Net::CIDR>'s
L<cidrvalidate> function and tests if L<cidrlookup> thows an exception when
attempting to lookup an IP addres.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Text";

=head1 DEPENDENCIES

L<Net::CIDR>

=head1 SUPPORT / WARRANTY

L<Form::Processor> is free software and is provided WITHOUT WARRANTY OF ANY KIND.
Users are expected to review software for fitness and usability.

=head1 AUTHOR

Bill Moseley <mods@hank.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Bill Moseley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
