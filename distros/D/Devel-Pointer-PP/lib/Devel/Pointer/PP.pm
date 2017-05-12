package Devel::Pointer::PP;
use strict;
use 5.8.1;
use warnings;
use B;
use Exporter;
use vars qw(@ISA @SVCLASSNAMES @EXPORT %EXPORT_TAGS $VERSION);

BEGIN {
    $VERSION = 1.01;
    @ISA = 'Exporter';
    @EXPORT = qw(address_of
		 deref
		 unsmash_sv
		 unsmash_av
		 unsmash_hv
		 unsmash_cv);
    %EXPORT_TAGS = ( ':all', \ @EXPORT );
    
    @SVCLASSNAMES =
      map "B::$_",
        qw( NULL
            IV
            NV
            RV
            PV
            PVIV
            PVNV
            PVMG
            BM
            PVLV
            AV
            HV
            CV
            GV
            FM
            IO );
}

sub address_of { 0 + \ $_[0] }

BEGIN {
    for my $name ('unsmash_sv',
		  'unsmash_av',
		  'unsmash_hv',
		  'unsmash_cv',
		  'deref') {
	eval "
sub $name {
    my \$address;
    if ( \$_[0] =~ /0x([a-f\\d]+)/ ) {
        \$address = hex \$1;
    }
    else {
        \$address = 0 + \$_[0];
    }

    # Temporarilly bless the object as a generic SV so I can query for
    # the type of the object.
    my \$obj = bless \\\$address, 'B::SV';
    my \$type = \$obj->SvTYPE;

    bless \$obj, \$SVCLASSNAMES[ \$type ];

    return \$obj->object_2svref;
}
";
    }
}

1;
__END__

=head1 NAME

Devel::Pointer::PP - Fiddle around with pointers, safer than Devel::Pointer

=head1 SYNOPSIS

 use Devel::Pointer ':all';
 
 my $addr = address_of( $val );

 # Dereference by address
 my $val2 = ${deref( $addr )};
 
 # Dereference a reference
 my $val2 = ${deref( \ $val )};
 
 # Dereference a stringified reference
 my $val2 = ${deref( "" . \ $val );
 
 $a = unsmash_sv(0+$scalar_ref);
 @a = unsmash_av(0+$array_ref);
 %a = unsmash_hv(0+$hash_ref);
 &a = unsmash_cv(0+$code_ref); 
 # Yes, you can do that. You get the idea.

 $c = deref(-1);        # *(-1), and the resulting segfault.

=head1 DESCRIPTION

The primary purpose of this is to turn a smashed reference address
back into a value. Once a reference is treated as a numeric or string
value, you can't dereference it normally; although with this module,
you can.

Be careful, though, to avoid dereferencing things that don't want to
be dereferenced.

=head2 EXPORT

All of the above

=head1 AUTHOR

Joshua ben Jore C<jjore@cpan.org>

Simon Cozens wrote the XS version and then some loony put an object_2svref
method into perl 5.8.1's B module and enabled me to rewrite the thing in
pure perl.

=head1 SEE ALSO

L<Devel::Pointer>, L<Devel::Peek>, L<perlref>

=cut
