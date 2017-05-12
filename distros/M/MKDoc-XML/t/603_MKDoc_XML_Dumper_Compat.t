#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Dumper;
use Data::Dumper;

{
    my $xml = <<EOF;
<perl>
  <hash id="id_151027208" bless="flo::editor::File">
    <item key="file">8763623178/search.html</item>
    <item key="title">search</item>
    <item key="uri_name">search.html</item>
  </hash>
</perl>
EOF

    my $struct = MKDoc::XML::Dumper->xml2perl ($xml);
    is (ref $struct, 'flo::editor::File');
    is ($struct->{file}, '8763623178/search.html');
    is ($struct->{title}, 'search');
    is ($struct->{uri_name}, 'search.html');
}


{
    my $xml = <<EOF;
<perl>
  <hash id="id_151020264" bless="flo::editor::Headlines">
    <item key="from_path">/</item>
    <item key="leaf_only">on</item>
    <item key="max_headlines">12</item>
    <item key="title">hello</item>
    <item key="uri_name">hello.html</item>
  </hash>
</perl>
EOF

    my $struct = MKDoc::XML::Dumper->xml2perl ($xml);
    is (ref $struct, 'flo::editor::Headlines');
    is ($struct->{from_path}, '/');
    is ($struct->{leaf_only}, 'on');
    is ($struct->{max_headlines}, '12');
    is ($struct->{title}, 'hello');
    is ($struct->{uri_name}, 'hello.html');
} 


{
    my $xml = <<EOF;
<perl>
  <hash id="id_151013220" bless="flo::editor::Image">
    <item key="image">7898392326/aureli-julian.jif</item>
    <item key="title">Aureli Julian</item>
    <item key="uri_name">aureli-julian.jif</item>
  </hash>
</perl>
EOF

    my $struct = MKDoc::XML::Dumper->xml2perl ($xml);
    is (ref $struct, 'flo::editor::Image');
    is ($struct->{image}, '7898392326/aureli-julian.jif');
    is ($struct->{title}, 'Aureli Julian');
    is ($struct->{uri_name}, 'aureli-julian.jif');
}


{
    my $xml = <<EOF;
<perl>
  <hash id="id_151013556" bless="flo::editor::Link">
    <item key="description">foo</item>
    <item key="title">foo</item>
    <item key="uri_name">foo.link</item>
    <item key="url">http://www.foo.com</item>
  </hash>
</perl>
EOF

    my $struct = MKDoc::XML::Dumper->xml2perl ($xml);
    is (ref $struct, 'flo::editor::Link');
    is ($struct->{description}, 'foo');
    is ($struct->{title}, 'foo');
    is ($struct->{uri_name}, 'foo.link');
    is ($struct->{url}, 'http://www.foo.com');
}


{
    my $xml = <<EOF;
<perl>
  <hash id="id_151013856" bless="flo::editor::Photo">
    <item key="alt">Aureli Julian</item>
    <item key="coverage"></item>
    <item key="creator">Fred Flintstone</item>
    <item key="date_created">2003-11-05</item>
    <item key="description">foo</item>
    <item key="image">0322940468/aureli-julian.jif</item>
    <item key="rights"></item>
    <item key="uri_name">aureli-julian-2.jif</item>
  </hash>
</perl>
EOF

    my $struct = MKDoc::XML::Dumper->xml2perl ($xml);
    is (ref $struct, 'flo::editor::Photo');
    is ($struct->{'alt'}, 'Aureli Julian');
    is ($struct->{'coverage'}, '');
    is ($struct->{'creator'}, 'Fred Flintstone');
    is ($struct->{'date_created'}, '2003-11-05');
    is ($struct->{'description'}, 'foo');
    is ($struct->{'image'}, '0322940468/aureli-julian.jif');
    is ($struct->{'rights'}, '');
    is ($struct->{'uri_name'}, 'aureli-julian-2.jif');
}


{
    my $xml = <<EOF;
<perl>
  <hash id="id_151013616" bless="flo::editor::Poll">
    <item key="answer1">foo</item>
    <item key="answer2">bar</item>
    <item key="answer3"></item>
    <item key="answer4"></item>
    <item key="answer5"></item>
    <item key="answer6"></item>
    <item key="answer7"></item>
    <item key="answer8"></item>
    <item key="answer9"></item>
    <item key="date_start">2003-11-05</item>
    <item key="date_stop">2003-11-07</item>
    <item key="hour_start">00</item>
    <item key="hour_stop">00</item>
    <item key="id">HWNJQUNGJB</item>
    <item key="question">woot?</item>
    <item key="uri_name">poll.html</item>
  </hash>
</perl>
EOF

    my $struct = MKDoc::XML::Dumper->xml2perl ($xml);
    is (ref $struct, 'flo::editor::Poll');
    is ($struct->{'answer1'}, 'foo');
    is ($struct->{'answer2'}, 'bar');
    is ($struct->{'answer3'}, '');
    is ($struct->{'answer4'}, '');
    is ($struct->{'answer5'}, '');
    is ($struct->{'answer6'}, '');
    is ($struct->{'answer7'}, '');
    is ($struct->{'answer8'}, '');
    is ($struct->{'answer9'}, '');
    is ($struct->{'date_start'}, '2003-11-05');
    is ($struct->{'date_stop'}, '2003-11-07');
    is ($struct->{'hour_start'}, '00');
    is ($struct->{'hour_stop'}, '00');
    is ($struct->{'id'}, 'HWNJQUNGJB');
    is ($struct->{'question'}, 'woot?');
    is ($struct->{'uri_name'}, 'poll.html');
}


{
    my $xml = <<EOF;
<perl>
  <hash id="id_151036892" bless="flo::editor::RSS">
    <item key="max">all</item>
    <item key="template">bulleted_list</item>
    <item key="title">foo</item>
    <item key="uri">http://www.foo.com/somerss</item>
    <item key="uri_name">rss.rss</item>
  </hash>
</perl>
EOF

    my $struct = MKDoc::XML::Dumper->xml2perl ($xml);
    is (ref $struct, 'flo::editor::RSS');
    is ($struct->{'max'}, 'all');
    is ($struct->{'template'}, 'bulleted_list');
    is ($struct->{'title'}, 'foo');
    is ($struct->{'uri'}, 'http://www.foo.com/somerss');
    is ($struct->{'uri_name'}, 'rss.rss');
} 


{
    my $xml = <<EOF;
<perl>
  <hash id="id_151018396" bless="flo::editor::Text">
    <item key="data">gsdfgsdfgds</item>
    <item key="uri_name">text.txt</item>
  </hash>
</perl>
EOF

    my $struct =  MKDoc::XML::Dumper->xml2perl ($xml);
    is (ref $struct, 'flo::editor::Text');
    is ($struct->{'data'}, 'gsdfgsdfgds');
    is ($struct->{'uri_name'}, 'text.txt');
}


{
    my $xml = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<perl>
  <hash id="id_144488596" bless="flo::editor::Photo">
    <item key="alt">Xchange Learning Centre</item>
    <item key="class">photo</item>
    <item key="coverage">Northamptonshire, UK</item>
    <item key="created_day">18</item>
    <item key="created_month">03</item>
    <item key="created_year">2002</item>
    <item key="creator">David Matthews</item>
    <item key="description">Photo taken outside the The Xchange Learning Centre, Kettering.</item>
    <item key="image">8217988573/xchange-learning-centre.jpg</item>
    <item key="param_name">_edit_block_32_photo</item>
    <item key="rights">© Crown copyright 2003</item>
  </hash>
</perl>
EOF

    ok (ref MKDoc::XML::Dumper->xml2perl ($xml));
}


__END__
