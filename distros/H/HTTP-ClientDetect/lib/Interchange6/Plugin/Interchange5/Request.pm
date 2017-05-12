package Interchange6::Plugin::Interchange5::Request;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Moo;

=head1 NAME

Interchange6::Plugin::Interchange5::Request - Mimic Dancer::Request inside IC5

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Quick summary of what the module does.

In a tag (shipped as dancer_request.tag)

    use Interchange6::Plugin::Interchange5::Request;
    my %env = %{::http()->{env}};
    return Interchange6::Plugin::Interchange5::Request->new(env => \%env);
    ...

Somewhere else

    my $req = $Tag->dancer_request;
    $req->header('Accept-Language');
    $req->accept_language;
    ....


=head1 ACCESSORS

=head2 env

=cut

has env => (is => 'ro',
            required => 1,
            isa => sub {
                die unless ref($_[0]) eq 'HASH';
            });

=head1 METHODS

=head2 environment($name)

Look into the environment variables, with the following routine:
first, we uppercase the name and replace any non-alpha and non-digit
character with the underscore. Then we look into the environment. If
not found, we try to prepend HTTP_. Return undef in nothing is found.

=head2 header($name)

Alias for environment

=cut

sub header {
    my ($self, $name) = @_;
    return $self->environment($name);
}

sub environment {
    my ($self, $name) = @_;
    return unless $name;
    $name =~ s/[^a-zA-Z0-9_]/_/g;
    $name = uc($name);
    my $http_name = "HTTP_" . $name;
    my $env = $self->env;
    if (exists $env->{$name}) {
        return $env->{$name};
    }
    elsif (exists $env->{$http_name}) {
        return $env->{$http_name};
    }
    else {
        return;
    }
}


=head2 SHORTCUTS

The following methods are just shortcuts for the C<environment> method.

=over 4

=item  accept

=item  accept_charset

=item  accept_encoding

=item  accept_language

=item  accept_type

=item  agent (alias for "user_agent")

=item  connection

=item  forwarded_for_address

=item  forwarded_protocol

=item  forwarded_host

=item  host

=item  keep_alive

=item  path_info

=item  referer

=item  remote_address

=item  user_agent

=back

=cut

sub accept { return shift->environment("accept") }

sub accept_charset { return shift->environment("accept_charset") }

sub accept_encoding { return shift->environment("accept_encoding") }

sub accept_language { return shift->environment("accept_language") }

sub accept_type { return shift->environment("accept_type") }

sub agent { return shift->environment("user_agent") }

sub connection { return shift->environment("connection") }

sub forwarded_for_address { return shift->environment("forwarded_for_address") }

sub forwarded_protocol { return shift->environment("forwarded_protocol") }

sub forwarded_host { return shift->environment("forwarded_host") }

sub host { return shift->environment("host") }

sub keep_alive { return shift->environment("keep_alive") }

sub path_info { return shift->environment("path_info") }

sub referer { return shift->environment("referer") }

sub remote_address { return shift->environment("remote_addr") }

sub user_agent { return shift->environment("user_agent") }

=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-interchange6-plugin-autodetect at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Interchange6-Plugin-Autodetect>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Interchange6::Plugin::Interchange5::Request


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Interchange6-Plugin-Autodetect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Interchange6-Plugin-Autodetect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Interchange6-Plugin-Autodetect>

=item * Search CPAN

L<http://search.cpan.org/dist/Interchange6-Plugin-Autodetect/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Marco Pessotto.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Interchange6::Plugin::Interchange5::Request
