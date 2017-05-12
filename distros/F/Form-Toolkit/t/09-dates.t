#!perl -T
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Form::Toolkit::Form;
use Form::Toolkit::Clerk::Hash;

use Data::Dumper;

package MyFormDate;
use Moose;
extends qw/Form::Toolkit::Form/;

sub build_fields{
  my ($self) = @_;
  my $sf = $self->add_field('Date' , 'adate' );
  $self->add_field('Date', 'month')->add_role('DateTruncate' , { date_truncation => 'month' });
}

1;
package main;

my $f = MyFormDate->new();
## Test field_Set
Form::Toolkit::Clerk::Hash->new( source => { adate => '1977-10-20T05:30:01' , month => '1977-10-20T05:30:01' } )->fill_form($f);
ok( !$f->has_errors() , "Ok not errors");

ok( $f->field('adate')->value() );
ok( $f->field('month')->value() );
is( $f->field('adate')->value_struct() , '1977-10-20T05:30:01' );
is( $f->field('month')->value_struct() , '1977-10-01' );

ok( $f->field('month')->value_matches(DateTime->new( year => 1977 , month => 10 , day => 20 )), "Ok good match");
ok( $f->field('month')->value_before(DateTime->new( year => 1977 , month => 10 , day => 20 )), "Ok good before match");
ok( $f->field('month')->value_before(DateTime->new( year => 1978 , month => 10 , day => 20 )), "Ok good before match");
ok( !$f->field('month')->value_matches(DateTime->new( year => 1977 , month => 9 , day => 20 )), "Ok good non-match");
ok( !$f->field('month')->value_before(DateTime->new( year => 1977 , month => 9 , day => 20 )), "Ok good non-match on value_before");

ok( !$f->field('month')->value_matches(undef) , "Ok no match on undef");
#diag(Dumper($f->dump_errors()));
$f->clear();

is( $f->field('adate')->meta->short_class() , 'Date' , "Ok good short_class for field Integer");

# {
#   ## Test mandatory role
#   $f->field('aint')->add_role('Mandatory');
#   Form::Toolkit::Clerk::Hash->new( source => {} )->fill_form($f);
#   ok($f->has_errors() , "Ok got error, because of mandatory");
#   $f->clear();
# }

# {
#   ## Bad format
#   Form::Toolkit::Clerk::Hash->new( source => { aint => 'Boudin blanc' } )->fill_form($f);
#   ok( $f->has_errors() , "Ok got errors, because of bad format");
#   $f->clear();
# }


# {
#   ## Min
#   $f->field('aint')->add_role('MinMax')->set_min(0);
#   Form::Toolkit::Clerk::Hash->new( source => { aint => '0' } )->fill_form($f);
#   ok( ! $f->has_errors(), "Ok good");
#   $f->clear();
#   Form::Toolkit::Clerk::Hash->new( source => { aint => '-1' } )->fill_form($f);
#   ok( $f->has_errors() , "Too low");
#   $f->clear();
#   ## Set exclusive
#   $f->field('aint')->set_min(0, 'excl');
#   Form::Toolkit::Clerk::Hash->new( source => { aint => '0' } )->fill_form($f);
#   ok( $f->has_errors(), "Not good");
#   $f->clear();
# }

# {
#   ## Max
#   $f->field('aint')->add_role('MinMax')->set_max(10);
#   Form::Toolkit::Clerk::Hash->new( source => { aint => '10' } )->fill_form($f);
#   ok( ! $f->has_errors(), "Ok good");
#   $f->clear();

#   Form::Toolkit::Clerk::Hash->new( source => { aint => '11' } )->fill_form($f);
#   ok( $f->has_errors() , "Too high");
#   $f->clear();

#   ## Set exclusive
#   $f->field('aint')->set_max(10, 'excl');
#   Form::Toolkit::Clerk::Hash->new( source => { aint => '10' } )->fill_form($f);
#   ok( $f->has_errors(), "Not good");
#   $f->clear();

#   Form::Toolkit::Clerk::Hash->new( source => { aint => '9' } )->fill_form($f);
#   ok( ! $f->has_errors(), "Ok good");
#   $f->clear();

# }

done_testing();
