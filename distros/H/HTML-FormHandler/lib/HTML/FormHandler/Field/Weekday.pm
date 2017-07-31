package HTML::FormHandler::Field::Weekday;
# ABSTRACT: select list day of week strings
$HTML::FormHandler::Field::Weekday::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field::Select';

sub build_options {
    my $i    = 0;
    my @days = qw/
        Sunday
        Monday
        Tuesday
        Wednesday
        Thursday
        Friday
        Saturday
        /;
    return [ map { { value => $i++, label => $_ } } @days ];
}


__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Weekday - select list day of week strings

=head1 VERSION

version 0.40068

=head1 DESCRIPTION

Creates an option list for the days of the week.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
