About the Family Tree Generator, v2.3.*


PACKAGE CONTENTS:

readme.txt                     This file
config/PerlSettingsImporter.pm Settings file
cgi/ftree.cgi                  The main perl script
cgi/*.pm                       Other perl modules
tree.txt, tree.xls, royal.ged  Example family tree data files
license.txt                    The GNU GPL license details
changes.txt					   Change history
pictures/*.[gif,png,jpg,tif]   The pictures of the relatives
graphics/*.gif                 The system graphic files 

OVERVIEW:
 
When I designed the Family Tree Generator, I wanted more than just an online version of a traditional tree. With this software it is possible to draw a tree of ancestors and descendants for any person, showing any number of generations (where the information exists).
Most other web-based "trees" are little more than text listings of people. 

A simple datafile contains details of people and their relationships. All the HTML pages are generated on the fly. This means that the tree is easy to maintain.

Note that the tree shows the "genetic" family tree. It contains no information about marriages and adaptation.

For a demonstration of this software, visit http://www.ilab.sztaki.hu/~bodon/Simpsons/cgi/ftree.cgi or http://www.ilab.sztaki.hu/~bodon/ftree2/cgi/ftree.cgi. 

The program is written in Perl.
It runs as a CGI program - its output is the HTML of the page that you see.
The program reads in the data file, and analyzes the relationships to determine the ancestors, siblings and descendants of the person selected. 
HTML tables are generated to display these trees, linking in the portrait images where they exist.

INSTALLATION INSTRUCTIONS:

1. Set up your web server (apache or IIS) so that it can run Perl scripts (e.g. mod-perl).

2. Uncompress and copy the demo package (make sure that you reserve the rights, i.e. files with extension pm, gif, jpg, png, tif, csv, txt, xls must be readable, files with extension cgi and pl must be executable).

3. Modify tree.xls so that it contains the details of your family. Tip: Select the second row, click on menu Window and select Freeze Panels. This will freeze the first row and you can see the title of columns.
   See format description below.

4. Update the config/PerlSettingsImporter.pm file (you can specify the administrator's email, homepage, default language etc.).

5. Copy the pictures of your family members to the pictures directory.

6. That's it.
   Call the ftree.cgi script with no parameters to get your index page.

7. If you are unhappy with the style and colors of the output then point the css_filename entry in PerlSettingsImporter.pm into your stly sheet.

DATAFILE FORMAT:

The program can handle excel, csv (txt), gedcom, serialized files and can get data from database. Follow these rules to decide which one to use:
1, Use gedcom if you already have your family tree data in a gedcom file and the fields that the program is able to import is sufficient.
2, Use the excel format if you just started to build your family tree data.
3, Convert your data file into serialized format if the data file contains many people (like some thousand) and you would like to reduce response time and memory need.

Data format history:
Originally the input file was a csv flat file with semicolon as the separator. It could store 6 fields for each person (name, father name, mother name, email, webpage, date of birth/death). As new fields were required (like gender, place of birth, cemetery, etc.) and the number of optional fields increased from 5 to 22, the csv format turned out to be hard to maintain. Although it is possible to be imported/exported into excel, it would be better to use excel spreadsheets directly. From version 2.2 this is possible. For backward compatibility it is still possible to use csv files. The new fields can be used in csv fields as well. From version 2.3 gedcom files can also be used.

We encourage everybody to use the excel format. To convert from the csv format to the excel format, use script script/convertFormat.pl

TIP 1.: Maintain your family tree data in excel using the Form option. Select all the columns, then press DATA->Form. It is convenient to add new people or to modify information of existing persons.
TIP 2.: Freeze the first line so that header does not disappear when scrolling down. 

The excel format:

The excel format is quite straightforward based on the example file. Each row (except the header) represents a person. The fields are:
 * ID: the ID of the person. It can be anything (like 123 or Bart_Simpson), but it should only contain alphanumeric characters and underscore (no whitespace is allowed).
 * title: like: Dr., Prof.
 * prefix: like: sir
 * first name
 * middle name 
 * last Name
 * suffix: like: VIII
 * nickname
 * father's ID
 * mother's ID
 * email
 * webpage
 * date of birth: the format is day/month/year, like: 24/3/1977
 * date of death: the format is day/month/year, like: 24/3/1977
 * gender: 0 for male, 1 female
 * is living?: 0 for live 1 for dead
 * place of birth: the format is: "country" "city". The city part may be omitted. Quotation marks are mandatory.
 * place of death: the format is: "country" "city". The city part may be omitted. Quotation marks are mandatory.
 * cemetery: the format is: "country" "city" "cemetery", like: "USA" "Washington D.C." "Arlington National Cemetery"
 * schools: use comma as separator, like: Harward, MIT
 * jobs: use comma as separator
 * work places: use comma as separator
 * places of living: places separated by comma, like: "USA" "Springfield", "USA" "Connecticut"
 * general: you would typically write something general about the person.
Note, that the extension of an excel data file must be xls.

Tip: Select the second row, click on menu Window and select Freeze Panels.
This will freeze the first row and you can see the title of columns.

The csv format:
Semicolon is the separator. The fields are:

1. Full name.
   Middle names can be included in this field.
   If more than one person share the same name, a number can be appended (not shown in the displayed output). For example, "Bart Simpson2". 
2. Father (optional - leave blank if not known). No middle names. 
3. Mother (optional) 
4. email address (optional) 
5. web page (optional) 
6. Dates, birth-death (both optional).
   Examples: "17/10/49-24/11/83", "10/69-"
   Note that the year of birth is not displayed for people who are still alive. 
7. Gender (0 for male, 1 for female)
8. title: like: Dr., Prof.
9. prefix: like: sir
10. suffix: like: VIII
11. is living?: 0 for live 1 for dead
12. place of birth: the format is: "country" "city". The city part may be omitted. Quotation marks are mandatory.
13. place of death: the format is: "country" "city". The city part may be omitted. Quotation marks are mandatory.
14. cemetery: the format is: "country" "city" "cemetery", like: "USA" "Washington D.C." "Arlington National Cemetery"
15. schools: use comma as separator, like: Harward,MIT
16. jobs: use comma as separator
17. work places: use comma as separator
18. places of living: places separated by comma, like: "USA" "Springfield", "USA" "Connecticut"
19. general: you would typically write something general about the person.
Note, that the extension of a csv data file must be either csv or txt. To define the encoding of the file use option encoding in the config file.

Convert from csv (txt) format to excel format:
To switch from comma separated value file to excel spreadsheet, do the following:
cd ftree2
perl ./scripts/convertFormat.pl ./tree.txt ./tree.xls
This will generate (overwrite) a tree.xls file. 

The GEDCOM format:
GEDCOM, an acronym for GEnealogical Data COMmunication, is a specification for exchanging genealogical data between different genealogy software. GEDCOM was developed by The Church of Jesus Christ of Latter-day Saints as an aid in their extensive genealogical research. A GEDCOM file is plain text (an obscure text encoding named ANSEL, though often in ASCII in the United States) containing genealogical information about individuals, and data linking these records together. Most genealogy software supports importing from and/or exporting to GEDCOM format.

Beside the father, mother relationships, the program handles the following information of a person:
1, gender
2, date of birth
3, date of death
4, place of birth (only city and country are extracted)
5, place of death (only city and country are extracted)
6, cemetery (only cemetery, city and country are extracted)
7, email address
8, homepage

It is possible to switch from GEDCOM to excel (or serialized) format. Use the scripts/convertFormat.pl script. For example
cd ftree2
perl ./scripts/convertFormat.pl ./tree.ged ./tree.xls

The ser format:
The drawback of excel, csv and GEDCOM format is that it has to be parsed and processed every time the program runs. It is possible to speed-up the program (and hence reduce response time) and reduce memory usage if you use the serialized format. The serialized format cannot be edited directly. Basically you maintain your family tree data in excel (or in csv or GEDCOM) then create a serialized file using scripts/convertFormat.pl program. If the name of the family tree data is ftree.xls then, the following commands will generate the serialized file:

cd ftree2
perl ./scripts/convertFormat.pl ./tree.xls ./tree.ser

Don't forget to set the data_source to "../tree.ser" in the PerlSettingsImporter.pm file.

Note, that the extension of a serialized data file must be ser. Also keep in mind that different versions of perl may produce incompatible serialized versions. It is advised to run the convertFormat.pl script on the same mashine where the webserver runs.

NAME OF THE PICTURE:

One picture may belong to each person. The name of the picture file reflects the person it belongs to. The picture file is obtained from the lowercased full name by substituting spaces with underscores and adding the file extension to it. From example from "Ferenc Bodon3" we get "ferenc_bodon3.jpg".

PERFORMANCE ISSUES:
This sofware was not designed so that it can handle very large family trees. It can easily cope with few thousands of members, but latency (time till page is generated) grows as the size of the family tree increases.
The main bottleneck of performance is that (1.) mod_perl is not used, therefore perl interpreter is starts for every request (2.) family tree is not cached but data file is parsed and tree is built-up for every request (using serialized format helps a little).
Since the purpose of this software is to provide a free and simple tool for those who would like to maintain their family tree themself, performance is not the primary concern.

SECURITY ISSUES:
The protection provided by password request (set in config file) is quite primitive, i.e. it is easy to break it.
Ther are historical reasons for being available. We suggest to use server side protection like .htaccess files in case of apache web servers. 

ACKNOWLEDGEMENT:
I am in debt to the translators:
Csaba Kiss (French)
Gergely Kovacs (German),
Przemek Świderski (Polish),
Rober Miles (Italian),
Lajos Malozsák (Romanian),
Vladimir Kangin (Russian)

I also would like to thank the feedback/help of (in no particular order) Alex Roitman, Anthony Fletcher, 
Richard Bos, Sylvia McKenzie and Sean Symes.


Dr. Ferenc Bodon and Simon Ward
http://www.cs.bme.hu/~bodon/en/index.html
http://simonward.com
