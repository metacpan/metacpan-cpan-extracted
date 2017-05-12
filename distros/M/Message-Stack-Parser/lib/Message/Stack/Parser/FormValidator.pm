package Message::Stack::FormValidator;
{
  $Message::Stack::FormValidator::VERSION = '0.06';
}
use Moose;

use Message::Stack::Message;

sub parse {
    my ($stack, $scope, $results) = @_;

    if($results->success) {
        return 1;
    }

    foreach my $f ($results->missing) {
        $stack->add(Message::Stack::Message->new(
            id      => "missing_$f",
            scope   => $scope,
            subject => $f,
            level   => 'error'
        ));
    }

    foreach my $f ($results->invalid) {
        $stack->add(Message::Stack::Message->new(
            id      => "invalid_$f",
            scope   => $scope,
            subject => $f,
            level   => 'error'
        ));
    }

    return 0;
}

1;

__END__
=pod

=head1 NAME

Message::Stack::FormValidator

=head1 VERSION

version 0.06

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

