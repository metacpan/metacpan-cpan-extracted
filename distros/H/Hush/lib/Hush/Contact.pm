package Hush::Contact;
use strict;
use warnings;
use Hush::Util qw/barf is_valid_zaddr/;
use Data::Dumper;
use File::Spec::Functions;
use Hush::Logger qw/debug/;
use File::Slurp;

my $HUSH_CONFIG_DIR     = $ENV{HUSH_CONFIG_DIR} || catdir($ENV{HOME},'.hush');
my $HUSHLIST_CONFIG_DIR = $ENV{HUSH_CONFIG_DIR} || catdir($HUSH_CONFIG_DIR, 'list');

sub contact {
    my $cmd = shift || '';
    my $subcommands = {
        "add" => sub {
            # add a hush contact, yay
            my ($cmd,$name,$zaddr) = @ARGV;

            barf "Hushlist contact name cannot by empty!" unless $name;
            barf "Invalid zaddr=$zaddr for Hushlist contact $name" unless is_valid_zaddr($zaddr);

            warn Dumper [ $cmd, $name, $zaddr ];
            #TODO: give user ability to choose
            my $chain = "hush";
            my $contacts_file = catdir($HUSHLIST_CONFIG_DIR,"$chain-contacts.txt");

            if (-e $contacts_file) {
                my %contacts   = read_file( $contacts_file ) =~ /^(z[a-z0-9]+) (.*)$/mgi ;

                # TODO: check if zaddr OR nickname exists
                if ($contacts{$zaddr}) {
                } else {
                    # TODO: see if this contact exists already in this chain
                    open my $fh, ">>", $contacts_file or barf "Could not write file $contacts_file ! : $!";
                    #TODO: validation?
                    print $fh "$zaddr $name\n";
                    close $fh;
                }
            }
        },
        "rm" => sub {
            my ($cmd,$name,$zaddr) = @ARGV;

            barf "Hushlist contact name cannot by empty!" unless $name;
            barf "Invalid zaddr=$zaddr for Hushlist contact $name" unless is_valid_zaddr($zaddr);

            barf Dumper [ $cmd, $name, $zaddr ];
        },
    };

    my $subcmd = $subcommands->{$cmd};
    if ($subcmd) {
        $subcmd->();
    } else {
        barf "Invalid hushlist contact subcommand!";
    }
}

1;
