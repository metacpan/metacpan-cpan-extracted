package HTML::FormHandler::Field::BoolSelect;
# ABSTRACT: Boolean select field
$HTML::FormHandler::Field::BoolSelect::VERSION = '0.40068';

use Moose;
extends 'HTML::FormHandler::Field::Select';

has '+empty_select' => ( default => 'Select One' );

sub build_options { [
    { value => 1, label => 'True'},
    { value => 0, label => 'False' }
]};


__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::BoolSelect - Boolean select field

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

A Boolean select field with three states: null, 1, 0.
Empty select is 'Select One'.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
