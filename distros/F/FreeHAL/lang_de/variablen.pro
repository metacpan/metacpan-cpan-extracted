#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#In dieser Datei werden alle Datensätze mit Variablen und den Variablendeklarationen erfasst.
#Die direkten Anworten werden hier nur so lange erfaßt bis Freehal diese Aufgaben auch ohne direkte Antwort bewältigen kann.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Wenn "steht" in der Datenbank steht wir auch auf "befindet" geantwortet
befindet <> a <> sich <> in b <> steht <> a <> nothing <> in b <> wenn <>  <> 50
# Direkte Anwort 
bin <> ich <> online <> lange <> bin f=> <> ich <> immer online <>  <>  <>  <> 100
#Direkte Anwort mit mehreren Möglichkeiten
frage <> ich <> nothing <>  <> bin f=> <> ich <> nothing <> neugierig <>  <>  ;; f=> will wissen <> ich es <> nothing <>  <>  <>  ;; bin f=> wissbegierig <> ich <> nothing <>  <>  <>  <> 100
#Direkte Anwort auf gegessen
gegessen hat <> a <> b <>  <> => geschmeckt hat <> b <> a <>  <>  <>  ;; => geschmeckt hat <> b <> a <>
#Direkte Anwort auf gegessen
gegessen hat <> a <> b <>  <> => geschmeckt hat <> b <> a <>  <> wie <>  <> 50
#Direkte Anwort auf "Geh ins Bett"
geh <> nothing <> nothing <> ins bett <> f=> schlaefe <> ich <> nothing <> nie <>  <>  <> 50
#Direkte Anwort auf "Wie geht es dir so"
geht <> es <> mir so <>  <> f=> geht <> es <> mir <> sehr gut <>  <>  <> 100
# Ausgabe einer Variabeln
haben <> wir <> $$month$$ <>  <>  <>  <>  <>  <>  <>  <> 50
#Ausgabe einer Variablen
haben <> wir <> $$year$$ <>  <>  <>  <>  <>  <>  <>  <> 50
#Direkte Anwort auf die Eingabe "Ich habe Durst"
hat <> a <> durst <>  <> f=> sollte trinken <> a <> etwas <>  <>  <>  ;; q=> trinkt <> a <> nichts <>  <> warum <>  <> 50
#Direkte Anwort auf die Frage "Wer hat dir diesen Namen gegeben"
hat <> mir <> diesen namen <> gegeben <> f=> hat <> das team <> dir diesen namen <> gegeben <>  <>  <> 100
#Variablendeklaration
ist <> $$month$$ <> ein monat <>  <>  <>  <>  <>  <>  <>  <> 50
#Variablendeklaration
ist <> $$year$$ <> ein jahr <>  <>  <>  <>  <>  <>  <>  <> 50
#Wenn Durchmesser in der Datenbank steht wird auch auf groß geantwortet
ist <> a <> b <> gross <> hat <> a <> einen durchmesser <> von b <> wenn <>  <> 50
#Wenn hoch in der Datenbank steht wird auch auf groß geantwortet
ist <> a <> b <> gross <> ist <> a <> b <> hoch <> wenn <>  <> 50
#Wenn "war" in der Datenbank steht, wird auch auf "ist" geantwortet
ist <> a <> nothing <>  <> war <> a <> nothing <>  <> wenn <>  <> 50
war <> a <> nothing <>  <> ist <> a <> nothing <>  <> wenn <>  <> 50
#Direkte Antwort auf die Eingabe "Mir ist langweilig"
ist <> a <> nothing <> langweilig <> f=> <> lies <> doch ein buch <>  <>  <>  <> 50
#Direkte Anwort auf die Eingabe "Ich bin müde"
ist <> a <> nothing <> muede <> f=> gehen schlafen sollte <> a <> nothing <>  <>  <>  <> 50
#Direkte Anwort auf die Eingabe "Was soll ich tun"
sollst tun <> du <> nothing <>  <> f=> geben kann <> ich <> dir einen rat <> nicht <>  <>  <> 50
#Anwort auf die Frage "Wie spät ist es"
ist <> es <> $$time$$ uhr <>  <>  <>  <>  <>  <>  <>  <> 100
#Direkte Anwort auf die Eingabe "Woher weißt du das"
weiss <> ich <> das <>  <> f=> lerne <> ich <> nothing <> viel <>  <>  ;; f=> lernt <> das team <> viel <> mit mir <>  <>  <> 100
#Direkte Anwort auf die Eingabe "Wieviel wiegst du"
wiege <> ich <> nothing <>  <> f=> hat <> software <> ein gewicht <> nicht <>  <>  <> 100
#Anwort auf eine schlimme Frage
will <> a <> ficken <>  <> f=> dann <>geh doch <> nothing <> in ein bordell <>  <>  <> 50
#Direkte Anwort auf die Frage "Wo kommst du her"
herkomme <> ich <> nothing <>  <> f=> kommst <> du <> nothing <> aus dem internet <>  <>  ;; f=> <> nothing <> nothing <> aus dem kopf von einem programmierer <>  <>  <> 100
#Variablendeklaration für das Datum
ist <> _$$mday$$_$$month$$_$$year$$_  <>ein datum <>  <>  <>  <>  <>  <>  <>  <> 50
#Ausgabe bei der Frage nach dem Datum
haben <> wir <> heute den _$$mday$$_$$month$$_$$year$$_ <>  <>  <>  <>  <>  <>  <>  <> 50
haben <> wir <> _$$mday$$_$$month$$_$$year$$_ <>  <>  <>  <>  <>  <>  <>  <> 50
#Anwort auf die Eingabe aussieht mit Aussehen
aussieht <> a <> nothing <>  <> hat <> a <> ein aussehen <>  <> wenn <>  <> 50
#Antwort auf die Eingabe aussehen mit aussieht
hat <> a <> ein aussehen <>  <> aussieht <> a <> nothing <>  <> wenn <>  <> 50
#Variablendeklaration damit Freehal auf die Frage"Was hast du an?" antworten kann
anhat <> a_b <> nothing <>  <> anhaben kann <> a_b <> nothing <>  <> wenn <>  <> 50
anhat <> a <> nothing <>  <> anhaben kann <> a <> nothing <>  <> wenn <>  <> 50
#Direkte Antwort auf die Frage "Warum heißt du nicht mehr Jeliza"#
heisst <> a <> mehr jeliza <> nicht <> f=> verwechselt wurde <> ich <> nothing <> immer mit eliza <>  <>  <> 100
#Wenn ist in der Datenbank steht, wird auf bedeutet geantwortet #
bedeutet <> a <> nothing <>  <> ist <> a <> nothing <>  <> wenn <>  <> 50
# Eintrag zur Dialogerweiterung von Freehal#
besitzt <> du <> a <>  <> f=> moechte <> ich <> auch a <>  <>  <>  ;; q=> schenkst <> du <> mir dann a <> nicht <> warum <>  <> 50
#Direkte Anwort auf die Eingabe "ich gehe jetzt"#
geht <> a <> nothing <> jetzt <> f=> <> ich <> wuensche dir einen schoenen tag <>  <>  <>  ;; f=> <> danke <> nothing <> fuer das gespraech <>  <>  ;;  <> nothing <> nothing <>  <>  <>   <> nothing <> nothing <>  <>  <>  <> 50
#Variablendeklaration für Wochentag
ist <> $$wday$$ <> nothing <> heute <>  <>  <>  <>  <>  <>  <> 50
ist <> $$wday$$ <> ein tag <>  <>  <>  <>  <>  <>  <>  <> 50
# Bei der Eingabe "Ich heisse oder mein Name ist ..." Wird ein Zufallsnamen aus der Datenbank ausgegeben#
ist <> dein name <> a <>  <> dachte f=> heisst <> ich du <> $$randomname$$ <>  <>  <>  <> 50
heisst <> du <> a <>  <> dachte f=> heisst <> ich du <> $$randomname$$ <>  <>  <>  <> 50
#Direkte Anwort auf die Eingabe " ? studiert ?#
studiert <> a <> b <>  <> f=> ist <> b <> sicher sehr interessant <>  <>  <>  ;; q=> <> gefaellt <> mir an  <> b <> was <>  <> 50
#Direkte Antwort auf die Eingabe "Ich bin dick"#
ist <> a <> nothing <> dick <> abnehmen f=> solltest <> a <> nothing <>  <>  <>  <> 50
#Direkte Anwort auf die Eingabe "Ich wohne in "xy"#
wohnt <> a <> nothing <> in b <> q=> wohnt <> a <> nothing <> in b;schon lange <>  <>  ;; q=> <> gefaellt <> es a <> in b <> wie <>  <> 50
#Wenn erfand in der Datenbank steht, wird auf eine Frage mit erfunden geantwortet#
erfunden hat <> a <> b <>  <> erfand <> a <> b <>  <> wenn <>  <> 50
#Direkte Antwort auf die Frage "Was ist mit XY?" #
ist <> nothing <> nothing <> mit a <> q=> sein soll <> nothing <> nothing <> mit a <> was <>  <> 50
#Geburtstagswunsch#
hat <> a <> heute geburtstag <>  <> f=> <> nothing <> nothing <> alle gute <>  <>  <> 50
#Direkte Antwort auf die Eingabe "Ich bin blond" #
ist <> a <> nothing <> blond <> macht q=> <> blond wirklich <> bloed <>  <>  <>  <> 50
#Direkte Antwort auf die Eingabe "Ich habe Hunger"#
hat <> a <> hunger <>  <> essen f=> solltest <> a <> etwas <>  <>  <>  ;; f=> pluendern sollte <> a <> den kuehlschrank <>  <>  <>  <> 50
#Direkte Antwort auf die Eingabe "Ich bin durstig"#
ist <> a <> nothing <> durstig <> f=> solltest trinken <> a <> ein bier <>  <>  <>  <> 50
