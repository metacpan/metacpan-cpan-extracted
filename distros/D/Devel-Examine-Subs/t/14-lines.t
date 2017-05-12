#!perl
use warnings;
use strict;

use Test::More tests => 28;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my %p = (
        file => 't/sample.data',
        engine => 'lines',
);
{
    $p{search} = 'this';

    my $des = Devel::Examine::Subs->new(%p);

    my $ret = $des->lines(%p);
    my %subs = %$ret;

    my $search = $p{search};
    delete $p{search};

    for my $sub (keys %subs){    

        for my $line_info (@{$subs{$sub}}){
            while (my ($k, $v) = each (%$line_info)){
                ok ($v =~ /$search/, "lines() uses file_lines_contain postproc correctly");
            }
        }
    }
}
delete $p{search};

{
    my $des = Devel::Examine::Subs->new(%p);

    my $ret = $des->run();
    my %subs = %$ret;


    for my $sub (keys %subs){    

        for my $line_info (@{$subs{$sub}}){
            while (my ($k, $v) = each (%$line_info)){ 
                if ($k == 22){    
                    ok ($v =~ 'sub three', "lines has correct line nums" );
                }      
                if ($k == 40){    
                    ok ($v =~ 'sub five', "lines has correct line nums" );
                }
                if ($k == 8){    
                     ok ($v =~ 'sub one_inner', "lines has correct line nums" );
                 }
                if ($k == 25){    
                     ok ($v =~ '# five', "lines has correct line nums" );
                 }
                if ($k == 46){    
                     ok ($v =~ 'sub seven', "lines has correct line nums" );
                 }
                if ($k == 9){    
                     ok ($v =~ 'sub one_inner_two', "lines has correct line nums" );
                 }
                if ($k == 43){    
                     ok ($v =~ 'sub six', "lines has correct line nums" );
                 }
                if ($k == 17){    
                     ok ($v =~ 'sub two', "lines has correct line nums" );
                 }

            }
        }
    }
}
{

    delete $p{engine};
    my $des = Devel::Examine::Subs->new(%p);

    my $subs = $des->lines(%p);
    my %subs = %$subs;

    for my $sub (keys %$subs){    

        for my $line_info (@{$subs{$sub}}){
            while (my ($k, $v) = each (%$line_info)){ 
                if ($k == 22){    
                    ok ($v =~ 'sub three', "lines has correct line nums" );
                }      
                if ($k == 40){    
                    ok ($v =~ 'sub five', "lines has correct line nums" );
                }
                if ($k == 8){    
                     ok ($v =~ 'sub one_inner', "lines has correct line nums" );
                 }
                if ($k == 25){    
                     ok ($v =~ '# five', "lines has correct line nums" );
                 }
                if ($k == 46){    
                     ok ($v =~ 'sub seven', "lines has correct line nums" );
                 }
                if ($k == 9){    
                     ok ($v =~ 'sub one_inner_two', "lines has correct line nums" );
                 }
                if ($k == 43){    
                     ok ($v =~ 'sub six', "lines has correct line nums" );
                 }
                if ($k == 17){    
                     ok ($v =~ 'sub two', "lines has correct line nums" );
                 }

            }
        }
    }
}
