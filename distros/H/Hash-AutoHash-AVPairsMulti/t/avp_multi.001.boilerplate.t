#!perl

use strict;
use warnings;
use File::Spec;
use Module::Build;
use Test::More tests => 4;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}



  not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
  );
  not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
  );

# NG 13-09-29: make this test generic
my $builder=Module::Build->current;
my $module_pm=File::Spec->catdir('blib',$builder->dist_version_from);
module_boilerplate_ok($module_pm);

# NG 13-09-29: Add test for correct version number an valid date in Changes
my $correct_version=$builder->dist_version;
open(CHANGES,"< Changes") or die "couldn't open Changes for reading: $!"; 
my $ok=0;
while (<CHANGES>) {
  if (/^$correct_version\s/) {
    my($year,$month,$day)=/(\d+)(?:-|$)/g;
    $ok=1 if $year&&$month&&$day;
    last;
  }
}
ok($ok,'Change has correct verion and valid date');

done_testing();

