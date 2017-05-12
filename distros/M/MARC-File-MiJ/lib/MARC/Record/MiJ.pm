package MARC::Record::MiJ;
use ex::monkeypatched;
use JSON;
use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

MARC::Record::MiJ - Convert MARC::Record to/from marc-in-json structure

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  use MARC::Record;
  use MARC::Record::MIJ

  my $str = get_marc_in_json_from_somewhere;

  # The most common use will be to use methods monkeypatched into MARC::Record
  my $r = MARC::Record->new_from_mij($str);
  my $json = $r->to_mij;

  # You can also work with the underlying hash/array structure if you're dealing with
  # json serialization/deserialization on your own

  my $mij_structure = $r->to_mij_structure;
  my $r = MARC::Record->new_from_mij_structure($mij_structure);

  # You can also call things on MARC::Record::MiJ

  my $r = MARC::Record::MiJ->new($str);
  my $json = MARC::Record::MiJ->to_mij($r);
  my $mij_structure = MARC::Record::MiJ->to_mij_structure($r);
  my $r = MARC::Record::MiJ->new_from_mij_structure($mij_structure);

=head1 DESCRIPTION

Reads and writes MARC-in-JSON structures and strings as supported by pymarc/ruby-marc/marc4j and
described at http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/

Don't confuse with another (incompatible) JSON encoding in the module C<MARC::File::JSON>, which
to the best of my knowledge isn't supported by other readers/writers.

For reading, you probably don't need to use this directly; take a look at C<MARC::File::MiJ> for reading in 
newline-delimited marc-in-json files by itself or in conjunction with C<MARC::Batch>.

The MARC::Record distribution doesn't so much do do writing out files. You can do something like this:

    # convert file from marc binary to marc-in-json
    use MARC::Batch;
    use MARC::Record::MiJ;
    my $batch = MARC::Batch->new('USMARC', 'file.mrc');
    open(my $jsonfile, '>', 'file.ndj' );
    while (my $r = $batch->next) {
      print $jsonfile MARC::Record::MiJ->to_mij($r), "\n";
    }
    close $jsonfile;

...to produce newline-delimited marc-in-json from a binary file.


=head1 SUBROUTINES/METHODS

=head2 json

Get a json object to work with (memoized). We want to control it so we make sure 
it's not doing anything pretty (like, say, putting newlines in, which woudl make it
harder to produce newline-delimited json file).

=cut

my $json;
sub json {
  return $json if ($json);
  my $self = shift;
  $json =  JSON->new->utf8;
  $json->pretty(0);
  return $json;
}


=head2 new($str)

Take a JSON string and turn it into a MARC::Record object

=cut

sub new {
  my $self = shift;
  my $str = shift;
  return $self->new_from_mij_structure($self->json->decode($str));
}

=head2 to_mij($r)

Take a record; return a JSON string

=cut

sub to_mij {
  my $self = shift;
  my $r = shift;
  return $self->json->encode($self->to_mij_structure($r));
}



=head2 MARC::Record::JSON->to_mij_structure($r)

Turn a record into a marc-in-json compatible hash; return the hash pointer

=cut

sub to_mij_structure {
  my $class = shift;
  my $r = shift;
  
  my $h = {};
  my @fields;
  $h->{leader} = $r->leader;
  
  foreach my $f ($r->fields) {
    if ($f->is_control_field) {
      push @fields, controlfield_to_mij_structure($f);
    } else {
      push @fields, valuefield_to_mij_structure($f);
    }
  }
  $h->{fields} = \@fields;
  return $h;
}


=head2 controlfield_to_mij_structure($field)

Turn a MARC::Record controlfield into an appropriate hash

=cut

sub controlfield_to_mij_structure {
  my $cf = shift;
  return {$cf->tag => $cf->data };
}

=head2 valuefield_to_mij_structure($field)

Turn a MARC::Record valuefield into an appropriate hash


=cut

sub valuefield_to_mij_structure {
  my $vf = shift;
  my @subfields;
  my $h = {ind1=>$vf->indicator(1), ind2=>$vf->indicator(2)};
  foreach my $sf ($vf->subfields) {
    push @subfields, subfield_to_mij_structure($sf);
  }
  $h->{subfields} = \@subfields;
  return {$vf->tag => $h};
  
}

=head2 subfield_to_mij_structure($sf) 

Turn a MARC::Record subfield pair (arrayref duple of code/value) into an appropriate hash


=cut

sub subfield_to_mij_structure {
  my $sf = shift;
  return {$sf->[0]=> $sf->[1]};
}


=head2 my $r =  MARC::Record::JSON->new_from_mij_structure($mij_structure)

Given a marc-in-json structure, return a MARC::Record object

=cut

sub new_from_mij_structure {
  my $self = shift;
  my $h = shift;
  
  my $r = new MARC::Record;
  
  $r->leader($h->{leader});
  
  my @fields;
  foreach my $f (@{$h->{fields}}) {
    push @fields, new_field_from_mij_structure($f);
  }
  $r->append_fields(@fields);
  return $r; 
}

=head2 new_field_from_mij_structure($f)

Given a field structure, create an appropriate (control or variable) field

=cut

sub new_field_from_mij_structure {
  my $mijf = shift;
  my ($tag, $h);


  while (my ($k, $v) = each(%$mijf)) {
    $tag = $k;
    $h = $v;
  }
  
  if (ref($h)) { # if it's a hashref
    return new_datafield_from_mij_structure($tag, $h);
  } else { # create and return a control field
    return MARC::Field->new($tag, $h);
  }

}

=head2 new_datafield_from_mij_structure

Support for new_field_from_mij_structure; do the more complex work
of creating a datafield

=cut

sub new_datafield_from_mij_structure {
  my ($tag, $h) = @_;
  my @subfields;
  foreach my $sf (@{$h->{subfields}}) {
    while (my ($code, $data) = each %$sf) {
      push @subfields, $code, $data
    }
  }
  return MARC::Field->new($tag, $h->{ind1}, $h->{ind2}, @subfields);

}

=head1 Monkeypatching MARC::Record

Add C<new_from_mij_structure($mij_structure) and C<to_mij_structure()> to MARC::Record

  my $r = MARC::Record->new_from_mij_structure($mij_structure);
  $mij_structure = $r->to_mij_structure;

=cut

ex::monkeypatched->inject('MARC::Record' =>
  new_from_mij_structure => sub { my $class = shift; my $mij = shift; return 
    MARC::Record::MiJ->new_from_mij_structure($mij)},
  to_mij_structure => sub { my $self = shift; return  MARC::Record::MiJ->to_mij_structure($self) },
  new_from_mij => sub { my $class = shift; my $mij = shift; return MARC::Record::MiJ->new($mij) },
  to_mij => sub { my $self = shift; return MARC::Record::MiJ->to_mij($self) }
  
);



=head1 AUTHOR

Bill Dueber, C<< <dueberb at umich.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-MARC-File-MiJ at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MARC-File-MiJ>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MARC::Record::MiJ


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MARC-File-MiJ>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MARC-File-MiJ>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MARC-File-MiJ>

=item * Search CPAN

L<http://search.cpan.org/dist/MARC-File-MiJ/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Bill Dueber.

This software is free software and may be distributed under the same
terms as Perl itself.


=cut

1; # End of MARC::Record::MiJ
