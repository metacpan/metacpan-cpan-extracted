package Error::Tiny;

use strict;
use warnings;

use vars qw(@ISA @EXPORT @EXPORT_OK);

our $VERSION = '0.03';

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
}

@EXPORT = @EXPORT_OK = qw(try then catch);

require Carp;
$Carp::Internal{+__PACKAGE__}++;

require Scalar::Util;

use Error::Tiny::Exception;
use Error::Tiny::Catch;
use Error::Tiny::Then;

sub try(&;@) {
    my ($try, @handlers) = @_;

    my $wantarray = wantarray;

    my @ret;
    eval { @ret = $wantarray ? $try->() : scalar $try->(); 1 } || do {
        my $e      = $@;
        my $orig_e = $e;

        if (!Scalar::Util::blessed($e)) {
            $orig_e =~ s{ at ([\S]+) line (\d+)\.\s*$}{}ms;
            $e = Error::Tiny::Exception->new(
                message => $orig_e,
                file    => $1,
                line    => $2
            );
        }

        for my $handler (@handlers) {
            if ($handler && $handler->isa('Error::Tiny::Catch')) {
                if ($e->isa($handler->class)) {
                    return $handler->handler->($e);
                }
            }
        }

        Carp::croak($orig_e);
    };

    return $wantarray ? @ret : $ret[0];
}

sub catch(&;@) {
    my ($class, $handler) =
      @_ == 2 ? ($_[0], $_[1]->handler) : ('Error::Tiny::Exception', $_[0]);

    Error::Tiny::Catch->new(handler => $handler, class => $class);
}

sub then(&;@) {
    my ($handler, $subhandler) = @_;

    (Error::Tiny::Then->new(handler => $handler), $subhandler);
}

1;
__END__

=head1 NAME

Error::Tiny - Tiny exceptions

=head1 SYNOPSIS

    use Error::Tiny;

    try {
        dangerous();
    }
    catch MyCustomException then {
        my $e = shift;

        ...everything whose parent is MyCustomException...
    }
    catch {
        my $e = shift;

        ...everything else goes here...
    };

=head1 DESCRIPTION

L<Error::Tiny> is a lightweight exceptions implementation.

=head1 FEATURES

=head2 C<Objects everywhere>

You will always get an object in the catch block. No need to check if it's
a blessed reference or anything like that. And there is no need for
C<$SIG{__DIE__}>!

=head2 C<Exception class built-in>

L<Error::Tiny::Exception> is a lightweight base exception class. It is easy to
throw an exception:

    Error::Tiny::Exception->throw('error');

=head1 WARNING

If you start getting strange behaviour when working with exceptions, make sure
that you C<use> L<Error::Tiny> in the correct package in the correct place.
Somehow perl doesn't report this as an error.

This will not work:

    use Error::Tiny;
    package MyPackage;

    try { ... };

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/error-tiny

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
