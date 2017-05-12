package Test::ListCompareSpecial;
# Contains test subroutines for distribution with List::Compare
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
    ok_capture_error ok_seen_a  ok_seen_h ok_any_h _capture
    getseen unseen
    wrap_is_member_which
    all_is_member_which
    func_all_is_member_which
    func_all_is_member_which_ref
    func_all_is_member_which_alt
    func_all_is_member_which_ref_alt
    wrap_is_member_which_ref
    all_is_member_which_ref
    wrap_are_members_which
    wrap_is_member_any
    all_is_member_any
    func_all_is_member_any
    func_all_is_member_any_alt
    wrap_are_members_any
    make_array_seen_hash
    @a0 @a1 @a2 @a3 @a4             @a8
    %h0 %h1 %h2 %h3 %h4 %h5 %h6 %h7 %h8
    $test_member_which_dual
    $test_member_which_mult
    $test_members_which
    $test_member_any_dual
    $test_member_any_mult
    $test_members_any
    $test_members_any_mult
    $test_members_which_mult
    func_wrap_is_member_which
    func_wrap_is_member_which_ref
    func_wrap_are_members_which
    func_wrap_is_member_any
    func_wrap_are_members_any
 );
our %EXPORT_TAGS = (
    seen => [ qw(
        ok_capture_error ok_seen_a  ok_seen_h ok_any_h _capture
        getseen unseen
        make_array_seen_hash
    ) ],
    wrap => [ qw(
        wrap_is_member_which
        all_is_member_which
        wrap_is_member_which_ref
        all_is_member_which_ref
        wrap_are_members_which
        wrap_is_member_any
        all_is_member_any
        wrap_are_members_any
    ) ],
    hashes => [ qw(
        %h0 %h1 %h2 %h3 %h4 %h5 %h6 %h7 %h8
    ) ],
    arrays => [ qw(
        @a0 @a1 @a2 @a3 @a4             @a8
    ) ],
    func_wrap => [ qw(
        func_wrap_is_member_which
        func_wrap_is_member_which_ref
        func_all_is_member_which_ref_alt
        func_all_is_member_which_alt
        func_wrap_are_members_which
        func_wrap_is_member_any
        func_wrap_are_members_any
        func_all_is_member_which
        func_all_is_member_which_ref
        func_all_is_member_any
        func_all_is_member_any_alt
    ) ],
    results => [ qw(
        $test_member_which_dual
        $test_member_which_mult
        $test_members_which
        $test_member_any_dual
        $test_member_any_mult
        $test_members_any
        $test_members_any_mult
        $test_members_which_mult
    ) ],
);
use List::Compare::Functional qw(
    is_member_which
    is_member_which_ref
    is_member_any
);

sub ok_capture_error {
    my $condition = shift;
    print "\nIGNORE PRINTOUT above during 'make test TEST_VERBOSE=1'\n        testing for bad values\n";
    return $condition;
}

sub ok_seen_h {
    die "Need 4 arguments: $!" unless (@_ == 4);
    my ($mhr, $arg, $quant_expect, $expected_ref) = @_;
    my (%seen, $score);
    $seen{$_}++ foreach (@{${$mhr}{$arg}});
    $score++ if (keys %seen == $quant_expect);
    foreach (@{$expected_ref}) {
        $score++ if exists $seen{$_};
    }
    $score == 1 + scalar(@{$expected_ref})
        ? return 1
        : return 0;
}

sub ok_seen_a {
    die "Need 4 arguments: $!" unless (@_ == 4);
    my ($mar, $arg, $quant_expect, $expected_ref) = @_;
    my (%seen, $score);
    $seen{$_}++ foreach (@{$mar});
    $score++ if (keys %seen == $quant_expect);
    foreach (@{$expected_ref}) {
        $score++ if exists $seen{$_};
    }
    $score == 1 + scalar(@{$expected_ref})
        ? return 1
        : return 0;
}

sub ok_any_h {
    die "Need 3 arguments: $!" unless (@_ == 3);
    my ($mhr, $arg, $expected) = @_;
    exists ${$mhr}{$arg} and ${$mhr}{$arg} == $expected
        ? return 1
        : return 0;
}

sub _capture { my $str = $_[0]; }

sub getseen {
    my $allref = shift;
    my @arr = @$allref;
    my (@seen);
    for (my $i=0; $i<=$#arr; $i++) {
        foreach my $j (@{$arr[$i]}) {
            $seen[$i]{$j}++;
        }
    }
    return @seen;
}

sub unseen {
    my ($seen, $nonexpected) = @_;
    my $errors = 0;
    foreach my $v ( @{ $nonexpected } ) {
        $errors++ if exists $seen->{$v};
    }
    $errors ? 0 : 1;
}

sub wrap_is_member_which {
    my $obj = shift;
    my $args = shift;
    my $correct = 0;
    foreach my $v ( keys %{ $args } ) {
        my @found = $obj->is_member_which($v);
        $correct++ if ok_seen_a( \@found, $v, @{ $args->{$v} } );
    }
    ($correct == scalar keys %{ $args }) ? 1 : 0;
}

sub all_is_member_which {
    my $obj = shift;
    my $args = shift;
    my @overall;
    for my $v ( @{ $args } ) {
        push @overall, [ $obj->is_member_which( $v ) ];
    }
    return \@overall;
}

sub func_all_is_member_which {
    my $data = shift;
    my $args = shift;
    my @overall;
    for my $v ( @{ $args } ) {
        push @overall, [ is_member_which( $data, [ $v ] ) ];
    }
    return \@overall;
}

sub func_all_is_member_which_alt {
    my $data = shift;
    my $args = shift;
    my @overall;
    for my $v ( @{ $args } ) {
        push @overall, [ is_member_which( {
            lists   => $data, 
            item    => $v,
        } ) ];
    }
    return \@overall;
}

sub func_all_is_member_which_ref_alt {
    my $data = shift;
    my $args = shift;
    my @overall;
    for my $v ( @{ $args } ) {
        push @overall, is_member_which_ref( {
            lists   => $data, 
            item    => $v,
        } );
    }
    return \@overall;
}

sub wrap_is_member_which_ref {
    my $obj = shift;
    my $args = shift;
    my $correct = 0;
    foreach my $v ( keys %{ $args } ) {
        my $memb_arr_ref = $obj->is_member_which_ref($v);
        $correct++ if ok_seen_a( $memb_arr_ref, $v, @{ $args->{$v} } );
    }
    ($correct == scalar keys %{ $args }) ? 1 : 0;
}

sub all_is_member_which_ref {
    my $obj = shift;
    my $args = shift;
    my @overall;
    for my $v ( @{ $args } ) {
        push @overall, $obj->is_member_which_ref( $v );
    }
    return \@overall;
}

sub func_all_is_member_which_ref {
    my $data = shift;
    my $args = shift;
    my @overall;
    for my $v ( @{ $args } ) {
        push @overall, is_member_which_ref( $data, [ $v ] );
    }
    return \@overall;
}

sub wrap_are_members_which {
    my $memb_hash_ref = shift;
    my $args = shift;
    my $correct = 0;
    foreach my $v ( keys %{ $args } ) {
        $correct++ if ok_seen_h( $memb_hash_ref, $v, @{ $args->{$v} } );
    }
    ($correct == scalar keys %{ $args }) ? 1 : 0;
}

sub wrap_is_member_any {
    my $obj = shift;
    my $args = shift;
    my $correct = 0;
    foreach my $v ( keys %{ $args } ) {
        $correct++ if ($obj->is_member_any( $v )) == $args->{$v};
    }
    ($correct == scalar keys %{ $args }) ? 1 : 0;
}

#@args = qw( abel baker camera delta edward fargo golfer hilton icon jerky zebra );

sub all_is_member_any {
    my $obj = shift;
    my $args = shift;
    my @overall;
    for my $v ( @{ $args } ) {
        push @overall, $obj->is_member_any( $v );
    }
    return \@overall;
}

sub func_all_is_member_any {
    my $data = shift;
    my $args = shift;
    my @overall;
    for my $v ( @{ $args } ) {
        push @overall, is_member_any( $data, [ $v ] );
    }
    return \@overall;
}

sub func_all_is_member_any_alt {
    my $data = shift;
    my $args = shift;
    my @overall;
    for my $v ( @{ $args } ) {
        push @overall, is_member_any( {
            lists => $data,
            item => $v,
        } );
    }
    return \@overall;
}

sub wrap_are_members_any {
    my $memb_hash_ref = shift;
    my $args = shift;
    my $correct = 0;
    foreach my $v ( keys %{ $args } ) {
        $correct++ if ok_any_h( $memb_hash_ref, $v, $args->{$v} );
    }
    ($correct == scalar keys %{ $args }) ? 1 : 0;
}

sub make_array_seen_hash {
    my $arrayref = shift;
    my @arrseen = ();
    foreach my $el (@{$arrayref}) {
        die "Each element must be an array ref"
            unless ref($el) eq 'ARRAY';
        my %seen;
        $seen{$_}++ for @{$el};
        push @arrseen, \%seen;
    }
    return \@arrseen;
}

@a0 = qw(abel abel baker camera delta edward fargo golfer);
@a1 = qw(baker camera delta delta edward fargo golfer hilton);
@a2 = qw(fargo golfer hilton icon icon jerky);
@a3 = qw(fargo golfer hilton icon icon);
@a4 = qw(fargo fargo golfer hilton icon);
@a8 = qw(kappa lambda mu);

%h0 = (
	abel     => 2,
	baker    => 1,
	camera   => 1,
	delta    => 1,
	edward   => 1,
	fargo    => 1,
	golfer   => 1,
);

%h1 = (
	baker    => 1,
	camera   => 1,
	delta    => 2,
	edward   => 1,
	fargo    => 1,
	golfer   => 1,
	hilton   => 1,
);

%h2 = (
	fargo    => 1,
	golfer   => 1,
	hilton   => 1,
	icon     => 2,
	jerky    => 1,	
);

%h3 = (
	fargo    => 1,
	golfer   => 1,
	hilton   => 1,
	icon     => 2,
);

%h4 = (
	fargo    => 2,
	golfer   => 1,
	hilton   => 1,
	icon     => 1,
);

%h5 = (
	golfer   => 1,
	lambda   => 0,
);

%h6 = (
	golfer   => 1,
	mu       => 00,
);

%h7 = (
	golfer   => 1,
	nu       => 'nothing',
);

%h8 = map {$_, 1} qw(kappa lambda mu);

$test_member_which_dual = [
  [ qw( 0   ) ],
  [ qw( 0 1 ) ],
  [ qw( 0 1 ) ],
  [ qw( 0 1 ) ],
  [ qw( 0 1 ) ],
  [ qw( 0 1 ) ],
  [ qw( 0 1 ) ],
  [ qw(   1 ) ],
  [ qw(     ) ],
  [ qw(     ) ],
  [ qw(     ) ],
];

$test_member_which_mult = [
  [ qw( 0         ) ],
  [ qw( 0 1       ) ],
  [ qw( 0 1       ) ],
  [ qw( 0 1       ) ],
  [ qw( 0 1       ) ],
  [ qw( 0 1 2 3 4 ) ],
  [ qw( 0 1 2 3 4 ) ],
  [ qw(   1 2 3 4 ) ],
  [ qw(     2 3 4 ) ],
  [ qw(     2     ) ],
  [ qw(           ) ],
];

$test_members_which =  {
    abel      => [ 1, [ qw< 0   > ] ],
    baker     => [ 2, [ qw< 0 1 > ] ],
    camera    => [ 2, [ qw< 0 1 > ] ],
    delta     => [ 2, [ qw< 0 1 > ] ],
    edward    => [ 2, [ qw< 0 1 > ] ],
    fargo     => [ 2, [ qw< 0 1 > ] ],
    golfer    => [ 2, [ qw< 0 1 > ] ],
    hilton    => [ 1, [ qw<   1 > ] ],
    icon      => [ 0, [ qw<     > ] ],
    jerky     => [ 0, [ qw<     > ] ],
    zebra     => [ 0, [ qw<     > ] ],
};

$test_member_any_dual = [ 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 ];
$test_member_any_mult = [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 ];

$test_members_any = {
    abel    => 1,
    baker   => 1,
    camera  => 1,
    delta   => 1,
    edward  => 1,
    fargo   => 1,
    golfer  => 1,
    hilton  => 1,
    icon    => 0,
    jerky   => 0,
    zebra   => 0,
};

$test_members_any_mult = {
    abel    => 1,
    baker   => 1,
    camera  => 1,
    delta   => 1,
    edward  => 1,
    fargo   => 1,
    golfer  => 1,
    hilton  => 1,
    icon    => 1,
    jerky   => 1,
    zebra   => 0,
};

$test_members_which_mult = {
    abel        => [ qw< 0         > ],
    baker       => [ qw< 0 1       > ],
    camera      => [ qw< 0 1       > ],
    delta       => [ qw< 0 1       > ],
    edward      => [ qw< 0 1       > ],
    fargo       => [ qw< 0 1 2 3 4 > ],
    golfer      => [ qw< 0 1 2 3 4 > ],
    hilton      => [ qw<   1 2 3 4 > ],
    icon        => [ qw<     2 3 4 > ],
    jerky       => [ qw<     2     > ],
    zebra       => [ qw<           > ],
};

sub func_wrap_is_member_which {
    my $data = shift;
    my $args = shift;
    my $correct = 0;
    foreach my $v ( keys %{ $args } ) {
        my @found = is_member_which( $data, [ $v ]);
        $correct++ if ok_seen_a( \@found, $v, @{ $args->{$v} } );
    }
    ($correct == scalar keys %{ $args }) ? 1 : 0;
}

sub func_wrap_is_member_which_ref {
    my $data = shift;
    my $args = shift;
    my $correct = 0;
    foreach my $v ( keys %{ $args } ) {
        my $memb_arr_ref = is_member_which_ref( $data, [ $v ]);
        $correct++ if ok_seen_a( $memb_arr_ref, $v, @{ $args->{$v} } );
    }
    ($correct == scalar keys %{ $args }) ? 1 : 0;
}

sub func_wrap_are_members_which {
    my $memb_hash_ref = shift;
    my $args = shift;
    my $correct = 0;
    foreach my $v ( keys %{ $args } ) {
        $correct++ if ok_seen_h( $memb_hash_ref, $v, @{ $args->{$v} } );
    }
    ($correct == scalar keys %{ $args }) ? 1 : 0;
}

sub func_wrap_is_member_any {
    my $data = shift;
    my $args = shift;
    my $correct = 0;
    foreach my $v ( keys %{ $args } ) {
        $correct++ if (is_member_any( $data, [ $v  ])) == $args->{$v};
    }
    ($correct == scalar keys %{ $args }) ? 1 : 0;
}

sub func_wrap_are_members_any {
    my $memb_hash_ref = shift;
    my $args = shift;
    my $correct = 0;
    foreach my $v ( keys %{ $args } ) {
        $correct++ if ok_any_h( $memb_hash_ref, $v, $args->{$v} );
    }
    ($correct == scalar keys %{ $args }) ? 1 : 0;
}

