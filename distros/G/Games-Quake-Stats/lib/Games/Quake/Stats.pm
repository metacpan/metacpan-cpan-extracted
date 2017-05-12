package Games::Quake::Stats;

###################################################################################
#
# This module provides simple mechanisms for collecting and displaying game
# statisitics for the Quake, Quake2, Quake2world, and Quake 3 games.   It works 
# by  reading the fraglog file created by Quake servers.
#
# You can specify the fraglog file when the object is constructed, the module
# compiles statistics for each player that appears in the log.
#
# The Games::Quake::Stats module can create simple bar charts showing
# the relative statistics of each player, and can generate textual and pre-
# formed HTML output (HTML output shows the graphs created).
#
###################################################################################

use strict;
use warnings;

use Games::Quake::Player;
use GD::Graph::hbars;
use GD::Graph::colour;
use Carp;


require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Games::Quake::Stats ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.05';


# Preloaded methods go here.

##################################################
# object constructor                      
#
sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
        _stats_graph  => undef,   
	_skill_graph => undef,	    
	_frag_log => undef,
	_frag_data => [],
	_players => {},
        @_, # Override previous attributes
    };
    
    bless $self, $class;

    if($self->{_frag_log}){	
	$self->get_frag_data($self->{_frag_log});
	$self->initialize();
    }
    else{
	$self->initialize();
    }
	
    return bless $self, $class;
}


			   
sub initialize{

    my ($self) = @_;
    my $frag_data = $self->{_frag_data};

    foreach my $frag (@$frag_data){
	
	my $fragger = $frag->[0];
	my $fraggee = $frag->[1];
	
	#  fraggee 
	my $fragged_player = Player->new(
	    _name => $fraggee,
	    );    	
	
	my $found_fraggee = $self->{_players}->{$fraggee};    
	if(!$found_fraggee){
	    $self->{_players}->{$fraggee} = $fragged_player;
	    $fragged_player->inc_times_fragged();
	}
	else{
	    $found_fraggee->inc_times_fragged();
	}
		
	#  player
	my $player = Player->new(
	    _name => $fragger,
	    );
	
	my $found_player = $self->{_players}->{$fragger};   
	if(!$found_player){	
	    $self->{_players}->{$fragger} = $player;
	    $player->update_stats($fraggee);
	}
	else{
	    $found_player->update_stats($fraggee);    
	}
    }
    
    foreach my $player_name (keys %{$self->{_players}}){		
	my $player = $self->{_players}->{$player_name};	
	my $total_frags = $player->total_frags();
	my $times_fragged = $player->times_fragged();
	
	if($times_fragged == 0){
	    $times_fragged = 1;  # avoid divide by zero
	}
	
	$player->{_skill} = $total_frags/$times_fragged;	
    }

}




########################################################################
#
#    Subroutines
#
########################################################################




#-----------------------------------------------------------------------
#
# get_player
#
#-----------------------------------------------------------------------
sub get_player{
    my ($self, $player_name) = @_;

    my $players = $self->{_players};

    return $players->{$player_name};
}



#-----------------------------------------------------------------------
#
# times_fragged
#
#-----------------------------------------------------------------------
sub times_fragged{
    my ($self, $player_name1, $player_name2) = @_;
    
    my $player1 = $self->{_players}->{$player_name1};
    
    if(!$player1){
	croak "times_fragged:  no such player ($player_name1)\n";
    }
    
    if(!$player_name2){
	return $player1->times_fragged();
    }
    else{
	my $player2 = $self->{_players}->{$player_name2};
	
	if(!$player2){
	    croak "times_fragged:  no such player ($player_name2)\n";
	}
	return $player1->times_fragged_player($player_name2);
    }
}


#-----------------------------------------------------------------------
#
# total_frags
#
#-----------------------------------------------------------------------
sub total_frags{
    my ($self, $player_name) = @_;

    my $player = $self->{_players}->{$player_name};
    
    if(!$player){
	croak "total_frags:  no such player ($player_name)\n";
    }

    return $player->total_frags();
}



#-----------------------------------------------------------------------
#
# skill_level
#
#-----------------------------------------------------------------------
sub skill_level{
    my ($self, $player_name) = @_;

    my $player = $self->{_players}->{$player_name};
    
    if(!$player){
	croak "total_frags:  no such player ($player_name)\n";
    }

    my $total_frags = $player->total_frags();
    my $times_fragged = $player->times_fragged(); 

    return $total_frags/$times_fragged;
}





#-----------------------------------------------------------------------
#
# generate_text
#
#-----------------------------------------------------------------------
sub generate_text{

    my ($self) = @_;
    
    my $players = $self->{_players};

    print "frag log statistics\n";

    foreach my $player_name (keys %$players){		
	my $player = $players->{$player_name};
	print "Player: " . $player->name() . ", total_frags: " . $player->total_frags() . "\n";	
	foreach my $player_fragged_name (keys %$players){
	    my $player_fragged = $players->{$player_fragged_name};
	    print "     " . $player_fragged->name() . " " . $player->times_fragged_player($player_fragged->name()) . "\n";
	}	
    }    
    return 1;
}



#-----------------------------------------------------------------------
#
# generate_graph
#
#-----------------------------------------------------------------------
sub generate_stats_graph
{
    my ($self, $graph_file) = @_;
    my $players = $self->{_players};

    if(!$graph_file){
	$graph_file = $self->{_stats_graph};	
    }

    my $data_ref = [];
    my @player_names;    
    my $max_y = 0;
    
    push(@player_names, "total  (- self-inflicted)");

    foreach my $player_name (sort(keys %$players)){

	my $player = $players->{$player_name};

	push(@player_names, $player->name());
	push(@{$data_ref->[0]}, $player->name());

	my $total_frags = $player->total_frags();
       	push(@{$data_ref->[1]}, $total_frags);	
	if ($total_frags > $max_y){
	    $max_y = $total_frags;
	}

	my $i = 2;
	foreach my $player_fragged_name (sort(keys %$players)){	    

	    my $player_fragged = $players->{$player_fragged_name};	    
	    my $times_fragged_player = $player->times_fragged_player($player_fragged->name());
	    
	    push(@{$data_ref->[$i]}, $times_fragged_player);
	    $i++;
	}	
    }
    
    my $my_graph = GD::Graph::hbars->new(550,550);
    
    $my_graph->set(
	x_label  =>  'player',
	y_label  =>  'frags',
	title    =>  'manliness',
	bar_spacing => 1,
	bargroup_spacing => 10, 
	legend_spacing => 3,
	legend_placement  => 'RT',
	show_values       => 1,
	y_max_value       => $max_y + int($max_y/10),
        #x_label_position   => 0,
	dclrs => [ ( "orange", "lgreen", "#0050FF", "dgreen", "#00BBBB", 
		     "dblue", "dred", "blue", "dpurple", "lgray"  ) ],
	) or warn $my_graph->error;


    $my_graph->set_legend(@player_names);
    $my_graph->plot($data_ref) or croak $my_graph->error;
    my $ext = $my_graph->export_format;
    my $outfile;
    open($outfile, ">$graph_file") or croak "Could not open $graph_file: $!\n";
    binmode $outfile;
    print $outfile $my_graph->gd->$ext();    
    close $outfile;
    
}


#-----------------------------------------------------------------------
#
# generate_skill_graph
#
#-----------------------------------------------------------------------
sub generate_skill_graph
{
    my ($self, $skill_graph_file) = @_;
    my $players = $self->{_players};

    if(!$skill_graph_file){
	$skill_graph_file = $self->{_skill_graph};	
    }

    my $data_ref = [];
    my @player_names;    
    my $max_y = 0;
    
    push(@player_names, "skill (frags/fragged * 100)");

    foreach my $player_name (sort(keys %$players)){
	
	my $player = $players->{$player_name};
	push(@player_names, $player_name);
	push(@{$data_ref->[0]}, $player_name);
	my $skill = sprintf("%0.2f", $player->{_skill} * 100);	
	push(@{$data_ref->[1]}, $skill);	
	if ($skill > $max_y){
	    $max_y = $skill;
	}
    }
    
    my $my_graph = GD::Graph::hbars->new(550,550);
   
    $my_graph->set(
	x_label  =>  'player',
	y_label  =>  'skill (% frags/fragged)',
	title    =>  'skill',
	bar_spacing => 1,
	bargroup_spacing => 50, 
	legend_spacing => 5,
	legend_placement  => 'RT',
	show_values       => 1,
	y_max_value       => $max_y + int($max_y/10),
        #x_label_position   => 0,
	dclrs => [ ( "#017797", "dpurple", "dred", "dgreen", "blue", "green", 
		     "lblue", "dgray", "dgreen", "dblue", "marine" ) ],
	) or warn $my_graph->error;
    

    $my_graph->set_legend(@player_names);
    $my_graph->plot($data_ref) or croak $my_graph->error;
    my $ext = $my_graph->export_format;
    my $outfile;

    open($outfile, ">$skill_graph_file") or croak "Could not open $skill_graph_file: $!\n";
    binmode $outfile;
    
    print $outfile $my_graph->gd->$ext();    
    close $outfile;    
}




#-----------------------------------------------------------------------
#
# generate_html
#
#-----------------------------------------------------------------------
sub generate_html{

    my ($self, $graph_base_url) = @_;

    my $players = $self->{_players};

    my $graph_file = $self->{_stats_graph};
    my $skill_graph_file = $self->{_skill_graph};
    my $graph_file_short;
    my $skill_graph_file_short;

    if($graph_file){
	my @path_components = split('/', $graph_file);
	$graph_file_short = pop(@path_components);
    }
    if($skill_graph_file){
	my @path_components = split('/', $skill_graph_file);
	$skill_graph_file_short = pop(@path_components);
    }
	
    print "<HTML>\n";
    print "<HEAD><TITLE>frag log statistics</TITLE></HEAD>\n";
    print "<BODY>\n";
    print "<H2><font face='courier'>frag log statistics</font></H2>";
    print "<TABLE cellpadding=0 cellspacing=0><TR><TD>\n";
    if($graph_file_short){
	print "<IMG src='" . $graph_base_url . $graph_file_short . "'></IMG>\n";
    }
    print "</TD><TD>\n";
    if($skill_graph_file_short){
	print "<IMG src='" . $graph_base_url . $skill_graph_file_short . "'></IMG>\n";
    }
    print "</TD></TR></TABLE>\n";
    print "<BR><BR><font face='courier' size=-1><b><i>the numbers don't lie</i></b></font><BR>";
    print "<PRE>\n";


    foreach my $player_name (sort(keys %$players)){	
	
	my $player = $players->{$player_name};
	my $total_frags = $player->total_frags();
	my $times_fragged = $player->times_fragged();
	my $name = $player->name();
	my $skill = $player->{_skill};
	my $skill_str = sprintf("%0.2f", $skill * 100);

	print "<br><b>$name</b>: total_frags: $total_frags\n";
	print "      times fragged:  $times_fragged\n";
	print "      skill (total_frags/times_fragged):  $skill_str\n";

	foreach my $player_fragged_name (keys %$players){

	    my $player_fragged = $players->{$player_fragged_name};

	    if($player_fragged->name() eq $player->name()){
		print "          <b><i>" . $player_fragged->name() . "</i></b> " . $player->times_fragged_player($player_fragged->name()) . " (self-inflicted)\n";
	    }
	    else{
		print "          " . $player_fragged->name() . " " . $player->times_fragged_player($player_fragged->name()) . "\n";
	    }
	}	
    }    

    
    print "</PRE>\n";   
    print "</BODY>\n";
    print "</HTML>\n";

    return 1;
}


#-----------------------------------------------------------------------
#
# get_frag_data
#
#-----------------------------------------------------------------------
sub get_frag_data
{
    my ($self, $in_file) = @_;

    open(READF, "<$in_file") || croak "Can't open input file:  $in_file.  $!";

    my @lines = <READF>;
    my @frags;

    my $line_num = 0;
    my $orig_line;


    foreach my $line (@lines){

	$orig_line = $line;
	$line_num++;
	

	# strip off the leading \ in a frag line:  "\pigvana\ShovelTooth\\n" becomes "pigvana\ShovelTooth\\n"
	$line =~ s/^(\s\s*)*\\//; 
	# strip off the trailing \\n in a frag line:  "pigvana\ShovelTooth\\n" becomes "pigvana\ShovelTooth"
	$line =~ s/\\\n$//;
	my @names = split(/\\/, $line);

	

	if(my $num_names = @names != 2){
	    croak "Bad log file- format unknown: (line $line_num) '$orig_line'\n";
	}

	push (@frags, \@names);
    }
   
    $self->{_frag_data} = \@frags;
    
    return @frags;
}



1;  # load successful


__END__


=head1 NAME

Games::Quake::Stats - Perl module for compiling basic Quake game statistics

=head1 SYNOPSIS

  use Games::Quake::Stats;
  

=head2 EXAMPLE


 use strict;
 use Games::Quake::Stats;
 
 # NOTE: 
 # 
 # This example supposes you want to use this module in a CGI setting.
 #
 #
 # If you configure your quake-server to write a fraglog in the directory 
 # where the quake-server is run, you can create a symbolic link from the
 # fraglog file to the file: /var/www/cgi-bin/fraglog.log (if that is where this
 # CGI application will reside).  This code will then read the statistics data
 # from the *actual* file, while the quake-server deals only with a symbolically
 # linked file.
 #
 my $quake_stats = Stats->new(_frag_log => "/var/www/cgi-bin/fraglog.log",
			      _stats_graph => "/var/www/html/stats/chart.jpg",
			      _skill_graph => "/var/www/html/stats/skill.jpg");
					   


 # number of times player 'player1' has been scored against
 my $player1_fragged = $stats->times_fragged("player1");


 # number of times player 'player1' has scored against 'player2'
 my $player_total = $stats->total_frags("player1", "player2");
 

 # total frags player 'player1' has scored
 my $player_total = $stats->total_frags("player1");
 

 # skill level of player 'player1' (total_scored/times_scored_against);
 my $player_skill = $stats->skill_level("player1");




 # create graphs					   
 $quake_stats->generate_stats_graph(); # or, generate_stats_graph("/var/www/html/stats/stats.jpg");
 $quake_stats->generate_skill_graph();


 # If you are using this code as a CGI response:
 print "Content-type: text/html\r\n\r\n";    

 # Usually create graphs before calling this (as this example did above)
 $quake_stats->generate_html("http://www.youraddress.net/stats/");

 exit (0);






=head1 DESCRIPTION

This module provides simple mechanisms for collecting and displaying game
statisitics for the Quake, Quake2, Quake2world, and Quake 3 games.   It works by 
reading the fraglog file created by Quake servers.

You can specify the fraglog file when the object is constructed, the module
compiles statistics for each player that appears in the log.

The Games::Quake::Stats module can create simple bar charts showing
the relative statistics of each player, and can generate textual and pre-formed
HTML output (HTML output shows the graphs created).


=head1 METHODS


=head2 new()

 my $stats = Games::Quake::Stats->new(_frag_log => "/var/www/cgi-bin/fraglog.log",
                                      _stats_graph => "/var/www/html/stats/chart.jpg",
                                      _skill_graph => "/var/www/html/stats/skill.jpg");


=head2 initialize()

 $stats->initialize($log_filename);

Initializes the Stats object with a frag log filename.


=head2 generate_stats_graph()

 $stats->generate_skills_graph($graph_filename);

Generate JPG graph file displaying player statistics.



=head2 generate_skills_graph()

 $stats->generate_skills_graph($graph_filename);

Generate JPG graph file displaying player skill levels.


=head2 generate_html()

 $stats->generate_html($base_url);

Generate HTML output using $base_url as the base URL for any images (such as the graphs you create with
generate_stats_graph() and generate_skills_graph().


=head2 generate_text()

Generate textual statistics output.


=head2 skill_level()

 my $skill_level = skill_level($player_name);

Returns the skill level of the player.   Skill level is defined as (total frags)/(times fragged).


=head2 total_frags()

 my $total_frags = total_frags($player_name);

Returns the number of frags a player has scored.


=head2 times_fragged()

 my $times_fragged = times_fragged($player_name);
 my $times_fragged = times_fragged($player_name1, $player_name2);

Returns the number of times a player has been fragged, or if a second player is provided, the
number of times the first player has been fragged by the second.





=head1 BUGS AND LIMITATIONS

At the moment the JPG graph generation can only accomodate about 10 or so players, due to a
limitation on the number of colors for the bars in the chart.    This will hopefully be addressed in a future
release.


=head1 DEPENDENCIES

Test::More,
Games::Quake::Player,
GD::Graph::hbars,
GD::Graph::colour


=head2 EXPORT

None by default.



=head1 SEE ALSO

The Quake2World game website, mantained by developer jdolan:  www.quake2world.net.
Or if you use IRC, try the #quetoo channel on irc.freenode.net.

=head1 AUTHOR

Matthias Beebe, E<lt>matthiasbeebe@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Matthias Beebe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
