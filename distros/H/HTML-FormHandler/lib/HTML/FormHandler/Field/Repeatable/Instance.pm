package    # hide from Pause
    HTML::FormHandler::Field::Repeatable::Instance;
# ABSTRACT: used internally by repeatable fields

use Moose;
extends 'HTML::FormHandler::Field::Compound';


sub BUILD {
    my $self = shift;

    $self->add_wrapper_class('hfh-repinst')
       unless $self->has_wrapper_class;
}

sub build_tags {{ wrapper => 1 }}

has '+do_label' => ( default => 0 );
has '+do_wrapper' => ( default => 1 );
has '+no_value_if_empty' => ( default => 1 );

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Repeatable::Instance - used internally by repeatable fields

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

This is a simple container class to hold an instance of a Repeatable field.
It will have a name like '0', '1'... Users should not need to use this class.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
