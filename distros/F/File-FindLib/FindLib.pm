package File::FindLib;
use strict;

use File::Basename          qw< dirname >;
use File::Spec::Functions   qw< rel2abs catdir splitdir >;

use vars                    qw< $VERSION >;

my $Pkg= __PACKAGE__;   # Our class name (convenient to use in messages)
BEGIN {
    $VERSION= 0.001_004;
}

return 1;   # No run-time code below; just 'sub's and maybe BEGIN blocks


sub import {
    my( $class, @args )= @_;
    if(  1 == @args  ) {
        my( $find )= @args;
        return LookUp(
            -from => ( caller )[1],
            -upto => $find,
            -add  => $find,
        );
    } else {
        die "Too many arguments to 'use $Pkg'.  Not yet supported.\n";
    }
}


sub LookUp {
    my %args=   @_;
    my $from=   rel2abs( $args{-from} );
    my $upto=   $args{-upto};
    my $add=    $args{-add};

    warn "$Pkg finds no $from; perhaps chdir()ed before 'use $Pkg'?\n"
        if  ! -e $from  &&  $^W;
    if(  -l $from  ) {
        $from= rel2abs( readlink($from), dirname($from) );
    }
    my $dir= $from;
    $dir= dirname( $dir )
        if  ! -d _;
    while(  1  ) {
        my $find= catdir( $dir, $upto );
        if(  -e $find  ) {
            my $path= catdir( $dir, $add );
            if(  -d $path  ) {
                require lib;
                lib->import( $path );
                return $path;
            }
            my $ret= require $path;
            UpdateInc( $path );
            return $ret;
        }
        my $up= dirname( $dir );
        die "$Pkg can't find $find in ancestor directory of $from.\n"
            if  $up eq $dir;
        $dir= $up;
    }
}


# Set $INC{'My/Mod.pm'} after loading 'lib/My/Mod.pm';
# so "use File::FindLib 'lib/Mod.pm'; use Mod;" doesn't load it twice.

sub UpdateInc {
    my( $path )= @_;    # Path to module file.
    my $base= $path;    # Path minus ".pm"; parts that go into package name.
    return 0            # If no .pm on end, "use Bareword" wouldn't find it.
        if  $base !~ s/[.]pm$//;
    my @parts= grep length $_, splitdir( $base );   # Potential pkg name parts.
    my @names;              # Above minus leading parts that aren't barewords.
    unshift @names, pop @parts              # Include last part until find...
        while  @parts  &&  $parts[-1] =~ /^\w+$/;   # ...a non-bareword.
 EDGE:
    for my $o ( 0 .. $#names ) {    # Strip shortest prefix that leaves a pkg.
        next            # "use Foo::123" works but "use 123::Foo" wouldn't.
            if  $names[$o] =~ /^[0-9]/;
        my $stab= \%main::;
        my @pkg= @names[ $o..$#names ];
        for my $name ( @pkg ) {         # Defined package? No autovivification.
            $stab= $stab->{$name.'::'};
            next EDGE
                if  ! $stab  ||  'GLOB' ne ref \$stab;
        }
        my $mod= join '/', @pkg;        # @INC always uses '/'; no catdir()
        $INC{"$mod.pm"} ||= $INC{$path};
        return 1;
    }
    return 0;
}


__END__

=head1 NAME

File::FindLib - Find and use a file/dir from a directory above your script file

=head1 SYNOPSIS

    use File::FindLib 'lib';

Or

    use File::FindLib 'lib/MyCorp/Setup.pm';

=head1 DESCRIPTION

File::FindLib starts in the directory where your script (or library) is
located and looks for the file or directory whose name you pass in.  If it
isn't found, then FindLib looks in the parent directory and continues moving
up parent directories until it finds it or until there is not another parent
directory.

If it finds the named path and it is a directory, then it prepends it to
C<@INC>.  That is,

    use File::FindLib 'lib';

is roughly equivalent to:

    use File::Basename qw< dirname >;
    use lib dirname(__FILE__) . '/../../../lib';

except you don't have to know how many '../'s to include and it adjusts
if __FILE__ is a symbolic link.

If it finds the named path and it is a file, then it loads the Perl code
stored in that file.  That is,

    use File::FindLib 'lib/MyCorp/Setup.pm';

is roughly equivalent to:

    use File::Basename qw< dirname >;
    BEGIN {
        require dirname(__FILE__) . '/../../../lib/MyCorp/Setup.pm';
    }

except you don't have to know how many '../'s to include (and it adjusts if
__FILE__ is a symbolic link).

=head2 MOTIVATION

It is common to have a software product that gets deployed as a tree
of directories containing commands (scripts) and/or test scripts in
the deployment that need to find Perl libraries that are part of the
deployment.

By including File::FindLib in your standard Perl deployment, you can
include one or more custom initialization or boot-strap modules in each
of your software deployments and easily load one by pasting one short line
into each script.  The custom module would likely add some directories to
@INC so that the script can then just load any modules that were included
in the deployment.

For example, you might have a deployment structure that looks like:

    bin/init
    ...
    db/bin/dump
    ...
    lib/MyCorp/Setup.pm
    lib/MyCorp/Widget.pm
    lib/MyCorp/Widget/Connect.pm
    ...
    t/TestEnv.pm
    t/itPing.t
    t/itTimeOut.t
    t/MyCorp/Widget/basic.t
    ...
    t/MyCorp/Widget/Connect/retry.t
    ...
    t/testlib/MyTest.pm
    ...

And your various Perl scripts like bin/init and db/bin/dump might start
with:

    use File::FindLib 'lib/MyCorp/Setup.pm';
    use MyCorp::Widget;

And Setup.pm might start with:

    package MyCorp::Setup;
    use File::FindLib 'lib';

While your various test scripts might start with:

    use File::FindLib 't/TestEnv.pm';
    use MyTest qw< plan ok >;

where TestEnv.pm might start with:

    package TestEnv;
    use File::FindLib 'testlib';    # Find modules in $repo/t/testlib/
    use File::FindLib 'lib';        # Find modules in $repo/lib/

And you don't have to worry about having to update a script if it gets
moved to a different point in the deployment directory tree.

=head2 SYMBOLIC LINKS

If the calling script/library was loaded via a symbolic link (if
C<-l __FILE__> is true inside the calling code), then File::FindLib will
start looking from where that symbolic link points.  If it points at another
symbolic link or if any of the parent directories are symbolic links, then
File::FindLib will ignore this fact.

So, if we have the following symbolic links:

    /etc/init.d/widget -> /site/mycorp/widget/bin/init-main
    /site/mycorp/widget/bin/init-main -> ../util/admin/init
    /site/mycorp/widget/ -> ../dist/widget/current/
    /site/mycorp/dist/widget/current/ -> 2011-12-01/
    /site/mycorp/dist/widget/2011-12-01 -> v1.042_037/
    /site/mycorp/ -> /export/site/mycorp/
    /site -> /export/var/site

And the following command produces the following output:

    $ head -2 /etc/init.d/widget
    #!/usr/bin/perl
    use File::FindLib 'lib/Setup.pm';
    $

Then File::FindLib will do:

    See that it was called from /etc/init.d/widget.
    See that this is a symbolic link.
    Act like it was called from /site/mycorp/widget/bin/init-main.
    (Ignore that this is another symbolic link.)
    Search for:
        /site/mycorp/widget/bin/lib/Setup.pm
        /site/mycorp/widget/lib/Setup.pm
        /site/mycorp/lib/Setup.pm
        /site/lib/Setup.pm
        /lib/Setup.pm

Only the first symbolic link that we mentioned is noticed.

This would be unfortunate if you also have the symbolic link:

    /etc/rc2.d/S99widget -> ../init.d/widget

Since running that command would cause the following searches:

    /etc/init.d/lib/Setup.pm
    /etc/lib/Setup.pm
    /lib/Setup.pm

If you instead made a hard link:

    # ln /etc/init.d/widget /etc/rc2.d/S99widget

then /etc/init.d/widget would also be a symbolic link to
/site/mycorp/widget/bin/init-main which would surely work better.

So future versions of File::FindLib may notice more cases of symbolic
links or provide options for controlling which symbolic links to notice.

=head2 %INC

The code:

    use File::FindLib 'lib/MyCorp/Setup.pm';

is more accurately approximated as:

    use File::Basename qw< dirname >;
    BEGIN {
        my $path= dirname(__FILE__) . '/../../../lib/MyCorp/Setup.pm';
        require $path;
        $INC{'MyCorp/Setup.pm'} ||= $INC{$path};
    }

The setting of C<$INC{'MyCorp/Setup.pm'}> is so that:

    use File::FindLib 'lib/MyCorp/Setup.pm';
    ...
    use MyCorp::Setup;

doesn't try to load the MyCorp::Setup module twice.

Though, this is only done if lib/MyCorp/Setup.pm defines a MyCorp::Setup
package... and C<$INC{'MyCorp/Setup.pm'}> isn't already set and there is
no lib::MyCorp::Setup package defined.  See the source code if you have
to know every detail of the heuristics used, though misfires are unlikely
(especially since module names are usually capitalized while library
subdirectory names usually are not).

Even this problem case is unlikely and the consequences of loading the same
module twice are often just harmless warnings, if that.

So this detail will not matter most of the time.

=head1 PLANS

I'd like to support a more powerful interface.  For example:

    use File::FindLib(
        -from           => __FILE__,
        -upto           => 'ReleaseVersion.txt',
        -inc            => 'custom/lib',    # Like: use lib ...
        +inc            => 'lib',           # Like: push @INC, ...
        -load           => 'initEnv.pl',    # Like: require ...
        \my $DataDir    => 'custom/data',   # Sets $DataDir to full path
    );

But adding such an interface should not interfere with the one-argument
interface already implemented.

=head1 CONTRIBUTORS

Author: Tye McQueen, http://perlmonks.org/?node=tye

=head1 ALSO SEE

Lake Missoula

=cut
