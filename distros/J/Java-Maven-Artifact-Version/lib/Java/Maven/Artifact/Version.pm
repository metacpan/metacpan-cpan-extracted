package Java::Maven::Artifact::Version;

use 5.008008;
use strict;
use warnings FATAL => 'all';
use Exporter;
use Scalar::Util qw/reftype/;
use Carp;

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/&version_parse &version_compare/;
=head1 NAME

Java::Maven::Artifact::Version - a perl module for comparing Artifact versions exactly like Maven does.

=head1 VERSION

Version 1.000001

see L</MAVEN VERSION COMPATIBILITY>.

=cut

our $VERSION = '1.000001';

=head1 SYNOPSIS

Note that this documentation is intended as a reference to the module.

    use Java::Maven::Artifact::Version qw/version_compare version_parse/;

    my $y = version_compare('1-alpha', '1-beta'); # $y = -1 
    my $x = version_compare('1.0', '1-0.alpha'); # $x = 0

    my $z = version_parse('1-1.2-alpha'); # $z = '(1,(1,2,alpha))' 
    my @l = version_parse('1-1.2-alpha'); # @l = (1,[1,2,'alpha'])

=head1 DESCRIPTION

L<Apache Maven|http://maven.apache.org/>  has a peculiar way to compare Artifact versions.
The aim of this module is to exactly reproduce this way in hope that it could be usefull to someone that wants to write utils like SCM hooks. It may quickly ensure an Artifact version respect a grow order without to have to install Java and Maven on the system in charge of this checking.

The official Apache document that describes it is here L<http://docs.codehaus.org/display/MAVEN/Versioning>.
But don't blindly believe everything. Take the red pill, and I show you how deep the rabbit-hole goes.
Because there is a gap between the truth coded in C<org.apache.maven.artifact.versioning.ComparableVersion.java> that can be found L<here|https://github.com/apache/maven/blob/master/maven-artifact/src/main/java/org/apache/maven/artifact/versioning/ComparableVersion.java> and that Maven official document.

Lucky for you this module cares about the real comparison differences hard coded in C<ComparableVersion> and reproduces it.

see L</FAQ> for details.

=cut

use constant {
  _ALPHA        => 'alpha',
  _BETA         => 'beta', 
  _DEBUG        => 0,
  _INTEGER_ITEM => 'integeritem',
  _LIST_ITEM    => 'listitem',
  _MILESTONE    => 'milestone',
  _NULL_ITEM    => 'nullitem',
  _RC           => 'rc',
  _SNAPSHOT     => 'snapshot',
  _SP           => 'sp',
  _STRING_ITEM  => 'stringitem',
  _UNDEF        => 'undef'
};

=head1 SUBROUTINES

=cut

# replace all following separators ('..', '--', '-.' or '.-') by .0.
# or replace leading separator by '0.'
# example : '-1..1' -> '0.1.0.1'
sub _append_zero {
  join '.',  map { $_ eq '' ? '0' : $_  } split /\-|\./, shift;
}

sub _compare_integeritem_to {
  my ($integeritem, $item, $depth) = @_;
  my $dispatch = {
    &_NULL_ITEM    => sub {
      print("comparing $integeritem to nullitem\n") if (_DEBUG); 
      $$depth++;
      $integeritem =~ m/^0+$/ ? 0 : 1;
    },
    &_LIST_ITEM    => sub {
      print("comparing $integeritem to listitem\n") if (_DEBUG); 
      1;
    },
    &_INTEGER_ITEM => sub {
      print("comparing $integeritem to $item\n") if (_DEBUG); 
      $$depth++;
      $integeritem <=> $item;
    },
    &_STRING_ITEM  => sub {
      print("comparing $integeritem to stringitem\n") if (_DEBUG); 
      1;
    }
  };
  $dispatch->{_identify_item_type($item)}->();
}

sub _compare_items {
  my ($item1, $item2, $max_depth, $depth) = @_;
  my $dispatch = {
    &_NULL_ITEM    => sub {
      print("_compare_items(nullitem, ?)\n") if (_DEBUG); 
      unless (defined($item2)) {
        $$depth++;
        return 0 ;
      }
      _compare_items($item2, undef, $depth) * -1;
    },
    &_LIST_ITEM    => sub {
      print("_compare_items(listitem, ?)\n") if (_DEBUG); 
      _compare_listitem_to($item1, $item2, $max_depth, $depth);
    },
    &_INTEGER_ITEM => sub {
      print("_compare_items(integeritem, ?)\n") if (_DEBUG);
      _compare_integeritem_to($item1, $item2, $depth);
    },
    &_STRING_ITEM  => sub {
      print("_compare_items(stringitem, ?)\n") if (_DEBUG);
      _compare_stringitem_to($item1, $item2, $depth);
    }
  };
  $dispatch->{_identify_item_type($item1)}->();
}

sub _compare_listitem_to {
  my ($listitem, $item, $max_depth, $depth) = @_;
  my $dispatch = {
    &_NULL_ITEM    => sub { _compare_listitem_to_nullitem($listitem, $max_depth, $depth) },
    &_LIST_ITEM    => sub { _compare_listitems($listitem, $item, $max_depth, $depth) },
    &_INTEGER_ITEM => sub { -1 },
    &_STRING_ITEM  => sub { 1 }
  };
  $dispatch->{_identify_item_type($item)}->();
}

sub _compare_listitem_to_nullitem {
  my ($listitem, $max_depth, $depth) = @_;
  if (not @$listitem) {
    warn("comparing listitem with empty listitem should never occur. Check your code boy...");
    0; #empty listitem (theoricaly impossible) equals null item
  } else {
    #only compare first element with null item (yes they did that...)
    _compare_items(@$listitem[0], undef, $max_depth, $depth);
  }
}

sub _compare_listitems {
  my ($list1, $list2, $max_depth, $depth) = @_;
  my @l = @$list1;
  my @r = @$list2;
  while (@l || @r) {
    last if ($max_depth && $$depth >= $max_depth);
    my $li = @l ? shift(@l) : undef;
    my $ri = @r ? shift(@r) : undef;
    my $c = defined($li) ? _compare_items($li, $ri, $max_depth, $depth) : _compare_items($ri, $li, $max_depth, $depth) * -1;
    print("depth is $$depth\n") if (_DEBUG);
    $c and return $c;
  }
  0;
}

sub _compare_stringitem_to {
  my ($stringitem, $item , $max_depth, $depth) = @_;
  my $dispatch = {
    &_NULL_ITEM    => sub { _compare_stringitem_to_stringitem($stringitem, $item, $depth) },
    &_LIST_ITEM    => sub { _compare_listitem_to($item, $stringitem, $max_depth, $depth) * -1 },
    &_INTEGER_ITEM => sub { _compare_integeritem_to($item, $stringitem, $depth) * -1 },
    &_STRING_ITEM  => sub { _compare_stringitem_to_stringitem($stringitem, $item, $depth) }
  };
  $dispatch->{_identify_item_type($item)}->();
}

sub _compare_stringitem_to_stringitem {
  my ($stringitem1, $stringitem2, $depth) = @_;
  $$depth++;
  _substitute_to_qualifier($stringitem1) cmp _substitute_to_qualifier($stringitem2);
}

sub _getref {
  my ($var) = @_;
  (ref($var) || not defined($var)) ? $var : \$var; # var may already be a ref
}

sub _identify_item_type {
  my ($item) = @_;
  my $types = {
    _UNDEF()  => sub { _NULL_ITEM }, 
    'SCALAR'  => sub { _identify_scalar_item_type($item) }, 
    'ARRAY'   => sub { _LIST_ITEM },
    _DEFAULT_ => sub { die "unable to identify item type of item $item ." }
  };
  my $t = _reftype($item);  
  print("_identify_item_type($t)\n") if (_DEBUG);
  exists $types->{$t} ? $types->{$t}->() : $types->{_DEFAULT_}->();
}

sub _identify_qualifier {
  my ($stringitem) = @_;
  return _NULL_ITEM unless defined($stringitem);
  return _ALPHA     if $stringitem =~ m/^(alpha|a\d+)$/;
  return _BETA      if $stringitem =~ m/^(beta|b\d+)$/;
  return _MILESTONE if $stringitem =~ m/^(milestone|m\d+)$/;
  return _RC        if $stringitem =~ m/^rc$/;
  return _SNAPSHOT  if $stringitem =~ m/^snapshot$/;
  return _NULL_ITEM if $stringitem =~ m/^$/;
  return _SP        if $stringitem =~ m/^sp$/;
  '_DEFAULT_';
}

sub _identify_scalar_item_type {
  my ($scalar) = @_;
  $scalar =~ m/^\d+$/ ? _INTEGER_ITEM : _STRING_ITEM;
}

sub _is_nullitem {
  my ($item) = @_;
  (not defined($item)) ? 1 : _UNDEF eq reftype(_getref($item));
}

sub _normalize {
  my ($listitems) = @_;
  my $norm_sublist;
  if (ref(@$listitems[-1]) eq 'ARRAY') {
    my $sublist = pop(@$listitems);
    $norm_sublist = _normalize($sublist);
  }
  pop(@$listitems) while (@$listitems && @$listitems[-1] =~ m/^(0+|ga|final)?$/ );
  push(@$listitems, $norm_sublist) if (defined($norm_sublist) && @$norm_sublist);
  $listitems;
}

sub _reftype {
  my ($item) = @_;
  _is_nullitem($item) ? _UNDEF : reftype(_getref($item));
}

sub _replace_alias {
  my ($string) = @_;
  if ($string eq '') {
    return 0;
  } elsif ($string =~ m/^(ga|final)$/) {
    return '';
  } elsif ($string eq 'cr') {
    return 'rc';
  }
  $string;
}

sub _replace_special_aliases {
  my ($string) = @_;
  $string =~ s/((?:^)|(?:\.|\-))a(\d)/$1alpha.$2/g; # a1 = alpha.1
  $string =~ s/((?:^)|(?:\.|\-))b(\d)/$1beta.$2/g; # b11 = beta.11
  $string =~ s/((?:^)|(?:\.|\-))m(\d)/$1milestone.$2/g; # m7 = milestone.7
  $string;
}

# split 'xxx12' to ['xxx',12] and vice versa
sub _split_hybrid_items {
  my ($string) = @_;
  $string =~ s/(\D)(\d)/$1.$2/g;
  $string =~ s/(\d)(\D)/$1.$2/g;
  split /\./, $string;
}

# _split_to_items must only be called when version has been splitted into listitems
# Then it works only on a single listitem
sub _split_to_items {
  my ($string) = @_;
  my @items = ();
  my @tonormalize = _split_to_to_normalize($string);
  #at this time we must replace aliases with their values 
  my $closure = sub {
    my ($i) = shift;
    $i = _append_zero($i);
    $i = _replace_special_aliases($i); #must be replaced BEFORE items splitting
    my @xs = split(/\-|\./, $i);
    @xs = map({ _replace_alias($_) } @xs); #must be replaced after items splitting
    @xs = map({ $_ !~ /^\s*$/ ? _split_hybrid_items($_) : $_ } @xs); 
    push(@items, @{_normalize(\@xs)} );
  };
  map { $closure->($_) } @tonormalize;
  @items;
}

sub _split_to_lists {
  my ($string, @items) = @_;
  #listitems are created every encountered dash when there are a digits in front and after it
  if (my ($a, $b) =  ($string =~ m/(.*?\d)\-(\d.*)/)) {
    push(@items, _split_to_items($a), _split_to_lists($b, ()));
  } else { 
    push(@items, _split_to_items($string));
  }
  \@items;
}

#_normalize must be called each time a digit is followed by a dash
sub _split_to_to_normalize {
  my ($string) = @_;
  $string =~ s#(\d)\-#$1</version>#g; # use '</version>' as seperator because it cannot be a part of an artifact version...
  split('</version>', $string);
}

sub _substitute_to_qualifier {
  my ($stringitem) = @_;
  my $qualifier_cmp_values = {
    &_ALPHA     => '0',
    &_BETA      => '1',
    &_MILESTONE => '2',
    &_RC        => '3',
    &_SNAPSHOT  => '4',
    &_NULL_ITEM => '5',
    &_SP        => '6',
    _DEFAULT_  => $stringitem ? "7-$stringitem" : '7-' #yes they really did that in ComparableVersion...
  };
  $qualifier_cmp_values->{_identify_qualifier($stringitem)};
}


sub _to_normalized_string {
  my ($items) = @_;
  my $s = '(';
  my $append = sub {
    my ($i) = shift; 
    ref($i) eq 'ARRAY' ? $s .= _to_normalized_string($i) : ($s .= "$i");
    $s .= ',';
  };
  map { $append->($_) } @$items ;
  chop($s) if (length($s) > 1);
  $s .= ')';
}

=head2 version_compare

By default C<version_compare> compares a version string to another one exactly like Maven does.

See L<http://docs.codehaus.org/display/MAVEN/Versioning> for general comparison description, and L</DESCRIPTION> for more details about mechanisms not described in that official Maven doc but occur during Maven Artifact versions comparison in Java.

This function will return :

=over 4

=item * C<0> if versions compared are equal

=item * C<1> if version is greater than version that is compared to

=item * C<-1> if version is lower than version that is compared to

=back 

    $v = version_compare('1.0', '1.1'); # $v = -1

C<version_compare> can go further. You can set C<max_depth> to stop comparison before the whole version comparison has processed.

Suppose you have to code SCM hook which enforce that pushed artifact source must always begin by the same two version items and new version must be greater than the old one.

    my ($old, $new) = ('1.1.12', '1.1.13');
    my $common = version_compare($old, $new, 2); # returns 0 here
    die "you did not respect the version policy" if $common; 
    die "you must increment artifact version" if version_compare($old, $new) >= 0;

Note that C<max_depth> cares about sub C<listitems>.
  
    $v = '1-1.0.sp; # normalized to (1,(1,0,'sp'))
    $o = '1-1-SNAPSHOT'; # normalized to (1,(1,'SNAPSHOT'))
    $x = version_compare($v, $o, 3); # will compare '0' to 'SNAPSHOT' and will return 1

Of course understand that this computation is done B<after> normalization.
    
    $x = version_compare('1-1.0-1-ga-0-1.2', '1-1.0-1-ga-0-1.3', 4); #only last item will be ignored during this comparison
    #                     ^ ^   ^      ^      ^ ^   ^      ^

Note that set negative C<max_depth> will always return 0, because no comparison will be done at all

    $x = version_compare(1, 2, -1); # $x = 0

=cut

sub version_compare {
  my ($v1, $v2, $max_depth) = @_;
  return unless defined($v1) || defined($v2);
  $max_depth = defined $max_depth ? $max_depth : 0;
  my $depth = 0;
  my @listitem1 = version_parse($v1);
  my @listitem2 = version_parse($v2);
  _compare_listitems(\@listitem1, \@listitem2, $max_depth, \$depth);
}

=head2 version_parse

will return normalized version representation (see L</"Normalization">).

In B<scalar context>, it will return string representation :

    $s = version_parse('1.0-final-1'); # $s = '(1,(,1))'

You would have the same string if you had call C<org.apache.maven.artifact.versioning.ComparableVersion.ListItem.toString()> private method of C<org.apache.maven.artifact.versioning.ComparableVersion.java> on the main C<ListItem>.

In B<list context>, it will return the data structure representation :

    @l = version_parse('1.0-final-1'); # [1,['',1]]

=cut

sub version_parse {
  my ($v) = @_;
  return unless defined wantarray;
  my $listitem = _normalize(_split_to_lists(lc($v), ()));
  wantarray ? @$listitem : _to_normalized_string($listitem);
}

=head1 FAQ

=head2 What are differences between actual Maven comparison algo and that described in the official Maven doc ?

=head3 zero appending on blank separator 

zero ('C<0>') will be appended on each blank separator char (dot '.' or dash '-')
During parsing if separator char is encountered and it was not preceded by C<stringitem> or C<listitem>, zero char ('C<0>') is automatically appended.
Then version that begins with separator is automatically prefixed by zero.

'C<-1>' will be internally moved to 'C<0-1>'.

'C<1....1>' will be internally moved to 'C<1.0.0.0.1>'.

=head3 The dash separator "B<->" 

The dash separator "B<->" will create C<listitem> only if it is preceeded by an C<integeritem> and it is followed by digit.

Then when they say C<1-alpha10-SNAPSHOT =E<gt> [1,["alpha",10,["SNAPSHOT"]]]> understand that it's wrong. 

C<1-alpha10-SNAPSHOT> is internally represented by C<[1,"alpha",10,"SNAPSHOT"]>. Which has a fully different comparison behavior because no sub C<listitem> is created.

Please note that L</zero appending on blank separator> has been done B<after> C<listitem> splitting. 

Then understand that 'C<-1--1>' will B<NOT> be internally represented by 'C<(0,(1,(0,(1))>', but by 'C<(0,1,0,1)>'.


=head3 Normalization

Normalization is one of the most important part of version comparison but it is not described at all in the official Maven document.
So what is I<normalization> ?
It's kind of reducing version components function.
Its aim is to shoot useless version components in artifact version. To simplify it, understand that C<1.0> must be internally represented by C<1> during comparison.
But I<normalization> appends in specific times during artifact version parsing.

It appends:

=over 4

=item 1. each time a dash 'C<->' separator is preceded by digit but B<before> any alias substitution (except when any of these digits is a L<zero appended|/zero appending on blank separator>, because C<listitem> splitting is done before 'zero appending').


=item 2. at the end of each parsed C<listitem>, then B<after> all alias substitution

=back

And I<normalization> process current parsed C<listitem> from current position when normalization is called, back to the beginning of this current C<listitem>.

Each encountered C<nullitem> will be shot until a non C<nullitem> is encountered or until the begining of this C<listitem> is reached if all its items are C<nullitems>. 
In this last case precisely, the empty C<listitem> will be shot except if it is the main one.

Then understand that :

=over 4

=item * C<1.0.alpha.0> becomes C<(1,0,alpha)> #because when main C<listitem> parsing has ended, I<normalization> has been called. Last item was 0, 0 is the C<nullitem> of C<integeritem>, then it has been shooted. Next last item was C<alpha> that is not C<nullitem> then normalization process stopped.

=item * C<1.0-final-1> becomes C<(1,,1)> #because a dash has been encoutered during parsing. Then normalization has been called because it was preceded by a digit and last item in the current C<listitem> is 0. Then it has been shot. C<final> has been substituted by C<''> but when next normalization has been called, at the end of the parsing, the last item was not C<nullitem>, then normalization did not meet C<''>.

=item * C<0.0.ga> becomes C<()> # because 'ga' has been substituted by C<''> and when C<listitem> has been normalized at the end, all items where C<nullitem>s

=item * C<final-0.1 becomes> (,0,1) # because normalization has not been called after first dash because it was not been preceded by digit.

=back

If you told me I<WTF ?>, I would answer I am not responsible of drug consumption...

In C<org.apache.maven.artifact.versioning.ComparableVersion.java>, the representation of normalized version is only displayable with the call of C<org.apache.maven.artifact.versioning.ComparableVersion.ListItem.toString()> private method on the main C<ListItem>.

Comma "C<,>" is used as items separator, and enclosing braces are used to represent C<ListItem>.

For example:
   in Java world C<org.apache.maven.artifact.versioning.ComparableVersion.ListItem.toString()> on C<"1-0.1"> gives C<"(1,(0,1))">.

L</version_parse> function reproduces this algo for the whole set C<Java::Maven::Artifact::Version>.

    $v = version_parse('1-0.1'); # $v = '(1,(O,1))'

=head3 listitem and nullitem comparison

It is not very clear in the official Maven doc.

Comparing C<listitem> with C<nullitem> will just compare first C<item> of the C<listitem> with C<nullitem>.

=head1 MAVEN VERSION COMPATIBILITY

This version is fully compatible with the C<org.apache.maven.artifact.versioning.ComparableVersion.java> algo of C<org.apache.maven:maven-artifact> embedded with : 

=over 4

=item * Maven 3.2.3

=item * Maven 3.2.2

=back

All L<Test::More|http://search.cpan.org/~exodist/Test-Simple-1.001003/lib/Test/More.pm> tests are also available with Java Junit tests to ensure comparison results are similars.

See L</SOURCE> if you want to check them.

I will do my best to check the Maven compatibility on each Maven new release.

=head1 AUTHOR

Thomas Cazali, C<< <pandragon at cpan.org> >>

=head1 SOURCE

The source code repository for C<Java::Maven::Artifact::Version> can be found at L<https://github.com/apendragon/Java-Maven-Artifact-Version/>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/apendragon/Java-Maven-Artifact-Version/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Java::Maven::Artifact::Version


You can also look for information at:

L<https://github.com/apendragon/Java-Maven-Artifact-Version/wiki>

=over 4

=item * github repository issues tracker (report bugs here)

L<https://github.com/apendragon/Java-Maven-Artifact-Version/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Java-Maven-Artifact-Version>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Java-Maven-Artifact-Version>

=item * Search CPAN

L<http://search.cpan.org/dist/Java-Maven-Artifact-Version/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Thomas Cazali.

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

1; # End of Java::Maven::Artifact::Version
