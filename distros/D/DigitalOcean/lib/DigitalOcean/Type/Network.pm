package DigitalOcean::Type::Network;
use Mouse::Util::TypeConstraints;
use DigitalOcean::Network;

subtype 'ArrayRefOfNetworks' => as 'ArrayRef[DigitalOcean::Network]';
subtype 'CoercedArrayRefOfNetworks' => as 'ArrayRefOfNetworks';
coerce 'CoercedArrayRefOfNetworks'
    => from 'ArrayRef[HashRef]'
    => via { [map { DigitalOcean::Network->new( %{$_} ) } @{$_}] };

no Mouse::Util::TypeConstraints;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Type::Network

=head1 VERSION

version 0.17

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
