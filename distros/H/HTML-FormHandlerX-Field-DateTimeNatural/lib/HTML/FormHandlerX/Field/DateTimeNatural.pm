package HTML::FormHandlerX::Field::DateTimeNatural;

# ABSTRACT: a datetime field with natural language parsing.

use version; our $VERSION = version->declare('v0.6');

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';

use MooseX::Types::DateTime;
use DateTime::Format::Natural;

has 'datetime_format_natural' => (
    is         => 'ro',
    isa        => 'DateTime::Format::Natural',
    lazy_build => 1,
    required   => 1,
);

has 'datetime' => (
    is  => 'rw',
    isa => 'DateTime',
);

has 'lang' => (
    is  => 'rw',
    isa => 'Str',
);

has 'format' => (
    is  => 'rw',
    isa => 'Str',
);

has 'prefer_future' => (
    is  => 'rw',
    isa => 'Bool',
);

has 'time_zone' => (
    is     => 'rw',
    isa    => 'DateTime::TimeZone',
    coerce => 1,
);

has 'daytime' => (
    is  => 'rw',
    isa => 'HashRef',
);

our $class_messages = { 'date_invalid' => 'Date is invalid.', };

sub get_class_messages {
    my $self = shift;
    return { %{ $self->next::method }, %{$class_messages}, };
}

sub validate {
    my $self  = shift;
    my $value = $self->value;

    ## validate
    my $parser = $self->datetime_format_natural;
    my $dt     = $parser->parse_datetime($value);

    ## update to inflated value or set error
    if ($parser->success) {
        $self->_set_value($dt);
    } else {
        $self->add_error($self->get_message('date_invalid'));
    }

    ## return
    return $parser->success;
}

sub _build_datetime_format_natural {
    my $self = shift;

    my %attributes;
    my $form = $self->form;
    foreach
        my $attr (qw/datetime time_zone lang format prefer_future daytime/)
    {
        if (defined $self->$attr) {
            $attributes{$attr} = $self->$attr;
        } elsif ($form
            && $form->meta->find_attribute_by_name($attr)
            && defined $form->$attr)
        {
            $attributes{$attr} = $form->$attr;
        }
    }

    ## Fix time_zone if set, because DT::F::N can only accept time zone
    ## names and not objects, at the time of writing this module.
    if ($attributes{time_zone}) {
        $attributes{time_zone} = $attributes{time_zone}->name;
    }

    return DateTime::Format::Natural->new(%attributes);
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=head1 NAME

HTML::FormHandlerX::Field::DateTimeNatural - a datetime field with natural language parsing.

=head1 VERSION

version v0.6

=head1 SYNOPSIS

This field is a simple text input field type, but it understands natural
language and dates. Most of the functionality is inherited from
L<DateTime::Format::Natural>. To see a list of dates it can understand see
L<DateTime::Format::Natural::Lang::EN>.

  has_field 'date' => (
    type      => 'DateTimeNatural',
    time_zone => 'UTC', # optional
  );

=head1 METHODS

This field supports all of the methods inherited from
L<HTML::FormHandler::Field::Text>, as well as all of the parameters offered by
L<DateTime::Format::Natural>, all of which are optional.

In addition to that, it will try to obtain the values for these attributes
from the parent form class. E.g. you can set the C<time_zone> attribute on the
form class, and all of the C<DateTimeNatural> fields will automatically have
the time zone set.

Here is the list of the methods, please refer to original module for
their description:

=over 4

=item * time_zone

=item * datetime

=item * lang

=item * format

=item * prefer_future

=item * daytime

=back

=head1 SEE ALSO

=over 4

=item * L<HTML::FormHandler>

=item * L<HTML::FormHandler::Field::Text>

=item * L<DateTime::Format::Natural>

=item * L<DateTime::Format::Natural::Lang::EN>

=back

=head1 AUTHOR

Roman F. <romanf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Roman F..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
