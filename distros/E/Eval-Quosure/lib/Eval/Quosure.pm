package Eval::Quosure;

# ABSTRACT: Evaluate within a caller environment

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001002'; # VERSION

use List::Util 1.28 qw(pairmap);
use PadWalker 2.3 qw(peek_my peek_our);
use Safe::Isa 1.000009;
use Sub::Quote 2.005 qw(quote_sub);
use Type::Params 1.004004;
use Types::Standard qw(Str Int HashRef Optional);

sub new {
    state $check = Type::Params::compile( Str, Optional [Int] );

    my $class = shift;
    my ( $expr, $level ) = $check->(@_);
    $level //= 0;

    my $captures = {
        pairmap { $a => $b }
        ( %{ peek_our( $level + 1 ) }, %{ peek_my( $level + 1 ) } )
    };

    my $self = bless {
        expr     => $expr,
        captures => $captures,
        caller   => [ caller($level) ],
    }, $class;
    return $self;
}


sub expr     { $_[0]->{expr} }
sub captures { $_[0]->{captures} }
sub caller   { $_[0]->{caller} }


sub eval {
    state $check = Type::Params::compile( Optional [HashRef] );

    my $self = shift;
    my ($additional_captures) = $check->(@_);
    $additional_captures //= {};

    my $captures =
      { %{ $self->captures }, pairmap { $a => \$b } %$additional_captures };
    my $caller = $self->caller;

    my $coderef = quote_sub(
        undef,
        $self->expr,
        $captures,
        {
            no_install => 1,              # do not install the function
            package    => $caller->[0],
            file       => $caller->[1],
            line       => $caller->[2],

            # Without below it would get error with Function::Parameters
            #  https://rt.cpan.org/Public/Bug/Display.html?id=122698
            hintshash => undef,
        }
    );

    my @rslt;
    if (wantarray) {
        @rslt = eval { $coderef->(); };
    }
    elsif ( defined wantarray ) {
        $rslt[0] = eval { $coderef->(); };
    }
    else {
        eval { $coderef->(); };
    }
    if ($@) {

        # Simplify error message as sometimes part of what's come from
        #  Sub::Quote may not be very meaningful to users.
        # See also https://metacpan.org/source/HAARG/Sub-Quote-2.006003/lib/Sub/Quote.pm#L307
        my $msg = $@;
        $msg =~ s/.*\d+:.*?[\n]+//ms;
        die $msg;
    }
    if (wantarray) {
        return @rslt;
    }
    elsif ( defined wantarray ) {
        return $rslt[0];
    }
    else {
        return;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Eval::Quosure - Evaluate within a caller environment

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

    use Eval::Quosure;

    sub foo {
        my $a = 2;
        my $b = 3;
        return Eval::Quosure->new('bar($a, $b, $c)');
    }

    sub bar {
        my ($a, $b, $c) = @_;
        return $a * $b * $c;
    }

    my $q = foo();

    my $a = 0;  # This is not used when evaluating the quosure.
    print $q->eval( { '$c' => 7 } ), "\n";

=head1 DESCRIPTION

This class acts similar to R's "quosure". A "quosure" is an object
that combines an expression and an environment in which the expression
can be evaluated. 

Note that as this is string eval so is not secure. USE IT WITH CAUTION!

=head1 CONSTRUCTION

    new(Str $expr, $level=0)

C<$expr> is a string. C<$level> is used like the argument of C<caller> and
PadWalker's C<peek_my>, C<0> is for the scope that creates the quosure
object, C<1> is for the upper scope of the scope that creates the quosure,
and so on. 

=head1 METHODS

=head2 expr

Get the expression stored in the object.

=head2 captures

Get the captured variables stored in the object. Returns a hashref with
keys being variables names including sigil and values being references
to the variables.

=head2 caller

Get the caller info stored in the object.
Returns an arrayref of same structure as what the C<caller()> returns.

=head2 eval

    eval(HashRef $additional_captures={})

Evaluate the quosure's expression in its own environment, with captured
variables from what's obtained when the quosure's created plus specified
by C<$additional_captures>, which is a hashref with keys be the full name
of the variable including sigil.

=head1 SEE ALSO

L<R's "rlang" package|https://cran.r-project.org/web/packages/rlang> which
provides quosure.

L<Eval::Closure>, L<Binding>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
