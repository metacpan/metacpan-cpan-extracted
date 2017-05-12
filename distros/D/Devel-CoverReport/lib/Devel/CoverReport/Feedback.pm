# Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://bs502.pl/

package Devel::CoverReport::Feedback;

use strict;
use warnings;

our $VERSION = "0.05";

use Carp::Assert::More qw( assert_defined );
use English qw( -no_match_vars );
use Params::Validate qw( :all );

=encoding UTF-8

=head1 DESCRIPTION

Methods used to provide some feedback from Devel::CoverReport::* modules.

=head1 WARNING

Consider this module to be an early ALPHA. It does the job for me, so it's here.

This is my first CPAN module, so I expect that some things may be a bit rough around edges.

The plan is, to fix both those issues, and remove this warning in next immediate release.

=head1 API

=over

=item new

Constructor for C<Devel::CoverReport::Feedback>.

B<Note:> setting I<quiet> AND I<verbose> does not have much sense... but - surprize! - will work :)
In such configuration, all usual things that are printed will NOT be printed,
and those that ususally are not printed - WILL.

=cut

# Send to screen as soon, as possible.
$OUTPUT_AUTOFLUSH = 1;

sub new { # {{{
    my $class = shift;
    my %P = @_;
    validate(
        @_,
        {
            quiet   => { type=>SCALAR },
            verbose => { type=>SCALAR },
        }
    );

    my $self = {
        quiet   => $P{'quiet'},
        verbose => $P{'verbose'},

        # This is needed to optimize diagnostic messages.
        # see print_file and print_file_* methods, bellow.
        at_file => q{},

        at_file_last => q{},
    };

    bless $self, $class;

    return $self;
} # }}}

=item note

Print a note, unless running in 'quiet' mode.

=cut

sub note { # {{{
    my ( $self, $text ) = @_;

    if (not $self->{'quiet'}) {
        $self->_print($text, qq{\n});
    }

    return;
} # }}}

=item info

Print informative text, when in 'verbose' mode.

=cut

sub info { # {{{
    my ( $self, $text ) = @_;

    if ($self->{'verbose'}) {
        $self->_print($text, qq{\n});
    }

    return;
} # }}}

=item at_file

Print indication, that specific file is being processed.

=cut

sub at_file { # {{{
    my ( $self, $file_path ) = @_;

    if (not $self->{'quiet'}) {
        $self->{'at_file_needed'} = 1;

        $self->_at_file($file_path);
    }

    $self->{'at_file'} = $file_path;

    return;
} # }}}

sub _at_file { # {{{
    my ( $self, $file_path ) = @_;

    assert_defined($file_path);

    # It's here, so we do not print the same thing twice:
    if ($self->{'at_file_last'} ne $file_path) {
        $self->_print(q{-> }, $file_path, qq{\n});
    
        $self->{'at_file_last'} = $file_path;
    }

    return;
} # }}}

=item file_off

Indicate, that file processing has finished. This means, that either this was the last file, or we are about to go to the next one.

=cut

sub file_off { # {{{
    my ( $self ) = @_;

    $self->{'at_file'} = q{};

    return;
} # }}}

=item error_at_file

Report any errors, that are related to file being currently processed.
Always printed.

If file path was not printed, it will be, just before the error.

=cut

sub error_at_file { # {{{
    my ( $self, $text ) = @_;

    $self->_at_file($self->{'at_file'});
    
    $self->_print(q{   E: }, $text, qq{\n});

    return;
} # }}}

=item warning_at_file

Report any warnings, that are related to file being currently processed.
Always printed.

If file path was not printed, it will be, just before the warning.

=cut

sub warning_at_file { # {{{
    my ( $self, $text ) = @_;

    $self->_at_file($self->{'at_file'});
    
    $self->_print(q{   W: }, $text, qq{\n});

    return;
} # }}}

=item progress_open

Open progress indicator.

=cut

sub progress_open { # {{{
    my ( $self, $text ) = @_;

    assert_defined($text, "Text must be defined.");

    if (not $self->{'quiet'}) {
        $self->_print(q{   }, $text, q{ [});
    }

    return;
} # }}}

=item progress_tick

Indicate, that a step in the process has been made.

=cut

sub progress_tick { # {{{
    my ( $self ) = @_;

    if (not $self->{'quiet'}) {
        $self->_print(q{.});
    }

    return;
} # }}}

=item progress_close

Close (end) progress indicator.

=cut

sub progress_close { # {{{
    my ( $self ) = @_;

    if (not $self->{'quiet'}) {
        $self->_print(qq{]\n});
    }

    return;
} # }}}

=item enable_buffer

Turn ON built-in output buffering. Since this function is used, any feedback will be stored in memory.
To get that feedback out, You should use C<dump_buffer>.

Primary use of the buffer is to hold child's output, and pass it to parent, which prints it.
This way output of one child is not interrupted by other child.

There is no C<disable_buffer>, since it was needed. I will add it, once there will be a need for it (see? I'm not THAT lazy ;).

=cut

sub enable_buffer { # {{{
    my ($self) = @_;

    $self->{'buffer_enabled'} = 1;

    $self->{'buffer'} = [];

    return 1;
} # }}}

=item dump_buffer

Dump serialized contents of the output buffer.

To print this data, use C<pass_buffer>.

After contents of the buffer are returned, the buffer itself is cleared.

B<Impotant:> make sure, You do not pass it using a Feedback object that has buffering enabled! That would not make much sense.

=cut

sub dump_buffer { # {{{
    my ($self) = @_;

    my $buffer = $self->{'buffer'};
    
    $self->{'buffer'} = [];

    return $buffer;
} # }}}

=item pass_buffer

Print serialized output buffer contents.

See notes in C<dump_buffer> too.

=cut

sub pass_buffer { # {{{
    my ($self, $buffer) = @_;

    return $self->_print( @{ $buffer or [] });
} # }}}

=item _print

This is the thing, that actually prints stuff out, so It's easy to silence/inspect the feedback in tests.

It can be overwritten in child classes, so they can log to file, or what ever You would need/like.

Private. Do not use from outside of the module!

=cut

sub _print { # {{{
    my ( $self, @params ) = @_;

    if ($self->{'buffer_enabled'}) {
        push @{ $self->{'buffer'} }, @params;

        return;
    }

    return print @params;
} # }}}

1;

=back

=head1 LICENCE

Copyright 2009-2011, Bartłomiej Syguła (perl@bs502.pl)

This is free software. It is licensed, and can be distributed under the same terms as Perl itself.

For more, see my website: http://bs502.pl/

=cut

