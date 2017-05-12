# Copyright (c) 2006 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Genezzo::GenDBI;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use strict;
use warnings;
use File::Path;
use File::Spec;

my $TEST_COUNT;

$TEST_COUNT = 2;

my $dbinit   = 1;
my $gnz_home = File::Spec->catdir("t", "gnz_home");
my $gnz_restore = File::Spec->catdir("t", "restore");
my $gnz_sql = File::Spec->catdir("t", "SQL");
my $gnz_log = File::Spec->catdir("t", "log");
#rmtree($gnz_home, 1, 1);
#mkpath($gnz_home, 1, 0755);

our $GZERR = sub {
    my %args = (@_);

    return 
        unless (exists($args{msg}));

    # to process spooling to multiple files
    my $outfile_h = $args{outfile_list} || undef;

    my $warn = 0;
    if (exists($args{severity}))
    {
        my $sev = uc($args{severity});
        $sev = 'WARNING'
            if ($sev =~ m/warn/i);

        # don't print 'INFO' prefix
        if ($args{severity} !~ m/info/i)
        {
            printf ("%s: ", $sev);

            if (defined($outfile_h))
            {
                while (my ($kk, $vv) = each (%{$outfile_h}))
                {
                    printf $vv ("%s: ", $sev);
                }
            }

            $warn = 1;
        }
        else
        {
            if (exists($args{no_info}))
            {
                # don't print info if no_info set...
                return;
            }
        }

    }
    print $args{msg};
    # add a newline if necessary
    print "\n" unless $args{msg}=~/\n$/;
#    carp $args{msg}
#      if (warnings::enabled() && $warn);

    if (defined($outfile_h))
    {
        while (my ($kk, $vv) = each (%{$outfile_h}))
        {
            print $vv $args{msg};
            # add a newline if necessary
            print $vv "\n" unless $args{msg}=~/\n$/;
        }
    }
    
};


{
    use Genezzo::TestSetup;

    my $fb = 
        Genezzo::TestSetup::CreateOrRestoreDB( 
                                               gnz_home => $gnz_home,
                                               restore_dir => $gnz_restore
                                               );

    unless (defined($fb))
    {
        not_ok ("could not create database");
        exit 1;
    }
    ok();
    $dbinit = 0;

}

{
    use Genezzo::Util;
    use Genezzo::TestSQL;

#    my $dbh = Genezzo::GenDBI->connect($gnz_home, "NOUSER", "NOPASSWORD");
    my $dbh = Genezzo::GenDBI->new(gnz_home => $gnz_home, 
                                   GZERR    => $GZERR);

    unless (defined($dbh))
    {
        not_ok ("could not find database");
        exit 1;
    }
    ok();

    my $dir_h;

    if ( !opendir($dir_h, $gnz_sql) )
    {
        not_ok ("could not open $gnz_sql");
    }
    else
    {
        my $fnam;
        while ($fnam  = readdir($dir_h))
        {
            next
                unless ($fnam =~ m/sql$/);
    
            # test each sql file in the directory

            my $sql_script = 
#                File::Spec->rel2abs(
                                    File::Spec->catfile(
                                                        $gnz_sql,
                                                        $fnam
                                                        );

            my $stat =
                Genezzo::TestSQL::TestSQL(dbh => $dbh,
                                          log_dir => $gnz_log,
                                          sql_script => $sql_script);

            unless (defined($stat))
            {
                not_ok("bad stat for $sql_script");
                next;
            }

            if ($stat =~ m/no differences found/)
            {
#                ok();
                next;
            }
            else
            {
                not_ok($stat);
            }
        } # end while
    }

    ok();
}

sub ok
{
    print "ok $TEST_COUNT\n";
    
    $TEST_COUNT++;
}


sub not_ok
{
    my ( $message ) = @_;
    
    print "not ok $TEST_COUNT #  $message\n";
        
        $TEST_COUNT++;
}


sub skip
{
    my ( $message ) = @_;
    
    print "ok $TEST_COUNT # skipped: $message\n";
        
        $TEST_COUNT++;
}

