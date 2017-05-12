#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/TestSetup.pm,v 1.2 2005/10/02 07:30:18 claude Exp claude $
#
# copyright (c) 2005 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::TestSetup;
use Genezzo::GenDBI;
use Genezzo::Util;

use strict;
use warnings;
use File::Path;
use File::Spec;
use File::Copy;

sub CreateDB 
{
#    my $self = shift;

    my %optional = (dbinit => 1);
    my %required = (gnz_home => "no gnz home"
                    );

    my %args = (%optional,
                @_);

    return undef 
        unless (Validate(\%args, \%required));

    my $gnz_home = $args{gnz_home};

    rmtree($gnz_home, 1, 1)
        if ($args{dbinit});
#mkpath($gnz_home, 1, 0755);

    my %nargs;

    $nargs{gnz_home} = $args{gnz_home};

    $nargs{dbinit} = $args{dbinit};
    $nargs{exe} = $0;

    my $fb = Genezzo::GenDBI->new(%nargs);

    return $fb;

}

sub CreateOrRestoreDB 
{
#    my $self = shift;

#    print Data::Dumper->Dump(\@_);
    my %optional = (dbinit => 0);
    my %required = (gnz_home => "no gnz home",
                    restore_dir => "no restore dir"
                    );


    my %args = (%optional,
                @_);

    print Data::Dumper->Dump([ \%args ]);

    return undef 
        unless (Validate(\%args, \%required));

    my $gnz_home = $args{gnz_home};
    
    my $old_db_file = File::Spec->catfile($args{restore_dir},
                                          "default.dbf");

    my $fb;

    my %nargs = (@_);
    $nargs{dbinit} = $args{dbinit};

    if ((!$args{dbinit}) && (-e $old_db_file))
    {
        my $dest_ts = File::Spec->catdir($args{gnz_home}, "ts");
        rmtree($gnz_home, 1, 1);
        mkpath($gnz_home, 1, 0755);
        mkpath($dest_ts, 1, 0755);
        my $dest_db = File::Spec->catfile($dest_ts, "default.dbf");

        return undef
            unless (copy($old_db_file, $dest_db));

        $fb = CreateDB(%nargs);

    }

    return $fb
        if (defined($fb));

    $nargs{dbinit} = 1;
    $fb = CreateDB(%nargs);

    return undef
        unless (defined($fb));

    {
        # Note: dest_ts is now the source...
        my $dest_ts = File::Spec->catdir($args{gnz_home}, "ts");
        my $dest_db = File::Spec->catfile($dest_ts, "default.dbf");

        rmtree($args{restore_dir}, 1, 1);
        mkpath($args{restore_dir}, 1, 0755);

        return undef
            unless (copy($dest_db, $old_db_file));

        my %nargs = (@_);
        $nargs{dbinit} = 0;

    }
    
    return $fb;

}

if (0)
{
    my $dbf;
    if ($dbf = 
        Genezzo::TestSetup::CreateOrRestoreDB( 
                                               gnz_home => "/tmp/gnz_home",
                                               restore_dir => "/tmp/rrr"))
    {
        print "created db\n";

        $dbf->Parseall("select * from _pref1");

    }
    else
    {
        print "failed\n";
    }
}

END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::TestSetup - setup functions for testing

=head1 SYNOPSIS

use Genezzo::TestSetup;


=head1 DESCRIPTION



=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item CreateDB

=item CreateOrRestoreDB

=back

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS


=head1 TODO

=over 4

=item stuff

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2005 Jeffrey I Cohen.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Address bug reports and comments to: jcohen@genezzo.com

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut
