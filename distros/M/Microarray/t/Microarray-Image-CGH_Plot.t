#!/usr/bin/perl -w

use strict;

use FindBin;
use Test::More tests=>4;
use Test::Group;
use Test::Image::GD;
use Microarray::File::Data;

#1
BEGIN {
	use_ok('Microarray::Image::CGH_Plot');
}

my ($oData_File,$oClone_File,$oGenome_Image,$oChrom_Image,$chr_plot,$cgh_plot);

my $directory = $FindBin::Bin;
my $file = $directory.'/../test_files/quantarray.csv';
my $clone_file = $directory.'/../test_files/Allclonepos.csv';
begin_skipping_tests "The test-files 'quantarray.csv' and 'Allclonepos.csv' could not be found" unless ((-s $file)&&(-s $clone_file));  # skip to end

#2
test "Object creation" => sub {
	ok($oData_File = data_file->new($file),'data_file object creation');
	isa_ok($oData_File,'quantarray_file','isa quantarry_file object');
	ok($oClone_File = clone_locn_file->new($clone_file),'clone_locn_file object creation');
	isa_ok($oClone_File,'clone_locn_file','isa clone_locn_file object');
	ok($oGenome_Image = genome_cgh_plot->new($oData_File,$oClone_File),'genome_cgh_plot');
	ok($oChrom_Image = cgh_plot->new($oData_File,$oClone_File),'cgh_plot');
};

#3
test "Image plotting" => sub {
	SKIP: {
        $chr_plot = $directory.'/../test_files/chr_plot.png';
        # figure we only need to test one open() in this directory
		eval { open (CHRPLOT,">$chr_plot") };
		skip "Couldn't open filehandle for creating plot", 4 if $@;
        ok($oChrom_Image->plot_gene_locn( 'CBL' => { chr => '11', start => '118582200', end => '118684066' } ),'chr_plot plot_gene_locn');
		ok(my $chr_plot_png = $oChrom_Image->make_plot(plot_chromosome=>11,scale=>100000));
		print CHRPLOT $chr_plot_png;
		close CHRPLOT;
		
        ok($oGenome_Image->plot_gene_locn( 
			'BRCA1' => { chr => '17', start => '38449840', end=> '38530994' },
			'BRCA2' => { chr => '13', start => '31787617', end => '31871806' },
			'CBL' => { chr => '11', start => '118582200', end => '118684066' } 
		),'genome_plot plot_gene_locn');
        $cgh_plot = $directory.'/../test_files/cgh_plot.png';
		ok(my $cgh_plot_png = $oGenome_Image->make_plot(scale=>3000000));
		open (CGHPLOT,">$cgh_plot");
		print CGHPLOT $cgh_plot_png;
		close CGHPLOT;
	}
};

#4
test "Image test" => sub {		
	ok(-s $chr_plot,'the chromosome plot was created');
	SKIP: {
		skip "no chromosome plot to test", 2 unless (-s $chr_plot);
		size_ok($directory.'/../test_files/chr_plot.png',[1345,450],'chr plot size');
		cmp_image($directory.'/../test_files/chr_plot.png',$directory.'/../test_files/chr_plot_c.png','chr plot matches control image');
	}
	unlink($chr_plot) if (-e $chr_plot);

	ok(-s $cgh_plot,'the cgh plot was created');
	SKIP: {
		skip "no cgh plot to test", 2 unless (-s $cgh_plot);
		size_ok($directory.'/../test_files/cgh_plot.png',[1051,375],'cgh plot size');
		cmp_image($directory.'/../test_files/cgh_plot.png',$directory.'/../test_files/cgh_plot_c.png','cgh plot matches control image');
	}
	unlink($cgh_plot) if (-e $cgh_plot);
};

end_skipping_tests;
