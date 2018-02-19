package Hush::App;
use strict;
use warnings;
use Try::Tiny;
use lib 'lib';
use Hush::List;
use Hush::Util qw/barf/;
use Data::Dumper;
use Hush::RPC;
use File::Slurp;

my $COMMANDS  = {
    "add"       => \&add,
    "contact"   => \&Hush::Contact::contact,
    "help"      => \&help,
    "new"       => \&new,
    "remove"    => \&remove,
    "send"      => \&send,
    "send-file" => \&send_file,
    "show"      => \&show,
    "status"    => \&status,
    #"public"   => \&public,
    "subscribe" => \&subscribe,
};
# TODO: translations
my %HELP      = (
    "add"       => "Add a contact to a Hushlist",
    "contact"   => "Manage Hushlist contacts",
    "help"      => "Get your learn on",
    "new"       => "Create a new Hushlist",
    "remove"    => "Remove a Hushlist",
    "send"      => "Send a new Hushlist memo, specified on command-line",
    "send-file" => "Send a new Hushlist memo from a file on disk",
    "status"    => "Get overview of Hushlists or a specific Hushlist",
    "show"      => "Show Hushlist memos",
    #"public"   => "Make a private Hushlist public",
);

my $options   = {};
my $rpc       = Hush::RPC->new;
my $list      = Hush::List->new($rpc, $options);

sub validate_hushlist_url {
    my ($url) = @_;
    # TODO: allow full syntax and bare privkeys
    # and other chains
    if ($url =~ m!^hushlist://(SK[A-z0-9]+)(\?height=(\d+))?!i) {
        my ($key,$height) = ($1,$3);
        my ($chain,$net)  = ("hush","");
        return ($chain, $net, $key,$height);
    }
    return undef;
}

sub subscribe {
    my ($url) = @_;

    my $status;
    if ($url) {
        if (my @hushlist = validate_hushlist_url($url)) {
            $status = $list->subscribe(@hushlist);
        } else {
            die "Invalid hushlist URL!\n";
        }
    } else {
        die "Usage: hushlist subscribe URL\n";
    }
    return $status;
}

sub show_status {
    my $chaininfo     = $rpc->getblockchaininfo;
    my $walletinfo    = $rpc->getwalletinfo;
    my $chain         = $chaininfo->{chain};
    my $blocks        = $chaininfo->{blocks};
    my $balance       = $rpc->z_gettotalbalance;
    my $tbalance      = sprintf "%.8f", $balance->{transparent};
    my $zbalance      = sprintf "%.8f", $balance->{private};
    my $total_balance = $balance->{total};
    my $blockchain    = "HUSH";

    print "Hushlist v$Hush::List::VERSION running on $blockchain ${chain}net, $blocks blocks\n";
    print "Balances: transparent $tbalance HUSH, private $zbalance HUSH\n";
}


sub run {
    my ($command) = @_;
    #print "Running command $command\n";
    my $cmd = $COMMANDS->{$command};

    show_status();

    if ($cmd) {
        return $cmd->(@ARGV);
    } else {
        usage();
    }
}

sub add {
    my ($list_name,$contact) = @_;

    # we add contacts to a list, not a zaddr
    $list->add_contact($list_name,$contact);
}

sub remove {
    my ($list_name,$zaddr) = @_;

    $list->remove_zaddr($list_name,$zaddr);
    return $list;
}

# send a Hushlist memo from a file
sub send_file {
    my ($list_name,$file) = @_;

    barf "You must specify a Hushlist to send to" unless $list_name;
    barf "You must specify a file to attach" unless $file;

    if (-e $file) {
        my $memo     = read_file($file);
        $list->send_memo($rpc, $list_name, $memo);
    } else {
        barf "Cannot find $file to attach to Hushlist memo to $list_name!";
    }
    return $list;
}

# send a Hushlist memo to list of contacts on the chain
# specified for this list
sub send {
    my ($list_name,$memo) = @_;

    $list->send_memo($rpc, $list_name, $memo);
}

sub help {
    print "Available Hushlist commands:\n";
    my @cmds = sort keys %$COMMANDS;
    for my $cmd (@cmds) {
        print "\t$cmd\t: $HELP{$cmd}\n";
    }
}

sub show {
    my ($name,@args) = @_;
    if ($name) {
        my $status = $list->show($name);
    } else {
        my $status = $list->global_show;
    }
}

sub usage {
    print "Usage: $0 command [subcommand] [options]\n";
    print "$0 help for more details :)\n";
    return 1;
}

sub status {
    my $name = shift;
    if ($name) {
        my $status = $list->status($name);
    } else {
        my $status = $list->global_status;
    }
}

# make a hushlist public by publishing its privkey in OP_RETURN data
# This operation costs HUSH and cannot be undone!!! It sends private
# keys to the PUBLIC BLOCKCHAIN
sub publicize {
    my ($name) = @_;

    $list->publicize($name);
}

sub new {
    my $name = shift || '';
    #TODO: better validation and allow safe unicode stuff
    barf "Invalid hushlist name '$name' !" unless $name && ($name =~ m/^[A-z0-9_-]{0,64}/);

    $list->new_list($name);
    print "hushlist '$name' created, enjoy your private comms ;)\n";
}

1;
