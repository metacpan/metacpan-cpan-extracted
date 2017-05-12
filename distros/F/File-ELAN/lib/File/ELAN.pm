package File::ELAN;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;

=head1 NAME

File::ELAN - Parsing and manipulating ELAN files

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

ELAN (http://tla.mpi.nl/tools/tla-tools/elan/) is a tool for creating annotations
on video and audio resources. This module allows you to read and manipulate the
annotation files.

    use File::ELAN;

    my $elan = File::ELAN->read("test.eaf");
    for my $annot ($elan->{annotations}{tier1}) { 
      ...
    }

    $elan->{annotations}{newtier} = [ ... ];

    $elan->write("test2.eaf");

=head1 SUBROUTINES/METHODS

=head2 read($filename)

Reads the annotations from the ELAN file into a data structure, to be found in 
the C<{annotations}> hashref. C<annotations> contains a hash of tiers, and each
tier contains an array of C<annotations>.

  my @annotations_in_this_tier = @{$elan->{annotations}{tier_i_am_interested_in}};

Each element of C<@annotations_in_this_tier> is a hashref which looks like this:

  {
    id    => "a123", # Annotation ID
    start => 12.34,   # Time value in seconds
    end   => 23.45,
    value => "Hello" # Content of annotation 
  }


=cut

use XML::LibXML;
use utf8;

sub read { 
  my ($class, $eaf) = @_;
  my $self = bless({}, $class);
  my $dom = XML::LibXML->load_xml(location => $eaf) or die "Couldn't load ELAN file $eaf: $!";
  $self->{dom} = $dom;
  $self->_read_timeslots();
  $self->_read_tiers();
  #delete $self->{timeslots};
  return $self;
}

sub _read_timeslots {
  my $self = shift;
  my $ts = $self->{dom}->find("//*/TIME_SLOT");
  $self->{timeslots} = {};
  foreach my $node ($ts->get_nodelist) {
    $self->{timeslots}{$node->getAttribute("TIME_SLOT_ID")} = $node->getAttribute("TIME_VALUE") / 1000;
  }
}
sub _trim {my $foo = shift; $foo =~ s/^\s+//gsm; $foo =~ s/\s+$//gsm; return $foo; }
sub _read_tiers {
  my $self = shift;
  my $tiers = $self->{dom}->find("//*/TIER");
  $self->{annotations} = {};
  foreach my $tier ($tiers->get_nodelist) {
    my $id = $tier->getAttribute("TIER_ID");
    $self->{annotations}{$id} = [];
    my $nl = $tier->find("*/ALIGNABLE_ANNOTATION") or die $!;
    foreach my $node ($nl->get_nodelist) { 
      push @{$self->{annotations}{$id}}, {
        id => $node->getAttribute("ANNOTATION_ID"),
        start => $self->{timeslots}{$node->getAttribute("TIME_SLOT_REF1")},
        end => $self->{timeslots}{$node->getAttribute("TIME_SLOT_REF2")},
        value => _trim($node->textContent())
      } 
    }
  }  
}

=head2 write($filename)

After fiddling with the annotations hash, you can call C<write> to write the
information back to another ELAN file. You can create new tiers, and new annotations.
You don't have to mess about with timeslots; we work all that out for you. You also
don't need to give each annotation an C<id>; one will be automatically assigned.

=cut

sub write {
  my ($self, $fn) = @_;

  # Assign timeslots to everyone
  my %timeslots;
  for my $tier (values %{$self->{annotations}}) {
    for (@$tier) {
      $timeslots{ $_->{start} * 1000 } = 1;
      $timeslots{ $_->{end} * 1000 } = 1;
    }
  }

  my $tsid = "ts1";
  for (sort {$a <=> $b} keys %timeslots) { $timeslots{$_} = $tsid++; }
  for my $tier (values %{$self->{annotations}}) {
    for (@$tier) {
      $_->{start} = $timeslots{$_->{start}*1000};
      $_->{end} = $timeslots{$_->{end}*1000};
    }
  }

  # Clean out TIME_ORDER tag and write timeslots there.
  my ($to) = $self->{dom}->find("//*/TIME_ORDER")->get_nodelist();
  $to->removeChildNodes();
  for (sort {$a <=> $b} keys %timeslots) { 
    my $node = XML::LibXML::Element->new( "TIME_SLOT" );
    $node->setAttribute("TIME_SLOT_ID", $timeslots{$_});
    $node->setAttribute("TIME_VALUE", $_);
    $to->addChild($node);
  }

  my ($lastid) = $self->{dom}->find('//*/PROPERTY[@NAME="lastUsedAnnotationId"]/text()')->get_nodelist;
  # For each tier:
  while (my ($tier_name, $annots) = each %{$self->{annotations}}) {
    my ($tier) = $self->{dom}->find("//TIER[\@TIER_ID='$tier_name']")->get_nodelist();
    if (!$tier) {
      # Add a tier tag after the last one present or after TIME_ORDER if not
      $tier = XML::LibXML::Element->new( "TIER" );
      $tier->setAttribute("TIER_ID", $tier_name);
      $tier->setAttribute("DEFAULT_LOCALE", "en");
      $tier->setAttribute("LINGUISTIC_TYPE_REF", "default-lt");
      my ($refnode) = $self->{dom}->find("(//TIME_ORDER|//TIER)[last()]")->get_nodelist();
      if (!$refnode) { die "Couldn't find anywhere to add a new tier"}
      $refnode->parentNode->insertAfter($tier, $refnode);
    }
    $tier->removeChildNodes();

    #    Dump out all the annotations into the tier tag
    for (@$annots) {
      my $aa = XML::LibXML::Element->new( "ALIGNABLE_ANNOTATION" );
      $aa->addNewChild("", "ANNOTATION_VALUE")->addChild($self->{dom}->createTextNode($_->{value}));
      $aa->setAttribute("ANNOTATION_ID", $_->{id} || "a".$lastid++);
      $aa->setAttribute("TIME_SLOT_REF1", $_->{start});
      $aa->setAttribute("TIME_SLOT_REF2", $_->{end});
      my $annot = XML::LibXML::Element->new( "ANNOTATION" );
      $annot->appendChild($aa);
      $tier->appendChild($annot);
    }
  }
  # Update last ID
  my ($lid) = $self->{dom}->find('//*/PROPERTY[@NAME="lastUsedAnnotationId"]')->get_nodelist();
  $lid->removeChildNodes();
  $lid->addChild($self->{dom}->createTextNode($lastid));

  open my $out, '>', $fn;
  binmode $out;
  $self->{dom}->toFH($out);
  close $out;

}

1;

=head1 AUTHOR

Simon Cozens, C<< <simon at simon-cozens.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-elan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-ELAN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::ELAN


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-ELAN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-ELAN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-ELAN>

=item * Search CPAN

L<http://search.cpan.org/dist/File-ELAN/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Simon Cozens.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of File::ELAN
