package Mason::Tidy::t::Basic;
BEGIN {
  $Mason::Tidy::t::Basic::VERSION = '2.57';
}
use Mason::Tidy;
use Test::Class::Most parent => 'Test::Class';

sub tidy {
    my %params  = @_;
    my $source  = $params{source} or die "source required";
    my $expect  = $params{expect} || $source;
    my $options = { mason_version => 2, %{ $params{options} || {} } };
    my $desc    = $params{desc};
    if ( !defined($desc) ) {
        my ($caller) = ( ( caller(1) )[3] =~ /([^:]+$)/ );
        ( my $source_flat = $source ) =~ s/\n/\\n/g;
        $desc = "$caller: $source_flat";
    }

    $source =~ s/\\n/\n/g;
    if ( defined($expect) ) {
        $expect =~ s/\\n/\n/g;
    }

    my $mt = Mason::Tidy->new( %$options, perltidy_argv => '--noprofile' );
    my $dest = eval { $mt->tidy($source) };
    my $err = $@;
    if ( my $expect_error = $params{expect_error} ) {
        like( $err, $expect_error, "got error - $desc" );
        is( $dest, undef, "no dest returned - $desc" );
    }
    else {
        is( $err,  '',      "no error - $desc" );
        is( $dest, $expect, "expected content - $desc" );
    }
}

sub trim {
    my $str = $_[0];
    return undef if !defined($str);
    for ($str) { s/^\s+//; s/\s+$// }
    return $str;
}

sub test_perl_sections : Tests {
    tidy(
        desc   => 'init section',
        source => '
<%init>
if($foo  )   {  
my @ids = (1,2);
    }  
</%init>
',
        expect => '
<%init>
if ($foo) {
    my @ids = ( 1, 2 );
}
</%init>
'
    );

    # This isn't ideal - would prefer it compressed to a single newline - but
    # both the <%init> and </%init> grab onto one of the newlines
    #
    tidy(
        desc   => 'empty init section',
        source => "<%init>\n\n\n\n</%init>",
        expect => "<%init>\n\n</%init>",
    );
}

sub test_mixed_sections : Tests {
    tidy(
        desc   => 'method',
        source => '<%method foo>\n%if (  $foo) {\ncontent\n%}\n</%method>\n',
        expect => '<%method foo>\n% if ($foo) {\ncontent\n% }\n</%method>\n'
    );
}

sub test_empty_method : Tests {
    tidy( source => 'foo\nbar\n' );
    tidy( source => '<%method foo>\n</%method>\n' );
    tidy( source => '<%method foo>\n%\n</%method>\n' );
    tidy( source => '<%method foo>\n\n</%method>' );
    tidy( source => '\n<%method foo>\n%\n%\n</%method>\n' );
}

sub test_text_section : Tests {
    tidy( source => '<%text>\n% my $foo=5\n<%3+5%>\n</%text>\n' );
}

sub test_backslashes : Tests {
    tidy( source => 'Blah\\\n\n<%method foo>\\\nFoo\\\n% my $d = 5;\n</%method>\\\nBlurg\\\n' );
}

sub test_multiple_methods : Tests {
    tidy(
        desc   => 'multiple method',
        source => '
<%method foo>
%foo();
</%method>

<%method bar>
<%perl>
bar();
</%perl>
</%method>

<%method .baz>
%if (1) {
<%blargh%>
%}
</%method>
',
        expect => '
<%method foo>
% foo();
</%method>

<%method bar>
<%perl>
  bar();
</%perl>
</%method>

<%method .baz>
% if (1) {
<% blargh %>
% }
</%method>
'
    );
}

sub test_args : Tests {
    tidy(
        desc   => 'perl lines',
        source => '
<%args>
$a
@b
%c
$d => "foo"
@e => (1,2,3)
%f => (a=>5, b=>6)
</%args>
',
        expect => '
<%args>
$a
@b
%c
$d => "foo"
@e => (1,2,3)
%f => (a=>5, b=>6)
</%args>
'
    );
}

sub test_perl_lines_and_perl_blocks : Tests {
    tidy(
        desc   => 'perl lines with commented out tags',
        source => '% # <%init>\n% # <% $foo %>\n% # <& "foo" &>\n'
    );
    tidy(
        desc   => 'perl lines',
        source => '
%my $d = 3;
<%perl>
if($foo  )   {
</%perl>
<% blargh() %>
%my @ids = (1,2);
<%perl>
my $foo = 3;
if($bar) {
my $s = 9;
</%perl>
% my $baz = 4;
%}
%    }  
',
        expect => '
% my $d = 3;
<%perl>
  if ($foo) {
</%perl>
<% blargh() %>
%     my @ids = ( 1, 2 );
<%perl>
      my $foo = 3;
      if ($bar) {
          my $s = 9;
</%perl>
%         my $baz = 4;
%     }
% }
'
    );
}

sub test_blocks_and_newlines : Tests {
    tidy( source => "<%perl>my \$foo=5;</%perl>" );
    tidy( source => "<%perl>my \$foo=5;\n  </%perl>" );
    tidy( source => "<%perl>\nmy \$foo=5;</%perl>" );
    tidy(
        source => "<%perl>\nmy \$foo=5;\n</%perl>",
        expect => "<%perl>\n  my \$foo = 5;\n</%perl>"
    );
    tidy(
        source => '<%perl>\n\nmy $foo = 3;\n\nmy $bar = 4;\n\n</%perl>',
        expect => '<%perl>\n\n  my $foo = 3;\n\n  my $bar = 4;\n\n</%perl>',
    );
    tidy(
        source => '<%perl>\n\n\nmy $foo = 3;\n\n\nmy $bar = 4;\n\n\n</%perl>',
        expect => '<%perl>\n\n\n  my $foo = 3;\n\n\n  my $bar = 4;\n\n\n</%perl>',
    );
    tidy(
        source => "<%init>my \$foo=5;</%init>",
        expect => "<%init>my \$foo = 5;</%init>"
    );
    tidy(
        source => "<%init>my \$foo=5;\n  </%init>",
        expect => "<%init>my \$foo = 5;\n  </%init>"
    );
    tidy(
        source => "<%init>\nmy \$foo=5;</%init>",
        expect => "<%init>\nmy \$foo = 5;</%init>"
    );
    tidy(
        source => "<%init>\nmy \$foo=5;\n</%init>",
        expect => "<%init>\nmy \$foo = 5;\n</%init>"
    );
    tidy(
        source => '<%init>\n\nmy $foo = 3;\n\nmy $bar = 4;\n\n</%init>',
        expect => '<%init>\nmy $foo = 3;\nmy $bar = 4;\n</%init>',
    );
}

sub test_tags : Tests {
    tidy(
        desc   => 'subst tag',
        source => '<%$x%> text <%foo(5,6)%>',
        expect => '<% $x %> text <% foo( 5, 6 ) %>',
    );
    tidy(
        desc   => 'comp call tag',
        source => '<&/foo/bar,a=>5,b=>6&> text <&  $comp_path, str=>"foo"&>',
        expect => '<& /foo/bar, a => 5, b => 6 &> text <& $comp_path, str => "foo" &>',
    );
    tidy(
        desc   => 'comp call w/content tag',
        source => '<&|/foo/bar,a=>5,b=>6&> text <&  $comp_path, str=>"foo"&>',
        expect => '<&| /foo/bar, a => 5, b => 6 &> text <& $comp_path, str => "foo" &>',
    );
}

sub test_filter_invoke : Tests {
    tidy(
        desc   => 'filter invoke',
        source => '
%$.Trim(3,17) {{
%sub {uc($_[0]  )} {{
%$.Fobernate() {{
   This string will be trimmed, uppercased
   and fobernated
% }}
%}}
%   }}
',
        expect => '
% $.Trim( 3, 17 ) {{
%     sub { uc( $_[0] ) } {{
%         $.Fobernate() {{
   This string will be trimmed, uppercased
   and fobernated
%         }}
%     }}
% }}
'
    );
}

sub test_filter_decl : Tests {
    tidy(
        desc   => 'Mason 1 filter declaration (no arg)',
        source => '
Hi

<%filter>
if (/abc/) {
s/abc/def/;
}
</%filter>
',
        expect => '
Hi

<%filter>
if (/abc/) {
    s/abc/def/;
}
</%filter>
'
    );

    tidy(
        desc   => 'Mason 2 filter declaration (w/ arg)',
        source => '
<%filter Item ($class)>
<li class="<%$class%>">
%if (my $x = $yield->()) {
<% $x %>
%}
</li>
</%filter>
',
        expect => '
<%filter Item ($class)>
<li class="<% $class %>">
% if ( my $x = $yield->() ) {
<% $x %>
% }
</li>
</%filter>
'
    );
}

sub test_perltidy_argv : Tests {
    tidy(
        desc   => 'default indent 2',
        source => '
% if ($foo) {
% if ($bar) {
% baz();
% }
% }
',
        expect => '
% if ($foo) {
%     if ($bar) {
%         baz();
%     }
% }
'
    );
    tidy(
        desc    => 'perltidy_line_argv = -i=2',
        options => { perltidy_line_argv => '-i=2' },
        source  => '
% if ($foo) {
% if ($bar) {
% baz();
% }
% }
',
        expect => '
% if ($foo) {
%   if ($bar) {
%     baz();
%   }
% }
'
    );
}

sub test_blank_lines : Tests {
    tidy( source => '\n%\n' );
    tidy( source => '%' );
    tidy( source => '\n' );
    tidy( source => '\n\n' );
    tidy( source => '% foo();' );
    tidy( source => '\n% foo();\n' );
    tidy( source => '% foo()\n%' );
    tidy( source => '\n% foo()\n%\n' );
    tidy( source => '  Hello\n\n\n  Goodbye\n' );
    tidy(
        source => '<%perl>\nmy $foo = 5;\n\nmy $bar = 6;\n\n</%perl>',
        expect => '<%perl>\n  my $foo = 5;\n\n  my $bar = 6;\n\n</%perl>'
    );
    tidy( source => '\n%\n%\n% my $foo = 5;\n%\n% my $bar = 6;\n%\n%\n' );
    tidy( source => '<%init>\nmy $foo = 5;\n</%init>\n\n' );
    tidy( source => '% my $foo = 5;\n' );
    tidy( source => '% my $foo = 5;' );
    tidy( source => '% my $foo = 5;\n% my $bar = 6;\n' );
    tidy( source => '% my $foo = 5;\n% my $bar = 6;' );
    tidy( source => '% my $foo = 5;\n% my $bar = 6;\n\n' );
}

sub test_single_line_block : Tests {
    tidy(
        source => '<%perl>my $foo = 5;</%perl>',
        expect => '<%perl>my $foo = 5;</%perl>'
    );
}

sub test_indent_perl_block : Tests {
    my $source = '
<%perl>
    if ($foo) {
$bar = 6;
  }
</%perl>
';
    tidy(
        desc    => 'indent_perl_block 0',
        options => { indent_perl_block => 0 },
        source  => $source,
        expect  => '
<%perl>
if ($foo) {
    $bar = 6;
}
</%perl>
'
    );
    tidy(
        desc   => 'indent_perl_block 2 (default)',
        source => $source,
        expect => '
<%perl>
  if ($foo) {
      $bar = 6;
  }
</%perl>
'
    );

    tidy(
        desc    => 'indent_perl_block 4',
        options => { indent_perl_block => 4 },
        source  => $source,
        expect  => '
<%perl>
    if ($foo) {
        $bar = 6;
    }
</%perl>
'
    );
}

sub test_indent_block : Tests {
    my $source = '
<%init>

    if ($foo) {
$bar = 6;
  }

</%init>
';
    tidy(
        desc   => 'indent_block 0 (default)',
        source => $source,
        expect => '
<%init>
if ($foo) {
    $bar = 6;
}
</%init>
'
    );
    tidy(
        desc    => 'indent_block 2',
        options => { indent_block => 2 },
        source  => $source,
        expect  => '
<%init>
  if ($foo) {
      $bar = 6;
  }
</%init>
'
    );
}

sub test_errors : Tests {
    tidy(
        desc         => 'syntax error',
        source       => '% if ($foo) {',
        expect_error => qr/final indentation level/,
    );
    tidy(
        desc         => 'no matching close block',
        source       => "<%init>\nmy \$foo = bar;</%ini>",
        expect_error => qr/no matching end tag/,
    );
}

sub test_here_docs : Tests {
    tidy(
        source => '<%perl>\nmy $text = <<"END";\nblah\nblah2\nEND\nprint $text;\n</%perl>',
        expect => '<%perl>\n  my $text = <<"END";\nblah\nblah2\nEND\n  print $text;\n</%perl>'
    );
}

sub test_random_bugs : Tests {
    tidy(
        desc    => 'final double brace (mason 1)',
        options => { mason_version => 1 },
        source  => '
% if ($foo) {
% if ($bar) {
% }}
',
        expect => '
% if ($foo) {
%     if ($bar) {
% }}
'
    );
    tidy(
        desc => 'long comp call tag',
        source =>
          '% # <& searchFormShared, report_title => $report_title, ask_site => 1, ask_date => 1, ask_search_terms => 1, ask_result_limit => 1 &>'
    );
    tidy(
        desc   => '% at beginning of line inside multi-line <% %> or <& &>',
        source => '<& /layouts/master.mc,\n%ARGS\n&>\n<%\n%ARGS\n%>'
    );

}

sub test_comprehensive : Tests {
    tidy(
        desc   => 'comprehensive',
        source => '
some text

% if ( $contents || $allow_empty ) {
  <ul>
% foreach my $line (@lines) {
<%perl>
dothis();
andthat();
</%perl>
  <li>
      <%2+(3-4)*6%>
  </li>
  <li><%  foo($.bar,$.baz,  $.bleah)   %></li>
% }
  </ul>
% }

%  $.Filter(3,2) {{  
some filtered text
%}}

<&footer,color=>"blue",height  =>  3&>

<%method foo>
%if(defined($bar)) {
% if  ( $write_list) {
even more text
%}
% }
</%method>
',
        expect => '
some text

% if ( $contents || $allow_empty ) {
  <ul>
%     foreach my $line (@lines) {
<%perl>
          dothis();
          andthat();
</%perl>
  <li>
      <% 2 + ( 3 - 4 ) * 6 %>
  </li>
  <li><% foo( $.bar, $.baz, $.bleah ) %></li>
%     }
  </ul>
% }

% $.Filter( 3, 2 ) {{
some filtered text
% }}

<& footer, color => "blue", height => 3 &>

<%method foo>
% if ( defined($bar) ) {
%     if ($write_list) {
even more text
%     }
% }
</%method>
'
    );
}

1;
