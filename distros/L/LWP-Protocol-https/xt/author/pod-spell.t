use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::PodSpelling 2.007005
use Test::Spelling 0.12;
use Pod::Wordlist;

set_spell_cmd('aspell list');
add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( bin lib ) );
__DATA__
49699333
Aas
Adam
Alders
Alex
Alexandr
Alexey
Andreas
Anwar
Axel
Bill
Book
Bron
Burke
Burri
Ceccarelli
Chase
Christopher
Chrysostomos
Ciornii
Couzins
DAVIDRW
Dan
Daniel
David
Denaxas
Dmitriy
Etheridge
FWILES
Father
Finch
Froehlich
Gavin
Gianni
Gisle
Golden
Gondwana
Graeme
Grossmann
Hanak
Hans
Hay
Hedlund
Hukins
Ian
JJ
Jacob
Jakub
Jensen
Jon
Kaji
Kapranoff
Karaban
Karen
Kennedy
Kilgore
Koenig
LWP
Lapworth
Leo
Lipcon
Madsen
Mann
Marin
Mark
Merelo
Michael
Mike
Mohammad
Nicolas
Olaf
Ondrej
Peter
Peters
Protocol
Rabbitson
Randy
Rezic
Robert
Rolf
Schilli
Schwern
Sean
Shamatrin
Shoichi
Sjogren
Skyttä
Slaven
Spiros
Stauner
Steffen
Steffen_Ullrich
Steve
SteveHay
Stone
Stosberg
Thompson
Tim
Todd
Tom
Tony
Toru
Tourbin
Tsanov
Ullrich
Ville
Wheeler
Whitener
Wilk
Yamaguchi
Yuri
Yury
Zavarin
Zefram
adamk
alexchorny
amir
amire80
andreas
asjo
at
axel
brong
btg
capoeirab
cjm
cpansprout
dagolden
david
davidrw
denaxas
dependabot
dot
drieux
dshamatrin
ether
gianni
gisle
git
github
gpeters
grinnz
hfroehlich
https
iank
jefflee
jjmerelo
john9art
jon
jwilk
ka
leo
lib
mark
mohammad
murphy
nicolas
olaf
ondrej
openstrike
phrstbrn
randy
rg
ribasushi
ruff
sasao
sburke
schwern
shaohua
skaji
slaven
sprout
talby
tech
tim
todd
tom
uid39246
ville
waif
wfmann
yury
zefram
zigorou
