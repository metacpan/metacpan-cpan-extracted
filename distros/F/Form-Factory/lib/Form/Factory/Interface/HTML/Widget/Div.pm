package Form::Factory::Interface::HTML::Widget::Div;
$Form::Factory::Interface::HTML::Widget::Div::VERSION = '0.022';
use Moose;

extends qw( Form::Factory::Interface::HTML::Widget::Element );

# ABSTRACT: HTML interface widget helper


has '+tag_name' => (
    default   => 'div',
);

has widgets => (
    is        => 'ro',
    isa       => 'ArrayRef',
    required  => 1,
    default   => sub { [] },
);

sub has_content { 1 }

sub render_widgets {
    my $self = shift;
    my $content = '';
    for my $widget (@{ $self->widgets }) {
        $content .= $widget->render;
    }
    return $content;
}

override render => sub {
    my $self = shift;
    return super() . $self->render_widgets;
};

sub consume_control {
    my $self = shift;
    my %args_accumulator;

    %args_accumulator = (%args_accumulator, %{ $_->consume(@_) || {} }) 
        for @{ $self->widgets };

    return \%args_accumulator;
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Interface::HTML::Widget::Div - HTML interface widget helper

=head1 VERSION

version 0.022

=head1 DESCRIPTION

Move along. Nothing to see here.

=for Pod::Coverage   .*

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
