package Mac::PropertyListFilter;

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK $VERSION);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw( xml_filter );
$VERSION = '0.02';

sub xml_filter {
  my ($href,$filter) = @_;
  my $output;
  if($href->{type} eq 'dict') {
    for(keys %{$href->{value}}) {
      $output->{$_} = xml_filter($href->{value}{$_},$filter);
    }
  }
  elsif($href->{type} eq 'array') {
    for(@{$href->{value}}) {
      push @$output,xml_filter($_,$filter);
    }
  }
  else { # Non-structural types
    $output = $href->{value};
  }
  for(@$filter) {
    my $transformed = $_->($output);
    $output = $transformed if $transformed and $transformed ne '';
  }
  return $output;
}

1;

__END__

=head1 NAME

Mac::PropertyListFilter - Transform XML Property lists into data structure.

=head1 SYNOPSIS

  use Mac::PropertyList;
  use Mac::PropertyListFilter qw(xml_filter);
  $data = Mac::PropertyList::parse_plist($string);
  $funcref = [
    #
    # Transform { a=>1,w=>0.6 } to [1,0.6]
    #
    sub {
      my $color = shift;
      if(ref($color) eq 'HASH' and
         defined $color->{a} and
         defined $color->{w}) {
      }
    }
  ];
  $new_data = xml_filter($data,$funcref);

=head1 DESCRIPTION

The filter transforms the output of parse_plist() to a more sensible form.
Generally, C<type => 'dict', value => { }> gets transformed to a simple hashref,
C<type => 'array', value => [ ]> gets transformed to an array ref. This
transformation B<will> lose data, specifically it retains no type information
from the original XML. C<type => 'real'> gets lost in the shuffle, however
this may not be useful to your application, or even misleading.

OmniGraffle 2.0, for instance, uses a B<string> type to represent points,
booleans and rectangles. In addition to reshaping the output in this fashion,
this lets you transform hashrefs into arrayrefs.

The second parameter to xml_filter() is an arrayref of references to functions.
The functions get called in order on every hash and array reference, and
element, depth-first. If the function returns any data, it replaces what was
there before.

As such, the xml_filter does not actually modify the data structure, unless
your subroutines modify data. This can be useful, especially when transforming
the OmniGraffle representation of a point C<"{32, 27}"> into something easier
to deal with, such as C<[32,27]>.

=head2 EXPORT

None by default, C<xml_parser()> on request.

=head1 SEE ALSO

L<Mac::PropertyList>, L<http://www.apple.com/DTDs/PropertyList-1.0.dtd>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
