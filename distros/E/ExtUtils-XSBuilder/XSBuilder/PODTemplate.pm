
package ExtUtils::XSBuilder::PODTemplate;


# --------------------------------------------------------------------------

sub new 

    {
    my $class = shift ;
    my $self = {} ;    
    bless $self, $class ;
    return $self ;
    }


# --------------------------------------------------------------------------

sub since_default { undef } ;

# --------------------------------------------------------------------------

sub gen_pod_head

    {
    my ($self, $module) = @_ ;

    qq{
    
=head1 NAME

$module

=head1 FUNCTIONS


} ;
    }

# --------------------------------------------------------------------------

sub gen_pod_func

    {
    my ($self, $objclass, $obj, $method, $args, $retclass, $ret, $comment, $since) = @_ ; 

    my $argnames = join (',', map {  $_ -> {name} } @{$args}[($objclass?1:0)..$#$args]) ;
    my $rettext  = $retclass?'$ret = ':'' ;
    my $objtext  = $objclass?"$obj -> ":'' ;

    my $data = qq{

=head2 \@func: $method()

$rettext$objtext $method($argnames)

=over 4

} ;

    foreach $arg (@$args)
        {
        $data .= qq{

=item \@param: $arg->{class} $arg->{name}

$arg->{comment}
} ;
        }

    if ($retclass)
        {
        $data .= qq{

=item \@ret: $retclass

$retcomment
} ;
        }
    
    $data .= qq{

=item \@since: $since

=back

$comment

} ;

    return $data ;
    }




# --------------------------------------------------------------------------

sub gen_pod_struct_member

    {
    my ($self, $objclass, $obj, $memberclass, $member, $comment, $since) = @_ ; 

qq{

=head2 \@func: $member()

\$val = $obj -> $member(\$newval)

=over 4

=item \@param: $objclass $obj

=item \@param: $memberclass \$newval

} .

($since?"=item \@since: $since\n\n":'') .

qq{
=back

$comment

} ;

    }

 1;
