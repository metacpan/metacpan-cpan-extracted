use warnings;
use strict;
use Test::More;
#use Test::Exception;
use blib;
use Image::SVG::Path qw/extract_path_info/;

#                            0    1      2      3    4    5     6 7      8    9     10
my $multiple_close_path = 'M 0,10 L 0,20 m 10,0 10,0 0,10 -10,0 z m 20,0 10,0 0,10 -10,0 z';
my @commands = extract_path_info ($multiple_close_path, { absolute => 1, }); 

is $commands[0]->{type}, 'moveto', 'Command 0 type';
is_deeply $commands[0]->{point}, [0,10], '... point' or
    diag explain $commands[0]->{point};

is $commands[1]->{type}, 'line-to', 'Command 1 type';
is_deeply $commands[1]->{point}, [0,20], '... point' or
    diag explain $commands[1]->{point};

is $commands[2]->{type}, 'moveto', 'Command 2 type';
is_deeply $commands[2]->{point}, [10,20], '... point' or
    diag explain $commands[2]->{point};

is $commands[3]->{type}, 'line-to', 'Command 3 type';
is_deeply $commands[3]->{point}, [20,20], '... point' or
    diag explain $commands[3]->{point};

is $commands[4]->{type}, 'line-to', 'Command 4 type';
is_deeply $commands[4]->{point}, [20,30], '... point' or
    diag explain $commands[4]->{point};

is $commands[5]->{type}, 'line-to', 'Command 5 type';
is_deeply $commands[5]->{point}, [10,30], '... point' or
    diag explain $commands[5]->{point};

is $commands[6]->{type}, 'closepath', 'Command 6 type';

is $commands[7]->{type}, 'moveto', 'Check next command after closepath';
is_deeply $commands[7]->{point}, [30,20], 'Check point to move to' or
    diag explain $commands[7]->{point};

# diag explain \@commands;

my $multiple_close_path2 = 'm 10,0 10,0 0,10 -10,0 z m 20,0 10,0 0,10 -10,0 z';
@commands = extract_path_info ($multiple_close_path2, { absolute => 1, }); 

is $commands[4]->{type}, 'closepath', 'Check type of command';
is $commands[5]->{type}, 'moveto', 'Check next command after closepath';
is_deeply $commands[5]->{point}, [30,0], 'Check point to move to' or
    diag explain $commands[5]->{point};

done_testing();
