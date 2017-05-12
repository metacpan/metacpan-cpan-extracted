=head1 NAME

ftw_new_app - create a new File::Tabular::Web application

=head1 SYNOPSIS

  cp some/data.txt /path/to/http/htdocs/some/data.txt
  perl ftw_new_app.pl -m field1 -m field2 -e \
                      -f "|" /path/to/http/htdocs/some/data.txt

=head1 DESCRIPTION

This script creates a skeleton for a Web application around
a tabular datafile. The concepts and basic setup instructions
are described in L<File::Tabular::Web>. After having created
the skeleton, you can navigate to URL C<http://myServer/some/data.ftw>.


=head1 CREATED FILES

The script will create the following files, in the same directory
as the data file :

=over

=item data.ftw

The application configuration file (also used as URL).

=item data_wrapper.tt

General wrapper template for the application, including the search form.

=item data_home.tt

Home page.

=item data_short.tt

Template for displaying result sets (short display of each record).

=item data_long.tt

Template for displaying detailed view of a single record.

=item data_modif.tt

HTML form for modifying a record.

=item data_msg.tt

Template for displaying a message (for example confirmation
of an update operation).

=back

All templates may be later be moved out of the C<htdocs> tree,
to a more appropriate location : you just have to specify the
new location in the configuration file (C<dir> variable in the C<[template]>
section).


=head1 OPTIONS

Options may be abbreviated to the first letter, i.e. 

  -m field1 -f "|"

instead of 

  -menu field1 -fieldSep "|"


=head2 -help

Help to using this script.

=head2 -menu field1 -menu field2 ...

For each specified field, will inspect all values currently in the 
data file, and creates an simple menu, like a spreadsheet
"automatic filter". However, this is currently merely static, so
if the data changes, menus will not be updated accordingly ---
it will improve in a future release.

=head2 -fieldSep

Specifies which character is the field separator in the data file.
Default is C<|>.

=head2 -override

Forces creation of the files, overriding previous files of 
the same names.

=head2 -editor username1 -editor username2

Writes into the configuration file that the data is
editable by the specified usernames. Usernames must
correspond to names returned by your Apache
authentication layer. If no username is given,
the default value is C<*>, which means "editable by all".

=cut



use strict;
use warnings;
no warnings 'uninitialized';
use File::Basename;
use File::Tabular;
use Getopt::Long;
use Template;
use List::MoreUtils qw/uniq any all/;
use Pod::Usage;

my %vars = ();

my $field_sep;
my @menus;
my $override;
my $help;
my @editor;

GetOptions("menu=s"     => \@menus,
           "fieldSep=s" => \$field_sep,
           "override!"  => \$override,
           "help"       => \$help,
           "editor:s"   => \@editor,
          )
  or pod2usage(-verbose => 0);

pod2usage(-verbose => 1) if $help;


# open data file
my $file_name = $ARGV[0] 
  or pod2usage(-message => "$0 : NO DATA FILE");
@vars{qw/base dir suffix/} = fileparse($file_name, qr/\.[^.]*$/);
chdir $vars{dir} or die $!;
my $tab_file = File::Tabular->new("$vars{base}$vars{suffix}", 
                                  {fieldSep => $field_sep});
my @headers = $tab_file->headers;


# build menus
if (@menus) {
  my %menu_values;

  # check that menus correspond to headers in datafile
  foreach my $menu (@menus) {
    any {$_ eq $menu } @headers or die "unknown menu field : $menu";
  }

  while (my $row = $tab_file->fetchrow) {
    foreach my $menu (@menus) {
      my $val = $row->{$menu};
      $menu_values{$menu}{$val} = 1;
    }
  }

  foreach my $menu (@menus) {
    $vars{menus}{$menu} = [sort keys %{$menu_values{$menu}}];
  }
}


# some data for templates
$vars{headers}    = \@headers;
$vars{key_header} = $headers[0];
$vars{fieldSep}   = $field_sep;
if (@editor) {
  $editor[0]   ||= "*"; # default
  $vars{editor}  = join ",", @editor;
}


# split DATA into template files (keys are filenames, values are tmpl contents)
local $/ = undef;
my (undef, %templates) = split /^__(.+?)__+\r?\n/m, <DATA>;



# create files from templates

# We will generate templates from templates, so there must be directives
# for first pass (template generation) and for second pass (runtime
# page generation). We use "{% .. %}" for first pass and default
# "[% .. %]" for second pass.
my %tmpl_config = (START_TAG => '{%', 
                   END_TAG   => '%}',
                  );

my $tmpl = Template->new(\%tmpl_config);
while (my ($name, $content) = each %templates) {
  my $output = sprintf $name, $vars{base};
  $override or not -e $output or die "$output exists, will not clobber";
  $tmpl->process(\$content, \%vars, $output) or die $tmpl->error();
}


#----------------------------------------------------------------------
# END OF MAIN PROGRAM. DATA SECTION BELOW CONTAINS THE TEMPLATES
#----------------------------------------------------------------------


__DATA__

__%s.ftw___________________________________________________________________
# GLOBAL SECTION
{%- IF fieldSep %}
fieldSep = {% fieldSep %}
{% END # IF fieldSep -%}

avoidMatchKey true         # searches will not match on first field (key)
preMatch {[                # string to insert for highlight
postMatch ]}               # end string to insert for highlight

[application]
mtime = %d.%m.%Y %H:%M:%S


[fixed]  # parameters in this section cannot be overridden by CGI parameters

max = 99999                # max records retrieved

[default] # parameters in this section can be overridden by CGI parameters

count = 50                 # how many records in a result slice

[fields]

autoNum {% key_header %}   # automatic numbering for new records

{% IF editor %}
[permissions]
add    = {% editor %}
delete = {% editor %}
modif  = {% editor %}
{% END # IF editor %}


__%s_wrapper.tt____________________________________________________________
<html>
<head>
  <title>{% base | html %} -- File::Tabular::Web application</title>
  <style>
    .HL {background: lightblue} /* highlighting search results */
  </style>
</head>
<body>
<span style="float:right;font-size:smaller">
  A <a href="http://search.cpan.org/dist/File-Tabular-Web">
     File::Tabular::Web
    </a> application
</span>
<h1>{% base | html %}</h1>

<form method="POST">
<fieldset>
  <span style="float:right">
  <a href="?H">Home</a> <br>
  <a href="?S=*">All</a>
  </span>

  {% FOREACH menu IN menus %}
    <select name="S">
      <option value="">--{% menu.key | html %}--</option>
     {% FOREACH val IN menu.value -%}
       <option value="+{% menu.key | html %}={% val | html %}">
          {%- val | html -%}
       </option>
     {% END # FOREACH val IN menu.value %}
    </select>
  {% END # FOREACH menu IN menus -%}
  <input name="S" size="30">
  <input type="submit" value="Search">
</fieldset>
</form>

<div style="font-size:70%;width:100%;text-align:right">
Last modified: [% self.mtime %]
</div>

[% content %]
</body>
</html>
__%s_home.tt_______________________________________________________________
[% WRAPPER {% base %}_wrapper.tt %]
<h2>Welcome</h2>

This is a web application around a single tabular file.
Type any words in the search box above. You may use boolean
combinations, parentheses, '+' or '-' prefixes, sequences of 
words within double quotes. You may also restrict a search word 
to a given data field, using a ":" prefix ; available fields are :
 <blockquote>
  {%- FOREACH header IN headers -%}
    {%- header | html -%}
    {%- " | " UNLESS loop.last -%}
  {%- END # FOREACH -%}
 </blockquote>
[% END # WRAPPER -%]

__%s_short.tt______________________________________________________________
[% WRAPPER {% base %}_wrapper.tt %]

[%- BLOCK links_prev_next -%]
  [% IF found.prev_link %]
    <a href="[% found.prev_link %]">[Previous &lt;&lt;]</a>
  [% END; # IF %]
  Displayed : <b>[% found.start %]</b> to <b>[% found.end %]</b> 
                                       from <b>[% found.count %]</b>
  [% IF found.next_link %]
    &nbsp;<a href="[% found.next_link %]">[&gt;&gt; Next]</a>
  [% END; # IF %]
[%- END # BLOCK -%]

<b>Your request </b> : [ [%- self.search_string | html -%] ] <br>
<b>[% found.count %]</b> records found              <br>

[% PROCESS links_prev_next %]

<table border>
[% FOREACH r IN found.records; %]
  <tr>
    <td>
    [%# dummy display; modify to choose whatever to display here %]
    {% FOREACH header IN headers; %}
      {%- IF loop.first -%}
       <a href="?L=[% r.{% header %} | unhighlight | uri %]">
         [%- r.{% header %} | html | highlight -%]
       </a>
      {%- ELSE  -%}
       [%- r.{% header %} | html | highlight -%] 
      {%- END # IF  -%}
      {%- " | " UNLESS loop.last; -%}
    {% END # FOREACH header %}
    </td>
  </tr>
[% END # FOREACH r IN found.records; %]
</table>

[% PROCESS links_prev_next %]

[% END # WRAPPER -%]

__%s_long.tt_______________________________________________________________
[% WRAPPER {% base %}_wrapper.tt %]
[% r = found.records.0; %]

[% IF self.can_do("modif", r); %]
  <a href="?M=[% r.{% key_header %} | unhighlight | uri %]" 
     style="float:right">Modify</a>
[% END # IF; -%]

<h2>Long display of record [% r.{% key_header %} | html | highlight %]</h2>

<table border>
{% FOREACH header IN headers; %}
<tr>
  <td align="right">{% header %}</td>
  <td>[% r.{% header %} | html | highlight %]</td>
</tr>
{% END # FOREACH header %}
</table>


[% END # WRAPPER -%]

__%s_modif.tt______________________________________________________________
[%- WRAPPER {% base %}_wrapper.tt -%]
[% r = found.records.0;
   key = r.{% key_header %} %]

<form method="POST">

<h2>Modify record [% key | html | highlight %]</h2>

<table border>
{% FOREACH header IN headers; 
   NEXT IF header==key_header; # skip (not allowed to edit key) 
%}
<tr>
  <td align="right">{% header | html %}</td>
  <td><input name="{% header | html %}" 
             value="[% r.{% header %} | unhighlight | html %]" size="40"></td>
</tr>
{% END # FOREACH header %}
</table>
<input type="submit">
<input type="reset">
[% IF self.can_do("delete", r); %]
<input type=button value="Destroy" 
       onclick="if (confirm('Really?')) {location.href='?D=[% key | uri %]';}">
[% END # IF %]

</form>

[% END # WRAPPER -%]

__%s_msg.tt________________________________________________________________
[% WRAPPER {% base %}_wrapper.tt %]

<h2>Message</h2>

<EM>[% self.msg %]</EM>

[% END # WRAPPER -%]

