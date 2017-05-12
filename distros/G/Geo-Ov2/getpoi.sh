#!/bin/sh

# Nastaveni promennych
agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; cs; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.4;MEGAUPLOAD 1.0"
referer="http://www.poi.cz/index.php?poi=sluco1"
FORMATS="CSV ov2 gpx kml txt"

# Ziskani seznamu vsech kategorii
categories=""
for i in `wget --keep-session-cookies --load-cookies=cookies.txt --save-cookies=cookies.txt -U "$agent" -O - 'http://www.poi.cz/index.php?poi=sluco1' | sed -n 's/^.*name="messageId\[\]" value="\([^"]*\)".*$/\1/p'`; do
	categories="${categories}&messageId%5B%5D=$i"
	#echo "catId: $i" >&2
done

sleep 5

# Postupne stazeni zipu vsech kategorii v ruznych formatech
for i in $FORMATS; do
	url="http://www.poi.cz/index.php?poi=sluco1&akce=tvor&r1=$i&t26=CZ-moje&t494%2C497%2C495%2C498=SK-Radar&t522%2C521%2C618%2C552=SK-Nakup&t26%2C175%2C16%2C173=CZ-Radary_vsechny&t128%2C103%2C102=CZ-Posta&t278%2C218%2C550%2C366%2C277=CZ-Pneu_&t127%2C48%2C129%2C49%2C77%2C47%2C92%2C156%2C322%2C93%2C76%2C327%2C52%2C51%2C74%2C543%2C58%2C11%2C20%2C297%2C154%2C651%2C88%2C205%2C281%2C280%2C279%2C38%2C53%2C451%2C82%2C50%2C101%2C83%2C162%2C610%2C94%2C100%2C611%2C12%2C114=CZ-Nakup&t36%2C37%2C31=CZ-Metro&t55%2C54%2C56%2C57=CZ-Hranicni_Prech&t492%2C320%2C334%2C167%2C164%2C45%2C46%2C125%2C41=CZ-Firma&t78%2C15%2C13=CZ-Fastfood&t22%2C63%2C64%2C18%2C65%2C17%2C25%2C21%2C67%2C68%2C69%2C24%2C71=CZ-CS_znackove&t66%2C70=CZ-CS_neznackove&t195%2C335%2C328%2C336%2C303%2C337%2C333%2C338%2C317%2C339%2C330=CZ-Banko&t134%2C132%2C135%2C19%2C27%2C136%2C137%2C139%2C216%2C133%2C140%2C141%2C142%2C143%2C144%2C145=CZ-Banka&t106%2C194%2C150%2C244%2C107%2C109%2C179%2C180%2C110%2C113%2C341%2C104%2C163%2C131%2C108%2C204%2C149%2C112%2C168%2C189=CZ-Auto_vsechny$categories&nazev=CZ-&vse=vse&h1=Vytvo%C5%99it"

	echo -n "Downloading $i..." >&2
	wget -nc --keep-session-cookies --load-cookies=cookies.txt --save-cookies=cookies.txt -U "$agent" -O "$i.zip" --referer="$referer" "$url"
	echo " done" >&2

	echo "Waiting 700 seconds..." >&2
	sleep 700

done

