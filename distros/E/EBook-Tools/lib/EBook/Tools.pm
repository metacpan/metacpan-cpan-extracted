package EBook::Tools;
use warnings; use strict; use utf8;
use v5.10.1; # Needed for smart-match operator and given/when
use English qw( -no_match_vars );
use version 0.74; our $VERSION = qv("0.5.4");

#use warnings::unused;

# Perl Critic overrides:
## no critic (Package variable)
# RequireBriefOpen seems to be way too brief to be useful
## no critic (RequireBriefOpen)
# Double-sigils are needed for lexical filehandles in clear print statements
## no critic (Double-sigil dereference)
our $debug = 0;



=head1 NAME

EBook::Tools - Object class for manipulating and generating E-books


=head1 DESCRIPTION

This module provides an object interface and a number of related
procedures intended to create or modify documents centered around the
International Digital Publishing Forum (IDPF) standards, currently
both OEBPS v1.2 and OPS/OPF v2.0.

=cut

=head1 SYNOPSIS

 use EBook::Tools qw(split_metadata system_tidy_xml);
 $EBook::Tools::tidysafety = 2;

 my $opffile = split_metadata('ebook.html');
 my $otheropffile = 'alternate.opf';
 my $retval = system_tidy_xml($opffile,'tidy-backup.xml');
 my $ebook = EBook::Tools->new($opffile);
 $ebook->fix_opf20;
 $ebook->fix_misc;
 $ebook->print;
 $ebook->save;

 $ebook->init($otheropffile);
 $ebook->fix_oeb12;
 $ebook->gen_epub;


=head1 DEPENDENCIES

=head2 Perl Modules

=over

=item Archive::Zip

=item Data::UUID (or OSSP::UUID)

=item Date::Manip

Note that Date::Manip will die on MS Windows system unless the
TZ environment variable is set in a specific manner. See:

http://search.cpan.org/perldoc?Date::Manip#TIME_ZONES

=item File::MimeInfo

=item HTML::Parser

=item Lingua::EN::NameParse

=item Tie::IxHash

=item Time::Local

=item URI::Escape

=item XML::Twig

=back

=head2 Other Programs

=over

=item Tidy

The command "tidy" needs to be available, and ideally on the path.  If
it isn't on the path, package variable L</$tidycmd> can be set to its
absolute path.  If tidy cannot be found, L</system_tidy_xml()> and
L</system_tidy_xhtml()> will be nonfunctional.

=back

=cut


require Exporter;
use base qw(Exporter);

our @EXPORT_OK;
@EXPORT_OK = qw (
    &capitalize
    &clean_filename
    &create_epub_container
    &create_epub_mimetype
    &debug
    &excerpt_line
    &fix_datestring
    &find_in_path
    &find_links
    &find_opffile
    &hashvalue_key_self
    &hexstring
    &get_container_rootfile
    &print_memory
    &split_metadata
    &split_pre
    &strip_script
    &system_result
    &system_tidy_xml
    &system_tidy_xhtml
    &trim
    &twigelt_create_uuid
    &twigelt_fix_oeb12_atts
    &twigelt_fix_opf20_atts
    &twigelt_is_author
    &usedir
    &userconfigdir
    &ymd_validate
    );
our %EXPORT_TAGS = ('all' => [@EXPORT_OK]);

# OSSP::UUID will provide Data::UUID on systems such as Debian that do
# not distribute the original Data::UUID.
use Data::UUID;

use Archive::Zip qw( :CONSTANTS :ERROR_CODES );
use Carp;
use Cwd qw(getcwd realpath);
use Date::Manip;
require EBook::Tools::BISG;
use Encode;
require Encode::Detect;
use File::Basename qw(basename dirname fileparse);
# File::MimeInfo::Magic gets *.css right, but detects all html as
# text/html, even if it has an XML header.
use File::MimeInfo::Magic;
# File::MMagic gets text/xml right (though it still doesn't properly
# detect XHTML), but detects CSS as x-system, and has a number of
# other weird bugs.
#use File::MMagic;
use File::Path;     # Exports 'mkpath' and 'rmtree'
use File::Temp;
use HTML::Entities qw(decode_entities _decode_entities %entity2char);
#use HTML::Tidy;
use Lingua::EN::NameParse qw(case_surname);
use Tie::IxHash;
use Time::Local;
use URI::Escape;
use XML::Twig;


=head1 CONFIGURABLE PACKAGE VARIABLES

=over

=item C<%bisacsubjects>

A mapping of lowercase BISAC codes and text descriptions to standard
capitalized text descriptions.  As BISG claims copyright on this and
does not allow the lists to be redistributed, this list must be
downloaded and cached locally via C<ebook dlbisac> before it is
available.

Running the unit tests will cause this to happen automatically.

=item C<%bisactolc>

An extremely incomplete mapping of lowercase BISAC codes and text
descriptions to Library of Congress standard subjects.

=item C<%booktypes>

A hash mapping all-lowercase terms to a standard vocabulary to be used
in <dc:type> elements.

=item C<%dcelements12>

A tied IxHash mapping an all-lowercase list of Dublin Core metadata
element names to the capitalization dictated by the OEB 1.2
specification, used by the fix_oeb12() and fix_oeb12_dcmeta() methods.
Changing the tags in this list will change the tags recognized and
placed inside the <dc-metadata> element.

Order is preserved and significant -- fix_oeb12 will output DC
metadata elements in the same order as in this hash, though order for
tags of the same name is preserved from the input file.

=item C<%dcelements20>

A tied IxHash mapping an all-lowercase list of Dublin Core metadata
element names to the all-lowercase form dictated by the OPF 2.0
specification (which means it maps the all-lowercase tags to
themselves).  It is used by the fix_opf20() and fix_opf20_dcmeta()
methods.  Changing the tags in this list will change the tags
recognized and placed directly under the <metadata> element.

Order is preserved and significant -- fix_opf20 will output DC
metadata elements in the same order as in this hash, though order for
tags of the same name is preserved from the input file.

=item C<%lcsubjects>

An extremely incomplete mapping of lowercase terms to Library of
Congress subject classifications.  This is used for automatic
normalization of subject elements.  Every value in the hash has a
lowercase representation of itself as a key in addition to any
aliases.

This MUST NOT contain mappings from BISAC codes or descriptors to
Library of Congress subjects.  Use %bisactolc for that.

=item C<%nonxmlentity2char>

This is the %entity2char conversion map from HTML::Entities with the 5
pre-defined XML entities (amp, gt, lt, quot, apos) removed.  This is
used during by L</init()> to sanitize the OPF file data before
parsing.  This hash can be modified to allow and convert other
non-standard entities to unicode characters.  See HTML::Entities for
details.

=item C<%publishermap>

A hash mapping known variants of publisher names to a canonical form,
used by L</fix_publisher()>, and thus also indirectly by
L</fix_misc()>.

Keys should be entered in lowercase.  The hash can also be set empty
to prevent fix_publisher() from taking any action at all.

=item C<%referencetypes>

A hash mapping valid OPF 2.0 reference types to themselves, along with
common variants to standard types.

=item C<%relatorcodes>

A hash mapping the MARC Relator Codes (see:
http://www.loc.gov/marc/relators/relacode.html) to their descriptive
names.

=item C<%sexcodes>

A hash normalizing subject tags for erotic fiction, as used by
StoriesOnline, ASSTR, and Literotica, among others.

Unlike the other mappings, this one is *not* lowercased, and the keys
are case-sensitive.  The hash maps only to the canonical base code,
but subject normalization will also add a prefix, defaulting to the
BISAC format of 'FICTION / Erotica / '.

=item C<%strangenames>

=item C<%strangefileas>

Hashes mapping mapping known incorrect outputs of name normalization
to correct format.  The first handles the main name display, the
second the file-as output.

=item C<$tidycmd>

The tidy executable name.  This has to be a fully qualified pathname
if tidy isn't on the path.  Defaults to 'tidy'.

=item C<$tidyxhtmlerrors>

The name of the error output file from system_tidy_xhtml().  Defaults
to 'tidyxhtml-errors.txt'

=item C<$tidyxmlerrors>

The name of the error output file from system_tidy_xml().  Defaults to
'tidyxml-errors.txt'

=item C<$tidysafety>

The safety level to use when running tidy (default is 1).  Potential
values are:

=over

=item C<$tidysafety < 1>:

No checks performed, no error files kept, works like a clean tidy -m

This setting is DANGEROUS!

=item C<$tidysafety == 1>:

Overwrites original file if there were no errors, but even if there
were warnings.  Keeps a log of errors, but not warnings.

=item C<$tidysafety == 2>:

Overwrites original file if there were no errors, but even if there
were warnings.  Keeps a log of both errors and warnings.

=item C<$tidysafety == 3>:

Overwrites original file only if there were no errors or warnings.
Keeps a log of both errors and warnings.

=item C<$tidysafety >= 4>:

Never overwrites original file.  Keeps a log of both errors and
warnings.

=back

=item C<%validspecs>

A hash mapping valid specification strings to themselves, primarily
used to undefine unrecognized values.  Default valid values are 'OEB12'
and 'OPF20'.

=back

=cut

our $mobi2htmlcmd = 'mobi2html';
our $tidycmd = 'tidy'; # Specify full pathname if not on path
our $tidyxhtmlerrors = 'tidyxhtml-errors.txt';
our $tidyxmlerrors = 'tidyxml-errors.txt';
our $tidysafety = 1;


our $utf8xmldec = '<?xml version="1.0" encoding="UTF-8" ?>' . "\n";
our $oeb12doctype =
    '<!DOCTYPE package' . "\n" .
    '  PUBLIC "+//ISBN 0-9673008-1-9//DTD OEB 1.2 Package//EN"' . "\n" .
    '  "http://openebook.org/dtds/oeb-1.2/oebpkg12.dtd">' . "\n";
our $opf20package =
    '<package version="2.0" xmlns="http://www.idpf.org/2007/opf">' . "\n";

my $bisg = EBook::Tools::BISG->new();
our %bisacsubjects = $bisg->bisac();

our %bisactolc = (
    # The entire ANTXXX line is ambiguous -- it could map to either
    # subdivisions of Antiques or Collectibles.  Work started here
    # before this was realized is being left intact for now, but the
    # list is incomplete for this reason.
    'ant000000'				=> 'Antiques',
    'ant001000'				=> 'Antiques--Americana',
    'ant002000'				=> 'Antiques--Art',
    'ant003000'				=> 'Autographs',
    'ant004000'				=> 'Antiques--Baskets',
    'ant005000'				=> 'Antiques--Books',
    'ant006000'				=> 'Antiques--Bottles',
    'ant010000'				=> 'Antiques--Clocks and watches',
    'ant012000'				=> 'Antiques--Cartoons',
    'ant015000'				=> 'Antiques--Dolls',
    'ant016000'				=> 'Antiques--Firearms',
    'ant017000'				=> 'Antiques--Furniture',
    'ant018000'				=> 'Antiques--Glassware',
    'ant021000'				=> 'Antiques--Jewelry',
    'ant022000'				=> 'Antiques--Kitchen utensils',
    'ant023000'				=> 'Antiques--Periodicals',
    'ant026000'				=> 'Antiques--Musical instruments',
    'ant031000'				=> 'Political collectibles',
    'ant052000'				=> 'Collectibles--Popular culture',
    'ant053000'				=> 'Antiques--Figurines',
    'arc000000'				=> 'Architecture',
    'arc005000'				=> 'Architecture--History',
    'arc007000'				=> 'Interior decoration',
    'art000000'				=> 'Art',
    'art002000'				=> 'Airbrush art',
    'art003000'				=> 'Calligraphy--Technique',
    'art004000'				=> 'Cartooning',
    'art006000'				=> 'Art collections',
    'art008000'				=> 'Conceptual art',
    'art009000'				=> 'Art criticism',
    'art010000'				=> 'Drawing',
    'art013000'				=> 'Folk art',
    'art015010'				=> 'Art, African',
    'art015020'				=> 'Art, American',
    'art015030'				=> 'Art, European',
    'art015040'				=> 'Art, Canadian',
    'art016000'				=> 'Artists',
    'art017000'				=> 'Mixed media (Art)',
    'art019000'				=> 'Art, Asian',
    'art020000'				=> 'Painting--Technique',
    'art021000'				=> 'Pastel drawing--Technique',
    'art023000'				=> 'Popular culture',
    'art024000'				=> 'Prints--Technique',
    'art026000'				=> 'Sculpture',
    'art027000'				=> 'Arts--Study and teaching',
    'art028000'				=> 'Art--Technique',
    'art029000'				=> 'Watercolor painting--Technique',
    'art033000'				=> 'Pen drawing--Technique',
    'art034000'				=> 'Pencil drawing--Technique',
    'art035000'				=> 'Religious art',
    'art037000'				=> 'Politics in art',
    'art038000'				=> 'African American art',
    'art039000'				=> 'Asian American art',
    'art040000'				=> 'Hispanic American art',
    'art042000'				=> 'Art, Australian',
    'art043000'				=> 'Art and business',
    'art044000'				=> 'Art, Latin American',
    'art045000'				=> 'Pottery',
    'art046000'				=> 'Digital art',
    'art047000'				=> 'Art--Middle East',
    'art049000'				=> 'Art, Russian',
    'art050000'				=> 'Art--Themes, motives',
    'art050010'				=> 'Human beings in art',
    'art050020'				=> 'Landscapes in art',
    # 'ART050030' could translate to either 'Animals in art' or 'Plants in art'
    'art050040'				=> 'Portraits',
    'art050050'				=> 'Erotic art',
    'art051000'				=> 'Color in art',
    'art052000'				=> 'Human figure in art',
    'art053000'				=> 'Sculpture--Technique',
    'art055000'				=> 'Body art',
    'art056000'				=> 'Art objects--Conservation and restoration',
    'art057000'				=> 'Video art',
    'art058000'				=> 'Street art',
    'art060000'				=> 'Performance art',
    'bib000000'				=> 'Bible',
    'bio000000'				=> 'Biography',
    'bio001000'				=> 'Artists--Biography',
    'bio008000'				=> 'Military biography',
    'bio009000'				=> 'Philosophers--Biography',
    'bio011000'				=> 'Heads of state--Biography',
    'bio022000'				=> 'Women--Biography',
    'bio023000'				=> 'Explorers--Biography',
    'bio024000'				=> 'Criminals--Biography',
    'bio030000'				=> 'Environmentalists--Biography',
    'bus000000'				=> 'Economics',
    'bus001000'				=> 'Accounting',
    'bus001030'				=> 'International business enterprises--Accounting',
    'bus001050'				=> 'Accounting--Standards',
    'bus002000'				=> 'Advertising',
    'bus003000'				=> 'Auditing',
    'bus004000'				=> 'Banks and banking',
    'bus005000'				=> 'Bookkeeping',
    'bus006000'				=> 'Budget',
    'bus007000'				=> 'Business communication',
    'bus007010'				=> 'Business meetings',
    'bus008000'				=> 'Business ethics',
    'bus009000'				=> 'Business etiquette',
    'bus010000'				=> 'Commercial law',
    'bus011000'				=> 'Business writing',
    'bus012000'				=> 'Occupations',
    'bus012010'				=> 'Internship programs',
    'bus013000'				=> 'Commercial policy',
    'bus014000'				=> 'Commodity exchanges',
    'bus015000'				=> 'Consolidation and merger of corporations',
    'bus016000'				=> 'Consumer behavior',
    'bus017000'				=> 'Corporations--Finance',
    'bus018000'				=> 'Customer relations',
    'bus019000'				=> 'Decision making',
    'bus020000'				=> 'Business--Development',
    'bus021000'				=> 'Econometrics',
    'bus022000'				=> 'Economic conditions',
    'bus023000'				=> 'Economic history',
    'bus024000'				=> 'Business education',
    'bus025000'				=> 'Entrepreneurship',
    'bus026000'				=> 'International trade',
    'bus027000'				=> 'Finance',
    'bus028000'				=> 'Foreign exchange',
    'bus029000'				=> 'Free enterprise',
    'bus030000'				=> 'Personnel management',
    'bus031000'				=> 'Inflation (Finance)',
    'bus032000'				=> 'Infrastructure (Economics)',
    'bus033000'				=> 'Insurance',
    'bus033010'				=> 'Automobile insurance',
    'bus033020'				=> 'Casualty insurance',
    'bus033040'				=> 'Health insurance',
    'bus033050'				=> 'Liability insurance',
    'bus033060'				=> 'Life insurance',
    'bus033070'				=> 'Risk (Insurance)',
    'bus033080'				=> 'Property insurance',
    'bus034000'				=> 'Interest',
    'bus035000'				=> 'International business enterprises',
    'bus036000'				=> 'Investments',
    'bus036010'				=> 'Bonds',
    'bus036020'				=> 'Futures',
    'bus036030'				=> 'Mutual funds',
    'bus036040'				=> 'Options (Finance)',
    'bus036050'				=> 'Real estate investment',
    'bus036060'				=> 'Stocks',
    'bus037000'				=> 'Job hunting',
    'bus037020'				=> 'Job hunting',
    'bus038000'				=> 'Labor',
    'bus039000'				=> 'Macroeconomics',
    'bus040000'				=> 'Mail-order business',
    'bus041000'				=> 'Management',
    'bus042000'				=> 'Management science',
    'bus043000'				=> 'Marketing',
    'bus043010'				=> 'Direct marketing',
    'bus043020'				=> 'Industrial marketing',
    'bus043030'				=> 'Export marketing',
    'bus043040'				=> 'Multilevel marketing',
    'bus043050'				=> 'Telemarketing',
    'bus043060'				=> 'Marketing research',
    'bus044000'				=> 'Microeconomics',
    'bus045000'				=> 'Monetary policy',
    'bus046000'				=> 'Achievement motivation',
    'bus047000'				=> 'Negotiation',
    'bus048000'				=> 'New business enterprises',
    'bus049000'				=> 'Operations research',
    'bus050000'				=> 'Finance, Personal',
    'bus050010'				=> 'Budgets, Personal',
    'bus050020'				=> 'Investments',
    'bus050040'				=> 'Retirement--Planning',
    'bus050050'				=> 'Income tax',
    'bus051000'				=> 'Finance, Public',
    'bus052000'				=> 'Public relations',
    'bus053000'				=> 'Quality control',
    'bus054000'				=> 'Real property',
    # 'bus054010' could be either House Buying or House Selling
    'bus054020'				=> 'Commercial real estate',
    'bus054030'				=> 'Mortgages',
    'bus055000'				=> 'Business--Reference books',
    'bus056030'				=> 'Résumés (Employment)',
    'bus057000'				=> 'Retail trade',
    # 'bus058000' could be either Sales or Selling
    'bus058010'				=> 'Sales management',
    'bus059000'				=> 'Business--Training',
    'bus060000'				=> 'Small business',
    # 'bus061000' could be either 'Commercial statistics' or 'Economic statistics'
    'bus062000'				=> 'Structural adjustment (Economic policy)',
    'bus063000'				=> 'Strategic planning',
    'bus064000'				=> 'Taxation',
    'bus064010'				=> 'Corporations--Taxation',
    'bus064020'				=> 'International business enterprises--Taxation',
    'bus064030'				=> 'Small business--Taxation',
    'bus065000'				=> 'Total quality management',
    'bus066000'				=> 'Business--Training',
    'bus067000'				=> 'Regional economics',
    'bus068000'				=> 'Economic development',
    'bus069000'				=> 'Economics',
    'bus069010'				=> 'Comparative economics',
    'bus069020'				=> 'Competition, International',
    'bus069030'				=> 'Economics',
    'bus070000'				=> 'Industries',
    'bus070010'				=> 'Agricultural industries',
    'bus070020'				=> 'Automobile industry and trade',
    'bus070030'				=> 'Computer industry',
    'bus070040'				=> 'Energy industries',
    'bus070050'				=> 'Manufacturing industries',
    'bus070060'				=> 'Communication and traffic',
    'bus070070'				=> 'Parks--Management',
    'bus070080'				=> 'Service industries',
    'bus070090'				=> 'Textile industry',
    'bus070100'				=> 'Transportation',
    'bus070110'				=> 'Entertainment industry',
    'bus070120'				=> 'Food industry and trade',
    'bus070130'				=> 'Biotechnology industries',
    'bus070140'				=> 'Financial services industry',
    'bus070150'				=> 'Natural resources',
    'bus071000'				=> 'Leadership',
    'bus072000'				=> 'Sustainable development',
    'bus073000'				=> 'Commerce',
    'bus074000'				=> 'Nonprofit organizations',
    # 'bus075000' is 'Consulting' which has no exact LC match
    'bus076000'				=> 'Purchasing',
    'bus077000'				=> 'Commerce--History',
    'bus078000'				=> 'Distribution (Economic theory)',
    'bus079000'				=> 'Industrial policy',
    'bus080000'				=> 'Home-based businesses',
    'bus081000'				=> 'Tourism',
    'bus082000'				=> 'Industrial management',
    'bus083000'				=> 'Information resources management',
    'bus084000'				=> 'Office practice--Automation',
    'bus085000'				=> 'Organizational behavior',
    'bus086000'				=> 'Business forecasting',
    'bus087000'				=> 'Production management',
    'bus088000'				=> 'Time management',
    'bus089000'				=> 'Secretaries--Training',
    'bus090000'				=> 'Electronic commerce',
    'bus090010'				=> 'Internet advertising',
    'bus090020'				=> 'Internet banking',
    'bus090030'				=> 'Electronic trading of securities',
    'bus090040'				=> 'Internet auctions',
    'bus091000'				=> 'Business mathematics',
    'bus092000'				=> 'Economic development',
    'bus093000'				=> 'Facility management',
    'bus094000'				=> 'Business enterprises--Environmental aspects',
    'bus095000'				=> 'Office equipment and supplies',
    'bus096000'				=> 'Office management',
    'bus097000'				=> 'Work environment',
    'bus098000'				=> 'Intellectual capital',
    'bus099000'				=> 'Environmental economics',
    'bus100000'				=> 'Museum techniques',
    'bus101000'				=> 'Project management',
    'bus102000'				=> 'Contracting out',
    'bus103000'				=> 'Organizational change',
    'bus104000'				=> 'Corporate governance',
    'bus105000'				=> 'Franchises (Retail trade)',
    'bus106000'				=> 'Executive coaching',
    'bus107000'				=> 'Success',
    'bus108000'				=> 'Research and development projects',
    'bus109000'				=> 'Businesswomen',
    'bus110000'				=> 'Conflict management',
    'cgn000000'				=> 'Comic books, strips, etc',
    'cgn004080'				=> 'Superheroes',
    'ckb000000'				=> 'Cooking',
    'ckb001000'				=> 'Cooking, African',
    'ckb002000'				=> 'Cooking, American',
    'ckb002010'				=> 'Cooking, American--California style',
    'ckb002020'				=> 'Cooking, American--Middle Atlantic States',
    'ckb002030'				=> 'Cooking, American--Midwestern style',
    'ckb002040'				=> 'Cooking, American--New England style',
    'ckb002050'				=> 'Cooking, American--Northwestern States',
    'ckb002060'				=> 'Cooking, American--Southern style',
    'ckb002070'				=> 'Cooking, American--Southwestern style',
    'ckb002080'				=> 'Cooking, American--Western style',
    'ckb003000'				=> 'Appetizers',
    'ckb004000'				=> 'Baking',
    'ckb005000'				=> 'Barbecuing',
    'ckb006000'				=> 'Bartending',
    'ckb007000'				=> 'Cooking (Beer)',
    'ckb008000'				=> 'Non-alcoholic beverages',
    'ckb009000'				=> 'Cooking (Bread)',
    'ckb010000'				=> 'Breakfasts',
    # 'ckb011000' could be 'Cooking, English', 'Cooking, Scottish', or 'Cooking, Welsh'
    'ckb012000'				=> 'Brunches',
    # 'ckb013000' could be either 'Cooking, Cajun' or 'Cooking, Creole'
    'ckb014000'				=> 'Cake',
    'ckb015000'				=> 'Canning and preserving',
    # 'ckb016000' could be either 'Cooking, Caribbean' or 'Cooking, West Indian'
    'ckb017000'				=> 'Cooking, Chinese',
    'ckb018000'				=> 'Cooking (Chocolate)',
    # 'ckb019000' could be either 'Cooking (Coffee)' or 'Cooking (Tea)'
    'ckb020000'				=> 'Cooking for one',
    'ckb021000'				=> 'Cookies',
    'ckb024000'				=> 'Desserts',
    'ckb026000'				=> 'Weight loss',
    'ckb029000'				=> 'Entertaining',
    'ckb033000'				=> 'Garnishes (Cooking)',
    'ckb034000'				=> 'Cooking, French',
    'ckb036000'				=> 'Cooking, German',
    'ckb038000'				=> 'Cooking, Greek',
    # 'ckb040000' could be 'Cooking (Herbs)', 'Cooking (Spices)', or 'Condiments'
    'ckb041000'				=> 'Cooking--History',
    'ckb042000'				=> 'Holiday cooking',
    'ckb050000'				=> 'Low-cholesterol diet',
    'ckb051000'				=> 'Low-fat diet',
    'ckb057000'				=> 'Microwave cooking',
    'ckb060000'				=> 'Outdoor cooking',
    'ckb062000'				=> 'Pastry',
    'ckb063000'				=> 'Pies',
    'ckb064000'				=> 'Pizza',
    'ckb069000'				=> 'Quantity cooking',
    'ckb070000'				=> 'Quick and easy cooking',
    'ckb073000'				=> 'Salads',
    # 'ckb079000' could map to either 'Soups' or 'Stews'
    'ckb088000'				=> 'Cooking (Liquors)',
    'ckb089000'				=> 'Wok cooking',
    'ckb090000'				=> 'Cooking, Asian',
    'ckb091000'				=> 'Cooking, Canadian',
    'ckb092000'				=> 'Cooking, European',
    'ckb095000'				=> 'Confectionery',
    'ckb099000'				=> 'Cooking, Latin American',
    'ckb100000'				=> 'Beverages',
    'ckb101000'				=> 'Entrées (Cooking)',
    'ckb102000'				=> 'Sauces',
    'ckb103000'				=> 'Cancer--Nutritional aspects',
    'ckb104000'				=> 'Heart--Diseases--Nutritional aspects',
    'ckb106000'				=> 'Food allergy',
    'ckb107000'				=> 'Baby foods',
    'ckb108000'				=> 'Low-carbohydrate diet',
    'ckb110000'				=> 'Raw foods',
    'ckb111000'				=> 'Gluten-free foods',
    'ckb112000'				=> 'Casserole cooking',
    'com000000'				=> 'Computers',
    'com001000'				=> 'Computer peripherals',
    'com003000'				=> 'Application software',
    'com004000'				=> 'Artificial intelligence',
    "com006000"				=> "Computers--Buyers' guides",
    'com007000'				=> 'CAD/CAM systems',
    'com008000'				=> 'Calculators',
    'com009000'				=> 'Optical disks',
    'com010000'				=> 'Compilers (Computer programs)',
    'com011000'				=> 'Computer architecture',
    'com012000'				=> 'Computer graphics',
    'com012040'				=> 'Computer games--Programming',
    'com012050'				=> 'Image processing',
    'com013000'				=> 'Computer literacy',
    'com014000'				=> 'Computer science',
    'com015000'				=> 'Malware (Computer software)',
    # 'com016000' could be either 'Computer vision' or 'Pattern recognition systems'
    'com018000'				=> 'Data processing',
    'com020000'				=> 'Data transmission systems',
    'com020010'				=> 'Electronic data interchange',
    'com020050'				=> 'Broadband communication systems',
    'com020060'				=> 'Modems',
    'com020090'				=> 'Wireless communication systems',
    'com021000'				=> 'Databases',
    'com021030'				=> 'Data mining',
    'com021040'				=> 'Data warehousing',
    'com023000'				=> 'Computer software--Education',
    'com024000'				=> 'Computer games',
    'com025000'				=> 'Expert systems (Computer science)',
    'com027000'				=> 'Finance, Personal--Software',
    'com031000'				=> 'Information theory',
    'com032000'				=> 'Information technology',
    'com034000'				=> 'Interactive computer systems',
    'com035000'				=> 'Keyboarding',
    'com036000'				=> 'Logic design',
    'com037000'				=> 'Machine theory',
    'com039000'				=> 'Management information systems',
    'com040000'				=> 'Memory management (Computer science)',
    'com041000'				=> 'Microprocessors',
    'com042000'				=> 'Computational linguistics',
    'com043000'				=> 'Computer networks',
    'com043020'				=> 'Local area networks (Computer networks)',
    'com043040'				=> 'Computer network protocols',
    'com043050'				=> 'Computer networks--Security measures',
    'com044000'				=> 'Neural networks (Computer science)',
    'com046000'				=> 'Operating systems (Computers)',
    'com046090'				=> 'Virtual computer systems',
    'com047000'				=> 'Optical data processing',
    'com048000'				=> 'Electronic data processing--Distributed processing',
    'com049000'				=> 'Computer peripherals',
    'com050000'				=> 'Microcomputers',
    'com050020'				=> 'Macintosh-compatible computers',
    'com051000'				=> 'Computer programming',
    'com051010'				=> 'Programming languages (Electronic computers)',
    'com051020'				=> 'Ada (Computer program language)',
    'com051030'				=> 'C (Computer program language)',
    'com051040'				=> 'Assembly languages (Electronic computers)',
    "com051050"				=> 'BASIC (Computer program language)',
    'com051060'				=> 'C (Computer program language)',
    'com051070'				=> 'C++ (Computer program language)',
    'com051080'				=> 'COBOL (Computer program language)',
    'com051090'				=> 'FORTRAN (Computer program language)',
    'com051100'				=> 'LISP (Computer program language)',
    'com051110'				=> 'C (Computer program language)',
    'com051120'				=> 'Modula-2 (Computer program language)',
    'com051130'				=> 'Pascal (Computer program language)',
    'com051140'				=> 'Prolog (Computer program language)',
    'com051150'				=> 'C (Computer program language)',
    'com051160'				=> 'Smalltalk (Computer program language)',
    'com051170'				=> 'SQL (Computer program language)',
    'com051180'				=> 'C (Computer program language)',
    'com051190'				=> 'Pascal (Computer program language)',
    'com051210'				=> 'Object-oriented programming (Computer science)',
    'com051220'				=> 'Parallel programming (Computer science)',
    # 'com051230' could be either 'Computer software--Development' or 'Software engineering'
    'com051240'				=> 'System analysis',
    'com051260'				=> 'JavaScript (Computer program language)',
    'com051270'				=> 'HTML (Document markup language)',
    'com051280'				=> 'Java (Computer program language)',
    'com051290'				=> 'RPG (Computer program language)',
    'com051300'				=> 'Computer programming--Algorithms',
    'com051310'				=> 'C# (Computer program language)',
    'com051320'				=> 'XML (Document markup language)',
    'com051330'				=> 'Computer software--Quality assurance',
    'com051340'				=> 'Computer network protocols',
    'com051350'				=> 'Perl (Computer program language)',
    'com051360'				=> 'Python (Computer program language)',
    'com051400'				=> 'PHP (Computer program language)',
    'com051410'				=> 'Ruby (Computer program language)',
    'com051420'				=> 'VBScript (Computer program language)',
    'com051430'				=> 'Software engineering--Project management',
    'com051450'				=> 'UML (Computer science)',
    'com052000'				=> 'Computers--Reference',
    'com053000'				=> 'Computer security',
    'com054000'				=> 'Electronic spreadsheets--Software',
    'com054010'				=> 'Electronic spreadsheets--Software',
    'com054020'				=> 'Electronic spreadsheets--Software',
    'com055000'				=> 'Computer technicians--Certification--Study guides',
    'com057000'				=> 'Virtual reality',
    'com058000'				=> 'Word processing--Software',
    'com058010'				=> 'Word processing--Software',
    'com058020'				=> 'Word processing--Software',
    'com059000'				=> 'Computer engineering',
    'com060000'				=> 'Internet',
    # 'com060030' could be either 'Extranets (Computer networks)' or
    # 'Intranets (Computer networks)'
    'com060010'				=> 'Browsers (Computer programs)',
    'com060040'				=> 'Internet--Safety measures',
    'com060070'				=> 'Web sites--Directories',
    'com060080'				=> 'World Wide Web',
    'com060090'				=> 'Application software--Internet--Development',
    'com060100'				=> 'Blogs',
    'com060110'				=> 'Webcasting',
    'com060120'				=> 'Web search engines',
    'com060130'				=> 'Web sites--Design',
    'com060140'				=> 'Online social networks',
    'com060150'				=> 'User-generated content',
    'com060160'				=> 'Web site development',
    'com060180'				=> 'Web services',
    'com063000'				=> 'Document imaging systems',
    'com064000'				=> 'Electronic commerce',
    'com065000'				=> 'Electronic publishing',
    'com067000'				=> 'Computers',
    'com069000'				=> 'Online information services',
    'com069010'				=> 'Online information services',
    'com070000'				=> 'User interfaces (Computer systems)',
    'com071000'				=> 'Computer animation',
    'com072000'				=> 'Computer simulation',
    'com073000'				=> 'Speech processing systems',
    'com074000'				=> 'Mobile computing',
    'com076000'				=> 'Computers',
    'com077000'				=> 'Computer software--Mathematics',
    'com078000'				=> 'Presentation graphics software',
    'com079000'				=> 'Computers--Social aspects',
    'com079010'				=> 'Human-computer interaction',
    'com080000'				=> 'Computers--History',
    'com081000'				=> 'Project management--Software',
    'com082000'				=> 'Bioinformatics',
    'com083000'				=> 'Cryptography',
    'com084000'				=> 'Application software',
    'com084010'				=> 'Databases',
    'com084020'				=> 'Electronic mail systems',
    'com085000'				=> 'Technical writing',
    'com087000'				=> 'Digital media',
    'com088000'				=> 'Computers--Administration',
    'com090000'				=> 'Tablet computers',
    'computers/programming languages/javascript' => 'JavaScript (Computer program language)',
    'computers/programming languages'	=> 'Programming languages (Electronic computers)',
    'computers/reference'		=> 'Computers--Reference',
    'juv000000'				=> 'Fiction, Juvenile',
    'fic000000'				=> 'Fiction',
    'fic009000'				=> 'Fantasy fiction',
    'fic014000'				=> 'Historical fiction',
    'fic027000'				=> 'Love stories',
    'occ000000'				=> 'Superstition',
    'occ003000'				=> 'Channeling (Spiritualism)',
    'occ004000'				=> 'Crystals',
    'occ005000'				=> 'Divination',
    'occ006000'				=> 'Dreams',
    'occ007000'				=> 'Extrasensory perception',
    'occ008000'				=> 'Fortune-telling',
    'occ009000'				=> 'Horoscopes',
    'occ010000'				=> 'Meditation',
    'occ011000'				=> 'Mental healing',
    'occ011010'				=> 'Energy medicine',
    'occ011020'				=> 'Spiritual healing',
    'occ014000'				=> 'New Thought',
    'occ015000'				=> 'Numerology',
    'occ016000'				=> 'Occultism',
    'occ017000'				=> 'Palmistry',
    'occ018000'				=> 'Parapsychology',
    'occ019000'				=> 'Inspiration--Religious aspects',
    'occ020000'				=> 'Prophecy',
    'occ022000'				=> 'Immortality',
    'occ023000'				=> 'Supernatural',
    'occ024000'				=> 'Tarot',
    'occ025000'				=> 'Unidentified flying objects',
    'occ026000'				=> 'Witchcraft',
    'occ027000'				=> 'Spiritualism',
    'occ028000'				=> 'Magic',
    'occ031000'				=> 'Controversial literature',
    'occ032000'				=> 'Guides (Spiritualism)',
    'occ034000'				=> 'Near-death experiences',
    'occ035000'				=> 'Astral projection',
    'occ036000'				=> 'Spirituality',
    'occ036030'				=> 'Shamanism',
    'occ036050'				=> 'Goddess religion',
    'occ037000'				=> 'Feng shui',
    'occ039000'				=> 'Hallucinogenic drugs',
    'occ040000'				=> 'Hermetism',
    'occ041000'				=> 'Sex--Religious aspects',
   );

our %booktypes = (
    # Fiction types, by length (definitions are not standardized)
    'micro fiction'	=> 'Micro Fiction',	# Below 100 words
    'micro-fiction'	=> 'Micro Fiction',
    'drabble'		=> 'Drabble',		# 100 words, exactly
    'flash fiction'	=> 'Flash Fiction',	# Below 1000 words
    'short short'	=> 'Flash Fiction',
    'short short story'	=> 'Flash Fiction',
    'short story'	=> 'Short Story',	# Generally 1k-10k words
    'short'		=> 'Short Story',
    'novelette'		=> 'Novelette',		# Generally 7.5k-15k words
    'novella'		=> 'Novella',		# Generally 12k-40k words
    'novel'		=> 'Novel',		# Over 50k words
    'anthology'		=> 'Anthology',		# Multiple novellas or shorter
    'omnibus'		=> 'Omnibus',		# Multiple novels
    'complete works'	=> 'Complete Works',	# Complete collection of all works by an author
    'opera omnia'	=> 'Complete Works',
    # Age categories
    'picture book'	=> 'Picture Book',	# For pre-readers or children ages 0-5
    'early reader'	=> 'Early Reader',	# For ages 5-7
    'chapter book'	=> 'Chapter Book',	# For ages 7-12
    'young-adult novel'	=> 'Young-Adult Novel',	# Subcategory of Novel aimed at ages 12-18
    'ya novel'		=> 'Young-Adult Novel',
    # Non-fiction types
    'academic paper'	=> 'Academic Paper',	# Creditable, peer-reviewed sources
    'almanac'		=> 'Almanac',
    'autobiography'	=> 'Autobiography',
    'biography'		=> 'Biography',
    'book report'	=> 'Book Report',
    'creative nonfiction' => 'Creative Nonfiction', # Flexible imaginings of actual events
    'design document'	=> 'Design Document',
    'diary'		=> 'Diary',
    'dictionary',	=> 'Dictionary',
    'encyclopædia'	=> 'Encyclopedia',
    'encyclopaedia'	=> 'Encyclopedia',
    'encyclopedia'	=> 'Encyclopedia',
    'essay'		=> 'Essay',
    'essay collection'	=> 'Essay Collection',
    'journal'		=> 'Journal',		# Collection of papers, academic or technical, with or without review
    'journalism'	=> 'Journalism',
    'letter'		=> 'Letters',		# Correspondence, singular or collective
    'letters'		=> 'Letters',
    'memoir'		=> 'Memoir',
    'popular science'	=> 'Popular Science',	# Interpretation of science for a general audience
    'reference'		=> 'Reference',		# Includes blueprints, guides, manuals, diagrams,
						# but see also 'Technical Writing' below
    'technical writing'	=> 'Technical Writing',	# Includes 'how-to' books even on nontechnical topics
    'technical'		=> 'Technical Writing',
    'thesaurus'		=> 'Thesaurus',
    'travelogue'	=> 'Travelogue',
    # Other types
    'art'		=> 'Art',		# Collection of artistic images
    'comic book'	=> 'Comic Book',
    'graphic novel'	=> 'Graphic Novel',
    'photography'	=> 'Photography',
    'poetry'		=> 'Poetry',		# One or more structured poems
    'prose poetry'	=> 'Prose',		# One or more unstructured prose works
    'prose'		=> 'Prose',
);

our %dcelements12;
tie %dcelements12, 'Tie::IxHash', (
    "dc:identifier"  => "dc:Identifier",
    "dc:title"       => "dc:Title",
    "dc:creator"     => "dc:Creator",
    "dc:contributor" => "dc:Contributor",
    "dc:subject"     => "dc:Subject",
    "dc:description" => "dc:Description",
    "dc:publisher"   => "dc:Publisher",
    "dc:date"        => "dc:Date",
    "dc:type"        => "dc:Type",
    "dc:format"      => "dc:Format",
    "dc:source"      => "dc:Source",
    "dc:language"    => "dc:Language",
    "dc:relation"    => "dc:Relation",
    "dc:coverage"    => "dc:Coverage",
    "dc:rights"      => "dc:Rights",
    "dc:copyrights"  => "dc:Rights"
    );

our %dcelements20;
tie %dcelements20, 'Tie::IxHash', (
    "dc:identifier"  => "dc:identifier",
    "dc:title"       => "dc:title",
    "dc:creator"     => "dc:creator",
    "dc:contributor" => "dc:contributor",
    "dc:subject"     => "dc:subject",
    "dc:description" => "dc:description",
    "dc:publisher"   => "dc:publisher",
    "dc:date"        => "dc:date",
    "dc:type"        => "dc:type",
    "dc:format"      => "dc:format",
    "dc:source"      => "dc:source",
    "dc:language"    => "dc:language",
    "dc:relation"    => "dc:relation",
    "dc:coverage"    => "dc:coverage",
    "dc:rights"      => "dc:rights",
    "dc:copyrights"  => "dc:rights"
    );

our %lcsubjects = (
    'abolition of capital punishment'	=> 'Capital punishment',
    'abolition of slavery'		=> 'Slavery',
    'abolition'				=> 'Slavery',
    'absent treatment'			=> 'Mental healing',
    'abstract automata'			=> 'Machine theory',
    'abstract machines'			=> 'Machine theory',
    'absurd (philosophy)'		=> 'Absurd (Philosophy)',
    'absurdist (philosophy)'		=> 'Absurd (Philosophy)',
    'absurdist'				=> 'Absurd (Philosophy)',
    'abuse of children'			=> 'Child abuse',
    'accountancy'			=> 'Accounting',
    'accounting'			=> 'Accounting',
    'accounting standards'		=> 'Accounting--Standards',
    'accounting--standards'		=> 'Accounting--Standards',
    'achievement motivation'		=> 'Achievement motivation',
    'aching, tiffany (fictitious character)' => 'Aching, Tiffany (Fictitious character)',
    'aching, tiffany'			=> 'Aching, Tiffany (Fictitious character)',
    'acquisition of corporations'	=> 'Consolidation and merger of corporations',
    'acquisitions and mergers'		=> 'Consolidation and merger of corporations',
    'action research'			=> 'Action research',
    'acts of terrorism'			=> 'Terrorism',
    'ada (computer program language)'	=> 'Ada (Computer program language)',
    'ada'				=> 'Ada (Computer program language)',
    'adding machines'			=> 'Calculators',
    'adding-machines'			=> 'Calculators',
    'adiposity'				=> 'Obesity',
    'administration'			=> 'Management',
    'administrative communication'	=> 'Business communication',
    'ads'				=> 'Advertising',
    'adventure'				=> 'Adventure stories',
    'adventure stories'			=> 'Adventure stories',
    'advertisements'			=> 'Advertising',
    'advertising'			=> 'Advertising',
    'african art'			=> 'Art, African',
    'african american art'		=> 'African American art',
    'african cooking'			=> 'Cooking, African',
    'afro-american art'			=> 'African American art',
    'afterlife'				=> 'Immortality',
    'agents, search'			=> 'Search engines',
    'agoraphobia'			=> 'Agoraphobia',
    'agribusiness'			=> 'Agricultural industries',
    'agricultural industries'		=> 'Agricultural industries',
    'aias (greek mythology)'		=> 'Ajax (Greek mythology)',
    'ajax (greek mythology)'		=> 'Ajax (Greek mythology)',
    'ajax (legendary character)'	=> 'Ajax (Greek mythology)',
    'ajax (web site development technology)' => 'Ajax (Web site development technology)',
    'ajax the greater (greek mythology)' => 'Ajax (Greek mythology)',
    'ajax the greater'			=> 'Ajax (Greek mythology)',
    'algorism'				=> 'Algorithms',
    'algorithmic knowledge discovery'	=> 'Data mining',
    'algorithms'			=> 'Algorithms',
    'allocation of time'		=> 'Time management',
    'amalgamation of corporations'	=> 'Consolidation and merger of corporations',
    'american cooking'			=> 'Cooking, American',
    'americana'				=> 'Americana',
    'androids'				=> 'Androids',
    'animation, computer'		=> 'Computer animation',
    'angelology'			=> 'Angels',
    'angels'				=> 'Angels',
    'angleterre'			=> 'England',
    'anglii͡a'				=> 'England',
    'animals in art'			=> 'Animals in art',
    'antique and classic cars'		=> 'Antique and classic cars',
    'antique cars'			=> 'Antique and classic cars',
    'antiques'				=> 'Antiques',
    'antiques--americana'		=> 'Antiques--Americana',
    'antiques--art'			=> 'Antiques--Art',
    'antiques--baskets'			=> 'Antiques--Baskets',
    'antiques--books'			=> 'Antiques--Books',
    'antiques--bottles'			=> 'Antiques--Bottles',
    'antiques--buttons'			=> 'Antiques--Buttons',
    'antiques--cartoons'		=> 'Antiques--Cartoons',
    'antiques--clocks and watches'	=> 'Antiques--Clocks and watches',
    'antiques--coins'			=> 'Antiques--Coins',
    'antiques--dolls'			=> 'Antiques--Dolls',
    'antiques--figurines'		=> 'Antiques--Figurines',
    'antiques--firearms'		=> 'Antiques--Firearms',
    'antiques--furniture'		=> 'Antiques--Furniture',
    'antiques--glassware'		=> 'Antiques--Glassware',
    'antiques--jewelry'			=> 'Antiques--Jewelry',
    'antiques--kitchen utensils'	=> 'Antiques--Kitchen utensils',
    'antiques--musical instruments'	=> 'Antiques--Musical instruments',
    'antiques--periodicals'		=> 'Antiques--Periodicals',
    'antislavery'			=> 'Slavery',
    'appearance bias'			=> 'Physical-appearance-based bias',
    'appearance discrimination'		=> 'Physical-appearance-based bias',
    'appearance-based bias'		=> 'Physical-appearance-based bias',
    'appearance-based discrimination'	=> 'Physical-appearance-based bias',
    'ai'				=> 'Artificial intelligence',
    'airbrush art'			=> 'Airbrush art',
    'airbrush art--technique'		=> 'Airbrush art',
    'ais'				=> 'Artificial intelligence',
    'alimentation',			=> 'Nutrition',
    'alsatian cooking'			=> 'Cooking, French--Alsatian style',
    'alternate histories'		=> 'Alternative histories (Fiction)',
    'alternate histories (fiction)'	=> 'Alternative histories (Fiction)',
    'alternate history'			=> 'Alternative histories (Fiction)',
    'alternative histories'		=> 'Alternative histories (Fiction)',
    'alternative histories (fiction)'	=> 'Alternative histories (Fiction)',
    'alternative history'		=> 'Alternative histories (Fiction)',
    'american art'			=> 'Art, American',
    'american science fiction and fantasy' => 'Speculative fiction',
    'appetizers'			=> 'Appetizers',
    'application computer programs'	=> 'Application software',
    'application computer software'	=> 'Application software',
    'application software'		=> 'Application software',
    'application software--development'	=> 'Application software--Development',
    'application software--internet'	=> 'Application software--Internet',
    'application software--internet--development' => 'Application software--Internet--Development',
    'applications software'		=> 'Application software',
    'apps (computer software)'		=> 'Application software',
    'apps'				=> 'Application software',
    'ararat, mount (turkey)'		=> 'Ararat, Mount (Turkey)',
    'architecture'			=> 'Architecture',
    'architecture, computer'		=> 'Computer architecture',
    'architecture--history'		=> 'Architecture--History',
    'arithmetic'			=> 'Mathematics',
    'art'				=> 'Art',
    'art and business'			=> 'Art and business',
    'art collections'			=> 'Art collections',
    'art criticism'			=> 'Art criticism',
    'art objects'			=> 'Art objects',
    'art objects--conservation and restoration'
      => 'Art objects--Conservation and restoration',
    'art technique'			=> 'Art--Technique',
    'art, african'			=> 'Art, African',
    'art, african american'		=> 'African American art',
    'art, american'			=> 'Art, American',
    'art, asian'			=> 'Art, Asian',
    'art, asian american'		=> 'Asian American art',
    'art, asiatic'			=> 'Art, Asian',
    'art, australian'			=> 'Art, Australian',
    'art, canadian'			=> 'Art, Canadian',
    'art, caribbean'			=> 'Art, Caribbean',
    'art, conceptual'			=> 'Conceptual art',
    'art, digital'			=> 'Digital art',
    'art, erotic'			=> 'Erotic art',
    'art, european'			=> 'Art, European',
    'art, folk'				=> 'Folk art',
    'art, hispanic american'		=> 'Hispanic American art',
    'art, latin american'		=> 'Art, Latin American',
    'art, middle east'			=> 'Art--Middle East',
    'art, middle eastern'		=> 'Art--Middle East',
    'art, modern'			=> 'Art, Modern',
    'art, modern--europe'		=> 'Art, Modern--Europe',
    'art, oriental'			=> 'Art, Asian',
    'art, performance'			=> 'Performance art',
    'art, russian'			=> 'Art, Russian',
    'art, spanish american'		=> 'Art, Latin American',
    'art, street'			=> 'Street art',
    'art, video'			=> 'Video art',
    'art, wall'				=> 'Street art',
    'art--criticism'			=> 'Art criticism',
    'art--middle east'			=> 'Art--Middle East',
    'art--subjects'			=> 'Art--Themes, motives',
    'art--technique'			=> 'Art--Technique',
    'art--themes, motives'		=> 'Art--Themes, motives',
    'artificial intelligence'		=> 'Artificial intelligence',
    'artificial neural networks'	=> 'Neural networks (Computer science)',
    'artificial thinking'		=> 'Artificial intelligence',
    'artistic technique'		=> 'Art--Technique',
    'artists'				=> 'Artists',
    'artists--biography'		=> 'Artists--Biography',
    'arts--criticism'			=> 'Art criticism',
    'arts--study and teaching'		=> 'Arts--Study and teaching',
    'asian american art'		=> 'Asian American art',
    'asian cookery'			=> 'Cooking, Asian',
    'asian cooking'			=> 'Cooking, Asian',
    'asiatic art'			=> 'Art, Asian',
    'assembler language (computer program language)'	=> 'Assembly languages (Electronic computers)',
    'assembler language (electronic computers)'	=> 'Assembly languages (Electronic computers)',
    'assembler language'		=> 'Assembly languages (Electronic computers)',
    'assembler languages (electronic computers)' => 'Assembly languages (Electronic computers)',
    'assembler languages'		=> 'Assembly languages (Electronic computers)',
    'assembly language (electronic computers)'	=> 'Assembly languages (Electronic computers)',
    'assembly language'			=> 'Assembly languages (Electronic computers)',
    'assembly languages (electronic computers)'	=> 'Assembly languages (Electronic computers)',
    'assembly languages'		=> 'Assembly languages (Electronic computers)',
    'assurance (insurance)'		=> 'Insurance',
    'astral projection'			=> 'Astral projection',
    'astral travel'			=> 'Astral projection',
    'astrology'				=> 'Astrology',
    'astrology, chinese'		=> 'Astrology, Chinese',
    'asynchronous javascript and xml'	=> 'Ajax (Web site development technology)',
    'athletic competitions'		=> 'Sports',
    'athletics'				=> 'Sports',
    'attacks, terrorist'		=> 'Terrorism',
    'auditing'				=> 'Auditing',
    'audits'				=> 'Auditing',
    'augury'				=> 'Divination',
    'austen, jane, 1775-1817'		=> 'Austen, Jane, 1775-1817',
    'austen, jane'			=> 'Austen, Jane, 1775-1817',
    'australian art'			=> 'Art, Australian',
    'authoring (authorship)'		=> 'Authorship',
    'authoring'				=> 'Authorship',
    'authorship'			=> 'Authorship',
    'autobiography'			=> 'Biography',
    'autographs'			=> 'Autographs',
    'automatic computers'		=> 'Computers',
    'automatic data processing equipment' => 'Computers',
    'automatic data processors'		=> 'Computers',
    'automatic drafting'		=> 'Computer graphics',
    'automatic language processing'	=> 'Computational linguistics',
    'automobile industry'		=> 'Automobile industry and trade',
    'automobile industry and trade'	=> 'Automobile industry and trade',
    'automobile collision insurance'	=> 'Automobile insurance',
    'automobile insurance'		=> 'Automobile insurance',
    'automobile liability insurance'	=> 'Automobile insurance',
    'automobiles'			=> 'Automobiles',
    'automotive industry'		=> 'Automobile industry and trade',
    'auvergnat cooking'			=> 'Cooking, French--Auvergne style',
    'auvergne cooking'			=> 'Cooking, French--Auvergne style',
    'b-to-b marketing'			=> 'Industrial marketing',
    'b2b marketing'			=> 'Industrial marketing',
    'babies'				=> 'Infants',
    'baby foods'			=> 'Baby foods',
    'bagdad (iraq)'			=> 'Baghdad (Iraq)',
    'bagdad'				=> 'Baghdad (Iraq)',
    'bagddad (iraq)'			=> 'Baghdad (Iraq)',
    'bagddad'				=> 'Baghdad (Iraq)',
    'baghdad (iraq)'			=> 'Baghdad (Iraq)',
    'baghdad'				=> 'Baghdad (Iraq)',
    'baking bread'			=> 'Cooking (Bread)',
    'baking'				=> 'Baking',
    'bank robberies'			=> 'Bank robberies',
    'banking industry'			=> 'Banks and banking',
    'banking'				=> 'Banks and banking',
    'banks and banking'			=> 'Banks and banking',
    'barbecue cookery'			=> 'Barbecuing',
    'barbecue cooking'			=> 'Barbecuing',
    'barbecuing'			=> 'Barbecuing',
    'barbeque cookery'			=> 'Barbecuing',
    'barbeque cooking'			=> 'Barbecuing',
    'barbequing'			=> 'Barbecuing',
    'bargaining'			=> 'Negotiation',
    'bartending'			=> 'Bartending',
    'basic (computer program language)'	=> 'BASIC (Computer program language)',
    'basic rights'			=> 'Civil rights',
    'baskets'				=> 'Baskets',
    'bavarian cooking'			=> 'Cooking, German--Bavarian style',
    'bbq cooking'			=> 'Barbecuing',
    'beaurocracy'			=> 'Bureaucracy',
    'bedouin'				=> 'Bedouins',
    'bedouins'				=> 'Bedouins',
    'beduin'				=> 'Bedouins',
    'beduins'				=> 'Bedouins',
    'beer'				=> 'Beer',
    'beer--use in cooking'		=> 'Cooking (Beer)',
    "beginner's all-purpose symbolic instruction code"	=> 'BASIC (Computer program language)',
    'behavior in organizations'		=> 'Organizational behavior',
    'beverages'				=> 'Beverages',
    'beverages, non-alcoholic'		=> 'Non-alcoholic beverages',
    'bi-sexuality'			=> 'Bisexuality',
    'bible'				=> 'Bible',
    'big guns'				=> 'Ordnance',
    'bio-informatics'			=> 'Bioinformatics',
    'bio-terrorism'			=> 'Bioterrorism',
    'biography'				=> 'Biography',
    'bioinformatics'			=> 'Bioinformatics',
    'biological informatics'		=> 'Bioinformatics',
    'biological neural networks'	=> 'Neural networks (Neurobiology)',
    'bionics'				=> 'Bionics',
    'biotechnology industries'		=> 'Biotechnology industries',
    'biotechnology'			=> 'Biotechnology',
    'bioterrorism'			=> 'Bioterrorism',
    'bioterrorism--social aspects'	=> 'Bioterrorism--Social aspects',
    'biscuits, english'			=> 'Cookies',
    'bisexuality'			=> 'Bisexuality',
    'blogging'				=> 'Blogs',
    'blogs'				=> 'Blogs',
    'boats'				=> 'Boats',
    'body art'				=> 'Body art',
    'body building'			=> 'Bodybuilding',
    'body care'				=> 'Hygiene',
    'body sculpting'			=> 'Bodybuilding',
    'body sculpting (bodybuilding)'	=> 'Bodybuilding',
    'bodybuilding'			=> 'Bodybuilding',
    'bodysculpting'			=> 'Bodybuilding',
    'bodysculpting (bodybuilding)'	=> 'Bodybuilding',
    'bond issues'			=> 'Bonds',
    'bonds'				=> 'Bonds',
    'bookkeeping'			=> 'Bookkeeping',
    'books'				=> 'Books',
    'books--appraisal'			=> 'Criticism',
    'bottles'				=> 'Bottles',
    'bread'				=> 'Bread',
    'bread--use in cooking'		=> 'Cooking (Bread)',
    'breads'				=> 'Bread',
    'breakfasts'			=> 'Breakfasts',
    'breton cooking'			=> 'Cooking, French--Brittany style',
    'bric-a-brac'			=> 'Art objects',
    'brittany cooking'			=> 'Cooking, French--Brittany style',
    'broadband communication systems'	=> 'Broadband communication systems',
    'browsers (computer programs)'	=> 'Browsers (Computer programs)',
    'brunches'				=> 'Brunches',
    'budget'				=> 'Budget',
    'budgeting'				=> 'Budget',
    'budgets, family'			=> 'Budgets, Personal',
    'budgets, personal'			=> 'Budgets, Personal',
    'budgets, time'			=> 'Time management',
    'bureaucracy'			=> 'Bureaucracy',
    'burgundy cooking'			=> 'Cooking, French--Burgundy style',
    'business'				=> 'Commerce',
    'business administration'		=> 'Industrial management',
    'business and art'			=> 'Art and business',
    'business coaching'			=> 'Executive coaching',
    'business combinations'		=> 'Consolidation and merger of corporations',
    'business communication'		=> 'Business communication',
    'business data interchange, electronic' => 'Electronic data interchange',
    'business development'		=> 'Business--Development',
    'business education'		=> 'Business education',
    'business enterprises'		=> 'Business enterprises',
    'business enterprises, home'	=> 'Home-based businesses',
    'business enterprises, international' => 'International business enterprises',
    'business enterprises--environmental aspects' =>
      'Business enterprises--Environmental aspects',
    'business enterprises--management'	=> 'Industrial management',
    'business espionage'		=> 'Business intelligence',
    'business ethics'			=> 'Business ethics',
    'business etiquette'		=> 'Business etiquette',
    'business finance'			=> 'Corporations--Finance',
    'business forecasting'		=> 'Business forecasting',
    'business forecasts'		=> 'Business forecasting',
    'business graphics software'	=> 'Presentation graphics software',
    'business history'			=> 'Commerce--History',
    'business intelligence'		=> 'Business intelligence',
    'business law'			=> 'Commercial law',
    'business machines'			=> 'Office equipment and supplies',
    'business management'		=> 'Industrial management',
    'business math'			=> 'Business mathematics',
    'business mathematics'		=> 'Business mathematics',
    'business meetings'			=> 'Business meetings',
    'business mergers'			=> 'Consolidation and merger of corporations',
    'business organizations'		=> 'Business enterprises',
    'business presentation software'	=> 'Presentation graphics software',
    'business starts'			=> 'New business enterprises',
    'business statistics'		=> 'Commercial statistics',
    'business to business marketing'	=> 'Industrial marketing',
    'business training'			=> 'Business--Training',
    'business writing'			=> 'Business writing',
    'business--development'		=> 'Business--Development',
    'business--forecasting'		=> 'Business forecasting',
    'business--government policy'	=> 'Industrial policy',
    'business--public relations'	=> 'Public relations',
    'business--reference books'		=> 'Business--Reference books',
    'business--statistical methods'	=> 'Commercial statistics',
    'business--statistics'		=> 'Commercial statistics',
    'business--study and teaching'	=> 'Business education',
    'business--training'		=> 'Business--Training',
    'business-to-business marketing'	=> 'Industrial marketing',
    'businesses'			=> 'Business enterprises',
    'businesses, home'			=> 'Home-based businesses',
    'businesses, small'			=> 'Small business',
    'businesswomen'			=> 'Businesswomen',
    'buttons'				=> 'Buttons',
    'buyer behavior'			=> 'Consumer behavior',
    "buyers' guides"			=> "Buyers' guides",
    'buying'				=> 'Purchasing',
    'buyouts, corporate'		=> 'Consolidation and merger of corporations',
    'c (computer program language)'	=> 'C (Computer program language)',
    'c plus plus'			=> 'C++ (Computer program language)',
    'c# (computer program language)'	=> 'C# (Computer program language)',
    'c++ (computer program language)'	=> 'C++ (Computer program language)',
    'c++'				=> 'C++ (Computer program language)',
    'c-sharp (computer program language)' => 'C# (Computer program language)',
    'cad'				=> 'Computer-aided design',
    'cad/cam systems'			=> 'CAD/CAM systems',
    'cajan cooking'			=> 'Cooking, Cajun',
    'cajun cooking'			=> 'Cooking, Cajun',
    'cake'				=> 'Cake',
    'cakes'				=> 'Cake',
    'calculating machines'		=> 'Calculators',
    'calculating-machines'		=> 'Calculators',
    'calculators'			=> 'Calculators',
    'california cooking'		=> 'Cooking, American--California style',
    'call options'			=> 'Options (Finance)',
    'calligraphy'			=> 'Calligraphy',
    'calligraphy--technique'		=> 'Calligraphy--Technique',
    'calls (finance)'			=> 'Options (Finance)',
    'caloric content of food'		=> 'Food--Caloric content',
    'caloric content of foods'		=> 'Food--Caloric content',
    'calories (food)'			=> 'Food--Caloric content',
    'cambistry'				=> 'Foreign exchange',
    'camellia sinensis'			=> 'Tea',
    'camellia thea'			=> 'Tea',
    'camellia theifera'			=> 'Tea',
    'cameralistics'			=> 'Finance, Public',
    'camp cooking'			=> 'Outdoor cooking',
    'campfire cooking'			=> 'Outdoor cooking',
    'canadian art'			=> 'Art, Canadian',
    'canadian cooking'			=> 'Cooking, Canadian',
    'canapes'				=> 'Appetizers',
    'canapés'				=> 'Appetizers',
    'cancer'				=> 'Cancer',
    'cancer--nutritional aspects'	=> 'Cancer--Nutritional aspects',
    'cancers'				=> 'Cancer',
    'canning and preserving'		=> 'Canning and preserving',
    'cannon'				=> 'Ordnance',
    'cannons'				=> 'Ordnance',
    'capital equipment'			=> 'Industrial equipment',
    'capital goods'			=> 'Industrial equipment',
    'capital punishment'		=> 'Capital punishment',
    'capital punishment, abolition of'	=> 'Capital punishment',
    'capital, intellectual'		=> 'Intellectual capital',
    'capital, knowledge'		=> 'Intellectual capital',
    'carcinoma'				=> 'Cancer',
    'careers'				=> 'Occupations',
    'caribbean art'			=> 'Art, Caribbean',
    'caribbean cooking'			=> 'Cooking, Caribbean',
    'caricatures and cartoons'		=> 'Caricatures and cartoons',
    'cars (automobiles)'		=> 'Automobiles',
    'cars'				=> 'Automobiles',
    'cars, antique'			=> 'Antique and classic cars',
    'cars, classic'			=> 'Antique and classic cars',
    'cars, vintage'			=> 'Antique and classic cars',
    'cartooning'			=> 'Cartooning',
    'cartooning--technique'		=> 'Cartooning',
    'cartoons'				=> 'Caricatures and cartoons',
    'carvings'				=> 'Sculpture',
    'case studies'			=> 'Case studies',
    'casserole cookery'			=> 'Casserole cooking',
    'casserole cooking'			=> 'Casserole cooking',
    'casualty insurance'		=> 'Casualty insurance',
    'cats'				=> 'Cats',
    'cds'	       			=> 'Compact discs',
    'ceramic art'			=> 'Pottery',
    'ceramics (art)'			=> 'Pottery',
    'ceramics'				=> 'Pottery',
    'certification'			=> 'Certification',
    'change, organizational'		=> 'Organizational change',
    'channeling (spiritualism)'		=> 'Channeling (Spiritualism)',
    'channelling (spiritualism)'	=> 'Channeling (Spiritualism)',
    'cheirognomy'			=> 'Palmistry',
    'cheiromancy'			=> 'Palmistry',
    'cheirosophy'			=> 'Palmistry',
    'cherubim'				=> 'Angels',
    'cherubs (spirits)'			=> 'Angels',
    'cherubs'				=> 'Angels',
    'child abuse'			=> 'Child abuse',
    'child maltreatment'		=> 'Child abuse',
    'child molestation'			=> 'Child sexual abuse',
    'child molesting'			=> 'Child sexual abuse',
    'child neglect'			=> 'Child abuse',
    'child sexual abuse'		=> 'Child sexual abuse',
    'children'				=> 'Children',
    'children--abuse of'		=> 'Child abuse',
    'chinaware'				=> 'Pottery',
    'chinese astrology'			=> 'Astrology, Chinese',
    'chinese cooking'			=> 'Cooking, Chinese',
    'chinese historical fiction'	=> 'Historical fiction, Chinese',
    'chirognomy'			=> 'Palmistry',
    'chiromancy'			=> 'Palmistry',
    'chirosophy'			=> 'Palmistry',
    'chocolate'				=> 'Chocolate',
    'chocolate--use in cooking'		=> 'Cooking (Chocolate)',
    # 'chowders' could map to either 'Soups' or 'Stews'
    'christianity'			=> 'Christianity',
    'cipher stories'			=> 'Code and cipher stories',
    'ciphers'				=> 'Ciphers',
    'ciphers--fiction'			=> 'Code and cipher stories',
    'ciphers--juvenile fiction'		=> 'Code and cipher stories',
    'cities and towns'			=> 'Cities and towns',
    'cities and towns--economic aspects' => 'Urban economics',
    'cities'				=> 'Cities and towns',
    'cities, imaginary'			=> 'Imaginary places',
    'city economics'			=> 'Urban economics',
    'city of london (england)'		=> 'City of London (England)',
    'civil liberties'			=> 'Civil rights',
    'civil resistance'			=> 'Government, Resistance to',
    'civil rights'			=> 'Civil rights',
    'class distinction'			=> 'Social classes',
    'classes, social'			=> 'Social classes',
    'classic automobiles'		=> 'Antique and classic cars',
    'classic cars'			=> 'Antique and classic cars',
    'cleanliness'			=> 'Hygiene',
    'climate science'			=> 'Climatology',
    'climate'				=> 'Weather',
    'climate, workplace'		=> 'Work environment',
    'climatology'			=> 'Climatology',
    'clinical informatics'		=> 'Medical informatics',
    'clinical sciences'			=> 'Medicine',
    'clocks and watches'		=> 'Clocks and watches',
    'clocks'				=> 'Clocks and watches',
    'clones of macintosh computers'	=> 'Macintosh-compatible computers',
    'coaching, business'		=> 'Executive coaching',
    'coaching, executive'		=> 'Executive coaching',
    'cobol (computer program language)'	=> 'COBOL (Computer program language)',
    'cobol'				=> 'COBOL (Computer program language)',
    'code and cipher stories'		=> 'Code and cipher stories',
    'code stories'			=> 'Code and cipher stories',
    'codes'				=> 'Ciphers',
    'coffea arabica'			=> 'Coffee',
    'coffea'				=> 'Coffee',
    'coffee'				=> 'Coffee',
    'coffee--use in cooking'		=> 'Cooking (Coffee)',
    'cognitive psychology'		=> 'Cognitive psychology',
    'coins'				=> 'Coins',
    'cold war'				=> 'Cold War',
    'collectables'			=> 'Collectibles',
    'collectibles'			=> 'Collectibles',
    'collectibles, political'		=> 'Political collectibles',
    'collectibles--popular culture'	=> 'Collectibles--Popular culture',
    'collision insurance, automobile'	=> 'Automobile insurance',
    'color in art'			=> 'Color in art',
    'colors in art'			=> 'Color in art',
    'comic book heroes'			=> 'Superheroes',
    'comic books'			=> 'Comic books, strips, etc',
    'comic books, strips, etc'		=> 'Comic books, strips, etc',
    'comic strips'			=> 'Comic books, strips, etc',
    'comics'				=> 'Comic books, strips, etc',
    'coming of age'			=> 'Coming of age',
    'command of troops'			=> 'Command of troops',
    'command of troops--case studies'	=> 'Command of troops--Case studies',
    'commerce'				=> 'Commerce',
    'commerce--history'			=> 'Commerce--History',
    'commerce--statistical methods'	=> 'Commercial statistics',
    'commerce--statistics'		=> 'Commercial statistics',
    'commercial accounting'		=> 'Accounting',
    'commercial education'		=> 'Business education',
    'commercial ethics'			=> 'Business ethics',
    'commercial goods'			=> 'Commercial products',
    'commercial law'			=> 'Commercial law',
    'commercial policy'			=> 'Commercial policy',
    'commercial products'		=> 'Commercial products',
    'commercial property'		=> 'Commercial real estate',
    'commercial real estate'		=> 'Commercial real estate',
    'commercial real property'		=> 'Commercial real estate',
    'commercial space (real estate)'	=> 'Commercial real estate',
    'commercial space'			=> 'Commercial real estate',
    'commercial speech'			=> 'Advertising',
    'commercial statistics'		=> 'Commercial statistics',
    'commercial trade'			=> 'Commerce',
    'commodities exchange'		=> 'Commodity exchanges',
    'commodities exchanges'		=> 'Commodity exchanges',
    'commodities'			=> 'Commercial products',
    'commodity exchanges'		=> 'Commodity exchanges',
    'commodity markets'			=> 'Commodity exchanges',
    'common business-oriented language'	=> 'COBOL (Computer program language)',
    'common shares'			=> 'Stocks',
    'common stocks'			=> 'Stocks',
    'communication and traffic'		=> 'Communication and traffic',
    'communication systems, computer'	=> 'Computer networks',
    'communication systems, wireless'	=> 'Wireless communication systems',
    'communication theory'		=> 'Information theory',
    'communication, administrative'	=> 'Business communication',
    'communication, business'		=> 'Business communication',
    'communication, industrial'		=> 'Business communication',
    'communications industries'		=> 'Communication and traffic',
    'community health'			=> 'Public health',
    'compact discs'			=> 'Compact discs',
    'compact disks'			=> 'Compact discs',
    'companies'				=> 'Business enterprises',
    'comparative economic systems'	=> 'Comparative economics',
    'comparative economics'		=> 'Comparative economics',
    'compatible computers, macintosh'	=> 'Macintosh-compatible computers',
    'competitive intelligence'		=> 'Business intelligence',
    'compilers (computer programs)'	=> 'Compilers (Computer programs)',
    'compilers'				=> 'Compilers (Computer programs)',
    'compiling programs'		=> 'Compilers (Computer programs)',
    'computer graphics'			=> 'Computer graphics',
    "computers--buyers' guides"		=> "Computers--Buyers' guides",
    'competition, international'	=> 'Competition, International',
    'comprehensive health planning'	=> 'Health planning',
    'computational linguistics'		=> 'Computational linguistics',
    'computer aided design'		=> 'Computer-aided design',
    'computer aided manufacturing systems' => 'CAD/CAM systems',
    'computer animation'		=> 'Computer animation',
    'computer architecture'		=> 'Computer architecture',
    'computer assisted design'		=> 'Computer-aided design',
    'computer assisted animation'	=> 'Computer animation',
    'computer assisted filmmaking'	=> 'Computer animation',
    'computer code, malicious'		=> 'Malware (Computer software)',
    'computer communication systems'	=> 'Computer networks',
    'computer crimes'			=> 'Computer crimes',
    'computer engineering'		=> 'Computer engineering',
    'computer game programming'		=> 'Computer games--Programming',
    'computer games'			=> 'Computer games',
    'computer games--programming'	=> 'Computer games--Programming',
    'computer hardware'			=> 'Computers',
    'computer history'			=> 'Computers--History',
    'computer industry'			=> 'Computer industry',
    'computer languages'		=> 'Programming languages (Electronic computers)',
    'computer literacy'			=> 'Computer literacy',
    'computer modeling'			=> 'Computer simulation',
    'computer models'			=> 'Computer simulation',
    'computer network protocols'	=> 'Computer network protocols',
    'computer network security'		=> 'Computer networks--Security measures',
    'computer networks'			=> 'Computer networks',
    'computer networks--security measures' => 'Computer networks--Security measures',
    'computer operating systems'	=> 'Operating systems (Computers)',
    'computer peripherals'		=> 'Computer peripherals',
    'computer privacy'			=> 'Computer security',
    'computer program languages'	=> 'Programming languages (Electronic computers)',
    'computer programming languages'	=> 'Programming languages (Electronic computers)',
    'computer programming'		=> 'Computer programming',
    'computer programming--algorithms'	=> 'Computer programming--Algorithms',
    'computer science'			=> 'Computer science',
    'computer security'			=> 'Computer security',
    'computer simulation'		=> 'Computer simulation',
    'computer software'			=> 'Computer software',
    'computer software--development'	=> 'Computer software--Development',
    'computer software--education'	=> 'Computer software--Education',
    'computer software--mathematics'	=> 'Computer software--Mathematics',
    'computer software--quality assurance' => 'Computer software--Quality assurance',
    'computer system security'		=> 'Computer security',
    'computer systems--security measures' => 'Computer security',
    'computer systems--security'	=> 'Computer security',
    'computer technicians'		=> 'Computer technicians',
    'computer technicians--certification--study guides' =>
      'Computer technicians--Certification--Study guides',
    'computer technologists'		=> 'Computer technicians',
    'computer vision'			=> 'Computer vision',
    'computer-aided design'		=> 'Computer-aided design',
    'computer-aided manufacturing systems' => 'CAD/CAM systems',
    'computer-assisted design'		=> 'Computer-aided design',
    'computer-assisted animation'	=> 'Computer animation',
    'computer-assisted filmmaking'	=> 'Computer animation',
    'computer-generated animation'	=> 'Computer animation',
    'computer-human interaction'	=> 'Human-computer interaction',
    'computers'				=> 'Computers',
    'computers, mechanical'		=> 'Calculators',
    'computers--administration'		=> 'Computers--Administration',
    'computers--design and construction' => 'Computer engineering',
    'computers--history'		=> 'Computers--History',
    'computers--operating systems'	=> 'Operating systems (Computers)',
    'computers--programming'		=> 'Computer programming',
    'computers--reference'		=> 'Computers--Reference',
    'computers--security measures'	=> 'Computer security',
    'computers--security'		=> 'Computer security',
    'computers--social aspects'		=> 'Computers--Social aspects',
    'computing history'			=> 'Computers--History',
    'computing machines'		=> 'Computers',
    'concatenation, file (statistics)'	=> 'Statistical matching',
    'concept art'			=> 'Conceptual art',
    'conceptual art'			=> 'Conceptual art',
    'condiments'			=> 'Condiments',
    'confectionary'			=> 'Confectionery',
    'confectionery'			=> 'Confectionery',
    'confections'			=> 'Confectionery',
    'confederate cooking'		=> 'Cooking, American--Southern style',
    'conflict control'			=> 'Conflict management',
    'conflict management'		=> 'Conflict management',
    'conflict resolution'		=> 'Conflict management',
    'consciousness'			=> 'Consciousness',
    'consciousness-expanding drugs'	=> 'Hallucinogenic drugs',
    'conservation of art objects'       => 'Art objects--Conservation and restoration',
    'consolidation and merger of corporations' => 'Consolidation and merger of corporations',
    'conspiracy'			=> 'Conspiracy',
    'constitutional rights'		=> 'Civil rights',
    'consumer advertising'		=> 'Advertising',
    'consumer behavior'			=> 'Consumer behavior',
    'consumer goods--marketing'		=> 'Marketing',
    'contract services'			=> 'Contracting out',
    'contracting for services'		=> 'Contracting out',
    'contracting out'			=> 'Contracting out',
    'contractions (topology)'		=> 'Contractions (Topology)',
    'controversial literature'		=> 'Controversial literature',
    'convenience cooking'		=> 'Quick and easy cooking',
    'cookery (appetizers)'		=> 'Appetizers',
    'cookery (baby foods)'		=> 'Baby foods',
    'cookery (beer)'			=> 'Cooking (Beer)',
    'cookery (bread)'			=> 'Cooking (Bread)',
    'cookery (chocolate)'		=> 'Cooking (Chocolate)',
    'cookery (coffee)'			=> 'Cooking (Coffee)',
    'cookery (entrées)'			=> 'Entrées (Cooking)',
    'cookery (garnishes)'		=> 'Garnishes (Cooking)',
    'cookery (herbs)'			=> 'Cooking (Herbs)',
    'cookery (liquors)'			=> 'Cooking (Liquors)',
    'cookery (spices)'			=> 'Cooking (Spices)',
    'cookery (tea)'			=> 'Cooking (Tea)',
    'cookery for one'			=> 'Cooking for one',
    'cookery'				=> 'Cooking',
    'cookery, african'			=> 'Cooking, African',
    'cookery, american'			=> 'Cooking, American',
    'cookery, asian'			=> 'Cooking, Asian',
    'cookery, cajan'			=> 'Cooking, Cajun',
    'cookery, cajun'			=> 'Cooking, Cajun',
    'cookery, canadian'			=> 'Cooking, Canadian',
    'cookery, caribbean'		=> 'Cooking, Caribbean',
    'cookery, chinese'			=> 'Cooking, Chinese',
    'cookery, english'			=> 'Cooking, English',
    'cookery, european'			=> 'Cooking, European',
    'cookery, french'			=> 'Cooking, French',
    'cookery, french-canadian'		=> 'Cooking, French-Canadian',
    'cookery, german'			=> 'Cooking, German',
    'cookery, greek'			=> 'Cooking, Greek',
    'cookery, latin american'		=> 'Cooking, Latin American',
    'cookery, oriental'			=> 'Cooking, Asian',
    'cookery, provencal'		=> 'Cooking, French--Provençal style',
    'cookery, provençal'		=> 'Cooking, French--Provençal style',
    'cookery, scottish'			=> 'Cooking, Scottish',
    'cookery, welsh'			=> 'Cooking, Welsh',
    'cookery, west indian'		=> 'Cooking, West Indian',
    'cookery--herbs'			=> 'Cooking (Herbs)',
    'cookery--history'			=> 'Cooking--History',
    'cookies (computer science)'	=> 'Cookies (Computer science)',
    'cookies'				=> 'Cookies',
    'cooking (appetizers)'		=> 'Appetizers',
    'cooking (beer)'			=> 'Cooking (Beer)',
    'cooking (bread)'			=> 'Cooking (Bread)',
    'cooking (chocolate)'		=> 'Cooking (Chocolate)',
    'cooking (coffee)'			=> 'Cooking (Coffee)',
    'cooking (entrées)'			=> 'Entrées (Cooking)',
    'cooking (garnishes)'		=> 'Garnishes (Cooking)',
    'cooking (herbs)'			=> 'Cooking (Herbs)',
    'cooking (liquors)'			=> 'Cooking (Liquors)',
    'cooking (spices)'			=> 'Cooking (Spices)',
    'cooking (spirits)'			=> 'Cooking (Liquors)',
    'cooking (spirits, alcoholic)'	=> 'Cooking (Liquors)',
    'cooking (tea)'			=> 'Cooking (Tea)',
    'cooking bread'			=> 'Cooking (Bread)',
    'cooking for one'			=> 'Cooking for one',
    'cooking for large numbers'		=> 'Quantity cooking',
    'cooking for many people'		=> 'Quantity cooking',
    'cooking history'			=> 'Cooking--History',
    'cooking utensils'			=> 'Kitchen utensils',
    'cooking with beer'			=> 'Cooking (Beer)',
    'cooking with bread'		=> 'Cooking (Bread)',
    'cooking with chocolate'		=> 'Cooking (Chocolate)',
    'cooking with coffee'		=> 'Cooking (Coffee)',
    'cooking with herbs'		=> 'Cooking (Herbs)',
    'cooking with liquors'		=> 'Cooking (Liquors)',
    'cooking with spices'		=> 'Cooking (Spices)',
    'cooking with tea'			=> 'Cooking (Tea)',
    'cooking'				=> 'Cooking',
    'cooking, african'			=> 'Cooking, African',
    'cooking, american'			=> 'Cooking, American',
    'cooking, american--california style'	=> 'Cooking, American--California style',
    'cooking, american--confederate style'	=> 'Cooking, American--Southern style',
    'cooking, american--middle atlantic states'	=> 'Cooking, American--Middle Atlantic States',
    'cooking, american--middle western style'	=> 'Cooking, American--Midwestern style',
    'cooking, american--midwestern style'	=> 'Cooking, American--Midwestern style',
    'cooking, american--new england style'	=> 'Cooking, American--New England style',
    'cooking, american--northwestern states'	=> 'Cooking, American--Northwestern States',
    'cooking, american--southern style'	=> 'Cooking, American--Southern style',
    'cooking, american--southwestern style'	=> 'Cooking, American--Southwestern style',
    'cooking, american--western style'	=> 'Cooking, American--Western style',
    'cooking, alsatian'			=> 'Cooking, French--Alsatian style',
    'cooking, asian'			=> 'Cooking, Asian',
    'cooking, auvergnat'		=> 'Cooking, French--Auvergne style',
    'cooking, auvergne'			=> 'Cooking, French--Auvergne style',
    'cooking, bavarian'			=> 'Cooking, German--Bavarian style',
    'cooking, breton'			=> 'Cooking, French--Brittany style',
    'cooking, brittany'			=> 'Cooking, French--Brittany style',
    'cooking, burgundy'			=> 'Cooking, French--Burgundy style',
    'cooking, cajan'			=> 'Cooking, Cajun',
    'cooking, cajun'			=> 'Cooking, Cajun',
    'cooking, california'		=> 'Cooking, American--California style',
    'cooking, canadian'			=> 'Cooking, Canadian',
    'cooking, caribbean'		=> 'Cooking, Caribbean',
    'cooking, central american and south american'	=> 'Cooking, Latin American',
    'cooking, central and south american'	=> 'Cooking, Latin American',
    'cooking, chinese'			=> 'Cooking, Chinese',
    'cooking, confederate style'	=> 'Cooking, American--Southern style',
    'cooking, confederate'		=> 'Cooking, American--Southern style',
    'cooking, cornish'			=> 'Cooking, English--Cornish style',
    'cooking, corsican'			=> 'Cooking, French--Corsican style',
    'cooking, creole'			=> 'Cooking, Creole',
    'cooking, cretan'			=> 'Cooking, Greek--Cretan style',
    'cooking, devon'			=> 'Cooking, English--Devon style',
    'cooking, devonshire'		=> 'Cooking, English--Devon style',
    'cooking, english'			=> 'Cooking, English',
    'cooking, english--cornish style'	=> 'Cooking, English--Cornish style',
    'cooking, english--devon style'	=> 'Cooking, English--Devon style',
    'cooking, european'			=> 'Cooking, European',
    'cooking, french'			=> 'Cooking, French',
    'cooking, french--alsatian style'	=> 'Cooking, French--Alsatian style',
    'cooking, french--auvergne style'	=> 'Cooking, French--Auvergne style',
    'cooking, french--brittany style'	=> 'Cooking, French--Brittany style',
    'cooking, french--burgundy style'	=> 'Cooking, French--Burgundy style',
    'cooking, french--corsican style'	=> 'Cooking, French--Corsican style',
    'cooking, french--gascony style'	=> 'Cooking, French--Gascony style',
    'cooking, french--lorraine style'	=> 'Cooking, French--Lorraine style',
    'cooking, french--normandy style'	=> 'Cooking, French--Normandy style',
    'cooking, french--provencal style'	=> 'Cooking, French--Provençal style',
    'cooking, french--provençal style'	=> 'Cooking, French--Provençal style',
    'cooking, french-canadian'		=> 'Cooking, French-Canadian',
    'cooking, gascon'			=> 'Cooking, French--Gascony style',
    'cooking, gascony'			=> 'Cooking, French--Gascony style',
    'cooking, german'			=> 'Cooking, German',
    'cooking, german--bavarian style'	=> 'Cooking, German--Bavarian style',
    'cooking, german--schleswig-holstein style'	=> 'Cooking, German--Schleswig-Holstein style',
    'cooking, german--southern style'	=> 'Cooking, German--Southern style',
    'cooking, german--westphalian style'	=> 'Cooking, German--Westphalian style',
    'cooking, greek'			=> 'Cooking, Greek',
    'cooking, greek--cretan style'	=> 'Cooking, Greek--Cretan style',
    'cooking, latin american'		=> 'Cooking, Latin American',
    'cooking, lorraine'			=> 'Cooking, French--Lorraine style',
    'cooking, microwave'		=> 'Microwave cooking',
    'cooking, midwestern style'		=> 'Cooking, American--Midwestern style',
    'cooking, midwestern'		=> 'Cooking, American--Midwestern style',
    'cooking, new england style'	=> 'Cooking, American--New England style',
    'cooking, new england'		=> 'Cooking, American--New England style',
    'cooking, norman'			=> 'Cooking, French--Normandy style',
    'cooking, normandy'			=> 'Cooking, French--Normandy style',
    'cooking, northwestern states'	=> 'Cooking, American--Northwestern States',
    'cooking, oriental'			=> 'Cooking, Asian',
    'cooking, provencal'		=> 'Cooking, French--Provençal style',
    'cooking, provençal'		=> 'Cooking, French--Provençal style',
    'cooking, schleswig-holstein'	=> 'Cooking, German--Schleswig-Holstein style',
    'cooking, scottish'			=> 'Cooking, Scottish',
    'cooking, southern (united states)'	=> 'Cooking, American--Southern style',
    'cooking, southern (germany)'	=> 'Cooking, German--Southern style',
    'cooking, southwestern (united states)'	=> 'Cooking, American--Southwestern style',
    'cooking, welsh'			=> 'Cooking, Welsh',
    'cooking, west indian'		=> 'Cooking, West Indian',
    'cooking, western (united states)'	=> 'Cooking, American--Western style',
    'cooking, westphalian'		=> 'Cooking, German--Westphalian style',
    'cooking--herbs'			=> 'Cooking (Herbs)',
    'cooking--history'			=> 'Cooking--History',
    'cornish cooking'			=> 'Cooking, English--Cornish style',
    'corporate acquisitions'		=> 'Consolidation and merger of corporations',
    'corporate buyouts'			=> 'Consolidation and merger of corporations',
    'corporate coaching'		=> 'Executive coaching',
    'corporate espionage'		=> 'Business intelligence',
    'corporate ethics'			=> 'Business ethics',
    'corporate finance'			=> 'Corporations--Finance',
    'corporate financial management'	=> 'Corporations--Finance',
    'corporate governance'		=> 'Corporate governance',
    'corporate income tax'		=> 'Corporations--Taxation',
    'corporate income taxes'		=> 'Corporations--Taxation',
    'corporate intelligence'		=> 'Business intelligence',
    'corporate management'		=> 'Industrial management',
    'corporate mergers'			=> 'Consolidation and merger of corporations',
    'corporate power'			=> 'Corporate power',
    'corporate takeovers'		=> 'Consolidation and merger of corporations',
    'corporate tax'			=> 'Corporations--Taxation',
    'corporate taxes'			=> 'Corporations--Taxation',
    'corporation ethics'		=> 'Business ethics',
    'corporation finance'		=> 'Corporations--Finance',
    'corporation income tax'		=> 'Corporations--Taxation',
    'corporation income taxes'		=> 'Corporations--Taxation',
    'corporation tax'			=> 'Corporations--Taxation',
    'corporation taxes'			=> 'Corporations--Taxation',
    'corporations'			=> 'Corporations',
    'corporations, federal'		=> 'Corporations, Government',
    'corporations, government'		=> 'Corporations, Government',
    'corporations, international'	=> 'International business enterprises',
    'corporations, nonprofit'		=> 'Nonprofit organizations',
    'corporations, religious'		=> 'Corporations, Religious',
    'corporations--consolidation'	=> 'Consolidation and merger of corporations',
    'corporations--finance'		=> 'Corporations--Finance',
    'corporations--management'		=> 'Industrial management',
    'corporations--mergers'		=> 'Consolidation and merger of corporations',
    'corporations--taxation'		=> 'Corporations--Taxation',
    'corpulence'			=> 'Obesity',
    'correspondence'			=> 'Letters',
    'corrupt practices'			=> 'Corruption',
    'corruption'			=> 'Corruption',
    'corsican cooking'			=> 'Cooking, French--Corsican style',
    'county parks'			=> 'Parks',
    'courting'				=> 'Courtship',
    'courtship'				=> 'Courtship',
    'courtship--fiction'		=> 'Courtship--Fiction',
    'coverage, insurance'		=> 'Insurance',
    'creole cooking'			=> 'Cooking, Creole',
    'cretan cooking'			=> 'Cooking, Greek--Cretan style',
    'criminals'				=> 'Criminals',
    'criminals--biography'		=> 'Criminals--Biography',
    'criticism'				=> 'Criticism',
    'crockery'				=> 'Pottery',
    'crockett, david, 1786-1836'	=> 'Crockett, Davy, 1786-1836',
    'crockett, davy, 1786-1836'		=> 'Crockett, Davy, 1786-1836',
    'cruelty to children'		=> 'Child abuse',
    'cryptanalysis'			=> 'Cryptography',
    'cryptogram stories'		=> 'Code and cipher stories',
    'cryptography'			=> 'Cryptography',
    'cryptography--fiction'		=> 'Code and cipher stories',
    'cryptography--juvenile fiction'	=> 'Code and cipher stories',
    'cryptology'			=> 'Cryptography',
    'crystals'				=> 'Crystals',
    'cuisine'				=> 'Cooking',
    'culture and politics'		=> 'Politics and culture',
    'culture conflict'			=> 'Culture conflict',
    'culture, popular'			=> 'Popular culture',
    'culture--political aspects'	=> 'Politics and culture',
    'currency exchange'			=> 'Foreign exchange',
    'currency'				=> 'Money',
    'curricula vitae'			=> 'Résumés (Employment)',
    'customer relations'		=> 'Customer relations',
    'cyber casting'			=> 'Webcasting',
    'cyber commerce'			=> 'Electronic commerce',
    'cyber crime'			=> 'Computer crimes',
    'cybercasting'			=> 'Webcasting',
    'cybercommerce'			=> 'Electronic commerce',
    'cybercrime'			=> 'Computer crimes',
    'cybernetics'			=> 'Cybernetics',
    'cyborg'				=> 'Cyborgs',
    'cyborgs'				=> 'Cyborgs',
    'c♯ (computer program language)'	=> 'C# (Computer program language)',
    'daniels, kate (fictitious character)'	=> 'Daniels, Kate (Fictitious character)',
    'daniels, kate--fiction'		=> 'Daniels, Kate (Fictitious character)',
    'data banks'			=> 'Databases',
    'data bases'			=> 'Databases',
    'data matching (statistics)'	=> 'Statistical matching',
    'data matching'			=> 'Statistical matching',
    'data merging (statistics)'		=> 'Statistical matching',
    'data merging'			=> 'Statistical matching',
    'data mining'			=> 'Data mining',
    'data networks'			=> 'Computer networks',
    'data networks, computer'		=> 'Computer networks',
    'data processing equipment'		=> 'Computers',
    'data processing'			=> 'Data processing',
    'data communication systems'	=> 'Data transmission systems',
    'data transmission systems'		=> 'Data transmission systems',
    'data transmission systems, broadband' => 'Broadband communication systems',
    'data transmission systems, wideband' => 'Broadband communication systems',
    'data transmission systems, wireless' => 'Wireless communication systems',
    'data warehousing'			=> 'Data warehousing',
    'databanks'				=> 'Databases',
    'database systems'			=> 'Databases',
    'databases'				=> 'Databases',
    'datamining'			=> 'Data mining',
    'death (personification)'		=> 'Death (Personification)',
    'death penalty'			=> 'Capital punishment',
    'death sentence'			=> 'Capital punishment',
    'death'				=> 'Death',
    'death--philosophy'			=> 'Death',
    'debentures'			=> 'Bonds',
    'debian (computer system)'		=> 'Debian (Computer system)',
    'debian'				=> 'Debian (Computer system)',
    'deciding'				=> 'Decision making',
    'decision (psychology)'		=> 'Decision making',
    'decision analysis'			=> 'Decision making',
    'decision making'			=> 'Decision making',
    'decision processes'		=> 'Decision making',
    'decoration of food'		=> 'Garnishes (Cooking)',
    'decoration, interior'		=> 'Interior decoration',
    'decoy ships'			=> 'Q-ships',
    'decriminalization of illegal drugs' => 'Drug legalization',
    'delivery of health care'		=> 'Medical care',
    'delivery of medical care'		=> 'Medical care',
    'depository institutions'		=> 'Banks and banking',
    'deprivation, sensory'		=> 'Sensory deprivation',
    'deprivation, sleep'		=> 'Sleep deprivation',
    'design of logic systems'		=> 'Logic design',
    'design, logic'			=> 'Logic design',
    'desk calculators'			=> 'Calculators',
    'desserts'				=> 'Desserts',
    'destitution'			=> 'Poverty',
    'devaluation of currency'		=> 'Monetary policy',
    'development of application software' => 'Application software--Development',
    'development of web sites'		=> 'Web site development',
    'development stage businesses'	=> 'New business enterprises',
    'development stage enterprises'	=> 'New business enterprises',
    'development, business'		=> 'Business--Development',
    'development, economic'		=> 'Economic development',
    'development, sustainable'		=> 'Sustainable development',
    'devon cooking'			=> 'Cooking, English--Devon style',
    'devonshire cooking'		=> 'Cooking, English--Devon style',
    'dickering'				=> 'Negotiation',
    'diet'				=> 'Diet',
    'diets'				=> 'Reducing diets',
    'digital art'			=> 'Digital art',
    'digital compact discs'		=> 'Compact discs',
    'digital compact disks'		=> 'Compact discs',
    'digital media'			=> 'Digital media',
    'digital publishing'		=> 'Electronic publishing',
    'dimensions'			=> 'Dimensions',
    'dip systems'			=> 'Document imaging systems',
    'direct mail campaigns'		=> 'Direct marketing',
    'direct marketing'			=> 'Direct marketing',
    'discoverers'			=> 'Explorers',
    'disc world (imaginary place)'	=> 'Discworld (Imaginary place)',
    'disc world'			=> 'Discworld (Imaginary place)',
    'discs, compact'			=> 'Compact discs',
    'discs, optical'			=> 'Optical disks',
    'discworld (imaginary place)'	=> 'Discworld (Imaginary place)',
    'discworld'				=> 'Discworld (Imaginary place)',
    'disk operating systems'		=> 'Operating systems (Computers)',
    'disks, compact'			=> 'Compact discs',
    'disks, optical'			=> 'Optical disks',
    'dispute settlement'		=> 'Conflict management',
    'distilled beverages'		=> 'Liquors',
    'distributed computer systems'	=> 'Electronic data processing--Distributed processing',
    'distributed computing systems'	=> 'Electronic data processing--Distributed processing',
    'distributed computing'		=> 'Electronic data processing--Distributed processing',
    'distributed processing'		=> 'Electronic data processing--Distributed processing',
    'distribution (economic theory)'	=> 'Distribution (Economic theory)',
    'distributorship, multilevel'	=> 'Multilevel marketing',
    'divination'			=> 'Divination',
    'divine healing'			=> 'Spiritual healing',
    'divine messengers'			=> 'Angels',
    'djin'				=> 'Jinn',
    'djinn'				=> 'Jinn',
    'djinni'				=> 'Jinn',
    'djinns'				=> 'Jinn',
    'djins'				=> 'Jinn',
    'depuy, william e. (william eugene), 1919-1992'
      => 'DePuy, William E. (William Eugene), 1919-1992',
    'doctrinal and controversial works'	=> 'Controversial literature',
    'document image processing'		=> 'Document imaging systems',
    'document imaging systems'		=> 'Document imaging systems',
    'document management systems'	=> 'Document imaging systems',
    'document management'		=> 'Document imaging systems',
    'doffing'				=> 'Textile industry',
    'dolls'				=> 'Dolls',
    'domestic fiction'			=> 'Domestic fiction',
    'domestic marketing'		=> 'Marketing',
    'domestic novels'			=> 'Domestic fiction',
    'domestic rabbit'			=> 'Rabbits',
    'domestic rabbits'			=> 'Rabbits',
    'double entry bookkeeping'		=> 'Bookkeeping',
    'drawing technique'			=> 'Drawing',
    'drawing'				=> 'Drawing',
    'drawing--technique'		=> 'Drawing',
    'dreaming'				=> 'Dreams',
    'dreams'				=> 'Dreams',
    'drinking water'			=> 'Drinking water',
    'drinks'				=> 'Beverages',
    'drug decriminalization'		=> 'Drug legalization',
    'drug legalization'			=> 'Drug legalization',
    'drugs'				=> 'Drugs',
    'dying'				=> 'Death',
    'e-business'			=> 'Electronic commerce',
    'e-commerce'			=> 'Electronic commerce',
    'e-mail correspondence'		=> 'Electronic mail messages',
    'e-mail messages'			=> 'Electronic mail messages',
    'e-mail software'			=> 'Electronic mail systems',
    'e-mail systems'			=> 'Electronic mail systems',
    'e-mail'				=> 'Electronic mail messages',
    'e-tailing'				=> 'Electronic commerce',
    'earthenware'			=> 'Pottery',
    'easy and quick cooking'		=> 'Quick and easy cooking',
    'ebusiness'				=> 'Electronic commerce',
    'ecclesiastical corporations'	=> 'Corporations, Religious',
    'ecological monitoring'		=> 'Environmental monitoring',
    'ecologically sustainable development' => 'Sustainable development',
    'ecommerce'				=> 'Electronic commerce',
    'econometrics'			=> 'Econometrics',
    'economic conditions'		=> 'Economic conditions',
    'economic development'		=> 'Economic development',
    'economic development, sustainable' => 'Sustainable development',
    'economic espionage'		=> 'Business intelligence',
    'economic goods'			=> 'Commercial products',
    'economic growth'			=> 'Economic development',
    # Works on the history of economics as a discipline are entered under Economics--History
    'economic history'			=> 'Economic history',
    'economic infrastructure'		=> 'Infrastructure (Economics)',
    'economic statistics'		=> 'Economic statistics',
    'economic sustainability'		=> 'Sustainable development',
    'economic theory'			=> 'Economics',
    'economics of cities'		=> 'Urban economics',
    'economics'				=> 'Economics',
    'economics, comparative'		=> 'Comparative economics',
    'economics--environmental aspects'	=> 'Environmental economics',
    'economics--history'		=> 'Economics--History',
    'edi (electronic data interchange)' => 'Electronic data interchange',
    'edi'				=> 'Electronic data interchange',
    'edinburgh (scotland)'		=> 'Edinburgh (Scotland)',
    'edinburgh, scotland'		=> 'Edinburgh (Scotland)',
    'education software'		=> 'Computer software--Education',
    'education'				=> 'Education',
    'education, business'		=> 'Business education',
    'educational software'		=> 'Computer software--Education',
    # Note that 'Educators' is different from 'Teachers'
    'educators'				=> 'Educators',
    'election monitoring'		=> 'Election monitoring',
    'election observation'		=> 'Election monitoring',
    'elections'				=> 'Elections',
    'electoral politics'		=> 'Elections',
    'electronic banking'		=> 'Internet banking',
    'electronic brains'			=> 'Artificial intelligence',
    'electronic business data interchange' => 'Electronic data interchange',
    'electronic business'		=> 'Electronic commerce',
    'electronic calculating machines'	=> 'Computers',
    'electronic calculating-machines'	=> 'Computers',
    'electronic commerce'		=> 'Electronic commerce',
    'electronic communication networks'	=> 'Computer networks',
    'electronic computer programming'	=> 'Computer programming',
    'electronic computers'		=> 'Computers',
    'electronic data interchange'	=> 'Electronic data interchange',
    'electronic data processing'	=> 'Data processing',
    'electronic data processing--distributed processing' => 'Electronic data processing--Distributed processing',
    'electronic data processing--programming'	=> 'Computer programming',
    'electronic document imaging systems' => 'Document imaging systems',
    'electronic document management systems' => 'Document imaging systems',
    'electronic information services'	=> 'Online information services',
    'electronic mail messages'		=> 'Electronic mail messages',
    'electronic mail systems'		=> 'Electronic mail systems',
    'electronic marketing'		=> 'Telemarketing',
    'electronic media'			=> 'Digital media',
    'electronic publishing'		=> 'Electronic publishing',
    'electronic social networks'	=> 'Online social networks',
    'electronic spread sheets'		=> 'Electronic spreadsheets',
    'electronic spreadsheet software'	=> 'Electronic spreadsheets--Software',
    'electronic spreadsheets'		=> 'Electronic spreadsheets',
    'electronic spreadsheets--software' => 'Electronic spreadsheets--Software',
    'electronic trading'		=> 'Electronic trading of securities',
    'electronic trading of securities'	=> 'Electronic trading of securities',
    'email correspondence'		=> 'Electronic mail messages',
    'email messages'			=> 'Electronic mail messages',
    'email software'			=> 'Electronic mail systems',
    'email systems'			=> 'Electronic mail systems',
    'email'				=> 'Electronic mail messages',
    'employment management'		=> 'Personnel management',
    'enchanters'			=> 'Wizards',
    'end of life'			=> 'Death',
    'energetic healing'			=> 'Energy medicine',
    'energy healing'			=> 'Energy medicine',
    'energy industries'			=> 'Energy industries',
    'energy medicine'			=> 'Energy medicine',
    'engeland'				=> 'England',
    'engineering design'	        => 'Engineering design',
    'engineering--authorship'		=> 'Technical writing',
    'engines, search'			=> 'Search engines',
    'england'				=> 'England',
    'england--fiction'			=> 'England--Fiction',
    'england--social life and customs'	=> 'England--Social life and customs',
    'england--social life and customs--19th century--fiction' => 'England--Social life and customs--19th century--Fiction',
    'english biscuits'			=> 'Cookies',
    'english cooking'			=> 'Cooking, English',
    'english customs'			=> 'England--Social life and customs',
    'english fiction'			=> 'English fiction',
    'english grammar'			=> 'English language--Grammar',
    'english language'			=> 'English language',
    'english language--grammar'		=> 'English language--Grammar',
    'english literature'		=> 'English literature',
    'enochian magic'			=> 'Enochian magic',
    'enochian magick'			=> 'Enochian magic',
    'enslavement'			=> 'Slavery',
    'enterprises'			=> 'Business enterprises',
    'enterprises, business'		=> 'Business enterprises',
    'entertaining'			=> 'Entertaining',
    # 'Entertainment industry' is not an official LC subject, but is submitted as one
    'entertainment industry'		=> 'Entertainment industry',
    'entheogens'			=> 'Hallucinogenic drugs',
    'entrées (cookery)'			=> 'Entrées (Cooking)',
    'entrées (cooking)'			=> 'Entrées (Cooking)',
    'entrepreneur'			=> 'Entrepreneurship',
    'entrepreneurs, women'		=> 'Businesswomen',
    'entrepreneurship'			=> 'Entrepreneurship',
    'environment, work'			=> 'Work environment',
    'environmental economics'		=> 'Environmental economics',
    'environmental monitoring'		=> 'Environmental monitoring',
    'environmental quality'		=> 'Environmental quality',
    'environmental quality--economic aspects' => 'Environmental economics',
    'environmental quality--measurement' => 'Environmental monitoring',
    'environmental quality--monitoring' => 'Environmental monitoring',
    'environmentalists'			=> 'Environmentalists',
    'environmentalists--biography'	=> 'Environmentalists--Biography',
    'environments, virtual'		=> 'Virtual reality',
    'equipment, capital'		=> 'Industrial equipment',
    'equipment, industrial'		=> 'Industrial equipment',
    'equities'				=> 'Stocks',
    'equity capital'			=> 'Stocks',
    'equity financing'			=> 'Stocks',
    'erotic art'			=> 'Erotic art',
    'erotic fiction'			=> 'Erotic stories',
    'erotic stories'			=> 'Erotic stories',
    'erotic'				=> 'Erotic stories',
    'erotica'				=> 'Erotic stories',
    'esd (ecologically sustainable development)' => 'Sustainable development',
    'esme weatherwax (fictitious character)'	=> 'Weatherwax, Granny (Fictitious character)',
    'esme weatherwax'			=> 'Weatherwax, Granny (Fictitious character)',
    'esmeralda weatherwax (fictitious character)'	=> 'Weatherwax, Granny (Fictitious character)',
    'esmeralda weatherwax'		=> 'Weatherwax, Granny (Fictitious character)',
    'esp'				=> 'Extrasensory perception',
    'espionage, business'		=> 'Business intelligence',
    'espionage, corporate'		=> 'Business intelligence',
    'espionage, economic'		=> 'Business intelligence',
    'espionage, industrial'		=> 'Business intelligence',
    'eternal life'			=> 'Immortality',
    'etheric world intelligences'	=> 'Guides (Spiritualism)',
    'ethics in government'		=> 'Political ethics',
    'ethics'				=> 'Ethics',
    'ethics, political'			=> 'Political ethics',
    'ethics, primitive'			=> 'Ethics',
    'ethology'				=> 'Ethics',
    'etiquette'				=> 'Etiquette',
    'european art'			=> 'Art, European',
    'european cooking'			=> 'Cooking, European',
    'evidence control'			=> 'Evidence preservation',
    'evidence preservation'		=> 'Evidence preservation',
    'evidence, criminal--preservation'	=> 'Evidence preservation',
    'ex-convicts'			=> 'Ex-convicts',
    'exchange, foreign'			=> 'Foreign exchange',
    'exchanges, commodity'		=> 'Commodity exchanges',
    'exchanges, produce'		=> 'Commodity exchanges',
    'excursions'			=> 'Tourism',
    'executive coaching'		=> 'Executive coaching',
    'executive information systems'	=> 'Management information systems',
    'executive power'			=> 'Executive power',
    'executive power--united states'	=> 'Executive power--United States',
    'exercise'				=> 'Physical fitness',
    'expert systems (computer science)'	=> 'Expert systems (Computer science)',
    'expert systems'			=> 'Expert systems (Computer science)',
    'explorers'				=> 'Explorers',
    'explorers--biography'		=> 'Explorers--Biography',
    'export marketing'			=> 'Export marketing',
    'exports & imports'			=> 'International trade',
    'exports and imports'		=> 'International trade',
    'extendible markup language'	=> 'XML (Document markup language)',
    'extensible markup language'	=> 'XML (Document markup language)',
    'external trade'			=> 'International trade',
    'extranets (computer networks)'	=> 'Extranets (Computer networks)',
    'extranets'				=> 'Extranets (Computer networks)',
    'extrasensory perception'		=> 'Extrasensory perception',
    'facilities management'		=> 'Facility management',
    'facility management'		=> 'Facility management',
    'factual data analysis'		=> 'Data mining',
    'faerie'				=> 'Fairies',
    'fairie'				=> 'Fairies',
    'fairies'				=> 'Fairies',
    'fairy tales'			=> 'Fairy tales',
    'fairy'				=> 'Fairies',
    'faith healing'			=> 'Spiritual healing',
    'faith-cure'			=> 'Spiritual healing',
    'family budgets'			=> 'Budgets, Personal',
    'family'				=> 'Family',
    'fantastic fiction'			=> 'Fantasy fiction',
    'fantasy fiction'			=> 'Fantasy fiction',
    'fantasy fiction--authorship'	=> 'Fantasy fiction--Authorship',
    'fantasy fiction--technique'	=> 'Fantasy fiction--Technique',
    'fantasy'				=> 'Fantasy fiction',
    'fat-free diet'			=> 'Low-fat diet',
    'fatness'				=> 'Obesity',
    'fear of being alone'		=> 'Agoraphobia',
    'fear of isolation'			=> 'Agoraphobia',
    'fear of open space'		=> 'Agoraphobia',
    'fear of open spaces'		=> 'Agoraphobia',
    'federal corporation tax'		=> 'Corporations--Taxation',
    'feng shui'				=> 'Feng shui',
    'festive cooking'			=> 'Holiday cooking',
    'fiction action adventure'		=> 'Adventure stories',
    'fiction'				=> 'Fiction',
    'fiction, juvenile'			=> 'Fiction, Juvenile',
    'fiction, paranormal'		=> 'Paranormal fiction',
    'fiction--fantasy'			=> 'Fantasy fiction',
    'fiction--paranormal'		=> 'Paranormal fiction',
    'fiction--science fiction'		=> 'Science fiction',
    'fictitious places'			=> 'Imaginary places',
    'figurines'				=> 'Figurines',
    'file concatenation (statistics)'	=> 'Statistical matching',
    'finance'				=> 'Finance',
    'finance, personal'			=> 'Finance, Personal',
    'finance, personal--planning'	=> 'Finance, Personal',
    'finance, personal--software'	=> 'Finance, Personal--Software',
    'finance, public'			=> 'Finance, Public',
    'financial analysis of corporations' => 'Corporations--Finance',
    'financial management of corporations' => 'Corporations--Finance',
    'financial management, corporate'	=> 'Corporations--Finance',
    'financial management, personal'	=> 'Finance, Personal',
    'financial planning of corporations' => 'Corporations--Finance',
    'financial planning, personal'	=> 'Finance, Personal',
    'financial risk management'		=> 'Financial risk management',
    'financial services industry'	=> 'Financial services industry',
    'financial services'		=> 'Financial services industry',
    'firearms'				=> 'Firearms',
    'firms'				=> 'Business enterprises',
    # 'First contact' is not directly a LC heading, but submitted as a recommendation
    'first contact'			=> 'First contact',
    'fitness, physical'			=> 'Physical fitness',
    'flasks'				=> 'Bottles',
    'flatboats'				=> 'Flatboats',
    'flight'				=> 'Flight',
    'flying saucers'			=> 'Unidentified flying objects',
    'flying-machines'			=> 'Flying-machines',
    'folk art'				=> 'Folk art',
    'food allergy'			=> 'Food allergy',
    'food calories'			=> 'Food--Caloric content',
    'food decoration'			=> 'Garnishes (Cooking)',
    'food industry and trade'		=> 'Food industry and trade',
    'food preparation industry'		=> 'Food industry and trade',
    'food preparation'			=> 'Cooking',
    'food processing industry'		=> 'Food industry and trade',
    'food processing'			=> 'Food industry and trade',
    'food trade'			=> 'Food industry and trade',
    'food, baby'			=> 'Baby foods',
    'food, raw'				=> 'Raw foods',
    'food--caloric content'		=> 'Food--Caloric content',
    'food--health aspects',		=> 'Nutrition',
    'foods, baby'			=> 'Baby foods',
    'foods, infant'			=> 'Baby foods',
    'foods, raw'			=> 'Raw foods',
    'forecasting, business'		=> 'Business forecasting',
    'foreign commerce'			=> 'International trade',
    'foreign exchange'			=> 'Foreign exchange',
    'foreign languages'			=> 'Language and languages',
    'foreign trade'			=> 'International trade',
    'foreign trade policy'		=> 'Commercial policy',
    'forex'				=> 'Foreign exchange',
    'fortran (computer program language)' => 'FORTRAN (Computer program language)',
    'fortune-telling'			=> 'Fortune-telling',
    'fortunetelling'			=> 'Fortune-telling',
    'franchises (retail trade)'		=> 'Franchises (Retail trade)',
    'franchises, retail'		=> 'Franchises (Retail trade)',
    'franchises, taxation of'		=> 'Corporations--Taxation',
    'franchises, taxation'		=> 'Corporations--Taxation',
    'franchises--taxation'		=> 'Corporations--Taxation',
    'free enterprise'			=> 'Free enterprise',
    'free markets'			=> 'Free enterprise',
    'french cooking'			=> 'Cooking, French',
    'french-canadian cooking'		=> 'Cooking, French-Canadian',
    'fundamental rights'		=> 'Civil rights',
    'funding'				=> 'Finance',
    'funnies'				=> 'Comic books, strips, etc',
    'furniture'				=> 'Furniture',
    'fusion of corporations'		=> 'Consolidation and merger of corporations',
    'fusion, data (statistics)'		=> 'Statistical matching',
    'fusion, data'			=> 'Statistical matching',
    # 'Future life' is a separate LC Subject meaning 'life after
    # death', not 'life in the future', but it is so confusing that it
    # just gets folded into 'Immortality' in this code.
    'future life'			=> 'Immortality',
    # 'Futures' is futures trading, not potential future events
    'futures contracts'			=> 'Futures',
    'futures trading'			=> 'Futures',
    'futures'				=> 'Futures',
    'fx (finance)'			=> 'Foreign exchange',
    'gaap (accounting)'			=> 'Accounting--Standards',
    'gaap'				=> 'Accounting--Standards',
    'gadgets'				=> 'Implements, utensils, etc',
    'game programming'			=> 'Computer games--Programming',
    'garnish, harry (fictitious character)' => 'Garnish, Harry (Fictitious character)',
    'garnishes (cookery)'		=> 'Garnishes (Cooking)',
    'garnishes (cooking)'		=> 'Garnishes (Cooking)',
    'garnishes'				=> 'Garnishes (Cooking)',
    'garnishing (cookery)'		=> 'Garnishes (Cooking)',
    'garnishing (cooking)'		=> 'Garnishes (Cooking)',
    'garnishing'			=> 'Garnishes (Cooking)',
    'gascon cooking'			=> 'Cooking, French--Gascony style',
    'gascony cooking'			=> 'Cooking, French--Gascony style',
    'gasoline automobiles'		=> 'Automobiles',
    'generally accepted accounting principles' => 'Accounting--Standards',
    'generals--united states'		=> 'Generals--United States',
    'genies'				=> 'Jinn',
    'genii'				=> 'Jinn',
    'german cooking'			=> 'Cooking, German',
    'ghost stories'			=> 'Ghost stories',
    'ghosts'				=> 'Ghost stories',
    'glass'				=> 'Glass',
    'glassman, josh (fictitious character)' => 'Glassman, Josh (Fictitious character)',
    'glassman, josh'			=> 'Glassman, Josh (Fictitious character)',
    'glassware'				=> 'Glassware',
    'global cities'			=> 'Cities and towns',
    'global commerce'			=> 'International trade',
    'global corporations'		=> 'International business enterprises',
    'global terrorism'			=> 'Terrorism',
    'global trade'			=> 'International trade',
    'gluten-free foods'			=> 'Gluten-free foods',
    'goal programming'			=> 'Programming (Mathematics)',
    'goblins'				=> 'Goblins',
    'goddess religion'			=> 'Goddess religion',
    'government'			=> 'Government',
    'government companies'		=> 'Corporations, Government',
    'government corporations'		=> 'Corporations, Government',
    'government ethics'			=> 'Political ethics',
    'government, resistance to'		=> 'Government, Resistance to',
    'government, resistance to--united states' => 'Government, Resistance to--United States',
    'graffiti'				=> 'Graffiti',
    'graffiti artists'			=> 'Graffiti artists',
    'graffiti culture'			=> 'Graffiti',
    'graphic data processing'		=> 'Computer graphics',
    'graphics, computer'		=> 'Computer graphics',
    'granny weatherwax (fictitious character)'	=> 'Weatherwax, Granny (Fictitious character)',
    'granny weatherwax'			=> 'Weatherwax, Granny (Fictitious character)',
    'greek cooking'			=> 'Cooking, Greek',
    'greek mythology'			=> 'Mythology, Greek',
    'green business'			=> 'Business enterprises--Environmental aspects',
    'grief'				=> 'Grief',
    'grilling (cooking)'		=> 'Barbecuing',
    'grim reaper'			=> 'Death (Personification)',
    'growing up'			=> 'Coming of age',
    'guests, entertaining'		=> 'Entertaining',
    'guides (spiritualism)'		=> 'Guides (Spiritualism)',
    'guides, spirit'			=> 'Guides (Spiritualism)',
    'gunning'				=> 'Shooting',
    'guns'				=> 'Firearms',
    'haggling'				=> 'Negotiation',
    'hares'				=> 'Rabbits',
    'harry garnish (fictitious character)' => 'Garnish, Harry (Fictitious character)',
    'higgling'				=> 'Negotiation',
    'hallucinations and illusions'	=> 'Hallucinations and illusions',
    'hallucinogenic drugs'		=> 'Hallucinogenic drugs',
    'hallucinogens'			=> 'Hallucinogenic drugs',
    'hardware, computer'		=> 'Computers',
    'heads of government'		=> 'Heads of state',
    'heads of state'			=> 'Heads of state',
    'heads of state--biography'		=> 'Heads of state--Biography',
    'healing'				=> 'Healing',
    'health & healing'			=> 'Healing',
    'health & fitness'			=> 'Physical fitness',
    'health and fitness'		=> 'Physical fitness',
    'health care delivery'		=> 'Medical care',
    'health care planning'		=> 'Health planning',
    'health care'			=> 'Medical care',
    'health informatics'		=> 'Medical informatics',
    'health insurance'			=> 'Health insurance',
    'health planning'			=> 'Health planning',
    'health plans'			=> 'Health planning',
    'health plans, prepaid'		=> 'Health insurance',
    'health services planning'		=> 'Health planning',
    'health services'			=> 'Medical care',
    'health thoughts'			=> 'Mental healing',
    'healthcare'			=> 'Medical care',
    'heart--diseases--nutritional aspects'	=> 'Heart--Diseases--Nutritional aspects',
    'heavy weapons'			=> 'Ordnance',
    'herbal cooking'			=> 'Cooking (Herbs)',
    'herbs'				=> 'Herbs',
    'herbs--use in cooking'		=> 'Cooking (Herbs)',
    'hermeticism'			=> 'Hermetism',
    'hermetism'				=> 'Hermetism',
    'high tech'				=> 'High technology',
    'high technology'			=> 'High technology',
    'hispanic american art'		=> 'Hispanic American art',
    'historical fiction'		=> 'Historical fiction',
    'historical fiction, chinese'	=> 'Historical fiction, Chinese',
    'history of cooking'		=> 'Cooking--History',
    'history'				=> 'History',
    'history--20th century'		=> 'History--20th century',
    'history--cooking'			=> 'Cooking--History',
    'history, economic'			=> 'Economic history',
    'history, military'			=> 'History, Military',
    'holiday cookery'			=> 'Holiday cooking',
    'holiday cooking'			=> 'Holiday cooking',
    'holiday industry'			=> 'Tourism',
    'home businesses'			=> 'Home-based businesses',
    'home buying'			=> 'House buying',
    'home computers'			=> 'Microcomputers',
    'home decoration'			=> 'Interior decoration',
    'home purchase'			=> 'House buying',
    'home purchasing'			=> 'House buying',
    'home selling'			=> 'House selling',
    'home-based businesses'		=> 'Home-based businesses',
    'homosexuality'			=> 'Homosexuality',
    'horoscopes'			=> 'Horoscopes',
    "hors d'oeuvres"			=> 'Appetizers',
    'hostile takeovers of corporations'	=> 'Consolidation and merger of corporations',
    'hostile takeovers'			=> 'Consolidation and merger of corporations',
    'hot dish cooking'			=> 'Casserole cooking',
    'hotdish cooking'			=> 'Casserole cooking',
    'house buying'			=> 'House buying',
    'house decoration'			=> 'Interior decoration',
    'house guests, entertaining'	=> 'Entertaining',
    'house hunting'			=> 'House buying',
    'house selling'			=> 'House selling',
    'houseguests, entertaining'		=> 'Entertaining',
    'household utensils'		=> 'Implements, utensils, etc',
    'how to start a business'		=> 'New business enterprises',
    'how to start businesses'		=> 'New business enterprises',
    'horror'				=> 'Horror',
    'html (document markup language)'	=> 'HTML (Document markup language)',
    'html'				=> 'HTML (Document markup language)',
    'http cookies (computer science)'	=> 'Cookies (Computer science)',
    'http cookies'			=> 'Cookies (Computer science)',
    # 'Human beings in art' is for representations of humans in art
    'human beings in art'		=> 'Human beings in art',
    'human body in art'			=> 'Human figure in art',
    'human body--care and hygiene'	=> 'Hygiene',
    'human factors in computing systems' => 'Human-computer interaction',
    'human females'			=> 'Women',
    # 'Human figure in art' is for art technique, not representations
    'human figure in art'		=> 'Human figure in art',
    'human resource management'		=> 'Personnel management',
    'human resources management'	=> 'Personnel management',
    'human rights'			=> 'Human rights',
    'human sexuality'			=> 'Sex',
    'human-computer interaction'	=> 'Human-computer interaction',
    'humans in art'			=> 'Human beings in art',
    'humanx'		 		=> 'Humanx Commonwealth (Imaginary organization)',
    'humanx commonwealth' 		=> 'Humanx Commonwealth (Imaginary organization)',
    'humanx commonwealth (imaginary organization)'
      => 'Humanx Commonwealth (Imaginary organization)',
    'humanx commonwealth (imaginary organization)--fiction'
      => 'Humanx Commonwealth (Imaginary organization)',
    'humor'				=> 'Humor',
    'humor adult humor and comedy'	=> 'Humor',
    'humour'				=> 'Humor',
    'hygiene'				=> 'Hygiene',
    'hygiene, public'			=> 'Public health',
    'hygiene, social'			=> 'Public health',
    'hypertext markup language'		=> 'HTML (Document markup language)',
    'icebreakers (ships)'		=> 'Icebreakers (Ships)',
    'illiteracy'			=> 'Literacy',
    'illusions'				=> 'Hallucinations and illusions',
    'illusions, optical'		=> 'Optical illusions',
    'image processing'			=> 'Image processing',
    'imaginary cities'			=> 'Imaginary places',
    'imaginary islands'			=> 'Imaginary places',
    'imaginary places'			=> 'Imaginary places',
    # 'Immortalism' refers to living indefinitely in the flesh
    'immortalism'			=> 'Immortalism',
    # 'Immortality' refers to survival of the soul after death
    'immortality'			=> 'Immortality',
    'implements, utensils, etc'		=> 'Implements, utensils, etc',
    'imports & exports'			=> 'International trade',
    'imports and exports'		=> 'International trade',
    'imputation, mass (statistics)'	=> 'Statistical matching',
    'income tax'			=> 'Income tax',
    'indemnity insurance'		=> 'Insurance',
    'industrial administration'		=> 'Industrial management',
    'industrial communication'		=> 'Business communication',
    'industrial equipment'		=> 'Industrial equipment',
    'industrial equipment--marketing'	=> 'Industrial marketing',
    'industrial espionage'		=> 'Business intelligence',
    'industrial management'		=> 'Industrial management',
    'industrial marketing'		=> 'Industrial marketing',
    'industrial policy'			=> 'Industrial policy',
    'industrial production'		=> 'Industries',
    'industrial project management'	=> 'Project management',
    'industries'			=> 'Industries',
    'industries--equipment and supplies' => 'Industrial equipment',
    'industries--government policy'	=> 'Industrial policy',
    'industries--public relations'	=> 'Public relations',
    'industry and state'		=> 'Industrial policy',
    'industry'				=> 'Industries',
    'infancy'				=> 'Infants',
    'infant foods'			=> 'Baby foods',
    'infants'				=> 'Infants',
    'infants--food'			=> 'Baby foods',
    'inflation (finance)'		=> 'Inflation (Finance)',
    'inflation'				=> 'Inflation (Finance)',
    'informatics'			=> 'Computer science',
    'information resources management'	=> 'Information resources management',
    'information systems management'	=> 'Information resources management',
    'information technology'		=> 'Information technology',
    'information theory'		=> 'Information theory',
    'information warehousing'		=> 'Data warehousing',
    'infrastructure (economics)'	=> 'Infrastructure (Economics)',
    'inghilterra'			=> 'England',
    'inglaterra'			=> 'England',
    'ink drawing'			=> 'Pen drawing',
    'inspiration'			=> 'Inspiration',
    'inspiration--religious aspects'	=> 'Inspiration--Religious aspects',
    'instruction'			=> 'Education',
    'instructors'			=> 'Teachers',
    'instruments, musical'		=> 'Musical instruments',
    'insurance coverage'		=> 'Insurance',
    'insurance industry'		=> 'Insurance',
    'insurance protection'		=> 'Insurance',
    'insurance risk'			=> 'Risk (Insurance)',
    'insurance'				=> 'Insurance',
    'insurance, automobile'		=> 'Automobile insurance',
    'insurance, casualty'		=> 'Casualty insurance',
    'insurance, health'			=> 'Health insurance',
    'insurance, liability'		=> 'Liability insurance',
    'insurance, life'			=> 'Life insurance',
    'insurance, property'		=> 'Property insurance',
    'insurance--risk'			=> 'Risk (Insurance)',
    'intellectronics'			=> 'Artificial intelligence',
    'intellectual capital'		=> 'Intellectual capital',
    'intelligence, artificial'		=> 'Artificial intelligence',
    'intelligence, business'		=> 'Business intelligence',
    'intelligence, corporate'		=> 'Business intelligence',
    'intelligences, etheric world'	=> 'Guides (Spiritualism)',
    'intelligent machines'		=> 'Artificial intelligence',
    'interaction, human-computer'	=> 'Human-computer interaction',
    'interactive computer systems'	=> 'Interactive computer systems',
    'intercourse, sexual'		=> 'Sex',
    'interest and usury'		=> 'Interest',
    'interest'				=> 'Interest',
    'interfaces, user (computer systems)' => 'User interfaces (Computer systems)',
    'interfaces, user'			=> 'User interfaces (Computer systems)',
    'interior decoration'		=> 'Interior decoration',
    'interior design'			=> 'Interior decoration',
    'internal internets (computer networks)' => 'Intranets (Computer networks)',
    'internal internets'		=> 'Intranets (Computer networks)',
    'international accounting'		=> 'International business enterprises--Accounting',
    'international business enterprises' => 'International business enterprises',
    'international business enterprises--accounting' =>
      'International business enterprises--Accounting',
    'international business enterprises--taxation' =>
      'International business enterprises--Taxation',
    'international competition'		=> 'Competition, International',
    'international corporations'	=> 'International business enterprises',
    'international economics'		=> 'Competition, International',
    'international exchange'		=> 'Foreign exchange',
    'international marketing'		=> 'Export marketing',
    'international taxation'		=> 'International business enterprises--Taxation',
    'international taxes'		=> 'International business enterprises--Taxation',
    'international terrorism'		=> 'Terrorism',
    'international trade policy'	=> 'Commercial policy',
    'international trade'		=> 'International trade',
    'internet advertising'		=> 'Internet advertising',
    'internet application development'	=> 'Application software--Internet--Development',
    'internet application software'	=> 'Application software--Internet',
    'internet applications'		=> 'Application software--Internet',
    'internet apps'			=> 'Application software--Internet',
    'internet auctions'			=> 'Internet auctions',
    'internet banking'			=> 'Internet banking',
    'internet bookstores'		=> 'Internet bookstores',
    'internet broadcasting'		=> 'Webcasting',
    'internet browsers'			=> 'Browsers (Computer programs)',
    'internet commerce'			=> 'Electronic commerce',
    'internet drugstores'		=> 'Internet pharmacies',
    'internet marketing'		=> 'Internet advertising',
    'internet pharmacies'		=> 'Internet pharmacies',
    'internet retailing'		=> 'Electronic commerce',
    'internet'				=> 'Internet',
    'internet--safety measures'		=> 'Internet--Safety measures',
    'internship programs'		=> 'Internship programs',
    'internships'			=> 'Internship programs',
    'intranets (computer networks)'	=> 'Intranets (Computer networks)',
    'intranets'				=> 'Intranets (Computer networks)',
    'intrapreneur'			=> 'Entrepreneurship',
    'investing'				=> 'Investments',
    'investment companies'		=> 'Mutual funds',
    'investment in real estate'		=> 'Real estate investment',
    'investment management'		=> 'Investments',
    'investment options'		=> 'Options (Finance)',
    'investment trusts'			=> 'Mutual funds',
    'investments'			=> 'Investments',
    'irrationalism (philosophy)'	=> 'Irrationalism (Philosophy)',
    'irrationalism'			=> 'Irrationalism (Philosophy)',
    'irrationalist (philosophy)'	=> 'Irrationalism (Philosophy)',
    'irrationalist'			=> 'Irrationalism (Philosophy)',
    'islands, imaginary'		=> 'Imaginary places',
    'isolation'				=> 'Social isolation',
    'isolation, fear of'		=> 'Agoraphobia',
    'isolation, perceptual'		=> 'Sensory deprivation',
    'it (information technology)'	=> 'Information technology',
    'jackrabbits'			=> 'Rabbits',
    'jane austen'			=> 'Austen, Jane, 1775-1817',
    'jane austen, 1775-1817'		=> 'Austen, Jane, 1775-1817',
    'java (computer program language)'	=> 'Java (Computer program language)',
    'javascript (computer program language)' => 'JavaScript (Computer program language)',
    'javascript'			=> 'JavaScript (Computer program language)',
    'jewellery'				=> 'Jewelry',
    'jewelry'				=> 'Jewelry',
    'jewels'				=> 'Jewelry',
    'jinn'				=> 'Jinn',
    'jinni'				=> 'Jinn',
    'jinns'				=> 'Jinn',
    'job hunting'			=> 'Job hunting',
    'job résumés'			=> 'Résumés (Employment)',
    'job searching'			=> 'Job hunting',
    'joblessness'			=> 'Unemployment',
    'jobs'				=> 'Occupations',
    'josh glassman'			=> 'Glassman, Josh (Fictitious character)',
    'kate daniels (fictitious character)' => 'Daniels, Kate (Fictitious character)',
    'kate daniels'			=> 'Daniels, Kate (Fictitious character)',
    'kdd (information retrieval)'	=> 'Data mining',
    'kdd'				=> 'Data mining',
    'ketogenic diet'			=> 'Ketogenic diet',
    'keyboarding'			=> 'Keyboarding',
    'kids'				=> 'Children',
    'kitchen utensils'			=> 'Kitchen utensils',
    'kitchenware'			=> 'Kitchen utensils',
    'kittens'			        => 'Kittens',
    'knowledge capital'			=> 'Intellectual capital',
    'knowledge discovery in data'	=> 'Data mining',
    'knowledge discovery in databases'	=> 'Data mining',
    'knowledge-based systems'		=> 'Expert systems (Computer science)',
    'korean war'			=> 'Korean War, 1950-1953',
    'korean war, 1950-1953'		=> 'Korean War, 1950-1953',
    'labor and laboring classes'	=> 'Labor',
    'labor'				=> 'Labor',
    'laissez faire'			=> 'Free enterprise',
    'laissez-faire'			=> 'Free enterprise',
    'latin american art'		=> 'Art, Latin American',
    'landscapes'			=> 'Landscapes',
    'landscapes in art'			=> 'Landscapes in art',
    'language and languages'		=> 'Language and languages',
    'language and languages--data processing' => 'Computational linguistics',
    'language art'			=> 'Conceptual art',
    'language art (fine arts)'		=> 'Conceptual art',
    'language data processing'		=> 'Computational linguistics',
    'languages'				=> 'Language and languages',
    'lans (computer networks)'		=> 'Local area networks (Computer networks)',
    'lans'				=> 'Local area networks (Computer networks)',
    'laser discs'			=> 'Optical disks',
    'laser disks'			=> 'Optical disks',
    'laserdiscs'			=> 'Optical disks',
    'laserdisks'			=> 'Optical disks',
    'later life (human life cycle)'	=> 'Old age',
    'latin american cooking'		=> 'Cooking, Latin American',
    'law'				=> 'Law',
    'law, business'			=> 'Commercial law',
    'law, commercial'			=> 'Commercial law',
    'laws (statutes)'			=> 'Statutes',
    'leadership coaching'		=> 'Executive coaching',
    'leadership'			=> 'Leadership',
    'legalization of illegal drugs'	=> 'Drug legalization',
    'legislative acts'			=> 'Statutes',
    'legislative enactments'		=> 'Statutes',
    'letter writing'			=> 'Letter writing',
    'letters'				=> 'Letters',
    'liability insurance'		=> 'Liability insurance',
    'liability insurance, automobile'	=> 'Automobile insurance',
    'life'				=> 'Life',
    'life after death'			=> 'Immortality',
    'life drawing'			=> 'Human figure in art',
    'life insurance'			=> 'Life insurance',
    'life on other planets'		=> 'Life on other planets',
    'linguistic science'		=> 'Linguistics',
    'linguistics'			=> 'Linguistics',
    'linguistics--data processing'	=> 'Computational linguistics',
    'liquors'				=> 'Liquors',
    'liquors--use in cooking'		=> 'Cooking (Liquors)',
    'lisp (computer program language)'	=> 'LISP (Computer program language)',
    'list processing computer language'	=> 'LISP (Computer program language)',
    'listed options'			=> 'Options (Finance)',
    'literacy'				=> 'Literacy',
    'literacy, computer'		=> 'Computer literacy',
    'literary criticism'		=> 'Criticism',
    'literature/poetry'			=> 'Poetry',
    'local area computer networks'	=> 'Local area networks (Computer networks)',
    'local area networks (computer networks)'	=> 'Local area networks (Computer networks)',
    'local area networks'		=> 'Local area networks (Computer networks)',
    'logic design'			=> 'Logic design',
    'london'				=> 'City of London (England)',
    'london, england'			=> 'City of London (England)',
    'look-ism'				=> 'Physical-appearance-based bias',
    'lookism'				=> 'Physical-appearance-based bias',
    'looks-ism'				=> 'Physical-appearance-based bias',
    'looksism'				=> 'Physical-appearance-based bias',
    'lorraine cooking'			=> 'Cooking, French--Lorraine style',
    'losing weight'			=> 'Weight loss',
    'loss of weight'			=> 'Weight loss',
    'love stories'			=> 'Love stories',
    'lovemaking'			=> 'Sex',
    'low salt diet'			=> 'Salt-free diet',
    'low sodium diet'			=> 'Salt-free diet',
    'low-carb diet'			=> 'Low-carbohydrate diet',
    'low-carbohydrate diet'		=> 'Low-carbohydrate diet',
    'low-cholesterol diet'		=> 'Low-cholesterol diet',
    'low-fat diet'			=> 'Low-fat diet',
    'low-salt diet'			=> 'Salt-free diet',
    'low-sodium diet'			=> 'Salt-free diet',
    'machine intelligence'		=> 'Artificial intelligence',
    'machine systems, virtual'		=> 'Virtual computer systems',
    'machine theory'			=> 'Machine theory',
    'machine vision'			=> 'Computer vision',
    'mac clones'			=> 'Macintosh-compatible computers',
    'mac computers'			=> 'Macintosh-compatible computers',
    'machine language'			=> 'Programming languages (Electronic computers)',
    'machine languages'			=> 'Programming languages (Electronic computers)',
    'macintosh clones'			=> 'Macintosh-compatible computers',
    'macintosh compatibles (computers)' => 'Macintosh-compatible computers',
    'macintosh compatibles'		=> 'Macintosh-compatible computers',
    'macintosh-compatible computers'	=> 'Macintosh-compatible computers',
    'macintosh computers'		=> 'Macintosh-compatible computers',
    'macroeconomics'			=> 'Macroeconomics',
    'magazines'				=> 'Periodicals',
    'magic cookies (computer science)'	=> 'Cookies (Computer science)',
    'magic'				=> 'Magic',
    'magic--fiction'			=> 'Magic',
    'magicians'				=> 'Magicians',
    'magicians--fiction'		=> 'Magicians--Fiction',
    'mail-order business'		=> 'Mail-order business',
    'mail-order houses'			=> 'Mail-order business',
    'main courses (cooking)'		=> 'Entrées (Cooking)',
    'main dishes (cooking)'		=> 'Entrées (Cooking)',
    'making bread'			=> 'Cooking (Bread)',
    'making decisions'			=> 'Decision making',
    'malevolent software'		=> 'Malware (Computer software)',
    'malicious computer code'		=> 'Malware (Computer software)',
    'malicious software'		=> 'Malware (Computer software)',
    'malignancy (cancer)'		=> 'Cancer',
    'malignant tumors'			=> 'Cancer',
    'maltreatment of children'		=> 'Child abuse',
    'malware (computer software)'	=> 'Malware (Computer software)',
    'malware'				=> 'Malware (Computer software)',
    'management coaching'		=> 'Executive coaching',
    'management decisions'		=> 'Decision making',
    'management information systems'	=> 'Management information systems',
    'management of computer memory'	=> 'Memory management (Computer science)',
    'management of conflict'		=> 'Conflict management',
    'management science'		=> 'Management science',
    'management'			=> 'Management',
    'management, industrial'		=> 'Industrial management',
    'management, sales'			=> 'Sales management',
    'managing conflict'			=> 'Conflict management',
    'manga'				=> 'Comic books, strips, etc',
    'manhua'				=> 'Comic books, strips, etc',
    'manhwa'				=> 'Comic books, strips, etc',
    'manpower utilization'		=> 'Personnel management',
    'manufacturing industries'		=> 'Manufacturing industries',
    'manufacturing management'		=> 'Production management',
    'market research'			=> 'Marketing research',
    'marketing research'		=> 'Marketing research',
    'marketing'				=> 'Marketing',
    'marketing, multilevel'		=> 'Multilevel marketing',
    'marketing--research'		=> 'Marketing research',
    'markets'				=> 'Markets',
    'markets, free'			=> 'Free enterprise',
    'markets--research'			=> 'Marketing research',
    'marksmanship'			=> 'Shooting',
    'marshall, george c. (george catlett), 1880-1959'
      => 'Marshall, George C. (George Catlett), 1880-1959',
    'mass communication'		=> 'Communication and traffic',
    'mass culture'			=> 'Popular culture',
    'mass imputation'			=> 'Statistical matching',
    'massacres'				=> 'Massacres',
    'massacres--vietnam'		=> 'Massacres--Vietnam',
    'matching, data (statistics)'	=> 'Statistical matching',
    'matching, statistical'		=> 'Statistical matching',
    'math'				=> 'Mathematics',
    'mathematical machine theory'	=> 'Machine theory',
    'mathematical machines'		=> 'Calculators',
    'mathematical programming'		=> 'Programming (Mathematics)',
    'mathematics'			=> 'Mathematics',
    'mechanical computers'		=> 'Calculators',
    'medical and health care industry'	=> 'Medical care',
    'medical and healthcare industry'	=> 'Medical care',
    'medical care planning'		=> 'Health planning',
    'medical care'			=> 'Medical care',
    'medical care, prepaid'		=> 'Health insurance',
    'medical care--planning'		=> 'Health planning',
    'medical care--social aspects'	=> 'Social medicine',
    'medical informatics'		=> 'Medical informatics',
    'medical information science'	=> 'Medical informatics',
    'medical insurance'			=> 'Health insurance',
    'medical profession'		=> 'Medicine',
    'medical services'			=> 'Medical care',
    'medical sociology'			=> 'Social medicine',
    'medical'				=> 'Medical care',
    'medicaments'			=> 'Drugs',
    'medications'			=> 'Drugs',
    'medications'			=> 'Drugs',
    'medicine (drugs)'			=> 'Drugs',
    'medicine'				=> 'Medicine',
    'medicine, social'			=> 'Social medicine',
    'medicine--social aspects'		=> 'Social medicine',
    'medicines (drugs)'			=> 'Drugs',
    'medicines'				=> 'Drugs',
    'meditation'			=> 'Meditation',
    'medium-sized business'		=> 'Small business',
    'medium-sized businesses'		=> 'Small business',
    'memorabilia'			=> 'Collectibles',
    'memory management (computer science)' => 'Memory management (Computer science)',
    'memory management'			=> 'Memory management (Computer science)',
    'mental healing'			=> 'Mental healing',
    'mental prayer'			=> 'Meditation',
    'mental telepathy'			=> 'Telepathy',
    'mercantile law'			=> 'Commercial law',
    'merchandise'			=> 'Commercial products',
    'merger of corporations'		=> 'Consolidation and merger of corporations',
    'mergers & acquisitions'		=> 'Consolidation and merger of corporations',
    'mergers and acquisitions'		=> 'Consolidation and merger of corporations',
    'mergers and acquisitions of corporations' => 'Consolidation and merger of corporations',
    'mergers of corporations'		=> 'Consolidation and merger of corporations',
    'mergers, corporate'		=> 'Consolidation and merger of corporations',
    'merging, data (Statistics)'	=> 'Statistical matching',
    'merging, data'			=> 'Statistical matching',
    'metamorphosis--folklore'		=> 'Shapeshifting',
    'micro computers'			=> 'Microcomputers',
    'micro-businesses'			=> 'Small business',
    'micro-enterprises'			=> 'Small business',
    'microbusinesses'			=> 'Small business',
    'microcomputers'			=> 'Microcomputers',
    'microeconomics'			=> 'Microeconomics',
    'microenterprises'			=> 'Small business',
    'microprocessors'			=> 'Microprocessors',
    'micros (microcomputers)'		=> 'Microcomputers',
    'microsimulation modeling (statistics)' => 'Statistical matching',
    'microwave cookery'			=> 'Microwave cooking',
    'microwave cooking'			=> 'Microwave cooking',
    'mid-atlantic states'		=> 'Middle Atlantic States',
    'middle atlantic region'		=> 'Middle Atlantic States',
    'middle atlantic states'		=> 'Middle Atlantic States',
    'middle colonies'			=> 'Middle Atlantic States',
    'middle states'			=> 'Middle Atlantic States',
    'middle-atlantic states'		=> 'Middle Atlantic States',
    'midwestern cooking'		=> 'Cooking, American--Midwestern style',
    'military biography'		=> 'Military biography',
    'military history'			=> 'History, Military',
    'mind reading'			=> 'Telepathy',
    'mind-cure'				=> 'Mental healing',
    'mind-distorting drugs'		=> 'Hallucinogenic drugs',
    'mind-reading'			=> 'Telepathy',
    'mindreading'			=> 'Telepathy',
    'mining data'			=> 'Data mining',
    'mining, data'			=> 'Data mining',
    'mixed media (art)'			=> 'Mixed media (Art)',
    'mixed media crafts'		=> 'Mixed media (Art)',
    'mixology'				=> 'Bartending',
    'mobile computing'			=> 'Mobile computing',
    'modeling, computer'		=> 'Computer simulation',
    'modeling, microsimulation (statistics)' => 'Statistical matching',
    'models, computer'			=> 'Computer simulation',
    'modems'				=> 'Modems',
    'modern & contemporary fiction (post c 1945)' => 'Fiction--1945-',
    'modern art'			=> 'Art, Modern',
    'modula-2 (computer program language)' => 'Modula-2 (Computer program language)',
    'modula-2'				=> 'Modula-2 (Computer program language)',
    'molesting children'		=> 'Child sexual abuse',
    'molesting of children'		=> 'Child sexual abuse',
    'monetary management'		=> 'Monetary policy',
    'monetary policy'			=> 'Monetary policy',
    'money'				=> 'Money',
    'monitoring, election'		=> 'Election monitoring',
    'mongolians'			=> 'Mongols',
    'mongols'				=> 'Mongols',
    'mongols--fiction'			=> 'Mongols--Fiction',
    'mongols--history'			=> 'Mongols--History',
    'monitoring, environmental'		=> 'Environmental monitoring',
    'moral philosophy'			=> 'Ethics',
    'morality'				=> 'Ethics',
    'morals'				=> 'Ethics',
    'mortgages'				=> 'Mortgages',
    'motivational speakers'		=> 'Motivational speakers',
    'motorcars (automobiles)'		=> 'Automobiles',
    'motorcars'				=> 'Automobiles',
    'mount sneffels wilderness (colo.)' => 'Mount Sneffels Wilderness (Colo.)',
    'mourning'				=> 'Grief',
    'mui tsai'				=> 'Slavery',
    'multilevel distributorship'	=> 'Multilevel marketing',
    'multilevel marketing'		=> 'Multilevel marketing',
    'multilevel sales companies'	=> 'Multilevel marketing',
    'multinational corporations'	=> 'International business enterprises',
    'multinational enterprises'		=> 'International business enterprises',
    'municipalities'			=> 'Cities and towns',
    'murder'				=> 'Murder',
    'murder mystery'			=> 'Mystery and detective stories',
    'museology'				=> 'Museum techniques',
    'museum administration'		=> 'Museum techniques',
    'museum techniques'			=> 'Museum techniques',
    'museums'				=> 'Museums',
    'museums--technique'		=> 'Museum techniques',
    'musical instruments'		=> 'Musical instruments',
    'mutual funds'			=> 'Mutual funds',
    'mutual insurance'			=> 'Insurance',
    'mystery and detective stories'	=> 'Mystery and detective stories',
    'mystery'				=> 'Mystery and detective stories',
    'mystical theology'			=> 'Mysticism',
    'mysticism'				=> 'Mysticism',
    'mythology, greek'			=> 'Mythology, Greek',
    'national resources'		=> 'Natural resources',
    'natural language processing'	=> 'Computational linguistics',
    'natural resources'			=> 'Natural resources',
    'natural science'			=> 'Science',
    'naval tactics'			=> 'Naval tactics',
    'navigators'			=> 'Explorers',
    'near-death experiences'		=> 'Near-death experiences',
    'negotiating'			=> 'Negotiation',
    'negotiation'			=> 'Negotiation',
    'negotiations'			=> 'Negotiation',
    'neglect of children'		=> 'Child abuse',
    'negro art'				=> 'African American art',
    'netcasting'			=> 'Webcasting',
    'nets, neural (computer science)'	=> 'Neural networks (Computer science)',
    'nets, neural (neurobiology)'	=> 'Neural networks (Neurobiology)',
    'network marketing'			=> 'Multilevel marketing',
    'network security'			=> 'Computer networks--Security measures',
    'network security, computer'	=> 'Computer networks--Security measures',
    'networks, computer'		=> 'Computer networks',
    'networks, neural (computer science)' => 'Neural networks (Computer science)',
    'networks, neural (neurobiology)'	=> 'Neural networks (Neurobiology)',
    'neural nets (computer science)'	=> 'Neural networks (Computer science)',
    'neural nets (neurobiology)'	=> 'Neural networks (Neurobiology)',
    'neural networks (computer science)' => 'Neural networks (Computer science)',
    'neural networks (neurobiology)'	=> 'Neural networks (Neurobiology)',
    'new business enterprises'		=> 'New business enterprises',
    'new companies'			=> 'New business enterprises',
    'new england cooking'		=> 'Cooking, American--New England style',
    'new thought'			=> 'New Thought',
    'newspapers'			=> 'Newspapers',
    'non-alcoholic beverages'		=> 'Non-alcoholic beverages',
    'non-alcoholic drinks'		=> 'Non-alcoholic beverages',
    'non-profit organizations'		=> 'Nonprofit organizations',
    'non-profit sector'			=> 'Nonprofit organizations',
    'non-profits'			=> 'Nonprofit organizations',
    'non-resistance to government'	=> 'Government, Resistance to',
    'nonprofit organizations'		=> 'Nonprofit organizations',
    'nonprofit sector'			=> 'Nonprofit organizations',
    'nonprofits'			=> 'Nonprofit organizations',
    'norman cooking'			=> 'Cooking, French--Normandy style',
    'normandy cooking'			=> 'Cooking, French--Normandy style',
    'northwestern states'		=> 'Northwestern States',
    'northwestern united states'	=> 'Northwestern States',
    'not-for-profit organizations'	=> 'Nonprofit organizations',
    'npos'				=> 'Nonprofit organizations',
    'numerology'			=> 'Numerology',
    'nutrition',			=> 'Nutrition',
    'nutrition--health aspects',	=> 'Nutrition',
    'oacet (imaginary organization)'	=> 'OACET (Imaginary organization)',
    'oacet'		 		=> 'OACET (Imaginary organization)',
    'obe (parapsychology)'		=> 'Astral projection',
    'obesity'				=> 'Obesity',
    'obesity--control'			=> 'Weight loss',
    'obesity--etiology'			=> 'Obesity--Etiology',
    'object-oriented programming (computer science)' => 'Object-oriented programming (Computer science)',
    'object-oriented programming'	=> 'Object-oriented programming (Computer science)',
    'objective c'			=> 'Objective-C (Computer program language)',
    'objective-c (Computer program language)'	=> 'Objective-C (Computer program language)',
    'objective-c'			=> 'Objective-C (Computer program language)',
    'objects, art'			=> 'Art objects',
    "objets d'art"			=> 'Art objects',
    'occultism'				=> 'Occultism',
    'occupations'			=> 'Occupations',
    'office administration'		=> 'Office management',
    'office automation'			=> 'Office practice--Automation',
    'office equipment and supplies'	=> 'Office equipment and supplies',
    'office equipment'			=> 'Office equipment and supplies',
    'office etiquette'			=> 'Business etiquette',
    'office machines'			=> 'Office equipment and supplies',
    'office management'			=> 'Office management',
    'office practice--automation'	=> 'Office practice--Automation',
    'office products'			=> 'Office equipment and supplies',
    'office supplies'			=> 'Office equipment and supplies',
    'office systems'			=> 'Office equipment and supplies',
    'oil painting'			=> 'Painting',
    'old age'				=> 'Old age',
    'on-line information services'	=> 'Online information services',
    'online auctions'			=> 'Internet auctions',
    'online commerce'			=> 'Electronic commerce',
    'online information services'	=> 'Online information services',
    'online investing'			=> 'Electronic trading of securities',
    'online publishing'			=> 'Electronic publishing',
    'online services (information services)'	=> 'Online information services',
    'online social networks'		=> 'Online social networks',
    'online trading'			=> 'Electronic trading of securities',
    'online trading of securities'	=> 'Electronic trading of securities',
    'open spaces'			=> 'Open spaces',
    'open spaces, fear of'		=> 'Agoraphobia',
    'open-end mutual funds'		=> 'Mutual funds',
    'operational analysis'		=> 'Operations research',
    'operational research'		=> 'Operations research',
    'operations management'		=> 'Production management',
    'operations research'		=> 'Operations research',
    'operating systems (computers)'	=> 'Operating systems (Computers)',
    'operating systems'			=> 'Operating systems (Computers)',
    'operators, tour (industry)'	=> 'Tourism',
    'operators, tour'			=> 'Tourism',
    'optical computing'			=> 'Optical data processing',
    'optical data processing'		=> 'Optical data processing',
    'optical discs'			=> 'Optical disks',
    'optical disks'			=> 'Optical disks',
    'optical illusions'			=> 'Optical illusions',
    'options (finance)'			=> 'Options (Finance)',
    'options exchange'			=> 'Options (Finance)',
    'options market'			=> 'Options (Finance)',
    'options trading'			=> 'Options (Finance)',
    'ordnance'				=> 'Ordnance',
    'organization development'		=> 'Organizational change',
    'organizational behavior'		=> 'Organizational behavior',
    'organizational change'		=> 'Organizational change',
    'organizational development'	=> 'Organizational change',
    'organizational innovation'		=> 'Organizational change',
    'organizations, business'		=> 'Business enterprises',
    'organizations, nonprofit'		=> 'Nonprofit organizations',
    'oriental art'			=> 'Art, Asian',
    'oriental cooking'			=> 'Cooking, Asian',
    'out-of-body experiences'		=> 'Astral projection',
    'outdoor cookery'			=> 'Outdoor cooking',
    'outdoor cooking'			=> 'Outdoor cooking',
    'outsourcing'			=> 'Contracting out',
    'overseas marketing'		=> 'Export marketing',
    'ownership of slaves'		=> 'Slavery',
    'pad computers'			=> 'Tablet computers',
    'pages, web'			=> 'Web sites',
    'painting'				=> 'Painting',
    'painting, primitive'		=> 'Painting',
    'painting--technique'		=> 'Painting--Technique',
    'paintings'				=> 'Painting',
    'palm reading'			=> 'Palmistry',
    'palmistry'				=> 'Palmistry',
    'palmreading'			=> 'Palmistry',
    'papooses'				=> 'Infants',
    'parallel programming (computer science)' => 'Parallel programming (Computer science)',
    'parallel programming'		=> 'Parallel programming (Computer science)',
    'paranormal'			=> 'Paranormal fiction',
    'paranormal fiction'		=> 'Paranormal fiction',
    'paranormal phenomena'		=> 'Parapsychology',
    'paraphernalia, political'		=> 'Political collectibles',
    'parapsychology'			=> 'Parapsychology',
    'park administration'		=> 'Parks--Management',
    'park management'			=> 'Parks--Management',
    'parklands'				=> 'Parks',
    'parks'				=> 'Parks',
    'parks--management'			=> 'Parks--Management',
    'parody'				=> 'Parody',
    'pascal (computer program language)' => 'Pascal (Computer program language)',
    'pastel drawing'			=> 'Pastel drawing',
    'pastel drawing--technique'		=> 'Pastel drawing--Technique',
    'pastel painting'			=> 'Pastel drawing',
    'pastels'				=> 'Pastel drawing',
    'pastry'				=> 'Pastry',
    'pathfinder (game)'			=> 'Pathfinder (Game)',
    'pathfinder game'			=> 'Pathfinder (Game)',
    'pathfinder novel'			=> 'Pathfinder (Game)',
    'pathfinder roleplaying game'	=> 'Pathfinder (Game)',
    'pathfinder story'			=> 'Pathfinder (Game)',
    'pathologically eclectic rubbish lister'	=> 'Perl (Computer program language)',
    'pattern classification systems'	=> 'Pattern recognition systems',
    'pattern recognition computers'	=> 'Pattern recognition systems',
    'pattern recognition systems'	=> 'Pattern recognition systems',
    'pcs (microcomputers)'		=> 'Microcomputers',
    'pcs'				=> 'Microcomputers',
    'peasant art'			=> 'Folk art',
    'pedagogy'				=> 'Education',
    'pedology (child study)'		=> 'Children',
    'pen drawing'			=> 'Pen drawing',
    'pen drawing--technique'		=> 'Pen drawing--Technique',
    'pen and ink drawing'		=> 'Pen drawing',
    'pencil drawing'			=> 'Pencil drawing',
    'pencil drawing--technique'		=> 'Pencil drawing--Technique',
    'peng, rachel (fictitious character)' => 'Peng, Rachel (Fictitious character)',
    'peng, rachel'			=> 'Peng, Rachel (Fictitious character)',
    'perceptual isolation'		=> 'Sensory deprivation',
    'performance art'			=> 'Performance art',
    'performance motivation'		=> 'Achievement motivation',
    'performance pieces'		=> 'Performance art',
    'periodicals'			=> 'Periodicals',
    'peripheral computer devices'	=> 'Computer peripherals',
    'peripheral computer equipment'	=> 'Computer peripherals',
    'peripheral devices (computers)'	=> 'Computer peripherals',
    'peripheral equipment (computers)'	=> 'Computer peripherals',
    'peripherals, computer'		=> 'Computer peripherals',
    'perl (computer program language)'	=> 'Perl (Computer program language)',
    'perl'				=> 'Perl (Computer program language)',
    'perl/tk (computer program language)' => 'Perl/Tk (Computer program language)',
    'perl/tk'				=> 'Perl/Tk (Computer program language)',
    'persian gulf war, 1991'		=> 'Persian Gulf War, 1991',
    'persistent cookies (computer science)'	=> 'Cookies (Computer science)',
    'persistent cookies'		=> 'Cookies (Computer science)',
    'personal body care'		=> 'Hygiene',
    'personal budgets'			=> 'Budgets, Personal',
    'personal cleanliness'		=> 'Hygiene',
    'personal computers'		=> 'Microcomputers',
    'personal finance software'		=> 'Finance, Personal--Software',
    'personal finance'			=> 'Finance, Personal',
    'personal financial management'	=> 'Finance, Personal',
    'personal financial planning'	=> 'Finance, Personal',
    'personal health services'		=> 'Medical care',
    'personal hygiene'			=> 'Hygiene',
    'personal identity'			=> 'Personality',
    'personal income tax'		=> 'Income tax',
    'personal time management'		=> 'Time management',
    'personality'			=> 'Personality',
    'personality traits'		=> 'Personality',
    'personification of death'		=> 'Death (Personification)',
    'personnel administration'		=> 'Personnel management',
    'personnel management'		=> 'Personnel management',
    'personology'			=> 'Personality',
    'pharmaceuticals'			=> 'Drugs',
    'philosophers'			=> 'Philosophers',
    'philosophers--biography'		=> 'Philosophers--Biography',
    'philosophy, moral'			=> 'Ethics',
    'php (computer program language)'	=> 'PHP (Computer program language)',
    'php'				=> 'PHP (Computer program language)',
    'physical endurance'		=> 'Physical fitness',
    'physical fitness'			=> 'Physical fitness',
    'physical stamina'			=> 'Physical fitness',
    'physical-appearance-based bias'	=> 'Physical-appearance-based bias',
    'physique'				=> 'Bodybuilding',
    'pickling'				=> 'Canning and preserving',
    'pictorial data processing'		=> 'Image processing',
    'picture processing'		=> 'Image processing',
    'pies'				=> 'Pies',
    'pies, pizza'			=> 'Pizza',
    'pizza pies'			=> 'Pizza',
    'pizza'				=> 'Pizza',
    'pizzas'				=> 'Pizza',
    'pl/c (computer program language)'	=> 'PL/C (Computer program language)',
    'pl/c'				=> 'PL/C (Computer program language)',
    'pl/sql (computer program language)' => 'PL/SQL (Computer program language)',
    'pl/sql'				=> 'PL/SQL (Computer program language)',
    'places, imaginary'			=> 'Imaginary places',
    'planning'				=> 'Planning',
    'planning, strategic'		=> 'Strategic planning',
    'plants in art'			=> 'Plants in art',
    'plants, psychoactive'		=> 'Psychotropic plants',
    'plants, psychotropic'		=> 'Psychotropic plants',
    'pocket calculators'		=> 'Calculators',
    'poems'				=> 'Poetry',
    'poetry'				=> 'Poetry',
    'police'			        => 'Police',
    'police--england'			=> 'Police--England',
    'police--england--london'		=> 'Police--England--London',
    'police--england--london--fiction'	=> 'Police--England--London--Fiction',
    'political collectibles'		=> 'Political collectibles',
    'political ethics'			=> 'Political ethics',
    'political paraphernalia'		=> 'Political collectibles',
    'political science--moral and ethical aspects' => 'Political ethics',
    'political terrorism'		=> 'Terrorism',
    'politics and culture'		=> 'Politics and culture',
    'politics and culture--united states' => 'Politics and culture--United States',
    'politics in art'			=> 'Politics in art',
    'politics, practical'		=> 'Politics, Practical',
    'politics, practical--moral and ethical aspects' => 'Political ethics',
    'poll watching'			=> 'Election monitoring',
    'pop culture'			=> 'Popular culture',
    'popular arts'			=> 'Popular culture',
    'popular culture'			=> 'Popular culture',
    'portraits'				=> 'Portraits',
    'possible art'			=> 'Conceptual art',
    'post-object art'			=> 'Conceptual art',
    'potable liquids'			=> 'Beverages',
    'potable water'			=> 'Drinking water',
    'potables'				=> 'Beverages',
    'pottery'				=> 'Pottery',
    'pottery, primitive'		=> 'Pottery',
    'poverty'				=> 'Poverty',
    'pr'				=> 'Public relations',
    'practical extraction and report language'	=> 'Perl (Computer program language)',
    'practical politics'		=> 'Politics, Practical',
    'prayer, mental'			=> 'Meditation',
    'precog'				=> 'Precognition',
    'precognition'			=> 'Precognition',
    'prepaid health plans'		=> 'Health insurance',
    'prepaid medical care'		=> 'Health insurance',
    'prescription drugs'		=> 'Drugs',
    'presentation graphics software'	=> 'Presentation graphics software',
    'presentation software'		=> 'Presentation graphics software',
    'preservation of art objects'       => 'Art objects--Conservation and restoration',
    'price theory'			=> 'Microeconomics',
    'princesses'			=> 'Princesses',
    'print making'			=> 'Prints--Technique',
    'printmaking'			=> 'Prints--Technique',
    'prints'				=> 'Prints',
    'prints--technique'			=> 'Prints--Technique',
    'privacy'				=> 'Privacy',
    'private enterprise'		=> 'Free enterprise',
    'procedural language/sql'		=> 'PL/SQL (Computer program language)',
    'processing, image'			=> 'Image processing',
    'processing, word'			=> 'Word processing',
    'processing, words'			=> 'Word processing',
    'produce exchanges'			=> 'Commodity exchanges',
    'product design'			=> 'Product design',
    'production management'		=> 'Production management',
    'products, commercial'		=> 'Commercial products',
    'professions'			=> 'Occupations',
    'profit-sharing trusts'		=> 'Mutual funds',
    'programming (electronic computers)' => 'Computer programming',
    'programming (mathematics)'		=> 'Programming (Mathematics)',
    'programming languages (computers)' => 'Programming languages (Electronic computers)',
    'programming languages (electronic computers)' => 'Programming languages (Electronic computers)',
    'programming languages'		=> 'Programming languages (Electronic computers)',
    'programming search engines'	=> 'Search engines--Programming',
    'programming'			=> 'Computer programming',
    'project management software'	=> 'Project management--Software',
    'project management'		=> 'Project management',
    'project management--software'	=> 'Project management--Software',
    'projection, astral'		=> 'Astral projection',
    'prolog (computer program language)' => 'Prolog (Computer program language)',
    'prolog'				=> 'Prolog (Computer program language)',
    'prolog++ (computer program language)' => 'Prolog++ (Computer program language)',
    'prolog++'				=> 'Prolog++ (Computer program language)',
    'property insurance'		=> 'Property insurance',
    'prophecy'				=> 'Prophecy',
    'prose poems'			=> 'Prose poems',
    'prose poetry'			=> 'Prose poems',
    'prostitution'			=> 'Prostitution',
    'protocols, computer network'	=> 'Computer network protocols',
    'provencal cooking'			=> 'Cooking, French--Provençal style',
    'provençal cooking'			=> 'Cooking, French--Provençal style',
    'provincial parks'			=> 'Parks',
    'psychedelic drugs'			=> 'Hallucinogenic drugs',
    'psychic healing'			=> 'Mental healing',
    'psychic phenomena'			=> 'Parapsychology',
    'psychic research'			=> 'Parapsychology',
    'psychical research'		=> 'Parapsychology',
    'psycho-kinesis'			=> 'Psychokinesis',
    'psychoactive plants'		=> 'Psychotropic plants',
    'psychokinesis'			=> 'Psychokinesis',
    'psychology'			=> 'Psychology',
    'psychology, cognitive'		=> 'Cognitive psychology',
    'psychotomimetic drugs'		=> 'Hallucinogenic drugs',
    'psychotropic plants'		=> 'Psychotropic plants',
    'public finance'			=> 'Finance, Public',
    'public health services'		=> 'Public health',
    'public health'			=> 'Public health',
    'public health--planning'		=> 'Health planning',
    'public hygiene'			=> 'Public health',
    'public markets'			=> 'Markets',
    'public relations'			=> 'Public relations',
    'public transportation'		=> 'Transportation',
    'punctuation'			=> 'Punctuation',
    'purchasing and buying'		=> 'Purchasing',
    'purchasing'			=> 'Purchasing',
    'purchasing--law and legislation'	=> 'Sales',
    'purchasing--law'			=> 'Sales',
    'put and call transactions'		=> 'Options (Finance)',
    'put options'			=> 'Options (Finance)',
    'puts (finance)'			=> 'Options (Finance)',
    'pyramid marketing'			=> 'Multilevel marketing',
    'pyramid sales clubs'		=> 'Multilevel marketing',
    'python (computer program language)' => 'Python (Computer program language)',
    'python'				=> 'Python (Computer program language)',
    'pythonidae'			=> 'Pythons',
    'pythoninae'			=> 'Pythons',
    'pythons'				=> 'Pythons',
    'q-boats'				=> 'Q-ships',
    'q-ships'				=> 'Q-ships',
    'quality assurance'			=> 'Quality assurance',
    'quality control'			=> 'Quality control',
    'quality management, total'		=> 'Total quality management',
    'quality of environment'		=> 'Environmental quality',
    'quantitative business analysis'	=> 'Management science',
    'quantity cookery'			=> 'Quantity cooking',
    'quantity cooking'			=> 'Quantity cooking',
    'quick and easy cookery'		=> 'Quick and easy cooking',
    'quick and easy cooking'		=> 'Quick and easy cooking',
    'quick-meal cookery'		=> 'Quick and easy cooking',
    'quick-meal cooking'		=> 'Quick and easy cooking',
    'r & d projects'			=> 'Research and development projects',
    'r & d'				=> 'Research and development projects',
    'r and d projects'			=> 'Research and development projects',
    'r&d projects'			=> 'Research and development projects',
    'r&d'				=> 'Research and development projects',
    'rabbits'				=> 'Rabbits',
    'rachel peng'			=> 'Peng, Rachel (Fictitious character)',
    'radio vision'			=> 'Television',
    'rationalization of industry'	=> 'Industrial management',
    'raw food'				=> 'Raw foods',
    'raw foods'				=> 'Raw foods',
    'real estate investment'		=> 'Real estate investment',
    'real estate'			=> 'Real property',
    'real property investment'		=> 'Real estate investment',
    'real property'			=> 'Real property',
    'reducing diets'			=> 'Reducing diets',
    'reduction of weight'		=> 'Weight loss',
    'realty'				=> 'Real property',
    'recreational shooting'		=> 'Shooting',
    'regional economics'		=> 'Regional economics',
    'regional parks'			=> 'Parks',
    'reicki (healing system)'		=> 'Reiki (Healing system)',
    'reicki'				=> 'Reiki (Healing system)',
    'reiki (healing system)'		=> 'Reiki (Healing system)',
    'reiki'				=> 'Reiki (Healing system)',
    'reincarnation'			=> 'Reincarnation',
    'religion and politics'		=> 'Religion and politics',
    'religion and politics--united states' => 'Religion and politics--United States',
    'religion and social problems'	=> 'Religion and social problems',
    'religious art'			=> 'Religious art',
    'religious corporations'		=> 'Corporations, Religious',
    'report program generator'		=> 'RPG (Computer program language)',
    'research & development projects'	=> 'Research and development projects',
    'research and development projects'	=> 'Research and development projects',
    'resistance to government'		=> 'Government, Resistance to',
    'resources, natural'		=> 'Natural resources',
    'restoration of art objects'	=> 'Art objects--Conservation and restoration',
    'resumes'				=> 'Résumés (Employment)',
    'resumes (employment)'		=> 'Résumés (Employment)',
    'résumés'				=> 'Résumés (Employment)',
    'résumés (employment)'		=> 'Résumés (Employment)',
    'retail industry'			=> 'Retail trade',
    'retail marketing'			=> 'Marketing',
    'retail trade'			=> 'Retail trade',
    'retail trade--marketing'		=> 'Marketing',
    'retail franchises'			=> 'Franchises (Retail trade)',
    'retailing'				=> 'Retail trade',
    'retirement planning'		=> 'Retirement--Planning',
    "rights of women"			=> "Women's rights",
    'retirement'			=> 'Retirement',
    'retirement--planning'		=> 'Retirement--Planning',
    'ridgway reservoir (colo.)'  	=> 'Ridgway Reservoir (Colo.)',
    'ridgway'				=> 'Ridgway Reservoir (Colo.)',
    'right and left (political science)' => 'Right and left (Political science)',
    'rights, civil'			=> 'Civil rights',
    'risk (insurance)'			=> 'Risk (Insurance)',
    'risk'				=> 'Risk',
    'rivers'				=> 'Rivers',
    'rivers--england'			=> 'Rivers--England',
    'romance'				=> 'Love stories',
    'routines, utility'			=> 'Utilities (Computer programs)',
    'rpg (computer program language)'	=> 'RPG (Computer program language)',
    'rubies'				=> 'Rubies',
    'ruby (computer program language)'	=> 'Ruby (Computer program language)',
    'rulers'				=> 'Heads of state',
    'russian art'			=> 'Art, Russian',
    'safety measures'			=> 'Safety measures',
    'salads'				=> 'Salads',
    'sales management'			=> 'Sales management',
    'sales'				=> 'Sales',
    'sales--law and legislation'	=> 'Sales',
    'sales--law'			=> 'Sales',
    'salesmanship'			=> 'Selling',
    'salesmen and salesmanship'		=> 'Selling',
    'salt-free diet'			=> 'Salt-free diet',
    'sam vimes (fictitious character)'	=> 'Vimes, Samuel (Fictitious character)',
    'samuel vimes (fictitious character)'	=> 'Vimes, Samuel (Fictitious character)',
    'sanitary affairs'			=> 'Public health',
    'satire'				=> 'Satire',
    'sauces'				=> 'Sauces',
    'schleswig-holstein cooking'	=> 'Cooking, German--Schleswig-Holstein style',
    'schooling'				=> 'Education',
    'sci fi'	 			=> 'Science fiction',
    'sci-fi'	 			=> 'Science fiction',
    'sci/fi'	 			=> 'Science fiction',
    'science fiction & fantasy'		=> 'Speculative fiction',
    'science fiction and fantasy'	=> 'Speculative fiction',
    'science fiction' 			=> 'Science fiction',
    'science fiction--authorship'	=> 'Science fiction--Authorship',
    'science fiction--general'		=> 'Science fiction',
    'science fiction--high tech'	=> 'High technology',
    'science fiction--technique'	=> 'Science fiction--Technique',
    'science fiction/fantasy'		=> 'Speculative fiction',
    'science of language'		=> 'Linguistics',
    'science of science'		=> 'Science',
    'science stories'			=> 'Science fiction',
    'science'				=> 'Science',
    'science, moral'			=> 'Ethics',
    'science--authorship'		=> 'Technical writing',
    'science--fiction'			=> 'Science fiction',
    'sciences'				=> 'Science',
    'scientific writing'		=> 'Technical writing',
    'scifi'	 			=> 'Science fiction',
    'scotland'				=> 'Scotland',
    'scottish cooking'			=> 'Cooking, Scottish',
    'screen trading (securities)'	=> 'Electronic trading of securities',
    'screen trading'			=> 'Electronic trading of securities',
    'sculpting'				=> 'Sculpture--Technique',
    'sculpture'				=> 'Sculpture',
    'sculpture--technique'		=> 'Sculpture--Technique',
    'search agents'			=> 'Search engines',
    'search engines'			=> 'Search engines',
    'search engines, web'		=> 'Web search engines',
    'search engines--programming'	=> 'Search engines--Programming',
    'second sight'			=> 'Precognition',
    'second world war'			=> 'World War, 1939-1945',
    'secret writing'			=> 'Cryptography',
    'secretarial aids & training'	=> 'Secretaries--Training',
    'secretarial aids and training'	=> 'Secretaries--Training',
    'secretaries'			=> 'Secretaries',
    'secretaries--training'		=> 'Secretaries--Training',
    'security of computer systems'	=> 'Computer security',
    'security of computer networks'	=> 'Computer networks--Security measures',
    'self-improvement'			=> 'Success',
    'selling homes'			=> 'House selling',
    'selling houses'			=> 'House selling',
    'selling'				=> 'Selling',
    'selling--law and legislation'	=> 'Sales',
    'selling--law'			=> 'Sales',
    'sensory deprivation therapy'	=> 'Sensory deprivation--Therapeutic use',
    'sensory deprivation'		=> 'Sensory deprivation',
    'sensory deprivation--therapeutic use' => 'Sensory deprivation--Therapeutic use',
    'sensory isolation'			=> 'Sensory deprivation',
    'seraphim'				=> 'Angels',
    'serial picture books'		=> 'Comic books, strips, etc',
    'service industries'		=> 'Service industries',
    'services, contracting for'		=> 'Contracting out',
    'services, financial'		=> 'Financial services industry',
    'sex'				=> 'Sex',
    'sex--religious aspects'		=> 'Sex--Religious aspects',
    'sexual abuse of children'		=> 'Child sexual abuse',
    'sexual behavior'			=> 'Sex',
    'sexual child abuse'		=> 'Child sexual abuse',
    'sexual practices'			=> 'Sex',
    'sexuality'				=> 'Sex',
    'shamanism'				=> 'Shamanism',
    'shape-shifters'			=> 'Shapeshifting',
    'shape-shifting'			=> 'Shapeshifting',
    'shapeshifters'			=> 'Shapeshifting',
    'shapeshifting'			=> 'Shapeshifting',
    'shapeshifting--fiction'		=> 'Shapeshifting',
    'shares of stock'			=> 'Stocks',
    'shooting sport'			=> 'Shooting',
    'shooting sports'			=> 'Shooting',
    'shooting'				=> 'Shooting',
    'short stories'			=> 'Short stories',
    'sickness insurance'		=> 'Health insurance',
    'simulation, computer'		=> 'Computer simulation',
    'sisters'				=> 'Sisters',
    'sisters--fiction'			=> 'Sisters--Fiction',
    'sites, web'			=> 'Web sites',
    'sixth sense'			=> 'Extrasensory perception',
    'sizeism'				=> 'Physical-appearance-based bias',
    'sizism'				=> 'Physical-appearance-based bias',
    'skills training'			=> 'Training',
    'slate computers'			=> 'Tablet computers',
    'slave holders'			=> 'Slaveholders',
    'slave keeping'			=> 'Slavery',
    'slave master'			=> 'Slaveholders',
    'slave masters'			=> 'Slaveholders',
    'slave owner'			=> 'Slaveholders',
    'slave owners'			=> 'Slaveholders',
    'slave ownership'			=> 'Slavery',
    'slave system'			=> 'Slavery',
    'slaveholders'			=> 'Slaveholders',
    'slaveholding'			=> 'Slavery',
    'slavemasters'			=> 'Slaveholders',
    'slaveowners'			=> 'Slaveholders',
    'slavery'				=> 'Slavery',
    'sleep deprivation'			=> 'Sleep deprivation',
    'sleep'				=> 'Sleep',
    'sleeping'				=> 'Sleep',
    'slimming'				=> 'Weight loss',
    'slumber'				=> 'Sleep',
    'small and medium-sized business'	=> 'Small business',
    'small and medium-sized businesses'	=> 'Small business',
    'small and medium-sized enterprise'	=> 'Small business',
    'small and medium-sized enterprises' => 'Small business',
    'small arms'			=> 'Firearms',
    'small business tax'		=> 'Small business--Taxation',
    'small business taxation'		=> 'Small business--Taxation',
    'small business taxes'		=> 'Small business--Taxation',
    'small business'			=> 'Small business',
    'small business--Taxation'		=> 'Small business--Taxation',
    'small businesses'			=> 'Small business',
    'smalltalk (computer program language)' => 'Smalltalk (Computer program language)',
    'smart growth'			=> 'Sustainable development',
    'sneffels' 				=> 'Mount Sneffels Wilderness (Colo.)',
    'social action'			=> 'Social action',
    'social action--research'		=> 'Action research',
    'social action--religious aspects'	=> 'Religion and social problems',
    'social classes'			=> 'Social classes',
    'social classes--fiction'		=> 'Social classes--Fiction',
    'social exclusion'			=> 'Social isolation',
    'social hygiene'			=> 'Public health',
    'social infrastructure'		=> 'Infrastructure (Economics)',
    'social isolation'			=> 'Social isolation',
    'social medicine'			=> 'Social medicine',
    'social networking web sites'	=> 'Online social networks',
    'social networking'			=> 'Social networks',
    'social networks'			=> 'Social networks',
    'social overhead capital'		=> 'Infrastructure (Economics)',
    'social problems and religion'	=> 'Religion and social problems',
    'social support systems'		=> 'Social networks',
    'socioeconomic status'		=> 'Economic conditions',
    'sodium-restricted diet'		=> 'Salt-free diet',
    'software development'		=> 'Computer software--Development',
    'software engineering'		=> 'Software engineering',
    'software engineering--project management' => 'Software engineering--Project management',
    'software'				=> 'Computer software',
    'software, computer'		=> 'Computer software',
    'software, malevolent'		=> 'Malware (Computer software)',
    'software, malicious'		=> 'Malware (Computer software)',
    'soho (london, england)'		=> 'Soho (London, England)',
    'soothsaying'			=> 'Soothsaying',
    'sorcerers'				=> 'Wizards',
    'sorrow'				=> 'Grief',
    'soup'				=> 'Soups',
    'soups'				=> 'Soups',
    'south german cooking'		=> 'Cooking, German--Southern style',
    'southern cooking (united states)'	=> 'Cooking, American--Southern style',
    'southern cooking (germany)'	=> 'Cooking, German--Southern style',
    'southwestern cooking (united states)'	=> 'Cooking, American--Southwestern style',
    'space colonies'			=> 'Space colonies',
    'space opera'			=> 'Speculative fiction',
    'space rockets'			=> 'Space vehicles',
    'space ships'			=> 'Space vehicles',
    'space vehicles'			=> 'Space vehicles',
    'spacecraft'			=> 'Space vehicles',
    'spaceships'			=> 'Space vehicles',
    'spam (electronic mail)'		=> 'Spam (Electronic mail)',
    'spam'				=> 'Spam (Electronic mail)',
    'specfic'				=> 'Speculative fiction',
    'specie'				=> 'Coins',
    'speculative fantasy'		=> 'Speculative fiction',
    'speculative fiction'		=> 'Speculative fiction',
    'speech processing systems'		=> 'Speech processing systems',
    'speech processing'			=> 'Speech processing systems',
    'spices--use in cooking'		=> 'Cooking (Spices)',
    'spies'     			=> 'Spy stories',
    'spirit channeling'			=> 'Channeling (Spiritualism)',
    'spirit guides'			=> 'Guides (Spiritualism)',
    'spiritism'				=> 'Spiritualism',
    'spirits, alcoholic'		=> 'Liquors',
    'spiritual healing'			=> 'Spiritual healing',
    'spiritual therapies'		=> 'Spiritual healing',
    'spiritual-mindedness'		=> 'Spirituality',
    'spiritualism'			=> 'Spiritualism',
    'spirituality'			=> 'Spirituality',
    'spirituous liquors'		=> 'Liquors',
    'sport shooting'			=> 'Shooting',
    'sports stories'			=> 'Sports stories',
    'sports'				=> 'Sports',
    'sports--fiction'			=> 'Sports stories',
    'sports--juvenile fiction'		=> 'Sports stories',
    'spread sheets'			=> 'Electronic spreadsheets',
    'spread sheets, electronic'		=> 'Electronic spreadsheets',
    'spreadsheet software'		=> 'Electronic spreadsheets--Software',
    'spreadsheeting, electronic'	=> 'Electronic spreadsheets',
    'spreadsheets'			=> 'Electronic spreadsheets',
    'spreadsheets, electronic'		=> 'Electronic spreadsheets',
    'spy stories'     			=> 'Spy stories',
    'sql (computer program language)'	=> 'SQL (Computer program language)',
    'sql'				=> 'SQL (Computer program language)',
    'standard of value'			=> 'Money',
    'star trek fiction'			=> 'Star Trek fiction',
    'star trek'				=> 'Star Trek fiction',
    'star wars fiction'			=> 'Star Wars fiction',
    'star wars'				=> 'Star Wars fiction',
    'start-up business enterprises'	=> 'New business enterprises',
    'start-up businesses enterprises'	=> 'New business enterprises',
    'start-up companies'		=> 'New business enterprises',
    'start-up enterprises'		=> 'New business enterprises',
    'start-ups (business enterprises)'	=> 'New business enterprises',
    'start-ups'				=> 'New business enterprises',
    'starting a business'		=> 'New business enterprises',
    'startups (business enterprises)'	=> 'New business enterprises',
    'startups'				=> 'New business enterprises',
    'state parks'			=> 'Parks',
    'statistical matching'		=> 'Statistical matching',
    'statues'				=> 'Sculpture',
    'statuettes'			=> 'Figurines',
    'statutes'				=> 'Statutes',
    'steampunk fiction'			=> 'Steampunk fiction',
    'steampunk'				=> 'Steampunk fiction',
    'steganography'			=> 'Cryptography',
    'stereograms'			=> 'Stereograms',
    'stew'				=> 'Stews',
    'stews'				=> 'Stews',
    'stimulus deprivation'		=> 'Sensory deprivation',
    'stock issues'			=> 'Stocks',
    'stock offerings'			=> 'Stocks',
    'stock trading'			=> 'Stocks',
    'stocks'				=> 'Stocks',
    'stonework, decorative'		=> 'Sculpture',
    'strategic management'		=> 'Strategic planning',
    'strategic planning'		=> 'Strategic planning',
    'street art'			=> 'Street art',
    'structural adjustment (economic policy)' => 'Structural adjustment (Economic policy)',
    'structural adjustment'		=> 'Structural adjustment (Economic policy)',
    'structured query language'		=> 'SQL (Computer program language)',
    'study guides'			=> 'Study guides',
    'submarine boats'			=> 'Submarines (Ships)',
    'submarines (ships)'		=> 'Submarines (Ships)',
    'submarines'			=> 'Submarines (Ships)',
    'success'				=> 'Success',
    'super heroes'			=> 'Superheroes',
    'superannuation'			=> 'Retirement',
    'superheroes'			=> 'Superheroes',
    'supernatural'			=> 'Supernatural',
    'survival'				=> 'Survival',
    'survival skills'			=> 'Survival',
    'suspense fiction'			=> 'Suspense fiction',
    'suspense tales'			=> 'Suspense fiction',
    'suspense'				=> 'Suspense fiction',
    'sustainable development'		=> 'Sustainable development',
    'sustainable economic development'	=> 'Sustainable development',
    'sweets'				=> 'Confectionery',
    'system administration'		=> 'Computers--Administration',
    'system analysis'			=> 'System analysis',
    'systems administration'		=> 'Computers--Administration',
    'systems analysis'			=> 'System analysis',
    'systems architecture'		=> 'Computer architecture',
    'systems, expert (computer science)' => 'Expert systems (Computer science)',
    'systems, expert'			=> 'Expert systems (Computer science)',
    'tablet computers'			=> 'Tablet computers',
    'tablets (computers)'		=> 'Tablet computers',
    'takeovers, corporate'		=> 'Consolidation and merger of corporations',
    'tap water'				=> 'Drinking water',
    'tarot'				=> 'Tarot',
    'tattooing'				=> 'Tattooing',
    'tattoos (body markings)'		=> 'Tattooing',
    'tattoos'				=> 'Tattooing',
    'tax policy'			=> 'Taxation',
    'tax reform'			=> 'Taxation',
    'tax-exempt organizations'		=> 'Nonprofit organizations',
    'taxable income'			=> 'Income tax',
    'taxation of franchises'		=> 'Corporations--Taxation',
    'taxation of income'		=> 'Income tax',
    'taxation'				=> 'Taxation',
    'taxation, incidence of'		=> 'Taxation',
    'taxes'				=> 'Taxation',
    'tea'				=> 'Tea',
    'tea--use in cooking'		=> 'Cooking (Tea)',
    'teachers'				=> 'Teachers',
    'technical writing'			=> 'Technical writing',
    'technology'			=> 'Technology',
    'technology--authorship'		=> 'Technical writing',
    'technomancers'			=> 'Technomancers',
    'technomancy'			=> 'Technomancy',
    'telekinesis'			=> 'Psychokinesis',
    'telemarketing'			=> 'Telemarketing',
    'telepathy'				=> 'Telepathy',
    'telephone marketing'		=> 'Telemarketing',
    'telephone service'			=> 'Telephone',
    'telephone'				=> 'Telephone',
    'telephones'			=> 'Telephone',
    'teleportation'			=> 'Teleportation',
    'teleprocessing networks'		=> 'Computer networks',
    'television'			=> 'Television',
    'territorial parks'			=> 'Parks',
    'terror attacks'			=> 'Terrorism',
    'terrorism'				=> 'Terrorism',
    'terrorism, acts of'		=> 'Terrorism',
    'terrorist acts'			=> 'Terrorism',
    'terrorist attacks'			=> 'Terrorism',
    'textile industry and fabrics'	=> 'Textile industry',
    'textile industry'			=> 'Textile industry',
    'textiles industry'			=> 'Textile industry',
    'thames'                 		=> 'Thames River (England)',
    'thames river'           		=> 'Thames River (England)',
    'thames river (england)' 		=> 'Thames River (England)',
    'theology'				=> 'Theology',
    'theology, mystical'		=> 'Mysticism',
    'thieves'				=> 'Thieves',
    'thinking, artificial'		=> 'Artificial intelligence',
    'thought-transference'		=> 'Telepathy',
    'thralldom'				=> 'Slavery',
    'thriller'				=> 'Suspense fiction',
    'thrillers (fiction)'		=> 'Suspense fiction',
    'thrillers'				=> 'Suspense fiction',
    'tiffany aching (fictitious character)' => 'Aching, Tiffany (Fictitious character)',
    'tiffany aching'			=> 'Aching, Tiffany (Fictitious character)',
    'time allocation'			=> 'Time management',
    'time budgets'			=> 'Time management',
    'time management'			=> 'Time management',
    'time use'				=> 'Time management',
    'time'				=> 'Time',
    'time--management'			=> 'Time management',
    'time--organization'		=> 'Time management',
    'time--use of'			=> 'Time management',
    'time-saving cooking'		=> 'Quick and easy cooking',
    'timepieces'			=> 'Clocks and watches',
    'total quality management'		=> 'Total quality management',
    'tour operators'			=> 'Tourism',
    'tourism industry'			=> 'Tourism',
    'tourism operators'			=> 'Tourism',
    'tourism'				=> 'Tourism',
    'tourist industry'			=> 'Tourism',
    'tourist trade'			=> 'Tourism',
    'tourist traffic'			=> 'Tourism',
    'towns'				=> 'Cities and towns',
    'tqm (total quality management)'	=> 'Total quality management',
    'tqm'				=> 'Total quality management',
    'trade policy'			=> 'Commercial policy',
    'trade'				=> 'Commerce',
    'trade, international'		=> 'International trade',
    'trades'				=> 'Occupations',
    'trading of securities, electronic'	=> 'Electronic trading of securities',
    'trading, futures'			=> 'Futures',
    'trading, stock'			=> 'Stocks',
    'training'				=> 'Training',
    'transmission of data'		=> 'Data transmission systems',
    'transnational corporations'	=> 'International business enterprises',
    'transnational enterprises'		=> 'International business enterprises',
    'transport industry'		=> 'Transportation',
    'transport'				=> 'Transportation',
    'transportation companies'		=> 'Transportation',
    'transportation industry'		=> 'Transportation',
    'transportation'			=> 'Transportation',
    'travel industry'			=> 'Tourism',
    'travel, astral'			=> 'Astral projection',
    'tv'				=> 'Television',
    'u.s. government'			=> 'United States--Politics and government',
    'u.s. political culture'		=> 'Politics and culture--United States',
    'u.s. politics'			=> 'United States--Politics and government',
    'u.s.a.'				=> 'United States',
    'ufo phenomena'			=> 'Unidentified flying objects',
    'ufo'				=> 'Unidentified flying objects',
    'ufology'				=> 'Unidentified flying objects',
    'ufos'				=> 'Unidentified flying objects',
    'uits'				=> 'Mutual funds',
    'uml (computer science)'		=> 'UML (Computer science)',
    'uml'				=> 'UML (Computer science)',
    'uncooked food'			=> 'Raw foods',
    'underwater basket weaving'		=> 'Underwater construction--Baskets',
    'underwater basket-weaving'		=> 'Underwater construction--Baskets',
    'underwater construction'		=> 'Underwater construction',
    'underwater construction--baskets'	=> 'Underwater construction--Baskets',
    'underwriting'			=> 'Insurance',
    'unemployment'			=> 'Unemployment',
    'unfired food'			=> 'Raw foods',
    'unidentified flying objects'	=> 'Unidentified flying objects',
    'unified modeling language'		=> 'Unified Modeling Language',
    'unit investment trusts'		=> 'Mutual funds',
    'unit trusts'			=> 'Mutual funds',
    'united states political culture'	=> 'Politics and culture--United States',
    'united states'			=> 'United States',
    'united states, northwestern'	=> 'Northwestern States',
    'united states--collectibles'	=> 'Americana',
    'united states--politics and culture' => 'Politics and culture--United States',
    'united states--politics and government' => 'United States--Politics and government',
    'urban economics'			=> 'Urban economics',
    'us government'			=> 'United States--Politics and government',
    'us political culture'		=> 'Politics and culture--United States',
    'us politics'			=> 'United States--Politics and government',
    'us'				=> 'United States',
    'usa'				=> 'United States',
    'use of time'			=> 'Time management',
    'user created content'		=> 'User-generated content',
    'user generated content'		=> 'User-generated content',
    'user interfaces (computer systems)' => 'User interfaces (Computer systems)',
    'user interfaces'			 => 'User interfaces (Computer systems)',
    'user-created content'		=> 'User-generated content',
    'user-generated content'		=> 'User-generated content',
    'usury'				=> 'Interest',
    'utensils'				=> 'Implements, utensils, etc',
    'utilities (computer programs)'	=> 'Utilities (Computer programs)',
    'utility programs'			=> 'Utilities (Computer programs)',
    'utility routines'			=> 'Utilities (Computer programs)',
    'valdemar'			        => 'Valdemar (Imaginary place)',
    'valdemar (imaginary place)'        => 'Valdemar (Imaginary place)',
    'vampires'				=> 'Vampires',
    'vbscript (computer program language)' => 'VBScript (Computer program language)',
    'vbscript'				=> 'VBScript (Computer program language)',
    'vessels (utensils)'		=> 'Implements, utensils, etc',
    'video art'				=> 'Video art',
    'video games'			=> 'Computer games',
    'vietnam'				=> 'Vietnam',
    'vietnam war'			=> 'Vietnam War, 1961-1975',
    'vietnam war, 1961-1975'		=> 'Vietnam War, 1961-1975',
    'vimes, samuel (fictitious character)'	=> 'Vimes, Samuel (Fictitious character)',
    'vintage automobiles'		=> 'Antique and classic cars',
    'vintage cars'			=> 'Antique and classic cars',
    'virtual computer systems'		=> 'Virtual computer systems',
    'virtual corporations'		=> 'Virtual corporations',
    'virtual environments'		=> 'Virtual reality',
    'virtual machine systems'		=> 'Virtual computer systems',
    'virtual machines'			=> 'Virtual computer systems',
    'virtual private networks'		=> 'Extranets (Computer networks)',
    'virtual reality'			=> 'Virtual reality',
    'virtual worlds'			=> 'Virtual reality',
    'vision, computer'			=> 'Computer vision',
    'vision, machine'			=> 'Computer vision',
    'visitor industry'			=> 'Tourism',
    'visual data processing'		=> 'Optical data processing',
    'voyagers'				=> 'Explorers',
    'vpns'				=> 'Extranets (Computer networks)',
    'vr'				=> 'Virtual reality',
    'w3 (world wide web)'		=> 'World Wide Web',
    'w3'				=> 'World Wide Web',
    'wall art'				=> 'Street art',
    'war stories'			=> 'War stories',
    'war'				=> 'War stories',
    'warehousing data'			=> 'Data warehousing',
    'warehousing information'		=> 'Data warehousing',
    'warehousing, data'			=> 'Data warehousing',
    'warehousing, information'		=> 'Data warehousing',
    'warlocks'				=> 'Warlocks',
    'warships'				=> 'Warships',
    'watches'				=> 'Clocks and watches',
    'water-color painting'		=> 'Watercolor painting',
    'water-color paintings'		=> 'Watercolor painting',
    'water-colors'			=> 'Watercolor painting',
    'watercolor painting'		=> 'Watercolor painting',
    'watercolor painting--technique'	=> 'Watercolor painting--Technique',
    'watercolor paintings'		=> 'Watercolor painting',
    'watercolors'			=> 'Watercolor painting',
    'weather'				=> 'Weather',
    'weatherwax, esme (fictitious character)'	=> 'Weatherwax, Granny (Fictitious character)',
    'weatherwax, esmerelda (fictitious character)'	=> 'Weatherwax, Granny (Fictitious character)',
    'weatherwax, granny (fictitious character)'	=> 'Weatherwax, Granny (Fictitious character)',
    'web (world wide web)'		=> 'World Wide Web',
    'web broadcasting'			=> 'Webcasting',
    'web browsers'			=> 'Browsers (Computer programs)',
    'web browsing software'		=> 'Browsers (Computer programs)',
    'web casting'			=> 'Webcasting',
    'web drugstores'			=> 'Internet pharmacies',
    'web logs'				=> 'Blogs',
    'web pages'				=> 'Web sites',
    'web pharmacies'			=> 'Internet pharmacies',
    'web programming'			=> 'Web site development',
    'web retailing'			=> 'Electronic commerce',
    'web search engines'		=> 'Web search engines',
    'web searching'			=> 'Web search engines',
    'web services'			=> 'Web services',
    'web site development'		=> 'Web site development',
    'web site directories'		=> 'Web sites--Directories',
    'web site programming'		=> 'Web site development',
    'web sites'				=> 'Web sites',
    'web sites--computer programming'	=> 'Web site development',
    'web sites--design'			=> 'Web sites--Design',
    'web sites--development'		=> 'Web site development',
    'web sites--directories'		=> 'Web sites--Directories',
    'web sites--programming'		=> 'Web site development',
    'webcasting'			=> 'Webcasting',
    'webliographies'			=> 'Web sites--Directories',
    'weblogs'				=> 'Blogs',
    'webpage design'			=> 'Web sites--Design',
    'webpages'				=> 'Web sites',
    'website design'			=> 'Web sites--Design',
    'website development'		=> 'Web site development',
    'website programming'		=> 'Web site development',
    'websites'				=> 'Web sites',
    'weight control of obesity'		=> 'Weight loss',
    'weight control'			=> 'Weight loss',
    'weight loss'			=> 'Weight loss',
    'weight reducing'			=> 'Weight loss',
    'weight reduction'			=> 'Weight loss',
    'welsh cooking'			=> 'Cooking, Welsh',
    'were-wolf'				=> 'Werewolves',
    'were-wolves'			=> 'Werewolves',
    'werewolf'				=> 'Werewolves',
    'werewolves'			=> 'Werewolves',
    'werewolves--fiction'		=> 'Werewolves',
    'werwolf'				=> 'Werewolves',
    'werwolves'				=> 'Werewolves',
    'west indian cooking'		=> 'Cooking, West Indian',
    'western cooking (united states)'	=> 'Cooking, American--Western style',
    'westphalian cooking'		=> 'Cooking, German--Westphalian style',
    'wideband communication systems'	=> 'Broadband communication systems',
    'wimmin'				=> 'Women',
    'wireless communication systems'	=> 'Wireless communication systems',
    'wireless data communication systems' => 'Wireless communication systems',
    'wireless data communication'	=> 'Wireless communication systems',
    'wireless data transmission systems' => 'Wireless communication systems',
    'wireless data transmission'	=> 'Wireless communication systems',
    'wireless information systems'	=> 'Wireless communication systems',
    'wireless telecommunication systems' => 'Wireless communication systems',
    'wireless telecommunication'	=> 'Wireless communication systems',
    'witchcraft'			=> 'Witchcraft',
    'wizard of london'			=> 'Wizards--England--London--Fiction',
    'wizards'				=> 'Wizards',
    'wizards--england--london--fiction'	=> 'Wizards--England--London--Fiction',
    'wok cookery'			=> 'Wok cooking',
    'wok cooking'			=> 'Wok cooking',
    'woman'				=> 'Women',
    'women'				=> 'Women',
    'women detectives'			=> 'Women detectives',
    'women entrepreneurs'		=> 'Businesswomen',
    'women heroes'			=> 'Women heroes',
    'women heroes--fiction'		=> 'Women heroes--Fiction',
    'women in business'			=> 'Businesswomen',
    'women--biography'			=> 'Women--Biography',
    "women--civil rights"		=> "Women's rights",
    "women--rights of women"		=> "Women's rights",
    'women--suffrage'			=> 'Women--Suffrage',
    "women's rights"			=> "Women's rights",
    'womon'				=> 'Women',
    'womyn'				=> 'Women',
    'wood furniture'			=> 'Furniture',
    'wooden furniture'			=> 'Furniture',
    'wooing'				=> 'Courtship',
    'word processing software'		=> 'Word processing--Software',
    'word processing'			=> 'Word processing',
    'word processing--software'		=> 'Word processing--Software',
    'work environment'			=> 'Work environment',
    'working conditions'		=> 'Work environment',
    'working conditions, physical'	=> 'Work environment',
    'working environment'		=> 'Work environment',
    'workplace climate'			=> 'Work environment',
    'workplace culture'			=> 'Work environment',
    'workplace environment'		=> 'Work environment',
    'workplace'				=> 'Work environment',
    'worksite environment'		=> 'Work environment',
    'world economics'			=> 'Competition, International',
    'world terrorism'			=> 'Terrorism',
    'world trade'			=> 'International trade',
    'world war, 1939-1945'		=> 'World War, 1939-1945',
    'world war 2'			=> 'World War, 1939-1945',
    'world war ii'			=> 'World War, 1939-1945',
    'world war two'			=> 'World War, 1939-1945',
    'world wide web'			=> 'World Wide Web',
    'world wide web pages'		=> 'Web sites',
    'world wide web searching'		=> 'Web search engines',
    'world wide web sites'		=> 'Web sites',
    'world wide web sites--directories'	=> 'Web sites--Directories',
    'world wide web--directories'	=> 'Web sites--Directories',
    'writing'				=> 'Writing',
    'writing letters'			=> 'Letter writing',
    'writing of letters'		=> 'Letter writing',
    'www (world wide web)'		=> 'World Wide Web',
    'www pages'				=> 'Web sites',
    'www sites'				=> 'Web sites',
    'www'				=> 'World Wide Web',
    'xml (document markup language)'	=> 'XML (Document markup language)',
    'xml'				=> 'XML (Document markup language)',
    'xml-based user interface language'	=> 'XUL (Document markup language)',
    'xul (document markup language)'	=> 'XUL (Document markup language)',
    'xul'				=> 'XUL (Document markup language)',
    'young women'			=> 'Young women',
    'young women--england--fiction'	=> 'Young women--England--Fiction',
    'young women--fiction'		=> 'Young women--Fiction',
    'youngsters'			=> 'Children',
    'zombies'				=> 'Zombies',
    'zombis'				=> 'Zombies',
   );


our %mobibooktypes = (
    'Default' => undef,
    'eBook' => 'text/x-oeb1-document',
    'eNews' => 'application/x-mobipocket-subscription',
    'News feed' => 'application/x-mobipocket-subscription-feed',
    'News magazine' => 'application/x-mobipocket-subscription-magazine',
    'Images' => 'image/gif',
    'Microsoft Word document' => 'application/msword',
    'Microsoft Excel sheet' => 'application/vnd.ms-excel',
    'Microsoft Powerpoint presentation' => 'application/vnd.ms-powerpoint',
    'Plain text' => 'text/plain',
    'HTML' => 'text/html',
    'Mobipocket game' => 'application/vnd.mobipocket-game',
    'Franklin game' => 'application/vnd.mobipocket-franklin-ua-game'
    );

our %publishermap = (
    'a.s.s.t.r'				=> 'ASSTR',
    'a.s.s.t.r.'			=> 'ASSTR',
    'ace books'             		=> 'Ace Books',
    'ace'                   		=> 'Ace Books',
    'acebooks'              		=> 'Ace Books',
    'alt sex stories text repository' 	=> 'ASSTR',
    'alt.sex.stories text repository' 	=> 'ASSTR',
    'alt.sex.stories'			=> 'ASSTR',
    'alt.sex.stories.moderated'		=> 'ASSTR',
    'anchor books'			=> 'Anchor Books',
    'anchor books a division of random house, inc.' => 'Anchor Books',
    'anchor booksa division of random house, inc.' => 'Anchor Books',
    'asstr'				=> 'ASSTR',
    'baen books'               		=> 'Baen Publishing Enterprises',
    'baen publishing'       		=> 'Baen Publishing Enterprises',
    'baen'                  		=> 'Baen Publishing Enterprises',
    'ballantine books'      		=> 'Ballantine Books',
    'ballantine'            		=> 'Ballantine Books',
    'barnes & noble'      		=> 'Barnes and Noble Publishing',
    'barnes &amp; noble'      		=> 'Barnes and Noble Publishing',
    'barnes and noble'      		=> 'Barnes and Noble Publishing',
    'barnes&amp;noble'      		=> 'Barnes and Noble Publishing',
    'barnes&noble'      		=> 'Barnes and Noble Publishing',
    'barnesandnoble.com'    		=> 'Barnes and Noble Publishing',
    'blackmask online'			=> 'Blackmask Online',
    'cpan'                  		=> 'CPAN',
    'del rey books'         		=> 'Del Rey Books',
    'del rey'               		=> 'Del Rey Books',
    'delrey'                		=> 'Del Rey Books',
    'e-reads'               		=> 'E-Reads',
    'electronic text center. university of virginia library.' => 'University of Virginia Library',
    'ereads'                		=> 'E-Reads',
    'ereads.com'            		=> 'E-Reads',
    'feedbooks (www.feedbooks.com)' 	=> 'Feedbooks',
    'feedbooks'             		=> 'Feedbooks',
    'fictionwise'           		=> 'Fictionwise',
    'fictionwise, inc.'       		=> 'Fictionwise',
    'fictionwise.com'       		=> 'Fictionwise',
    'gutenberg'             		=> 'Project Gutenberg',
    'gutenberg.org'         		=> 'Project Gutenberg',
    'harmony books'         		=> 'Harmony Books',
    'harmony'               		=> 'Harmony Books',
    'harper collins'        		=> 'HarperCollins',
    'harper-collins'        		=> 'HarperCollins',
    'harpercollins'         		=> 'HarperCollins',
    'http://www.blackmask.com'		=> 'Blackmask Online',
    'http://www.blackmask.com/'		=> 'Blackmask Online',
    'manybooks'             		=> 'ManyBooks',
    'manybooks.net'         		=> 'ManyBooks',
    'marion zimmer bradley literary works trust' => 'Marion Zimmer Bradley Literary Works Trust',
    'mzb literary works trust'		=> 'Marion Zimmer Bradley Literary Works Trust',
    'penguin group'         		=> 'Penguin Group',
    'penguin group, usa'    		=> 'Penguin Group',
    'penguin'               		=> 'Penguin Group',
    'project gutenberg'     		=> 'Project Gutenberg',
    'random-house.com'      		=> 'Random House',
    'randomhouse'           		=> 'Random House',
    'randomhouse.co.uk'     		=> 'Random House',
    'rosetta books'         		=> 'Rosetta Books',
    'rosetta'               		=> 'Rosetta Books',
    'rosettabooks'          		=> 'Rosetta Books',
    'siren publishing'      		=> 'Siren Publishing',
    'siren'                 		=> 'Siren Publishing',
    'smashwords'			=> 'Smashwords',
    'smashwords, inc.'			=> 'Smashwords',
    'stonehouse press'			=> 'Stonehouse Press',
    'stories online'			=> 'World Literature Company',
    'storiesonline'			=> 'World Literature Company',
    'the random house publishing group' => 'Random House',
    'tom doherty associates'		=> 'Tom Doherty Associates',
    'university of virginia library'	=> 'University of Virginia Library',
    'university of virginia library.'	=> 'University of Virginia Library',
    'wildside press'        		=> 'Wildside Press',
    'wildside'              		=> 'Wildside Press',
    'world literature company'          => 'World Literature Company',
    'www.blackmask.com'			=> 'Blackmask Online',
    'www.ereads.com'        		=> 'E-Reads',
    'www.feedbooks.com'     		=> 'Feedbooks',
    'www.fictionwise.com'   		=> 'Fictionwise',
    'www.gutenberg.org'     		=> 'Project Gutenberg',
    'www.random-house.com'  		=> 'Random House',
    'www.randomhouse.co.uk' 		=> 'Random House',
    );


our %nonxmlentity2char = %entity2char;
delete($nonxmlentity2char{'amp'});
delete($nonxmlentity2char{'gt'});
delete($nonxmlentity2char{'lt'});
delete($nonxmlentity2char{'quot'});
delete($nonxmlentity2char{'apos'});

our %referencetypes = (
    # standard types
    'acknowledgements'   => 'acknowledgements',
    'bibliography'       => 'bibliography',
    'colophon'           => 'colophon',
    'copyright-page'     => 'copyright-page',
    'cover'              => 'cover',
    'dedication'         => 'dedication',
    'epigraph'           => 'epigraph',
    'foreword'           => 'foreword',
    'glossary'           => 'glossary',
    'index'              => 'index',
    'loi'                => 'loi',
    'lot'                => 'lot',
    'notes'              => 'notes',
    'preface'            => 'preface',
    'text'               => 'text',
    'title-page'         => 'title-page',
    'toc'                => 'toc',
    # common nonstandard types
    'start'              => 'text',
    'coverimage'         => 'other.ms-coverimage',
    'coverimagestandard' => 'other.ms-coverimage-standard',
    'other.copyright'    => 'copyright-page',
    'other.ms-firstpage' => 'text',
    'thumbimage'         => 'other.ms-thumbimage',
    'thumbimagestandard' => 'other.ms-thumbimage-standard',
   );

our %relatorcodes = (
    'act' => 'Actor',
    'adp' => 'Adapter',
    'ann' => 'Annotator',
    'ant' => 'Bibliographic antecedent',
    'app' => 'Applicant',
    'arc' => 'Architect',
    'arr' => 'Arranger',
    'art' => 'Artist',
    'asg' => 'Assignee',
    'asn' => 'Associated name',
    'att' => 'Attributed name',
    'aui' => 'Author of introduction',
    'aus' => 'Author of screenplay',
    'aut' => 'Author',
    'bdd' => 'Binding designer',
    'bjd' => 'Bookjacket designer',
    'bkd' => 'Book designer',
    'bkp' => 'Book producer',
    'bnd' => 'Binder',
    'bpd' => 'Bookplate designer',
    'bsl' => 'Bookseller',
    'chr' => 'Choreographer',
    'cli' => 'Client',
    'cll' => 'Calligrapher',
    'clt' => 'Collotyper',
    'cmm' => 'Commentator',
    'cmp' => 'Composer',
    'cmt' => 'Compositor',
    'cnd' => 'Conductor',
    'cns' => 'Censor',
    'coe' => 'Contestant-appellee',
    'col' => 'Collector',
    'com' => 'Compiler',
    'cos' => 'Contestant',
    'cot' => 'Contestant-appellant',
    'cpe' => 'Complainant-appellee',
    'cph' => 'Copyright holder',
    'cpl' => 'Complainant',
    'cpt' => 'Complainant-appellant',
    'crp' => 'Correspondent',
    'crr' => 'Corrector',
    'cst' => 'Costume designer',
    'cte' => 'Contestee-appellee',
    'ctg' => 'Cartographer',
    'cts' => 'Contestee',
    'ctt' => 'Contestee-appellant',
    'dfd' => 'Defendant',
    'dfe' => 'Defendant-appellee',
    'dft' => 'Defendant-appellant',
    'dln' => 'Delineator',
    'dnc' => 'Dancer',
    'dnr' => 'Donor',
    'dpt' => 'Depositor',
    'drt' => 'Director',
    'dsr' => 'Designer',
    'dst' => 'Distributor',
    'dte' => 'Dedicatee',
    'dto' => 'Dedicator',
    'dub' => 'Dubious author',
    'edt' => 'Editor',
    'egr' => 'Engraver',
    'elt' => 'Electrotyper',
    'eng' => 'Engineer',
    'etr' => 'Etcher',
    'flm' => 'Film editor',
    'fmo' => 'Former owner',
    'fnd' => 'Funder/Sponsor',
    'frg' => 'Forger',
    'grt' => 'Graphic technician (discontinued code)',
    'hnr' => 'Honoree',
    'ill' => 'Illustrator',
    'ilu' => 'Illuminator',
    'ins' => 'Inscriber',
    'inv' => 'Inventor',
    'itr' => 'Instrumentalist',
    'ive' => 'Interviewee',
    'ivr' => 'Interviewer',
    'lbt' => 'Librettist',
    'lee' => 'Libelee-appellee',
    'lel' => 'Libelee',
    'len' => 'Lender',
    'let' => 'Libelee-appellant',
    'lie' => 'Libelant-appellee',
    'lil' => 'Libelant',
    'lit' => 'Libelant-appellant',
    'lse' => 'Licensee',
    'lso' => 'Licensor',
    'ltg' => 'Lithographer',
    'lyr' => 'Lyricist',
    'mon' => 'Monitor/Contractor',
    'mte' => 'Metal-engraver',
    'nrt' => 'Narrator',
    'org' => 'Originator',
    'oth' => 'Other',
    'pbl' => 'Publisher',
    'pfr' => 'Proofreader',
    'pht' => 'Photographer',
    'plt' => 'Platemaker',
    'pop' => 'Printer of plates',
    'ppm' => 'Papermaker',
    'prd' => 'Production personnel',
    'prf' => 'Performer',
    'pro' => 'Producer',
    'prt' => 'Printer',
    'pte' => 'Plaintiff-appellee',
    'ptf' => 'Plaintiff',
    'pth' => 'Patent holder',
    'ptt' => 'Plaintiff-appellant',
    'rbr' => 'Rubricator',
    'rce' => 'Recording engineer',
    'rcp' => 'Recipient',
    'rse' => 'Respondent-appellee',
    'rsp' => 'Respondent',
    'rst' => 'Respondent-appellant',
    'sce' => 'Scenarist',
    'scr' => 'Scribe',
    'scl' => 'Sculptor',
    'sec' => 'Secretary',
    'sgn' => 'Signer',
    'srv' => 'Surveyor',
    'str' => 'Stereotyper',
    'trc' => 'Transcriber',
    'trl' => 'Translator',
    'tyd' => 'Type designer',
    'tyg' => 'Typographer',
    'voc' => 'Vocalist',
    'wam' => 'Writer of accompanying material',
    'wde' => 'Wood-engraver',
    'wit' => 'Witness',
    );

our %sexcodes = (
    # Age/Gender
    'MF'      => 'Ma/Fa',	# Adult Male over 18, Adult Female over 18
    'mf'      => 'mt/ft',	# Teen Male under 18, Teen Female under 18
    'Mf'      => 'Ma/ft',	# Adult Male over 18, Teen Female under 18
    'mF'      => 'mt/Fa',	# Teen Male under 18, Adult Female
    'FF'      => 'Fa/Fa',	# 2 or more Females over 18
    'ff'      => 'ft/ft',	# 2 or more Teen Females under 18
    'Ff'      => 'Fa/ft',	# Adult Female, Teen female under 18
    'boy'     => 'boy',		# Boy 12 years old or younger
    'Boy'     => 'boy',
    'girl'    => 'gi',		# Girl 12 years old or younger
    'Girl'    => 'gi',
    'MM'      => 'Ma/Ma',	# 2 or more Adult Males over 18
    'Mm'      => 'Ma/mt',	# Adult Male, Teen Male under 18
    'mm'      => 'mt/mt',	# 2 or more Teen Males under 18
    'mult'    => 'Mult',	# Multiple Partner. ie MFF or mmmF
    'teen'    => 'Teenagers',	# Cast of story is mostly teenagers.
    'Teen'    => 'Teenagers',
    'teenagers' => 'Teenagers',

    # Level of Consent
    'cons'       => 'Consensual', # All parties are consenting to the act
    'consensual' => 'Consensual',
    'rom'      => 'Romantic',	  #  Mushy love story
    'romance'  => 'Romantic',
    'romantic' => 'Romantic',
    'non-con'  => 'NonConsensual', # At least one of the parties is not participating willfully
    'nonconsensual' => 'NonConsensual',
    'pedo'     => 'Pedophilia',	  # An adult initiating sexual contact with a
				  # pre-pubescent child (boy or girl, 12 or under)
    'pedophilia' => 'Pedophilia',
    'lolita'  => 'Lolita',	  # A pre-pubescent child (boy or girl, 12 or
				  # younger) initiates sexual contact with an adult
    'reluc'   => 'Reluctant',	  # Start as non consentual and then the non
				  # consenting party participates willingly
    'reluctant' => 'Reluctant',
    'rape'    => 'Rape',	  # Stories with violent rape
    'coer'    => 'Coercion',	  # Not exactly blackmail, but applying different
				  # kinds of pressure to force into the act.
    'coercion' => 'Coercion',
    'Blkm'    => 'Blackmail',	  # Blackmailing somebody to force them into the sex act depicted
    'blackmail' => 'Blackmail',
    'mc'      => 'Mind Control',  # Stories where one party somehow controls another's mind
    'mind control' => 'Mind Control',
    'MindControl'  => 'Mind Control',
    'Mindcontrol'  => 'Mind Control',
    'mindcontrol'  => 'Mind Control',
    'hypno'   => 'Hypnosis',	  # One party using hypnosis for sexual purposes
    'hypnosis' => 'Hypnosis',
    'dru'     => 'Drunk/Drugged', # One party at least is drunk or drugged and
				  # participates while under the influence without really knowing
    'drunk/drugged' => 'Drunk/Drugged',
    'Drunk'         => 'Drunk/Drugged',
    'drunk'         => 'Drunk/Drugged',
    'Drugged'       => 'Drunk/Drugged',
    'drugged'       => 'Drunk/Drugged',
    'mag'     => 'Magic', 	  # Contains magic and supernatural phenomenons
    'slave'   => 'Slavery',	  # Slavery, sexual or otherwise
    'Slave'   => 'Slavery',
    'slavery' => 'Slavery',

    # Sexual Orientations
    'gay'     => 'Gay',		  # Self Explanatory
    'les'     => 'Lesbian',	  # Self Explanatory
    'Les'     => 'Lesbian',
    'lesbian' => 'Lesbian',
    'lesbian sex' => 'Lesbian',
    'bi'      => 'BiSexual',	  # Self Explanatory
    'Bisexual' => 'BiSexual',
    'bisexual' => 'BiSexual',
    'het'     => 'Heterosexual',  # Self Explanatory
    'hetero'  => 'Heterosexual',
    'heterosexual' => 'Heterosexual',
    'tg'      => 'TransGender',   # Gender crossing (note that code 'trans' refers to transformation)
    'Transgender' => 'TransGender',
    'transgender' => 'TransGender',
    'cd'      => 'CrossDressing', # Men dressing as women and in women clothing, also vice-versa
    'Crossdressing' => 'CrossDressing',
    'crossdressing' => 'CrossDressing',
    'Crossdress' => 'CrossDressing',
    'crossdress' => 'CrossDressing',
    'herm'    => 'Hermaphrodite', # Person having both male and female genitalia
    'hermaphrodite' => 'Hermaphrodite',
    'shem'    => 'Shemale',	  # Trans women with male genitalia and female
    'shemale' => 'Shemale',       # breasts from breast augmentation and/or use of hormones

    # Story Types
    'fict'     => 'Fiction',	# Fictitious story, not true
    'fiction'  => 'Fiction',
    'true'    => 'True Story',	# A true story, according to the author.
    'hiFant'  => 'High Fantasy', # High Fantasy, sword and sorcery and such
    'fanfic'  => 'Fan Fiction', # A story using characters from movies, TV shows or Comics
    'celeb'   => 'Celebrity',	# A story about a real life celebrity, the
				# story is fictional of course.
    'ScFi'    => 'Science Fiction', # Science Fiction
    'Scifi'   => 'Science Fiction',
    'scifi'   => 'Science Fiction',
    'TimeTr'  => 'Time Travel',	# Science Fiction involving travel through time
    'robot'   => 'Robot',	# Humans having relations, sexual or otherwise,
				# with non-biological entities (mechanical
				# robots or full blown androids)
    'PostApoc' => 'Post Apocalypse', # Post Apocalyptic world.
    'hist'    => 'Historical',	# Story that is set in past history, mostly
				# related to famous people and events.
    'horror'  => 'Horror',	# Horror Elements in the story, erotic or otherwise.
    'humor'   => 'Humor',	# Contains humor or the story is a spoof
    'tears'   => 'Tear Jerker', # Sad story or containing sad moments
    'superhero' => 'Superhero', # Story contains Super Hero/Heroine
    'ESP'     => 'Extra Sensory Perception', # Perceiving things by means other
				# than the known senses, e.g. by telepathy or clairvoyance.
    'Zoo'     => 'Zoophilia ',	# Different from bestiality, it's about
				# relationships between humans and animals, not just sex.
    'space'   => 'Space',	# Story set in outer space
    'myst'    => 'Mystery',	# A suspensful story about a mystery
    'sport'   => 'Sports',	# A story with a sports theme
    'west'    => 'Western',	# Set in the old US west
    'doover'  => 'DoOver',	# Getting to do one's life all over again

    # Paranormal
    'paranormal' => 'Paranormal', # Ghosts, angels, spirits, poltergeists, etc
    'vamp'    => 'Vampires',	# Vampires in the story
    'vampire' => 'Vampires',
    'vampires' => 'Vampires',
    'furry'   => 'Furry',	# Anthropomorphic animals or 'taurs' (animal
				# bodies with anthropomorphic torsos) it also
				# includes other forms such as dragons.
    'non-anthro' => 'non-anthro', # Animal in form with human level
				# intelligence, e.g. Werewolves
    'were'    => 'Were animal', # A human that can turn into an animal temporarily.
    'zom'     => 'Zombies',	# Zombies in the story

    # Couples
    'cheat'   => 'Cheating',	# One party is cheating on their spouse
    'cheating' => 'Cheating',
    'wife'    => 'Slut Wife',	# Slutty wife
    'wimp'    => 'Wimp Husband', # Husband does not stand up for himself when
				# faced with a cheating wife
    'cuckold' => 'Cuckold',	# When man is being forced to accept
				# his wife's cheating against his will.
    'watch'   => 'Wife Watching', # Man enjoys watching his wife getting fucked
    'reven'   => 'Revenge',	# One party gets revenge for spouse's cheating

    # Incest
    'inc'     => 'Incest',	# sex between the members of the same family
    'incest'  => 'Incest',
    'mother'  => 'Mother',	# Self Explanatory
    'son'     => 'Son',		# Self Explanatory
    'bro'     => 'Brother',	# Self Explanatory
    'brother' => 'Brother',
    'sis'     => 'Sister',	# Self Explanatory
    'fath'    => 'Father',	# Self Explanatory
    'father'  => 'Father',
    'dau'     => 'Daughter',	# Self Explanatory
    'daughter' => 'Daughter',
    'cous'    => 'Cousins',	# Self Explanatory
    'cousin'  => 'Cousins',
    'cousins' => 'Cousins',
    'grand'   => 'Grand Parent', # Self Explanatory
    'Grandfather' => 'Grand Parent',
    'grandfather' => 'Grand Parent',
    'Grandmother' => 'Grand Parent',
    'grandmother' => 'Grand Parent',
    'Grandparent' => 'Grand Parent',
    'grandparent' => 'Grand Parent',
    'grand parent' => 'Grand Parent',
    'unc'     => 'Uncle',	# Self Explanatory
    'uncle'   => 'Uncle',
    'niece'   => 'Niece',	# Self Explanatory
    'aunt'    => 'Aunt',	# Self Explanatory
    'neph'    => 'Nephew',	# Self Explanatory
    'nephew'  => 'Nephew',
    'in-law'  => 'InLaws',	# Self Explanatory
    'inlaw'   => 'InLaws',
    'inlaws'   => 'InLaws',
    'Inlaws'   => 'InLaws',

    # BDSM Elements
    'BDSM'    => 'BDSM',	# Bondage and/or SadoMasochism
    'bdsm'    => 'BDSM',
    'bd/sm'   => 'BDSM',
    'Bondage' => 'BDSM',
    'bondage' => 'BDSM',
    'Sadomasochism' => 'BDSM',
    'sadomasochism' => 'BDSM',
    'D/S'     => 'DomSub',	# Story about domination, being sexual or otherwise
    'd/s'     => 'DomSub',
    'Domsub'  => 'DomSub',
    'domsub'  => 'DomSub',
    'Domination' => 'DomSub',
    'domination' => 'DomSub',
    'Lesdom'  => 'DomSub',
    'lesdom'  => 'DomSub',
    'Mdom'    => 'MaleDom',	# Male Dominant
    'mdom'    => 'MaleDom',
    'Fdom'    => 'FemaleDom',	# Female Dominant
    'fdom'    => 'FemaleDom',
    'span'    => 'Spanking',	# Somebody gets spanked in the story, willingly or unwillingly
    'spank'   => 'Spanking',
    'spanking' => 'Spanking',
    'rough'   => 'Rough',	# Rough sex
    'lght'    => 'Light Bond',  # Light Bondage, usually consensual and for
				# experimentation at the request of the one of the parties
    'humil'   => 'Humiliation', # Degradation of somebody in the story and/or
    'Humil'   => 'Humiliation',	# humiliating them publicly
    'sad'     => 'Sadistic',	# Somebody inflicting pain, physical or mental, for the hell of it
    'sadism'  => 'Sadistic',
    'Sadism'  => 'Sadistic',
    'tort'    => 'Torture',	# Self Explanatory
    'torture' => 'Torture',
    'snuff'   => 'Snuff',	# Killing being done during the act of sex.
				# (Non-sexual murder is in violent)

    # Groups
    'swing'   => 'Swinging',	# Trading Sexual Partners
    'swingers' => 'Swinging',
    'swinging' => 'Swinging',
    'gang'    => 'Gang Bang',   # Multiple men fucking same woman
    'GangBang' => 'Gang Bang',
    'Gangbang' => 'Gang Bang',
    'gangbang' => 'Gang Bang',
    'group'   => 'Group Sex',   # Multiple couples in the same place or a threesome
    'orgy'    => 'Orgy',	# Everybody is Fucking everybody in a group
    'harem'   => 'Harem',	# There is a harem involved in the story.
    'poly'    => 'Polygamy/Polyamory', # Multiple spouses or partners (multiple men or multiple women)
    'polygamy' => 'Polygamy/Polyamory',
    'Polygamy' => 'Polygamy/Polyamory',
    'polyamory' => 'Polygamy/Polyamory',
    'Polyamory' => 'Polygamy/Polyamory',

    # Interracial Elements
    'interr'  => 'Interracial',   # Sexual partners of different races
    'Interr'  => 'Interracial',
    'interrracial'  => 'Interracial',
    'WC'      => 'White Couple',  # Self Explanatory
    'BC'      => 'Black Couple',  # Self Explanatory
    'BF'      => 'Black Female',  # Self Explanatory
    'BM'      => 'Black Male',    # Self Explanatory
    'WM'      => 'White Male',    # Self Explanatory
    'WF'      => 'White Female',  # Self Explanatory
    'OM'      => 'Oriental Male', # Self Explanatory
    'OF'      => 'Oriental Female', # Self Explanatory
    'HM'      => 'Hispanic Male', # Self Explanatory
    'HF'      => 'Hispanic Female', # Self Explanatory

    # Sexual Activities
    '1st'     => 'First',	# One of the parties having sex is a virgin
    'first'   => 'First',	# One of the parties having sex is a virgin
    'safe'    => 'Safe Sex',    # Sex with proper protection
    'Safe'    => 'Safe Sex',
    'oral'    => 'Oral Sex',    # Self Explanatory
    'oral sex' => 'Oral Sex',
    'fellatio' => 'Oral Sex',
    'cunnilingus' => 'Oral Sex',
    'anal'    => 'Anal Sex',    # Self Explanatory
    'mastrb'  => 'Masturbation', # Self pleasuring, could be alone or while
				# with somebody else but no intercourse
    'masturbation' => 'Masturbation',
    'pett'    => 'Petting',     # Feeling up and such
    'petting' => 'Petting',
    'fingering' => 'Petting',
    'fist'    => 'Fisting',	# Hand and arm or foot insertion
    'Fist'    => 'Fisting',
    'toys'    => 'Sex Toys',	# Sex with the help of sex toys, such as dildos and vibrators
    'Toys'    => 'Sex Toys',
    'beast'   => 'Bestiality',  # Sex with animals
    'bestiality' => 'Bestiality',
    'squirt'  => 'Squirting',	# Female Ejaculation
    'squirting' => 'Squirting',
    'food'    => 'Food',        # Sex where food is involved, like doing it to
				# a pie or shoving a carrot
    'lac'     => 'Lactation',   # Drinking and playing with human milk
    'lact'    => 'Lactation',
    'lactation' => 'Lactation',
    'ws'      => 'Water Sports', # Peeing on each other
    'golden shower' => 'Water Sports',
    'enem'    => 'Enema',       # Getting an enema as a sexual thing
    'scat'    => 'Scatology',   # Playing with feces
    'preg'    => 'Pregnancy',   # Somebody gets pregnant in the story
    'Preg'    => 'Pregnancy',
    'creampie' => 'Cream Pie',  # Somebody licks a pussy full of cum
    'necro'   => 'Necrophilia', # Sex with a corpse
    'Necro'   => 'Necrophilia',
    'fart'    => 'Flatulence',  # Flatulence as a sexual fetish
    'spit'    => 'Spitting',    # Spitting as a sexual fetish
    'exhib'   => 'Exhibitionism', # Enjoyment of self exposure
    'Exhib'   => 'Exhibitionism',
    'voy'     => 'Voyeurism',   # Enjoyment of watching other people without their knowledge
    'Voy'     => 'Voyeurism',
    'voyeur'  => 'Voyeurism',
    'Voyeur'  => 'Voyeurism',
    'DP'      => 'Double Penetration', # Simultaneous Anal and Vaginal Penetration
    'dp'      => 'Double Penetration',

    # Fetishes
    'size'    => 'Size',        # Where the size of the sex parts (penis,
				# breasts, toys) plays a major role in the story
    'doct'    => 'Doctor/Nurse', # Medical Fetish, Doctor or Nurse Play a prominent role in the story
    'BBW'     => 'BBW',		# Big Beautiful Woman. Loving Big Women
    'feet'    => 'Foot Fetish', # Foot fetish
    'legs'    => 'Leg Fetish',  # Leg fetish, often with stockings, garters and heels.
    'hairy'   => 'Hairy Fetish', # with hairy men/women
    'mod'     => 'Body Modification', # Erotic body modification, including
				# piercings and tattoos, plays a prominent role.
    'amput'   => 'Amputee',	# Sex with an amputee
    'needles' => 'Needles',	# Includes injections and play or permanent piercings.
    'teach'   => 'Teacher/Student', # Teacher/student relations
    'teacher/student' => 'Teacher/Student',
    'teacher student' => 'Teacher/Student',
    'bbsit'   => 'Babysitter',	# Sex with babysitters fetish
    'BBr'     => 'Big Breasts', # Women with Big Breasts
    'clergy'  => 'Clergy',      # Involving members of the clergy (Priest, Bishops, nuns)
    'menses'  => 'Menstrual Play', # Sex play with a woman who's on menstrual cycle
    'Menses'  => 'Menstrual Play',
    'menstruation' => 'Menstrual Play',
    'Menstruation' => 'Menstrual Play',
    'public'  => 'Public Sex',	# Sexual events taking place in public
    'Public'  => 'Public Sex',

    # Other
    'slow'    => 'Slow',	# There is a story and plot development before
				# any sex occurs. Not a stroke story.
    'clas'    => 'Novel-Classic', # An old classic novel that is now in the public domain
    'bknk'    => 'Novel-Pocketbook', # An old published pocketbook novel that
				# is not in circulation any more and the
				# publisher has gone under, so it's not going to be published again
    'caution' => 'Caution',	# Story contains something that can't be
				# classified but requires caution on the reader's part
    '2nd'     => '2nd POV',	# Story written from the 2nd person POV
    'violent' => 'Violent',	# Violence in the story, not necessarily of sexual nature
    'work'    => 'Workplace',   # Story centres around a workplace setting
    'workplace' => 'Workplace',
    'sch'     => 'School',	# Mostly in an educational setting (high-school, college, University)
    'school'  => 'School',
    'schoolgirl' => 'School',
    'student' => 'School',
    'college' => 'School',
    'professor' => 'School',
    'university' => 'School',
    'secret'  => 'Secret',      # Secret or hidden or forbidden relationship
    'Secret'  => 'Secret',
    'Secret Love' => 'Secret',
    'Secret love' => 'Secret',
    'secret love' => 'Secret',
    'Forbidden Love' => 'Secret',
    'Forbidden love' => 'Secret',
    'forbidden love' => 'Secret',
    'trans'   => 'Transformation', # Un-natural physical transformation
    'prost'   => 'Prostitution', # Prostitution elements
    'prostitute' => 'Prostitution',
    'prostitution' => 'Prostitution',
    'nud'     => 'Nudism',      # Features scenes set in a naturist/nudist environment
    'nudism'  => 'Nudism',
    'nudist'  => 'Nudism',
    'Mil'     => 'Military',    # Story in a Military setting
    'military' => 'Military',
    'pornThea' => 'Porn Theatre', # Story has events in a porn theatre or Adult bookstore
    'cf'      => 'Cat-Fighting', # Women having a cat fight
    'catfight' => 'Cat-Fighting',
    'cannib'  => 'Cannibalism',	# Self explanatory
    'cannibalism' => 'Cannibalism',
);
hashvalue_key_self(\%sexcodes);

our %strangenames = (
    'brian d foy'	=> 'brian d foy',
    'brian d. foy'	=> 'brian d foy',
   );

our %strangefileas = (
    'foy, brian d'	=> 'd foy, brian',
    'foy, brian d.'	=> 'd foy, brian',
   );

our %validspecs = (
    'OEB12' => 'OEB12',
    'OPF20' => 'OPF20',
    'MOBI12' => 'MOBI12',
    );


#####################################################
########## CONSTRUCTORS AND INITIALIZATION ##########
#####################################################

my %rwfields = (
    'opffile'   => 'string', # OPF filename (with no path)
    'opfsubdir' => 'string', # Subdirectory name where opffile is found
    'erotic'    => 'scalar', # Enable special handling for erotic fiction
    'spec'      => 'string',
    );
my %rofields = (
    'topdir'   => 'string', # Top-level directory of the unpacked book
    'twig'     => 'scalar',
    'twig_unmodified' => 'scalar',
    'twigroot' => 'scalar',
    'errors'   => 'arrayref',
    'warnings' => 'arrayref',
    );
my %privatefields = (
);

# A simple 'use fields' will not work here: use takes place inside
# BEGIN {}, so the @...fields variables won't exist.
require fields;
fields->import(
    keys(%rwfields),keys(%rofields),keys(%privatefields)
    );


=head1 CONSTRUCTORS AND INITIALIZATION

=head2 C<new($filename)>

Instantiates a new EBook::Tools object.  If C<$filename> is specified,
it will also immediately initialize itself via the C<init> method.

=cut

sub new {
    my ($self,$filename) = @_;
    my $class = ref($self) || $self;
    my $subname = (caller(0))[3];
    debug(2,"DEBUG[",$subname,"]");
    my $bisg = EBook::Tools::BISG->new();

    $self = fields::new($class);

    if($filename) {
	debug(2,"DEBUG: new object from '",$filename,"'");
	$self->init($filename);
    }
    return $self;
}


=head2 C<init($filename)>

Initializes the object from an existing OPF file.  If C<$filename> is
specified and exists, the OEB object will be set to read and write to
that file before attempting to initialize.  Otherwise, if the object
currently points to an OPF file it will use that name.  If there is no
OPF filename data, and C<$filename> was not specified, it will make a
last-ditch attempt to find an OPF file first by looking in
META-INF/container.xml, and if nothing is found there, by looking in
the current directory for a single OPF file.

If no such files or found (or more than one is found), the
initialization croaks.

=cut

sub init :method {
    my ($self,$filename) = @_;
    my $fh_opffile;
    my $opfstring;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    $self->{topdir} = getcwd();

    if($filename) { $self->{opffile} = $filename; }

    if(!$self->{opffile})
    {
        $opfstring = find_opffile();
        $self->{opffile} = $opfstring if($opfstring);
    }

    if(!$self->{opffile})
    {
	croak($subname,"(): Unable to find an OPF file to work with!\n");
    }

    if(! -f $self->{opffile})
    {
	croak($subname,"(): '",$self->{opffile},
              "' does not exist or is not a regular file!")
    }

    if(-z $self->{opffile})
    {
	croak("OPF file '",$self->{opffile},"' has zero size!");
    }

    # At this point, we have definitely found an OPF file to work
    # with, but it might not be in the top level directory, and with
    # the exception of final book construction and EPUB metadata, we
    # want to be in the directory of the OPF.
    $self->{opfsubdir} = dirname($self->{opffile});
    $self->{opffile} = basename($self->{opffile});
    usedir($self->opfdir);

    debug(2,"DEBUG: init using '",$self->{opfsubdir},"/",$self->{opffile},"'");

    # Initialize the twig before use
    $self->{twig} = XML::Twig->new(
	keep_atts_order => 1,
	output_encoding => 'utf-8',
	pretty_print => 'record'
	);

    # Initialize a second copy to be used to check for changes
    $self->{twig_unmodified} = XML::Twig->new(
	keep_atts_order => 1,
	output_encoding => 'utf-8',
	pretty_print => 'record'
	);

    # Read and decode entities before parsing to avoid parsing errors
    open($fh_opffile,'<:encoding(:UTF-8)',$self->{opffile})
        or croak($subname,"(): failed to open '",$self->{opffile},
                 "' for reading!");
    read($fh_opffile,$opfstring,-s $self->opffile)
        or croak($subname,"(): failed to read from '",$self->{opffile},"'!");
    close($fh_opffile)
        or croak($subname,"(): failed to close '",$self->{opffile},"'!");

    # We use _decode_entities and the custom hash to decode, but also
    # see below for the regexp
    _decode_entities($opfstring,\%nonxmlentity2char);

    # This runs decode_entities on the substring containing just the
    # entity for every entity *except* the 5 predefined internal
    # entities.  It seems to be about the same speed as running
    # _decode_entities on a small file, but having the hash map as a
    # package variable has additional utility, so that technique gets
    # used instead.
#    $opfstring =~
#        s/(&
#            (?! (?:lt|gt|quot|apos|amp);
#            )\w+;
#          )
#         / decode_entities($1) /gex;

    $self->{twig}->parse($opfstring);
    $self->{twig_unmodified}->parse($opfstring);
    $self->{twigroot} = $self->{twig}->root;
    $self->opf_namespace;
    $self->twigcheck;
    debug(2,"DEBUG[/",$subname,"]");
    return $self;
}


=head2 C<init_blank(%args)>

Initializes an object containing nothing more than the basic OPF
framework, suitable for adding new documents when creating an e-book
from scratch.

=head3 Arguments

C<init_blank> takes up to three optional named arguments:

=over

=item C<opffile>

This specifies the OPF filename to use.  If not specified, defaults to
'content.opf'

=item C<author>

This specifies the content of the initial dc:creator element.  If not
specified, defaults to "Unknown Author".

=item C<title>

This specifies the content of the initial dc:title element. If not
specified, defaults to "Unknown Title".

=back

=head3 Example

 init_blank('opffile' => 'newfile.opf',
            'title' => 'The Great Unknown');

=cut

sub init_blank :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");


    my %valid_args = (
        'opffile' => 1,
        'author' => 1,
        'title' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    $args{opffile} ||= "content.opf";

    my $author = $args{author} || 'Unknown Author';
    my $title = $args{title} || 'Unknown Title';
    my $metadata;
    my $element;

    $self->{topdir} = getcwd();
    $self->{opfsubdir} = '.';
    $self->{opffile} = $args{opffile};
    $self->{twig} = XML::Twig->new(
	keep_atts_order => 1,
	output_encoding => 'utf-8',
	pretty_print => 'record'
        );
    $self->{twig_unmodified} = XML::Twig->new(
	keep_atts_order => 1,
	output_encoding => 'utf-8',
	pretty_print => 'record'
       );

    $element = XML::Twig::Elt->new('package');
    $self->{twig}->set_root($element);
    $self->{twig_unmodified}->set_root($element);
    $self->{twigroot} = $self->{twig}->root;
    $metadata = $self->{twigroot}->insert_new_elt('first_child','metadata');

    # dc:identifier
    $self->fix_packageid;

    # dc:title
    $element = $metadata->insert_new_elt('last_child','dc:title');
    $element->set_text($title);

    # dc:creator (author)
    $element = $metadata->insert_new_elt('last_child','dc:creator');
    $element->set_att('opf:role','aut');
    $element->set_text($author);

    $self->fix_opf20;
    return 1;
}


######################################
########## ACCESSOR METHODS ##########
######################################

=head1 ACCESSOR METHODS

The following methods return data deeper in the structure than the
auto-accessors, but still do not modify any object data or files.


=head2 C<adult()>

Returns the text of the Mobipocket-specific <Adult> element, if it
exists.  Expected values are 'yes' and undef.

=cut

sub adult :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my $twigroot = $self->{twigroot};

    my $element = $twigroot->first_descendant(qr/^adult$/ix);
    return unless($element);

    if($element->text) { return $element->text; }
    else { return; }
}


=head2 C<contributor_list()>

Returns a list containing the text of all dc:contributor elements
(case-insensitive) or undef if none are found.

In scalar context, returns the first contributor, not the last.

=cut

sub contributor_list :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my @retval = ();
    my $twigroot = $self->{twigroot};

    my @elements = $twigroot->descendants(qr/dc:contributor/ix);
    return unless(@elements);

    foreach my $el (@elements)
    {
        push(@retval,$el->text) if($el->text);
    }
    return unless(@retval);
    if(wantarray) { return @retval; }
    else { return $retval[0]; }
}


=head2 C<coverimage()>

Returns the href to the cover image, or undef if none is found.

Checks the following in order:

=over

=item <reference type="other.ms-coverimage-standard">

=item <EmbeddedCover>

=item <meta name="cover"> (as href)

=item <meta name="cover"> (as item id)

=back

=cut

sub coverimage :method {
    my ($self) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $twigroot = $self->{twigroot};
    my $element;
    my $href;
    my $id;

    $element = $twigroot->first_descendant('reference[@type="other.ms-coverimage-standard"]');
    $href = $element->att('href') if $element;
    return $href if $href;

    $element = $twigroot->first_descendant('EmbeddedCover');
    $href = $element->text if $element;
    return $href if $href;

    $element = $twigroot->first_descendant('meta[@name="cover"]');
    if($element) {
        if(-f $element->att('content')) {
            return $element->att('content');
        }
        $id = $element->att('content');
        $element = $twigroot->first_descendant("item[\@id='${id}']");
        $href = $element->att('href') if $element;
        return $href if $href;
    }
    return;
}


=head2 C<date_list(%args)>

Returns the text of all dc:date elements (case-insensitive) matching
the specified attributes.

In scalar context, returns the first match, not the last.

Returns undef if no matches are found.

=head3 Arguments

=over

=item * C<id> - 'id' attribute that must be matched exactly for the
result to be added to the list

=item * C<event> 'opf:event' or 'event' attribute that must be
matched exactly for the result to be added to the list

=back

If both arguments are specified a value is added to the list if it
matches either one (i.e. the logic is OR).

=cut

sub date_list :method {
    my ($self,%args) = @_;
    my %valid_args = (
        'id' => 1,
        'event' => 1,
        );
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my @elements = $self->{twigroot}->descendants(qr/^ dc:date $/ix);
    my @list = ();
    my $id;
    my $scheme;
    foreach my $el (@elements) {
        if($args{id}) {
            $id = $el->att('id') || '';
            if($id eq $args{id}) {
                push(@list,$el->text);
                next;
            }
        }
        if($args{event}) {
            $scheme = $el->att('opf:event') || $el->att('event') || '';
            if($scheme eq $args{event}) {
                push(@list,$el->text);
                next;
            }
        }
        next if($args{id} || $args{event});
        push(@list,$el->text);
    }
    return unless(@list);
    if(wantarray) { return @list; }
    else { return $list[0]; }
}


=head2 C<description()>

Returns the description of the e-book, if set, or undef otherwise.

=cut

sub description :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my $twigroot = $self->{twigroot};

    my $element = $twigroot->first_descendant(qr/^dc:description$/ix);
    return unless($element);

    if($element->text) { return $element->text; }
    else { return; }
}


=head2 C<element_list(%args)>

Returns a list containing the text values of all elements matching the
specified criteria.

=head3 Arguments

=over

=item * C<cond>

The L<XML::Twig> search condition used to find the elements.
Typically this is just the GI (tag) of the element you wish to find,
but it can also be a C<qr//> expression, coderef, or anything else
that XML::Twig can work with.  See the XML::Twig documentation for
details.

If this is not specified, an error is added and the method returns
undef.

=item * C<id> (optional)

'id' attribute that must be matched exactly for the
result to be added to the list

=item * C<scheme> (optional)

'opf:scheme' or 'scheme' attribute that must be
matched exactly for the result to be added to the list

=item * C<event> (optional)

'opf:event' or 'event' attribute that must be matched exactly for the
result to be added to the list

=back

If more than one of the arguments C<id>, C<scheme>, or C<event> are
specified a value is added to the list if it matches any one (i.e. the
logic is OR).

=cut

sub element_list :method {
    my ($self,%args) = @_;
    my %valid_args = (
        'cond' => 1,
        'id' => 1,
        'scheme' => 1,
        );
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }
    unless($args{cond}) {
        $self->add_error($subname,"(): no search condition specified");
        return;
    }

    my @elements = $self->{twigroot}->descendants($args{cond});
    my @list = ();
    my $id;
    my $scheme;
    foreach my $el (@elements) {
        if($args{id}) {
            $id = $el->att('id') || '';
            if($id eq $args{id}) {
                push(@list,$el->text);
                next;
            }
        }
        if($args{event}) {
            $scheme = $el->att('opf:event') || $el->att('event') || '';
            if($scheme eq $args{event}) {
                push(@list,$el->text);
                next;
            }
        }
        if($args{scheme}) {
            $scheme = $el->att('opf:scheme') || $el->att('scheme') || '';
            if($scheme eq $args{scheme}) {
                push(@list,$el->text);
                next;
            }
        }
        next if($args{id} || $args{event} || $args{scheme});
        push(@list,$el->text);
    }
    return unless(@list);
    if(wantarray) { return @list; }
    else { return $list[0]; }
}


=head2 C<errors()>

Returns an arrayref containing any generated error messages.

=cut

sub errors :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{errors};
}


=head2 C<identifier()>

Returns the text of the dc:identifier element pointed to by the
'unique-identifier' attribute of the root 'package' element, or undef
if it could not be located.

=cut

sub identifier :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my $identid = $self->{twigroot}->att('unique-identifier');
    return unless($identid);

    my $identifier = $self->{twig}->first_elt("*[\@id='$identid']");
    return unless($identifier);

    my $idtext = $identifier->text;
    return unless($idtext);

    return($idtext);
}


=head2 C<isbn_list(%args)>

Returns a list of all ISBNs matching the specified attributes.  See
L</twigelt_is_isbn()> for a detailed description of how the ISBN
elements are found.

Returns undef if no matches are found.

In scalar context returns the first match, not the last.

See also L</isbns(%args)>.

=head3 Arguments

=over

=item * C<id> (optional)

'id' attribute that must be matched exactly for the
result to be added to the list

=item * C<scheme> (optional)

'opf:scheme' or 'scheme' attribute that must be
matched exactly for the result to be added to the list

=back

If both arguments are specified a value is added to the list if it
matches either one (i.e. the logic is OR).

=cut

sub isbn_list :method {
    my ($self,%args) = @_;
    my %valid_args = (
        'id' => 1,
        'scheme' => 1,
        );
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my @list = $self->element_list(cond => \&twigelt_is_isbn,
                                   %args);
    return unless(@list);
    if(wantarray) { return @list; }
    else { return $list[0]; }
}


=head2 C<isbns(%args)>

Returns all of the ISBN identifiers matching the specificied
attributes as a list of hashrefs, with one hash per ISBN identifier
presented in the order that the identifiers are found.  The hash keys
are 'id' (containing the value of the 'id' attribute), 'scheme'
(containing the value of either the 'opf:scheme' or 'scheme'
attribute, whichever is found first), and 'isbn' (containing the text
of the element).

If no entries are found, returns undef.

In scalar context returns the first match, not the last.

See also L</isbn_list(%args)>.

=head3 Arguments

C<isbns()> takes two optional named arguments:

=over

=item * C<id> - 'id' attribute that must be matched exactly for the
result to be added to the list

=item * C<scheme> - 'opf:scheme' or 'scheme' attribute that must be
matched exactly for the result to be added to the list

=back

If both arguments are specified a value is added to the list if it
matches either one (i.e. the logic is OR).

=cut

sub isbns :method {
    my ($self,%args) = @_;
    my %valid_args = (
        'id' => 1,
        'scheme' => 1,
        );
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my @elements = $self->{twigroot}->descendants(\&twigelt_is_isbn);
    my @list = ();
    my $id;
    my $scheme;
    foreach my $el (@elements) {
        if($args{id}) {
            $id = $el->att('id') || '';
            if($id eq $args{id}) {
                push(@list,
                     {
                         'isbn' => $el->text,
                         'id'   => $el->att('id'),
                         'scheme'   => $el->att('scheme'),
                     });
                next;
            }
        }
        if($args{scheme}) {
            $scheme = $el->att('opf:scheme') || $el->att('scheme') || '';
            if($scheme eq $args{scheme}) {
                push(@list,
                     {
                         'isbn' => $el->text,
                         'id'   => $el->att('id'),
                         'scheme'   => $el->att('scheme'),
                     });
                next;
            }
        }
        next if($args{id} || $args{scheme});
        $scheme = $el->att('opf:scheme') || $el->att('scheme');
        push(@list,
             {
                 'isbn'   => $el->text,
                 'id'     => $el->att('id'),
                 'scheme' => $scheme,
             });
    }
    return unless(@list);
    if(wantarray) { return @list; }
    else { return $list[0]; }
}


=head2 C<languages()>

Returns a list containing the text of all dc:language
(case-insensitive) entries, or undef if none are found.

In scalar context returns the first match, not the last.

=cut

sub languages :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my @retval = ();
    my @elements = $self->{twigroot}->descendants(qr/^dc:language$/ix);
    foreach my $el (@elements) {
        push(@retval,$el->text) if($el->text);
    }
    return unless(@retval);
    if(wantarray) { return @retval; }
    else { return $retval[0]; }
}


=head2 C<manifest(%args)>

Returns all of the items in the manifest as a list of hashrefs, with
one hash per manifest item in the order that they appear, where the
hash keys are 'id', 'href', and 'media-type', each returning the
appropriate attribute, if any.

In scalar context, returns the first match, not the last.

=head3 Arguments

C<manifest()> takes four optional named arguments:

=over

=item * C<id> - 'id' attribute to match

=item * C<href> - 'href' attribute to match

=item * C<mtype> - 'media-type' attribute to match

=item * C<logic> - logic to use (valid values are 'and' or 'or', default: 'and')

=back

If any of the named arguments are specified, C<manifest()> will return
only items matching the specified criteria.  This is an exact
case-sensitive match, but it can (especially in the case of mtype)
still return multiple elements.

=head3 Return values

Returns undef if there is no <manifest> element directly underneath
<package>, or if <manifest> contains no items.

=head3 See also

L</manifest_hrefs()>, L</spine()>

=head3 Example

 @manifest = $ebook->manifest(id => 'ncx',
                              mtype => 'text/xml',
                              logic => 'or');

=cut

sub manifest :method {
    my ($self,%args) = @_;
    my %valid_args = (
        'id' => 1,
        'href' => 1,
        'mtype' => 1,
        'logic' => 1
        );
    my %valid_logic = (
        'and' => 1,
        'or' => 1
        );
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }
    if($args{logic}) {
        croak($subname,
              "(): logic must be 'and' or 'or' (got '",$args{logic},"')")
            if(!$valid_logic{$args{logic}});
    }
    else { $args{logic} = 'and'; }

    debug(1,"DEBUG: manifest() called with '",join(" ",keys(%args)),"'");

    my @elements;
    my @retarray;
    my $cond;

    if($args{id})
    {
        debug(1,"DEBUG: manifest searching on id");
        $cond = "item[\@id='$args{id}'";
    }
    if($args{href})
    {
        debug(1,"DEBUG: manifest searching on href");
        if($cond) { $cond .= " $args{logic} \@href='$args{href}'"; }
        else { $cond = "item[\@href='$args{href}'"; }
    }
    if($args{mtype})
    {
        debug(1,"DEBUG: manifest searching on mtype");
        if($cond) { $cond .= " $args{logic} \@media-type='$args{mtype}'"; }
        else { $cond = "item[\@media-type='$args{mtype}'"; }
    }
    if($cond) { $cond .= "]"; }
    else { $cond = "item"; }

    my $manifest = $self->{twigroot}->first_child('manifest');
    return unless($manifest);

    debug(1,"DEBUG: manifest search condition = '",$cond,"'");
    @elements = $manifest->children($cond);
    return unless(@elements);

    foreach my $el (@elements)
    {
        push(@retarray,
             {
                 'id' => $el->id,
                 'href' => $el->att('href'),
                 'media-type' => $el->att('media-type')
             });
    }
    if(wantarray) { return @retarray; }
    else { return $retarray[0]; }
}


=head2 C<manifest_hrefs()>

Returns a list of all of the hrefs in the current OPF manifest, or the
empty list if none are found.

In scalar context returns the first href, not the last.

See also: C<manifest()>, C<spine_idrefs()>

=cut

sub manifest_hrefs :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my @items;
    my $href;
    my $manifest;
    my $mimetype;
    my @retval = ();

    $manifest = $self->{twigroot}->first_child('manifest');
    if(! $manifest) { return @retval; }

    @items = $manifest->descendants('item');
    foreach my $item (@items) {
	$href = $item->att('href');
        if($href) {
            $mimetype = mimetype($href) || "UNKNOWN";
            debug(3,"DEBUG: '",$href,"' has mime-type '",$mimetype,"'");
            push(@retval,$href);
        }
    }
    debug(2,"DEBUG[/",$subname,"]");
    if(wantarray) { return @retval; }
    else { return $retval[0]; }
}


=head2 C<opf_namespace()>

Some OPF generators explicity assign 'opf:' in the gi as a prefix on
OPF elements.  This makes later parsing more complex and is
unnecessary, so this is stripped before any parsing takes place.

=cut

sub opf_namespace :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");

    my @elements = $self->{twig}->descendants(qr/^opf:/ix);
    foreach my $el (@elements)
    {
        my $gi = $el->gi;
        $gi =~ s/^opf:(.*)/$1/ix;
        $el->set_gi($gi);
    }
    return;
}


=head2 C<opfdir()>

Returns the full filesystem path to the directory where the OPF
metadata file will be stored, or undef if either the top-level
directory or the OPF subdirectory is not found.

=cut

sub opfdir :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");
    return unless($self->{topdir});
    return unless($self->{opfsubdir});

    if($self->{opfsubdir} eq '.') {
        return $self->{topdir};
    }
    return $self->{topdir} . '/' . $self->{opfsubdir};
}


=head2 C<opffile()>

Returns the name of the file where the OPF metadata will be stored or
undef if no value is found..

=cut

sub opffile :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");
    return unless($self->{opffile});
    return $self->{opffile};
}


=head2 C<opfpath()>

Returns the full filesystem path to the file where the OPF metadata
will be stored or undef if either the top level directory or the OPF
filename is not found.

=cut

sub opfpath :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");
    return unless($self->{topdir});
    return unless($self->{opfsubdir});
    return unless($self->{opffile});

    return $self->{topdir} . '/' . $self->{opfsubdir} . '/' . $self->{opffile};
}


=head2 C<primary_author()>

Finds the primary author of the book, defined as the first
'dc:creator' entry (case-insensitive) where either the attribute
opf:role="aut" or role="aut", or the first 'dc:creator' entry if no
entries with either attribute can be found.  Entries must actually
have text to be considered.

In list context, returns a two-item list, the first of which is the
text of the entry (the author name), and the second element of which
is the value of the 'opf:file-as' or 'file-as' attribute (where
'opf:file-as' is given precedence if both are present).

In scalar context, returns the text of the entry (the author name).

If no entries are found, returns undef.

Uses L</twigelt_is_author()> in the first half of the search.

=head3 Example

 my ($fileas, $author) = $ebook->primary_author;
 my $author = $ebook->primary_author;

=cut

sub primary_author :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $twigroot = $self->{twigroot};
    my $element;
    my $fileas;

    $element = $twigroot->first_descendant(\&twigelt_is_author);
    $element = $twigroot->first_descendant(qr/dc:creator/ix) if(!$element);
    if(! $element) {
        carp("## WARNING: no dc:creator elements found!");
        return;
    }
    if(! $element->text) {
        carp("## WARNING: dc:creator element is empty!");
        return;
    }
    $fileas = $element->att('opf:file-as');
    $fileas = $element->att('file-as') unless($fileas);
    if(wantarray) { return ($element->text, $fileas); }
    else { return $element->text; }
}


=head2 C<print_errors()>

Prints the current list of errors to STDERR.

=cut

sub print_errors :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $errorref = $self->{errors};

    if(!$self->errors) {
	debug(1,"DEBUG: no errors found!");
	return 1;
    }


    foreach my $error (@$errorref) {
	print "ERROR: ",$error,"\n";
    }
    return 1;
}


=head2 C<print_warnings()>

Prints the current list of warnings to STDERR.

=cut

sub print_warnings :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $warningref = $self->{warnings};

    if(!$self->warnings) {
	debug(2,"DEBUG: no warnings found!");
	return 1;
    }

    foreach my $warning (@$warningref) {
	print "WARNING: ",$warning,"\n";
    }
    return 1;
}


=head2 C<print_opf()>

Prints the OPF file to the default filehandle

=cut

sub print_opf :method {
    my $self = shift;
    my $filehandle = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    if(defined $filehandle) { $self->{twig}->print($filehandle); }
    else { $self->{twig}->print; }
    return 1;
}


=head2 C<publishers()>

Returns a list containing the text of all dc:publisher
(case-insensitive) entries, or undef if none are found.

In scalar context returns the first match, not the last.

=cut

sub publishers :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my @pubs = ();
    my @elements = $self->{twigroot}->descendants(qr/^dc:publisher$/ix);
    foreach my $el (@elements) {
        push(@pubs,$el->text) if($el->text);
    }
    return unless(@pubs);
    if(wantarray) { return @pubs; }
    else { return $pubs[0]; }
}


=head2 C<retailprice()>

Returns a two-scalar list, the first scalar being the text of the
Mobipocket-specific <SRP> element, if it exists, and the second being
the 'Currency' attribute of that element, if it exists.

In scalar context, returns just the text (price).

Returns undef if the SRP element is not found.

=cut

sub retailprice :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my $twigroot = $self->{twigroot};

    my $element = $twigroot->first_descendant(qr/^ SRP $/ix);
    return unless($element);
    if(wantarray) { return ($element->text,$element->att('Currency')); }
    else { return $element->text };
}


=head2 C<review()>

Returns the text of the Mobipocket-specific <Review> element, if it
exists.  Returns undef if one is not found.

=cut

sub review :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my $twigroot = $self->{twigroot};

    my $element = $twigroot->first_descendant(qr/^review$/ix);
    return unless($element);
    return $element->text;
}


=head2 C<< rights('id' => 'identifier') >>

Returns a list containing the text of all of dc:rights or
dc:copyrights (case-insensitive) entries in the e-book, or undef if
none are found.

In scalar context returns the first match, not the last.

If the optional named argument 'id' is specified, it will only return
entries where the id attribute matches the specified identifier.
Although this still returns a list, if more than one entry is found, a
warning is logged.

Note that dc:copyrights is not a valid Dublin Core element -- it is
included only because some broken Mobipocket books use it.

=cut

sub rights :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my %valid_args = (
        'id' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }


    my @rights = ();
    my $id = $args{id};
    my @elements = $self->{twigroot}->descendants(qr/^dc:(copy)?rights$/ix);

    foreach my $element (@elements)
    {
        if($id)
        {
            next if($element->att('id') ne $id);
            push @rights,$element->text if($element->text);
        }
        else { push @rights,$element->text if($element->text); }
    }

    if($id)
    {
        add_warning($subname
                     . "(): More than one rights entry found with id '"
                     . $id ."'" )
            if(scalar(@rights) > 1);
    }
    return unless(@rights);
    if(wantarray) { return @rights; }
    else { return $rights[0]; }
}


=head2 C<search_knownuids()>

Searches the OPF twig for the first dc:identifier (case-insensitive)
element with an ID matching known UID IDs.

Returns the ID if a match is found, undef otherwise

=cut

sub search_knownuids :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my @elements;

    @elements = $self->{twigroot}->descendants(\&twigelt_is_knownuid);
    return unless(@elements);
    debug(1,"DEBUG: found known UID '",$elements[0]->id,"'");
    return $elements[0]->id;
}


=head2 C<search_knownuidschemes()>

Searches descendants of the OPF twig element for the first
<dc:identifier> or <dc:Identifier> subelement with the attribute
'scheme' or 'opf:scheme' matching a known list of schemes for unique
IDs

NOTE: this is NOT a case-insensitive search!  If you have to deal with
really bizarre input, make sure that you run L</fix_oeb12()> or
L</fix_opf20()> before calling L</fix_packageid()> or L</fix_misc()>.

Returns the ID if a match is found, undef otherwise.

=cut

sub search_knownuidschemes :method {
    my ($self,$gi) = @_;
    if(!$gi) { $gi = 'dc:identifier'; }
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my $topelement = $self->{twigroot};

    my @knownuidschemes = (
        'GUID',
	'UUID',
	'FWID',
	);

    # Creating a regexp to search on works, but doesn't let you
    # specify priority.  For that, you really do have to loop.
#    my $schemeregexp = "(" . join('|',@knownuidschemes) . ")";

    my @elems;
    my $id;

    my $retval = undef;

    foreach my $scheme (@knownuidschemes) {
	debug(2,"DEBUG: searching for scheme='",$scheme,"'");
	@elems = $topelement->descendants(
            "dc:identifier[\@opf:scheme=~/$scheme/ix or \@scheme=~/$scheme/ix]"
            );
        push @elems, $topelement->descendants(
            "dc:Identifier[\@opf:scheme=~/$scheme/ix or \@scheme=~/$scheme/ix]"
            );
	foreach my $elem (@elems) {
	    debug(2,"DEBUG: working on scheme '",$scheme,"'");
	    if(defined $elem) {
		if($scheme eq 'FWID') {
		    # Fictionwise has a screwy output that sets the ID
		    # equal to the text.  Fix the ID to just be 'FWID'
		    debug(1,"DEBUG: fixing FWID");
		    $elem->set_id('FWID');
		}

		$id = $elem->id;
                unless(defined $id) {
		    debug(1,"DEBUG: assigning ID from scheme '",$scheme,"'");
		    $id = uc($scheme);
		    $elem->set_id($id);
                }
                $retval = $id;
		debug(1,"DEBUG: found Package ID: ",$id);
		last;
	    } # if(defined $elem)
	} # foreach my $elem (@elems)
	last if(defined $retval);
    }
    debug(2,"[/",$subname,"]");
    return $retval;
}


=head2 C<spec()>

Returns the version of the OEB specification currently in use.  Valid
values are C<OEB12> and C<OPF20>.  This value will default to undef
until C<fix_oeb12> or C<fix_opf20> is called, as there is no way for
the object to know what specification is being conformed to (if any)
until it attempts to enforce it.

=cut

sub spec :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{spec};
}


=head2 C<spine()>

Returns all of the manifest items referenced in the spine as a list of
hashrefs, with one hash per manifest item in the order that they
appear, where the hash keys are 'id', 'href', and 'media-type', each
returning the appropriate attribute, if any.

In scalar context, returns the first item, not the last.

Returns undef if there is no <spine> element directly underneath
<package>, or if <spine> contains no itemrefs.  If <spine> exists, but
<manifest> does not, or a spine itemref exists but points an ID not
found in the manifest, spine() logs an error and returns undef.

See also: L</spine_idrefs()>, L</manifest()>

=cut

sub spine :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $spine = $self->{twigroot}->first_child('spine');
    return unless($spine);
    my @spinerefs;
    my $idref;
    my $element;
    my @retarray;

    my $manifest = $self->{twigroot}->first_child('manifest');
    if(!$manifest)
    {
        $self->add_error(
            $subname . "(): <spine> found without <manifest>"
            );
        debug(1,"DEBUG: <spine> found without <manifest>!");
        return;
    }

    @spinerefs = $spine->children('itemref');
    return unless(@spinerefs);

    foreach my $spineref (@spinerefs)
    {
        $idref = $spineref->att('idref');
        if(!$idref)
        {
            $self->add_warning(
                $subname . "(): <itemref> found with no idref -- skipping"
                );
            debug(1,"DEBUG: <itemref> found with no idref -- skipping");
            next;
        }
        $element = $manifest->first_child("item[\@id='$idref']");
        if(!$element)
        {
            $self->add_error(
                $subname ."(): id '" . $idref . "' not found in manifest!"
                );
            debug(1,"DEBUG: id '",$idref," not found in manifest!");
            return;
        }
        push(@retarray,
             {
                 'id' => $element->id,
                 'href' => $element->att('href'),
                 'media-type' => $element->att('media-type')
             });
    }
    if(wantarray) { return @retarray; }
    else { return $retarray[0]; }
}


=head2 C<spine_idrefs()>

Returns a list of all of the idrefs in the current OPF spine, or the
empty list if none are found.

In scalar context, returns the first idref, not the last.

See also: L</spine()>, L</manifest_hrefs()>

=cut

sub spine_idrefs :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $spine = $self->{twigroot}->first_child('spine');;
    my @retval = ();
    my @itemrefs;
    my $idref;

    if(! $spine) { return @retval; }

    @itemrefs = $spine->children('itemref');
    foreach my $item (@itemrefs) {
	$idref = $item->att('idref');
	push(@retval,$idref) if($idref);
    }
    if(wantarray) { return @retval; }
    else { return $retval[0]; }
}


=head2 C<subject_list()>

Returns a list containing the text of all dc:subject elements or undef
if none are found.

In scalar context, returns the first subject, not the last.

=cut

sub subject_list :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my @retval = ();
    my $twigroot = $self->{twigroot};

    my @subjects = $twigroot->descendants(qr/dc:subject/ix);
    return unless(@subjects);

    foreach my $subject (@subjects) {
        push(@retval,$subject->text) if($subject->text);
    }
    return unless(@retval);
    if(wantarray) { return @retval; }
    else { return $retval[0]; }
}


=head2 C<title()>

Returns the title of the e-book, or undef if no dc:title element
(case-insensitive) exists.  If a dc:title element exists, but contains
no text, returns an empty string.

=cut

sub title :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my $twigroot = $self->{twigroot};
    my $retval;

    my $element = $twigroot->first_descendant(qr/^dc:title$/ix);
    return unless($element);
    $retval = $element->text || '';
    $retval = trim($retval);
    return $retval;
}


=head2 C<twig()>

Returns the raw L<XML::Twig> object used to store the OPF metadata.

Although this twig can be manipulated via the standard XML::Twig
methods, doing so requires caution and is not recommended.  In
particular, changing the root element from here will cause the
EBook::Tools internal twig and twigroot attributes to become unlinked
and the result of any subsequent action is not defined.

=cut

sub twig :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{twig};
}


=head2 C<twigcheck()>

Croaks showing the calling location unless C<$self> has both a twig and a
twigroot, and the twigroot is <package>.  Used as a sanity check for
methods that use twig or twigroot.

=cut

sub twigcheck :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");

    my @calledfrom = caller(1);
    croak("twigcheck called from unknown location") if(!@calledfrom);

    croak($calledfrom[3],"(): undefined twig")
        if(!$self->{twig});
    croak($calledfrom[3],"(): twig isn't a XML::Twig")
        if( (ref $self->{twig}) ne 'XML::Twig' );
    croak($calledfrom[3],"(): twig root missing")
        if(!$self->{twigroot});
    croak($calledfrom[3],"(): twig root isn't a XML::Twig::Elt")
        if( (ref $self->{twigroot}) ne 'XML::Twig::Elt' );
    croak($calledfrom[3],"(): twig root is '" . $self->{twigroot}->gi
          . "' (needs to be 'package')")
        if($self->{twigroot}->gi ne 'package');
    debug(3,"DEBUG[/",$subname,"]");
    return 1;
}


=head2 C<twigroot()>

Returns the raw L<XML::Twig> root element used to store the OPF
metadata.

This twig element can be manipulated via the standard XML::Twig::Elt
methods, but care should be taken not to attempt to cut this element
from its twig as doing so will cause the EBook::Tools internal twig
and twigroot attributes to become unlinked and the result of any
subsequent action is not defined.

=cut

sub twigroot :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{twigroot};
}


=head2 C<warnings()>

Returns an arrayref containing any generated warning messages.

=cut

sub warnings :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    return $self->{warnings};
}


######################################
########## MODIFIER METHODS ##########
######################################

=head1 MODIFIER METHODS

Unless otherwise specified, all modifier methods return undef if an
error was added to the error list, and true otherwise (even if a
warning was added to the warning list).


=head2 C<add_document($href,$id,$mediatype)>

Adds a document to the OPF manifest and spine, creating <manifest> and
<spine> if necessary.  To add an item only to the OPF manifest, see
add_item().

=head3 Arguments

=over

=item C<$href>

The href to the document in question.  Usually, this is just a
filename (or relative path and filename) of a file in the current
working directory.  If you are planning to eventually generate a .epub
book, all hrefs MUST be in or below the current working directory.

The method returns undef if $href is not defined or empty.

=item C<$id>

The XML ID to use.  If not specified, defaults to the href with
invalid characters removed.

This must be unique not only to the manifest list, but to every
element in the OPF file.  If a duplicate ID exists, the method sets an
error and returns undef.

=item C<$mediatype> (optional)

The mime type of the document.  If not specified, will attempt to
autodetect the mime type, and if that fails, will default to
'application/xhtml+xml'.

=back

=cut

sub add_document :method {
    my ($self,$href,$id,$mediatype) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    $href = trim($href);
    return unless($href);

    my $twig = $self->{twig};
    my $topelement = $self->{twigroot};
    my $element;

    $id = $href unless($id);
    $id =~ s/[^\w.-]//gx; # Delete all nonvalid XML 1.0 namechars
    $id =~ s/^[.\d -]+//gx; # Delete all nonvalid XML 1.0 namestartchars

    $element = $twig->first_elt("*[\@id='$id']");
    if($element)
    {
        $self->add_error(
            $subname . "(): ID '" . $id . "' already exists"
            . " (in a '" . $element->gi ."' tag)"
            );
        return;
    }

    if(!$mediatype)
    {
	my $mimetype = mimetype($href);
	if($mimetype) { $mediatype = $mimetype; }
	else { $mediatype = "application/xhtml+xml"; }
	debug(2,"DEBUG: '",$href,"' has mimetype '",$mimetype,"'");
    }

    my $manifest = $topelement->first_child('manifest');
    $manifest = $topelement->insert_new_elt('last_child','manifest')
        if(!$manifest);
    my $spine = $topelement->first_child('spine');
    $spine = $topelement->insert_new_elt('last_child','spine')
        if(!$spine);

    my $item = $manifest->insert_new_elt('last_child','item');
    $item->set_id($id);
    $item->set_att(
	'href' => $href,
	'media-type' => $mediatype
	);

    my $itemref = $spine->insert_new_elt('last_child','itemref');
    $itemref->set_att('idref' => $id);

    return 1;
}


=head2 C<add_error(@errors)>

Adds @errors to the list of object errors.  Each member of
@errors should be a string containing the entire text of the
error, with no ending newline.

SEE ALSO: L</add_warning()>, L</clear_errors()>, L</clear_warnerr()>

=cut

sub add_error :method {
    my ($self,@newerror) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");

    my $currenterrors;
    $currenterrors = $self->{errors} if($self->{errors});

    if(@newerror) {
        my $error = join('',@newerror);
	debug(1,"ERROR: ",$error);
	push(@$currenterrors,$error);
    }
    $self->{errors} = $currenterrors;
    return 1;
}


=head2 C<add_identifier(%args)>

Creates a new dc:identifier element containing the specified text, id,
and scheme.

If a <dc-metadata> element exists underneath <metadata>, the
identifier element will be created underneath the <dc-metadata> in OEB
1.2 format, otherwise the title element is created underneath
<metadata> in OPF 2.0 format.

Returns the twig element containing the new identifier.

=head3 Arguments

C<add_identifier()> takes three named arguments, one mandatory, two
optional.

=over

=item * C<text> - the text of the identifier.  This is mandatory, and
the method croaks if it is not present.

=item * C<scheme> - 'opf:scheme' or 'scheme' attribute to be added (optional)

=item * C<id> - 'id' attribute to be added.  If this is specified, and
the id is already in use, a warning will be added but the method will
continue, removing the id attribute from the element that previously
contained it.

=back

=cut

sub add_identifier :method {
    my ($self,%args) = @_;
    my %valid_args = (
        'text' => 1,
        'id' => 1,
        'scheme' => 1,
        );
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }
    croak($subname,"(): identifier text not specified")
        unless($args{text});

    $self->fix_metastructure_basic();
    my $meta = $self->{twigroot}->first_child('metadata');
    my $dcmeta = $meta->first_child('dc-metadata');
    my $element;
    my $idelem;
    my $newid = $args{id};
    $idelem = $self->{twig}->first_elt("*[\@id='$newid']") if($newid);

    if($dcmeta) {
        $element = $dcmeta->insert_new_elt('last_child','dc:Identifier');
        $element->set_att('scheme' => $args{scheme}) if($args{scheme});
    }
    else {
        $element = $meta->insert_new_elt('last_child','dc:identifier');
        $element->set_att('opf:scheme' => $args{scheme}) if($args{scheme});
    }
    $element->set_text($args{text});

    if($idelem && $idelem->cmp($element) ) {
        $self->add_warning(
            $subname,"(): reassigning id '",$newid,
            "' from a '",$idelem->gi,"' element!"
            );
        $idelem->del_att('id');
    }
    $element->set_att('id' => $newid) if($newid);

    return $element;
}


=head2 C<add_item($href,$id,$mediatype)>

Adds a document to the OPF manifest (but not spine), creating
<manifest> if necessary.  To add an item only to both the OPF manifest
and spine, see add_document().

=head3 Arguments

=over

=item C<$href>

The href to the document in question.  Usually, this is just a
filename (or relative path and filename) of a file in the current
working directory.  If you are planning to eventually generate a .epub
book, all hrefs MUST be in or below the current working directory.

=item C<$id>

The XML ID to use.  If not specified, defaults to the href with all
nonword characters removed.

This must be unique not only to the manifest list, but to every
element in the OPF file.  If a duplicate ID exists, the method sets an
error and returns undef.

=item C<$mediatype> (optional)

The mime type of the document.  If not specified, will attempt to
autodetect the mime type, and if that fails, will set an error and
return undef.

=back

=cut

sub add_item :method {
    my ($self,$href,$id,$mediatype) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    $href = trim($href);
    return unless($href);

    my $twig = $self->{twig};
    my $topelement = $self->{twigroot};
    my $element;

    $id = $href unless($id);
    $id =~ s/[^\w.-]//gx; # Delete all nonvalid XML 1.0 namechars
    if($id =~ /^[.\d -]+/x) {
       # We're starting with a nonvalid XML 1.0 namestartchar, so
       # prefix with id_
        $id = 'id_' . $id;
    }

    $element = $twig->first_elt("*[\@id='$id']");
    if($element) {
        $self->add_error(
            $subname . "(): ID '" . $id . "' already exists"
            . " (in a '" . $element->gi ."' tag)"
            );
        debug(2,"DEBUG[/",$subname,"]");
        return;
    }

    if(!$mediatype) {
	my $mimetype = mimetype($href);
	if($mimetype) { $mediatype = $mimetype; }
	else { $mediatype = "application/xhtml+xml"; }
	debug(2,"DEBUG: '",$href,"' has mimetype '",$mediatype,"'");
    }

    my $manifest = $self->{twigroot}->first_child('manifest');
    $manifest = $topelement->insert_new_elt('last_child','manifest')
        if(!$manifest);

    debug(2,"DEBUG: adding item '",$id,"': '",$href,"'");
    my $item = $manifest->insert_new_elt('last_child','item');
    $item->set_id($id);
    $item->set_att(
	'href' => $href,
	'media-type' => $mediatype
	);

    debug(3,"DEBUG[/",$subname,"]");
    return 1;
}


=head2 add_metadata(%args)

Creates a metadata element with the specified text, attributes, and parent.

If a <dc-metadata> element exists underneath <metadata>, the language
element will be created underneath the <dc-metadata> and any standard
attributes will be created in OEB 1.2 format, otherwise the element is
created underneath <metadata> in OPF 2.0 format.

Returns 1 on success, returns undef if no gi or if no text was specified.

=cut

=head3 Arguments

=over

=item C<gi>

The generic identifier (tag) of the metadata element to alter or
create.  If not specified, the method sets an error and returns undef.

=item C<parent>

The generic identifier (tag) of the parent to use for any newly
created element.  If not specified, defaults to 'dc-metadata' if
'dc-metadata' exists underneath 'metadata', and 'metadata' otherwise.

A newly created element will be created under the first element found
with this gi.  A modified element will be moved under the first
element found with this gi.

Newly created elements will use OPF 2.0 attribute names if the parent
is 'metadata' and OEB 1.2 attribute names otherwise.

=item C<text>

This specifies the element text to set.  If not specified, the method
sets an error and returns undef.

=item C<id> (optional)

This specifies the ID to set on the element.  If set and the ID is
already in use, a warning is logged and the ID is removed from the
other location and assigned to the element.

=item C<fileas> (optional)

This specifies the file-as attribute to set on the element.

=item C<role> (optional)

This specifies the role attribute to set on the element.

=item C<scheme> (optional)

This specifies the scheme attribute to set on the element.

=back

=head3 Example

 $retval = $ebook->add_metadata(gi => 'AuthorNonstandard',
                                text => 'Element Text',
                                id => 'customid',
                                fileas => 'Text, Element',
                                role => 'xxx',
                                scheme => 'code');

=cut

sub add_metadata :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");
    my %valid_args = (
        'gi' => 1,
        'parent' => 1,
        'text' => 1,
        'id' => 1,
        'fileas' => 1,
        'role' => 1,
        'scheme' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $gi = $args{gi};
    unless($gi) {
        $self->add_error($subname,"(): no gi specified");
        return;
    }

    my $text = $args{text};
    unless($text) {
        $self->add_error($subname,"(): no text specified");
        return;
    }

    my $newid = $args{id};
    my $idelem;
    my $element;
    my $meta;
    my $dcmeta;
    my $parent;
    my %dcatts;

    $self->fix_metastructure_basic();
    $parent =  $self->{twigroot}->first_descendant(qr/^ $args{parent} $/ix)
        if($args{parent});
    $meta = $self->{twigroot}->first_child('metadata');
    $dcmeta = $meta->first_child('dc-metadata');
    $parent = $parent || $dcmeta || $meta;
    if($parent->gi eq 'metadata') {
        %dcatts = (
            'file-as' => 'opf:file-as',
            'role' => 'opf:role',
            'scheme' => 'opf:scheme',
            );
    }
    else {
        %dcatts = (
            'file-as' => 'file-as',
            'role' => 'role',
            'scheme' => 'scheme'
        );
    }

    debug(2,"DEBUG: creating '",$gi,"' under <",$parent->gi,">");
    $element = $parent->insert_new_elt('last_child',$gi);
    $element->set_att($dcatts{'file-as'},$args{fileas})
        if($args{fileas});
    $element->set_att($dcatts{'role'},$args{role})
        if($args{role});
    $element->set_att($dcatts{'scheme'},$args{scheme})
        if($args{scheme});
    $element->set_text($text);

    $idelem = $self->{twig}->first_elt("*[\@id='$newid']") if($newid);
    if($idelem && $idelem->cmp($element) ) {
        $self->add_warning(
            $subname,"(): reassigning id '",$newid,
            "' from a '",$idelem->gi,"' to a '",$element->gi,"'!"
            );
        $idelem->del_att('id');
    }
    $element->set_att('id' => $newid) if($newid);
    return 1;
}


=head2 C<add_subject(%args)>

Creates a new dc:subject element containing the specified text, code,
and id.

If a <dc-metadata> element exists underneath <metadata>, the
subject element will be created underneath the <dc-metadata> in OEB
1.2 format, otherwise the title element is created underneath
<metadata> in OPF 2.0 format.

Returns the twig element containing the new subject.

=head3 Arguments

C<add_subject()> takes four named arguments, one mandatory, three
optional.

=over

=item * C<text> - the text of the subject.  This is mandatory, and
the method croaks if it is not present.

=item * C<scheme> (optional) - 'opf:scheme' or 'scheme' attribute to
be added.  Be warned that neither the OEB 1.2 nor the OPF 2.0
specifications allow a scheme to be added to this element, so if this
is specified, the resulting OPF file will fail to validate against
either standard.

=item * C<basiccode> (optional) - 'BASICCode' attribute to be added.
Be warned that this is a Mobipocket-specific attribute that does not
exist in either the OEB 1.2 nor the OPF 2.0 specifications, so if this
is specified, the resulting OPF file will fail to validate against
either standard.

=item * C<id> (optional) - 'id' attribute to be added.  If this is
specified, and the id is already in use, a warning will be added but
the method will continue, removing the id attribute from the element
that previously contained it.

=back

=cut

sub add_subject :method {
    my ($self,%args) = @_;
    my %valid_args = (
        'text' => 1,
        'id' => 1,
        'scheme' => 1,
        'basiccode' => 1,
        );
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }
    croak($subname,"(): subject text not specified")
        unless($args{text});

    $self->fix_metastructure_basic();
    my $meta = $self->{twigroot}->first_child('metadata');
    my $dcmeta = $meta->first_child('dc-metadata');
    my $element;
    my $idelem;
    my $newid = $args{id};
    $idelem = $self->{twig}->first_elt("*[\@id='$newid']") if($newid);

    if($dcmeta) {
        $element = $dcmeta->first_child('dc:Subject[string()="' . $args{text} .  '"]');
        if(! $element) {
            $element = $dcmeta->insert_new_elt('last_child','dc:Subject');
        }
        $element->set_att('scheme' => $args{scheme}) if($args{scheme});
    }
    else {
        $element = $meta->first_child('dc:subject[string()="' . $args{text} .  '"]');
        if(! $element) {
            $element = $meta->insert_new_elt('last_child','dc:subject');
        }
        $element->set_att('opf:scheme' => $args{scheme}) if($args{scheme});
    }
    $element->set_text($args{text});
    $element->set_att('BASICCode' => $args{basiccode}) if($args{basiccode});

    if($idelem && $idelem->cmp($element) ) {
        $self->add_warning(
            $subname,"(): reassigning id '",$newid,
            "' from a '",$idelem->gi,"' element!"
            );
        $idelem->del_att('id');
    }
    $element->set_att('id' => $newid) if($newid);

    return $element;
}


=head2 C<add_warning(@newwarning)>

Joins @newwarning to a single string and adds it to the list of object
warnings.  The warning should not end with a newline newline.

SEE ALSO: L</add_error()>, L</clear_warnings()>, L</clear_warnerr()>

=cut

sub add_warning :method {
    my ($self,@newwarning) = @_;
    my $subname = (caller(0))[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");

    my @currentwarnings;
    @currentwarnings = @{$self->{warnings}} if($self->{warnings});

    if (@newwarning) {
        my $warning = join('',@newwarning);
	debug(1,"WARNING: ",$warning);
	push(@currentwarnings,$warning);
    }
    $self->{warnings} = \@currentwarnings;

    debug(3,"DEBUG[/",$subname,"]");
    return 1;
}


=head2 C<clear_errors()>

Clear the current list of errors

=cut

sub clear_errors :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    $self->{errors} = ();
    return 1;
}


=head2 C<clear_warnerr()>

Clear both the error and warning lists

=cut

sub clear_warnerr :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    $self->{errors} = ();
    $self->{warnings} = ();
    return 1;
}


=head2 C<clear_warnings()>

Clear the current list of warnings

=cut

sub clear_warnings :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    $self->{warnings} = ();
    return 1;
}


=head2 C<delete_meta_filepos()>

Deletes metadata elements with the attribute 'filepos' underneath
the given parent element

These are secondary metadata elements included in the output from
mobi2html may that are not used.

=cut

sub delete_meta_filepos :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my @elements = $self->{twigroot}->descendants('metadata[@filepos]');
    foreach my $el (@elements) {
	$el->delete;
    }
    return 1;
}


=head2 C<delete_subject(%args)>

Deletes dc:subject and dc:Subject elements based on text content or
the id, scheme, or basiccode attributes.  Matches are case-sensitive.

Specifying multiple arguments will delete subject matching any of them.

This has the same potential arguments as add_subject.

Returns the count of elements deleted.

=cut

sub delete_subject :method {
    my ($self,%args) = @_;
    my %valid_args = (
        'text' => 1,
        'id' => 1,
        'scheme' => 1,
        'basiccode' => 1,
        );
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my @elements;
    my $count = 0;

    if(defined $args{text}) {
        @elements = $self->{twigroot}->descendants('dc:subject[text()="' . $args{text} . '"]');
        foreach my $el (@elements) {
            $el->delete;
            $count++;
        }
        @elements = $self->{twigroot}->descendants('dc:Subject[text()="' . $args{text} . '"]');
        foreach my $el (@elements) {
            $el->delete;
            $count++;
        }
    }

    if($args{id}) {
        @elements = $self->{twigroot}->descendants('dc:subject[@id="' . $args{id} . '"]');
        foreach my $el (@elements) {
            $el->delete;
            $count++;
        }
        @elements = $self->{twigroot}->descendants('dc:Subject[@id="' . $args{id} . '"]');
        foreach my $el (@elements) {
            $el->delete;
            $count++;
        }
    }

    if($args{scheme}) {
        @elements = $self->{twigroot}->descendants('dc:subject[@scheme="' . $args{scheme} . '"]');
        foreach my $el (@elements) {
            $el->delete;
            $count++;
        }
        @elements = $self->{twigroot}->descendants('dc:subject[@opf:scheme="' . $args{scheme} . '"]');
        foreach my $el (@elements) {
            $el->delete;
            $count++;
        }
        @elements = $self->{twigroot}->descendants('dc:Subject[@scheme="' . $args{scheme} . '"]');
        foreach my $el (@elements) {
            $el->delete;
            $count++;
        }
        @elements = $self->{twigroot}->descendants('dc:Subject[@opf:scheme="' . $args{scheme} . '"]');
        foreach my $el (@elements) {
            $el->delete;
            $count++;
        }
    }

    if($args{basiccode}) {
        @elements = $self->{twigroot}->descendants('dc:subject[@BASICCode="' . $args{id} . '"]');
        foreach my $el (@elements) {
            $el->delete;
            $count++;
        }
        @elements = $self->{twigroot}->descendants('dc:Subject[@BASICCode="' . $args{id} . '"]');
        foreach my $el (@elements) {
            $el->delete;
            $count++;
        }
    }
    debug(2,"DEBUG: Deleted ",$count," elements");
    return $count;
}


=head2 C<fix_creators()>

Normalizes creator and contributor names and file-as attributes

Names are normalized to 'First Last' format, while file-as attributes
are normalized to 'Last, First' format.

This can damage some unusual names that do not match standard
capitalization formats, so it is not made part of L</fix_misc()>.

=cut

sub fix_creators :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $twigroot = $self->{twigroot};
    my @elements = $twigroot->descendants(qr/dc:(creator|contributor)/ix);
    my $nameparse = Lingua::EN::NameParse->new(
        allow_reversed  => 1,
        extended_titles => 1,
        force_case      => 1,
        lc_prefix       => 1,
       );
    foreach my $el (@elements) {
        my $fileas = $el->att('opf:file-as') || '';
        my $name = $el->text || '';
        my $fixed;
        $name = trim($name);

        if ( $nameparse->parse($name) ) {
	    $self->add_warning(
                "failure while parsing name: ",
                {$nameparse->properties}->{non_matching});
        }
        else {
            $fixed = $nameparse->case_all;
            if($fixed and $strangenames{lc $fixed}) {
                $fixed = $strangenames{lc $fixed};
            }
            debug(2,"DEBUG: creator name '",$name,"' -> '",
                  $fixed,"'");
            $el->set_text($fixed);

            $fixed = $nameparse->case_all_reversed;
            if($fixed and $strangefileas{lc $fixed}) {
                $fixed = $strangefileas{lc $fixed};
            }
            if($fixed) {
                debug(2,"DEBUG: creator file-as '",$fileas,"' -> '",
                      $fixed,"'");
                $el->set_att('opf:file-as',$fixed);
            }
            else {
                debug(2,"DEBUG: removing empty creator file-as from creator '",
                      $name,"'");
                $el->del_att('opf:file-as');
            }
        }
    }
    return;
}


=head2 C<fix_dates()>

Standardizes all <dc:date> elements via fix_datestring().  Adds a
warning to the object for each date that could not be fixed.

Called from L</fix_misc()>.

=cut

sub fix_dates :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my @dates;
    my $newdate;

    @dates = $self->{twigroot}->descendants('dc:date');
    push(@dates,$self->{twigroot}->descendants('dc:Date'));

    foreach my $dcdate (@dates) {
	if(!$dcdate->text) {
	    $self->add_warning(
                "WARNING: found dc:date with no value -- skipping");
	}
	else {
	    $newdate = fix_datestring($dcdate->text);
	    if(!$newdate) {
		$self->add_warning(
		    sprintf("fixmisc(): can't deal with date '%s' -- skipping",
                            $dcdate->text)
		    );
	    }
	    elsif($dcdate->text ne $newdate) {
		debug(2,"DEBUG: setting date from '",$dcdate->text,
                      "' to '",$newdate,"'");
		$dcdate->set_text($newdate);
	    }
	}
    }
    return 1;
}


=head2 C<fix_guide()>

Fixes problems related to the OPF guide elements, specifically:

=over

=item * Ensures the guide element exists

=item * Moves all reference elements directly underneath the guide element

=item * Finds nonstandard reference types and either converts them to
standard or prefaces them with 'other.'

=item * Finds reference elements with a href with only an anchor
portion and assigns them to the first spine href.  This only works if
the spine is in working condition, so it may be wise to run
L</fix_spine()> before C<fix_guide()> if the input is expected to be
very badly broken.

=back

Logs a warning if a reference href is found that does not appear in
the manifest.

=cut

sub fix_guide :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $twigroot = $self->{twigroot};
    my $guide = $twigroot->first_descendant('guide');
    my $parent;
    my $href;
    my $type;
    my @spine;

    # If <guide> doesn't exist, create it
    unless($guide) {
        debug(1,"DEBUG: creating <guide>");
        $guide = $twigroot->insert_new_elt('last_child','guide');
    }

    # Make sure that the guide is a child of the twigroot,
    $parent = $guide->parent;
    if( $parent->cmp($twigroot) ) {
        debug(1,"DEBUG: moving <guide>");
        $guide->move('last_child',$twigroot);
    }


    my @elements = $twigroot->descendants(qr/^reference$/ix);
    foreach my $el (@elements) {
        $type = $el->att('type');
        if($referencetypes{$type}) {
            $el->set_att('type',$referencetypes{$type});
        }
        elsif($type !~ /^other./x) {
            $type = 'other.' . $type;
            $el->set_att('type',$type);
        }

        $href = $el->att('href');
        if (!$href) {
            # No href means it is broken.
            # Leave it alone, but log a warning
            $self->add_warning(
                "fix_guide(): <reference> with no href -- skipping");
            next;
        }
        if ($href =~ /^#/) {
            # Anchor-only href.  Attempt to fix from the first
            # spine entry
            @spine = $self->spine;
            if (!@spine) {
                $self->add_warning(
                    "fix_guide(): Cannot correct reference href '",$href,
                    "', spine is empty");
            }
            elsif (!$spine[0]->{href}) {
                $self->add_warning(
                    "fix_guide(): Cannot correct reference href '",$href,
                    "', cannot find href for first spine entry");
            }
            else {
                debug(1,"DEBUG: correcting reference href from '",$href,
                      "' to '",$spine[0]->{href} . $href,"'");
                $el->set_att('href',$spine[0]->{href} . $href);
            }
        }
        debug(3,"DEBUG: processing reference '",$href,"')");
        $el->move('last_child',$guide);
    } # foreach my $el (@elements)

    return 1;
}


=head2 C<fix_languages(%args)>

Checks through the <dc:language> elements (case-insensitive) and
removes any duplicates.  If no <dc:language> elements are found, one
is created.

TODO: Also convert language names to IANA language and region codes.

=head3 Arguments

=over

=item * C<default>

The default language string to use when creating a new language
element.  If not specified, defaults to 'en'.

=back

=cut

sub fix_languages :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my %valid_args = (
        'default' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $twigroot = $self->{twigroot};
    my $defaultlang = $args{default} || 'en';
    my $langel;
    my @elements = $twigroot->descendants(qr/dc:language/ix);
    while($langel = shift(@elements) ) {
        foreach my $el (@elements) {
            $el->delete if(twigelt_detect_duplicate($el,$langel) );
        }
    }

    @elements = $self->languages;
    if(!@elements) {
        $self->set_language(text => $defaultlang);
    }
    return 1;
}


=head2 C<fix_links()>

Checks through the links in the manifest and checks them for anything
they might link to, adding anything missing to the manifest.

A warning is added for every manifest item missing a href.

If no <manifest> element exists directly underneath the <package>
root, or <manifest> contains no items, the method logs a warning and
returns undef.  Otherwise, it returns 1.

=cut

sub fix_links :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $twigroot = $self->{twigroot};

    my $manifest = $twigroot->first_child('manifest');
    my @unchecked;

    # The %links hash points a href to one of three values:
    # * undef : the link has not been checked at all
    # * 0 : the link has been checked and is not reachable
    # * 1 : the link has been checked and exists
    my %links;
    my @newlinks;
    my $href;
    my $mimetype;

    my %linking_mimetypes = (
        'text/html' => 1,
        'text/xhtml' => 1,
        'text/xml' => 1,
        'text/x-oeb1-document' => 1,
        'application/atom+xml' => 1,
        'application/xhtml+xml' => 1,
        'application/xml' => 1
        );

    if(!$manifest) {
        $self->add_warning(
            "fix_links(): no manifest found!"
            );
        return;
    }

    @unchecked = $self->manifest_hrefs;
    if(!@unchecked) {
        $self->add_warning(
            "fix_links(): empty manifest found!"
            );
        return;
    }

    # Initialize %links, so we don't try to add something already in
    # the manifest
    foreach my $mhref (@unchecked) {
        $mhref = uri_unescape($mhref);
        $links{$mhref} = undef unless(exists $links{$mhref});
    }

    while(@unchecked) {
        debug(3,"DEBUG: ",scalar(@unchecked),
              " items left to check at start of loop");
        $href = shift(@unchecked);
        $href = trim($href);
        $href = uri_unescape($href);
        debug(3,"DEBUG: checking '",$href,"'");
        next if(defined $links{$href});

        # Skip mailto: and news: links
        if($href =~ m#(mailto|news):#ix) {
            debug(1,"DEBUG: mailto link '",$href,"' skipped");
            $links{$href} = 0;
            next;
        }

        # Skip URIs for now
        if($href =~ m#^ \w+://#ix) {
            debug(1,"DEBUG: URI '",$href,"' skipped");
            $links{href} = 0;
            next;
        }
        if(! -f $href) {
            $self->add_warning(
                "fix_links(): '" . $href . "' not found"
                );
            $links{$href} = 0;
            next;
        }

        $mimetype = mimetype($href);

        if(!$linking_mimetypes{$mimetype}) {
            debug(2,"DEBUG: '",$href,"' has mimetype '",$mimetype,
                "' -- not checking");
            $links{$href} = 1;
            next;
        }

        debug(1,"DEBUG: finding links in '",$href,"'");
        @newlinks = find_links($href);
        trim(@newlinks) if(@newlinks);
        $links{$href} = 1;
        foreach my $newlink (sort @newlinks) {
            # Skip mailto: and news: links
            if($newlink =~ m#(mailto|news):#ix) {
                debug(1,"DEBUG: mailto link '",$href,"' skipped");
                next;
            }
            # Skip URIs for now
            elsif($newlink =~ m#^ \w+://#ix) {
                debug(1,"DEBUG: URI '",$newlink,"' skipped");
                next;
            }
            elsif(!exists $links{$newlink}) {
                debug(2,"DEBUG: adding '",$newlink,"' to the manifest");
                push(@unchecked,$newlink);
                $self->add_item($newlink);
                $links{$newlink} = 1;
            }
        }
        debug(2,"DEBUG: ",scalar(@unchecked),
            " items left to check at end of loop");
    } # while(@unchecked)
    debug(2,"DEBUG[/",$subname,"]");
    return 1;
}

=head2 C<fix_manifest()>

Finds all <item> elements and moves them underneath <manifest>,
creating <manifest> if necessary.

Logs a warning but continues if it finds an <item> with a missing id
or href attribute.  If both id and href attributes are missing, logs a
warning, skips moving the item entirely (unless it was already
underneath <manifest>, in which case it is moved to preserve its sort
order along all other items under <manifest>), but otherwise
continues.

=cut

sub fix_manifest :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $twigroot = $self->{twigroot};

    my $spec = $self->spec || '';
    my $manifest = $twigroot->first_descendant('manifest');
    my @elements;
    my @extras;
    my $parent;

    my $href;
    my $id;
    my $type;

    # If <manifest> doesn't exist, create it
    if(! $manifest) {
	debug(1,"DEBUG: creating <manifest>");
	$manifest = $twigroot->insert_new_elt('last_child','manifest');
    }

    # Make sure that the manifest is the first child of the twigroot,
    # which should be <package>
    $parent = $manifest->parent;
    if($parent != $twigroot) {
	debug(1,"DEBUG: moving <manifest>");
	$manifest->move('first_child',$twigroot);
    }

    # Find and merge any other manifests
    @extras = $twigroot->descendants('manifest');
    shift @extras;
    foreach my $extra (@extras) {
        my @elements = $extra->children;
        foreach my $el (@elements) {
            debug(2,"DEBUG: moving <",$el->gi,"> into primary manifest");
            $el->move('last_child',$manifest);
        }
        $extra->delete;
    }

    @elements = $twigroot->descendants(qr/^item$/ix);
    foreach my $el (@elements) {
        $href = $el->att('href');
        $id = $el->id;
        $type = $el->att('media-type');

        # Convert to OPF2.0 document types if necessary
        if($spec eq 'OPF20') {
            if($type eq "text/x-oeb1-document") {
                $type = "application/xhtml+xml";
                $el->set_att('media-type',$type);
            }
            if($id eq 'ncx') {
                $type = 'application/x-dtbncx+xml';
                $el->set_att('media-type',$type);
            }

        }

        if(!$id) {
            if(!$href) {
                # No ID, no href, there's something very fishy here,
                # so log a warning.
                # If it is already underneath <manifest>, move it to
                # preserve sort order, but otherwise leave it alone
                $self->add_warning(
                    "fix_manifest(): found item with no id or href"
                    );
                debug(1,"fix_manifest(): found item with no id or href");
                if($el->parent == $manifest) {
                    $el->move('last_child',$manifest);
                }
                else {
                    print "DEBUG: skipping item with no id or href\n"
                        if($debug);
                }
                next;
            } # if(!$href)
            # We have a href, but no ID.  Log a warning, but move it anyway.
            $self->add_warning(
                'fix_manifest(): handling item with no ID! '
                . sprintf "(href='%s')",$href
                );
            debug(1,"DEBUG: processing item with no id (href='",$href,"')");
            $el->move('last_child',$manifest);
        } # if(!$id)
        if(!$href) {
            # We have an ID, but no href.  Log a warning, but move it anyway.
            $self->add_warning(
                "fix_manifest(): item with id '" . $id . "' has no href!"
                );
            debug(1,"fix_manifest(): item with id '",$id,"' has no href!");
            $el->move('last_child',$manifest);
        }
        else {
            # We have an ID and a href
            debug(3,"DEBUG: processing item '",$id,"' (href='",$href,"')");
            $el->move('last_child',$manifest);
        }
    }
    return 1;
}

=head2 C<fix_metastructure_basic()>

Verifies that <metadata> exists (creating it if necessary), and moves
it to be the first child of <package>.  If additional <metadata>
elements exist, their children are moved into the first one found and
then the extras are deleted.

Used in L</fix_metastructure_oeb12()>, L</fix_packageid()>, and
L</set_primary_author(%args)>.

=cut

sub fix_metastructure_basic :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $twigroot = $self->{twigroot};
    my $metadata = $twigroot->first_descendant('metadata');

    my @extras = $twigroot->descendants('metadata');
    shift @extras;

    if(! $metadata) {
	debug(1,"DEBUG: creating <metadata>");
	$metadata = $twigroot->insert_new_elt('first_child','metadata');
    }

    foreach my $extra (@extras) {
        my @elements = $extra->children;
        foreach my $el (@elements) {
            debug(2,"DEBUG: moving <",$el->gi,"> into primary metadata");
            $el->move('last_child',$metadata);
        }
        $extra->delete;
    }
    debug(3,"DEBUG: moving <metadata> to be the first child of <package>");
    $metadata->move('first_child',$twigroot);

    if($metadata->att('xmlns:calibre')) {
        # xmlns:calibre isn't a real namespace; it's just there for
        # advertising, so remove it
        $metadata->del_att('xmlns:calibre');
    }
    return 1;
}


=head2 C<fix_metastructure_oeb12()>

Verifies the existence of <metadata>, <dc-metadata>, and <x-metadata>,
creating them as needed, and making sure that <metadata> is a child of
<package>, while <dc-metadata> and <x-metadata> are children of
<metadata>.

Used in L</fix_oeb12()> and L</fix_mobi()>.

=cut

sub fix_metastructure_oeb12 :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $twigroot = $self->{twigroot};

    my $metadata;
    my $dcmeta;
    my $xmeta;
    my $parent;

    # Start by forcing the basic <package><metadata> structure
    $self->fix_metastructure_basic;
    $metadata = $twigroot->first_child('metadata');

    # If <dc-metadata> doesn't exist, we'll have to create it.
    $dcmeta = $twigroot->first_descendant('dc-metadata');
    if(! $dcmeta) {
	debug(2,"DEBUG: creating <dc-metadata>");
	$dcmeta = $metadata->insert_new_elt('first_child','dc-metadata');
    }

    # Make sure that $dcmeta is a child of $metadata
    $parent = $dcmeta->parent;
    if($parent != $metadata) {
	debug(2,"DEBUG: moving <dc-metadata>");
	$dcmeta->move('first_child',$metadata);
    }

    # If <x-metadata> doesn't exist, create it
    $xmeta = $metadata->first_descendant('x-metadata');
    if(! $xmeta) {
        debug(2,"DEBUG: creating <x-metadata>");
        $xmeta = $metadata->insert_new_elt('last_child','x-metadata');
    }

    # Make sure that x-metadata is a child of metadata
    $parent = $xmeta->parent;
    if($parent != $metadata) {
        debug(2,"DEBUG: moving <x-metadata>");
        $xmeta->move('after',$dcmeta);
    }
    return 1;
}


=head2 C<fix_misc()>

Fixes miscellaneous potential problems in OPF data.  Specifically,
this is a shortcut to calling L</delete_meta_filepos()>,
L</fix_packageid()>, L</fix_dates()>, L</fix_languages()>,
L</fix_publisher()>, L</fix_manifest()>, L</fix_spine()>,
L</fix_subjects()>, L</fix_type()>, L</fix_guide()>, and
L</fix_links()>.

L</fix_creators()> is not run from this, as it carries a risk of taking
a correct name and making it incorrect.

The objective here is that you can run either C<fix_misc()> and either
L</fix_oeb12()> or L</fix_opf20()> and a perfectly valid OPF file will
result from only two calls.

=cut

sub fix_misc :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    $self->delete_meta_filepos();
    $self->fix_packageid();
    $self->fix_dates();
    $self->fix_languages();
    $self->fix_publisher();
    $self->fix_manifest();
    $self->fix_spine();
    $self->fix_subjects();
    $self->fix_type();
    $self->fix_guide();
    $self->fix_links();

    debug(2,"DEBUG[/",$subname,"]");
    return 1;
}


=head2 C<fix_mobi()>

Manipulates the twig to fix Mobipocket-specific issues

=over

=item * Force the OEB 1.2 structure (although not the namespace, DTD,
or capitalization), so that <dc-metadata> and <x-metadata> are
guaranteed to exist.

=item * Find and move all Mobi-specific elements to <x-metadata>

=item * If no <output> element exists, creates one for a utf-8 ebook

=back

Note that the forced creation of <output> will cause the OPF file to
become noncompliant with IDPF specifications.

=cut

sub fix_mobi :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $twigroot = $self->{twigroot};

    my %mobicontenttypes = (
	'text/x-oeb1-document' => 'text/x-oeb1-document',
	'application/x-mobipocket-subscription'
	=> 'application/x-mobipocket-subscription',
	'application/x-mobipocket-subscription-feed'
	=> 'application/x-mobipocket-subscription-feed',
	'application/x-mobipocket-subscription-magazine'
	=> 'application/x-mobipocket-subscription-magazine',
	'image/gif' => 'image/gif',
	'application/msword' => 'application/msword',
	'application/vnd.ms-excel' => 'application/vnd.ms-excel',
	'application/vnd.ms-powerpoint' => 'application/vnd.ms-powerpoint',
	'text/plain' => 'text/plain',
	'text/html' => 'text/html',
	'application/vnd.mobipocket-game' => 'application/vnd.mobipocket-game',
	'application/vnd.mobipocket-franklin-ua-game'
	=> 'application/vnd.mobipocket-franklin-ua-game'
	);

    my %mobiencodings = (
	'Windows-1252' => 'Windows-1252',
	'utf-8' => 'utf-8'
	);

    my @mobitags = (
        'output',
        'Adult',
        'Demo',
        'DefaultLookupIndex',
        'DictionaryInLanguage',
        'DictionaryOutLanguage',
        'DictionaryVeryShortName',
        'DatabaseName',
        'EmbeddedCover',
        'Review',
        'SRP',
        'Territory'
        );

    my $dcmeta;
    my $xmeta;
    my @elements;
    my $output;


    # Mobipocket currently requires that its custom elements be found
    # underneath <x-metadata>.  Since the presence of <x-metadata>
    # requires that the Dublin Core tags be under <dc-metadata>, we
    # have to use at least the OEB1.2 structure (deprecated, but still
    # allowed in OPF2.0), though we don't have to convert everything.
    $self->fix_metastructure_oeb12();
    $dcmeta = $twigroot->first_descendant('dc-metadata');
    $xmeta = $twigroot->first_descendant('x-metadata');

    # If <x-metadata> doesn't exist, create it.  Even if there are no
    # mobi-specific tags, this method will create at least one
    # (<output>) which will need it.
    if(!$xmeta) {
        debug(2,"DEBUG: creating <x-metadata>");
        $xmeta = $dcmeta->insert_new_elt('after','x-metadata')
    }

    foreach my $tag (@mobitags) {
        @elements = $twigroot->descendants($tag);
        next unless (@elements);

        # In theory, only one Mobipocket-specific element should ever
        # be present in a document.  We'll deal with multiples anyway,
        # but send a warning.
        if(scalar(@elements) > 1) {
            $self->add_warning(
                'fix_mobi(): Found ' . scalar(@elements) . " '" . $tag .
                "' elements, but only one should exist."
                );
        }

        foreach my $el (@elements) {
            $el->move('last_child',$xmeta);
        }
    }

    $output = $xmeta->first_child('output');
    if($output) {
	my $encoding = $mobiencodings{$output->att('encoding')};
	my $contenttype = $mobicontenttypes{$output->att('content-type')};

	if($contenttype) {
	    $output->set_att('encoding','utf-8') if(!$encoding);
	    debug(2,"DEBUG: setting encoding only and returning");
	    return 1;
	}
    }
    else {
        debug(1,"DEBUG: creating <output> under <x-metadata>");
        $output = $xmeta->insert_new_elt('last_child','output');
    }


    # At this stage, we definitely have <output> in the right place.
    # Set the attributes and return.
    $output->set_att('encoding' => 'utf-8',
		     'content-type' => 'text/x-oeb1-document');
    debug(2,"DEBUG[/",$subname,"]");
    return 1;
}


=head2 C<fix_oeb12()>

Modifies the OPF data to conform to the OEB 1.2 standard

Specifically, this involves:

=over

=item * adding the OEB 1.2 doctype

=item * removing OPF 2.0 version and namespace attributes

=item * setting the OEB 1.2 namespace on <package>

=item * moving all of the dc-metadata elements underneath an element
with tag <dc-metadata>, which itself is forced to be underneath
<metadata>, which is created if it doesn't exist.

=item * moving any remaining tags underneath <x-metadata>, again
forced to be under <metadata>

=item * making the dc-metadata tags conform to the OEB v1.2 capitalization

=back

=cut

sub fix_oeb12 :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $twigroot = $self->{twigroot};
    my $metadata;
    my $dcmeta;
    my $xmeta;
    my @elements;

    # Verify and correct locations for <metadata>, <dc-metadata>, and
    # <x-metadata>, creating them as needed.
    $self->fix_metastructure_oeb12;
    $metadata = $twigroot->first_descendant('metadata');
    $dcmeta = $metadata->first_descendant('dc-metadata');
    $xmeta = $metadata->first_descendant('x-metadata');

    # Clobber metadata attributes 'xmlns:dc' and 'xmlns:opf'
    # used only in OPF2.0
    $metadata->del_atts('xmlns:dc','xmlns:opf');

    # Assign the DC namespace attribute to dc-metadata for OEB 1.2
    $dcmeta->set_att('xmlns:dc',"http://purl.org/dc/elements/1.1/");

    # Set the correct tag name and move it into <dc-metadata> in the
    # right order
    foreach my $dcel (keys %dcelements12) {
        @elements = $twigroot->descendants(qr/^$dcel$/ix);
        foreach my $el (@elements) {
            debug(3,"DEBUG: processing '",$el->gi,"'");
            croak("Found invalid DC element '",$el->gi,"'!")
                if(!$dcelements12{lc $el->gi});
            $el->set_gi($dcelements12{lc $el->gi});
            $el = twigelt_fix_oeb12_atts($el);
            $el->move('last_child',$dcmeta);
        }
    }

    # Handle non-DC metadata, deleting <x-metadata> if it isn't
    # needed.
    @elements = $metadata->children(qr/^(?!(?s:.*)-metadata)/x);
    if(@elements) {
	if($debug) {
	    print {*STDERR} "DEBUG: extra metadata elements found: ";
	    foreach my $el (@elements) { print {*STDERR} $el->gi," "; }
	    print {*STDERR} "\n";
	}
	foreach my $el (@elements) {
	    $el->move('last_child',$xmeta);
	}
    }
    @elements = $twigroot->children(qr/^meta$/ix);
    foreach my $el (@elements) {
        $el->set_gi(lc $el->gi);
        $el->move('last_child',$xmeta);
    }
    @elements = $xmeta->children;
    $xmeta->delete unless(@elements);

    # Delete Calibre advertisements in dc:Contributor elements
    @elements = $twigroot->descendants('dc:Contributor[string() =~ /calibre-ebook.com|calibre.kovidgoyal.net/]');
    foreach my $el (@elements) {
	$el->delete;
    }

    # Fix <manifest> and <spine>
    $self->fix_manifest;
    $self->fix_spine;

    # Set the OEB 1.2 doctype
    $self->{twig}->set_doctype('package',
                              "http://openebook.org/dtds/oeb-1.2/oebpkg12.dtd",
                              "+//ISBN 0-9673008-1-9//DTD OEB 1.2 Package//EN");

    # Clean up <package>
    $twigroot->del_att('version');
    $twigroot->set_att(
        'xmlns' => 'http://openebook.org/namespaces/oeb-package/1.0/');
    $self->fix_packageid;

    $self->{spec} = $validspecs{'OEB12'};
    debug(2,"DEBUG[/",$subname,"]");
    return 1;
}


=head2 C<fix_oeb12_dcmetatags()>

Makes a case-insensitive search for tags matching a known list of DC
metadata elements and corrects the capitalization to the OEB 1.2
standard.  Also corrects 'dc:Copyrights' to 'dc:Rights'.  See global
variable $dcelements12.

The L</fix_oeb12()> method does this also, but fix_oeb12_dcmetatags()
is usable separately for the case where you want DC metadata elements
with consistent tag names, but don't want them moved from wherever
they are.

=cut

sub fix_oeb12_dcmetatags :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $topelement = $self->{twigroot};

    my @elements;

    foreach my $dcmetatag (keys %dcelements12) {
	@elements = $topelement->descendants(qr/^$dcmetatag$/ix);
	foreach my $el (@elements) {
	    $el->set_tag($dcelements12{lc $el->tag})
		if($dcelements12{lc $el->tag});
	}
    }
    return 1;
}


=head2 C<fix_opf20()>

Modifies the OPF data to conform to the OPF 2.0 standard

Specifically, this involves:

=over

=item * moving all of the dc-metadata and x-metadata elements directly
underneath <metadata>

=item * removing the <dc-metadata> and <x-metadata> elements themselves

=item * lowercasing the dc-metadata tags (and fixing dc:copyrights to
dc:rights)

=item * setting namespaces on dc-metata OPF attributes

=item * setting version and xmlns attributes on <package>

=item * setting xmlns:dc and xmlns:opf on <metadata>

=back

=cut

sub fix_opf20 :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    # Ensure a sane structure
    $self->fix_metastructure_basic();

    # If there is an existing cover image, ensure it hits all standards
    my $coverimage = $self->coverimage;
    $self->set_cover('href' => $coverimage) if $coverimage;

    my $twigroot = $self->{twigroot};
    my $metadata = $twigroot->first_descendant('metadata');
    my @elements;

    # If <dc-metadata> exists, make sure that it is directly
    # underneath <metadata> so that its children will collapse to the
    # correct position, then erase it.
    @elements = $twigroot->descendants('dc-metadata');
    if(@elements) {
	foreach my $dcmeta (@elements) {
	    debug(1,"DEBUG: moving <dc-metadata>");
	    $dcmeta->move('first_child',$metadata);
	    $dcmeta->erase;
	}
    }

    # If <x-metadata> exists, make sure that it is directly underneath
    # <metadata> so that its children will collapse to the correct
    # position, then erase it.
    @elements = $twigroot->descendants('x-metadata');
    if(@elements) {
	foreach my $xmeta (@elements) {
	    debug(1,"DEBUG: moving <x-metadata>");
	    $xmeta->move('last_child',$metadata);
	    $xmeta->erase;
	}
    }

    # Delete any old OEB12 output elements
    @elements = $twigroot->descendants('output');
    foreach my $el (@elements) {
        $el->delete;
    }

    # For all DC elements at any location, set the correct tag name
    # and attribute namespace and move it directly under <metadata>
    foreach my $dcmetatag (keys %dcelements20) {
	@elements = $twigroot->descendants(qr/$dcmetatag/ix);
	foreach my $el (@elements) {
	    debug(2,"DEBUG: checking DC element <",$el->gi,">");
	    $el->set_gi($dcelements20{$dcmetatag});
            $el = twigelt_fix_opf20_atts($el);
	    $el->move('last_child',$metadata);
	}
    }

    # Find any <meta> elements anywhere in the package and move them
    # under <metadata>.  Force the tag to lowercase.

    @elements = $twigroot->descendants(qr/^meta$/ix);
    foreach my $el (@elements) {
        debug(2,'DEBUG: checking meta element <',$el->gi,
              ' name="',$el->att('name'),'">');
        $el->set_gi(lc $el->gi);
        $el->move('last_child',$metadata);
    }

    # Delete Calibre advertisements in dc:contributor elements
    @elements = $twigroot->descendants('dc:contributor[string() =~ /calibre-ebook.com|calibre.kovidgoyal.net/]');
    foreach my $el (@elements) {
	$el->delete;
    }
    # Delete Aspose.Words advertisements in dc:contributor elements
    @elements = $twigroot->descendants('dc:contributor[string() =~ /Aspose.Words/]');
    foreach my $el (@elements) {
	$el->delete;
    }

    # Fix the <package> attributes
    $twigroot->set_att('version' => '2.0',
                       'xmlns' => 'http://www.idpf.org/2007/opf');
    $self->fix_packageid;

    # Fix the <metadata> attributes
    $metadata->set_att('xmlns:dc' => "http://purl.org/dc/elements/1.1/",
                       'xmlns:opf' => "http://www.idpf.org/2007/opf",
                       'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance");

    # Fix <manifest> and <spine>
    $self->fix_manifest;
    $self->fix_spine;

    # Clobber the doctype, if present
    $self->{twig}->set_doctype(0,0,0,0);

    # Set the specification
    $self->{spec} = $validspecs{'OPF20'};

    debug(2,"DEBUG[/",$subname,"]");
    return 1;
}


=head2 C<fix_opf20_dcmetatags()>

Makes a case-insensitive search for tags matching a known list of DC
metadata elements and corrects the capitalization to the OPF 2.0
standard.  Also corrects 'dc:copyrights' to 'dc:rights'.  See package
variable %dcelements20.

The L</fix_opf20()> method does this also, but
C<fix_opf20_dcmetatags()> is usable separately for the case where you
want DC metadata elements with consistent tag names, but don't want
them moved from wherever they are.

=cut

sub fix_opf20_dcmetatags :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $topelement = $self->{twigroot};
    my @elements;

    foreach my $dcmetatag (keys %dcelements20) {
	@elements = $topelement->descendants(qr/^$dcmetatag$/ix);
	foreach my $el (@elements) {
	    $el->set_tag($dcelements20{lc $el->tag})
		if($dcelements20{lc $el->tag});
	}
    }
    return;
}


=head2 C<fix_packageid()>

Checks the <package> element for the attribute 'unique-identifier',
makes sure that it is mapped to a valid dc:identifier subelement, and
if not, searches those subelements for an identifier to assign, or
creates one if nothing can be found.

Requires that <metadata> exist.  Croaks if it doesn't.  Run
L</fix_oeb12()> or L</fix_opf20()> before calling this if the input
might be very broken.

=cut

sub fix_packageid :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    # Start by enforcing the basic structure needed
    $self->fix_metastructure_basic();
    my $twigroot = $self->{twigroot};
    my $packageid = $twigroot->att('unique-identifier');

    my $meta = $twigroot->first_child('metadata')
        or croak($subname,"(): metadata not found");
    my $element;

    if($packageid) {
        # Check that the ID maps to a valid identifier
	# If not, undefine it
	debug(2,"DEBUG: checking existing packageid '",$packageid,"'");

	# The twig ID handling system is unreliable, especially when
	# multiple twigs may be existing simultaneously.  Use
	# XML::Twig->first_elt instead of XML::Twig->elt_id, even
	# though it is slower.
        #
        # As of Twig 3.32, this will cause 'uninitialized value'
        # warnings to be spewed for each time no descendants are
        # found.
	#$element = $self->{twig}->elt_id($packageid);
	$element = $self->{twig}->first_elt("*[\@id='$packageid']");

	if($element) {
	    if(lc($element->tag) ne 'dc:identifier') {
		debug(1,"DEBUG: packageid '",$packageid,
                      "' points to a non-identifier element ('",
                      $element->tag,"')");
                debug(1,"DEBUG: undefining existing packageid '",
                      $packageid,"'");
		undef($packageid);
	    }
	    elsif(!$element->text) {
		debug(1,"DEBUG: packageid '",$packageid,
                      "' points to an empty identifier.");
		debug(1,"DEBUG: undefining existing packageid '",
                      $packageid,"'");
		undef($packageid);
	    }
	}
	else { undef($packageid); };
    }

    if(!$packageid) {
	# Search known IDs for a unique Package ID
	$packageid = $self->search_knownuids;
    }

    # If no unique ID found so far, start searching known schemes
    if(!$packageid) {
	$packageid = $self->search_knownuidschemes;
    }

    # And if we still don't have anything, we have to make one from
    # scratch using Data::UUID
    if(!$packageid) {
	debug(1,"DEBUG: creating new UUID");
	$element = twigelt_create_uuid();
	$element->paste('first_child',$meta);
	$packageid = 'UUID';
    }

    # At this point, we have a unique ID.  Assign it to package
    $twigroot->set_att('unique-identifier',$packageid);
    debug(2,"[/",$subname,"]");
    return 1;
}


=head2 C<fix_publisher()>

Standardizes publisher names in all dc:publisher entities, mapping
known variants of a publisher's name to a canonical form via package
variable %publishermap.

Publisher entries with no text are deleted.

=cut

sub fix_publisher :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my @publishers = $self->twigroot->descendants(qr/^dc:publisher$/ix);
    foreach my $pub (@publishers) {
        debug(3,"Examining publisher entry in element '",$pub->gi,"'");
        if(!$pub->text) {
            debug(1,'Deleting empty publisher entry');
            $pub->delete;
            next;
        }
        elsif( $publishermap{lc $pub->text} &&
               ($publishermap{lc $pub->text} ne $pub->text) )
        {
            debug(1,"DEBUG: Changing publisher from '",$pub->text,"' to '",
                  $publishermap{lc $pub->text},"'");
            $pub->set_text($publishermap{lc $pub->text});
        }
    }
    return 1;
}


=head2 C<fix_spine()>

Fixes problems with the OPF spine, specifically:

=over

=item Moves all <itemref> elements underneath <spine>, creating
<spine> if necessary.

=back

=cut

sub fix_spine :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $twigroot = $self->{twigroot};
    my $manifest = $twigroot->first_descendant('manifest');
    my $spine = $twigroot->first_descendant('spine');
    my @elements;
    my $parent;

    @elements = $twigroot->descendants(qr/^itemref$/ix);
    if(@elements) {
        # If <spine> doesn't exist, create it
        if(! $spine) {
            debug(1,"DEBUG: creating <spine>");
            $spine = $twigroot->insert_new_elt('last_child','spine');
        }

        # Make sure that the spine is a child of the twigroot,
        $parent = $spine->parent;
        if($parent != $twigroot) {
            debug(1,"DEBUG: moving <spine>");
            $spine->move('last_child',$twigroot);
        }

        # If an NCX item exists in the manifest, reference it as a
        # spine attribute
        if($manifest->has_child('@id="ncx"')) {
            $spine->set_att('toc' => 'ncx');
        }

        foreach my $el (@elements) {
            if(!$el->att('idref')) {
                # No idref means it is broken.
                # Leave it alone, but log a warning
                $self->add_warning(
                    "fix_spine(): <itemref> with no idref -- skipping");
                next;
            }
            debug(3,"DEBUG: processing itemref '",$el->att('idref'),"')");
            $el->move('last_child',$spine);
        }
    }
    else {
        # No elements, delete spine if it exists
        $spine->delete if($spine);
    }

    return 1;
}


=head2 C<fix_subjects()>

Deletes empty and duplicate subject elements and normalizes existing
subject text against the known Library of Congress mappings.

If $self->{erotic} is true, then the book will be treated as a
work of erotic fiction and the subjects will go through preprocessing
against the C<%sexcodes> package variable, normalizing matches and
prepending 'FICTION / Erotica / ' (with a trailing space).

This method is called as a component of C<fix_misc()>.

=cut

sub fix_subjects :method {
    my ($self) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $eroticaprefix = 'FICTION / Erotica / ';

    my $twigroot = $self->{twigroot};
    my $manifest = $twigroot->first_descendant('manifest');
    my $bisac;
    my $newsubject;
    my $text;
    my $newtext;

    $self->delete_subject('text' => '');
    my @elements = $self->{twigroot}->descendants(qr/^dc:subject$/ix);
    my %subjects_seen;
    foreach my $el (@elements) {
        # Matches to the list are done after stripping leading and
        # trailing whitespace, trailing periods, and removing
        # whitespace around '--', then converting ' - ' to '--' and
        # decoding entities.
        $text = trim $el->text;
        $text =~ s|\.\z||x;
        $text =~ s|\s* -- \s*|--|gx;
        $text =~ s|\s* - \s*|--|gx;
        $text =~ s|\s*—\s*|--|gx;
        # We can't normalize spaces around slashes -- they have
        # potentially distinct meanings
        #$text =~ s|\s* / \s*|/|gx;
        $text = decode_entities($text);

        # Sex code matches are case-sensitive
        if($self->{erotic}) {
            if($sexcodes{$text}) {
                $newtext = $eroticaprefix . $sexcodes{$text};
                debug(1,"DEBUG: normalizing ${text} to " . $newtext);
                if($subjects_seen{$newtext}) {
                    $el->delete;
                }
                else {
                    $el->set_text($newtext);
                    $subjects_seen{$newtext} = 1;
                }
            }
        }

        # ... but all other normalizations are not.
        $text = lc $text;
        debug(1,"DEBUG: normalizing subject '",$text,"'");

        # TODO: check for BISACCODE property, convert it to both a
        # BISAC descriptor and a LoC subject, then remove it.
        if($el->att('BASICCode')) {
            $newsubject = $self->add_subject(text => $el->att('BASICCode'));
            $el->del_att('BASICCode');
            push(@elements,$newsubject);
        }
        if($bisacsubjects{$text}) {
            debug(1,"DEBUG: found BISAC: ",$text);
            $bisac = $bisacsubjects{$text};
            if($subjects_seen{$bisac}) {
                $el->delete;
            }
            else {
                $el->set_text($bisac);
                $subjects_seen{$bisac} = 1;
            }
        }

        # TODO: check for a BISAC code or descriptor in attribute as
        # well as text, normalize it to standard descriptor format, as
        # well as inserting an additional matching LoC subject if
        # present
        if($bisactolc{$text}) {
            $bisac = $bisactolc{$text};
            if(! $subjects_seen{$bisac}) {
                $self->add_subject(text => $bisac);
            }
        }
        elsif($lcsubjects{$text}) {
            $text = $lcsubjects{$text};
            $el->set_text($text);
        }

        if($subjects_seen{$text}) {
            $el->delete;
        }
        else {
            $subjects_seen{$text} = 1;
        }
    }
    return;
}


=head2 C<fix_type()>

Normalizes <dc:type> elements against a limited list based on book types listed in Wikipedia.

=cut

sub fix_type :method {
    my ($self) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck();

    my $twigroot = $self->{twigroot};
    my $manifest = $twigroot->first_descendant('manifest');
    my $text;
    my $type;

    my @elements = $self->{twigroot}->descendants(qr/^dc:type$/ix);
    foreach my $el (@elements) {
        # Matches to the list are done after stripping leading and
        # trailing whitespace, trailing periods, and removing
        # whitespace around '--' and '/'
        $text = lc trim $el->text;
        $text =~ s|\.\z||x;
        debug(2,"DEBUG: normalizing type '",$text,"'");

        if($booktypes{$text}) {
            $type = $booktypes{$text};
            $el->set_text($type);
        }
        else {
            debug(1,"WARNING: unknown book type '",$text,"'");
        }
    }
    return;
}


=head2 C<gen_epub(%args)>

Creates a .epub format e-book.  This will create (or overwrite) the
files 'mimetype' and 'META-INF/container.xml' in the current
directory, creating the subdirectory META-INF as needed.

A NCX file will also be created if missing.

=head3 Arguments

This method can take two optional named arguments.

=over

=item C<filename>

The filename of the .epub output file.  If not specified, takes the
base name of the opf file and adds a .epub extension.

=item C<dir>

The directory to output the .epub file.  If not specified, uses the
current working directory.  If a specified directory does not exist,
it will be created, or the method will croak.

=back

=head3 Example

 gen_epub(filename => 'mybook.epub',
          dir => '../epub_books');

=cut

sub gen_epub :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my %valid_args = (
        'filename' => 1,
        'dir' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $filename = $args{filename};
    my $dir = $args{dir};
    my $zip = Archive::Zip->new();
    my $member;
    my $cwd = usedir($self->{topdir});

    $self->gen_epub_files();
    if(! $self->{opffile} ) {
	$self->add_error(
	    "Cannot create epub without an OPF (did you forget to init?)");
        debug(1,"Cannot create epub without an OPF");
	return;
    }
    if(! -f $self->opfpath) {
	$self->add_error(
	    sprintf("OPF '%s' does not exist (did you forget to save?)",
		    $self->opfpath)
	    );
        debug(1,"OPF '",$self->opfpath,"' does not exist");
	return;
    }

    debug(3,"DEBUG: adding core metadata to zip archive");
    $member = $zip->addFile('mimetype');
    $member->desiredCompressionMethod(COMPRESSION_STORED);

    $member = $zip->addFile('META-INF/container.xml');
    $member->desiredCompressionLevel(9);

    $member = $zip->addFile($self->{opfsubdir} . '/' . $self->{opffile});
    $member->desiredCompressionLevel(9);

    debug(3,"DEBUG: adding manifest files to zip archive");
    foreach my $file ($self->manifest_hrefs()) {
        $file = uri_unescape($file);
	if(-f $self->{opfsubdir} . '/' . $file) {
	    $member = $zip->addFile($self->{opfsubdir} . '/' . $file);
	    $member->desiredCompressionLevel(9);
	}
	else { print STDERR "WARNING: ",$self->{opfsubdir} . '/' . $file," not found, skipping.\n"; }
    }

    if(! $filename) {
	$filename = basename($self->{topdir}) . '.epub';
    }

    if($dir) {
        unless(-d $dir) {
            mkpath($dir)
                or croak("Unable to create working directory '",$dir,"'!");
        }
        $filename = "$dir/$filename";
    }

    unless ( $zip->writeToFileNamed($filename) == AZ_OK ) {
	$self->add_error(
            sprintf("Failed to create epub as '%s'",$filename));
        debug(1,"Failed to create epub as '",$filename,"'");
	return;
    }

    usedir($cwd);
    return 1;
}


=head2 C<gen_epub_files()>

Generates the C<mimetype> and C<META-INF/container.xml> files expected
by a .epub container, but does not actually generate the .epub file
itself.  This will be called automatically by C<gen_epub>.

The OPF will be normalized to the OPF 2.0 format.

If no NCX element exists, it will also be created.

=cut

sub gen_epub_files :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my $manifest = $self->{twigroot}->first_descendant('manifest');

    $self->fix_opf20();
    if( ! $manifest->first_child('item[@id="ncx"]') ) {
        $self->gen_ncx();
    }
    $self->save();

    # These two functions must happen from the top-level directory, not the OPF directory
    if($self->{opfsubdir} ne '.') {
        debug(3,"DEBUG: switching to ",$self->{topdir}," to generate EPUB metadata");
        my $cwd = usedir($self->{topdir});
        create_epub_mimetype();
        create_epub_container($self->{opfsubdir} . '/' . $self->{opffile});
        usedir($cwd);
    }
    else {
        create_epub_mimetype();
        create_epub_container($self->{opffile});
    }

    return 1;
}


=head2 C<gen_ncx($filename)>

Creates a NCX-format table of contents from the package
unique-identifier, the dc:title, dc:creator, and spine elements, and
then add the NCX entry to the manifest if it is not already
referenced.

Adds an error and fails if any of those cannot be found.  The first
available dc:title is taken, but will prioritize dc:creator elements
with opf:role="aut" over those with no role attribute (see
twigelt_is_author() for details).

WARNING: This method REQUIRES that the e-book be in OPF 2.0 format to
function correctly.  Call fix_opf20() before calling gen_ncx().
gen_ncx() will log an error and fail if $self{spec} is not set to
OPF20.

=head3 Arguments

=over

=item $filename : The filename to save to.  If not specified, will use
'toc.ncx'.

=back

This method will overwrite any existing file.

Returns a twig containing the NCX XML, or undef on failure.

=cut

sub gen_ncx :method {
    my ($self,$filename) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    $filename = 'toc.ncx' if(!$filename);

    my $cwd = usedir($self->opfdir);
    my $twigroot = $self->{twigroot};
    my $identifier = $self->identifier;
    my $element;            # Generic element container
    my $parent;             # Generic parent element container
    my $ncx;                # NCX twig
    my $ncxroot;            # NCX twig root <ncx>
    my $ncxitem;            # manifest item pointing to the NCX document
    my $navmap;             # NCX element <navMap>
    my $navpoint;           # NCX element <navPoint>
    my %navpointorder;      # Hash mapping playOrder to id
    my $navpointindex = 1;  # playOrder number starting at 1
    my $title;              # E-book title
    my $author;             # E-book primary author
    my @spinelist;          # List of hashrefs containing spine data
    my $manifest;           # OPF manifest element
    my $spine;		    # OPF spine element

    if($self->{spec} ne 'OPF20') {
        $self->add_error(
            $subname . "(): specification is currently set to '"
            . $self->{spec} . "' -- need 'OPF20'"
            );
        debug(1,"DEBUG: gen_ncx() FAILED: wrong specification ('",
              $self->{spec},"')!");
        return;
    }

    if(!$identifier) {
        $self->add_error( $subname . "(): no unique-identifier found" );
        debug(1,"DEBUG: gen_ncx() FAILED: no unique-identifier!");
        return;
    }

    # Get the title
    $title = $self->title();
    if(!$title) {
        $self->add_error( $subname . "(): no title found" );
        debug(1,"DEBUG: gen_ncx() FAILED: no title!");
        return;
    }

    # Get the author
    $author = $self->primary_author();
    if(!$author) {
        $self->add_error( $subname . "(): no title found" );
        debug(1,"DEBUG: gen_ncx() FAILED: no title!");
        return;
    }

    # Get the spine list
    @spinelist = $self->spine();
    if(!@spinelist) {
        $self->add_error( $subname . "(): no spine found" );
        debug(1,"DEBUG: gen_ncx() FAILED: no spine!");
        return;
    }

    # Make sure the manifest element exists
    # (This should in theory never fail, since it is also checked by
    # spine() above)
    $manifest = $twigroot->first_descendant('manifest');
    if(!$manifest) {
        $self->add_error( $subname . "(): no manifest found" );
        debug(1,"DEBUG: gen_ncx() FAILED: no manifest!");
        return;
    }

    $ncx = XML::Twig->new(
	output_encoding => 'utf-8',
	pretty_print => 'record'
	);

    # <ncx>
    $element = XML::Twig::Elt->new('ncx');
    $element->set_att('xmlns' => 'http://www.daisy.org/z3986/2005/ncx/');
    $element->set_att('version' => '2005-1');
    $ncx->set_root($element);
    $ncxroot = $ncx->root;

    # <head>
    $parent = $ncxroot->insert_new_elt('first_child','head');
    $element = $parent->insert_new_elt('last_child','meta');
    $element->set_att(
        'name' => 'dtb:uid',
        'content' => $identifier
        );

    $element = $parent->insert_new_elt('last_child','meta');
    $element->set_att(
        'name'    => 'dtb:depth',
        'content' => '1'
        );
    $element = $parent->insert_new_elt('last_child','meta');
    $element->set_att(
        'name' => 'dtb:totalPageCount',
        'content' => '0'
        );

    $element = $parent->insert_new_elt('last_child','meta');
    $element->set_att(
        'name' => 'dtb:maxPageNumber',
        'content' => '0'
        );

    # <docTitle>
    $parent = $parent->insert_new_elt('after','docTitle');
    $element = $parent->insert_new_elt('first_child','text');
    $element->set_text($title);

    # <navMap>
    $navmap = $parent->insert_new_elt('after','navMap');

    foreach my $spineitem (@spinelist) {
        # <navPoint>
        $navpoint = $navmap->insert_new_elt('last_child','navPoint');
        $navpoint->set_att('id' => $spineitem->{'id'},
                           'playOrder' => $navpointindex);
        $navpointindex++;

        # <navLabel>
        $parent = $navpoint->insert_new_elt('last_child','navLabel');
        $element = $parent->insert_new_elt('last_child','text');
        $element->set_text($spineitem->{'id'});

        # <content>
        $element = $navpoint->insert_new_elt('last_child','content');
        $element->set_att('src' => $spineitem->{'href'});
    }

    # Backup existing file
    if(-e $filename) {
        rename($filename,"$filename.backup")
            or croak($subname,"(): could not backup ",$filename,"!");
    }

    # Twig handles utf-8 on its own.  Setting binmode :utf8 here will
    # cause double-conversion.
    open(my $fh_ncx,'>',$filename)
        or croak($subname,"(): failed to open '",$filename,"' for writing!");
    $ncx->print(\*$fh_ncx);
    close($fh_ncx)
        or croak($subname,"(): failed to close '",$filename,"'!");

    # Search for existing NCX entries and modify the first one found,
    # creating a new one if there are no matches.
    $ncxitem = $manifest->first_child('item[@id="ncx"]');
    $ncxitem = $manifest->first_child("item[\@href='$filename']")
        if(!$ncxitem);
    $ncxitem = $manifest->first_child('item[@media-type="application/x-dtbncx+xml"]')
        if(!$ncxitem);
    $ncxitem = $manifest->insert_new_elt('first_child','item')
        if(!$ncxitem);

    $ncxitem->set_att(
        'id' => 'ncx',
        'href' => $filename,
        'media-type' => 'application/x-dtbncx+xml'
        );

    # Move the NCX item to the top of the manifest
    $ncxitem->move('first_child',$manifest);

    # Ensure that the spine references the NCX
    $spine = $twigroot->first_descendant('spine');
    $spine->set_att('toc' => 'ncx');

    usedir($cwd);
    return $ncx;
}


=head2 C<save()>

Saves the OPF file to disk.  Existing files are backed up to
filename.backup.

=cut

sub save :method {
    my $self = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    croak($subname,"(): no opffile specified (did you forget to init?)")
        if(!$self->{opffile});

    my $fh_opf;
    my $cwd = usedir($self->opfdir);
    my $filename = $self->{opffile};

    # Backup existing file
    if(-e $filename) {
        rename($filename,"$filename.backup")
            or croak($subname,"(): could not backup ",$filename,"!");
    }

    # Update the last-modified timestamp as the very last thing before
    # saving if the output changed at all
    if($self->{twig}->sprint ne $self->{twig_unmodified}->sprint) {
        $self->set_timestamp();
    }

    if(!open($fh_opf,">:encoding(UTF-8)",$self->{opffile})) {
	add_error(sprintf("Could not open '%s' to save to!",$self->{opffile}));
	return;
    }
    $self->{twig}->print(\*$fh_opf);

    if(!close($fh_opf)) {
	add_error(sprintf("Failure while closing '%s'!",$self->{opffile}));
	return;
    }

    usedir($cwd);
    return 1;
}


=head2 C<set_adult($bool)>

Sets the Mobipocket-specific <Adult> element, creating or deleting it
as necessary.  If C<$bool> is true, the text is set to 'yes'.  If it
is defined but false, any existing elements are deleted.  If it is
undefined, the method immediately returns.

If a new element has to be created, L</fix_metastructure_oeb12> is
called to ensure that <x-metadata> exists and the element is created
under <x-metadata>, as Mobipocket elements are not recognized by
Mobipocket's software when placed directly under <metadata>

=cut

sub set_adult :method {
    my $self = shift;
    my $adult = shift;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    return 1 unless(defined $adult);

    my $xmeta;
    my $element;
    my @elements;

    if($adult) {
        $element = $self->{twigroot}->first_descendant(qr/^adult$/ix);
        unless($element) {
            $self->fix_metastructure_oeb12();
            $xmeta = $self->{twigroot}->first_descendant('x-metadata');
            $element = $xmeta->insert_new_elt('last_child','Adult');
        }
        $element->set_text('yes');
    }
    else {
        @elements = $self->{twigroot}->descendants(qr/^adult$/ix);
        foreach my $el (@elements) {
            debug(2,"DEBUG: deleting <Adult> flag");
            $el->delete;
        }
    }
    return 1;
}


=head2 C<set_cover(%args)>

Sets a cover image

In OPF 2.0, this is done by setting both a <meta name="cover"> element
and a guide <reference type="other.ms-coverimage-standard"> element
(though some readers will also extract the first image found in the
HTML of the <reference type="cover"> element, which this method will
not handle).

In OEB 1.2, this is done by setting the <EmbeddedCover> tag.

If the filename is not currently listed as an item in the manifest, it
is added.

=head3 Arguments

=over

=item C<href>

The filename of the image file to use.  This is mandatory.

=item C<id>

The id attribute to assign to its item element

=item C<spec>

The specification to use, either OEB12 or OPF20.  If this is left
undefined, the current spec state will be checked, and if that is
undefined, it will default to OPF20.

=back

=cut

sub set_cover :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    my %valid_args = (
        'href' => 1,
        'id' => 1,
        'spec' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $href = $args{href};
    my $newid = $args{id};
    my $spec = $args{spec};
    my $id;
    my $mimetype;
    my $manifest;
    my $guide;
    my $dcmeta;
    my $element;

    if(! $href) {
        $self->add_error($subname,"(): no href specified");
        return;
    }
    $mimetype = mimetype($href);
    if($mimetype !~ m#^image/#ix) {
        $self->add_warning(
            $subname,"(): ",$href,
            " does not appear to be an image (detected: ",$mimetype,")"
           );
    }

    if(! $spec) {
        $spec = $self->spec || 'OPF20';
    }

    # Ensure that there is a matching manifest item
    $manifest = $self->{twigroot}->first_child('manifest');
    $element = $manifest->first_child('item[@href="' . $href . '"]');
    if($element) {
        if($newid) {
            $element->set_id($newid);
        }
    }
    else {
        $element = $manifest->insert_new_elt('first_child','item');
        if ($newid) {
            $element->set_id($newid);
        }
        elsif ($self->{twig}->first_elt('*[@id="coverimage"]')) {
            $element->set_id(basename($href));
        }
        else {
            $element->set_id('coverimage');
        }
        $element->set_att('href',$href);
        $element->set_att('media-type',$mimetype);
    }
    $id = $element->id;

    if ($spec eq 'OPF20') {
        $self->fix_metastructure_basic;
        $self->fix_guide;
        $guide = $self->{twigroot}->first_child('guide');
        $element = $guide->first_child('reference[@type="other.ms-coverimage-standard"]');
        if ($element) {
            $element->set_att('href',$href);
            $element->set_att('title','Cover');
        }
        else {
            $element = $guide->insert_new_elt('last_child','reference');
            $element->set_att('href',$href);
            $element->set_att('title','Cover');
            $element->set_att('type','other.ms-coverimage-standard');
        }
        $self->set_meta('name' => 'cover',
                        'content' => $href);

        # Now that the OPF 2.0 elements are set, we can delete the
        # OEB12 EmbeddedCover element
        $element = $self->{twigroot}->first_descendant('EmbeddedCover');
        if ($element) {
            debug(1,"deleting cover");
            $element->delete;
        }
    }
    elsif ($spec eq 'OEB12') {
        $self->fix_metastructure_oeb12;
        $dcmeta = $self->{twigroot}->first_child('dc-metadata');
        $element = $dcmeta->first_child('EmbeddedCover');
        if ($element) {
            $element->set_text($href);
        }
        else {
            $element = $dcmeta->insert_new_elt('last_child','EmbeddedCover');
            $element->set_text($href);
        }
    }
    else {
        self->add_error($subname,"(): unknown specification type: '",$spec,"'");
    }
    return;
}


=head2 C<set_date(%args)>

Sets the date metadata for a given event.  If more than one dc:date or
dc:Date element is present with the specified event attribute, sets
the first.  If no dc:date element is present with the specified event
attribute, a new element is created.

If a <dc-metadata> element exists underneath <metadata>, the date
element will be created underneath the <dc-metadata> in OEB 1.2
format, otherwise the title element is created underneath <metadata>
in OPF 2.0 format.

Returns 1 on success, logs an error and returns undef if no text or
event was specified.

=head3 Arguments

=over

=item C<text>

This specifies the description to use as the text of the element.  If
not specified, the method sets an error and returns undef.

=item C<event>

This optionally specifies the event attribute for the date.  This
attribute is not valid in OPF 3.0 (which only allows publication date
in this element) and should no longer be used.

=item C<id> (optional)

This specifies the ID to set on the element.  If set and the ID is
already in use, a warning is logged and the ID is removed from the
other location and assigned to the element.

=back

=cut

sub set_date :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    my %valid_args = (
        'text' => 1,
        'event' => 1,
        'id' => 1,
       );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
          if (!$valid_args{$arg});
    }

    my $text = $args{text};
    my $event = $args{event};
    my $newid = $args{id};
    unless($text) {
        $self->add_error($subname,"(): no text specified");
        return;
    }

    my $meta = $self->{twigroot}->first_child('metadata');
    my $dcmeta = $meta->first_child('dc-metadata');
    my $idelem;
    $idelem = $self->{twig}->first_elt("*[\@id='$newid']") if($newid);

    $self->fix_metastructure_basic();

    my $element;
    if ($event) {
        $element = $self->{twigroot}->first_descendant(
            "dc:date[\@opf:event=~/$event/ix or \@event=~/$event/ix]");
        $element = $self->{twigroot}->first_descendant(
            "dc:Date[\@opf:event=~/$event/ix or \@event=~/$event/ix]")
          unless($element);
    }
    else {
        $element = $self->{twigroot}->first_descendant("dc:date");
        $element = $self->{twigroot}->first_descendant("dc:Date")
          unless($element);
    }

    if ($element) {
        $element->set_text($text);
    }
    elsif ($dcmeta) {
        $element = $dcmeta->insert_new_elt('last_child','dc:Date');
        $element->set_text($text);
        if ($event) {
            $element->set_att('event',$event);
        }
    }
    else {
        $element = $meta->insert_new_elt('last_child','dc:date');
        $element->set_text($text);
        if ($event) {
            $element->set_att('opf:event',$event);
        }
    }

    if ($idelem && $idelem->cmp($element) ) {
        $self->add_warning(
            $subname,"(): reassigning id '",$newid,
            "' from a '",$idelem->gi,"' element!"
           );
        $idelem->del_att('id');
    }
    $element->set_att('id' => $newid) if($newid);
    return 1;
}


=head2 set_description(%args)

Sets the text and optionally ID of the first dc:description element
found (case-insensitive).  Creates the element if one did not exist.
If a <dc-metadata> element exists underneath <metadata>, the
description element will be created underneath the <dc-metadata> in
OEB 1.2 format, otherwise the title element is created underneath
<metadata> in OPF 2.0 format.

Returns 1 on success, returns undef if no publisher was specified.

=head3 Arguments

C<set_description()> takes one required and one optional named argument

=over

=item C<text>

This specifies the description to use as the text of the element.  If
not specified, the method returns undef.

=item C<id> (optional)

This specifies the ID to set on the element.  If set and the ID is
already in use, a warning is logged and the ID is removed from the
other location and assigned to the element.

=back

=head3 Example

 $retval = $ebook->set_description('text' => 'A really good book',
                                   'id' => 'mydescid');

=cut

sub set_description :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    my %valid_args = (
        'text' => 1,
        'id' => 1,
       );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
          if (!$valid_args{$arg});
    }

    my $text = $args{text};
    unless($text) {
        $self->add_error($subname,"(): no text specified");
        return;
    }

    $self->fix_metastructure_basic();
    my $element = $self->{twigroot}->first_descendant(qr/^dc:description$/ix);
    my $meta = $self->{twigroot}->first_child('metadata');
    my $dcmeta = $meta->first_child('dc-metadata');

    my $gi = ($dcmeta) ? 'dc:Description' : 'dc:description';
    $self->set_metadata(gi => $gi,
                        text => $text,
                        id => $args{id});

    return 1;
}


=head2 C<set_erotic($bool)>

If C<$bool> is true, C<$self->{erotic}> is set to 1, otherwise this is
set to 0.

This will enable or disable special handling for erotic books, most
notably in subject normalization.

This is not related in any way to C<set_adult> which is a
Mobipocket-specific flag.

Returns 1 if no argument is given, 0 otherwise.

=cut

sub set_erotic :method {
    my ($self,$flag) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    return 1 unless(defined $flag);

    if($flag) {
        $self->{erotic} = 1;
    }
    else {
        $self->{erotic} = 0;
    }
    return 0;
}


=head2 C<set_language(%args)>

Sets the text and optionally the ID of the first dc:language element
found (case-insensitive).  Creates the element if one did not exist.
If a <dc-metadata> element exists underneath <metadata>, the language
element will be created underneath the <dc-metadata> in OEB 1.2
format, otherwise the title element is created underneath <metadata>
in OPF 2.0 format.

Returns 1 on success, returns undef if no text was specified.

=head3 Arguments

=over

=item C<text>

This specifies the language set as the text of the element.  If not
specified, the method sets an error and returns undef.  This should be
an IANA language code, and it will be lowercased before it is set.

=item C<id> (optional)

This specifies the ID to set on the element.  If set and the ID is
already in use, a warning is logged and the ID is removed from the
other location and assigned to the element.

=back

=head3 Example

 $retval = $ebook->set_language('text' => 'en-us',
                                'id' => 'langid');

=cut

sub set_language :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    my %valid_args = (
        'text' => 1,
        'id' => 1,
       );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
          if (!$valid_args{$arg});
    }

    my $text = lc($args{text});
    unless($text) {
        $self->add_error($subname,"(): no text specified");
        return;
    }

    $self->fix_metastructure_basic();
    my $element = $self->{twigroot}->first_descendant(qr/^dc:language$/ix);
    my $meta = $self->{twigroot}->first_child('metadata');
    my $dcmeta = $meta->first_child('dc-metadata');

    my $gi = ($dcmeta) ? 'dc:Language' : 'dc:language';
    $self->set_metadata(gi => $gi,
                        text => $text,
                        id => $args{id});
    return 1;
}


=head2 set_meta(%args)

Sets a <meta> element in the <metadata> element area.

=head3 Arguments

=over

=item C<name>

The name attribute to use when finding or creating OPF 2.0 <meta>
elements.  Either this or the property attribute (below) must be
specified, but specifying both is an error.

=item C<content>

The value of the content attribute to set on OPF 2.0 elements.  If
this value is empty or undefined, but C<name> is provided and matches
an existing element, that element will be deleted.

=item C<property>

The property attribute to use when finding or creating OPF 3.0 <meta>
elements.  Either this or C<name> (above) must be specified, but
specifying both is an error.

=item C<refines>

The refines attribute to use when finding or creating OPF 3.0 <meta>
elements.

=item C<scheme>

The scheme attribute to use when creating or updating OPF 3.0 <meta>
elements.

=item C<text>

The text set on OPF 3.0 <meta> elements.  If this value is empty or
undefined, but C<property> is provided and the combination of
C<property> and C<refines> matches an existing element, that element
will be deleted.

=item C<lang>

The xml:lang attribute to set.  This is valid on both OPF 2 and OPF 3
<meta> elements.

=back

=cut

sub set_meta :method {
    my ($self, %args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");
    my %valid_args = (
        'name'     => 1,
        'content'  => 1,
        'property' => 1,
        'refines'  => 1,
        'scheme'   => 1,
        'text'     => 1,
        'lang'     => 1,
       );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
          if (!$valid_args{$arg});
    }

    my $name = $args{name};
    my $content = $args{content};
    my $property = $args{property};
    my $refines = $args{refines};
    my $scheme = $args{scheme};
    my $text = $args{text};
    my $lang = $args{lang};
    my $standard;

    if ($name) {
        if ($property) {
            $self->add_error($subname,"(): both name (OPF2) and property (OPF3) attributes specified for a meta tag");
            return;
        }
        $standard = 'OPF2';
    }
    else {
        if ($property) {
            $standard = 'OPF3';
        }
        else {
            $self->add_error($subname,"(): neither name (OPF2) nor property (OPF3) attributes specified for a meta tag");
            return;
        }
    }

    $self->fix_metastructure_basic();
    my $metadata = $self->{twigroot}->first_child('metadata');
    my $element;

    if ($standard eq 'OPF2') {
        $element = $metadata->first_descendant('meta[@name="' . $name . '"]');

        if ($element) {
            if (! $content) {
                debug(2,"DEBUG: deleting <meta name='",$name,"'>");
                $element->delete;
            }
            else {
                debug(2,"DEBUG: updating <meta name='",$name,"'>");
                $element->set_att('content',$content);
                if ($lang) {
                    $element->set_att('xml:lang',$lang);
                }
            }
        }
        else {
            if ($content) {
                debug(2,"DEBUG: creating <meta name='",$name,"'>");
                $element = $metadata->insert_new_elt('last_child','meta');
                $element->set_att('name',$name);
                $element->set_att('content',$content);
            }
        }
    }
    elsif ($standard eq 'OPF3') {
        if ($refines) {
            $element = $metadata->first_descendant(
                'meta[@property="' . $property . '" and @refines="' . $refines . '"]');
        }
        else {
            $element = $metadata->first_descendant(
                'meta[@property="' . $property . '"]');
        }
        if ($element) {
            if (! $text) {
                debug(2,"DEBUG: deleting meta property='",$property,"'>");
                $element->delete;
            }
            else {
                debug(2,"DEBUG: updating <meta property='",$property,"'>");
                $element->set_text($text);
            }
            if ($scheme) {
                $element->set_att('scheme',$scheme);
            }
            if ($lang) {
                $element->set_att('xml:lang',$lang);
            }
        }
        else {
            if ($text) {
                debug(2,"DEBUG: creating <meta property='",$property,"'>");
                $element = $metadata->insert_new_elt('last_child','meta');
                $element->set_att('property',$property);
                if ($refines) {
                    $element->set_att('refines',$refines);
                }
                if ($scheme) {
                    $element->set_att('scheme',$scheme);
                }
                if ($lang) {
                    $element->set_att('xml:lang',$lang);
                }
                $element->set_text($text);
            }
        }
    }
    else {
        croak($subname,"(): unknown standard '${standard}'! (This should be impossible!)");
    }

    return;
}


=head2 set_metadata(%args)

Sets the text and optionally the ID of the first specified element
type found (case-insensitive).  Creates the element if one did not
exist (with the exact capitalization specified).

If a <dc-metadata> element exists underneath <metadata>, the language
element will be created underneath the <dc-metadata> and any standard
attributes will be created in OEB 1.2 format, otherwise the element is
created underneath <metadata> in OPF 2.0 format.

Returns 1 on success, returns undef if no gi or if no text was specified.

=cut

=head3 Arguments

=over

=item C<gi>

The generic identifier (tag) of the metadata element to alter or
create.  If not specified, the method sets an error and returns undef.

=item C<parent>

The generic identifier (tag) of the parent to use for any newly
created element.  If not specified, defaults to 'dc-metadata' if
'dc-metadata' exists underneath 'metadata', and 'metadata' otherwise.

A newly created element will be created under the first element found
with this gi.  A modified element will be moved under the first
element found with this gi.

Newly created elements will use OPF 2.0 attribute names if the parent
is 'metadata' and OEB 1.2 attribute names otherwise.

=item C<text>

This specifies the element text to set.  If not specified, the method
sets an error and returns undef.

=item C<id> (optional)

This specifies the ID to set on the element.  If set and the ID is
already in use, a warning is logged and the ID is removed from the
other location and assigned to the element.

=item C<fileas> (optional)

This specifies the file-as attribute to set on the element.

=item C<role> (optional)

This specifies the role attribute to set on the element.

=item C<scheme> (optional)

This specifies the scheme attribute to set on the element.

=back

=head3 Example

 $retval = $ebook->set_metadata(gi => 'AuthorNonstandard',
                                text => 'Element Text',
                                id => 'customid',
                                fileas => 'Text, Element',
                                role => 'xxx',
                                scheme => 'code');

=cut

sub set_metadata :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(3,"DEBUG[",$subname,"]");
    my %valid_args = (
        'gi' => 1,
        'parent' => 1,
        'text' => 1,
        'id' => 1,
        'fileas' => 1,
        'role' => 1,
        'scheme' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $gi = $args{gi};
    unless($gi) {
        $self->add_error($subname,"(): no gi specified");
        return;
    }

    my $text = $args{text};
    unless($text) {
        $self->add_error($subname,"(): no text specified");
        return;
    }

    my $newid = $args{id};
    my $idelem;
    $idelem = $self->{twig}->first_elt("*[\@id='$newid']") if($newid);

    my $element = $self->{twigroot}->first_descendant(qr/^ $gi $/ix);
    my $meta;
    my $dcmeta;
    my $parent;
    my %dcatts;

    $self->fix_metastructure_basic();
    $parent =  $self->{twigroot}->first_descendant(qr/^ $args{parent} $/ix)
        if($args{parent});
    $meta = $self->{twigroot}->first_child('metadata');
    $dcmeta = $meta->first_child('dc-metadata');
    $parent = $parent || $dcmeta || $meta;
    if($parent->gi eq 'metadata') {
        %dcatts = (
            'file-as' => 'opf:file-as',
            'role' => 'opf:role',
            'scheme' => 'opf:scheme',
            );
    }
    else {
        %dcatts = (
            'file-as' => 'file-as',
            'role' => 'role',
            'scheme' => 'scheme'
        );
    }


    if($element) {
        debug(2,"DEBUG: updating '",$gi,"'");
        if($element->att('opf:file-as') && $args{fileas}) {
            debug(3,"DEBUG:   setting opf:file-as '",$args{fileas},"'");
            $element->set_att('opf:file-as',$args{fileas});
        }
        elsif($args{fileas}) {
            debug(3,"DEBUG:   setting file-as '",$args{fileas},"'");
            $element->set_att('file-as',$args{fileas});
        }
        if($element->att('opf:role') && $args{role}) {
            debug(3,"DEBUG:   setting opf:role '",$args{role},"'");
            $element->set_att('opf:role',$args{role});
        }
        elsif($args{role}) {
            debug(3,"DEBUG:   setting role '",$args{role},"'");
            $element->set_att('role',$args{role});
        }
        if($element->att('opf:scheme') && $args{scheme}) {
            debug(3,"DEBUG:   setting opf:scheme '",$args{scheme},"'");
            $element->set_att('opf:scheme',$args{scheme});
        }
        elsif($args{scheme}) {
            debug(3,"DEBUG:   setting scheme '",$args{scheme},"'");
            $element->set_att('scheme',$args{scheme});
        }
        debug(3,"DEBUG:   setting text");
        $element->set_text($text);

        unless($element->parent->gi eq $parent->gi) {
            debug(2,"DEBUG: moving <",$element->gi,"> under <",
                  $parent->gi,">");
            $element->move('last_child',$parent);
        }
    }
    else {
        debug(2,"DEBUG: creating '",$gi,"' under <",$parent->gi,">");
        $element = $parent->insert_new_elt('last_child',$gi);
        $element->set_att($dcatts{'file-as'},$args{fileas})
            if($args{fileas});
        $element->set_att($dcatts{'role'},$args{role})
            if($args{role});
        $element->set_att($dcatts{'scheme'},$args{scheme})
            if($args{scheme});
        $element->set_text($text);
    }

    if($idelem && $idelem->cmp($element) ) {
        $self->add_warning(
            $subname,"(): reassigning id '",$newid,
            "' from a '",$idelem->gi,"' to a '",$element->gi,"'!"
            );
        $idelem->del_att('id');
    }
    $element->set_att('id' => $newid) if($newid);
    return 1;
}


=head2 set_opffile($filename)

Sets the filename used to store the OPF metadata.

Returns 1 on success; sets an error message and returns undef if no
filename was specified.

=cut

sub set_opffile :method {
    my ($self,$filename) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    unless($filename) {
        debug(1,$subname,"(): no filename specified!");
        $self->add_warning($subname,"(): no filename specified!");
        return;
    }
    $self->{opffile} = $filename;
    return 1;
}


=head2 set_retailprice(%args)

Sets the Mobipocket-specific <SRP> element (Suggested Retail Price),
creating or deleting it as necessary.

If a new element has to be created, L</fix_metastructure_oeb12> is
called to ensure that <x-metadata> exists and the element is created
under <x-metadata>, as Mobipocket elements are not recognized by
Mobipocket's software when placed directly under <metadata>

=head3 Arguments

=over

=item * C<text>

The price to set as the text of the element.  If this is undefined,
the method sets an error and returns undef.  If it is set but false,
any existing <SRP> element is deleted.

=item * C<currency> (optional)

The value to set on the 'Currency' attribute.  If not provided,
defaults to 'USD' (US Dollars)

=back

=cut

sub set_retailprice :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    $self->twigcheck;

    my %valid_args = (
        'text' => 1,
        'currency' => 1,
        );

    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }
    unless(defined $args{text}) {
        $self->add_error($subname,"(): text not defined");
        return;
    }

    my $xmeta;
    my $element;
    my @elements;

    if($args{text}) {
        $element = $self->{twigroot}->first_descendant(qr/^ SRP $/ix);
        unless($element) {
            $self->fix_metastructure_oeb12();
            $xmeta = $self->{twigroot}->first_descendant('x-metadata');
            $element = $xmeta->insert_new_elt('last_child','SRP');
        }
        $element->set_text($args{text});
        $element->set_att('Currency',$args{currency}) if($args{currency});
    }
    else {
        @elements = $self->{twigroot}->descendants(qr/^ SRP $/ix);
        foreach my $el (@elements) {
            debug(2,"DEBUG: deleting <SRP>");
            $el->delete;
        }
    }
    return 1;
}


=head2 set_primary_author(%args)

Sets the text, id, file-as, and role attributes of the primary author
element (see L</primary_author()> for details on how this is found),
or if no primary author exists, creates a new element containing the
information.

This method calls L</fix_metastructure_basic()> to enforce the
presence of the <metadata> element.  When creating a new element, the
method will use the OEB 1.2 element name and create the element
underneath <dc-metadata> if an existing <dc-metadata> element is found
underneath <metadata>.  If no existing <dc-metadata> element is found,
the new element will be created with the OPF 2.0 element name directly
underneath <metadata>.  Regardless, it is probably a good idea to call
L</fix_oeb12()> or L</fix_opf20()> after calling this method to ensure
a consistent scheme.

=head3 Arguments

Three optional named arguments can be passed:

=over

=item * C<text>

Specifies the author text to set.  If omitted and a primary author
element exists, the text will be left as is; if omitted and a primary
author element cannot be found, an error message will be generated and
the method will return undef.

=item * C<fileas>

Specifies the 'file-as' attribute to set.  If omitted and a primary
author element exists, any existing attribute will be left untouched;
if omitted and a primary author element cannot be found, the newly
created element will not have this attribute.

=item * C<id>

Specifies the 'id' attribute to set.  If this is specified, and the id
is already in use, a warning will be added but the method will
continue, removing the id attribute from the element that previously
contained it.

If this is omitted and a primary author element exists, any existing
id will be left untouched; if omitted and a primary author element
cannot be found, the newly created element will not have an id set.

=back

If called with no arguments, the only effect this method has is to
enforce that either an 'opf:role' or 'role' attribute is set to 'aut'
on the primary author element.

=head3 Return values

Returns 1 if successful, returns undef and sets an error message if
the author argument is missing and no primary author element was
found.

=cut

sub set_primary_author :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    my %valid_args = (
        'text' => 1,
        'fileas' => 1,
        'id' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $twigroot = $self->{twigroot};
    $self->fix_metastructure_basic();
    my $meta = $twigroot->first_child('metadata');
    my $dcmeta = $meta->first_child('dc-metadata');
    my $element;
    my $newauthor = $args{text};
    my $newfileas = $args{fileas};
    my $newid = $args{id};
    my $idelem;
    $idelem = $self->{twig}->first_elt("*[\@id='$newid']") if($newid);

    $element = $twigroot->first_descendant(\&twigelt_is_author);
    $element = $twigroot->first_descendant(qr/dc:creator/ix) if(!$element);

    unless($element) {
        unless($newauthor) {
            add_error(
                $subname,
                "(): cannot create a new author element when the author is not specified");
            return;
        }
        if($dcmeta) {
            $element = $dcmeta->insert_new_elt('last_child','dc:Creator');
            $element->set_att('role' => 'aut');
            $element->set_att('file-as' => $newfileas) if($newfileas);
        }
        else {
            $element = $meta->insert_new_elt('last_child','dc:creator');
            $element->set_att('opf:role' => 'aut');
            $element->set_att('opf:file-as' => $newfileas) if($newfileas);
        }
    } # unless($element)
    $element->set_text($newauthor);

    if($idelem && $idelem->cmp($element) ) {
        $self->add_warning(
            $subname,"(): reassigning id '",$newid,
            "' from a '",$idelem->gi,"' element!"
            );
        $idelem->del_att('id');
    }
    $element->set_att('id' => $newid) if($newid);
    return 1;
}


=head2 C<set_publisher(%args)>

Sets the text and optionally the ID of the first dc:publisher element
found (case-insensitive).  Creates the element if one did not exist.
If a <dc-metadata> element exists underneath <metadata>, the publisher
element will be created underneath the <dc-metadata> in OEB 1.2
format, otherwise the title element is created underneath <metadata>
in OPF 2.0 format.

Returns 1 on success, returns undef if no publisher was specified.

=head3 Arguments

C<set_publisher()> takes one required and one optional named argument

=over

=item C<text>

This specifies the publisher name to set as the text of the element.
If not specified, the method returns undef.

=item C<id> (optional)

This specifies the ID to set on the element.  If set and the ID is
already in use, a warning is logged and the ID is removed from the
other location and assigned to the element.

=back

=head3 Example

 $retval = $ebook->set_publisher('text' => 'My Publishing House',
                                 'id' => 'mypubid');

=cut

sub set_publisher :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    my %valid_args = (
        'text' => 1,
        'id' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $publisher = $args{text};
    return unless($publisher);

    my $newid = $args{id};
    my $idelem;
    $idelem = $self->{twig}->first_elt("*[\@id='$newid']") if($newid);

    $self->fix_metastructure_basic();
    my $element = $self->{twigroot}->first_descendant(qr/^dc:publisher$/ix);
    my $meta = $self->{twigroot}->first_child('metadata');
    my $dcmeta = $meta->first_child('dc-metadata');

    if(!$element && $dcmeta) {
        $element = $dcmeta->insert_new_elt('last_child','dc:Publisher');
    }
    elsif(!$element) {
        $element = $meta->insert_new_elt('last_child','dc:publisher');
    }
    $element->set_text($publisher);
    if($idelem && $idelem->cmp($element) ) {
        $self->add_warning(
            $subname,"(): reassigning id '",$newid,
            "' from a '",$idelem->gi,"' element!"
            );
        $idelem->del_att('id');
    }
    $element->set_att('id' => $newid) if($newid);
    return 1;
}


=head2 set_review(%args)

Sets the text and optionally ID of the first <Review> element found
(case-insensitive), creating the element if one did not exist.

This is a Mobipocket-specific element and if it needs to be created it
will always be created under <x-metadata> with
L</fix_metastructure_oeb12()> called to ensure that <x-metadata>
exists.

Returns 1 on success, returns undef if no review text was specified

=head3 Arguments

=over

=item C<text>

This specifies the description to use as the text of the element.  If
not specified, the method returns undef.

=item C<id> (optional)

This specifies the ID to set on the element.  If set and the ID is
already in use, a warning is logged and the ID is removed from the
other location and assigned to the element.

=back

=head3 Example

 $retval = $ebook->set_review('text' => 'This book is perfect!',
                              'id' => 'revid');

=cut

sub set_review :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    my %valid_args = (
        'text' => 1,
        'id' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $text = $args{text};
    unless($text) {
        $self->add_error($subname,"(): no text specified");
        return;
    }

    $self->fix_metastructure_oeb12();
    $self->set_metadata(gi => 'Review',
                        parent => 'x-metadata',
                        text => $args{text},
                        id => $args{id});

    return 1;
}


=head2 C<set_rights(%args)>

Sets the text of the first dc:rights or dc:copyrights element found
(case-insensitive).  If the element found has the gi of dc:copyrights,
it will be changed to dc:rights.  This is to correct certain
noncompliant Mobipocket files.

Creates the element if one did not exist.  If a <dc-metadata> element
exists underneath <metadata>, the title element will be created
underneath the <dc-metadata> in OEB 1.2 format, otherwise the title
element is created underneath <metadata> in OPF 2.0 format.

Returns 1 on success, returns undef if no rights string was specified.

=head3 Arguments

=over

=item * C<text>

This specifies the text of the element.  If not specified, the method
returns undef.

=item * C<id> (optional)

This specifies the ID to set on the element.  If set and the ID is
already in use, a warning is logged but the method continues anyway.

=back

=cut

sub set_rights :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    my %valid_args = (
        'text' => 1,
        'id' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }
    my $rights = $args{text};
    return unless($rights);
    my $newid = $args{id};
    my $idelem;
    $idelem = $self->{twig}->first_elt("*[\@id='$newid']") if($newid);

    $self->fix_metastructure_basic();
    my $element = $self->{twigroot}->first_descendant(qr/^dc:(copy)?rights$/ix);
    my $meta = $self->{twigroot}->first_child('metadata');
    my $dcmeta = $meta->first_child('dc-metadata');
    my $parent = $dcmeta || $meta;

    $element ||= $parent->insert_new_elt('last_child','dc:rights');
    $element->set_text($rights);
    $element->set_gi('dc:Rights') if($element->gi eq 'dc:Copyrights');
    $element->set_gi('dc:rights') if($element->gi eq 'dc:copyrights');
    if($idelem && $idelem->cmp($element) ) {
        $self->add_warning(
            $subname,"(): reassigning id '",$newid,
            "' from a '",$idelem->gi,"' element!"
            );
        $idelem->del_att('id');
    }
    $element->set_att('id' => $newid) if($newid);
    return 1;
}


=head2 C<set_spec($spec)>

Sets the OEB specification to match when modifying OPF data.
Allowable values are 'OEB12', 'OPF20', and 'MOBI12'.

Returns 1 if successful; returns undef and sets an error message if an
unknown specification was set.

=cut

sub set_spec :method {
    my ($self,$spec) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    unless($validspecs{$spec}) {
        $self->add_error($subname,"(): invalid specification '",$spec,"'");
        return;
    }
    $self->{spec} = $validspecs{$spec};
    return 1;
}


=head2 C<set_timestamp()>

Sets the <meta property="dcterms:modified"> element to the current
timestamp and removes duplicate or nonstandard timestamps.

=cut

sub set_timestamp :method {
    my ($self) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my @timestamps;
    my $twigroot = $self->{twigroot};
    my $time = Date::Manip::Date->new();

    @timestamps = $twigroot->descendants(
        'meta[@property="dcterms:modified" or @name="calibre:timestamp"]');
    foreach my $timestamp (@timestamps) {
        $timestamp->delete;
    }
    @timestamps = $twigroot->descendants(
        'dc:date[@opf:event="modification" or @event="modification"]');
    foreach my $timestamp (@timestamps) {
        $timestamp->delete;
    }
    $time->parse('now');
    $self->set_meta('property' => 'dcterms:modified',
                    'text' => $time->printf('%O') );
    return;
}


=head2 C<set_title(%args)>

Sets the text or id of the first dc:title element found
(case-insensitive).  Creates the element if one did not exist.  If a
<dc-metadata> element exists underneath <metadata>, the title element
will be created underneath the <dc-metadata> in OEB 1.2 format,
otherwise the title element is created underneath <metadata> in OPF
2.0 format.

=head3 Arguments

set_title() takes two optional named arguments.  If neither is
specified, the method will do nothing.

=over

=item * C<text>

This specifies the text of the element.  If not specified, and no
title element is found, an error will be set and the method will
return undef -- set_title() will refuse to create a dc:title element
with no text.

=item * C<id>

This specifies the ID to set on the element.  If set and the ID is
already in use, a warning is logged but the method continues anyway.

=back

=cut

sub set_title :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");

    my %valid_args = (
        'text' => 1,
        'id' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }
    my $title = $args{text};
    my $newid = $args{id};
    my $idelem;
    $idelem = $self->{twig}->first_elt("*[\@id='$newid']") if($newid);

    $self->fix_metastructure_basic();
    my $element = $self->{twigroot}->first_descendant(qr/^dc:title$/ix);
    my $meta = $self->{twigroot}->first_child('metadata');
    my $dcmeta = $meta->first_child('dc-metadata');
    my $parent = $dcmeta || $meta;
    unless($element) {
        unless($title) {
            add_error($subname,
                      "(): no title specified, but no existing title found");
            return;
        }
        $element = $parent->insert_new_elt('last_child','dc:title');
    }
    $element->set_text($title) if($title);

    if($idelem && $idelem->cmp($element) ) {
        $self->add_warning(
            $subname,"(): reassigning id '",$newid,
            "' from a '",$idelem->gi,"' element!"
            );
        $idelem->del_att('id');
    }
    $element->set_att('id' => $newid) if($newid);
    return 1;
}


=head2 C<set_type(%args)>

Sets the text and optionally the ID of the first dc:type element
found (case-insensitive).  Creates the element if one did not exist.
If a <dc-metadata> element exists underneath <metadata>, the publisher
element will be created underneath the <dc-metadata> in OEB 1.2
format, otherwise the title element is created underneath <metadata>
in OPF 2.0 format.

Returns 1 on success, returns undef if no publisher was specified.

=head3 Arguments

C<set_type()> takes one required and one optional named argument

=over

=item C<text>

This specifies the publisher name to set as the text of the element.
If not specified, the method returns undef.

=item C<id> (optional)

This specifies the ID to set on the element.  If set and the ID is
already in use, a warning is logged and the ID is removed from the
other location and assigned to the element.

=back

=head3 Example

 $retval = $ebook->set_type('text' => 'Short Story',
                            'id' => 'mytypeid');

=cut

sub set_type :method {
    my ($self,%args) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname . "() called as a procedure") unless(ref $self);
    debug(2,"DEBUG[",$subname,"]");
    my %valid_args = (
        'text' => 1,
        'id' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $text = $args{text};
    return unless($text);

    my $newid = $args{id};
    my $idelem;
    $idelem = $self->{twig}->first_elt("*[\@id='$newid']") if($newid);

    $self->fix_metastructure_basic();
    my $element = $self->{twigroot}->first_descendant(qr/^dc:type$/ix);
    my $meta = $self->{twigroot}->first_child('metadata');
    my $dcmeta = $meta->first_child('dc-metadata');

    if(!$element && $dcmeta) {
        $element = $dcmeta->insert_new_elt('last_child','dc:Type');
    }
    elsif(!$element) {
        $element = $meta->insert_new_elt('last_child','dc:type');
    }
    $element->set_text($text);
    if($idelem && $idelem->cmp($element) ) {
        $self->add_warning(
            $subname,"(): reassigning id '",$newid,
            "' from a '",$idelem->gi,"' element!"
            );
        $idelem->del_att('id');
    }
    $element->set_att('id' => $newid) if($newid);
    return 1;
}


################################
########## PROCEDURES ##########
################################

=head1 PROCEDURES

All procedures are exportable, but none are exported by default.  All
procedures can be exported by using the ":all" tag.


=head2 C<_lc>

Wrapper for CORE::lc to get around the fact that builtins can't be
used in dispatch tables prior to Perl 5.16.

WARNING: this procedure may disappear once Perl 5.16 is standard on
all systems in common use!  For that reason, this is not exportable.

=cut

sub _lc {
    my ($string) = @_;
    return lc $string;
}


=head2 C<_uc>

Wrapper for CORE::uc to get around the fact that builtins can't be
used in dispatch tables prior to Perl 5.16.

WARNING: this procedure may disappear once Perl 5.16 is standard on
all systems in common use!  For that reason, this is not exportable.

=cut

sub _uc {
    my ($string) = @_;
    return uc $string;
}


=head2 C<capitalize($string)>

Capitalizes the first letter of each word in $string.

Returns the corrected string.

=cut

sub capitalize {
    my ($string) = @_;
    $string =~ s/(?<=\w)(.)/\l$1/gx;
    return $string;
}


=head2 C<clean_filename($string)>

Takes an input string and cleans out any characters that would not be
valid in a filename.

Returns the cleaned string.

=cut

sub clean_filename {
    my ($string) = @_;
    $string =~ s/[^A-Za-z0-9_ \-\.]//g;
    return $string;
}


=head2 C<create_epub_container($opffile)>

Creates the XML file META-INF/container.xml pointing to the
specified OPF file.

Creates the META-INF directory if necessary.  Will destroy any
non-directory file named 'META-INF' in the current directory.  If
META-INF/container.xml already exists, it will rename that file to
META-INF/container.xml.backup.

=head3 Arguments

=over

=item $opffile

The OPF filename (and path, if necessary) to use in the container.  If
not specified, looks for a sole OPF file in the current working
directory.  Fails if more than one is found.

=back

=head3 Return values

=over

=item Returns a twig representing the container data if successful, undef
otherwise

=back

=cut

sub create_epub_container {
    my ($opffile) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $twig;
    my $twigroot;
    my $rootfiles;
    my $element;
    my $fh_container;

    if($opffile eq '') { return; }

    if(-e 'META-INF') {
	if(! -d 'META-INF') {
	    unlink('META-INF') or return;
	    mkdir('META-INF') or return;
	}
    }
    else { mkdir('META-INF') or return; }

    $twig = XML::Twig->new(
	output_encoding => 'utf-8',
	pretty_print => 'record'
	);

    $element = XML::Twig::Elt->new('container');
    $element->set_att('version' => '1.0',
		      'xmlns' => 'urn:oasis:names:tc:opendocument:xmlns:container');
    $twig->set_root($element);
    $twigroot = $twig->root;

    $rootfiles = $twigroot->insert_new_elt('first_child','rootfiles');
    $element = $rootfiles->insert_new_elt('first_child','rootfile');
    $element->set_att('full-path',$opffile);
    $element->set_att('media-type','application/oebps-package+xml');


    # Backup existing file
    if(-e 'META-INF/container.xml') {
        rename('META-INF/container.xml','META-INF/container.xml.backup')
            or croak($subname,"(): could not backup container.xml!");
    }

    open($fh_container,'>:encoding(UTF-8)','META-INF/container.xml')
        or croak($subname,"(): could not write to 'META-INF/container.xml'\n");
    $twig->print(\*$fh_container);
    close($fh_container)
        or croak($subname,"(): could not close 'META-INF/container.xml'\n");
    return $twig;
}


=head2 C<create_epub_mimetype()>

Creates a file named 'mimetype' in the current working directory
containing 'application/epub+zip' (no trailing newline)

Destroys and overwrites that file if it exists.

Returns the mimetype string if successful, undef otherwise.

=cut

sub create_epub_mimetype {
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $mimetype = "application/epub+zip";
    my $fh_mimetype;

    open($fh_mimetype,">",'mimetype') or return;
    print {*$fh_mimetype} $mimetype;
    close($fh_mimetype) or croak($subname,"(): failed to close filehandle [$!]");

    return $mimetype;
}


=head2 C<debug($level,@message)>

Prints a debugging message to C<STDERR> if package variable C<$debug>
is greater than or equal to C<$level>.  A trailing newline is
appended, and should not be part of @message.

Returns true or dies.

=cut

sub debug {
    my ($level,@message) = @_;
    my $subname = ( caller(0) )[3];
    croak($subname,"(): no debugging level specified") unless($level);
    croak($subname,"(): invalid debugging level '",$level,"'")
        unless( $level =~ /^\d$/ );
    croak($subname,"(): no message specified") unless(@message);
    print {*STDERR} @message,"\n" if($debug >= $level);
    return 1;
}


=head2 C<excerpt_line($text)>

Takes as an argument a list of text pieces that will be joined.  If
the joined length is less than 70, all of the joined text is returned.

If the joined length is greater than 70, the return string is the
first 30 characters followed by C<' [...] '> followed by the last 30
characters.

=cut

sub excerpt_line {
    my @parts = @_;
    my $subname = ( caller(0) )[3];
    my $text = join('',@parts);
    if(length($text) > 70)
    {
        $text =~ /^ (.{30}) .*? (.{30}) $/sx;
        return ($1 . ' [...] ' . $2);
    }
    else { return $text; }
}


=head2 C<find_in_path($pattern,@extradirs)>

Searches through C<$ENV{PATH}> (and optionally any additional
directories specified in C<@extradirs>) for the first regular file
matching C<$pattern>.  C<$pattern> itself can take two forms: if
passed a C<qr//> regular expression, that expression is used directly.
If passed any other string, that string will be used for a
case-insensitive exact match where the extension '.bat', '.com', or
'.exe' is optional (i.e. the final pattern will be
C<qr/^ $pattern (\.bat|\.com|\.exe)? $/ix>).

Returns the first match found, or undef if there were no matches or if
no pattern was specified.

=cut

sub find_in_path {
    my ($pattern,@extradirs) = @_;
    return unless($pattern);
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my $regexp;
    my @dirs;
    my $fh_dir;
    my @filelist;
    my $envsep = ':';
    my $filesep = '/';
    if($OSNAME eq 'MSWin32') {
        $envsep = ';';
        $filesep = "\\";
    }

    if(ref($pattern) eq 'Regexp') { $regexp = $pattern; }
    else { $regexp = qr/^ $pattern (\.bat|\.com|\.exe)? $/ix; }

    @dirs = split(/$envsep/,$ENV{PATH});
    unshift(@dirs,@extradirs) if(@extradirs);
    foreach my $dir (@dirs) {
        if(-d $dir) {
            if(opendir($fh_dir,$dir)) {
                @filelist = grep { /$regexp/ } readdir($fh_dir);
                @filelist = grep { -f "$dir/$_" } @filelist;
                closedir($fh_dir);

                if(@filelist) { return $dir . $filesep . $filelist[0]; }
            }
        }
    }
    return;
}

=head2 C<find_links($filename)>

Searches through a file for href and src attributes, and returns a
list of unique links with any named anchors removed
(e.g. 'myfile.html#part7' returns as just 'myfile.html').  If no links
are found, or the file does not exist, returns undef.

Does not check to see if the links are local.  Requires that links be
surrounded by double quotes, not single or left bare.  Assumes that
any link will not be broken across multiple lines, so it will (for
example) fail to find:

 <img src=
 "myfile.jpg">

though it can find:

 <img
  src="myfile.jpg">

This also does not distinguish between local files and remote links.

=cut

sub find_links {
    my ($filename) = @_;
    return unless(-f $filename);
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my $fh;
    my %linkhash;
    my @links;

    my $subdir = dirname($filename);
    if($subdir eq '.') {
        $subdir = '';
    }
    else {
        $subdir = $subdir . '/';
    }

    open($fh,'<:raw',$filename)
        or croak($subname,"(): unable to open '",$filename,"'\n");

    while(<$fh>) {
        @links = /(?:href|src) \s* = \s* "
                  ([^">]+)/gix;
        foreach my $link (@links) {
            # Perform URI decoding
            $link = uri_unescape($link);

            # Strip off any named anchors
            $link =~ s/#.*$//;
            next unless $link;

            # Skip links that begin with backwards directory traversal
            next if $link =~ m#^\.\./.*$#;

            # Strip javascript: hrefs
            next if $link =~ m#javascript:#;

            # Baen HTML sources in particular may contain javascript
            # href generators
            next if $link =~ /\+ /;

            # If the link is not a URI and we are in a subdirectory
            # relative to the OPF, ensure that subdirectory is placed
            # as a prefix.
            if($subdir and $link !~ m#^ \w+://#ix) {
                $link = $subdir . $link;
            }
            debug(2, "DEBUG: found link '",$link,"'");
            $linkhash{$link}++;
        }
    }
    if(%linkhash) { return keys(%linkhash); }
    else { return; }
}


=head2 C<find_opffile()>

Attempts to locate an OPF file, first by calling
L</get_container_rootfile()> to check the contents of
C<META-INF/container.xml>, and then by looking for a single file with
the extension C<.opf> in the current working directory.

Returns the filename of the OPF file, or undef if nothing was found.

=cut

sub find_opffile {
    my $subname = ( caller(0) )[3];
    my $opffile = get_container_rootfile();

    if(!$opffile) {
	my @candidates = glob("*.opf");
        if(scalar(@candidates) > 1) {
            debug(1,"DEBUG: Multiple OPF files found, but no container",
                  " to specify which one to choose!");
            return;
        }
        if(scalar(@candidates) < 1) {
            debug(1,"DEBUG: No OPF files found!");
            return;
        }
        $opffile = $candidates[0];
    }
    return $opffile;
}


=head2 C<fix_datestring($datestring)>

Takes a date string and attempts to convert it to the limited subset
of ISO8601 allowed by the OPF standard (YYYY, YYYY-MM, or YYYY-MM-DD).

In the special case of finding MM/DD/YYYY, it assumes that it was a
Mobipocket-mangled date, and not only converts it, but will strip the
day information if the day is '01', and both the month and day
information if both month and day are '01'.  This is because
Mobipocket Creator enforces a complete MM/DD/YYYY even if the month
and day aren't known, and it is common practice to use 01 for an
unknown value.

=head3 Arguments

=over

=item $datestring

A date string in a format recognizable by Date::Manip

=back

=head3 Returns $fixeddate

=over

=item $fixeddate : the corrected string, or undef on failure

=back

=cut

sub fix_datestring {
    my ($datestring) = @_;
    return unless($datestring);
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $date;
    my ($year,$month,$day);
    my $fixeddate;

    $_ = $datestring;

    debug(3,"DEBUG: checking M(M)/D(D)/YYYY");
    if(( ($month,$day,$year) = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/x ) == 3) {
	# We have a XX/XX/XXXX datestring
	debug(3,"DEBUG: found '",$month,"/",$day,"/",$year,"'");
	($year,$month,$day) = ymd_validate($year,$month,$day);
	if($year) {
	    $fixeddate = $year;
	    $fixeddate .= sprintf("-%02u",$month)
		unless( ($month == 1) && ($day == 1) );
	    $fixeddate .= sprintf("-%02u",$day) unless($day == 1);
	    debug(3,"DEBUG: returning '",$fixeddate,"'");
	    return $fixeddate;
	}
    }

    debug(3,"DEBUG: checking M(M)/YYYY");
    if(( ($month,$year) = /^(\d{1,2})\/(\d{4})$/x ) == 2) {
	# We have a XX/XXXX datestring
	debug(3,"DEBUG: found '",$month,"/",$year,"'");
	if($month <= 12) {
	    # We probably have MM/YYYY
	    $fixeddate = sprintf("%04u-%02u",$year,$month);
	    debug(3,"DEBUG: returning '",$fixeddate,"'");
	    return $fixeddate;
	}
    }

    # These regexps will reduce '2009-xx-01' to just 2009
    # We don't want this, so don't use them.
#    ($year,$month,$day) = /(\d{4})-?(\d{2})?-?(\d{2})?/;
#    ($year,$month,$day) = /(\d{4})(?:-?(\d{2})-?(\d{2}))?/;

    # Force exact match)
    debug(3,"DEBUG: checking YYYY-MM-DD");
    ($year,$month,$day) = /^(\d{4})-(\d{2})-(\d{2})$/x;
    ($year,$month,$day) = ymd_validate($year,$month,$day);

    if(!$year) {
	debug(3,"DEBUG: checking YYYYMMDD");
	($year,$month,$day) = /^(\d{4})(\d{2})(\d{2})$/x;
	($year,$month,$day) = ymd_validate($year,$month,$day);
    }

    if(!$year) {
	debug(3,"DEBUG: checking YYYY-M(M)");
	($year,$month) = /^(\d{4})-(\d{1,2})$/x;
	($year,$month) = ymd_validate($year,$month,undef);
    }

    if(!$year) {
	debug(3,"DEBUG: checking YYYY");
	($year) = /^(\d{4})$/x;
    }

    # At this point, we've exhausted all of the common cases.  We use
    # Date::Manip to hit all of the unlikely ones as well.  This comes
    # with a drawback: Date::Manip doesn't distinguish between 2008
    # and 2008-01-01, but we should have covered that above.
    #
    # Note that Date::Manip will die on MS Windows system unless the
    # TZ environment variable is set in a specific manner.
    # See:
    # http://search.cpan.org/perldoc?Date::Manip#TIME_ZONES

    if(!$year) {
	$date = ParseDate($datestring);
	$year = UnixDate($date,"%Y");
	$month = UnixDate($date,"%m");
	$day = UnixDate($date,"%d");
	debug(2,"DEBUG: Date::Manip found '",UnixDate($date,"%Y-%m-%d"),"'");
    }

    if($year) {
	# If we still have a $year, $month and $day either don't exist
	# or are plausibly valid.
	print {*STDERR} "DEBUG: found year=",$year," " if($debug >= 2);
	$fixeddate = sprintf("%04u",$year);
	if($month) {
	    print {*STDERR} "month=",$month," " if($debug >= 2);
	    $fixeddate .= sprintf("-%02u",$month);
	    if($day) {
		print {*STDERR} "day=",$day if($debug >= 2);
		$fixeddate .= sprintf("-%02u",$day);
	    }
	}
	print {*STDERR} "\n" if($debug >= 2);
	debug(2,"DEBUG: returning '",$fixeddate,"'");
	return $fixeddate if($fixeddate);
    }

    if(!$year) {
	debug(3,"fix_date: didn't find a valid date in '",$datestring,"'!");
	return;
    }
    elsif($debug) {
	print {*STDERR} "DEBUG: found ",sprintf("04u",$year);
	print {*STDERR} sprintf("-02u",$month) if($month);
	print {*STDERR} sprintf("-02u",$day),"\n" if($day);
    }

    $fixeddate = sprintf("%04u",$year);
    $fixeddate .= sprintf("-%02u-%02u",$month,$day);
    return $fixeddate;
}


=head2 C<get_container_rootfile($container)>

Opens and parses an OPS/epub container, extracting the 'full-path'
attribute of element 'rootfile'

=head3 Arguments

=over

=item $container

The OPS container to parse.  Defaults to 'META-INF/container.xml'

=back

=head3 Return values

=over

=item Returns a string containing the rootfile on success, undef on failure.

=back

=cut

sub get_container_rootfile {
    my ($container) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $twig = XML::Twig->new();
    my $rootfile;
    my $retval = undef;

    $container = 'META-INF/container.xml' if(! $container);

    if(-f $container) {
	$twig->parsefile($container) or return;
	$rootfile = $twig->root->first_descendant('rootfile');
	return unless($rootfile);
	$retval = $rootfile->att('full-path');
    }
    return $retval;
}


=head2 C<hashvalue_key_self(\%hash, $modifier)>

Takes as an argument a hash reference and an optional modifier and
inserts a new key for every value in that hash if no such key already
exists.

If the modifer is set to 'lc' or 'uc', the value is either lowercased
or uppercased respectively before it is used as a key.

Croaks if the first argument is not a hashref, or if an invalid
modifier string is used.

=cut

sub hashvalue_key_self {
    my ($hashref, $modifier) = @_;
    my $subname = ( caller(0) )[3];
    debug(4,"DEBUG[",$subname,"]");

    if (not $hashref or not ref($hashref)) {
        croak($subname,"(): first argument is not a reference");
    }
    elsif (!UNIVERSAL::isa($hashref,'HASH')) {
        croak($subname,"(): first argument is not a hashref");
    }

    my %modifier_dispatch = (
        'lc' => \&_lc,
        'uc' => \&_uc,
       );

    if ($modifier and not $modifier_dispatch{$modifier}) {
        croak($subname,"(): ",$modifier," is not a valid modifier string");
    }

    foreach my $value (values %{$hashref}) {
        my $key;
        if($modifier) {
            $key = $modifier_dispatch{$modifier}($value);
        }
        else {
            $key = $value;
        }
        if (! $hashref->{$key}) {
            $hashref->{$key} = $value;
        }
    }
    return;
}


=head2 C<hexstring($bindata)>

Takes as an argument a scalar containing a sequence of binary bytes.
Returns a string converting each octet of the data to its two-digit
hexadecimal equivalent.  There is no leading "0x" on the string.

=cut

sub hexstring {
    my $data = shift;
    my $subname = ( caller(0) )[3];
    debug(4,"DEBUG[",$subname,"]");

    croak($subname,"(): no data provided")
        unless($data);

    my $byte;
    my $retval = '';
    my $pos = 0;

    while($pos < length($data)) {
        $byte = unpack("C",substr($data,$pos,1));
        $retval .= sprintf("%02x",$byte);
        $pos++;
    }
    return $retval;
}


=head2 C<print_memory($label)>

Checks /proc/$PID/statm and prints out a line to STDERR showing the
current memory usage.  This is a debugging tool that will likely fail
to do anything useful on a system without a /proc system compatible
with Linux.

=head3 Arguments

=over

=item $label

If defined, will be output along with the memory usage.

=back

Returns 1 on success, undef otherwise.

=cut

sub print_memory {
    my ($label) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my @mem;
    my $fh_procstatm;

    if(!open($fh_procstatm,"<","/proc/$$/statm")) {
	print "[",$label,"]: " if(defined $label);
	print "Couldn't open /proc/$$/statm [$!]\n";
        return;
    }

    @mem = split(/\s+/,<$fh_procstatm>);
    close($fh_procstatm);

    # @mem[0]*4 = size (kb)
    # @mem[1]*4 = resident (kb)
    # @mem[2]*4 = shared (kb)
    # @mem[3] = trs
    # @mem[4] = lrs
    # @mem[5] = drs
    # @mem[6] = dt

    print "Current memory usage";
    print " [".$label."]" if(defined $label);
    print ":  size=",$mem[0]*4,"k";
    print "  resident=",$mem[1]*4,"k";
    print "  shared=",$mem[2]*4,"k\n";
    return 1;
}



=head2 C<split_metadata($metahtmlfile, $metafile)>

Takes a psuedo-HTML containing one or more <metadata>...</metadata>
blocks and splits out the metadata blocks into an XML file ready to be
used as an OPF document.  The input HTML file is rewritten without the
metadata.

If $metafile (or the temporary HTML-only file created during the
split) already exists, it will be moved to filename.backup.

=head3 Arguments

=over

=item C<$metahtmlfile>

The filename of the pseudo-HTML file

=item C<$metafile> (optional)

The filename to write out any extracted metadata.  If not specified,
will default to the basename of $metahtmlfile with '.opf' appended.

=back

Returns the filename the metadata was written to, or undef if no
metadata was found.

=cut

sub split_metadata {
    my ($metahtmlfile,$metafile) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    croak($subname,"(): no input file specified")
        if(!$metahtmlfile);

    croak($subname,"(): input file has zero size")
        if(-z $metahtmlfile);

    my @metablocks;
    my @guideblocks;
    my $htmlfile;

    my ($filebase,$filedir,$fileext);
    my ($fh_metahtml,$fh_meta,$fh_html);

    ($filebase,$filedir,$fileext) = fileparse($metahtmlfile,'\.\w+$');
    $metafile = $filedir . $filebase . ".opf" if(!$metafile);
    $htmlfile = $filedir . $filebase . "-html.html";

    debug(2,"DEBUG: metahtml='",$metahtmlfile,"'  meta='",$metafile,
          "  html='",$htmlfile,"'");

    # Move existing output files to avoid overwriting them
    if(-f $metafile) {
        debug(3, "DEBUG: moving metafile '",$metafile,"'");
        croak ($subname,"(): output file '",$metafile,
               "' exists and could not be moved!")
            if(! rename($metafile,"$metafile.backup") );
    }
    if(-f $htmlfile) {
        debug(3, "DEBUG: moving htmlfile '",$htmlfile,"'");
        croak ($subname,"(): output file '",$htmlfile,
               "' exists and could not be moved!")
            if(! rename($htmlfile,"$metafile.backup") );
    }

    debug(2,"  splitting '",$metahtmlfile,"'");
    open($fh_metahtml,"<:raw",$metahtmlfile)
	or croak($subname,"(): Failed to open '",$metahtmlfile,"' for reading!");
    open($fh_meta,">:raw",$metafile)
	or croak($subname,"(): Failed to open '",$metafile,"' for writing!");
    open($fh_html,">:raw",$htmlfile)
	or croak($subname,"(): Failed to open '",$htmlfile,"' for writing!");


    # Preload the return value with the OPF headers
    print $fh_meta $utf8xmldec,$oeb12doctype,"<package>\n";
    #print $fh_meta $utf8xmldec,$opf20package;

    # Finding and removing all of the metadata requires that the
    # entire thing be handled as one slurped string, so temporarily
    # undefine the perl delimiter
    #
    # Since multiple <metadata> sections may be present, cannot use
    # </metadata> as a delimiter.
    local $/;
    while(<$fh_metahtml>) {
        s/\sfilepos=\d+//gix;
	(@metablocks) = m#(<metadata>.*</metadata>)#gisx;
	(@guideblocks) = m#(<guide>.*</guide>)#gisx;
	last unless(@metablocks || @guideblocks);
	print {*$fh_meta} @metablocks,"\n" if(@metablocks);
	print {*$fh_meta} @guideblocks,"\n" if(@guideblocks);
	s#<metadata>.*</metadata>##gisx;
	s#<guide>.*</guide>##gisx;
	print {*$fh_html} $_,"\n";
    }
    print $fh_meta "</package>\n";

    close($fh_html)
        or croak($subname,"(): Failed to close '",$htmlfile,"'!");
    close($fh_meta)
        or croak($subname,"(): Failed to close '",$metafile,"'!");
    close($fh_metahtml)
        or croak($subname,"(): Failed to close '",$metahtmlfile,"'!");

    if( (-z $htmlfile) && (-z $metafile) ) {
        croak($subname,"(): ended up with no text in any output file",
              " -- bailing out!");
    }

    # It is very unlikely that split_metadata will be called twice
    # from the same program, so undef all capture variables reclaim
    # the memory.  Just going out of scope will not necessarily do
    # this.
    undef(@metablocks);
    undef(@guideblocks);
    undef($_);

    if(-z $htmlfile) {
        debug(1,"split_metadata(): HTML has zero size.",
             "  Not replacing original.");
        unlink($htmlfile);
    }
    else {
        rename($htmlfile,$metahtmlfile)
            or croak("split_metadata(): Failed to rename ",$htmlfile,
                     " to ",$metahtmlfile,"!\n");
    }

    if(-z $metafile) {
        croak($subname,
              "(): unable to remove empty output file '",$metafile,"'!")
            if(! unlink($metafile) );
        return;
    }
    return $metafile;
}


=head2 C<split_pre($htmlfile,$outfilebase)>

Splits <pre>...</pre> blocks out of a source HTML file into their own
separate HTML files including required headers.  Each block will be
written to its own file following the naming format
C<$outfilebase-###.html>, where ### is a three-digit number beginning
at 001 and incrementing for each block found.  If C<$outfilebase> is
not specified, it defaults to the basename of C<$htmlfile> with
"-pre-###.html" appended.  The

Returns a list containing all filenames created.

=cut

sub split_pre {
    my ($htmlfile,$outfilebase) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    croak($subname,"(): no input file specified")
        if(!$htmlfile);

    my ($filebase,$filedir,$fileext);
    my ($fh_html,$fh_htmlout,$fh_pre);
    my $htmloutfile;
    my @preblocks;
    my @prefiles = ();
    my $prefile;
    my $count = 0;

    my $htmlheader = <<'END';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title></title>
</head>
<body>
END

    ($filebase,$filedir,$fileext) = fileparse($htmlfile,'\.\w+$');
    $outfilebase = "$filebase-pre" if(!$outfilebase);
    $htmloutfile = "$filebase-nopre.html";

    open($fh_html,"<:raw",$htmlfile)
	or croak($subname,"(): Failed to open '",$htmlfile,"' for reading!");
    open($fh_htmlout,">:raw",$htmloutfile)
        or croak($subname,"(): Failed to open '",$htmloutfile,"' for writing!");

    local $/;
    while(<$fh_html>)
    {
	(@preblocks) = /(<pre>.*?<\/pre>)/gisx;
	last unless(@preblocks);

        foreach my $pre (@preblocks)
        {
            $count++;
            debug(1,"DEBUG: split_pre() splitting block ",
                  sprintf("%03d",$count));
            $prefile = sprintf("%s-%03d.html",$outfilebase,$count);
            if(-f $prefile)
            {
                rename($prefile,"$prefile.backup")
                    or croak("Unable to rename '",$prefile,
                             "' to '",$prefile,".backup'");
            }
            open($fh_pre,">:raw",$prefile)
                or croak("Unable to open '",$prefile,"' for writing!");
            print {*$fh_pre} $utf8xmldec;
            print {*$fh_pre} $htmlheader,"\n";
            print {*$fh_pre} $pre,"\n";
            print {*$fh_pre} "</body>\n</html>\n";
            close($fh_pre) or croak("Unable to close '",$prefile,"'!");
            push @prefiles,$prefile;
        }
	s/(<pre>.*?<\/pre>)//gisx;
	print {*$fh_htmlout} $_,"\n";
        close($fh_htmlout)
            or croak($subname,"(): Failed to close '",$htmloutfile,"'!");
        rename($htmloutfile,$htmlfile)
            or croak($subname,"(): Failed to rename '",$htmloutfile,"' to '",
                     $htmlfile,"'!");
    }
    return @prefiles;
}


=head2 C<strip_script(%args)>

Strips any <script>...</script> blocks out of a HTML file.

=head3 Arguments

=over

=item C<infile>

Specifies the input file.  If not specified, the sub croaks.

=item C<outfile>

Specifies the output file.  If not specified, it defaults to C<infile>
(i.e. the input file is overwritten).

=item C<noscript>

If set to true, the sub will strip <noscript>...</noscript> blocks as
well.

=back

=cut

sub strip_script {
    my %args = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    croak($subname,"(): no input file specified")
        if(!$args{infile});

    my %valid_args = (
        'infile'  => 1,
        'outfile' => 1,
        'noscript' => 1,
        );
    foreach my $arg (keys %args) {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $infile = $args{infile};
    my $outfile = $args{outfile};
    $outfile = $infile unless($outfile);

    my ($fh_in,$fh_out);
    my $html;
    local $/;

    open($fh_in,"<:raw",$infile)
	or croak($subname,"(): Failed to open '",$infile,"' for reading!\n");
    $html = <$fh_in>;
    close($fh_in)
	or croak($subname,"(): Failed to close '",$infile,"'!\n");

    $html =~ s#<script>.*?</script>\n?##gix;
    $html =~ s#<noscript>.*?</noscript>\n?##gix
        if($args{noscript});

    open($fh_out,">:raw",$outfile)
	or croak($subname,"(): Failed to open '",$outfile,"' for writing!\n");
    print {*$fh_out} $html;
    close($fh_out)
	or croak($subname,"(): Failed to close '",$outfile,"'!\n");

    return 1;
}


=head2 C<system_result($caller,$retval,@syscmd)>

Checks the result of a system call and croak on failure with an
appropriate message.  For this to work, it MUST be used as the line
immediately following the system command.

=head3 Arguments

=over

=item $caller

The calling function (used in output message)

=item $retval

The return value of the system command

=item @syscmd

The array passed to the system call

=back

=head3 Return Values

Returns 0 on success

Croaks on failure.

=cut

sub system_result {
    my ($caller,$retval,@syscmd) = @_;

    if ( ($CHILD_ERROR >> 8) == 0 ) {
        return 0;
    }
    elsif ($CHILD_ERROR == -1) {
        croak($caller," child failed to execute (ERRNO=",$ERRNO,"):\n ",
              join(' ',@syscmd),"\n")
    }
    elsif ($CHILD_ERROR & 127) {
        my $withcoredump = ($CHILD_ERROR & 128) ? 'with' : 'without';
        croak($caller," child died with signal ",($CHILD_ERROR & 127)," ",
              $withcoredump," coredump:\n ",join(' ',@syscmd),"\n");
    }
    else {
        croak($caller," child exited with value ",$CHILD_ERROR >> 8,":\n ",
              join(' ',@syscmd),"\n")
    }
}


=head2 C<system_tidy_xhtml($infile,$outfile)>

Runs tidy on a XHTML file semi-safely (using a secondary file)

Converts HTML to XHTML if necessary

=head3 Arguments

=over

=item $infile

The filename to tidy

=item $outfile

The filename to use for tidy output if the safety condition to
overwrite the input file isn't met.

Defaults to C<infile-tidy.ext> if not specified.

=back

=head3 Global variables used

=over

=item $tidycmd

the location of the tidy executable

=item $tidyxhtmlerrors

the filename to use to output errors

=item $tidysafety

the safety factor to use (see CONFIGURABLE GLOBAL VARIABLES, above)

=back

=head3 Return Values

Returns the return value from tidy

=over

=item 0 - no errors

=item 1 - warnings only

=item 2 - errors

=item Dies horribly if the return value is unexpected

=back

=cut

sub system_tidy_xhtml {
    my ($infile,$outfile) = @_;
    my $retval;

    croak("system_tidy_xhtml called with no input file") if(!$infile);
    if(!$outfile)
    {
        my ($filebase,$filedir,$fileext) = fileparse($infile,'\.\w+$');
        $outfile = $filebase . "-tidy" . $fileext;
    }
    croak("system_tidy_xhtml called with no output file") if(!$outfile);

    $retval = system($tidycmd,
		     '-q','-utf8','--tidy-mark','no',
                     '--wrap','0',
                     '--clean','yes',
		     '-asxhtml',
                     '--output-xhtml','yes',
                     '--add-xml-decl','yes',
		     '--doctype','auto',
		     '-f',$tidyxhtmlerrors,
		     '-o',$outfile,
		     $infile);

    # Some systems may return a two-byte code, so deal with that first
    if($retval >= 256) { $retval = $retval >> 8 };
    if($retval == 0)
    {
	rename($outfile,$infile) if($tidysafety < 4);
	unlink($tidyxhtmlerrors);
    }
    elsif($retval == 1)
    {
	rename($outfile,$infile) if($tidysafety < 3);
	unlink($tidyxhtmlerrors) if($tidysafety < 2);
    }
    elsif($retval == 2)
    {
	print {*STDERR} "WARNING: Tidy errors encountered.  Check ",$tidyxhtmlerrors,"\n"
	    if($tidysafety > 0);
	unlink($tidyxhtmlerrors) if($tidysafety < 1);
    }
    else
    {
	# Something unexpected happened (program crash, sigint, other)
	croak("Tidy did something unexpected (return value=",$retval,
              ").  Check all output.");
    }
    return $retval;
}


=head2 C<system_tidy_xml($infile,$outfile)>

Runs tidy on an XML file semi-safely (using a secondary file)

=head3 Arguments

=over

=item C<$infile>

The filename to tidy

=item C<$outfile> (optional)

The filename to use for tidy output if the safety condition to
overwrite the input file isn't met.

Defaults to C<infile-tidy.ext> if not specified.

=back

=head3 Global variables used

=over

=item C<$tidycmd>

the name of the tidy executable

=item C<$tidyxmlerrors>

the filename to use to output errors

=item C<$tidysafety>

the safety factor to use (see CONFIGURABLE GLOBAL VARIABLES, above)

=back

=head3 Return values

Returns the return value from tidy

=over

=item 0 - no errors

=item 1 - warnings only

=item 2 - errors

=item Dies horribly if the return value is unexpected

=back

=cut

  sub system_tidy_xml {
      my ($infile,$outfile) = @_;
      my $retval;

      croak("system_tidy_xml called with no input file") if(!$infile);

      if (!$outfile) {
          my ($filebase,$filedir,$fileext) = fileparse($infile,'\.\w+$');
          $outfile = $filebase . "-tidy" . $fileext;
      }
      croak("system_tidy_xml called with no output file") if(!$outfile);

      $retval = system($tidycmd,
                       '-q','-utf8','--tidy-mark','no',
                       '--wrap','0',
                       '-xml',
                       '--add-xml-decl','yes',
                       '-f',$tidyxmlerrors,
                       '-o',$outfile,
                       $infile);

      # Some systems may return a two-byte code, so deal with that first
      if ($retval >= 256) {
          $retval = $retval >> 8;
      }
      ;
      if ($retval == 0) {
          rename($outfile,$infile) if($tidysafety < 4);
          unlink($tidyxmlerrors);
      }
      elsif ($retval == 1) {
          rename($outfile,$infile) if($tidysafety < 3);
          unlink($tidyxmlerrors) if($tidysafety < 2);
      }
      elsif ($retval == 2) {
          print STDERR "WARNING: Tidy errors encountered.  Check ",$tidyxmlerrors,"\n"
	    if ($tidysafety > 0);
          unlink($tidyxmlerrors) if($tidysafety < 1);
      }
      else {
          # Something unexpected happened (program crash, sigint, other)
          croak("Tidy did something unexpected (return value=",$retval,
                ").  Check all output.");
      }
      return $retval;
  }


=head2 C<trim>

Removes any whitespace characters from the beginning or end of every
string in @list (also works on scalars).

 trim;               # trims $_ inplace
 $new = trim;        # trims (and returns) a copy of $_
 trim $str;          # trims $str inplace
 $new = trim $str;   # trims (and returns) a copy of $str
 trim @list;         # trims @list inplace
 @new = trim @list;  # trims (and returns) a copy of @list

This was shamelessly copied from japhy's example at perlmonks.org:

http://www.perlmonks.org/?node_id=36684

If needed for large lists, it would probably be better to use
String::Strip.

=cut

sub trim { ## no critic
    ## no critic
    # PerlCritic is turned off here, as this is unusual code
    # deliberately bending rules.
    @_ = $_ if not @_ and defined wantarray;
    @_ = @_ if defined wantarray;
    for ( @_ ? @_ : $_ ) { s/^\s+//, s/\s+$// }
    return wantarray ? @_ : $_[ 0 ] if defined wantarray;
}


=head2 C<twigelt_create_uuid($gi)>

Creates an unlinked element with the specified gi (tag), and then
assigns it the id and scheme attributes 'UUID'.

=head3 Arguments

=over

=item  $gi : The gi (tag) to use for the element

Default: 'dc:identifier'

=back

Returns the element.

=cut

sub twigelt_create_uuid {
    my ($gi) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");
    my $element;

    if(!$gi) { $gi = 'dc:identifier'; }

    my $uuidgen = Data::UUID->new();
    $element = XML::Twig::Elt->new($gi);
    $element->set_id('UUID');
    $element->set_att('scheme' => 'UUID');
    $element->set_text($uuidgen->create_str());
    return $element;
}


=head2 C<twigelt_detect_duplicate($element1, $element2)>

Takes two twig elements and returns 1 if they have the same GI (tag),
text, and attributes, but are not actually the same element.  The GI
comparison is case-insensitive.  The others are case-sensitive.

Returns 0 otherwise.

Croaks if passed anything but twig elements.

=cut

sub twigelt_detect_duplicate {
    my ($element1,$element2) = @_;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    croak($subname,"(): arguments must be XML::Twig::Elt objects")
      unless( $element1->isa('XML::Twig::Elt')
                && $element2->isa('XML::Twig::Elt') );

    my (%atts1, %atts2);

    unless($element1->cmp($element2)) {
        debug(3,"  both elements have the same position");
        return 0;
    }

    unless( lc($element1->gi) eq lc($element2->gi) ) {
        debug(3,"  elements have different GIs");
        return 0;
    }

    unless($element1->text eq $element2->text) {
        debug(3,"  elements have different text");
        return 0;
    }

    %atts1 = %{$element1->atts};
    %atts2 = %{$element2->atts};

    my $attkeys1 = join('',sort keys %atts1);
    my $attkeys2 = join('',sort keys %atts2);

    unless($attkeys1 eq $attkeys2) {
        debug(3,"  elements have different attributes");
        return 0;
    }

    foreach my $att (keys %atts1) {
        unless($element1->att($att) eq $element2->att($att)) {
            debug(3,"  elements have different values for attribute '",
                  $att,"'");
            return 0;
        }
    }
    debug(3,"  elements are duplicates of each other!");
    return 1;
}

=head2 C<twigelt_fix_oeb12_atts($element)>

Checks the attributes in a twig element to see if they match OPF names
with an opf: namespace, and if so, removes the namespace.  Used by the
fix_oeb12() method.

Takes as a sole argument a twig element.

Returns that element with the modified attributes, or undef if the
element didn't exist.  Returns an unmodified element if both att and
opf:att exist.

=cut

sub twigelt_fix_oeb12_atts {
    my ($element) = @_;
    return unless($element);
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my %opfatts_no_ns = (
        "opf:role" => "role",
        "opf:file-as" => "file-as",
        "opf:scheme" => "scheme",
        "opf:event" => "event"
        );

    foreach my $att ($element->att_names)
    {
        debug(3,"DEBUG:   checking attribute '",$att,"'");
        if($opfatts_no_ns{$att})
        {
            # If the opf:att attribute properly exists already, do nothing.
            if($element->att($opfatts_no_ns{$att}))
            {
                debug(1,"DEBUG:   found both '",$att,"' and '",
                      $opfatts_no_ns{$att},"' -- skipping.");
                next;
            }
            debug(1,"DEBUG:   changing attribute '",$att,"' => '",
                  $opfatts_no_ns{$att},"'");
            $element->change_att_name($att,$opfatts_no_ns{$att});
        }
    }
    return $element;
}


=head2 C<twigelt_fix_opf20_atts($element)>

Checks the attributes in a twig element to see if they match OPF
names, and if so, prepends the OPF namespace.  Used by the fix_opf20()
method.

Takes as a sole argument a twig element.

Returns that element with the modified attributes, or undef if the
element didn't exist.

=cut

sub twigelt_fix_opf20_atts {
    my ($element) = @_;
    return unless($element);
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my %opfatts_ns = (
        "role" => "opf:role",
        "file-as" => "opf:file-as",
        "scheme" => "opf:scheme",
        "event" => "opf:event"
        );

    foreach my $att ($element->att_names)
    {
        debug(2,"DEBUG:   checking attribute '",$att,"'");
        if($opfatts_ns{$att})
        {
            # If the opf:att attribute properly exists already, do nothing.
            if($element->att($opfatts_ns{$att}))
            {
                debug(1,"DEBUG:   found both '",$att,"' and '",
                      $opfatts_ns{$att},"' -- skipping.");
                next;
            }
            debug(1,"DEBUG:   changing attribute '",$att,"' => '",
                  $opfatts_ns{$att},"'");
            $element->change_att_name($att,$opfatts_ns{$att});
        }
    }
    return $element;
}


=head2 C<twigelt_is_author($element)>

Takes as an argument a twig element.  Returns true if the element is a
dc:creator (case-insensitive) with either a opf:role="aut" or
role="aut" attribute defined.  Returns undef otherwise, and also if
the element has no text.

Croaks if fed no argument, or fed an argument that isn't a twig
element.

Intended to be used as a twig search condition.

=head3 Example

 my @elements = $ebook->twigroot->descendants(\&twigelt_is_author);

=cut

sub twigelt_is_author {
    my ($element) = @_;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    croak($subname,"(): no element provided") unless($element);

    my $ref = ref($element) || '';

    croak($subname,"(): argument was of type '",$ref,
          "', needs to be 'XML::Twig::Elt' or a subclass")
        unless($element->isa('XML::Twig::Elt'));

    return if( (lc $element->gi) ne 'dc:creator');
    return unless($element->text);

    my $role = $element->att('opf:role') || $element->att('role');
    return unless($role);

    return 1 if($role eq 'aut');
    return;
}


=head2 C<twigelt_is_isbn($element)>

Takes as an argument a twig element.  Returns true if the element is a
dc:identifier (case-insensitive) where any of the id, opf:scheme, or
scheme attributes start with 'isbn', '-isbn', 'eisbn', or 'e-isbn'
(again case-insensitive).

Returns undef otherwise, and also if the element has no text.

Croaks if fed no argument, or fed an argument that isn't a twig
element.

Intended to be used as a twig search condition.

=head3 Example

 my @elements = $ebook->twigroot->descendants(\&twigelt_is_isbn);

=cut

sub twigelt_is_isbn {
    my ($element) = @_;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    croak($subname,"(): no element provided") unless($element);

    my $ref = ref($element) || '';
    my $id;
    my $scheme;

    croak($subname,"(): argument was of type '",$ref,
          "', needs to be 'XML::Twig::Elt' or a subclass")
        unless($element->isa('XML::Twig::Elt'));

    return if( (lc $element->gi) ne 'dc:identifier');
    return unless($element->text);

    $id = $element->id || '';
    return 1 if($id =~ /^e?-?isbn/ix);

    $scheme = $element->att('opf:scheme') || '';
    return 1 if($scheme =~ /^e?-?isbn/ix);
    $scheme = $element->att('scheme') || '';
    return 1 if($scheme =~ /^e?-?isbn/ix);
    return;
}


=head2 C<twigelt_is_knownuid($element)>

Takes as an argument a twig element.  Returns true if the element is a
dc:identifier (case-insensitive) element with an C<id> attribute
matching the known IDs of proper unique identifiers suitable for a
package-id (also case-insensitive).  Returns undef otherwise.

Croaks if fed no argument, or fed an argument that isn't a twig element.

Intended to be used as a twig search condition.

=head3 Example

 my @elements = $ebook->twigroot->descendants(\&twigelt_is_knownuid);

=cut

sub twigelt_is_knownuid {
    my ($element) = @_;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    croak($subname,"(): no element provided") unless($element);

    my $ref = ref($element) || '';

    croak($subname,"(): argument was of type '",$ref,
          "', needs to be 'XML::Twig::Elt' or a subclass")
        unless($element->isa('XML::Twig::Elt'));

    return if( (lc $element->gi) ne 'dc:identifier');
    my $id = $element->id;
    return unless($id);

    my %knownuids = (
        'package-id' => 56,
        'overdriveguid' => 48,
        'guid' => 40,
        'uuid' => 32,
        'uid'  => 24,
        'calibre_id' => 16,
        'fwid' => 8,
        );

    if($knownuids{lc $id})
    {
#        debug(2,"DEBUG: '",$element->gi,"' has known UID '",$id,"'");
        return 1;
    }
    return;
}


=head2 C<usedir($dir)>

Changes the current working directory to the one specified, creating
it if necessary.

Returns the current working directory before the change.  If no
directory is specified, returns the current working directory without
changing anything.

Croaks on any failure.

=cut

sub usedir {
    my ($dir) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]: $dir");

    my $cwd = getcwd();
    return $cwd unless($dir);

    unless(-d $dir) {
        debug(2,"  Creating directory '",$dir,"'");
        mkpath($dir)
            or croak("Unable to create output directory '",$dir,"'!\n");
    }
    chdir($dir)
        or croak("Unable to change working directory to '",$dir,"'!\n");
    return $cwd;
}


=head2 C<userconfigdir()>

Returns the directory in which user configuration files and helper
programs are expected to be found, creating that directory if it does
not exist.  Typically, this directory is C<"$ENV{HOME}/.ebooktools">,
but on MSWin32 systems if that directory does not already exist,
C<"$ENV{USERPROFILE}/ApplicationData/EBook-Tools"> is returned (and
potentially created) instead.

If C<$ENV{HOME}> (and C<$ENV{USERPROFILE}> on MSWin32) are either not
set or do not point to a directory, the sub returns undef.

=cut

sub userconfigdir {
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my $dir;

    if(-d $ENV{HOME}) {
        $dir = $ENV{HOME} . '/.ebooktools';
    }

    if($OSNAME eq 'MSWin32') {
        if(not -d $dir and -d $ENV{USERPROFILE}) {
            $dir = $ENV{USERPROFILE} . '\Application Data\EBook-Tools';
        }
    }
    if($dir) {
        if(! -d $dir) {
            mkpath($dir)
                or croak($subname,
                         "(): unable to create configuration directory '",
                         $dir,"'!\n");
        }
        return $dir;
    }
    else { return; }
}


=head2 C<ymd_validate($year,$month,$day)>

Make sure month and day have valid values.  Return the passed values
if they are, return 3 undefs if not.  Testing of month or day can be
skipped by passing undef in that spot.

=cut

sub ymd_validate {
    my ($year,$month,$day) = @_;

    return (undef,undef,undef) unless($year);

    if($month) {
	return (undef,undef,undef) if($month > 12);
	if($day) {
	    if(!eval { timelocal(0,0,0,$day,$month-1,$year); }) {
		debug(1,"DEBUG: timelocal validation failed for year=",
                      $year," month=",$month," day=",$day);
		return (undef,undef,undef);
	    }
	}
	return ($year,$month,$day);
    }

    # We don't have a month.  If we *do* have a day, the result is
    # broken, so send back the undefs.
    return (undef,undef,undef) if($day);
    return ($year,undef,undef);
}


########## END CODE ##########

=head1 BUGS AND LIMITATIONS

=over

=item * fix_links() could be improved to download remote URIs instead
of ignoring them.

=item * fix_links() needs to check the <reference> links under <guide>

=item * fix_links() needs to be redone with HTML::TreeBuilder or
Mojo::DOM to avoid the weakness with newlines between attribute names
and values

=item * Need to implement fix_tours() that should collect the related
elements and delete the parent if none are found.  Empty <tours>
elements aren't allowed.

=item * fix_languages() needs to convert language names into IANA
language codes.

=item * set_language() should add a warning if the text isn't a valid
IANA language code.

=item * NCX generation only generates from the spine.  It should be
possible to use a TOC html file for generation instead.  In the long
term, it should be possible to generate one from the headers and
anchors in arbitrary HTML files.

=item * It might be better to use sysread / index / substr / syswrite in
&split_metadata to handle the split in 10k chunks, to avoid massive
memory usage on large files.

This may not be worth the effort, since the average size for most
books is less than 500k, and the largest books are rarely over 10M.

=item * The only generator is currently for .epub books.  PDF,
PalmDoc, Mobipocket, Plucker, and iSiloX are eventually planned.

=item * Although I like keeping warnings associated with the ebook
object, it may be better to throw exceptions on errors and catch them
later.  This probably won't be implemented until it bites someone who
complains, though.

=item * Unit tests are incomplete

=back

=head1 AUTHOR

Zed Pobre <zed@debian.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2013 Zed Pobre

Licensed to the public under the terms of the GNU GPL, version 2

=cut

1;
