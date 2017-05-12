use strict;
use warnings;
use utf8;

package Pod::Weaver::PluginBundle::Author::LESPEA;
$Pod::Weaver::PluginBundle::Author::LESPEA::VERSION = '1.008000';
BEGIN {
  $Pod::Weaver::PluginBundle::Author::LESPEA::AUTHORITY = 'cpan:LESPEA';
}

# ABSTRACT: A bundle that implements LESPEA's preferred Pod::Weaver config

use namespace::autoclean;
use Pod::Weaver::Config::Assembler;



sub _exp {
    return Pod::Weaver::Config::Assembler->expand_package($_[0]);
}


sub mvp_bundle_config {
    my (undef, $params) = @_;
    my $opts = $params->{payload};

    ## no critic 'ValuesAndExpressions::RequireInterpolationOfMetachars'
    my @setup = (
        [ '@Author::LESPEA/CorePrep'             , _exp('@CorePrep')             , {} ]                            ,

        [ '@Author::LESPEA/Name'                 , _exp('Name')                  , {} ]                            ,
        [ '@Author::LESPEA/Version'              , _exp('Version')               , {} ]                            ,

        [ '@Author::LESPEA/prelude'              , _exp('Region')                , { region_name => 'prelude' } ]  ,

        [ 'SYNOPSIS'                             , _exp('Generic')               , {} ]                            ,
        [ 'OVERVIEW'                             , _exp('Generic')               , {} ]                            ,
        [ 'DESCRIPTION'                          , _exp('Generic')               , {} ]                            ,

        [ 'EXPORTS'                              , _exp('Generic')               , {} ]                            ,

        [ 'OPTIONS'                              , _exp('Collect')               , { command => 'option' } ]       ,
        [ 'CONSTANTS'                            , _exp('Collect')               , { command => 'const'  } ]       ,
        [ 'ATTRIBUTES'                           , _exp('Collect')               , { command => 'attr' } ]         ,
        [ 'METHODS'                              , _exp('Collect')               , { command => 'method' } ]       ,
        [ 'FUNCTIONS'                            , _exp('Collect')               , { command => 'func' } ]         ,

        [ '@Author::LESPEA/Leftovers'            , _exp('Leftovers')             , {} ]                            ,
        [ '@Author::LESPEA/postlude'             , _exp('Region')                , { region_name => 'postlude' } ] ,
        [ '@Author::LESPEA/SeeAlso'              , _exp('SeeAlso')               , {} ]                            ,
        [ '@Author::LESPEA/Installation'         , _exp('Installation')          , {} ]                            ,
        [ '@Author::LESPEA/Authors'              , _exp('Authors')               , {} ]                            ,
    );


    #  Don't include "support" if this isn't a cpan module
    if ($opts->{is_cpan}) {
        push @setup, [ '@Author::LESPEA/Support', _exp('Support'), {} ];
    }


    push @setup, (
        [ '@Author::LESPEA/Legal'              , _exp('Legal')              , {} ]                        ,
        [ '@Author::LESPEA/WarrantyDisclaimer' , _exp('WarrantyDisclaimer') , {} ]                        ,
        [ '@Author::LESPEA/-Transformer'       , _exp('-Transformer')       , { transformer => 'List' } ] ,
    );

    return @setup;
}


# Happy ending
1;

__END__

=pod

=head1 NAME

Pod::Weaver::PluginBundle::Author::LESPEA - A bundle that implements LESPEA's preferred Pod::Weaver config

=head1 VERSION

version 1.008000

=head1 SYNOPSIS

    In weaver.ini:

    [@Author::LESPEA]

=head1 DESCRIPTION

This is the bundle used by LESPEA when using L<Pod::Weaver|Pod::Weaver> to generate documentation for Perl modules.

It is nearly equivalent to the following:

    [@CorePrep]

    [Name]
    [Version]

    [Region  / prelude]

    [Generic / SYNOPSIS]
    [Generic / OVERVIEW]
    [Generic / DESCRIPTION]

    [Generic / EXPORTS]

    [Collect / OPTIONS]
    command = option

    [Collect / CONSTANTS]
    command = const

    [Collect / ATTRIBUTES]
    command = attr

    [Collect / METHODS]
    command = method

    [Collect / FUNCTIONS]
    command = func

    [Leftovers]

    [Region  / postlude]

    [SeeAlso]

    [Installation]

    [Authors]
    [Support]
    [Legal]

    [WarrantyDisclaimer]


    [-Transformer]
    transformer = List

=encoding utf8

=for Pod::Coverage mvp_bundle_config

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::PluginBundle::Author::LESPEA|Dist::Zilla::PluginBundle::Author::LESPEA>

=item *

L<Pod::Weaver|Pod::Weaver>

=item *

L<Pod::Weaver::Section::Installation|Pod::Weaver::Section::Installation>

=item *

L<Pod::Weaver::Section::Support|Pod::Weaver::Section::Support>

=item *

L<Pod::Weaver::Section::WarrantyDisclaimer|Pod::Weaver::Section::WarrantyDisclaimer>

=item *

L<Pod::Elemental::Transformer::List|Pod::Elemental::Transformer::List>

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Adam Lesperance <lespea@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Lesperance.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
