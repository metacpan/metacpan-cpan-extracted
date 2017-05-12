package Graphics::Color::Types;
$Graphics::Color::Types::VERSION = '0.31';
use MooseX::Types -declare => [qw(
    Number360OrLess NumberOneOrLess
)];

use MooseX::Types::Moose qw(Num);

subtype Number360OrLess,
    as Num,
    where { $_ <= 360 && $_ >= 0 },
    message { "This number ($_) is not less than or equal to 360!" };

subtype NumberOneOrLess,
    as Num,
    where { $_ <= 1 && $_ >= 0 },
    message { "This number ($_) is not less or equal to one!" };

1;

__END__

=pod

=head1 NAME

Graphics::Color::Types

=head1 VERSION

version 0.31

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
