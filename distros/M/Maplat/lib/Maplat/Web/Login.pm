# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::Login;
use strict;
use warnings;
use 5.012;

use base qw(Maplat::Web::BaseModule);

use Carp;
use Digest::MD5 qw(md5_hex);
use Digest::SHA1 qw(sha1_hex);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::DBSerialize;

use Readonly;

our $VERSION = 0.995;

my $password_prefix = "CARNIVORE::";
my $password_postfix = "# or 1984";
my $ip_postfix = "Grummel42";

Readonly my $TESTRANGE => 1_000_000;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    my %paths;
    $self->{paths} = \%paths;
    
    # Check if user "admin" exists... if it doesn't, create it. This makes
    # testing and initial setup of a database a bit easier. It also serves as
    # a crude backdoor for a sole admin user if he forgot his password: With
    # local access to the database, he only has to delete the table row
    # and it gets recreated with the default password...
    # This feature is normaly disabled in the config file, so editing
    # the config file and restarting the process is required for additional
    # security
    if($self->{check_admin_user} eq "1") {
        my $dbh = $self->{server}->{modules}->{$self->{db}};
        my $getsth = $dbh->prepare_cached("SELECT username FROM users") or croak($dbh->errstr);
        my $insth = $dbh->prepare_cached("INSERT INTO users (username, password_md5, password_sha1, is_admin, email_addr) " .
                                  "VALUES (?, ?, ?, ?, ?)") or croak($dbh->errstr);
        my %users;
        $getsth->execute or croak($dbh->errstr);
        while((my @array = $getsth->fetchrow_array)) {
            $users{$array[0]} = 1;
        }
        $getsth->finish;
        
        if(!defined($users{admin})) {
            my $password = $password_prefix . "admin" . $password_postfix;
            $insth->execute("admin", md5_hex($password), sha1_hex($password), "true", 'rene.schickbauer@gmail.com') or croak($dbh->errstr);
        }
        $dbh->commit;
    }
    
    my @publicurls;
    $self->{publicurls} = \@publicurls;
    
    return $self;
}

sub register {
    my $self = shift;
    
    $self->register_webpath($self->{login}->{webpath}, "get_login");
    $self->register_webpath($self->{logout}->{webpath}, "get_logout");
    $self->register_webpath($self->{pwchange}->{webpath}, "get_pwchange");
    $self->register_webpath($self->{useredit}->{webpath}, "get_useredit");
    $self->register_webpath($self->{viewselect}->{webpath}, "get_viewselect");
    $self->register_webpath($self->{sessionrefresh}->{webpath}, "get_sessionrefresh");
    $self->register_prefilter("prefilter");
    $self->register_postfilter("postfilter");
    $self->register_defaultwebdata("get_defaultwebdata");
    $self->register_prerender("prerender");
    return;
}

sub reload {
    my ($self) = @_;
    # We don't load anything, but we use the opportunity to update our redirect
    # links for our views
    #
    # This can't be done on "new" because at that time not all modules are
    # configured yet. On the other hand, this doesn't change on a regular basis,
    # so completly dynamic handling is not needed
    foreach my $view (@{$self->{viewselect}->{views}->{view}}) {
        my $modname = $view->{startpage};
    
        # use the link as debug output ;-)
        $view->{startlink} = "UNKNOWN/MODULE";
        
        next if(!defined($modname));
        
        foreach my $menu (@{$view->{menu}}) {
            next if($menu->{display} ne $modname);

            # Try to get data directly from the corresponding module
            my ($locmodname, $subvarname, $subsubvarname) = split/\//, $menu->{path};
            $subvarname = "" if(!defined($subvarname));
            $subsubvarname = "" if(!defined($subsubvarname));
                    
            if(defined($self->{server}->{modules}->{$locmodname})) {
                my %mod;
                if($subvarname eq "") {
                    %mod = %{$self->{server}->{modules}->{$locmodname}};
                } elsif($subsubvarname eq "") {
                    %mod = %{$self->{server}->{modules}->{$locmodname}->{$subvarname}};
                } else {
                    %mod = %{$self->{server}->{modules}->{$locmodname}->{$subvarname}->{$subsubvarname}};
                }
                
                if(!defined($mod{webpath})) {
                    $view->{startlink} = "BROKEN/PATH";
                } else {
                    $view->{startlink} = $mod{webpath};
                }
                
            }
        }   
    }
    return;
}

sub get_viewselect {
    my ($self, $cgi) = @_;
    
    my $session = $cgi->cookie("maplat-session");
    
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{pwchange}->{viewselect},
    );
    
    my $user;
    my $newview = $cgi->param('viewname') || '';
    
    if($self->validateSessionID($session, $cgi)) {
        $user = $self->{server}->{modules}->{$self->{memcache}}->get($session);
        $user = $$user;
        if($newview ne "") {
            $user->{view} = "logout"; # Make logout view the default
            $user->{startpage} = $self->{logout}->{webpath};
            foreach my $view (@{$self->{viewselect}->{views}->{view}}) {
                if($newview eq $view->{display} && $user->{$view->{db}}) {
                    $user->{view} = $view->{display};
                    $user->{logoview} = $view->{logodisplay};
                    $user->{startpage} = $view->{startlink};
                }
           }
        }
        
        $self->{server}->{modules}->{$self->{memcache}}->set($session, $user);
        # Redirect to start page of this view
        return (status      => 303,
                location    => $user->{startpage},
                type        => "text/html",
                data         => "<html><body><h1>Changing view</h1><br>" .
                                "If you are not automatically redirected, click " .
                                "<a href=\"" . $user->{startpage} . "\">here</a>.</body></html>",
                );


    } else {
        # Need to login
        return (status      => 303,
                location    => $self->{login}->{webpath},
                type        => "text/html",
                data         => "<html><body><h1>Please login</h1><br>" .
                                "If you are not automatically redirected, click " .
                                "<a href=\"" . $self->{login}->{webpath} . "\">here</a>.</body></html>",
                );
    }
    
}

sub get_logout {
    my ($self, $cgi) = @_;
    
    my $session = $cgi->cookie("maplat-session");
    if(defined($session)) {
        $self->{server}->{modules}->{$self->{memcache}}->delete($session);
        $self->{server}->user_logout($session);
    }
    
    $self->{cookie} = $cgi->cookie({"name" => "maplat-session",
                                    "value" => "NONE",
                                    "expires" => "+10m"});
    
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{logout}->{pagetitle},
        BackLink    =>  $self->{login}->{webpath},
    );
    
    my $template = $self->{server}->{modules}->{templates}->get("logout", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_login {
    my ($self, $cgi) = @_;
    
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{login}->{pagetitle},
        #OnLoad      =>  "document.login.password.focus();", 
        username    =>  $cgi->param('username') || '',
        password    =>  $cgi->param('password') || '',
        PostLink    =>  $self->{login}->{webpath},
    );
    
    my $mode = $cgi->param('mode') || 'username';
    my $host_addr = $cgi->remote_addr();    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $cardid = "";
    
    if($mode eq "chipcard") {
        # First, we need to check if a chipcard is active from that client and get its ID
        my $casth = $dbh->prepare_cached("SELECT card_id FROM cc_activecards
                                  WHERE client_addr = ?")
                or croak($dbh->errstr);
        if(!$casth->execute($host_addr)) {
            $dbh->rollback;
        } else {
            my ($tmpcard) = $casth->fetchrow_array;
            $casth->finish;
            if(defined($tmpcard)) {
                $cardid = $tmpcard;
            }
        }
        
        if($cardid eq "") {
            $mode = "username";
            $webdata{statustext} = "No Chipcard";
            $webdata{statuscolor} = "errortext";
        }
    }
        
    if($mode eq "chipcard") {    
        my $newuser = ""; # in case we need to generate a new user on the fly
        
        # Now, let's check if the card already has a MAPLAT user attached to it...
        my $custh = $dbh->prepare_cached("SELECT username FROM users
                                  WHERE chipcard_id = ?")
                or croak($dbh->errstr);
        if(!$custh->execute($cardid)) {
            $dbh->rollback;
            $cardid = "";
        } else {
            my ($tmpuser) = $custh->fetchrow_array;
            $custh->finish;
            if(defined($tmpuser)) {
                $webdata{username} = $tmpuser;
                $webdata{password} = '?'; # bypass empty password check
            } else {
                # Ok, we need to create a new user with some default settings
                # First, we need the chipcard username
                my $costh = $dbh->prepare_cached("SELECT owner_name
                                          FROM cc_card
                                          WHERE card_id = ?")
                        or croak($dbh->errstr);
                if(!$costh->execute($cardid)) {
                    $dbh->rollback;
                    $cardid = "";
                } else {
                    my ($tmpowner) = $costh->fetchrow_array;
                    $costh->finish;
                    if(defined($tmpowner)) {
                        $newuser = $tmpowner;
                    } else {
                        $cardid = "";
                    }
                }
            }
        }
        
        # Ok, we need to make a new user
        if($cardid ne "" && $newuser ne "") {
            my $nsth = $dbh->prepare_cached("INSERT INTO users
                                     (username, password_sha1, password_md5, has_vnc,
                                      has_chipcardonly, chipcard_id)
                                      VALUES (?, ?, ?, ?, ?, ?)")
                    or croak($dbh->errstr);
            if(!$nsth->execute($newuser, '----', '----', 't', 't', $cardid)) {
                $dbh->rollback;
                $cardid = "";
            } else {
                $dbh->commit;
                $webdata{username} = $newuser;
                $webdata{password} = '?'; # bypass empty password check
            }
        }
    }
    
    if($cardid eq "") {
        $mode = "username";
    }
    
    if($webdata{username} ne '' && $webdata{password} ne '') {
        my @dbRights;
        my %defaultViews;
        foreach my $ur (@{$self->{userlevels}->{userlevel}}) {
            push @dbRights, $ur->{db};
            $defaultViews{$ur->{db}} = $ur->{defaultview};
        }
        my $rightCols = join(", ", @dbRights);
        my $sth;
        
        if($mode eq "username") {
            $sth = $dbh->prepare_cached("SELECT username, email_addr, chipcard_id,
                                           $rightCols
                                           FROM users
                                    WHERE username = ?
                                    AND password_md5 = ?
                                    AND password_sha1 = ?
                                    AND has_chipcardonly = 'false'::boolean")
                        or croak($dbh->errstr);
            
            my $password = $password_prefix . $webdata{password} . $password_postfix;
            $sth->execute($webdata{username}, md5_hex($password), sha1_hex($password));
        } elsif($mode eq "chipcard") {
            $sth = $dbh->prepare_cached("SELECT username, email_addr, chipcard_id, 
                                           $rightCols
                                           FROM users
                                    WHERE username = ?
                                    AND chipcard_id = ?")
                        or croak($dbh->errstr);
            $sth->execute($webdata{username}, $cardid);
        }
        my %user;
        while((my $line = $sth->fetchrow_hashref)) {
            $user{username} = $line->{username};
            $user{email_addr} = $line->{email_addr};
            $user{chipcard_id} = $line->{chipcard_id};
            
            if($line->{chipcard_id} eq "") {
                # User has no chipcard - disable access to VNC since we don't have a company name
                $line->{has_vnc} = 0;
            }
            
            # Default: Set company to a save default of "UNKNOWN"
            # This gets overriden if the user has a chipcard set in his/her profile
            $user{company} = "UNKNOWN";
            
            if($line->{$self->{userlevels}->{admin}}) {
                $user{type} = "admin";
            } else {
                $user{type} = "user";
            }
            
            foreach my $dbright (@dbRights) {
                if($line->{$dbright}) {
                    $user{$dbright} = 1;
                    if(!defined($user{view})) {
                        # the first applicable we find is the default view
                        $user{view} = $defaultViews{$dbright};
                        
                        foreach my $view (@{$self->{viewselect}->{views}->{view}}) {
                            if($user{view} eq $view->{display} && defined($view->{startlink})) {
                                $user{logoview} = $view->{logodisplay};
                                $user{startpage} = $view->{startlink};
                            }
                        }
                        
                    }
                } else {
                    $user{$dbright} = 0;
                }
            }
            
            if(!defined($user{view})) {
                # User has no right, automatically log out again ;-)
                $user{view} = "logout";
                $user{startpage} = $self->{logout}->{webpath};
            }
            last;
        }
        $sth->finish;
        
        if(defined($user{username}) && $user{chipcard_id} ne "") {
            my $comsth = $dbh->prepare_cached("SELECT company_name
                                              FROM cc_card
                                              WHERE card_id = ?")
                    or croak($dbh->errstr);
            if(!$comsth->execute($user{chipcard_id})) {
                $dbh->rollback;
            } else {
                my ($tmpcompany) = $comsth->fetchrow_array;
                $comsth->finish;
                if(defined($tmpcompany)) {
                    $user{company} = $tmpcompany;
                }
            }
        }
        
        $dbh->rollback;
        if(defined($user{username})) {
            my $session = "SESSION" . int(rand($TESTRANGE)) . int(rand($TESTRANGE)) . int(rand($TESTRANGE));
        
            $session .= "-of-" . md5_hex($host_addr . $ip_postfix);
        
            $self->{server}->{modules}->{$self->{memcache}}->set($session, \%user);
            $webdata{statustext} = "Login ok, please wait...!";
            $webdata{statuscolor} = "oktext";
            $webdata{OnLoad} = "document.location.href = '" . $user{startpage} . "';";
            
            $self->{cookie} = $cgi->cookie({"name" => "maplat-session",
                                    "value" => "$session",
                                    "expires" => "+10m"});
            $self->{currentSessionID} = $session;
            $self->{server}->user_login($user{username}, $session);
        } else {
            $webdata{statustext} = "Login error";
            $webdata{statuscolor} = "errortext";
        } 
    }
    
    # Make sure we don't pass out internal data on chipcard mode
    if($mode eq "chipcard") {
        $webdata{username} = "";
        $webdata{password} = "";
    }
    
    my $template = $self->{server}->{modules}->{templates}->get("login", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_pwchange {
    my ($self, $cgi) = @_;
    
    
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{pwchange}->{pagetitle},
        #OnLoad      =>  "document.pwchange.password.focus();", 
        pwold       =>  $cgi->param('pwold') || '',
        pwnew1      =>  $cgi->param('pwnew1') || '',
        pwnew2      =>  $cgi->param('pwnew2') || '',
        PostLink    =>  $self->{pwchange}->{webpath},
    );
    
    my $mode = $cgi->param('mode') || 'view';
    if($mode eq "changepw") {
        if($webdata{pwold} ne "" && $webdata{pwnew1} ne "" && $webdata{pwnew2} ne "") { ## no critic (ControlStructures::ProhibitCascadingIfElse)
            if($webdata{pwnew1} ne $webdata{pwnew2}) {
                $webdata{statustext} = "New Passwords do not match!";
                $webdata{statuscolor} = "errortext";
                $webdata{OnLoad} = "document.pwchange.pwnew1.focus();";
            } else {
                my $oldpw = $password_prefix . $webdata{pwold} . $password_postfix;
                my $newpw = $password_prefix . $webdata{pwnew1} . $password_postfix;
                
                my $dbh = $self->{server}->{modules}->{$self->{db}};
                my $selsth = $dbh->prepare_cached("SELECT username FROM users " .
                                            "WHERE username = ? AND password_md5 = ? and password_sha1 = ?")
                            or croak($dbh->errstr);
                my $oldpwok = 0;
                $selsth->execute($webdata{userData}->{user}, md5_hex($oldpw), sha1_hex($oldpw)) or croak($dbh->errstr);
                while((my @array = $selsth->fetchrow_array)) {
                    $oldpwok = 1;
                }
                $selsth->finish;
                if(!$oldpwok) {
                    $webdata{statustext} = "Old password incorrect!";
                    $webdata{statuscolor} = "errortext";
                    $webdata{OnLoad} = "document.pwchange.pwold.focus();";
                    $dbh->rollback;
                } else {
                    my $upsth = $dbh->prepare_cached("UPDATE users SET password_md5 = ?, password_sha1 = ? " .
                                              "WHERE username = ?")
                                            or croak($dbh->errstr);
                    $upsth->execute(md5_hex($newpw), sha1_hex($newpw), $webdata{userData}->{user}) or croak($dbh->errstr);
                    $upsth->finish;
                    $dbh->commit;
                    $webdata{statustext} = "Password changed!";
                    $webdata{statuscolor} = "oktext";
                    $webdata{pwold} = $webdata{pwnew1};
                }
                
            }
        } elsif ($webdata{pwold} eq "") {
            $webdata{statustext} = "No old password!";
            $webdata{statuscolor} = "errortext";
            $webdata{OnLoad} = "document.pwchange.pwold.focus();";
        } elsif ($webdata{pwnew1} eq "") {
            $webdata{statustext} = "No new password!";
            $webdata{statuscolor} = "errortext";
            $webdata{OnLoad} = "document.pwchange.pwnew1.focus();";
        } elsif ($webdata{pwnew2} eq "") {
            $webdata{statustext} = "New password repetition!";
            $webdata{statuscolor} = "errortext";
            $webdata{OnLoad} = "document.pwchange.pwnew2.focus();";
        }
    }
    
    my $template = $self->{server}->{modules}->{templates}->get("pwchange", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
    
}

sub get_useredit {
    my ($self, $cgi) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};

    my @userLevels;
    my @webUserLevels;
    foreach my $ur (@{$self->{userlevels}->{userlevel}}) {
        push @userLevels, $ur->{db};
        my %ul = (
            name    => $ur->{display},
            id      => $ur->{db},
        );
        push @webUserLevels, \%ul;
    }
    
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{useredit}->{pagetitle}, 
        PostLink    =>  $self->{useredit}->{webpath},
        UserLevels  => \@webUserLevels,
    );
    
    my %adduser = (
        username    =>  $cgi->param('adduser_username') || '',
        pwnew       =>  $cgi->param('adduser_pwnew') || '',
        email       =>  $cgi->param('adduser_email') || '',
        chipcard_id =>  $cgi->param('adduser_chipcard_id') || '',
    );
    my @addurights;
    foreach my $userLevel (@userLevels) {
        my %aur = (
            id  => $userLevel,
            val => $cgi->param('adduser_' . $userLevel) || '',
        );
        push @addurights, \%aur;
    }
    $adduser{rights} = \@addurights;
    $webdata{adduser} = \%adduser;
    
    my $mode = $cgi->param('mode') || 'view';
    if($mode eq "adduser") {
        if($webdata{adduser}->{username} eq "" ||
                $webdata{adduser}->{email} eq "" ||
                $webdata{adduser}->{pwnew} eq "") {
            $webdata{statustext} = "Incomplete form!";
            $webdata{statuscolor} = "errortext";
        } else {
            
            my $addsth = $dbh->prepare_cached("INSERT INTO users (username, password_md5,
                                              password_sha1, email_addr, chipcard_id) " .
                                       "VALUES (?, ?, ?, ?, ?)")
                        or croak($dbh->errstr);
            my $newpw = $password_prefix . $webdata{adduser}->{pwnew} . $password_postfix;
            if(!$addsth->execute($webdata{adduser}->{username}, md5_hex($newpw),
                                sha1_hex($newpw), $webdata{adduser}->{email}, $webdata{adduser}->{chipcard_id})) {
                $webdata{statustext} = "User creation failed: " . $dbh->errstr;
                $webdata{statuscolor} = "errortext";
                $addsth->finish;
                $dbh->rollback;
            } else {

                my $upstatus = 1;
                foreach my $userLevel (@userLevels) {
                    if($upstatus) {
                        my $chsth = $dbh->prepare_cached("UPDATE users SET $userLevel = ?                                      
                                                    WHERE username = ?")
                        or croak($dbh->errstr);
                        
                        my $lval= $cgi->param("adduser_" . $userLevel) || '';
                        if($lval eq "") {
                            $lval = "false";
                        } else {
                            $lval = "true";
                        }
                        
                        if(!$chsth->execute($lval, $webdata{adduser}->{username})) {
                            $webdata{statustext} = "User creation failed: " . $dbh->errstr;
                            $webdata{statuscolor} = "errortext";
                            $chsth->finish;
                            $dbh->rollback;
                            $upstatus = 0;
                        } else {
                            $chsth->finish;
                        } 
                    }            
                }

                if($upstatus) {
                    $addsth->finish;
                    $dbh->commit;
                    $webdata{statustext} = "User created";
                    $webdata{statuscolor} = "oktext";
                }
            }
        }
    } elsif($mode eq "deleteuser") {
        my $username = $cgi->param('username') || '';
        if($username eq "") {
            $webdata{statustext} = "User deletion failed: No Username given";
            $webdata{statuscolor} = "errortext";
        } elsif($username eq $webdata{userData}->{user}) {
            $webdata{statustext} = "User deletion failed: Can't delete own user";
            $webdata{statuscolor} = "errortext";            
        } else {
            my $delsth = $dbh->prepare_cached("DELETE FROM users WHERE username = ?")
                    or croak($dbh->errstr);
            if($delsth->execute($username)) {
                $delsth->finish;
                $dbh->commit;
                $webdata{statustext} = "User deleted";
                $webdata{statuscolor} = "oktext";
            } else {
                $webdata{statustext} = "User deletion failed: " . $dbh->errstr;
                $webdata{statuscolor} = "errortext";
                $delsth->finish;
                $dbh->rollback;                
            }
        }
    } elsif($mode eq "changeuser") {
        my $username = $cgi->param('username') || '';
        my $password = $cgi->param('password') || '';
        my $email = $cgi->param('email_addr') || '';
        my $chipcard_id = $cgi->param('chipcard_id') || '';
        
        my $chsth;
        my $chstatus = 1;
        if($password ne "") {
            $password = $password_prefix . $password . $password_postfix;
            $chsth = $dbh->prepare_cached("UPDATE users SET password_md5 = ?, password_sha1 = ? " .
                                   "WHERE username = ?")
                        or croak($dbh->errstr);
                        
            if(!$chsth->execute(md5_hex($password), sha1_hex($password), $username)) {
                $webdata{statustext} = "Password change failed: " . $dbh->errstr;
                $webdata{statuscolor} = "errortext";
                $chsth->finish;
                $dbh->rollback;
                $chstatus = 0;
            } else {
                $chsth->finish;
            }
        }
        if($chstatus) {
            $chsth = $dbh->prepare_cached("UPDATE users SET email_addr = ?, chipcard_id = ?                                      
                                        WHERE username = ?")
            or croak($dbh->errstr);
            
            if(!$chsth->execute($email, $chipcard_id, $username)) {
                $webdata{statustext} = "User change failed: " . $dbh->errstr;
                $webdata{statuscolor} = "errortext";
                $chsth->finish;
                $dbh->rollback;
                $chstatus = 0;
            } else {
                $chsth->finish;
            } 
        }
        
        foreach my $userLevel (@userLevels) {
            if($chstatus) {
                $chsth = $dbh->prepare_cached("UPDATE users SET $userLevel = ?                                      
                                            WHERE username = ?")
                or croak($dbh->errstr);
                
                my $lval= $cgi->param($userLevel) || '';
                if($lval eq "") {
                    $lval = "false";
                } else {
                    $lval = "true";
                }
                
                if(!$chsth->execute($lval, $username)) {
                    $webdata{statustext} = "User change failed: " . $dbh->errstr;
                    $webdata{statuscolor} = "errortext";
                    $chsth->finish;
                    $dbh->rollback;
                    $chstatus = 0;
                } else {
                    $chsth->finish;
                } 
            }            
        }
        
        if($chstatus) {
            $dbh->commit;
            $webdata{statustext} = "User changed";
            $webdata{statuscolor} = "oktext";
        }
        
    }
    
                
    my $selsth = $dbh->prepare_cached("SELECT *
                                      FROM users " .
                                "ORDER BY username")
                        or croak($dbh->errstr);
    $selsth->execute();
    my @users;
    while((my $user = $selsth->fetchrow_hashref)) {
        my @urights;
        foreach my $userLevel (@userLevels) {
            my %ur = (
                id  =>  $userLevel,
                val =>  $user->{$userLevel},
            );
            push @urights, \%ur;
        }
        
        my %ud = (
            username    =>  $user->{username},
            email_addr  =>  $user->{email_addr},
            chipcard_id =>  $user->{chipcard_id},
            rights      =>  \@urights,
        );
        
        push @users, \%ud;
    }
    $selsth->finish;
    $webdata{users} = \@users;
    
    my $template = $self->{server}->{modules}->{templates}->get("useredit", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}


sub register_publicurl {
    my ($self, $url) = @_;
    
    push @{$self->{publicurls}}, $url;
    return;
}

sub prefilter {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    #warn "User requested path $webpath\n";

    $self->{cookie} = 0;
    $self->{currentData} = undef;
    $self->{currentSessionID} = undef;
    
    if($webpath eq $self->{login}->{webpath} || $webpath eq $self->{logout}->{webpath} ||
       $webpath =~ /^\/(pics|static|logo)\// || $webpath ~~ @{$self->{publicurls}}) {
        # Ok, we need to access our own pages as well as all
        # stuff in /static, /pics and /logo to display the login and logout pages,
        # so don't block them ;-)
        # This also speeds up the process a little bit
        #
        # Also, make sure some (externally) registered public urls are available for
        # everyone
        #
        return;
    }
    
    if($webpath =~ /^\/webapi\//) {
        # All Webapi pages have to do their own user handling if they require it
        return;
    }

    my $session = $cgi->cookie("maplat-session");
    my $user;
    if($self->validateSessionID($session, $cgi)) {
        $user = $self->{server}->{modules}->{$self->{memcache}}->get($session);
        if(defined($user)) {
            $user = dbderef($user);
        }

        if(defined($user)) {
            # Check if the user tries to open something he's not allowed to
            foreach my $ur (@{$self->{userlevels}->{userlevel}}) {
                next if(!defined($ur->{path}));
                my $checkpath = "^" .  $ur->{path};
                if(($webpath =~ /$checkpath/ && !$user->{$ur->{db}})) {
            #warn "Forbidden path $webpath\n";
                    my %deniedwebdata = (
                        $self->{server}->get_defaultwebdata(),
                        PageTitle   =>  $self->{pagetitle},
                        webpath        =>  $webpath,
                        statustext  =>  "Forbidden! You are not allowed to access this page but tried anyway.<br>&nbsp;<br>" .
                                        "Please ask your administrator for mercy (buying a coffee might help)!",
                    );
                    my $template = $self->{server}->{modules}->{templates}->get("forbidden", 1, %deniedwebdata) || $deniedwebdata{statustext};
                    return (status  =>  403,
                            type    => "text/html",
                            data    => $template);
                }
            }
            $self->{cookie} = $cgi->cookie({"name" => "maplat-session",
                                            "value" => $session,
                                            "expires" => "+10m"});
            my %currentData = (sessionid    =>  $session,
                               user         =>  $user->{username},
                               email_addr    =>    $user->{email_addr},
                               company      =>  $user->{company},
                               chipcard_id  =>  $user->{chipcard_id},
                               type         =>  $user->{type},
                               view            =>    $user->{view},
                               logoview        =>    $user->{logoview},
                              );
            
            foreach my $ur (@{$self->{userlevels}->{userlevel}}) {
                $currentData{$ur->{db}} = $user->{$ur->{db}};
            }
            $self->{currentData} = \%currentData;
        } else {
        #warn "No user session data for $session\n";
    }
    } else {
    #warn "Invalid session cookie\n";
    }
    
    if($self->{cookie}) {
        # Refresh the session
        $self->{server}->sessionrefresh($self->{currentData}->{sessionid});
        $self->{currentSessionID} = $session;
        
        return; # No redirection
    } else {
        # Need to login
        return (status      => 303,
                location    => $self->{login}->{webpath},
                type        => "text/html",
                data         => "<html><body><h1>Please login</h1><br>" .
                                "If you are not automatically redirected, click " .
                                "<a href=\"" . $self->{login}->{webpath} . "\">here</a>.</body></html>",
                );
    }
}

sub postfilter {
    my ($self, $cgi, $header, $result) = @_;
    
    # Just add the cookie to the header
    if($self->{cookie}) {
        $header->{cookie} = $self->{cookie};
    }
    
    return;
}

sub get_defaultwebdata {
    my ($self, $webdata) = @_;
    
    if($self->{currentData}) {
        $webdata->{userData} = $self->{currentData};
    }
    return;
}

# Generating the dynamic menu
# This is done during the "prerender" phase, e.g. juuust before
# the template engine starts putting webdata into the templates...
# ...this assures as that we have as much data as possible for getting
# things right. This includes the isActive flags which other modules
# might update in the defaultwebdata phase
sub prerender {
    my ($self, $webdata) = @_;
    
    # Unless the user is logged in, we don't have to generate data
    # for views and menues...
    return if(!$self->{currentData});
    
    # Get list of available Views for this user and generate the current menu bar
    my @userViews;
    my @menuItems;
    foreach my $view (@{$self->{viewselect}->{views}->{view}}) {
        if($self->{currentData}->{$view->{db}}) {
            my $uvclass = $view->{class} || "standard";
            my %tmpuv = (
                name    => $view->{display},
                class   => $uvclass,
            );
            push @userViews, \%tmpuv;
            
            if($view->{display} eq $webdata->{userData}->{view}) {
                # make view
                foreach my $menu (@{$view->{menu}}) {
                    next if($menu->{admin} == 1 && $webdata->{userData}->{type} ne "admin");
                    # some "save" defaults
                    my %menuItem = (
                        DisplayName     => $menu->{display},
                        activeClass     => "rbspageactive",
                        inactiveClass   => "rbspageinactive",
                        link            => "/",
                        isActive        => 0,
                        PageTitle       => "unknown",
                    );
                    
                    if($menu->{admin} == 1) {
                        $menuItem{activeClass} = "admpageactive";
                        $menuItem{inactiveClass} = "admpageinactive";
                    }
                    
                    # Try to get data directly from the corresponding module
                    my ($modname, $subvarname, $subsubvarname) = split/\//, $menu->{path};
                    $subvarname = "" if(!defined($subvarname));
                    $subsubvarname = "" if(!defined($subsubvarname));
                    
                    if(!defined($self->{server}->{modules}->{$modname})) {
                        # use the link as debug output ;-)
                        $menuItem{link} = "UNKNOWN/MODULE";
                    } else {
                        my %mod;
                        if($subvarname eq "") {
                            %mod = %{$self->{server}->{modules}->{$modname}};
                        } elsif($subsubvarname eq "") {
                            %mod = %{$self->{server}->{modules}->{$modname}->{$subvarname}};
                        } else {
                            %mod = %{$self->{server}->{modules}->{$modname}->{$subvarname}->{$subsubvarname}};
                        }
                        
                        if(!defined($mod{webpath})) {
                            $menuItem{link} = "BROKEN/PATH";
                        } elsif(!defined($mod{pagetitle})) {
                            $menuItem{link} = "NO/pagetitle/FOUND";
                        } else {
                            $menuItem{link} = $mod{webpath};
                            $menuItem{PageTitle} = $mod{pagetitle};
                            if(defined($menu->{checkvar})) {
                                if(defined($webdata->{$menu->{checkvar}}) &&
                                        $webdata->{$menu->{checkvar}} ne "") {
                                    $menuItem{isActive} = 1;
                                }
                            } elsif(!defined($mod{isActive}) || $mod{isActive}) {
                                $menuItem{isActive} = 1;
                            }
                            
                            if(defined($menu->{warnvar})) {
                                if(defined($webdata->{$menu->{warnvar}}) &&
                                   $webdata->{$menu->{warnvar}} > 0) {
                                    $menuItem{warning} = $webdata->{$menu->{warnvar}};
                                }
                            }
                        }
                    }
                    
                    # Now, set the actual rendering class, so the Template don't
                    # has to (makes template a bit more readable)
                    if(defined($webdata->{PageTitle}) && $webdata->{PageTitle} eq $menuItem{PageTitle}) {
                        $menuItem{Class} = $menuItem{activeClass};
                    } else {
                        $menuItem{Class} = $menuItem{inactiveClass};
                    }
                    
                    push @menuItems, \%menuItem;
                    
                }
            }
        }
    }
    
    $webdata->{userViews} = \@userViews;
    $webdata->{menuItems} = \@menuItems;
    return;
}

sub validateSessionID {
    my ($self, $session, $cgi) = @_;
    
    if(!defined($session) || $session eq "NONE") {
    #warn "No session cookie: $session\n";
    return 0; # Invalid session
    }
    
    my $client_checksum = "";
    if($session =~ /\-of\-(.*)/) {
    $client_checksum = $1;
    } else {
    #warn "Session ID missing from cookie: $session\n";
    return 0; # Session ID missing Client IP checksum
    }
    
    my $host_addr = $cgi->remote_addr();
    my $host_checksum =  md5_hex($host_addr . $ip_postfix);
    if($host_checksum eq $client_checksum) {
    return 1; # Client-IP checks out
    } else {
    #warn "Cookie checksum wrong: my $host_checksum your $client_checksum your ip: $host_addr\n";
    return 0; # Burn in hell for faking the client IP checksum
    }
}

sub get_sessionid {
    my ($self) = @_;
    
    return $self->{currentSessionID};
}

sub get_sessionrefresh {
    my ($self, $cgi) = @_;
    
    # we just return the current time, everything else is done by prefilter ;-)
    return (status      => 200,
        type        => "text/plain",
        data         => getISODate(),
        );
}

1;
__END__

=head1 NAME

Maplat::Web::Login - this module handles login, user managment and views

=head1 SYNOPSIS

This modules provides a complete user managment, including login handling, views and a few
other gimmicks.

=head1 DESCRIPTION

This module is currently documented somewhat poorly (it was hacked together over a few months). Basically, you have to play around
with the configuration and take a peek at the source code.

We're sorry for that!

=head1 Configuration

        <!-- Login module -->
        <module>
                <modname>authentification</modname>
                <pm>Login</pm>
                <options>
                        <db>maindb</db>
                        <memcache>memcache</memcache>
                        <sendmail>sendmail</sendmail>
                        <expires>+1h</expires>

                        <!-- Setting this flag to 1 enables the login module to
                                re-create the "admin" user if the table row does not
                                exist in the database - normally disabled because it
                                *might* be a security risk under certain circumstances -->
                        <check_admin_user>0</check_admin_user>

                        <userlevels admin="is_admin">
                                <!-- Highest to lowest, first applicable will be used
                                        as the users default view -->
                                <userlevel display="Admin" db="is_admin" defaultview="Admin" path="/admin/" />
                                <userlevel display="RBS" db="has_rbs" defaultview="RBS" path="/rbs/" />
                                <userlevel display="WDNE" db="has_wdne" defaultview="WDNE" path="/wdne/" />
                                <userlevel display="Chipcard" db="has_chipcard" defaultview="Chipcard" path="/chipcard/" />
                                <userlevel display="AFM" db="has_afm" defaultview="AFM Parameters" path="/afm/" />
                                <userlevel display="CC WebAPI" db="has_ccwebapi" defaultview="Chipcard WebAPI" path="/ccwebapi/" />
                                <userlevel display="Dev Test" db="has_devtest" defaultview="Dev: Docs" path="/devtest/" />
                        </userlevels>

                        <login>
                                <webpath>/user/login</webpath>
                                <pagetitle>Login</pagetitle>
                        </login>
                        <logout>
                                <webpath>/user/logout</webpath>
                                <pagetitle>Logout</pagetitle>
                        </logout>
                        <pwchange>
                                <webpath>/user/pwchange</webpath>
                                <pagetitle>Change Password</pagetitle>
                        </pwchange>
                        <useredit>
                                <webpath>/admin/useredit</webpath>
                                <pagetitle>Users</pagetitle>
                        </useredit>
                       <sessionrefresh>
                                <webpath>/user/sessionrefresh</webpath>
                                <pagetitle>Sessionrefresh</pagetitle>
                        </sessionrefresh>
                        <viewselect>
                                <webpath>/user/viewselect</webpath>
                                <pagetitle>Changing view</pagetitle>
                                <views>
                                        <view display="Admin" logodisplay="admin" path="/admin/"
                                                  db="is_admin" startpage="Commands" class="admin">
                                                <menu display="Status" path="rbsstatus/" admin="1" />
                                                <menu display="Commands" path="command/" admin="1" />
                                                <menu display="ProdLines" path="prodlines/admin" admin="1" />
                                                <menu display="DirCleaner" path="dircleaner/" admin="1" />
                                                <menu display="Sendmail" path="sendmail/" admin="1" />
                                                <menu display="Variables" path="variablesadm/" admin="1" />
                                                <menu display="Users" path="authentification/useredit" admin="1" />
                                        </view>
                                        <view display="CC WebAPI" logodisplay="admin" path="/ccwebapi/"
                                                  db="is_admin" startpage="Cards" class="admin">
                                                <menu display="Cards" path="ccwebapi/getcards" admin="0" />
                                        </view>
                                        <view display="Dev: Docs" logodisplay="devtest" path="/devtest/"
                                                  db="has_devtest" startpage="Text" class="devel">
                                                <menu display="Text" path="docswordprocessor/list" admin="0" />
                                                <menu display="Table" path="docsspreadsheet/list" admin="0" />
                                                <menu display="Search" path="docssearch/" admin="1" />
                                        </view>
                                </views>
                        </viewselect>
                </options>
        </module>

=head2 register_publicurl

Takes one argument. Register additional public URLS (need to be the FULL path).

=head2 get_login

Internal function.

=head2 get_logout

Internal function.

=head2 get_pwchange

Internal function.

=head2 get_sessionid

Internal function.

=head2 get_sessionrefresh

Internal function.

=head2 get_useredit

Internal function.

=head2 get_viewselect

Internal function.

=head2 postfilter

Internal function.

=head2 prefilter

Internal function.

=head2 prerender

Internal function. Blocks all unauthorized access.

=head2 validateSessionID

Internal function.

=head1 TODO

Get this module properly documented.

=head1 SEE ALSO

Maplat::Web

"If unsure, see source code or email the author"

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
