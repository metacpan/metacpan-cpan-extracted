use YAML::Tiny;
use LWP::UserAgent;

my $resources = 'http://raw.githubusercontent.com/ua-parser/uap-core/master/';
my $dir = "../uap-core/";

sub get_test_yaml {
    my $file = shift;
    my $content;

    if (-e $dir.$file) {
        $file = $dir.$file;
        open (my $FH, $file) or die "Can't open $file\n";
        $content = join("\n", <$FH>);
        close ($FH);
    }
    else {
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get($resources . $file);
        die $res->status_line if !$res->is_success;
        $content = $res->content;
    }

    die "couldn't get yaml content" if !$content;

    my $yaml = fix_yaml($content);
    return YAML::Tiny->read_string( $yaml )->[0]->{test_cases};
}

sub fix_yaml {
    my $yaml = shift;
    open(my $fh,'<:encoding(UTF-8)', \$yaml );
    my $c;
    while(my $line = <$fh>){
        if ($line){
            $line =~ s/(\s*(?:family|major|minor|patch|patch_minor|brand|model):)\s?\n$/$1 ~\n/;
        }
        $c .= $line;
    }
    close $fh;
    return $c;
}

1;
