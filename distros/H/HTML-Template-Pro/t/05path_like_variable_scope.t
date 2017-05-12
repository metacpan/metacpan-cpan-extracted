use strict;
use warnings;
use Test::More qw(no_plan);
use lib qw(../blib);
use HTML::Template::Pro;

my $template_text=<<'END;';
<TMPL_LOOP NAME=class>
  <TMPL_LOOP NAME=person>
    <TMPL_VAR NAME="../teacher_name">  <!-- access to class.teacher_name -->
    <TMPL_VAR NAME="name">
    <TMPL_VAR NAME="age">
    <TMPL_VAR NAME="/top_level_value"> <!-- access to top level value -->
    <TMPL_VAR EXPR="${/top_level_value} * 5"> <!-- need ${} to use path_like_variable in EXPR -->
  </TMPL_LOOP>
</TMPL_LOOP>
END;

my $template = HTML::Template->new(
    path_like_variable_scope => 1,
    scalarref => \$template_text,
);
$template->param(top_level_value => "3",
                 class => [
                     {
                         teacher_name => "Adam",
                         person => [
                             {
                                 name => "Jon",
                                 age  => "20",
                             },
                             {
                                 name => "Bob",
                                 age  => "21",
                             },
                         ],
                     },
    {
    }
]);
is($template->output, <<'END;');

  
    Adam  <!-- access to class.teacher_name -->
    Jon
    20
    3 <!-- access to top level value -->
    15 <!-- need ${} to use path_like_variable in EXPR -->
  
    Adam  <!-- access to class.teacher_name -->
    Bob
    21
    3 <!-- access to top level value -->
    15 <!-- need ${} to use path_like_variable in EXPR -->
  

  

END;
