package Markaya;

use warnings;
use strict;
use v5.8.3;
use HTML::Entities;
use YAML::XS qw();

our $VERSION = '0.40';

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub load {
    my $self = shift;
    my $str  = shift;
    $self->{document} = YAML::XS::Load($str);
}

sub to_html {
    my $self = shift;
    _to_html($self->{document});
}

sub _to_html {
    my $node = shift;
    my $ret = "";
    if (ref $node eq "ARRAY") {
        for my $child (@$node) {
            $ret .= _to_html($child)
        }
    }
    elsif(ref $node eq "HASH") {
        while(my ($k,$v) = each %$node) {
            my $attr_str="";
            if (index($k, "=") != -1) {
                ($k, my $attrs) = split(" ", $k, 2);
                my %attrs = (split(/=([^" ]+|"[^"]+") */, $attrs));
                for(sort keys %attrs) {
                    my $v = $attrs{$_};
                    $v =~ s/^"//; $v =~ s/"$//;
                    $v = encode_entities($v);
                    $attr_str .= qq{ $_="$v"}
                }
            }
            $ret .= "<$k$attr_str>". _to_html($v) ."</$k>";
        }
    }
    else {
        $ret .= encode_entities( $node )
    }
    return $ret;

}


1;
__END__

=head1 NAME

Markaya - Markup As YAML

=head1 VERSION

This document describes Markaya version 0.0.2

=head1 SYNOPSIS

    use Markaya;
    my $m = Markaya->new;
    $/ = undef;
    $m->load(<>);
    print $m->to_html;

=head1 DESCRIPTION

Markaya is a YAML-based text-to-html conversion convention,
Similar to Textile, but using YAML as its syntax. Any Markaya
document is also a valid YAML document.

For detail, see doc/Spec in the distribution tarball.

=head1 INTERFACE

=over

=item new()

Object contructor.

=item load( STRING )

Load Markaya document as a YAML string.

=item to_html()

Convert loaded Markaya document into HTML. Return a string contain
the converted HTML.

=item _to_html()

Do not use this. Internal recursive function.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Markaya requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<YAML::XS>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-markaya@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Kang-min Liu C<< <gugod@gugod.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
