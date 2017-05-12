
use v5.12;
use autodie;
use ExtUtils::MakeMaker;

my $dest	= 'lib/LinkedList/Single.pm';

-e $dest && unlink $dest;

eval{ require v5.16 }
? link 'Single-Post516_pm' => $dest
: link 'Single-Pre516_pm'  => $dest
;

our $VERSION = '1.02';
$VERSION = eval $VERSION;

WriteMakefile
(
    NAME            => 'LinkedList::Single',
    VERSION         =>  $VERSION,
    ABSTRACT_FROM   => $dest,
    LICENSE         => 'perl',
    PREREQ_PM       =>
    {
        qw
        (
            strict              0
            overload            0

            Carp                0
            Symbol              0
            Scalar::Util        0
            Test::More          0
            Test::Deep          0
            ExtUtils::MakeMaker 0
        )
    },
);

__END__
