#!perl
use YAML::Tiny;
use LWP::UserAgent;

my $resources = 'https://raw.githubusercontent.com/ua-parser/uap-core/master/';
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
        
        $ua->ssl_opts(verify_hostname => 0,
                      SSL_verify_mode => 0x00);
        
        my $req = HTTP::Request->new(GET => $resources . $file);
        my $res = $ua->request($req);
        die if !$res->is_success;
        $content = $res->content;
    }

    die if !$content;
    
    my $yaml = fix_yaml($content);
    return YAML::Tiny->read_string( $yaml )->[0]->{test_cases};
}

sub fix_yaml {
    my $yaml = shift;
    open(my $fh,'<', \$yaml );
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
