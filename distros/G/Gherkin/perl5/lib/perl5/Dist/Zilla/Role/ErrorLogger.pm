#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: Dist/Zilla/Role/ErrorLogger.pm
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Dist-Zilla-Role-ErrorLogger.
#
#   perl-Dist-Zilla-Role-ErrorLogger is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Role-ErrorLogger is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Role-ErrorLogger. If not, see <http://www.gnu.org/licenses/>.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#pod =for :this This is C<Dist::Zilla::Role::ErrorLogger> role documentation. Read this if you want to
#pod have error logging capabilities in your Dist::Zilla plugin.
#pod
#pod =for test_synopsis
#pod my ( $cond, $file );
#pod sub Dist::Zilla::Plugin::YourPlugin::do_something;
#pod sub Dist::Zilla::Plugin::YourPlugin::do_something_else;
#pod
#pod =head1 SYNOPSIS
#pod
#pod     package Dist::Zilla::Plugin::YourPlugin;
#pod     use Moose;
#pod     use namespace::autoclean;
#pod     with 'Dist::Zilla::Role::Plugin';
#pod     with 'Dist::Zilla::Role::ErrorLogger';
#pod
#pod     sub method {
#pod         my $self = shift( @_ );
#pod
#pod         if ( $cond ) { $self->log_error( 'error message' ); };
#pod
#pod         do_something or $self->log_error( 'another error message' );
#pod
#pod         while ( $cond ) {
#pod             do_something_else or $self->log_error( 'error message' ) and next;
#pod             ...;
#pod         };
#pod
#pod         $self->log_errors_in_file(
#pod             $file,
#pod             1 => 'error message',           # Error at file line 1.
#pod             5 => 'another error message',   # Error at file line 5.
#pod         );
#pod
#pod         $self->abort_if_errors( 'errors found' );
#pod     };
#pod
#pod     __PACKAGE__->meta->make_immutable;
#pod     1;
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

#pod =head1 DESCRIPTION
#pod
#pod The role extends standard C<Dist::Zilla> logging capabilities with few methods a bit more
#pod convenient for reporting (multiple) errors than brutal C<log_fatal>. See L</"WHY?"> for more
#pod details.
#pod
#pod The role requires C<log> method in the consumer.
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Dist::Zilla::Role::ErrorLogger;

use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Have error logging capabilities in your Dist::Zilla plugin
our $VERSION = 'v0.9.0'; # VERSION

requires qw{ log };

use List::Util qw{ min max };

# --------------------------------------------------------------------------------------------------

#pod =attr error_count
#pod
#pod     $int = $self->error_count;
#pod
#pod C<Int>, read-only. Number of logged errors (i. e. number of made C<log_error> calls).
#pod
#pod =cut

has error_count => (
    is          => 'ro',
    isa         => 'Int',
    default     => 0,
    init_arg    => undef,
);

# --------------------------------------------------------------------------------------------------

#pod =method log_error
#pod
#pod     $self->log_error( @items );
#pod     $self->log_error( \%args, @items );
#pod
#pod This method calls C<log> method, passing all the arguments, and increments value of C<error_count>
#pod attribute. The method returns true value, so can be used in following constructs:
#pod
#pod     while ( ... ) {
#pod         do_something or $self->log_error( 'message' ) and next;
#pod         ...
#pod     };
#pod
#pod =cut

sub log_error {                         ## no critic ( RequireArgUnpacking )
    my $self = shift( @_ );
    #   If the first argument is a hashref, it is treated as extra arguments to logging, not as
    #   message, see <https://metacpan.org/pod/Log::Dispatchouli#log>. These extra arguments
    #   include `level` argument. It seems natural that error messages have `'error'` level.
    #   However, such messages do not appear in `dzil` output. So, do not try to set level, just
    #   pass all the arguments to `log`.
    $self->log( @_ );
    ++ $self->{ error_count };
    return $self->{ error_count };
};

# --------------------------------------------------------------------------------------------------

#pod =method abort
#pod
#pod     $self->abort( @items );
#pod     $self->abort( \%args, @items );
#pod
#pod This is an attempt to workaround L<C<log_fatal>
#pod drawback|https://github.com/rjbs/Dist-Zilla/issues/397>: in contrast to C<log_fatal>, C<abort>
#pod guarantees the message (which can be quite long) appears on the screen only once.
#pod
#pod The method log the message (via C<log>), then flush C<STDOUT>, then throws an exception of
#pod C<Dist::Zilla::Role::ErrorLogger::Exception::Abort> class (which being stringified gives short
#pod message C<"Aborting...\n">).
#pod
#pod =cut

sub abort {                             ## no critic ( RequireArgUnpacking, RequireFinalReturn )
    my $self = shift( @_ );
    if ( @_ ) {
        $self->log( @_ );
    };
    STDOUT->flush();
    Dist::Zilla::Role::ErrorLogger::Exception::Abort->throw();
};

# --------------------------------------------------------------------------------------------------

#pod =method abort_if_error
#pod
#pod =method abort_if_errors
#pod
#pod     $self->abort_if_errors( @items );
#pod     $self->abort_if_errors( \%args, @items );
#pod
#pod If there was any errors (i. e. C<error_count> is greater than zero), the logs all the arguments and
#pod aborts execution. Both actions (logging and aborting) are implemented by calling C<abort>.
#pod
#pod C<abort_if_error> is an alias for C<abort_if_errors>.
#pod
#pod =cut

sub abort_if_errors {                   ## no critic ( RequireArgUnpacking )
    my $self = shift( @_ );
    if ( $self->error_count ) {
        $self->abort( @_ );
    };
    return;
};

*abort_if_error = \&abort_if_errors;

# --------------------------------------------------------------------------------------------------

#pod =method log_errors_in_file
#pod
#pod The method intended to report errors against a file. It prints file name (and colon after it), then
#pod prints line-numbered file content annotated by error messages. The method does not print entire
#pod file content, but only error lines with surrounding context (2 lines above and below each error
#pod line).
#pod
#pod     $self->log_errors_in_file(
#pod         $file,
#pod         $linenum1 => $message1,
#pod         $linenum2 => $message2,
#pod         $linenum3 => [ $message3a, $message3b, ... ],
#pod         ...
#pod     );
#pod
#pod C<$file> should be a C<Dist::Zilla> file (e. g. C<Dist::Zilla::File::OnDisk>,
#pod C<Dist::Zilla::File::InMemory>, or does role C<Dist::Zilla::Role::File>).
#pod
#pod Errors are specified by pairs C<< $linenum => $message >>, where C<$linenum> is a number of problem
#pod line (one-based), and C<$message> is an error message (C<Str>) or array of messages
#pod (C<ArrayRef[Str]>). Order of errors does not matter usually. However, if errors are associated with
#pod the same line (the same line number may appear multiple times), they will be printed in order of
#pod appearance.
#pod
#pod Zero or negative line numbers, or line numbers beyond the last line are invalid. Messages
#pod associated with invalid line numbers are reported in unspecified way.
#pod
#pod Normally, the method prints all the information by calling C<log_error> method and returns a
#pod positive integer. However, If any invalid line numbers are specified, the method returns negative
#pod integer. If no errors are specified, the method prints "No errors found at I<file>." by calling
#pod C<log> (not C<log_error>!) and returns zero.
#pod
#pod TODO: Example.
#pod
#pod =cut

sub log_errors_in_file {

    my ( $self, $file, @errors ) = @_;

    # Corner case: no errors specified.
    if ( not @errors ) {
        $self->log( [ 'No errors at %s.', $file->name ] );
        return 0;
    };

    #   TODO: Chop too long lines?
    my $text  = [ split( "\n", $file->content ) ];

    #   Parse `@errors`.
    my %errors;     # Key is line number, value is arrayref to error messages.
    my %invalid;    # The same but for invalid line numbers.
    while ( @errors ) {
        my ( $n, $msg ) = splice( @errors, 0, 2 );
        if ( 1 <= $n and $n <= @$text ) {
            my $ctx = 2; # TODO: Parametrize it?
            for my $k ( max( $n - $ctx, 1 ) .. min( $n + $ctx, @$text + 0 ) ) {
                if ( not $errors{ $k } ) {
                    $errors{ $k } = [];
                };
            };
            push( @{ $errors{ $n } }, ref( $msg ) ? @$msg : $msg );
        } else {
            push( @{ $invalid{ $n } }, ref( $msg ) ? @$msg : $msg );
        };
    };

    my $t = ' ' x 4;                                # Indent for text lines.

    if ( %errors ) {

        my $w = length( 0 + @$text );               # Width of linenumber column.
        my $e = $t . ( ' ' x ( $w + 2 ) );          # Indent for error messages.
        my $last = 0;                               # Number of the last printed text line.

        my $log_line = sub {        # Log text line number and content.
            my ( $n ) = @_;
            my $line = $n <= @$text ? $text->[ $n - 1 ] : '';
            chomp( $line );
            $self->log_error( [ '%s%0*d: %s', $t, $w, $n, $line ] );
        };
        my $log_messages = sub {    # Log error messahes.
            my ( $n ) = @_;
            $self->log_error( [ '%s^^^ %s ^^^', $e, $_ ] ) for @{ $errors{ $n } };
        };
        my $log_skipped = sub {     # Log number of skipped lines.
            my ( $n ) = @_;
            if ( $n > $last + 1 ) {                 # There are skipped lines.
                my $count = $n - $last - 1;         # Number of skipped lines.
                if ( $count == 1 ) {
                    $log_line->( $n - 1 );          # There is no sense to skip one line.
                } else {
                    $self->log_error( [ '%s... skipped %d lines ...', $e, $count ] );
                };
            };
        };

        #   Do actual logging.
        $self->log_error( [ '%s:', $file->name ] );
        for my $n ( sort( { $a <=> $b } keys( %errors ) ) ) {
            $log_skipped->( $n );
            $log_line->( $n );
            $log_messages->( $n );
            $last = $n;
        };
        $log_skipped->( @$text + 1 );

    };

    if ( %invalid ) {
        $self->log_error( 'Following errors are reported against non-existing lines of the file:' );
        for my $n ( sort( { $a <=> $b } keys( %invalid ) ) ) {
            $self->log_error( [ '%s%s at %s line %d.', $t, $_, $file->name, $n ] )
                for @{ $invalid{ $n } };
        };
        return -1;
    };

    return 1;

};

# --------------------------------------------------------------------------------------------------

## no critic ( ProhibitMultiplePackages )

package Dist::Zilla::Role::ErrorLogger::Exception::Abort;

use strict;
use warnings;

## no critic ( ProhibitReusedNames )
# ABSTRACT: Exception class which C<ErrorLogger> throws to abort C<Dist::Zilla>
our $VERSION = 'v0.9.0'; # VERSION
## critic ( ProhibitReusedNames )

use overload '""' => sub { return "Aborting...\n"; };

sub throw {
    my ( $class ) = @_;
    die bless( {} => $class );          ## no critic ( RequireCarping )
};

# --------------------------------------------------------------------------------------------------

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 NOTES
#pod
#pod All the methods defined in the role log items through the C<log> method. C<Dist::Zilla> takes this
#pod method from C<Log::Dispatchouli>, the latter uses C<String::Flogger> to process the messages. It
#pod means you can use C<String::Flogger> tricks, e. g.:
#pod
#pod     $self->log_error( [ 'oops at %s line %d', $file, $line ] );
#pod         #   [] are shorter than sprintf.
#pod
#pod Also note how C<Log::Dispatchouli> describes the C<log> method:
#pod
#pod     $logger->log( @messages );
#pod
#pod and says:
#pod
#pod     Each message is flogged individually, then joined with spaces.
#pod
#pod So beware. A call
#pod
#pod     $self->log_error( 'error 1', 'error 2' );
#pod
#pod logs I<one> message "error 1 error 2", I<not> I<two> messages "error 1" and "error 2", and bumps
#pod C<error_count> by 1, not 2.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod =   L<Dist::Zilla>
#pod =   L<Dist::Zilla::Role>
#pod =   L<Dist::Zilla::Plugin>
#pod =   L<Log::Dispatchouli>
#pod =   L<String::Flogger>
#pod
#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: doc/what.pod
#
#   This file is part of perl-Dist-Zilla-Role-ErrorLogger.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Dist-Zilla-Role-ErrorLogger> is a C<Dist::Zilla> role. It provides C<log_error>, C<abort>, and
#pod C<abort_if_errors> methods to consuming plugins.
#pod
#pod =cut

# end of file #
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: doc/why.pod
#
#   This file is part of perl-Dist-Zilla-Role-ErrorLogger.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#pod =encoding UTF-8
#pod
#pod =head1 WHY?
#pod
#pod C<Dist::Zilla> limits logging capabilities with 3 logging levels available in plugins through
#pod C<log_debug>, C<log>, and C<log_fatal> methods. Debug level messages are turned off by default, the
#pod first fatal message terminates C<Dist::Zilla>. This is simple, but sometimes you may want to report
#pod all the errors, instead of stopping at the first found one. In such a case C<log_fatal> cannot be
#pod used, obviously. There are few alternatives:
#pod
#pod Collect error messages in an array, then report all the errors with single C<log_fatal> call:
#pod
#pod     my @errors;
#pod     ...
#pod     push( @errors, ... );
#pod     ...
#pod     if ( @errors ) {
#pod         $self->log_fatal( join( "\n", @errors ) );
#pod     };
#pod
#pod This works, but current implementation of C<log_fatal> has a disadvantage: it prints the message
#pod twice, so output looks ugly. (See L<message handling in log_fatal is
#pod suboptimal|https://github.com/rjbs/Dist-Zilla/issues/397>.)
#pod
#pod Another approach is reporting each error immediately with C<log>, counting number of reported
#pod errors, and calling C<log_fatal> once at the end:
#pod
#pod     my $error_count = 0;
#pod     ...
#pod     $self->log( 'error' );
#pod     ++ $error_count;
#pod     ...
#pod     if ( $error_count ) {
#pod         $self->log_fatal( 'Aborting...' );
#pod     };
#pod
#pod This works, but incrementing the counter after each C<log> call is boring and error-prone.
#pod C<Dist-Zilla-Role-ErrorLogger> role automates it, making plugin code shorter and more readable:
#pod
#pod     with 'Dist-Zilla-Role-ErrorLogger';
#pod     ...
#pod     $self->log_error( 'error' );
#pod     ...
#pod     $self->abort_if_errors();
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::ErrorLogger - Have error logging capabilities in your Dist::Zilla plugin

=head1 VERSION

Version v0.9.0, released on 2015-10-26 21:04 UTC.

=head1 WHAT?

C<Dist-Zilla-Role-ErrorLogger> is a C<Dist::Zilla> role. It provides C<log_error>, C<abort>, and
C<abort_if_errors> methods to consuming plugins.

This is C<Dist::Zilla::Role::ErrorLogger> role documentation. Read this if you want to
have error logging capabilities in your Dist::Zilla plugin.

=head1 SYNOPSIS

    package Dist::Zilla::Plugin::YourPlugin;
    use Moose;
    use namespace::autoclean;
    with 'Dist::Zilla::Role::Plugin';
    with 'Dist::Zilla::Role::ErrorLogger';

    sub method {
        my $self = shift( @_ );

        if ( $cond ) { $self->log_error( 'error message' ); };

        do_something or $self->log_error( 'another error message' );

        while ( $cond ) {
            do_something_else or $self->log_error( 'error message' ) and next;
            ...;
        };

        $self->log_errors_in_file(
            $file,
            1 => 'error message',           # Error at file line 1.
            5 => 'another error message',   # Error at file line 5.
        );

        $self->abort_if_errors( 'errors found' );
    };

    __PACKAGE__->meta->make_immutable;
    1;

=head1 DESCRIPTION

The role extends standard C<Dist::Zilla> logging capabilities with few methods a bit more
convenient for reporting (multiple) errors than brutal C<log_fatal>. See L</"WHY?"> for more
details.

The role requires C<log> method in the consumer.

=head1 OBJECT ATTRIBUTES

=head2 error_count

    $int = $self->error_count;

C<Int>, read-only. Number of logged errors (i. e. number of made C<log_error> calls).

=head1 OBJECT METHODS

=head2 log_error

    $self->log_error( @items );
    $self->log_error( \%args, @items );

This method calls C<log> method, passing all the arguments, and increments value of C<error_count>
attribute. The method returns true value, so can be used in following constructs:

    while ( ... ) {
        do_something or $self->log_error( 'message' ) and next;
        ...
    };

=head2 abort

    $self->abort( @items );
    $self->abort( \%args, @items );

This is an attempt to workaround L<C<log_fatal>
drawback|https://github.com/rjbs/Dist-Zilla/issues/397>: in contrast to C<log_fatal>, C<abort>
guarantees the message (which can be quite long) appears on the screen only once.

The method log the message (via C<log>), then flush C<STDOUT>, then throws an exception of
C<Dist::Zilla::Role::ErrorLogger::Exception::Abort> class (which being stringified gives short
message C<"Aborting...\n">).

=head2 abort_if_error

=head2 abort_if_errors

    $self->abort_if_errors( @items );
    $self->abort_if_errors( \%args, @items );

If there was any errors (i. e. C<error_count> is greater than zero), the logs all the arguments and
aborts execution. Both actions (logging and aborting) are implemented by calling C<abort>.

C<abort_if_error> is an alias for C<abort_if_errors>.

=head2 log_errors_in_file

The method intended to report errors against a file. It prints file name (and colon after it), then
prints line-numbered file content annotated by error messages. The method does not print entire
file content, but only error lines with surrounding context (2 lines above and below each error
line).

    $self->log_errors_in_file(
        $file,
        $linenum1 => $message1,
        $linenum2 => $message2,
        $linenum3 => [ $message3a, $message3b, ... ],
        ...
    );

C<$file> should be a C<Dist::Zilla> file (e. g. C<Dist::Zilla::File::OnDisk>,
C<Dist::Zilla::File::InMemory>, or does role C<Dist::Zilla::Role::File>).

Errors are specified by pairs C<< $linenum => $message >>, where C<$linenum> is a number of problem
line (one-based), and C<$message> is an error message (C<Str>) or array of messages
(C<ArrayRef[Str]>). Order of errors does not matter usually. However, if errors are associated with
the same line (the same line number may appear multiple times), they will be printed in order of
appearance.

Zero or negative line numbers, or line numbers beyond the last line are invalid. Messages
associated with invalid line numbers are reported in unspecified way.

Normally, the method prints all the information by calling C<log_error> method and returns a
positive integer. However, If any invalid line numbers are specified, the method returns negative
integer. If no errors are specified, the method prints "No errors found at I<file>." by calling
C<log> (not C<log_error>!) and returns zero.

TODO: Example.

=head1 WHY?

C<Dist::Zilla> limits logging capabilities with 3 logging levels available in plugins through
C<log_debug>, C<log>, and C<log_fatal> methods. Debug level messages are turned off by default, the
first fatal message terminates C<Dist::Zilla>. This is simple, but sometimes you may want to report
all the errors, instead of stopping at the first found one. In such a case C<log_fatal> cannot be
used, obviously. There are few alternatives:

Collect error messages in an array, then report all the errors with single C<log_fatal> call:

    my @errors;
    ...
    push( @errors, ... );
    ...
    if ( @errors ) {
        $self->log_fatal( join( "\n", @errors ) );
    };

This works, but current implementation of C<log_fatal> has a disadvantage: it prints the message
twice, so output looks ugly. (See L<message handling in log_fatal is
suboptimal|https://github.com/rjbs/Dist-Zilla/issues/397>.)

Another approach is reporting each error immediately with C<log>, counting number of reported
errors, and calling C<log_fatal> once at the end:

    my $error_count = 0;
    ...
    $self->log( 'error' );
    ++ $error_count;
    ...
    if ( $error_count ) {
        $self->log_fatal( 'Aborting...' );
    };

This works, but incrementing the counter after each C<log> call is boring and error-prone.
C<Dist-Zilla-Role-ErrorLogger> role automates it, making plugin code shorter and more readable:

    with 'Dist-Zilla-Role-ErrorLogger';
    ...
    $self->log_error( 'error' );
    ...
    $self->abort_if_errors();

=for test_synopsis my ( $cond, $file );
sub Dist::Zilla::Plugin::YourPlugin::do_something;
sub Dist::Zilla::Plugin::YourPlugin::do_something_else;

=head1 NOTES

All the methods defined in the role log items through the C<log> method. C<Dist::Zilla> takes this
method from C<Log::Dispatchouli>, the latter uses C<String::Flogger> to process the messages. It
means you can use C<String::Flogger> tricks, e. g.:

    $self->log_error( [ 'oops at %s line %d', $file, $line ] );
        #   [] are shorter than sprintf.

Also note how C<Log::Dispatchouli> describes the C<log> method:

    $logger->log( @messages );

and says:

    Each message is flogged individually, then joined with spaces.

So beware. A call

    $self->log_error( 'error 1', 'error 2' );

logs I<one> message "error 1 error 2", I<not> I<two> messages "error 1" and "error 2", and bumps
C<error_count> by 1, not 2.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role>

=item L<Dist::Zilla::Plugin>

=item L<Log::Dispatchouli>

=item L<String::Flogger>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
