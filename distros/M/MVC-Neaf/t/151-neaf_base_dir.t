#!/usr/bin/env perl

=head1 DESCRIPTION

Test that absolute/relative path handling works.

=cut

use strict;
use warnings;
use Test::More;
use File::Spec;

use MVC::Neaf::X;

sub path_is ($$;$) { ## no critic
    my ($got, $exp, $comment) = @_;
    is( File::Spec->canonpath($got), File::Spec->canonpath($exp), $comment );
};

my $obj = MVC::Neaf::X->new( neaf_base_dir => '/www/mysite' );

path_is $obj->dir( 'foo' ), '/www/mysite/foo', 'relative path extended';
path_is $obj->dir( '/www/images' ), '/www/images', 'absolute path untouched';
is_deeply
    $obj->dir( [ 'foo', '/www/images' ] ),
    [map { File::Spec->canonpath($_) } '/www/mysite/foo', '/www/images'],
    'ditto with array ref';

done_testing;

