package Hypatia;
{
  $Hypatia::VERSION = '0.029';
}
use Moose;
use Hypatia::Columns;
use Class::Load qw(load_class);
use Data::Dumper;


#ABSTRACT: A Data Visualization API


has 'back_end'=>(isa=>'Str',is=>'ro',required=>1);


has 'graph_type'=>(isa=>'Str',is=>'ro',predicate=>'has_graph_type');

sub BUILD
{
    my $self=shift;
    
    my @allowed_back_ends = qw(Chart::Clicker GraphViz2);
    
    my %allowed_graph_types=(q(Chart::Clicker)=>[qw(Area Bar Bubble CandleStick Line Pie Point PolarArea StackedArea StackedBar)]);
    
    push @allowed_back_ends,map{"Hypatia::" . $_}@allowed_back_ends;
    
    foreach(keys %allowed_graph_types)
    {
	$allowed_graph_types{"Hypatia::" . $_} = $allowed_graph_types{$_};
    }
    
    my $back_end=$self->back_end;
    
    confess "The back_end value of $back_end is not supported" unless grep{$_ eq $back_end}@allowed_back_ends;
    
    $back_end="Hypatia::" . $back_end unless $back_end=~/^Hypatia::/;
    
    
    my $graph_type;
    my $stacked=0;
    
    if($self->has_graph_type)
    {
	$graph_type=$self->graph_type;
	
	if($graph_type)
	{
	    $graph_type = ucfirst $graph_type;
	    
	    confess "The graph_type of $graph_type is not supported with a back_end of $back_end"
	    unless grep{$_ eq $graph_type}@{$allowed_graph_types{$back_end}};
	    
	    if($back_end eq "Hypatia::Chart::Clicker" and $graph_type=~/Stacked/)
	    {
		$graph_type=~s/Stacked//;
		$stacked=1;
	    }
	    elsif($back_end eq "GraphViz2")
	    {
		warn "WARNING: the graph_type attribute of " . $graph_type . " will be ignored in Hypatia::GraphViz2.\n";
	    }
	}
	elsif($back_end eq "Hypatia::Chart::Clicker")
	{
	    confess "The argument of graph_type is required for a back_end of Chart::Clicker";
	}
    }
    
    my %args=%{$self->args_to_pass};
    $args{stacked}=1 if $stacked;
    
    my $class=$back_end;
    $class.="::" . $graph_type if $graph_type;
    
    load_class($class);
    
    eval{has 'engine'=>(isa=>$class,is=>'rw',handles=>qr/^[^B]|^B(?!UILD)/)};
    
    confess $@ if $@;
    
    $self->engine($class->new(\%args));
}

has 'args_to_pass'=>(isa=>'HashRef',is=>'rw',required=>1);




around BUILDARGS =>sub
{
    my $orig  = shift;
    my $class = shift;
    my $args=shift;
    
    confess "Argument passed to BUILDARGS is not a hash reference" unless ref $args eq ref {};
    
    confess "No back_end argument given" unless defined $args->{back_end} and (ref $args->{back_end} eq ref "");
    
    delete $args->{engine} if defined $args->{engine};
    
    $args->{args_to_pass}={};
    
    foreach my $attr(keys %$args)
    {
	unless($attr eq "back_end" or $attr eq "graph_type")
	{
	    $args->{args_to_pass}->{$attr}=$args->{$attr};
	    delete $args->{$attr};
	}
    }
    return $class->$orig($args);
};


1;

__END__

=pod

=head1 NAME

Hypatia - A Data Visualization API

=head1 VERSION

version 0.029

=head1 SYNOPSIS

	use strict;
	use warnings;
	use Hypatia;
	
	my $hypatia=Hypatia->new({
	back_end=>"Chart::Clicker",
	graph_type=>"Line",
	dbi=>{
		dsn=>"dbi:MySQL:dbname=database;host=localhost",
		username=>"jdoe",
		password=>"sooperseekrit",
		query=>"select DATE(time_of_sale) as date,sum(revenue) as daily_revenue
		from widget_sales
		group by DATE(time_of_sale)"
    },
  columns=>{"x"=>"date","y"=>"daily_revenue"}
  });
  
  #grabs data from the query and puts it into a Chart::Clicker line graph
  my $cc=$hypatia->chart;
  
  #Since $cc is a Chart::Clicker object, we can now do whatever we want to it.
  
  $cc->title->text("Total Daily Revenue for Widget Sales");
  $cc->write_output("daily_revenue.png");

=head1 DESCRIPTION

For reporting and analysis of data, it's often useful to have charts and graphs of various kinds:  line graphs, bar charts, histograms, etc.  Of course, CPAN has modules for data visualization--in fact, there are L<quite|https://metacpan.org/module/Chart::Clicker> L<a|https://metacpan.org/module/GD::Graph> L<few|https://metacpan.org/module/GraphViz2> L<of|https://metacpan.org/module/Statistics::R> L<them|https://metacpan.org/module/Chart::Gnuplot>, each with different features and wildly different syntaxes.  The aim of Hypatia is to provide a layer between DBI and these data visualization modules, so that one can get a basic, "no-frills" chart with as little knowledge of the syntax of the particular data visualization package as possible.

Currently, the only bindings that are supported are:

=over 4

=item L<Chart::Clicker> (via L<Hypatia::Chart::Clicker>)

=item L<GraphViz2> (via L<Hypatia::GraphViz2>)

=back

However, support for other data visualization modules will be supported (see the L</TODO> section below).

=head2 Hypatia?

This distribution makes use of L<DBI>, but isn't an extension of L<DBI>, and hence doesn't belong in the C<DBIx::*> namespace.  It also isn't an extension of, eg, L<Chart::Clicker>, and thus shouldn't be in the C<Chartx::Clicker> namespace (or should that be C<Chart::Clickerx>?  C<Chart::xClicker>?  Bah!).

So, instead, this distribution is named after L<the first female mathematician of historical note and a mathematician and one of the librarians of the Great Library of Alexandria|http://en.wikipedia.org/wiki/Hypatia>

=head2 WARNING

Although I've put a considerable amount of thought into the API, this software should considered to be in alpha status. The API may change, although if it does, I'll do what I can to preserve backwards compatibility.

=head2 TODO

=over 4

=item * Expand the API to other data visualization packages.

=item * Add unit tests and more attributes to L<Hypatia::GraphViz2>.

=item * Allow the loading of options via configuration files (initially XML or ini; the only thing making this difficult for JSON is that queries usually take more than one line, and JSON doesn't support multi-line strings).

=item * Finish up some more of the options in L<Hypatia::Chart::Clicker>, and include some default "prettification" options that adds a reasonable amount of padding, fudging, etc.

=back

=head1 ATTRIBUTES

=head2 back_end

This string attribute represents the general name of the data visualization API that you wish to use.  For right now, the only supported value is C<Chart::Clicker>.

=head2 graph_type

This string attribute represents the type of graph that you want: 

=head1 ACKNOWLEDGEMENTS

I'd like to thank the following people for suggestions in making this distribution better. Any (constructive) criticism and feedback is welcome (jack at jackmaney dot com or jackmaney at gmail dot com).

=over 4

=item 1. L<Cory Watson|http://about.me/cory.g.watson> (aka L<gphat|https://metacpan.org/author/GPHAT>) for suggestions that greatly streamlined the API.

=item 2. L<David Precious|http://www.preshweb.co.uk/> for the idea of passing an active database handle into a L<Hypatia::DBI> object, instead of requiring the connection parameters.

=item 3. L<Ron Savage|http://savage.net.au/index.html> for updating L<GraphViz2> in order to make unit tests easier.

=back

=head1 AUTHOR

Jack Maney <jack@jackmaney.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jack Maney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
