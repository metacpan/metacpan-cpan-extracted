use Test::Simple 'no_plan';

ok 1, 'Testing for deps. You may want to run this interactively.';

deps_cli();


sub deps_cli {
   for my $bin ( qw(convert tesseract) ){      
      warn("# Testing for command dep: $bin ..");
      require File::Which;

      File::Which::which($bin) or warn("# Missing path to executable: $bin")
         and return 0;
      ok 1,"have path to executable $bin, good.. ";
   }
   1;
}

