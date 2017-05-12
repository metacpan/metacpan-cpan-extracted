#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the Labels model.

=cut

use Jifty::Test tests => 9;

# Make sure we can load the model
use_ok('TestApp::Model::Labels');

# Grab a system user
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, "Found a system user");


use JiftyX::ModelHelpers;

# Try testing a create
my $o = TestApp::Model::Labels->new(current_user => $system_user);
my ($id) = $o->create(
    name => 'C++',
    hit => 3,
);
ok($id, "Labels create returned success");
ok($o->id, "New Labels has valid id set");
is($o->id, $id, "Create returned the right id");


use JiftyX::ModelHelpers;

my $rel = M('LabelPost');

# And another
$o->create( 
        name => 'Perl',
        hit => 20,
);
$rel->create( ref_label => $o ) for ( 1 .. 20 );


$o->create( 
        name => 'Jifty',
        hit => 10,
);
$rel->create( ref_label => $o ) for ( 1 .. 10 );

use_ok( 'JiftyX::CloudTags' );

my $tgen = new JiftyX::CloudTags;
ok( $tgen );
$tgen->set_tags( 'LabelsCollection' , 
    text_by => 'name',
    size_by => 'posts',
    break_width => 200,
);
my $html = $tgen->render;
like( $html , qr{\Q<span class="cloudtags" style="font-size: 48px;">} , 'html ok' );
like( $html , qr{\Q<br/>} , 'br ok' );


