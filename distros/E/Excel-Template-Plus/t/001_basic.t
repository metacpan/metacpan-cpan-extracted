#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use File::Spec::Functions;

use Test::More tests => 11;
use Test::Exception;
use Test::Excel::Template::Plus qw(cmp_excel_files);

BEGIN {
    use_ok('Excel::Template::Plus');
    use_ok('Excel::Template::Plus::TT');
}

my %CONFIG   = (
    INCLUDE_PATH => [
        catdir($FindBin::Bin, 'templates'),
    ]
);

my %PARAMS   = (
    worksheet_name => 'Canonical Example',
    greeting       => 'Hello'
);

my $template = Excel::Template::Plus->new(
    engine   => 'TT',
    template => 'basic.tmpl',
    config   => \%CONFIG,
    params   => \%PARAMS
);
isa_ok($template, 'Excel::Template::Plus::TT');

is_deeply 
[qw/greeting worksheet_name/],
[ sort $template->param ],
"... got the list of template params";

is 'basic.tmpl', $template->template, '... got the template from the template';
is_deeply \%CONFIG, $template->config, '... got the config from the template';
is_deeply \%PARAMS, $template->params, '... got the params from the template';

$template->param(location => 'World');

is_deeply 
[qw/greeting location worksheet_name/],
[ sort $template->param ],
"... got the list of template params";

is 'World', $template->param('location'), '... got the location param from the template params';

lives_ok {
    $template->write_file("temp.xls");
} '... writing the template file was successful';

cmp_excel_files "temp.xls", "t/xls/001_basic.xls", '... the generated excel file was correct';

#`open temp.xls`;
unlink 'temp.xls';


