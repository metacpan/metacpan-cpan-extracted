$DEBUG = 0;
my $eps = 1e-8;
######### help funcs
sub ok_matrix ($$$)
{
    my ($a, $b, $msg) = @_;
    my $res = abs($a-$b);
    ok( similar($a,$b) , $msg);
    print " (|Delta| = $res)\n" if $DEBUG;
}
sub ok_matrix_orthogonal ($)
{
    my ($M) = @_;
    my $tmp = $M->shadow();
    $tmp->one();
    my $transp = $M->shadow();
    $transp->transpose($M);
    $tmp->subtract($M->multiply($transp), $tmp);
    my $v = $tmp->norm_one();
    ok(($v < $eps), 'matrix is orthogonal');
    print " (|M * ~M - I| = $v)\n" if $DEBUG;
}
sub ok_eigenvectors ($$$;$)
{
    my ($M, $L, $V, $msg) = @_;
    $msg ||= 'eigenvectors computed correctly';
    # Now check that all of them correspond to eigenvalue * eigenvector
    my ($rows, $columns) = $M->dim();
    unless ($rows == $columns) {
        ok(0,'matrix should be square to compute eigenvalues');
        return;
    }
    # Computes the result of all eigenvectors...
    my $test = $M * $V;
    my $test2 = $V->clone();
    for (my $i = 1; $i <= $columns; $i++)
    {
        my $lambda = $L->element($i,1);
        for (my $j = 1; $j <= $rows; $j++)
        { # Compute new vector via lambda * x
            $test2->assign($j, $i, $lambda * $test2->element($j, $i));
        }
      }
    ok_matrix($test,$test2, $msg );
    return;
}
sub similar($$;$) {
    my ($x,$y, $eps) = @_;
    $eps ||= 1e-8;
    abs($x-$y) < $eps ? 1 : 0;
}

sub _debug_info
{
    my($text,$object,$argument,$flag) = @_;

    unless (defined $object)   { $object   = 'undef'; };
    unless (defined $argument) { $argument = 'undef'; };
    unless (defined $flag)     { $flag     = 'undef'; };
    if (ref($object))   { $object   = ref($object);   }
    if (ref($argument)) { $argument = ref($argument); }
    print "$text: \$obj='$object' \$arg='$argument' \$flag='$flag'\n";
}

sub assert_dies($;$)
{
    my ($code,$msg) = @_;
    eval { &$code };
    ok($@, $msg);
}

1;
