use strict;
use warnings;
use Devel::ebug;
use Test::More;
use Test::Mojo;
use Devel::ebug::HTTP;

my $ebug = Devel::ebug->new;
$ebug->program("corpus/calc.pl");
$ebug->load;
Devel::ebug::HTTP::App->ebug($ebug);

my $t = Test::Mojo->new('Devel::ebug::HTTP');

$t->get_ok("/")
  ->status_is(200)
  ->content_type_like(qr{^text/html})
  ->text_is('title', 'corpus/calc.pl main(corpus/calc.pl#3) my $q = 1;')
  ->content_like(qr/Step/)
  ->content_like(qr/Next/)
  ->content_like(qr/corpus\/calc\.pl main\(corpus\/calc\.pl#3\)/)
  ->content_like(qr/#!perl/)
  ->content_like(qr/Variables in main/)
  ->content_like(qr/Stack trace/)
  ->content_like(qr/STDOUT/)
  ->content_like(qr/STDERR/)
  ->content_like(qr/Devel::ebug/)
  ->content_like(qr/\Q$Devel::ebug::VERSION\E/);

# $q not defined yet
$t->get_ok('/ajax_variable/$q')
  ->status_is(200)
  ->content_type_is('text/xml')
  ->content_is(q|<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<response>
  <variable>$q</variable>
  <value><![CDATA[Not defined]]></value>
</response>
  |);

# 2+3 = 5
$t->post_ok('/ajax_eval', form => { eval => '2+3', myaction => 'Eval' })
  ->status_is(200)
  ->content_type_is('text/html')
  ->content_is('5');

# hit "Step"
$t->post_ok('/foo', form => { sequence => 3, myaction => 'Step' })
  ->status_is(200)
  ->content_type_like(qr{^text/html})
  ->text_is('title', 'corpus/calc.pl main(corpus/calc.pl#4) my $w = 2;')
  ->content_like(qr/corpus\/calc\.pl main\(corpus\/calc\.pl#4\)/);

# $q is now defined, and 1
$t->get_ok('/ajax_variable/$q')
  ->status_is(200)
  ->content_type_is('text/xml')
  ->content_is(q|<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<response>
  <variable>$q</variable>
  <value><![CDATA[1<br/>]]></value>
</response>
  |);

undef $ebug->{proc};

done_testing;
