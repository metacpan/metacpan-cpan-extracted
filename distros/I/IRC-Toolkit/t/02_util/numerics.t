use Test::More;
use strict; use warnings FATAL => 'all';

BEGIN {
  use_ok( 'IRC::Toolkit::Numerics' );
}

# Functional:

ok( main->can('name_from_numeric'), 'name_from_numeric imported' );
ok( main->can('numeric_from_name'), 'numeric_from_name imported' );

my $name = name_from_numeric('005');
cmp_ok( $name, 'eq', 'RPL_ISUPPORT', 'name_from_numeric() ok' );

my $num = numeric_from_name('RPL_LUSEROP');
cmp_ok( $num, 'eq', '252', 'numeric_from_name() ok' );

my $numshash  = IRC::Toolkit::Numerics->export;
my $nameshash = IRC::Toolkit::Numerics->export_by_name;
cmp_ok( $numshash->keys->count, '==', $nameshash->keys->count, 
  'exported hashes have same key count'
) or do {
  my %seen;
  for my $name ($numshash->values->all) {
    if ($seen{$name}) {
      diag "DUPE: $name\n"
    }
    $seen{$name}++
  }
  BAIL_OUT("Failed")
};


## OO:
my $nobj = new_ok( 'IRC::Toolkit::Numerics' );

cmp_ok( $nobj->get_name_for(471), 'eq', 'ERR_CHANNELISFULL',
  'get_name_for() ok'
);

# Should also work as a class method:
cmp_ok( IRC::Toolkit::Numerics->get_name_for(471), 'eq', 'ERR_CHANNELISFULL',
  'get_name_for() as class method ok'
);

cmp_ok( $nobj->get_numeric_for('ERR_CHANNELISFULL'), '==', 471,
  'get_numeric_for() ok'
);

cmp_ok( IRC::Toolkit::Numerics->get_numeric_for('ERR_CHANNELISFULL'),
  '==', 471,
  'get_numeric_for() as class method ok'
);

cmp_ok( $nobj->get_name_for(484), 'ne', 'ERR_RESTRICTED',
  'pre-override check ok'
);
$nobj->associate_numeric( '484' => 'ERR_RESTRICTED' );
cmp_ok( $nobj->get_name_for(484), 'eq', 'ERR_RESTRICTED',
  'override get_name_for ok'
);
cmp_ok( $nobj->get_numeric_for('ERR_RESTRICTED'), '==', 484,
  'override get_numeric_for ok'
);

undef $numshash;
undef $nameshash;
$numshash = $nobj->export;
$nameshash = $nobj->export_by_name;

cmp_ok( $numshash->get('484'), 'eq', 'ERR_RESTRICTED',
  'override export() ok'
);
cmp_ok( $nameshash->get('ERR_RESTRICTED'), '==', 484,
  'override export_by_name ok'
);

{ package
    IRC::Toolkit::Numerics::Test;
  use Lowu 'hash';
  our @ISA = 'IRC::Toolkit::Numerics';
  sub new {
    bless +{
      over_num  => hash(304 => 'RPL_FOO'),
      over_name => hash('RPL_OMOTD' => '100'),
    }, $_[0]
  }
}

$nobj = IRC::Toolkit::Numerics->new('Test');
cmp_ok $nobj->get_name_for('304'), 'eq', 'RPL_FOO',
  'numeric override ok';
cmp_ok $nobj->get_numeric_for('RPL_OMOTD'), '==', 100,
  'name override ok';
cmp_ok $nobj->get_name_for(471), 'eq', 'ERR_CHANNELISFULL',
  'overrides did not mask original set';

done_testing;
