package FrameNet::WordNet::Detour::Data;

require Exporter;
our @ISA = qw(Exporter);
our $VERSION = "0.99";

use strict;
use warnings;
use FrameNet::WordNet::Detour::Frame;

sub new {
  my $class = shift;
  my $this = {};
  
  bless($this, $class);
  
  $this->{'s2f-result'} = shift;
  $this->{'raw'} = $this->{'s2f-result'}{'raw'};
  $this->{'sorted'} = $this->{'s2f-result'}{'sorted'};
  my @warr = reverse (sort { $a <=> $b } keys %{$this->{'sorted'}});
  $this->{'weights'} = \@warr;
  $this->query(shift);
  $this->message(shift) || $this->message('OK');

  return $this;
}

sub query {
    my ($self,$query) = @_;
    if (defined $query) {
	$self->{'query'} = $query;
    };
    return $self->{'query'};
}

#sub get_query {
#    my ($self,$query) = @_;
#    if (defined $query) {
#	return $self->query($query);
#    };
#    return $self->query;
#}

sub message {
    my ($self,$msg) = @_;
    if (defined $msg) {
	$self->{'message'} = $msg;
    };
    return $self->{'message'};
}



# Checks, wether the query returned some useful results or not. 
# If not, one should check the error message via &get_message. 
# Could be better, by checking deeper in the data structure,
# if there is a 'Frame'-Object.
sub isOK {
  my $self = shift;
  return 1 if ($self->{'message'} eq 'OK');
  return 0;
};



sub get_fees {
  my $self = shift;
  my $_frame = shift;
  my $f = $self->get_frame($_frame);
  return $f if ($f == -1);
  return $f->fees;
};

sub get_weight {
  my $self = shift;
  my $frame = shift;
  my $f = $self->get_frame($frame);

  return $f if ($f == -1);
  return $f->weight;
};

sub get_weights {
  my $self = shift;
  return $self->{'weights'};
};

# not working
sub _get_delta {
  my $self = shift;
  my $frame = shift;
  

  my $w0 = $self->{'raw'}->{$frame}->{'weight'};
  my $w1 = 0;
  my @weights = ( sort { $a <=> $b } (keys %{$self->{'sorted'}}));



  for(my $i = 0; $i < scalar @weights; $i++) {
    $w1 = $weights[$i+1] if ($w0 == $weights[$i] && 
			     exists($weights[$i+1]));
  };
  return int((($w0 - $w1)*1000)+0.5)/1000;
};

sub get_number_of_frames {
  my $self = shift;
  return scalar (keys %{$self->{'raw'}});
};

# Returns a reference to an array containing the arg1 
# best frames (as Frame-Objects). Frames are sorted according
# to their weight.
# If arg1 is not given, the best frame will be returned.
# Works always on the first (e.g. 0th) synset.
sub get_best_frames {
  my $self = shift;
  my $n = 0;
  my $m = shift || 1;

  my $ResultsByWeight = $self->{'sorted'};

  my $ResultList = [];

  my $result_counter = 1;
  
  foreach my $weight (reverse(sort(keys %$ResultsByWeight))) {
    if ($result_counter <= $m) {
      foreach my $frame (keys %{$ResultsByWeight->{$weight}}) {
	push (@$ResultList, $ResultsByWeight->{$weight}->{$frame});
      };
    };
    $result_counter++;
  };
  return $ResultList;
};

# WORKS
sub get_best_framenames {
  my $self = shift;
  my $m = shift || 1;
  my $frames = $self->get_best_frames($m);
  my @arr =  map($_->name, @$frames);
  return \@arr;
};

# Returns a list of all found frames.
sub get_all_framenames ($) {
  my $self = shift;
  my $tmp = {};
  foreach my $frame (keys %{$self->{'raw'}}) {
      $tmp->{$frame} = 1;
  }
  my @ret = keys %$tmp; 
  return \@ret;
};

sub get_all_frames {
  my $self = shift;
  my $ResultsByWeight = $self->{'sorted'};
  my $ResultList = [];

  foreach my $weight (reverse(sort(keys %$ResultsByWeight))) {
    foreach my $frame (keys %{$ResultsByWeight->{$weight}}) {
      push (@$ResultList, $ResultsByWeight->{$weight}->{$frame});
    };
  };
  return $ResultList;
};

sub get_frame {
  my $self = shift;
  my $frame = shift;
  #print STDERR $frame."!!!";
  return $self->{'raw'}->{$frame} if (exists($self->{'raw'}->{$frame}));
  return $self->{'raw'}->{lc($frame)} if (exists($self->{'raw'}->{lc($frame)}));
  return $self->{'raw'}->{ucfirst($frame)} if (exists($self->{'raw'}->{ucfirst($frame)}));
  return -1;
};

sub get_best_weight {
  my $self = shift;
  my $w = $self->get_weights;
  return $w->[0];
};

sub get_frames_with_weight {
  my $self = shift;
  my $weight = shift;
  my @l = keys %{$self->{'sorted'}->{$weight}};
  return \@l;
};

__END__

## DOCUMENTATION ##

=head1 NAME

FrameNet::WordNet::Detour::Data - A class representing the results of the Detour.

=head1 SYNOPSIS

  use FrameNet::WordNet::Detour;

  my $wn = WordNet::QueryData->new($WNSEARCHDIR);
  my $sim = WordNet::Similarity::path->new ($wn);
  my $detour = FrameNet::WordNet::Detour->new($wn,$sim);

  my $result = $detour->query($synset);

  $result->is_ok;   # Returns whether there were problems in the run
  $result->message; # Returns 'Ok' or an error message

  # All frames are returned as lists of 
  # L<FrameNet::WordNet::Detour::Frame> objects


  $result->get_best_frames; # Returns the frames 
                            # with the highest weight
  $result->get_best_frames(3); # Returns the frames
                               # with the three highest weights
  $result->get_all_frames; # Returns all resulting frames


  $result->get_best_framenames;    # Returns the names
                                   # of the highest weighted frames
  $result->get_best_framenames(3); # Returns the names of the frames
                                   # with the three highest weights
  $result->get_all_framenames;     # Returns the names of all frames.

=head1 METHODS

=over 4

=item get_frame FRAME

Returns the frame $string as a FrameNet::WordNet::Detour::Frame-object. Returns -1 if FRAME is not in the result (Pay attention on lower/upper case, we look a bit around, but that could be a hard-to-find error).

=item get_best_frames [ NUMBER ] 

Returns the frames with the highest weight (as Frame-objects). Optional: If you specify $number, the method returns the $number highest rated frames.

=item get_all_frames

Returns all found frames as Frame-objects.

=item query

Returns the query-synset as string.

=item message

Returns an eventual error message.

=item get_fees FRAME

Returns the frame evoking elements for the given frame. Returns -1 if FRAME was not in the result (Pay attention on lower/upper case, we look a bit around, but that could be a hard-to-find error).

=item get_weight FRAME

Returns the weight of the given frame. Returns -1 if FRAME was not in the result(Pay attention on lower/upper case, we look a bit around, but that could be a hard-to-find error).

=item get_weights

Returns a reference to an array of all weights that appeared in this run. The weights are sorted in descending order (normally, one is interested in the best e.g. highest values instead of the bad ones).

=item get_number_of_frames

Returns the overall number of frames found for this specific query:

  # The first variant returns all frames, because even in the worst 
  # case (that each frame has a different weight) we get all weight
  # classes. It does not matter if one specifies a number greater 
  # that the numer of existing frames, 
  # so the second variant leads normally to the same results.

  $result->get_best_frames($result->get_number_of_frames) 

  $result->get_best_frames(1000);

=item get_frames_with_weight WEIGHT

Returns a reference to a list of the frames with the given weight. You should notice, that you have to give the exact weight - e.g. like in the get_weights-array. Rounded values will not find anything.

=item new ( )

=item get_all_framenames 

Returns a list containing all frame names.

=item get_best_framenames N

Returns a list of N highest weighted names of frames.

=item get_best_weight

Returns the highest weight

=item isOK

Returns true, if the data object is sober and clean

=back

=head1 BUGS

Please report bugs to L<mailto:reiter@cpan.org>.

=head1 COPYRIGHT

Copyright 2005 Aljoscha Burchardt and Nils Reiter. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
