use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Data::Dumper;
use Form::Sensible;

use Form::Sensible::Form;

my $lib_dir = $FindBin::Bin;
my @dirs = split '/', $lib_dir;
pop @dirs;
$lib_dir = join('/', @dirs);

use DateTime;
use DateTime::Span;

my $start = DateTime->new( year => 2005, month => 6, day => 10, hour => 7, minute => 2, second => 5 );
my $end = DateTime->new( year => 2012, month => 5, day => 25, hour => 10, minute => 59, second => 38 );
my $span = DateTime::Span->from_datetimes( start=> $start, end => $end );

my $form = Form::Sensible->create_form( {
                                            name => 'test',
                                            fields => [
                                                         {
                                                             field_class => 'DateTime',
                                                             name => 'simple_date',
                                                         },
                                                         {
                                                             field_class => 'DateTime',
                                                             name => 'date_in_span',
                                                             span => $span,
                                                         },
                                                         {
                                                             field_class => 'DateTime',
                                                             name => 'date_with_yearly_recurrence',
                                                             span => $span,
                                                             recurrence => sub {
                                                                return $_[0] if $_[0]->is_infinite;
                                                                return $_[0]->truncate( to => 'year' )->add( years => 1 );
                                                             },
                                                         },
                                                         {
                                                             field_class => 'DateTime',
                                                             name => 'date_with_monthly_recurrence',
                                                             span => $span,
                                                             recurrence => sub {
                                                                return $_[0] if $_[0]->is_infinite;
                                                                return $_[0]->truncate( to => 'month' )->add( months => 1 );
                                                             },
                                                         },
                                                         {
                                                             field_class => 'DateTime',
                                                             name => 'date_with_daily_recurrence',
                                                             span => $span,
                                                             recurrence => sub {
                                                                return $_[0] if $_[0]->is_infinite;
                                                                return $_[0]->truncate( to => 'day' )->add( days => 1 );
                                                             },
                                                         },
                                                         {
                                                             field_class => 'DateTime',
                                                             name => 'date_with_daily_recurrence_string',
                                                             span => $span,
                                                             recurrence => 'daily',
                                                         },
                                                      ],
                                        } );

my $now     = DateTime->now;
my $year    = DateTime->new( year => 2006 );
my $month   = DateTime->new( year => 2010, month => 9 );
my $day     = DateTime->new( year => 2009, month => 7, day => 6 );

## first, success     
$form->set_values({ 
                    string => 'a2z0to9',
                    blah => 'boblawlaw',
                    simple_date => $now,
                    date_in_span => $now,
                    date_with_yearly_recurrence => $year,
                    date_with_monthly_recurrence => $month,
                    date_with_daily_recurrence => $day,
                    date_with_daily_recurrence_string => $day,
                  });
                  
my $validation_result = $form->validate();

ok( $validation_result->is_valid(), 'valid datetime values are considered valid');

# Test yearly
{
    my $start_orig = DateTime->from_epoch( epoch => $start->epoch );
    my @tests = (
        { nok => 1,
          value => DateTime->from_epoch( epoch => $start->epoch )->truncate( to => 'year' ),
          error => 'start year not valid yearly recurrence'
        },
        { nok => 0,
          before => sub { $start->truncate( to => 'year' ) },
          after => sub { $start->set( $_ => $start_orig->$_ ) for qw(month day hour minute second) },
          value => DateTime->from_epoch( epoch => $start->epoch )->truncate( to => 'year' ),
          error => 'now start year is valid yearly recurrence'
        },
        { nok => 1,
          value => DateTime->from_epoch( epoch => $start->epoch )->truncate( to => 'year' ),
          error => 'start year is again not valid yearly recurrence'
        },
        { nok => 0,
          value => DateTime->from_epoch( epoch => $end->epoch )->truncate( to => 'year' ),
          error => 'end year is valid yearly recurrence'
        },
        { nok => 1,
          value => $month,
          error => 'not every month is valid yearly recurrence'
        },
        { nok => 0,
          value => $year,
          error => 'a year is valid yearly recurrence'
        },
        { nok => 0,
          value => DateTime->new( year => 2008, month => 1 ),
          error => 'first month is valid yearly recurrence'
        },
        { nok => 1,
          value => DateTime->new( year => 2004 ),
          error => 'year before valid range'
        },
        { nok => 1,
          value => DateTime->new( year => 2013 ),
          error => 'year after valid range'
        },
        { nok => 1,
          value => '20X11',
          error => 'datetime cannot be parsed',
        },
        { nok => 0,
          value => '2011',
          error => 'datetime parses year',
        },
    );
    for ( @tests ) {
        $_->{'before'}->( $_ ) if exists $_->{'before'};
        $form->set_values({ date_with_yearly_recurrence => $_->{'value'} });
        $validation_result = $form->validate();
        ok( ($_->{'nok'} xor $validation_result->is_valid()), $_->{'error'} );
        $_->{'after'}->( $_ ) if exists $_->{'after'};
    }
}

# Test monthly
{
    my @tests = (
        { nok => 1,
          value => DateTime->from_epoch( epoch => $start->epoch )->truncate( to => 'month' ),
          error => 'start month not valid monthly recurrence'
        },
        { nok => 0,
          value => DateTime->from_epoch( epoch => $end->epoch )->truncate( to => 'month' ),
          error => 'end month valid monthly recurrence'
        },
        { nok => 0,
          value => $month,
          error => 'a month is valid monthly recurrence',
        },
        { nok => 1,
          value => DateTime->new( year => 2004, month => 6, day => 4 ),
          error => 'not every day is valid monthly recurrence',
        },
        { nok => 1,
          value => DateTime->new( year => 2004, month => 7 ),
          error => 'month before valid range',
        },
        { nok => 1,
          value => DateTime->new( year => 2013, month => 1 ),
          error => 'month after valid range'
        },
        { nok => 1,
          value => '20z7z12',
          error => 'datetime cannot be parsed',
        },
        { nok => 0,
          value => 'February 2009',
          error => 'datetime parses month and year',
        },
    );
    for ( @tests ) {
        $form->set_values({ date_with_monthly_recurrence => $_->{'value'} });
        $validation_result = $form->validate();
        ok( ($_->{'nok'} xor $validation_result->is_valid()), $_->{'error'} );
    }
}

# Test daily
{
    my @tests = (
        { nok => 1,
          value => DateTime->from_epoch( epoch => $start->epoch )->truncate( to => 'day' ),
          error => 'start day not valid daily recurrence'
        },
        { nok => 0,
          value => DateTime->from_epoch( epoch => $end->epoch )->truncate( to => 'day' ),
          error => 'end day valid daily recurrence'
        },
        { nok => 0,
          value => $day,
          error => 'a day is valid day recurrence',
        },
        { nok => 1,
          value => DateTime->new( year => 2004, month => 6, day => 4, minute => 6 ),
          error => 'not every minute is valid daily recurrence',
        },
        { nok => 1,
          value => DateTime->new( year => 2004, month => 7, day => 8 ),
          error => 'day before valid range',
        },
        { nok => 1,
          value => DateTime->new( year => 2013, month => 1, day => 9 ),
          error => 'day after valid range'
        },
        { nok => 1,
          value => '20092',
          error => 'datetime cannot be parsed',
        },
        { nok => 0,
          value => 'February 28, 2009',
          error => 'datetime parses date',
        },
        { nok => 0,
          value => 'last Monday',
          error => 'datetime parses relative date',
        },
    );
    for ( @tests ) {
        $form->set_values({ date_with_daily_recurrence => $_->{'value'} });
        $validation_result = $form->validate();
        ok( ($_->{'nok'} xor $validation_result->is_valid()), $_->{'error'} );
    }
}

# Test daily w/string
{
    my @tests = (
        { nok => 1,
          value => DateTime->from_epoch( epoch => $start->epoch )->truncate( to => 'day' ),
          error => '[string: daily] start day not valid daily recurrence'
        },
        { nok => 0,
          value => DateTime->from_epoch( epoch => $end->epoch )->truncate( to => 'day' ),
          error => '[string: daily] end day valid daily recurrence'
        },
        { nok => 0,
          value => $day,
          error => '[string: daily] a day is valid day recurrence',
        },
        { nok => 1,
          value => DateTime->new( year => 2004, month => 6, day => 4, minute => 6 ),
          error => '[string: daily] not every minute is valid daily recurrence',
        },
    );
    for ( @tests ) {
        $form->set_values({ date_with_daily_recurrence_string => $_->{'value'} });
        $validation_result = $form->validate();
        ok( ($_->{'nok'} xor $validation_result->is_valid()), $_->{'error'} );
    }
}

done_testing();
