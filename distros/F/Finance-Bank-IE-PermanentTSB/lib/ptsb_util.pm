package ptsb_util;

=head1 NAME

ptsb_util - functions used by the Finance::Bank::IE::PermanentTSB CLI

This is a package which contains a set of functions used by the CLI utility.

=cut

use Getopt::Long;
use Date::Calc qw(check_date);
use Switch;
use File::Copy;
use Data::Dumper;
use FindBin;
use lib "$FindBin::RealBin/lib";

use Finance::Bank::IE::PermanentTSB;

use strict;
use warnings;

sub usage {
  use Pod::Usage;
  pod2usage(-verbose =>1);
}

# parse config file to retrieve acc_no, password and pan
sub parse_configfile {

    my $cfgfile = shift;

    my $gpg = `which gpg`;
    chop $gpg;

    if($gpg =~ /not found/ or not -x $gpg) {
        print "You need to install and use GnuPG to secure your config file\n";
        print "Please see the documentation on \n".
        "http://search.cpan.org/~pallotron/Finance-Bank-IE-PermanentTSB/ptsb\n";
        exit -1;
    } 

    # encryption dance
    # use the 'file' command to check the cfgfile
    my $res = `file $cfgfile`;
    if($res !~ /GPG encrypted data/is) {
        # not encrypted: encrypt it!
        print("Config file not encrypted. I'm gonna encrypt it!\n");
        print("Executing gpg.. \n");
        print("You'll have to type the name of the key you want to use\n");
        system('gpg -e '.$cfgfile);
        # checking exit status
        if($? != 0 ) {
            # problem with gpg?
            print "Exiting...\n";
            exit -1;
        }
        # If file has been create overwrite the original one
        if(-e $cfgfile.'.gpg') {
            move($cfgfile.'.gpg', $cfgfile);
        }
        # now the config file is crypted!
    }

    # decrypt file in memory
    my @res = `gpg -d $cfgfile`;
    
    # go thru the lines...
    my($user, $pass, $pan);
    foreach my $line (@res) {
        $line =~ s/\n//g;
        $_ = $line;
        if(not /^\s{0,}#/ or not /^\s{0,}/) {
            my ($key, $val) = split '=';
            $val =~ s/^\s+//;
            $val =~ s/\s+$//;
            $user = $val if($key eq 'open24_number');
            $pass = $val if($key eq 'password');
            $pan = $val if($key eq 'pan');
        }
    }

    # die if some of the arguments are undef
    foreach my $i ($user, $pass, $pan) {
        if(not defined $i) {
            die ("invalid configuration file!");
        }
    }

    return ($user, $pass, $pan);
}

sub parse_options {

    my $cf = shift;

    # set some defaults

    # default config file is in ~/.ptsbrc
    $cf->{cfgfile} = $ENV{HOME}."/.ptsbrc";
    $cf->{no_balance} = 0;
    $cf->{statement_type} = 'all';
    $cf->{image} = '/tmp/file.png.'.$$.'.'.time;

    # =o -> Extended integer, Perl style. This can be either an optional
    # leading plus or minus sign, followed by a sequence of digits, or
    # an octal string (a zero, optionally followed by '0', '1', .. '7'),
    # or a hexadecimal string (0x followed by '0' .. '9', 'a' .. 'f',
    # case insensitive), or a binary string (0b followed by a series of
    # '0' and '1').
    #
    # =s -> string
    # =i -> integer

    my $error;
    # be case sensitive!
    Getopt::Long::Configure ("bundling");
    # pase opts, put everything in the $cf hash_ref
    Getopt::Long::GetOptions(
        "file|f=s" => \$cf->{'cfgfile'},
        "help|h" => \$cf->{'help'},
        "debug|D" => \$cf->{'debug'},
        "balance|b" => \$cf->{'balance'},
        "statement|s" => \$cf->{'statement'},
        "statement-type|T=s" => \$cf->{'statement_type'},
        "from-date|f=s" => \$cf->{'fromdate'},
        "to-date|t=s" => \$cf->{'todate'},
        "account-type|a=s" => \$cf->{'acc_type'},
        "account-num|n=s" => \$cf->{'acc_no'},
        "no-balance|N" => \$cf->{'no_balance'},
        "regexp|r=s" => \$cf->{'regexp'},
        "version|v" => \$cf->{'version'},
        "expr|e=s" => \$cf->{'expr'},
        "i|image=s" => \$cf->{'image'},
        "g|graph" => \$cf->{'graph'},
        "o|output=s" => \$cf->{'csv'},
    ) or $error = 1;

    usage if($error or $cf->{'help'});

    usage if(defined $cf->{graph} and $cf->{graph} eq '');

}

sub validate_options {

    my $cf = shift;

    # balance and statement cannot stay together
    if($cf->{balance} and $cf->{statement}) {
        print "You can not select -s and -b together!\n";
        print "You can only select one operation at a time!\n";
        exit -1;
    }

    if(defined $cf->{acc_type}) {
        # acc_type must be 'c' or 'v'
        switch ($cf->{acc_type}) {
            case "c" { $cf->{acc_type} = SWITCH_ACCOUNT; }
            case "v" { $cf->{acc_type} = VISA_ACCOUNT; }
            else     {
                print("Account type invalid\n");
                exit -1;
            }
        }
    }
    
    if(defined $cf->{statement_type}) {
        switch ($cf->{statement_type}) {
            case /WITHDRAWAL/is { $cf->{statement_type} = WITHDRAWAL; }
            case /DEPOSIT/is { $cf->{statement_type} = DEPOSIT; }
            case /ALL/is { $cf->{statement_type} = ALL; }
            else     {
                print("Statement type invalid\n");
                exit -1;
            }
        }
    }

    if(defined $cf->{acc_type}) {
        if($cf->{acc_type} =~ /VISA/is) {
            $cf->{no_balance} = 1;
            $cf->{statement_type} = ALL;
        }
    }   

    if(defined $cf->{version}) {
        print Finance::Bank::IE::PermanentTSB->VERSION, "\n";
        exit 0;
    }

    # all the other check are made by Finance::Bank::IE::PermanentTSB
}

sub print_statement_header {

    my $nobal = shift;

    if ($nobal) {
        for(0...54) { 
            print("-"); 
        }
    } else {
        for(0...68) { 
            print("-"); 
        }
    }
    print "\n";
    my $coldate = "Date"; 
    my $coldesc = "Description";
    my $colam   = "Amount";
    my $colbal  = "Balance";
    printf("| %10s | %25s | %11s |", $coldate, $coldesc, $colam);
    printf(" %11s |", $colbal) if(not $nobal);
    print "\n";
    if ($nobal) {
        for(0...54) { 
            print("-"); 
        }
    } else {
        for(0...68) { 
            print("-"); 
        }
    }
    print "\n";

}

sub print_statement_footer {

    my $nobal = shift;

    if ($nobal) {
        for(0...54) { 
            print("-"); 
        }
    } else {
        for(0...68) { 
            print("-"); 
        }
    }
    print "\n";

}

sub print_balance_header {

    my $colname = "Account name";
    my $coldigit = "Acc. #";
    my $colbal = "Balance";
    my $colavail = "Available";
    for(0...58) { 
        print("-"); 
    }
    print "\n";
    printf("| %18s | %6s | %11s | %11s |", $colname, $coldigit, $colbal,
        $colavail);
    print "\n";
    for(0...58) { 
        print("-"); 
    }
    print "\n";

}

sub print_balance_footer {

    for(0...58) { 
        print("-"); 
    }
    print "\n";

}


sub balance {
    
    my $cf = shift;

    my %config = (
        "open24numba" => $cf->{open24_num},
        "password" => $cf->{pass},
        "pan" => $cf->{pan},
        "debug" => $cf->{debug},
    );

    my $balance = Finance::Bank::IE::PermanentTSB->check_balance(
        \%config, 
        $cf->{acc_type}, 
        $cf->{acc_no}, 
        $cf->{fromdate},
        $cf->{todate});


    if(defined $balance->[0]->{accno}) {
        if($balance->[0]->{accno} eq '') {
            print "Error while retrieving the content...\n";
            return;
        }
    } else {
        exit -1;
    }

    print STDERR Dumper(\$balance) if($cf->{debug});

    print_balance_header;
    
    foreach my $row (@$balance) {
        printf("| %18s | %6s | %11s | %11s |\n",
            $row->{accname},
            $row->{accno},
            $row->{accbal},
            $row->{availbal});
    }
   
    print_balance_footer; 

}

sub statement {

    my $cf = shift;
    my $plot = shift;

    $plot ||= 0;

    my $counter_deposit = 0;
    my $counter_withdrawal = 0;
    my $initial_balance = 0;
    my $final_balance = 0;

    my $gnuplot_tmpfile;

    my $error = 0;
    my $csv = 0;

    my %config = (
        "open24numba" => $cf->{open24_num},
        "password" => $cf->{pass},
        "pan" => $cf->{pan},
        "debug" => $cf->{debug},
    );

    my $statement = Finance::Bank::IE::PermanentTSB->account_statement(
        \%config,
        $cf->{acc_type},
        $cf->{acc_no},
        $cf->{fromdate},
        $cf->{todate},
        $cf->{statement_type},
    );

    if(not defined $statement) {
        return;
    }

    print STDERR Dumper(\$statement) if($cf->{debug});

    if(defined $cf->{csv}) {
        if(open(CSV, ">".$cf->{csv})) {
            $csv = 1;
        } else {
            print STDERR "Error opening file ".$cf->{csv}.": $!\n";
            $csv = 0;
        }
    }

    print_statement_header($cf->{no_balance});

    my $print = 1;
    #foreach my $row (@$statement) {
    for(my $i=0; $i<scalar($#$statement); $i++) {
        my $row = $statement->[$i];
        my $regex = $cf->{regexp};
        my $expr = $cf->{expr};
        if(defined $row->{description} and defined $cf->{regexp}) {
            if($row->{description} =~ /$regex/is) {
                $print = 1;
            } else {
                $print = 0;
            }
        }
        # matches the value of --expr
        if(defined $expr) {
            if($expr =~ /([<,>,=])\s*(\d*)/) {
                my $oper = $1;
                my $val = scalar($2);
                my $am = $row->{euro_amount};
                $am =~ s/[\+-]//g;
                if($cf->{debug}) {
                    print "\n";
                    print "am: '$am'\n";
                    print "1: '$oper'\n";
                    print "2: '$val'\n";
                }
                switch ($oper) {
                    case '<' {
                        if ($am < $val) {
                            $print = 1;
                        } else {
                            $print = 0;
                        }
                    }
                    case '>' {
                        if ($am > $val) {
                            $print = 1;
                        } else {
                            $print = 0;
                        }
                    }
                    case '=' {
                        if ($am == $val) {
                            $print = 1;
                        } else {
                            $print = 0;
                        }
                    }
                    case '<=' {
                        if ($am <= $val) {
                            $print = 1;
                        } else {
                            $print = 0;
                        }
                    }
                    case '>=' {
                        if ($am >= $val) {
                            $print = 1;
                        } else {
                            $print = 0;
                        }
                    }
                    else {
                        $print = 0;
                    }
                }
            }
        }
        if($print) {
            printf("| %s | %25s | %11s ",
                $row->{date},
                $row->{description},
                $row->{euro_amount},
            );
            if(not $cf->{no_balance}) {
                printf "| %11s ", $row->{balance};
                if ($statement->[($i+1)]->{date} ne
                    $statement->[$i]->{date}) {

                    $gnuplot_tmpfile .=
                    $row->{date}."\t".$row->{balance}."\n";
                }
            }
            print "|\n";
            if($row->{euro_amount}<0) {
                $counter_withdrawal += $row->{euro_amount};
            } else {
                $counter_deposit += $row->{euro_amount};
            }
            if($csv) {
                printf CSV "%s,%s,%s", $row->{date}, $row->{description},
                    $row->{euro_amount};
                print CSV ",", $row->{balance} if(not $cf->{no_balance});
                print CSV "\n";
            }
        }

    }

    close CSV if ($csv);

    $gnuplot_tmpfile .=
        $statement->[$#$statement]->{date}."\t".
        $statement->[$#$statement]->{balance}."\n";

    print_statement_footer($cf->{no_balance});

    print "\n=== Totals ===\n\n";
    if($cf->{statement_type} == ALL or $cf->{statement_type} == DEPOSIT) {
        print "Total deposit: $counter_deposit\n";
    }
    if($cf->{statement_type} == ALL or $cf->{statement_type} ==
        WITHDRAWAL) {
        print "Total withdrawal: $counter_withdrawal\n";
    }
    if($cf->{statement_type} == ALL) {
        printf("Profit: %f\n", $counter_deposit+$counter_withdrawal);
    }

    $initial_balance = $statement->[0]->{balance};
    $initial_balance =~ s/[\+|-]//;
    $final_balance = $statement->[$#$statement]->{balance};
    $final_balance =~ s/[\+|-]//;
    if(not $cf->{no_balance}) {
        print "\n";
        print "Initial Balance: ", $initial_balance, "\n";
        print "Final Balance: ", $final_balance, "\n";
        printf "Delta Balance: %f\n", $final_balance-$initial_balance;
    }

    if(defined $cf->{graph} and $cf->{graph}) {

        # writing $gnuplot_tmpfile to file
        my $tmp_data = '/tmp/gnuplot_data'.$$.'.'.time;
        open(TMP, ">$tmp_data");
        print TMP $gnuplot_tmpfile;
        close(TMP);

        # open lib/Finance/Bank/IE/templates/gnuplot_print.gp
        # an parse it replacing [% var %]:
        #
        # - [% ACCOUNT %]
        # - [% OUTPUT %]
        # - [% FILENAME %]
        # - [% TITLE %]

        # open the template and load it in @data
        open(GNUPLOT, "<$FindBin::RealBin/lib/Finance/Bank/IE/templates/gnuplot_print.gp");
        my @data=<GNUPLOT>;
        close(GNUPLOT);

        # define substitutions
        my $template_hash = { 
                ACCOUNT => $cf->{acc_type}."-".$cf->{acc_no},
                OUTPUT => $cf->{image},
                FILENAME => $tmp_data,
                TITLE => $cf->{acc_no},
            };

        print Dumper($template_hash) if($cf->{debug});

        # fill template
        for(my $i = 0; $i<$#data; $i++) {
            $data[$i] =~ s{\[%\s*([_a-zA-Z0-9]+)\s*%\]}{ 
                _fill_template_element($template_hash, $1);
            }gsex;
        }

        # create the gnuplog command file
        my $gnu_print = '/tmp/gnuplot_print'.$$.'.'.time;
        open(TMP, ">$gnu_print");
        foreach my $d (@data) {
            print TMP $d;
        }
        close(TMP);

        # calling gnuplot
        print "\n=== Plotting === \n";
        print "Calling GnuPlot...\n";
        my $res = `which gnuplot`;
        chop $res;
        if(!defined $res or not -e $res or not -x $res) { 
            print STDERR "problems with gnuplot! maybe not installed or permission problem?\n";
            $error = 1;
        } else {
            system("gnuplot $gnu_print");
            print "done.\n";
        }

        print "Cleaning up...\n";
        # unlink the tmp files
        unlink ($tmp_data);
        unlink ($gnu_print);
        if($cf->{image} !~ /^\/tmp\/file\.png\.\d+\.\d+$/ and not $error){
            print "PNG file has been created in ".$cf->{image}."\n";
        } else {
            unlink ($cf->{image});
        }
    }

}

sub _fill_template_element {
    my ($hash, $name) = @_;
    if (!defined $hash->{$name}) {
        warn "undefined template tag: [\% $name \%]\n";
        return '';
    } else {
        return $hash->{$name};
    }
}

1;

