=head1 NAME

Devel::PerlySense::Plugin::Syntax::Moose - Plugin for parsing Moose syntax
constructs

=head1 DESCRIPTION

Parses Moose specific syntax, like the "extends" keyword.

Currently supported:


=over 4

=item * has - Attributes

Treated as subs (getters/setters).

Multiple attributes and overridden attributes are supported.

Things like C<handles>, C<clearer>, and C<predicate> aren't supported.


=item * extends - Inheritance

Single and multiple inheritance supported.


=item * with - Roles

Treated as base classes.


=back



=head1 KNOWN MOOSE BUGS

Broken Moose code, e.g. multiple extends are parsed incorrectly (the
ISA isn't reset). But you shouldn't have broken Moose code should you?

Roles are treated like base classes, because that's the most similar
Perl concept.

Some parts of the parsing is a bit sloppy and fragile, e.g. comments
in lists may be picked up.



=head1 KNOWN BUGS

This plugin module is not yet it's own distribution, which it should
be. It should have a base class inside the PerlySense distro to future
proof both PerlySense's and the plugins' APIs against each other.

The plugins could have some kind of marker for when they should be run
for a document. It could be a quick regex on the source or per line or
something.

Reporting back to PerlySense isn't quite uniform yet in that most
things are set in a hash ref, but sub location are set on the Meta
object. That should be fixed.

=cut





use strict;
use warnings;
use utf8;

package Devel::PerlySense::Plugin::Syntax::Moose;
$Devel::PerlySense::Plugin::Syntax::Moose::VERSION = '0.0221';





use Spiffy -Base;
use Carp;
use Data::Dumper;
use PPI::Document;
use PPI::Dumper;





=head1 PROPERTIES

=head1 API METHODS

=cut





=head2 parse($rhDataDocument, $oMeta, $oDocument, $oNode, $pkgNode, $row, $col, $packageCurrent)

Parse the Devel::PerlySense::Document and extract metadata. Fill
appropriate data structures.

rhDataDocument

the key e.g. "Moose" for Plugin::Syntax::Moose, is for the plugin to
manage. It's persistent during the complete parse of a document.

Return 1 or die on errors.

=cut
sub parse {
    my ($rhDataDocument, $oMeta, $oDocument, $oNode, $pkgNode, $row, $col, $packageCurrent) = Devel::PerlySense::Util::aNamedArg(["rhDataDocument", "oMeta", "oDocument", "oNode", "pkgNode", "row", "col", "packageCurrent"], @_);

    #sub  (has getter/setter)

    ### Bareword
    #   PPI::Statement
    #     PPI::Token::Word  	'has'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Token::Word  	'timeBareword'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Token::Operator  	'=>'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Structure::List  	( ... )
    #       PPI::Statement::Expression
    #         PPI::Token::Word  	'is'
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Operator  	'=>'
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Quote::Double  	'"rw"'
    #     PPI::Token::Structure  	';'

    ### Quoted
    #   PPI::Statement
    #     PPI::Token::Word  	'has'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Token::Quote::Double  	'"timeQuoted"'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Token::Operator  	'=>'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Structure::List  	( ... )
    #       PPI::Token::Whitespace  	'\n'
    #       PPI::Token::Whitespace  	'    '
    #       PPI::Statement::Expression
    #         PPI::Token::Word  	'is'
    #         PPI::Token::Whitespace  	'  '
    #         PPI::Token::Operator  	'=>'
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Quote::Double  	'"rw"'
    #         PPI::Token::Operator  	','
    #         PPI::Token::Whitespace  	'\n'
    #         PPI::Token::Whitespace  	'    '
    #         PPI::Token::Word  	'isa'
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Operator  	'=>'
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Quote::Double  	'"Int"'
    #         PPI::Token::Operator  	','
    #       PPI::Token::Whitespace  	'\n'
    #     PPI::Token::Structure  	';'

    ### Comma instead  of =>
    #   PPI::Statement
    #     PPI::Token::Word  	'has'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Token::Quote::Double  	'"timeQuotedComma"'
    #     PPI::Token::Operator  	','
    #     PPI::Token::Whitespace  	' '
    #     PPI::Structure::List  	( ... )
    #       PPI::Statement::Expression
    #         PPI::Token::Word  	'is'
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Operator  	'=>'
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Quote::Double  	'"rw"'
    #     PPI::Token::Structure  	';'

    ### Quoted list
    #   PPI::Statement
    #     PPI::Token::Word  	'has'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Structure::Constructor  	[ ... ]
    #       PPI::Statement
    #         PPI::Token::Quote::Double  	'"timeList1"'
    #         PPI::Token::Operator  	','
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Quote::Double  	'"timeList2"'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Token::Operator  	'=>'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Structure::List  	( ... )
    #       PPI::Token::Whitespace  	'\n'
    #       PPI::Token::Whitespace  	'    '
    #       PPI::Statement::Expression
    #         PPI::Token::Word  	'is'
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Operator  	'=>'
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Quote::Double  	'"rw"'
    #         PPI::Token::Operator  	','
    #       PPI::Token::Whitespace  	'\n'
    #     PPI::Token::Structure  	';'

    ### Quoted Word list
    #   PPI::Statement
    #     PPI::Token::Word  	'has'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Structure::Constructor  	[ ... ]
    #       PPI::Token::Whitespace  	' '
    #       PPI::Statement
    #         PPI::Token::QuoteLike::Words  	'qw/ timeQwList1 timeQwList2 /'
    #       PPI::Token::Whitespace  	' '
    #     PPI::Token::Whitespace  	' '
    #     PPI::Token::Operator  	'=>'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Structure::List  	( ... )
    #       PPI::Token::Whitespace  	'\n'
    #       PPI::Token::Whitespace  	'    '
    #       PPI::Statement::Expression
    #         PPI::Token::Word  	'is'
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Operator  	'=>'
    #         PPI::Token::Whitespace  	' '
    #         PPI::Token::Quote::Double  	'"ro"'
    #         PPI::Token::Operator  	','
    #       PPI::Token::Whitespace  	'\n'
    #     PPI::Token::Structure  	';'

    ### q/name/
    #   PPI::Statement
    #     PPI::Token::Word  	'has'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Token::Quote::Literal  	'q/timeSingleQuoted/'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Token::Operator  	'=>'
    #     PPI::Token::Whitespace  	' '
    #     PPI::Structure::List  	( ... )
    #     PPI::Token::Structure  	';'

    ###TODO: Getting the scalar or list contents seems very common. Extract?
    # What about comments inside a stringified list?

    if ($pkgNode eq "PPI::Token::Word" && $oNode eq "has") {
        if (ref(my $oNodeStatement = $oNode->parent) eq "PPI::Statement") {
            if (ref(my $nodeName = $oNode->snext_sibling()) ) {
                my $namesSub = "$nodeName";

                #Special case q and qq
                my $refName = ref($nodeName);
                if ($refName eq "PPI::Token::Quote::Literal" || $refName eq "PPI::Token::Quote::Interpolate") {
                    $namesSub =~ s/\w+//ms;  #Remove first word, which should be the quote operator
                }
                #Special case qw/ /
                elsif ($refName eq "PPI::Structure::Constructor" && $nodeName->can("find_first")) {
                    if (my $nodeListStatement = $nodeName->find_first("PPI::Token::QuoteLike::Words")) {
                        $namesSub = substr("$nodeListStatement", 2); #Ignore leading "qw"
                    }
                }

                for my $nameSub ( $namesSub =~ /(\w+)/gsm ) {
                    push(
                        @{$oMeta->raLocationSub},
                        $oMeta->oLocationSub(
                            $oDocument,
                            $oNodeStatement,
                            $nameSub,
                            $packageCurrent,
                        ),
                    );
                }
            }
        }
    }


    #base class (ISA and Roles)
    for my $keyword (qw/ extends with /) {
        # Slightly fragile, especially wrt comments
        if ($pkgNode eq "PPI::Statement") {
            if ($oNode =~ /^ $keyword \s+ (?:qw)? \s* (.+);$/xs) {
                my $modules = $1;
                for my $module (grep { $_ ne "qw" } $modules =~ /([\w:]+)/gs) {
                    $rhDataDocument->{rhNameModuleBase}->{$module}++;
                }
            }
        }
    }

    return(1);
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
