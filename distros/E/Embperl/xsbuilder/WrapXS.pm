package Embperl::WrapXS ;
use strict;
use vars qw{@ISA $VERSION $verbose} ;

use warnings FATAL => 'all';

use ExtUtils::XSBuilder::WrapXS ;

@ISA = ('ExtUtils::XSBuilder::WrapXS') ;

$VERSION = '2.0.0';

# ============================================================================

sub new_parsesource  { [ Embperl::ParseSource->new ] }

# ============================================================================

sub my_xs_prefix  { 'epxs_' }

# ============================================================================

sub h_filename_prefix  { 'ep_xs_' }

# ============================================================================

sub xs_includes  
    { 
    my $self = shift ;

    my $inc = $self -> SUPER::xs_includes ;

    unshift @$inc, "epmacro.h" ;
    unshift @$inc, "ep.h" ;

    return $inc ;
    }


sub xs_map_dir    { "$FindBin::Bin/maps" } ;

sub xs_target_dir { "$FindBin::Bin/../xs" } ;

sub xs_include_dir { "$FindBin::Bin/../xsinclude" } ;

sub trans
    {
    my $name = shift ;

    return $name if ($name !~ /[A-Z]/) ;
    $name =~ s/^.*?([A-Z])/$1/ ;
    $name =~ s/([A-Z]+)/'_' . lc($1)/eg ;
    $name =~ s/^_// ;
    return $name ;
    }



sub mapline_elem

    {
    my ($self, $name) = @_ ;

    my $perl_name = trans ($name) ;

    return "$name | $perl_name" if ($name ne $perl_name) ;
    return $name ;
    }


sub pm_text { undef } ;

sub makefilepl_text {
    my $self = shift ;

    my $code = "local \$mp2cfg ;\nlocal \$ccdebug ;\nlocal \$addcflags;\n" .
                $self -> SUPER::makefilepl_text (@_) ;

    $code .= q[



sub MY::top_targets
	{
	my ($txt) = shift -> MM::top_targets (@_) ;
        $txt =~ s/config\s+pm_to_blib\s+subdirs\s+linkext/\$(O_FILES) subdirs/ ; 
	return $txt ;
	}


sub MY::cflags 
	{
	my $self = shift ;
        
        my $txt = $self -> MM::cflags (@_) ;

        if ($mp2cfg)
            { # with Apache 2, make sure we have the same defines as mod_perl
            $txt =~ s/-O\d//g if ($ccdebug =~ /-O\d/) ;
            $txt =~ /CCFLAGS\s*=(.*?)\n/s ;
	    my $flags = $mp2cfg->{MODPERL_CCOPTS} || $1 ;
            $txt =~ s/CCFLAGS\s*=(.*?)\n/CCFLAGS = $ccdebug $flags $addcflags\n/s ;
            }
        else
            {
            $txt =~ s/-O\d//g if ($ccdebug =~ /-O\d/) ;
	    $txt =~ s/CCFLAGS\s*=/CCFLAGS = $ccdebug $addcflags/ ;
            }

        
        return $txt ;
	}

] ;

    return $code ;
    }

