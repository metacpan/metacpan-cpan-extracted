package MYDan::Util::Command;
use strict;
use warnings;
use Carp;
use MYDan;

sub new
{
    my ( $class, $name, $cmd, $alias ) = @_;
    bless +{ name => $name, cmd => $cmd, alias => $alias || +{} }, ref $class || $class;
}

sub do
{
    my ( $this, $cmd, @argv )= @_;

    $ENV{MYDan_DEBUG} = 1 && $cmd = lc( $cmd ) if $cmd && $cmd =~ /^[A-Z][a-z]*$/;

    if( $cmd && $cmd eq '--box' )
    {
        system "touch '$MYDan::PATH/dan/.ignore'" if -d "$MYDan::PATH/dan";
        print "Switch to `box` first.\n";
	return;
    }
    elsif( $cmd && $cmd eq '--dan' )
    {
        unlink "$MYDan::PATH/dan/.ignore" if -f "$MYDan::PATH/dan/.ignore";
        print "Switch to `dan` first.\n";
	return;
    }

    $cmd = $this->{alias}{$cmd} if $cmd && $this->{alias}{$cmd};

    my ( $c ) = grep{ $cmd && $_->[0] eq $cmd }@{$this->{cmd}};

    $this->help() and return unless $c;

    my @x = splice @$c, 2;
    @x = reverse @x if -f "$MYDan::PATH/dan/.ignore";
    map{ exec join( ' ', "$MYDan::PATH/$_", map{"'$_'"}@argv ) if -e "$MYDan::PATH/$_" }@x;
    print "$cmd is not installed\n";
}

sub help
{
    my $this = shift;

    my ( $name, $cmd ) = @$this{qw( name cmd )};

    print "Usage: $name COMMAND [arg...]\n";
    print "Options:\n\t--dan\tSwitch to `dan` first.\n\t--box\tSwitch to `box` first.\n\n";
    print "\tHelp\tshow detail\n";
    print "Commands:\n";

    map{
        my @x = splice @$_, 2;
	@x = reverse @x if -f "$MYDan::PATH/dan/.ignore";
        my ( $x ) = grep{ -e "$MYDan::PATH/$_" }@x;
	if( $ENV{MYDan_DEBUG} )
	{
            printf "\t%s $_->[0]\t$_->[1]\n", $x ? $x =~ /^dan/ ? 'dan' : 'box' : 'nil';
	}
	else
	{
            printf "\t%s $_->[0]\t$_->[1]\n", $x ? '*': ' ';
	}
    }@$cmd;

    print "\nRun '$name COMMAND --help' for more information on a command.\n"
}

1;
__END__
