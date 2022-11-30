# -*- Perl -*-
#
# Ultima Ratio Coquorum

package Food::Ratio 0.01;
use Object::Pad 0.52;
class Food::Ratio :strict(params);
use Carp 'croak';
use List::UtilsBy 'nsort_by';
use Scalar::Util 'looks_like_number';

use constant {
    MASS   => 0,    # array index for $things, $groups, $total
    NAME   => 1,
    GROUPS => 2,
    ORDER  => 3,
    RATIO  => 4,
};
has $things :reader;        # individual ingredients (aref of aref)
has $groups :reader;        # groups of ingredients (href of aref)
has $total  :reader;        # (aref)

has $key :reader;           # ratio key ingredient, group, or total

has $index_group = 0;       # to keep the output in input addition order

ADJUST {
    $groups = {};
    $things = [];
    $total = [];
}

method add($mass, $name, @rest) {
    croak "mass must be positive"
      unless defined $mass
      and looks_like_number($mass)
      and $mass > 0;
    croak "things must be something" unless defined $name and length $name;
    for my $grname (@rest) {
        croak "groups must be something" unless defined $grname and length $grname;
    }
    # hopefully after here nothing blows up that might leave the object
    # in an inconsistent state
    my @meta;
    @meta[ MASS, NAME, GROUPS, RATIO ] = ( $mass, $name, @rest ? \@rest : [], 0 );
    push @$things, \@meta;
    for my $grname (@rest) {
        my $gmeta = $groups->{$grname} //= [];
        $gmeta->@[ NAME, RATIO ] = ( $grname, 0 );
        $gmeta->[MASS] += $mass;
        $gmeta->[ORDER] = $index_group++ unless defined $gmeta->[ORDER];
    }
    $total->[MASS] += $mass;
    return $self;
}

method details() {
    croak "ratio has not been called" unless defined $key;
    my %details;
    for my $ref (@$things) {
        push $details{ingredients}->@*, {
            groups => [ $ref->[GROUPS]->@* ],
            mass => $ref->[MASS],
            name => $ref->[NAME],
            ratio => $ref->[RATIO],
        }
    }
    for my $ref (nsort_by { $_->[ORDER] } values %$groups) {
        push $details{groups}->@*, {
            mass => $ref->[MASS],
            name => $ref->[NAME],
            order => $ref->[ORDER],
            ratio => $ref->[RATIO],
        }
    }
    $details{total} = {
        mass => $total->[MASS],
        ratio => $total->[RATIO],
    };
    return \%details;
}

# the ratio could be based on the total amount, or for cooking there is
# more likely some key ingredient--flour--or a group of ingredients,
# such as a variety of flours that together form the total for the ratio
method ratio(%param) {
    my $amount;
    if ( exists $param{id} ) {
        croak "id must be something"
          unless defined $param{id} and length $param{id};
        # NOTE only the first match is used if there are duplicates in
        # the ingredients list
        my $okay = 0;
        for my $ref (@$things) {
            if ( $ref->[NAME] eq $param{id} ) {
                ( $key, $amount ) = ( $ref, $ref->[MASS] );
                $okay = 1;
                last;
            }
        }
        croak "no such id '$param{id}'" unless $okay;
    } elsif ( exists $param{group} ) {
        croak "group must be something"
          unless defined $param{group} and length $param{group};
        croak "no such group '$param{group}'" unless exists $groups->{ $param{group} };
        $key    = $groups->{ $param{group} };
        $amount = $key->[MASS];
    } else {
        $key = $total;
        $amount = $total->[MASS];
    }
    for my $ref ( @$things, values %$groups, $total ) {
        $ref->[RATIO] = $ref->[MASS] * 100 / $amount;
    }
    return $self;
}

method string() {
    croak "ratio has not been called" unless defined $key;
    my $s = '';
    for my $ref (@$things) {
        $s .= join( "\t",
            sprintf( "%.4g\t%.4g%%", $ref->@[MASS, RATIO] ),
            $ref->[NAME], $ref->[GROUPS]->@* )
          . "\n";
    }
    if ( keys %$groups ) {
        $s .= "--\n";
        for my $ref ( nsort_by { $_->[ORDER] } values %$groups ) {
            $s .=
              join( "\t", sprintf( "%.4g\t%.4g%%", $ref->@[MASS, RATIO] ), $ref->[NAME] )
              . "\n";
        }
    }
    $s .= "--\n";
    $s .= join "\t", $total->[MASS], sprintf( '%.4g%%', $total->[RATIO] ),
      "*total\n";
    return $s;
}

method weigh($mass, %param) {
    croak "ratio has not been called" unless defined $key;
    croak "mass must be positive"
      unless defined $mass
      and looks_like_number($mass)
      and $mass > 0;
    my $ratio;
    if ( exists $param{id} ) {
        croak "id must be something"
          unless defined $param{id} and length $param{id};
        # NOTE only the first match is used if there are duplicates in
        # the ingredients list
        my $okay = 0;
        for my $ref (@$things) {
            if ( $ref->[NAME] eq $param{id} ) {
                $ratio = $mass / $ref->[MASS];
                $okay = 1;
                last;
            }
        }
        croak "no such id '$param{id}'" unless $okay;
    } elsif ( exists $param{group} ) {
        croak "group must be something"
          unless defined $param{group} and length $param{group};
        croak "no such group '$param{group}'" unless exists $groups->{ $param{group} };
        $ratio = $mass / $groups->{ $param{group} }->[MASS];
    } else {
        $ratio = $mass / $total->[MASS];
    }
    for my $ref ( @$things, values %$groups, $total ) {
        $ref->[MASS] *= $ratio;
    }
    return $self;
}

1;
__END__

=head1 NAME

Food::Ratio - calculate ingredient ratios

=head1 SYNOPSIS

  use Food::Ratio;
  my $fr = Food::Ratio->new;

  # add some ingredients of various amounts
  $fr->add( 500,  'flour' );
  $fr->add( 360,  'water' );    # at 90F to 95F
  $fr->add( 11.5, 'salt'  );
  $fr->add( 2,    'yeast' );

  # make flour the basis for the ratio
  $fr->ratio( id => 'flour' );

  # emit to a string form
  print $fr->string;
  # 500   100.00% flour
  # 360   72.00%  water
  # 11.5  2.30%   salt
  # 2     0.40%   yeast
  # --
  # 873.5 174.7%  *total

  # how much of the other are required given 9 grams of yeast?
  $fr->weigh( 9, id => 'yeast' );

  # emit to a data structure that could be converted to JSON
  use Data::Dumper;
  print Dumper $fr->details;

The observant may notice that the water and salt are a bit off from the
normal bread recipe. This is easier to see in ratio form.

=head1 DESCRIPTION

This module calculates ratios of ingredients, with the ability to select
what ingredient or group of ingredients the ratio is based on. With a
ratio, the masses of the ingredients can then be adjusted with B<weigh>,
which can be of any particular ingredient or group of ingredients.

=head1 METHODS

=over 4

=item B<add> I<mass> I<name> [ I<groups> .. ]

Adds the given amount of the given ingredient. The I<mass> probably
should be consistent across the ingredients; grams might be a good
choice. The I<mass> could instead be volumes, provided that the units
are consistent.

The optional I<groups> indicate what groups the ingredient belongs to,
for example

  $fr->add( 160, 'cornmeal', 'gflour', 'dry' );
  $fr->add( 150, 'flour',    'gflour', 'dry' );
  $fr->add( 3.5, 'salt',               'dry' );
  ...

when there are multiple types of flour, and one wants to base the ratio
on the I<group> gflour, not the ingredient flour. The group could be
named "flour"; it is named "gflour" here for clarity of documentation.

=item B<details>

Returns a hash reference of the internal details. Must be called after
B<ratio>, and ideally after a few B<add> calls. L<Data::Dumper> will
show the form of the resulting structure.

=item B<new>

Constructor.

=item B<ratio> I<param>

Calculates the ratios for the ingredients and any ingredient groups.
Must be called after B<add> has been used to add things to the object.
There are three possible ways to select the key ingredient for the basis
of the ratio:

  $fr->ratio;                        # $total is used
  $fr->ratio( id    => 'flour' );    # use the first 'flour' ingredient
  $fr->ratio( group => 'gflour' );   # the group 'gflour' is used

The I<id> argument takes priority over I<group> which in turn takes
priority over the ratio being based on the total mass of the ingredients
involved. Ingredients may be duplicated in the list; in this case, the
first matching ingredient is used, in the order the ingredients were
added with the B<add> method.

B<ratio> must be called before using various output methods.

A new ratio can be calculated by calling B<ratio> again; the ratios
stick around in the object.

=item B<string>

Returns a string form of the ingredients and groups. The form depends on
whether B<ratio> has been called.

B<ratio> (and probably some B<add> calls) must be called before calling
this method.

=item B<weigh> I<mass> I<param>

Updates the mass for all the ingredients and ingredient groups based
on the new I<mass> that optionally may be associated by I<id> or
I<group> to a particular ingredient or ingredient group, as also
supported by B<ratio>.

A typical use for this would be to adjust a recipe based on the weight
of the egg you have, given that some fraction of flour is easier to
weigh instead of breaking out the fractional eggs.

  $fr->weigh( 53, id => 'egg' );

This updates the mass of all the ingredients, etc, in the object.

=back

=head1 ACCESSORS

The data returned by these probably should not be fiddled with. On the
other hand, the internal details are unlikely to change. I assume you
know your way around L<Data::Dumper>. The B<details> method is probably
a better way to get at this data?

=over 4

=item B<amount>

After B<ratio> has been called contains the amount of the B<total>
or key ingredient or ingredient group, depending on how B<ratio>
was called. Is C<0> if B<ratio> has not been called.

=item B<groups>

Hash reference of any optional ingredient groups.

=item B<key>

After B<ratio> has been called, maybe contains a reference to the key
ingredient or ingredient group.

=item B<things>

Array reference of the ingredients, if any.

=item B<total>

The total mass of every ingredient added.

=back

=head1 BUGS

Bugs are commonly present in flour and other ingredients.

=head1 SEE ALSO

Forkish, Ken. Flour water salt yeast: The fundamentals of artisan bread and pizza. Random House Digital, Inc., 2012.

Ruhlman, Michael. Ratio: The simple codes behind the craft of everyday cooking. Simon and Schuster, 2009.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
