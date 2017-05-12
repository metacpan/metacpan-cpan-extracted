package FuseBead::From::PNG::View::JSON;

use strict;
use warnings;

BEGIN {
    $FuseBead::From::PNG::VERSION = '0.02';
}

use parent qw(FuseBead::From::PNG::View);

use Data::Debug;

use JSON;

sub print {
    my $self = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    return JSON->new->utf8->pretty->encode( \%args );
}

=pod

=head1 NAME

FuseBead::From::PNG::View::JSON - Format data returned from FuseBead::From::PNG

=head1 SYNOPSIS

  use FuseBead::From::PNG;

  my $object = FuseBead::From::PNG->new({ filename => 'my_png.png' });

  $object->process(view => 'JSON'); # Data is returned as JSON

=head1 DESCRIPTION

Class to returned processed data in JSON format

=head1 USAGE

=head2 new

 Usage     : ->new()
 Purpose   : Returns FuseBead::From::PNG::View::JSON object

 Returns   : FuseBead::From::PNG::View::JSON object
 Argument  :
 Throws    :

 Comment   :
 See Also  :

=head2 print

 Usage     : ->print({}) or ->print(key1 => val1, key2 => val2)
 Purpose   : Returns JSON formated data (in utf8 and pretty format)

 Returns   : Returns JSON formated data (in utf8 and pretty format)
 Argument  :
 Throws    :

 Comment   :
 See Also  :


=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

    Travis Chase
    CPAN ID: GAUDEON
    gaudeon@cpan.org
    https://github.com/gaudeon/FuseBead-From-Png

=head1 COPYRIGHT

This program is free software licensed under the...

    The MIT License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
