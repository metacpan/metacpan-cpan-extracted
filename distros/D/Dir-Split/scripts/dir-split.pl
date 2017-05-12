#!/usr/bin/perl

use strict;
use warnings;

use Dir::Split;

our ($dir, %Form, %Form_opt, $retval);
$retval = $ADJUST;

#
# Modify following lines accordingly to whether
# numeric or characteristic splitting shall be
# performed.
#

my %num_options = (
   mode    =>    'num',

   source  =>    '/source',
   target  =>    '/target',

   verbose     =>        1,
   override    =>        0,

   identifier  =>    'sub',
   file_limit  =>        2,
   file_sort   =>      '+',

   separator   =>      '-',
   continue    =>        1,
   length      =>        5,
);

my %char_options = (
   mode    =>    'char',

   source  =>    '/source',
   target  =>    '/target',

   verbose     =>          1,
   override    =>          0,

   identifier  =>      'sub',

   separator   =>        '-',
   case        =>    'upper',
   length      =>          1,

);

# options
#
#$Dir::Split::UNLINK                = 1;
#$Dir::Split::TRAVERSE              = 1;
#$Dir::Split::TRAVERSE_UNLINK       = 1;
#$Dir::Split::TRAVERSE_RMDIR        = 1;
#$Dir::Split::TRAVERSE_RMDIR_SOURCE = 1;

# numeric splitting
#
#$dir = Dir::Split->new(%num_options);

# characteristic splitting
#
#$dir = Dir::Split->new(%char_options);

# split files
#
#$retval = $dir->split_dir;

# End of config
###############

# no config
if ($retval == $ADJUST) {
    print __FILE__, " requires adjustment\n";
}
# action
elsif ($retval == $ACTION) {
    formwrite('track');
}
# no action
elsif ($retval == $NOACTION) {
    print "None moved.\n";
}
# existing files
elsif ($retval == $EXISTS) {
    local %Form_opt;

    $Form_opt{header} = 'EXISTS';
    $Form_opt{ul} = '-' x length $Form_opt{header};

    formwrite('start_debug');

    for my $file (@Dir::Split::exists) {
        print "file:\t$file\n";
    }

    formwrite('end_debug');
    formwrite('track');
}
# copy or unlink failure
elsif ($retval == $FAILURE) {
    local %Form_opt;

    if (@Dir::Split::exists) {
        $Form_opt{header} = 'EXISTS';
        $Form_opt{ul} = '-' x length $Form_opt{header};

        formwrite('start_debug');

        for my $file (@Dir::Split::exists) {
            print "file:\t$file\n";
        }

        formwrite('end_debug');
    }

    $Form_opt{header} = 'FAILURE';
    $Form_opt{ul} = '-' x length $Form_opt{header};

    formwrite('start_debug');

    for my $file (@{$Dir::Split::failure{copy}}) {
        print "copy failed:\t$file\n";
    }
    for my $file (@{$Dir::Split::failure{unlink}}) {
        print "unlink failed:\t$file\n";
    }

    formwrite('end_debug');
    formwrite('track');
}

sub formwrite
{
    my ($ident) = @_;

    no warnings 'redefine';
    eval $Form{$ident};
    die $@ if $@;
    write;
}

BEGIN {
    $Form{track} = 'format =
-------------------
source - files: @<<<
sprintf "%3d", $Dir::Split::track{source}{files}
target - files: @<<<
sprintf "%3d", $Dir::Split::track{target}{files}
target - dirs : @<<<
sprintf "%3d", $Dir::Split::track{target}{dirs}
-------------------
.';

    $Form{start_debug} = 'format =
---------------@<<<<<<<<<<
$Form_opt{ul}
START: DEBUG - @<<<<<<<<<<
$Form_opt{header}
---------------@<<<<<<<<<<
$Form_opt{ul}
.';

    $Form{end_debug} = 'format =
---------------@<<<<<<<<<<
$Form_opt{ul}
END  : DEBUG - @<<<<<<<<<<
$Form_opt{header}
---------------@<<<<<<<<<<
$Form_opt{ul}
.';
}
