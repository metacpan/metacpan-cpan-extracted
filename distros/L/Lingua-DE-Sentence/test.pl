# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Lingua::DE::Sentence;
$loaded = 1;
print "ok 1\n";


use Lingua::DE::Sentence;

$splitting = 1;
$test_data = join ("", (<DATA>));
while ($test_data =~ m%\|([^\|]*?)\|%g) {
    push @exp_sent, $1;
}
$test_data =~ s/\|//g;
$real_sent = get_sentences($test_data);

for ($i=0; $i<scalar @exp_sent; $i++) {
    unless ($exp_sent[$i] eq $real_sent->[$i]) {
	print 
	    "not ok 2 ",
	    "Splitting is not correct: ",
	    "expected:  $exp_sent[$i] ",
	    "but found: $real_sent->[$i]";
	$splitting = 0;
	last;
    }
}
print "ok 2\n" if $splitting;

__DATA__

 |Durch den 1781 von Herschel entdeckten Planeten Uranus wurde der Horizont des Planetensystems unserer Sonne um das Doppelte erweitert.| |Dieser Planet ist nämlich noch einmal so weit als Saturn - 400 Millionen Meilen von der Sonne entfernt.| |Er vollendet seine lange Reise um die Sonne erst in 84 Jahren und 6 Trabanten umkreisen ihn.| |Die Entdeckung der vier kleinen Planeten, durch welche die früher unterbrochene harmonische Progression in den Abständen der Planeten, sich vollständiger zu bestätigen scheint, verdanken wir den Deutschen.| |Piazzi, in Deutschland geboren, entdeckte am 1ten Jan. 1801 zu Palermo glücklich einen zwischen Mars und Jupiter früher vermutheten Planeten, dem er den Namen Ceres beilegte.| |Kaum 1½ Jahre nachher hatte Olbers in Bremen das Glück einen 2ten planetarischen Körper zwischen Mars und Jupiter aufzufinden, den er Pallas nannte.| |Am 1ten Septbr. 1804 entdeckte Prof. Harding zu Lilienthal einen dritten neuen Planeten, ungefähr in demselben mittleren Abstande von der Sonne als Ceres und Pallas.| |Man hat ihn Juno genannt.| - |Endlich hat Olbers am 29ten Maerz 1807 abermals einen 4ten Planeten zwischen Mars und Jupiter entdeckt, der von dem großen Gaus in Goettingen den Namen Vesta erhielt.| |Außer diesen nunmehr bekannten Haupt und Nebenplaneten gibt es im weiten Reiche unserer Sonne noch eine ungleich größere Anzahl anderer Weltkörper welche mehrentheils in langen elliptischen Bahnen sich um die Sonne drehen.| |Dies sind die Kometen.| |Ueber diese hat sich neuerlich die Meinung der Astronomen sehr geändert.| |Jener Gedanke namentlich, daß sie ein Planetensystem mit dem andern verbinden, ist ganz verschwunden; obgleich einige sich sehr weit von der Sonne entfernen müssen, indem ihre Sonnennähe zwischen Jupiter und Saturn liegt.| - |Man hat bis jetzt Kometen welche von der Erde aus sichtbar gewesen sind 400 beobachtet, nur 128 wirklich gemessen.| |Rechnen wir aber alle dazu, welche außerhalb der Erde ihre Bahnen ziehen, so kann ihre Zahl leicht auf einige l00,000 gesteigert werden, welche alle zu unserm Planetensystem gehören.| - |Die wichtigste Entdeckung in dieser Hinsicht machte in der neuesten Zeit unser Astronom Enke.| |Er berechnete die Bahn eines Kometen, der in 3½ Jahrn seinen Umlauf vollendet.| |Bei seinem letzten Erscheinen hatte er sein Wiederkommen genau vorhergesagt, und es entdeckte ihn zuerst Rühmker in Paramatta auf Neuholland.| |Nur fand man, daß er sich ein wenig verspätet hatte, und dies führte auf die bewegungshemmende Eigenschaft des Aethers.| |Dieser Komet ist nun schon 5 mal beobachtet.| - |Der Hauptmann Biela in Böhmen entdeckte später einen 2ten Kometen, der in 6½ Jahren seinen Weg um die Sonne zurücklegt.| - |Der berühmte Halley sagte die Wiederkunft eines Kometen auf das Jahr 1759 voraus, den der sternkundige Landmann Palitsch bei Dresden wirklich am 25 Decbr. 1758 zuerst wiedersehe.| |Hätte man damals die Masse des Jupiters und Saturns genauer und die Existenz des Uranus gekannt, so würde man eine Genauigkeit von 5-6 Tagen erreicht haben.| |Von allen Kometen welche beobachtet, und deren Bahnen berechnet worden, ist keiner unserer Erde so nahe gekommen, als der von Biela entdeckte; und allerdings könnte uns dieser gefährlich werden, da man berechnet hat, daß einer seiner Knoten wirklich innerhalb der Erdbahn liegt.| |Die große Leichtigkeit dieser Weltkörper kann uns jedoch von aller Besorgniß befreien; denn man hat nachgewiesen, daß einer derselben (der von 1770) durch das Trabantensystem des Jupiter gegangen ist, ohne dasselbe im mindesten in Unordnung zu bringen.| |Die Dichtigkeit der Kometen beträgt 1/5000 von der Dichtigkeit der Erde.| |Sie sind also noch weit dünner, als die dünnste Luft, welche wir unter der Luftpumpe hervorbringen können.| |Zu den merkwürdigsten, bisher noch keineswegs genügend erklärten Erscheinungen gehören die Aerolithen, jene größeren und kleineren Steinmassen, welche aus den Himmelsräumen zu uns herabkommen.| |Chladni hat das Verdienst, auf dieses schon den Alten unter dem Namen von Steinregen bekannte Phänomen, von neuem aufmerksam gemacht, und neue Erfahrungen darüber gesammelt zu haben.| |Die verschiedensten Hypothesen sind aufgestellt worden, um den Ursprung dieser Massen zu erklären, die in den meisten Fällen aus terrestrischen Stoffen (Eisen, Nickel etc) gebildet scheinen, und in denen Gustav Rose sogar das Vorkommen crystallinischer Theile nachgewiesen hat.| - |Einige haben sie für vulkanische Auswürfe der Erde erklären wollen; andere sie für Producte von Mondseruptionen gehalten, welche wahrscheinlichere Meinung in der auf dem Monde 5 mal geringeren Schwere, und der großen Feinheit seiner Atmosphäre, die der Bewegung keinen merklichen Widerstand entgegen setzen kann, einen Stützpunkt findet.| - |Die Annahme, daß die Bestandtheile dieser Massen, sich aufgelöst im Luftkreise vorfinden sollten, und durch irgend eine elektrische Explosion, (die Feuerkugeln, welche die Erscheinung gewöhnlich begleiten) im Moment des Herabfallens vereinigt würden, hat wenig Haltbarkeit, da mindestens ein Raum von 4-5 Meilen Luft erforderlich wäre, um ähnliche Massen aufgelöst zu enthalten.| |Einige glauben Ueberbleibsel der ehemaligen chaotischen Massen darin zu erkennen, und wir mögten sie geradezu für planetarische Weltkörper erklären, die gleich den übrigen im Weltall kreisen, bis sie der Attractionssphäre des Einen oder Andern sich nähernd, auf fremden Bahnen ihren Untergang finden.| |Die Kleinheit derselben darf dieser Annahme nicht entgegen stehen.| |Der kleinste Hauptplanet ist im Verhältniß gegen den Syrius viel kleiner als der größte Aerolith im Vergleich mit der Vesta.| |Bei allen Messungen im Weltraume ist es weit interressanter die Größen und Zahlen in ihrer relativen Ausdehnung zu kennen, als in ihrer absoluten: gerade wie bei den Berghöhen.| |Die Schneekoppe ist ½ mal so hoch als der höchste Gipfel der Pyrenäen; der Pic von Teneriffa ½ von der Spitze des Himalaya; der Brocken 1/6 des Chimborazo.| |So wird auch eine vergleichende Berechnung von der Größe des Weltraums, wie sie Herschel anstellte, hier an ihrem Platze seyn.| |Man setze den Durchmesser unseres Sonnensystems mit den äußersten Kometenbahnen = 1 Linie: so wird die größere Axe unserer linsenförmigen Sternschicht = 260 Fuß seyn; und von uns bis zum fernsten Nebelfleck = 4¾ geogr. Meilen.| |Die Sehweite des bewaffneten Auge ist also 4¾ Meile, die des unbewaffneten in gleichem Verhältniß 5 Fuß.| - |Man hat Infusionsthiere beobachtet, deren Durchmesser 1/1000 einer Linie beträgt.| |Diese verhalten sich zu einem Wallfisch von 60-70 Fuß Länge, wie der Durchmesser unseres Sonnensystems, zu der Entfernung desselben von den weitesten Nebelflecken.| |Bei allen diesen Erscheinungen ist natürlich eine Ungewißheit vorhanden, welche nur dadurch verringert wird, daß man sie in ganz bestimmte Gränzen einschließen läßt.| |So weiß man mit Bestimmtheit, daß der Sirius 10,000 mal weiter von uns entfernt ist als Uranus, weil seine Parallaxe noch nicht 1/5 Sek. beträgt.| - |Bei der Entfernung des Mondes von 51,000 Meilen ist man nur um 14-15 Meilen ungewiß, welches so viel heißt, als ob man bei der Höhe des Brockens 3200 Fuß, um 1-2 Fuß ungewiß wäre.| |Wenn wir nunmehr zu den tellurischen Verhältnissen übergehen, so müssen wir zuerst zwei flüssige Hüllen um den Erdkörper bemerken, die des Meeres und der Luft, wodurch man schon auf die Kugelgestalt der Erde geführt werden können.| |Schon Aristoteles stellt die Behauptung auf, daß die Erde rund sey, weil man bei den Mondfinsternissen den Erdschatten rund in die Mondscheibe eintreten sieht.| |Die Erde hat aber keine vollkomne Kugelgestalt, mit gleichem Durchmesser, sondern bildet vielmehr ein Sphäroïd mit starker Abplattung an den Polen.| |Diese Abplattung ist bedeutender als man früher glaubte.| |Man nahm sie sonst zu 1/305-1/310 an.| |Jetzt weiß man, daß sie zwischen 1/289-1/290 liegt.| - |Eben so hielt man früher die Figur des Erdsphäroids für unregelmäßig, und glaubte die südliche Hemisphäre abgeplatteter als die nördliche.| |Nach Freycinets und Duperrés sehr genauen Messungen ist erweislich dies nicht der Fall, und die Regelmäßigkeit dieser um so viel größer.| |Die specifische Dichtigkeit der Erde ist sehr beträchtlich; sie ist 4-5 mal größer als die des Wassers.| |Die Attraction der Berge, nach deren Einwirkung auf die Pendelschwingungen man die Schwere der Erde berechnet hat, gab verschiedene Resultate.| |In Schottland 4,7 schwerer als Wasser, am Mont Cénis 4,4 - nach Cavendish Erdwage 5,4.| |Das Mittel aus diesen verschiedenen Angaben würde 4,8-5,0 ergeben.| |Von Cavendish der berühmte Versuche über die Zersetzung des Wassers gemacht hat, sagt man: er habe das Wasser zerlegt und die Erde gewogen.| |Wir müssen aber annehmen, daß im Innern der Erde eine größere Dichtigkeit herscht, als wir in den dichtesten Gebirgsarten antreffen.| |(Die magnetische Spannung der Erde äußert sich horizontal und perpendikular, oft auch oscillirend, und wird durch die innere und äußere Erwärmung vermehrt.| - |Die Versuche von Morechini in Rom haben bewiesen, daß man kleine unmagnetische eiserne Nadeln, durch die Einwirkung der Sonnenstrahlen magnetisiren kann, und diese Versuche die bei der Einwirkung der italienischen Sonne nicht immer gelangen, sind von Miss Sommerville in London, mit vielem Glück wiederholt, nach Wollaston's unverwerflichem Zeugnis.| - |Wir müssen demnach unsere Erde in einer fortdauernd electro-magnetischen Spannung annehmen, und es ist sehr wahrscheinlich, daß diese Spannung durch die Sonnenwärme erhalten wird, wie dies aus Seebeck's schöner Entdeckung vom Thermomagnetismus, der durch ungleiche Erwärmung hervorgerufen wird, und aus anderweiten Beobachtungen der Miss Sommerville über die Sonnenstrahlen hervorgeht.)| |400 Millionen Meilen = 3 Milliarden Kilometer Zurück 4-5 Meilen = 30-38 Kilometer Zurück 1 Linie = 2¼ Millimeter Zurück 260 Fuß = 85 Meter Zurück 4¾ geogr. Meilen = 35 Kilometer Zurück 5 Fuß = 1,6 Meter Zurück 51,000 Meilen = 378,000 Kilometer Zurück 14-15 Meilen = 100-110 Kilometer Zurück 3200 Fuß = 1040 Meter Zurück 1-2 Fuß = 30-60 cm Zurück Vorige Seite Titelseite Nächste Seite|

|Entführung| 

|Willibald Alexis| 

|O Lady Judith, spröder Schatz, Drückt dich zu fest mein Arm?| |Je zwei zu Pferd haben schlechten Platz Und Winternacht weht nicht warm.| |Hart ist der Sitz und knapp und schmal, Und kalt mein Kleid von Erz, Doch kälter und härter als Sattel und Stahl War gegen mich dein Herz.| |Sechs Nächte lag ich in Sumpf und Moor Und hab' um dich gewacht, Doch weicher, bei Sankt Görg ich's schwor, Schlaf' ich die siebente Nacht!|
 |Zwei Krebse "Geh doch gerade und vorwärts!" rief einem jungen Krebs seine Mutter zu.| |"Von Herzen gerne, liebe Mutter", antwortete dieser, "nur möchte ich es dich ebenso machen sehen."| |Jedoch vergeblich war der Mutter Anstrengung und sichtbar ihre Klügelei und Tadelsucht.| |Gib keine Befehle, die man nicht vollbringen kann, und tadle an andern keine Fehler, die du selbst begehst!|
|Die alten und die jungen Frösche| 

|Abraham a Sancta Clara| 

|Die jungen Frösche haben einmal bei warmer Sommerzeit nächst einer Lache über allen Maßen gequackt und geschrien, also zwar, daß ein alter Frosch selbst über diese abgeschmackte Musik verdrüssig geworden und die Jungen nicht wenig ausgefilzt hat.| |"Schamt euch, ihr grünhosenden Fratzen!" sagte er, "ihr wilden Lachendrescher, ihr hupfenden Spitzbuben, schamt euch, daß ihr so ein verdrießlich Geschrei vollführt!| |Wenn ihr aber doch wollt lustig sein und frohlocken, so singt aufs wenigst' wie die Nachtigall, wlche auf diesem nächsten Ast sitzt.| |Ihr großmaulenden Narren, könt ihr denn nichts anderes als nur das Qua-Qua-Qua?"| |"Vater", antworteten die Frösche, "das haben wir von dir gelernt."|
|Dr. Rentschler Dorithricin( Limone Halstabletten|

|Liebe Patientin, lieber Patient!|
|Bitte lesen Sie folgende Gebrauchsinformation aufmerksam, weil sie wichtige Informationen darüber enthält, was Sie bei der Anwendung dieses Arzneimittels beachten sollten.| |Wenden Sie sich bitte bei Fragen an Ihren Arzt oder Apotheker.|

|Gebrauchsinformation
Dorithricin( Limone Halstabletten
Zusammensetzung
1 Lutschtablette enthält:
Arzneilich wirksame Bestandteile:
Tyrothricin			0,5 mg
Lidocainhydrochlorid 1H20	1,0 mg|

|Sonstige Bestandteile:
Povidon, Saccharin-Natrium, Sorbitol, Weinsäure, Talkum, Saccharosestearat, Carmellose-Natrium, Aromen.|

|Darreichungsform und Inhalt
Originalpackung mit 20 (N1) Lutschtabletten|

|Stoff- oder Indikationsgruppe, Wirkungsweise
Dorithricin( Limone Halstabletten wirken zweifach bei schmerzhaften Entzündungen im Mund- und Rachenraum: Das Lokalanästhetikum (örtliches Betäubungsmittel) Lidocain lindert einerseits den Schmerz und die Schluckbeschwerden, andererseits bekämpft das Lokalantibiotikum Tyrothricin effektiv die krankheitsverursachenden Keime.|

|Pharmazeutischer Unternehmer und Hersteller
Dr. Rentschler Arzneimittel GmbH & Co.
Mittelstraße 18, 88471 Laupheim
Telefon (07392) 701-0, Telefax (07392) 701-300|

|Anwendungsgebiete
Entzündliche und infektiöse (ansteckende) Erkrankungen des Mund- und Rachenraums (Entzündungen der Mundschleimhaut und des Zahnfleisches, Mandelentzündungen und Mundsoor), Halsentzündungen, Kehlkopfentzündungen, Infektionen der oberen Luftwege.|
|Vor operativen Eingriffen im Mund und Rachen (Zahnextraktion, Entfernung der Gaumenmandeln).|

|Gegenanzeigen
Wann dürfen Sie Dorithricin( Limone Halstabletten nicht anwenden?|
|Bei einer Überempfindlichkeit gegen einen der Wirk- oder Hilfsstoffe von Dorithricin( Limone Halstabletten sollten Sie dieses Arzneimittel nicht anwenden.|
|Bei größeren frischen Wunden im Mund- und Rachenraum sollten Sie Dorithricin( Limone Halstabletten nicht anwenden.|

|Wann dürfen Sie Dorithricin( Limone Halstabletten erst nach Rücksprache mit Ihrem Arzt anwenden?|
|Im folgenden wird beschrieben, wann Sie Dorithricin( Limone Halstabletten nur unter bestimmten Bedingungen und nur mit besonderer Vorsicht anwenden dürfen.| |Befragen Sie bitte hierzu Ihren Arzt.| |Dies gilt auch, wenn diese Angaben bei Ihnen früher einmal zutrafen.|
|Dorithricin( Limone Halstabletten enthalten Sorbitol.| |Bei angeborener Sorbitol- bzw. Fructose-Unverträglichkeit sollten Sie vor der Anwendung Ihren Arzt befragen.| |Bei einer eitrigen Mandelentzündung mit Fieber ist in jedem Fall vom Arzt zu entscheiden, ob neben den primär notwendigen Behandlungsmaßnahmen wie z.B. einer zusätzlichen Antibiotikagabe, Dorithricin( Limone Halstabletten angewendet werden sollen.|

|Was müssen Sie in Schwangerschaft und Stillzeit beachten?|
|Schädigende Wirkungen durch Dorithricin( Limone Halstabletten sind bisher nicht bekannt geworden.| |Aus grundsätzlichen medizinischen Überlegungen sollte jedoch auf eine strenge Indikationsstellung geachtet werden und vor der Anwendung in jedem Fall mit einem Arzt Rücksprache gehalten werden.|

|Was ist bei Kindern und älteren Menschen zu berücksichtigen?|
|Dorithricin( Limone Halstabletten sind für Säuglinge und Kleinkinder nicht geeignet, das die sachgemäße Anwendung (Lutschen) nicht gewährleistet ist.|

|Vorsichtsmaßnahmen für die Anwendung und Warnhinweise
Worauf müssen Sie achten?|
|Hinweis für Diabetiker
Der in einer Dorithricin( Limone Halstablette eingesetzte Zuckeraustauschstoff Sorbitol entspricht 0,07 BE.|

|Wechselwirkungen
Nicht bekannt.|

|Dosierungsanleitung, Art und Dauer der Anwendung
Die folgenden Angaben gelten, soweit Ihnen Ihr Arzt Dorithricin( Limone Halstabletten nicht anders verordnet hat.| |Bitte halten Sie sich an die Anwendungsvorschriften, da Dorithricin( Limone Halstabletten sonst nicht richtig wirken können.|

|Wie oft, in welcher Menge und wie sollten Sie Dorithricin( Limone Halstabletten anwenden?|
|Soweit nicht anders verordnet, lassen Erwachsene alle 2 Stunden, bis zu 8 mal täglich, eine Lutschtablette langsam im Mund zergehen.|
|Kinder erhalten bis zu 6 mal täglich eine Lutschtablette.|

|Wie lange sollten Sie Dorithricin( Limone Halstabletten anwenden?|
|Die Behandlung soll noch einen Tag nach abklingen der Beschwerden fortgesetzt werden.| |Bei schweren Halsentzündungen oder Halsschmerzen, die mit hohem Fieber, Kopfschmerzen, Übelkeit oder Erbrechen einhergehen, sollten Dorithricin( Limone Halstabletten nicht länger als 2 Tage ohne ärztlichen oder zahnärztlichen Rat angewendet werden.|

|Anwendungsfehler und Überdosierung
Bis jetzt sind keine Vergiftungsfälle nach Anwendung dieses Arzneimittels bekannt.|

|Was müssen Sie beachten, wenn Sie zu wenig Dorithricin( Limone Halstabletten angewendet oder eine Anwendung vergessen haben?|
|Dorithricin( Limone Halstabletten werden mehrmals täglich angewendet.| |Sollten Sie eine Anwendung vergessen haben, können Sie diese jederzeit nachholen.|

|Nebenwirkungen
Welche Nebenwirkungen können bei der Anwendung von Dorithricin( Limone Halstabletten auftreten?|
|In seltenen Fällen kann es zu Überempfindlichkeitsreaktionen oder zu einer Sensibilisierung im Mundbereich kommen.|
|Wenn Sie Nebenwirkungen bei sich beobachten, die nicht in dieser Packungsbeilage aufgeführt sind, teilen Sie diese bitte Ihrem Arzt oder Apotheker mit.|

|Hinweise und Angaben zur Haltbarkeit des Arzneimittels
Das Verfallsdatum dieses Arzneimittels ist auf der Verpackung aufgedruckt.| |Verwenden Sie das Arzneimittel nicht mehr nach diesem Datum!|

|Achten Sie stets darauf, das Arzneimittel so aufzubewahren, daß es für Kinder nicht zu erreichen ist!|

|Stand der Information
Juni 1998|

|Liebe Patientin, lieber Patient,
im Mund-Rachenraum leben ständig mehr Keime als Menschen in der Riesenstadt New York.| |Das Abwehrsystem des Körpers, effektiv wie eine Polizeitruppe, sorgt dafür, daß alle Keimarten in einem ausgewogenen Gleichgewichtsverhältnis zueinander bleiben und dadurch keine Krankheiten auslösen können.| |Erst Störungen von außen, kleine Verletzungen etwa, eine Invasion fremder Krankheitserreger durch Ansteckung, oder auch Schwächen im Abwehrsystem können die friedliche Situation plötzlich verändern.| |Dann finden einzelne Keimarten Gelegenheit, sich in gefährlichem Maße zu vermehren und äußerst aggressiv gegen den Körper zu werden.|
|Wegen der reichlichen Versorgung der Mundhöhle mit Nerven machen sich solche Geschehnisse durch Schmerzen und Krankheitsgefühl bald bemerkbar.| |Der Körper wehrt sich so gut er kann durch vermehrtes Heranführen von Abwehrstoffen mit dem Blutstrom.| |Das Gewebe im Mund und Rachen schwillt an, entzündet und rötet sich.| |Es bilden sich Beläge auf der Schleimhaut.| |Spätestens jetzt ist es notwendig, energisch einzugreifen und den Körper zu unterstützen.| |Dorithricin( Limone Halstabletten bekämpfen die Krankheitserreger intensiv und dämpfen zugleich die Schmerzen nachhaltig.| |Ihr Organismus wird rascher und besser mit der Erkrankung fertig.| |Wenn Sie sich an die Einnahmevorschrift halten, wird der Erfolg nicht ausbleiben.| |Ist trotz richtiger Einnahme nach 2-3 Tagen keine durchgreifende Besserung festzustellen, sollten Sie den Arzt aufsuchen.|
|Dorithricin( Limone Halstabletten sind zuckerfrei und damit zahnschonend und für Diabetiker geeignet.|

|Wir wünschen Ihnen gute Besserung!|
|Ihre Dr. Rentschler Arzneimittel GmbH & Co.|


                       |Logische Optimierung| 


|Logische Optimierung 
Höhere, nichtprozedurale Abfragesprachen (SQL, 
QBE, ...) verlangen keine Kenntnisse des 
Benutzers über die Implementierung, müssen aber 
in prozedurale Form (z. B. Relationenalgebra) 
umgesetzt werden.|  
 
|Um trotzdem effiziente Bearbeitung von Queries zu 
erzielen wird die gestellte Anfrage intern 
umformuliert und verbessert.| |Diesen Vorgang 
nennt man Query Optimization.|  
|Im allgemeinen wird keine optimale Lösung erzielt, 
sondern nur eine Verbesserung.| 













|Grundlagen der Datenbanksysteme I1| 



                       |Logische Optimierung| 

                                  
                                  
   
                  |Query (z.B. SQL)| 

       |Query Prozessor| 

          ??|Analyse 
          ??||Umwandlung in relationale Algebra 
          ??||Datenzugriff 
          ??||Ausführung|                           
















|Grundlagen der Datenbanksysteme I2| 



                       |Logische Optimierung| 

|Fragen: 
     Welche Operationen benötigen viel Zeit für ihre 
     Ausführung?| 
      
     |Können diese vermieden werden, indem man 
     die Anfrage neu formuliert?| 
       
|Beispiel: 
Gegeben sei folgender relationaler Ausdruck: 
                 ?||A(? B=C?||D="99" (AB ?| |CD)) 
Dieser offensichtlich teuere Ausdruck (wg. 
kartesichem Produkt) kann besser formuliert 
werden: 
                ?||A(? B=C(AB ? ?| |D="99" (CD)))
Das kartesische Produkt in dieser Abfrage ist 
offensichtlich durch die Selektion über B=C 
äquivalent zu einem Gleichverbund: 
                 ?||A(AB [B=C] ?| |D="99" (CD))| 







|Grundlagen der Datenbanksysteme I3| 



                       |Logische Optimierung| 

|Grundlegende Aspekte 
Zu betrachten sind für eine Optimierung die fünf 
Grundoperationen.| |Wo liegt ihr Schwachpunkt und 
wie können diese Schwachpunkte umgangen 
werden?| 
 
??|Die auf jeden Fall aufwendigste Operation ist das 
     kartesische Produkt bzw. der Verbund:  
     Bei einfachster Implementierung eines 
     Verbundes zwischen A und B erfolgt ein 
     Durchlauf aller Tupel von B für jedes Tupel von A. 
     Dies ist ein Aufwand mit o(nm).| 
??|Die Projektionen sind aufwendig durch das 
     Entfernen von Duplikaten.| 
??|Die Selektionen sollte man so früh wie möglich 
     durchführen, da dies zu kleineren 
     Zwischenresultaten führt.| 











|Grundlagen der Datenbanksysteme I4| 



                       |Logische Optimierung| 

 
??|Die unären Operationen (Projektion/Selektion) 
     bedingen je einen Durchlauf aller Tupel, daher 
     mehrere möglichst zusammenziehen oder mit 
     einer binären Operation zusammenfassen.| 
??|Nach gemeinsamen Teilausdrücken suchen, 
     damit diese nur einmal abgearbeitet werden.|
??|Eventuell temporäre Verwendung bestimmter 
     Dateiorganisationen (Indizes, Sortieren) einführen  
     ?|  |Physische Optimierung| 
      
|Der Zeitaufwand für das Untersuchen der 
verschiedenen Möglichkeiten ist im allgemeinen 
viel geringer als für das Durchführen einer 
ineffizienten Query.| |Daher wird die Optimierung 
immer durchgeführt!| 












|Grundlagen der Datenbanksysteme I5| 



                       |Logische Optimierung| 

|Algebraische Manipulation 
??||Gesetze der relationalen Algebra.| 
??|Äquivalenz von Ausdrücken.| 
  |Es gilt E1 ?|  |E2 falls sie dieselbe Abbildung 
  repräsentieren, d.h. falls dieselben Relationen für 
  identische Bezeichnungen in den beiden 
  Ausdrücken eingesetzt werden, erhallten wir 
  gleiche Ergebnisse.| 

|A. ist sehr aufgeblasen, er glaubt im Guten weit vorgeschritten zu sein, da er, offenbar als ein immer verlockenderer Gegenstand immer mehr Versuchungen aus ihm bisher ganz unbekannten Richtungen sich ausgesetzt fühlt.| |Die richtige Erklärung ist aber die, daß ein großer Teufel in ihm Platz genommen hat und die Unzahl der Kleineren herbeikommt, um dem Großen zu dienen.|
|Verschiedenheit der Anschauungen, die man etwa von einem Apfel haben kann: die Anschauung des kleinen Jungen, der den Hals strecken muß, um noch knapp den Apfel auf der Tischplatte zu sehn und die Anschauung des Hausherrn, der den Apfel nimmt und frei dem Tischgenossen reicht.|

|Zum letztenmal Psychologie!|
|Zwei Aufgaben des Lebensanfangs: Deinen Kreis immer mehr einschränken und immer wieder nachprüfen, ob Du Dich nicht irgendwo außerhalb Deines Kreises versteckt hältst.|
|Das Böse ist manchmal in der Hand wie ein Werkzeug, erkannt oder unerkannt, läßt es sich, wenn man den Willen hat, ohne Widerspruch zur Seite legen.|
|Die Freuden dieses Lebens sind nicht die seinen, sondern unsere Angst vor dem Aufsteigen in ein höheres Leben; die Qualen dieses Lebens sind nicht die seinen, sondern unsere Selbstqual wegen jener Angst.|

|Kannst Du denn etwas anderes kennen als Betrug?| |Wird einmal der Betrug vernichtet darst Du ja nicht hinsehn oder Du wirst zur Salzsäule.|
|Alle sind zu A. sehr freundlich, so etwa wie man ein ausgezeichnetes Billard selbst vor guten Spielern sorgfältig zu bewahren sucht, solange bis der große Spieler kommt, das Brett genau untersucht, keinen vorzeitigen Fehler duldet, dann aber, wenn er selbst zu spielen anfängt, sich auf die rücksichtsloseste Weise auswütet.|
|"Dann aber kehrte er zu seiner Arbeit zurück, so wie wenn nichts geschehen wäre."| |Das ist eine Bemerkung, die uns aus einer unklaren Fülle alter Erzählungen geläufig ist, trotzdem sie vielleicht in keiner vorkommt.|


|9.)| |Das Lager der PDS-Wahler schließt offenkundig auch Menschen ein, die 1989 gegen den SED-Staat aufstanden (,,Wir sind ein Volk!").| |Der Hauptgrund für ihr Verhalten heute ist die Enttäuschung über das verweigerte Gefühl, mit der Wiedervereinigung endlich zu Hause angekommen zu sein.| |Mit der Vereinigung in einem Staat ging nicht eine Einheit im Fühlen und Wollen einher.| |Verweigerung der nationalen Solidarität erzeugt ein Trauma.| |Während in Mittel- und Osteuropa der Völkerfrühling einzog und die multinationalen Zwangsgebilde zum Einsturz brachte, saß die westdeutsche politische Klasse in einem antinationalen Getto, von einem postnationalen Zeitalter träumend; ihr fehlendes positives Verhältnis zur eigenen Nation ist eine der Ursachen der PDS-Erfolge.|
|Hauptaufgabe der LAN’s ist heute das Application-Sharing, das heisst, auf der Festplatte eines zentralen Server-Rechners liegen verschiedene Anwendungen, die von allen - dazu zugelassenen - Client-Rechnern genutzt werden können.| |Ebenso werden die verschiedenen Daten und Dateien - gleich ob Dokumente oder Spreadsheets - auch zentral vorgehalten.| |Eine Sonderrolle nehmen hier noch die Anwendungen wie Datenbanksysteme (DBMS) ein, die - ebenfalls zentral - auf einem Server gefahren werden, deren Datenbestände dann von den vernetzten Arbeitsstationen aus mit Client-Software (Access, Excel etc.) abgefragt werden können.| |Bezeichnet wird dieses System der Datenhaltung und -bearbeitung als "Client-Server-Computing" im weitesten Sinne.| |Der Schritt zu einem Intranet ist da bald nicht mehr weit.| |Nur: was ist ein Intranet?| 
|Als dieser Begriff im Sprachgebrauch aufkam, wurde er zunächst eher als Marketing-Gag denn als neues Werkzeug für die tägliche Arbeit angesehen.|
|Meistens wird als Intranet eine Netzwerkumgebung und deren Werkzeuge bezeichnet, die hauptsächlich firmenintern, das heisst, im eigenen LAN angesiedelt sind - ganz im Gegensatz zum Internet, das den gesamten Rest der Welt umfasst.|

|Hier tabellarisch die wichtigsten technischen Daten der Testgeräte:|

|Rechnername	fuchur	multimed1|
	
|Domain/IP-Nummer	radiond1.de / 192.168.1.10	fh-reutlingen.de / 134.103.192.26|	

|Netzart	Intranet	FHRT-Net|	

|Prozessor	AMD 486DX100	Cyrix 486/66|	

|Arbeitsspeicher (RAM)	20 MB	32 MB|	

|Harddisks	2 x 500MB IDE	920MB / 298MB SCSI|	

|Betriebssystem	Linux (S.u.S.e 5.3)	Linux (S.u.S.e 5.3)|	

|Die Testläufe auf diesen Rechnern haben eine für das System ausreichende Server-Performance ergeben.| |Dazu hat auch das verwendete Betriebssystem beigetragen.|

|Während der Programmierarbeiten am Intranet Framework sind mir etliche Inkompatibilitäten zwischen den beiden im Internet am weitesten verbreiteten Browsern aufgefallen - um nicht zu sagen: sauer aufgestoßen.|
|Stichwort "JavaScript"
Beide Browser können durch die eingebaute Sprache JavaScript (Netscape) bzw. JScript (Microsoft) etliche einfachere Programmlogik auf den Client - den Browser - verlagern.| |Der Stolperstein dabei ist dabei aber die unterschiedliche Implementation der Sprache: offensichtlich verstehen Microsoft und Netscape unter ein und dem selben Konstrukt etwa verschiedenes, so das man tatsächlich das ein oder andere Mal gezwungen ist, in ein JavaScript-Programm eine Abfrage nach dem Hersteller (!) des Browsers vorzusehen.|

 |Die Software des Frameworks übergibt nämlich die zu speichernden Daten per URL-Parameter, wie zum Beispiel in der Form "http://seite.html?parameter1=1&parameter2=2" usw. Apache genauso wie seine Kollegen kann aber nur eine bestimmte Länge dieses Strings verarbeiten; überschreitet die Länge der URL den Grenzwert, dann gibt das Webserver-Programm eine Fehlermeldung an den Bowser zurück und führt die gewünscht Aktion nicht aus.| |Durch empirische Versuche habe ich die URL-Länge auf ca. 4650 Zeichen eingrenzen können (was in etwa 2 DIN-A4-Seiten entsprechen dürfte), dies wohlgemerkt im besten Falle.|
|Dieser Überlauf dürfte aber bei dem geplanten Anwendungsgebiet nicht auftreten, da die zu speichernden Textarten selten mehr als 2000 Zeichen habe, wie eine Untersuchung der bisher mit Word erstellten Texte gezeigt hat.|
|Trotzdem ist hier für die Zukunft geplant, entweder den Sourcecode des Apache entsprechend zu verändern, oder - das wäre wohl die elegante Lösung - zumindest das Editor-Feld der HTML-Seite nach Java zu portieren und den geschriebenen Text dann mittels JDBC in die Datenbank zu schreiben.|


|In der Theorie war jeder Nutzer angehalten, seine redaktionellen Texte in das entsprechende Verzeichnis, dessen Namen eine räumliche oder thematische Zuordnung erlaubte, einzusortieren.| |In der Praxis wurde das System von den Mitarbeitern des Radiosenders aus den verschiedensten Gründen (Unkenntnis des Systems, Angst vor dem Computer, usw.) nicht genutzt.| |Die Dokumente wurden nach einem Ausdruck nicht gespeichert, und wenn, dann willkürlich irgendwohin in das Verzeichnissystem mit irgendeinem Dateinamen, der nichts aussagte ("Dokument1.doc").| |Das Prinzip dabei: Der Computer ist eine Schreibmaschine mit Bildschirm ...
Das Problem ... 
Dieses chaotische System lief solange gut, bis man einen Text zu einem bestimmten Thema suchte: Er war ohne besondere Hilfen und vor allem Kenntnisse von Windows95 nicht zu finden.| |Glück hatte nur der Redakteur, der den Menupunkt "Datei suchen" kannte und vor allem auch bedienen konnte.| |Doch ist diese Art der Suche nicht sehr produktiv, und meist auch nicht sonderlich erfolgreich, da Microsoft dem Anschein nach die Suchalgorithmen sehr unscharf programmiert hat.|

|Das Intranet-Framework erlaubt auch das Drucken eines Textes.| |Dazu findet man in der Menuzeile verschiedener Fenster den Button Drucken.| |Ein Klick auf diesen öffnet ein Vorschaufenster mit dem zu druckenden Text.|
|Allerdings kann man in dieser Version des Intranet-Frameworks keine perfekte Druckausgabe wie zum Beispiel bei Word für Windows erwarten.| |Dies ist prinzipbedingt, denn eigentlich ist die Beschreibungssprache HTML nicht für die Erstellung druckreifer Web-Dokumente erdacht worden, sondern noch eher zur Strukturierung von Dokumenten jeglicher Art.| |Dies lässt auch schon der Name erkennen: Hypertext Markup Language.|
|Ich habe versucht, dieses Manko durch HTML-Tabellen-Programmierung etwas zu umgehen, das heißt, ich habe die einzelnen auszugebenden Textteile mittels Tabelle positioniert.|

|WWWBoard wurde komplett in Perl geschrieben und stellt auf einfache Weise die Funktionalitäten eines Schwarzen Brettes zur Verfügung.|
|Installation 
Die Installation der Software gestaltet sich als recht einfach: Laut der Installationsanleitung werden die entsprechenden Einträge in das Programm vorgenommen, die Verzeichnisse für die verschiedenen Daten auf dem Server erstellt - das wars.|
|Auch die grundsätzliche Einbindung ins Framework ist kein Problem.| |Lediglich die Optik der Software muss an den Style-Guide des Intranets angepasst werden.|

|[1]	HTML Handbuch	Stefan Münz/Wolfgang Nefzger,  Feldkirchen, Franzis-Verlag, 1997|
	
|[2]	SQL - Standardisierte Datanbanksprache vom PC bis zum Mainframe	Albrecht Achilles, München, Oldenbourg Verlag, 1989|	

|[3]	Das SQL-Lehrbuch	Rick F. Van der Lans Bonn, Addison-Wesley, 1987|	

|[4]	MySQL - Technical Reference Manual	David Axmark  TcX AB, 1998|	

|[5]	PHP3 - Manual	Stig S. Bakken PHP Documentation Group, 1997|	

|[6]	Linux - das Kompendium	Jack Tackett jun. etc. Haar, Verlag Markt & Technik, 1995	
Zeitschriften|

|[1]	Dynamische Webseiten mit PHP/FI	Tom Schwaller Linux Magazin 6/1996 S. 39, Aschheim 1996|	

|[2]	Pulverkaffee - Dynamische HTML-Seiten mit PHP/FI, mSQL und gd	Tobias Häcker iX 8/1996 S. 56, Hannover 1996|	


|[3]	Net at Work - Intranet im preiswerten Eigenbau	Dirk Brenken C’t 10/1996 S. 302, Hannover 1996|	

|[4]	Systemcocktail - Datenbanken und Web-Technik	Jürgen Diercks iX 10/1997 S. 110, Hannover 1997|	

|[5]	Heißes Bemühn - Internet Explorer 4 für Solaris	Henning Behme iX 4/1998 S. 62, Hannover 1998|	


|[6]	Ins Netz gegangen - Freie Unix-Versionen	Jürgen Kuri C’t 11/1998 S. 366, Hannover 1998|	

|[7]	Geschäfte im Web	Detlef Beyer/André Schröter C’t 15/1998 S. 290, Hannover 1998|	

|[8]	Schirmherrschaft - Das Web: Plattform für Firmenanwendungen	Jürgen Diercks iX 1/1999 S. 104, Hannover 1999|	

|REC-html40-19980424| 

|HTML 4.0 Specification| 

|W3C Recommendation, revised on 24-Apr-1998| 

|This version:| 

|http://www.w3.org/TR/1998/REC-html40-19980424| 

|Latest version:| 

|http://www.w3.org/TR/REC-html40| 

|Previous version:| 

|http://www.w3.org/TR/REC-html40-971218| 

|Editors:| 

|Dave Raggett <dsr@w3.org>| 

|Arnaud Le Hors <lehors@w3.org>| 

|Ian Jacobs <ij@w3.org>| 

|Available formats|

|The HTML 4.0 W3C Recommendation is also available in the following formats:| 

|A plain text file:| 

|http://www.w3.org/TR/1998/REC-html40-19980424/html40.txt (735Kb),|
 
|A gzip'ed tar file containing HTML documents:| 

|http://www.w3.org/TR/1998/REC-html40-19980424/html40.tgz (357Kb),| 

|A zip file containing HTML documents (this is a '.zip' file not an '.exe'):| 

|http://www.w3.org/TR/1998/REC-html40-19980424/html40.zip (389Kb),| 

|A gzip'ed Postscript file:| 

|http://www.w3.org/TR/1998/REC-html40-19980424/html40.ps.gz (600Kb, 367 pages),| 

|A PDF file:| 

|http://www.w3.org/TR/1998/REC-html40-19980424/html40.pdf (2.1Mb) file.| 


|Eins, zwei, drei, etc..|
|Selbst der 100. Punkt ist kein Grund fuer eine Trennung.|
|Auch nicht der 1000. Punkt, oder der 30000. Punkt.|
|Selbstverstaendlich sind normale Jahreszahlen Satzenden, wie etwa 1903.|
|Oder erst recht 1979.| |Ganz zu schweigen von 2010.|
|Insbesondere sollte es mit einem Jahr sehr gut klappen: 2000.|
|Auch andere duerfen keine Probleme machen, etwa 1900.|
|Und 2100.|
|Selbst <<Dies und das!!>> sagte er, sollte verstanden werden.|
|Abkuerzungen aus nur Vokalen sollen richtig interpretiert werden, ua. solche wie iaa. oder aü. oder auch uuu..|
|Verstanden ?|
