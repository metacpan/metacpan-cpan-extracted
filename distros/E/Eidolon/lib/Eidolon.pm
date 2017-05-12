package Eidolon;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon.pm - root metapackage
#
# ==============================================================================

use 5.008008;
use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-12 04:53:33

1;

__END__

=head1 NAME

Eidolon - web application framework.

=head1 DESCRIPTION

I<Eidolon> is intended to turn a headache of web user interface 
development into something easy and full of fun. The main goal of the project is
to ease the creation of various web-based backends and systems such as project 
management systems, customer relationship management systems, online payment 
services and so on. You can use I<Eidolon> for web site creation too, but it
isn't recommended - try to use another powerful tools, that are intended for 
this task (for example, Typo3 CMF, Movable Type or, say, Wordpress).

=head2 Yet another Perl framework? What for?

There is a lot of another Perl frameworks today - Jifty, Hyper, Konstrukt, Rose,
RWDE, Gantry, Catalyst, BlackFramework, etc. Some of them have too much
dependencies, some take too much time to do easy things, some force you to use
only one way to do something (is it Perl or what?!), some of them are already 
unsupported, some are too complicated and have a confusing API... all of this 
was the cause of the I<Eidolon> birth.

=head2 Features

=over 4

=item * Small core

There is only 8 core packages that occupy approximately 45 Kb of disk space, 
including POD sections and various comments. It means that anyone can easily 
I<understand> how the core works, which algorithms it uses, what it can do and
what it can't. 

=item * Object oriented API

I<Eidolon> is almost fully object oriented (except L<Eidolon::Debug>
package), each class is well-documented in awful English. 

=item * CGI and FastCGI support

I<Eidolon> applications can work both in CGI and FastCGI mode. For 
FastCGI applications support you need L<FCGI> module to be installed.

=item * A few dependencies

I<Eidolon> mostly depends on Perl core modules. There are two modules required, that 
are not installed with Perl distribution by default - DBI and Class::Accessor::Fast. 

=item * TMTOWTDI

There is more than one way to do it. Larry presented this ability to all of us, 
so keeping this principle is the sign of our respect.

=item * Code generator

The L<eidolon.pl> code generator will help you to create the application skeleton, so
you won't need to make applications from scratch.

=back

=head1 NOTES

Please note that I<Eidolon> core API is subject to change until 0.10
version release. 

=head1 SEE ALSO

L<eidolon.pl>, L<Eidolon::Application>

L<http://www.atma7.com/en/products/eidolon/> - official project web page.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
