BEGIN {
#        use Test::More tests => 2005;
        use Test::More tests => 1;
        use_ok('FFmpeg');
#        use_ok('Devel::Leak');
      };

#my $fname = "eg/t1.m2v";
#
#my $count = Devel::Leak::NoteSV($handle);
#for(1..1000){
#  ok(my $ff = FFmpeg->new(input_file => $fname) , 'ff object created successfully');
#}
#my $now = Devel::Leak::NoteSV($handle);
#
#ok(1, "average bytes leaked per FFmpeg creation: ".(($now - $count)/1000));
#
##-----
#
#my $ff = FFmpeg->new(input_file => $fname);
#
#$count = Devel::Leak::NoteSV($handle);
#for(1..1000){
#  ok(my $sg = $ff->create_streamgroup           , 'streamgroup object created successfully');
#}
#$now = Devel::Leak::NoteSV($handle);
#
#ok(1, "average bytes leaked per FFmpeg::StreamGroup creation: ".(($now - $count)/1000));
