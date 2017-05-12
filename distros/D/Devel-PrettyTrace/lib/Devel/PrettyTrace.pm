package Devel::PrettyTrace;

use 5.005;
use strict;

use parent qw(Exporter);
use Data::Printer;
use List::MoreUtils qw(all any);

our $VERSION = '0.04';
our @EXPORT = qw(bt);

our $Indent = '  ';
our $Evalen = 40;
our $Deeplimit = 0;
our $Skiplevels = 0;

our %IgnorePkg;
our %Opts = (
    colored		=> 1,
    class 		=> {
        internals       => 1,
        show_methods    => 'none',
        parents         => 0,
        linear_isa      => 0,
        expand          => 1,
    },
    max_depth	=> 2,
    indent		=> 2,
);

sub bt() {
    #local @DB::args;
    my $ret = '';
    my $i = $Skiplevels + 1;	#skip own call
    my $filter = get_ignore_filter();
    
    while (
        ($Deeplimit <= 0 || $i < $Deeplimit + 1)
            &&
        (my @info = get_caller_info($i + 1))	#+1 as we introduce another call frame
    ){
        $i++;
        next if $filter->($info[3]);
    
        $ret .= format_call(\@info);
    }
    
    if (defined wantarray){
        return $ret;
    }else{
        print STDERR $ret;
    }
}

sub get_ignore_filter{
    my @filters = map { qr/^\Q$_\E/ } keys %IgnorePkg;
    
    return sub {
        my $test_pkg = shift;
        
        return 1 if any { $test_pkg =~ $_ } @filters;
        return 0;
    }
}

sub format_call{
    my $info = shift;

    my $result = $Indent;
    
    if (defined $info->[6]){
        if ($info->[7]){
            $result .= "require $info->[6]";
            
        }else{
            $info->[6] =~ s/\n;$/;/;
            $result .= "eval '".trim_to_length($info->[6], $Evalen)."'";
        }
        
    }elsif ($info->[3] eq '(eval)'){
            $result .= 'eval {...}';
            
    }else{
        $result .= $info->[3];
    }
    
    if ($info->[4]){
        $result .= "(";
    
        if (scalar @DB::args){
            $result .= format_args();
        }
        
        $result .= ')';
    }
    
    $result .= " called at $info->[1] line $info->[2]\n";

    return $result;
}

sub format_args{
    my $result = p(@DB::args, %Opts);
    
    #result is always non-empty array, so transform [\n a\n b\n] => \n\t\t a \n\t\t b \n\t
    $result =~ s/^.*?\n/\n/;
    $result =~ s/\]$//;
    $result =~ s/\n/\n$Indent/go;
    
    return $result;
}

sub trim_to_length{
    my ($str, $len) = @_;
    
    if ($len > 2 && length($str) > $len){
        substr($str, $len - 3) = '...';
    }
    
    return $str;
}

sub get_caller_info{
    my $level = shift;

    do {
        package DB;
        @DB::args = ();
        return caller($level);
    };
}

1;
