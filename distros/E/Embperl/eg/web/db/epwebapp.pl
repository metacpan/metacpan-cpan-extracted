

use DBIx::Recordset ;
use Data::Dumper ;
use Embperl::Mail ;
use File::Basename ;
use Embperl::Form::Validate;

BEGIN { Execute ({isa => '../epwebapp.pl', syntax => 'Perl'}) ;  }


sub init
    {
    my $self     = shift ;
    my $r        = shift ;

    my $ret ;

    $r -> {error}   = $fdat{-error} ;
    $r -> {success} = $fdat{-success} ;

    $self -> SUPER::init ($r) ;

    $self -> initdb ($r) ;

    my $db = $r -> {db} ;

    $r->{warning} = [];


    my $login = $self -> checkuser ($r) ;
    if ($config->{always_need_login} && $login < 1)
        {
        $r -> {need_login} = 1 ;
        return ;
	}
    return 0 if ($r->{done}) ;

    # warn "fdat = ", Data::Dumper->Dump ([\%fdat]);

    $r -> {language_set} = DBIx::Recordset -> Search ({'!DataSource' => $db,
                                                       '!Table' => 'language'}) ;

    if ($fdat{-add_category})
        {
        $self -> add_category($r) ;
        $self -> get_category($r, 2) ;
        }
    elsif ($fdat{-add_item})
        {
        $self -> get_category($r, 2) ;
        $ret = $self -> add_item($r) ;
        }
    elsif ($fdat{-update_item})
        {
        $self -> get_category($r, 2) ;
        $ret = $self -> update_item ($r) ;
        }
    elsif ($fdat{-delete_item})
        {
        $self -> get_category($r, 2) ;
        $ret = $self -> delete_item($r) ;
        }
    elsif ($fdat{-edit_item})
        {
        $self -> get_category($r, 2) ;
        $self -> get_item_lang($r) ;
        $self -> setup_edit_item($r) ;
        }
    elsif ($fdat{-show_item})
        {
        $self -> get_category($r, 2) ;
        $self -> get_item_lang($r) ;
        }
    elsif ($fdat{-update_user})
        {
        $self -> update_user($r) ;
	}
    else
        {
        $self -> get_category($r) ;
        $self -> get_item($r) ;
	#$self -> get_user($r);
        }


    #d# if ($r->param->uri =~ m|/user\.epl$|)
    #d#	{
    #	$self -> get_users($r) if $r->{user_admin};
    #	}

    return defined ($ret)?$ret:0 ;
    }


# ----------------------------------------------------------------------------

sub initdb
    {
    my $self     = shift ;
    my $r        = shift ;
    my $config   = $r -> {config} ;

    $DBIx::Recordset::Debug = $config -> {dbdebug} || 1 ;
    *DBIx::Recordset::LOG = \*STDERR ;
    my $db = DBIx::Database -> new ({'!DataSource' => $config -> {dbdsn},
                                     '!Username'   => $config -> {dbuser},
                                     '!Password'   => $config -> {dbpassword},
                                     '!DBIAttr'    => { RaiseError => 1, PrintError => 1, LongReadLen => 32765, LongTruncOk => 0, },

                                     }) ;

    $db -> TableAttr ('*', '!SeqClass', "DBIx::Recordset::FileSeq,$config->{root}/db") if ($^O eq 'MSWin32') ;
    $db -> TableAttr ('*', '!PrimKey', 'id') ;
    $db -> TableAttr ('*', '!Filter',
        {
        'creationtime'  => [\&current_time, undef, DBIx::Recordset::rqINSERT  ],
        'modtime'       => [\&current_time, undef, DBIx::Recordset::rqINSERT + DBIx::Recordset::rqUPDATE ],
        }) ;

    $r -> {db} = $db ;

    }

# ----------------------------------------------------------------------------

sub current_time

    {
    return $_[0] if ($_[0]) ;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                             localtime(time);

    $mon++ ;
    $year += 1900 ;
    return "$year-$mon-$mday $hour:$min:$sec" ;
    }



# ----------------------------------------------------------------------------
#
# Get url for postings forms
#
# $dest = path relativ to current uri
#

sub posturl
    {
    my ($self, $dest) = @_ ;

    my $r = $self -> curr_req ;

    return $dest if (!$r -> {action_prefix}) ;

    my $config = $r->{config} ;
    my $buri = $config -> {baseuri} ;
    $buri .= '/' if (!$buri =~ m#/$#) ;
    my $uri  = $r-> param -> uri ;
    my $path = ($uri =~ /\Q$buri\E(.*?)$/)?$1:$uri ;
    my $lang = (@{$config -> {supported_languages}} > 1)?$r -> param -> language . '/':'' ;

    my $url ;
    if (!$dest)
        {
        $url = $r -> {action_prefix} . $buri . $lang . $path ;
        }
    else
        {
        $path =~ m#^/?(.*)/# ;
        my $dir = $1 ;
        $url = $r -> {action_prefix} . $buri . $lang . $dir . '/' . $dest ;
        }

    return $url ;    
    }



# ----------------------------------------------------------------------------
#
# check if user is loged in, handle login/out and createing of new users
#
# allowed actions parameters:
#   -login
#   -logout
#   -newuser
#   -newpassword
# formfields expected:
#   user_email
#   user_password
#
# returns:
#   undef   not logged in
#   1       user logged in
#   2       admin logged in
#

sub checkuser_light
    {
    my $self     = shift ;
    my $r        = shift ;

    if ($udat{user_id} && $udat{user_email} && !$fdat{-logout})
        {
        $r -> {user_id}    = $udat{user_id} ;
        $r -> {user_email} = $udat{user_email} ;
        $r -> {user_name}  = $udat{user_name} ;
        $r -> {user_admin} = $udat{user_admin} ;
        return $r -> {user_admin}?2:1 ;
        }
    return 0;
    }

sub checkuser
    {
    my $self     = shift ;
    my $r        = shift ;


    if ($udat{user_id} && $udat{user_email} && !$fdat{-logout})
        {
        $r -> {user_id}    = $udat{user_id} ;
        $r -> {user_email} = $udat{user_email} ;
        $r -> {user_name}  = $udat{user_name} ;
        $r -> {user_admin} = $udat{user_admin} ;
        return $r -> {user_admin}?2:1 ;
        }

    if (($fdat{-login} || $fdat{-newuser} || $fdat{-newpassword})
	&& !$fdat{user_email})
        {
        $r -> {error} = 'err_email_needed' ;
        return ;
        }

    my $user ;

    if ($fdat{user_email})
        {
        $user = DBIx::Recordset -> Search ({'!DataSource' => $r -> {db},
                                              '!Table' => 'user',
                                              'email'  => $fdat{user_email}}) ;
        }

    if ($fdat{-login} && $fdat{user_email})
        {
        if ($user -> {id} && $user -> {password} eq $fdat{user_password})
            {
            $r -> {user_id}    = $udat{user_id}    = $user -> {id} ;
            $r -> {user_email} = $udat{user_email} = $user -> {email} ;
            $r -> {user_name}  = $udat{user_name}  = $user -> {user_name} ;
            $r -> {user_admin} = $udat{user_admin} = $user -> {admin} ;
	    $r -> {success} = "suc_login";
            return $r -> {user_admin}?2:1 ;
            }

        $r -> {error} = 'err_access_denied' ;
	$r -> {need_login} = 1 ;
        return ;
        }

    if ($fdat{-logout})
        {
        $r -> {user_id}    = $udat{user_id}    = undef ;
        $r -> {user_email} = $udat{user_email} = undef ;
        $r -> {user_name}  = $udat{user_name}  = undef ;
        $r -> {user_admin} = $udat{user_admin} = undef ;
	$r -> {success} = 'suc_logout';
        return ;
        }

    if ($fdat{-newuser} && $user -> {id})
        {
	$r -> {error} = 'err_user_exists';
        return ;
        }

    if ($fdat{-newpassword} && !$user -> {id})
        {
        $r -> {error} = 'err_user_not_exists' ;
        return ;
        }

    my $user_password = '' ;
    if ($fdat{-newuser} || $fdat{-newpassword})
        {
        my $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-+$!#*=@1234567890-+$!#*=@' ;
        for (my $i = 0; $i < 6; $i++)
            {
            $user_password .= substr($chars, rand(length($chars)), 1) ;
            }
        }


    if ($fdat{-newuser} && $fdat{user_email})
        {
	my @errors_user = ();
	my @errors_admin = ();
        my $set = DBIx::Recordset -> Insert ({'!DataSource' => $r -> {db},
                                              '!Table'      => 'user',
					      'user_name' => $fdat{user_name},
					      'password'    => $user_password,
                                              'email'       => $fdat{user_email}}) ;
	if (DBIx::Recordset -> LastError)
	    {
	    $r -> {error} = 'err_db';
	    $r -> {error_details} = DBIx::Recordset -> LastError;
	    }

        my $usermail = Embperl::Mail::Execute ({
	    inputfile => 'newuser.mail',
	    from => $r->{config}->{emailfrom},
	    to => $fdat{user_email},
	    subject =>  $r->gettext('mail_subj_newuser'),
	    param => [$user_password],
	    errors => \@errors_user});
	if ($usermail)
	    {
	    $r->{error} = 'err_user_mail';
	    $r->{error_details} = join("\n",@errors_user);
	    }
	else
	    {
	    $r->{success} = 'suc_password_sent';
            }

        my $adminmail = Embperl::Mail::Execute ({
	    inputfile => 'newuser.admin.mail',
	    from => $r->{config}->{emailfrom},
	    to => $r->{config}->{adminemail},
	    subject => ($r->{error} ?
			"Error while creating new website user '$fdat{user_email}'" :
			"New website user: $fdat{user_email}"),
	    errors => \@errors_admin});

	if ($adminmail)
	    {
	    $r->{error} = 'err_user_admin_mail';
	    $r->{error_details} = join('; ',@errors_admin);
	    }

        $r -> {done} = 1 ;
	$r -> {need_login} = 1 ;

        return ;
        }

    if ($fdat{-newpassword} && $fdat{user_email})
        {
	my @errors_pw;
        my $set = DBIx::Recordset -> Update ({'!DataSource' => $r -> {db},
                                              '!Table'      => 'user',
					      'password'    => $user_password,
                                              'email'       => $fdat{user_email}},
					     {'id'          => $user -> {id}}) ;

        my $newpw_mail = Embperl::Mail::Execute ({
	    inputfile => 'newpw.mail',
	    from => $r->{config}->{emailfrom},
	    to => $fdat{user_email},
	    subject => $r->gettext('mail_subj_newpw'),
	    param => [$user_password],
	    errors => \@errors_pw});
	if ($newpw_mail)
	    {
	    $r->{error} .= 'err_pw_mail';
	    $r->{error_details} .= join("\n",@errors_pw);
	    }
	else
	    {
	    $r->{success} = 'suc_password_sent';
	    }
        $r -> {need_login} = 1 ;
	$r -> {done} = 1 ;

        return ;
        }

    return ;
    }

# ----------------------------------------------------------------------------

###
### Not yet working with new db-scheme
###

sub add_category
    {
    my $self     = shift ;
    my $r        = shift ;

    if ($self -> checkuser($r) < 2)
        {
        $r -> {need_login} = 1 ;
        return ;
        }

    my $set = DBIx::Recordset -> Insert ({'!DataSource' => $r -> {db},
                                          '!Table'      => 'category',
                                          '!Serial'     => 'id',
                                           state        => 0}) ;
    my $id = $$set -> LastSerial ;
    my $langset = $r -> {language_set} ;
    my $txtset = DBIx::Recordset -> Setup ({'!DataSource' => $r -> {db},
                                            '!Table'      => 'categorytext'}) ;

    $$langset -> Reset ;
    while ($rec = $$langset -> Next)
        {
        $$txtset -> Insert ({category_id => $id,
                             language_id => $rec->{id},
                             category    => $fdat{"category_$rec->{id}"}}) if ($fdat{"category_$rec->{id}"}) ;
        delete $fdat{"category_$rec->{id}"} ;
        }
    }


# ----------------------------------------------------------------------------

sub add_item
    {
    my $self     = shift ;
    my $r        = shift ;

    die "No category" if (!defined ($r->{category_set}{edit_level})) ;

    if ($self -> checkuser($r) < $r->{category_set}{edit_level})
        {
        $r -> {need_login} = 1 ;
        return ;
        }

    # Check the URL

    my $tt = $r->{category_set}{table_type};
    my $cf = $r->{category_fields};
    my $cfnl = $r->{category_fields_nolang};

    foreach ((@$cf, @$cfnl))
    {
	next unless $r->{category_types}{$_} =~ /url/;

	if ($fdat{$_} && $fdat{$_} =~ /\s/)
        {
	    $fdat{$_} =~ s/\s//g;
	    push(@{$r->{warning}}, 'warn_url_removed_white_space');
        }

	if ($fdat{$_} && $fdat{$_} !~ m{http://})
        {
	    $fdat{$_} =~ s{^}{http://};
	    push(@{$r->{warning}}, 'warn_url_added_http');
        }

    }

    my $set = DBIx::Recordset -> Insert ({'!DataSource' => $r -> {db},
                                          '!Table'      => $tt,
                                          '!Serial'     => 'id',
					   (map { $_ => $fdat{$_} } @$cfnl),
                                           url          => $fdat{url},
				           $fdat{modtime} ? (modtime  => $fdat{modtime}) : (),
                                           category_id  => $fdat{category_id},
                                           user_id      => $r -> {user_id},
                                           state        => $r ->{user_admin} ? ($fdat{state}?1:0):0}) ;

    my $id = $$set -> LastSerial ;
    my $langset = $r -> {language_set} ;
    my $txtset = DBIx::Recordset -> Setup ({'!DataSource' => $r -> {db},
                                            '!Table'      => "${tt}text"}) ;

    $$langset -> Reset ;
    while ($rec = $$langset -> Next)
        {
	# Check the URL

	my $lang = $rec->{id};

	foreach (@$cf)
	{
	    next unless $r->{category_types}{$_.'_'.$lang} =~ /url/;

	    if ($fdat{$_.'_'.$lang} && $fdat{$_.'_'.$lang} =~ /\s/)
	    {
		$fdat{$_.'_'.$lang} =~ s/\s//g;
		push(@{$r->{warning}}, 'warn_url_removed_white_space');
	    }

	    if ($fdat{$_.'_'.$lang} && $fdat{$_.'_'.$lang} !~ m{http://})
	    {
		$fdat{$_.'_'.$lang} =~ s{^}{http://};
		push(@{$r->{warning}}, 'warn_url_added_http');
	    }

	}

        $$txtset -> Insert ({ (map { $_ => $fdat{$_.'_'.$lang} || $fdat{$_} } @$cf),
			      "${tt}_id"  => $id,
                              language_id => $lang })
	    if (grep { $fdat{$_.'_'.$lang} || $fdat{$_} } @$cf) ;
        }

    $fdat{"${tt}_id"} = $id ;

    $r->{item_set} = undef ;
    $self->get_item_lang($r);

    if (!$udat{user_admin})
        {
	my @errors;
	my $newitemmail = Embperl::Mail::Execute ({
	    inputfile => 'updateditem.mail',
	    from => $r->{config}->{emailfrom},
	    to => $r->{config}->{adminemail},
	    subject => 'New item on Embperl Website (Category '.$r->{category_set}{category}.')'.($udat{user_email}?" by $udat{user_email}":''),
	    errors => \@errors});
	if ($newitemmail)
            {
	    $r->{error} = 'err_item_admin_mail';
	    $r->{error_details} = join("\n",@errors);

	    return;
            }
        }

    $r->{success} = 'suc_item_created';

    return $self -> redir_to_show ($r) ;
    }

# ----------------------------------------------------------------------------

sub update_item
    {
    my $self     = shift ;
    my $r        = shift ;

    die "No category" if (!defined ($r->{category_set}{edit_level})) ;

    if ($self -> checkuser($r) < $r->{category_set}{edit_level})
        {
        $r -> {need_login} = 1 ;
        return ;
        }

    my $tt = $r->{category_set}{table_type};
    my $cf = $r->{category_fields};
    my $cfnl = $r->{category_fields_nolang};

    # make sure we have an id
    if (!$fdat{"${tt}_id"})
        {
	$r -> {error} = 'err_cannot_update_no_id';
        return ;
        }

    my $set = DBIx::Recordset -> Setup  ({'!DataSource' => $r -> {db},
                                          '!Table'      => $tt }) ;

    # update the entry, but only if it has the correct user id or the has admin rights
    my $rows = $$set -> Select ({ id =>  $fdat{"${tt}_id"},
				  $r ->{user_admin} ? () : (user_id => $r->{user_id}) }) ;
    if ($rows <= 0)
        { # error if nothing was found (this will happen when the record isdn't owned by the user)
        $r -> {error} = 'err_cannot_update_maybe_wrong_user' ;
        return ;
        }

    $$set -> Update ({ url => $fdat{url},
				   (map { $_ => $fdat{$_} } @$cfnl),
				  $fdat{modtime} ? (modtime  => $fdat{modtime}) : (),
				  $fdat{category_id} ? (category_id  => $fdat{category_id}) : (),
				  $r->{user_admin}   ? (state        => $fdat{state})       : () },
				{ id => $fdat{"${tt}_id"},
				  $r ->{user_admin} ? () : (user_id => $r->{user_id}) }) ;


    my $id = $fdat{"${tt}_id"} ;
    my $langset = $r -> {language_set} ;
    my $txtset = DBIx::Recordset -> Setup ({'!DataSource' => $r -> {db},
                                            '!Table'      => "${tt}text"}) ;

    if (DBIx::Recordset->LastError)
        {
	$r -> {error} = 'err_update_db' ;
	return ;
        }

    # Update the texts for every languange, but only if they belong to
    # the item we have updated above

    $$langset -> Reset ;
    while ($rec = $$langset -> Next)
        {
	my $lang = $rec->{id};
        if (grep { $fdat{$_.'_'.$lang} || $fdat{$_} } @$cf)
            {
            $rows = $$txtset -> Search ({"${tt}_id" => $id,
                                         language_id   => $lang
                                         }) ;
            if (DBIx::Recordset->LastError)
	        {
	        $r -> {error} = 'err_update_lang_db' ;
	        return ;
	        }
            elsif ($rows == 0)
                {
                $$txtset -> Insert ({ (map { $_ => $fdat{$_.'_'.$lang} || $fdat{$_} } @$cf),
			          language_id   => $lang,
			          "${tt}_id"    => $id,
			      }) ;

	        if (DBIx::Recordset->LastError)
	            {
	            $r -> {error} = 'err_update_lang_db' ;
	            return ;
	            }
                }
	    else
		{
                $rows = $$txtset -> Update ({ (map { $_ => $fdat{$_.'_'.$lang} || $fdat{$_} } @$cf),
			          language_id => $lang,
			      }, {
			          "${tt}_id" => $id,
			          id         => $fdat{"id_$lang"}
			      }) ;
	        if (DBIx::Recordset->LastError)
	            {
	            $r -> {error} = 'err_update_lang_db' ;
	            return ;
	            }
                }
            }
        }

    $r -> {item_set} = undef ;
    $self->get_item_lang($r) ;

    if (!$udat{user_admin})
        {
	my @errors;
	$r->{is_update} = 1;
	my $newitemmail = Embperl::Mail::Execute ({
	    inputfile => 'updateditem.mail',
	    from => $r->{config}->{emailfrom},
	    to => $r->{config}->{adminemail},
	    subject => 'Updated item on Embperl Website (Category '.$r->{category_set}{category}.')'.($udat{user_email}?" by $udat{user_email}":''),
	    errors => \@errors});
	if ($newitemmail)
            {
	    $r->{error} = 'err_item_admin_mail';
	    $r->{error_details} = join('; ',@errors);

	    return;
            }
        }

    $r->{success} = 'suc_item_updated' ;

    return $self -> redir_to_show ($r) ;
    }


# ----------------------------------------------------------------------------

sub delete_item
    {
    my $self     = shift ;
    my $r        = shift ;

    if (!$self -> checkuser($r))
        {
        $r -> {need_login} = 1 ;
        return ;
        }

    my $tt = $r->{category_set}{table_type};
    my $cf = $r->{category_fields};

    # make sure we have an id
    if (!$fdat{"${tt}_id"})
        {
        $r -> {error} = 'err_cannot_delete_no_id' ;
        return ;
        }

    # first see if the entry exists and has the correct user_id
    my $set = DBIx::Recordset -> Search  ({'!DataSource' => $r->{db},
					   '!Table'      => $tt,
					   id            => $fdat{"${tt}_id"},
					   $r->{user_admin} ? () : (user_id => $r->{user_id}) }) ;

    if (!$$set -> MoreRecords())
        { # error if nothing was found (this will happen when the record isdn't owned by the user
        $r -> {error} = 'err_cannot_delete_maybe_wrong_user_or_no_such_item' ;
        return ;
        }

    # delete the entry, but only if it has the correct user id or the has admin rights
    $$set -> Delete ({id => $fdat{"${tt}_id"},
		      $r ->{user_admin}?():(user_id => $r->{user_id})}) ;

    if (DBIx::Recordset->LastError)
        {
	$r->{error} = 'err_cannot_delete_db_error';
	$r->{error_details} = DBIx::Recordset->LastError;
	return;
        }

    my $id = $fdat{"${tt}_id"} ;
    my $langset = $r -> {language_set} ;
    my $txtset = DBIx::Recordset -> Setup ({'!DataSource' => $r -> {db},
                                            '!Table'      => "${tt}text"}) ;

    # Delete the texts for every languange, but only if they belong to the item we have delete above
    $$langset -> Reset ;
    while ($rec = $$langset -> Next)
        {
        $$txtset -> Delete ({ "${tt}_id" => $id,
			      id         => $fdat{"id_$rec->{id}"}}) ;

	if (DBIx::Recordset->LastError)
            {
	    $r->{error} = 'err_cannot_delete_db_error';
	    $r->{error_details} = DBIx::Recordset->LastError;
	    return;
            }
        }

    if (!$udat{user_admin})
        {
	my @errors;
	$r->{is_update} = -1;
	my $newitemmail = Embperl::Mail::Execute ({
	    inputfile   => 'updateditem.mail',
	    from        => $r->{config}->{emailfrom},
	    to          => $r->{config}->{adminemail},
	    subject     => 'Delete item on Embperl Website (Category '.$r->{category_set}{category}.')'.($udat{user_email}?" by $udat{user_email}":''),
	    errors      => \@errors});
	if ($newitemmail)
            {
	    $r->{error} = 'err_item_admin_mail';
	    $r->{error_details} = join('; ',@errors);

	    return;
            }
        }

    $r->{success} = 'suc_item_deleted' ;

    return $self -> redir_to_show ($r) ;
    }


# ----------------------------------------------------------------------------

sub redir_to_show
    {
    my $self     = shift ;
    my $r        = shift ;

    my $tt = $r->{category_set}{table_type};

    my %params =
        (
        -show_item  => 1,
        $fdat{category_id} ? (category_id => $fdat{category_id}) : (),
        $fdat{"${tt}_id"}  ? ("${tt}_id"  => $fdat{"${tt}_id"})  : (),
        $r -> {error}   ? (-error      => $r -> {error})   : (),
        $r -> {success} ? (-success    => $r -> {success}) : (),
        ) ;

    my $dest = join ('&', map { $_ . '=' . $r -> Escape (ref ($params{$_})?join("\t", @{$params{$_}}):$params{$_} , 2) } keys %params) ;

    my ($uri) = split (/\?/, $r -> param -> unparsed_uri, 1) ;
    $http_headers_out{'location'} = $r -> param -> server_addr . dirname ($uri) ."/show.epl?$dest" ;
    
    return 302 ;
    }



# ----------------------------------------------------------------------------


sub get_category
    {
    my $self     = shift ;
    my $r        = shift ;
    my $edit	 = shift || 0 ;

    $r -> {category_set} = DBIx::Recordset -> Search ({'!DataSource' => $r -> {db},
                                                       '!Table' => 'category, categorytext',
                                                       '!TabRelation' => 'category_id = category.id',
                                                       'language_id'  => $r -> param -> language,
                                                       $fdat{category_id}?(category_id => $fdat{category_id}):(),
                                                       $edit?(edit_level => $r -> {user_admin}?2:1, '*edit_level' => '<='):(),
                                                       $r -> {user_admin} || $edit?():(state => 1)}) ;

    my $level = $r -> {user_admin}?2:1 ;
    my $level_field = $edit?'categoryfields.edit_level':'categoryfields.view_level' ;


    *fields = DBIx::Recordset -> Search ({'!DataSource' => $r -> {db},
					  '!Table' => 'category, categoryfields',
					  '!TabRelation' => 'category_id = category.id',
					  'language_id'  => $r -> param -> language,
					  $fdat{category_id}?(category_id => $fdat{category_id}):(),
                                          $edit?('category.edit_level' => $r -> {user_admin}?2:1, '*category.edit_level' => '<='):(),
					  $level_field => $level,
					  "*$level_field" => '<=',
                                          $r -> {user_admin} || $edit?():(state => 1),
				          '$order' => 'position' }) ;

    my %texts = ();
    my %types = ();
    my %remarks = ();
    my @textfields = ();
    my @textfields_nolang = ();
    my @validate ;

    while (my $field = $fields->Next)
        {
	if ($field->{nolang})
	    {
	    push(@textfields_nolang, $field->{fieldname});
	    }
	else
	    {
	    push(@textfields, $field->{fieldname});
	    }
	$texts{$field->{fieldname}.'_text'} = $field->{txt};
	$types{$field->{fieldname}} = $field->{typeinfo};
	$remarks{$field->{fieldname}} = $field->{remark};
	if ($field -> {validate})
	    {
	    my @tests = split (/[=,]/, $field -> {validate}) ;
            push @validate, ('-key', $field->{fieldname}) ;
	    push @validate, ('-name', $field->{txt}) ;
	    push @validate, @tests ;
	    }	
        }

    $r -> {category_fields} = \@textfields;
    $r -> {category_fields_nolang} = \@textfields_nolang;
    $r -> {category_texts} = \%texts;
    $r -> {category_types} = \%types;
    $r -> {category_remarks} = \%remarks;

    my $title_type = 'heading';
    foreach my $f (@textfields)
	{
	if ($types{$f} =~ /title/)
	    {
	    $title_type = $f;
	    last;
	    }
	}

    $r -> {category_title_type} = $title_type;


    $r -> {validate} = new Embperl::Form::Validate(\@validate, 'form') ;

    }


# ----------------------------------------------------------------------------

sub get_item
    {
    my $self     = shift ;
    my $r        = shift ;
    my %state ;

    if (!$r -> {user_admin})
        {
        if ($r -> {user_id})
            {
            %state = ('$expr' => { '$conj' => 'or', state => 1, user_id => $r -> {user_id} } ) ;
            }
        else
            {
            %state = (state => 1) ;
            }
        }

    my $tt = $r->{category_set}{table_type};


    my $currlang = $r->param->language ;
    my $rec ;
    my %idmap ;
    my @langs ;
    while ($rec = ${$r -> {language_set}} -> Next)
	{
	push @langs, $rec->{id} ;
	}


    ${$r -> {language_set}} -> Reset ;
    @langs = grep {$_ ne $currlang} @langs ;
    push @langs, $currlang ;


    foreach my $lang (@langs)
	{
    	my $set = DBIx::Recordset -> Search ({'!DataSource'  => $r->{db},
						   '!Fields'      => "$tt.id as id, ${tt}text.id as textid",
						   '!Table'       => "user, ${tt}, ${tt}text",
						   '!TabJoin'   => "($tt left join ${tt}text on (${tt}_id = ${tt}.id)), user",
						   '!TabRelation' => "${tt}.user_id = user.id",
						   '$expr1' => {
						   	'language_id'  => $lang,
							'$conj'        => 'or',
							"${tt}_id"     => undef,
							},
						   $fdat{category_id} ? (category_id => $fdat{category_id}) : (),
						   $fdat{"${tt}_id"}  ? ("${tt}_id"  => $fdat{"${tt}_id"})  : (),
						   %state}) ;
       	while ($rec = $$set -> Next)
	    {
	    $idmap{$rec -> {id}} = $rec -> {textid} ;
	    }
	}

    warn 'dbg ' . __LINE__ . "tab = user, ${tt}, ${tt}text;  fields =  *, $tt.id as ${tt}_id; idmap = " . 
                 join (',', keys %idmap) if ($r -> {config}{dbdebug} > 1);
    $r -> {item_set} = DBIx::Recordset -> Search ({'!DataSource'  => $r->{db},
						   '!Fields'      => "*, $tt.id as ${tt}_id",
						   '!Table'       => "user, ${tt}, ${tt}text",
						   '!TabJoin'   => "($tt left join ${tt}text on (${tt}text.${tt}_id = ${tt}.id)), user",
						   '!TabRelation' => "${tt}.user_id = user.id",
						   #"$tt.id" => [keys %idmap],
						   '$expr1' => {
						        '$expr1' => { "${tt}text.id" => [values %idmap], },
						   	#'language_id'  => $currlang,
							'$conj'        => 'or',
							'$expr2' => { "${tt}text.id"     => undef },
							},
						   '!Order'       => $fdat{-order} || 'modtime desc',
						   $fdat{category_id} ? (category_id => $fdat{category_id}) : (),
						   $fdat{"${tt}_id"}  ? ("${tt}_id"  => $fdat{"${tt}_id"})  : (),
						   %state}) ;

    }


# ----------------------------------------------------------------------------

sub get_item_lang
    {
    my $self     = shift ;
    my $r        = shift ;

    my %state ;

    if (!$r -> {user_admin})
        {
        if ($r -> {user_id})
            {
            %state = ('$expr' => { '$conj' => 'or', state => 1, user_id => $r -> {user_id} } ) ;
            }
        else
            {
            %state = (state => 1) ;
            }
        }

    $tt = $r->{category_set}{table_type};

    $r -> {item_set} = DBIx::Recordset -> Search ({'!DataSource'  => $r->{db},
						   '!Fields'      => "*, ${tt}text.id as id, $tt.id as ${tt}_id",
						   '!Table'       => "user, ${tt}, language, ${tt}text",
						   '!TabJoin'   => "($tt left join ${tt}text on (${tt}_id = ${tt}.id)) left join language on (language_id = language.id), user",
						   '!TabRelation' => "${tt}.user_id = user.id",
						   '!Order'       => 'modtime desc',
						   $fdat{category_id} ? (category_id => $fdat{category_id}) : (),
						   $fdat{"${tt}_id"}  ? ("${tt}.id"  => $fdat{"${tt}_id"})  : (),
						   %state}) ;



    $r->{item_set} = undef unless ${$r->{item_set}}->MoreRecords;
    ${$r->{item_set}} -> Reset if ($r->{item_set}) ;

    }

# ----------------------------------------------------------------------------

sub setup_edit_item
    {
    my $self     = shift ;
    my $r        = shift ;

    if (!$self -> checkuser($r))
        {
        $r -> {need_login} = 1 ;
        return ;
        }

    my $set = $r -> {item_set} ;

    unless (defined $set)
        {
	$r->{error} = 'err_item_not_found_or_access_denied';

	return;
	}

    my $tt = $r->{category_set}{table_type};
    my $cf = $r->{category_fields};
    my $cfnl = $r->{category_fields_nolang};

    $fdat{"${tt}_id"} = $set->{"${tt}_id"} if $set->{"${tt}_id"};

    $$set -> Reset ;
    while ($rec = $$set -> Next)
        {
        my $lang = $rec -> {language_id} ;
        $fdat{'id_' . $lang} = $rec -> {id};
        foreach my $type (@$cf)
            {
            $fdat{$type . '_' . $lang} = $rec -> {$type} ;
            }
        foreach my $type (@$cfnl)
            {
            $fdat{$type} = $rec -> {$type} ;
            }
        }

    $$set -> Reset ;
    $r -> {edit} = 1 ;
    }


# ----------------------------------------------------------------------------

sub get_user
    {
    my $self     = shift ;
    my $r        = shift ;

    $fdat{user_id} = undef unless $r -> {user_admin};

    $r -> {user_set} = DBIx::Recordset -> Search ({'!DataSource'  => $r->{db},
						   '!Table'       => "user",
						   id => $fdat{user_id} || $udat{user_id}
						   }) ;
    $r->{user_set} = undef unless ${$r->{user_set}}->MoreRecords;
    }

# ----------------------------------------------------------------------------

sub get_users
    {
    my $self     = shift ;
    my $r        = shift ;

    if ($self -> checkuser_light($r) < 1)
        {
        $r -> {need_login} = 1 ;
        return ;
        }

    return unless $r -> {user_admin};

    $r -> {users} = DBIx::Recordset -> Search ({'!DataSource'  => $r->{db},
						   '!Table'       => "user" }) ;
    $r->{users} = undef unless ${$r->{users}}->MoreRecords;
    }


# ----------------------------------------------------------------------------

sub update_user
    {
    my $self     = shift ;
    my $r        = shift ;

    if ($self -> checkuser_light($r) < 1)
        {
        $r -> {need_login} = 1 ;
        return ;
        }

    unless (($fdat{user_id} == $udat{user_id}) or $r->{user_admin})
	{
	$r->{error} = 'err_cannot_update_wrong_user_xxx';
	return;
	}

    eval { *set = DBIx::Recordset -> Update ({'!DataSource'  => $r->{db},
					      '!Table'       => "user",
					      'user_name' => $fdat{user_name},
					      'pid'  => $fdat{pid} },
					     { id => $fdat{user_id} || $udat{user_id}}) ; };


    if ($@ and $@ =~ 'Duplicate entry')
	{
	$r->{error} = 'err_pid_exists';
	return;
	}

    if (DBIx::Recordset->LastError)
	{
	$r->{error} = 'err_update_db';
	push(@{$r->{error_details}}, DBIx::Recordset->LastError
	     );
	}

    $r->{success} = 'suc_user_update';

    }

# ----------------------------------------------------------------------------
# Warning: This will not yet work as intended if there is more than
# one category using $table as category type!

sub get_title
    {
    my ($self, $r, $col, $id) = @_;

    (my $table = $col) =~ s/_id$// or die "Can't strip '_id' (col=$col)";

    my $config = $r->{config};
    my $db = DBIx::Database -> new ({'!DataSource' => $config -> {dbdsn},
                                     '!Username'   => $config -> {dbuser},
                                     '!Password'   => $config -> {dbpassword},
                                     '!DBIAttr'    => { RaiseError => 1, PrintError => 1, LongReadLen => 32765, LongTruncOk => 0, }});


    # SQL can't handle such kind soft links, so we need two requests
    *fields = DBIx::Recordset -> Search ({'!DataSource'  => $db,
					  '!Table'       => 'category, categoryfields',
					  '!TabRelation' => 'category_id = category.id',
					  'table_type'   => $table,
					  #'state'        => 1,
					  'typeinfo'     => 'title',
					  '*typeinfo'    => 'LIKE',
				          '$order'       => 'position' }) ;

    *set = DBIx::Recordset -> Search ({'!DataSource'  => $db,
				       '!Table'       => $table.'text',
				       'language_id' => $r -> param -> language,
				       $table.'_id'   => $id }) ;


    return $set{$fields{fieldname}};
    }

# ----------------------------------------------------------------------------
# Warning: This will not yet work as intended if there is more than
# one category using $table as category type!

sub get_titles
    {
    my ($self, $r, $table) = @_;

#    *set = DBIx::Recordset -> Search ({'!DataSource'  => $r->{db},
#				       '!Fields'      => "id,$r->{category_title_type} as title",
#				       '!Table'       => $table, }) ;
#    print OUT Dumper $config;
#
#    return;

    my $config = $r->{config};
    my $db = DBIx::Database -> new ({'!DataSource' => $config -> {dbdsn},
                                     '!Username'   => $config -> {dbuser},
                                     '!Password'   => $config -> {dbpassword},
                                     '!DBIAttr'    => { RaiseError => 1, PrintError => 1, LongReadLen => 32765, LongTruncOk => 0, },
                                     }) ;

    # SQL can't handle such kind soft links, so we need two requests
    # warn "tab=\"${table}\"  searching for title\n" ;
    *fields = DBIx::Recordset -> Search ({'!DataSource'  => $db,
					  '!Table'       => 'category, categoryfields',
					  '!TabRelation' => 'category_id = category.id',
					  'table_type'   => $table,
					  #'state'        => 1,
					  'typeinfo'     => 'title',
					  '*typeinfo'    => 'LIKE',
				          '$order'       => 'position' }) ;
    my $title_type = $fields{fieldname};
    # warn "tt=\"$title_type\" tab=\"${table}text\"     ${table}_id as id, $title_type as title" . $fields -> LastSQLStatement . "\n" ;

    *set = DBIx::Recordset -> Search ({'!DataSource' => $db,
				       '!Table'      => $table.'text',
				       'language_id' => $r -> param -> language,
				       '!Fields'     => $table."_id as id, $title_type as title",
				       }) ;


    return \@set;
    }

# ----------------------------------------------------------------------------

sub set_xslt_param
    {
    my ($class, $r, $config, $param) = @_ ;

    $class -> SUPER::set_xslt_param ($r, $config, $param) ;

    my $p = $param -> xsltparam ;
    $p -> {category_id} = $fdat{category_id} || 0 ;
    }



