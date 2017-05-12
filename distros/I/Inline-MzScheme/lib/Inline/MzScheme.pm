package Inline::MzScheme;
$Inline::MzScheme::VERSION = '0.05';
@Inline::MzScheme::ISA = qw(Inline);

use strict;

use Inline ();
use Language::MzScheme ();

=head1 NAME

Inline::MzScheme - Inline module for the PLT MzScheme interpreter

=head1 VERSION

This document describes version 0.05 of Inline::MzScheme, released
June 13, 2004.

=head1 SYNOPSIS

    use subs 'perl_multiply'; # have to declare before Inline runs

    use Math::BigInt;
    use Inline MzScheme => q{
        (define (square x) (perl-multiply x x))
        (define assoc-list '((1 . 2) (3 . 4) (5 . 6)))
        (define linked-list '(1 2 3 4 5 6))
        (define hex-string (bigint 'as_hex))
    }, (bigint => Math::BigInt->new(1792));

    sub perl_multiply { $_[0] * $_[1] }

    print square(10);           # 100
    print $hex_string;          # 0x700
    print $assoc_list->{1};     # 2
    print $linked_list->[3];    # 4

=head1 DESCRIPTION

This module allows you to add blocks of Scheme code to your Perl
scripts and modules.

All user-defined procedures in your Scheme code will be available
as Perl subroutines; association lists and hash tables are available
as Perl hash refereces; lists and vectors available as array references;
boxed values become scalar references.

Perl subroutines in the same package are imported as Scheme primitives,
as long as they are declared before the C<use Inline MzScheme> line.

Non-word characters in Scheme identifiers are turned into C<_> for Perl.
Underscores in Perl identifiers are turned into C<-> for Scheme.

Additional objects, classes and procedures may be imported into Scheme,
by passing them as config parameters to C<use Inline>.  See L<Inline>
for details about this syntax.

You can invoke perl objects in Scheme code with the syntax:

    (object 'method arg1 arg2 ...)

If your method takes named argument lists, this will do:

    (object 'method 'key1 val1 'key2 val2)

For information about handling MzScheme data in Perl, please see
L<Language::MzScheme>.  This module is mostly a wrapper around
L<Language::MzScheme::scheme_eval_string> with a little auto-binding
magic for procedures and input variables.

=cut

# register for Inline
sub register {
    return {
	language => 'MzScheme',
	aliases  => ['MZSCHEME'],
	type     => 'interpreted',
	suffix   => 'go',
    };
}

# check options
sub validate {
    my $self = shift;
    my $env = $self->{env} ||= Language::MzScheme->new;

    while (@_ >= 2) {
        my ($key, $value) = (shift, shift);
        $env->define($key, $value) if $key =~ /^\w/;
    }
}

# required method - doesn't do anything useful
sub build {
    my $self = shift;

    # magic dance steps to a successful Inline compile...
    my $path = "$self->{API}{install_lib}/auto/$self->{API}{modpname}";
    my $obj  = $self->{API}{location};
    $self->mkpath($path)                   unless -d $path;
    $self->mkpath($self->{API}{build_dir}) unless -d $self->{API}{build_dir};

    # touch my monkey
    open(OBJECT, ">$obj") or die "Unable to open object file: $obj : $!";
    close(OBJECT) or die "Unable to close object file: $obj : $!";
}

# load the code into the interpreter
sub load {
    my $self = shift;
    my $code = $self->{API}{code};
    my $pkg  = $self->{API}{pkg} || 'main';
    my $env = $self->{env} ||= Language::MzScheme->new;
    $env->define_perl_wrappers;

    my %sym = map(
        ( $_ => 1 ),
        $env->eval('(namespace-mapped-symbols)') =~ /([^\s()]+)/g
    );

    $env->eval($code);

    no strict 'refs';

    foreach my $sym (sort keys %{"$pkg\::"}) {
        my $code = *{${"$pkg\::"}{$sym}}{CODE} or next;
        $sym =~ tr/_/-/;
        $env->define("$pkg\::$sym", $code) unless $sym{"$pkg\::$sym"}++;
        $env->define($sym, $code) unless $sym{$sym}++;
    }

    SYMBOL:
    foreach my $sym (grep !$sym{$_}, $env->eval('(namespace-mapped-symbols)') =~ /([^\s()]+)/g) {
        my $obj = $env->lookup($sym);
        $sym =~ s/\W/_/g;
        foreach my $type (qw( CODE GLOB )) {
            $obj->isa($type) or next;
            *{"$pkg\::$sym"} = $obj->can('to_'.lc($type).'ref')->($obj);
            next SYMBOL;
        }
        *{"$pkg\::$sym"} = \$obj;
    }
}

# no info implementation yet
sub info { }

1;

__END__

=head1 ACKNOWLEDGEMENTS

Thanks to Sam Tregar's L<Inline::Guile> for showing me how to do this.

=head1 SEE ALSO

L<Language::MzScheme>, L<Inline>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
