package Form::Factory::Result::Gathered;
$Form::Factory::Result::Gathered::VERSION = '0.022';
use Moose;

use Carp ();
use Scalar::Util qw( blessed refaddr );
use List::MoreUtils qw( all any );

with qw( Form::Factory::Result );

# ABSTRACT: A group of results


has _results => (
    is       => 'ro',
    isa      => 'HashRef[Form::Factory::Result]',
    required => 1,
    default  => sub { {} },
);


sub results {
    my $self = shift;
    return values %{ $self->_results };
}


sub gather_results {
    my ($self, @results) = @_;

    my $results = $self->_results;
    for my $result (@results) {
        Carp::croak('you attempted to pass a result itself to gather_results(), but you cannot gather results recursively')
            if refaddr $result == refaddr $self;

        my $addr = refaddr $result;
        $results->{$addr} = $result;
    }
}


sub clear_state {
    my $self = shift;
    $_->clear_state for $self->results;
}


sub clear_results {
    my $self = shift;
    %{ $self->_results } = ();
}


sub clear_messages {
    my $self = shift;
    $_->clear_messages for $self->results;
}


sub clear_messages_for_field {
    my $self  = shift;
    my $field = shift;

    $_->clear_messages_for_field($field) for $self->results;
}


sub clear_all {
    my $self = shift;
    $self->clear_state;
    $self->clear_messages;
    $self->clear_results;
}


sub is_valid {
    my $self = shift;
    return all { not $_->is_validated or $_->is_valid } $self->results;
}


sub is_validated {
    my $self = shift;
    return any { $_->is_validated } $self->results;
}


sub is_success {
    my $self = shift;
    return all { not $_->is_outcome_known or $_->is_success } $self->results;
}


sub is_outcome_known {
    my $self = shift;
    return any { $_->is_outcome_known } $self->results;
}


sub messages {
    my $self = shift;
    return [ map { @{ $_->messages } } $self->results ];
}


# Dumb merge
sub content {
    my $self = shift;
    return { map { %{ $_->content } } $self->results };
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Result::Gathered - A group of results

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  my $result = Form::Factory::Result::Gathered->new;
  $result->gather_results($other_result1, $other_result2, $other_result3);

  my @child_results = $result->results;

  $result->clear_messages;
  $result->clear_messages_for_field('foo');
  $result->clear_results;
  $result->clear_all;

  my $validated = $result->is_validated;
  my $valid     = $result->is_valid;

  my $has_outcome = $result->is_outcome_known;
  my $success     = $result->is_success;

  my $messages    = $result->messages;
  my $content     = $result->content;

=head1 DESCRIPTION

This is a collection of results. The results are grouped and collected together in a way that makes sense to the Form::Factory API.

=head1 METHODS

=head2 results

  my @results = $self->results;

Returns a list of the results that have been gathered.

=head2 gather_results

  $result->gather_results(@results);

Given one or more result objects, it adds them to the list of results already gathered. These are placed in a set such that no result is added more than once. If a result object was already added, it will not be added again.

=head2 clear_state

Clears the state of all gathered results. It just calls C<clear_state> recursively on all results.

=head2 clear_results

Clears the list of results. L</results> will return an empty list after this is called.

=head2 clear_messages

Calls the C<clear_messages> method on all results that have been gathered. This will clear messages for all the associated results.

=head2 clear_messages_for_field

  $result->clear_messagesw_for_field($field);

Calls the C<clear_messages_for_field> method on all results that have been gathered. 

=head2 clear_all

Clears all messages on the gathered results (via L</clear_message>) and then clears all the results (via L</clear_results>).

=head2 is_valid

Tests each result for validity. This will return true if every result returns false for C<is_validated> or returns true for C<is_valid>.

=head2 is_validated

Returns true if any result returns true for C<is_validated>.

=head2 is_success

Tests each result for success. This will return true if every result returns false for C<is_outcome_known> or true for C<is_success>.

=head2 is_outcome_known

Returns true if any result returns true for C<is_outcome_known>.

=head2 messages

Returns a reference to an array of messages. This includes all messages from the gathered results.

=head2 content

Performs a shallow merge of all the return value of each result's C<content> method and returns that.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
