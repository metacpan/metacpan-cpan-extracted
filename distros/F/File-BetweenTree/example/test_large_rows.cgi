#!/usr/bin/perl

	# File is generated only once the first.
	# Warning. Takes a long time to generate the file.

	BEGIN{
	  # Environmental sustainability when creating
	  my $pp = $ENV{SCRIPT_FILENAME}
	  || $ENV{DOCUMENT_ROOT}.$ENV{REQUEST_URI}
	  || (require Cwd,Cwd::getcwd().'/:)');
	  $pp =~ s/\/?[^\/\\]+?$//;
	  unshift @INC, $pp.'/lib', '/../lib';
	};

	use strict;
	use warnings;
	use Time::HiRes;
	$|=1;

	my $testfile = 'sorted_keep.txt';
	-e $testfile || do {
	  print "Creating files for testing(Only the first processing)\n";
	    open my $fh, '>', $testfile;
	      for my $i (1 .. 9999999) {
	        print "."  if ($i =~ /00000$/);
	          print "\n" if ($i =~ /000000$/);
	            print $fh "$i," . tx($i) ."\n";
	      }
	    close $fh;
	  print "\n\n";
	};

	use File::BetweenTree;
	my $bt = new File::BetweenTree($testfile);

	my $a = defined $ARGV[0] ? $ARGV[0] : int(rand(9999999));
	my $b = defined $ARGV[1] ? $ARGV[1] : int(rand(9999999));


	print "Searching between $a and $b; limit 10 ..\n\n";

	my $processing_time = Time::HiRes::time;
	my $result_array_ref = $bt->search(
	  $a,		# min_data
	  $b,		# max_data
	  $ARGV[2],	# mode: numeric_string=0, text_string=1
	  $ARGV[3],	# result_limit: default= 1000
	  $ARGV[4],	# result_start: default= 0
	  $ARGV[5],	# order_by: 'ASC' or 'DESC' | default='ASC'
	  $ARGV[6],	# row_sep: default= ','
	  $ARGV[7],	# row_num, default=  0
	);

	print "Find:\n-----------------------\n"
	     . join ("\n",@{$result_array_ref}) . "\n\n"
	     . $bt->mon ."\n"
	     ."file_size:" . int((-s $testfile)/1048576) ."MB"
	     ." processing_time: "
	     .(Time::HiRes::time - $processing_time) ." sec\n";

	print "\nSearch options that are available here in log_file"
		 ."\nARGV[0], # mininum data"
		 ."\nARGV[1], # maximum data"
		 ."\nARGV[2], # mode: numeric_string=0, text_string=1"
		 ."\nARGV[3], # result_limit: default= 1000"
		 ."\nARGV[4], # result_start: default= 0"
		 ."\nARGV[5], # order_by: 'ASC' or 'DESC' | default='ASC'"
		 ."\nARGV[6], # separator to divide the line"
		 ."\nARGV[7], # data of the second from the left"
		 ."\n"
		 ."\nYou can specify a number between ARGV[0] and ARGV[1]."
		 ."\nData is 1 .. 9999999"
		 ."\nIf you do not specify a random."
		 ."\n"
		 ."\nfor example -> 9999900 9999905 0 5 0 DESC"
		 ."\n         .. -> lemon lemoz 1 13 0 ASC , 1"
		 ."\n"
		 ."\nPlease reload the results out instantly."
		 ."\n";

	sub tx {
	my $dec = (shift) + 17575;
	my $str = '';
	my @ch  = ('a'..'z');
	while ($dec) {
		$str = $ch[$dec % 26] . $str;
		$dec = int($dec / 26);
	}
	return $str;
	}
