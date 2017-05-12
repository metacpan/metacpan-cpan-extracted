package Goo::PerlCoder;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::PerlCoder.pm
# Description:  Manipulate perl programs like a real coder. Pretend to be
#               a perl programmer!
#
# Date          Change
# -----------------------------------------------------------------------------
# 20/02/2005    Auto generated file
# 20/02/2005    Needed to be called by ProgramEditor
# 09/08/2005    Added the Add Change Log feature - works well!
# 09/08/2005    This is one more change but will appear over multiple lines.
#               Will the Goo be able to wrap the text correctly?
# 10/08/2005    Added method: test
# 10/08/2005    This is a new change
# 18/09/2005    Added full path instead of relative path
# 09/11/2005    Added method: addHeader
# 09/11/2005    Added method: addConstructor
# 09/11/2005    Added method: addPackages
# 09/11/2005    Added method: addISA
#
###############################################################################

use strict;

use Goo::Date;
use Goo::Object;
use Text::FormatTable;
use Goo::FileUtilities;

use base qw(Goo::Object);


###############################################################################
#
# new - construct a perl_coder object
#
###############################################################################

sub new {

    my ($class, $filename) = @_;

    my $this = $class->SUPER::new();

    # remember the filename
    $this->{filename} = $filename;

    # if the file exists maybe load it in?
    if (-e $this->{filename}) {
        $this->{code} = Goo::FileUtilities::get_file_as_string($this->{filename});
    }

    return $this;

}


###############################################################################
#
# save - save the updates to disk
#
###############################################################################

sub save {

    my ($this) = @_;

    Goo::FileUtilities::write_file($this->{filename}, $this->{code});

}


###############################################################################
#
# rename_method - change the name of the method
#
###############################################################################

sub rename_method {

    my ($this, $from, $to) = @_;

    $this->{code} =~ s/^sub $from/sub $to/m;

    $this->{code} =~ s!^\#\s+$from!\# $to!m;

}


###############################################################################
#
# get_code - return a string value
#
###############################################################################

sub get_code {

    my ($this) = @_;

    return $this->{code};

}


###############################################################################
#
# sort_package - sort the package to the program - this needs to be fixed
#
###############################################################################

sub sort_packages {

    my ($a, $b) = @_;

    # make sure pragmas come first
    if ($a =~ /^use\s+[a-z]/) {
        return 1;
    }

    if ($b =~ /^use\s+[a-z]/) {
        return 1;
    }

    return length($a) <=> length($b);

}


###############################################################################
#
# add_package - add a package to the program
#
###############################################################################

sub add_package {

    my ($this, $package) = @_;

    # remove the existing packages, assumes we always
    # have one package at least: use strict
    $this->{code} =~ s/use strict;/placeholder/;

    # will capture trailing comments too
    my @packages = $this->{code} =~ m/^(use.*?)$/mg;

    # add the package to the list
    push(@packages, "use $package;");

    # resort the packages by length
    my @sorted = sort { sort_packages($a, $b) } @packages;

    # remove all the packages - need to delete line feeds too!
    $this->{code} =~ s/^use.*?\n//mg;

    my $packages = join("\n", @sorted);

    # insert the packages back in - use strict comes first
    $this->{code} =~ s/^placeholder/use strict;\n\n$packages/m;

}


###############################################################################
#
# delete_package - delete a package from the program
#
###############################################################################

sub delete_package {

    my ($this, $package) = @_;

    $this->{code} =~ s/^use $package.*?\n//sm;

}


###############################################################################
#
# delete_method - remove a method from a program
#
###############################################################################

sub delete_method {

    my ($this, $method) = @_;

    # delete any comments box too from ### to the start of the sub
    # match the comment block - note the greedy start otherwise the
    # whole thing gets deleted!
    $this->{code} =~ m/.*(^##.*?^#\s$method\s+.*?^sub)/ms;

    # matches the comment box and the word "sub" below
    $this->{code} =~ s/$1/sub/ms;

    #print $1;
    # match opening sub to closing } and any whitespace
    $this->{code} =~ s/^sub $method.*?^\}\s+//ms;

    $this->add_change_log("Deleted method: " . $method);

}


###############################################################################
#
# clone_method - copy and paste a method
#
###############################################################################

sub clone_method {

    my ($this, $from_name, $to_name) = @_;

    # get me
    # grab the contents of a method and rename it

    # copy one method another
    # addMethod

}


###############################################################################
#
# add_change_log - add a change log entry
#
###############################################################################

sub add_change_log {

    my ($this, $change) = @_;

    my $table = Text::FormatTable->new('14l 62l');

    $table->row("~" . Goo::Date::get_current_date_with_slashes(), $change);

    my $comment = $table->render();

    # prefix the table with the comment symbol #
    $comment =~ s/^/\#/mg;

    # substitute this temporary placeholder ~ with a space
    $comment =~ s/~/ /;

    # match the last line in the header and add a comment
    # between existing comments
    $this->{code} =~ s/^\#\s+.*?\#\#/$comment\#\n\#\#/m;

}


###############################################################################
#
# delete_change_log - delete a changelog entry
#
###############################################################################

sub delete_change_log {

    my ($this, $date, $change) = @_;


}


###############################################################################
#
# add_module_name - add this at the top of the module
#
###############################################################################

sub add_module_name {

    my ($this, $name) = @_;

    # add a name to the start of the module
    $this->{code} =~ s/^/package $name;\n/;

}


###############################################################################
#
# add_returns_true - all modules need to return true - so lets do it.
#
###############################################################################

sub add_returns_true {

    my ($this) = @_;

    # add a name to the start of the module
    $this->{code} .= "\n\n1;\n";

}


###############################################################################
#
# add_header - add a header to the program
#
###############################################################################

sub add_header {

    my ($this, $filename, $author, $company, $description, $reason) = @_;

    my $tokens;

    # add header tokens to the header
    $tokens->{filename}    = $filename;
    $tokens->{company}     = $company;
    $tokens->{author}      = $author;
    $tokens->{description} = $description;

    # insert the date
    $tokens->{date} = Goo::Date::get_current_date_with_slashes();
    $tokens->{year} = Goo::Date::get_current_year();

    # prepend the header template to the code
    $this->{code} .=
        Goo::Template::replace_tokens_in_string(
                                                Goo::WebDBLite::get_template(
                                                                        "perl-module-header.tpl"),
                                                $tokens
                                               );

    # add a change log - this is version 1!
    $this->add_change_log("Version 1 generated by PerlCoder.pm.");

}


###############################################################################
#
# add_method - add a method
#
###############################################################################

sub add_method {

    my ($this, $name, $description, @parameters) = @_;

    my $tokens = {};

    $tokens->{name}        = $name;
    $tokens->{description} = $description;

    # get the constructor template
    $tokens->{parameter_list} = 'my (' . join(', ', @parameters) . ') = @_;';

    # add the constructor to the code
    # $this->{code} .= Template::replaceTokensInString
    my $method_body =
        Goo::Template::replace_tokens_in_string(Goo::WebDBLite::get_template("perl-method.tpl"),
                                                $tokens);

    if ($this->{code} =~ /^1;/m) {

        # v1 only add methods to packages - add it to the end of the file
        $this->{code} =~ s/^1;/$method_body\n\n1;/m;

    } else {

        # this must be a script - append to the end!
        $this->{code} .= "\n\n" . $method_body;
    }

    $this->add_change_log("Added method: " . $name);

}


###############################################################################
#
# add_constructor - add a constructor to a program
#
###############################################################################

sub add_constructor {

    my ($this, @parameters) = @_;

    my $tokens = {};

    $tokens->{name} = "new()";

    # get the constructor template
    $tokens->{parameter_list} = join(", ", @parameters);

    # add the constructor to the code
    # $this->{code} .= Template::replaceTokensInString
    $this->{code} .=
        Goo::Template::replace_tokens_in_string(
                                                Goo::WebDBLite::get_template(
                                                                          "perl-constructor.tpl"),
                                                $tokens
                                               );

}


###############################################################################
#
# add_packages - add a list of packages
#
###############################################################################

sub add_packages {

    my ($this, @packages) = @_;

    foreach my $package (@packages) {
        $this->add_package($package);
    }

}


###############################################################################
#
# add_isa - add isa to this module
#
###############################################################################

sub add_isa {

    my ($this, $package) = @_;

    $this->{code} .= "\n";
    $this->{code} .= "use base qw($package);";
    $this->{code} .= "\n";

}

1;


__END__

=head1 NAME

Goo::PerlCoder - Manipulate Perl programs just like a real programmer.

=head1 SYNOPSIS

use Goo::PerlCoder;

=head1 DESCRIPTION

=head1 METHODS

=over

=item new

constructor

=item save

save the updates to disk

=item rename_method

change the name of a method

=item get_code

return the code as a string

=item sort_package

sort the use list at the start of the program

=item add_package

add a package to the use list as the start of the program

=item delete_package

delete a package from the use list

=item delete_method

remove a method from the program

=item clone_method

copy and paste a method

=item add_change_log

add a change log entry

=item delete_change_log

delete a change log entry

=item add_module_name

add this at the top of the module

=item add_returns_true

all modules need to return true add a 1; at the bottom of the module

=item add_header

add a header to the program

=item add_method

add a method

=item add_constructor

add a constructor to a program

=item add_packages

add a list of packages

=item add_isa

add an isa to this module

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

