#!/usr/bin/perl -w
use strict;
use warnings;

use Image::Synchronize::Logger qw(log_message set_printer);
use Test::More;

my @messages1;
my @messages2;

# test multiple printers for a single logger

my $l1 = Image::Synchronize::Logger->new(
  {
    action => sub { push @messages1, join( '', @_ ) }
  }
);
$l1->set_printer(
  {
    min_level => 2,
    name      => '#2',
    action    => sub { push @messages2, join( '', @_ ) }
  }
);

$l1->log_message('no level');    # unconditional message
is_deeply( \@messages1, ['no level'], 'no level, printer 1' );
is_deeply( \@messages2, ['no level'], 'no level, printer 2' );

$l1->log_message( 1, 'level 1' );
$l1->log_message( 2, 'level 2' );
$l1->log_message( 3, 'level 3' );
is_deeply(
  \@messages1,
  [ 'no level', 'level 1', 'level 2', 'level 3' ],
  'levels 1 - 3, printer 1'
);
is_deeply(
  \@messages2,
  [ 'no level', 'level 2', 'level 3' ],
  'levels 1 - 3, printer 2'
);

# test the default logger

@messages1 = ();
@messages2 = ();

set_printer(
  {
    action => sub { push @messages1, join( '', @_ ) }
  }
);

log_message('default logger');
is_deeply( \@messages1, ['default logger'], 'default, default logger' );

# test clear_printer

@messages1 = ();
@messages2 = ();

$l1->clear_printer('');    # only printer 2 is left

$l1->log_message( 2, 'X' );
is_deeply( \@messages1, [],    'X, printer 1' );
is_deeply( \@messages2, ['X'], 'X, printer 2' );

# test bit flags

@messages1 = ();
@messages2 = ();
$l1->set_printer(
  {
    bitflags => 4,
    action   => sub { push @messages1, join( '', @_ ) }
  }
);

$l1->log_message('U')->log_message( 0, '0' )->log_message( 1, '1' )
  ->log_message( 2, '2' )->log_message( 3, '3' )->log_message( 4, '4' )
  ->log_message( 5, '5' )->log_message( 6, '6' )->log_message( 7, '7' )
  ->log_message( 8, '8' )->log_message( 9, '9' );
is_deeply( \@messages1, [ 'U', '4', '5', '6', '7' ], 'level 0 - 9, printer 1' );
is_deeply(
  \@messages2,
  [ 'U', '2', '3', '4', '5', '6', '7', '8', '9' ],
  'level 0 - 9, printer 2'
);

# test special condition

@messages1 = ();
@messages2 = ();
$l1->set_printer(
  {
    bitflags => 2,
    action   => sub { push @messages1, join( '', @_ ) }
  }
);
$l1->set_printer_condition( '', 'condition 1',
  sub { ( $_->{X} // '' ) eq 'yes' } );

$l1->log_message('U');
$l1->log_message( 1, '1 no condition' );
$l1->log_message( 1, { X => 'yes' }, '1 with condition' );
is_deeply( \@messages1, [ 'U', '1 with condition' ], 'with condition' );

done_testing();
