#!perl

use strict;
use warnings;

use Carp qw(croak);

use Test::More;
use File::Basename;
use File::Path;
use File::Spec;

use File::ConfigDir 'config_dirs';

my $test_dir;
END { defined( $test_dir ) and rmtree $test_dir; }

sub test_dir
{
    unless( defined( $test_dir ) )
    {
        $test_dir = File::Spec->rel2abs( File::Spec->curdir () );
        $test_dir = File::Spec->catdir ( $test_dir, "test_output_" . $$ );
        $^O eq 'VMS' and $test_dir = VMS::Filespec::unixify($test_dir);
        rmtree $test_dir;
        mkpath $test_dir;
        # create our two test dirs
        mkpath ( File::Spec->catdir( $test_dir, 'plugg', 'extra' ) );
        mkpath ( File::Spec->catdir( $test_dir, 'pure' ) );
    }

    return $test_dir;
}

test_dir();

my $plugg_src = sub {
    my @cfg_base = @_;
    return File::Spec->catdir( $test_dir, 'plugg', @cfg_base);
};

my $pure_src = sub {
    my @cfg_base = @_;
    0 == scalar(@cfg_base)
      or croak "pure_src(), not pure_src("
      . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return File::Spec->catdir( $test_dir, 'pure' );
};

ok(File::ConfigDir::_plug_dir_source($plugg_src), "registered extensible plugin");
ok(File::ConfigDir::_plug_dir_source($pure_src, "0E0"), "registered pure plugin");

ok(!File::ConfigDir::_plug_dir_source(), "registered nothing");
ok(!File::ConfigDir::_plug_dir_source(undef), "registered undef");

my @dirs = config_dirs();
note( "config_dirs: " . join( ",", @dirs ) );
ok( scalar @dirs >= 3, "config_dirs" );    # we expect system_cfg_dir + plugs
is( $dirs[-1], File::Spec->catdir( $test_dir, 'pure'), 'pure');
is( $dirs[-2], File::Spec->catdir( $test_dir, 'plugg'), 'plugg');

@dirs = config_dirs(qw(extra));
note( "config_dirs: " . join( ",", @dirs ) );
ok( scalar @dirs >= 2, "config_dirs" );    # we expect our plugs
is( $dirs[-1], File::Spec->catdir( $test_dir, 'pure'), 'pure with extra');
is( $dirs[-2], File::Spec->catdir( $test_dir, 'plugg', 'extra'), 'plugg with extra');

done_testing();
