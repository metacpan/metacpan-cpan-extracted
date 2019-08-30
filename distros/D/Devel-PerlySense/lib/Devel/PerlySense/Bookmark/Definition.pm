=head1 NAME

Devel::PerlySense::Bookmark::Definition - A Bookmark definition

=head1 DESCRIPTION


=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Bookmark::Definition;
$Devel::PerlySense::Bookmark::Definition::VERSION = '0.0221';




use Spiffy -Base;
use Carp;
use Data::Dumper;

use Devel::PerlySense;
use Devel::PerlySense::Bookmark::Match;





=head1 PROPERTIES

=head2 moniker

The moniker of the Bookmark.

Default: ""

=cut
field "moniker" => "";





=head2 raRexText

Regexp texts to be evaled as qr definitions.

Bookmarks are matched in this order.

Default: []

=cut
field "raRexText" => [];





=head2 rhQrRex

Hash ref with (keys: regexp texts; values: qr objects).

Default: {}

=cut
field "rhQrRex" => {};





=head1 METHODS

=head2 newFromConfig(moniker, rex)

Create new PerlySense::Bookmark::Definition object. Give it $moniker and
parse the regex definitions in $ref (either a scalar or an array ref
with scalars).

Die on errors, like if the rex definitions aren't valid Perl, or if
they don't result in a qr object.

=cut
sub newFromConfig {
    my ($moniker, $rex) = Devel::PerlySense::Util::aNamedArg(["moniker", "rex"], @_);

    $self = bless {}, $self;    #Create the object. It looks weird because of Spiffy
    $self->moniker($moniker)
            or die("Bad Bookmark definition: No 'moniker' specified' in " . Dumper({@_}));

    my $raRex = ref $rex ? $rex : [ $rex ];

    for my $rex (@$raRex) {
        push(@{$self->raRexText}, $rex);
        my $qr = $self->parseRex($rex);
        $self->rhQrRex->{$rex} = $qr;
    }

    return($self);
}





=head2 parseRex($rex)

Perl eval the $rex string to create a qr// object and return it.

Die on eval errors, or if the result isn't a qr.

=cut
sub parseRex {
    my ($rex) =  @_;

    my $qr = eval $rex;  ## no critic
    $@ and die("Perl syntax error encountered when parsing Bookmark regex ($rex):\n$@");
    ref $qr eq "Regexp" or die("Bookmark regex definition ($rex) doesn't result in a regex (a qr// object)\n");
    return $qr;
}





=head2 aMatch(file, source)

Return a Bookmark::Match object for each time this bookmark matches a
line in source.

=cut
sub aMatch {
    my ($file, $source) = Devel::PerlySense::Util::aNamedArg(["file", "source"], @_);

    my @aMatch;
    my $row = 0;
    for my $line (split(/\r?\n/, $source)) {
        $row++;

        for my $rexText (@{$self->raRexText}) {
            my $qr = $self->rhQrRex->{$rexText};

            if($line =~ $qr) {
                my $text = defined($1) ? $1 : $line;
                
                push(
                    @aMatch,
                    Devel::PerlySense::Bookmark::Match->new(
                        oDefinition => $self,
                        file => $file,
                        line => $line,
                        text => $text,
                        row => $row,
                    ),
                );
                last;
            }
        }
    }

    return(@aMatch);
}





1;





__END__

=encoding utf8

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-perlysense@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-PerlySense>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
