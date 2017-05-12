package Lingua::EN::CommonMistakes;

use 5.006;
use strict;
use warnings FATAL => 'all';
use warnings::register;
use Carp;

our $VERSION = 20130425;

my %MISTAKES;

# reads data from __DATA__ section into %MISTAKES
sub _read_mistakes {
  my $in_tag = ':common';

  while ( my $line = <Lingua::EN::CommonMistakes::DATA> ) {
    chomp $line;
    $line =~ s{#.*\z}{};
    $line =~ s{\s+\z}{};
    $line =~ s{\A\s+}{};
    $line =~ s{ {2,}}{ };
    next unless $line;

    if ( $line =~ m{\A:[^\s]+\z} ) {
      $in_tag = $line;
      next;
    }

    my ( $word, $correction ) = split( /\s/, $line, 2 );
    $MISTAKES{$in_tag}{$word} = $correction;
  }
  close(Lingua::EN::CommonMistakes::DATA);

  return;
}

sub import {
  my ( $package, @args ) = @_;
  my @out_name;
  my %tags = map { $_ => 1 } qw(:common :punct);
  foreach my $arg (@args) {
    if ( substr( $arg, 0, 1 ) eq '%' ) {
      push @out_name, substr( $arg, 1 );
    }
    elsif ( substr( $arg, 0, 1 ) eq ':' ) {
      if ($arg eq ':no-defaults') {
        %tags = ();
      } elsif ($arg =~ m{\A:no-(.+)\z}) {
        delete $tags{ ":$1" };
      } else {
        $tags{$arg}++;
      }
    }
    else {
      croak __PACKAGE__ . ": import argument $arg is not understood";
    }
  }

  if ( !@out_name ) {
    push @out_name, 'MISTAKES';
  }

  if ( $tags{':american'} && $tags{':british'} ) {
    croak __PACKAGE__ .  ": can't use both :american and :british";
  }

  if ( !%MISTAKES ) {
    _read_mistakes();
  }

  my %out;
  foreach my $tag ( keys %tags ) {
    if ( !$MISTAKES{$tag} ) {
      if (warnings::enabled( __PACKAGE__ )) {
        carp __PACKAGE__ . ": import argument $tag is not understood";
      }
    }
    else {
      (%out) = ( %out, %{ $MISTAKES{$tag} } );
    }
  }

  my ($caller_package) = caller();
  foreach my $out_name (@out_name) {
    no strict 'refs';
    no warnings 'once';
    *{ $caller_package . '::' . $out_name } = \%out;
  }
  return;
}

=head1 NAME

Lingua::EN::CommonMistakes - map of common English spelling errors

=head1 SYNOPSIS

    use Lingua::EN::CommonMistakes qw(%MISTAKES);

    foreach my $word (split /\b/, $text) {
        if (my $correction = $MISTAKES{lc $word}) {
            warn "Likely spelling error: $word (-> $correction)\n";
        }
    }

    # or use a different flavor of English
    use Lingua::EN::CommonMistakes qw(:no-punct :british %MISTAKES);
    ...

Provides a customizable map of common English spelling errors with their
respective corrections.

=head1 USAGE

The behavior of this package is customized at import time.

By default, importing this package will create a hash named
C<%MISTAKES> in the calling package, containing most corrections, but
not containing either American English or British English corrections.

This behavior may be customized by providing the following parameters
when importing:

=over

=item %I<NAME> [default: C<%MISTAKES>]

The map will be imported with the given name.

=item C<:common>, C<:no-common> [default: C<:common>]

If enabled, include the base set of corrections common among all
English variants. This is the largest set of corrections.

=item C<:american>, C<:no-american> [default: C<:no-american>]

If enabled, American English is desirable; include corrections from
British English to American English. For example, "colour" should be
replaced with "color".

=item C<:british>, C<:no-british> [default: C<:no-british>]

If enabled, British English is desirable; include corrections from
American English to British English. For example, "recognized" should
be replaced with "recognised".

=item C<:punct>, C<:no-punct> [default: C<:punct>]

If enabled, include corrections which introduce punctuation characters;
for example, "dont" should be replaced with "don't".

C<:no-punct> is often useful when scanning input text where
punctuation characters have special meaning, such as in most
programming languages.

=item C<:no-defaults>

If set, the corrections map only includes sets which have been
explicitly enabled.

=back

It's possible to C<use> the package several times if multiple mappings are
needed, as in the following example:

  # one map for common mistakes, another for british->american only
  use Lingua::EN::CommonMistakes qw(%MISTAKES_COMMON);
  use Lingua::EN::CommonMistakes qw(:no-defaults :american %MISTAKES_GB_TO_US);

=head1 WHY?

One might justifiably wonder why it would make sense to use a list of
mistakes rather than a full dictionary when spell checking.

Spell checking typically uses a whitelist approach: all words are
considered incorrect unless they can be found in the whitelist
(dictionary). This module instead facilitates a blacklist approach:
words are considered correct unless they can be found in the blacklist
(map of mistakes).

A blacklist approach to spell-checking is often more suitable than a
whitelist approach when scanning text which is partly but not entirely
English.

Computer programs are a prime example of semi-English documents;
comments and identifiers may be written in English, with additional
restrictions (such as no punctuation characters permitted in
identifiers) and often contain words which are intentionally not
spelled correctly (abbreviations or corruptions of valid English
words, e.g. "int" for "integer").

Other examples include mixed language documents or documents which are
ostensibly English but contain a lot of domain-specific jargon
unlikely to be found in an English dictionary.

Despite the fact that such bodies of text are only partly English, any
occurrences of words in the blacklist are likely to be genuine errors.

A blacklist approach also makes sense when it is more important to
have a low rate of false positives than it is to find every error (for
example, an automated system which risks being ignored if it generates
too many reports of dubious value).

=head1 AUTHOR

Rohan McGovern, C<rohan@mcgovern.id.au>

=head1 BUGS

Please view and report any bugs here:
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-EN-CommonMistakes>

=head1 ACKNOWLEDGEMENTS

Most of the word list has been sourced from other projects, including:

=over

=item *

I<krazy> code checker tool, written for KDE:
L<http://gitorious.org/krazy/krazy/blobs/master/plugins/general/spelling>

=item *

I<lintian> package checker tool, written for Debian:
L<http://anonscm.debian.org/gitweb/?p=lintian/lintian.git;a=blob;f=data/spelling/corrections>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Rohan McGovern.

Incorporated word lists may be Copyright their respective authors.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1;

__DATA__
aasume assume
aasumed assumed
aasumes assumes
abailable available
abandonning abandoning
abbrevation abbreviation
abbrevations abbreviations
abbriviate abbreviate
abbriviated abbreviated
abbriviates abbreviates
abbriviation abbreviation
abigious ambiguous
abilties abilities
abitrate arbitrate
ablolute absolute
abov above
abreviate abbreviate
abreviates abbreviates
absense absence
absolut absolute
absoulte absolute
acceleratoin acceleration
accelleration acceleration
acces access
accesible accessible
accesing accessing
accesnt accent
accessable accessible
accidentaly accidentally
accidentually accidentally
accomodate accommodate
accomodates accommodates
accout account
accross across
acessable accessible
acess access
achive achieve
achived achieved
achives achieves
achiving achieving
acient ancient
acknoledge acknowledge
acknoledged acknowledged
acknoledges acknowledges
acknowldegement acknowldegement
acknowlege acknowledge
ackowledge acknowledge
ackowledged acknowledged
acommodate accommodate
acommodated accommodated
acommodates accommodates
aconym acronym
aconyms acronyms
acording according
acount account
acounted accounted
acounting accounting
acounts accounts
acout account
acouted accounted
acouting accounting
acouts accounts
activ active
activete activate
acton action
actons actions
acually actually
acumulating accumulating
adapat adapt
adapated adapted
adapater adapter
adapaters adapters
adapating adapting
adapats adapts
adatp adapt
adatped adapted
adatper adapter
adatpers adapters
adatping adapting
adatps adapts
addded added
adddress address
addional additional
additinoal additional
additinoally additionally
additionaly additionally
additionnal additional
additionnally additionally
additionnaly additionally
additonal additional
addreses addresses
addtionally additionally
addtionaly additionalyy
aditional additional
aditionally additionally
aditionaly additionally
adminstrator administrator
adminstrators administrators
adress address
adressed addressed
adresses addresses
advertize advertise
adviced advised
afecting affecting
afganistan afghanistan
agressive aggressive
agressively aggressively
albumns albums
alegorical allegorical
algorith algorithm
algorithmical algorithmically
algoritm algorithm
algoritms algorithms
algorrithm algorithm
algorritm algorithm
aligement alignment
alignement alignment
allign align
alligned aligned
allignment alignment
alligns aligns
allmost almost
allpication application
allready already
allways always
alogirhtms algorithms
alook a look
alot a lot
alow allow
alows allows
alrady already
alreay already
alternativly alternatively
altough although
ambigious ambiguous
ambiguouity ambiguity
ammount amount
amoung among
amout amount
analagous analogous
analizer analyzer
analogue analog
analysator analyzer
anfer after
angainst against
ang and
anniversery anniversary
annouced announced
annoucement announcement
annouces announces
announcments announcements
anomolies anomalies
anomoly anomaly
anwer answer
anwered answered
anwers answers
anwser answer
anwsers answers
apearance appearance
apear appear
apeared appeared
apears appears
aplication application
aplications applications
appeareance appearance
appearence appearance
appeares appears
apperarance appearance
appers appears
applicaiton application
applicaitons applications
applicalble applicable
appliction application
applictions applications
appplication application
appplications applications
approciate appreciate
approciated appreciated
approciates appreciates
appropiate appropriate
appropriatly appropriately
approriate appropriate
approximatly approximately
apropriate appropriate
aquire acquire
aquired acquired
aquires acquires
arbitarily arbitrarily
arbitary arbitrary
architechture architecture
arguement argument
arguements arguments
aribrary arbitrary
aribtrarily arbitrarily
aribtrary arbitrary
aritmetic arithmetic
arne't aren't
arraival arrival
arround around
artifical artificial
artillary artillery
assigment assignment
assigments assignments
assistent assistant
assosciate associate
assosciated associated
assosciates associates
assosiate associate
assosiated associated
assosiates associates
assoziate associate
assoziated associated
assoziates associates
asssemble assemble
asssembled assembled
asssembler assembler
asssembles assembles
assumend assumed
asume assume
asumed assumed
asumes assumes
asuming assuming
asycronous asynchronous
asynchonous asynchronous
asynchroneously asynchronously
asyncronous asynchronous
atempt attempt
atempts attempts
aticle article
aticles articles
atleast at least
atomatically automatically
atomicly atomically
attachement attachment
attatchment attachment
attatchments attachments
attemps attempts
attruibutes attributes
auhor author
auhors authors
authentification authentication
authoratative authoritative
automaticaly automatically
automaticly automatically
automatize automate
automatized automated
automatizes automates
autonymous autonomous
autoreplacment autoreplacement
auxilary auxiliary
auxilliary auxiliary
avaiable available
avaible available
availabled available
availablity availability
availale available
availavility availability
availble available
availiable available
availibility availability
availible available
avaliable available
avaluate evaluate
avare aware
aviable available
backgroud background
backrefences backreferences
bahavior behavior
baloon balloon
baloons balloons
bandwith bandwidth
basicly basically
batery battery
beautifull beautiful
becase because
becomming becoming
becuase because
beeep beep
beeing being
beexported be exported
befor before
beggining beginning
begining beginning
belarussian belarusian
beteen between
betrween between
betweeen between
bianries binaries
blueish bluish
bofore before
bosth both
botton bottom
bottons bottoms
boudaries boundaries
boundries boundaries
boundry boundary
boxs boxes
bruning burning
buton button
butons buttons
buxfixes bugfixes
cacheing caching
calender calendar
calulation calculation
cancelation cancellation
capabilites capabilities
capatibilities capabilities
caracters characters
cariage carriage
cataloge catalog
cataloges catalogs
catalogue catalog
catalogues catalogs
catched caught
cencel cancel
ceneration generation
challange challenge
challanges challenges
changable changeable
chaning changing
characer character
characers characters
charachter character
charachters characters
charactere character
characteres characters
charakter character
charakters characters
charater character
charaters characters
charcter character
chatacter character
chatacters characters
childs children
chnage change
chnages changes
choosed chose
choosen chosen
chosing choosing
cirumstance circumstance
cirumstances circumstances
classess classes
cloumn column
cloumns columns
coffie coffee
colaborate collaborate
colaboration collaboration
collapsable collapsible
collecion collection
collecions collections
collumn column
collumns columns
colorfull colorful
coloum column
coloumn column
coloumns columns
coloums columns
colum column
colums columns
comamnd command
comamnds commands
comand command
comination combination
cominations combinations
comit commit
commense commence
commerical commercial
commerically commercially
comming coming
comminucation communication
commited committed
commiting committing
committ commit
commmand command
commmands commands
commoditiy commodity
commuication communication
commuications communications
communcation communication
communcations communications
compability compatibility
comparision comparison
comparisions comparisons
compatability compatibility
compatable compatible
compatibiliy compatibility
compatibilty compatibility
compatiblity compatibility
compedium compendium
compediums compendiums
compiile compile
compiiled compiled
compilant compliant
compleatly completely
compleion completion
completly completely
complient compliant
compres compress
compresion compression
comression compression
comsumer consumer
comsumers consumers
comunication communication
comunications communications
concatonate concatenate
concatonated concatenated
concurent concurrent
concurently concurrently
conditionaly conditionally
configration configuration
configrations configurations
configuratoin configuration
configuraton configuration
configuratons configurations
conjuction conjunction
connectinos connections
connent connect
connents connects
connnection connection
connnections connections
consecutivly consecutively
consequtive consecutive
consistancy consistency
consistant consistent
constuctor constructor
constuctors constructors
containes contains
containg containing
containts contains
contence contents
contexual contextual
contigious contiguous
contingous contiguous
continouos continuous
continous continuous
continously continuously
continueing continuing
contiribute contribute
contiributed contributed
contiributes contributes
contiributing contributing
contoller controller
contorll control
contorlled controlled
contorller controller
contorlls controls
contraints constraints
controler controller
controling controlling
controll control
controlls controls
convenenient convenient
conver convert
convers converts
convertor converter
convient convenient
conviently conveniently
convinience convenience
convinient convenient
conviniently conveniently
coordiator coordinator
coordiators coordinators
copys copies
corected corrected
coresponding corresponding
corrdinate coordinate
corrdinates coordinates
corrent correct
correponding corresponding
correponds corresponds
correspoding corresponding
costraints constraints
coudn't couldn't
coursor cursor
coursors cursors
coverted converted
coverts converts
coypright copyright
coyprights copyrights
cricle circle
cricles circles
criticisim criticism
criticisims criticisms
cryptocraphic cryptographic
cryptograhy cryptography
culculate calculate
culculated calculated
culculating calculating
curently currently
curren current
currenty currently
curteousy courtesy
custimisable customizable
custimisation customization
custimise customize
custimised customized
custimizable customizable
custimization customization
custimize customize
custimized customized
cutsom custom
cutt cut
cutted cut
dafault default
datas data
dcopcient dcopclient
dcopcients dcopclients
deactive deactivate
deactives deactivates
deafult default
deamon daemon
deamons daemons
debain Debian
debuging debugging
declar declare
declars declares
decompres decompress
decriptor descriptor
decriptors descriptors
defaul default
defauls defaults
defered deferred
definate definite
definately definitely
defination definition
defininition definition
defininitions definitions
defintion definition
defintions definitions
dekstop desktop
dekstops desktop
delared declared
delare declare
delares declares
delaring declaring
delemiter delimiter
deleteing deleting
demonsrative demonstrative
deniel denial
denstiy density
depencies dependencies
depency dependency
dependancies dependencies
dependancy dependency
dependant dependent
dependeds depends
dependend dependent
dependig depending
depreacted deprecated
depreacte deprecate
depricated deprecated
derfined defined
derfine define
derfines defines
derivs derives
desactivate deactivate
descide decide
desciptor descriptor
desciptors descriptors
descryption description
descryptions descriptions
desctroy destroy
desctroyed destroyed
desdination destination
desdinations destinations
desiabled disabled
desiable disable
desidered desired
desidere desire
desination destination
desinations destinations
deskop desktop
deskops desktops
desription description
desriptions descriptions
destiantion destination
destiantions destinations
destrutor destructor
detabase database
determiend determined
determien determine
determiens determines
determinated determined
determins determines
detremined determined
detremine determine
detremines determines
detroy destroy
detructor destructor
devellop develop
develloped developed
devellops develops
developement development
developerss developers
developped developed
developpement development
developper developer
developpment development
deveolpment development
devevelopment development
devided divided
devide divide
devides divides
diabled disabled
diable disable
diaglostic diagnostic
dialag dialog
dialags dialogs
dialler dialer
diallers dialers
dialling dialing
diaog dialog
diaogs dialog
dictionnary dictionary
diffcult difficult
diffculty difficulty
differenciated differentiated
differenciate differentiate
differenciates differentiates
differenly differently
differntiated differentiated
differntiates differentiates
dificult difficult
dificulty difficulty
difusion diffusion
digitised digitized
digitise digitize
diplay display
diplayed displayed
diplays displays
dirctely directly
dirctories directories
dirctory directory
direcories directories
direcory directory
directoies directories
directorys directories
directoy directory
disactivate deactivate
disapeared disappeared
disapper disappear
disappered disappeared
disappers disappears
disbaled disabled
disbale disable
disbales disables
discontigous discontiguous
discpline discipline
discription description
discriptions descriptions
dispertion dispersion
disppearance disappearance
disppear disappear
disppeared disappeared
disppears disappears
dissapears disappears
dissappearance disappearance
dissappear disappear
dissappeared disappeared
dissappears disappears
dissassembled disassembled
dissassemble disassemble
dissassembler disassembler
dissassembles disassembles
dissassembly disassembly
distingush distinguish
distingushed distinguished
distingushes distinguishes
distribte distribute
distribtes distributes
distribtuion distribution
distribtuions distributions
distrubutor distributor
distrubutors distributors
divizor divisor
divizors divisors
docucument document
docucuments documents
docuentation documentation
documantation documentation
documentaion documentation
documentaiton documentation
documentors documenters
doens't doesn't
donnot do not
dont't don't
dou do
downlad download
downlads downloads
draging dragging
dreamt dreamed
droped dropped
duotes quotes
durring during
dynamicly dynamically
eallocate deallocate
eample example
easilly easily
ecspecially especially
edditable editable
editory editor
editting editing
efficent efficient
efficently efficiently
effiency efficiency
elemt element
elemts elements
eletronic electronic
embedabble embeddable
embedable embeddable
embeddabble embeddable
embeded embedded
emcompass encompass
emited emitted
emticon emoticon
emtiness emptiness
emty empty
enchanced enhanced
encorporating incorporating
encyption encryption
endianess endianness
enhaced enhanced
enhandcement enhancement
enhandcements enhancements
enles endless
enlightnment enlightenment
enocded encoded
enought enough
enterily entirely
entitities entities
entriess entries
entrys entries
enumarated enumerated
envirnmental environmental
envirnment environment
envirnments environments
envirnomental environmental
envirnoment environment
envirnoments environments
enviroiment environment
enviromental environmental
enviroment environment
enviroments environments
environement environment
environemntal environmental
environemnt environment
environemnts environments
environental environmental
environent environment
environents environments
equador ecuador
equiped equipped
equivelant equivalent
equivilant equivalent
equlas equals
errorous erroneous
errror error
errrors errors
escriptor descriptor
escriptors descriptors
espacially especially
espesially especially
evaluted evaluated
evalute evaluate
evalutes evaluates
evaluting evaluating
everytime every time
exacly exactly
exapmle example
exapmles examples
excecpt except
excecutable executable
exceded exceeded
excellant excellent
execeeded exceeded
execeede exceede
execeedes exceedes
execess excess
exection execution
exections executions
execuable executable
execuables executables
executeble executable
executebles executables
exept except
exisiting existing
existance existence
existant existent
exlcude exclude
exlcusive exclusive
exlusive exclusive
exlusively exclusively
exmaple example
exmaples examples
expecially especially
experienceing experiencing
expeted expected
expet expect
expets expects
explaination explanation
explicitely explicitly
explicity explicitly
explict explicit
explictly explicitly
explit explicit
expresion expression
expresions expressions
exprimental experimental
extensability extensibility
extented extended
extention extension
extentions extensions
extesion extension
extracter extractor
fabilous fabulous
failuer failure
falg flag
falgs flags
familar familiar
familarity familiarity
fastes fastest
fatser faster
featue feature
featues features
feauture feature
feautures features
feeded fed
fetaure feature
fetaures features
filsystem filesystem
filsystems filesystems
finded found
firts first
firware firmware
fisrt first
fixiated fixated
fixiate fixate
fixiating fixating
flaged flagged
flavours flavors
focussed focused
folllowed followed
folllowing following
follwed followed
follwing following
folowing following
footnotexs footnotes
formaly formally
forse force
fortan fortran
fortunally fortunately
fortunantly fortunately
fortunatly fortunately
forwardig forwarding
foward forward
fowards forward
fragement fragment
fragements fragment
framesyle framestyle
framesyles framestyles
framset frameset
framsets framesets
framwork framework
fucntion function
fucntions functions
fuction function
fuctions functions
fufiled fulfilled
fufil fulfill
fufilled fulfilled
fufill fulfill
fufills fulfills
fufils fulfills
fulfiling fulfilling
fullfiled fulfilled
fullfilled fulfilled
fullfills fulfills
fullfils fulfills
funcion function
funcions functions
funciton function
funcitons function
functin function
functins function
functionallity functionality
functionaly functionally
functionnality functionality
functonality functionality
funtional functional
funtionality functionality
funtion function
funtions functions
furthur further
futhermore furthermore
gaalxies galaxies
gamee game
generiously generously
gernerated generated
gernerate generate
gernerates generates
ges goes
ghostscipt ghostscript
giuded guided
giude guide
giudes guides
globaly globally
goind going
gostscript ghostscript
grabing grabbing
grahical graphical
grahpical graphical
gramatics grammar
grapic graphic
grapphis graphics
greyed grayed
guage gauge
guaranted guaranteed
guarenteed guaranteed
guarranteed guaranteed
guarrantee guarantee
gziped gzipped
halfs halves
handeling handling
handfull handful
harware hardware
havn't haven't
heigt height
heigth height
heigths heights
heigts heights
heirarchically hierarchically
helpfull helpful
hiddden hidden
hierachical hierarchical
hierachically hierarchically
hierachy hierarchy
hierarchie hierarchy
highlighlighted highlighted
highlighlight highlight
highligting highlighting
higlighting highlighting
hirarchies hierarchies
hirarchy hierarchy
honours honors
horziontal horizontal
horziontally horizontally
howver however
hypen hyphen
hypens hyphens
hysically physically
hysical physical
iconized iconified
iconize iconifiy
illumnate illuminate
illumnating illuminating
imaginery imaginary
imitatation imitation
imitatations imitations
immeadiately immediately
immedialely immediately
immediatly immediately
imortant important
imperical empirical
implemantation implementation
implemantations implementations
implemenation implementation
implemenations implementations
implemention implementation
implenetation implementation
implenetations implementations
implimention implementation
implimentions implementations
implmentation implementation
implmentations implementations
inactiv inactive
incldued included
incldue include
incldues includes
incomme income
incomming incoming
incompatabilities incompatibilities
incompatable incompatible
inconsistant inconsistent
incovenient inconvenient
incoveniently inconveniently
indeces indices
indendation indentation
indended intended
indentical identical
indentification identification
indentifications identifications
indepedancy independency
independant independent
independed independent
independend independent
indetectable undetectable
indicdated indicated
indicdate indicate
indicdates indicates
indice index
indictes indicates
infinitv infinitive
infomation information
informa inform
informaion information
informatation information
informatiom information
informationon information
informations information
infromation information
inifity infinity
inital initial
initalization initialization
initalized initialized
initalize initialize
initalizes initializes
initally initially
initators initiators
initializiation initialization
initialyzed initialized
initialyze initialize
initialyzes initializes
initilialyzed initialized
initilialyze initialize
initilialyzes initializes
initilization initialization
initilizations initializations
initilized initialized
initilize initialize
initilizes initializes
innacurate inaccurate
innacurately inaccurately
inofficial unofficial
insde inside
inteface interface
intefaces interfaces
integreated integrated
integrety integrity
integrey integrity
intendet intended
interactivelly interactively
interchangable interchangeable
interfer interfere
interfrace interface
interisting interesting
interistingly interestingly
intermittant intermittent
interrrupt interrupt
interrrupts interrupts
interrumped interrupted
interrups interrupts
interupted interrupted
interupt interrupt
interupts interrupts
intervall interval
intervalls intervals
intiailized initialized
intiailize initialize
intiailizes initializes
intial initial
intialisation initialization
intialisations initializations
intialization initialization
intializations initializations
intialize initialize
intializing initializing
intregral integral
introdutionary introductory
introdution introduction
introdutions introductions
intrrupted interrupted
intrrupt interrupt
intrrupts interrupts
intruction instruction
intructions instructions
intuative intuitive
invarient invariant
invarients invariants
invocate invoke
invoced invoked
invoce invoke
invokate invoke
invokation invocation
invokations invocations
irrevesible irreversible
isntance instance
isntances instances
is'nt isn't
issueing issuing
istories histories
istory history
iterface interface
iterfaces interfaces
itselfs itself
itterate iterate
itterates iterates
itterator iterator
itterators iterators
jave java
journalised journalized
judgement judgment
judgements judgments
kdelbase kdebase
keyboad keyboard
keyboads keyboards
klicking clicking
knowlege knowledge
konquerer konqueror
konstant constant
konstants constants
kscreensave kscreensaver
labelling labeling
labell label
langage language
langauage language
langauge language
langugage language
lauching launching
lauch launch
layed laid
leace lease
learnt learned
leats least
leightweight lightweight
lenght length
lesstiff lesstif
libaries libraries
libary library
librairies libraries
libraris libraries
licenced licensed
licenceing licencing
licence license
licences licenses
licens license
liset list
listenening listening
listveiw listview
litle little
litteral literal
litterally literally
localy locally
loggging logging
loggin login
logile logfile
looged logged
losely loosely
maanged managed
maange manage
maanges manages
machinary machinery
maching matching
magnication magnification
magnifcation magnification
mailboxs mailboxes
maillinglist mailinglist
maillinglists mailinglists
maintainance maintenance
maintainence maintenance
maintan maintain
makeing making
malicous malicious
malicousness maliciousness
malplaced misplaced
malplace misplace
mamage manage
mamagement management
managable manageable
managment management
manangement management
mannually manually
mannual manual
manoeuvering maneuvering
mantainer maintainer
mantainership maintainership
mantainers maintainers
manupulation manipulation
manupulations manipulations
marbels marbles
matchs matches
mathimatical mathematical
mathimatic mathematic
mathimatics mathematics
maximimum maximum
maxium maximum
mdification modification
mdifications modifications
mdified modified
mdify modify
ment meant
menues menus
mesage message
mesages messages
messanger messenger
messangers messengers
messanging messaging
messenging messaging
messsage message
messsages messages
microprocesspr microprocessor
microsft microsoft
millimetres millimeters
milliseonds milliseconds
mimimum minimum
minimun minimum
minium minimum
minumum minimum
miscelaneous miscellaneous
miscelanous miscellaneous
miscellaneaous miscellaneous
miscellanous miscellaneous
miscelleneous miscellaneous
misformed malformed
mispeled misspelled
mispelled misspelled
mispelt misspelt
misteries mysteries
mistery mystery
mmnemonic mnemonic
modifes modifies
modifing modifying
modul module
modulues modules
monochorome monochrome
monochromo monochrome
monocrome monochrome
mosue mouse
mozzila mozilla
mroe more
mssing missing
mulitimedia multimedia
mulitple multiple
mulitplied multiplied
multible multiple
multidimensionnal multidimensional
multipe multiple
multy multi
mutiple multiple
nam name
nams names
navagating navigating
nead need
neccesarily necessarily
neccesary necessary
neccessarily necessarily
neccessary necessary
neccessities necessities
neccessity necessity
necesary necessary
necesserily necessarily
necessery necessary
nedd need
neet need
negativ negative
negociated negotiated
negociation negotiation
negotation negotiation
neogtiation negotiation
nescessary necessary
nessecarily necessarily
nessecarrily necessarily
nessecarry necessary
nessecary necessary
nessesarily necessarily
nessesary necessary
nessessary necessary
neworked networked
neworking networking
nework network
neworks networks
newtorked networked
newtorking networking
newtork network
newtorks networks
nickanme nickname
nickanmes nicknames
nonexistant nonexistent
noone nobody
noone no-one
noticable noticeable
notications notifications
nucleous nucleus
obtail obtain
obtails obtains
o'caml OCaml
occationally occasionally
occoured occurred
occourence occurrence
occourences occurrences
occouring occurring
occurance occurrence
occurances occurrences
occured occurred
occurence occurrence
occurences occurrences
occure occur
occuring occurring
occurrance occurrence
occurrances occurrences
ocupied occupied
offically officially
offical official
omitt omit
ommited omitted
ommit omit
ommitted omitted
onself oneself
onthe on the
opend opened
optimite optimize
optionnally optionally
optionnal optional
optmizations optimizations
orangeish orangish
orginated originated
orginate originate
orginates originates
orginating originating
orientatied orientated
orientied oriented
originaly originally
orignally original
orignal original
oscilated oscillated
oscilate oscillate
oscilates oscillates
oscilating oscillating
otehr other
otehrs others
ouput output
ouputs outputs
ourselfes ourselves
outputing outputting
overaall overall
overidden overridden
overiden overridden
overriden overridden
ownes owns
pacakge package
pachage package
packacge package
packege package
packge package
pakage package
pakages packages
pallette palette
panelised panelized
paramameters parameters
paramater parameter
paramaters parameters
parametes parameters
parametised parametrised
parametre parameter
parametres parameters
paramter parameter
paramters parameters
particip participle
particularily particularly
pased passed
paticular particular
pendantic pedantic
pendings pending
peprocessor preprocessor
percentate percentage
percentates percentages
percetage percentage
percetages percentages
perfomance performance
perfoming performing
performace performance
periferially peripherally
periferial peripheral
permision permission
permisions permissions
permissable permissible
permissons permissions
persistant persistent
personalizsation personalization
perticularly particularly
perticular particular
phyiscally physically
phyiscal physical
plaform platform
plaforms platforms
plattform platform
pleaes please
plese please
ploting plotting
poer power
poers powers
poinnter pointer
politness politeness
porgram program
porgrams programs
posibilities possibilities
posibility possibility
posible possible
positon position
positons positions
possebilities possibilities
possebility possibility
possibilites possibilities
possibilty possibility
possiblity possibility
posssibility possibility
postgressql PostgreSQL
potentally potentially
potental potential
powerfull powerful
practise practice
practising practicing
preceeded preceded
preceede precede
preceedes precedes
preceeding preceding
precendence precedence
precison precision
precisons precisions
precission precision
preemphasised preemphasized
prefered preferred
prefere prefer
preferrable preferable
preferrably preferably
prefferably preferably
prefiously previously
prefious previous
preformance performance
prepaired prepared
prerequisits prerequisites
presense presence
pressentation presentation
pressentations presentations
prgramm program
prgramms programs
primative primitive
princliple principle
prining printing
priorty priority
privelege privilege
priveleges privileges
priviledge privilege
priviledges privileges
privilige privilege
priviliges privileges
probatilities probabilities
probatility probability
probelm problem
probelms problems
proberly properly
problme problem
problmes problems
procceed proceed
proccesors processors
proceedure procedure
proceedures procedures
proces process
processessing processing
processess processes
processpr processor
processsing processing
proctection protection
proctections protections
proecsses processes
proecss process
progams programs
progession progression
progess progress
programers programmers
programing programming
programme program
programmes programs
programm program
programms programs
projet project
projets projects
promiscousness promiscuousness
promiscous promiscuous
promped prompted
promps prompts
pronnounced pronounced
prononciation pronunciation
pronouce pronounce
pronounciation pronunciation
pronounciations pronunciations
pronunced pronounced
pronunce pronounce
pronunces pronounces
pronunciated pronounced
properies properties
propertites properties
propery property
propigate propagate
propigation propagation
propogated propagated
propogate propagate
propogates propagates
prosess process
protable portable
protcol protocol
protecion protection
protocoll protocol
protoype prototype
protoypes prototypes
proxys proxies
psuedo pseudo
psychadelic psychedelic
purposee purpose
purposees purposes
purpouse purpose
purpouses purposes
quatna quanta
queing queuing
quering querying
querys queries
quiten quiet
quiting quitting
readony readonly
realised realized
realise realize
realises realizes
realy really
reamde readme
reasearcher researcher
reasearchers researchers
reasearch research
reasonnable reasonable
reasonnably reasonably
receieved received
receieve receive
receieves receives
recepeient recipient
recepeients recipients
recepient recipient
recepients recipients
recevied received
recevie receive
recevier receiver
recevies receives
receving receiving
recieved received
recieve receive
reciever receiver
recieves receives
recived received
recive receive
reciver receiver
recives receives
recogniced recognised
recognizeable recognizable
recomended recommended
recomend recommend
recommanded recommended
recommand recommend
recommented recommended
recomment recommend
redialling redialing
redircet redirect
redirectrion redirection
reenabled re-enabled
reenable re-enable
reencode re-encode
reets resets
refence reference
refered referred
refering referring
refeshes refreshes
refesh refresh
refreshs refreshes
regarless regardless
registaration registration
registarations registrations
registed registered
registerd registered
registraration registration
registred registered
regsiter register
regsiters registers
regulamentations regulations
regulare regular
regularily regularly
reigster register
reigsters registers
reimplemenation reimplementation
reimplemenations reimplementations
releated related
releate relate
relection reselection
relections reselections
relevent relevant
relocateable relocatable
remaing remaining
remeber remember
remebers remembers
remoote remote
remotley remotely
removeable removable
renderes renders
renewd renewed
reorienting reorientating
repalcement replacement
repalcements replacements
repectively respectively
replacments replacements
replys replies
reponsibilities responsibilities
reponsibility responsibility
requeriment requirement
requeriments requirements
requeusted requested
requeuster requester
requeusting requesting
requeust request
requeusts requests
requiere require
requred required
requried required
resaon reason
resently recently
resetted reset
resistent resistant
resizeable resizable
resognized recognized
resognize recognize
resonable reasonable
resonably reasonably
resoure resource
resoures resources
responsability responsibility
responsivness responsiveness
resported reported
resport report
resports reports
resposible responsible
resposibly responsibly
ressize resize
ressource resource
ressources resources
ressoure resource
ressoures resources
retransmited retransmitted
retreived retrieved
retreive retrieve
retreives retrieves
retult result
retults results
rewriteble rewritable
rewritebles rewritables
richt right
rigths rights
rigt right
rmeoved removed
rmeove remove
rmeoves removes
runned ran
runnning running
sacrifying sacrificing
safly safely
saftey safety
satified satisfied
savable saveable
savely safely
savety safety
scalled scaled
scather scatter
scathers scatters
scenerio scenario
scenerios scenarios
sceptical skeptical
schduler scheduler
schdulers schedulers
searchs searches
sectionning sectioning
secund second
selction selection
selctions selections
selectde selected
sensistve sensitive
separatly separately
separed separated
separeted separated
separete separate
sepcified specified
sepcify specify
seperated separated
seperately separately
seperate separate
seperates separates
seperation separation
seperations separations
seperatly separately
seperator separator
seperators separators
sepperate separate
sequencially sequentially
sequencial sequential
sertificate certificate
sertificated certificated
sertificates certificates
serveral several
setted set
setts sets
sheduled scheduled
sheme scheme
shemes schemes
shorctut shortcut
shorctuts shortcuts
shoud should
shuld should
shure sure
similarily similarly
similiarly similarly
similiar similar
simlar similar
simliar similar
simpliest simplest
simultaneuosly simultaneously
simultaneuos simultaneous
skript script
skripts scripts
slewin slewing
smaple sample
smaples samples
softwares software
sombody somebody
somehwat somewhat
soure source
soures sources
sparcely sparsely
speach speech
speakiing speaking
specefied specified
specfic specific
specfied specified
specialised specialized
specialise specialize
specialises specializes
speciefied specified
specifc specific
specifed specified
specifes specifies
specificatin specification
specificaton specification
specificiation specification
specificiations specifications
specifieing specifying
specifing specifying
specifiy specify
speficied specified
speling spelling
spezifying specifying
spezify specify
splitted split
spreaded spread
sprectra spectra
sprectrum spectrum
staically statically
standardss standards
standars standards
standar standard
standart standard
startp startup
statfeul stateful
statfull stateful
staticly statically
storeys storys
storey story
straighforward straightforward
streched stretched
streches stretches
strech stretch
striked stroked
stucked stuck
stuctures structures
stucture structure
styleshets stylesheets
styleshet stylesheet
subcribed subscribed
subcriber subscriber
subcribes subscribes
subcribe subscribe
subdirectoires subdirectories
subdirectorys subdirectories
suble subtle
subseqently subsequently
substracting subtracting
substractions subtractions
substraction subtraction
substract subtract
subystems subsystems
subystem subsystem
succeded succeeded
succeds succeeds
succed succeed
succesfully successfully
succesful successful
succesfuly successfully
succesively successively
succesive successive
succesors successors
succesor successor
successfull successful
sucesses successes
sucessfull successful
sucessfully successfully
sucessfuly successfully
sucess success
sufficently sufficiently
sufficent sufficient
superflous superfluous
superseeded superseded
suplied supplied
suport support
supossed supposed
suposse suppose
suppored supported
supportin supporting
suppoted supported
suppported supported
suppport support
supressed suppressed
supresses suppresses
supress suppress
suprised surprised
suprises surprises
suprise surprise
surpresses suppresses
susbstituted substituted
susbstitutes substitutes
susbstitute substitute
suspicously suspiciously
swaped swapped
synax syntax
synchonizations synchronizations
synchonization synchronization
synchonized synchronized
synchroneously synchronously
synchronitation synchronization
synchronyze synchronize
syncronization synchronization
syncronized synchronized
syncronizes synchronizes
syncronize synchronize
syncronizing synchronizing
syncronous synchronous
syncronus synchronous
syncrounous synchronous
syndroms syndromes
syndrom syndrome
syntex syntax
synthetizers synthesizers
synthetizer synthesizer
synthezisers synthesizers
syntheziser synthesizer
syste system
sytems systems
sytem system
sythesis synthesis
taht that
talbs tables
talse false
targetted targeted
targetting targeting
targget target
tartget target
tecnologies technologies
tecnology technology
teh the
tempararily temporarily
temparary temporary
tempertures temperatures
temperture temperature
terminatin terminating
texured textured
texures textures
texure texture
themc them
thet that
threshholds thresholds
threshhold threshold
throttes throttles
throtte throttle
throught through
throuth through
tiggered triggered
tihs this
timditiy timidity
timdity timidity
timming timing
tranceivers transceivers
tranceiver transceiver
tranfers transfers
tranfer transfer
tranisition transition
tranisiton transition
tranlated translated
tranlates translates
tranlate translate
tranlations translations
tranlation translation
transalted translated
transaltes translates
transalte translate
transations transactions
transation transaction
transfered transferred
transfering transferring
transferrable transferable
transmiterd transmitterd
transmiters transmitters
transmiter transmitter
transmiting transmitting
transmitions transmissions
transmition transmission
transmittions transmissions
transmittion transmission
transparancy transparency
transparant transparent
trasfered transferred
trasfers transfers
trasfer transfer
trasmission transmission
travellers travelers
traveller traveler
travelling traveling
treshold threshold
trhee three
trigerring triggering
triggerg triggering
triggerred triggered
truely truly
trys tries
typess types
uglyness ugliness
unabiguousness unambiguousness
unabiguous unambiguous
unaccesible unaccessible
unallowed disallowed
unamed unnamed
unathorized unauthorized
unconditionaly unconditionally
uncrypted unencrypted
uncutt uncut
underlieing underlying
underrruns underruns
underrrun underrun
understandement understanding
undesireable undesirable
undestood understood
undexpected unexpected
undoedne undid
unecessarily unnecessarily
unecessary unnecessary
unexecpted unexpected
unexperienced inexperienced
unexperience inexperience
unfortunally unfortunately
unfortunantly unfortunately
unfortunatelly unfortunately
unfortunatly unfortunately
uniq unique
unitialized uninitialized
unknonw unknown
unkown unknown
unmoveable unmovable
unneccessary unnecessary
unneccessay unnecessary
unsellectected unselected
unsuccesful unsuccessful
unuseable unusable
unuseful useless
unusuable unusable
unvailable unavailable
uploades uploads
upppercase uppercase
usally usually
usefule useful
usefull useful
usege usage
usera users
usere user
usetnet Usenet
usuable usable
usuallly usually
usualy usually
utilites utilities
utillities utilities
utilties utilities
utiltity utility
utitlty utility
vaild valid
valied valid
valueable valuable
varb verb
variantions variations
varient variant
vays ways
vay way
verbse verbose
verfications verifications
verfication verification
verically vertically
verisons versions
verison version
versins versions
versin version
verson version
verticaly vertically
verticies vertices
veryify verify
vicefersa vice-versa
vicitims victims
vicitim victim
visiblity visibility
visiters visitors
visul visual
vitual virtual
volonteering volunteering
volonteers volunteers
volonteer volunteer
volumen volume
voribis vorbis
vrtual virtual
waranties warranties
waranty warranty
wastefull wasteful
wastefuly wastefully
wast waste
watsefull wasteful
watsefully wastefully
watseful wasteful
watse waste
wats waste
weigths weights
weigth weight
wether whether
whataver whatever
wheter whether
whicn which
whishes wishes
whish wish
whitch which
whithin within
whith with
whitin within
wiazrds wizards
wiazrd wizard
wich which
wierd weird
wieving viewing
wievs view
wiev view
wih with
willl will
withing within
wnat want
workimg working
workin working
workstatios workstation
workstatio workstation
woud would
wouldd would
writting writing
xwindows X
yeld yield
yesturday yesterday
yorself yourself
you'ld you would
yourcontrycode yourcountrycode
yur your

:punct
didnt didn't
doesnt doesn't
dont don't
hasnt hasn't
shouldnt shouldn't

:british
acknowledgment acknowledgement
acknowledgments acknowledgements
analyze analyse
analyzes analyses
behavior behaviour
centralize centralise
centralized centralised
center centre
color colour
colors colours
customizable customisable
customization customisation
customize customise
customized customised
favor favour
favorable favourable
favorite favourite
favors favours
honor honour
honoring honouring
initialization initialisation
initialize initialise
initializing initialising
internationalization internationalisation
internationalizations internationalisations
ionization ionisation
ionizations ionisations
localization localisation
localizations localisations
minimize minimise
minimizing minimising
neighbor neighbour
neighborhood neighbourhood
neighbors neighbours
normalization normalisation
normalizations normalisations
optimization optimisation
optimizations optimisations
optimize optimise
organization organisation
organization organisation
organizational organisational
organizations organisations
organize organise
organized organised
organizer organiser
organizing organising
recognize recognise
recognized recognised
recognizes recognises
synchronization synchronisation
synchronizations synchronisations
synchronize synchronise
synchronized synchronised
synchronizes synchronises
utilization utilisation
utilizations utilisations
visualization visualisation
visualizations visualisations
visualize visualise

:american
acknowledgement acknowledgment
acknowledgements acknowledgments
analyse analyze
analyses analyzes
authorisation authorization
authorisations authorizations
behaviour behavior
centralise centralize
centralised centralized
centre center
colour color
colours colors
customisable customizable
customisation customization
customise customize
customised customized
favour favor
favourable favorable
favourite favorite
favours favors
honour honor
honouring honoring
initialisation initialization
initialise initialize
initialising initializing
internationalisation internationalization
internationalisations internationalizations
ionisation ionization
ionisations ionizations
localisation localization
localisations localizations
minimise minimize
minimising minimizing
neighbour neighbor
neighbourhood neighborhood
neighbours neighbors
normalisation normalization
normalisations normalizations
optimisation optimization
optimisations optimizations
optimise optimize
organisation organization
organisation organization
organisational organizational
organisations organizations
organise organize
organised organized
organiser organizer
organising organizing
recognise recognize
recognised recognized
recognises recognizes
synchronisation synchronization
synchronisations synchronizations
synchronise synchronize
synchronised synchronized
synchronises synchronizes
utilisation utilization
utilisations utilizations
visualisation visualization
visualisations visualizations
visualise visualize
