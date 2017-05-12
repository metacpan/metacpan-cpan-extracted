package Math::ES;

require 5.005_62;
use strict;
use warnings;
use FileHandle;

use Math::Random qw( random_permuted_index );

require Exporter;
# use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ();
our @EXPORT_OK   = ();
our @EXPORT      = ();
our $VERSION     = '0.08';      # Change version number in POD !

# --------------------------------------------------------------------

my $debug = 0;

#
# Selection schemes:
#  1 : n best survive
#  2 : n-1 best survive, last choses randomly
#  3 : GA Roulette (not implemented, yet)
#

# Package variable
my $count = 0;
my $file  = 'es';
my $debug_suffix = '.dbg';
my $log_suffix   = '.log';


# --------------------------------------------------------------------
#
# Constructor method
#
sub new {

    my $obj = shift;

    $count++;

    # Preset with default values
    my $eso = bless {
        'populations'  => 2,
        'individuals'  => 5,
        'parents'      => 2,
        'children'     => 10,
        'elite'        => 1,
        'selection_scheme' => 1,

        'generations'      => 50,
        'stepwidth_const'  => 1,
        'stepwidth_var'    => 1.5,
        'variance_mutator' => 0.5,

        'isolation'        => 25,               
        'migrators'        => 1,

        'genes'            => [],
        'gene_deviations'  => [],
        'max_gene_values'  => [],
        'min_gene_values'  => [],
        'rating_function'  => '',

        'log'   => 1,
        'debug' => 0,

        'log_handle'   => FileHandle->new(),
        'debug_handle' => FileHandle->new(),

        'log_file'   => "$file-$count$log_suffix",
        'debug_file' => "$file-$count$debug_suffix",
    }, $obj;

    # Overwrite with user specific values
    $eso->set_values(@_) if (@_);
    return $eso;
}

# --------------------------------------------------------------------
#
# Add user specific values
#
sub set_values {
    my $obj = shift;
    # Add or overwrite
    %{$obj} = ((%{$obj}) ,@_);
    return ($obj);
}


# --------------------------------------------------------------------
#
# Validate control parameters, array conformities etc.
#
sub validate {
    my $obj = shift;

    my $msg = '';

    $msg .= "<!> Number of populations must be greater than zero\n" if ($obj->{'populations'} < 1);
    $msg .= "<!> Number of individuals must be greater than zero\n" if ($obj->{'individuals'} < 1);
    $msg .= "<!> Number of parents must be greater than zero\n" if ($obj->{'parents'} < 1);
    $msg .= "<!> Number of children must be greater than zero\n" if ($obj->{'children'} < 1);
    $msg .= "<!> Number of children must be greater than or equal to number of individuals\n" 
        if ($obj->{'children'} < $obj->{'individuals'});
    $msg .= "<!> Number of elite must be less than number of individuals\n" 
        if ($obj->{'elite'} >= $obj->{'individuals'});
    $msg .= "<!> Selection scheme must be 1 or 2\n" if ($obj->{'selection_scheme'} != 1 and
                                             $obj->{'selection_scheme'} != 2);
    $msg .= "<!> Number of generations must be greater than zero\n" if ($obj->{'generations'} < 1);
    $msg .= "<!> variance_mutator must be positive\n" if ($obj->{'variance_mutator'} < 0);
    $msg .= "<!> Number of isolation cycles must not be negative\n" if ($obj->{'isolation'} < 0);
    $msg .= "<!> Number of migrators must not be negative\n" if ($obj->{'migrators'} < 0);
    
    my $ng  = @{$obj->{'genes'}};
    my $ngd = @{$obj->{'gene_deviations'}};
    my $gmx = @{$obj->{'max_gene_values'}};
    my $gmn = @{$obj->{'min_gene_values'}};

    $msg .= "<!> Number of gene_deviations ($ngd) must be equal to number of genes ($ng)\n" 
        unless ($ng == $ngd);
    $msg .= "<!> Number of max_gene_values ($gmx) must be equal to number of genes ($ng)\n" 
        unless ($ng == $gmx);
    $msg .= "<!> Number of min_gene_values ($gmn) must be equal to number of genes ($ng)\n" 
        unless ($ng == $gmn);
    
    for my $i (1..$ng) {
        my $g = $obj->{'genes'}[$i-1];
        my $max = $obj->{'max_gene_values'}[$i-1];
        my $min = $obj->{'min_gene_values'}[$i-1];
        $msg .= "<!> max_gene_value $i ($max) is smaller than gene $i ($g)\n" 
            if ($ng == $gmx and  $max < $g );
        $msg .= "<!> min_gene_value $i ($min) is greater than gene $i ($g)\n" 
            if ($ng == $gmn and  $min > $g );
    }

    if ($obj->{'populations'} == 1) {
        $msg .= "<!> Isolation feature cannot be used for a single population\n" 
            if ($obj->{'isolation'} > 0);
        $msg .= "<!> Migration feature cannot be used for a single population\n" 
            if ($obj->{'migrators'} > 0);       
    }

    $msg .= "<!> Rating function is missing\n" 
        unless (ref($obj->{'rating_function'}) =~ /CODE/);

    print "Validated\n" if ($debug);
    return ($msg);
}

# --------------------------------------------------------------------
#
# go Darwin go
#
sub start {

    my $obj = shift;
    
    my $debug = $obj->{'debug'};
    my $log   = $obj->{'log'};
    $| = 1;

    # Validate
    my $msg = $obj->validate();
    return ($msg) if ($msg);

    # Files
    my $dfh = $obj->{'debug_handle'};
    my $lfh = $obj->{'log_handle'};
    if ($debug) {
        open ($dfh, ">".$obj->{'debug_file'});
    }
    if ($log) {
        open ($lfh, ">".$obj->{'log_file'});
    }

    # Setup
    my $npop = $obj->{'populations'};
    my @populations = ();
    for (my $i=1; $i<=$npop; $i++) {
        print $dfh "Creating population number $i ...\n" if ($debug);
        my $pop = Math::ES::Population->new (
                                  'individuals'    => $obj->{'individuals'},
                                  'parents'      => $obj->{'parents'},
                                  'children'     => $obj->{'children'},
                                  'elite'        => $obj->{'elite'},
                                  'selection_scheme' => $obj->{'selection_scheme'},
                                  'migrators'    => $obj->{'migrators'},
                                  
                                  'stepwidth_const' => $obj->{'stepwidth_const'},
                                  'stepwidth_var'   => $obj->{'stepwidth_var'},
                                  'variance_mutator' => $obj->{'variance_mutator'},
                                  
                                  'genes'            => [@{$obj->{'genes'}}],
                                  'max_gene_values'  => [@{$obj->{'max_gene_values'}}],
                                  'min_gene_values'  => [@{$obj->{'min_gene_values'}}],
                                  'gene_deviations'      => [@{$obj->{'gene_deviations'}}],
                                  'max_gene_deviations'  => 
	     ( defined($obj->{'max_gene_deviations'}) ? [@{$obj->{'max_gene_deviations'}}] : [ ] ),
                                  'min_gene_deviations'  => 
	     ( defined($obj->{'min_gene_deviations'}) ? [@{$obj->{'min_gene_deviations'}}] : [ ] ),
                                  'rating_function'  => $obj->{'rating_function'},
                                  
                                  'debug' => $obj->{'debug'},                             
                                  'debug_handle' => $obj->{'debug_handle'},    
                                  );
        push (@populations, $pop);
        print $dfh "done\n" if ($debug);
    }

    $obj->{'populations_list'} = [@populations];

    $obj->run;
}

# --------------------------------------------------------------------
#
# go Darwin go
#
sub run {
    my $obj = shift;
    
    my $debug = $obj->{'debug'};
    my $log   = $obj->{'log'};
    my $dfh   = $obj->{'debug_handle'};
    my $lfh   = $obj->{'log_handle'};
#    $| = 1;

    # 0, Validate
    my $msg = $obj->validate();
    return ($msg) if ($msg);

    # 1, Setup
    my @populations = @{$obj->{'populations_list'}};
    my $nmig = $obj->{'migrators'};
    my $niso = $obj->{'isolation'};

    # 2, Evaluate first generation
    my @pop_rate_list;
    my @pop_rate_ranked;
    foreach my $pop (@populations) {
        # Evaluate function
        push (@pop_rate_list, $pop->rate_individuals());

        # Sort individuals
        push (@pop_rate_ranked, $pop->rank_individuals());
    }
    

    # --- Loop
    my $maxgn = $obj->{'generations'};
    for (my $gn = 1; $gn <= $maxgn; $gn++) {
        
        # This should go to log file
        if ($log) {
            print $lfh ">>","-"x80,"\n";
            print $lfh ">>Generation $gn\n";
        }

        # 3, Create children
        foreach my $pop (@populations) {
            $pop->manage_children();
            
            $pop->do_selection();


            if ($log) {
                my $ra_p= $pop->rank_individuals();
                print $lfh " Ranking list:\t";
                foreach my $p (@$ra_p) {
                    printf $lfh " %10.5f", $p;
                }
                print $lfh "\tBest genes: ",$pop->{'individuals_list'}[0]->pretty_genes;            
                print $lfh "\n";
            }

        }

        # 4, Do migration
        if ($nmig > 0 and scalar(@populations) > 1 ) {
            $obj->do_migration();
        }

        # Do mixing
        if ($niso > 0 and scalar(@populations) > 1 and ($gn % $niso) == 0) {
            $obj->do_mixing();
        }

        
    }

    return ($obj->return_best_value(), [$obj->return_best_genes()]);
}

# --------------------------------------------------------------------
#
# Do migration of n individuals
#
sub do_migration {
    my $obj = shift;

    my $debug = $obj->{'debug'};
    my $dfh = $obj->{'debug_handle'};
    my $nmig = $obj->{'migrators'};
    my @populations = @{$obj->{'populations_list'}};

    for my $i (1..$nmig) {
        
        my @migrators = ();
        
        # Fetch migrator
        foreach my $pop (@populations) {
            push (@migrators, $pop->withdraw_random_individual());
        }
        
        # Insert migrator (cyclic changed)
        my $p = shift (@populations); push (@populations, $p);
        foreach my $pop (@populations) {
            $pop->integrate_individual( shift(@migrators) );
        }
    }

    # Debug
    print $dfh "Migrated $nmig individual(s)\n" if ($debug); 

    return (1); 

}

# --------------------------------------------------------------------
#
# Do mixing of all populations after n generations of isolation
#
sub do_mixing {
    my $obj = shift;

    my @all_indy = ();
    my @idx = ();
    my @nindy = ();
    
    my $debug = $obj->{'debug'};
    my $dfh = $obj->{'debug_handle'};
    my $niso = $obj->{'isolation'};
    my @populations = @{$obj->{'populations_list'}};

    # Empty all populations
    foreach my $pop (@populations) {
        my $n1 = $pop->{'individuals'};
        print $dfh "\t$n1 individuals in current pop\n" if ($debug);
        push (@all_indy, $pop->withdraw_all_individual);
        push (@nindy, $n1);
    }

    print $dfh "\t",scalar(@all_indy)," individuals in total\n" if ($debug);
    
    # Now fill again ...
    my $n2 = scalar (@all_indy);
    @idx = &random_permuted_index($n2);
 
    print $dfh "<D> Indexvector : \n",join(":",@idx),"\n" if ($debug);

    # ... all populations ...
    foreach my $pop (@populations) {
        my $n1 = shift(@nindy);
        
        # ... with randomly choosen individuals.
        for my $i (1..$n1) {
            my $idx = shift(@idx);
            if (defined($idx) and defined($all_indy[$idx])) {
                $pop->integrate_individual( $all_indy[$idx] );
            }
            else {
                print $dfh "<!> Oops, we lost an individual: $i from $n1\n";
            }
        }
    }

    # Debug
    print $dfh "Mixing done\n" if ($debug); 

    return (1);

}

# --------------------------------------------------------------------
#
# Retrieve best genes from all populations
#
sub return_best_genes {
    my $obj = shift;

    my @populations = @{$obj->{'populations_list'}};
    
    my @best_indys = ();
    foreach my $pop (@populations) {

        # Be sure, that we have an ordered list.
        $pop->rank_individuals(); 
        
        push (@best_indys, $pop->{'individuals_list'}[0]);
    }

    @best_indys = sort { $a->rate() <=> $b->rate() } (@best_indys);

    return (@{$best_indys[0]{'genes'}});
}

# --------------------------------------------------------------------
#
# Retrieve best function value from all populations
#
sub return_best_value {
    my $obj = shift;

    my @populations = @{$obj->{'populations_list'}};
    
    my @best_indys = ();
    foreach my $pop (@populations) {

        # Be sure, that we have an ordered list.
        $pop->rank_individuals(); 
        
        push (@best_indys, $pop->{'individuals_list'}[0]);
    }

    @best_indys = sort { $a->rate() <=> $b->rate() } (@best_indys);

    return ($best_indys[0]->rate);
}

# --------------------------------------------------------------------
# --------------------------------------------------------------------

package Math::ES::Population;
use Math::Random qw( random_uniform_integer );

sub new {
    my $name = shift;
    my $obj = bless {@_}, $name;
    
    my $debug = $obj->{'debug'};
    my $dfh   = $obj->{'debug_handle'};

    my $nindiv = $obj->{'individuals'};
    $obj->{'pop_counter'} = 0;

    print $dfh "  Creating population with $nindiv members\n" if ($debug);
    
    my @individuals = ();
    for (my $j=1; $j <= $nindiv; $j++) {
        print $dfh "\tCreating individuum $j out of $nindiv ... " if ($debug);
        # Guarantee a individual with the input genes
        my $do_mutate = 1;
        $do_mutate = 0 if ($j == 1); 
        my $indi = Math::ES::Individuum->new (
                                    'pop_rate_individuals' => undef,
                                    'genes'            => [@{$obj->{'genes'}}],
                                    'gene_deviations'  => [@{$obj->{'gene_deviations'}}],
                                    'max_gene_values'  => [@{$obj->{'max_gene_values'}}],
                                    'min_gene_values'  => [@{$obj->{'min_gene_values'}}],
                                    'rating_function'  => $obj->{'rating_function'},

                                    'stepwidth_const' => $obj->{'stepwidth_const'},
                                    'stepwidth_var'   => $obj->{'stepwidth_var'},
                                    'variance_mutator' => $obj->{'variance_mutator'},
                                   
                                    'mutate'     => $do_mutate,

                                    'debug' => $obj->{'debug'},                           
                                   );
        push (@individuals, $indi);
        print $dfh " ok\n" if ($debug);
    }
    $obj->{'individuals_list'} = [@individuals];
    print $dfh "  done\n" if ($debug);

    # ---

    return $obj;
}

# -------------

# Create n children stemming from m parents, mutate them, rate them 
sub manage_children {
    my $obj = shift;
    
    my $debug = $obj->{'debug'};
    my $dfh   = $obj->{'debug_handle'};

    my $nchld = $obj->{'children'};
    my $nindy = $obj->{'individuals'};
    my $npar  = $obj->{'parents'};

    my @new_children = ();

    $obj->{'children_list'} = [];

    if ($debug) {
        print $dfh "<D> Managing children\n";

        print $dfh "<D> Parents\n";
        my $pp=0;
        foreach my $p (@{$obj->{'individuals_list'}}) {
            print $dfh "Parent $pp = ",$p->pretty_genes(),"\n";
            $pp++;
        }
    }

    # Create children
    for my $nc (1..$nchld) {
        my $child = Math::ES::Individuum->new();

        # Determine parents
        my @parents_idx = ();
        my @parents_list = ();
        for my $np (1..$npar) {
            my $num = random_uniform_integer(1, 0,$nindy-1);
            if (grep(/^$num$/, @parents_idx)) {
                redo;
            } 
            else {
                push (@parents_idx, $num) ;
                push (@parents_list, $obj->{'individuals_list'}[$num]);
            }
        }

        # Now do the origination (data copy and crossover)
        print $dfh "<D> Parents chosen for crossover ",join(' : ',@parents_idx),"\n" if($debug);
        $child->originate(@parents_list);

        # ... mutate it ...
        $child->mutate();

        # ... and rate it
        $child->rate();

        push (@{$obj->{'children_list'}}, $child);

        print $dfh "Child $nc = ",$child->pretty_genes()," >=> ",$child->rate(),"\n" if ($debug);
    }

    $obj->rank_children();
    
    return(@{$obj->{'children_list'}});
}

# -------------

sub rate_individuals {
    my $obj = shift;
    
    unless (exists($obj->{'pop_rate_individuals'}) or defined($obj->{'pop_rate_individuals'}) ) {
        $obj->{'pop_rate_individuals'} = 0;
        foreach my $indy (@{$obj->{'individuals_list'}}) {
            $obj->{'pop_rate_individuals'} += $indy->rate();
        }
    }

    return($obj->{'pop_rate_individuals'});
}

# -------------

sub rank_individuals {
    my $obj = shift;

    $obj->rate_individuals();

    my @temp = sort { $a->rate() <=> $b->rate() } (@{$obj->{'individuals_list'}});
    $obj->{'individuals_list'} = [@temp];

    my @temp2;
    foreach my $indy (@{$obj->{'individuals_list'}}) {
        push (@temp2, $indy->rate());
    }
    $obj->{'ranked_rates_individuals'} = [@temp2];
    return(\@temp2);
}

# -------------

sub rate_children {
    my $obj = shift;
    
    unless (exists($obj->{'pop_rate_children'}) or defined($obj->{'pop_rate_children'}) ) {
        $obj->{'pop_rate_children'} = 0;
        foreach my $indy (@{$obj->{'children_list'}}) {
            $obj->{'pop_rate_children'} += $indy->rate();
        }
    }

    return($obj->{'pop_rate_children'});
}

# -------------

sub rank_children {
    my $obj = shift;

    $obj->rate_children();

    my @temp = sort { $a->rate() <=> $b->rate() } (@{$obj->{'children_list'}});
    $obj->{'children_list'} = [@temp];

    my @temp2;
    foreach my $indy (@{$obj->{'children_list'}}) {
        push (@temp2, $indy->rate());
    }
    $obj->{'ranked_rates_children'} = [@temp2];
    return(\@temp2);
}

# -------------

sub do_selection {
    my $obj = shift;

    my @new_indies = ();

    my $nchld = $obj->{'children'};
    my $nindy = $obj->{'individuals'};
    my $elite = $obj->{'elite'};

    # Respect the elite
    if ($elite > 0 and $elite <= $nindy ) {
        my @temp = sort { $a->rate() <=> $b->rate() } (@{$obj->{'children_list'}}, @{$obj->{'individuals_list'}});
        
        for my $i (1..$elite) {
            push (@new_indies, $temp[$i-1]);
        }
    }

    # Deal with the rest
    my $nrest = $nindy - $elite;
    if ($nrest > 0) {

        # Selection according to scheme
        my $scheme = $obj->{'selection_scheme'};

        # 1 = Select n best
        if ($scheme == 1) {
            foreach my $i (1..$nrest) {
                push (@new_indies, $obj->{'children_list'}[$i-1]);          
            }
        }

        # 2 = Select n-1 best and one random other 
        elsif ($scheme == 2) {
            foreach my $i (1..$nrest-1) {
                push (@new_indies, $obj->{'children_list'}[$i-1]);          
            }
            my $lastone = random_uniform_integer(0, $nrest, $nchld);
            push (@new_indies, $obj->{'children_list'}[$lastone-1]);             
        }
        
    }

    # Move to next generation
    $obj->{'individuals_list'} = [@new_indies];
    $obj->{'pop_counter'}++;
    
}

# -------------
# Withdraw a number of individuals from the population
#  but spare the elite. 
#
sub withdraw_random_individual {
    my $obj = shift;

    my $num = (shift || 1);

    my ($nindy, $elite);
    $elite = $obj->{'elite'};

    my @withdrawn = ();
    for my $i (1..$num) {

        $nindy = $obj->{'individuals'};
        last if ($nindy-$elite <= 0);
        last if ($nindy == 0);

        my $num = random_uniform_integer(0, $elite+1, $nindy);

        $obj->{'individuals'}--;
        push (@withdrawn, splice(@{$obj->{'individuals_list'}},$num-1,1));
    }

    $obj->rank_individuals();

    return(@withdrawn);
}

# -------------
# Withdraw all individuals
#
sub withdraw_all_individual {
    my $obj = shift;


    my @withdrawn = @{$obj->{'individuals_list'}};
    $obj->{'individuals_list'} = [];
    $obj->{'individuals'} = 0;

    return(@withdrawn);
}

# -------------
# Add a number of new individuals to the population
#
sub integrate_individual {
    my $obj = shift;
    
    foreach my $indy (@_) {
        $obj->{'individuals'}++;
        push (@{$obj->{'individuals_list'}}, $indy);
    }

    $obj->rank_individuals();

    return($obj);
}


# --------------------------------------------------------------------
# --------------------------------------------------------------------
package Math::ES::Individuum;
use Math::Random qw(random_normal random_uniform);

# -----------
# Constructor of a new individuum
#
sub new {
    my $name = shift;
    my $obj = bless {@_}, $name;

    $obj->{'indy_rate'} = undef;

    if ($obj->{'mutate'}) {
        $obj->mutate;
    }

    return ($obj);
}

# -----------
# Return the rating function value of the individuum 
#
#
sub rate {
    my $obj = shift;
    

    # Call the rating function (if no value is present)
    #
    #  &function(@values) returns a result
    unless (defined $obj->{'indy_rate'}) {    
        $obj->{'indy_rate'} = &{$obj->{'rating_function'}}( @{$obj->{'genes'}} );
    }
    return ($obj->{'indy_rate'});       
}


# -----------
# Do mutation on individuum
#
#  $obj->mutate(); 
#
sub mutate {

    my $obj = shift;

    # Firstly mutate deviations
    my $i=-1;
    foreach my $gd (@{$obj->{'gene_deviations'}}) {
        my $rnn = random_normal(0,0, $obj->{'variance_mutator'});
        $i++;
        my $tmp = $gd * exp($rnn);
        if (defined($obj->{'max_gene_deviations'}[$i]) and 
             $tmp > $obj->{'max_gene_deviations'}[$i]) {
            $gd = $obj->{'max_gene_deviations'}[$i]; 
        }
        elsif (defined($obj->{'min_gene_deviations'}[$i]) and 
                $tmp < $obj->{'min_gene_deviations'}[$i]) {
            $gd = $obj->{'min_gene_deviations'}[$i];
        }
        else {
            $gd = $tmp;
        };
    }

    # Secondly mutate genes
    my $n = @{$obj->{'genes'}};
    for (my $i=0; $i<$n; $i++) {

      Try: {
          my $var = $obj->{'stepwidth_var'};
          my $factor = ( random_uniform() > 0.5 ? $var : 1/$var ) * $obj->{'stepwidth_const'};
          
          my $gd = $obj->{'gene_deviations'}[$i];
          my $rnn = random_normal(0,0,$gd);
          
          my $temp = $obj->{'genes'}[$i] + ($rnn * $factor);
          redo Try if ($temp > $obj->{'max_gene_values'}[$i]);
          redo Try if ($temp < $obj->{'min_gene_values'}[$i]);

          $obj->{'genes'}[$i] = $temp;
      }

    }
    
    return (1);
}

# -----------
# Simulate the originating process of a new individuum.
#
#  $child_obj->originate($parent1, $parent1, ...)
#
sub originate {
    my $obj = shift;
    my @parents = @_; # Allow more than 1 or 2 cross over parents

    my $np = @parents;

    # Copy all info from first parent
    $parents[0]->copy_to($obj);

    # ... but reset the value !!! 
    $obj->{'indy_rate'} = undef;

    my $n = @{$obj->{'genes'}};
        
    # We have more than one parent, do the crossover
    unless ($np == 1) {

        # Iterate over the genes
        for (my $i=0; $i<$n; $i++) {
            my $rnu = random_uniform();
#           print "Random Number: $rnu\n";

            # Find the appropriate parent
            Parent: for (my $p=0; $p<$np; $p++) {
                if ($rnu <= 1/$np*($p+1)) {
                    $obj->{'genes'}[$i] = $parents[$p]->{'genes'}[$i];              
                    $obj->{'gene_deviations'}[$i] = $parents[$p]->{'gene_deviations'}[$i];                  
                    last Parent;
                }
            }
        }
        
    }
    return ($obj);
}

# -----------
# Copy operator for an individuum
#  $from_obj->copy_to($to_obj);

sub copy_to {
    my $obj = shift;
    my $new = shift;
    
    foreach (keys (%{$obj})) { 
        my $temp = $obj->{$_};
        if (ref($temp) =~ 'ARRAY') {
            $new->{$_} = [@$temp];
        }
        elsif (ref($temp) =~ 'HASH') {
            $new->{$_} = {%$temp};          
        }
        else {
            $new->{$_} = $temp; # Scalars and programs go here              
        }
    };
    return ($new);      
}

# -----------
# Return the genes and variances in a 'pretty' style
#
sub pretty_genes {
    my $obj = shift;

    my $n = @{$obj->{'genes'}};
    my $output;

    # Iterate over the genes
    for (my $i=0; $i<$n; $i++) {
        $output .= sprintf("%10.6f", $obj->{'genes'}[$i]) 
            . ' (' . sprintf("%10.6f", $obj->{'gene_deviations'}[$i]) . ')';
    }
    return ($output);
}

1;

__END__


# -------------------------------------------------------------------

=pod

=head1 NAME

Math::ES - Evolution Strategy Optimizer

=head1 SYNOPSIS

  use Math::ES;

  # New ES object 
  my $es new Math::ES (
       'genes'  => [ -100,-50, 5, 200],
       'gene_deviations' => [ 1,1,1,1],
       'max_gene_values' => [ 500, 500, 500, 500],
       'min_gene_values' => [-500,-500,-500,-500],
       'rating_function' => \&function,
                       );

  my ($value1, $ra_genes1) = $es->start();   # Start the ES
  # ... doing some other things ...
  $es->run();                                # Run the ES again

  my @best_genes2 = $es->return_best_genes();
  my $best_value2 = $es->return_best_value();

  sub function {
      my $sum;
      foreach my $x (@_) {$sum += $x**2};
      return ($sum);
  }  

=head1 DESCRIPTION

The package B<Math::ES> provides an object orientated Evolution
Strategy (ES) for function minimization. It supports multiple
populations, elitism, migration, isolation, two selection schemes and
self-adapting step widths.


=head2 Historical background 

Evolution Programs were invented in the 1960s in Germany and USA
rather simultaneously, although their inventors intentions were
different: John Holland wanted to study nature's form of optimization
and tried to transfer the new insights from biological and biochemical
investigations; thus he invented the Genetic Algorithm (GA). On the
other side, the German engineer Ingo Rechenberg was interested in
practical problem solutions, and his Evolution Strategies had been
successfully applied for real world problems.

For a long time, the two algorthmic groups kept themselves separated
from each other. Nowadays, many conceptual ideas are mixed, so that
often there is just the naming of Evolution Programs. 

However, although most people dealing with optimization know GAs as
tools, but the ES is rather unknown. This is weird, because the GAs
traditionally use a bit string for the variable representation (and
have developped special codings to overcome some shortcommings of the
traditional binary system), whereas ES uses real numbers, what is most
often exactly what one wants.

=head2 General algorithm 

=over 4

=item Initialization

The ES object is initialized; all populations are created and filled
with individuals that are mutated copies from the input genes.

=item Loop start

The evolutionary process starts, i.e. the main generation loop begins.

=item Create children, Cross over, Mutation

The defined number of children is created; for each child the
requested number of parents is selected randomly.

Then for each of the child's genes it's decided randomly which of the
parent gives its gene value (together with the variance parameter).

After that, each gene's variance is varied under the influence of
the C<variance_mutator> parameter.

=begin latex

    Be the variance at generation $i$ $\sigma_i$ then the updated
    variance $\sigma_{i+1}$ is determined via

    \begin{equation}
     \sigma_{i+1} = \sigma_i * \exp({\cal N}(0,\Delta))
    \end{equation}

   with ${\cal N}(0, \Delta)$ being a random number from a 
   standard normal distribution with variance $\Delta$, the variance\_mutator parameter.

=end latex

Finally, the new gene value is created by adding a random number from
a standard distribution around 0 modified with the C<stepwidth_const>
and C<stepwidth_var> parameters.

=begin latex

    The gene $x_i$ in generation $i$ is mutated to $x_{i+1}$ according to

    \begin{equation}
     x_{i+1} = x_i + s {\cal N}(0,\sigma_{i+1})
    \end{equation}

   with $s$ being the stepwidth defined by

    \begin{equation}
     s = a \cdot b
    \end{equation}

    Thereby $a$ is a constant stepwidth parameter (normally $1$) 
    and $b$ is the variable stepwidth parameter that is either $b$ or $1/b$ 
    (decided randomly).

=end latex

=item Rate, rank and select children

The provided function is calulated for all children and they are
ordered according to the function value (increasing order). Then the
selection takes place, where either the n best or the n-1 best survive
(cf below).

If elitism is in use, the elite individuals are not subjected to
selection but simply saved to the next generation.

=item Migrate and mix populations

If migration is wanted, a defined number of migrators is interchanged
cyclically between the populations, i.e. in three populations migrator
from population1 wanders into population2, that from population2 jumps
into population3 and the from population3 fills the gap in population1.

Finally, if mixing is enabled, and the requested number of isolation
generations have passed all individuals from all populations are
collected and then randomly redistributed over all populations again.

=item Loop end

After the specified number of generations the optimization stops and
the results can be investigated. The ES may be run again with the same
control parameters to refine the parameters (cd SYNOPSIS).

=back 4

=head2 Constructor usage and options

The basic usage may be taken from the SYNOPSIS and is rather
self-explanatory. However, in the following the default parameters are
presented together with a more detailed description of their meaning.

Apart from the C<genes>, C<gene_deviations>, C<max_gene_values>,
C<min_gene_values> and C<rating_function>, which must be supplied by
the user, the following constructor lists all attributes with their
default values.

  my $es = new Math::ES (
        'debug' => 0,
        'log'   => 1,

        'log_file' => 'es-xx.log',               
        'dbg_file' => 'es-xx.dbg',               

        'individuals'          => 5,
        'parents'              => 2,
        'children'             => 10,
        'populations'          => 2,
        'selection_scheme'     => 1,
        'elite'                => 1,
        'generations'          => 50,
                               
        'stepwidth_const'      => 1,
        'stepwidth_var'        => 1.5,
        'variance_mutator'     => 0.5,
                               
        'migrators'            => 1,
        'isolation'            => 25,           
                               
        'genes'                => [],
        'max_gene_values'      => [],
        'min_gene_values'      => [],
        'gene_deviations'      => [],
        'max_gene_deviations'  => [],
        'min_gene_deviations'  => [],
        'rating_function'      => '',
                          );

=over 4

=item C<debug>

Debug flag for TONS of debug output; this goes to file 
I<es-1.dbg> for first ES object.

=item C<log>

If true the ES prints out the best genes and function values for each
population and generation. The file name is I<es-1.log> for first ES
object.

=item C<log_file>

The name of the log file. Unless overridden by user, this is
automatically set to C<es-xx.log>, with C<xx> being an internal
counter of how many ES objects have been created in total.

=item C<dbg_file>

The name of the debug file; follows the same idea as the log file.

=item C<individuals>

This determines the number of individuals in a population, i.e. the
starting number and the number of children to survive.

=item C<parents>

The number of individuals used to generate a child using cross
over. If C<parents=1> then no cross over is performed, the genes are
just copied from the parent; otherwise, for each gene and its
deviation the respective parent is determined randomly.

=item C<children>

The number of children in a population created in each generation. The
smaller the ratio of individuals to children, the higher is the
evolutionary pressure.

=item C<populations>

The number of (independent) populations to be created. 

=item C<selection_scheme>

The selction scheme to be applied. There are two schemes implemented at the moment:

=over 4

=item B<1>: The n best children survive (n beeing the number of individuals).

=item B<2>: The n-1 best children survive; the last child is choosen randomly.

=back 4

=item C<elite>

The number of best individuals to be kept apart from selection;
e.g. if C<elite=1> this means that the best individuum out of the
combination of parents and children is taken into the next generation.

=item C<generations>

The number of cycles the optimization will run. Note that at the moment, this
is the only ending criterion for an simulation.

=item C<stepwidth_const>

The s_c parameter for determination of the mutation step (see previous
section for details).

=item C<stepwidth_var>

The s_v parameter for determination of the mutation step (see previous
section for details).

=item C<variance_mutator>

The parameter for mutating the gene variances.

=item C<migrators>

The number of migrators (individuals) to be exchanged between isolated
populations in each generation (after mutation and selection).

=item C<isolation>

The number of generations the populations stay isolated (apart from
possible migrators). If greater than zero, after the respecive number
of generations all individuals are collected and randomly
redistributed over the populations.

=item C<rating_function>

This must be a reference to the rating function that takes the array
of the genes as argument and returns the function value as simple
scalar variable. The ES will try to B<minimize> this function.

=item C<genes>

Array of the parameters to be minimized.

=item C<gene_deviations>

Array of the variances of the parameters used for the mutation.

=item C<max_gene_values> and C<min_gene_values>

Arrays of parameter boundaries.

=item 'max_gene_deviations' and 'min_gene_deviations'

Arrays of the gene deviation boundaries. Unless set, the deviations
may increase to rather unintended heights.

=back 4


=head2 Other methods

The following object methods are available within the ES object:

=over 4

=item C<start()>

This method builds up the populations and then does the computation;
it initializes and runs the ES. It returns the best function value
found and a reference to an array with the best variables of the last
generation.

In case of erroneous input, it return the error message.

=item C<run()>

This method may be used for rerunning the ES (with the same parameters). 
Useful for refining (see subroutine B<test3> in B<test.pl>).
It returns the same as C<start()>.

In case of erroneous input, it return the error message.

=item C<return_best_genes()>

Returns an array of the best set of variables within the last generation.

=item C<return_best_value()>

Return the function value for the best set of variables of the last generation.

=item C<set_values()>

At the moment, no real accessor methods for the single options are available.
If one wants to change the options of an ES objects after its creation, one
must reset the value directly:

    $es->set_values( 'generations' => 100 );

However, you can only change the control variables in that way. A
change of the core parameters ( number of C<genes>, C<gene_deviations>,
C<max_gene_values>, C<min_gene_values> or C<individuals>;
C<rating_function>) requires a newly initialized ES object. 

=item C<validate()>

Do this before actual starting the ES. The method returns the error message(s) as
single string, or and empty string if all is ok.

If you use C<start()> or C<run()>, C<validate()> is called first internally and
if there is an error, the first two methods return the error string.


=back 4


=head1 PREREQUISITES

The current module depends on B<Math::Random> from CPAN; thus this has to be
in the module search path.


=head1 AUTHOR

Anselm H. C. Horn, Computer Chemie Centrum,
Friedrich-Alexander-Universitaet Erlangen-Nuernberg

Anselm.Horn@chemie.uni-erlangen.de

http://www.ccc.uni-erlangen.de/clark/horn

=head1 COPYRIGHT

For this software the 'Artistic License' applies. See file LICENSE in
the Math::ES distribution for details or visit
http://www.opensource.org/licenses/artistic-license.php .

Cite this work in any scientific publication as

 Anselm H. C. Horn, 'ES - Evolution Strategy Optimizer', Version x.xx
  Erlangen 2003; http://www.cpan.org/authors/id/A/AH/AHCHORN/Math/ES/

Please also consider sending me a short note, maybe with the
literature reference included.

=head1 VERSION

Main version number is 0.08. 

$Revision: 1.27 $

=head1 SEE ALSO

perl(1).

Further reading and references:

=over 4

=item [1] E. Schoeneburg, F. Heinmann, S. Feddersen
 
I<Genetische Algorithmen und Evolutionsstrategieen>,
Addison-Wesley, Bonn 1994.

=item [2] Z. Michalewicz

I<Genetic Algorithms + Data Structures = Evolution Programs>,
3rd ed., Springer, Heidelberg 1996. 


=back 4

=head1 NO WARRANTY

There is NO WARRANTY for this software!

See COPYRIGHT for details.

=cut






