
=head1 NAME

HTML::StickyForm::RequestHash - Minimal CGI-like request object

=head1 SYNOPSIS

  my $req=HTML::StickyForm::RequestHash->new(
    key1 => 'abc',
    key1 => 'def',
    key2 => ['ghi','jkl'],
  );
  my @keys=$req->param;
  my $val1=$req->param('key1');
  my @val2=$req->param('key2');

=head1 DESCRIPTION

This class provides the minimum features required of a request object by
L<HTML::StickyForm>, for use in cases where a normal request is not available.
This might be because an empty request is needed, or where parameters are
available, but it is not appropriate to use L<CGI> or L<Apache::Request>.

=cut

package HTML::StickyForm::RequestHash;
BEGIN {
  $HTML::StickyForm::RequestHash::VERSION = '0.08';
}

use strict;
use warnings;

=head1 CLASS METHODS

=over

=item new(PAIRLIST)

Constructor. Creates a request object with the supplied list of parameters.
Multiple values for the same parameter name can be set up either by passing
multiple name/value pairs, or by passing arrayrefs for values. It is not an
error to mix these methods - all supplied values will be set in the new object.

=cut

sub new{
  my $class=shift;
  my %self;

  while(my($name,$val)=splice @_,0,2){
    my $array=$self{$name}||=[];
    if($val && ref($val) eq 'ARRAY'){
      push @$array,@$val;
    }else{
      push @$array,$val;
    }
  }

  bless \%self,$class;
}

=back

=head1 METHODS

=over

=item param()

Returns a list of the names of all configured parameters. Each name is listed
only once, regardless of how many values are configured for any given name.

=item param($name)

In scalar context, returns the first configured value for the given name.
In list context, returns all configured values for the given name.

=cut

sub param{
  my($self)=shift;
  if(my($name)=@_){
    $name='' unless defined $name;
    my $array=$self->{$name}
      or return;
    return @$array if wantarray;
    return $array->[0];
  }else{
    return keys %$self;
  }
}

=back

=cut

# Return true to require
1;


=head1 AUTHOR

Copyright (C) Institute of Physics Publishing 2005-2011

	Peter Haworth <pmh@edison.ioppublishing.com>

You may use and distribute this module according to the same terms
that Perl is distributed under.

