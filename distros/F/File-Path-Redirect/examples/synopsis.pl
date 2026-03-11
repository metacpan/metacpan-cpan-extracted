  use File::Path::Redirect;

  # Create  a test file to link to
  #
  my $source_path="path_to_file.txt";
  my $contents="Probably a large file";

  open my $fh, ">", $source_path or die $!;
  print $fh $contents;
  close $fh;
  
  

  # 'Link' or redirect a file to another
  #
  my $link_path="my_link.txt";


  make_redirect($source_path, $link_path);

  
  # Elsewhere in the application normal and redirect files are tested
  my $path=follow_redirect($link_path);

  # open/process $path as normal
  open my $f,"<", $path or die $!;
  while(<$f>){
    print $_;
  }
