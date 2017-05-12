#line 1
# $Id: CheckOS.pm,v 1.19 2007/11/07 21:36:54 drhyde Exp $

package Devel::CheckOS;

use strict;
use Exporter;

use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

$VERSION = '1.42';

# localising prevents the warningness leaking out of this module
local $^W = 1;    # use warnings is a 5.6-ism

@ISA = qw(Exporter);
@EXPORT_OK = qw(os_is os_isnt die_if_os_is die_if_os_isnt die_unsupported list_platforms);
%EXPORT_TAGS = (
    all      => \@EXPORT_OK,
    booleans => [qw(os_is os_isnt die_unsupported)],
    fatal    => [qw(die_if_os_is die_if_os_isnt)]
);

#line 64

sub os_is {
    my @targets = @_;
    foreach my $target (@targets) {
        die("Devel::CheckOS: $target isn't a legal OS name\n")
            unless($target =~ /^\w+(::\w+)*$/);
        eval "use Devel::AssertOS::$target";
        if(!$@) {
            no strict 'refs';
            return 1 if(&{"Devel::AssertOS::${target}::os_is"}());
        }
    }
    return 0;
}

#line 85

sub os_isnt {
    my @targets = @_;
    foreach my $target (@targets) {
        return 0 if(os_is($target));
    }
    return 1;
}

#line 103

sub die_if_os_isnt {
    os_is(@_) ? 1 : die_unsupported();
}

#line 113

sub die_if_os_is {
    os_isnt(@_) ? 1 : die_unsupported();
}

#line 127

sub die_unsupported { die("OS unsupported\n"); }

#line 143

my ($re_Devel, $re_AssertOS);

sub list_platforms {
    eval " # only load these if needed
        use File::Find::Rule;
        use File::Spec;
    ";
    
    die($@) if($@);
    if (!$re_Devel) {
        my $case_flag = File::Spec->case_tolerant ? '(?i)' : '';
        $re_Devel    = qr/$case_flag ^Devel$/x;
        $re_AssertOS = qr/$case_flag ^AssertOS$/x;
    }
    return sort { $a cmp $b } map {
        my (undef, $dir_part, $file_part) = File::Spec->splitpath($_);
        $file_part =~ s/\.pm$//;
        my (@dirs) = grep {+length} File::Spec->splitdir($dir_part);
        foreach my $i (reverse 1..$#dirs) {
            next unless $dirs[$i] =~ $re_AssertOS
                && $dirs[$i - 1] =~ $re_Devel;
            splice @dirs, 0, $i + 1;
            last;
        }
        join '::', @dirs, $file_part
    } File::Find::Rule->file()->name('*.pm')->in(
        grep { -d }
        map { File::Spec->catdir($_, qw(Devel AssertOS)) }
        @INC
    );
}

#line 254

$^O;
