package Devel::Trace::Subs::HTML;
use 5.008;
use strict;
use warnings;

use Data::Dumper;
use Exporter;
use HTML::Template;

our $VERSION = '0.24';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(html);

my (@stack_tpl, @flow_tpl, @all_tpl);

sub html {

    my %p = @_;

    my $file = $p{file};
    my $want = $p{want};
    my $data = $p{data};

    if ($want && $want eq 'stack') {

        my $template = HTML::Template->new(arrayref => \@stack_tpl);

        $template->param(STACK => $data);

        if ($file) {
            open my $wfh, '>', $file
                or die "Can't open the output file, $file: $!";

            print $wfh $template->output;
            close $wfh or die $!;
        }
        else {
            print $template->output;
        }
    }
    elsif ($want && $want eq 'flow') {

        my $template = HTML::Template->new(arrayref => \@flow_tpl);

        $template->param(FLOW => $data);

        if ($file) {
            open my $wfh, '>', $file
                or die "Can't open the output file, $file: $!";

            print $wfh $template->output;
            close $wfh or die $!;
        }
        else {
            print $template->output;
        }
    }
    else {
        my $template = HTML::Template->new(arrayref => \@all_tpl);

        $template->param(
            FLOW => $data->{flow},
            STACK => $data->{stack},
        );
         if ($file) {
            open my $wfh, '>', $file
                or die "Can't open the output file, $file: $!";

            print $wfh $template->output;
            close $wfh or die $!;
        }
        else {
            print $template->output;
        }
    }
}

BEGIN {

@stack_tpl = <<EOF;
<html>
<head>
 <title>Devel::Trace::Subs</title>
</head>

<body>

<br><br>

<h3>Stack trace:</h3>

<table id=error border=0 cellspacing=0>
<TMPL_LOOP NAME=STACK>
        <tr><td>in:</td>  <td>&nbsp;</td>
        <td><TMPL_VAR NAME=in></td></tr>
        <tr><td>sub:</td>  <td>&nbsp;</td>
        <td><TMPL_VAR NAME=sub></td></tr>
        <tr><td>file:</td>    <td>&nbsp;</td>
        <td><TMPL_VAR NAME=filename></td></tr>
	    <tr><td>line:</td>    <td>&nbsp;</td>
	    <td><TMPL_VAR NAME=line></td></tr>
        <tr><td>package:</td>   <td>&nbsp;</td>
        <td><TMPL_VAR NAME=package></td></tr>
        <tr><td colspan=3>&nbsp;</td></tr>
</TMPL_LOOP>

</table>
</body>
</html>
EOF

@flow_tpl = <<EOF;
<html>
<head>
 <title>Devel::Trace::Subs</title>
</head>

<body>

<br><br>

<h3>Code Subs:</h3>

<table id=error border=0 cellspacing=0>
<TMPL_LOOP NAME=FLOW>
    <tr><td><TMPL_VAR NAME=name></td>  <td>&nbsp;</td>
    <td><TMPL_VAR NAME=value></td></tr>
</TMPL_LOOP>

</table>
</body>
</html>
EOF

@all_tpl = <<EOF;
<html>
<head>
 <title>Devel::Trace::Subs</title>
</head>

<body>

<br>

<h3>Code Subs:</h3>

<table id=error border=0 cellspacing=0>
<TMPL_LOOP NAME=FLOW>
    <tr><td><TMPL_VAR NAME=name>:</td>
    <td>&nbsp;</td> <td><TMPL_VAR NAME=value></td></tr>
</TMPL_LOOP>

</table>

<br>

<h3>Stack trace:</h3>

<table id=error border=0 cellspacing=0>
<TMPL_LOOP NAME=STACK>
        <tr><td>in:</td>  <td>&nbsp;</td>
        <td><TMPL_VAR NAME=in></td></tr>
        <tr><td>sub:</td>  <td>&nbsp;</td>
        <td><TMPL_VAR NAME=sub></td></tr>
        <tr><td>file:</td>    <td>&nbsp;</td>
        <td><TMPL_VAR NAME=filename></td></tr>
	    <tr><td>line:</td>    <td>&nbsp;</td>
	    <td><TMPL_VAR NAME=line></td></tr>
        <tr><td>package:</td>   <td>&nbsp;</td>
        <td><TMPL_VAR NAME=package></td></tr>
        <tr><td colspan=3>&nbsp;</td></tr>
</TMPL_LOOP>

</table>

</body>

</html>
EOF
}

__END__

=head1 NAME

Devel::Trace::Subs::HTML

=for html
<a href="https://github.com/stevieb9/devel-examine-subs/actions"><img src="https://github.com/stevieb9/devel-examine-subs/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/devel-examine-subs?branch=master'><img src='https://coveralls.io/repos/stevieb9/devel-examine-subs/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>


=head1 FUNCTIONS

=head2 C<html(file => 'file.ext', want => 'string', data => HREF)>

=cut

1;
