########################################################################
# housekeeping
########################################################################
package GC::Testy;
use v5.40;
use autodie;
use FindBin::libs;
use FindBin::libs   qw( base=t      export=test_d  scalar   );
use FindBin::libs   qw( base=.prove export=prove   scalar   );

use File::Basename;
use Test::More;

use List::Util  qw( first );

use File::Spec::Functions
qw
(
    rel2abs
    catpath
);

########################################################################
# package variables and sanity checks
########################################################################

my $path
= do
{
    my $base    = basename $0 => qw( .t );
    my $sep     = substr $base, 0, 1;

    join '/' => split "$sep" => $base
};

-e $path
or die "Non-existant: '$path'\n";

my $last_prove  
= do
{
    if
    (
        exists $ENV{ LAST_PROVE } 
        and
        $ENV{ LAST_PROVE } ne ''
    )
    {
        $ENV{ LAST_PROVE }
    }
    elsif( -e $prove )
    {
        ( stat $prove )[9]
    }
    else
    {
        0
    }
};

SKIP:
{
    ( stat $path )[9] > $last_prove 
    or skip "File unchanged: $path", 1;

    my $madness
    = do
    {
        # strip any leading numerics used for ordering.
        # replace any non-words with pkg separators.

        my $base    = basename $0 => qw( .t .pm );

        my $pkg_rx  
        = qr{ (?:~lib (?:~perl5 (?:~x86_64-linux[^~]*)?)? ~) (.*) }x;

        my ( $pkg ) = $base =~ $pkg_rx;

        join '::' => split /\W/, $pkg
    }; 

    my $method  = 'VERSION';

    ########################################################################
    # run the tests
    ########################################################################

    SKIP:
    {
        require_ok $madness
        or
        skip "'$madness' does not compile." => 1;

        can_ok(  $madness, $method )
        or
        skip "'$madness' lacks any '$method'" => 1;

        $madness->$method
        or note "$madness lacks a version";
    };
};

done_testing

__END__

=head1 NAME

01-pm_t - generic unit test for perl modules.

=head1 SYNOPSIS

    # symlink the absolute path to a module to this
    # file and then run prove. 

    cd t;
    rm -rf 01-pm;
    mkdir 01-pm;
    cd 01-pm;
    ln -fs /path/to/lib/Foo/Bar.pm path~to~lib~Foo~Bar.pm.t;

    cd ../..;
    prove -v t/01-pm;

=head1 Description

Simplifed sanity check for require and using a method in a module.
In this case the module name is derived from the path and the method
is standardized to "VERSION".

=head2 Ignored modules

Some modules are not suitable for unit testing: Net::FTP::* modules
require Net::FTP to be loaded first, GSSAPI depends on kerberos that
may not be installed. These are filtered out by the test code and 
skipped. The list if ignored modules is curated as a list in the 
code for now:

    my @ignorz
    = qw
    (
        GSSAPI
        new_booking_passport

        Test2
        Manual
        Net::FTP
        Test2/AsyncSubtest/Formatter
        PDF/API2/Win32
        if
        File/Spec/VMS
    );

=head1 SEE ALSO

=over 4

=item t/bin/install-pm-tests

Locates all "*.pm" files in the sibling "lib" directory
to t containing the executable and symlinks them to the
*_t files in its directory.


=back
