package MFor;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(&mfor);
our $VERSION = '0.052';

sub mfor(&@);

sub mfor(&@) {
    my $cr = shift;
    my $h_arrs;

    if ( ref( $_[0] ) eq 'ARRAY' and ref( $_[1] ) eq 'ARRAY' ) {
        $h_arrs = shift;    # array
    }

    my $arrs = shift;

    my ( $arr_lev, $arr_idx );
    ( $arr_lev, $arr_idx ) = @_ if (@_);

    $arr_lev ||= 0;
    my $arr_sz = scalar(@$arrs);

    unless ($arr_idx) {
        push @$arr_idx, 0 for ( 1 .. $arr_sz );
    }

    my $cur_arr = $arrs->[$arr_lev];
    my $idx     = scalar(@$cur_arr);
    if ( $arr_sz == $arr_lev + 1 ) {
        my @args = ();
        my $tlev = 0;

        for (@$arr_idx) {
            last if ( !$arrs->[$tlev]->[$_] );
            push @args, $arrs->[$tlev]->[$_];
            $tlev++;
        }

        for my $i ( 0 .. $idx - 1 ) {
            $args[ $tlev - 1 ] = $arrs->[ $tlev - 1 ]->[$i];
            if ($h_arrs) {
                # merge args and hash key to a hash
                my $index = 0;
                my $hash_args = {};
                map { $hash_args->{ $_ } = $args[$index++];  }  @$h_arrs;
                $cr->( $hash_args );
            }
            else {
                $cr->(@args);
            }
        }
    }
    else {

        if ($h_arrs) {
            for my $i ( 0 .. $idx - 1 ) {
                $arr_idx->[$arr_lev] = $i;
                mfor {&$cr} $h_arrs, $arrs, $arr_lev + 1, $arr_idx;
            }
        }
        else {
            for my $i ( 0 .. $idx - 1 ) {
                $arr_idx->[$arr_lev] = $i;
                mfor {&$cr} $arrs, $arr_lev + 1, $arr_idx;
            }
        }
    
        $arr_idx->[$arr_lev] = 0;
    }
}


sub it (@);
sub it (@) {
    if( ref $_[0] ) { # blessed
        my $self = shift;

        if( @_ and ref($_[0]) eq 'HASH' ) {
            my %arr_hash = %{+ shift };
            my ($key) = keys %arr_hash;
            my @values = values %arr_hash;
            $self->_sub_it_hash( $key , @values );
        } else {
            $self->_sub_it( @_ );
        }


        return $self;
    } else {  # unblessed
        # do bless
        my $class = shift;
        my $self = {};
        $self = bless $self , $class;

        $self->{ARRAY} = [];
        if( @_ and ref($_[0]) eq 'HASH' ) {
            my %arr_hash = %{+ shift };
            $self->{HASH_NAME} = [];
            my ($key) = keys %arr_hash;
            my @values = values %arr_hash;
            $self->_sub_it_hash( $key , @values );
        } else {
            $self->_sub_it( @_ );
        }
        return $self;
    }
}

sub _sub_it_hash {
    my $self = shift;
    my ($key,@values) = @_;
    push @{ $self->{HASH_NAME} }, $key;
    push @{ $self->{ARRAY} }, @values;
    return $self;
}

sub _sub_it {
    my $self = shift;
    push @{ $self->{ARRAY} }, [@_];
    return $self;
}


sub when {
    my $self = shift;
    my ($op_and,$op,$op_and2) = @_;
    $self->{COND} = { OP1 => $op_and, OPAND => $op, OP2 => $op_and2 };
    return $self;
}

sub do (&) {
    my $self = shift;
    my $sub  = shift;
    my $array = [ @{ $self->{ARRAY} } ] ;

    if ( defined $self->{HASH_NAME} ) {

        if( defined $self->{COND} ) {

            mfor {
                if ( defined $_[0]->{ $self->{COND}->{OP1} } ) {
                    my $ret;
                    my $eval = sprintf(
                        '$ret = ( %s %s %s ) ? 1 : 0;',
                        $_[0]->{ $self->{COND}->{OP1} },
                        $self->{COND}->{OPAND},
                        $self->{COND}->{OP2}
                    );
                    eval $eval;
                    $sub->(@_) if $ret;
                }
            }   $self->{HASH_NAME}, $array;

        } 

        else {
            mfor { $sub->(@_); } $self->{HASH_NAME}, $array;
        }

    }
    else{
        mfor { 
            $sub->( @_ ); 
        } $array;
    }
    delete $self->{ARRAY};
}


1;

__END__

=head1 NAME

MFor - A module for multi-dimension looping.

=head1 SYNOPSIS

  use MFor;
  mfor {
      my @args = @_;  # get a,x,1 in first loop
      print "Looping..  " , join(',',@_) , "\n";
  }  [
       [ qw/a b c/ ],
       [ qw/x y z/ ],
       [ 1 .. 7 ],
  ];

or

  MFor->it( 1 .. 7 )->it(  'a' ... 'z' )->do( sub {

      # do something 
      my @args = @_;


  });

insteads of:

  for my $a ( qw/a b c/ ) {
    for my $b ( qw/x y z/ ) {
      for my $c (  1 .. 7 ) {
        print "Looping..  " , join(',',$a,$b,$c) , "\n";
      }
    }
  }

=head2 mfor 

    mfor {
        my @args = @_;  # get a,x,1 in first loop
        print "Looping..  " , join(',',@_) , "\n";
    }  [
        [ qw/a b c/ ],
        [ qw/x y z/ ],
        [ 1 .. 7 ],
    ];

=head2 it

iterator with hash reference

    MFor->it({ L1 => qw|a b c| })->it({ L2 =>  qw|X Y Z| })
    ->do(sub {
		my $args = shift;

        print $args->{L1};
        print $args->{L2};


	});

conditon with iterator

    MFor->it({ L1 => qw|a b c| })->when( qw|L1 eq 'a'|  )->do( sub {

        # only do something when L1 equal to 'a'
        my $args = shift;

    })


=head1 DESCRIPTION

This module provides another way to do loop. 

=head2 EXPORT

mfor

=head1 SEE ALSO

=head1 AUTHOR

Lin Yo-An, E<lt>cornelius.howl@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by c9s

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
