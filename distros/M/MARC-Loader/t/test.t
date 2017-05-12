#!/usr/bin/perl
use Data::Compare;
use strict;
use warnings;
use lib qw( lib ../lib );
use YAML;
use Test::More 'no_plan';
BEGIN {
    use_ok( 'MARC::Loader' );
}
my $r={
          'ldr' => 'optionnal_leader',
          'orderfields' => 0,
          'ordersubfields' => 0,
          'cleannsb' => 1,
          'f005' => [
                      {
                        'f005_' => 'controlfield_contenta'
                      },
                      {
                        'f005_' => 'controlfield_contentb'
                      }
                    ],
          'f006_' => 'controlfield_content',
          'f995' => [
                      {
                        '001##f995e' => 'Salle de lecture 1',
                        '002##f995b' => 'MP',
                        '003##f995k' => 'NT 0380/6/1',
                        '004##f995c' => 'MPc',
                        '005##f995f' => '8001-ex',
                        '006##f995r' => 'PRET',
                        '007##f995o' => '0'
                      },
                      {
						'i9951' => '1',
						'i9952' => '2',
                        'f995e' => 'Salle de lecture 2',
                        'f995b' => 'MP',
                        'f995k' => 'NT 0380/6/1',
                        'f995c' => 'MPc',
                        'f995f' => '8002-ex',
                        'f995r' => 'PRET',
                        'f995o' => '0'
                      },
                      {
                        'f995e' => 'Salle de lecture 3',
                        'f995b' => 'MPS',
                        'f995k' => 'MIS 0088',
                        'f995c' => 'MPS',
                        'f995f' => '8003-ex',
                        'f995r' => 'PRET',
                        'f995o' => '0'
                      }
                    ],
          'f215a' => [
                       '201'
                     ],
          'f615' => [
                      {
                        'f615a' => 'CATHEDRALE'
                      },
                      {
                        'f615a' => 'BATISSEUR'
                      }
                    ],
          'f210a' => [
                       'Paris'
                     ],
          '001##f300' => [
                      {
                        'f300a' => 'tabl. photos'
                      }
                    ],
          'f035a' => '8002',
          'i0992' => '4',
          'f702' => [
                      {
                        'f702f' => '1090?-1153',
                        'f7024' => '730',
                        'f702a' => 'Bernard de Clairvaux'
                      }
                    ],
          'f010d' => '45',
          'f200a' => "\x88Les \x89ouvriers des calanques",
          'i0991' => '3',
          'f210c' => [
                       'La Martiniere'
                     ],
          'f010a' => [
                       '111242417X'
                     ],
          'f461' => [
                      {
                        'f461v' => '48'
                      },
                      {
                        'f461v' => '61'
                      }
                    ],
          'f099c' => '2011-02-03',
          'f700' => [
                      {
                        'f700f' => '',
                        'f700a' => 'ICHERFrancois'
                      },
                      {
                        'f700f' => '1353? - 1435',
                        'f700a' => 'PAULUS',
                        'f700b' => [ 'jean','francois']
                      }
                    ],
          'f099d' => '',
          'f225' => [
                      {
                        'f225a' => 'Sources calanquaises',
                        'f225v' => '48'
                      },
                      {
                        'f225a' => 'Calanquaises Kommentar',
                        'f225v' => '61'
                      }
                    ],
          'f210d' => '1998',
          'f200g' => [
                       'ITHER, fred',
                       'Facundus,hector (05..?-0571?)',
                       'Bernard de Clairvaux (saint ; 1090?-1153)'
                     ],
          'f101a' => [
                       'lat',
                       'fre',
                       'ger',
                       'gem',
                       'por',
                       'spa'
                     ],
          'f099t' => 'LIVRE',
          'f200f' => 'ICHERFrancois, PAULUS, MARIA 1353? - 1435',
          'f330' => [],
          'f701' => [
                      {
                        'f701f' => '',
                        'f701a' => 'ITHER',
                        'f701b' => 'fred'
                      },
                      {
                        'f701f' => '05..?-0571?',
                        'f701a' => 'Facundus',
                        'f701b' => 'hector'
                      }
                    ],
          'f215c' => 'ill. coul.'
        };

my $record = MARC::Loader->new($r);
#my $v1=YAML::Dump $record->as_formatted;
#print recordtostring($record);
my $v1=recordtostring($record);
my $v2="optionnal_leader||||005:controlfield_contenta||005:controlfield_contentb||006:controlfield_content||010:  |a:111242417X|d:45||035:  |a:8002||099:34|c:2011-02-03|t:LIVRE||101:  |a:fre|a:gem|a:ger|a:lat|a:por|a:spa||200:  |a:Les ouvriers des calanques|f:ICHERFrancois, PAULUS, MARIA 1353? - 1435|g:Bernard de Clairvaux (saint ; 1090?-1153)|g:Facundus,hector (05..?-0571?)|g:ITHER, fred||210:  |a:Paris|c:La Martiniere|d:1998||215:  |a:201|c:ill. coul.||225:  |a:Calanquaises Kommentar|v:61||225:  |a:Sources calanquaises|v:48||300:  |a:tabl. photos||461:  |v:48||461:  |v:61||615:  |a:BATISSEUR||615:  |a:CATHEDRALE||700:  |a:ICHERFrancois||700:  |a:PAULUS|b:francois|b:jean|f:1353? - 1435||701:  |a:Facundus|b:hector|f:05..?-0571?||701:  |a:ITHER|b:fred||702:  |4:730|a:Bernard de Clairvaux|f:1090?-1153||995:  |b:MPS|c:MPS|e:Salle de lecture 3|f:8003-ex|k:MIS 0088|o:0|r:PRET||995:  |b:MP|c:MPc|e:Salle de lecture 1|f:8001-ex|k:NT 0380/6/1|o:0|r:PRET||995:12|b:MP|c:MPc|e:Salle de lecture 2|f:8002-ex|k:NT 0380/6/1|o:0|r:PRET";

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

ok(Compare($v1,$v2))
    or diag(Dump $v1);
#print $record->as_formatted;
