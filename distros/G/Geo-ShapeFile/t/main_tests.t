#  tests for Geo::ShapeFile

use Test::More;
use strict;
use warnings;
use rlib '../lib', './lib';

use Geo::ShapeFile;
use Geo::ShapeFile::Shape;
use Geo::ShapeFile::Point;

#  should use $FindBin::bin for this
my $dir = "t/test_data";

note "Testing Geo::ShapeFile version $Geo::ShapeFile::VERSION\n";

use Geo::ShapeFile::TestHelpers;

#  conditional test runs approach from
#  http://www.modernperlbooks.com/mt/2013/05/running-named-perl-tests-from-prove.html

exit main( @ARGV );

sub main {
    my @args  = @_;

    if (@args) {
        for my $name (@args) {
            die "No test method test_$name\n"
                if not my $func = (__PACKAGE__->can( 'test_' . $name ) || __PACKAGE__->can( $name ));
            $func->();
        }
        done_testing;
        return 0;
    }

    test_open_croaks();
    test_corners();
    test_shapes_in_area();
    #test_end_point_slope();
    test_shapepoint();
    test_files();
    test_files_no_caching();
    test_file_version_defined();
    test_empty_dbf();
    test_points_in_polygon();
    test_spatial_index();
    test_angle_to();

    test_shape_indexing();
    
    test_type();

    done_testing;
    return 0;
}



###########################################

sub test_file_version_defined {
    #github #22
    my $empty_file = "$dir/empty_points";
    
    foreach my $type (qw /shx shp/) {
        my $obj = Geo::ShapeFile->new("${empty_file}.${type}");
        my $version = $obj->file_version; 
    
        ok (defined $version, "file_version: got defined value for empty file of type $type");
    }
}


sub test_dbf_header {
    my %data = Geo::ShapeFile::TestHelpers::get_data();

    foreach my $base (sort keys %data) {

        my $shp = Geo::ShapeFile->new ("$dir/$base");

        my $hdr = $shp->get_dbf_field_info;
    
        #  not the world's best test, but it ensures the returned copy is corrct
        is_deeply ($hdr, $shp->{dbf_field_info}, "header for $base has correct structure");
    }
}


sub test_open_croaks {
    my $filename = "blurfleblargfail";
    
    my $shp = eval {
        Geo::ShapeFile->new ($filename);
    };
    my $e = $@;
    ok ($e, 'threw an exception on invalid file');
    
}



sub test_shapepoint {
    my @test_points = (
        ['1','1'],
        ['1000000','1000000'],
        ['9999','43525623523525'],
        ['2532525','235253252352'],
        ['2.1352362','1.2315216236236'],
        ['2.2152362','1.2315231236236','1134'],
        ['2.2312362','1.2315236136236','1214','51321'],
        ['2.2351362','1.2315236216236','54311'],
    );

    my @pnt_objects;
    foreach my $pts (@test_points) {
        my ($x,$y,$m,$z) = @$pts;
        my $txt;

        if(defined $z && defined $m) {
            $txt = "Point(X=$x,Y=$y,Z=$z,M=$m)";
        }
        elsif (defined $m) {
            $txt = "Point(X=$x,Y=$y,M=$m)";
        }
        else {
            $txt = "Point(X=$x,Y=$y)";
        }
        my $p1 = Geo::ShapeFile::Point->new(X => $x, Y => $y, Z => $z, M => $m);
        my $p2 = Geo::ShapeFile::Point->new(Y => $y, X => $x, M => $m, Z => $z);
        print "p1=$p1\n";
        print "p2=$p2\n";
        cmp_ok ( $p1, '==', $p2, "Points match");
        cmp_ok ("$p1", 'eq', $txt);
        cmp_ok ("$p2", 'eq', $txt);
        push @pnt_objects, $p1;
    }
    
    
    return;
    
}

sub test_angle_to {
    my $p1 = Geo::ShapeFile::Point->new (X => 0, Y => 0);

    my @checks = (
        [ 0,  0,    0],
        [ 1,  0,   90],
        [ 1,  1,   45],
        [ 0,  1,    0],
        [-1,  1,  315],
        [-1,  0,  270],
        [-1, -1,  225],
        [ 0, -1,  180],
    );

    foreach my $p2_data (@checks) {
        my ($x, $y, $exp) = @$p2_data;
        my $p2 = Geo::ShapeFile::Point->new (X => $x, Y => $y);
        my $angle = $p1->angle_to ($p2);

        is (
            $angle,
            $exp,
            "Got expected angle of $exp for $x,$y",
        );
    }

    return;
}

sub test_end_point_slope {
    return;  #  no testing yet - ths was used for debug

    my %data  = Geo::ShapeFile::TestHelpers::get_data();
    my %data2 = (drainage => $data{drainage});
    %data = %data2;

    my $obj = Geo::ShapeFile->new("$dir/drainage");
    my $shape = $obj->get_shp_record(1);
    my $start_pt = Geo::ShapeFile::Point->new(X => $shape->x_min(), Y => $shape->y_min());
    my $end_pt   = Geo::ShapeFile::Point->new(X => $shape->x_min(), Y => $shape->y_max());
    my $hp = $shape->has_point($start_pt);
    
    printf
        "%i : %i\n",
        $shape->has_point($start_pt),
        $shape->has_point($end_pt);
    print;

    return;
}


sub test_files_no_caching {
    test_files ('no_cache');
}

sub test_files {
    my $no_cache = shift;
    
    my %data = Geo::ShapeFile::TestHelpers::get_data();

    foreach my $base (sort keys %data) {
        foreach my $ext (qw/dbf shp shx/) {
            ok(-f "$dir/$base.$ext", "$ext file exists for $base");
        }
        my $fname = "$dir/$base.shp";
        my $obj = $data{$base}->{object}
                = Geo::ShapeFile->new("$dir/$base", {no_cache => $no_cache});
        
        my @expected_fld_names
          = grep
            {$_ ne '_deleted'}
            split /\s+/, $data{$base}{dbf_labels};
        my @got_fld_names = $obj->get_dbf_field_names;

        is_deeply (
            \@expected_fld_names,
            \@got_fld_names,
            "got expected field names for $base",
        );

        # test SHP
        cmp_ok (
            $obj->shape_type_text(),
            'eq',
            $data{$base}->{shape_type},
            "Shape type for $base",
        );
        cmp_ok(
            $obj->shapes(),
            '==',
            $data{$base}->{shapes},
            "Number of shapes for $base"
        );

        # test shapes
        my $nulls = 0;
        subtest "$base has valid records" => sub {
            if (!$obj->records()) {
                ok (1, "$base has no records, so just pass this subtest");
            }

            for my $n (1 .. $obj->shapes()) {
                my($offset, $cl1) = $obj->get_shx_record($n);
                my($number, $cl2) = $obj->get_shp_record_header($n);

                cmp_ok($cl1, '==', $cl2,    "$base($n) shp/shx record content-lengths");
                cmp_ok($n,   '==', $number, "$base($n) shp/shx record ids agree");

                my $shp = $obj->get_shp_record($n);

                if ($shp->shape_type == 0) {
                    $nulls++;
                }

                my $parts = $shp->num_parts;
                my @parts = $shp->parts;
                cmp_ok($parts, '==', scalar(@parts), "$base($n) parts count");

                my $points = $shp->num_points;
                my @points = $shp->points;
                cmp_ok($points, '==', scalar(@points), "$base($n) points count");

                my $undefs = 0;
                foreach my $pnt (@points) {
                    defined($pnt->X) || $undefs++;
                    defined($pnt->Y) || $undefs++;
                }
                ok(!$undefs, "undefined points");

                my $len = length($shp->{shp_data});
                cmp_ok($len, '==', 0, "$base($n) no leftover data");
            }
        };

        ok($nulls == $data{$base}->{nulls});
        
        #  need to test the bounds
        my @shapes_in_file;
        for my $n (1 .. $obj->shapes()) {
            push @shapes_in_file, $obj->get_shp_record($n);
        }

        my %bounds = $obj->find_bounds(@shapes_in_file);
        for my $bnd (qw /x_min y_min x_max y_max/) {
            is ($bounds{$bnd}, $data{$base}{$bnd}, "$bnd across objects matches, $base");
        }

        if (defined $data{$base}{y_max}) {
            is ($obj->height, $data{$base}{y_max} - $data{$base}{y_min}, "$base has correct height");
            is ($obj->width,  $data{$base}{x_max} - $data{$base}{x_min}, "$base has correct width");
        }
        else {
            is ($obj->height, undef, "$base has correct height");
            is ($obj->width,  undef, "$base has correct width");
        }

        # test DBF
        ok($obj->{dbf_version} == 3, "dbf version 3");

        cmp_ok(
            $obj->{dbf_num_records},
            '==',
            $obj->shapes(),
            "$base dbf has record per shape",
        );

        cmp_ok(
            $obj->records(),
            '==',
            $obj->shapes(),
            "same number of shapes and records",
        );

        subtest "$base: can read each record" => sub {
            if (!$obj->records()) {
                ok (1, "$base has no records, so just pass this subtest");
            }

            for my $n (1 .. $obj->shapes()) {
                ok (my $dbf = $obj->get_dbf_record($n), "$base($n) read dbf record");
            }
        };

        #  This is possibly redundant due to get_dbf_field_names check above,
        #  although that does not check against each record.
        my @expected_flds = sort split (/ /, $data{$base}->{dbf_labels});
        subtest "dbf for $base has correct labels" => sub {
            if (!$obj->records()) {
                ok (1, "$base has no records, so just pass this subtest");
            }
            for my $n (1 .. $obj->records()) {
                my %record = $obj->get_dbf_record($n);
                is_deeply (
                    [sort keys %record],
                    \@expected_flds,
                    "$base, record $n",
                );
            }
        };
        
        if ($obj->shapes) {
            #  a bit lazy, as we check for any caching, not specific caching
            my $expect_cache = !$no_cache;
            #  tests should not know about internals
            my $object_cache = $obj->{_object_cache};
            my $cache_count = 0;
            foreach my $type (keys %$object_cache) {
                $cache_count += scalar keys %{$object_cache->{$type}};
            }
            my $nc_msg = defined $no_cache ? 'on' : 'off';
            is (!!$cache_count,
                $expect_cache,
                "$fname: Got expected caching for no_cache flag: $nc_msg",
            );
        }
    }

    return;
}


sub test_empty_dbf {
    my $empty_dbf = Geo::ShapeFile::TestHelpers::get_empty_dbf();
    my $obj = Geo::ShapeFile->new("$dir/$empty_dbf");
    my $records = $obj->records;
    is ($records, 0, 'empty dbf file has zero records');
}


sub test_shapes_in_area {
    my $shp = Geo::ShapeFile->new ("$dir/test_shapes_in_area");

    my @shapes_in_area = $shp->shapes_in_area (1, 1, 11, 11);
    is_deeply (
        [1],
        \@shapes_in_area,
        'Shape is in area'
    );

    @shapes_in_area = $shp->shapes_in_area (1, 1, 11, 9);
    is_deeply (
        [1],
        \@shapes_in_area,
        'Shape is in area'
    );

    @shapes_in_area = $shp->shapes_in_area (11, 11, 12, 12);
    is_deeply (
        [],
        \@shapes_in_area,
        'Shape is not in area'
    );

    my @bounds;

    @bounds = (1, -1, 9, 11);
    @shapes_in_area = $shp->shapes_in_area (@bounds);
    is_deeply (
        [1],
        \@shapes_in_area,
        'edge overlap on the left, right edge outside bounds',
    );


    @bounds = (0, -1, 9, 11);
    @shapes_in_area = $shp->shapes_in_area (@bounds);
    is_deeply (
        [1],
        \@shapes_in_area,
        'left and right edges outside the bounds, upper and lower within',
    );

    ###  Now check with a larger region
    $shp = Geo::ShapeFile->new("$dir/lakes");

    #  This should get all features
    @bounds = (-104, 17, -96, 22);
    @shapes_in_area = $shp->shapes_in_area (@bounds);
    is_deeply (
        [1, 2, 3],
        \@shapes_in_area,
        'All lake shapes in bounds',
    );
    
    #  just the western two features
    @bounds = (-104, 17, -100, 22);
    @shapes_in_area = $shp->shapes_in_area (@bounds);
    is_deeply (
        [1, 2],
        \@shapes_in_area,
        'Western two lake shapes in bounds',
    );
    
    #  the western two features with a partial overlap
    @bounds = (-104, 17, -101.7314, 22);
    @shapes_in_area = $shp->shapes_in_area (@bounds);
    is_deeply (
        [1, 2],
        \@shapes_in_area,
        'Western two lake shapes in bounds, partial overlap',
    );

    return;
}


sub test_corners {
    my $shp = Geo::ShapeFile->new("$dir/lakes");

    my $ul = $shp->upper_left_corner();
    my $ll = $shp->lower_left_corner();
    my $ur = $shp->upper_right_corner();
    my $lr = $shp->lower_right_corner();
    
    is ($ul->X, $ll->X,'corners: min x vals');
    is ($ur->X, $lr->X,'corners: max x vals');
    is ($ll->Y, $lr->Y,'corners: min y vals');
    is ($ul->Y, $ur->Y,'corners: max y vals');

    cmp_ok ($ul->X, '<', $ur->X, 'corners: ul is left of ur');
    cmp_ok ($ll->X, '<', $lr->X, 'corners: ll is left of lr');

    cmp_ok ($ll->Y, '<', $ul->Y, 'corners: ll is below ul');
    cmp_ok ($lr->Y, '<', $ur->Y, 'corners: lr is below ur');

    return;
}

sub test_points_in_polygon {
    my $shp;
    my $filename;

    #  multipart poly
    $filename = 'states.shp';
    $shp = Geo::ShapeFile->new ("$dir/$filename");

    my @in_coords = (
        [-112.386, 28.950],
        [-112.341, 29.159],
        [-112.036, 29.718],
        [-110.186, 30.486],
        [-114.845, 32.380],
    );
    my @out_coords = (
        [-111.286, 27.395],
        [-113.843, 30.140],
        [-111.015, 31.767],
        [-112.594, 34.300],
        [-106.772, 28.420],
        [-114.397, 24.802],
    );

    #  shape 23 is sonora
    my $test_poly = $shp->get_shp_record(23);

    subtest "$filename polygon 23 (not indexed) contains points" => sub {
        foreach my $coord (@in_coords) {
            my $point  = Geo::ShapeFile::Point->new(X => $coord->[0], Y => $coord->[1]);
            my $result = $test_poly->contains_point ($point);
            ok ($result, "$point is in $filename polygon 23");
        }
    };

    subtest "$filename polygon 23 (not indexed) does not contain points" => sub {
        foreach my $coord (@out_coords) {
            my $point  = Geo::ShapeFile::Point->new(X => $coord->[0], Y => $coord->[1]);
            my $result = $test_poly->contains_point ($point);
            ok (!$result, "$point is not in $filename polygon 23");
        }
    };

    #  use the spatial index
    $test_poly->build_spatial_index;

    subtest "$filename polygon 23 (indexed) contains points" => sub {
        foreach my $coord (@in_coords) {
            my $point  = Geo::ShapeFile::Point->new(X => $coord->[0], Y => $coord->[1]);
            my $result = $test_poly->contains_point ($point, 0);
            ok ($result, "$point is in $filename polygon 23 (indexed)");
        }
    };

    subtest "$filename polygon 23 (indexed) does not contain points" => sub {
        foreach my $coord (@out_coords) {
            my $point  = Geo::ShapeFile::Point->new(X => $coord->[0], Y => $coord->[1]);
            my $result = $test_poly->contains_point ($point);
            ok (!$result, "$point is not in $filename polygon 23 (indexed)");
        }
    };

    #  now try with a shapefile with holes in the polys
    $filename = 'polygon.shp';
    $shp = Geo::ShapeFile->new ("$dir/$filename");
    #  shape 83 has holes
    $test_poly = $shp->get_shp_record(83);

    @in_coords = (
        [477418, 4762016],
        [476644, 4761530],
        [477488, 4760789],
        [477716, 4760055],
    );
    @out_coords = (
        [477521, 4760247],  # hole
        [477414, 4761150],  # hole
        [477388, 4761419],  # hole
        [477996, 4761648],  # hole
        [476810, 4761766],  # outside but in bounds
        [478214, 4760627],  # outside but in bounds
        [477499, 4762436],  # outside bounds
    );

    subtest "$filename polygon 83 (not indexed) contains points" => sub { 
        foreach my $coord (@in_coords) {
            my $point  = Geo::ShapeFile::Point->new(X => $coord->[0], Y => $coord->[1]);
            my $result = $test_poly->contains_point ($point);
            ok ($result, "$point is in $filename polygon 83");
        }
    };

    subtest "$filename polygon 83 (not indexed) does not contain points" => sub { 
        foreach my $coord (@out_coords) {
            my $point  = Geo::ShapeFile::Point->new(X => $coord->[0], Y => $coord->[1]);
            my $result = $test_poly->contains_point ($point);
            ok (!$result, "$point is not in $filename polygon 83");
        }
    };

    #  Now with the spatial index.
    $test_poly->build_spatial_index;

    subtest "$filename polygon 83 (indexed) contains points" => sub {
        foreach my $coord (@in_coords) {
            my $point  = Geo::ShapeFile::Point->new(X => $coord->[0], Y => $coord->[1]);
            my $result = $test_poly->contains_point ($point, 0);
            ok ($result, "$point is in $filename polygon 83 (indexed)");
        }
    };
    subtest "$filename polygon 83 (indexed) does not contain points" => sub {
        foreach my $coord (@out_coords) {
            my $point  = Geo::ShapeFile::Point->new(X => $coord->[0], Y => $coord->[1]);
            my $result = $test_poly->contains_point ($point);
            ok (!$result, "$point is not in $filename polygon 83 (indexed)");
        }
    };

    return;
}


sub test_spatial_index {
    #  polygon.shp has a variety of polygons
    my $poly_file = "$dir/polygon";

    my $shp_use_idx = Geo::ShapeFile->new ($poly_file);
    my $shp_no_idx  = Geo::ShapeFile->new($poly_file);

    my $sp_index = $shp_use_idx->build_spatial_index;

    ok ($sp_index, 'got a spatial index');

    my @bounds = $shp_use_idx->bounds;
    my $objects = [];
    $sp_index->query_completely_within_rect (@bounds, $objects);

    my @shapes = $shp_use_idx->get_all_shapes;

    is (
        scalar @$objects,
        scalar @shapes,
        'index contains same number of objects as shapefile',
    );

    #  need to sort the arrays to compare them
    my @sorted_shapes  = $shp_use_idx->get_shapes_sorted;
    my @sorted_objects = $shp_use_idx->get_shapes_sorted ($objects);

    is_deeply (
        \@sorted_objects,
        \@sorted_shapes,
        'spatial_index contains all objects',
    );

    #  now get the mid-point for a lower-left bounds
    my $mid_x =  ($bounds[0] + $bounds[2]) / 2;
    my $mid_y =  ($bounds[1] + $bounds[3]) / 2;
    my @bnd_ll = ($bounds[0], $bounds[1], $mid_x, $mid_y);

    foreach my $expected ([\@bounds, 474], [\@bnd_ll, 130]) {
        my $bnds = $expected->[0];
        my $shape_count = $expected->[1];

        my $shapes_in_area_no_idx  = $shp_no_idx->shapes_in_area (@$bnds);
        my $shapes_in_area_use_idx = $shp_use_idx->shapes_in_area (@$bnds);
    
        my $message = 'shapes_in_area same with and without spatial index, bounds: '
            . join ' ', @$bnds;

        is (scalar @$shapes_in_area_no_idx,  $shape_count, 'got right number of shapes back, no index');
        is (scalar @$shapes_in_area_use_idx, $shape_count, 'got right number of shapes back, use index');

        is_deeply (
            [sort @$shapes_in_area_no_idx],
            [sort @$shapes_in_area_use_idx],
            $message,
        );
    }       
    
}

sub test_shape_indexing {
    my $poly_file = "$dir/poly_to_check_index";
    
    my $shp = Geo::ShapeFile->new ($poly_file);

    my @in_coords = (
        [-1504329.017, -3384142.590],
        [ -811568.465, -3667544.634],
        [-1417733.948, -3793501.098],
    );

    foreach my $size (5, 10, 15, 20, 100) {
        foreach my $shape ($shp->get_all_shapes) {
            my %part_indexes = $shape->build_spatial_index ($size);
            foreach my $part (values %part_indexes) {
                my $containers = $part->{containers};
                ok (scalar keys %$containers == $size, "index generated $size containers")
            }
            subtest "polygon contains points when using index of size $size" => sub { 
                foreach my $coord (@in_coords) {
                    my $point  = Geo::ShapeFile::Point->new(X => $coord->[0], Y => $coord->[1]);
                    my $result = $shape->contains_point ($point);
                    ok ($result, "$point is in polygon");
                }
            }
        }
    }
}

sub test_type {
    my $poly_file = "$dir/poly_to_check_index";    
    my $shp = Geo::ShapeFile->new ($poly_file);
    
    ok !$shp->type_is(200), 'invalid numeric type returns false';
    ok !$shp->type_is(5.2), 'floating point numeric type returns false';
    ok $shp->type_is(5), 'valid numeric type returns true';
    ok $shp->type_is('polygon'), 'valid text type returns true';
    ok $shp->type_is('PolygoN'), 'text type is case insensitive';
    
}
