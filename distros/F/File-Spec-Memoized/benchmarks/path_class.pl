#!perl -w
use strict;
use Benchmark qw(:all);
use Config; printf "Perl/%vd (%s)\n", $^V, $Config{archname};

use File::Spec::Memoized;
BEGIN{
    package File::Spec::Original;
    our @ISA = @File::Spec::Memoized::ISA;
}

use Path::Class;

my $arg = $INC{'File/Spec.pm'};

print "Path::Class/$Path::Class::VERSION\n";

print "For new()\n";

cmpthese timethese -1 => {
    'Original' => sub{
        local $Path::Class::Foreign = 'File::Spec::Original';
        foreach (1 .. 100) {
            my $x = Path::Class::File->new($arg);
        }
    },
    'Memoized' => sub{
        local $Path::Class::Foreign = 'File::Spec::Memoized';
        foreach (1 .. 100) {
            my $x = Path::Class::File->new($arg);
        }
    },
};

print "For stringify()\n";
cmpthese timethese -1 => {
    'Original' => sub{
        local $Path::Class::Foreign = 'File::Spec::Original';
        my $x = Path::Class::File->new($arg);
        foreach (1 .. 100) {
            my $y = $x->stringify();
        }
    },
    'Memoized' => sub{
        local $Path::Class::Foreign = 'File::Spec::Memoized';
        my $x = Path::Class::File->new($arg);
        foreach (1 .. 100) {
            my $y = $x->stringify();
        }
    },
};

if(grep { $_ eq '--dump-cache' } @ARGV){
    require Data::Dumper;
    my $dd = Data::Dumper->new([File::Spec::Memoized->__cache], ['*cache']);
    $dd->Indent(1);
    $dd->Useqq(1);
    print $dd->Dump;
}
