package Haineko::HTTPD::Router;
use strict;
use warnings;
use parent 'Router::Simple';
1;
__END__
=encoding utf-8

=head1 NAME

Haineko::HTTPD::Request - Child class of Plack::Request

=head1 DESCRIPTION

Haineko::HTTPD::Router is child class of Router::Simple.

=head1 SYNOPSIS

    use Haineko::HTTPD::Router;
    my $r = Haineko::HTTPD::Router->new;    # => isa 'Haineko::HTTPD::Router'

=head1 SEE ALSO

L<Haineko::HTTPD>

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
