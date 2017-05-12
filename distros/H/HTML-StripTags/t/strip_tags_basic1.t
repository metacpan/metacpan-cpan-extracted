# Test strip_tags() function : basic functionality - with default arguments

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use HTML::StripTags qw/strip_tags/;
use Test::More tests => 14;

#------------------------- Test Cases ------------------------------------------
my $tests = {
    1  => "<html>hello</html>",
    2  => '<html>hello</html>',
    3  => "<?php echo hello ?>",
    4  => '<?php echo hello ?>',
    5  => "<? echo hello ?>",
    6  => '<? echo hello ?>',
    7  => "<% echo hello %>",
    8  => '<% echo hello %>',
    9  => "<script language= \"PHP\"> echo hello </script>",
    10 => '<script language= \"PHP\"> echo hello </script>',
    11 => "<html><b>hello</b><p>world</p></html>",
    12 => '<html><b>hello</b><p>world</p></html>',
    13 => "<html><!-- COMMENT --></html>",
    14 => '<html><!-- COMMENT --></html>',
};

my $results = {
    1  => "hello",
    2  => "hello",
    3  => "",
    4  => "",
    5  => "",
    6  => "",
    7  => "",
    8  => "",
    9  => " echo hello ",
    10 => " echo hello ",
    11 => "helloworld",
    12 => "helloworld",
    13 => "",
    14 => "",
};

foreach my $test_number (sort {$a <=> $b} keys %$tests) {
    is (strip_tags($tests->{$test_number}), $results->{$test_number}, $tests->{$test_number});
}
