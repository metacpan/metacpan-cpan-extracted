=head1 NAME

Devel::PerlySense::BookmarkConfig - A collection of
Bookmark::Definition and their configuration.


=head1 DESCRIPTION

This is the Bookmark config chunk, and the parsed Bookmark::Definition
objects that results in.

=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::BookmarkConfig;
$Devel::PerlySense::BookmarkConfig::VERSION = '0.0218';


use Spiffy -Base;
use Carp;
use Data::Dumper;
use File::Basename;
use File::Path;
use Path::Class;

use Devel::PerlySense;
use Devel::PerlySense::Util;
use Devel::PerlySense::Util::Log;

use Devel::PerlySense::Bookmark::Definition;
use Devel::PerlySense::Bookmark::MatchResult;





=head1 PROPERTIES

=head2 oPerlySense

Devel::PerlySense object.

Default: set during new()

=cut
field "oPerlySense" => undef;





=head2 raDefinition

Array ref with Bookmark::Definition objects from the oPerlySense
config.

=cut
sub raDefinition {
    return [
        map { Devel::PerlySense::Bookmark::Definition->newFromConfig( %$_ ) }
        @{$self->oPerlySense->rhConfig->{bookmark}}
    ];
}





=head1 METHODS

=head2 new(oPerlySense)

Create new BookmarkConfig object. Associate it with $oPerlySense.

=cut
sub new {
    my ($oPerlySense) = Devel::PerlySense::Util::aNamedArg(["oPerlySense"], @_);

    $self = bless {}, $self;    #Create the object. It looks weird because of Spiffy
    $self->oPerlySense($oPerlySense);

    return($self);
}





=head2 aMatch(file)

Parse the text in $file and return list of Bookmark::MatchResult
objects that have matches.

Die on errors, like if $file doesn't exist.

=cut
sub aMatchResult {
    my ($file) = Devel::PerlySense::Util::aNamedArg(["file"], @_);

    defined( my $source = slurp($file) ) or die("Could not read source file ($file)\n");

    $self->oPerlySense->setFindProject(file => $file) or debug("Could not identify any PerlySense Project for Bookmark matching, but that's not fatal\n");

    my @aMatchResult = map {
        Devel::PerlySense::Bookmark::MatchResult->newFromMatch(
            oDefinition => $_,
            file => $file,
            source => $source
        );
    } @{$self->raDefinition};

    return(@aMatchResult);
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
