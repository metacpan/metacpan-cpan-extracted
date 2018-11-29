use v5.10.0;
use strict;
use warnings;
use Pod::Section qw(select_podsection);
use Test::More tests => 1;

my ($synopsis) = select_podsection('lib/Hailo.pm' , 'SYNOPSIS');
$synopsis =~ s/^.*?(?=\s+use)//s;
$synopsis =~ s!"megahal\.trn"!"t/lib/Hailo/Test/badger.trn"!s;
{
    my $trim = '$hailo->train($filehandle);';
    $synopsis =~ s!\Q$trim\E!!;
}
$synopsis =~ s/say //g;

local $@;
eval <<SYNOPSIS;
open my \$filehandle, '<', __FILE__;
$synopsis
SYNOPSIS

is($@, '', "No errors in SYNOPSIS");
