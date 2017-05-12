use strict;
use warnings;

my $HZ = 60;
my $SIZE = 80;
my $MUTATION_CHANCE = 0.001;

###########3

my $CELL_SIZE = 9;

use Graphics::Raylib;
use PDL;
use PDL::Matrix;

sub rotations { ($_->rotate(-1), $_, $_->rotate(1)) }

AGAIN:
my @data;
foreach (0..$SIZE) {
    my @row;
    foreach (0..$SIZE) {
            push @row, !!int(rand(2));
    }
    push @data, \@row;
}
#my @data = map { tr/ o\n/01/; [split //] } <DATA>;
my $gen = mpdl \@data;

my $g = Graphics::Raylib->new([$CELL_SIZE*$SIZE,$CELL_SIZE*$SIZE]);

$g->fps($HZ);

while (!$g->exiting)
{
    my @rows = split /^/m, $gen;
    shift @rows;
    pop @rows;
    
    Graphics::Raylib::draw {
        Graphics::Raylib::clear();

        my $i = 0;
        for my $row (@rows) {
            my $j = 0;
            for my $col (split /[\[\] \n]/, $row) {
                next unless $col ne '';

                Graphics::Raylib::drawRect(
                     [$j, $i],
                     [$CELL_SIZE, $CELL_SIZE]
                 ) if $col eq '1';

                $j += $CELL_SIZE;
            }
            $i += $CELL_SIZE;
        }



    };


    # replace every cell with a count of neighbours
    my $neighbourhood = zeroes $gen->dims;
    $neighbourhood += $_ for map { rotations } map {$_->transpose}
                             map { rotations }      $gen->transpose;

    #  next gen are live cells with three neighbours or any with two
    my $next = $gen & ($neighbourhood == 4) | ($neighbourhood == 3);
    # mutation
    $next |= $neighbourhood == 2 if rand(1) < $MUTATION_CHANCE;

    # procreate
    $gen = $next;
}


__DATA__
                                     
         oo    o        o            
         oo    o       o o           
        oo     o      o   ooo        
        oo            o   ooo        
                      o   ooo   o    
                       o o      o    
               ooo      o       o    
                                     
                              o      
      ooo                     o      
                     o        o      
              o      o               
              o      o               
    ooo       o                      
                           ooo       
                                 o   
         o                      o o  
         o                       o   
         oo                          
                                     
     ooo                             
                   ooo               
                   o o               
                   ooo               
                   ooo               
                   ooo               
                   ooo               
                   o o               
                   ooo               
                                     
                                     
                                     
                                     
                                     
                                     

