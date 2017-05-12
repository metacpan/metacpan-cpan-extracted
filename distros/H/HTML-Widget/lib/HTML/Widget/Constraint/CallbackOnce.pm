package HTML::Widget::Constraint::CallbackOnce;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';

__PACKAGE__->mk_accessors(qw/callback/);

*cb = \&callback;

=head1 NAME

HTML::Widget::Constraint::CallbackOnce - CallbackOnce Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'CallbackOnce', 'foo', 'bar' )->callback(
      sub { 
        my ($foo, $bar) = @_;
        return 1 if $foo == $bar * 2;
    });

=head1 DESCRIPTION

A callback constraint which will only be run once for each call of 
L<HTML::Widget/"process">.

=head1 METHODS

=head2 callback

=head2 cb

Arguments: \&callback

Requires a subroutine reference used for validation, which will be passed 
a list of values corresponding to the constraint names.

L</cb> is provided as an alias to L</callback>.

=head2 process

Overrides L<HTML::Widget::Constraint/"process"> to ensure L</validate> is 
only called once for each call of L</validate>.

=cut

sub process {
    my ( $self, $w, $params ) = @_;

    my @names = @{ $self->names };
    my @values = map { $params->{$_} } @names;

    my $result = $self->validate(@values);

    my $results = [];

    if ( $self->not ? $result : !$result ) {
        for my $name (@names) {
            push @$results, HTML::Widget::Error->new(
                { name => $name, message => $self->mk_message } );
        }
    }

    return $results;
}

=head2 render_errors

Arguments: @names

A list of element names for which an error should be displayed.

If this is not set, the default behaviour is for the error to be displayed 
for all of the Constraint's named elements.  

=head2 validate

perform the actual validation.

=cut

sub validate {
    my ( $self, @values ) = @_;

    my $callback = $self->callback || sub {1};

    return $callback->(@values);
}

=head1 AUTHOR

Carl Franks C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
