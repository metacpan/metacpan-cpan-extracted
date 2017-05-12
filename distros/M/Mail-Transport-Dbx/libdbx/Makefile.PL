# $Id$

use ExtUtils::MakeMaker;

if (unpack("h*", pack("s", 1)) =~ /01/) {
    $BYTEORDER = "DBX_BIG_ENDIAN";
} elsif (unpack("h*", pack("s", 1)) =~ /^1/) {
    $BYTEORDER = "DBX_LITTLE_ENDIAN";
} else {
    print <<EOERR;
Woah!

Your machine is neither BIG_ENDIAN nor LITTLE_ENDIAN!!
libdbx however is only trained to work with one of these two
byteorders.

I will abort now since this library wont be functional on 
this machine.
EOERR
    exit 1;
}

WriteMakefile(
    NAME   => 'Mail::Transport::Dbx::libdbx',
    SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
    clean  => {'FILES' => 'libdbx$(LIBEEXT)'},
    test   => {'TESTS' => ''},
    DEFINE => "-D$BYTEORDER",
);

sub MY::top_targets {
    my $self = shift;
    my $flags;
    if ($self->{AR} eq 'lib') { # the Microsoft's ar
        $flags = "/OUT:";
    } else {                    # use defaults
        $flags = $self->{AR_STATIC_ARGS}. " ";
    }
    "
all :: static

static ::       libdbx\$(LIB_EXT)

libdbx\$(LIB_EXT): \$(O_FILES)
	\$(AR) ${flags}libdbx\$(LIB_EXT) \$(O_FILES)
	\$(RANLIB) libdbx\$(LIB_EXT)

pure_all:
	
";
}
