package Javascript::Select::Chain;

use 5.006001;
use strict;
use warnings;

use Carp qw/confess/;
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

our $VERSION = '1.3';


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

  $model->{data}[0][0][0] = "" unless defined($model->{data}[0][0][0]);

  print $fh sprintf 'addListGroup("%s", "%s");', 
    $model->{listgroupname},
      $model->{data}[0][0][0];

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
    addonelist($fh,$record, $func);
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

  use Data::Dumper;
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

Javascript::Select::Chain - generate arbitrary depth DHTML select pulldowns

=head1 ABSTRACT

This Perl package makes it easy to generate a series of pulldowns
whose content is a function of the selection in the previous pulldown.
It is a Perl API to a Javascript package written by Xin Yang.
His Javascript package is included, but you can consult his website
for information beyond this documentation:

    http://www.yxscripts.com/

=head1 DESCRIPTION

It would really help to read over the docs at:

    http://www.yxscripts.com/cs/chainedselects.html

If you read this, then you will have the concepts and vocabulary 
necessary to understand and use this Perl wrapper to his library.

However, I will do my best to explain everything you need to know here.


=head2 selectchain( $model , $options )

C<selectchain()> takes two arguments. C<$model> is a hash reference
with two keys, C<data> and C<listgroupname>. The value of the key
C<listgroupname> is exactly what is referred to in the original
docs. See C<Car1.pm> in the distribution for a sample usage. The value
of the key C<data> is an array reference in which each element
completely represents one pulldown in the chain. Summarily, here is
C<$model> at the highest level:

  {
   data          =>  [ $level1, $level2, $level3 ],
   listgroupname => $listgroupname                  # e.g., 'vehicles'
  }

Now, we go into how C<$level1>, C<$level2>, ... C<$levelN> looks. In
words, each level is an array reference in which each element is an
array reference. The "inner" array reference looks like this:

   [  $list_name, $option_text, $option_value => $next_list_name ]

There is also a final optional argument which indicates that this item
in the pulldown is the default selected one.

Here is a sample level, completely described:

 my $level1 =
  [
   [ "car-makers", "Select a maker", "",         "dummy-list"  ],
   [ "car-makers", "Toyota",         "Toyota",   "Toyota"       ],
   [ "car-makers", "Honda",          "Honda",    "Honda"        ],
   [ "car-makers", "Chrysler",       "Chrysler", "Chrysler", 1  ],
   [ "car-makers", "Dodge",          "Dodge",    "Dodge" ],
   [ "car-makers", "Ford",           "Ford",     "Ford" ]
  ];


C<Car1.pm> in the distro contains a complete example which generates the
3-level hierarchy shown at www.xyscripts.com.


=head2 EXPORT

None by default, C<selectchain> can be exported on request.

=head1 SEE ALSO

  http://www.yxscripts.com

=head1 AUTHOR

Terrence Brannon, E<lt>tbone@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Terrence Brannon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
