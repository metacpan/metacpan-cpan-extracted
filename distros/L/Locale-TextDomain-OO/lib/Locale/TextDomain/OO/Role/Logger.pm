package Locale::TextDomain::OO::Role::Logger;

use strict;
use warnings;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(CodeRef);
use namespace::autoclean;

our $VERSION = '1.006';

has logger => (
    is  => 'rw',
    isa => CodeRef,
);

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Role::Logger - Provides a logger method

$Id: Logger.pm 461 2014-01-09 07:57:37Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Role/Logger.pm $

=head1 VERSION

1.006

=head1 DESCRIPTION

This module provides a logger method for
for L<Locale::TextDomain:OO|Locale::TextDomain:OO>.

=head1 SYNOPSIS

    with qw(
        Locale::TextDomain::OO::Role::Logger
    );

=head1 SUBROUTINES/METHODS

=head2 method logger

Store logger code to get some information
what lexicon is used
or why the translation process is using a fallback.

    $lexicon_hash->logger(
        sub {
            my ($message, $arg_ref) = @_;
            my $type = $arg_ref->{type};
            Log::Log4perl->get_logger(...)->$type($message);
            return;
        },
    );

$arg_ref contains

    object => $self, # the object itself
    type   => 'debug', # the log category
    event  => 'lexicon,load', # event category

Get back

    $code_ref_or_undef = $self->logger;

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

nothing

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Moo::Role|Moo::Role>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 - 2014,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
