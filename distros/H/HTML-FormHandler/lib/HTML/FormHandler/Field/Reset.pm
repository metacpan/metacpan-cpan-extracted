package HTML::FormHandler::Field::Reset;
# ABSTRACT: reset field
$HTML::FormHandler::Field::Reset::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field::NoValue';


has '+widget' => ( default => 'Reset' );
has '+value' => ( default => 'Reset' );
has '+type_attr' => ( default => 'reset' );
has '+html5_type_attr' => ( default => 'reset' );
sub do_label {0}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Reset - reset field

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Use this field to declare a reset field in your form.

   has_field 'reset' => ( type => 'Reset', value => 'Restore' );

Uses the 'reset' widget.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
