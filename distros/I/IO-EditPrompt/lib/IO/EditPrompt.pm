package IO::EditPrompt;

use warnings;
use strict;

use File::Temp ();
use IO::Prompter ();

our $VERSION = '0.02';

sub new {
    my ($class, $opts) = (@_);

    $opts ||= {};
    die "parameter is not a hashref.\n" unless ref $opts eq ref {};
    die "'$opts->{tmpdir}' is not a directory.\n" if defined $opts->{tmpdir} and !-d $opts->{tmpdir};

    my $self = bless {
        dir => $opts->{tmpdir},
        editor => $opts->{editor},
        editor_args => [],
    }, $class;
    $self->_normalize_editor( $opts->{default_editor} );
    return $self;
}

sub prompt {
    my ($self, $prompt, $deftext) = @_;

    my $output = '';
    my $fmt_prompt = _format_prompt( $prompt );

    do {
        my ($tmp, $filename) = $self->_create_tmp_file( $fmt_prompt, $deftext );
        $self->_run_editor( $filename );
        $output = $self->_get_output( $filename, $fmt_prompt );
    } while( (0 == length $output) && IO::Prompter::prompt( 'Content is empty, retry?', '-y' ) );

    return $output;
}

sub _normalize_editor {
    my ($self, $def_editor) = @_;
    $self->{editor} ||= $ENV{EDITOR} || $def_editor || 'vim';

    # Turn off saving state on vim
    $self->{editor_args} = [ '-i', 'NONE' ] if $self->{editor} =~ /\bvim$/;
    return;
}

sub _format_prompt {
    my ($prompt) = @_;
    return '' unless defined $prompt;
    return join( q{}, map { "# $_\n" } split /\n/, $prompt );
}

sub _create_tmp_file {
    my ($self, @texts) = @_;

    my $tmp = File::Temp->new( UNLINK => 1, EXLOCK => 1, ($self->{dir} ? (DIR => $self->{dir}) : ()) );
    my $filename = $tmp->filename;
    print {$tmp} grep { defined $_ } @texts;
    close( $tmp ) or die "Unable to write '$filename': $!\n";

    return ($tmp, $filename);
}

sub _read_file {
    my ($self, $filename) = @_;
    open my $fh, '<', $filename or die "Unable to re-read '$filename': $!\n";
    local $/;
    return scalar <$fh>;
}

sub _get_output {
    my ($self, $filename, $prompt) = @_;
    return '' if  -s $filename eq length $prompt;
    my $output = $self->_read_file( $filename );
    $output =~ s/^#[^\n]*(?:\n|\Z)//smg;
    return $output;
}

sub _run_editor {
    my ($self, $file) = @_;
    my $err = system $self->{editor}, @{$self->{editor_args}}, $file;
    return unless $err;
    if ($? == -1) {
        die "failed to execute '$self->{editor}': $!\n";
    }
    elsif ($? & 127) {
        die sprintf "'$self->{editor}' died with signal %d, %s coredump\n",
            ($? & 127),  ($? & 128) ? 'with' : 'without';
    }
    else {
        die sprintf "'$self->{editor}' exited with value %d\n", $? >> 8;
    }
}

1;
__END__

=head1 NAME

IO::EditPrompt - Support a prompt that uses the configured editor to take long text

=head1 VERSION

This document describes IO::EditPrompt version 0.01

=head1 SYNOPSIS

    use IO::EditPrompt;

    my $p = IO::EditPrompt->new();
    my $answer = $p->prompt( 'Explain in your own words:' );

    my $p1 = IO::EditPrompt->new({ tmpdir=>'./tmp', editor=>'emacs' });
    my $abstract = $p1->prompt( "Enter your abstract:\n(no HTML tags allowed)\n", 'Boilerplate abstract' );
    my $write_up = $p1->prompt( <<EOH );
    Enter a write-up of meeting:
      blank lines for paragraphs.
      <em/>, <strong/>, <a/> are all supported
    EOH

=head1 DESCRIPTION

This module provides extended functionality for entering or changing text for
command line programs.

The C<IO::Prompter> module does a wonderful job of encapsulating
a lot of user entry tasks in a really nice interface. One thing it does not do well
is allow input for long-form text. Many version control systems use the approach
of opening a window in your editor to deal with long-form text. This seems like a
great solution and avoids a large number of nasty bits (like editing functions
surrounding Unicode characters).

This module wraps up the functionality needed to use an editor in this fashion
in a realtively straight-forward interface.

=head1 INTERFACE 

=head2 new

Create new C<IO::EditPrompt> object. This object can be used with multiple prompt
calls. The optional paramters must be passed as a hashref.

=over

=item dir

Specify a directory for the temporary file to edit.

=item default_editor

The name of a default editor if none is provided by the EDITOR environment
variable.

=item editor

Force calling this program as the editor, independent of the environment. If
this parameter is missing, the program will default to using the EDITOR environment
variable. If there is no value for EDITOR, we try the supplied C<default_editor>
parameter. If none of these have values, we default to C<vim>.

=back

=head2 prompt( $prompt, $deftext )

Open the editor with the supplied C<$prompt> and C<$deftext> already filled in.
Every line of the prompt text will be prefixed by the string C<# >, the default
text will be supplied as is. After the user saves any changes, the content of
the file is read and any text that begins with C<#> is removed. The result is
returned to the caller.

If the cleaned up text is empty, the user is given an attempt to retry.

=head1 CONFIGURATION AND ENVIRONMENT

IO::EditPrompt relies on the EDITOR environment variable to supply a default
editor to use.


=head1 DEPENDENCIES

=over

=item *

C<File::Temp>

=item *

C<IO::Prompter>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-io-editprompt@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

Other modules with related functionality include:

=over

=item *

C<IO::Prompt>

=item *

C<IO::Prompter>

=item *

C<IO::Prompt::Tiny>

=item *

C<IO::Prompt::Simple>

=item *

C<Prompt::Timeout>

=item *

C<Term::Prompt>

=back

=head1 AUTHOR

G. Wade Johnson  C<< <gwadej@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, G. Wade Johnson C<< <gwadej@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
