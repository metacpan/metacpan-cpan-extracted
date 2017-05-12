

# -----------------------------------------------------------------------
#
# verify - prüfen ob alle Eingaben ok sind
#
# ruft für alle Seiten vor der aktuellen die method preverfiy auf
# und für die Seite von der die Daten abgesendet wurden die methode
# verify
#
#   in  $page   index der aktuellen Seite
#   ret         bei Fehler: Seitenobjekt
#               sonst:      undef
#

sub verify
    {
    my ($self, $page, $r) = @_ ;

    my $pages = $self -> {pages} ;
    #my $r = $self -> curr_req ;

    my $i = 0 ;
    while ($i < $page) 
        {
        $pageobj = Execute ({object => $pages -> [$page]}) ;
        $i++ ;
        next if ($pageobj -> can('condition') && !$pageobj -> condition($r)) ;
        next if (!$pageobj -> can('preverify')) ;

        if (!$pageobj -> preverify($r))
            {
            return ($i-1, $pageobj) ;
            }
        }

    $pageobj = Execute ({object => $pages -> [$page]}) ;
    if ($pageobj -> can('verify') && !$pageobj -> verify($r, $self))
        {
        return ($page, $pageobj) ;
        }
    return ;
    }


# -----------------------------------------------------------------------
#
# callpages - ruft eine Methode in allen Seiten auf
#
#   in  $method Name der Methode
#       ...     Argumente
#   ret         Summe der Rückgabewerte
#

sub callpages
    {
    my $self = shift ;
    my $method = shift ;

    my $pages = $self -> {pages} ;
    my $ret = 0 ;
    
    foreach my $page (@$pages)
        {
        my $pageobj = Execute ({object => $page}) ;
        $i++ ;

        next if (!$pageobj -> can($method)) ;

        $ret += $pageobj -> $method (@_) ;
        }

    return ;
    }
    
# -----------------------------------------------------------------------
#
# get_page_to_show - liefert das Seitenobjekt für die anzuzeigende Seite
#
#   in  $page       index der aktuellen Seite
#       $backwards  wenn gesetzt wird rückwärtz geblättert
#

sub get_page_to_show
    {
    my ($self, $page, $step) = @_ ;

    
    my $pages = $self -> {pages} ;
    my $r = $self -> curr_req ;

    while (1) 
        {
        $page += $step ;
        #warn "page=$page, step = $step" ;
        die "Seite nicht verfügbar" if ($page >= @$pages || $page < 0) ;

        $pageobj = Execute ({object => $pages -> [$page]}) ;
        last if (!$pageobj -> can('condition') || $pageobj -> condition($r)) ;
        $step ||= 1 ;
        }

    return ($page, $pageobj) ;
    }

# -----------------------------------------------------------------------


sub init
    {
    my ($self, $r) = @_ ;

    my $cfgobj = $self -> {cfgobj} ||= Execute ({object => 'wizconfig.pl'}) ;

    if ($cfgobj -> can('app_isa'))
	{
	my $isa = $cfgobj -> app_isa ;
	Execute ({isa => $isa}) ;
	}

    $cfgobj -> init($self, $r) if ($cfgobj -> can('init'));

    my $pages  = $self -> {pages}  ||= $cfgobj -> getpages ;

    $r -> {aborturl} = $cfgobj -> can('aborturl') && $cfgobj -> aborturl ;
    if ($fdat{-abort} && $r -> {aborturl})
    	{
	$epreq -> apache_req -> err_header_out('location', $r -> {aborturl}) ;
	
	return 301 ;
    	}

    if ($fdat{-start})
        {
        delete $fdat{-page} ;
        delete $fdat{-prev} ;
        delete $fdat{-next} ;
        delete $fdat{-start} ;
        }

    $r -> {data}    = \%fdat ;

    my $page = $fdat{-page} || 0 ;
    my $showpage = $page ;

    if (!defined ($fdat{-page}) || !(($page, $pageobj) = $self -> verify ($page, $r)))
        {
        ($page, $pageobj) = $self -> get_page_to_show ($showpage, $fdat{-prev}?-1:($fdat{-next}?1:0)) ;
        }

    $r -> {pageobj} = $pageobj ;
    $r -> {page}    = $page ;
    $r -> {pages}   = $pages ;

    $r -> param -> filename ($pages -> [$page]) ;

    my $rc = 0 ;
    $rc = $pageobj -> init($r) if ($pageobj -> can('init'));

    return 0 ;
    }

#------------------------------------------------------------------------------------------
#
#   get_recipe
#

sub get_recipe

    {
    my ($class, $r, $recipe) = @_ ;

    my $self ;
    my $param  = $r -> component -> param  ;
    my ($src)  = $param -> inputfile =~ /^.*\.(.*?)$/ ;

    if ($src eq 'pl')
        {
        $r -> component -> config -> syntax('Perl') ;
        }
   return Embperl::Recipe::Embperl -> get_recipe ($r, $recipe) ;
   }
