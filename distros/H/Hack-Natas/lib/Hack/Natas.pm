package Hack::Natas;
use strict;
use warnings;
use v5.16.0;
our $VERSION = '0.003'; # VERSION
# ABSTRACT: solve some of the Natas server-side security war games

use Carp qw/ confess /;
use URI;
use HTTP::Tiny 0.034;
use Types::Standard qw(Int Str);
use Type::Utils qw(class_type);
use Moo::Role;
requires qw(run get_password_length);


has level     => ( is => 'ro', isa => Int, required => 1);
has http_user => ( is => 'ro', lazy => 1, isa => Str, default => sub { 'natas' . $_[0]->level } );
has http_pass => ( is => 'ro', lazy => 1, isa => Str, required => 1 );
my $uri_type = class_type({ class => 'URI' })->plus_constructors( Str, 'new' );
has uri     => (
    is      => 'ro',
    lazy    => 1,
    isa     => $uri_type,
    coerce  => $uri_type->coercion,
    default => sub {
        my $self = shift;
        return sprintf 'http://%s:%s@natas%s.natas.labs.overthewire.org',
            $self->http_user, $self->http_pass, $self->level
    },
    handles => { set_query => 'query_form' },
);
has ua      => (
    is      => 'ro',
    lazy    => 1,
    isa     => class_type({class => 'HTTP::Tiny'}),
    default => sub {
        return HTTP::Tiny->new(
            timeout => 5,
            default_headers =>  { Host => $_[0]->http_user . '.natas.labs.overthewire.org' },
        );
    },
);
has password => ( is => 'rw', isa => Str );
has password_length => (is => 'rw', isa => Int, builder => 'get_password_length');


sub get {
    my $self = shift;
    $self->set_query( { @_ } ) if @_;
    return $self->ua->get( $self->uri );
}


before run => sub { STDOUT->autoflush(1) };
after  run => sub { printf "\rPassword is '%s'.\n", $_[0]->password };

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Hack::Natas - solve some of the Natas server-side security war games

=head1 VERSION

version 0.003

=head1 DESCRIPTION

L<overthewire.org|http://www.overthewire.org/wargames/> has a series of war games.
Natas is the server-side security challenge.

This package contains some scripts to automate solving some of the tedious levels,
and documents walking you through all levels up to #17.

This role provides the basic attributes and methods which are generally
required for scripting password extraction.

=head1 METHODS

=head2 get

This sets the query string of the C<uri> according to the key-value pairs
passed in. Then, does an HTTP GET for that resource, and returns the
response (a hashref).

=head2 run

The implementation of C<run> must be provided by the consuming class.

Before C<run> executes, turn on autoflush for STDOUT.

After B<run> executes, print out the final password.

=head1 ATTRIBUTES

=over 4

=item * level - a read-only integer for the current level

=item * http_user - the username to use to access the current level. By default, "natas${level}"

=item * http_pass - the password to use to access the current level. Required.

=item * uri - the L<URI> for the current level. Can be coerced from a string. By default,
this is constructed from the level, http_user, and http_pass.

=item * ua - an L<HTTP::Tiny> object. By default, the timeout is 5s, and the C<Host> header is set.

=item * password - the password we are extracting to access the next level.

=item * password_length - the length of the password. This is built by the C<get_password_length> method.

=back

=head1 SEE ALSO

=over 4

=item * L<natas15>

Level 15 requires you to do blind SQL injection.

=item * L<natas16>

Level 16 requires you to do blind shell injection.

=item * L<https://hashbang.ca/tag/natas>

=item * L<http://overthewire.org>

=back

=head1 AVAILABILITY

The project homepage is L<https://hashbang.ca/tag/natas>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Hack::Natas/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Hack-Natas>
and may be cloned from L<git://github.com/doherty/Hack-Natas.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Hack-Natas/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
