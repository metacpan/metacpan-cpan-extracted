#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 't/lib';
use TestFunctions;
use utf8;

plan tests => 5;

my $package = 'MarpaX::Languages::PowerBuilder::SRD';

use_ok( $package )       || print "Bail out!\n";

my $parser = $package->new;
is( ref($parser), $package, 'testing new');
	
my $DATA = <<'DATA';
HA$PBExportHeader$dddw_test.srd
release 10.5;
datawindow(units=0 timer_interval=0 color=1073741824 processing=1 HTMLDW=no print.printername="" print.documentname="" print.orientation = 0 print.margin.left = 110 print.margin.right = 110 print.margin.top = 96 print.margin.bottom = 96 print.paper.source = 0 print.paper.size = 0 print.canusedefaultprinter=yes print.prompt=no print.buttons=no print.preview.buttons=no print.cliptext=no print.overrideprintjob=no print.collate=yes print.preview.outline=yes hidegrayline=no grid.lines=0 )
header(height=80 color="536870912" )
summary(height=0 color="536870912" )
footer(height=0 color="536870912" )
detail(height=92 color="536870912" )
table(column=(type=char(4) updatewhereclause=yes name=db_data dbname="db_data" )
 column=(type=char(100) updatewhereclause=yes name=db_desc dbname="db_desc" )
 )
data("ABCD","Abcdefghijklmnopqrstuvwxyz","0123","0123456789","+-.,","+-.,?/$$HEX1$$a700$$ENDHEX$$!",) 
text(band=header alignment="2" text="Db Data" border="0" color="33554432" x="14" y="8" height="64" width="210" html.valueishtml="0"  name=db_data_t visible="1"  font.face="Tahoma" font.height="-10" font.weight="400"  font.family="2" font.pitch="2" font.charset="0" background.mode="1" background.color="536870912" )
text(band=header alignment="2" text="Db Desc" border="0" color="33554432" x="238" y="8" height="64" width="2743" html.valueishtml="0"  name=db_desc_t visible="1"  font.face="Tahoma" font.height="-10" font.weight="400"  font.family="2" font.pitch="2" font.charset="0" background.mode="1" background.color="536870912" )
column(band=detail id=1 alignment="0" tabsequence=10 border="0" color="33554432" x="14" y="8" height="76" width="210" format="[general]" html.valueishtml="0"  name=db_data visible="1" edit.limit=0 edit.case=any edit.focusrectangle=no edit.autoselect=yes edit.autohscroll=yes  font.face="Tahoma" font.height="-10" font.weight="400"  font.family="2" font.pitch="2" font.charset="0" background.mode="1" background.color="536870912" )
column(band=detail id=2 alignment="0" tabsequence=20 border="0" color="33554432" x="238" y="8" height="76" width="2743" format="[general]" html.valueishtml="0"  name=db_desc visible="1" edit.limit=0 edit.case=any edit.focusrectangle=no edit.autoselect=yes edit.autohscroll=yes  font.face="Tahoma" font.height="-10" font.weight="400"  font.family="2" font.pitch="2" font.charset="0" background.mode="1" background.color="536870912" )
htmltable(border="1" )
htmlgen(clientevents="1" clientvalidation="1" clientcomputedfields="1" clientformatting="0" clientscriptable="0" generatejavascript="1" encodeselflinkargs="1" netscapelayers="0" pagingmethod=0 generatedddwframes="1" )
xhtmlgen() cssgen(sessionspecific="0" )
xmlgen(inline="0" )
xsltgen()
jsgen()
export.xml(headgroups="1" includewhitespace="0" metadatatype=0 savemetadata=0 )
import.xml()
export.pdf(method=0 distill.custompostscript="0" xslfop.print="0" )
export.xhtml()
DATA
my $parsed = $parser->parse( $DATA );
is( ref($parser), $package, 'testing parsed package');
is( $parsed->{error}, '', 'testing parse(FH) without error');

my $got = $parsed->value;
my $expected = {
  controls => {
    db_data => {
      '#' => 1,
      alignment => '0',
      'background.color' => '536870912',
      'background.mode' => '1',
      band => 'detail',
      border => '0',
      color => '33554432',
      'edit.autohscroll' => 'yes',
      'edit.autoselect' => 'yes',
      'edit.case' => 'any',
      'edit.focusrectangle' => 'no',
      'edit.limit' => '0',
      'font.charset' => '0',
      'font.face' => 'Tahoma',
      'font.family' => '2',
      'font.height' => '-10',
      'font.pitch' => '2',
      'font.weight' => '400',
      format => '[general]',
      height => '76',
      'html.valueishtml' => '0',
      id => '1',
      name => 'db_data',
      tabsequence => '10',
      type => 'column',
      visible => '1',
      width => '210',
      x => '14',
      y => '8'
    },
    db_data_t => {
      alignment => '2',
      'background.color' => '536870912',
      'background.mode' => '1',
      band => 'header',
      border => '0',
      color => '33554432',
      'font.charset' => '0',
      'font.face' => 'Tahoma',
      'font.family' => '2',
      'font.height' => '-10',
      'font.pitch' => '2',
      'font.weight' => '400',
      height => '64',
      'html.valueishtml' => '0',
      name => 'db_data_t',
      text => 'Db Data',
      type => 'text',
      visible => '1',
      width => '210',
      x => '14',
      y => '8'
    },
    db_desc => {
      '#' => 2,
      alignment => '0',
      'background.color' => '536870912',
      'background.mode' => '1',
      band => 'detail',
      border => '0',
      color => '33554432',
      'edit.autohscroll' => 'yes',
      'edit.autoselect' => 'yes',
      'edit.case' => 'any',
      'edit.focusrectangle' => 'no',
      'edit.limit' => '0',
      'font.charset' => '0',
      'font.face' => 'Tahoma',
      'font.family' => '2',
      'font.height' => '-10',
      'font.pitch' => '2',
      'font.weight' => '400',
      format => '[general]',
      height => '76',
      'html.valueishtml' => '0',
      id => '2',
      name => 'db_desc',
      tabsequence => '20',
      type => 'column',
      visible => '1',
      width => '2743',
      x => '238',
      y => '8'
    },
    db_desc_t => {
      alignment => '2',
      'background.color' => '536870912',
      'background.mode' => '1',
      band => 'header',
      border => '0',
      color => '33554432',
      'font.charset' => '0',
      'font.face' => 'Tahoma',
      'font.family' => '2',
      'font.height' => '-10',
      'font.pitch' => '2',
      'font.weight' => '400',
      height => '64',
      'html.valueishtml' => '0',
      name => 'db_desc_t',
      text => 'Db Desc',
      type => 'text',
      visible => '1',
      width => '2743',
      x => '238',
      y => '8'
    }
  },
  cssgen => {
    sessionspecific => '0'
  },
  data => [
    'ABCD',
    'Abcdefghijklmnopqrstuvwxyz',
    '0123',
    '0123456789',
    '+-.,',
    "+-.,?/§!"
  ],
  datawindow => {
    HTMLDW => 'no',
    color => '1073741824',
    'grid.lines' => '0',
    hidegrayline => 'no',
    'print.buttons' => 'no',
    'print.canusedefaultprinter' => 'yes',
    'print.cliptext' => 'no',
    'print.collate' => 'yes',
    'print.documentname' => '',
    'print.margin.bottom' => '96',
    'print.margin.left' => '110',
    'print.margin.right' => '110',
    'print.margin.top' => '96',
    'print.orientation' => '0',
    'print.overrideprintjob' => 'no',
    'print.paper.size' => '0',
    'print.paper.source' => '0',
    'print.preview.buttons' => 'no',
    'print.preview.outline' => 'yes',
    'print.printername' => '',
    'print.prompt' => 'no',
    processing => '1',
    timer_interval => '0',
    units => '0'
  },
  detail => {
    color => '536870912',
    height => '92'
  },
  encoding => 'HA$',
  'export.pdf' => {
    'distill.custompostscript' => '0',
    method => '0',
    'xslfop.print' => '0'
  },
  'export.xhtml' => {},
  'export.xml' => {
    headgroups => '1',
    includewhitespace => '0',
    metadatatype => '0',
    savemetadata => '0'
  },
  file => 'dddw_test.srd',
  footer => {
    color => '536870912',
    height => '0'
  },
  header => {
    color => '536870912',
    height => '80'
  },
  htmlgen => {
    clientcomputedfields => '1',
    clientevents => '1',
    clientformatting => '0',
    clientscriptable => '0',
    clientvalidation => '1',
    encodeselflinkargs => '1',
    generatedddwframes => '1',
    generatejavascript => '1',
    netscapelayers => '0',
    pagingmethod => '0'
  },
  htmltable => {
    border => '1'
  },
  'import.xml' => {},
  jsgen => {},
  release => '10.5',
  summary => {
    color => '536870912',
    height => '0'
  },
  table => {
    columns => {
      db_data => {
        '#' => 1,
        dbname => 'db_data',
        name => 'db_data',
        type => 'char(4)',
        updatewhereclause => 'yes'
      },
      db_desc => {
        '#' => 2,
        dbname => 'db_desc',
        name => 'db_desc',
        type => 'char(100)',
        updatewhereclause => 'yes'
      }
    }
  },
  xhtmlgen => {},
  xmlgen => {
    inline => '0'
  },
  xsltgen => {}
};

_is_deep_diff( $got, $expected, 'testing parse(FH) value');