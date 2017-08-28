package MYDan::Node::KeySet;

=head1 NAME

MYDan::Node::KeySet - KeySet implementation

=head1 SYNOPSIS

 use MYDan::Node::KeySet;

 my @a = qw( foo foo1 bar1 baz1 );
 my $a = MYDan::Node::KeySet->new()->load( \@a );

 my %b = ( foo => 1, foo2 => 1, bar2 => 1, baz2 => 1 );
 my $b = $a->new()->load( \%b );

 my $c = $a->new()->load( 'foo1', 'foo3' );
 my $d = $a->new()->load( $c );

 $a->add( $b );
 $b->subtract( qr/foo/ );
 $c->intersect( \%b );

 print $a->dump( range => '..' ), "\n";
 
=cut
use strict;
use warnings;
use Carp;

use base qw( MYDan::Node::Object );

=head1 SYMBOLS

range : '~'
 list : ','
 null : '$'

=cut
our %SYMBOL = ( range => '~', null => '$', list => ',' );

sub new
{
    my $class = shift;
    my $self = bless { set => {}, symbol => {} }, ref $class || $class;
}

=head1 DATA METHODS

=head3 get( $o )

Returns a list of elements of a supported object.

=cut
sub get
{
    my ( $self, $o ) = @_;
    my $ref = ref $o;

    return $ref eq 'ARRAY' ? @$o : $ref eq 'HASH' ? keys %$o :
        $ref eq 'Regexp' ? grep { $_ =~ $o } $self->list :
        $self->isa( $ref ) ? $o->list :
        confess( "cannot operate on unknown type: $ref" );
}

=head3 load( $o, %symbol )

Loads from a supported object, or a pair of delimiting elements that
indicate a contiguous range. Symbols may be redefined in %symbol.

=cut
sub load
{
    my ( $self, @o ) = splice @_, 0, 2 + @_ % 2;
    my %symbol = @_;
    $self->{symbol}{null} = $symbol{null} || $SYMBOL{null};

    my @load = @o ? ref $o[0] ? $self->get( @o ) : $self->_range( @o ) : ();
    my $set = $self->{set} = {}; @$set{ @load } = map { 1 } @load;
    return $self;
}

=head3 dump( %symbol )

Serializes to a range expression. Symbols may be redefined in %symbol.

=cut
sub dumpori
{
    my ( $self, %symbol, %sort ) = @_;
    my ( $error, %char ) =
        sprintf "symbols for %s should not have a common character.",
        join ', ', map { "'$_'" } my @symbol = keys %SYMBOL;

    $self->{symbol} = \%SYMBOL;

    for my $name ( @symbol )
    {
        $self->{symbol}{$name} = $symbol{$name} if defined $symbol{$name};
        my %uniq = map { $_ => 1 } split '', $self->{symbol}{$name};
        map { if ( $char{$_} ) { warn $error } else { $char{$_} = 1 } }
            keys %uniq;
    }

    map { $self->_sort( \%sort, [ _token( $_ ) ] ) } $self->list;
    return $self->_string( \%sort );
}

sub dump
{
    my ( $self, %symbol ) = @_;
    my ( $error, %char ) =
        sprintf "symbols for %s should not have a common character.",
        join ', ', map { "'$_'" } my @symbol = keys %SYMBOL;

    $self->{symbol} = \%SYMBOL;

    for my $name ( @symbol )
    {
        $self->{symbol}{$name} = $symbol{$name} if defined $symbol{$name};
        my %uniq = map { $_ => 1 } split '', $self->{symbol}{$name};
        map { if ( $char{$_} ) { warn $error } else { $char{$_} = 1 } }
            keys %uniq;
    }


    my ( $range, $list ) = map{ $self->{symbol}{$_} }qw( range list );

    my ( @data, %data );
    map {
        $_ =~ s/%/@<i>@/g;
        my $n = $_;
        $n =~ s/\d+/\%s/g ? push( @{$data{$n}}, $_ ): push( @data, $n );
    }$self->list;


    while ( my ( $k, $v ) = each %data )
    {
        my ( $key, %key, @ddd, %det ) = ( 0 );
        map{ 
           my @d = $_ =~ /(\d+)/g; push @ddd, \@d; 
           map{ $key{$_}{$d[$_]} = 1 } 0 .. @d -1; 
        }@$v;

        map{
            $key = $_ if ( scalar keys %{$key{$_}} ) > ( scalar keys %{$key{$key}} );
        }keys %key;

        for my $t ( @ddd )
        {
            my $like = sprintf $k, map{ $_ == $key ? '@<DD>@' : $t->[$_] } 0 .. @$t -1;
            push @{$det{$like}}, $t->[$key];
        }

        map
        {
            my ( @id, $id ) = @{$det{$_}};
            if( @id == 1 ) { $id = shift @id; }
            else
            {
                my ( $index, @idd, $tmp ) = ( 0 );
                for( sort { $a <=> $b } @id )
                {
                    $index ++ if defined $tmp && $tmp +1 < $_;
                    push @{$idd[$index]}, $_;
                    $tmp = $_;
                }

                $id = sprintf "{%s}", join $list, 
                    map{ @$_ > 1 ? "$_->[0]~$_->[$#$_]" : $_->[0] }@idd;
            }

            $_ =~ s/@<DD>@/$id/;
            push @data, $_;
        }keys %det;
    }

    map{ s/@<i>@/%/g }@data;

    return join ',', sort @data;
}

=head3 list()

Returns a list of elements.

=cut
sub list
{
    my $self = shift;
    keys %{ $self->{set} };
}

=head3 has( $element )

Determines if object contains I<element>.

=cut
sub has
{
    my $self = shift;
    $self->{set}{ shift @_ };
}

=head1 ARITHMETIC METHODS

( These methods modify the invoking object. )

=head3 add( $o )

Adds a supported object to object.

=cut
sub add
{
    my $self = shift;
    my $set = $self->{set};
    map { $set->{$_} = 1 } $self->get( @_ );
    return $self;
}

=head3 subtract( $o )

Subtracts a supported object from object.

=cut
sub subtract
{
    my $self = shift;
    my $set = $self->{set};
    delete @$set{ $self->get( @_ ) };
    return $self;
}

=head3 intersect( $o )

Intersects with a supported object.

=cut
sub intersect
{
    my $self = shift;
    my $set = $self->{set};
    %$set = map { $_ => 1 } grep { $set->{$_} } $self->get( @_ );
    return $self;
}

=head3 symdiff( $o )

Takes symmetric difference with a supported object.

=cut
sub symdiff
{
    my $self = shift;
    my $set = $self->{set};
    map { if ( $set->{$_} ) { delete $set->{$_} } else { $set->{$_} = 1 } }
        $self->get( @_ );
    return $self;
}

=head3 multiply( $o )

X with a supported object.

=head1 SUPPORTED OBJECTS

I<ARRAY>, I<HASH>, another I<object>, and for arithmetic methods, I<Regexp>.

=cut
sub multiply
{
    my $self = shift;
    my @val = map { 1 } 
    my @key = $self->get( @_ );
    my $set = $self->{set};

    for my $x ( keys %$set )
    {
        delete $set->{$x};
        @$set{ map { $x . $_ } @key } = @val;
    }
    return $self;
}

sub _range
{
    my ( $self, $x, $y ) = @_;
    my $head = my $tail = '';
    return $x eq $self->{symbol}{null} ? $head : $x if $x eq $y;

    my @x = _token( $x );
    my @y = _token( $y );
    return () if @x != @y;

    while ( @x ) ## head
    {
        $x = shift @x; $y = shift @y;
        $head .= $x eq $y ? $x : last;
    }
    return () if $x =~ /\D/ || $y =~ /\D/;

    for my $x ( @x ) { $tail .= $x eq shift @y ? $x : return () }; ## tail
    ( $x, $y ) = ( $y, $x ) if $x > $y; ## sort

    my $len = length $x;
    return () if $len > length $y;

    my ( $x0, $y0 ) = map { length $_ } map { $_ =~ /^(0*)/ } $x, $y;
    return () unless $x0 >= $y0 && ( $len -= $y0 );

    if ( $y0 ) { $head .= 0 x $y0; map { substr $_, 0, $y0, '' } $x, $y }
    return map { $head . $_ . $tail } "$x" .. "$y";
}

sub _sort
{
    my ( $self, $sort, $list ) = @_;
    return unless my $size = @$list;
    my $s = $sort->{ shift @$list } ||= {};
    if ( $size > 1 ) { $self->_sort( $s, $list ) } else { $s->{''} = '' }
}

sub _string
{
    my ( $self, $sort ) = @_;
    my ( %key, %val, @str );
    
    if ( defined $sort->{''} )
    {
        return '' if keys %$sort == 1;
        $sort->{ $self->{symbol}{null} } = delete $sort->{''};
    }

    while ( my ( $key, $val ) = each %$sort )
    {
        $val = $sort->{$key} = $self->_string( $val ) if ref $val;
        push @{ $val{$val} }, $key; 
    }

    while ( my ( $val, $key ) = each %val )
    {
        $key = @$key > 1 ? $self->_join( $key ) : shift @$key if ref $key;
        $key{$key} = $val;
    }

    map { push @str, $_ . $key{$_} } sort keys %key;
    my $str = join $self->{symbol}{list}, @str;
    return @str > 1 ? "\{$str\}" : $str;
}

sub _join
{
    my ( $self, $list ) = @_;
    my ( $R, @str, @cont, %list, %sort, $multi ) = $self->{symbol}{range};

    for my $elem ( @$list )
    {
        if ( $elem =~ /\D/ ) { push @str, $elem }
        else { $list{$elem} = length $elem }
    }

    if ( %list )
    {
        map { push @{ $sort{ $list{$_} } }, $_ } keys %list;

        for my $chars ( sort { $a <=> $b } keys %sort )
        {
            for my $num ( sort { $a <=> $b } @{ $sort{$chars} } )
            {
                if ( @cont )
                {
                    if ( $cont[1] + 1 == $num ) { $cont[1] = $num; next }
                    $multi = $cont[0] != $cont[1];
                    push @str, $multi ? join $R, @cont : shift @cont;
                }

                @cont = ( $num, $num );
            }
        }

        $multi = $cont[0] != $cont[1];
        push @str, $multi ? join $R, @cont : shift @cont;
    }

    my $str = join $self->{symbol}{list}, sort @str;
    return @str > 1 || $multi ? "\{$str\}" : $str;
}

sub _token
{ 
    my ( $string, @token ) = shift;
    push @token, $1 while $string =~ /\G(\d+|\D+)/g;
    return @token;
}

1;
