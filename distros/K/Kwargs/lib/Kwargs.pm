package Kwargs;

# ABSTRACT: Simple, clean handing of named/keyword arguments.

use strict;
use warnings;

use Sub::Exporter -setup => {
    exports => [ qw(kw kwn) ],
    groups  => {
        default => [ qw(kw kwn) ],
    }
};

sub kwn(\@@) {
    my $array = shift;
    my $npos  = shift;
    my @pos   = splice(@$array, 0, $npos) if $npos > 0;
    my $hash  = @$array == 1 ? $array->[0] : { @$array };
    return (@pos, $hash) unless @_;
    return (@pos, @{$hash}{@_});
}

sub kw(\@@) {
    splice(@_, 1, 0, 0);
    goto &kwn;
}

1;



=pod

=head1 NAME

Kwargs - Simple, clean handing of named/keyword arguments.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Kwargs;

    # just named
    my ($foo, $bar, baz) = kw @_, qw(foo bar baz);

    # positional followed by named
    my ($pos, $opt_one, $opt_two) = kwn @_, 1, qw(opt_one opt_two)

    # just a hashref
    my $opts = kw @_;

    # positional then hashref
    my ($one, $two, $opts) = kwn @_, 2;

=head1 WHY?

Named arguments are good, especially when you take lots of (sometimes
optional) arguments. There are two styles of passing named arguments (by
convention) in perl though, with and without braces:

    sub foo {
        my $args = shift;
        my $bar  = $args->{bar};
    }

    foo({ bar => 'baz' });

    sub bar {
        my %args = @_;
        my $foo  = $args{foo};
    }

    bar(foo => 'baz');

If you want to support both calling styles (because it should be mainly a
style issue), then you have to do something like this:

    sub foo {
        my $args = ref $_[0] eq 'HASH' ? $_[0] : { @_ };
        my $bar  = $args->{bar};
    }

Which is annoying, and not even entirely correct. What if someone wanted to
pass in a tied object for their optional arguments? That could work, but what
are the right semantics for checking for it?  It also gets uglier if you want
to unpack your keyword arguments in one line for clarity:

    sub foo {
        my ($one, $two, $three) = 
            @{ ref $_[0] eq 'HASH' ? $_[0] : { @_ } }{qw(one two three) };
    }

Did I say clarity? B<HAHAHAHAHA!> Surely no one would actually put something
like that in his code. Except I found myself typing this very thing, and
I<That Is Why>.

=head1 EXPORTS

Two functions (L<kw> and L<kwn>) are exported by default. You can also ask for
them individually or rename them to something else.  See L<Sub::Exporter> for
details.

=head2 kw(@array, @names)

Short for C<kwn(@array, 0, @names)>

=head2 kwn(@array, $number_of_positional_args, @names)

Conceptually shifts off n positional arguments from array, then figures out
whether the rest of the array is a list of key-value pairs or a single
argument (usually, but not necessarily, a hashref). If you passed in any
@names, these are used as keys into the hash, and the values at those keys are
appended to any positional arguments and returned.  If you do not pass @names,
you will get a hashref (or whatever the single argument was, like a tied
object) back.

Note that if the single argument cannot be dereferenced as a hashref, this can
die. No attempt is made by this module to handle the exception.

=head1 AUTHOR

Paul Driver <frodwith@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Paul Driver <frodwith@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

