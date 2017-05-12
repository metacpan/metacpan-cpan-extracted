package JavaScript::Writer::Var;
use strict;
use warnings;

our $VERSION = '0.0.2';

use self;
use JSON::Syck;

sub new {
    my ($class, $ref, $params) = @_;
    tie $$ref, $class, $$ref, $params;
    return $$ref;
}

sub TIESCALAR {
    my ($class, $value, $params) = @_;
    return bless {
        %$params,
        value => $value
    }, $class;
}

sub STORE {
    self->{value} = (args)[0];

    unless (self->{name}) {
        die("Doing assignment on an anonymous variable ? That's not going to work");
    }
    my $v = "";
    if (ref(self->{value}) =~ (/^JavaScript::Writer/)) {
        $v = self->{value}->as_string;
    }
    else {
        $v = JSON::Syck::Dump( self->{value} );
    }

    $v =~ s/\.?;?$/;/;
    my $s = self->{name} . " = $v" ;
    self->{jsw}->append($s);
}

sub FETCH {
    self->{value};
}


1;

__END__

=head1 NAME

JavaScript::Writer::Var - javascript variable can tie with perl's

=head1 DESCRIPTION

This modules does an old trick with tie, so you can have a perl
variable in your code, but when you do assignments, it'll effect the
variable in the javascript output.

You should'nt use this module directly, please read the description of
C<var> method in L<JavaScript::Writer> moudle. That's the document you
only need to read.

=head1 METHODS

=over

=item new(\$your_var, $params)

Constructor, this does the tie for you. The first arg needs to be a
scalar reference. You'll need to create that variable in your scope,
calling this method will call tie your variable.

=item TIESCALAR()

=item STORE()

=item FETCH()

As you can see, these three methods are required to full-fill the tie
interface. Whenever you do an variable assignement, it'll be written
as a javascript assignment too. Only the value are dumped with
C<JSON::Syck>.

=back

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Kang-min Liu C<< <gugod@gugod.org> >>.

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

=cut

