package MYDan::VSSH::Print;
use strict;
use warnings;
use Carp;

use MYDan::Node;
use Term::ANSIColor qw(:constants :pushpop );
$Term::ANSIColor::AUTORESET = 1;

use MYDan::VSSH::Execute;

our $BTLEN = 30;

sub new
{
    my ( $this ) = @_;
    bless +{}, ref $this || $this;
}

sub welcome
{
printf <<EOF;
                        _                          
          __      _____| | ___ ___  _ __ ___   ___ 
          \\ \\ /\\ / / _ \\ |/ __/ _ \\| '_ ` _ \\ / _ \
           \\ V  V /  __/ | (_| (_) | | | | | |  __/
            \\_/\\_/ \\___|_|\\___\\___/|_| |_| |_|\\___|
          
EOF

}

sub yesno
{
    while( 1 )
    {
        print "Are you sure you want to run this command [y/n]:";
        my $in = <STDIN>;
        next unless $in;
        return 1 if $in eq "y\n";
        return 0 if $in eq "n\n";
    }
}
sub result
{
    my ( $this, %r ) = @_;

    print "\n";
    print PUSHCOLOR RED ON_GREEN  "#" x $BTLEN, ' RESULT ', "#" x $BTLEN;
    print "\n";

    my %re;
    map{ push @{$re{$r{$_}}}, $_ }keys %r;
    my $range = MYDan::Node->new( );
    print "=" x 68, "\n";
    map{

        printf "%s[", $range->load( $re{$_} )->dump;
        my $count = scalar @{$re{$_}};

        my $exit = $_ && $_ =~ s/--- (\d+)\r?\n$// ? $1 : 1;

        $exit ? print BOLD RED $count : print BOLD GREEN $count;

        print "]:\n";

        $exit ? print BOLD RED "$_\n" : print BOLD GREEN  "$_\n";

        print "=" x 68, "\n";
    }keys %re;
}

1;
