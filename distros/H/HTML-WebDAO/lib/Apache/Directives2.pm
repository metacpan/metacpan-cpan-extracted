#$Id: Directives2.pm 97 2007-06-17 13:18:56Z zag $

package Apache::Directives2;

use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestUtil;

use Apache2::Const -compile => qw(OR_ALL RAW_ARGS ITERATE TAKE1);
use Apache2::CmdParms  ();
use Apache2::Module    ();
use Apache2::Directive ();
use Data::Dumper;

sub define_d {
    my $name   = shift;
    my $const  = shift;
    my $pkg    = __PACKAGE__;
    my $method = ( $const == Apache2::Const::TAKE1 ) ? 'set_val' : 'set_pars_val';
    my $code   = qq{
    package $pkg;
    sub $name { 
      return \&$method('$name',\@_)
    }
  };
    eval $code;
    die @! if @!;
    return { name => $name, args_how => $const };
}
my @directives = (
    map { &define_d( $_->[0], $_->[1] ) } (
        [ 'wdStore'    => Apache2::Const::TAKE1 ],
        [ 'wdStorePar' => Apache2::Const::RAW_ARGS ],
        [ 'wdSession'  => Apache2::Const::TAKE1 ],
        [ wdSessionPar => Apache2::Const::RAW_ARGS ],
        [ wdIndexFile  => Apache2::Const::TAKE1 ],
    )
);

Apache2::Module::add( __PACKAGE__, \@directives );

sub _SERVER_MERGE { merge(@_) }
sub _DIR_MERGE    { merge(@_) }

sub _parse_str_to_hash {
    my $str = shift;
    my %hash = map { split( /=/, $_ ) } split( /;/, $str );
    foreach ( values %hash ) {
        s/^\s+//;
        s/\s+^//;
    }
    \%hash;
}

sub set_val {
    my ( $name, $self, $parms, $arg ) = @_;
    $self->{$name} = $arg;
}

sub set_pars_val {
    my ( $name, $self, $parms, $arg ) = @_;
    return &set_val( $name, $self, $parms, &_parse_str_to_hash($arg) );
}

sub merge {
    my ( $base, $add ) = @_;
    my %mrg = ();
    die "aaa";
    print STDERR "MERGE:"
      . Dumper( { 'keys %$base' => [ keys %$base ], 'keys %$add' => [ keys %$add ] } );
    for my $key ( keys %$base, keys %$add ) {
        next if exists $mrg{$key};
        $mrg{$key} = $base->{$key} if exists $base->{$key};
        $mrg{$key} = $add->{$key}  if exists $add->{$key};
    }
    return bless \%mrg, ref($base);
}
1;
