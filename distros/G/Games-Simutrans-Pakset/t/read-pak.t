# -*- mode: cperl -*-
use strict;
use Test::More;

use Mojo::File;

################
#
# Use a single *.dat file located relative to this test script.
#
# The file contains two objects (separated by a line of '--')
# but here we should load only the first.
#
use Games::Simutrans::Pak;
{
    my $pak_file = Mojo::File->new(Mojo::File->new($0)->sibling('test_files/ind50.dat'));
    isa_ok($pak_file, 'Mojo::File');

    my $pak_text = $pak_file->slurp;
    like ($pak_text, qr/Obj=building/i, 'Loaded pak *.dat definition');

    my $pak = Games::Simutrans::Pak->new;
    isa_ok($pak, 'Games::Simutrans::Pak');

    $pak->from_string({file => $pak_file, text => $pak_text});

    is_deeply($pak->comments, [' Test file'], 'Loaded exactly one object definition, with comments');
    is($pak->name, 'WL_IND_50_00', 'Loaded correct object');
    is($pak->{chance}, 50, 'Loaded correct parameter');
    is($pak->{level}, 4, 'Loaded correct parameter');
    is(scalar %{$pak->{backimage}}, 4, 'Loaded correct number of images');
    is($pak->{backimage}{0}{0}{0}{0}{0}{1}{image}, 'images/ind/1950parking-snow', 'Correct image in grid');
    is($pak->{backimage}{0}{0}{0}{0}{0}{1}{x}, 2, 'Correct image in grid');

    my $new_text = $pak->to_string;

    like ($new_text, qr/intro_year=1950\b/, 'Generated introduction');
    like ($new_text, qr/intro_month=1\b/, 'Generated introduction');
    like ($new_text, qr/dims=1,1,4\b/, 'Generated dimensions');
    like ($new_text, qr/# Test file/, 'Retained comments');
}

################
#
#
#
use Games::Simutrans::Pakset;
{
    my $pakset_path = Mojo::File->new(Mojo::File->new($0)->sibling('test_files'));

    my $set = Games::Simutrans::Pakset->new;
    $set->path( $pakset_path );

    ok ($set->valid, 'Pakset location appears to be valid');
    $set->load();

    is (scalar @{$set->languages}, 1, 'Pakset has exactly one defined translation');

    my @object_names = sort keys %{$set->objects};
    my @object_xlat_names = map{$set->translate($set->object($_)->name)} @object_names;

    is_deeply(\@object_xlat_names, ["Car Park 1950s", "Car Park 1980s"], "Translated object names to English");

    my $an_image = $set->object('WL_IND_50_00')->{backimage}{0}{0}{0}{0}{0}{0}->{imagefile};
    like ($an_image, qr{test_files/images/ind/1950parking.png\Z}, 'Object points to correct image file');
    isa_ok($set->imagefiles->{$an_image}, 'Games::Simutrans::Image', 'Object has an attached image');
    is($set->imagefiles->{$an_image}->{tilesize}, 128, 'Correctly computed tile size for attached image');
}

done_testing;

1;
