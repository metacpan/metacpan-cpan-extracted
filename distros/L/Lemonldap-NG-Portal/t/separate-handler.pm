use IO::Pipe;
use IO::Select;
our ( $in,  $out )  = ( IO::Pipe->new, IO::Pipe->new );
our ( $rin, $rout ) = ( IO::Pipe->new, IO::Pipe->new );
my $pid = fork;

unless ( defined $pid ) {
    plan skip_all => 'Unable to fork';
    exit;
}

unless ($pid) {
    {
        no warnings;
    }
    $in->reader;
    $out->writer;
    $rin->writer;
    $rout->reader;
    $out->autoflush(1);
    $rin->autoflush(1);
    use lib 't/lib/';
    require Lemonldap::NG::Handler::Test;
    Lemonldap::NG::Handler::Test::init();
    Lemonldap::NG::Handler::Test::run();
    exit;
}
$in->writer;
$out->reader;
$rin->reader;
$rout->writer;
$in->autoflush(1);
$rout->autoflush(1);
my $s = IO::Select->new();
$s->add($out);
$s->add($rin);

sub handler {
    my (%args) = @_;
    print $in JSON::to_json( $args{req} ) . "\n";
    while ( my @ready = $s->can_read ) {
        foreach $fh (@ready) {
            if ( $fh == $out ) {
                my $res = <$out>;
                return JSON::from_json($res);
            }
            else {
                my $res = <$rin>;
                $res = $args{sub}->( JSON::from_json($res) );
                print $rout JSON::to_json($res) . "\n";
            }
        }
    }
}

sub end_handler {
    print $in "END\n";
}

1;
