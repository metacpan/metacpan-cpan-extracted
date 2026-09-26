#!/usr/bin/perl
#
use strict;
no strict qw(refs);
no warnings qw(uninitialized redefine utf8);

#  Load
#
use Test::More qw(no_plan);
use FindBin qw($RealBin $Script);
use Digest::MD5;
use File::Find qw(find);
use IO::File;
use Data::Dumper;
use Docbook::Convert::Constant;
use File::Basename;
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;


#  Load Module
#
require_ok('Docbook::Convert');
*diag=sub{};


#  Set no image fetch, other globals
#
$NO_IMAGE_FETCH=1;
$NO_WARN_UNHANDLED=1;


#  Handlers to test and reference file extenstions
#
my %handler=(
    markdown    => '.md'
);


#  Special handling for some files
#
my %test_param=(
    'meta4.xml' => {
        meta_display_top        => 1
    },
);


#  Get test files
#
my @test_fn;
my $wanted_sr=sub { push (@test_fn, $File::Find::name) if /(?<!.)\w+\.xml$/ };
find($wanted_sr, $RealBin);
foreach my $test_fn (sort {$a cmp $b } @test_fn) {

    #  Get file name
    #
    my $test_sn=fileparse($test_fn);
    diag("test file name: $test_sn");
    
    
    #  Iterate through handlers
    #
    while (my ($handler, $ref_ext)=each %handler) {
    

        
        
        #  Set any special params for this test.
        #
        my $param_hr=$test_param{$test_sn};
        


        #  Produce output
        #
        my $output=Docbook::Convert->process_file($test_fn, { 
            handler             =>  $handler, 
            no_warn_unhandled   =>  1,
            %{$param_hr} 
        }) ||
            fail("could not create output for file $test_sn");
            

        #  Output to file if producing ref files
        #
        (my $ref_fn=$test_fn)=~s/\.xml$/${ref_ext}/;
        my $ref_sn=fileparse($ref_fn);
        if ($ENV{'MAKEREF'}) {
            my $ref_fh=IO::File->new($ref_fn, O_WRONLY|O_TRUNC|O_CREAT) || 
                die("unable to create reference file $ref_fn, $!");
            print $ref_fh $output;
            $ref_fh->close();
            diag ("create ref file: $ref_sn with handler $handler");
            next;
        }


        #  Get MD5 of file we just converted
        #
        my $md5_or=Digest::MD5->new();
        $md5_or->add($output);
        my $md5_test=$md5_or->hexdigest();
        #diag("test file MD5: $md5_test");
        
        
        #  Load reference file for handler
        #
        diag("test file ref: $ref_sn");
        my $ref_fh=IO::File->new($ref_fn, O_RDONLY) ||
            fail("unable to open reference file $ref_sn");
        binmode($ref_fh);
        
        
        #  Hash that
        #
        $md5_or->addfile($ref_fh);
        my $md5_ref=$md5_or->hexdigest();


        #  Now compare
        #
        if ($md5_test eq $md5_ref) {
            pass("render $handler OK: $test_sn");
        }
        else {
            # Try to write failed file out
            #
            my ($ext)=($ref_fn=~/\.(\w+)$/);
            if (my $fail_fh=IO::File->new("${ref_fn}.fail.${ext}", O_WRONLY|O_TRUNC|O_CREAT)) {
                print $fail_fh $output;
                $fail_fh->close();
                diag("wrote failed test output to ${ref_sn}.fail.${ext}");
            }
            fail("render $handler FAIL: $test_sn, wrote failed test output to ${ref_sn}.fail.${ext}");
        }


        #  Clean up
        #
        $ref_fh->close();
        
    }
}
