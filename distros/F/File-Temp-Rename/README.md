file-temp-rename-p5
===================

Create a temporary file object for output, and rename it when done.

    use File::Temp;

    {
      # create a file named output.txt.tmpXXXXXX, where the X's are random characters
      my $ftr = File::Temp::Rename->new(FILE => "output.txt", CLOBBER => 0)
                or die ("output.txt already existed, and not clobbering");
   
      $ftr->print('$ftr can be treated as a file handle, as it is a File::Temp subclass');
    } 
    # after $ftr is destroyed, output.txt.tmpXXXXXX is renamed output.txt

