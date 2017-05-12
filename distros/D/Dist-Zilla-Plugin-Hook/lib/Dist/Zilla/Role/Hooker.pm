#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Role/Hooker.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Hook.
#
#   perl-Dist-Zilla-Plugin-Hook is free software: you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Hook is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Hook. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =for :this This is C<Hooker> role documentation. Read this if you are going to hack or extend
#pod C<Dist-Zilla-Plugin-Hook>, or use the role in your plugin.
#pod
#pod =for :those If you want to write C<Dist::Zilla> plugin directly in F<dist.ini>, read the L<manual|Dist::Zilla::Plugin::Hook::Manual>. General
#pod topics like getting source, building, installing, bug reporting and some others are covered in the
#pod F<README>.
#pod
#pod =head1 DESCRIPTION
#pod
#pod C<Dist-Zilla-Plugin-Hook> is a set of plugins: C<Hook::Init>, C<Hook::BeforeBuild>, C<Hook::GatherFiles>,
#pod etc. All these plugins are just stubs, they contains almost no code. They just use services
#pod provided by the C<Hooker> role. The role is an engine for all C<Hook> plugins.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Dist::Zilla>
#pod = L<Dist::Zilla::Role>
#pod = L<Dist::Zilla::Role::Plugin>
#pod = L<Dist::Zilla::Plugin::Hook::Manual>
#pod
#pod =cut

package Dist::Zilla::Role::Hooker;

use Moose::Role;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: Run Perl code written in your plugin's F<dist.ini> section
our $VERSION = 'v0.8.3'; # VERSION

with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::ErrorLogger' => { -version => 0.005 };

# --------------------------------------------------------------------------------------------------

#pod =attr code
#pod
#pod Perl code to execute, list of lines (without newline characters).
#pod
#pod C<ArrayRef[Str]>, read-only. Default value is empty array (i. e. no code).
#pod
#pod Note: C<init_arg> attribute property set to ".". In F<dist.ini> file the Perl code should be
#pod specified using this notation:
#pod
#pod     [Hook::Role]
#pod         . = …Perl code…
#pod
#pod =cut

has code => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    auto_deref  => 1,
    init_arg    => '.',
    default     => sub { [] },
);

# --------------------------------------------------------------------------------------------------

#pod =method hook
#pod
#pod     $ret = $self->hook( @args );
#pod     @ret = $self->hook( @args );
#pod     $self->hook( @args );
#pod
#pod This is the primary method of the role. The method executes Perl code specified in C<code>
#pod attribute (prepended with C<_prologue>) with string form of C<eval>. The method passes arguments
#pod specified by the caller to the code, and passes the code return value back to the caller. Calling
#pod context (list, scalar, or void) is preserved. The method also hides all the lexical variables
#pod (except the variables documented below) from code. The method intercepts warnings generated in code
#pod and logs them; warnings do not stop executing.
#pod
#pod Following lexical variables are exposed to the code intentionally:
#pod
#pod =begin :list
#pod
#pod = C<@_>
#pod C<hook> arguments, self-reference is already shifted!
#pod
#pod = C<$arg>
#pod The same as C<$_[ 0 ]>.
#pod
#pod = C<$self>
#pod = C<$plugin>
#pod Reference to the plugin object executing the code (such as C<Hook::Init> or C<Hook::BeforeBuild>).
#pod
#pod = C<$dist>
#pod = C<$zilla>
#pod Reference to C<Dist::Zilla> object, the same as C<< $self->zilla >>.
#pod
#pod =end :list
#pod
#pod If code dies, the method logs error message and aborts C<Dist::Zilla>.
#pod
#pod =cut

sub hook {                  ## no critic ( RequireArgUnpacking )
    my $self = shift( @_ );
    if ( not $self->code ) {
        return;
    };
    my $zilla  = $self->zilla;      # `eval` sees these variables.
    my $plugin = $self;
    my $dist   = $zilla;
    my $arg    = $_[ 0 ];
    my $code   =                    # Declaration is not yet completed, `eval` will not see it.
        sub {
            #~ local $SIG{ __DIE__ };   # TODO: Should I cancel die handler, if any is set?
            local $SIG{ __WARN__ } = sub {
                my $msg = "$_[ 0 ]";
                chomp( $msg );
                $self->log( $msg );
            };
            eval(           ## no critic ( ProhibitStringyEval, RequireCheckingReturnValueOfEval )
                join(
                    "\n",
                    $self->_line_directive( 'prologue' ),           # Make error repot nice.
                    $self->_prologue,
                    $self->_line_directive( $self->plugin_name ),   # Make error repot nice.
                    $self->code,
                )
            );
        };
    my $want = wantarray();
    my ( $err, @ret );
    {
        local $@ = $@;                  # Keep outer `$@` intact.
        if ( $want ) {                  # Let us keep calling context.
            @ret = $code->( @_ );
        } elsif ( defined( $want ) ) {
            $ret[ 0 ] = $code->( @_ );
        } else {
            $code->( @_ );
        };
        $err = "$@";                    # Stringify `$@`.
    }
    if ( $err ne '' ) {
        chomp( $err );
        $self->abort( $err );
    };
    return $want ? @ret : $ret[ 0 ];
};

# --------------------------------------------------------------------------------------------------

#pod =method _line_directive
#pod
#pod     $dir = $self->_line_directive( $filename, $linenumber );
#pod     $dir = $self->_line_directive( $filename );
#pod
#pod The method returns Perl line directive, like
#pod
#pod     #line 1 "filename.ext"
#pod
#pod The method takes care about quotes. Perl line directive does not allow any quotes (escaped or not)
#pod in filename, so directive
#pod
#pod     #line 1 "\"Assa\" project.txt"
#pod
#pod will be ignored. To avoid this, C<line_directive> replaces quotes in filename with apostrophes, e.
#pod g.:
#pod
#pod     #line 1 "'Assa' project.txt"
#pod
#pod If line number is not specified, 1 will be used.
#pod
#pod =cut

sub _line_directive {
    my ( $self, $file, $line ) = @_;
    $file =~ s{"}{'}gx;     #   Perl `#line` directive does not allow quotes in filename.
    # TODO: Issue a warning if filename contains double quote?
    if ( not defined( $line ) ) {
        $line = 1;
    };
    return sprintf( '#line %d "%s"', $line, $file );
};

# --------------------------------------------------------------------------------------------------

#pod =method _prologue
#pod
#pod     @code = $self->_prologue;
#pod
#pod The method returns prologue code.
#pod
#pod Prologue code is extracted from C<Dist::Zilla> plugin named C<prologue>.
#pod
#pod =cut

sub _prologue {
    my ( $self ) = @_;
    my $zilla = $self->zilla;
    my $prologue = $zilla->plugin_named( 'prologue' );
    if ( $prologue and $prologue->meta->does_role( 'Dist::Zilla::Role::Hooker' ) ) {
        return $prologue->code;
    };
    return ();
};

# --------------------------------------------------------------------------------------------------

#pod =method mvp_multivalue_args
#pod
#pod The method tells C<Dist::Zilla> that dot (C<.>) is a multi-value option.
#pod
#pod =cut

around mvp_multivalue_args => sub {
    my ( $orig, $self ) = @_;
    return ( $self->$orig(), qw{ . } );
};

# --------------------------------------------------------------------------------------------------

around mvp_aliases => sub {
    my ( $orig, $self ) = @_;
    my $aliases = $self->$orig();
    $aliases->{ hook } = '.';
    return $aliases;
};

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015, 2016 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

#   ------------------------------------------------------------------------------------------------
#
#   file: doc/what.pod
#
#   This file is part of perl-Dist-Zilla-Plugin-Hook.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Dist-Zilla-Plugin-Hook> (or just C<Hook>) is a set of C<Dist-Zilla> plugins. Every plugin executes Perl
#pod code inlined into F<dist.ini> at particular stage of build process.
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Hooker - Run Perl code written in your plugin's F<dist.ini> section

=head1 VERSION

Version v0.8.3, released on 2016-11-25 22:04 UTC.

=head1 WHAT?

C<Dist-Zilla-Plugin-Hook> (or just C<Hook>) is a set of C<Dist-Zilla> plugins. Every plugin executes Perl
code inlined into F<dist.ini> at particular stage of build process.

This is C<Hooker> role documentation. Read this if you are going to hack or extend
C<Dist-Zilla-Plugin-Hook>, or use the role in your plugin.

If you want to write C<Dist::Zilla> plugin directly in F<dist.ini>, read the L<manual|Dist::Zilla::Plugin::Hook::Manual>. General
topics like getting source, building, installing, bug reporting and some others are covered in the
F<README>.

=head1 DESCRIPTION

C<Dist-Zilla-Plugin-Hook> is a set of plugins: C<Hook::Init>, C<Hook::BeforeBuild>, C<Hook::GatherFiles>,
etc. All these plugins are just stubs, they contains almost no code. They just use services
provided by the C<Hooker> role. The role is an engine for all C<Hook> plugins.

=head1 OBJECT ATTRIBUTES

=head2 code

Perl code to execute, list of lines (without newline characters).

C<ArrayRef[Str]>, read-only. Default value is empty array (i. e. no code).

Note: C<init_arg> attribute property set to ".". In F<dist.ini> file the Perl code should be
specified using this notation:

    [Hook::Role]
        . = …Perl code…

=head1 OBJECT METHODS

=head2 hook

    $ret = $self->hook( @args );
    @ret = $self->hook( @args );
    $self->hook( @args );

This is the primary method of the role. The method executes Perl code specified in C<code>
attribute (prepended with C<_prologue>) with string form of C<eval>. The method passes arguments
specified by the caller to the code, and passes the code return value back to the caller. Calling
context (list, scalar, or void) is preserved. The method also hides all the lexical variables
(except the variables documented below) from code. The method intercepts warnings generated in code
and logs them; warnings do not stop executing.

Following lexical variables are exposed to the code intentionally:

=over 4

=item C<@_>

C<hook> arguments, self-reference is already shifted!

=item C<$arg>

The same as C<$_[ 0 ]>.

=item C<$self>

=item C<$plugin>

Reference to the plugin object executing the code (such as C<Hook::Init> or C<Hook::BeforeBuild>).

=item C<$dist>

=item C<$zilla>

Reference to C<Dist::Zilla> object, the same as C<< $self->zilla >>.

=back

If code dies, the method logs error message and aborts C<Dist::Zilla>.

=head2 _line_directive

    $dir = $self->_line_directive( $filename, $linenumber );
    $dir = $self->_line_directive( $filename );

The method returns Perl line directive, like

    #line 1 "filename.ext"

The method takes care about quotes. Perl line directive does not allow any quotes (escaped or not)
in filename, so directive

    #line 1 "\"Assa\" project.txt"

will be ignored. To avoid this, C<line_directive> replaces quotes in filename with apostrophes, e.
g.:

    #line 1 "'Assa' project.txt"

If line number is not specified, 1 will be used.

=head2 _prologue

    @code = $self->_prologue;

The method returns prologue code.

Prologue code is extracted from C<Dist::Zilla> plugin named C<prologue>.

=head2 mvp_multivalue_args

The method tells C<Dist::Zilla> that dot (C<.>) is a multi-value option.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role>

=item L<Dist::Zilla::Role::Plugin>

=item L<Dist::Zilla::Plugin::Hook::Manual>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
