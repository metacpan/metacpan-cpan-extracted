#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Language::Befunge::lib::EVAR;
# ABSTRACT: Environment variables extention
$Language::Befunge::lib::EVAR::VERSION = '5.000';
sub new { return bless {}, shift; }


# -- env vars

#
# 0gnirts = G(0gnirts)
#
# Get the value of an environment variable.
#
sub G {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $k  = $ip->spop_gnirts;
    $ip->spush( 0 );
    $ip->spush( map { ord } split //, reverse $ENV{$k} );
}


#
# $n = N()
#
# get the number of environment variables
#
sub N {
    my ($self, $lbi) = @_;
    $lbi->get_curip->spush( scalar keys %ENV );
}


#
# P( 0gnirts )
#
# update an environment variable (arg is of the form: name=value)
#
sub P {
    my ($self, $lbi) = @_;
    my $ip  = $lbi->get_curip;
    my $str = $ip->spop_gnirts;
    my ($k, $v) = split /=/, $str;
    $ENV{$k} = $v;
}


#
# 0gnirts = V($n)
#
# Get the nth environment variable (form: name=value).
#
sub V {
    my ($self, $lbi) = @_;
    my $ip   = $lbi->get_curip;
    my $n = $ip->spop;
    if ( $n >= scalar keys %ENV ) {
        $ip->dir_reverse;
        return;
    }
    my @keys = sort keys %ENV;
    my $k    = $keys[$n];
    $ip->spush( 0 );
    $ip->spush( map { ord } split //, reverse "$k=$ENV{$k}" );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::EVAR - Environment variables extention

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The EVAR fingerprint (0x45564152) is helping to retrieve & update environment
values.

=head1 FUNCTIONS

=head2 new

Create a new ORTH instance.

=head2 Environment variables operations

=over 4

=item 0gnirts = G(0gnirts)

Get the value of an environment variable.

=item $n = N()

Get the number of environment variables.

=item P( 0gnirts )

Update (or create) an environment variable (arg is of the form: name=value).

=item 0gnirts = V($n)

Get the C<$n>th environment variable (form: name=value).

=back

=head1 SEE ALSO

L<http://www.rcfunge98.com/rcsfingers.html#EVAR>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
