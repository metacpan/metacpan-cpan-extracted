
use Embperl::Recipe::XSLT ;
use Embperl::Recipe::Embperl  ;
use Embperl::Recipe::EmbperlXSLT  ;
use Embperl::Recipe::EmbperlPODXSLT  ;
use Embperl::Constant ;

   
sub fill_menu 

    {
    my ($config, $item, $baseuri, $root, $parent) = @_ ;

    foreach $m (@$item)
        {
        $m -> {parent} ||= $parent ;
        $m -> {relurl}  ||= "$baseuri$m->{uri}" ;
        if (ref $m -> {path})
            {
            foreach my $k (keys %{$m -> {path}})
                { 
                if (($m -> {path}{$k} =~ /^\%(.*?)\%/))
                    {
                    if ($config -> {$1}) 
                        {
                        my $val = $config -> {$1} ;
                        $m -> {path}{$k} =~ s/^\%.*?\%/$val/ ; 
                        }
                    else
                        {
                        $m -> {path}{$k} = '' ;
                        }
                    }
                }
            }
        elsif ($m -> {path})
            {
            if (($m -> {path} =~ /^\%(.*?)\%/))
                {
                #warn "path=$m->{path}, 1=$1 c1=$config->{$1}" ;
                if ($config -> {$1}) 
                    {
                    my $val = $config -> {$1} ;
                    $m -> {path} =~ s/^\%.*?\%/$val/ ; 
                    }
                else
                    {
                    $m -> {path} = '' ;
                    }
                }
            }
        elsif (!$m -> {file} && !exists $m -> {path})
            {
            $m -> {path} = $root . $config -> {basepath} . $m -> {relurl} ;
            $m -> {path} .= 'index.htm' if ($m -> {path} =~ m#/$#) ;
            }
        elsif (ref $m -> {file})
            {
            $m -> {path} = { map { $_ => $root . $m->{file}{$_} } keys %{$m->{file}} } ;
            }
        elsif (!exists $m -> {path})
            {
            $m -> {path} = $root . $m->{file} ;
            $m -> {path} .= 'index.htm' if ($m -> {path} =~ m#/$#) ;
            }
        if ($m -> {path})
            {
            $config -> {map1}{$m -> {relurl}} = $m ;
            $config -> {map2}{$1} = $m if ($m  -> {relurl} =~ /^(.*)\./ );
            }

        my $subbase ;
        if ($m -> {relurl} !~ m#/$#)
            {
            $m -> {relurl} =~ /^(.*)\./ ;
            $subbase = "$1/" ;
            }
        else
            {
            $subbase = $m -> {relurl} ;
            }

        fill_menu ($config, $m -> {sub}, $subbase, $root, $m) if ($m -> {sub}) ;        
        fill_menu ($config, $m -> {same}, $baseuri, $root, $parent) if ($m -> {same}) ;        
        }
    }

#
# Add language to uri
#

sub languri
    {
    my ($self, $r, $uri, $lang) = @_ ;

    my $buri = $r->{config}{baseuri} ;
    $lang ||= $r -> {selected_language} ;
    $prefix = $r->{baseuri}  . ($r -> {selected_language}?'../':'') ;
    if ($lang && ($uri =~ /$buri(.*?)$/))
        {
        return "$prefix$lang/$1" ; 
        }

    return $uri ;
    }



sub map_file
    {
    my ($r, $uri) = @_ ;
    my $config = $r -> {config} ;

    # check if we have anything under this uri in our configuration
    #   if it's a directory, try to append index.*
    my $m ;
    $uri =~ /^(.*)\./ ;
    if (!($m = $config -> {map1}{$uri} || $config -> {map2}{$1}))
        {
        $m = $config -> {map1}{$1} if ($uri =~ m#^(.*?/)index\..*$#) ;
        }    

    # if we found something, setup $r -> {menuitem} to hold the menu
    # tree we need to display for this page
    if ($m && $m -> {path})
        {
        my @menuitems = ($m) ;
        my $item = $m ;
        while ($item = $item -> {parent})
            {
            unshift @menuitems, $item ;
            }
        $r -> {menuitems} = \@menuitems ;
        if ($m -> {fdat})
            {
            while (my ($k, $v) = each %{$m -> {fdat}}) 
                {
                $fdat{$k} = $v ;
                }
            }

        $r -> {curritem} = $m ;
        my $path = $m -> {path} ;
        if (ref $path)
            {
            return $path -> {$r -> param -> language} || $path -> {'en'} ;
            }

        return $path ;
        }

    # nothing found
    return ;
    }


sub init 
    {
    my $self     = shift ;
    my $r        = shift ;

    my $config = Execute ({object => 'config.pl', syntax => 'Perl'}) ;

    $config -> new ($r) ;    
    
    $r -> {config} = $config  ;    

    my $uri = $r -> param -> uri ;

    # we embed some parameters in the uri itself, to allow making a
    # static copy, so see if there is anything here
    while ($uri =~ s/\.-(.*?)-(.*?)-\././g)
        {
        $fdat{$1} = $2 ;
        }


    # figure out necessary prefixes, so we can use relativ urls
    my @uri = split (/\//, $uri) ;
    push @uri, '' if ($uri =~ m#/$#) ;
    my $basedepth = $config->{basedepth} + 1 ;
    shift @uri while ($basedepth--) ;
    my $depth = $r -> {depth} = $#uri ;

    $r -> {imageuri} = ('../' x $depth) . $config -> {imageuri} ;
    $r -> {baseuri}  = ('../' x $depth)  ;
    # this is when creating static pages, to let actions point to the correct URL of the dynamic site
    $r -> {action_prefix} = $ENV{ACTION_PREFIX} || '' ; 

    my $langs  = $config -> {supported_languages} ;
    # serach the url, if there is a language embeded,
    # if yes remove it
    $r -> {selected_language} = '' ;
    my  $accept_lang = $r -> param -> language ;
    my  $lang_ok = 0 ;
    foreach (@$langs)
        {
        if ($uri[0] eq $_) 
            {
            $r -> param -> language($_) ;
            $r -> {selected_language} = $_ ;
            shift @uri ;
            $uri =~ s#/$_/#/# ;
            $r -> {baseuri}  = ('../' x ($depth - 1))  ; # we want to stay in the same language tree
            $lang_ok = 1 ;
            last ;
            }
	elsif ($accept_lang && $_ eq $accept_lang)
	    {
	    $lang_ok = 1 ;
	    }
        }

    $r -> param -> uri ($uri) ;
    $r -> param -> language($langs -> [0]) if (!$r -> param -> language || !$lang_ok) ;


    #warn "2 d = $r->{depth} bd = $config->{basedepth}  #uri=$#uri  uri = @uri new uri = $uri" ;

    # get the menu data and create a tree structure out of it if not already done
    $r -> {menu}   = $config -> get_menu ($r) ;    
    fill_menu ($config, $r -> {menu}, '', $config -> {root}) ; ##if (!$config -> {map1}) ;
   

    # map the request uri to the real filename    
    $uri = join ('/', @uri) ;
    $pf = map_file ($r, $uri) ;
    
    # try different location to statisfy links in pod via xslt 
    if (!$pf && ($uri =~ s/doc/intro/))
        {
        $pf = map_file ($r, $uri) ;
        if (!$pf && ($uri =~ s/intro/list/))
            {
            $pf = map_file ($r, $uri) ;
            if (!$pf && ($uri =~ s/list\///))
                {
                $pf = map_file ($r, $uri) ;
                }
            }
        }                            

    # nothing found, so return a general error page
    $pf = "$r->{config}{root}$r->{config}{basepath}notfound.htm" if (!$pf) ;

    $r -> param -> filename ($pf) ;      # tell Embperl the filename
    $r -> apache_req -> filename ($pf) ; # tell Apache the filename

   
    #warn Dumper ($r -> {config}, $r -> param -> uri, $pf, \%fdat, $r -> config -> path) ;
    
    # read in the multi language messages 
    Execute ({inputfile => 'messages.pl', syntax => 'Perl'}) ;

    return 0 ;
    }


sub set_xslt_param
    {
    my ($class, $r, $config, $param) = @_ ;

    $config -> xsltstylesheet('pod.xsl') ;
    my $page = $fdat{page} || 0 ;
    $r -> param -> uri =~ /^.*\/(.*)\.(.*?)$/ ;
    my $p = {
            page      => "'$page'", 
            basename  => "'$1'", 
            extension => "'$2'",
            imageuri  => "'$r->{imageuri}'",
            baseuri   => "'$r->{baseuri}'",
            language  => "'" . $r -> param -> language . "'" , 
            } ;

    $param -> xsltparam($p) ;
    }



sub get_recipe

    {
    my ($class, $r, $recipe) = @_ ;

    my $self ;
    my $param  = $r -> component -> param  ;
    my $config = $r -> component -> config  ;
    my ($src)  = $param -> inputfile =~ /^.*\.(.*?)$/ ;
    my ($dest) = $r -> param -> uri =~ /^.*\.(.*?)$/ ;

   

    if ($src)
        {
        if ($src eq 'pl')
            {
            $config -> syntax('Perl') ;
            return Embperl::Recipe::Embperl -> get_recipe ($r, $recipe) ;
            }

        if ($src eq 'pod' || $src eq 'pm')
            {
            $config -> escmode(0) ;
            if ($dest eq 'pod')
                {
                $config -> syntax('Text') ;
                return Embperl::Recipe::Embperl -> get_recipe ($r, $recipe) ;
                }

            $config -> syntax('POD') ;
            if ($dest eq 'xml')
                {
                return Embperl::Recipe::Embperl -> get_recipe ($r, $recipe) ;
                }

            $class -> set_xslt_param ($r, $config, $param) ;
            return Embperl::Recipe::EmbperlXSLT -> get_recipe ($r, $recipe) ;
            }
    
        if ($src eq 'xml')
            {
            $class -> set_xslt_param ($r, $config, $param) ;
            return Embperl::Recipe::EmbperlXSLT -> get_recipe ($r, $recipe) ;
            }
    
        if ($src eq 'epd')
            {
            $config -> escmode(0) ;
            $config -> options($config -> options | &Embperl::Constant::optKeepSpaces) ;

            if ($dest eq 'pod')
                {
                $config -> syntax('EmbperlBlocks') ;
                return Embperl::Recipe::Embperl -> get_recipe ($r, $recipe) ;
                }


            $class -> set_xslt_param ($r, $config, $param) ;
            return Embperl::Recipe::EmbperlPODXSLT -> get_recipe ($r, $recipe) ;
            }
    
        if ($src eq 'epl' || $src eq 'htm')
            {
            $config -> syntax('Embperl') ;
            return Embperl::Recipe::Embperl -> get_recipe ($r, $recipe) ;
            }

        if ($src eq 'mail')
            {
            $config -> syntax('EmbperlBlocks') ;
            return Embperl::Recipe::Embperl -> get_recipe ($r, $recipe) ;
            }
        }

    $config -> syntax('Text') ;
    return Embperl::Recipe::Embperl -> get_recipe ($r, $recipe) ;
    }
