package Long::Jump;
use strict;
use warnings;

our $VERSION = '0.000003';

use Carp qw/croak/;
use Importer Importer => 'import';

our @EXPORT_OK = qw/setjump longjump/;

my (%STACK, $SEEK, $OUT);

sub setjump {
    my ($name, $code, @args) = @_;

    croak "You must name your jump point" unless defined $name;
    croak "You must provide a subroutine as a second argument" unless $code && ref($code) eq 'CODE';

    croak "There is already a jump point named '$name'" if exists $STACK{$name};

    local $STACK{$name} = 1;

    LONG_JUMP_SET: {
        $code->(@args);
        return undef;
    }

    longjump($SEEK, @$OUT) if $name ne $SEEK;

    my $out = $OUT;
    $OUT = undef;
    return $out;
}

sub longjump {
    $SEEK = shift;

    croak "No such jump point: '$SEEK'" unless $STACK{$SEEK};

    $OUT = [@_];

    my $ok = eval { no warnings 'exiting'; last LONG_JUMP_SET; 1 };
    my $err = $@;

    my $msg = "longjump('$SEEK') failed";
    $msg .= ", error: $err" unless $ok;

    croak $msg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Long::Jump - Mechanism for returning to a specific point from a deeply nested
stack.

=head1 DESCRIPTION

This module essentially provides a multi-level return. You can mark a spot with
C<setjump()> and then unwind the stack back to that point from any nested stack
frame by name using C<longjump()>. You can also provide a list of return
values.

This is not quite a match for C's long jump, but it is "close enough". It is
safer than C's jump in that it only lets you escape frames by going up the
stack, you cannot jump in other ways.

=head1 SYNOPSIS

    use Long::Jump qw/setjump longjump/;

    my $out = setjump foo => sub {
        bar();
        ...; # Will never get here
    };
    is($out, [qw/x y z/], "Got results of the long jump");

    $out = setjump foo => sub {
        print "Not calling longjump";
    };
    is($out, undef, "longjump was not called so we got an undef response");

    sub bar {
        baz();
        return 'bar'; # Will never get here
    }

    sub baz {
        bat();
        return 'baz'; # Will never get here
    }

    sub bat {
        my @out = qw/x y z/;
        longjump foo => @out;

        return 'bat'; # Will never get here
    }

=head1 EXPORTS

=over 4

=item $out = setjump($NAME, sub { ... })

=item $out = setjump $NAME, sub { ... }

=item $out = setjump($NAME => sub { ... })

=item $out = setjump $NAME => sub { ... }

Set a named point to which you will return when calling C<longjump()>. C<$out>
will be C<undef> if C<longjump()> was not called. C<$out> will be an arrayref
if C<longjump()> was called. The C<$out> arrayref will be empty, but present if
C<longjump()> is called without any return values.

The return value will always be false if C<longjump> was not called, and will
always be true if it was called.

You cannot nest multiple jump points with the same name, but you can nest
multiple jump points if they have unqiue names. C<longjump()> will always jump
to the correct name.

=item longjump($NAME)

=item longjump $NAME

=item longjump($NAME, @RETURN_LIST)

=item longjump($NAME => @RETURN_LIST)

=item longjump $NAME => @RETURN_LIST

Jump to the named point, optionally with values to return. This will throw
exceptions if you use an invalid C<$NAME>, which includes the case of calling
it without a set jump point.

=back

=head1 SOURCE

The source code repository for Long-Jump can be found at
F<https://github.com/exodist/Long-Jump/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2018 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
