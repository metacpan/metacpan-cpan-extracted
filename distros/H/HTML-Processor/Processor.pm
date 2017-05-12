package HTML::Processor;

use strict;
use vars qw($VERSION $syntax_pre $syntax_post @ISA);

require Exporter;

@ISA = qw(Exporter);

$VERSION = '0.2.1';

#----------------------------------------------
# Constructor for Template Object
#----------------------------------------------
sub new {
	# new Template
	my $proto 		= shift;
	my $config_ref 	= shift; # hash of config options
    
    # BEGIN CONFIG ////////////////////////////////
    # These are template defaults and can be changed
    # prior to installation or over-ridden when
    # setting up the object
    my %config = (
    	clean		=> 0,
        escape      => 0,
    	debug		=> 'Off',
    	footprint	=> 1,
    	syntax_pre	=> '\[TPL ',
    	syntax_post	=> '\]'
    );
    # END CONFIG //////////////////////////////////
    
   
    my $class = ref($proto) || $proto;
    my $self  = {
	        PATHS       => {},
            DEBUG_LEVELS=> {
                Fatal	=> 3,
            	Normal	=> 2,
            	Verbose	=> 1,
            	Off		=> 0
            },
	 		DEBUG_LEVEL	=> {},
			FOOTPRINT	=> {},
	 		CLEAN		=> {},
            ESCAPE		=> {},
			NESTS		=> {},
			LOOPS	    => {},
			VARIABLES	=> {},
			OPTIONS		=> {},
			INCLUDES	=> {},
			HEADER		=> undef
    };
	
	# set up configs with passed data or default
	$self->{ DEBUG_LEVEL } 	= $self->{DEBUG_LEVELS}{ $config_ref->{ debuglevel } } 	|| $self->{DEBUG_LEVELS}{$config{ debug }};
	$self->{ FOOTPRINT } 	= $config_ref->{ footprint } 					|| $config{ footprint };
	$self->{ CLEAN } 		= $config_ref->{ clean } 						|| $config{ clean };
    $self->{ ESCAPE } 		= $config_ref->{ escape } 						|| $config{ escape };
	$syntax_pre				= $config_ref->{ syntax_pre }					|| $config{ syntax_pre };
	$syntax_post			= $config_ref->{ syntax_post }					|| $config{ syntax_post };
	bless($self, $class);
	
	# debug the debug level!
	if($config_ref->{ debuglevel } && !exists $self->{DEBUG_LEVELS}{ $config_ref->{ debuglevel } }){ 
		$self->debug("param",3,"Invalid debug level: '<b>$config_ref->{ debuglevel }</b>' not one of (". join(", ", keys %{$self->{DEBUG_LEVELS}}) . ")",3); 
	}
    return $self;
}


#----------------------------------------------
# Constructor for Loop Object
#----------------------------------------------
sub new_loop {
    my $self = shift;
    my $name = shift;
	my $nest = shift;
	
	if($nest){
		push @{ $self->{ NESTS }->{$name}->{ KEYS } }, $nest;
		$name = "${name}~${nest}";
	}
	$self->{ LOOPS }->{$name} = HTML::Processor::Loop->new();
	return $self->{ LOOPS }->{$name};  # return a handle
}

#----------------------------------------------
# build variables
#----------------------------------------------
sub variable {
	my $self = shift;
	my $name = shift;
	my $val  = shift;

	$self->{ VARIABLES }{$name} = $val if( defined $val ); 
	return $self->{ VARIABLES }{$name};

}

#----------------------------------------------
# concatenate variable value with input
#----------------------------------------------
sub concat {
	my $self 	= shift;
	my $name 	= shift;
	my $val  	= shift;
	my $invert	= shift;
	
	if ( $invert ) {
		$self->{ VARIABLES }{$name} = $val . $self->{ VARIABLES }{$name};
	}
	else{
		$self->{ VARIABLES }{$name} .= $val; 
	}
    return $self->{ VARIABLES }{$name};
}

#----------------------------------------------
# perform basic maths on a variable
#----------------------------------------------
sub math {
    my $self 	= shift;
	my ( $var, $val, $opr, $invert ) = @_;
	my $result;
	my %operands = (
		'+' => \&addition,
		'-' => \&subtraction,
		'*' => \&multiplication,
		'/' => \&division,
	);
	# check if this is a valid variable
	if(!$self->{ VARIABLES }{$var}){
		$self->debug("process",3,"'$var' is an un-declared variable, can't do math");
	}
	# check if this is a valid operand
	elsif(!$operands{$opr}){
		$self->debug("process",3,"'$opr' is not a valid math operand from('+', '-', '*','/')");
	}
	else {
		# retrieve the values
		my $val_val = ( exists $self->{ VARIABLES }{ $val } ) ? $self->{ VARIABLES }{ $val } : $val;
		my $var_val = $self->{ VARIABLES }{ $var };

		my @pair = ($invert) ? ($val_val, $var_val) : ($var_val, $val_val);
		$result = &{ $operands{$opr} }( \@pair );
	}
	$self->variable($var, $result);
	return $result;
}

#----------------------------------------------
# build included files
#----------------------------------------------
sub include {
	my $self = shift;
	my $name = shift;
	my $file = shift;
	
	$self->{ INCLUDES }{ $name } = $file if ( $file ); 
	return $self->{ INCLUDES }{ $name };
}
#----------------------------------------------
# Add base paths
#----------------------------------------------
sub add_path {
    my $self = shift;
    my $path = shift;
    
    $self->{ PATHS }->{ $path }++;
}

#----------------------------------------------
# build options
#----------------------------------------------
sub option {
    my $self = shift;
	my $name = shift;
	my $val = shift;
	
	$self->{ OPTIONS }{ $name } = $val if ( $val ); 
    return $self->{ OPTIONS }{ $name };
}

#----------------------------------------------
# Print a value and exit
#----------------------------------------------
sub print_die {
	my $self = shift;
	my $data = shift;
	
	print "Content-type: text/html \n\n";
	print $data;
	exit;
}

#----------------------------------------------
# print content inline 4 debugging
#----------------------------------------------
sub print {
	my $self 		= shift;
	my $data 		= shift;
	my $line_end 	= shift;
	if(!$self->{ HEADER }){
		# print a header on first pass
		print "Content-type: text/html \n\n";
		$self->{ HEADER } = 1;
	}
	print $data . ($line_end || "<br>\n");
}

#----------------------------------------------
# Print a value and exit
#----------------------------------------------
sub error {
	my $self = shift;
	my $data = shift;
	my $app	 = shift;
	
	my( $file, $line, $pack, $sub ) = id(1);
	print "Content-type: text/html \n\n";
	my $out = qq|<h1>$app Software Error:</h1>
<pre>$data
at: $file line: $line
</pre>
|;
	print $out;
	exit;
}

#----------------------------------------------
# Set clean on||off
#----------------------------------------------
sub set_clean {
	my $self = shift;
	my $state = shift;
	
	$self->{ CLEAN } = $state || 0; 
}

#----------------------------------------------
# Set escape on||off
#----------------------------------------------
sub set_escape {
	my $self = shift;
	my $state = shift;

	$self->{ ESCAPE } = $state || 0; 
}
#----------------------------------------------
# Set footprint on||off
#----------------------------------------------
sub set_footprint {
	my $self = shift;
	my $state = shift;
	
	$self->{ FOOTPRINT } = $state || 0; 
}

#----------------------------------------------
# Set config options
#----------------------------------------------
sub set_config {
	my $self = shift;
	my $state = shift;

	# define cofig for various states
	my %states = (
		'email' => {
			FOOTPRINT 	=> 0,
			CLEAN 		=> 0
		},
		'default' => {
			FOOTPRINT 	=> 1,
			CLEAN 		=> 1
		}
	);
	# set config params according to passed state
	if( $states{$state} ){
		foreach my $func(keys %{ $states{$state} }){
			$self->{$func} = $states{$state}->{$func};
		}
	}
}

#----------------------------------------------
# Sort a loop by one of its keys
#----------------------------------------------
sub sort {
	my $self 		= shift;
	my $sortby		= shift;
    

	# return if there is not sort by values
	return unless $sortby;
	
	$self->{ SORTBY } = $sortby;
	my ( $dir, $loop, $sort_on );
	my @sorts = reverse split( /-/, $sortby );
	
	# test the sort key for: dir - sorton - loop
	if ( @sorts == 3 ) {
		$dir        = lc $sorts[0];
		$sort_on    = $sorts[1];
		$loop       = $sorts[2];
	}
	elsif (@sorts == 2 && (lc $sorts[0] eq "asc" || lc $sorts[0] eq "desc")){
		$dir        = lc $sorts[0];
		$sort_on    = $sorts[1];
	}
	elsif (@sorts == 2 && (lc $sorts[0] ne "asc" || lc $sorts[0] ne "desc")){
		$dir        = "asc";
		$sort_on    = $sorts[0];
		$loop       = $sorts[1];
	}
	elsif (@sorts == 1){
		$dir = "asc";
		$sort_on = $sorts[0];
	}
	
	# if we don't have an loop to sort on yet - go find one
	my @multiples;
	if ( !$loop ) {
		foreach my $loop_name ( keys %{ $self->{ LOOPS } }){
			# use the last loop that tests true
			if($self->{ LOOPS }->{ $loop_name }->{ $sort_on }){
				$loop = $loop_name;
				push @multiples, $loop_name;
			}
		}
		# die if we have more than 1 possible loop
		$self->debug("parse",
					 3,
					 "sort called without specifying loop & " .
					 "multiple possible loops [" . 
					 join(", ", @multiples) .
					 "] found for sort key: $sort_on"
					 ) if @multiples > 1;
	}
	
	if($self->{ LOOPS }->{ $loop }{$sort_on}){
		my @sortkeys = @{ $self->{ LOOPS }->{ $loop }{$sort_on} };
		# check if data is string or int
		my $data_type = ($sortkeys[0] =~ /(\D)/ && $1 !~ /\.|\,/) ? "STRING" : "INT";
        if ( $data_type eq "INT" ) {
            # strip commas
            $sortkeys[$_] =~ s/,//g for 0..$#sortkeys;
        }
		my %sortcode = (
			"STRING-asc" 	=> sub { return sort { uc $sortkeys[$a] cmp uc $sortkeys[$b] } 0..$#sortkeys },
			"STRING-desc"	=> sub { return sort { uc $sortkeys[$b] cmp uc $sortkeys[$a] } 0..$#sortkeys },
			"INT-asc"		=> sub { return sort {    $sortkeys[$a]   <=>  $sortkeys[$b] } 0..$#sortkeys },
			"INT-desc"		=> sub { return sort {    $sortkeys[$b]   <=>  $sortkeys[$a] } 0..$#sortkeys }
		);
		my @sorted =  &{ $sortcode{"${data_type}-${dir}"} };
		$self->{ LOOPS }->{ $loop }{$_} = [ @{$self->{ LOOPS }->{ $loop }{$_}}[@sorted] ] for keys %{ $self->{ LOOPS }->{ $loop } };
	    $self->{ SKEYS } = [@sorted];
        
        # sort the bg colours if there are any
        #--------------------------------------------------------
        if ( $self->{ LOOPS }->{ $loop }{ 'bgcolor' } ) {
            
            # get the unique colours
            my %colours;
            foreach my $colour ( @{ $self->{ LOOPS }->{ $loop }{ 'bgcolor' } } ){
                $colours{ $colour }++;
                last if ( scalar keys %colours >= 2 );
            }
            # if we have 2 to work with
            if ( keys %colours == 2 ) {
                # create the colour toggle
                my $toggle = $self->create_toggle( keys %colours );
                my $colour;
                # reset each of the bgcolour elements
                for ( my $i = 0; $i < scalar @{ $self->{ LOOPS }->{ $loop }{ 'bgcolor' } }; $i++ ){
                    $colour = $toggle->( $colour );
                    $self->{ LOOPS }->{ $loop }{ 'bgcolor' }->[$i] = $colour;
                }                
            }
        }

    }
	else {
		$self->debug("parse",2,"sortby called with non-existent sort key: $loop => $sortby");
	}
}

#--------------------------------------------
# toggle a colour
#--------------------------------------------
sub create_toggle {
    my $self = shift;
    my ( $primary, $secondary ) = @_;

    my $current = $secondary;
    return sub {
        my $cur_ref = \$current;
        $$cur_ref = ($$cur_ref eq $primary) ? $secondary : $primary;
        return $$cur_ref;
    }
}

#--------------------------------------------------
# generic subroutine for creating HTML dropdowns
#--------------------------------------------------
sub create_dropdown {

	my $self = shift;
	my ( $itr_name, $ref_array_id, $ref_array_name, $selected_id, $selected_name ) = @_;
	# create loop
	my $itr = $self->new_loop($itr_name);
	my $count = 0;
	# populate loop
	foreach my $id ( @$ref_array_id ) {
		my $name = ( $ref_array_name ) ? $$ref_array_name[$count++] : '';
		my $type_selected = '';
		
		$itr->array("id", $id);
		$itr->array("name", $name || $id);
		# is this the selected item?
		if ( $selected_id ) {
			$type_selected = ( $selected_id eq $id ) ? " SELECTED" : "";
		}
		else {
			$type_selected = ( $selected_name eq $name ) ? " SELECTED" : "";
		}
		$itr->array("selected", $type_selected);
	}
}

#----------------------------------------------
# Parse and Return the template
#----------------------------------------------
sub process {
	my $self 			= shift;
	my $template_path 	= shift;
	my $debug_object	= shift;

	# prepend template path and name to output if footprint is set
	my $template = ($self->{ FOOTPRINT }) ? "<!--- TEMPLATE: $template_path --->\n" : "";

	# check for a template file on line 1 of template path
	if ( (split /\n/, $template_path)[0] =~ /\.\w{3,4}$/ ) {
		# we're processing a file
        
        # if the file is not found: check if its relative to a stored path
        unless ( -e $template_path ) {
            foreach my $stored_path ( keys %{ $self->{ PATHS } } ) {
                # check if the template exists at the stored PATH location
                if ( -e ($stored_path . $template_path) ) {
                    $template_path = $stored_path . $template_path;
                    last;
                }
            }
        }
        
		local $/ = undef; # undef record separator for reading file into scalar
		open (READFILE, $template_path) or $self->debug("file",3,"Can't open content file : $template_path $!");
		$template .= <READFILE>;
		close READFILE;
		
	} 
    else {
        # we're processing a data block
		$template = $template_path;
		# set base path to Cwd for includes from data
		use Cwd;	
        $template_path = cwd;
	}
	
    $self->{ TEMPLATE } = $template_path;
    
	# process the html template
	$self->do_includes		(\$template,\$template_path);
	$self->do_options		(\$template);
	$self->do_ifelse		(\$template);
	$self->do_variables		(\$template);
	$self->do_loops     	(\$template);
	$self->do_sort_dir		(\$template) if $self->{ SORTBY };
	$self->do_clean			(\$template) if $self->{ CLEAN };
	
	# if we are dumping object data
	if( $debug_object ){ 
		use Data::Dumper;
		# take a copy of the object
        my $debugObj = $self;
        # clean up the object before debug display
        delete $debugObj->{ IT_STACK };
        delete $debugObj->{ DEBUG_LEVELS };
		$template .= "<div style=\"position:relative; top:50;\"><pre>" . Dumper( $debugObj ) . "</pre></div>";
	}
	# add debug data
	$template .= $self->build_err if($self->{ DEBUG_LEVEL } > 0);
	
	return $template;
}



#=========================================================
# PRIVATE METHODS
#=========================================================

#=====================================
# math private methods
#=====================================
sub addition {
	my $pair = shift;
	my ($this, $that) = @$pair;
	return $this + $that;
}

sub subtraction {
	my $pair = shift;
	my ($this, $that) = @$pair;
	return $this - $that;
}

sub multiplication {
	my $pair = shift;
	my ($this, $that) = @$pair;
	return $this * $that;
}

sub division {
	my $pair = shift;
	my ($this, $that) = @$pair;
	return $this / $that;
}

#=====================================

#=====================================
# change the sort direction
#=====================================
sub do_sort_dir {
	my $self 				= shift;
	my $template_ref 		= shift;
	
	return if $self->{ SORTBY } =~ /ASC|DESC/;
	my $out;
	my $skey = $self->{ SORTBY };
	$skey =~ /(asc|desc)/;
	my $dir = $1;
	my $dirout = ($dir eq "desc") ? "asc" : "desc";
	if ( $dir ) {
		$out = $skey;
		$out =~ s/$dir/$dirout/;
	}
	else {
		$out = $skey . "-$dirout";
	}
	$$template_ref =~ s/sort=$skey/sort=$out/o;

}

#=====================================
# include files into template
#=====================================
sub do_includes {
    my $self              = shift;
    my $template_ref      = shift;
    my $template_path_ref = shift;

    # use template path as root for includes
    if ( $$template_path_ref =~ m/\// ) {
        # if there is a path
        $$template_path_ref =~ s/(.*)(\/)(.*?)$/$1$2/;
    }
    else {
        # file name only
        $$template_path_ref = "";
    }
    # start paths library
    $self->{ PATHS }->{ $$template_path_ref } = 1;
    
    while ( $$template_ref =~ m/\A(.*)${syntax_pre}include='(.*?)'${syntax_post}(.*)\Z/msi ) {
        my $inc_pre  = $1;    # pre included file
        my $file     = $2;    # $variables name for file
        my $inc_post = $3;    # post include data
        my $filepath = '';
        
        if ( $file =~ /\./ ) {
            $filepath = $$template_path_ref . $file;
            my $filename;
            my $local_path = "";
            # has a path
            if ($file =~ /\// ) {
                $local_path = $file;
                $local_path =~ s/(.*)(\/)(.*?)(\.\w{3,4}$)/$1$2/;
                $filename = $3.$4;
            }
            else {
                $filename = $file;
            }
            # store path
            $self->{ PATHS }->{$$template_path_ref . $local_path}++;
            
            # if the file is relative to an included file
            unless ( -e $filepath ) {
                foreach ( keys %{ $self->{PATHS} } ) {
                    if ( -e $_ . $filename ) {
                        $filepath = $_ . $filename;
                    }
                }
            }
        }
        else {
            $filepath = $self->include($file);
        }

        my $footpre = ( $self->{FOOTPRINT} ) ? "<!-- TEMPLATE BEGIN INCLUDE $filepath -->\n\n" : "";
        my $footpost = ( $self->{FOOTPRINT} ) ? "\n\n<!-- TEMPLATE END INCLUDE: $filepath -->\n\n" : "";
        
        # test for existence of file
        if ( -e $filepath ) {
            local $/ = undef;
            open( INCLUDE, "< $filepath" );
            my $inc_data = <INCLUDE>;
            close(INCLUDE);
            $$template_ref = "$inc_pre$footpre$inc_data$footpost$inc_post";
        }
        # no file to include
        else {
            $$template_ref = $inc_pre . "<!-- TEMPLATE ERR: no inc file - $filepath -->" . $inc_post;
            $self->debug( "parse", 3, "File to <b>include</b> does not exist:'<b>$filepath</b>'" );
        }
    }
}
#=====================================
# evaluate optional content
#=====================================
sub do_options {
	my $self 		= shift;
	my $template_ref 	= shift;
	
	while ($$template_ref =~ m/\A(.*)${syntax_pre}OPTION name([ !=]+)'([\w\d-]*)'${syntax_post}(.*?)${syntax_pre}OPTION END${syntax_post}(.*)\Z/msi){
		my $opt_pre  = $1;
		my $opt_type = $2;
		my $opt_name = $3;
		my $opt_data = $4;
		my $opt_post = $5;
		# clean the option comarisons
		$opt_type =~ s/ //g;
		$opt_type =~ s/==/=/;
		
		my $test_val = $self->option($opt_name) || $self->variable($opt_name);
		
		if($opt_type eq "=" && $test_val){
			$$template_ref = $opt_pre.$opt_data.$opt_post;
		}
		elsif($opt_type eq "!=" && !$test_val){
			$$template_ref = $opt_pre.$opt_data.$opt_post;
		}
		# option fails
		else {
			# loose the optional content
			$$template_ref = $opt_pre.$opt_post;
		}
	}
}

#=====================================
# Evaluate If/Else clauses
#=====================================
sub do_ifelse {
    my $self         = shift;
    my $template_ref = shift;

    while ( $$template_ref =~ m/\A(.*)${syntax_pre}IF (\w+)([ =!<>]+)'([\w-]*)'${syntax_post}(.*?)(${syntax_pre}ENDIF${syntax_post})(.*)\Z/msi ) {
        my $if_pre    = $1;    # pre if data
        my $fs_var    = $2;    # first if variable
        my $fs_oper   = $3;    # first if operand
        my $fs_val    = $4;    # first value to test
        my $if_cont   = $5;    # block to do work on
        my $if_end    = $6;    # [ENDIF] end of string
        my $if_post   = $7;    # rest of template
        my $if_output = '';

        # test if the first is true
        if ( $self->compare( $fs_oper, $self->variable($fs_var), $fs_val ) ) {
            $if_cont =~ s/(.*?)${syntax_pre}(ELSIF|ELSE).*\Z/$1/msi if $if_cont =~ /${syntax_pre}(ELSIF|ELSE)/msi;
            $if_output = $if_cont;
        }
        # loop through remaining tests
        else {
            my $if_data = $if_cont . $if_end;

            # evaluate each ELSIF|ELSE
            while ( $if_data =~ m/${syntax_pre}(ELSIF|ELSE)(| (\w+)([ =!<>]+)'([\w-]*)')${syntax_post}(.*?)(${syntax_pre}(ELSIF|ELSE|ENDIF).*)\Z/msi ) {
                my $if_type    = $1;    # clause type (IF|ELSIF|ELSE)
                my $if_var     = $3;    # value to test
                my $oper       = $4;    # if operator
                my $if_val     = $5;    # value to test
                my $if_content = $6;    # output for the block
                my $if_tail    = $7;    # following IF/ELSE clauses

                # evaluate clauses
                if ( $if_type =~ /ELSIF|IF/ && $self->compare( $oper, $self->variable($if_var), $if_val ) ) {
                    $if_output = $if_content;
                    last;    # exit if there's a match
                }
                # use the else if above fails
                elsif ( $if_type =~ /ELSE/ ) {
                    $if_output = $if_content;
                }
                # truncate the string for each loop by what we just tested
                $if_data = $if_tail;
            }
        }
        $$template_ref = $if_pre . $if_output . $if_post;
    }
}


#=====================================
# replace loops
#=====================================
#my (%it_stack);
sub do_loops {
	my $self 			= shift;
	my $template_ref 	= shift;
    
    $self->{ IT_STACK } = {};
    
    while ( $$template_ref =~ m/\A(.*)${syntax_pre}LOOP name='([\w\d-]+)'${syntax_post}(.*?)${syntax_pre}LOOP END${syntax_post}(.*)\Z/msi) {
		my $it_pre 		= $1; 	# data before the loop block
		my $it_name		= $2;	# name of loop
		my $data 		= $3; 	# loop data to process
		my $it_post 	= $4; 	# data after the loop block
		
		# insert place holders
		$$template_ref = $it_pre."[LOOP:'$it_name']".$it_post;
		$self->debug("parse",1,"<b>loop</b>: <b>$it_name</b> not found in object") unless ( $self->{ LOOPS }{ $it_name } || $self->{ NESTS }{ $it_name });
		# push loop block to named hash of arrays,
		# allows for multiple loops of the same name
		push @{ $self->{ IT_STACK }->{$it_name} }, $data;
    }
    

	my (%multi);
	# add looped content to template
	while ($$template_ref =~ m/\A(.*)\[LOOP:'([\w\d-]+)'\](.*)\Z/msi){
		my $pre 	= $1;
		my $iter 	= $2;
		my $post 	= $3;

		# log duplicate loops
		$multi{$iter}++;
		# go iterate over loop
		$$template_ref = $pre.$self->iterate_loop( $iter, $self->{ IT_STACK }->{$iter}[$multi{$iter}-1] ).$post;
	}
}

#=====================================
# loop processing 
#=====================================
#my (%parents);
sub iterate_loop {
	my $self 	= shift;
	my $it_name = shift;
	my $dat_ref	= shift;
	my $p_count = shift;
	my ($iterated);
	my $input_name = $it_name;

	# initialise position counter
	# start at -1 so ++ on first pass gives 0
	#if(!exists $parents{$input_name}){ $parents{$input_name} = -1 };
	$self->{ PARENTS }{$input_name} = $self->{ PARENTS }{$input_name} || -1;

	# if we are processing a nest - indicated by passed value for
	# 'p_count' (parent counter)
	if($p_count ne ''){
		# use sort keys for position if we have a sorted parent
        my $position = ( $self->{ SKEYS } ) ? $self->{ SKEYS }[$p_count] : $p_count;
		my $it_key = $self->{ NESTS }->{$it_name}->{ KEYS }[$position];
		$it_name = "${it_name}~${it_key}";
	}

	my $max_count = 0;
	# get the longest array for this loop
	foreach (keys %{ $self->{ LOOPS }->{$it_name} }){
		if(ref $self->{ LOOPS }->{$it_name}->{$_} eq "ARRAY"){
			my $a_length = @{$self->{ LOOPS }->{$it_name}->{$_}};
			$max_count = $a_length if ( $a_length > $max_count );
		}
	}

	# loop for the length of the longest array
	for (my $count = 0; $count < $max_count; $count++) {
	    my $loop = $dat_ref; # deref & scope loop data
	    while ($loop =~ m/\A(.*)${syntax_pre}array='([\w\d-]*)'${syntax_post}(.*)\Z/msi) {
			my $ins_pre = $1;
			my $ins_name = $2;
			my $ins_post = $3;
			
			my $it_val = $self->{ LOOPS }->{$it_name}->{$ins_name}[$count];
			$it_val = $self->escape_html($it_val) if $self->{ ESCAPE };# ***
			# build the output for this instance
			$loop = $ins_pre.$it_val.$ins_post;
	    }
		# increment the count for this pass
		$self->{ PARENTS }{$input_name}++;
		
		# Loop Option processing
		#---------------------------------------------------
		while ($loop =~ m/\A(.*)${syntax_pre}LOOP OPTION name(!=|=)'([\w\d-]*)'${syntax_post}(.*?)${syntax_pre}LOOP OPTION END${syntax_post}(.*)\Z/msi){
			my $opt_pre = $1;
			my $opt_type = $2;
			my $opt_name = $3;
			my $opt_data = $4;
			my $opt_post = $5;
			my $opt_itr_val;
			
			# check if there is an explicit options setting
			if(exists $self->{ LOOPS }->{$it_name}->{ OPTIONS }->{$opt_name}){
				$opt_itr_val = $self->{ LOOPS }->{$it_name}->{ OPTIONS }->{$opt_name}[$count];
			}
			# otherwise look for the 'array' in the current loop
			elsif(exists $self->{ LOOPS }->{$it_name}->{$opt_name}){
				$opt_itr_val = $self->{ LOOPS }->{$it_name}->{$opt_name}[$count];
			}
			else {
				$self->debug("process",2,"The loop option: '$opt_name' cannot be found");
			}
			
			# if the option variable is true
			if ($opt_itr_val && $opt_type eq "="){
				$loop = $opt_pre.$opt_data.$opt_post;
			}
			# if the option variable is not true
			elsif (!$opt_itr_val && $opt_type eq "!="){
				$loop = $opt_pre.$opt_data.$opt_post;
			}
			else {
				# loose the optional content
				$loop = $opt_pre.$opt_post;
			}
		}
		 # Loop if/else processing
        #---------------------------------------------------------
        while ( $loop =~ m/\A(.*)${syntax_pre}LOOP IF (\w+)([ =!<>]+)'([\w-]*)'${syntax_post}(.*?)(${syntax_pre}LOOP ENDIF${syntax_post})(.*)\Z/msi ) {
            my $if_pre    = $1;    # pre if data
            my $fs_var    = $2;    # first if variable
            my $fs_oper   = $3;    # first if operand
            my $fs_val    = $4;    # first value to test
            my $if_cont   = $5;    # block to do work on
            my $if_end    = $6;    # [ENDIF] end of string
            my $if_post   = $7;    # rest of template
            my $if_output = '';

            # test if the first is true
            if ( $self->compare( $fs_oper, $self->{LOOPS}->{$it_name}->{$fs_var}[$count], $fs_val ) ) {
                $if_cont =~ s/(.*?)${syntax_pre}LOOP (ELSIF|ELSE).*\Z/$1/msi if $if_cont =~ /${syntax_pre}LOOP (ELSIF|ELSE)/msi;
                $if_output = $if_cont;
            }
            # loop through remaining tests
            else {
                my $if_data = $if_cont . $if_end;

                # evaluate each ELSIF|ELSE
                while ( $if_data =~ m/${syntax_pre}LOOP (ELSIF|ELSE)(| (\w+)([ =!<>]+)'([\w-]*)')${syntax_post}(.*?)(${syntax_pre}LOOP (ELSIF|ELSE|ENDIF).*)\Z/msi ) {
                    my $if_type    = $1;    # clause type (IF|ELSIF|ELSE)
                    my $if_var     = $3;    # value to test
                    my $oper       = $4;    # if operator
                    my $if_val     = $5;    # value to test
                    my $if_content = $6;    # output for the block
                    my $if_tail    = $7;    # following IF/ELSE clauses

                    # evaluate clauses
                    if ( $if_type =~ /ELSIF|IF/ && $self->compare( $oper, $self->{LOOPS}->{$it_name}->{$if_var}[$count], $if_val ) ) {
                        $if_output = $if_content;
                        last; # exit if there's a match
                    }
                    # use the else if above fails
                    elsif ( $if_type =~ /ELSE/ ) {
                        $if_output = $if_content;
                    }
                    # truncate the sring each loop by what we just tested
                    $if_data = $if_tail;
                }
            }
            $loop = $if_pre . $if_output . $if_post;
        }
		
		# Nested Loop processing (recursive)
		#---------------------------------------------------------
		my %nest_multi;
		while ($loop =~ /\A(.*)\[LOOP:'([\w\d-]+)'\](.*)\Z/msi){
			my $curr_pre 	= $1;
			my $curr_nst 	= $2;
			my $curr_post 	= $3;
			
			$self->debug("parse",1,"<b>loop</b>: <b>$it_name</b> not found in object") unless $self->{ LOOPS }{ $it_name };
			
			# handle duplicate naming of nested loops
			$nest_multi{$curr_nst}++ ;
            my $thisdata = $self->iterate_loop( $curr_nst, $self->{ IT_STACK }->{$curr_nst}[$nest_multi{$curr_nst}-1], $self->{ PARENTS }{$input_name} );
			$loop = $curr_pre . $thisdata . $curr_post;
            
		}
		# add to iterated content
	    $iterated .= $loop;
	}
	return $iterated;
}

#=====================================
# replace normal variables
#=====================================
sub do_variables {
	my $self 			= shift;
	my $template_ref 	= shift;

    $$template_ref =~ s/${syntax_pre}variable='([\d\w-]+)'${syntax_post}/$self->{ ESCAPE } ? $self->escape_html($self->variable($1)) : ($self->variable($1) )/eg;
}


# encode html un-friendly entities
#----------------------------------
sub escape_html {
    my $self = shift;
    my $data = shift;
    my %esc = (
        '"'	 => '&#34;',
        '&'  => '&#38;',
        '<'  => '&lt;',
        '>'  => '&gt;'
    );
    $data =~ s/([\"<>])/$esc{$1}/g;
    return $data;
}

#=====================================
# Clean spaces
#=====================================
sub do_clean {
	my $self			= shift;
	my $template_ref 	= shift;
	
	# remove empty lines except in text areas
	$$template_ref =~ s/\s+\n/\n/sg unless $$template_ref =~ /textarea(.*?)\s+\n(.*?)\/textarea/msi;
	$$template_ref =~ s/\n\s+</\n</sg; # space before tag
}

#=====================================
# perform comparisons
#=====================================
sub compare {
	my $self	= shift;
	my $oper	= shift;
	my $left	= shift || 0;
	my $right	= shift || 0;
	$oper =~ s/ //g;

	if(
        ( $oper eq "="  && $left eq $right ) ||
		( $oper eq "==" && $left eq $right ) ||
		( $oper eq "!=" && $left ne $right ) ||
		( $oper eq "<"  && $left < $right )  ||
		( $oper eq "<=" && $left <= $right ) ||
		( $oper eq ">"  && $left > $right )  ||
		( $oper eq ">=" && $left >= $right ) ||
        ( $oper eq "LIKE" && $left =~ m/$right/ ) ||
        ( $oper eq "NOTLIKE" && $left !~ m/$right/ )
	  ) { return 1; }
	else { return 0; }
}

#=====================================
# debug template data
#=====================================
my $error_count;
sub debug {
	my $self 		= shift;
	my $type		= shift;
	my $level		= shift;
	my $msg			= shift;
	
	$$error_count++;
	# get caller data
	my( $file, $line, $pack, $sub ) = id(2);
	
	if( !$level ) { print "no debug level at: at $file line $line"; exit; }
	
	# insert the error in to the object hash
	$self->{ DEBUG }{ $level }{ $type }{ $$error_count }{ MSG } = $msg;
	$self->{ DEBUG }{ $level }{ $type }{ $$error_count }{ SUB } = $sub;
	$self->{ DEBUG }{ $level }{ $type }{ $$error_count }{ LOC } = "at $file line $line";
		
	# HIGH level debugging: print error and exit
	#---------------------------------
	if ( $level == $self->{DEBUG_LEVELS}{'Fatal'} ) {
		print $self->build_err($self->{DEBUG_LEVELS}{'Fatal'});
		exit;
	}

}
#===============================
# format error data
#===============================
sub build_err {
	my $self = shift;
	my $level = shift;
	
	# possible error types
	my %error_types = (
		param	=> "setup parameter",
		file	=> "file open / close / print",
		process	=> "building object data",
		parse	=> "parsing the html temlate"
	);
	my $level_type = $level || $self->{ DEBUG_LEVEL };

	# Shameless use of html for 'pretty' debugging
	# The module is, after all HTML::Processor
	my $error = qq|
		<style>
		.errlabel{ font: bold 12px verdana; }
		.errdata { font: normal 12px verdana; }
		.errhead { font: bold 14px verdana; border:1px solid #DDDDDD; background-color:#EEEEEE;}
		</style>
		<table border="0" cellpadding="1" cellspacing="1" bgcolor="#FFFFFF" align="center">
		<tr><td colspan="2" class="errlabel"><font size="4">Template Processing Debug Info:</font></td></tr>
	|;
	if( $$error_count == 0 ) { $error .= qq|<tr><td colspan="2" class="errlabel" bgcolor="#d7fbd8">No bugs to report</td></tr>|; }
	my %level_key = reverse %{ $self->{DEBUG_LEVELS} };
	foreach my $err_lvl(sort {{$b} <=> {$a}} keys %{ $self->{ DEBUG } } ){
		
		# debug up to & including given level
		if($err_lvl >= $level_type) {
		
			foreach my $err_typ(keys %{ $self->{ DEBUG }{ $err_lvl } } ){
				
				$error .= qq|<tr><td colspan="2" class="errhead">GROUP: [$error_types{$err_typ}] LEVEL: $level_key{$err_lvl}</td></tr>|;
				
				foreach my $err_num(sort {{$a} <=> {$b}} keys %{ $self->{ DEBUG }{ $err_lvl }{ $err_typ } } ){
					$error .= "<tr><td class=\"errlabel\" align=\"right\"><b>sub:</b></td><td class=\"errdata\">" . 
								$self->{ DEBUG }{ $err_lvl }{ $err_typ }{ $err_num } { SUB } .
							"</td></tr>" .
							"<tr><td class=\"errlabel\" align=\"right\"><b>what:</b></td><td class=\"errdata\" bgcolor=\"#eee2bf\">" .
								$self->{ DEBUG }{ $err_lvl }{ $err_typ }{ $err_num } { MSG } .
							"</td></tr>" .
							"<tr><td class=\"errlabel\" align=\"right\"><b>where:</b></td><td class=\"errdata\">" .
								$self->{ DEBUG }{ $err_lvl }{ $err_typ }{ $err_num } { LOC } .
							"</td></tr><tr><td colspan=\"2\"><hr size=\"1\" color=\"#808080\"></td></tr>\n";
				}
				$error .= qq|<tr><td colspan="2"> </td></tr>|;
			}
		}
	}
	$error .= qq|
	</table>
	|;
	return $error;
}
#===============================
# get error location data
#===============================
sub id {
    my $level = shift;
    my ( $pack, $file, $line, $sub ) = caller($level);
    my ( $id ) = $file =~ m|([^/]+)\z|;
    return ( $file, $line, $pack, $sub );
}


package HTML::Processor::Loop;

#----------------------------------------------
# Constructor for Loop Object
#----------------------------------------------
sub new {
    my $proto = shift;

    my $class = ref( $proto ) || $proto;
    my $self  = {};

    bless( $self, $class );
    return $self;
}

#----------------------------------------------
#	iterarion array method
#----------------------------------------------
sub array {
	my $self = shift;
	my ( $name, $val ) = @_;
	
	push @{ $self->{$name} }, $val;

}


#----------------------------------------------
# build loop options
#----------------------------------------------
sub option {
    my $self = shift;
	my $name = shift;
	my $val = shift;
	my $posit = shift;

	push @{ $self->{ OPTIONS }->{$name} }, $val;
	return $self->{ OPTIONS }->{$name};
}
1;

__END__

=head1 NAME

HTML::Processor - HTML template processor

=head1 SYNOPSIS

I<-perl>

	use HTML::Processor;

	$tpl = new HTML::Processor;
    
	-or with config options-
    
	$tpl = new HTML::Processor ({ 
	   debug     => "Normal",
	   footprint => 1,
	   clean     => 0
	});

	# data
	%animals = (
	    mammals    => {
	       types => [qw(monkey lion zebra elephant)],
	       count => 120
	    },
	    fish       => {
	       types => [qw(swordfish shark guppy tuna marlin tunny)],
	       count => 85
	    },
	    reptiles   => {
	       types => [qw(monitor python crocodile tortoise)],
	       count => 25
	    },
	    birds      => {
	       types => [qw(eagle pigeon kite crow owl sparrow)],
	       count => 57
	   }
	
	);

	# create parent loop object
	my $animals = $tpl->new_loop("animals");
	foreach my $animal_type( keys %animals){
	   # add data to the parent loop
	   $animals->array("animal_type", $animal_type);
	   $animals->array("count", $animals{$animal_type}{ count });

	   # create new nested loop object 'keyed' on
	   # the parent via $animal_type
	   my $types = $tpl->new_loop("types", $animal_type);
	   foreach my $type ( @{ $animals{$animal_type}{types} }){
	      # populate each 'child' loop
	      $types->array("type", $type);
	   }
	}
	# set variables
	$tpl->variable("what", "ANIMALS");
	$tpl->variable("count", 2);
	
	# process and print parsed template
	print $tpl->process("templates/animals.html");

I<-html>

	<html>
	<head>
		<title>Sample</title>
	</head>
	<body>
	[TPL variable='what']:<br>
	<table width="200">
	[TPL LOOP name='animals']
	   <tr>
	      <td>[TPL array='animal_type'] [[TPL array='count']]</td>
	   </tr>
	   <tr>
	      <td align="right">
	      [TPL LOOP name='types']
	         [TPL array='type']<br>
	      [TPL LOOP END]
	      </td>
	   </tr>
	[TPL LOOP END]
	</table>
	<br><br>
	   [TPL IF count == '2']
	      count is  2
	   [TPL ELSE]
	      count is not 2
	   [TPL ENDIF]
	<br><br>
	
	[TPL include='footer.inc']

I<-output>

	<!--- TEMPLATE: templates/animals.html --->
	<html>
	<head>
	<title>Sample</title>
	</head>
	<body>
	ANIMALS:<br>
	<table width="200">
	<tr>
	<td>mammals [120]</td>
	</tr>
	<tr>
	<td align="right">
				monkey<br>
				lion<br>
				zebra<br>
				elephant<br>
	</td>
	</tr>
	<tr>
	<td>fish [85]</td>
	</tr>
	<tr>
	<td align="right">
				swordfish<br>
				shark<br>
				guppy<br>
				tuna<br>
				marlin<br>
				tunny<br>
	</td>
	</tr>
	<tr>
	<td>birds [57]</td>
	</tr>
	<tr>
	<td align="right">
				eagle<br>
				pigeon<br>
				kite<br>
				crow<br>
				owl<br>
				sparrow<br>
	</td>
	</tr>
	<tr>
	<td>reptiles [25]</td>
	</tr>
	<tr>
	<td align="right">
				monitor<br>
				python<br>
				crocodile<br>
				tortoise<br>
	</td>
	</tr>
	</table>
	<br><br>
			count is  2
	<br><br>
	<!--- INCLUDED: templates/footer.inc --->
	<br>
	COMMON FOOTER
	</body>
	</html>

=head1 DESCRIPTION

The Processor.pm module is designed to remove html from perl 
scripts without putting too much Perl into the html. 
The syntax (configurable) is somewhat verbose in order to 
not scare off html coders, while retaining some Perl logic and 
functionality. It has a fairly basic set of methods and is not 
as heavy duty as some of the other Template parsers
out there but manages to cover most of the essential html
processing operations.

B<Documentation Syntax>

As the module deals with PERL CODE, HTML CODE and OUTPUT
the documentation will indicate these as separate blocks:

I<-perl>

I<-html>

I<-output>

=head2 Module Defaults


=head2 Object Construction
    
    use HTML::Processor;
    
	$tpl = new HTML::Processor; # with defaults
	-or-
	$tpl = new HTML::Processor({
	   debuglevel  => 'Verbose',
	   footprint   => 0,
	   clean       => 0,
	   syntax_pre  => '\[% ',
	   syntax_post => ' %\]'
	});

When creating a new object some of the module defaults
may be overridden by passing a hash of options to
the constructor, these include:

=over 3

=item *
debuglevel

     values: [Off|Fatal|Normal|Verbose]  # case sensitive
	Default: Off
    Actions: Off => no debug info is displayed
             Fatal => only fatal errors are displayed
             Normal => basic processing info is displayed
             Verbose => verbose info about the processing stage
             ** Debug info is appended to the output

=item *
footprint

	 Values: [1|0]
	Default: 0
	Actions: 1 => leave an html comment describing the
	              location and name of the primary template
	              at the start of the output:
	              <!-- TEMPLATE: templates/animals.html --->
	              and for each included file:
	              <!-- TEMPLATE BEGIN INCLUDE templates/footer.html -->
                    -- included file data
                  <!-- TEMPLATE END INCLUDE: templates/footer.html -->
	         0 => don't

=item 3
clean

	 Values: [1|0]
	Default: 1
	Actions: 1 => remove blank lines and leading whitespace
	              from template output - reduces html
	              file size for efficiency but source is
	              no longer 'pretty'
	         0 => don't

=item 3
syntax_pre

	 Values: pretty much anything BUT escape special chars
	Default: '\[TPL ' # note the space
	Actions: Sets the opening syntax for template tags, may
	         conform to a variety of existing styles eg:
	         '<\% ' asp style
	         '<\? ' php style
	         '\[% ' Template-Toolkit style
	         Watch out for spaces and charaters which have
	         meaning within regular expressions

=item 3
syntax_post

	 Values: as above
	Default: '\]'
	Actions: As above

=back

Default Template Syntax examples

	[TPL variable='varname']
	[TPL LOOP name='loop_name']
	   [TPL array='loop_item']
	[TPL LOOP END]

Alternative syntax examples

	[% variable='varname' %]
	[% LOOP BEGIN name='loop_name' %]
	   [% array='loop_item' %]
	[% LOOP END %]

	<? variable='varname' ?>
	<? LOOP BEGIN name='loop_name' ?>
	   <? array='loop_item' ?>
	<? LOOP END ?>

=head2 Syntax

When passing variables to object methods and when
reflecting the variables in the html, the names
must be matchable by: [a-zA-Z0-9_-]

Names must be quoted in single quotes in the HTML/text
but double quotes are fine within Perl code.

Bad examples:

I<-perl>

	$tpl->variable("my~name", $val);

I<-html>

	[TPL variable='my~name']
	[TPL variable="myname"]



=head2 Precedence

The template data is processed in the following order
    
   (0. SORT - if called)
    1. INCLUDE
    2. OPTION
    3. IF/ELSE
    4. VARIABLES
    5. LOOPS
	   5a. LOOP OPTION
	   5b. LOOP IF/ELSE
	
Thus, if a LOOP is nested within an OPTION, the OPTION is
evaluated and if true, the LOOP is processed.

=head2 Including external files

File fragments or complete html files may be included into
any template file. The included files may also contain any
Template code blocks or tags. The name and path of the included file
may be stored within a template object or interpreted from
the include statement in the html.

The root path is relative to the primary template opened in by the

	$tpl->process("templates/main_template.html")

method.

B<adding tempate location paths>

Additional paths to locate templates may be added via the:

    $tpl->add_path("new/path/relative/to/calling/script");

The effect of adding base paths means that template locations
are more flexible and can be moved easily. Also, the paths are
used to test alternatives when a template can't be found at a 
specified location


B<Syntax:>

I<-perl>
	
    # specifying includes from Perl
	$tpl->include("footer", "templates/footer.html");

I<-html>

	[TPL include='footer']
	# $tpl->include("footer") will be accessed for filename

	-or-
    
    # specifying includes from the template
    
	[TPL include='fragments/footer.inc']
	# footer.inc is included by means of the direct
	# reference to its location in the html
	# the method call: $tpl->include("footer", "templates/footer.html");
	# IS NOT REQUIRED IN PERL

To expand on this lets take a script in /cgi-bin which calls

	$tpl->process("templates/main_template.html")

Within 'main_template.html' is the include:

	[TPL include='fragments/footer.inc']
    
Within footer.inc is the include:

    [TPL include='../../other_files/foo.htm']

When processed we have:

    /cgi-bin/templates/main_template.html
    # which then includes
    /cgi-bin/templates/fragments/footer.inc
    # which then includes
    /cgi-bin/other_files/foo.htm

The include process keeps track of the locations of all
included files relative to the template root.


=head2 Debugging

There are several methods available for debugging the Template
object.

    1. Debugging Perl
       HTML::Processor can be used to display program info during runtime
       to assist in Perl debugging. There are 2 methods for this:
       A: $tpl->print_die("data_to_print");
          "data_to_print" can be anything printable. This method
          will print an HTML header and then the data and exit
          the program.
          
       B: $tpl->print("data", 'line terminator')
          this will print an HTML header(once) then data
          inline as the script is executed. Sometimes usefull
          for viewing a loop's content eg:
          
          while ( @loop_data ) {
            $tpl->print($_, "<br>");
          }
          
          This outputs the data with HTML linebreaks for viewing
          in the browser.
          
       Output from both methods will be printed before any template
       content data.
       
    2. Debugging the Template Object
       The HTML::Processor object can be debugged in 2 ways:
       A: Using the Config Option at object creation set 'debuglevel'
          as describe in 'Object Creation' above. Debug data is appended
          the the end of object content.
          eg: $tpl = new HTML::Processor({ debuglevel => 'Verbose' });
          
       B: Viewing the entire content of the object via Data::Dumper
          $tpl->process("templates/template.html", 1);
          Pass an additional 'true' parameter to the process method and the
          object internal data is passed to Data::Dumper and appended
          to the end of object output content.

=head2 Option blocks

Option blocks are chunks of html/text which are displayed only
if a condition is true. The internal 'option' hash is
tested first and may be set explicitly, if the variable 
name is not found there, the 'variables' hash is tested.

If both tests return false the block is excluded from
temlate output. True is returned for anything but
0 or '' (empty string).

B<Syntax:>

I<-perl>

	# explicit
	$hour = (localtime)[2];
	$morning = ($hour < 12) ? 1 : 0;
	$tpl->option("morning", $morning);
	$tpl->variable("time", scalar localtime)
	-or-
	# implicit, re-using an object variable
	$tpl->variable("morning", scalar localtime) if ((localtime)[2] < 12);


I<-html>

	# explicit
	[TPL OPTION name='morning']
	   Good morning<br>
	   It is now: [TPL variable='time']
	[TPL OPTION END]

	# implicit
	[TPL OPTION name='morning']
	   Good morning<br>
	   It is now: [TPL variable='morning']
	[TPL OPTION END]

I<-output>

	# implicit and explicit
	Good morning
	It is now: Sat Jun 2 09:23:29 2001 

The logic may be inverted in an option block eg:

I<-perl>

    # A
    $tpl->option("optA", 1);
    # B
    $tpl->option("optB", 0);
    
I<-html>

    [TPL OPTION name='optA']
	   option A data
	[TPL OPTION END]
    
    [TPL OPTION name!='optB']
	   option B data
	[TPL OPTION END]

Both of the above evaluate as true and the content
will be output in both cases.


=head2 If / else blocks

If/Else blocks function in a similar way to Perl
if(){} elsif(){} else{} constructs and display the
contents of the first block for which the expression
returns true. Regular object variables are used
for the expression. Evaluation operators include:

	( == != < <= > >= LIKE NOTLIKE )

Equality and Inequality, for 
both strings and numerics, is via C<==> and C<!=>
respectively. HTML::Processor will determine whether the values
for comparison are strings or numerics and apply the
appropriate operators. Numbers handled are floating points,
integers or comma delimited floating points ( eg. 2,999,999.34 ).
All other number formats will be treated as strings.

The 'LIKE' and 'NOTLIKE' operators use a regular expression
for evaluation.

B<Syntax:>

I<-perl>
    
    # Assume the 'hour' is 11:00
	$tpl->variable("hour", (localtime)[2]);


I<-html>

	[TPL IF hour < '12']
	   Good Morning
	[TPL ELSIF hour >= '18']
	   Good Evening
	[TPL ELSE]
	   Good Afternoon
	[TPL ENDIF]

I<-output>

	Good morning


=head2 Loops

Loops handle multiple records of a given format. Each loop
must be named and can be thought of as similar to a database
table with rows and columns. Each 'row' represents a data
record and the 'columns' are data fields. Loops may be
nested within other loops by means of associating the
nested loop to its parent via a 'key' value (one of the data
fields). Loops may also contain conditional arguments,
If/Else and Option blocks, which evaluate a condition for 
each loop of a loop. 
Loop syntax is best explained by example:

B<Syntax:>

I<-perl>
    
    # consider this basic data set:
    my @pets_data = (
        "Boots,5,cat",
        "Rover,3,dog",
        "Tweety,1,budgie"
    );
    
    # create a new loop object
    # and populate the object via the loop
    # 'array' method
    $pets = $tpl->new_loop("pets");
    foreach my $pet (@pets_data){
        my ( $name, $age, $type ) = split (/,/, $pet);
        $pets->array("name", $name);
        $pets->array("age",  $age);
        $pets->array("type", $type);
    }

I<-html>
    
    My Pets:<br>
    NAME, AGE, TYPE<br>
    [TPL LOOP name='pets']
        [TPL array='name'], [TPL array='age'], [TPL array='type']<br>
    [TPL LOOP END]
    
I<-output>

    My Pets:
    NAME, AGE, TYPE
    Boots, 5, cat
    Rover, 3, dog
    Tweety, 1, budgie


=head3 Loop Options

Loop options evaluate a data field within the loop, if true the
optinal content is displayed. They are the same as normal options
but derive their scope from the current loop of the loop
which they are in.

Using our above data set:

I<-perl>
    
    # consider, again, this basic data set:
    my @pets_data = (
        "Boots,5,cat",
        "Rover,3,dog",
        "Tweety,1,budgie"
    );
    
    # create a new loop object
    # and populate the object via the loop
    # 'array' method
    $pets = $tpl->new_loop("pets");
    foreach my $pet (@pets_data){
        my ( $name, $age, $type ) = split (/,/, $pet);
        $pets->array("name", $name);
        $pets->array("age",  $age);
        $pets->array("type", $type);
        # set the variable 'cat' as true for testing
        # optional content
        $pets->array("cat", 1) if $type eq "cat";
    }

I<-html>

    My Pets:<br>
    NAME, AGE, TYPE<br>
    [TPL LOOP name='pets']
        [TPL array='name'], [TPL array='age'], [TPL array='type']
         [TPL LOOP OPTION name = 'cat']
            'meeow'
         [TPL LOOP OPTION END]
        <br>
    [TPL LOOP END]

I<-output>

    My Pets:
    NAME, AGE, TYPE
    Boots, 5, cat 'meeow'
    Rover, 3, dog
    Tweety, 1, budgie

Internally, each time the loop is evaluated if variable 'cat'
is true the data is displayed.


=head3 Loop If/Else

Same as normal If/Else but, like the Loop Option, tests values
within current loop of loop.

I<-html>
    
    My Pets:<br>
    NAME, AGE, TYPE<br>
    [TPL LOOP name='pets']
        [TPL array='name'], [TPL array='age'], [TPL array='type']
         [TPL LOOP IF type = 'cat']
            'meeow'
         [TPL ELSIF type = 'dog']
            'woof'
         [TPL ELSIF type = 'bird']
            'tweet'
         [TPL LOOP ENDIF]
        <br>
    [TPL LOOP END]


I<-output>

    My Pets:
    NAME, AGE, TYPE
    Boots, 5, cat 'meeow'
    Rover, 3, dog 'woof'
    Tweety, 1, budgie 'tweet'


=head3 Nested Loops

The concept of nested loops is similar to a database 'join'
where multi-record content for a field is derived from 
elsewhere based on a 'key'. Nests may be several levels deep
provided the syntax is maintained. Consider the following:


I<-perl>

    %animals = (
	    mammals    => {
	       types => [qw(monkey lion zebra elephant)],
	       count => 120
	    },
	    fish       => {
	       types => [qw(swordfish shark guppy tuna marlin tunny ray)],
	       count => 85
	    },
	    reptiles   => {
	       types => [qw(monitor python crocodile tortoise)],
	       count => 25
	    },
	    birds      => {
	       types => [qw(eagle pigeon owl)],
	       count => 57
	   }
	);

Here each type of animal has a variable-length record for the
names of its types.

    # create parent loop object
	my $animals = $tpl->new_loop("animals");
	foreach my $animal_type( keys %animals){
	   # add data to the parent loop
	   $animals->array("animal_type", $animal_type);
	   $animals->array("count", $animals{$animal_type}{ count });

	   # create new nested loop object 'keyed' on
	   # the parent via $animal_type
	   my $types = $tpl->new_loop("types", $animal_type);
	   foreach my $type ( @{ $animals{$animal_type}{types} }){
	      # populate each 'child' loop
	      $types->array("type", $type);
	   }
	}

    # IMPORATNAT SYNTAX
    # NEW PARENT LOOP OBJECT is created outside the block
    
    my $parent = $tpl->new_loop("parent");
    
    foreach ( @parent_data ) {
        my ( $val1,$val2,$val3,$parent_key ) = @_;
        $parent->array("val1", $val1);
        
        # create a NEW CHILD LOOP OBJECT for each loop
        # of the parent loop, use a unique value in
        # the parent data as the 'key' for each
        # child loop
        
        my $child = $tpl->new_loop("child", $parent_key);
        
        foreach ( @child_data ) {
            $child->array("name", $_);
        }
    }

I<-html>

	<table>
	[TPL LOOP name='animals']
	   <tr>
	      <td>[TPL array='animal_type'] [[TPL array='count']]</td>
	   </tr>
	   <tr>
	      <td align="right">
	      [TPL LOOP name='types']
	         [TPL array='type']<br>
	      [TPL LOOP END]
	      </td>
	   </tr>
	[TPL LOOP END]
	</table>



=head2 Sorting

Sort is a handy method to sort output data by columns. Often
output is an HTML table with rows and columns. The data may
be derived from several database calls, or other methods, and
it becomes difficult to sort the output internally in Perl.
This is where the Sort method comes in. Sort is applied to
a named LOOP on one of its columns. This is again best illustrated
by example (see the supplied perl example file for the full
data example - the example makes use of CGI.pm to grab incoming
sort instructions)

I<-perl>
    
    $tpl->sort($cgi->param('sortby'));
    print $tpl->process("templates/countries.html");


I<-html>

    <table>
    <tr>
        <td>name [<a href="scriptname.cgi?sort=countries-name">sort</a>]</td>
        <td>
            population 
            [<a href="scriptname.cgi?sort=population-ASC">ASC</a> 
            | <a href="scriptname.cgi?sort=population-DESC">DESC</a>]
        </td>
        <td>currency [<a href="scriptname.cgi?sort=currency">sort</a>]</td>
        <td>capital [<a href="scriptname.cgi?sort=capital">sort</a>]</td>
        <td>area [<a href="scriptname.cgi?sort=area">sort</a>]</td>
    </tr>
    [TPL LOOP name='countries']
    <tr>
        <td>[TPL array='name']</td>
        <td>[TPL array='population']</td>
        <td>[TPL array='currency']</td>
        <td>[TPL array='capital']</td>
        <td>[TPL array='area'] Km<sup>2</sup></td>
    </tr>
    [TPL LOOP END]
    </table>

The method $tpl->sortby('name_of_column_to_sort') is called
just prior the $tpl->process() The value of the column to sort
on 'name_of_column_to_sort' is derived from the query string in the
HTML link. The HTML link must be of the form:

    sort=name_of_array

'name_of_array' is the named array used when populating the loop object.

The direction of the sort will change alternately for each array
sorted beginning with Ascending. To specifically start with a
descinding sort use:

    sort=name_of_array-desc

If the direction is specified IN UPPERCASE as: 

    sort=name_of_array-ASC
    -or-
    sort=name_of_array-DESC

The direction will not alternate for that array during a sort, it will always
be in the direction specified.


Sorting where multiple loops exist

If an object contains several named loops and arrays it is advisable to
specify both the loop name and array name (in addition to sort direction).
In the above example we have 'sort=countries-name' this allows for 2 different
loops containing an array of the same name to be sorted accurately. If, for
example there were 2 loops with an array called 'name', it is necessary to
specify which 'name' array to sort on.


Alternating background colours

It often occurs when outputting tabular data that rows are highlited by
alternating HTML background colours. In order to achieve this in conjunction
with sorted data, the colours must be arranged after the data sort. The sort
method will look for an array within the loop to sort named:
'bgcolor'
If it finds this named array, the corresponding colour pair will
be applied to the data in alternation.



=head2 Processing Variables

=over 2

=item B<simple variable get and set>

=back

After a new template object has been created, variables
can be added to or returned from the object via:

	$tpl->variable("foo", $bar);
	# set foo = $bar

	$tpl->variable("foo");
	# return the value of foo

Variables may be re-set within the script:

    $tpl->variable("value", $value);
    $tpl->variable("value", sprintf("%.2f", $tpl->variable("value")));
    # this is clearly just an illustration - it could have been
    # done in one go.
    
    # another example which comes in handy
    $tpl->variable("checkbox_a", ($checkbox_val) ? "checked" : ""));


I<-perl>

	$varval = "hello world";
	$tpl->variable("greet", $varval);
	-or-
	$tpl->variable("greet", "hello world");

I<-html>

	[TPL variable='greet']

I<-output>

	hello world


=head3 variable concatenation


Once a variable is in an object you may want to
alter it in some way or add strings to it.

Syntax:

	$tpl->concat("varname", value, invert);

If 'invert' is true ie. not(0|'') value will be pre-pended
to 'varname'

I<-perl>

	$tpl->variable("greet", "hello world");
	$tpl->concat("greet", " its only me");

You can also invert the concatenation and pre-pend
a string

	$tpl->variable("message", "rain is wet");
	$tpl->concat("message", "roses are red, ", 1);

I<-html>

	[TPL variable='greet']<br>
	[TPL variable='message']

I<-output>

	hello world its only me
	roses are red, rain is wet


=head3 variable math


Basic mathematical operators may be applied to
variables in the form:

=over 3

=item *
'+' addition 

=item *
'-' subtraction

=item *
'*' multiplication

=item *
'/' division

=back

Syntax:

	$tpl->math("varname", value, operation);
	# varname = varname operation value
    
	-invert the operation
	
	$tpl->math("varname", value, operation, invert);
	# varname = value operation varname


B<addition and subtraction>

	$tpl->variable("one", 1);                        # one = 1
	$tpl->variable("two", 2);                        # two = 2
	$tpl->variable("three", 3);                      # three = 3

	$tpl->math("two", 2, "+");                       # two = 4
    # NOTE - this is the same as:
    $tpl->variable("two", $tpl->variable("two") + 2);
    
	$tpl->math("two", $tpl->variable("one"), "+");   # two = 5

	# using originally declared values
	$tpl->math("two", 2, "-");                       # two = 0
	
	# invert the operation
	$tpl->math("three", 1, "-", 1);                  # three = -2
	# tranlates as: 
	# 1 - $tpl->variable("three")
	# 1 - 3
	# -2

B<multiplication and division>

	$tpl->variable("one", 1);                        # one = 1
	$tpl->variable("two", 2);                        # two = 2
	$tpl->variable("three", 3);                      # three = 3

	$tpl->math("two", 3, "*");                       # two = 6
	$tpl->math("two", 12, "/", 1);   				 # two = 2


=head2 Processing the Template

$tpl->process("template_path/template_name.html");

This method returns the parsed template data, substituting all template
syntax for object data. Typical usage:

I<-perl>

    sub foo {
        $tpl->variable("varname", 'varval')
        ... populate template object with data
        ...
        
        print "Content-type: text/html";
        print $tpl->process("template_path/template.html");
        
        # print template and object data
        print $tpl->process("template_path/template.html", 1);
    }


=head1 AUTHOR

Paul Schnell    pschnell@touchpowder.com

Thanks to Alexis Orssich and Tom Robinson for ideas and putting the code
through its paces.

=head1 COPYRIGHT

Copyright (c) 2001 Paul Schnell. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

HTML::Template
HTML::Mason
Template

=cut