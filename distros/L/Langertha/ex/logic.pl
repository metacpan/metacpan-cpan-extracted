#!/usr/bin/env perl
# ABSTRACT: Synopsis examples

$|=1;

use FindBin;
use lib "$FindBin::Bin/../lib";

use utf8;
use open ':std', ':encoding(UTF-8)';
use strict;
use warnings;
use Data::Dumper qw( Dumper );
use Time::HiRes qw( time );

use Langertha::Engine::Ollama;

use Text::ASCIITable;

my $entities = join(', ',qw(
  Person
  Company
  Organization
  Country
  City
));

my $system_prompt = <<__EOP__;

-Goal-

Given a text document that is potentially relevant to this activity and a list of entity types, identify all entities of those types from the text and all relationships among the identified entities.
 
-Steps-

1. Identify all entities. For each identified entity, extract the following information:

- entity_name: Name of the entity
- entity_type: One of the following types: [$entities]
- entity_description: Comprehensive description of the entity's attributes and activities

Format each entity as ("entity";<entity_name>;<entity_type>;<entity_description>)
 
2. From the entities identified in step 1, identify all pairs of (source_entity, target_entity) that are *clearly related* to each other.

For each pair of related entities, extract the following information:
- source_entity: name of the source entity, as identified in step 1
- target_entity: name of the target entity, as identified in step 1
- relationship_description: explanation as to why you think the source entity and the target entity are related to each other
- relationship_strength: a numeric score indicating strength of the relationship between the source entity and target entity
 Format each relationship as ("relationship";<source_entity>;<target_entity>;<relationship_description>;<relationship_strength>)
 
3. Return output in English as a single list of all the entities and relationships identified in steps 1 and 2. Use a new line as the list delimiter.

4. When finished, output __END_OF_PARSING__

Examples: 

Example 1:
Entity_types: Organization, Person
Text:
The Verdantis's Central Institution is scheduled to meet on Monday and Thursday, with the institution planning to release its latest policy decision on Thursday at 1:30 p.m. PDT, followed by a press conference where Central Institution Chair Martin Smith will take questions. Investors expect the Market Strategy Committee to hold its benchmark interest rate steady in a range of 3.5%-3.75%.
Output:
("entity";Central Institution;Organization;The Central Institution is the Federal Reserve of Verdantis, which is setting interest rates on Monday and Thursday)
("entity";Martin Smith;Person;Martin Smith is the chair of the Central Institution)
("entity";Market Strategy Committee;Organization;The Central Institution committee makes key decisions about interest rates and the growth of Verdantis's money supply)
("relationship";Martin Smith;Central Institution;Martin Smith is the Chair of the Central Institution and will answer questions at a press conference;9)
__END_OF_PARSING__

Example 2:
Entity_types: Organization
Text:
TechGlobal's (TG) stock skyrocketed in its opening day on the Global Exchange Thursday. But IPO experts warn that the semiconductor corporation's debut on the public markets isn't indicative of how other newly listed companies may perform.
TechGlobal, a formerly public company, was taken private by Vision Holdings in 2014. The well-established chip designer says it powers 85% of premium smartphones.
Output:
("entity";TechGlobal;Organization;TechGlobal is a stock now listed on the Global Exchange which powers 85% of premium smartphones)
("entity";Vision Holdings;Organization;Vision Holdings is a firm that previously owned TechGlobal)
("relationship";TechGlobal;Vision Holdings;Vision Holdings formerly owned TechGlobal from 2014 until present;5)
__END_OF_PARSING__

__EOP__

my $prompt = <<__EOP__;

######################
-Real Data-
######################
Entity_types: $entities
Text:
The Commercial Space Launch Act of 1984 required encouragement of commercial space ventures, adding a new clause to NASA's mission statement:

(c) Commercial Use of Space. --Congress declares that the general welfare of the United States requires that the Administration seek and encourage, to the maximum extent possible, the fullest commercial use of space.
Yet one of NASA's early actions was to effectively prevent private space flight through a large amount of regulation. From the beginning, though, this met significant opposition not only by the private sector, but in Congress. In 1962, Congress passed its first law pushing back the prohibition on private involvement in space, the Communications Satellite Act of 1962. While largely focusing on the satellites of its namesake, this was described by both the law's opponents and advocates of private space, as the first step on the road to privatisation.

While launch vehicles were originally bought from private contractors, from the beginning of the Shuttle program until the Space Shuttle Challenger disaster in 1986, NASA attempted to position its shuttle as the sole legal space launch option.[14] But with the mid-launch explosion/loss of Challenger came the suspension of the government-operated shuttle flights, allowing the formation of a commercial launch industry.[15]

On 4 July 1982, the Reagan administration released National Security Decision Directive Number 42 which officially set its goal to expand United States private-sector investment and involvement in civil space and space-related activities.[16]

On 16 May 1983, the Reagan administration issued National Security Decision Directive Number 94 encouraging the commercialization of expendable launch vehicles (ELVs), which directed that, "The U.S. Government will license, supervise, and/or regulate U.S. commercial ELV operations only to the extent required to meet its national and international obligations and to ensure public safety."[17]

On 30 October 1984, US President Ronald Reagan signed into law the Commercial Space Launch Act.[18] This enabled an American industry of private operators of expendable launch systems. Prior to the signing of this law, all commercial satellite launches in the United States were restricted by Federal regulation to NASA's Space Shuttle.

On 11 February 1988, the Presidential Directive declared that the government should purchase commercially available space goods and services to the fullest extent feasible and shall not conduct activities with potential commercial applications that preclude or deter Commercial Sector space activities except for national security or public safety reasons.[19]

On 5 November 1990, United States President George H. W. Bush signed into law the Launch Services Purchase Act.[20] The Act, in a complete reversal of the earlier Space Shuttle monopoly, ordered NASA to purchase launch services for its primary payloads from commercial providers whenever such services are required in the course of its activities.

In 1996, the United States government selected Lockheed Martin and Boeing to each develop Evolved Expendable Launch Vehicles (EELV) to compete for launch contracts and provide assured access to space. The government's acquisition strategy relied on the strong commercial viability of both vehicles to lower unit costs. This anticipated market demand did not materialise, but both the Delta IV and Atlas V EELVs remain in active service.

Commercial launches outnumbered government launches at the Eastern Range in 1997.[21]

The Commercial Space Act was passed in 1998 and implements many of the provisions of the Launch Services Purchase Act of 1990.[22]

Nonetheless, until 2004 NASA kept private space flight effectively illegal.[23] But that year, the Commercial Space Launch Amendments Act of 2004 required that NASA and the Federal Aviation Administration legalise private space flight.[24] The 2004 Act also specified a "learning period" which restricted the ability of the FAA to enact regulations regarding the safety of people who might actually fly on commercial spacecraft through 2012, ostensibly because spaceflight participants would share the risk of flight through informed consent procedures of human spaceflight risks, while requiring the launch provider to be legally liable for potential losses to uninvolved persons and structures.[25]
######################
Output:

__EOP__

if ($ENV{OLLAMA_URL}) {

  my $url = URI->new($ENV{OLLAMA_URL});
  my $t = Text::ASCIITable->new({ headingText => 'Entity Test at '.$url->host_port });

  $t->setCols('model','temp','run','time','ents','rels');

  print($system_prompt);

  print(("-" x 50)."\n");

  print($prompt);

  print(("-" x 50)."\n");

  for my $model (qw( llama3.1:8b gemma2:2b gemma2:9b )) {
    print "\n".$model." ";

    for my $run (1..2) {
      print "#".$run." ";
      for my $tempno (0..2) {

        my $temp = ( $tempno * 0.4 ) + 0.1;

        print $temp." ";

        my $ollama = Langertha::Engine::Ollama->new(
          url => $url->as_string,
          model => $model,
          keep_alive => '2s',
          system_prompt => $system_prompt,
          context_size => ( 2048 + 1024 ),
          temperature => $temp,
        );

        my $start = time;
        my $request = $ollama->chat({
          role => 'user',
          content => $prompt,
        });
        my $response = $ollama->user_agent->request($request);
        my $data = $ollama->json->decode($response->content);
        my $reply = $request->response_call->($response);
        my $end = time;

        my $ents = my @ent_list = $reply =~ /\("entity".+\)/g;
        my $rels = my @rel_list = $reply =~ /\("relationship".+\)/g;

        $t->addRow(
          $model,
          $temp,
          $run,
          sprintf('%.2f',($end - $start)),
          $ents,
          $rels,
        );

      }
    }
  }

  #print "\n\n".$t."\n\n";

}

exit 0;

__DATA__

llama3.1:8b

("entity";United States;Country;The United States is a country that has been involved in space-related activities)
("entity";NASA;Organization;NASA is an organization responsible for the US space program)
("entity";Ronald Reagan;Person;Ronald Reagan was the President of the United States who signed the Commercial Space Launch Act into law)
("entity";George H. W. Bush;Person;George H. W. Bush was the President of the United States who signed the Launch Services Purchase Act into law)
("entity";Lockheed Martin;Company;Lockheed Martin is a company that developed Evolved Expendable Launch Vehicles (EELV))
("entity";Boeing;Company;Boeing is a company that developed Evolved Expendable Launch Vehicles (EELV))
("relationship";Ronald Reagan;NASA;Ronald Reagan signed the Commercial Space Launch Act into law, which encouraged commercial space ventures and added a new clause to NASA's mission statement;8)
("relationship";George H. W. Bush;NASA;George H. W. Bush signed the Launch Services Purchase Act into law, which ordered NASA to purchase launch services from commercial providers;9)
("relationship";Lockheed Martin;Boeing;Both Lockheed Martin and Boeing developed Evolved Expendable Launch Vehicles (EELV) to compete for launch contracts;7)
("relationship";United States;NASA;The United States government has been involved in space-related activities through NASA;10)

("entity";United States;Country;The United States is a country where various space-related activities are taking place)
("entity";Ronald Reagan;Person;Ronald Reagan was the President of the United States who signed the Commercial Space Launch Act in 1984)
("entity";George H. W. Bush;Person;George H. W. Bush was the President of the United States who signed the Launch Services Purchase Act in 1990)
("entity";Lockheed Martin;Company;Lockheed Martin is a company that developed an Evolved Expendable Launch Vehicle (EELV) to compete for launch contracts)
("entity";Boeing;Company;Boeing is a company that developed an Evolved Expendable Launch Vehicle (EELV) to compete for launch contracts)
("relationship";Ronald Reagan;United States;Ronald Reagan was the President of the United States who signed the Commercial Space Launch Act in 1984;8)
("relationship";George H. W. Bush;United States;George H. W. Bush was the President of the United States who signed the Launch Services Purchase Act in 1990;7)
("relationship";Lockheed Martin;Boeing;Both Lockheed Martin and Boeing developed EELVs to compete for launch contracts;6)
("relationship";Ronald Reagan;Commercial Space Launch Act;The Commercial Space Launch Act was signed into law by Ronald Reagan in 1984;9)
("relationship";George H. W. Bush;Launch Services Purchase Act;The Launch Services Purchase Act was signed into law by George H. W. Bush in 1990;8)
("relationship";Lockheed Martin;Boeing;Both Lockheed Martin and Boeing developed EELVs to compete for launch contracts;6)
("entity";NASA;Organization;NASA is the United States government agency responsible for space exploration and development)
("entity";Federal Aviation Administration;Organization;The Federal Aviation Administration is a US government agency responsible for regulating commercial aviation, including space launches)
("relationship";NASA;United States;NASA is a US government agency responsible for space exploration and development;8)
("relationship";Federal Aviation Administration;United States;The Federal Aviation Administration is a US government agency responsible for regulating commercial aviation, including space launches;7)
("relationship";Ronald Reagan;National Security Decision Directive Number 42;Ronald Reagan issued National Security Decision Directive Number 42 to encourage private sector investment in civil space and space-related activities;8)
("relationship";George H. W. Bush;Launch Services Purchase Act;The Launch Services Purchase Act was signed into law by George H. W. Bush in 1990;7)

("entity";United States;Country;The United States requires that the Administration seek and encourage, to the maximum extent possible, the fullest commercial use of space)
("entity";Ronald Reagan;Person;Ronald Reagan signed into law the Commercial Space Launch Act in 1984)
("entity";George H. W. Bush;Person;George H. W. Bush signed into law the Launch Services Purchase Act in 1990)
("entity";Lockheed Martin;Company;Lockheed Martin was selected to develop Evolved Expendable Launch Vehicles (EELV))
("entity";Boeing;Company;Boeing was selected to develop Evolved Expendable Launch Vehicles (EELV))
("relationship";Ronald Reagan;United States;Ronald Reagan signed into law the Commercial Space Launch Act which encouraged commercial space ventures in the United States;8)
("relationship";George H. W. Bush;United States;George H. W. Bush signed into law the Launch Services Purchase Act which ordered NASA to purchase launch services from commercial providers;9)
("relationship";Lockheed Martin;Boeing;Both Lockheed Martin and Boeing were selected to develop Evolved Expendable Launch Vehicles (EELV);8)
("relationship";United States;NASA;The United States government required NASA to purchase launch services from commercial providers;9)

("entity";United States;Country;"The United States requires that the Administration seek and encourage, to the maximum extent possible, the fullest commercial use of space.")
("entity";NASA;Organization;"NASA's mission statement was amended to include a new clause for commercial space ventures.")
("entity";Ronald Reagan;Person;"US President Ronald Reagan signed into law the Commercial Space Launch Act in 1984.")
("entity";George H. W. Bush;Person;"United States President George H. W. Bush signed into law the Launch Services Purchase Act in 1990.")
("entity";Lockheed Martin;Organization;"The United States government selected Lockheed Martin to develop Evolved Expendable Launch Vehicles (EELV) in 1996.")
("entity";Boeing;Organization;"The United States government selected Boeing to develop Evolved Expendable Launch Vehicles (EELV) in 1996.")
("relationship";Ronald Reagan;United States;"Ronald Reagan was the President of the United States when he signed the Commercial Space Launch Act into law.";8)
("relationship";George H. W. Bush;United States;"George H. W. Bush was the President of the United States when he signed the Launch Services Purchase Act into law.";8)
("relationship";NASA;Lockheed Martin;"NASA selected Lockheed Martin to develop Evolved Expendable Launch Vehicles (EELV) in 1996.";7)
("relationship";NASA;Boeing;"NASA selected Boeing to develop Evolved Expendable Launch Vehicles (EELV) in 1996.";7)
("relationship";Ronald Reagan;NASA;"Ronald Reagan signed the Commercial Space Launch Act into law, which affected NASA's mission statement.";8)
("relationship";George H. W. Bush;NASA;"George H. W. Bush signed the Launch Services Purchase Act into law, which required NASA to purchase launch services from commercial providers.";8)



