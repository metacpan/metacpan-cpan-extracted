package Egg::Release::JSON;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: JSON.pm 210 2007-11-03 14:38:29Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

Egg::Release::JSON - JSON module kit for Egg.

=head1 DESCRIPTION

VIEW and PLUGIN to use JSON are enclosed.

=head1 EXAMPLE

=head2 VIEW

Defolt VIEW is set and the output preparation of JSON is done.

  $e->default_view('JSON')->obj({
    hogehoge => 'hoooo',
    uhauha   => 'beeee',
    });

* Please see L<Egg::View::JSON> in detail.

=head2 PLUGIN

The method for the mutual conversion of JSON is added.

  my $json_data = {
    aaaaa => 'bbbbb',
    ccccc => 'ddddd',
    };
  my $json_js   = $e->obj2json($json_data);
  my $json_hash = $e->json2obj($json_js);

The object of L<JSON> module is acquired.

  my $json= $e->json;

* Please see the document of L<JSON > in detail.

=head1 SEE ALSO

L<JSON>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
