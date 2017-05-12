package Inline::Perl;
$Inline::Perl::VERSION = '0.01';
@Inline::Perl::ISA = qw(Inline);

use strict;

use Inline ();
use Perl ();

=head1 NAME

Inline::Perl - Inline module for another Perl interpreter

=head1 VERSION

This document describes version 0.01 of Inline::Perl, released
December 24, 2004.

=head1 SYNOPSIS

    use Inline Perl => q{
        sub set_x { $::x = $_[0] }
        sub get_x { $::x }
    };

    set_x(1);
    $::x = 2;
    print get_x(); # 1

=head1 DESCRIPTION

This module allows you to add blocks of Perl code to your Perl scripts
and modules.  This allows you to run them in another interperter, and
then examine the results.

All user-defined procedures in the inlined Perl code will be available
as normal subroutines; global variables are not exported.

Objects, classes and procedures may also be imported by passing them
as config parameters to C<use Inline>.  See L<Inline> for details about
this syntax.

For information about handling another Perl interperter, please see
the B<PerlInterp> distribution on CPAN.

=cut

# register for Inline
sub register {
    return {
	language => 'Perl',
	aliases  => ['perl'],
	type     => 'interpreted',
	suffix   => 'go',
    };
}

# check options
sub validate {
    my $self = shift;
    my $perl = $self->{perl} ||= Perl->new;

    while (@_ >= 2) {
        my ($key, $value) = (shift, shift);
        $perl->define($key, $value) if $key =~ /^\w/;
    }
}

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
    my $perl = $self->{perl} ||= Perl->new;

    $perl->eval($code);

    no strict 'refs';
    foreach my $sym ($perl->eval(q[grep *{$::{$_}}{CODE}, keys %::])) {
        *{"$pkg\::$sym"} = sub {
            $perl->eval("$sym(".join(', ', map '"'.quotemeta($_).'"', @_).")");
        };
    }
}

# no info implementation yet
sub info { }

1;

__END__

=head1 SEE ALSO

L<Perl>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
