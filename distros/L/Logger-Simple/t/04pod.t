eval "use Test::Pod tests => 1";

if($@){
  print"Test::Pod must be installed to test POD\n";
  exit;
}

pod_file_ok("Simple.pm","POD looks good");

