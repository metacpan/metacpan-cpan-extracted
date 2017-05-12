package Javascript::Select::Chain::Nested;

use 5.006001;
use strict;
use warnings;

use Carp qw/confess/;
use Data::Dumper;
use FileHandle;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Javascript::Select::Chain ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
				  ) ],
		   );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ,
		   'selectchain'
		 );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';


# Preloaded methods go here.


sub header {
  my $fh = shift;
  print $fh "var hide_empty_list=true;\n\n";
}

sub validate {

  my $model = shift;

  exists $model->{listgroupname} or 
    confess "listgroupname must be supplied in model";

  exists $model->{data} or 
    confess "data must be supplied in model";


}

sub add_list_group {

  my ($fh, $model) = @_;

  my $first_list_item = (keys %{$model->{data}[0][0]})[0];
  $first_list_item = "" unless defined($first_list_item);

  print $fh sprintf 'addListGroup("%s", "%s");', 
    $model->{listgroupname},
      $first_list_item;

  print $fh "\n\n";
}

sub quoteary {
  my $ary = shift;
  my $size = shift;

  for my $elt (0..$size-2) {
    $ary->[$elt] = "" unless defined($ary->[$elt]);
    $ary->[$elt] = sprintf '"%s"', $ary->[$elt];
  }

}

my %quoteary = (addList => 5, addOption => 4);

sub addonelist {

  my ($fh, $ary, $func) = @_;

  quoteary($ary, $quoteary{$func});

  print $fh sprintf "$func(%s);\n", join ', ', @$ary;
}

sub addlistary {
  my ($fh, $data, $func) = @_;


  for my $record (@$data) {
    my ($list_name, $list_data) = each %$record;
    
    for my $list_item (@{$list_data}) {
      addonelist($fh, [ $list_name, @$list_item ], $func);
    }
  }

}

sub addlist {
  my ($fh,$data) = @_;


  for my $d (0 .. $#$data-1) {
    addlistary($fh, $data->[$d], 'addList');
  }

}

sub addoption {
  my ($fh,$data) = @_;


#  warn Dumper($data->[$#$data]);

  addlistary($fh, $data->[$#$data], 'addOption');


}




sub selectchain {
  my ($model, $config) = @_;

  validate $model ;

  my $js = $config->{js} || "_out.js";
  my $jsf = new FileHandle;
  $jsf->open("> $js") or die $!;

#  header($jsf);
  add_list_group($jsf, $model);

  addlist($jsf, $model->{data});
  addoption($jsf, $model->{data});

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Javascript::Select::Chain::Nested -  arbitrary depth DHTML select pulldowns

=head1 SYNOPSIS

# DISCOURAGED!

  use Javascript::Select::Chain::Nested;

=head1 ABSTRACT

This module does the same thing as Javascript::Select::Chain but
it expects the data structure to look a little different. I do not recommend
the use of this module because it is actually harder to generate the
intricately nested structures that it requires as opposed to the flat and 
simple ones used by J::S::C.

I don't recommend that you use this module, but it is here as proof of concept
of TMTOWTDI.

=head1 DESCRIPTION

There is less redundancy in way of describing the chain of selects,
but I actually found it harder to generate from database queries.
Personally, I only use the "flat" data structure described in 
L<Javascript::Select::Chain>.

=head2 selectchain( $model , $options )

C<selectchain()> takes two arguments. C<$model> is a hash reference
with two keys, C<data> and C<listgroupname>. The value of the key
C<listgroupname> is exactly what is referred to in the original
docs. See C<Car2.pm> in the distribution for a sample usage. The value
of the key C<data> is an array reference in which each element
completely represents one pulldown in the chain. Summarily, here is
C<$model> at the highest level:

  {
   data          =>  [ $level1, $level2, $level3 ],
   listgroupname => $listgroupname                  # e.g., 'vehicles'
  }

Now, we go into how each level looks. In words, each level is an array
reference in which each element is a hash reference. Said hash
reference has a key which is the first-list-name or second-list-name
or whatever-list-name, depending on what level we are at. The value of
said key is an array reference of C<$list_item>, where C<$list_item>
is 

   [  $option_text, $option_value => $next_list_name ]

Here is a sample level, completely described:

 my $level1 =
  [
   { 'car-makers' =>
     [
      [  "Select a maker", ""          => "dummy-list"  ],
      [  "Toyota",         "Toyota"    => "Toyota"     ],
      [  "Honda",          "Honda"     => "Honda"       ],
      [  "Chrysler",       "Chrysler"  => "Chrysler", 1  ],
      [  "Dodge",          "Dodge"     => "Dodge" ],
      [  "Ford",           "Ford"      => "Ford" ]
     ]
   }
  ] ;

NOTE WELL: even if a list item only has one element they structure
must still be maintained. For example, here is the start of a level 2
description. Note how much boilerplate was around the value to the key
C<dummy-list> even though it only had one element:

 my $level2 =
  [

   { 'dummy-list' => 
     [
      [ "Not available", "" => "dummy-sub"] 
     ] },

   { Toyota => 
     [
      ["--- Toyota vehicles ---", "" => "dummy-list" ],
      [ "Cars",    "car",            => "Toyota-Cars"            ],
      [ "SUVs/Van", "suv",           => "Toyota-SUVs/Van"  ],
      [ "Trucks", "truck",           => "Toyota-Trucks", 1 ]
     ]
   },
  ...

C<Car2.pm> in the distro contains a complete example to generate the 
3-level hierarchy shown at www.xyscripts.com.


=head2 EXPORT

None by default. C<selectchain> can be exported.





=head1 SEE ALSO

=over 4

=item * http://www.yxscripts.com/cs/chainedselects.html

=item * http://www.dynamicdrive.com

=item * http://www.quirksmode.org/

=item * http://www.javascipts.com

=cut

=head1 TODO

=over 4

=item * must insure that lists have size to avoid err

=item * test flat version

=cut

=head1 AUTHOR

Terrence Brannon, E<lt>tbone@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Terrence Brannon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
