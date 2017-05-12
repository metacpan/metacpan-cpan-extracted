use Pod::Simple::HTML;

my @files = qw(
./lib/EBook/MOBI.pm
./lib/EBook/MOBI/Driver/Example.pm
./lib/EBook/MOBI/Driver/POD.pm
./lib/EBook/MOBI/Driver.pm
./lib/EBook/MOBI/Converter.pm
./lib/EBook/MOBI/Picture.pm
./lib/EBook/MOBI/Mhtml2Mobi.pm
);

my $all_html = '';
for my $file (@files) {

    my $p = Pod::Simple::HTML->new;

    $p->output_string(\my $html);
    $p->parse_file($file);
    $all_html .= $html;
    $all_html .= "\n<hr />\n";
}

open my $out, '>', 'Doku.html' or die "Cannot open 'Doku.html': $!\n";
print $out $all_html;

