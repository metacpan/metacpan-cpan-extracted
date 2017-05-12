use strict;
use warnings;
use Cwd;
use Carp qw(croak carp);
use GD::Image;
use Test::MockObject;
use Data::Dumper;


use Test::More tests => 1;                      # last test to print

my $class= 'Image::Resize::Path';

my $mock = Test::MockObject->new;
$mock->fake_new('GD::Image');
$mock->mock('getBounds', sub {return [0,1]});
$mock->mock('copyResampled', sub {return [0,1]});
$mock->mock('png', sub {return [0,1]});



use Image::Resize::Path;



my $test_obj = Image::Resize::Path->new;
$test_obj->supported_images(['png']);
my $dest_path = getcwd . '/test_data/dest';
my $src_path = getcwd . '/test_data';
$test_obj->dest_path($dest_path);
diag $src_path;
$test_obj->src_path($src_path);

my @images = $test_obj->resize_images(100,100);

diag @images;
diag Dumper(\@images);

is_deeply(\@images, ['test.png']);












sub setup_mock_objects
{
    my $mock_gd_obj = Test::MockObject->new;
    my $mock_gd_image_obj = Test::MockObject->new;
    
    $mock_gd_obj->fake_module('GD', 
                               'Image' => sub { carp("BITCH!!!") },
                            );    
    $mock_gd_image_obj->fake_module('GD::Image',
                                    'new' => sub { carp("NEW BITCH!!!") }, 
                                    );    
    

    return ($mock_gd_obj, $mock_gd_image_obj);
    
}
