#!/usr/bin/perl
use strict;
use warnings;
use lib qw( lib ../lib );
use Cwd;
use YAML;
use Test::More 'no_plan';
BEGIN {
    use_ok( 'MARC::Transform' );
}

sub recordtostring {
	my ($record) = @_;
	my $string="";
	my $finalstring=$record->leader;
	my %tag_names = map( { $$_{_tag} => 1 } $record->fields);
	my @order = qw/0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
	foreach my $tag(sort({ $a cmp $b } keys(%tag_names)))
	{
		my @fields=$record->field($tag);
		foreach my $field(@fields)
		{
			$string.="|#f#|$tag:";
			if ($field->is_control_field())
			{
				$string.=$field->data();
			}
			else
			{
				$string.=$field->indicator(1);
				$string.=$field->indicator(2);
				foreach my $key (@order)
				{
					foreach my $subfield (sort({ $a cmp $b } $field->subfield($key)))
					{
						$string.="|$key:".$subfield;
					}
				}
			}
		}
	}
	my @arec = split(/\|#f#\|/,$string);#warn Data::Dumper::Dumper @arec;
	foreach my $tempstring (sort({ $a cmp $b } @arec))
	{
		$finalstring.="||$tempstring";
	}
	return $finalstring;
}

#test 2
my %mtest;
$mtest{"var"}="a string";
my $record2a = MARC::Record->new();
$record2a->leader('optionnal leader');
$record2a->insert_fields_ordered( MARC::Field->new( '005', 'controlfield_content' ));
$record2a->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_content8b' ));
$record2a->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_content8a' ));
$record2a->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'a' => 'foao', 'b' => '1', 'b' => 'baoar', 'c' => 'big') );
$record2a->insert_fields_ordered( MARC::Field->new( '501', '', '', 'c' => '1') );
$record2a->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'I want "$"') );
$record2a->insert_fields_ordered( MARC::Field->new( '106', '', '', 'a' => 'VaLuE') );
$record2a->insert_fields_ordered( MARC::Field->new( '503', '', '', 'a' => 'fee', 'a' => 'babar') );
$record2a->insert_fields_ordered( MARC::Field->new( '504', '', '', 'a' => 'zut', 'a' => 'sisi') );
$record2a->insert_fields_ordered( MARC::Field->new( '604', '', '', 'a' => 'foo', 'a' => 'foo', 'b' => 'bar', 'c' => 'truc') );
$record2a->insert_fields_ordered( MARC::Field->new( '401', '', '', 'a' => 'afooa') );
$record2a->insert_fields_ordered( MARC::Field->new( '402', '1', '', 'a' => 'a402a1') );
$record2a->insert_fields_ordered( MARC::Field->new( '402', '', '2', 'a' => 'a402a2') );
my $record2b = MARC::Record->new();
$record2b->leader('optionnal leader');
$record2b->insert_fields_ordered( MARC::Field->new( '005', 'controlfield_content' ));
$record2b->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_content8b' ));
$record2b->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_content8a' ));
$record2b->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'a' => 'foao', 'b' => '1', 'b' => 'baoar', 'c' => 'big') );
$record2b->insert_fields_ordered( MARC::Field->new( '501', '', '', 'c' => '1') );
$record2b->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'I want "$"') );
$record2b->insert_fields_ordered( MARC::Field->new( '106', '', '', 'a' => 'VaLuE') );
$record2b->insert_fields_ordered( MARC::Field->new( '503', '', '', 'a' => 'fee', 'a' => 'babar') );
$record2b->insert_fields_ordered( MARC::Field->new( '504', '', '', 'a' => 'zut', 'a' => 'sisi') );
$record2b->insert_fields_ordered( MARC::Field->new( '604', '', '', 'a' => 'foo', 'a' => 'foo', 'b' => 'bar', 'c' => 'truc') );
$record2b->insert_fields_ordered( MARC::Field->new( '401', '', '', 'a' => 'afooa') );
$record2b->insert_fields_ordered( MARC::Field->new( '402', '1', '', 'a' => 'a402a1') );
$record2b->insert_fields_ordered( MARC::Field->new( '402', '', '2', 'a' => 'a402a2') );
#print "--init record--\n". $record1->as_formatted;
my $yaml2 = '---
condition : $f501a eq "foo"
create :
 f502a : this is the value of a subfield of a new 502 field
---
condition : $f401a=~/foo/
create :
 b : new value of the 401 conditions field
 f600 :
  a : 
   - first a subfield of this new 600 field
   - second a subfield of this new 600 field
   - $$mth{"var"}
  b : the 600b value
execute : \&reencodeRecordtoUtf8()
---
condition : $f502a eq "I want #_dbquote_##_dollars_##_dbquote_#"
create :
 f605a : "#_dbquote_#$f502a#_dbquote_# contain a #_dollars_# sign"
---
-
 condition : $f501a =~/foo/ and $f503a =~/bar/
 forceupdate :
  $f503b : mandatory b in condition\'s field
  f005_ : mandatory 005
  f006_ : \&return_record_encoding()
  f700 :
   a : the a subfield of this mandatory 700 field
   b : \&sub1("$f503a")
 forceupdatefirst :
  $f501b : update only the first b in condition\'s field 501
-
 condition : $f501a =~/foo/
 execute : \&warnfoo("f501a contain foo")
-
 subs : >
    sub return_record_encoding { $record->encoding(); }
    sub sub1 { my $string = shift;$string =~ s/a/e/g;return $string; }
    sub warnfoo { my $string = shift;warn $string; }
---
-
 condition : $f501b2 eq "o"
 update :
  c : updated value of all c in condition\'s field
  f504a : updated value of all 504a if exists
  f604 :
   b : \&LUT("$this")
   c : \&LUT("NY","cities")
 updatefirst :
  f604a : update only the first a in 604
-
 condition : $f501c eq "1"
 delete : $f501
-
 LUT :
   1 : first
   2 : second
   bar : openbar
---
delete :
 - f401a
 - f005
---
condition : $ldr2 eq "t"
execute : \&SetRecordToLowerCase($record)
---
condition : $f008_ eq "controlfield_content8b"
duplicatefield :
 - $f008 > f007
 - f402 > f602
delete : f402
---
global_subs: >
    sub reencodeRecordtoUtf8 {
        $record->encoding( \'UTF-8\' );
    }
    sub warnfee {
        my $string = shift;warn $string;
    }
global_LUT:
 cities:
  NY : New York
  SF : San Fransisco
 numbers:
  1 : one
  2 : two
';
$record2a = MARC::Transform->new($record2a,$yaml2,\%mtest);
$record2b = MARC::Transform->new($record2b,$yaml2,\%mtest);
#print "\n--transformed record--\n". $record2b->as_formatted ."\n";
my $v2aa=recordtostring($record2a);
my $v2ba=recordtostring($record2b);
my $v2b='optionnalaleader||||006:UTF-8||007:controlfield_content8b||008:controlfield_content8a||008:controlfield_content8b||106:  |a:VaLuE||401:  |b:new value of the 401 conditions field||501:  |a:foao|a:foo|b:baoar|b:update only the first b in condition\'s field 501|c:updated value of all c in condition\'s field||501:  |c:1||502:  |a:I want "$"||502:  |a:this is the value of a subfield of a new 502 field||503:  |a:babar|a:fee|b:mandatory b in condition\'s field||504:  |a:updated value of all 504a if exists|a:updated value of all 504a if exists||600:  |a:a string|a:first a subfield of this new 600 field|a:second a subfield of this new 600 field|b:the 600b value||602: 2|a:a402a2||602:1 |a:a402a1||604:  |a:foo|a:update only the first a in 604|b:openbar|c:New York||605:  |a:"I want "$"" contain a $ sign||700:  |a:the a subfield of this mandatory 700 field|b:beber';
is( $v2aa.$v2ba, $v2b.$v2b, "" );

#test 3
my $record3 = MARC::Record->new();
$record3->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo') );
#print "--init record--\n". $record3->as_formatted;
my $yaml3 = '---
condition : $f501a or $f502a
create :
 f600a : aaa
';
$record3 = MARC::Transform->new($record3,$yaml3);
#print "\n--transformed record--\n". $record2->as_formatted ."\n";
my $v3a=recordtostring($record3);
my $v3b="                        ||||501:  |a:foo||600:  |a:aaa";
is($v3a,$v3b, "" );

#test 4
my $record4 = MARC::Record->new();
$record4->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
#print "--init record--\n". $record4->as_formatted;
my $yaml4 = '
---
condition : $f501a eq "foo"
create :
 f502a : value of a new 502a
update :
  $f501b : \&LUT("$this")
LUT :
 1 : first
 2 : second value in this LUT (LookUp Table)
---
delete : f501c
';
$record4 = MARC::Transform->new($record4,$yaml4);
#print "\n--transformed record--\n". $record3->as_formatted ."\n";
my $v4a=recordtostring($record4);
my $v4b="                        ||||501:  |a:foo|b:first||502:  |a:value of a new 502a";
is($v4a,$v4b,"");

#test 5
my $record5 = MARC::Record->new();
$record5->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
#print "--init record--\n". $record5->as_formatted;
my $yaml5 = '
---
condition : $f501a eq "foo"
create :
 b : new subfield value of the conditions field
 f502a : this is the value of a subfield of a new 502 field
 f502b : 
  - this is the first value of two \'b\' of another new 502
  - this is the 2nd value of two \'b\' of another new 502
 f600 :
  a : 
   - first a subfield of this new 600 field
   - second a subfield of this new 600 field
  b : the 600b value
';
$record5 = MARC::Transform->new($record5,$yaml5);
#print "\n--transformed record--\n". $record5->as_formatted ."\n";
my $v5a=recordtostring($record5);
my $v5b="                        ||||501:  |a:foo|b:1|b:new subfield value of the conditions field|c:bar||502:  |a:this is the value of a subfield of a new 502 field||502:  |b:this is the 2nd value of two 'b' of another new 502|b:this is the first value of two 'b' of another new 502||600:  |a:first a subfield of this new 600 field|a:second a subfield of this new 600 field|b:the 600b value";
is($v5a,$v5b,"");

#test 6
my $record6 = MARC::Record->new();
$record6->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
$record6->insert_fields_ordered( MARC::Field->new( '502', '', '', 'b' => 'truc', 'c' => 'bidule') );
$record6->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'poto') );
$record6->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'first a', 'a' => 'second a', 'b' => 'bbb', 'c' => 'ccc1', 'c' => 'ccc2') );
#print "--init record--\n". $record6->as_formatted;
my $yaml6 = '
---
condition : $f502a eq "second a"
update :
 b : updated value of all \'b\' subfields in the condition field
 f502c : updated value of all \'c\' subfields into all \'502\' fields
 f501 :
  a : updated value of all \'a\' subfields into all \'501\' fields
  b : $f502a is the value of 502a conditionnal field
';
$record6 = MARC::Transform->new($record6,$yaml6);
#print "\n--transformed record--\n". $record6->as_formatted ."\n";
my $v6a=recordtostring($record6);
my $v6b="                        ||||501:  |a:updated value of all 'a' subfields into all '501' fields|b:second a is the value of 502a conditionnal field|c:bar||502:  |a:first a|a:second a|b:updated value of all 'b' subfields in the condition field|c:updated value of all 'c' subfields into all '502' fields|c:updated value of all 'c' subfields into all '502' fields||502:  |a:poto||502:  |b:truc|c:updated value of all 'c' subfields into all '502' fields";
is($v6a,$v6b,"");

#test 7
my $record7 = MARC::Record->new();
$record7->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
$record7->insert_fields_ordered( MARC::Field->new( '502', '', '', 'b' => 'truc', 'c' => 'bidule') );
$record7->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'poto') );
$record7->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'first a', 'a' => 'second a', 'b' => 'bbb', 'c' => 'cc1', 'c' => 'cc2') );
#print "--init record--\n". $record7->as_formatted;
my $yaml7 = '
---
condition : $f502a eq "second a"
forceupdate :
 b : value of \'b\' subfields in the condition field
 f502c : value of \'502c\'
 f503 :
  a : value of \'503a\'
  b : $f502a is the value of 502a conditionnal field
';
$record7 = MARC::Transform->new($record7,$yaml7);
#print "\n--transformed record--\n". $record7->as_formatted ."\n";
my $v7a=recordtostring($record7);
my $v7b="                        ||||501:  |a:foo|b:1|c:bar||502:  |a:first a|a:second a|b:value of 'b' subfields in the condition field|c:value of '502c'|c:value of '502c'||502:  |a:poto|c:value of '502c'||502:  |b:truc|c:value of '502c'||503:  |a:value of '503a'|b:second a is the value of 502a conditionnal field";
is($v7a,$v7b,"");

#test 8
my $record8 = MARC::Record->new();
$record8->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
$record8->insert_fields_ordered( MARC::Field->new( '502', '', '', 'b' => 'truc', 'c' => 'bidule') );
$record8->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'poto') );
$record8->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'first a', 'a' => 'second a', 'b' => 'bbb', 'c' => 'cc1', 'c' => 'cc2') );
#print "--init record--\n". $record8->as_formatted;
my $yaml8 = '
---
condition : $f502a eq "second a"
forceupdatefirst :
 b : value of \'b\' subfields in the condition field
 f502c : value of \'502c\'
 f503 :
  a : value of \'503a\'
  b : $f502a is the value of 502a conditionnal field
';
$record8 = MARC::Transform->new($record8,$yaml8);
#print "\n--transformed record--\n". $record8->as_formatted ."\n";
my $v8a=recordtostring($record8);
my $v8b="                        ||||501:  |a:foo|b:1|c:bar||502:  |a:first a|a:second a|b:value of 'b' subfields in the condition field|c:cc2|c:value of '502c'||502:  |a:poto|c:value of '502c'||502:  |b:truc|c:value of '502c'||503:  |a:value of '503a'|b:second a is the value of 502a conditionnal field";
is($v8a,$v8b,"");

#test 9
my $record9 = MARC::Record->new();
$record9->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'bar', 'b' => 'bb1', 'b' => 'bb2') );
$record9->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo') );
$record9->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'pata') );
$record9->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'poto') );
$record9->insert_fields_ordered( MARC::Field->new( '503', '', '', 'a' => 'pata') );
$record9->insert_fields_ordered( MARC::Field->new( '504', '', '', 'a' => 'ata1', 'a' => 'ata2', 'b' => 'tbbt') );
#print "--init record--\n". $record9->as_formatted;
my $yaml9 = '
---
condition : $f501a eq "foo"
delete : $f501
---
condition : $f501a eq "bar"
delete : b
---
delete : f502
---
delete : 
 - f503
 - f504a
';
$record9 = MARC::Transform->new($record9,$yaml9);
#print "\n--transformed record--\n". $record9->as_formatted ."\n";
my $v9a=recordtostring($record9);
my $v9b="                        ||||501:  |a:bar||504:  |b:tbbt";
is($v9a,$v9b,"");

#test 10
my $record10 = MARC::Record->new();
$record10->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '1', 'c' => 'bar') );
$record10->insert_fields_ordered( MARC::Field->new( '502', '', '', 'b' => 'truc', 'c' => 'bidule') );
$record10->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'poto') );
$record10->insert_fields_ordered( MARC::Field->new( '502', '', '', 'a' => 'first a', 'a' => 'second a', 'b' => 'bbb', 'c' => 'ccc1', 'c' => 'ccc2') );
#print "--init record--\n". $record10->as_formatted;
my $yaml10 = '
---
condition : $f502a eq "second a"
updatefirst :
 b : updated value of first \'b\' subfields in the condition field
 f502c : updated value of first \'c\' subfields into all \'502\' fields
 f501 :
  a : updated value of first \'a\' subfields into all \'501\' fields
  b : $f502a is the value of 502a conditionnal field
';
$record10 = MARC::Transform->new($record10,$yaml10);
#print "\n--transformed record--\n". $record10->as_formatted ."\n";
my $v10a=recordtostring($record10);
my $v10b="                        ||||501:  |a:updated value of first 'a' subfields into all '501' fields|b:second a is the value of 502a conditionnal field|c:bar||502:  |a:first a|a:second a|b:updated value of first 'b' subfields in the condition field|c:ccc2|c:updated value of first 'c' subfields into all '502' fields||502:  |a:poto||502:  |b:truc|c:updated value of first 'c' subfields into all '502' fields";
is($v10a,$v10b,"");

#test 11
my $record11 = MARC::Record->new();
$record11->insert_fields_ordered( MARC::Field->new( '005', 'controlfield_content1' ));
$record11->insert_fields_ordered( MARC::Field->new( '005', 'controlfield_content2' ));
$record11->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_contenta' ));
$record11->insert_fields_ordered( MARC::Field->new( '008', 'controlfield_contentb' ));
$record11->insert_fields_ordered( MARC::Field->new( '501', '1', '2', 'a' => 'bar', 'b' => 'bb1', 'b' => 'bb2') );
$record11->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo') );
#print "--init record--\n". $record11->as_formatted;
my $yaml11 = '
---
condition : $f008_ eq "controlfield_contentb"
duplicatefield : $f008 > f007
---
condition : $f501a eq "bar"
duplicatefield : $f501 > f400
---
condition : $f501a eq "foo"
duplicatefield : 
 - f501 > f401
 - $f501 > f402
 - f005 > f006
';
$record11 = MARC::Transform->new($record11,$yaml11);
#print "\n--transformed record--\n". $record11->as_formatted ."\n";
my $v11a=recordtostring($record11);
my $v11b="                        ||||005:controlfield_content1||005:controlfield_content2||006:controlfield_content1||006:controlfield_content2||007:controlfield_contentb||008:controlfield_contenta||008:controlfield_contentb||400:12|a:bar|b:bb1|b:bb2||401:  |a:foo||401:12|a:bar|b:bb1|b:bb2||402:  |a:foo||501:  |a:foo||501:12|a:bar|b:bb1|b:bb2";
is($v11a,$v11b,"");

#test 12
my $record12 = MARC::Record->new();
$record12->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => 'boo', 'd' => 'doo') );
#print "--init record--\n". $record12->as_formatted;
my $yaml12 = '
---
-
 condition : $f501a eq "foo"
 create : 
  c : \&fromo2e("$f501a")
 update :
  d : the value of this 501d is $this
  b : \&fromo2e("$this")
-
 subs: >
    sub fromo2e { my $string=shift; $string =~ s/o/e/g; $string; }
';
$record12 = MARC::Transform->new($record12,$yaml12);
#print "\n--transformed record--\n". $record12->as_formatted ."\n";
my $v12a=recordtostring($record12);
my $v12b="                        ||||501:  |a:foo|b:bee|c:fee|d:the value of this 501d is doo";
is($v12a,$v12b,"");

#test 13
my $record13 = MARC::Record->new();
$record13->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => '8/13/10', 'c' => 'boo', 'd' => '40,00') );
#print "--init record--\n". $record13->as_formatted;
my $yaml13 = '
---
-
 condition : $f501a eq "foo" and defined $f501d
 update :
  b : \&convertbaddate("$this")
  c : \&trim("$f501d")
-
 subs: >
    sub convertbaddate {
        #this function convert date like "21/2/98" to "1998-02-28"
        my $in = shift;
        if ($in =~/^(\d{1,2})\/(\d{1,2})\/(\d{2}).*/)
        {
            my $day=$1;
            my $month=$2;
            my $year=$3;
            if ($day=~m/^\d$/) {$day="0".$day;}
            if ($month=~m/^\d$/) {$month="0".$month;}
            if (int($year)>13)
            {$year="19".$year;}
            else {$year="20".$year;}
            return "$year-$month-$day";
        }
        else
        {
            return $in;
        }
    }
    
    sub trim {
        # This function removes ",00" at the end of a string
        my $in = shift;
        $in=~s/,00$//;
        return $in;
    }
';
$record13 = MARC::Transform->new($record13,$yaml13);
#print "\n--transformed record--\n". $record13->as_formatted ."\n";
my $v13a=recordtostring($record13);
my $v13b="                        ||||501:  |a:foo|b:2010-13-08|c:40|d:40,00";
is($v13a,$v13b,"");

#test 14
my $record14 = MARC::Record->new();
$record14->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'b' => 'bar', 'c' => '40,00') );
#print "--init record--\n". $record14->as_formatted;
my $yaml14 = '
---
condition : $f501a eq "foo"
update :
 b : \&areturn_record_encoding()
 c : \&atrim("$this")
---
global_subs: >
 sub areturn_record_encoding {
     $record->encoding();
 }
 
 sub atrim {
     # This function removes ",00" at the end of a string
     my $in = shift;
     $in=~s/,00$//;
     return $in;
 }
';
$record14 = MARC::Transform->new($record14,$yaml14);
#print "\n--transformed record--\n". $record14->as_formatted ."\n";
my $v14a=recordtostring($record14);
my $v14b="                        ||||501:  |a:foo|b:MARC-8|c:40";
is($v14a,$v14b,"");

#test 15
my $record15 = MARC::Record->new();
$record15->insert_fields_ordered( MARC::Field->new( '501', '', '', 'b' => 'bar', 'c' => '1') );
#print "--init record--\n". $record15->as_formatted;
my $yaml15 = '
---
-
 condition : $f501b eq "bar"
 create :
  f604a : \&LUT("$f501b")
 update :
  c : \&LUT("$this")
-
 LUT :
  1 : first
  2 : second
  bar : openbar
';
$record15 = MARC::Transform->new($record15,$yaml15);
#print "\n--transformed record--\n". $record15->as_formatted ."\n";
my $v15a=recordtostring($record15);
my $v15b="                        ||||501:  |b:bar|c:first||604:  |a:openbar";
is($v15a,$v15b,"");

#test 16
my $record16 = MARC::Record->new();
$record16->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => '1', 'a' => '3', 'b' => 'foo', 'c' => 'SF') );
#print "--init record--\n". $record16->as_formatted;
my %mth16;
my $yaml16 = '
---
-
 update :
  f501a : \&LUT("$this","numbers")
  f501b : \&LUT("$this","cities")
  f501c : \&LUT("$this","cities")
---
global_LUT:
 cities:
  NY : New York
  SF : San Fransisco
  TK : Tokyo
  _default_value_ : unknown city
 numbers:
  1 : one
  2 : two
';
$record16 = MARC::Transform->new($record16,$yaml16,\%mth16);
#print "\n--transformed record--\n". $record16->as_formatted ."\n";
my $v16a=recordtostring($record16);
$v16a.=$mth16{"_defaultLUT_to_mth_"}->{"cities"}[0];
my $v16b="                        ||||501:  |a:3|a:one|b:unknown city|c:San Fransisco";
$v16b.="foo";
is($v16a,$v16b,"");

#test 17
my $record17 = MARC::Record->new();
$record17->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'I want "$"') );
#print "--init record--\n". $record17->as_formatted;
my $yaml17 = '
---
condition : $f501a eq "I want #_dbquote_##_dollars_##_dbquote_#"
create :
 f604a : "#_dbquote_#$f501a#_dbquote_# contain a #_dollars_# sign"
';
$record17 = MARC::Transform->new($record17,$yaml17);
#print "\n--transformed record--\n". $record17->as_formatted ."\n";
my $v17a=recordtostring($record17);
my $v17b='                        ||||501:  |a:I want "$"||604:  |a:"I want "$"" contain a $ sign';
is($v17a,$v17b,"");

#test 18
my $record18 = MARC::Record->new();
$record18->insert_fields_ordered( MARC::Field->new( '995', '', '', 'a' => '1', 'b' => 'foo', 'c' => 'SF') );
$record18->insert_fields_ordered( MARC::Field->new( '995', '', '', 'a' => '2', 'b' => 'foo', 'c' => 'SF') );
$record18->insert_fields_ordered( MARC::Field->new( '995', '', '', 'a' => '1', 'b' => 'foo', 'c' => 'SF') );
#print "--init record--\n". $record18->as_formatted;
my $yaml18 = '
---
condition : $f995a eq "2"
update :
 b : updated value of all \'b\' subfields in the condition field
 $f995a : 3
 f995c : updated
';
$record18 = MARC::Transform->new($record18,$yaml18);
#print "\n--transformed record--\n". $record18->as_formatted ."\n";
my $v18a=recordtostring($record18);
my $v18b="                        ||||995:  |a:1|b:foo|c:updated||995:  |a:1|b:foo|c:updated||995:  |a:3|b:updated value of all 'b' subfields in the condition field|c:updated";
is($v18a,$v18b,"");

#test 19
my $record19 = MARC::Record->new();
$record19->leader('optionnal leader');
$record19->insert_fields_ordered( MARC::Field->new( '500', '', '', 'a' => '0123456789abcd') );
#print "--init record--\n". $record19->as_formatted;
my $yaml19 = '
---
condition : $ldr6 eq "n" and $f500a11 eq "b"
create :
  f604a : ok
';
$record19 = MARC::Transform->new($record19,$yaml19);
#print "\n--transformed record--\n". $record19->as_formatted ."\n";
my $v19a=recordtostring($record19);
my $v19b="optionnal leader||||500:  |a:0123456789abcd||604:  |a:ok";
is($v19a,$v19b,"");

#test 20
my $record20 = MARC::Record->new();
$record20->leader('optionnal leader');
#$record20->insert_fields_ordered( MARC::Field->new( '500', '', '', 'a' => 'var') );
#print "--init record--\n". $record20->as_formatted;
my %mt;
$mt{"inc"}=1;
$mt{"var"}="a string";
my $yaml20 = '
---
condition : $$mth{"var"} eq "a string"
create :
 f500a : $$mth{"var"}
---
-
 execute : \&test20a()
-
 subs: >
    sub test20a { $$mth{"inc"}++; }
---
create :
 f600a : \&test20b()
---
global_subs: >
    sub test20b { $$mth{"inc"}++;$$mth{"inc"}; }

';
$record20 = MARC::Transform->new($record20,$yaml20,\%mt);
#print "\n--transformed record--\n". $record20->as_formatted ."\n";
#print recordtostring($record20);
my $v20a=recordtostring($record20);
my $v20b="optionnal leader||||500:  |a:a string||600:  |a:3";
is( $v20a, $v20b, "" );

#test 21
my $record21 = MARC::Record->new();
$record21->leader('optionnal leader');
$record21->insert_fields_ordered( MARC::Field->new( '327', '', '', 'a' => 'blabla') ); 
$record21->insert_fields_ordered( MARC::Field->new( '464', '', '', 'a' => 'Bar', 'b' => 'Bbr') );
#print "--init record--\n". $record21->as_formatted;
my $yaml21 = '
---
condition : $f327a
delete : a
---
condition : $f464a
delete : $f464a
';
$record21 = MARC::Transform->new($record21,$yaml21);
#print "\n--transformed record--\n". $record21->as_formatted ."\n";
my $v21a=recordtostring($record21);
my $v21b="optionnal leader||||464:  |b:Bbr";
is($v21a,$v21b,"");

#test 22
my $record22 = MARC::Record->new();
$record22->leader('optionnal leader');
$record22->insert_fields_ordered( MARC::Field->new( '327', '', '', 'a' => 'blabla', 'a' => 'blbl') );
#print "--init record--\n". $record22->as_formatted;
my $yaml22 = '
---
condition : $f327a
duplicatefield : $f327 > f464
';
$record22 = MARC::Transform->new($record22,$yaml22);
#print "\n--transformed record--\n". $record22->as_formatted ."\n";
my $v22a=recordtostring($record22);
my $v22b="optionnal leader||||327:  |a:blabla|a:blbl||464:  |a:blabla|a:blbl";
is($v22a,$v22b,"");

#test 23
my $record23 = MARC::Record->new();
$record23->leader('optionnal leader');
$record23->insert_fields_ordered( MARC::Field->new( '105', '', '', 'a' => '0123456789abcd') );
#print "--init record--\n". $record23->as_formatted;
my $yaml23 = '
---
condition : $f105a4 ne "m"
create :
  f604a : ok
';
$record23 = MARC::Transform->new($record23,$yaml23);
#print "\n--transformed record--\n". $record23->as_formatted ."\n";
my $v23a=recordtostring($record23);
my $v23b="optionnal leader||||105:  |a:0123456789abcd||604:  |a:ok";
is($v23a,$v23b,"");

#test 24
my $record24 = MARC::Record->new();
$record24->leader('optionnal leader');
#$record24->insert_fields_ordered( MARC::Field->new( '500', '', '', 'a' => 'var') );
#print "--init record--\n". $record24->as_formatted;
my %mth24;
$mth24{"inc"}=1;
$mth24{"var"}="a string";
my $yaml24 = '
---
condition : $$mth{"var"} eq "a string"
forceupdate :
 f500a : $$mth{"var"}
---
-
 execute : \&test24a()
-
 subs: >
    sub test24a { $$mth{"inc"}++; }
---
forceupdate :
 f600a : \&test24b()
---
global_subs: >
    sub test24b { $$mth{"inc"}++;$$mth{"inc"}; }
';
$record24 = MARC::Transform->new($record24,$yaml24,\%mth24);
$record24 = MARC::Transform->new($record24,$yaml24,\%mth24);
#print "\n--transformed record--\n". $record24->as_formatted ."\n";
#print recordtostring($record24);
my $v24a=recordtostring($record24);
my $v24b="optionnal leader||||500:  |a:a string||600:  |a:5";
is( $v24a, $v24b, "" );

#test 25
my $record25 = MARC::Record->new();
$record25->insert_fields_ordered( MARC::Field->new( '501', '', '', 'a' => 'foo', 'a' => 'bar') );
#print "--init record--\n". $record25->as_formatted;
my $yaml25 = '---
delete : f501a
';
$record25 = MARC::Transform->new($record25,$yaml25);
#print "\n--transformed record--\n". $record25->as_formatted ."\n";
my $v25a=recordtostring($record25);
my $v25b="                        ||||501:  ";
is($v25a,$v25b, "" );

#test 26
my $record26 = MARC::Record->new();
$record26->leader('012345gs0 2200253   4500');
$record26->insert_fields_ordered( MARC::Field->new( '008', 'd') );
$record26->insert_fields_ordered( MARC::Field->new( '215', '', '', 'v' => 'd') );
$record26->insert_fields_ordered( MARC::Field->new( '099', '', '', 't' => '13', 'v' => 'd') );
$record26->insert_fields_ordered( MARC::Field->new( '115', '', '', 'v' => 'd') );
$record26->insert_fields_ordered( MARC::Field->new( '116', '', '', 'v' => 'd') );
$record26->insert_fields_ordered( MARC::Field->new( '117', '', '', 'v' => 'd') );
$record26->insert_fields_ordered( MARC::Field->new( '135', '', '', 'a' => 'vo') );
$record26->insert_fields_ordered( MARC::Field->new( '463', '', '', 'v' => 'd') );
$record26->insert_fields_ordered( MARC::Field->new( '464', '', '', 'v' => 'd') );
#print "--init record--\n". $record26->as_formatted;
my $yaml26 = '---
condition : $ldr6 eq "g" or $f135a1 eq "o"
forceupdate :
 f9950 : test0
---
condition : $f215v eq "d" or $f115a eq "a"
forceupdate :
 f995a : test1
---
condition : $ldr6 eq "g" or $f115a
forceupdate :
 f995b : test2
---
condition : $f115b or $f115v
forceupdate :
 f995c : test3
---
condition : $f215v or $f115v
forceupdate :
 f995d : test4
---
condition : $f115b or $f115v
forceupdate :
 f995e : test5
---
condition : $f116b or $f116v eq "d"
forceupdate :
 f995f : test6
---
condition : $f117b eq "1" or $f117v eq "d"
forceupdate :
 f995g : test7
---
condition : $f463 or $f464
forceupdate :
 f995h : test8
---
condition : ($f463 or $f464) and $f008_ eq "d"
forceupdate :
 f995i : test9
---
condition : $f099t eq "13" and ($f135a0 eq "v" or $f135a1 eq "o")
forceupdate :
 f995j : test10
---
condition : $f008 or $f009
forceupdate :
 f995k : test11
---
condition : $f117b and $f117v
forceupdate :
 f995k : testbad
---
condition : $f463v eq "d" and $f135
forceupdate :
 f700a : test0
---
condition : ($f463v eq "d" or $f464v eq "d") or $f008
forceupdate :
 f463v : test0
';
$record26 = MARC::Transform->new($record26,$yaml26);
#print "\n--transformed record--\n". $record26->as_formatted ."\n";
my $v26a=recordtostring($record26);
my $v26b="012345gs0 2200253   4500||||008:d||099:  |t:13|v:d||115:  |v:d||116:  |v:d||117:  |v:d||135:  |a:vo||215:  |v:d||463:  |v:test0||464:  |v:d||700:  |a:test0||995:  |0:test0|a:test1|b:test2|c:test3|d:test4|e:test5|f:test6|g:test7|h:test8|i:test9|j:test10|k:test11";
is($v26a,$v26b, "" );

#test 27
my $record27 = MARC::Record->new();
$record27->leader('01499nam0 2200301   4500');
$record27->insert_fields_ordered( MARC::Field->new( '008', 'y   7   000yy') );
$record27->insert_fields_ordered( MARC::Field->new( '105', '', '', 'a' => 'y   7   000yy') );
#print "--init record--\n". $record27->as_formatted;
my $yaml27 = '---
-
 condition : ($ldr7 eq "m") and ($ldr6 eq "a" or $ldr6 eq "m" or $ldr6 eq "l") and ($f105a4 ne "m") and ($f105a4 ne "v") and ($f105a4 ne "7")
 create :
  f099t : LIV
-
 condition : $f105a4 eq "m" or $f105a4 eq "v" or $f105a4 eq "7"
 create :
  f099t : THE
-
 create :
  f099t : AUT
';
$record27 = MARC::Transform->new($record27,$yaml27);
#print "\n--transformed record--\n". $record27->as_formatted ."\n";
my $v27a=recordtostring($record27);
my $v27b="01499nam0 2200301   4500||||008:y   7   000yy||099:  |t:THE||105:  |a:y   7   000yy";
is($v27a,$v27b,"");

#test 28
my $record28 = MARC::Record->new();
$record28->leader('01499nam0 2200301   4500');
$record28->insert_fields_ordered( MARC::Field->new( '997', '', '', 'a' => 'value') );
$record28->insert_fields_ordered( MARC::Field->new( '998', '', '', 'a' => 'value') );
$record28->insert_fields_ordered( MARC::Field->new( '999', '', '', 'a' => 'value') );
#print "--init record--\n". $record28->as_formatted;
my $yaml28='---
condition : defined $f997
update :
 $f997a : b$this
---
condition : defined $f998
create :
 $f998a : ESC
---
condition : defined $f999
create :
 a : ESC
';
$record28 = MARC::Transform->new($record28,$yaml28);
#print "\n--transformed record--\n". $record28->as_formatted ."\n";
my $v28a=recordtostring($record28);
my $v28b="01499nam0 2200301   4500||||997:  |a:bvalue||998:  |a:ESC|a:value||999:  |a:ESC|a:value";
is($v28a,$v28b,"");
