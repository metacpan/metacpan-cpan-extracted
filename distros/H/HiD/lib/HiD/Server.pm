# ABSTRACT: Helper for 'hid server'


package HiD::Server;
our $AUTHORITY = 'cpan:GENEHACK';
$HiD::Server::VERSION = '1.98';
use 5.014; # strict, unicode_strings
use warnings;

use parent 'Plack::App::File';


sub locate_file {
  my ($self, $env) = @_;

  my $path = $env->{PATH_INFO} || '';

  $path =~ s|^/|| unless $path eq '/';

  if ( -e -d $path and $path !~ m|/$| ) {
    $path .= '/';
    $env->{PATH_INFO} .= '/';
  }

  $env->{PATH_INFO} .= 'index.html'
    if ( $path && $path =~ m|/$| );

  return $self->SUPER::locate_file( $env );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::Server - Helper for 'hid server'

=head1 DESCRIPTION

Helper for C<hid server>

=head1 METHODS

=head2 locate_file

Overrides L<Plack::App::File>'s method of the same name to handle '/' and
'/index.html' cases

=head1 VERSION

version 1.98

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
