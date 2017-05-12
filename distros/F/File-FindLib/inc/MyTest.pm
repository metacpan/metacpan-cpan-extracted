package MyTest;
use strict;

use Test qw< plan ok skip >;
use vars qw< @EXPORT_OK >;

BEGIN {
    @EXPORT_OK= qw< plan ok skip Okay SkipIf Lives Dies >;
    require Exporter;
    *import= \&Exporter::import;
}

$|= 1;

return 1;


sub Okay($;$$) {
    @_=  @_ < 3  ?  reverse @_  :  @_[1,0,2];
    goto &ok;
}


sub SkipIf($;$$$) {
    my $skip= shift @_;
    die "Can't not skip a non-test"
        if  ! $skip  &&  ! @_;
    $skip= 'Prior test failed'
        if  $skip  &&  1 eq $skip;
    @_=  @_ < 3  ?  reverse @_  :  @_[1,0,2];
    @_= ( $skip, @_ );
    goto &skip;
}


sub Lives {
    my( $code, $desc )= @_;
    my( $pkg, $file, $line )= caller();
    if(  ref $code  ) {
        $desc ||= "$file line $line";
        @_= ( 1, eval { $code->(); 1 }, "Should not die:\n$desc\n$@" );
        goto &Okay;
    } else {
        $desc ||= $code;
        ++$line;
        my $eval= qq(\n#line $line "$file"\n) . $code . "\n1;\n";
        @_= ( 1, eval $eval, "Should not die:\n$desc\n$@" );
        goto &Okay;
    }
}


sub Dies {
    my( $code, $omen, $desc )= @_;
    my( $pkg, $file, $line )= caller();
    ++$line;
    if(  ref $code  ) {
        $desc ||= "$file line $line";
        @_= (
            ! Okay( undef, eval { $code->(); 1 }, "Should die:\n$desc" ),
            $omen, $@, "Error from:\n$desc",
        );
    } else {
        $desc ||= $code;
        my $eval= qq(\n#line $line "$file"\n) . $code . "\n1;\n";
        @_= (
            ! Okay( undef, eval $eval, "Should die:\n$desc" ),
            $omen, $@, "Error from:\n$desc",
        );
    }
    goto &SkipIf;
}
