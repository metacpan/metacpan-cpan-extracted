# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GPS-Tracer.t'

#########################

#use Test::More tests => 16;
use Test::More qw( no_plan );
BEGIN { use_ok('GPS::Tracer') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tracer = GPS::Tracer->new;
ok (defined $tracer,              'new() returned something');
ok ($tracer->isa ('GPS::Tracer'), 'and it is the right class');

# test all allowed attributes
$tracer = new GPS::Tracer
    ( user             => 'user',
      passwd           => 'passwd',
      from_date        => '2007-01-02 22:23:24',
      to_date          => '2007-01-02 22:23:24',
      login_url        => 'http://yes',
      data_url         => 'http://no',
      default_id       => 'id',
      min_distance     => 10,
      result_dir       => 'results',
      result_basename  => 'basename',
      input_data       => 'file',
      input_format     => '1,2,3,4',
      );		   
is ($tracer->user, 'user',                     'get user');
is ($tracer->passwd, 'passwd',                 'get passwd');
is ($tracer->from_date, '2007-01-02 22:23:24', 'get from_date');
is ($tracer->to_date, '2007-01-02 22:23:24',   'get to_date');
is ($tracer->login_url, 'http://yes',          'get login_url');
is ($tracer->data_url, 'http://no',            'get data_url');
is ($tracer->default_id, 'id',                 'get default_id');
ok ($tracer->min_distance == 10,               'get min_distance');
is ($tracer->result_dir, 'results',            'get result_dir');
is ($tracer->result_basename, 'basename',      'get result_basename');
is ($tracer->input_data, 'file',               'get input_data');
is ($tracer->input_format, '1,2,3,4',          'get input_format');
ok ( ! defined eval { $tracer->unknown },      'unknown attribute');

# test reading, parsing and cleaning input data
$tracer = new GPS::Tracer
    ( input_data => 'data/small.csv',
      );
ok ( defined eval { $tracer->get_data },  'get_data');
my $data = $tracer->get_data;
ok ( @$data == 3,                         'count data');
foreach my $point (@$data) {
    ok ($$point{'time'} =~ /\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d/,  $$point{'time'});
    ok ($$point{'type'} =~ /[10]/,                               'type ' . $$point{'type'});
    ok ($$point{'lat'} =~ /76\.66664|76\.66668|76\.66666/,       'lat ' . $$point{'lat'});
    ok ($$point{'lng'} =~ /16\.78067|16\.78040|16\.78029/,       'lng ' . $$point{'lng'});
}

__END__
$DATA = [
          {
            'elevation' => '',
            'lat' => '76.66664',
            'time' => '2007-04-21 12:06:11',
            'type' => 1,
            'lng' => '16.78067'
          },
          {
            'elevation' => '',
            'lat' => '76.66668',
            'time' => '2007-04-21 12:36:05',
            'type' => 0,
            'lng' => '16.78040'
          },
          {
            'elevation' => '',
            'lat' => '76.66666',
            'time' => '2007-04-21 12:48:27',
            'type' => 0,
            'lng' => '16.78029'
          }
        ];


