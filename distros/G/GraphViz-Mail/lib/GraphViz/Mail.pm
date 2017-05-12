package GraphViz::Mail;

use strict;
use Mail::Thread;
use GraphViz;
use Date::Parse qw( str2time );
use base qw( Class::Accessor::Chained::Fast );
__PACKAGE__->mk_accessors(qw( messages width height graph thread));

use vars qw($VERSION);


$VERSION = "0.1";



=head1 NAME

GraphViz::Mail - visualise a Mail thread as a tree

=head1 SYNOPSIS

 my $threader = Mail::Thread->new( @messages );
 $threader->thread;

 my $i;
 for my $thread ($threader->rootset) {
     ++$i;
	 my $gm       = GraphViz::Mail->new($thread);
     write_file( "thread_$i.svg", $gm->as_png );
 }

=head1 DESCRIPTION

GraphViz::Mail takes a Mail::Thread::Container and generates a 
graph of the thread.

=head1 METHODS

=head2 new

Generic constructor, takes a Mail::Thread::Container

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $thread = shift;

  my $graph = GraphViz->new();
  
  my $self = {};
  bless $self, ref $class || $class;
  $self->graph($graph);
  $self->thread($thread);
  $self->_init();

  return $graph;
}

=head2 as_*

The Thread can be visualised in a number of different graphical
formats. Methods include as_ps, as_hpgl, as_pcl, as_mif, as_pic,
as_gd, as_gd2, as_gif, as_jpeg, as_png, as_wbmp, as_ismap, as_imap,
as_vrml, as_vtx, as_mp, as_fig, as_svg. See the GraphViz documentation
for more information. The two most common methods are:

  # Print out a PNG-format file
  print $g->as_png;

  # Print out a PostScript-format file
  print $g->as_ps;

=cut

sub _init {
    my $self = shift;

   	my $g    = $self->graph();
	my $root = $self->thread();


  # extract just the containers with messages
    my @messages;
    $root->iterate_down(
        sub {
            my $container = shift;
            push @messages, $container; # if $container->message;
        } );

    # sort on date
    @messages = sort {
        $self->date_of( $a ) <=> $self->date_of( $b )
    } @messages;


    {	
        # assign the numbers needed to compute X
        my $i;
        $self->messages( { map { $_ => ++$i } @messages } );
    }
    $self->draw_arc( $_->parent, $_ ) for @messages;
    $self->draw_message( $_ ) for @messages;


}

=head2 draw_message( $message )

Draw the message on the Graph.

=cut

sub draw_message {
    my ($self, $message) = @_;
	
	my $colour = 'red';
  	my $shape  = 'ellipse';
	my $from   = $message->header('from');
	my $subj   = $message->header('subject');

	$self->graph()->add_node($message, label => "$from:\n $subj" , color => $colour, shape => $shape);

}

=head2 draw_arc( $from, $to )

draws an arc between two messages

=cut

sub draw_arc {
    my ($self, $from, $to) = @_;
	$self->graph()->add_edge($from => $to);

}

=head2 date_of( $container )

The date the message was sent, in epoch seconds

=cut

sub date_of {
    my ($self, $container) = @_;
    return str2time $container->header( 'date' );
}





=head1 BUGS

None known.

=head1 AUTHOR

Simon Wistow E<lt>F<simon@thegestalt.org>E<gt>

=head1 COPYRIGHT

Copyright (C) 2003, Simon Wistow

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;

