#
# This file is part of Lingua-AtD
#
# This software is copyright (c) 2011 by David L. Day.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Lingua::AtD::Exceptions;
$Lingua::AtD::Exceptions::VERSION = '1.160790';
use Exception::Class (
    Lingua::AtD::URLException => {
        fields      => [ 'url', 'host', 'port' ],
        description => 'Indicates a malformed URL.',
    },
    Lingua::AtD::HTTPException => {
        fields => [ 'http_status', 'service_url' ],
        description => 'Indicates a problem connecting to the AtD service.',
    },
    Lingua::AtD::ServiceException => {
        fields      => ['service_message'],
        description => 'Indicates the AtD service returned an error message.',
    },
);

# ABSTRACT: Exception classes for Lingua::AtD

1;    # Magic true value required at end of module

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::AtD::Exceptions - Exception classes for Lingua::AtD

=head1 VERSION

version 1.160790

=head1 AUTHOR

David L. Day <dday376@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David L. Day.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
