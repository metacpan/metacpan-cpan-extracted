# File: File/Find/Rex.pm
# Description:
# Revisions:  2018.01.21 - Roland Ayala - Created
#
# License: Artistic License 2.0
#
package File::Find::Rex;

use 5.006;
use strict;
use warnings;
our $VERSION = '1.00';

# import modules
use Carp;
use Cwd 'abs_path';
use File::Basename;
use File::Find;
use File::Spec 'canonpath';
use if $^O eq 'MSWin32', 'Win32::File';

sub new {
    my ( $class, $options, $callback ) = @_;
    if ( defined $options && ref $options ne 'HASH' ) {
        croak 'options expects hash reference';
    }
    if ( defined $callback && ref $callback ne 'CODE' ) {
        croak 'callback expects code reference';
    }

    my $self = {
        _options  => $options,
        _callback => $callback
    };
    bless $self, $class;
    return $self;
}

sub set_option {
    my ( $self, $key, $value ) = @_;
    if ( defined $key ) {
        $self->{_options}->{$key} = $value;
    }
    return;
}

sub is_ignore_dirs {
    my $self = shift;
    return
        defined $self->{_options}->{ignore_dirs}
      ? $self->{_options}->{ignore_dirs} > 0
          ? 1
          : 0
      : 0;
}

sub is_ignore_hidden {
    my $self = shift;
    return
        defined $self->{_options}->{ignore_hidden}
      ? $self->{_options}->{ignore_hidden} > 0
          ? 1
          : 0
      : 0;
}

sub is_recursive {
    my $self = shift;
    return
        defined $self->{_options}->{recursive}
      ? $self->{_options}->{recursive} > 0
          ? 1
          : 0
      : 0;
}

sub get_last_modified_earliest {
    my $self = shift;
    my $val  = $self->{_options}->{last_modified_earliest};
    if ( defined $val ) {

        # ensure that value set is an integer value, because caller should
        # be setting option using epoch timevalue
        $val =~ m/^[\d]*$/gxs or $val = undef;
    }
    return $val;
}

sub get_last_modified_latest {
    my $self = shift;
    my $val  = $self->{_options}->{last_modified_latest};
    if ( defined $val ) {

        # ensure that value set is an integer value, because caller should
        # be setting option using epoch timevalue
        $val =~ m/^[\d]*$/gxs or $val = undef;
    }
    return $val;
}

sub query {
    my ( $self, $source, $regexp, $context ) = @_;
    defined $source or croak 'source path expected';
    if ( defined $regexp && ref $regexp ne 'Regexp' ) {
        croak 'regular expression expected';
    }

    # Initialize an empty array. If caller sets a callback then this empty
    # array is returned, else wanted callback will push any files found onto
    # the array.
    my @files = ();

    if ( -e $source ) {

        # Get the absolute path in case caller specifies relative path to source
        # directory so recursive behavior in find_files_wanted works correctly,
        # and for logging purposes.
        $source = abs_path($source);

        if ( -d $source )    # source is a directory
        {
            File::Find::find(
                _make_wanted(
                    \&_callback, $self, \@files, $source, $regexp, $context
                ),
                $source
            );
        }
        else                 # source is a file
        {
            _callback( $self, \@files, $source, $regexp, $context, 1 );
        }
    }
    else {
        warn 'No such file or directory' . "\n";
    }

    return @files;
}

sub _make_wanted {
    my @args   = @_;            # freeze the args
    my $wanted = shift @args;
    return sub { $wanted->(@args); };
}

sub _callback {
    my ( $self, $files, $source, $regexp, $context, $dummy ) = @_;
    my $file = defined $dummy ? $source : $File::Find::name;

    # if the file is a directory and caller has specified to ignore dirs in
    # results set then jump to end.
    unless ( -d $file && $self->is_ignore_dirs ) {
      NEXT: {
            my ( $fbase, $fdir, $ftype ) = fileparse( $file, '\.[^\.]*' );
            my $filename = $fbase . $ftype;

            # handle ignore_hidden option
            if ( $self->is_ignore_hidden ) {

                # method for determining if file is hidden depends on if windows
                # or not.
                my $is_visible;
                if ( $^O eq 'MSWin32' ) {
                    my $attr;
                    Win32::File::GetAttributes( $file, $attr );
                    $is_visible = !( $attr & Win32::File::HIDDEN() );
                }
                else {
                    $is_visible = ( $filename !~ /^[.]/gxs );
                }
                $is_visible or last NEXT;
            }

            # handle regex pattern rule if set
            if ( defined $regexp && !-d $file ) {
                $filename =~ $regexp or last NEXT;
            }

            # handle last modified window rules if set
            my $oldest = $self->get_last_modified_earliest;
            my $newest = $self->get_last_modified_latest;
            if ( defined $oldest || defined $newest ) {

                # capture last modified timestamp from file
                my $timestamp = ( stat $file )[9];
                if ( defined $oldest ) { $timestamp >= $oldest or last NEXT; }
                if ( defined $newest ) { $timestamp <= $newest or last NEXT; }
            }

            my $cfile = File::Spec->canonpath($file);
            if ( defined $self->{_callback} ) {
                $self->{_callback}->( $cfile, $context );
            }
            else {
                push @{$files}, $cfile;
            }
        }
    }
    if ( -d $file && ( uc $file ) ne ( uc $source ) && !$self->is_recursive ) {
        $File::Find::prune = 1;
    }

    return;
}

1;    # End of File::Find::Rex

__END__

=head1 NAME

File::Find::Rex - Combines simpler File::Find interface with support for
regular expression search criteria.

=head1 VERSION

Version 1.00

=head1 DESCRIPTION

This module provides an easy to use object oriented interface to
C<File::Find> and adds the ability to filter results using regular
expressions.

Features include:

=over 4

=item * Object oriented interface

=item * Find results returned as array or via a callback subroutine

=item * Regular expression matching

=item * Option to ignore directory listings in output (i.e., just files)

=item * Option to ignore hidden files

=item * Option to scope query using file last modified date

=item * Caller provided context passed when using callback subroutine


=back


=head1 SYNOPSIS

B< # Example 1:> Simplest use-case - finds all files in present working
 # directory.

 use File::Find::Rex;
 my $source = ".";
 my $rex = new File::Find::Rex;
 my @files = $rex->query($source);
 foreach (@files)
 {
  say $_;
 }

B< # Example 2:> Regex use-case - finds all files in present working
 # directory that start with the letter 'b' or 'B'.

 my @files = $rex->query($source, qr/^b/i);
 foreach (@files) {
   say $_;
 }

B< # Example 3:> Setting find options - sets options to perform recursive
 # query, ignore hidden files, and ignore directory entries in results.

 $rex->set_option('ignore_dirs', 1);
 $rex->set_option('ignore_hidden', 1);
 $rex->set_option('recursive', 1);
 my @files = $rex->query($source);
 foreach (@files) {
   say $_;
 }

B< # Example 4:> Callback method - results returned via callback method
 # instead of array, and options are passed to constructor.

 my %options = (
   recursive => 1,
   ignore_dirs => 1,
   ignore_hidden => 1,
   );

 $rex = new File::Find::Rex(\%options, \&callback);
 $rex->query($source);
 sub callback {
   say shift;
 }

=head1 CONSTRUCTOR

=head2 File::Find::Rex->new(<options>, <callback>)

The constructor takes two optional arguments:

B<options> is a hash reference containing key-value pairs specifying find
options. See the Options section for the list of available options.

B<callback> is a code reference to a subroutine that is called for each
find result. If passed, C<query> results are returned via the callback
method instead of return value.

=head1 SUBROUTINES/METHODS

=head2 query([source], <regexp>, <context>)

The query method takes one required and two optional arguments:

B<source> is the directory or file path to start search. A directory
path is typically passed; however, support for file path is offered to
simplify application logic by providing consistent call semantics and
behavior in scenarios where input can be a single file or a collection.

B<regex> is a regular expression for constraining query result to
matching filenames. The regular expression is tested on jstu the
filename - basename and extension. The file's directory path is not
evaluated. If passed, ref type expected is C<Regexp>, which can be
accomplished using regexp-like quoted string using C<qr>. For more
information see L<http://perldoc.perl.org/functions/qr.html>.

B<context> enables the caller have an arbitrary value or reference passed
to the callback method. It can be used, for example, by an object to
get a reference back to itself when callback is used to get results. This
option is only applicable when a callback is used.


=head2 set_option([option], <value>)

The set_option method takes one required and one optional argument:

B<option> specifies the option to set. See Options section for list of
options.

B<value> specifies the option value. See Options section for the values
settable for each option. If this argument is not set then option value is
set to undef, which has same effect as unsetting it.

=head2 is_ignore_dirs

Returns ignore_dirs option setting. 0: disabled, 1: enabled.

=head2 is_ignore_hidden

Returns ignore_hidden option setting. 0: disabled, 1: enabled.

=head2 get_last_modified_earliest

Returns last_modified_earliest epoch time value. If disabled, undef is
returned.

=head2 get_last_modified_latest

Returns last_modified_latest epoch time value. If disabled, undef is
returned.

=head2 is_recursive

Returns recursive option setting. 0: disabled, 1: enabled.

=head1 OPTIONS

C<File::Find::Rex> utilizes the options listed here to control find
behavior and to filter results. Options are set by passing a hash
reference to the construtor and by using the C<set_option> method. When
passing options constructor, each key-value pair maps to the option name
and its value.

=head2 ignore_dirs (default: disabled)

If set, this option suppresses listing directory entries in results. I.e.,
just files are returned.

To enable this option, set its value to 1. To disable set to 0 or undef,
or do not create a hash entry for it when passing options to construtor.

=head2 ignore_hidden (default: disabled)

If set, this option suppresses listing hidden files in results.

To enable this option, set its value to 1. To disable, set to 0 or undef,
or do not create a hash entry for it when passing options to construtor.

=head2 last_modified_latest (default: disabled)

If set, this option scopes query to files having file last modified
timestamp values less than or equal to the option value specified.
Timestamp values are in epoch datetime format, meaning an integer value is
expected.

To enable this option, set its value to an epoch timestamp. To disable,
set to undef or do not create a hash entry for it when passing options to
construtor.

=head2 last_modified_earliest (default: disabled)

If set, this option scopes query to files having file last modified
timestamp values greater than or equal to the option value specified.
Timestamp values are in epoch datetime format, meaning an integer value is
expected.

To enable this option, set its value to an epoch timestamp. To disable,
set to undef or do not create a hash entry for it when passing options to
construtor.

=head2 recursive (default: disabled)

If set, this option includes all subdirectories under the source directory
specified in C<query> call. This option has no affect on results if the
source specified is a file.

To enable this option, set its value to 1. To disable, set to 0 or undef,
or do not create a hash entry for it when passing options to construtor.

=head1 CALLBACK

If the caller passes an optional callback subroutine reference to the
constructor then C<query> results are returned via the callback instead
being returned as an array. The callback method is called for each file
found (as it is discovered) instead of waiting for the query to complete to
return results.

=head2 callback([file], <context>)

The callback subroutine is called for each file found, and arguments are
passed in the order shown:

B<file> is the fully qualified path to a file or directory found.

B<context> is the optional, caller defined value or reference passed to
C<query> call.


=head1 DEPENDENCIES

This module has the following depenencies:

=over 4

=item * Carp 1.29

=item * Cwd 3.40

=item * File::Basename 2.84

=item * File::Find 1.23

=item * File::Spec 3.40

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Find::Rex


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Find-Rex>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Find-Rex>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Find-Rex>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Find-Rex/>

=item * GitHub

L<https://github.com/rolanday/File-Find-Rex>


=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-file-find-rex at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Find-Rex>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<File::Find>

=head1 AUTHOR

Roland Ayala, C<< <rolanday at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Roland Ayala.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
