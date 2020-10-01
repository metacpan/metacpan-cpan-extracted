package Mail::BIMI::App;
# ABSTRACT: App::Cmd base class
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Mail::BIMI::Prelude;
use App::Cmd::Setup -app;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::App - App::Cmd base class

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

App::Cmd class for Mail::BIMI helper applications

=head1 REQUIRES

=over 4

=item * L<App::Cmd::Setup|App::Cmd::Setup>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
