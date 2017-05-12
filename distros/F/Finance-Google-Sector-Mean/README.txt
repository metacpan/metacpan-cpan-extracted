Finance-Google-Sector-Mean version 0.08
======================================

The README is used to introduce the module and provide instructions on
how to install the module, any machine dependencies it may have (for
example C compilers and installed libraries) and any other information
that should be provided before the module is installed.

A README file is required for CPAN modules since CPAN extracts the
README file from a module distribution so that people browsing the
archive can use it get an idea of the modules uses. It is usually a
good idea to provide version information here so that people can
decide whether fixes for the module are worth downloading.

INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install



RUN

	use Data::Dumper;
	use Finance::Google::Sector::Mean;
	
	my @sector = sectorsummary();
	
	print Dumper [@sector];






This module requires these other modules and libraries:

	LWP::Simple
        Statistics::Basic
        HTML::TreeBuilder
        List::Util


MORE

	use Data::Dumper;
	use Finance::Optical::StrongBuy;
	use Finance::NASDAQ::Markets;
	use Finance::Google::Sector::Mean;




	my @sector = sectorsummary();
	my @idx = index();
	my @sec = sector();


	my $new = Finance::Optical::StrongBuy->new("/tmp");
	foreach my $symbol (qw/C BAC WFC WM F GE AAPL GOOG/){
	    $new->callCheck($symbol);
	}

	print Dumper [@idx,@sec,@sector ,$new];

	1;


