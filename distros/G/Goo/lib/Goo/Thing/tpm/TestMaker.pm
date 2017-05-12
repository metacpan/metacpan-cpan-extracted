#!/usr/bin/perl

package Goo::TestMaker;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2003
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::TestMaker.pm
# Description:  Analyse program source and make test stubs add to the
#               testsuite
#
# Date          Change
# -----------------------------------------------------------------------------
# 14/08/2003    Version 1
# 06/02/2005    Returned to make more OO and usable - need to create a test
#               and check it into the test suite in one go!
# 28/08/2005    Added method: run
# 15/10/2005    Created test file: TestMakerTest.tpm
#
###############################################################################

use strict;

use Cwd;    							# get the current directory getcwd()
use Goo::Date;
use Goo::Object;
use Goo::Template;     					# replace tokens into the code template
use Goo::Prompter;     					# send out a message!
use Goo::WebDBLite;    					# store the code templates in the CMS
use Goo::FileUtilities;
use Goo::Thing::pm::ModuleDocumentor;   # use the ModuleDocumentor for introspection

use base qw(Object);


###############################################################################
#
# format_signature - strip $this, and $class from the signature
#
###############################################################################

sub format_signature {

    my ($this, $signature) = @_;

    # strip $this, or $class from the signature
    $signature =~ s/\$this//;
    $signature =~ s/\$class//;
    $signature =~ s/^\,//;       # any leading , left over

    return $signature;

}


###############################################################################
#
# create_test_for_module - create a test file for a module
#
###############################################################################

sub create_test_for_module {

    my $this      = shift;
    my $full_path = shift;

    # match the path and filename
    $full_path =~ m/(.*)\/(.*)$/;

    # get the location and filename
    my $location        = $1 || getcwd();
    my $module_filename = $2 || $full_path;

    # Prompter::notify("full path === $full_path ");
    # create a test file name for this module
    $module_filename =~ m/(.*)\.(.*)$/;

    my $module_name          = $1;
    my $test_module_name     = $1 . "Test";
    my $test_module_filename = $1 . "Test.tpm";

    my $test_module_path = $location . "/test";

    unless (-e $test_module_path) {
        mkdir $test_module_path;
    }

    $test_module_path .= "/" . $test_module_filename;

    # use the module documentor to do introspection
    my $documentor = Goo::Thing::pm::ModuleDocumentor->new($full_path);

    # need to check out signatures
    $documentor->calculate_method_signatures();

    my $t = {};

    $t->{name}                 = $test_module_name;
    $t->{program}              = $module_filename;
    $t->{filename}             = $test_module_filename;
    $t->{sourcefile}           = $test_module_filename;
    $t->{shortmodulename}      = lc(join("", $module_name =~ m/[A-Z]/g));
    $t->{description}          = $documentor->get_description();
    $t->{constructorsignature} = $this->format_signature($documentor->get_method_signature("new"));

    # strip the suffix
    $t->{program} = $module_filename;
    $t->{module}  = $module_name;
    $t->{date}    = Goo::Date::get_current_date_with_slashes();
    $t->{year}    = Goo::Date::get_current_year();

    foreach my $method ($documentor->get_methods()) {

        my $description = $documentor->get_method_description($method);
        my $signature   = $this->format_signature($documentor->get_method_signature($method));

        if ($method eq "new") { next; }

        if ($documentor->get_method_signature($method) =~ /\$this|\$class/) {
            $t->{methods} .= $this->get_oomethod($t, $method, $signature, $description);
        } else {
            $t->{methods} .= $this->get_class_method($t, $method, $signature, $description);
        }

    }


    my $template = $documentor->has_constructor() ? "testmodule-oo.tpl" : "testmodule.tpl";

    my $test = Goo::Template::replace_tokens_in_string(Goo::WebDBLite::get_template($template), $t);

    Goo::FileUtilities::write_file($test_module_path, $test);

    #my $pc = PerlCoder->new( { filename => $test_module_path } );
    #$pc->add_change_log("Test created for ");

    Goo::Prompter::yell("Test created: $test_module_path");

}


###############################################################################
#
# get_class_method - return a test for an class/package method
#
###############################################################################

sub get_class_method {

    my ($this, $tokens, $method, $signature, $description) = @_;

    return <<METHOD;
	
	\# $description
	\#\$this->ok($tokens->{module}\:\:$method($signature), "$description");
METHOD

}


###############################################################################
#
# get_oomethod - return a test for an oo method
#
###############################################################################

sub get_oomethod {

    my ($this, $tokens, $method, $signature, $description) = @_;

    return <<METHOD;
	
	\# $description
	\#\$this->ok(\$$tokens->{shortmodulename}\->$method($signature), "$description");
METHOD

}


1;



__END__

=head1 NAME

Goo::TestMaker - Analyse program source and make test stubs add to the

=head1 SYNOPSIS

use Goo::TestMaker;

=head1 DESCRIPTION



=head1 METHODS

=over

=item format_signature

strip $this, and $class from the signature

=item create_test_for_module

create a test file for a module

=item get_class_method

return a test for an class/package method

=item get_oomethod

return a test for an oo method


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

