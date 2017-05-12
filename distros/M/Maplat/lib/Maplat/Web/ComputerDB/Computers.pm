# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

package Maplat::Web::ComputerDB::Computers;
use strict;
use warnings;

use 5.012;
use base qw(Maplat::Web::BaseModule);

use Maplat::Helpers::DateStrings;
use Maplat::Helpers::Padding qw(doFPad);
use PDF::Report;


our $VERSION = 0.995;

use Carp;

my @keynames = qw[old_computer_name computer_name costunit description net_internal_type net_internal_ip net_internal_mac
                             net_prod_type net_prod_ip net_prod_mac computer_domain account_user account_password
                             account_domain lastedit_time lastedit_user operating_system servicepack is_64bit
                             has_antivirus line_id position_x position_y has_acronisagent has_vnc vnc_password];

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do
    return;
}

sub register {
    my $self = shift;
    $self->register_webpath($self->{computeredit}->{webpath}, "get_edit");
    $self->register_webpath($self->{computerselect}->{webpath}, "get_select");
    $self->register_webpath($self->{computervnc}->{webpath}, "get_vncedit");
    $self->register_webpath($self->{pdflist}->{webpath}, "get_pdflist");
    $self->register_loginitem("on_login");
    return;
}

sub on_login {
    my ($self, $username, $sessionid) = @_;
    
    return;
}

# This is a quite complex tool. Until i have found a better way, disable the ExcessComplexity warning
# of Perl::Critic
sub get_edit { ## no critic (ProhibitExcessComplexity)
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $maph = $self->{server}->{modules}->{$self->{mapmaker}};
    
    my $host_addr = $cgi->remote_addr();
    my $mode = $cgi->param('mode') || 'new';
    
    my @domains;
    my $dsth = $dbh->prepare_cached("SELECT enumvalue FROM enum_computers_domains
                                     ORDER BY enumvalue")
          or croak($dbh->errstr);
    $dsth->execute or croak($dbh->errstr);
    while((my $domain = $dsth->fetchrow_array)) {
       push @domains, $domain;
    }
    $dsth->finish;

    my @networktypes;
    my $nsth = $dbh->prepare_cached("SELECT enumvalue FROM enum_computers_network
                                    ORDER BY enumvalue")
            or croak($dbh->errstr);
    $nsth->execute or croak($dbh->errstr);
    while((my $networktype = $nsth->fetchrow_array)) {
        push @networktypes, $networktype;
    }
    $nsth->finish;
    
    my @prodlines;
    my $psth = $dbh->prepare_cached("SELECT * FROM global_prodlines
                                    ORDER BY line_id")
            or croak($dbh->errstr);
    $psth->execute or croak($dbh->errstr);
    while((my $prodline = $psth->fetchrow_hashref)) {
        push @prodlines, $prodline;
    }
    $psth->finish;
    
    my @companies;
    my $csth = $dbh->prepare_cached("SELECT * FROM cc_company
                                    ORDER BY company_name")
            or croak($dbh->errstr);
    $csth->execute or croak($dbh->errstr);
    while((my $company = $csth->fetchrow_hashref)) {
        push @companies, $company->{company_name};
    }
    $psth->finish;
    
    
    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{computeredit}->{pagetitle},
        webpath            =>  $self->{computeredit}->{webpath},
        ComputerSelect    =>    $self->{computerselect}->{webpath},
        domains            => \@domains,
        networktypes    => \@networktypes,
        AvailProdLines  => \@prodlines,
    );
    
    my %computer;
    if($mode ne "new") {
        # Get parameters from webform
        foreach my $keyname (@keynames) {
            if(!defined($computer{$keyname})) {
                $computer{$keyname} = $cgi->param($keyname) || '';
                given($keyname) {
                    when(/^(?:is_|has_)/o) {
                        if($computer{$keyname} eq "on") {
                            $computer{$keyname} = 1;
                        } else {
                            $computer{$keyname} = 0;
                        }
                    }
                    when(/^net_.*_ip/o) {
                        if($computer{$keyname} eq "") {
                            $computer{$keyname} = "0.0.0.0";
                        }
                    }
                    when(/^net_.*_mac/o) {
                        if($computer{$keyname} eq "") {
                            $computer{$keyname} = "00:00:00:00:00:00";
                        } else {
                            $computer{$keyname} =~ s/\-/:/go;
                        }
                    }
                    when("servicepack") {
                        if(defined($computer{$keyname})) {
                            if($computer{$keyname} eq "") {
                                $computer{$keyname} = 0;
                            }
                            $computer{$keyname} = $computer{$keyname} + 0;
                        } else {
                            $computer{$keyname} = 0;
                        }
                    }
                }
            }
        }
    }
    
    # Handle standard POST requests
    given($mode) {
        when("delete") {
            my $sth = $dbh->prepare("DELETE FROM computers
                                           WHERE computer_name = ?")
                    or croak($dbh->errstr);
            if($sth->execute($computer{old_computer_name})) {
                $sth->finish;
                $dbh->commit;
                $webdata{statustext} = "Computer deleted";
                $webdata{statuscolor} = "oktext";
            } else {
                $dbh->rollback;
                $webdata{statustext} = "Deletion failed";
                $webdata{statuscolor} = "errortext";
            }
            $mode = 'new';
        }
        when("create") {
            my @fields;
            my @values;
            foreach my $keyname (@keynames) {
                next if($keyname eq "old_computer_name");
                push @fields, $keyname;
                if(!defined($computer{$keyname})) {
                    $computer{$keyname} = "";
                }
                if($keyname eq "lastedit_time") {
                    push @values, "now()";
                } elsif($keyname eq "lastedit_user") {
                    push @values, $dbh->quote($webdata{userData}->{user});
                } elsif($keyname =~ /^(is_|has_)/) {
                    if($computer{$keyname} == 1) {
                        push @values, "'true'";
                    } else {
                        push @values, "'false'";
                    }

                } else {
                    push @values, $dbh->quote($computer{$keyname});
                }
            }

            my $stmt = "INSERT INTO computers (" . join(',', @fields) . ") " .
                        " VALUES (" . join(',', @values) . ")";

            my $sth = $dbh->prepare($stmt)
                    or croak($dbh->errstr);
            my $ok = 1;
            if(!$sth->execute()) {
                $ok = 0;
            } else {
                $sth->finish;
            }
            
            my @vcompany;
            my @vcompanies = $cgi->param('vnccompany[]');
            foreach my $company (@companies) {
                my $enabled = 0;
                if($company ~~ @vcompanies) {
                    $enabled = 1;
                }
                
                my %tmp = (
                    name        => $company,
                    is_active    => $enabled,
                );
                push @vcompany, \%tmp;
            }

            if($ok) {
                my $vsth = $dbh->prepare_cached("INSERT INTO computers_vnccompany
                                                (computer_name, company_name, is_enabled)
                                                VALUES (?,?,?)")
                        or croak($dbh->errstr);
                foreach my $vcomp (@vcompany) {
                    
                    if(!$vsth->execute($computer{computer_name}, $vcomp->{name}, $vcomp->{is_active})) {
                        $ok = 0;
                        last;
                    }
                }
            }
            
            if($ok) {
                $dbh->commit;
                $webdata{statustext} = "Computer created";
                $webdata{statuscolor} = "oktext";

                # Force reload from database so server side processing gets integrated into
                # the displayed data
                $computer{old_computer_name} = $computer{computer_name};
                $mode = "select";

            } else {
                $dbh->rollback;
                $webdata{statustext} = "Creation failed";
                $webdata{statuscolor} = "errortext";
                $webdata{vnccompanies} = \@vcompany;
                $mode = "create";
            }
        }
        when("edit") {
            my @fields;
            foreach my $keyname (@keynames) {
                next if($keyname eq "old_computer_name");
                my $field = "$keyname = ";
                if(!defined($computer{$keyname})) {
                    $computer{$keyname} = "";
                }
                if($keyname eq "lastedit_time") {
                    $field .= "now()";
                } elsif($keyname eq "lastedit_user") {
                    $field .= $dbh->quote($webdata{userData}->{user});
                } elsif($keyname =~ /^(is_|has_)/) {
                    if($computer{$keyname} == 1) {
                        $field .= "'true'";
                    } else {
                        $field .= "'false'";
                    }
                } else {
                    $field .= $dbh->quote($computer{$keyname});
                }
                push @fields, $field;
            }

            my $stmt = "UPDATE computers SET " . join(',', @fields) .
                        " WHERE computer_name = " . $dbh->quote($computer{old_computer_name});

            my $sth = $dbh->prepare($stmt)
                    or croak($dbh->errstr);
            my $ok = 1;
            if(!$sth->execute()) {
                $ok = 0;
            } else {
                $sth->finish;
            }

            if($ok) {
                my $vdelsth = $dbh->prepare_cached("DELETE FROM computers_vnccompany
                                                   WHERE computer_name = ?")
                        or croak($dbh->errstr);
                if(!$vdelsth->execute($computer{computer_name})) {
                    $ok = 0;
                } else {
                    $vdelsth->finish;
                }
            }
            
            my @vcompany;
            my @vcompanies = $cgi->param('vnccompany[]');
            foreach my $company (@companies) {
                my $enabled = 0;
                if($company ~~ @vcompanies) {
                    $enabled = 1;
                }
                
                my %tmp = (
                    name        => $company,
                    is_active    => $enabled,
                );
                push @vcompany, \%tmp;
            }
            
            if($ok) {
                my $vsth = $dbh->prepare_cached("INSERT INTO computers_vnccompany
                                                (computer_name, company_name, is_enabled)
                                                VALUES (?,?,?)")
                        or croak($dbh->errstr);

                foreach my $vcomp (@vcompany) {
                    if(!$vsth->execute($computer{computer_name}, $vcomp->{name}, $vcomp->{is_active})) {
                        $ok = 0;
                        last;
                    }
                }
            }

            if($ok) {
                $dbh->commit;
                $webdata{statustext} = "Computer updated";
                $webdata{statuscolor} = "oktext";
                
                # Force reload from database so server side processing gets integrated into
                # the displayed data
                $computer{old_computer_name} = $computer{computer_name};
                $mode = "select";
                
            } else {
                $dbh->rollback;
                $webdata{statustext} = "Update failed";
                $webdata{statuscolor} = "errortext";
                $mode = "edit";
                $webdata{vnccompanies} = \@vcompany;
            }
        }
    }

    if($mode eq "select") {
        my $stmt = "SELECT * FROM computers " .
                    "WHERE computer_name = ?";
        my $sth = $dbh->prepare($stmt)
                or croak($dbh->errstr);
        if(!$sth->execute($computer{old_computer_name})) {
            $dbh->rollback;
            $webdata{statustext} = "Can't load computer";
            $webdata{statuscolor} = "errortext";
            $mode = "new";
        } else {
            my $line = $sth->fetchrow_hashref;
            $sth->finish;
            $dbh->rollback;
            if(defined($line)) {
                foreach my $keyname (@keynames) {
                    next if($keyname eq "old_computer_name");
                    if(!defined($line->{$keyname})) {
                        $computer{$keyname} = "";
                    } else {
                        $computer{$keyname} = $line->{$keyname};
                    }
                }
                
                my $vsth = $dbh->prepare_cached("SELECT company_name, is_enabled
                                                FROM computers_vnccompany
                                                WHERE computer_name = ?")
                        or croak($dbh->errstr);
                my %vcomp;
                $vsth->execute($computer{old_computer_name});
                while((my $vline = $vsth->fetchrow_hashref)) {
                    $vcomp{$vline->{company_name}} = $vline->{is_enabled};
                }
                $vsth->finish;
                my @vnccompanies;
                foreach my $vnccompany (@companies) {
                    my %tmp = (
                        name        =>    $vnccompany,
                        is_active    =>    0,
                    );
                    if(defined($vcomp{$vnccompany})) {
                        $tmp{is_active}    = $vcomp{$vnccompany};
                    }
                    push @vnccompanies, \%tmp;
                }
                $webdata{vnccompanies} = \@vnccompanies;
                
                $mode = "edit";    
            } else {
                $webdata{statustext} = "Can't load computer";
                $webdata{statuscolor} = "errortext";
                $mode = "new";
            }
        }
    }

    
    if($mode eq "new") {
        my %defaultcomputer = (
            is_64bit            => 0,
            has_antivirus        => 1,
            has_vnc                => 0,
        );
        foreach my $keyname (@keynames) {
            if(!defined($defaultcomputer{$keyname})) {
                $defaultcomputer{$keyname} = "";
            }
        }
        $defaultcomputer{position_x} = "0";
        $defaultcomputer{position_y} = "0";
        $webdata{computer} = \%defaultcomputer;
        
        my @vnccompanies;
        foreach my $vnccompany (@companies) {
            my %tmp = (
                name        =>    $vnccompany,
                is_active    =>    0,
            );
            push @vnccompanies, \%tmp;
        }
        $webdata{vnccompanies} = \@vnccompanies;
        
        $mode = "create";
    } else {
        # Beautify a bit
        if($computer{net_internal_ip} eq "0.0.0.0") {
            $computer{net_internal_ip} = "";
        }
        if($computer{net_prod_ip} eq "0.0.0.0") {
            $computer{net_prod_ip} = "";
        }
        if($computer{net_internal_mac} eq "00:00:00:00:00:00") {
            $computer{net_internal_mac} = "";
        }
        if($computer{net_prod_mac} eq "00:00:00:00:00:00") {
            $computer{net_prod_mac} = "";
        }
        $webdata{computer} = \%computer;
    }
    $webdata{EditMode} = $mode;
    
    my $ossth = $dbh->prepare_cached("SELECT * FROM computers_os
                                     ORDER BY operating_system")
            or croak($dbh->errstr);
    $ossth->execute() or croak($dbh->errstr);
    my @oss;
    while((my $line = $ossth->fetchrow_hashref)) {
        push @oss, $line;
    }
    $webdata{operating_systems} = \@oss;
    
    my $custh = $dbh->prepare_cached("SELECT * FROM global_costunits
                                 ORDER BY costunit")
        or croak($dbh->errstr);
    $custh->execute() or croak($dbh->errstr);
    my @costunits;
    while((my $line = $custh->fetchrow_hashref)) {
        push @costunits, $line;
    }
    $webdata{costunits} = \@costunits;
    
    $maph->makeMap(\%webdata,
        type    => 'computer',
        readonly=> '0',
        pos_x   => $webdata{computer}->{position_x},
        pos_y   => $webdata{computer}->{position_y},
        target_x    => '#position_x_c',
        target_y    => '#position_y_c',
        infofield   => 'div#computercoords',
        status  => 'ok',                   
    );
    
    my $template = $self->{server}->{modules}->{templates}->get("computerdb/computers_edit", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}


# "get_select" actually only displays the available card list, POST
# is done to the main mask to have a smoother workflow without redirects
sub get_select {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    my $mode = $cgi->param('mode') || 'view';
    
    if($mode eq "view") {
        my $sth = $dbh->prepare_cached("SELECT * FROM computers 
                                       ORDER BY computer_name")
                    or croak($dbh->errstr);
        my @computers;
        
        if($sth->execute) {
            while((my $line = $sth->fetchrow_hashref)) {
                push @computers, $line;
            }
        }
        
    
        my $pdfpath =  $self->{pdflist}->{webpath} . '/' .
                int(rand(10000)) . '_' .
                int(rand(10000)) . '_';
        
        my %webdata = 
        (
            $self->{server}->get_defaultwebdata(),
            PageTitle   =>  $self->{computerselect}->{pagetitle},
            webpath        =>  $self->{computerselect}->{webpath},
            pdflist            =>    $pdfpath,
            computers        =>  \@computers,
        );
        
        my $template = $self->{server}->{modules}->{templates}->get("computerdb/computers_select", 1, %webdata);
        return (status  =>  404) unless $template;
        return (status  =>  200,
                type    => "text/html",
                data    => $template);
    } else {
        return $self->get_edit($cgi);
    }
}

sub get_pdflist {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    
        my $pdf = PDF::Report->new(PageSize          => "A4", 
                                PageOrientation => "Portrait",
                                );
    
    my ($pagewidth, $pageheight) = $pdf->getPageDimensions();
    
    my $pagecount = 1;
    
    my $usth = $dbh->prepare_cached("SELECT *, co.description co_description
                               FROM computers co, global_costunits cu
                               WHERE co.costunit = cu.costunit
                               ORDER BY line_id, computer_name")
            or croak($dbh->errstr);
    
    $usth->execute() or croak($dbh->errstr);

    my $z = $pageheight;
        
    $pdf->setFont('Arial');

    my @computers;
    my %convert = (
        'ä'    => 'ae',
        'ö'    => 'oe',
        'ü'    => 'ue',
        'Ä'    => 'Ae',
        'Ö'    => 'Oe',
        'Ü'    => 'Ue',
        'ß'    => 'ss',
    );
    while((my $computer = $usth->fetchrow_hashref)) {
        foreach my $key (keys %convert) {
            my $val = $convert{$key};
            $computer->{co_description} =~ s/$key/$val/g;
        }
        push @computers, $computer;

        if($z == $pageheight) {
            $pdf->newpage(1);
            $z -= 20;
        
            if(defined($self->{pdflist}->{logo})) {
                $pdf->addImg($self->{pdflist}->{logo}, 40, $z - 58);
            }
        
            $pdf->setSize(10);
            $pdf->addRawText("Page $pagecount", $pagewidth - 150, 20, "grey");
            $pdf->addRawText(getISODate(), 40, 20, "grey");
            $pdf->setSize(30);
            $z -= 110;
            $pdf->addRawText("Computer list", 100, $z, "black", 0);
            $z -= 40;
            $pdf->setSize(12);
            $pdf->addRawText("ProdLine", 40, $z, "black");
            $pdf->addRawText("Hostname", 115, $z, "black");
            $pdf->addRawText("Operating System", 200, $z, "black");
            $pdf->addRawText("Description", 360, $z, "black");
            
            $z -= 14;
        }    

        $pdf->setSize(12);
        $pdf->addRawText($computer->{line_id}, 40, $z, "black");
        $pdf->addRawText($computer->{computer_name}, 115, $z, "black");
        my $osname = $computer->{operating_system} . ' SP ' . $computer->{servicepack};
        $pdf->addRawText($osname, 200, $z, "black");
        $pdf->addRawText($computer->{co_description}, 360, $z, "black");
        $z -= 14;
    
        if($z < 60) {
            $pagecount++;
            $z = $pageheight;
        }
    }

    $usth->finish;
    $dbh->rollback;
    
    # Add "computer data sheet"
    if($z != $pageheight) {
        $pagecount++;
        $z = $pageheight;
    }
    
    if(1) {
    foreach my $computer (@computers) {
            $pdf->newpage(1);
            $z = $pageheight - 20;
        
            if(defined($self->{pdflist}->{logo})) {
                $pdf->addImg($self->{pdflist}->{logo}, 40, $z - 58);
            }
        
            $pdf->setSize(10);
            $pdf->addRawText("Page $pagecount", $pagewidth - 150, 20, "grey");
            $pdf->addRawText(getISODate(), 40, 20, "grey");
            $pdf->setSize(30);
            $z -= 110;
            $pdf->addRawText("Computer data sheet", 100, $z, "black", 0);
            $z -= 40;
            $pdf->addRawText($computer->{line_id}, 40, $z, "black");
            $pdf->addRawText($computer->{computer_name}, 240, $z, "black");
            
            # ------------- COMPUTER -----------
            $z -= 50;
            $pdf->setSize(20);
            $pdf->addRawText("Computer", 40, $z, "black", 0);
            $z -= 24;
            $pdf->setSize(12);
            $pdf->addRawText("Hostname: " . $computer->{computer_name}, 40, $z, "black");
            $z -= 14;
            $pdf->addRawText("Location: " . $computer->{line_id}, 40, $z, "black");
            $z -= 14;
            $pdf->addRawText("Cost Unit: " . $computer->{costunit}, 40, $z, "black");
            $z -= 14;
            $pdf->addRawText("Description: " . $computer->{co_description}, 40, $z, "black");
            $z -= 14;
            
            # --------------- OS ----------------
            $z -= 20;
            $pdf->setSize(20);
            $pdf->addRawText("Operating System", 40, $z, "black", 0);
            $z -= 24;
            $pdf->setSize(12);
            $pdf->addRawText("OS: " . $computer->{operating_system}, 40, $z, "black");
            $z -= 14;
            $pdf->addRawText("Servicepack: " . $computer->{servicepack}, 40, $z, "black");
            $z -= 14;
            if($computer->{is_64bit}) {
                $pdf->addRawText("32/64 Bit: 64 Bit", 40, $z, "black");
            } else {
                $pdf->addRawText("32/64 Bit: 32 Bit", 40, $z, "black");
            }
            $z -= 14;
            if($computer->{has_antivirus}) {
                $pdf->addRawText("AntiVirus: McAfee Antivirus", 40, $z, "black");
            } else {
                $pdf->addRawText("AntiVirus: none", 40, $z, "black");
            }
            $z -= 14;

            # --------------- Domain ----------------
            $z -= 20;
            $pdf->setSize(20);
            $pdf->addRawText("Domain", 40, $z, "black", 0);
            $z -= 24;
            $pdf->setSize(12);
            $pdf->addRawText("Computer Domain: " . $computer->{computer_domain}, 40, $z, "black");
            $z -= 14;
            $pdf->addRawText("Login Domain: " . $computer->{computer_domain}, 40, $z, "black");
            $z -= 14;
            $pdf->addRawText("Username: " . $computer->{account_user}, 40, $z, "black");
            $z -= 14;
            $pdf->addRawText("Password: " . $computer->{account_password}, 40, $z, "black");
            $z -= 14;

            # --------------- ext. Network ----------------
            $z -= 20;
            $pdf->setSize(20);
            $pdf->addRawText("ext. Network", 40, $z, "black", 0);
            $z -= 24;
            $pdf->setSize(12);
            $pdf->addRawText("Type: " . $computer->{net_prod_type}, 40, $z, "black");
            $z -= 14;
            $pdf->addRawText("IP: " . $computer->{net_prod_ip}, 40, $z, "black");
            $z -= 14;
            $pdf->addRawText("MAC: " . $computer->{net_prod_mac}, 40, $z, "black");
            $z -= 14;

            # --------------- int. Network ----------------
            $z -= 20;
            $pdf->setSize(20);
            $pdf->addRawText("int. Network", 40, $z, "black", 0);
            $z -= 24;
            $pdf->setSize(12);
            $pdf->addRawText("Type: " . $computer->{net_internal_type}, 40, $z, "black");
            $z -= 14;
            $pdf->addRawText("IP: " . $computer->{net_internal_ip}, 40, $z, "black");
            $z -= 14;
            $pdf->addRawText("MAC: " . $computer->{net_internal_mac}, 40, $z, "black");
            $z -= 14;
            $pagecount++;

    }
    }
    
    
    my $report = $pdf->Finish();
    
    return (status  =>  404) unless $report;
    return (status  =>  200,
        type    => "application/pdf",
        data    => $report);
}

# VNCEdit is a quickedit tool to quickly changes VNC access rights on a number
# of computers
sub get_vncedit {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $mode = $cgi->param('mode') || 'view';
    
    
    my $csth = $dbh->prepare_cached("SELECT * FROM computers
                                    ORDER BY line_id, computer_name")
            or croak($dbh->errstr);
    my $rsth = $dbh->prepare_cached("SELECT * FROM cc_company
                                    ORDER BY company_name")
            or croak($dbh->errstr);
    my $vsth = $dbh->prepare_cached("SELECT * FROM computers_vnccompany
                                    WHERE computer_name = ?
                                    AND company_name = ?")
            or croak($dbh->errstr);

    # Search available computers and companies
    my @AvailComputers;
    if(!$csth->execute) {
        $dbh->rollback;
    } else {
        while((my $line = $csth->fetchrow_hashref)) {
            push @AvailComputers, $line;
        }
        $csth->finish;
    }
    
    my @AvailCompanies;
    if(!$rsth->execute) {
        $dbh->rollback;
    } else {
        while((my $line = $rsth->fetchrow_hashref)) {
            push @AvailCompanies, $line;
        }
        $rsth->finish;
    }
    
    # Update rights if needed
    if($mode eq "save") {
        my $upsth = $dbh->prepare_cached("SELECT merge_vnccompany(?,?,?)")
                or croak($dbh->errstr);
        foreach my $computer (@AvailComputers) {
            foreach my $company (@AvailCompanies) {
                my $enabled = $cgi->param('vnc_' . $computer->{computer_name} . '_' . $company->{company_name}) || '0';
                if($upsth->execute($computer->{computer_name},
                                   $company->{company_name},
                                   $enabled)) {
                    $upsth->finish;
                    $dbh->commit;
                } else {
                    $dbh->rollback;
                }
            }
        }
    }


    # Read back merged rights from database
    foreach my $computer (@AvailComputers) {
        my @rights;
        foreach my $company (@AvailCompanies) {
            my $enabled = 0;
            if($vsth->execute($computer->{computer_name}, $company->{company_name})) {
                my $line = $vsth->fetchrow_hashref;
                if(defined($line)) {
                    if($line->{is_enabled} == 1) {
                        $enabled = 1;
                    }
                }
                $vsth->finish;
            } else {
                $dbh->rollback;
            }
            my %vright = (
                company    => $company->{company_name},
                val        => $enabled,
            );
            push @rights, \%vright;
        }
        $computer->{rights} = \@rights;
    }

    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{computervnc}->{pagetitle},
        webpath            =>  $self->{computervnc}->{webpath},
        AvailComputers  => \@AvailComputers,
        AvailCompanies  => \@AvailCompanies,
    );    

    my $template = $self->{server}->{modules}->{templates}->get("computerdb/computers_vncedit", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);

}

1;
__END__

=head1 NAME

Maplat::Web::ComputerDB::Computers - manage a list of Computers

=head1 SYNOPSIS

  use Maplat::Web;
  use Maplat::Web::ComputerDB;
  
Then configure() the module as you would normally.

=head1 DESCRIPTION

    <module>
        <modname>globalcomputers</modname>
        <pm>ComputerDB::Computers</pm>
        <options>
            <computerselect>
                <webpath>/computers/computerselect</webpath>
                <pagetitle>Computer Select</pagetitle>
            </computerselect>
            <pdflist>
                <webpath>/computers/pdflist</webpath>
                <logo>/path/to/logo/on/pdf.gif</logo>
            </pdflist>
            <computeredit>
                <webpath>/computers/computeredit</webpath>
                <pagetitle>Computer Edit</pagetitle>
            </computeredit>
            <db>maindb</db>
            <memcache>memcache</memcache>
            <session>sessionsettings</session>
        </options>
    </module>

This module provides the webmasks required to edit and list computers in the database and to print a PDF.

=head2 on_login

Internal function, sets some basic states in every login session.

=head2 get_edit

Internal function, renders the "Edit computer" mask.

=head2 get_vncedit

Internal function, renders the VNC rights managment quickedit mask.

=head2 get_select

Internal function, renders the "List Computers" mask.

=head2 get_pdflist

Internal function, creates the PDF computer list.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
