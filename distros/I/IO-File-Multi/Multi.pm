# *|* PERL *|*
#
# Print to multiple filehandles with a single call
#
# File: Multi.pm
#
# Author: Nem W Schlecht
# Last Modification: $Date: 1998/08/07 23:30:57 $
#
# $Id: Multi.pm,v 1.1 1998/08/07 23:30:57 nem Exp $
# $Log: Multi.pm,v $
# Revision 1.1  1998/08/07 23:30:57  nem
# Initial revision
#
#
#
# Copyright © 1996 by Nem W Schlecht.  All rights reserved.
# This is free software; you can distribute it and/or
# modify it under the same terms as Perl itself.
#

package IO::File::Multi;
use strict;
use IO::File;
use Carp;

use vars qw($VERSION);
$VERSION='1.02';

sub new {
    my($class)=shift;
    return bless({}, $class);
}

#
# add another output
sub open {
    my($self)=shift;
    my($fh)=new IO::File;
    $fh->open(@_) || carp(ref($self), " - open failed: '@_'");
    push(@{$self->{handles}}, $fh);
}

#
# Return refs to IO::File objects
sub members {
    my($self)=shift;
    return @{$self->{handles}};
}

#
# IO::File stub routine
sub fh_st {
    my($self)=shift;
    my(@args)=@_;
    my($ret);
    my($sub_call)=(split(/::/o,(caller(1))[3]))[-1];	# Ack!
    for (@{$self->{handles}}) {
	$ret = $_->$sub_call(@args);
    }
    return $ret;
}

#
# Clean up.
sub DESTROY {
    my($self)=shift;
    $self->close();
}

sub print { my($I)=shift; $I->fh_st(@_); }
sub printf { my($I)=shift; $I->fh_st(@_); }
sub close { my($I)=shift; $I->fh_st(@_); }
sub autoflush { my($I)=shift; $I->fh_st(@_); }
sub output_field_separator { my($I)=shift; $I->fh_st(@_); }
sub output_record_separator { my($I)=shift; $I->fh_st(@_); }
sub format_page_number { my($I)=shift; $I->fh_st(@_); }
sub format_lines_per_page { my($I)=shift; $I->fh_st(@_); }
sub format_lines_left { my($I)=shift; $I->fh_st(@_); }
sub format_name { my($I)=shift; $I->fh_st(@_); }
sub format_top_name { my($I)=shift; $I->fh_st(@_); }
sub format_line_break_characters { my($I)=shift; $I->fh_st(@_); }
sub format_formfeed { my($I)=shift; $I->fh_st(@_); }

#
# IO::File::Multi don't do input (yet - and maybe it never will)
#
#sub getline { my($I)=shift; $I->fh_st(@_); }
#sub getlines { my($I)=shift; $I->fh_st(@_); }
#sub input_record_separator { my($I)=shift; $I->fh_st(@_); }
#sub input_line_number { my($I)=shift; $I->fh_st(@_); }

__END__

=head1 NAME

Multi - Print to multiple filehandles with one output call

=head1 SYNOPSIS

    use IO::File::Multi;
    $mult_obj=new IO::File::Multi;
    $mult_obj->open('>-');
    $mult_obj->open('>file');
    $mult_obj->open(">$file");
    $mult_obj->open('>>file2');
    $mult_obj->print("This will be printed to several filehandles\n");
    $mult_obj->printf("This will be printed to %d filehandles\n",
        scalar @{$mult_obj->{handles}});
    $mult_obj->autoflush();
    @handle_refs = $mult_obj->members();
    $mult_obj->output_field_separator(':');
    $mult_obj->output_record_separator('\n');
    $mult_obj->format_page_number(2);
    $mult_obj->format_lines_per_page(66);
    $mult_obj->format_lines_left(10);
    $mult_obj->format_name('AN_REPORT');
    $mult_obj->format_top_name('AN_REPORT_TOP');
    $mult_obj->format_line_break_characters('\n');
    $mult_obj->format_formfeed('\l');
    $mult_obj->close();

=head1 DESCRIPTION

This module requires that the user have the IO::File module installed (it
comes with the perl distribution).  Create objects for each of the output
filehandles you'll have - then call the print() and printf() methods to
send output to ALL the filehandles associated with an object.

=head1 EXAMPLES

Look at the B<SYNOPSIS> section.  Also, here is a simple implementation
of the unix tee(1) program (non-append mode):

  #!/local/bin/perl
  use IO::File::Multi;
  $mh=new IO::File::Multi;
  $mh->open('>-');
  for (@ARGV) { $mh->open(">$_"); }
  while (<STDIN>) { $mh->print($_); }

=head1 BUGS

I don't think using my()s the way I am in the open() method is all that
good.  binmode isn't supported, but I don't see anybody using that anyways.
In order to use fcntl(), fileno(), or flock() you'll have to access the
filehandles yourself by calling members().  There's no write() yet (but I'm
working on it!).  Also, any limitations to the IO::File module also apply
here.

It has been pointed out to me that multiple open() calls on the same file
under MacOS will fail.  Hopefully, the carp() call will help with catching
this.

=head1 AUTHOR

Nem W Schlecht (nem@plains.nodak.edu).  Comments, bugs fixes, and
suggestions welcome.
