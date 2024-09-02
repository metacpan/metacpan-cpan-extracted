=head1 NAME

Devel::PerlySense::Bookmark::MatchResult - A Bookmark definition and its matches

=head1 DESCRIPTION

A Bookmark definition, and a list of matching Bookmark::Match objects

=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Bookmark::MatchResult;
$Devel::PerlySense::Bookmark::MatchResult::VERSION = '0.0223';




use Spiffy -Base;
use Carp;
use Data::Dumper;

use Devel::PerlySense;
use Devel::PerlySense::Bookmark::Match;
use Devel::PerlySense::Bookmark::Definition;





=head1 PROPERTIES

=head2 oDefinition

Bookmark::Definition object.

=cut
field "oDefinition" => undef;





=head2 raMatch

Array ref with Bookmark::Match object.

Default: []

=cut
field "raMatch" => [];





=head1 METHODS

=head2 newFromMatch(oDefinition, file, source)

Create new PerlySense::Bookmark::MatchResult object. Use $oDefinition
to match against the $source in $file.

If no matches were found, don't create the MatchResult object. Instead
return undef (scalar context), or or an empty list (list context).

Die on errors.

=cut
sub newFromMatch {
    my ($oDefinition, $file, $source) = Devel::PerlySense::Util::aNamedArg(["oDefinition", "file", "source"], @_);

    my @aMatch = $oDefinition->aMatch(
        file => $file,
        source => $source,
    );

    @aMatch or return;

    $self = bless {}, $self;    #Create the object. It looks weird because of Spiffy

    $self->oDefinition($oDefinition);
    $self->raMatch(\@aMatch);

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
    my $indexLine = 0;
    for my $line (split(/\n/, $source)) {
        $indexLine++;

        for my $rexText (@{$self->raRexText}) {
            my $qr = $self->rhQrRex->{$rexText};

            if($line =~ $qr) {
                my $text = defined($1) ? $1 : $line;

                push(
                    @aMatch,
                    Devel::PerlySense::Bookmark::Match->new(
                        oMatchResult => $self,
                        file => $file,
                        line => $line,
                        text => $text,
                        row => $indexLine,
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
