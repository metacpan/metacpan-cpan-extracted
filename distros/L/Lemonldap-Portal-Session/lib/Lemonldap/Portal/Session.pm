package Lemonldap::Portal::Session;

use strict;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lemonldap::Portal::Session ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(

          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.02';

# Preloaded methods go here.

my $parser = {
    'ATOM' => sub {
        my $val = shift;
        return $val;
    },
    'FRACT' => sub {
        my ( $val, $sep, $rg ) = @_;
        my @tab = split $sep, $val;
        return $tab[$rg];
    },
    'EXP' => \&replace,
};

sub tokens {
    my $target = shift;
    return sub {
        return [ 'ATOM', $1, $parser->{'ATOM'} ] if $target =~ /\G ([^%]+) /gcx;
        return [ 'EXP',  $1, $parser->{'EXP'} ]  if $target =~ /%(.+)%/gcx;
        return [ 'NOHUP', '', '' ] if $target =~ /\G \s+ /gcx;

    };

}

sub replace {
    my ( $param, $exp, $entry ) = @_;
    my %tmp = %$exp;
    my ( $chaine, $sep, $pos );
    unless ( $tmp{$param} ) {
        $sep   = substr( $param, -2, 1 );
        $pos   = substr( $param, -1, 1 );
        $param = substr( $param, 0,  -2 );
    }
    $chaine = $tmp{$param}->{valeur}
      if ( lc( $tmp{$param}->{type} ) ) eq 'constant';
    $chaine = $entry->dn() if ( lc( $tmp{$param}->{type} ) ) eq 'dnentry';
    my @tmp_attr;
    my @tchaine;
    @tmp_attr = $entry->get_value( $tmp{$param}->{attribut} )
      if ( lc( $tmp{$param}->{type} ) ) eq 'attrldap';
    if ( $#tmp_attr == 0 ) {
        $chaine = shift @tmp_attr;
        $chaine = $parser->{'FRACT'}( $chaine, $sep, $pos ) if $sep;
    }

    else {
        foreach (@tmp_attr) {
            $chaine = $_;
            $chaine = $parser->{'FRACT'}( $chaine, $sep, $pos ) if $sep;
            push @tchaine, $chaine;

        }

    }
    return \@tchaine if @tchaine;
    return $chaine;
    1;

}

sub analyse {
    my ( $ligne, $exp, $entry ) = @_;
    my @res;
    my $iter = tokens($ligne);
    my $ref;
    while ( $ref = $iter->() ) {
        push @res, $ref;
    }
##  now I resolv all %exp%
    foreach (@res) {

        $_->[1] = $_->[2]( $_->[1], $exp, $entry );

        #next if ($_->[0] eq 'ATOM' ) ;
    }
    my $chaine;
    foreach (@res) {
        $chaine .= $_->[1] if $_->[1];

    }
    return $chaine;
}

sub analyse_multi {
    my ( $ligne, $exp, $entry ) = @_;
    my @res;
    my $iter = tokens($ligne);
    my $ref;
    while ( $ref = $iter->() ) {
        push @res, $ref;
    }
##  now I resolv all %exp%
    my @chaines;
    foreach (@res) {

        $_->[1] = $_->[2]( $_->[1], $exp, $entry );

        #next if ($_->[0] eq 'ATOM' ) ;
        #    print "pause\n";
    }
    my $cp = 0;
    foreach (@res) {
        if ( ref $_->[1] ) {
            my @t = @{ $_->[1] };
            $cp = $#t + 1;

        }   
	else {  
      # correction bug multi on one line 
            my @t;
	    $t[0] =  $_->[1] ;
	    $cp = $#t + 1;
	}
    }
    my $i;
    my @tchaine;
    for ( $i = 0 ; $i < $cp ; $i++ ) {
        my $c;
        foreach (@res) {
            if ( ref $_->[1] ) {
                $c .= $_->[1]->[$i];
            }
            else { $c .= $_->[1]; }

        }
        push @tchaine, $c;
    }

    return \@tchaine;
}

sub init {
## declaration #########
## grammar ##

    my $dict = {
        'single' => sub {
            ( my $param1, my $param2, my $expr, my $entry ) = @_;
            return (
                &analyse( $param1, $expr, $entry ),
                &analyse( $param2, $expr, $entry )
            );
        },
        'multi' => sub {
            ( my $param1, my $param2, my $expr, my $entry ) = @_;
            return (
                &analyse_multi( $param1, $expr, $entry ),
                &analyse_multi( $param2, $expr, $entry )
            );
        },

    };

    my $class = shift;
    my %args;
    if ( ref( $_[0] ) ) {
        my $rf = shift @{ $_[0] };
        foreach ( keys %$rf ) {
            $args{$_} = $rf->{$_};

        }
        shift @_;
    }
    foreach ( ( my $cle, my $val ) = (@_) ) {

        $args{$cle} = $val;
    }
    my $self = bless {

      },
      ref($class) || $class;
    %$self = ( %$self, %args );

    #    return $self;

    my %_session;
    foreach ( keys( %{ $self->{ligne} } ) ) {
        my %_tsession;
        my $tmp = $self->{ligne}{$_};
        $tmp->{_traitement} = $dict->{ $tmp->{type} };

        my @res = (
            $tmp->{_traitement}( $tmp->{cle}, $tmp->{valeur}, $self->{exp},
                $self->{entry} ) );
        if (@res) {
            if ( ref( $res[0] ) ) {
                foreach ( @{ $res[0] } ) {
                    $_tsession{$_} = shift @{ $res[1] };
                }
            }
            else {

                $_tsession{ $res[0] } = $res[1] || 'NULL';
            }
        }
        if ( $tmp->{primarykey} ) {
            $_session{ $tmp->{primarykey} } = \%_tsession;
        }
        else { @_session{ keys %_tsession } = values %_tsession; }
    }

    return \%_session;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lemonldap::Portal::Session - Perl extension for Lemonldap websso

=head1 SYNOPSIS

  use Lemonldap::Portal::Session;

  my $paramxml = $test->{DefinitionSession} ; # $test is the result of XML  parsing 
  my $obj = Lemonldap::Portal::Session->init ($paramxml,'entry' =>$entry) ;
  


=head1 example :


   XML input :

 <DefinitionSession>
	<ligne  id = "commentaire" 
		type = "single"
		cle ="commentaire"
		valeur= "mon commentaire est %buffer% merci"> 
	</ligne>
	<ligne  id = "mail" 
		type = "single"
		cle ="mail"
		valeur= "%mail%" >
	</ligne>
	<ligne  id = "roleprofil" 
		type = "single"
		cle ="%roleprofil;0%"
		valeur= "%roleprofil;1%" >
	</ligne>
	<ligne  id = "mefiapplicp" 
		type = "multi"
		cle ="%mefiapplicp;0%"
		primarykey="cp" 
		valeur= "%mefiapplicp;1%" >
	</ligne>
	
	<ligne  id = "dn" 
		type = "single"
		cle ="dn"
		valeur= "%dn%" >
	</ligne>

	<exp    id ="dn" 
	        type= "dnentry"
	      />
	<exp    id ="buffer" 
	        type= "constant"
		valeur=" ce  que je veux "
		/>
	
	<exp    id ="mail" 
	        type= "attrldap"
	        attribut= "mail" />

	<exp    id ="roleprofil" 
	        type= "attrldap"
	        attribut= "roleprofil" />
	<exp    id ="mefiapplicp" 
	        type= "attrldap"
	        attribut= "mefiapplicp" />
	
	
 </DefinitionSession>
 
after processing :

 Dumper ($obj) :

 $VAR1 = {
          'appli' => 'etoile',
          'commentaire' => 'mon commentaire est  ce  que je veux  merci',
          'mail' => 'germanlinux@yahoo.fr',
          'cp' => {
                  'appli1' => 'etoile1',
                  'appli2' => 'etoile2'
                },
          'dn' => 'uid=egerman-cp,ou=personnes,ou=cp,dc=demo,dc=net'
        };




=head1 DESCRIPTION

Lemonldap::Portal::Session is a parser of XML description of session to keys,values of hash .

It is a piece of lemonldap  websso framework .
see 'eg'  directory for implementation .
 

=head1 SEE ALSO

Lemonldap(3), Lemonldap::NG::Portal

http://lemonldap.sourceforge.net/


=head1 AUTHOR

Eric German, E<lt>germanlinux@yahoo.frE<gt>


=head1 COPYRIGHT AND LICENSE


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

Copyright (C) 2004 by Eric German E<amp> Xavier Guimard E<amp> Isabelle Serre

Lemonldap originaly written by Eric german who decided to publish him in 2003
under the terms of the GNU General Public License version 2.

=over 1

=item This package is under the GNU General Public License, Version 2.

=item The primary copyright holder is Eric German.

=item Portions are copyrighted under the same license as Perl itself.

=item Portions are copyrighted by Doug MacEachern and Lincoln Stein.
This library is under the GNU General Public License, Version 2.

=item Portage under Apache2 is made with help of : Ali Pouya and 
Shervin Ahmadi (MINEFI/DGI) 



=cut
