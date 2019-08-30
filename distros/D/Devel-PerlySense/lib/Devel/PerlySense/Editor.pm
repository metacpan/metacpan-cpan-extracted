=head1 NAME

Devel::PerlySense::Editor - Integration with editors

=head1 DESCRIPTION


=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Editor;
$Devel::PerlySense::Editor::VERSION = '0.0221';



use Spiffy -Base;
use Data::Dumper;
use File::Basename;
use Graph::Easy;
use Text::Table;
use List::Util qw/ max first /;
use POSIX qw/ ceil /;
use Path::Class;

use Devel::PerlySense;
use Devel::PerlySense::Class;
use Devel::PerlySense::Util;
use Devel::PerlySense::Util::Log;
use Devel::PerlySense::Document::Api::Method;





=head1 PROPERTIES

=head2 oPerlySense

Devel::PerlySense object.

Default: set during new()

=cut
field "oPerlySense" => undef;





=head2 widthDisplay

The width of the display in columns, or undef if N/A.

Default: undef

=cut
field "widthDisplay" => undef;





=head2 raClassOverviewShowDefault

Names of features to show in the class overview by default.

Default: { ... }

=cut
field "raClassOverviewShowDefault" => [qw/
    inheritance
    api
    bookmarks
    uses
/];





=head2 raClassOverviewShow

Names of features to allow being show in the class overview.

Default: { ... }

=cut
field "raClassOverviewShow" => [qw/
    inheritance
    api
    bookmarks
    uses
    neighbourhood
/];





=head1 CLASS METHODS

=head2 dirExtenal()

Return the absolute directory of the external editor files.

=cut
sub dirExtenal {
    return dir(
        file(__FILE__)->dir->absolute,
        "external",
    ) . "";
}





=head2 new(oPerlySense, widthDisplay = undef)

Create new Emcacs object.

=cut
sub new {
    my ($oPerlySense, $widthDisplay) = Devel::PerlySense::Util::aNamedArg(["oPerlySense", "widthDisplay"], @_);

    $self = bless {}, $self;    #Create the object. It looks weird because of Spiffy
    $self->oPerlySense($oPerlySense);
    $self->widthDisplay($widthDisplay);

    return($self);
}





=head1 METHODS

=head2 classOverview(oClass)

Return string representing the Class Overview of $oClass.

=cut
sub classOverview {
    my ($oClass, $raShow) = Devel::PerlySense::Util::aNamedArg(["oClass", "raShow"], @_);

    my %hNameHeading = (
        Api           => "API",
        Neighbourhood => "NeighbourHood",
    );
    my @aTextOutput;
    for my $show (@$raShow) {
        my $name = ucfirst($show);
        my $nameMethod = "textClass$name";
        $self->can($nameMethod) or die("Internal error ($nameMethod)");

        my $nameHeading = $hNameHeading{$name} || $name;
        my $text = "* $nameHeading *\n" . $self->$nameMethod(oClass => $oClass);
        push(@aTextOutput, $text);
    }

    my $textOverview = $self->stripTrailingWhitespace( join("\n", @aTextOutput) );

    #Highlight the current class
    my $leftBracket = "[[]";
    my $space = "[ ]";
    my $name = $oClass->name;
    $textOverview =~ s| $leftBracket \s+ ( $name \s*? ) $space ] |[<$1>]|xg;
    debug($textOverview);

    return $textOverview;
}





=head2 textClassInheritance(oClass)

Return string representing the class hierarchy of $oClass.

=cut
sub textClassInheritance {
    my ($oClass) = Devel::PerlySense::Util::aNamedArg(["oClass"], @_);

    my $oGraph = Graph::Easy->new();
    $oGraph->set_attribute('graph', flow => "up");
    $oGraph->set_attribute('node', border => "dotted");

    $oGraph->add_node($oClass->name);
    my $rhSeenEdge = { };
    $self->addBaseClassNameToGraph(
        oGraph => $oGraph,
        oClass => $oClass,
        rhSeenEdge => $rhSeenEdge,
    );


    # Disable the subclass view until it either becomes faster and/or
    # is better rendered. The Neighbourhood view may be quite enough.

#     $self->addSubClassNameToGraph(
#         oGraph => $oGraph,
#         oClass => $oClass,
#         rhSeenEdge => $rhSeenEdge,
#     );

    my $textInheritance = $self->textCompactGraph(text => $oGraph->as_ascii()) . "\n";

    return $textInheritance;
}



sub addBaseClassNameToGraph {
    my ($oClass, $oGraph, $rhSeenEdge) = Devel::PerlySense::Util::aNamedArg(["oClass", "oGraph", "rhSeenEdge"], @_);

    for my $oClassBase (values %{$oClass->rhClassBase}) {
        $rhSeenEdge->{$oClass->name . "->" .$oClassBase->name}++ and next;
        $oGraph->add_edge($oClass->name, $oClassBase->name);

        $self->addBaseClassNameToGraph(
            oGraph => $oGraph,
            oClass => $oClassBase,
            rhSeenEdge => $rhSeenEdge,
        );
    }

    return 1;
}





sub addSubClassNameToGraph {
    my ($oClass, $oGraph, $rhSeenEdge) = Devel::PerlySense::Util::aNamedArg(["oClass", "oGraph", "rhSeenEdge"], @_);

    for my $oClassSub (values %{$oClass->rhClassSub}) {
        $rhSeenEdge->{$oClassSub->name . "->" .$oClass->name}++ and next;
        $oGraph->add_edge($oClassSub->name, $oClass->name);

        $self->addSubClassNameToGraph(
            oGraph => $oGraph,
            oClass => $oClassSub,
            rhSeenEdge => $rhSeenEdge,
        );
    }

    return 1;
}





=head2 textClassNeighbourhood(oClass)

Return string representing the neighbourhood of $oClass.

=cut
sub textClassNeighbourhood {
    my ($oClass) = Devel::PerlySense::Util::aNamedArg(["oClass"], @_);

    my $rhDirClass = $oClass->rhDirNameClassInNeighbourhood();

    my @aColText;
    for my $raNameClass (map { $rhDirClass->{$_} } qw/ up current down /) {
        my $lenMax = max( map { length } @$raNameClass );

        my $text = join(
            "\n",
            map { sprintf("[ %-*s ]", $lenMax, $_) } @$raNameClass,
        ) || "-none-";

        push(@aColText, $text);
    }

    my $oTable = Text::Table->new();
    $oTable->load([ @aColText ]);

    return "$oTable";
}





=head2 textClassUses(oClass)

Return string representing the modules used by $oClass. Use the least
number of columns to display this.

=cut
sub textClassUses {
    my ($oClass) = Devel::PerlySense::Util::aNamedArg(["oClass"], @_);

    my $columnsToFitWithin = $self->widthDisplay || 90;  ###TODO: Move to config

    return(
        $self->textTable(
            [ $oClass->aNameModuleUse() ],
            $columnsToFitWithin,
            sub {
                my ($item, $raItem) = @_;
                my $lenMax = max( map { length } @$raItem );
                sprintf("[ %-*s ]", $lenMax, $item);
            },
        )
    );
}





=head2 textTable($raItem, $columnWidthMax, [$rsRenderItem = string-as-is])

Return string with the items in $raItem rendered as a table, with as
few columns as possible.

If the $rsRenderItem sub ref is passed, it is called for each item to
be rendered:

  $rsRenderItem->($stringItem, $rsItemColumn)

where $stringItem is each individual item, and $rsItemColumn is the
items in the current column. The default is to just pass through the
$stringItem text.

=cut
sub textTable {
    my ($raItemAll, $columnsToFitWithin, $rsRenderItem) = @_;
    $rsRenderItem ||= sub { $_[0] };

    my $text = "";
    for my $columns (reverse 1 .. @$raItemAll) {
        my @aColText;

        for my $raItem ( @{$self->raItemInNGroups($raItemAll, $columns)} ) {
            my $text = join("\n", map { $rsRenderItem->($_, $raItem) } @$raItem);
            push(@aColText, $text);
        }

        my $oTable = Text::Table->new();
        $oTable->load([ @aColText ]);
        $text = "$oTable";

        length( (split(/\n/, $text))[0] ) <= $columnsToFitWithin and last;
    }


    return $text;
}





=head2 textClassBookmarks(oClass)

Return string representing the Bookmarks of $oClass.

=cut
sub textClassBookmarks {
    my ($oClass) = Devel::PerlySense::Util::aNamedArg(["oClass"], @_);

    my @aBookmarkMatchResult = $oClass->aBookmarkMatchResult();

    my $matches = join(
        "\n",
        map(
            {
                "- " . $_->oDefinition->moniker . "\n" . join(
                    "\n",
                    map(
                        {
                            sprintf(
                                "%s:%s: %s",
                                basename($_->oLocation->file),
                                $_->oLocation->row,
                                $_->text,   ##TODO: text escaped for { }
                            );
                        }
                        @{$_->raMatch},
                    ),
                ),
            }
            @aBookmarkMatchResult,
        ),
    );
    $matches &&= "$matches\n";

    return $matches;
}





=head2 textClassStructure(oClass)

Return string representing the structure of $oClass.

This includes a Signature Survey string.

=cut
sub textClassStructure {
    my ($oClass) = Devel::PerlySense::Util::aNamedArg(["oClass"], @_);

    my $textSignature = $self->textLineWrapped(
        join(
            "",
            map { $_->stringSignatureSurveyFromFile } @{$oClass->raDocument},
        ),
    );

    return "$textSignature\n";
}





=head2 textClassApi(oClass)

Return string representing the API of $oClass.

=cut
sub textClassApi {
    my ($oClass) = Devel::PerlySense::Util::aNamedArg(["oClass"], @_);

    my $oDocument = $oClass->raDocument->[0]; ### or die
    $oDocument->determineLikelyApi(nameModule => $oClass->name);

    my $oApi = $oDocument->rhPackageApiLikely->{$oClass->name} or do {
        debug("Could not find API for ("
                      . $oClass->name . ") in ("
                      . $oDocument->file . ")");
        return("");
    };

    my @aColText = map {
        my $nameMethod = $_;

        my $oMethod = Devel::PerlySense::Document::Api::Method->new(
            name => $nameMethod,
            oDocument => $oDocument,
        );

        my $oLocationDeclaration = $oApi->rhSub->{$nameMethod};
        $oMethod->signatureCall($oLocationDeclaration);
    } $oApi->aNameSubVisible(
        oPerlySense => $self->oPerlySense,
        fileCurrent => $oDocument->file,
    );

    my $columnsToFitWithin = $self->widthDisplay || 90;  ###TODO: Move to config
    return( $self->textTable(\@aColText, $columnsToFitWithin) );
}





=head2 textLineWrapped($text)

Return $text wrapped hard at the available number of columns.

=cut
sub textLineWrapped {
    my ($text) = @_;

    my $columnsToFitWithin = $self->widthDisplay || 90;  ###TODO: Move to config

    my @aLine;
    while (length($text)) {
        push(@aLine, substr($text, 0, $columnsToFitWithin, ""));
    }

    my $textWrapped = join("\n", @aLine);

    return $textWrapped;
}





=head2 raItemInNGroups($raItem, $countGroup)

Split up the items in $raItem so that they form at most $countGroup
array refs.

The items are evenly distributed between the group with the same numer
of items in each, except for the last one which may contain fewer
items.

Return array ref with $countGroup items, each of which is an array ref
with the elements in $raItem.

=cut
sub raItemInNGroups {
    my ($raItem, $countGroup) = @_;

    my @aItem = @$raItem;
    my $countItemPerGroup = ceil(@aItem / $countGroup) or return( [ ] );

    my @aGroupItem;
    while(scalar @aItem) {
        push(@aGroupItem, [ splice(@aItem, 0, $countItemPerGroup) ]);
    }
    @aItem and push(@aGroupItem, [ @aItem ]);

    return [ @aGroupItem ];
}





=head2 textCompactGraph(text)

Return compact version of $text.

=cut
sub textCompactGraph {
    my ($text) = Devel::PerlySense::Util::aNamedArg(["text"], @_);

#    debug($text);

    my @aLine = split(/\n/, $text);

    #Remove blank lines
    @aLine = grep { $_ } @aLine;

    #Put [ Class::Name ] around module names
    s{ : ( \s+ [\w:]+ \s+ ) : }{[$1]}xg for (@aLine);

    #Make [ Class::Name ] left-aligned in the box
    my $leftBracket = "[[]";
    my $space = "[ ]";
    s{ $leftBracket $space (\s+) ([\w:]+) }{[ $2$1}xg for (@aLine);

    #Remove border-only lines
    @aLine = grep { ! /[.]/ } @aLine;

    #Remove vertical-lines-only lines
    @aLine = grep { /[^ |^]/ } @aLine;

    $text = join("\n", @aLine);

    return $text;
}





=head2 formatOutputDataStructure(rhData)

Return stringification of $rhData suited for the Editor.

=cut
sub formatOutputDataStructure {
    my ($rhData) = Devel::PerlySense::Util::aNamedArg(["rhData"], @_);
    croak("Abstract method called (formatOutputDataStructure)");
}





=head2 formatOutputItem($item)

Return stringification of $item suited for the Editor. $item can be a
scalar, array ref or hash ref.

=cut
sub formatOutputItem {
    my ($value) =  @_;
    croak("Abstract method called (formatOutputDataStructure)");
}





=head2 renameIdentifier($identifier)

Return $identifier changed to suit the Editor.

Default is to do nothing.

=cut
sub renameIdentifier {
    my ($identifier) = (@_);
    return $identifier;
}





sub escapeValue {
    my ($value) = (@_);
    return $value;
}





=head2 stripTrailingWhitespace($string)

Return $string with each line in $string stripped of trailing
whitespace.

=cut
sub stripTrailingWhitespace {
    my ($string) = @_;
    return join(
        "\n",
        map { $_ =~ s/\s+$//; $_ } split("\n", $string), ## no critic
    );
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
