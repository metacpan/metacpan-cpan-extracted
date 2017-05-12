package Email::Public;

use warnings;
use strict;

=head1 NAME

Email::Public - Quickly find if an email address is from a public email provider

=head1 VERSION

Version 0.11

=cut

use vars qw/$VERSION %PUBLIC_DOMAINS/ ;

$VERSION = '0.13';

=head1 SYNOPSIS

This module relies on a list of domains known to be
public email providers (such as yahoo , gmail, hotmail ... ).

To include a new domain in the list, or to remove one please submit a bug at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Public>
I'll be notified and I will review it.


Code snippet:

    use Email::Public;

    if ( Email::Public->isPublic($email) ){
      ....
    }

=cut



=head2 isPublic

Returns true if the given email address belongs to the public list.

Usage:
    if ( Email::Public->isPublic($email) ){
      ....
    }


=cut

sub isPublic{
    my ($class, $email) = @_ ;
    my ( $user , $domain ) = split('@' , $email ) ;
    
    return $PUBLIC_DOMAINS{lc($domain)} ;
}


sub BEGIN{

#
# Please keep the list alpha sorted
#
    map { $PUBLIC_DOMAINS{$_} = 1 } qw/
163.com
absamail.co.za
adelphia.net
aim.com
airtel.net
aliceadsl.fr
alice.it
aol.com
aol.com.au
aol.com.mx
aol.co.uk
aol.de
aol.es
aol.fr
aol.in
aol.it
aol.nl
aol.se
aon.at
arcor.de
att.net
belgacom.net
bellsouth.net
bestmail.us
bigfoot.com
bigfoot.de
bigpond.com
bigpond.com.au
bigpond.net.au
bluewin.ch
blueyonder.co.uk
bol.com.br
bt.com
btinternet.com
btopenworld.com
cantv.net
caramail.com
cbn.net.id
cegetel.net
cellc.co.za
centrum.cz
charter.net
click21.com.br
clix.pt
club-internet.fr
clubinternet.fr
comcast.net
copper.net
cox.net
dbmail.com
earthlink.net
eircom.net
e-mailanywhere.com
email.com
email.cz
eresmas.com
euskalnet.net
evc.net
excite.com
fastmail.fm
fastmail.us
fastwebnet.it
fnac.net
free.fr
freemail.hu
freeserve.co.uk
freesurf.fr
fsmail.net
gadz.org
gawab.com
gamail.com
gmail.co.in
gmail.com
gmail.com.ar
gmx.at
gmx.de
gmx.li
gmx.net
go2.pl
googlemail.com
highveldmail.co.za
hispavista.com
hispeed.ch
hotbox.com
hotmail.be
hotmail.com
hotmail.com.br
hotmail.com.mx
hotmail.co.uk
hotmail.de
hotmail.es
hotmail.fr
hotmail.it
hotmail.co.li
iafrica.com
ibest.com.br
ifrance.com
ig.com.br
imode.fr
inbox.ru
indiatimes.com
infonie.fr
inicia.es
interia.pl
iol.pt
itelefonica.com.br
juno.com
katamail.com
kittymail.com
laposte.fr
laposte.net
latinmail.com
libero.it
libertysurf.fr
live.be
live.com
live.com.mx
live.com.pt
live.co.uk
live.co.za
live.ie
live.nl
lycos.com
lycos.co.uk
lycos.es
mageos.com
mail.com
mail.ru
mail2world.com
mailmate.co.za
menara.ma
messagerie.net
mixmail.com
msn.com
msn.fr
mweb.co.za
mynet.com
myway.com
navegalia.com
netcourrier.com
netplus.ch
netscape.com
netscape.net
net-up.com
netzero.net
neuf.fr
nomade.fr
noos.fr
ntlworld.com
numericable.com
numericable.fr
o2.pl
oi.com.br
onet.eu
online.fr
ono.com
op.pl
operamail.com
optusnet.com.au
orange.es
orange.fr
orangemail.es
oreka.com
ozu.es
pandora.be
paradise.net.nz
peoplepc.com
peoplepc.fr
poczta.fm
poczta.onet.pl
pop.com.br
portugalmail.pt
prodigy.net.mx
rediffmail.com
romandie.com
safe-mail.net
sapo.pt
sbcglobal.net
scarlet.be
seznam.cz
sfr.fr
sify.com
sina.com.cn
skynet.be
sohu.com
sohu.net
surfsimple.net
superonline.com
swing.be
sympatico.ca
tele2.ch
tele2.fr
telefonica.net
telenet.be
telepolis.com
telkomsa.net
terra.com
terra.com.br
terra.es
tiscali.be
tiscali.co.uk
tiscali.fr
tiscali.it
tlen.pl
ttmail.com
tvcablenet.de
t-online.de
t-online.hu
uol.com.ar
uol.com.br
uol.com.co
uol.com.mx
uol.com.ve
verizon.net
virgilio.it
virgin.net
vodamail.co.za
voila.fr
vp.pl
wanadoo.com
wanadoo.es
wanadoo.fr
web.de
webmail.co.za
worldonline.fr
wp.pl
xtra.co.nz
ya.com
yahoo.ar
yahoo.ca
yahoo.co.in
yahoo.com
yahoo.com.ar
yahoo.com.au
yahoo.com.br
yahoo.com.cn
yahoo.com.hk
yahoo.com.is
yahoo.com.mx
yahoo.com.ph
yahoo.com.ru
yahoo.com.sg
yahoo.com.ve
yahoo.co.jp
yahoo.co.nz
yahoo.co.uk
yahoo.co.jp
yahoo.co.kr
yahoo.co.nz
yahoo.co.uk
yahoo.co.za
yahoo.de
yahoo.dk
yahoo.es
yahoo.fr
yahoo.gr
yahoo.ie
yahoo.it
yahoo.jp
yahoo.nl
yahoo.no
yahoo.se
yahoomail.com
yopmail.com
ymail.com
zipmail.com.br
zwallet.com

mail.com
email.com
usa.com
consultant.com
myself.com
europe.com
london.com
post.com
engineer.com
iname.com
cheerful.com
writeme.com
lawyer.com
dr.com
asia.com
techie.com
accountant.com
adexec.com
allergist.com
alumnidirector.com
archaeologist.com
bartender.net
brew-master.com
chef.net
chemist.com
clerk.com
columnist.com
consultant.com
contractor.net
counsellor.com
deliveryman.com
diplomats.com
doctor.com
execs.com
financier.com
fireman.net
footballer.com
gardener.com
geologist.com
graphic-designer.com
hairdresser.net
instructor.net
insurer.com
journalist.com
legislator.com
lobbyist.com
mad.scientist.com
minister.com
monarchy.com
optician.com
orthodontist.net
pediatrician.com
photographer.net
politician.com
presidency.com
programmer.net
publicist.com
radiologist.net
realtyagent.com
registerednurses.com
repairman.com
representative.com
rescueteam.com
salesperson.net
scientist.com
secretary.net
socialworker.net
sociologist.com
songwriter.net
teachers.org
teacher.com
technologist.com
therapist.net
tvstar.com
umpire.com
artlover.com
bikerider.com
birdlover.com
catlover.com
collector.org
comic.com
cutey.com
doglover.com
elvisfan.com
gardener.com
hockeymail.com
madonnafan.com
musician.org
petlover.com
reggaefan.com
rocketship.com
rockfan.com
thegame.com
africamail.com
americamail.com
arcticmail.com
asia-mail.com
australiamail.com
berlin.com
brazilmail.com
chinamail.com
dallasmail.com
delhimail.com
dublin.com
dutchmail.com
englandmail.com
europe.com
europemail.com
germanymail.com
indiamail.com
irelandmail.com
israelmail.com
italymail.com
japan.com
koreamail.com
madrid.com
moscowmail.com
mexicomail.com
munich.com
nycmail.com
pacific-ocean.com
pacificwest.com
paris.com
polandmail.com
rome.com
russiamail.com
safrica.com
samerica.com
scotlandmail.com
singapore.com
spainmail.com
swedenmail.com
swissmail.com
usa.com
alabama.usa.com
alaska.usa.com
arizona.usa.com
arkansas.usa.com
california.usa.com
colorado.usa.com
connecticut.usa.com
delaware.usa.com
florida.usa.com
georgia.usa.com
hawaii.usa.com
idaho.usa.com
illinois.usa.com
indiana.usa.com
iowa.usa.com
kansas.usa.com
kentucky.usa.com
louisiana.usa.com
maine.usa.com
maryland.usa.com
massachusetts.usa.com
michigan.usa.com
minnesota.usa.com
mississippi.usa.com
missouri.usa.com
montana.usa.com
nebraska.usa.com
nevada.usa.com
newhampshire.usa.com
newjersey.usa.com
newmexico.usa.com
newyork.usa.com
northcarolina.usa.com
northdakota.usa.com
ohio.usa.com
oklahoma.usa.com
oregon.usa.com
pennsylvania.usa.com
rhodeisland.usa.com
southcarolina.usa.com
southdakota.usa.com
tennessee.usa.com
texas.usa.com
utah.usa.com
vermont.usa.com
virginia.usa.com
washington.usa.com
westvirginia.usa.com
wisconsin.usa.com
wyoming.usa.com
2die4.com
angelic.com
activist.com
alumni.com
amorous.com
aroma.com
atheist.com
been-there.com
bigger.com
caress.com
cliffhanger.com
comic.com
comfortable.com
count.com
couple.com
cyberdude.com
cybergal.com
cyber-wizard.com
dbzmail.com
disciples.com
disposable.com
doramail.com
doubt.com
earthling.net
fastermail.com
feelings.com
graduate.org
hackermail.com
hilarious.com
homosexual.net
hot-shot.com
hour.com
howling.com
humanoid.net
indiya.com
innocent.com
inorbit.com
instruction.com
keromail.com
kittymail.com
linuxmail.org
loveable.com
mailpuppy.com
mcdull.net
mcmug.org
mindless.com
minister.com
muslim.com
mobsters.com
monarchy.com
nastything.com
nightly.com
nonpartisan.com
null.net
oath.com
orthodox.com
outgun.com
priest.com
protestant.com
playful.com
poetic.com
reborn.com
reincarnate.com
religious.com
revenue.com
rocketmail.com
rocketship.com
royal.net
saintly.com
sailormoon.com
seductive.com
sister.com
sizzling.com
skim.com
snakebite.com
soon.com
surgical.net
tempting.com
toke.com
toothfairy.com
tough.com
tvstar.com
uymail.com
wallet.com
webname.com
weirdness.com
who.net
whoever.com
winning.com
witty.com
yours.com
    /
    
    ;
}


=head1 AUTHOR

Jerome Eteve C<< <jerome at eteve.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-email-public at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Public>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Public

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Public>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Public>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Public>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Public>

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to L<http://www.careerjet.com> for the initial list.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jerome Eteve, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1; # End of Email::Public
