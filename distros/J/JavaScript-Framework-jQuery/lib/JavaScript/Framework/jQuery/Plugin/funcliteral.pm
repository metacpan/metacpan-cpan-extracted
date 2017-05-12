package JavaScript::Framework::jQuery::Plugin::funcliteral;

use warnings;
use strict;

use Moose;
use JavaScript::Framework::jQuery::Subtypes qw( libraryAssets pluginAssets );
use MooseX::Types::Moose qw( Str ArrayRef );

our $VERSION = '0.05';

has 'name' => (
    is => 'ro',
    isa => Str,
    required => 1,
    default => 'funcliteral',
);

has 'funccalls' => (
    is => 'ro',
    isa => ArrayRef[ Str ],
    required => 1,
);

no Moose;

=head1 NAME

JavaScript::Framework::jQuery::Plugin::funcliteral - Add literal JavaScript code to document ready

=head1 SYNOPSIS

 # add literal text to output of $(document).ready(function (){...});
 my $plugin = JavaScript::Framework::jQuery::Plugin::funcliteral->new(
    funccalls => [
        '$("div ul").foobar();',
        '$("div ul").barfoo();'
    ]
 );

 print $plugin->cons_statement;

 #  $("div ul").foobar();
 #  $("div ul").barfoo();


=head1 DESCRIPTION

Support for addition of literal function call or other JavaScript code to the
body of the $(document).ready(...) call text.

=cut

=head1 METHODS

=cut

=head2 cons_statement( )

Return the text of the JavaScript statements passed in the constructor,
joined with newlines.

=cut

sub cons_statement {
    my ( $self ) = @_;

    return join "\n" => @{$self->funccalls};
}

1;

__END__

 # need to be able to print this type of invocation chain
 # //<![CDATA[
 #     $(document).ready(function(){
 #         $("ul.sf-menu").supersubs({
 #             minWidth: 12,
 #             maxWidth: 27,
 #             extraWidth: 1
 #         }).superfish({
 #             delay: 500,
 #             animation: {opacity:'show'},
 #             dropShadows: true,
 #             pathClass:  'current'
 #         });
 #     });
 # //]]>


=head1 AUTHOR

David P.C. Wollmann E<lt>converter42 at gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 David P.C. Wollmann, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


