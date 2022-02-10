package Devel::Trace::Subs::Text;
use 5.008;
use strict;
use warnings;

use Data::Dumper;
use Exporter;
use Template;

our $VERSION = '0.24';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(text);

my ($stack_tpl, $flow_tpl, $all_tpl);

sub text {

    my %p = @_;

    my $file = $p{file};
    my $want = $p{want};
    my $data = $p{data};

    if ($want && $want eq 'stack') {

        my $template = Template->new;

        if ($file) {

            $template->process(
                \$stack_tpl,
                {stack => $data},
                $file
            ) || die $template->error;
        }
        else {
            $template->process(
                \$stack_tpl,
                {stack => $data},
            ) || die $template->error;
        }
    }
    elsif ($want && $want eq 'flow') {

        my $template = Template->new;

        if ($file) {

            $template->process(
                \$flow_tpl,
                {flow => $data},
                $file
            ) || die $template->error;
        }
        else {
            $template->process(
                \$flow_tpl,
                {flow => $data}
            ) || die $template->error;
        }
    }
    else {
        my $template = Template->new;

         if ($file) {

            $template->process(
                \$all_tpl,
                $data,
                $file,
            ) || die $template->error;
        }
        else {
            $template->process(\$all_tpl, {
                flow => $data->{flow},
                stack => $data->{stack},
            });
        }
    }
}

BEGIN {

$flow_tpl = <<EOF;

Code flow:

[% FOREACH entry IN flow -%]
    [% entry.name %]: [% entry.value %]
[% END %]
EOF

$stack_tpl = <<EOF;

Stack trace:

[%- FOREACH entry IN stack %]
    in:      [% entry.in %]
    sub:     [% entry.sub %]
    file:    [% entry.filename %]
    line:    [% entry.line %]
    package: [% entry.package %]
[% END %]
EOF

$all_tpl = <<EOF;

Code flow:

[% FOREACH entry IN flow -%]
    [% entry.name %]: [% entry.value %]
[% END %]
Stack trace:

[%- FOREACH entry IN stack %]
    in:      [% entry.in %]
    sub:     [% entry.sub %]
    file:    [% entry.filename %]
    line:    [% entry.line %]
    package: [% entry.package %]
[% END %]
EOF
}
__END__

=head1 NAME

Devel::Trace::Subs::Text

=for html
<a href="https://github.com/stevieb9/devel-examine-subs/actions"><img src="https://github.com/stevieb9/devel-examine-subs/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/devel-examine-subs?branch=master'><img src='https://coveralls.io/repos/stevieb9/devel-examine-subs/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>


=head1 FUNCTIONS

=head2 C<text(file => 'file.ext', want => 'string', data => HREF)>

=cut

1;
