package HTML::TableBracket;

$HTML::TableBracket::VERSION = '0.11';

use strict;
use POSIX qw(ceil floor);

=head1 NAME

HTML::TableBracket - Tournament Table Bracket Generator

=head1 SYNOPSIS

    use HTML::TableBracket;

    # Create the Bracket, list of names in seeded order
    $temp=HTML::TableBracket->new("Jeek", "Tom", "Dick", "Harry",
				  "Larry", "Curly", "Moe");

    # Process the matches (TEAM1 => SCORE1, TEAM2 => SCORE2)
    $temp->match(Larry => 10, Harry => 20);
    $temp->match(Jeek  => 10, Harry => 20);
    $temp->match(Dick  => 20, Curly => 21);
    $temp->match(Moe   => 10, Tom   => 20);

    # For matches that don't have a score, such as chess matches,
    # Use the round method. (WINNER,LOSER)
    $temp->round("Tom","Curly");

    # Display the table in HTML format
    print $temp->as_html;

    # Display the table in XHTML format
    print $temp->as_xhtml;

    # Display the table in .dot format (name of graph as argument)
    print $temp->as_directed_graph_source("Tournament");

    # Display the table as a directed graph (name of graph as argument)
    print $temp->as_directed_graph("Tournament")->as_png;


=head1 DESCRIPTION

This module generates a tournament bracket drawing for standard
single-elimination-style matchups.

=cut

#my (%element, $lastelement, @person, $numofpeople);

sub new {
    my $class = shift; 
    my (%element, $lastelement, @person, $j);
    my $numofpeople = 0;

    foreach my $name (@_) {
	$person[++$numofpeople] = "$numofpeople $name";
    }

    for ($j = 2; $j < 2 * (2 ** ceil(log($numofpeople) / log(2))); $j++) {
        $element{$j} = 0;
    }

    my $row = 0;
    $element{1} = 1;

    for ($j = 2; $j <= $numofpeople;) {
        my $maxrankincurrentrow = 0;
    	my $maxrankaddress = 0;

        for (my $k = (2 ** $row) / 2; $k < (2 ** $row); $k++) {
            $k = 1 if ($k < 1);

	    if ($element{$k}>$maxrankincurrentrow) {
		$maxrankincurrentrow=$element{$k}; $maxrankaddress=$k;
	    }
	}

	if ($maxrankincurrentrow == 0) {
	    $row++;
	} else {
	    if (($maxrankaddress / 2) == (ceil($maxrankaddress / 2))) {
		if (($maxrankaddress / 4) != (floor($maxrankaddress / 4))) {
		    $element{$maxrankaddress * 2} = $maxrankincurrentrow;
		    $element{($maxrankaddress * 2) + 1} = $j;
		} else {
		    if ($maxrankaddress == 2) {
			$element{4} = $j;
			$element{5} = $maxrankincurrentrow;
		    } else {
			$element{$maxrankaddress * 2} = $maxrankincurrentrow;
			$element{($maxrankaddress * 2) + 1} = $j;
		    }
		}
	    } else {
		if (($maxrankaddress / 4) == (floor($maxrankaddress / 4))) {
		    $element{$maxrankaddress * 2} = $maxrankincurrentrow;
		    $element{($maxrankaddress * 2) + 1} = $j;
		} else {
		    $element{$maxrankaddress * 2} = $j;
		    $element{($maxrankaddress * 2) + 1} = $maxrankincurrentrow;
		}
	    }

	    $element{$maxrankaddress} = -1;
	    $j++;
	}
    }

    return bless({
	ELEMENT		=> \%element,
	NUMOFPEOPLE	=> $numofpeople,
	LASTELEMENT	=> $numofpeople,
	PERSON		=> \@person,
    }, $class);
}

sub match {
    my ($self, $teamname1, $score1, $teamname2, $score2) = @_;
    my (%element, $lastelement, @person, $numofpeople);
    my ($team1, $team2, $x) = (0, 0, 0);

    $numofpeople = $self->{NUMOFPEOPLE};
    @person	 = @{$self->{PERSON}};
    %element	 = %{$self->{ELEMENT}};
    $lastelement = $self->{LASTELEMENT};

    while ($team1 == 0) {
        $_ = $person[++$x];
	$team1 = $x if (/\d+ (.*)/ and ($1 eq $teamname1));
	die "Invalid Team 1" if ($team1 > $lastelement);
    }

    $x = 0;

    while ($team2 == 0) {
        $_ = $person[++$x];
	$team2 = $x if (/\d+ (.*)/ and ($1 eq $teamname2));
	die "Invalid Team 2" if ($team2 > $lastelement);
    }

    my $i = 2;

    while ($team2 != $element{(0 - (2 * (($i % 2)- .5)) + $i)}) {
	$i++ while ($element{$i} != $team1);
    }

    if ($score1 > $score2) {
        $element{floor($i / 2)}   = $team1;
        $person[$lastelement + 1] = "";
        $x++;
        $person[$lastelement + 2] = "<S>";
        $person[++$lastelement]  .= "$person[$team1]&nbsp;($score1)";
        $element{$i}		  = $lastelement;
        $person[++$lastelement]  .= "$person[$team2]</S> ($score2)";
    } else {
        $element{floor($i / 2)}   = $team2;
        $person[$lastelement + 1] ="<S>";
        $person[$lastelement + 2] ="";
        $person[++$lastelement]  .= "$person[$team1]</S> ($score1)";
        $element{$i}		  = $lastelement;
        $person[++$lastelement]  .= "$person[$team2]&nbsp;($score2)";
    }

    $element{(0 - (2 * (($i % 2) - .5)) + $i)} = $lastelement;

    @{$self}{qw/ELEMENT    LASTELEMENT   PERSON    NUMOFPEOPLE/}
	     = (\%element, $lastelement, \@person, $numofpeople);

    return $self;
}

sub round {
    my ($self, $teamname1, $teamname2) = @_;
    my (%element, $lastelement, @person, $numofpeople);
    my ($team1, $team2, $x) = (0, 0, 0);

    $numofpeople = $self->{NUMOFPEOPLE};
    @person	 = @{$self->{PERSON}};
    %element	 = %{$self->{ELEMENT}};
    $lastelement = $self->{LASTELEMENT};

    while ($team1 == 0) {
        $_ = $person[++$x];
	$team1 = $x if (/\d+ (.*)/ and ($1 eq $teamname1));
	die "Invalid Team 1" if ($team1 > $lastelement);
    }

    $x = 0;

    while ($team2 == 0) {
        $_ = $person[++$x];
	$team2 = $x if (/\d+ (.*)/ and ($1 eq $teamname2));
	die "Invalid Team 2" if ($team2 > $lastelement);
    }

    my $i = 2;
    while ($team2 != $element{(0 - (2 * (($i % 2) - .5)) + $i)}) {
	$i++ while ($element{$i} != $team1);
    }

    $element{floor($i / 2)}   = $team1;
    $person[$lastelement + 1] = "";
    $x++;
    $person[$lastelement + 2] = "<S>";
    $person[++$lastelement]  .= "$person[$team1]&nbsp;";
    $element{$i}	      = $lastelement;
    $person[++$lastelement]  .= "$person[$team2]</S>";

    $element{(0 - (2 * (($i % 2) - .5)) + $i)} = $lastelement;

    @{$self}{qw/ELEMENT    LASTELEMENT   PERSON    NUMOFPEOPLE/}
	     = (\%element, $lastelement, \@person, $numofpeople);

    return $self;
}

sub as_html {
    my $self = shift; my $output = "";
    my (%element, $lastelement, @person, $numofpeople);

    $numofpeople = $self->{NUMOFPEOPLE};
    @person	 = @{$self->{PERSON}};
    %element	 = %{$self->{ELEMENT}};
    $lastelement = $self->{LASTELEMENT};

    my $firstentry = 2 ** ceil(log($numofpeople) / log(2));
    my $width = floor(100 / (log($firstentry) + 3));

    $output .= "<TABLE BORDER=1>\n";

    for (my $i = $firstentry; $i <= (2 * $firstentry - 1); $i++) {
	$output .= "    <TR>\n";

	my $j = $i;
	my $x = 1.5 * (2 ** ceil(log($i + 1) / log(2))) - $j - 1;
	my $k = 1;

	while ($j == floor($j)) {
	    $x=(1.5 * (2 ** (ceil(log($j + 1) / log(2))))) - $j - 1;

	    if ($element{$x} < 0) {
		$output .= "        <TD NOBREAK NOWRAP ROWSPAN=$k WIDTH=".$width."%>&nbsp;</TD>\n";
	    } elsif ($element{$x} == 0) {
		$output .= "        <TD NOBREAK NOWRAP WIDTH=$width% ROWSPAN=$k>&nbsp;</TD>\n";
	    } else {
		$output .= "        <TD WIDTH=$width% NOBREAK NOWRAP ROWSPAN=$k>$person[$element{$x}]</TD>\n";
	    }

	    $j /= 2; $k *= 2;
	}

	$output .= "    </TR>\n";
    }

    $output .= "</TABLE>\n";
}

sub as_xhtml {
    my $self = shift; my $output = "";

    my (%element, $lastelement, @person, $numofpeople);
    $numofpeople = $self->{NUMOFPEOPLE};
    @person	 = @{$self->{PERSON}};
    %element	 = %{$self->{ELEMENT}};
    $lastelement = $self->{LASTELEMENT};

    my $firstentry = 2 ** ceil(log($numofpeople) / log(2));
    my $width = floor(100 / (log($firstentry) + 3));

    $output .= "<table border=\"1\">\n    <tbody>\n";

    for (my $i = $firstentry; $i <= (2 * $firstentry - 1); $i++) {
	$output .= "        <tr>\n";

	my $j = $i;
	my $x = 1.5 * (2 ** ceil(log($i + 1) / log(2))) - $j - 1;
	my $k = 1;

	while ($j == floor($j)) {
	    $x=(1.5 * (2 ** (ceil(log($j + 1) / log(2))))) - $j - 1;

	    if ($element{$x} < 0) {
		$output .= "            <td nowrap=\"nowrap\" rowspan=\"$k\" width=\"".$width."%\">&nbsp;</td>\n";
	    } elsif ($element{$x} == 0) {
		$output .= "            <td nowrap=\"nowrap\" width=\"$width%\" rowspan=\"$k\">&nbsp;</td>\n";
	    } else {
		$output .= "            <td width=\"$width%\" nowrap=\"nowrap\" rowspan=\"$k\">$person[$element{$x}]</td>\n";
	    }

	    $j /= 2; $k *= 2;
	}

	$output .= "        </tr>\n";
    }

    $output .= "    </tbody>\n</table>\n";
    $output =~ s!</?S>!!isg;

    return $output;
}

sub as_directed_graph_source {
    my $self = shift; my $output = ""; my $reverse="";
    my $name = shift;
    my (%element, $lastelement, @person, $numofpeople);
    my $i = 0; my $current="";

    $numofpeople = $self->{NUMOFPEOPLE};
    @person	 = @{$self->{PERSON}};
    %element	 = %{$self->{ELEMENT}};
    $lastelement = $self->{LASTELEMENT};

    my $firstentry = 2 ** ceil(log($numofpeople) / log(2));
    for ($i = 1; $i < (2 * $firstentry - 1); $i++) {
        if ($element{$i} > 0) {
            $current=$person[$element{$i}];
            $output = "    $i [label=\"$current\"];\n". $output;
        } elsif ($i < $firstentry) {
	    $output = "    $i [label=\" \"];\n" . $output;
        }

        my $j = 0; my $k = 0;

        if ($i > 1) {
            if ($i < $firstentry) {
                $j = floor($i / 2);
                $reverse = "    $i -> $j;\n" . $reverse;
            } elsif ($element{$i} > 0) {
		$j = floor($i / 2);
		$reverse = "    $i -> $j;\n" . $reverse;
            }
        }
    }

    $output = "digraph $name {\n    rankdir=LR;\n" . $output;
    $output .= $reverse . "}\n";
    $output =~ s!</?S>!!isg;
    $output =~ s!&nbsp;! !isg;

    return $output;
}

#sub as_directed_graph {
#    my $self = shift;
#    my $name = shift;
#    my (%element, $lastelement, @person, $numofpeople);
#    my $i = 0; my $current = "";
#
#    eval "use GraphViz; 1" or die "You need to install GraphViz.pm to use this function"
#    my $g = GraphViz->new(directed => 1, rankdir => 1);
#
#    $numofpeople = $self->{NUMOFPEOPLE};
#    @person	 = @{$self->{PERSON}};
#    %element	 = %{$self->{ELEMENT}};
#    $lastelement = $self->{LASTELEMENT};
#
#    my $firstentry = 2 ** ceil(log($numofpeople) / log(2));
#    for ($i = (2 * $firstentry); $i > 0; $i--) {
#        if ($element{$i} > 0) {
#            $current = $person[$element{$i}];
#            $current =~ s!</?S>!!isg;
#            $current =~ s!&nbsp;! !isg;
#            $g->add_node($i, label => $current);
#        } elsif ($i<$firstentry) {
#	    $g->add_node($i, label => ' ');
#        }
#
#        my $j = 0;
#
#        if ($i > 1) {
#            if ($i < $firstentry) {
#                $j = floor($i / 2);
#                $g->add_edge($i, $j);
#            } elsif ($element{$i} > 0) {
#		$j = floor($i / 2);
#		$g->add_edge($i, $j);
#            }
#        }
#    }
#
#    return $g;
#}

1;

=head1 ACKNOWLEDGEMENTS

Thanks to Fletch and autrijus of the I<#perl that doesn't officially exist>
for interface suggestions.

More thanks to autrijus for setting up the original distribution.

Yet more thanks to autrijus for his continuing assistance in polishing th
code.

=head1 BUGS

The as_directed_graph function is commented out until I can find a way
to only load it if the user has GraphViz installed.

=head1 AUTHORS

T. J. Eckman E<lt>jeek@jeek.netE<gt>.

=head1 COPYRIGHT

Copyright 2001 by T. J. Eckman E<lt>jeek@jeek.netE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
